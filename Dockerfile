FROM alpine:3.21.3

RUN apk update && apk --no-cache add bash curl git

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG KUSTOMIZE=5.6.0
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize

ARG HELM_V3=3.17.1
RUN curl -sSL https://get.helm.sh/helm-v${HELM_V3}-linux-amd64.tar.gz | \
tar xz && mv linux-amd64/helm /usr/local/bin/helmv3 && rm -rf linux-amd64 && ln -s /usr/local/bin/helmv3 /usr/local/bin/helm && helm version

RUN rm -rf /var/cache/apk/*

COPY kustdiff /kustdiff

ENTRYPOINT ["/kustdiff"]
