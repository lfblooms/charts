# Upstream Tracker Agent

Monitor upstream repositories for updates, security patches, and new releases.

## Purpose

This agent monitors upstream chart repositories to:
- Track new releases and versions
- Identify security patches and CVEs
- Alert on breaking changes
- Recommend update priorities

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
cd forks/<chart>
git fetch upstream --tags

# Latest upstream tag
git describe --tags --abbrev=0 upstream/main

# Current fork version
git describe --tags --abbrev=0 HEAD

# Tags between current and latest
git tag --sort=-version:refname | head -10
```

### 2. Analyze Releases

For each new release:
- Parse release notes
- Check for security fixes
- Identify breaking changes
- Note new features

### 3. Generate Priority Report

## Output Format

### Upstream Status Report

```
Upstream Tracker Report
Generated: 2024-01-15 10:30 UTC
═══════════════════════════════════════════════════════════════

SUMMARY
───────────────────────────────────────────────────────────────

| Chart          | Current | Latest  | Behind | Priority |
|----------------|---------|---------|--------|----------|
| cert-manager   | v1.13.0 | v1.14.2 | 3      | HIGH     |
| ingress-nginx  | v4.8.0  | v4.9.1  | 2      | MEDIUM   |
| external-dns   | v1.13.0 | v1.13.1 | 1      | LOW      |

Total: 3 charts, 2 need attention

═══════════════════════════════════════════════════════════════
CERT-MANAGER - Priority: HIGH
═══════════════════════════════════════════════════════════════

Current: v1.13.0
Latest:  v1.14.2
Releases behind: 3 (v1.13.1, v1.14.0, v1.14.1, v1.14.2)

🔴 SECURITY ALERT
   CVE-2024-1234: Certificate validation bypass
   Fixed in: v1.13.1
   Severity: HIGH
   Action: Immediate update recommended

📦 New Releases:

v1.14.2 (2024-01-10) - Patch
  - Fix: Memory leak in webhook
  - Fix: Race condition in ACME solver

v1.14.1 (2024-01-05) - Patch
  - Fix: Certificate renewal timing

v1.14.0 (2024-01-01) - Minor
  ⚠️ BREAKING: Removed deprecated --leader-elect flag
  ⚠️ BREAKING: Minimum Kubernetes version now 1.25
  - Feature: ACME external account binding
  - Feature: Improved DNS01 solvers
  - Improvement: 30% memory reduction

v1.13.1 (2023-12-15) - Security Patch
  🔴 Security: CVE-2024-1234 fix
  - Fix: Certificate validation

Upgrade Path Recommendation:
  1. v1.13.0 -> v1.13.1 (security fix, minimal changes)
  2. v1.13.1 -> v1.14.2 (feature update, review breaking changes)

═══════════════════════════════════════════════════════════════
INGRESS-NGINX - Priority: MEDIUM
═══════════════════════════════════════════════════════════════

Current: v4.8.0
Latest:  v4.9.1
Releases behind: 2 (v4.9.0, v4.9.1)

📦 New Releases:

v4.9.1 (2024-01-08) - Patch
  - Fix: WebSocket connection handling
  - Fix: Header size limits

v4.9.0 (2024-01-02) - Minor
  - Feature: OpenTelemetry support
  - Feature: Custom error pages
  - Improvement: Better gRPC support

No breaking changes detected.
No security issues identified.

Recommendation: Update at convenience

═══════════════════════════════════════════════════════════════
EXTERNAL-DNS - Priority: LOW
═══════════════════════════════════════════════════════════════

Current: v1.13.0
Latest:  v1.13.1
Releases behind: 1

📦 New Releases:

v1.13.1 (2024-01-03) - Patch
  - Fix: AWS Route53 pagination
  - Docs: Updated examples

No breaking changes detected.
No security issues identified.

Recommendation: Update at convenience

═══════════════════════════════════════════════════════════════
ACTION ITEMS
═══════════════════════════════════════════════════════════════

Immediate (Security):
  1. Update cert-manager to v1.13.1 minimum (CVE-2024-1234)

This Week:
  2. Plan cert-manager v1.14.x upgrade
     - Review breaking changes
     - Test in local environment
     - Update values if needed

When Convenient:
  3. Update ingress-nginx to v4.9.1
  4. Update external-dns to v1.13.1

═══════════════════════════════════════════════════════════════
NEXT CHECK
═══════════════════════════════════════════════════════════════

Schedule: Weekly on Monday
Last check: 2024-01-15
Next check: 2024-01-22
```

## Alert Levels

- **CRITICAL**: Active security vulnerability, immediate action required
- **HIGH**: Security patch available, update within days
- **MEDIUM**: New features or improvements, update within weeks
- **LOW**: Minor patches, update at convenience

## Data Sources

- GitHub releases API
- Git tags and commits
- Release notes (CHANGELOG.md, releases page)
- Security advisories (GitHub Security, CVE databases)

## Invocation Examples

- "Check for upstream updates"
- "Are there any security patches needed?"
- "What's new in cert-manager upstream?"
- "Show update priority for all charts"

## Related Commands

- `/charts-fork-sync <chart>` - Sync with upstream after review
- `/charts-fork-list` - Current fork status
