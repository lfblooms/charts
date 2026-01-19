# Fork Analyzer Agent

Analyze fork divergence, conflicts, and upgrade paths for Helm chart forks.

## Purpose

This agent performs deep analysis of chart forks to help with:
- Understanding divergence from upstream
- Identifying potential merge conflicts
- Planning upgrade paths
- Documenting local customizations

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
cd forks/<chart>
git fetch upstream

# Commits behind
git rev-list --count HEAD..upstream/main

# Commits ahead (local customizations)
git rev-list --count upstream/main..HEAD

# Modified files
git diff --name-only upstream/main

# Detailed diff stats
git diff --stat upstream/main
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
git diff --name-only HEAD...upstream/main
```

### 4. Generate Report

## Output Format

### Fork Analysis Report

```
Fork Analysis: cert-manager
═══════════════════════════════════════════════════════════════

Upstream: https://github.com/cert-manager/cert-manager
Fork:     https://github.com/MisterGrinvalds/cert-manager
Branch:   main

Divergence Summary:
  Upstream version: v1.14.0
  Fork version:     v1.13.0 + 5 local commits
  Commits behind:   47
  Commits ahead:    5

───────────────────────────────────────────────────────────────
LOCAL CUSTOMIZATIONS (5 commits)
───────────────────────────────────────────────────────────────

1. abc1234 - Add custom resource limits for local dev
   Files: values.yaml

2. def5678 - Add prometheus servicemonitor
   Files: templates/servicemonitor.yaml (new)

3. ghi9012 - Customize webhook configuration
   Files: templates/webhook-deployment.yaml

4. jkl3456 - Add node selector for arm64
   Files: values.yaml, templates/_helpers.tpl

5. mno7890 - Update default replicas
   Files: values.yaml

───────────────────────────────────────────────────────────────
UPSTREAM CHANGES (47 commits since fork)
───────────────────────────────────────────────────────────────

Breaking Changes:
  - [BREAKING] Webhook now requires cert-manager.io/v1 API
  - [BREAKING] Removed deprecated --leader-elect flag

Notable Updates:
  - Security fix: CVE-2024-xxxx patched
  - New feature: ACME external account binding
  - Performance: Reduced memory usage by 30%

Modified Files:
  templates/   15 files changed
  values.yaml  1 file changed
  Chart.yaml   1 file changed

───────────────────────────────────────────────────────────────
CONFLICT ANALYSIS
───────────────────────────────────────────────────────────────

High Risk (likely conflicts):
  - values.yaml
    Local: Added custom resources section
    Upstream: Restructured resources section
    Recommendation: Manual merge required

Medium Risk (review needed):
  - templates/webhook-deployment.yaml
    Local: Added custom annotations
    Upstream: Updated container spec
    Recommendation: May merge cleanly, verify result

Low Risk (should merge cleanly):
  - templates/servicemonitor.yaml
    Local: New file (addition)
    Recommendation: Will preserve local addition

───────────────────────────────────────────────────────────────
UPGRADE RECOMMENDATION
───────────────────────────────────────────────────────────────

Recommended approach: Incremental merge

Steps:
1. Backup current fork state
2. Merge upstream/main with --no-commit
3. Resolve conflicts in values.yaml manually
4. Test helm template output
5. Run /charts-values-validate cert-manager
6. Commit merge

Estimated effort: Medium (1-2 conflicts to resolve)

Alternative: Rebase (cleaner history, but rewrites local commits)
```

## Invocation Examples

- "Analyze the cert-manager fork"
- "What customizations do we have in ingress-nginx?"
- "Can I safely merge upstream changes?"
- "Plan an upgrade from v1.13 to v1.14"

## Related Commands

- `/charts-fork-sync <chart>` - Execute the sync after analysis
- `/charts-fork-list` - See all forks and their status
- `/charts-values-validate <chart>` - Validate after merge
