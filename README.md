# 🏗️ k8s-infrastructure
Infrastructure and tenant bootstrapping using [flux](https://fluxcd.io/).

### Multi tenancy

The [clusters](./clusters) folder contains an entrypoint for each cluster that is used by flux when bootstrapping:
- [production](https://github.com/mmontes11/k8s-bootstrap/blob/main/bootstrap.sh)


### Infrastructure

The [infrastructure](./infrastructure) folder contains cluster-wide resources and workloads shared between all the tenants. 

### Tenants

The [tenants](./tenants) folder configures the entrypoint for the tenant resources, which live in separated repositories:
- [dns](https://github.com/mmontes11/k8s-dns)
- [iot](https://github.com/mmontes11/k8s-iot)
- [media](https://github.com/mmontes11/k8s-media)
- [github-explorer](https://github.com/mmontes11/k8s-github-explorer)
- [gotway](https://github.com/gotway/k8s-gotway)