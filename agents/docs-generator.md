# Docs Generator Agent

Generate comprehensive documentation for forked Helm charts.

## Purpose

This agent analyzes Helm charts and generates thorough documentation including:
- Overview and architecture understanding
- Complete values reference
- Usage examples for different contexts
- Dependency documentation
- Upgrade guides

## Capabilities

### Chart Analysis
- Parse Chart.yaml for metadata
- Analyze values.yaml structure and defaults
- Review templates to understand what gets deployed
- Identify dependencies and their configuration
- Check for schema files (values.schema.json)

### Documentation Generation
- Create structured README with all sections
- Generate complete CONFIGURATION.md with every value
- Create practical EXAMPLES.md for common scenarios
- Document context-specific configurations

### Research
- Fetch upstream documentation for context
- Research best practices for the application
- Identify security considerations
- Find common configuration patterns

## Workflow

### 1. Gather Chart Information

```bash
# Read chart metadata
cat forks/<chart>/Chart.yaml

# Read all values
cat forks/<chart>/values.yaml

# List what templates exist
ls -la forks/<chart>/templates/

# Check for schema
cat forks/<chart>/values.schema.json 2>/dev/null

# Read template helpers
cat forks/<chart>/templates/_helpers.tpl

# Check existing docs
cat forks/<chart>/README.md 2>/dev/null
```

### 2. Analyze Templates

Understand what Kubernetes resources are created:
- Deployments/StatefulSets
- Services
- Ingress
- ConfigMaps/Secrets
- RBAC resources
- Custom Resources

### 3. Research Application

If upstream URL is available:
- Fetch official documentation
- Understand application architecture
- Identify configuration best practices
- Note security considerations

### 4. Generate Documentation

Create three documentation files:

#### README.md Structure

```markdown
# <Chart Name>

> <Tagline from upstream or description>

## Overview

<What this chart deploys, architecture overview>

### Components

- **Component A**: Description
- **Component B**: Description

### Architecture

<Describe how components interact, data flow>

## Prerequisites

- Kubernetes X.X+
- Helm 3.X+
- PV provisioner (if persistence used)
- <Application-specific requirements>

## Installation

### Using this Repository

1. Create your values configuration:
   \`\`\`bash
   /charts-values-create <chart> local
   \`\`\`

2. Edit base values:
   \`\`\`bash
   $EDITOR configs/values/<chart>/base.yaml
   \`\`\`

3. Install:
   \`\`\`bash
   helm install <release> forks/<chart> \
     -f configs/values/<chart>/base.yaml \
     -f configs/values/<chart>/local.yaml \
     -n <namespace> --create-namespace
   \`\`\`

### Quick Start (Development)

\`\`\`bash
helm install <release> forks/<chart> -n <namespace> --create-namespace
\`\`\`

### Production Deployment

\`\`\`bash
# Create namespace
kubectl create namespace <namespace>

# Create required secrets
kubectl create secret generic <secret-name> \
  --from-literal=KEY=value \
  -n <namespace>

# Install with production values
helm install <release> forks/<chart> \
  -f configs/values/<chart>/base.yaml \
  -f configs/values/<chart>/cloud-prod.yaml \
  -n <namespace>
\`\`\`

## Configuration

See [CONFIGURATION.md](CONFIGURATION.md) for complete reference.

### Essential Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| ... | ... | ... |

### Secrets Management

<How to configure secrets, external secret options>

### Persistence

<Storage configuration if applicable>

### Networking

<Service types, ingress configuration>

## Dependencies

| Repository | Chart | Version | Purpose |
|------------|-------|---------|---------|
| bitnami | postgresql | 15.x | Database |
| ... | ... | ... | ... |

### Disabling Dependencies

<How to use external services instead>

## Upgrading

### From X.X to Y.Y

<Breaking changes, migration steps>

### General Upgrade Process

\`\`\`bash
# Backup database if applicable
# ...

# Update chart
helm upgrade <release> forks/<chart> \
  -f configs/values/<chart>/base.yaml \
  -f configs/values/<chart>/<context>.yaml \
  -n <namespace>
\`\`\`

## Troubleshooting

### Common Issues

**Issue**: Description
**Solution**: Steps to resolve

## Uninstallation

\`\`\`bash
helm uninstall <release> -n <namespace>

# Clean up PVCs if needed
kubectl delete pvc -l app.kubernetes.io/instance=<release> -n <namespace>
\`\`\`

## References

- [Official Documentation](<url>)
- [GitHub Repository](<url>)
```

#### CONFIGURATION.md Structure

Document EVERY value:

```markdown
# Configuration Reference

Complete reference for <chart> Helm chart values.

## Table of Contents

- [Global](#global)
- [Image](#image)
- [Deployment](#deployment)
- ...

---

## Global

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `replicaCount` | int | `1` | Number of pod replicas |
| `nameOverride` | string | `""` | Override chart name |
| `fullnameOverride` | string | `""` | Override full resource names |

## Image

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image.repository` | string | `"org/app"` | Container image repository |
| `image.tag` | string | `""` | Image tag (defaults to `.Chart.AppVersion`) |
| `image.pullPolicy` | string | `"IfNotPresent"` | Image pull policy |
| `imagePullSecrets` | list | `[]` | Image pull secrets |

## <Section>

<Description of this section>

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| ... | ... | ... | ... |

### Subsection

<Deeper configuration>

---

## Dependencies

### PostgreSQL

See [Bitnami PostgreSQL Chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `postgresql.enabled` | bool | `true` | Deploy PostgreSQL |
| ... | ... | ... | ... |
```

#### EXAMPLES.md Structure

```markdown
# Usage Examples

Practical configuration examples for different scenarios.

## Development / Local

Minimal resources, single replica, debug enabled.

\`\`\`yaml
# configs/values/<chart>/local.yaml
replicaCount: 1

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    memory: 512Mi

# Enable debug/development features
...
\`\`\`

## Staging

Production-like but with reduced resources.

\`\`\`yaml
# configs/values/<chart>/staging.yaml
replicaCount: 2

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
\`\`\`

## Production with High Availability

\`\`\`yaml
# configs/values/<chart>/cloud-prod.yaml
replicaCount: 3

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi

podDisruptionBudget:
  enabled: true
  minAvailable: 2

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: <chart>
          topologyKey: kubernetes.io/hostname
\`\`\`

## With External Database

\`\`\`yaml
# Disable bundled database
postgresql:
  enabled: false

# Configure external database
externalDatabase:
  host: "db.example.com"
  port: 5432
  database: "appdb"
  existingSecret: "db-credentials"
\`\`\`

## With Ingress and TLS

\`\`\`yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
\`\`\`

## Air-gapped / Private Registry

\`\`\`yaml
image:
  repository: registry.internal/org/app
  pullPolicy: Always

imagePullSecrets:
  - name: registry-credentials
\`\`\`
```

## Output Format

After generating documentation:

```
Documentation Generated: <chart>
═══════════════════════════════════════════════════════════════

Created Files:
  configs/values/<chart>/
  ├── README.md .............. Overview, installation, usage
  │   └── Sections: 12 (Overview, Prerequisites, Installation,
  │       Configuration, Dependencies, Upgrading, Troubleshooting,
  │       Uninstallation, References)
  ├── CONFIGURATION.md ....... Complete values reference
  │   └── Parameters: 47 documented across 8 sections
  └── EXAMPLES.md ............ Usage examples
      └── Scenarios: 6 (Local, Staging, Production HA,
          External DB, Ingress/TLS, Air-gapped)

Chart Analysis:
  - Templates: 9 (deployment, service, ingress, ...)
  - Dependencies: 2 (postgresql, redis)
  - Values depth: 4 levels max
  - Secrets required: 3

Validation:
  ✓ All values documented
  ✓ All sections present
  ✓ YAML examples valid

Next Steps:
  1. Review generated documentation
  2. Add application-specific details
  3. Create base.yaml: /charts-values-create <chart> base
  4. Validate: /charts-docs-validate <chart>
```

## Invocation Examples

- "Document the infisical chart"
- "Generate docs for cert-manager"
- "Create comprehensive documentation for ingress-nginx"
- "Analyze and document the external-dns fork"
