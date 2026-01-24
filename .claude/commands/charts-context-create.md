# Create Deployment Context

Create a new deployment context definition.

## Arguments

- `<name>` - Context name (e.g., `local`, `staging`, `cloud-prod`)

## Instructions

1. **Check Existing**: Verify context doesn't already exist
   ```bash
   ls configs/contexts/<name>.yaml 2>/dev/null
   ```

2. **Gather Information**: Prompt for context details
   - Description
   - Kubernetes cluster name
   - Default namespace
   - Any special requirements

3. **Create Context File**: Write to `configs/contexts/<name>.yaml`

4. **Update Documentation**: Add to CLAUDE.md if needed

## Context File Structure

```yaml
# configs/contexts/<name>.yaml
name: <name>
description: <description>
cluster: <cluster-name>
namespace: <namespace>

# Optional settings
defaults:
  storageClass: standard
  ingressClass: nginx

# Environment-specific notes
notes: |
  - Use make <repo>-install for deployment
  - Values layered: base.yaml + <name>.yaml
```

## Standard Contexts

### local
```yaml
name: local
description: Local development environment
cluster: kind
namespace: default

defaults:
  storageClass: standard

notes: |
  - For KIND/minikube development
  - Single replicas, minimal resources
  - Port-forward for access
```

### staging
```yaml
name: staging
description: Staging environment for testing
cluster: gke-staging
namespace: staging

defaults:
  storageClass: standard-rwo
  ingressClass: nginx

notes: |
  - Production-like but reduced resources
  - Separate namespace per chart
```

### cloud-prod
```yaml
name: cloud-prod
description: Production environment
cluster: gke-prod
namespace: production

defaults:
  storageClass: premium-rwo
  ingressClass: nginx

notes: |
  - High availability configuration
  - External managed databases
  - Ingress with TLS
```

## Output Format

### Success
```
Created context: local
  File: configs/contexts/local.yaml

Context configuration:
  Cluster:   kind
  Namespace: default

Next steps:
  1. Create values for charts: /charts-values-create <chart> local
  2. Install chart: make <repo>-install
```

### Already Exists
```
Context 'local' already exists.

Current configuration:
  Cluster:   kind
  Namespace: default

Options:
  1. Edit existing: $EDITOR configs/contexts/local.yaml
  2. Overwrite (not recommended)
```

## Commands

```bash
# List contexts
ls configs/contexts/

# View context
cat configs/contexts/local.yaml
```
