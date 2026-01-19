# Config Reviewer Agent

Review Helm values configurations for security, best practices, and production readiness.

## Purpose

This agent performs comprehensive review of Helm values to ensure:
- Security best practices are followed
- Production configurations are robust
- Resource allocations are appropriate
- No sensitive data is exposed

## Capabilities

### Security Review
- Container security contexts
- RBAC configurations
- Network policies
- Secret management
- Image security (tags, registries)

### Best Practice Validation
- Resource requests and limits
- Health checks and probes
- Pod disruption budgets
- Affinity and anti-affinity rules
- Horizontal pod autoscaling

### Environment-Specific Checks
- Development vs production settings
- Debug flags in production
- Replica counts
- Resource sizing

## Review Workflow

### 1. Gather Configuration
```bash
# Read values files
cat configs/values/<chart>/base.yaml
cat configs/values/<chart>/<context>.yaml

# Read chart defaults for comparison
cat forks/<chart>/values.yaml
```

### 2. Security Analysis

Check for:
- Privileged containers
- Host network/PID/IPC
- Root user
- Capabilities
- Read-only root filesystem
- Secret references

### 3. Resource Analysis

Verify:
- CPU/memory requests defined
- Limits appropriate for context
- No unbounded resources in production

### 4. Generate Report

## Output Format

### Configuration Review Report

```
Configuration Review: cert-manager
Context: cloud-prod
═══════════════════════════════════════════════════════════════

Overall Score: 78/100

───────────────────────────────────────────────────────────────
SECURITY (Score: 85/100)
───────────────────────────────────────────────────────────────

✅ PASS: No privileged containers
✅ PASS: Security context defined
✅ PASS: Non-root user configured
✅ PASS: Read-only root filesystem
⚠️  WARN: NET_BIND_SERVICE capability added
         Justification needed for production
❌ FAIL: Image tag is mutable (:latest)
         Risk: Unpredictable deployments
         Fix: Pin to specific version (e.g., v1.14.0)

───────────────────────────────────────────────────────────────
RESOURCES (Score: 70/100)
───────────────────────────────────────────────────────────────

✅ PASS: CPU requests defined (500m)
✅ PASS: Memory requests defined (512Mi)
⚠️  WARN: CPU limit missing
         Risk: Pod can consume unlimited CPU
         Recommendation: Set limit to 1000m
⚠️  WARN: Memory limit missing
         Risk: Pod can be OOMKilled unexpectedly
         Recommendation: Set limit to 1Gi

Current Resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: <not set>
    memory: <not set>

───────────────────────────────────────────────────────────────
HIGH AVAILABILITY (Score: 75/100)
───────────────────────────────────────────────────────────────

✅ PASS: Replicas: 3 (appropriate for production)
✅ PASS: Pod anti-affinity configured
⚠️  WARN: PodDisruptionBudget not configured
         Risk: All pods could be evicted during node drain
         Recommendation: Set minAvailable: 2

───────────────────────────────────────────────────────────────
OBSERVABILITY (Score: 80/100)
───────────────────────────────────────────────────────────────

✅ PASS: Liveness probe configured
✅ PASS: Readiness probe configured
✅ PASS: Prometheus metrics enabled
⚠️  WARN: No ServiceMonitor for Prometheus Operator
         Recommendation: Enable serviceMonitor.enabled

───────────────────────────────────────────────────────────────
PRODUCTION READINESS (Score: 75/100)
───────────────────────────────────────────────────────────────

✅ PASS: Debug logging disabled
✅ PASS: Resource requests defined
❌ FAIL: Image pull policy is Always
         Risk: Performance impact on restarts
         Fix: Set to IfNotPresent with pinned tag
⚠️  WARN: No priorityClass set
         Recommendation: Set appropriate priority for critical workload

───────────────────────────────────────────────────────────────
RECOMMENDATIONS
───────────────────────────────────────────────────────────────

Priority 1 (Must Fix):
  1. Pin image to specific version
  2. Set CPU and memory limits

Priority 2 (Should Fix):
  3. Add PodDisruptionBudget
  4. Change imagePullPolicy to IfNotPresent
  5. Add priorityClass

Priority 3 (Nice to Have):
  6. Enable ServiceMonitor
  7. Document NET_BIND_SERVICE justification

───────────────────────────────────────────────────────────────
CONTEXT COMPARISON
───────────────────────────────────────────────────────────────

Settings that differ from 'local':
  - replicaCount: 3 (local: 1) ✅ Appropriate
  - debug.enabled: false (local: true) ✅ Appropriate
  - resources.requests.cpu: 500m (local: 100m) ✅ Appropriate

Potential issues:
  - image.tag same as local - should be pinned differently?
```

## Review Modes

### Quick Review
Focus on critical security and production issues only.

### Full Review
Comprehensive analysis of all aspects.

### Diff Review
Compare changes between two configurations.

### Pre-Deploy Review
Final checks before production deployment.

## Invocation Examples

- "Review cert-manager values for production"
- "Is ingress-nginx configuration secure?"
- "Compare local vs prod settings for security"
- "Pre-deployment check for cloud-prod"

## Related Commands

- `/charts-values-validate <chart>` - Schema validation
- `/charts-values-diff <chart> <c1> <c2>` - Compare contexts
