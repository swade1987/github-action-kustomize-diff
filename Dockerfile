FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

RUN apk update && apk --no-cache add bash curl git

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# kustomize/helm versions are kept in step with what flux itself is built
# against - see scripts/upgrade-flux-versions.sh and
# .github/workflows/monitor-flux-versions.yml, which derive these from
# flux2's own release rather than chasing each tool's latest independently.
ARG KUSTOMIZE=5.8.1
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize

ARG HELM_VERSION=3.19.2
RUN curl -sSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | \
tar xz && mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 && helm version

RUN rm -rf /var/cache/apk/*

COPY kustdiff /kustdiff

ENTRYPOINT ["/kustdiff"]
