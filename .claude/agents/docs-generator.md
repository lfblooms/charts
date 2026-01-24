# Docs Generator Agent

Generate comprehensive documentation for forked Helm charts.

## Purpose

This agent analyzes Helm charts and generates thorough documentation including:
- Overview and architecture understanding
- Complete values reference
- Usage examples for different contexts
- Dependency documentation
- Upgrade guides

## Repository Structure

```
forks/<repo>/helm-charts/<chart>/     # Chart location
├── Chart.yaml                         # Metadata
├── values.yaml                        # Defaults
└── templates/                         # Templates

configs/values/<chart>/                # Documentation output
├── README.md                          # Overview
├── CONFIGURATION.md                   # Values reference
└── EXAMPLES.md                        # Usage examples
```

## Capabilities

### Chart Analysis
- Parse Chart.yaml for metadata
- Analyze values.yaml structure and defaults
- Review templates to understand what gets deployed
- Identify dependencies and their configuration

### Documentation Generation
- Create structured README with all sections
- Generate complete CONFIGURATION.md with every value
- Create practical EXAMPLES.md for common scenarios

### Research
- Fetch upstream documentation for context
- Research best practices for the application
- Identify security considerations

## Workflow

### 1. Find the Chart
```bash
find forks -path "*/helm-charts/*" -name "Chart.yaml" | while read f; do
  chart=$(yq '.name' "$f")
  echo "$chart: $(dirname $f)"
done
```

### 2. Gather Chart Information
```bash
# Chart metadata
cat <chart-path>/Chart.yaml

# Default values
cat <chart-path>/values.yaml

# Templates
ls <chart-path>/templates/

# Dependencies
cat <chart-path>/Chart.lock
```

### 3. Analyze Templates

Understand what Kubernetes resources are created:
- Deployments/StatefulSets
- Services
- Ingress
- ConfigMaps/Secrets
- RBAC resources

### 4. Generate Documentation

Create three files in `configs/values/<chart>/`:

#### README.md
- Overview and architecture
- Prerequisites
- Installation (using Makefile)
- Configuration summary
- Dependencies
- Upgrading
- Troubleshooting
- Uninstallation

#### CONFIGURATION.md
Document every value:
- Parameter name
- Type
- Default
- Description

#### EXAMPLES.md
- Local development
- Staging
- Production with HA
- External database
- With Ingress/TLS
- Air-gapped

## Output Format

```
Documentation Generated: infisical-standalone-postgres
═══════════════════════════════════════════════════════════════

Chart: forks/infisical/helm-charts/infisical-standalone-postgres

Created Files:
  configs/values/infisical-standalone-postgres/
  ├── README.md ............ Overview and installation
  ├── CONFIGURATION.md ..... Values reference (47 parameters)
  └── EXAMPLES.md .......... Usage examples (6 scenarios)

Chart Analysis:
  - Templates: 9
  - Dependencies: 3 (ingress-nginx, postgresql, redis)
  - Values depth: 4 levels

Next Steps:
  1. Review generated documentation
  2. Create base values: /charts-values-create <chart> base
  3. Validate: /charts-docs-validate <chart>
```

## Invocation Examples

- "Document infisical-standalone-postgres"
- "Generate docs for the infisical chart"
- "Create comprehensive documentation"
