# Charts Repository

This repository manages Helm chart forks as git submodules with multi-context configuration support.

## Repository Structure

```
charts/
├── .claude/
│   ├── commands/                # Claude slash commands
│   └── agents/                  # Claude agents for analysis
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── forks/                       # Forked repositories (git submodules)
│   └── <repo>/                  # e.g., infisical (fork of Infisical/infisical)
│       └── helm-charts/         # Helm charts within the repo
│           └── <chart>/         # e.g., infisical-standalone-postgres
├── configs/
│   ├── contexts/                # Context definitions (local, cloud-prod)
│   │   └── <context>.yaml       # Context-specific settings
│   └── values/                  # Values per chart per context
│       └── <chart>/             # e.g., infisical-standalone-postgres
│           ├── base.yaml        # Shared values across all contexts
│           └── <context>.yaml   # Context-specific overrides
├── makefiles/                   # Chart-specific makefiles
│   └── <repo>.mk                # e.g., infisical.mk
├── skills/                      # Domain knowledge references
└── scripts/                     # Helper scripts
```

## Fork Naming Convention

Forks follow the pattern: `<Owner>.<repo>`
- Upstream: `https://github.com/Infisical/infisical`
- Fork: `https://github.com/MisterGrinvalds/Infisical.infisical`
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
```

## Workflows

### Adding a New Chart Fork

1. Run `/charts-fork-add <upstream-url>`
   - Forks repo to MisterGrinvalds/<Owner>.<repo>
   - Adds as submodule at forks/<repo>
   - Configures upstream remote
2. Create makefile: `makefiles/<repo>.mk`
3. Create context: `/charts-context-create local`
4. Create values: `/charts-values-create <chart> local`

### Syncing with Upstream

1. Check status: `/charts-fork-list`
2. Analyze changes with `fork-analyzer` agent
3. Sync: `/charts-fork-sync <repo>`
4. Update chart deps: `make <repo>-deps`
5. Validate: `/charts-values-validate <chart>`

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
