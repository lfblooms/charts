# Charts Repository

This repository manages Helm chart forks as git submodules, custom charts, and publishes them to OCI registries. It also provides a mirroring system to pull upstream chart versions and their container images into a target OCI registry (DigitalOcean Container Registry).

## Repository Structure

```
charts/                              # github.com/lfblooms/charts
├── .claude/
│   ├── commands/                    # Claude slash commands
│   └── agents/                      # Claude agents for analysis
├── .claude-plugin/
│   └── plugin.json                  # Plugin manifest
├── forks/                           # Forked repositories (git submodules)
│   └── <repo>/                      # e.g., infisical (fork of Infisical/infisical)
│       └── helm-charts/             # Helm charts within the repo
│           └── <chart>/             # e.g., infisical-standalone-postgres
├── custom/                          # Original charts (not forked from upstream)
│   └── <chart>/                     # Self-contained Helm chart directory
├── configs/
│   ├── contexts/                    # Context definitions (local, cloud-prod)
│   │   └── <context>.yaml           # Context-specific settings
│   └── values/                      # Values per chart per context
│       └── <chart>/                 # e.g., infisical-standalone-postgres
│           ├── base.yaml            # Shared values across all contexts
│           └── <context>.yaml       # Context-specific overrides
├── registry/
│   ├── registries.yaml              # OCI registry definitions (used by push-chart.sh)
│   └── mirror.yaml                  # Mirror config: upstreams, versions, target (used by lazyoci mirror)
├── docker-compose.yaml              # Local CNCF Distribution registry
├── makefiles/                       # Chart-specific makefiles
│   └── <repo>.mk                    # e.g., infisical.mk
├── skills/                          # Domain knowledge references
└── scripts/
    ├── push-chart.sh                # Package + push chart to OCI registry
    ├── sync-upstream.sh             # Sync fork with upstream
    └── validate-values.sh           # Validate chart values
```

## Fork Naming Convention

Forks follow the pattern: `<Owner>.<repo>`
- Upstream: `https://github.com/Infisical/infisical`
- Fork: `https://github.com/lfblooms/Infisical.infisical`
- Submodule: `forks/infisical`

## Quick Reference

### Fork Management Commands
- `/charts-fork-add <upstream-url>` - Fork upstream repo, add as submodule
- `/charts-fork-list` - List all tracked forks with sync status
- `/charts-fork-sync <repo>` - Sync fork with upstream changes
- `/charts-fork-track [repo]` - Initialize submodule tracking

### Configuration Commands
- `/charts-context-create <name>` - Create deployment context
- `/charts-context-list` - List all contexts
- `/charts-values-create <chart> <ctx>` - Create values file
- `/charts-values-diff <chart> <c1> <c2>` - Diff between contexts
- `/charts-values-validate <chart>` - Validate against schema

### Documentation Commands
- `/charts-docs-generate <chart>` - Generate comprehensive documentation
- `/charts-docs-validate <chart>` - Validate documentation completeness

### Status
- `/charts-status` - Overall repository status

## Makefile Targets

Each fork has a makefile in `makefiles/<repo>.mk`:

```bash
make help                    # Show all targets

# Infisical example
make infisical-install       # Install to cluster
make infisical-uninstall     # Uninstall
make infisical-status        # Check status
make infisical-logs          # View logs
make infisical-port-forward  # Access locally

# OCI Registry & Publishing
make registry-start          # Start local OCI registry (Distribution)
make registry-stop           # Stop local OCI registry
make registry-list           # List charts in registry
make registry-clean          # Remove .packages/ artifacts

make infisical-package       # Package chart only
make infisical-push          # Package + push to registry (REGISTRY=local)
make push-all REGISTRY=local # Push all charts to a registry
make package-all             # Package all charts

# Mirroring (Upstream → DOCR, powered by lazyoci mirror)
make vault-mirror                              # Mirror versions from registry/mirror.yaml
make vault-mirror VERSION=0.28.0               # Override with specific version
make mirror-all                                # Mirror all charts to DOCR
make vault-images                              # List container images in chart
```

## Workflows

### Adding a New Chart Fork

1. Run `/charts-fork-add <upstream-url>`
   - Forks repo to lfblooms/<Owner>.<repo>
   - Adds as submodule at forks/<repo>
   - Configures upstream remote
2. Create makefile: `makefiles/<repo>.mk`
3. Create context: `/charts-context-create local`
4. Create values: `/charts-values-create <chart> local`

### Adding a Custom Chart

1. Create chart directory: `custom/<chart>/`
2. Add `Chart.yaml`, `values.yaml`, `templates/` as standard Helm chart
3. Create makefile: `makefiles/<chart>.mk` with `-package` and `-push` targets
4. Custom charts use `push-chart.sh` directly (no upstream mirroring)

### Syncing with Upstream

1. Check status: `/charts-fork-list`
2. Analyze changes with `fork-analyzer` agent
3. Sync: `/charts-fork-sync <repo>`
4. Update chart deps: `make <repo>-deps`
5. Validate: `/charts-values-validate <chart>`

### Publishing Charts to OCI Registries

1. Start local registry: `make registry-start`
2. Package and push a chart: `make <chart>-push REGISTRY=local`
3. Push to DOCR: `make <chart>-push REGISTRY=docr`
4. Push all charts: `make push-all REGISTRY=local`
5. Verify: `make registry-list REGISTRY=local`

Registry definitions in `registry/registries.yaml`:
```yaml
registries:
  local:
    url: localhost:5000
    plain-http: true
    charts-prefix: charts
  docr:
    url: registry.digitalocean.com/greenforests
    plain-http: false
    charts-prefix: charts
```

### Mirroring Upstream Charts + Images to DOCR

The mirroring system uses `lazyoci mirror` to pull chart versions from upstream
sources and copy both chart OCI artifacts and container images to a target
registry (DOCR).

**Configuration:** `registry/mirror.yaml` — unified config defining upstream
chart sources (with source types and version lists) and the target registry.

**Source types:**
- `repo` — traditional Helm repository (e.g., `https://charts.jetstack.io`)
- `oci` — OCI registry (e.g., `oci://registry-1.docker.io/bitnamicharts`)
- `local` — built from fork source (e.g., `forks/infisical/helm-charts/...`)

**Usage:**
```bash
# Authenticate to DOCR (valid 30 days)
doctl registry login

# Mirror a single chart (reads versions from registry/mirror.yaml)
make vault-mirror

# Override with specific version
make vault-mirror VERSION=0.28.0

# Mirror multiple specific versions
lazyoci mirror --config registry/mirror.yaml --chart vault --version 0.28.0 --version 0.29.0

# Dry run (preview what would be mirrored)
lazyoci mirror --config registry/mirror.yaml --chart vault --dry-run

# Mirror charts only (no images)
lazyoci mirror --config registry/mirror.yaml --chart vault --charts-only

# Mirror images only (no chart push)
lazyoci mirror --config registry/mirror.yaml --chart vault --images-only

# Mirror all charts defined in mirror.yaml
make mirror-all

# List images in a chart
make vault-images

# JSON output for scripting
lazyoci mirror --config registry/mirror.yaml --all -o json
```

**Image path mapping:**
Images are mirrored with a flat path — the source registry host is stripped and
the remaining path is preserved under the target registry:
```
ghcr.io/stakater/reloader:v1.2.1
  → registry.digitalocean.com/greenforests/stakater/reloader:v1.2.1

docker.io/library/busybox:1.28
  → registry.digitalocean.com/greenforests/library/busybox:1.28
```

**Skip-if-exists:** Both chart and image pushes check if the artifact already
exists in the target registry before pushing. Safe to run repeatedly.

**Dependencies:** `helm`, `lazyoci`, `jq`

### Managing Configurations

- **Base values** (`configs/values/<chart>/base.yaml`): Shared across all contexts
- **Context values** (`configs/values/<chart>/<context>.yaml`): Environment-specific
- Values merged: base.yaml + <context>.yaml

## Agents

- **fork-analyzer**: Analyze fork divergence, conflicts, upgrade paths
- **config-reviewer**: Review values for security and best practices
- **upstream-tracker**: Monitor upstream for updates, security patches
- **docs-generator**: Generate comprehensive documentation

## Best Practices

1. Always create `base.yaml` before context-specific values
2. Keep sensitive values out of version control (use external secrets)
3. Regularly sync forks with upstream for security patches
4. Use `config-reviewer` agent before production deployments
5. Document customizations in fork commits for upgrade tracking
6. Run `doctl registry login` before mirroring to DOCR
7. Use `--dry-run` to preview mirror operations before executing
8. Custom charts go in `custom/`, forked charts go in `forks/`
