# Compare Values Between Contexts

Compare values configuration between two contexts for a chart.

## Arguments

- `<chart>` - Chart name
- `<context1>` - First context (e.g., `local`)
- `<context2>` - Second context (e.g., `cloud-prod`)

## Instructions

1. **Validate Files Exist**:
   ```bash
   ls configs/values/<chart>/<context1>.yaml
   ls configs/values/<chart>/<context2>.yaml
   ```

2. **Compute Merged Values**: Merge base + context for each
   ```bash
   yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
     configs/values/<chart>/base.yaml \
     configs/values/<chart>/<context1>.yaml > /tmp/merged1.yaml

   yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
     configs/values/<chart>/base.yaml \
     configs/values/<chart>/<context2>.yaml > /tmp/merged2.yaml
   ```

3. **Generate Diff**: Compare the merged values
   ```bash
   diff -u /tmp/merged1.yaml /tmp/merged2.yaml
   ```

4. **Highlight Key Differences**: Focus on important settings

## Output Format

```
Values Comparison: infisical-standalone-postgres
================================================

Comparing: local vs cloud-prod

Key Differences:

| Setting              | local      | cloud-prod    |
|----------------------|------------|---------------|
| replicaCount         | 1          | 3             |
| resources.requests.cpu | 100m     | 500m          |
| resources.limits.memory | 512Mi   | 2Gi           |
| ingress.enabled      | false      | true          |
| postgresql.enabled   | true       | false         |

Full Diff:
----------
--- local (merged with base)
+++ cloud-prod (merged with base)
@@ -1,5 +1,5 @@
-replicaCount: 1
+replicaCount: 3

 resources:
   requests:
-    cpu: 100m
-    memory: 256Mi
+    cpu: 500m
+    memory: 1Gi
   limits:
-    memory: 512Mi
+    memory: 2Gi

+ingress:
+  enabled: true
+  hosts:
+    - host: infisical.example.com

-postgresql:
-  enabled: true
+postgresql:
+  enabled: false
+externalDatabase:
+  existingSecret: rds-credentials
```

## Error Handling

- **File not found**: "Values for '<context>' not found. Create with: /charts-values-create <chart> <context>"
- **Same values**: "No differences found between <context1> and <context2>"
