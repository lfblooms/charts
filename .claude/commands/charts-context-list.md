# List Deployment Contexts

List all deployment contexts with their configurations.

## Instructions

1. **Find Contexts**: List all context files
   ```bash
   ls configs/contexts/*.yaml 2>/dev/null
   ```

2. **Parse Each Context**: Extract key information
   ```bash
   for f in configs/contexts/*.yaml; do
     yq '.name + ": " + .description + " (" + .cluster + ")"' "$f"
   done
   ```

3. **Show Values Coverage**: Which charts have values for each context

## Output Format

```
Deployment Contexts
===================

local
  Description: Local development environment
  Cluster:     kind
  Namespace:   default
  Charts with values:
    - infisical-standalone-postgres (base.yaml, local.yaml)

staging
  Description: Staging environment for testing
  Cluster:     gke-staging
  Namespace:   staging
  Charts with values:
    (none configured)

cloud-prod
  Description: Production environment
  Cluster:     gke-prod
  Namespace:   production
  Charts with values:
    - infisical-standalone-postgres (base.yaml, cloud-prod.yaml)

Summary:
  Contexts: 3
  Charts with full coverage: 1
```

## Empty State

```
No contexts defined.

Create a context:
  /charts-context-create local

Standard contexts:
  - local: KIND/minikube development
  - staging: Pre-production testing
  - cloud-prod: Production deployment
```

## Commands

```bash
# List context files
ls configs/contexts/

# View specific context
cat configs/contexts/local.yaml

# Find charts with values for a context
for chart in configs/values/*/; do
  if [ -f "$chart/local.yaml" ]; then
    basename "$chart"
  fi
done
```
