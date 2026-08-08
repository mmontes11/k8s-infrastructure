# 🐘 PostgreSQL

Basic commands to connect to and inspect the [CloudNativePG](https://cloudnative-pg.io/) resources defined in [`infrastructure/cloudnative-pg/postgresql`](../infrastructure/cloudnative-pg/postgresql).

## Resources

| Resource | Kind | Description |
| --- | --- | --- |
| `postgresql` | `Cluster` | Single instance PostgreSQL 18.4 cluster in the `database` namespace |
| `app` | database | Bootstrap database, owned by the `app` role (credentials in the `postgresql` secret) |
| `multica` | `Database` + `DatabaseRole` | Tenant database with the `vector` extension, owned by the `multica` role |
| `postgresql-super` | secret | `postgres` superuser credentials (`enableSuperuserAccess: true`) |
| `postgresql-server-tls` / `postgresql-client-tls` | `Certificate` | Server and replication certs issued by the `homelab` `ClusterIssuer` |
| `postgresql` | `PodMonitor` | Scrapes the CNPG metrics exporter |

The operator creates three services in the `database` namespace:

- `postgresql-rw`: primary, read-write.
- `postgresql-ro`: replicas only, read-only. With `instances: 1` it has **no endpoints**.
- `postgresql-r`: any instance, read-only routing.

## Inspect the cluster

```bash
kubectl get cluster -n database
kubectl get pods,svc,pvc -n database -l cnpg.io/cluster=postgresql
kubectl get database,databaserole -n database
kubectl describe cluster postgresql -n database
```

With the [`cnpg` plugin](https://cloudnative-pg.io/documentation/current/kubectl-plugin/):

```bash
kubectl cnpg status postgresql -n database
kubectl cnpg status postgresql -n database --verbose
kubectl cnpg psql postgresql -n database        # psql shell on the primary
```

## Get credentials

```bash
# superuser
kubectl get secret postgresql-super -n database -o jsonpath='{.data.username}' | base64 -d; echo
kubectl get secret postgresql-super -n database -o jsonpath='{.data.password}' | base64 -d; echo

# app owner
kubectl get secret postgresql -n database -o jsonpath='{.data.password}' | base64 -d; echo

# multica owner
kubectl get secret multica -n database -o jsonpath='{.data.password}' | base64 -d; echo
```

## Connect

### From the cluster pod

The `postgres` superuser connects over the local socket, no password needed:

```bash
kubectl exec -it postgresql-1 -n database -c postgres -- psql
kubectl exec -it postgresql-1 -n database -c postgres -- psql -d multica
kubectl exec -it postgresql-1 -n database -c postgres -- psql -c '\l'
```

### From your machine

Port-forward the read-write service and connect with `psql`:

```bash
kubectl port-forward svc/postgresql-rw 5432:5432 -n database

PGPASSWORD=$(kubectl get secret postgresql-super -n database -o jsonpath='{.data.password}' | base64 -d) \
  psql -h 127.0.0.1 -p 5432 -U postgres -d app
```

As the `multica` owner:

```bash
PGPASSWORD=$(kubectl get secret multica -n database -o jsonpath='{.data.password}' | base64 -d) \
  psql -h 127.0.0.1 -p 5432 -U multica -d multica
```

### From another pod in the cluster

```bash
kubectl run psql --rm -it --restart=Never -n database \
  --image=ghcr.io/cloudnative-pg/postgresql:18.4 -- \
  psql "postgresql://multica@postgresql-rw.database.svc.cluster.local:5432/multica"
```

### TLS

The server certificate is signed by the `homelab` CA (`homelab-bundle`) and only covers the `postgresql`, `postgresql-rw` and `postgresql-r` DNS names — not `postgresql-ro`. To verify the server certificate, extract the CA and use `sslmode=verify-full`:

```bash
kubectl get secret homelab-bundle -n database -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/homelab-ca.crt

psql "host=postgresql-rw.database.svc.cluster.local port=5432 dbname=app user=app \
      sslmode=verify-full sslrootcert=/tmp/homelab-ca.crt"
```

When port-forwarding, hostname verification fails against `127.0.0.1`; use `sslmode=require` instead.

## Inspect with psql

### Databases, roles and schemas

```sql
\l+                      -- databases with sizes and owners
\du+                     -- roles and their attributes
\c multica               -- switch database
\dn+                     -- schemas
\conninfo                -- current connection details
```

### Tables and objects

```sql
\dt+                     -- tables with sizes
\di+                     -- indexes
\dv                      -- views
\df                      -- functions
\d+ <table>              -- describe a table
\dx                      -- installed extensions (vector should be listed in multica)
```

### Sizes

```sql
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database ORDER BY pg_database_size(datname) DESC;

SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 20;
```

### Activity and configuration

```sql
SELECT pid, usename, datname, client_addr, state, query
FROM pg_stat_activity WHERE state <> 'idle';

SHOW shared_buffers;     -- 256MB, set in cluster.yaml
SELECT version();
SELECT pg_is_in_recovery();          -- false on the primary
SELECT * FROM pg_stat_replication;   -- empty with instances: 1
SELECT * FROM pg_stat_ssl WHERE pid = pg_backend_pid();
```

## Metrics

The CNPG exporter is scraped by the `postgresql` `PodMonitor`. To check it directly:

```bash
kubectl port-forward postgresql-1 9187:9187 -n database
curl -s localhost:9187/metrics | grep cnpg_
```

The custom queries come from the `cnpg-default-monitoring` ConfigMap, and the Helm release ships a Grafana dashboard into the `monitoring` namespace.

## Logs

```bash
kubectl logs postgresql-1 -n database -c postgres -f
kubectl cnpg logs cluster postgresql -n database -f
```
