ROOK_VERSION ?= v1.15.2
ROOK_URL ?= https://raw.githubusercontent.com/rook/rook/refs/tags/$(ROOK_VERSION)/deploy/examples/crds.yaml

PROMETHEUS_VERION ?= 63.1.0
PROMETHEUS_URL ?= https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-$(PROMETHEUS_VERION)/kube-prometheus-stack-$(PROMETHEUS_VERION).tgz

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