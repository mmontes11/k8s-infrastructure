ROOK_VERSION ?= v1.15.2
ROOK_URL ?= https://raw.githubusercontent.com/rook/rook/refs/tags/$(ROOK_VERSION)/deploy/examples/crds.yaml

PROMETHEUS_VERSION ?= 63.1.0
PROMETHEUS_URL ?= https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-$(PROMETHEUS_VERSION)/kube-prometheus-stack-$(PROMETHEUS_VERSION).tgz

GATEWAY_API_VERSION ?= v1.2.0/
GATEWAY_API_URL ?= https://github.com/kubernetes-sigs/gateway-api/releases/download/$(GATEWAY_API_VERSION)/experimental-install.yaml

EXTERNAL_SNAPSHOTTER_VERSION ?= v8.1.0
EXTERNAL_SNAPSHOTTER_URL ?= https://github.com/kubernetes-csi/external-snapshotter/

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: rook-crds
rook-crds: ### Get rook CRDs to be installed by flux.
	curl -sSLo infrastructure/rook/rook-crds/crds.yaml $(ROOK_URL)

.PHONY: prometheus-crds
prometheus-crds: ### Get prometheus CRDs to be installed by flux.
	@if [ -d "kube-prometheus-stack" ]; then \
			rm -rf kube-prometheus-stack/; \
	fi
	curl -sL $(PROMETHEUS_URL) | tar xz -C .
	cp kube-prometheus-stack/charts/crds/crds/*.yaml  infrastructure/kube-prometheus-stack/prometheus-crds
	rm -rf kube-prometheus-stack/

.PHONY: gateway-api-crds
gateway-api-crds: ## Get gateway-api CRDs to be installed by flux.
	curl -sSLo infrastructure/gateway-api/gateway-api.yaml $(GATEWAY_API_URL)

.PHONY: external-snapshotter-crds
external-snapshotter-crds: ## Get external-snapshotter CRDs
	@if [ -d "external-snapshotter" ]; then \
		rm -rf external-snapshotter/; \
	fi
	git clone $(EXTERNAL_SNAPSHOTTER_URL); \
	cd external-snapshotter; \
	git checkout $(EXTERNAL_SNAPSHOTTER_VERSION); \
	kubectl kustomize client/config/crd  > ../infrastructure/external-snapshotter/crds/crds.yaml; \
	cd ..; \
	rm -rf external-snapshotter/