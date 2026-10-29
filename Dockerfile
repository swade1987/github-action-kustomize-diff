FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

RUN apk update && apk --no-cache add bash curl git

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# kustomize/helm versions are kept in step with what flux itself is built
# against - see scripts/upgrade-flux-versions.sh and
# .github/workflows/monitor-flux-versions.yml, which derive these from
# flux2's own release rather than chasing each tool's latest independently.
ARG KUSTOMIZE=5.8.1
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize

ARG HELM_VERSION=4.2.4
RUN curl -sSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | \
tar xz && mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 && helm version

RUN rm -rf /var/cache/apk/*

COPY kustdiff /kustdiff

ENTRYPOINT ["/kustdiff"]
