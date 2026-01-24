# Validate Values

Validate values files against the chart's JSON schema and best practices.

## Arguments

- `<chart>` - Chart name to validate (e.g., `infisical-standalone-postgres`)

## Instructions

1. **Find Chart**: Locate the chart in forks
   ```bash
   find forks -path "*/helm-charts/*" -name "Chart.yaml" | while read f; do
     if [ "$(yq '.name' $f)" = "<chart>" ]; then
       dirname "$f"
     fi
   done
   ```

2. **Find Schema**: Look for values schema in the chart
   ```bash
   ls <chart-path>/values.schema.json 2>/dev/null
   ```

3. **Gather Values Files**: List all values for this chart
   ```bash
   ls configs/values/<chart>/*.yaml
   ```

4. **Validate Each File**:
   - YAML syntax validation
   - Schema validation (if schema exists)
   - Best practice checks

5. **Merge Validation**: Test base + context merges
   ```bash
   helm template test <chart-path> \
     -f configs/values/<chart>/base.yaml \
     -f configs/values/<chart>/<context>.yaml
   ```

## Validation Checks

### Schema Validation
- Required fields present
- Types match schema
- Enum values valid

### Best Practice Checks
- Resource requests/limits defined
- No hardcoded secrets
- Image tags are pinned (not :latest in prod)

### Security Checks
- No privileged containers without justification
- Security contexts defined
- RBAC follows least privilege

## Output Format

### Validation Passed
```
Values Validation: infisical-standalone-postgres
================================================

Chart: forks/infisical/helm-charts/infisical-standalone-postgres

Files Validated:
  - base.yaml ........... PASS
  - local.yaml .......... PASS (2 warnings)

Warnings:

local.yaml:
  [WARN] resources.limits.cpu not defined
         Recommendation: Define CPU limits for predictable scheduling

Helm Template Test:
  - base.yaml + local.yaml ... PASS

Best Practice Score: 90/100
```

### Validation Failed
```
Values Validation: infisical-standalone-postgres
================================================

Files Validated:
  - base.yaml ........... PASS
  - local.yaml .......... FAIL

Errors:

local.yaml:
  [ERROR] Line 8: Invalid YAML syntax
          Expected mapping, found scalar

  [ERROR] Helm template failed
          Error: values don't meet chart requirements

Fix these errors before deployment.
```

## Integration

Use `make <repo>-lint` for quick chart linting:
```bash
make infisical-lint
```
