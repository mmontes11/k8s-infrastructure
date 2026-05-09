ROOK_VERSION ?= v1.16.5
ROOK_URL ?= https://raw.githubusercontent.com/rook/rook/refs/tags/$(ROOK_VERSION)/deploy/examples/crds.yaml

GATEWAY_API_VERSION ?= v1.2.0/
GATEWAY_API_URL ?= https://github.com/kubernetes-sigs/gateway-api/releases/download/$(GATEWAY_API_VERSION)/experimental-install.yaml

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: rook-crds
rook-crds: ### Get rook CRDs to be installed by flux.
	curl -sSLo infrastructure/rook/rook-crds/crds.yaml $(ROOK_URL)

.PHONY: gateway-api-crds
gateway-api-crds: ## Get gateway-api CRDs to be installed by flux.
	curl -sSLo infrastructure/gateway-api/gateway-api.yaml $(GATEWAY_API_URL)