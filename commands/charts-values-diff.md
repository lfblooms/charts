# Diff Values Between Contexts

Compare values files between two contexts for a specific chart.

## Arguments

- `<chart>` - Chart name
- `<context1>` - First context to compare
- `<context2>` - Second context to compare

## Instructions

1. **Validate Files Exist**:
   - `configs/values/<chart>/<context1>.yaml`
   - `configs/values/<chart>/<context2>.yaml`

2. **Perform Diff**: Compare the two files
   ```bash
   diff -u configs/values/<chart>/<context1>.yaml configs/values/<chart>/<context2>.yaml
   ```

3. **Analyze Differences**: Categorize changes
   - Resource differences (CPU, memory)
   - Replica counts
   - Feature flags
   - Security settings
   - Environment-specific values

4. **Present Results**: Show meaningful diff with context

## Output Format

### Diff Report
```
Values Comparison: cert-manager
  Context 1: local
  Context 2: cloud-prod

Summary:
  - 5 values differ
  - 2 only in local
  - 3 only in cloud-prod

Differences:

┌─────────────────────────────────────────────────────────────┐
│ Resources                                                    │
├─────────────────────────────────────────────────────────────┤
│ Key                      │ local        │ cloud-prod        │
├──────────────────────────┼──────────────┼───────────────────┤
│ replicaCount             │ 1            │ 3                 │
│ resources.requests.cpu   │ 100m         │ 500m              │
│ resources.requests.memory│ 128Mi        │ 512Mi             │
│ resources.limits.cpu     │ 200m         │ 1000m             │
│ resources.limits.memory  │ 256Mi        │ 1Gi               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Feature Flags                                                │
├─────────────────────────────────────────────────────────────┤
│ Key                      │ local        │ cloud-prod        │
├──────────────────────────┼──────────────┼───────────────────┤
│ debug.enabled            │ true         │ false             │
│ metrics.enabled          │ false        │ true              │
└─────────────────────────────────────────────────────────────┘

Only in local:
  - debug.verbosity: 3

Only in cloud-prod:
  - podDisruptionBudget.enabled: true
  - podDisruptionBudget.minAvailable: 2
  - affinity.podAntiAffinity: (complex)
```

## Alternative Views

### Raw Diff
```bash
diff -u configs/values/<chart>/<context1>.yaml configs/values/<chart>/<context2>.yaml
```

### YAML Merge Preview
Show what the merged result would look like for each context:
```
base.yaml + local.yaml = <merged local values>
base.yaml + cloud-prod.yaml = <merged prod values>
```

## Error Handling

- **Missing file**: "Values for '<chart>' in '<context>' not found. Create with: /charts-values-create <chart> <context>"
- **Same context**: "Cannot diff a context with itself"
- **No differences**: "Values are identical between local and cloud-prod"
