# Upstream Tracker Agent

Monitor upstream repositories for updates, security patches, and new releases.

## Purpose

This agent monitors upstream repositories to:
- Track new releases and versions
- Identify security patches and CVEs
- Alert on breaking changes
- Recommend update priorities

## Repository Structure

```
forks/<repo>/                    # Git submodule
├── .git                         # Submodule git
├── helm-charts/                 # Helm charts
│   └── <chart>/Chart.yaml       # Chart version info
└── ...
```

## Capabilities

### Release Monitoring
- Check for new upstream releases
- Compare versions across forks
- Track release frequency

### Security Tracking
- Identify security-related commits
- Check for CVE mentions
- Monitor security advisories

### Change Analysis
- Summarize release notes
- Identify breaking changes
- Highlight new features

## Monitoring Workflow

### 1. Check Upstream Status
```bash
git -C forks/<repo> fetch upstream --tags

# Latest upstream tag
git -C forks/<repo> describe --tags --abbrev=0 upstream/main

# Current fork version
git -C forks/<repo> describe --tags --abbrev=0 HEAD

# Recent tags
git -C forks/<repo> tag --sort=-version:refname | head -10
```

### 2. Check Chart Versions
```bash
# Current chart version
yq '.version' forks/<repo>/helm-charts/<chart>/Chart.yaml
yq '.appVersion' forks/<repo>/helm-charts/<chart>/Chart.yaml
```

### 3. Analyze Releases

For each new release:
- Parse release notes
- Check for security fixes
- Identify breaking changes
- Note new features

### 4. Generate Priority Report

## Output Format

### Upstream Status Report

```
Upstream Tracker Report
Generated: 2024-01-15 10:30 UTC
═══════════════════════════════════════════════════════════════

SUMMARY
───────────────────────────────────────────────────────────────

| Repo       | Chart                        | Current | Latest | Priority |
|------------|------------------------------|---------|--------|----------|
| infisical  | infisical-standalone-postgres| v0.8.0  | v0.9.2 | HIGH     |
| infisical  | infisical-gateway            | v0.2.0  | v0.2.1 | LOW      |

═══════════════════════════════════════════════════════════════
INFISICAL - Priority: HIGH
═══════════════════════════════════════════════════════════════

Repository: forks/infisical
  Origin:   lfblooms/Infisical.infisical
  Upstream: Infisical/infisical

Charts:
  infisical-standalone-postgres
    Current: v0.8.0
    Latest:  v0.9.2
    Releases behind: 3

🔴 SECURITY ALERT
   CVE-2024-xxxx: Authentication bypass
   Fixed in: v0.8.1
   Action: Immediate update recommended

📦 New Releases:

v0.9.2 (2024-01-10) - Patch
  - Fix: Memory leak in worker

v0.9.0 (2024-01-01) - Minor
  ⚠️ BREAKING: New secret format
  - Feature: External secrets support

v0.8.1 (2023-12-15) - Security Patch
  🔴 Security: CVE-2024-xxxx fix

Upgrade Path Recommendation:
  1. v0.8.0 -> v0.8.1 (security fix)
  2. v0.8.1 -> v0.9.2 (review breaking changes)

═══════════════════════════════════════════════════════════════
ACTION ITEMS
═══════════════════════════════════════════════════════════════

Immediate (Security):
  1. Sync infisical fork: /charts-fork-sync infisical

This Week:
  2. Plan v0.9.x upgrade
     - Review breaking changes
     - Update values if needed
```

## Alert Levels

- **CRITICAL**: Active security vulnerability
- **HIGH**: Security patch available
- **MEDIUM**: New features or improvements
- **LOW**: Minor patches

## Invocation Examples

- "Check for upstream updates"
- "Are there any security patches needed?"
- "What's new in infisical upstream?"

## Related Commands

- `/charts-fork-sync <repo>` - Sync with upstream
- `/charts-fork-list` - Current fork status
