# 🏗️ k8s-infrastructure
Infrastructure and tenant bootstrapping using [Flux](https://fluxcd.io/).

### [Clusters](./clusters) 

Entrypoint for each cluster that is used by Flux when bootstrapping:
- [production](https://github.com/mmontes11/k8s-bootstrap/blob/main/bootstrap.sh): Provisioned in [k8s-bootstrap](https://github.com/mmontes11/k8s-bootstrap).


### [Infrastructure](./infrastructure) 

Cluster-wide resources and workloads shared between all the tenants. 

### [Tenants](./tenants) 

Entrypoint for the tenant resources, which live in separated repositories:
- [iot](https://github.com/mmontes11/k8s-iot)
- [media](https://github.com/mmontes11/k8s-media)
- [github-explorer](https://github.com/mmontes11/k8s-github-explorer)
- [gotway](https://github.com/gotway/k8s-gotway)

### Network map

![Network map](https://raw.githubusercontent.com/mmontes11/k8s-infrastructure/main/docs/network-map.png)

### Blog
- [Securely Ingressing into Bare Metal Kubernetes Clusters with Gateway API and Tailscale](https://itnext.io/securely-ingressing-into-bare-metal-kubernetes-clusters-with-gateway-api-and-tailscale-cc68299b646a)
