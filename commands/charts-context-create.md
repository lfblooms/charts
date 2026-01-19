# Create Deployment Context

Create a new deployment context definition for managing environment-specific configurations.

## Arguments

- `<name>` - Context name (required). Examples: local, cloud-dev, cloud-prod

## Instructions

1. **Validate Name**: Check context name is valid
   - Alphanumeric with hyphens only
   - Not already exists in `configs/contexts/`

2. **Gather Information**: Ask for context details
   - Description
   - Target cluster (optional)
   - Default namespace (optional)
   - Additional metadata

3. **Create Context File**: Write to `configs/contexts/<name>.yaml`

4. **Report Success**: Show next steps

## Context File Structure

```yaml
# configs/contexts/<name>.yaml
name: <name>
description: <user-provided description>
cluster: <optional cluster name>
namespace: <optional default namespace>
created: <timestamp>
metadata:
  # Additional context-specific settings
  environment: <development|staging|production>
```

## Example Contexts

### Local Development
```yaml
name: local
description: Local development environment using minikube
cluster: minikube
namespace: default
created: 2024-01-15T10:00:00Z
metadata:
  environment: development
  debug: true
```

### Cloud Production
```yaml
name: cloud-prod
description: Production cluster on cloud provider
cluster: prod-cluster-01
namespace: production
created: 2024-01-15T10:00:00Z
metadata:
  environment: production
  replicas: 3
  resources: high
```

## Output Format

### Success
```
Created context: local

File: configs/contexts/local.yaml

Context Details:
  Name:        local
  Description: Local development environment
  Cluster:     minikube
  Namespace:   default

Next steps:
  1. Create values for charts: /charts-values-create <chart> local
  2. List all contexts: /charts-context-list
```

### Already Exists
```
Context 'local' already exists.

To view: cat configs/contexts/local.yaml
To modify: Edit configs/contexts/local.yaml directly
```

## Common Contexts

Suggest these standard contexts if user is unsure:
- `local` - Local development (minikube, kind, docker-desktop)
- `dev` - Shared development environment
- `staging` - Pre-production testing
- `prod` - Production environment
