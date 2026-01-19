# List Deployment Contexts

List all configured deployment contexts.

## Instructions

1. **Scan Contexts Directory**: Read all YAML files in `configs/contexts/`
2. **Parse Each Context**: Extract key information
3. **Format Output**: Present as a table

## Commands to Execute

```bash
# List context files
ls configs/contexts/*.yaml 2>/dev/null

# For each file, extract name and description
for f in configs/contexts/*.yaml; do
  if [ -f "$f" ]; then
    yq -r '.name + "|" + .description + "|" + (.cluster // "not set")' "$f" 2>/dev/null
  fi
done
```

## Output Format

### With Contexts
```
Deployment Contexts:

| Context    | Description                     | Cluster          | Namespace  |
|------------|---------------------------------|------------------|------------|
| local      | Local development environment   | minikube         | default    |
| cloud-dev  | Development cloud environment   | dev-cluster-01   | dev        |
| cloud-prod | Production environment          | prod-cluster-01  | production |

Total: 3 contexts

Values Coverage:
  - cert-manager: local, cloud-prod
  - ingress-nginx: local, cloud-dev, cloud-prod
```

### Empty State
```
No contexts defined.

To create a context:
  /charts-context-create local

Common contexts:
  - local     (Local development)
  - dev       (Shared development)
  - staging   (Pre-production)
  - prod      (Production)
```

## Additional Information

For each context, also show:
- Number of charts with values for this context
- Last modified date
- Any validation warnings
