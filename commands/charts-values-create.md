# Create Values File

Create a values file for a specific chart and context.

## Arguments

- `<chart>` - Chart name (must exist in forks/)
- `<context>` - Context name (must exist in configs/contexts/)

## Instructions

1. **Validate Prerequisites**:
   - Chart exists in `forks/<chart>`
   - Context exists in `configs/contexts/<context>.yaml`

2. **Check Existing Values**:
   - If `base.yaml` doesn't exist, suggest creating it first
   - If context values exist, warn about overwriting

3. **Analyze Chart**: Read the chart's default values
   ```bash
   cat forks/<chart>/values.yaml
   ```

4. **Generate Template**: Create values file with:
   - Common overrides commented out
   - Context-specific sections
   - References to base.yaml

5. **Write File**: Save to `configs/values/<chart>/<context>.yaml`

## Values File Structure

### Base Values (configs/values/<chart>/base.yaml)
```yaml
# Base values for <chart>
# These apply to all contexts

# Common configuration
commonLabels:
  managed-by: charts-repo

# Shared settings across environments
# (Add chart-specific common values)
```

### Context Values (configs/values/<chart>/<context>.yaml)
```yaml
# Values for <chart> in <context> context
# Inherits from: base.yaml

# Context-specific overrides
replicaCount: 1  # local: single replica

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

# Context: <context>
# Cluster: <cluster-from-context>
# Namespace: <namespace-from-context>
```

## Output Format

### Success
```
Created values file: configs/values/cert-manager/local.yaml

Values Structure:
  Base:    configs/values/cert-manager/base.yaml (exists)
  Context: configs/values/cert-manager/local.yaml (created)

Template includes:
  - Resource limits (development defaults)
  - Single replica configuration
  - Debug logging enabled

Next steps:
  1. Edit the values: configs/values/cert-manager/local.yaml
  2. Validate: /charts-values-validate cert-manager
  3. Compare contexts: /charts-values-diff cert-manager local prod
```

### Missing Base
```
Base values not found for cert-manager.

Creating base.yaml first is recommended for shared configuration.

Options:
  1. Create base.yaml and local.yaml (recommended)
  2. Create only local.yaml
```

## Error Handling

- **Chart not found**: "Chart 'xyz' not found. Available charts: cert-manager, ingress-nginx"
- **Context not found**: "Context 'xyz' not found. Create it with: /charts-context-create xyz"
- **Values exist**: "Values already exist. Overwrite? [y/N]"
