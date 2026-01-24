# Validate Chart Documentation

Validate that chart documentation is complete and up-to-date.

## Arguments

- `<chart>` - Chart name to validate

## Instructions

### 1. Check Documentation Exists

```bash
ls configs/values/<chart>/README.md
ls configs/values/<chart>/CONFIGURATION.md
ls configs/values/<chart>/EXAMPLES.md 2>/dev/null  # optional
```

### 2. Find Chart Path

```bash
find forks -path "*/helm-charts/*" -name "Chart.yaml" | while read f; do
  if [ "$(yq '.name' $f)" = "<chart>" ]; then
    dirname "$f"
  fi
done
```

### 3. Validate README.md Sections

Check for required sections:
- [ ] Title and description
- [ ] Overview section
- [ ] Prerequisites section
- [ ] Installation section
- [ ] Configuration summary table
- [ ] Dependencies section (if chart has deps)
- [ ] Upgrading notes
- [ ] Uninstallation section

### 4. Validate CONFIGURATION.md

Compare documented values against actual values.yaml:
```bash
# Extract all value keys from chart
yq '.. | path | join(".")' <chart-path>/values.yaml | sort -u

# Compare with documented parameters
```

### 5. Check Version Sync

```bash
# Get chart version
yq '.version' <chart-path>/Chart.yaml
yq '.appVersion' <chart-path>/Chart.yaml
```

## Output Format

### Validation Passed

```
Documentation Validation: infisical-standalone-postgres
=======================================================

Chart: forks/infisical/helm-charts/infisical-standalone-postgres
Version: 0.8.0 (appVersion: 0.155.0)

Files Present:
  - README.md
  - CONFIGURATION.md
  - EXAMPLES.md

README.md Sections:
  - Title and description
  - Overview
  - Prerequisites
  - Installation
  - Configuration table
  - Dependencies
  - Upgrading
  - Uninstallation

Configuration Coverage:
  45/47 values documented (96%)
  Missing: extraEnv, extraVolumes

Overall: PASSED (2 minor gaps)
```

### Validation Failed

```
Documentation Validation: infisical-standalone-postgres
=======================================================

Files Present:
  - README.md
  - CONFIGURATION.md (missing)

Issues Found:
  1. [ERROR] CONFIGURATION.md is missing
  2. [ERROR] README.md missing Prerequisites section
  3. [WARN] Chart version changed since docs updated

Recommendations:
  - Run /charts-docs-generate <chart> to create missing docs
  - Update prerequisites for new dependencies

Overall: FAILED (2 errors, 1 warning)
```
