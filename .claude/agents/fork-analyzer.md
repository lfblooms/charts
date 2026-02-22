# Fork Analyzer Agent

Analyze fork divergence, conflicts, and upgrade paths for Helm chart forks.

## Purpose

This agent performs deep analysis of chart forks to help with:
- Understanding divergence from upstream
- Identifying potential merge conflicts
- Planning upgrade paths
- Documenting local customizations

## Repository Structure

```
forks/<repo>/                    # Git submodule (fork of upstream)
├── helm-charts/                 # Helm charts location
│   └── <chart-name>/            # Individual chart
└── ...                          # Other repo contents
```

## Capabilities

### Divergence Analysis
- Count commits ahead/behind upstream
- Identify modified files
- Categorize changes (config, templates, CRDs, etc.)
- Track breaking changes

### Conflict Detection
- Predict merge conflicts before they happen
- Identify overlapping modifications
- Suggest resolution strategies

### Upgrade Planning
- Analyze upstream release notes
- Identify breaking changes in upgrades
- Create step-by-step upgrade plans
- Suggest value migrations

## Analysis Workflow

### 1. Gather Information
```bash
# Get fork status
git -C forks/<repo> fetch upstream

# Commits behind
git -C forks/<repo> rev-list --count HEAD..upstream/main

# Commits ahead (local customizations)
git -C forks/<repo> rev-list --count upstream/main..HEAD

# Modified files
git -C forks/<repo> diff --name-only upstream/main

# Detailed diff stats
git -C forks/<repo> diff --stat upstream/main
```

### 2. Categorize Changes

Group changes by type:
- **Values**: Default configuration changes
- **Templates**: Kubernetes manifest templates
- **CRDs**: Custom Resource Definitions
- **Helpers**: Template helper functions
- **Chart metadata**: Chart.yaml, requirements.yaml
- **Documentation**: README, NOTES.txt

### 3. Identify Conflicts

Check for overlapping modifications:
```bash
# Files modified in both local and upstream
git -C forks/<repo> diff --name-only HEAD...upstream/main
```

### 4. Generate Report

## Output Format

### Fork Analysis Report

```
Fork Analysis: infisical
═══════════════════════════════════════════════════════════════

Repository: forks/infisical
  Origin:   https://github.com/lfblooms/Infisical.infisical
  Upstream: https://github.com/Infisical/infisical
  Branch:   main

Helm Charts:
  - helm-charts/infisical-standalone-postgres (v0.8.0)
  - helm-charts/infisical-gateway (v0.2.0)

Divergence Summary:
  Commits behind:   47
  Commits ahead:    5

───────────────────────────────────────────────────────────────
LOCAL CUSTOMIZATIONS (5 commits)
───────────────────────────────────────────────────────────────

1. abc1234 - Add custom resource limits for local dev
   Files: helm-charts/infisical-standalone-postgres/values.yaml

2. def5678 - Add prometheus servicemonitor
   Files: helm-charts/infisical-standalone-postgres/templates/servicemonitor.yaml (new)

───────────────────────────────────────────────────────────────
UPSTREAM CHANGES (47 commits since fork)
───────────────────────────────────────────────────────────────

Breaking Changes:
  - [BREAKING] Minimum Kubernetes version now 1.25

Notable Updates:
  - Security fix: CVE-2024-xxxx patched
  - New feature: External secrets support

───────────────────────────────────────────────────────────────
CONFLICT ANALYSIS
───────────────────────────────────────────────────────────────

High Risk (likely conflicts):
  - helm-charts/infisical-standalone-postgres/values.yaml
    Recommendation: Manual merge required

Low Risk (should merge cleanly):
  - helm-charts/infisical-standalone-postgres/templates/servicemonitor.yaml
    Recommendation: Will preserve local addition

───────────────────────────────────────────────────────────────
UPGRADE RECOMMENDATION
───────────────────────────────────────────────────────────────

Recommended approach: Incremental merge

Steps:
1. Backup current fork state
2. git -C forks/<repo> merge upstream/main --no-commit
3. Resolve conflicts manually
4. Test: make <repo>-lint
5. Commit merge
6. Update parent repo: git add forks/<repo> && git commit
```

## Invocation Examples

- "Analyze the infisical fork"
- "What customizations do we have?"
- "Can I safely merge upstream changes?"
- "Plan an upgrade path"

## Related Commands

- `/charts-fork-sync <repo>` - Execute the sync after analysis
- `/charts-fork-list` - See all forks and their status
