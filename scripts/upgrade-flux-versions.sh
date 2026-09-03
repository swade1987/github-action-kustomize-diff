#!/usr/bin/env bash

###############################################################################
# Script Name     : upgrade-flux-versions.sh
# Description     : Creates a pull request to keep the Dockerfile's
#                    kustomize/helm versions in step with what flux itself
#                    is built against
###############################################################################
#
# Flux's own release doesn't state which kustomize/Helm CLI versions it was
# built against directly - it has to be derived:
#
#   1. The flux2 release body has a "Components changelog" section listing
#      kustomize-controller and helm-controller at their own versions.
#   2. kustomize-controller's go.mod, at that version, carries a literal
#      "// Pin kustomize to vX.Y.Z" comment - the real kustomize CLI version.
#   3. helm-controller's go.mod, at that version, imports helm.sh/helm/vN -
#      the module version *is* the Helm CLI release version.
#
# This keeps the action's kustomize/Helm aligned with what Flux itself is
# compatible with, rather than independently chasing each tool's own latest -
# including across a Helm major version move, since the ARG is named
# HELM_VERSION, not HELM_V3.
#
# Unlike a tool this repo tracks by its own version number (there's no
# "flux" ARG here - this repo only bundles kustomize/helm), there's nothing
# to compare flux's own release against for a "nothing to do" check. Instead
# the script always derives the current target kustomize/helm versions from
# flux's latest release and compares those directly to what's already in the
# Dockerfile.

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# shellcheck source=lib/signed-pr.sh
source "${SCRIPT_DIR}/scripts/lib/signed-pr.sh"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

VERBOSE=true
DRY_RUN=true
LOG_FILE="${SCRIPT_DIR}/scripts/${SCRIPT_NAME}.log"
readonly DOCKERFILE="Dockerfile"

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Checks flux2's latest release, derives the kustomize and Helm versions it
was built against, and (with --execute) opens a pull request updating
${DOCKERFILE} to match.

Options:
    -h, --help         Show this help message
    -e, --execute      Execute changes (disabled by default)
    -l, --log FILE     Log output to specified file
EOF
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
    fi

    if [[ "${VERBOSE}" == "true" ]] || [[ "${level}" == "ERROR" ]]; then
        case "${level}" in
            ERROR)   echo -e "${RED}${timestamp} [${level}] ${message}${NC}" >&2 ;;
            WARN)    echo -e "${YELLOW}${timestamp} [${level}] ${message}${NC}" ;;
            SUCCESS) echo -e "${GREEN}${timestamp} [${level}] ${message}${NC}" ;;
            *)       echo "${timestamp} [${level}] ${message}" ;;
        esac
    fi
}

check_requirements() {
    local failed=false
    for cmd in "$@"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            log "ERROR" "${cmd} is required but not installed."
            failed=true
        fi
    done
    [[ "${failed}" == "true" ]] && exit 1
    return 0
}

fetch_file() {
    local repo="$1" path="$2" ref="$3"
    gh api "repos/${repo}/contents/${path}?ref=${ref}" --jq '.content' | base64 -d
}

get_latest_flux_tag() {
    gh api repos/fluxcd/flux2/releases/latest --jq '.tag_name'
}

get_current_arg() {
    local name="$1"
    grep -E "^ARG ${name}=" "${DOCKERFILE}" | head -1 | cut -d= -f2
}

get_component_version() {
    local body="$1" component="$2"
    awk '/^## Components changelog/{f=1;next} /^## /{f=0} f' <<<"$body" \
        | grep -E "^- ${component} \[v" \
        | grep -oE '\[v[0-9]+\.[0-9]+\.[0-9]+\]' \
        | tr -d '[]v'
}

get_kustomize_version() {
    local kc_tag="$1" content
    content="$(fetch_file "fluxcd/kustomize-controller" "go.mod" "v${kc_tag}")"
    grep -m1 "// Pin kustomize to v" <<<"$content" \
        | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
        | tr -d v
}

# Prints "<major> <version>", e.g. "4 4.2.4"
get_helm_version() {
    local hc_tag="$1" content
    content="$(fetch_file "fluxcd/helm-controller" "go.mod" "v${hc_tag}")"
    grep -m1 -E '^\s*helm\.sh/helm/v[0-9]+ v' <<<"$content" \
        | sed -E 's|.*helm\.sh/helm/v([0-9]+) v([0-9.]+).*|\1 \2|'
}

show_config() {
    log "INFO" "=== Configuration ==="
    log "INFO" "flux release checked: v${FLUX_VERSION}"
    log "INFO" "kustomize target:     ${KUSTOMIZE_VERSION} (current: ${CURRENT_KUSTOMIZE})"
    log "INFO" "Helm target:          ${HELM_VERSION}, v${HELM_MAJOR} line (current: ${CURRENT_HELM})"
    log "INFO" "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'EXECUTE')"
    log "INFO" "===================="
}

update_dockerfile() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update KUSTOMIZE/HELM_VERSION ARGs in ${DOCKERFILE}"
        return 0
    fi
    sed -i.bak -E "s/^ARG KUSTOMIZE=.*/ARG KUSTOMIZE=${KUSTOMIZE_VERSION}/" "${DOCKERFILE}"
    sed -i.bak -E "s/^ARG HELM_VERSION=.*/ARG HELM_VERSION=${HELM_VERSION}/" "${DOCKERFILE}"
    rm -f "${DOCKERFILE}.bak"
    log "SUCCESS" "Updated ${DOCKERFILE}"
}

create_pull_request() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would create pull request for kustomize/Helm version upgrade"
        return 0
    fi

    local branch_name="flux/sync-versions-${FLUX_VERSION}"
    local commit_message="feat: sync kustomize/helm to flux v${FLUX_VERSION}"

    local body="Keeps kustomize and Helm in step with flux v${FLUX_VERSION}."

    if [[ "${KUSTOMIZE_VERSION}" != "${CURRENT_KUSTOMIZE}" ]]; then
        body="${body} Bumps kustomize from ${CURRENT_KUSTOMIZE} to ${KUSTOMIZE_VERSION}, derived from kustomize-controller v${KC_VERSION}'s pinned version (flux v${FLUX_VERSION}'s Components changelog)."
    fi

    if [[ "${HELM_VERSION}" != "${CURRENT_HELM}" ]]; then
        body="${body} Bumps Helm from ${CURRENT_HELM} to ${HELM_VERSION} (helm-controller v${HC_VERSION} pins helm.sh/helm/v${HELM_MAJOR} v${HELM_VERSION})."
        if [[ "${HELM_MAJOR}" != "${CURRENT_HELM_MAJOR}" ]]; then
            body="${body} Note: this crosses a Helm major version (v${CURRENT_HELM_MAJOR} -> v${HELM_MAJOR}) - Helm's CLI surface can differ across majors, so review this one a bit more closely than a routine patch bump."
        fi
    fi

    create_signed_pr "$branch_name" "$commit_message" "$commit_message" "$body"
}

main() {
    check_requirements "git" "gh" "jq" "sed" "awk"

    log "INFO" "Fetching latest flux2 release..."
    local latest_tag
    latest_tag="$(get_latest_flux_tag)"
    FLUX_VERSION="${latest_tag#v}"
    readonly FLUX_VERSION

    log "INFO" "Fetching v${FLUX_VERSION} release notes..."
    local body
    body="$(gh api "repos/fluxcd/flux2/releases/tags/${latest_tag}" --jq '.body')"

    KC_VERSION="$(get_component_version "$body" "kustomize-controller")"
    HC_VERSION="$(get_component_version "$body" "helm-controller")"
    readonly KC_VERSION HC_VERSION

    if [[ -z "${KC_VERSION}" || -z "${HC_VERSION}" ]]; then
        log "ERROR" "Could not find kustomize-controller/helm-controller versions in the Components changelog"
        exit 1
    fi

    log "INFO" "Deriving kustomize version from kustomize-controller v${KC_VERSION}..."
    KUSTOMIZE_VERSION="$(get_kustomize_version "${KC_VERSION}")"
    readonly KUSTOMIZE_VERSION

    log "INFO" "Deriving Helm version from helm-controller v${HC_VERSION}..."
    read -r HELM_MAJOR HELM_VERSION <<<"$(get_helm_version "${HC_VERSION}")"
    readonly HELM_MAJOR HELM_VERSION

    if [[ -z "${KUSTOMIZE_VERSION}" || -z "${HELM_VERSION}" ]]; then
        log "ERROR" "Could not derive kustomize/Helm versions from component go.mod files"
        exit 1
    fi

    CURRENT_KUSTOMIZE="$(get_current_arg KUSTOMIZE)"
    CURRENT_HELM="$(get_current_arg HELM_VERSION)"
    readonly CURRENT_KUSTOMIZE CURRENT_HELM
    CURRENT_HELM_MAJOR="${CURRENT_HELM%%.*}"
    readonly CURRENT_HELM_MAJOR

    show_config

    if [[ "${KUSTOMIZE_VERSION}" == "${CURRENT_KUSTOMIZE}" && "${HELM_VERSION}" == "${CURRENT_HELM}" ]]; then
        log "INFO" "Already in sync with flux v${FLUX_VERSION}; nothing to do."
        exit 0
    fi

    update_dockerfile
    create_pull_request
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            *)
                log "ERROR" "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

parse_args "$@"
main
