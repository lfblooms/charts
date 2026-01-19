# Validate Chart Documentation

Validate that chart documentation is complete and up-to-date.

## Arguments

- `<chart>` - Chart name to validate (must exist in `forks/`)

## Instructions

### 1. Check Documentation Exists

```bash
# Required files
ls configs/values/<chart>/README.md
ls configs/values/<chart>/CONFIGURATION.md

# Optional files
ls configs/values/<chart>/EXAMPLES.md 2>/dev/null
```

### 2. Validate README.md

Check for required sections:
- [ ] Title and description
- [ ] Overview section
- [ ] Prerequisites section
- [ ] Installation section
- [ ] Configuration summary table
- [ ] Dependencies section (if chart has deps)
- [ ] Upgrading notes
- [ ] Uninstallation section

### 3. Validate CONFIGURATION.md

Compare documented values against actual values.yaml:

```bash
# Extract all value keys from values.yaml
yq eval '.. | path | join(".")' forks/<chart>/values.yaml | sort -u

# Compare with documented parameters in CONFIGURATION.md
```

Check for:
- [ ] All top-level values documented
- [ ] All nested values documented
- [ ] Types specified correctly
- [ ] Defaults match actual values.yaml
- [ ] Descriptions are meaningful

### 4. Check Version Sync

Verify documentation matches chart version:

```bash
# Get chart version
yq eval '.version' forks/<chart>/Chart.yaml
yq eval '.appVersion' forks/<chart>/Chart.yaml

# Check if mentioned in docs
grep -l "version" configs/values/<chart>/*.md
```

### 5. Validate Links

Check internal links work:
- [ ] Links to CONFIGURATION.md resolve
- [ ] Links to EXAMPLES.md resolve (if referenced)
- [ ] External links are valid

### 6. Check Examples

If EXAMPLES.md exists:
- [ ] YAML examples are valid syntax
- [ ] Examples use documented parameters
- [ ] Examples cover common use cases

## Output Format

### Validation Passed

```
Documentation Validation: <chart>
═══════════════════════════════════════════════════

Files Present:
  ✓ README.md
  ✓ CONFIGURATION.md
  ✓ EXAMPLES.md

README.md Sections:
  ✓ Title and description
  ✓ Overview
  ✓ Prerequisites
  ✓ Installation
  ✓ Configuration table
  ✓ Dependencies
  ✓ Upgrading
  ✓ Uninstallation

Configuration Coverage:
  ✓ 45/45 values documented (100%)

Version Sync:
  ✓ Chart version: 0.1.0
  ✓ App version: 0.151.0
  ✓ Docs updated for current version

Overall: PASSED
```

### Validation Failed

```
Documentation Validation: <chart>
═══════════════════════════════════════════════════

Files Present:
  ✓ README.md
  ✗ CONFIGURATION.md (missing)
  - EXAMPLES.md (optional, not present)

README.md Sections:
  ✓ Title and description
  ✓ Overview
  ✗ Prerequisites (missing)
  ✓ Installation
  ✗ Configuration table (incomplete)
  ✓ Dependencies
  ✗ Upgrading (missing)
  ✓ Uninstallation

Configuration Coverage:
  ! Cannot validate - CONFIGURATION.md missing

Issues Found:
  1. [ERROR] CONFIGURATION.md is missing
  2. [ERROR] README.md missing Prerequisites section
  3. [ERROR] README.md missing Upgrading section
  4. [WARN] Configuration table has 5 values, chart has 45

Recommendations:
  - Run /charts-docs-generate <chart> to create missing docs
  - Add Prerequisites section with Kubernetes/Helm versions
  - Document upgrade process between versions

Overall: FAILED (3 errors, 1 warning)
```

## Severity Levels

- **ERROR**: Missing required documentation
- **WARN**: Documentation exists but incomplete
- **INFO**: Suggestions for improvement
