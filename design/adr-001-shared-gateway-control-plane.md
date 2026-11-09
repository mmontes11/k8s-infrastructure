---
title: "ADR-0001: Shared Envoy Gateway + Agent Router control plane"
status: "Accepted"
date: "2026-11-09"
authors: "mmontes"
tags: ["architecture", "decision", "envoy-gateway", "ai-gateway", "multi-tenancy"]
supersedes: ""
superseded_by: ""
---

# ADR-0001: Shared Envoy Gateway + Agent Router control plane

## Status

**Accepted** (2026-11-09) — implemented in `feature-envoy-gateway-system-ns` (this repo, which now owns the entire shared control plane, both releases included) and the matching branch in `mmontes11/k8s-ai` (removes the Agent Router release and its CRDs); live verification follows the merge.

## Context

The homelab serves multiple tenants (internal: `envoy-internal`, external: `envoy-external`, plus the `ai` tenant's LLM/MCP routes) through Envoy Gateway. The original layout followed the traefik pattern — control plane and data plane per tenant — and LAB-385 moved both controllers (Envoy Gateway, Agent Router) out of the tenant namespaces into a shared `envoy-gateway-system` namespace while keeping **one controller per tenant** (tenant-specific `controllerName` + `GatewayClass`, a second controller release for `envoy-external`).

That per-tenant-controller design was reconsidered: it duplicates a stateless control plane for every tenant (extra pods, webhooks, certgen jobs, Prometheus targets, upgrade surface) while providing no isolation the tenant namespaces do not already provide — the Gateway API resources of a tenant live in its own namespace, and the Envoy proxy (data plane) deploys to the Gateway's namespace regardless of where the controller runs.

## Decision

**One shared control plane in `envoy-gateway-system`, watching all namespaces; a dedicated Envoy data plane per tenant.**

### Envoy Gateway controller (gateway-helm v1.10.0)

- Single Helm release `envoy-gateway` in `envoy-gateway-system`; `provider.kubernetes.deploy.type: GatewayNamespace`, **no watch restriction** → the controller reconciles GatewayClasses/Gateways in **all** namespaces and creates each Gateway's proxy Deployment/Service **in the Gateway's own namespace**.
- **No custom `controllerName`**: the default `gateway.envoyproxy.io/gatewayclass-controller` is used, so a **single shared `GatewayClass/envoy`** (cluster-scoped, kept in the `envoy-gateway-system` kustomization) serves every tenant. The per-tenant `GatewayClass`es and their `gateway.envoyproxy.io/envoy-<tenant>` controller names are removed.
- Fleet-wide proxy defaults (replicas, container resources) live in the release's `config.envoyGateway.envoyProxy`; **per-tenant specifics** (LoadBalancer IP via `metallb.io/loadBalancerIPs`, replicas, `externalTrafficPolicy`, PDB, priority class, gateway-scoped anti-affinity) live in a **namespaced `EnvoyProxy`** per tenant, referenced from its Gateway via `spec.infrastructure.parametersRef` (documented precedence: Gateway-level EnvoyProxy > GatewayClass-level > controller defaults; tenant EnvoyProxies use `mergeType: StrategicMerge` so list fields merge instead of being replaced).
- `deploy.type` **must stay `GatewayNamespace`**: with it unset the v1.10 controller treats the fleet as `ControllerNamespace` mode (`GatewayNamespaceMode()` is false) and the chart renders only the namespaced infra-manager Role — proxies would deploy into `envoy-gateway-system` and cross-tenant proxy creation would be denied.

### Agent Router controller (ai-gateway-helm v1.2.0)

- Single Helm release `ai-gateway` in `envoy-gateway-system`, **in this repo** (`infrastructure/envoy/envoy-gateway-system/`, delivered by the same Flux Kustomization as the Envoy Gateway release) — the entire shared control plane is owned by one repo. `controller.watch.namespaces` **unset** → watches all namespaces. Its mutating webhook (extproc sidecar injection) matches pods by `app.kubernetes.io/managed-by: envoy-gateway` with no namespace selector, so it injects into Envoy proxies in every tenant namespace.
- Its CRDs (`ai-gateway-crds-helm`, AIGatewayRoute/MCPRoute/etc.) are installed by the `ai-gateway-crds` HelmRelease in `infrastructure/envoy/crds/`; the tenant `AIGatewayRoute`/`MCPRoute` objects stay in `k8s-ai` and now depend on the shared `envoy-crds` Kustomization.
- `envoyGateway.namespace: envoy-gateway-system` — the namespace of the shared Envoy Gateway controller; the chart's own InferencePool `ClusterRoleBinding` thereby grants read access to the shared controller's `envoy-gateway` ServiceAccount (the hand-rolled `envoy-gateway-inferencepool-role` ClusterRole in the same kustomization duplicates it and can be dropped once the move is verified).

### Per-tenant data plane (unchanged shape)

Each tenant namespace keeps its `Gateway`, routes, TLS, policies, EnvoyProxy, and Prometheus monitors. `envoy-internal`: 2 replicas, LB `10.0.0.71`, PDB `minAvailable: 1`. `envoy-external`: 1 replica, LB `10.0.0.81`, PDB `minAvailable: 1`. The `envoy-gateway-external` namespace and the second Envoy Gateway controller release (LAB-387 staging) are removed.

## Validation

- **RBAC (chart render, gateway-helm v1.10.0):** `deploy.type: GatewayNamespace` + no watch renders the cluster-scoped `envoy-gateway-cluster-infra-manager` ClusterRole/Binding for the `envoy-gateway` SA — the controller can create proxy Deployments/Services/ServiceAccounts in any namespace. `ControllerNamespace` mode would render only a namespaced infra-manager Role (proxy creation limited to the controller namespace) — rejected for this reason.
- **Topology-injection webhook (chart render):** in `GatewayNamespace` mode with no `watch.namespaces` the MutatingWebhookConfiguration carries **no namespaceSelector** (cluster-wide; `failurePolicy: Ignore`) — proxy pods in every tenant namespace get injected.
- **Scoping:** the only thing that previously limited the controller to one tenant was the custom `controllerName` (EnvoyGateway config + matching `GatewayClass`). Without it, and without a watch restriction, the controller serves every Gateway in the cluster by design.
- **Fixed resource names (chart templates):** the chart hardcodes the controller resources to `envoy-gateway` (Deployment/Service/ServiceAccount/certgen) regardless of release name, so one release in `envoy-gateway-system` cannot collide with tenant resources, and the `envoy-gateway` Service the webhook clientConfigs point at exists exactly once.
- **Agent Router:** `controller.watch.namespaces` empty is the chart default for watch-all; `--envoyGatewayNamespace` only locates the Envoy Gateway controller (RBAC/certs), which now runs in `envoy-gateway-system`.

## Consequences

- **Shared blast radius:** one control-plane failure (or rolling update) temporarily affects *all* tenants' Gateways (status programming, new route picks). Data plane keeps serving established traffic (Envoy is a push-based data plane; the proxies do not restart on controller updates). Mitigation: the controller runs with leader-election-ready chart defaults and is monitored by a single `ServiceMonitor`; accept the trade for a homelab.
- **Cluster-scoped RBAC:** the shared controller holds cluster-wide infra-write (pods/services/servicesaccounts/configmaps in any namespace) via `envoy-gateway-cluster-infra-manager`. Accepted: single trusted cluster, homelab trust model.
- **No per-tenant control-plane upgrade independence:** all tenants upgrade together with the one release.
- **Divergence from traefik:** traefik couples control and data plane in one pod per tenant; this design splits them (central stateless control plane, per-tenant data plane). Accepted explicitly — it is the Envoy Gateway model, and the per-tenant proxy preserves the data-plane isolation the traefik pattern provided.
- **Single-repo ownership:** both control-plane releases (and the Agent Router CRDs) live in this repo; `k8s-ai` keeps only its tenant routing resources (`AIGatewayRoute`, `MCPRoute`), which depend on the shared `envoy-crds` Kustomization. One repo = one upgrade/rollback unit for the whole control plane.
- **Cutover:** the controller release is uninstalled from its old location and reinstalled in `envoy-gateway-system` (Helm cannot move a release across namespaces); the `GatewayClass` rename (`envoy-internal` → `envoy`) re-attaches the Gateways. Both cause a short window of degraded programming (webhooks are `failurePolicy: Ignore`; proxies keep running). This repo's PR must land before (or together with) the k8s-ai PR, which prunes the old `ai`-namespace Agent Router release — merging k8s-ai first would uninstall it while no replacement exists.
- **Future tenants:** onboarding is a namespace + `Gateway` (class `envoy`) + `EnvoyProxy`; no new controller, webhook, or namespace for control plane.

## Alternatives considered

1. **One controller per tenant (previous LAB-385 design, traefik pattern).** Rejected: duplicated stateless control plane per tenant (pods, webhooks, certgen, metrics, upgrade surface) without additional isolation; two releases could not even share one namespace (fixed resource names, envoyproxy/gateway#1258), forcing a control-plane namespace per tenant.
2. **One controller with `deploy.type: ControllerNamespace`.** Rejected: all proxies would deploy into `envoy-gateway-system` — it breaks the per-tenant data-plane requirement (and the chart only grants namespaced infra RBAC in this mode).
3. **Per-tenant watch lists on the shared controller (`watch.namespaces`).** Rejected: it forces per-tenant Role/RoleBindings instead of the single cluster-scoped infra role and still requires per-tenant controller names to split the fleet — the opposite of the goal.
