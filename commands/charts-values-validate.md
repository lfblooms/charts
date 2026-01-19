# Validate Values

Validate values files against the chart's JSON schema and best practices.

## Arguments

- `<chart>` - Chart name to validate

## Instructions

1. **Find Schema**: Look for values schema in the chart
   ```bash
   ls forks/<chart>/values.schema.json 2>/dev/null
   ```

2. **Gather Values Files**: List all values for this chart
   ```bash
   ls configs/values/<chart>/*.yaml
   ```

3. **Validate Each File**:
   - Schema validation (if schema exists)
   - YAML syntax validation
   - Best practice checks

4. **Merge Validation**: Test base + context merges
   ```bash
   yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
     configs/values/<chart>/base.yaml \
     configs/values/<chart>/<context>.yaml
   ```

5. **Helm Template Test**: Optionally test with helm
   ```bash
   helm template test forks/<chart> -f configs/values/<chart>/base.yaml -f configs/values/<chart>/<context>.yaml
   ```

## Validation Checks

### Schema Validation
- Required fields present
- Types match schema
- Enum values valid
- No unknown properties (if additionalProperties: false)

### Best Practice Checks
- Resource requests/limits defined
- No hardcoded secrets
- Appropriate replica counts per context
- Labels follow conventions
- Image tags are pinned (not :latest in prod)

### Security Checks
- No privileged containers without justification
- Security contexts defined
- Network policies considered
- RBAC follows least privilege

## Output Format

### Validation Report
```
Values Validation: cert-manager

Files Validated:
  - base.yaml ........... PASS
  - local.yaml .......... PASS (2 warnings)
  - cloud-prod.yaml ..... PASS

Warnings:

local.yaml:
  [WARN] Line 15: resources.limits not defined
         Recommendation: Define resource limits for predictable behavior

  [WARN] Line 23: image.tag is 'latest'
         Recommendation: Pin to specific version for reproducibility

Best Practice Score: 85/100

Suggestions:
  1. Add resource limits to local.yaml
  2. Pin image versions in development environments
  3. Consider adding podDisruptionBudget for cloud-prod
```

### Validation Failure
```
Values Validation: cert-manager

Files Validated:
  - base.yaml ........... PASS
  - local.yaml .......... FAIL

Errors:

local.yaml:
  [ERROR] Line 8: Invalid YAML syntax
          Expected mapping, found scalar

  [ERROR] Schema validation failed
          - replicaCount: expected integer, got string "one"
          - resources.requests.cpu: invalid format "lots"

Fix these errors before deployment.
```

## Schema Not Found

If no schema exists:
```
No values.schema.json found for cert-manager.

Performing basic validation:
  - YAML syntax: PASS
  - Best practices: See warnings below
  - Merge test: PASS

Consider adding a schema to the chart for stricter validation.
```

## Integration with Agents

Suggest using the `config-reviewer` agent for deeper analysis:
```
For comprehensive security and best practice review:
  Use the config-reviewer agent
```
