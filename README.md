# Charts

Helm chart management for the lfblooms infrastructure. Manages 20 upstream chart forks as git submodules and mirrors chart OCI artifacts + container images to DigitalOcean Container Registry (DOCR).

## What This Does

```
Upstream Helm repos          This repo              DOCR
─────────────────     ──────────────────     ──────────────────
charts.jetstack.io  ──►  forks/cert-manager  ──►  greenforests/charts/cert-manager:v1.16.1
helm.releases.      ──►  forks/vault-helm    ──►  greenforests/charts/vault:0.28.0
  hashicorp.com
ghcr.io/kyverno     ──►  (images mirrored)   ──►  greenforests/kyverno/kyverno:v1.13.2
docker.io/hashicorp ──►  (images mirrored)   ──►  greenforests/hashicorp/vault:1.16.1
```

**Three operations:**

1. **Fork management** — upstream Helm chart repos are forked to `lfblooms/<Owner>.<repo>` and tracked as git submodules under `forks/`
2. **Chart publishing** — charts are packaged and pushed as OCI artifacts to registries via `helm push`
3. **Mirroring** — chart versions and their container images are pulled from upstream and copied to DOCR so deployments don't depend on third-party registries

## Repository Structure

```
├── forks/                    # 20 upstream chart forks (git submodules)
├── makefiles/                # Per-chart Makefile includes (18 files)
├── registry/
│   ├── mirror.yaml           # Mirror config: upstreams, versions, DOCR target
│   └── registries.yaml       # OCI registry definitions (for push-chart.sh)
├── scripts/
│   ├── push-chart.sh         # Package + push chart to OCI registry
│   ├── sync-upstream.sh      # Sync forks with upstream
│   └── validate-values.sh    # Validate chart values
├── Makefile                  # Root makefile (includes makefiles/*.mk)
└── docker-compose.yaml       # Local CNCF Distribution registry (localhost:5000)
```

## Charts

26 charts across 20 forked repositories:

| Category | Chart | Source | Version |
|---|---|---|---|
| **GitOps** | argo-cd | argoproj/argo-helm | 7.6.8 |
| **Secrets** | cert-manager | cert-manager/cert-manager | v1.16.1 |
| | external-secrets | external-secrets/external-secrets | 0.10.5 |
| | vault | hashicorp/vault-helm | 0.28.0 |
| | vault-secrets-operator | hashicorp/vault-secrets-operator | 0.9.1 |
| **Networking** | ingress-nginx | kubernetes/ingress-nginx | 4.11.2 |
| | external-dns | kubernetes-sigs/external-dns | 1.15.0 |
| | tailscale-operator | tailscale/tailscale | 1.82.0 |
| **Service Mesh** | base, istiod, cni, gateway | istio/istio | 1.23.4 |
| **Observability** | grafana | grafana/helm-charts | 8.5.11 |
| | loki | grafana/helm-charts | 2.16.0 |
| | tempo | grafana/helm-charts | 1.24.4 |
| | mimir-distributed | grafana/helm-charts | 6.0.5 |
| | kube-prometheus-stack | prometheus-community/helm-charts | 82.2.0 |
| | prometheus | prometheus-community/helm-charts | 25.28.0 |
| **Security** | kyverno | kyverno/kyverno | 3.3.4 |
| | policy-reporter | kyverno/policy-reporter | 3.0.0 |
| | kiali-server | kiali/helm-charts | 2.4.0 |
| **Storage** | harbor | goharbor/harbor-helm | 1.16.2 |
| **Identity** | keycloak | bitnami (OCI) | 24.0.1 |
| **Config** | reloader | stakater/Reloader | 2.2.8 |
| **Local** | infisical-standalone | Infisical/infisical (fork) | 1.7.2 |
| | infisical-gateway | Infisical/infisical (fork) | 1.0.4 |

## Prerequisites

- [helm](https://helm.sh/docs/intro/install/)
- [lazyoci](https://github.com/mistergrinvalds/lazyoci) (mirror command)
- [jq](https://jqlang.github.io/jq/)
- [yq](https://github.com/mikefarah/yq) (used by push-chart.sh)
- [doctl](https://docs.digitalocean.com/reference/doctl/) (DOCR authentication)
- Docker (for local registry)

## Quick Start

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/lfblooms/charts.git
cd charts

# See all available targets
make help

# List images in a chart
make vault-images

# Mirror a chart + images to DOCR (requires doctl registry login)
make vault-mirror

# Mirror all charts
make mirror-all
```

## Makefile Targets

Each chart gets a set of targets defined in `makefiles/<repo>.mk`. The root `Makefile` includes all of them via `include makefiles/*.mk`.

### Per-Chart Targets

Using vault as an example:

```bash
# Cluster operations
make vault-install         # helm upgrade --install
make vault-uninstall       # helm uninstall
make vault-status          # helm status + pod list
make vault-logs            # kubectl logs -f
make vault-port-forward    # kubectl port-forward

# Chart operations
make vault-lint            # helm lint
make vault-template        # helm template (render locally)
make vault-deps            # helm dependency update
make vault-sync            # git fetch upstream + merge

# OCI packaging
make vault-package         # helm package → .packages/
make vault-push            # helm package + push to registry

# Mirroring
make vault-mirror          # Mirror chart + images to DOCR
make vault-mirror VERSION=0.29.0  # Override version
make vault-images          # List container images in chart
```

### Bulk Targets

```bash
make package-all           # Package all charts
make push-all REGISTRY=docr  # Push all charts to a registry
make mirror-all            # Mirror all charts + images to DOCR
```

### Registry Management

```bash
make registry-start        # Start local OCI registry (localhost:5000)
make registry-stop         # Stop local registry
make registry-list         # List charts in registry
make registry-clean        # Remove .packages/ directory
```

## Mirroring

Mirroring is powered by [`lazyoci mirror`](https://github.com/mistergrinvalds/lazyoci), which pulls chart OCI artifacts and their container images from upstream sources and copies them to DOCR. This eliminates runtime dependencies on third-party registries.

### Configuration

All mirroring is configured in `registry/mirror.yaml`:

```yaml
target:
  url: registry.digitalocean.com/greenforests
  charts-prefix: charts          # charts land at .../charts/<name>:<version>

upstreams:
  vault:
    type: repo                   # traditional Helm repository
    repo: https://helm.releases.hashicorp.com
    chart: vault
    versions: ["0.28.0"]

  keycloak:
    type: oci                    # OCI registry source
    registry: oci://registry-1.docker.io/bitnamicharts
    chart: keycloak
    versions: ["24.0.1"]

  infisical:
    type: local                  # built from fork source
    path: ../forks/infisical/helm-charts/infisical-standalone-postgres
    chart: infisical-standalone
    versions: ["1.7.2"]
```

Three source types:
- **`repo`** — traditional Helm repository with `index.yaml` (most charts)
- **`oci`** — OCI registry like Docker Hub (keycloak)
- **`local`** — chart directory on disk, packaged with `helm package` (infisical)

### Usage

```bash
# Authenticate to DOCR first (token valid 30 days)
doctl registry login

# Mirror a single chart
make vault-mirror

# Override version
make vault-mirror VERSION=0.29.0

# Mirror all charts
make mirror-all

# Direct lazyoci usage for more control
lazyoci mirror --config registry/mirror.yaml --chart vault --dry-run
lazyoci mirror --config registry/mirror.yaml --all --charts-only
lazyoci mirror --config registry/mirror.yaml --chart vault --images-only
lazyoci mirror --config registry/mirror.yaml --all -o json
```

### Image Path Mapping

Images are mirrored with a flat path — the source registry host is stripped:

```
ghcr.io/kyverno/kyverno:v1.13.2
  → registry.digitalocean.com/greenforests/kyverno/kyverno:v1.13.2

docker.io/hashicorp/vault:1.16.1
  → registry.digitalocean.com/greenforests/hashicorp/vault:1.16.1
```

Both chart and image pushes check if the artifact already exists before pushing. Safe to run repeatedly.

## Fork Management

Forks follow the naming pattern `<Owner>.<repo>`:

| Upstream | Fork | Submodule |
|---|---|---|
| `github.com/hashicorp/vault-helm` | `lfblooms/hashicorp.vault-helm` | `forks/vault-helm` |
| `github.com/Infisical/infisical` | `lfblooms/Infisical.infisical` | `forks/infisical` |

```bash
# Sync a fork with upstream
make vault-sync

# Sync all forks
./scripts/sync-upstream.sh

# Dry run
./scripts/sync-upstream.sh --dry-run
```

## Publishing Charts

Separate from mirroring, charts can be packaged from fork source and pushed to any OCI registry defined in `registry/registries.yaml`:

```bash
# Package only
make vault-package

# Package + push to DOCR
make vault-push REGISTRY=docr

# Push all charts
make push-all REGISTRY=docr
```

## Local Development

A local OCI registry (CNCF Distribution v3) is available for testing:

```bash
make registry-start          # Starts localhost:5000
make vault-push REGISTRY=local
make registry-list REGISTRY=local
make registry-stop
```

Requires uncommenting the `local` entry in `registry/registries.yaml`.
