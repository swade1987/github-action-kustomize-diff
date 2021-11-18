FROM alpine:3.14.3

RUN apk add --no-cache \
  curl \
  bash \
  git \
  && rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.7/kustomize_v3.8.7_linux_amd64.tar.gz \
  | tar xz -C /usr/local/bin 

COPY kustdiff /kustdiff

ENTRYPOINT ["/kustdiff"]
