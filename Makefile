PROJNAME := github-action-kustomize-diff
GOOS ?= $(if $(TARGETOS),$(TARGETOS),linux)
GOARCH ?= $(if $(TARGETARCH),$(TARGETARCH),amd64)
BUILDPLATFORM ?= $(GOOS)/$(GOARCH)

# ############################################################################################################
# Local tasks
# ############################################################################################################

initialise:
	pre-commit --version || brew install pre-commit
	pre-commit install --install-hooks
	pre-commit run -a

build:
	docker buildx build --build-arg BUILDPLATFORM=$(BUILDPLATFORM) --build-arg TARGETARCH=$(GOARCH) -t local/$(PROJNAME) .

scan: build
	trivy image -s "UNKNOWN,MEDIUM,HIGH,CRITICAL" --exit-code 1 local/$(PROJNAME)
