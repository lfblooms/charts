# Generate Chart Documentation

Generate comprehensive documentation for a forked Helm chart.

## Arguments

- `<chart>` - Chart name to document (must exist in `forks/`)

## Instructions

### 1. Analyze the Chart

Read and analyze the following files:

```bash
# Chart metadata
cat forks/<chart>/Chart.yaml

# Default values with comments
cat forks/<chart>/values.yaml

# Check for existing README
cat forks/<chart>/README.md 2>/dev/null

# List all templates
ls forks/<chart>/templates/

# Check dependencies
cat forks/<chart>/Chart.lock 2>/dev/null
```

### 2. Create Documentation Structure

Create documentation in `configs/values/<chart>/`:

```
configs/values/<chart>/
├── README.md           # Main documentation
├── CONFIGURATION.md    # Detailed values reference
└── EXAMPLES.md         # Usage examples
```

### 3. Generate README.md

Include these sections:

```markdown
# <Chart Name>

<Description from Chart.yaml>

## Overview

<Brief explanation of what this chart deploys and its purpose>

## Prerequisites

- Kubernetes 1.x+
- Helm 3.x+
- <Any specific requirements>

## Installation

### Quick Start

\`\`\`bash
# Add values configuration
/charts-values-create <chart> local

# Install
helm install <release> forks/<chart> -f configs/values/<chart>/base.yaml
\`\`\`

### Production

\`\`\`bash
helm install <release> forks/<chart> \
  -f configs/values/<chart>/base.yaml \
  -f configs/values/<chart>/cloud-prod.yaml \
  -n <namespace>
\`\`\`

## Configuration

See [CONFIGURATION.md](CONFIGURATION.md) for detailed values reference.

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| ... | ... | ... |

## Dependencies

| Chart | Version | Condition |
|-------|---------|-----------|
| ... | ... | ... |

## Upgrading

<Notes on upgrading between versions>

## Uninstallation

\`\`\`bash
helm uninstall <release> -n <namespace>
\`\`\`
```

### 4. Generate CONFIGURATION.md

Document every value in values.yaml:

```markdown
# Configuration Reference

Complete reference for all configuration options.

## Global

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|

## Image

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image.repository` | string | `"..."` | Container image repository |
| `image.tag` | string | `""` | Image tag (defaults to appVersion) |
| `image.pullPolicy` | string | `"IfNotPresent"` | Image pull policy |

## <Section>

...
```

### 5. Generate EXAMPLES.md

Create practical usage examples:

```markdown
# Usage Examples

## Local Development

\`\`\`yaml
# configs/values/<chart>/local.yaml
replicaCount: 1
resources:
  requests:
    cpu: 100m
    memory: 128Mi
\`\`\`

## Production with HA

\`\`\`yaml
# configs/values/<chart>/cloud-prod.yaml
replicaCount: 3
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
podDisruptionBudget:
  enabled: true
\`\`\`

## With External Database

\`\`\`yaml
postgresql:
  enabled: false
externalDatabase:
  uri: "postgres://..."
\`\`\`
```

## Output

After generating documentation, report:

```
Documentation generated for <chart>:

  configs/values/<chart>/
  ├── README.md ............ Overview and installation
  ├── CONFIGURATION.md ..... Values reference (X parameters)
  └── EXAMPLES.md .......... Usage examples (X scenarios)

Next steps:
  1. Review generated documentation
  2. Create base values: /charts-values-create <chart> base
  3. Create context values: /charts-values-create <chart> local
```

## Integration

Suggest using the `docs-generator` agent for deeper analysis:
```
For comprehensive documentation with architecture diagrams:
  Use the docs-generator agent
```
