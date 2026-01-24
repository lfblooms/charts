# Create Values File

Create a values file for a specific chart and context.

## Arguments

- `<chart>` - Chart name (e.g., `infisical-standalone-postgres`)
- `<context>` - Context name (e.g., `local`, `cloud-prod`)

## Repository Structure

```
forks/<repo>/helm-charts/<chart>/values.yaml    # Default chart values
configs/values/<chart>/
├── base.yaml                                    # Shared values
└── <context>.yaml                               # Context-specific values
```

## Instructions

1. **Find the Chart**: Locate the chart in forks
   ```bash
   find forks -path "*/helm-charts/*" -name "Chart.yaml" | while read f; do
     if [ "$(yq '.name' $f)" = "<chart>" ]; then
       dirname "$f"
     fi
   done
   ```

2. **Validate Prerequisites**:
   - Chart exists in a fork
   - Context exists in `configs/contexts/<context>.yaml` (or create it)

3. **Check Existing Values**:
   - If `base.yaml` doesn't exist, create it first
   - If context values exist, warn about overwriting

4. **Analyze Chart**: Read the chart's default values
   ```bash
   cat forks/<repo>/helm-charts/<chart>/values.yaml
   ```

5. **Generate Template**: Create values file with context-specific settings

6. **Write File**: Save to `configs/values/<chart>/<context>.yaml`

## Values File Structure

### Base Values (configs/values/<chart>/base.yaml)
```yaml
# Base values for <chart>
# Shared across all contexts

# Common labels
commonLabels:
  managed-by: charts-repo

# Security defaults
podSecurityContext:
  fsGroup: 1000

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

### Context Values (configs/values/<chart>/<context>.yaml)
```yaml
# Values for <chart> in <context> context
# Layered on top of base.yaml

replicaCount: 1

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    memory: 512Mi
```

## Output Format

### Success
```
Created values file: configs/values/infisical-standalone-postgres/local.yaml

Values Structure:
  Base:    configs/values/infisical-standalone-postgres/base.yaml
  Context: configs/values/infisical-standalone-postgres/local.yaml

Chart location:
  forks/infisical/helm-charts/infisical-standalone-postgres

Next steps:
  1. Edit values: $EDITOR configs/values/infisical-standalone-postgres/local.yaml
  2. Install: make infisical-install
  3. Validate: /charts-values-validate infisical-standalone-postgres
```

### Missing Base
```
Base values not found for infisical-standalone-postgres.

Creating base.yaml first is recommended for shared configuration.

Options:
  1. Create base.yaml and local.yaml (recommended)
  2. Create only local.yaml
```

## Error Handling

- **Chart not found**: "Chart 'xyz' not found. Available charts: infisical-standalone-postgres, infisical-gateway"
- **Context not found**: "Context 'xyz' not found. Create it with: /charts-context-create xyz"
- **Values exist**: "Values already exist. Overwrite? [y/N]"
