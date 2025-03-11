FROM alpine:3.21.3

RUN apk update && apk --no-cache add bash curl git

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG KUSTOMIZE=5.6.0
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize

RUN rm -rf /var/cache/apk/*

COPY kustdiff /kustdiff

ENTRYPOINT ["/kustdiff"]
