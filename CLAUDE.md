# Charts Repository

This repository manages Helm chart forks as git submodules with multi-context configuration support.

## Repository Structure

```
charts/
├── forks/                       # Forked chart submodules
│   └── <chart-name>/            # e.g., cert-manager, ingress-nginx
├── configs/
│   ├── contexts/                # Context definitions (local, cloud-dev, cloud-prod)
│   │   └── <context>.yaml       # Context-specific settings
│   └── values/                  # Values per chart per context
│       └── <chart-name>/
│           ├── base.yaml        # Shared values across all contexts
│           └── <context>.yaml   # Context-specific overrides
├── commands/                    # Claude slash commands
├── agents/                      # Claude agents for analysis
├── skills/                      # Domain knowledge references
└── scripts/                     # Helper scripts
```

## Quick Reference

### Fork Management Commands
- `/charts-fork-add <url>` - Fork upstream repo, add as submodule
- `/charts-fork-list` - List all tracked forks with sync status
- `/charts-fork-sync <chart>` - Sync fork with upstream changes
- `/charts-fork-track [chart]` - Initialize submodule tracking

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

## Workflows

### Adding a New Chart Fork

1. Fork the upstream repository on GitHub
2. Run `/charts-fork-add <your-fork-url>`
3. Create contexts if needed: `/charts-context-create local`
4. Create values: `/charts-values-create <chart> local`

### Syncing with Upstream

1. Check current status: `/charts-fork-list`
2. Sync changes: `/charts-fork-sync <chart>`
3. Review changes with the `fork-analyzer` agent
4. Validate values: `/charts-values-validate <chart>`

### Managing Configurations

- **Base values** (`configs/values/<chart>/base.yaml`): Shared across all contexts
- **Context values** (`configs/values/<chart>/<context>.yaml`): Environment-specific overrides
- Values are merged: base.yaml + <context>.yaml

## Context Definitions

Contexts define deployment environments. Each context file in `configs/contexts/` contains:

```yaml
name: local
description: Local development environment
cluster: minikube
namespace: default
```

## Agents

- **fork-analyzer**: Analyze fork divergence, conflicts, and upgrade paths
- **config-reviewer**: Review values for security and best practices
- **upstream-tracker**: Monitor upstream for updates and security patches
- **docs-generator**: Generate comprehensive documentation for charts

## Helper Scripts

- `scripts/sync-upstream.sh` - Sync all forks with upstream
- `scripts/validate-values.sh` - Validate all values files

## Best Practices

1. Always create a `base.yaml` before context-specific values
2. Keep sensitive values out of version control (use external secrets)
3. Regularly sync forks to stay current with upstream security patches
4. Use the `config-reviewer` agent before deploying to production
5. Document customizations in fork commits for upgrade tracking
