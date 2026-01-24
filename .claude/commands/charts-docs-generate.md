# Generate Chart Documentation

Generate comprehensive documentation for a forked Helm chart.

## Arguments

- `<chart>` - Chart name to document (e.g., `infisical-standalone-postgres`)

## Instructions

### 1. Find the Chart

```bash
find forks -path "*/helm-charts/*" -name "Chart.yaml" | while read f; do
  if [ "$(yq '.name' $f)" = "<chart>" ]; then
    echo "$(dirname $f)"
  fi
done
```

### 2. Analyze the Chart

```bash
# Chart metadata
cat <chart-path>/Chart.yaml

# Default values
cat <chart-path>/values.yaml

# List templates
ls <chart-path>/templates/

# Check dependencies
cat <chart-path>/Chart.lock 2>/dev/null
```

### 3. Create Documentation Structure

```
configs/values/<chart>/
├── README.md           # Main documentation
├── CONFIGURATION.md    # Detailed values reference
└── EXAMPLES.md         # Usage examples
```

### 4. Generate README.md

Include sections:
- Overview and purpose
- Prerequisites
- Installation (using Makefile)
- Configuration summary
- Dependencies
- Upgrading notes
- Troubleshooting
- Uninstallation

### 5. Generate CONFIGURATION.md

Document every value in values.yaml:
- Parameter name
- Type
- Default value
- Description

### 6. Generate EXAMPLES.md

Create practical examples:
- Local development
- Staging
- Production with HA
- External database
- With Ingress/TLS

## Output Format

```
Documentation generated for infisical-standalone-postgres:

  configs/values/infisical-standalone-postgres/
  ├── README.md ............ Overview and installation
  ├── CONFIGURATION.md ..... Values reference (47 parameters)
  └── EXAMPLES.md .......... Usage examples (6 scenarios)

Chart location:
  forks/infisical/helm-charts/infisical-standalone-postgres

Next steps:
  1. Review generated documentation
  2. Create base values: /charts-values-create <chart> base
  3. Validate: /charts-docs-validate <chart>
```

## Integration

For deeper analysis, use the `docs-generator` agent.
