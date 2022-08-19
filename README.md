# 🏗️ k8s-infrastructure
Infrastructure and tenant bootstrapping using [Flux](https://fluxcd.io/).

### [Clusters](./clusters) 

Entrypoint for each cluster that is used by flux when bootstrapping:
- [production](https://github.com/mmontes11/k8s-bootstrap/blob/main/bootstrap.sh): Provisioned in [k8s-bootstrap](https://github.com/mmontes11/k8s-bootstrap).


### [Infrastructure](./infrastructure) 

Cluster-wide resources and workloads shared between all the tenants. 

### [Tenants](./tenants) 

Entrypoint for the tenant resources, which live in separated repositories:
- [dns](https://github.com/mmontes11/k8s-dns)
- [iot](https://github.com/mmontes11/k8s-iot)
- [media](https://github.com/mmontes11/k8s-media)
- [github-explorer](https://github.com/mmontes11/k8s-github-explorer)
- [gotway](https://github.com/gotway/k8s-gotway)
