# 🏗️ k8s-infrastructure
Infrastructure and tenant bootstrapping using [Flux](https://fluxcd.io/).

### [Clusters](./clusters) 

Entrypoint for each cluster that is used by Flux when bootstrapping:
- [`homelab`](https://github.com/mmontes11/k8s-infrastructure/tree/main/clusters/homelab): Provisioned by [__k8s-management__](https://github.com/mmontes11/k8s-management) and [__k8s-bootstrap__](https://github.com/mmontes11/k8s-bootstrap?tab=readme-ov-file#add-node-to-a-existing-talos-cluster).


### [Infrastructure](./infrastructure) 

Cluster-wide resources and workloads shared between all the tenants. 

### [Tenants](./tenants) 

Entrypoint for the tenant resources, which live in separated repositories:
- [ai](https://github.com/mmontes11/k8s-ai)
- [media](https://github.com/mmontes11/k8s-media)
- [iot](https://github.com/mmontes11/k8s-iot)
- [github-explorer](https://github.com/mmontes11/k8s-github-explorer)

### Benchmarks

Performance benchmarks for the infrastructure and its tenants:
- [storage-bench](https://github.com/mmontes11/storage-bench): Storage performance benchmarks
- [database-bench](https://github.com/mmontes11/database-bench): Database performance benchmarks
- [llm-bench](https://github.com/mmontes11/llm-bench): LLM inference performance benchmarks

### Network map

![Network map](https://raw.githubusercontent.com/mmontes11/k8s-infrastructure/main/docs/network-map.png)

### Blog
- [Securely Ingressing into Bare Metal Kubernetes Clusters with Gateway API and Tailscale](https://itnext.io/securely-ingressing-into-bare-metal-kubernetes-clusters-with-gateway-api-and-tailscale-cc68299b646a)
