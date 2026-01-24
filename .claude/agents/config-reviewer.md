# Config Reviewer Agent

Review Helm values configurations for security, best practices, and production readiness.

## Purpose

This agent performs comprehensive review of Helm values to ensure:
- Security best practices are followed
- Production configurations are robust
- Resource allocations are appropriate
- No sensitive data is exposed

## Repository Structure

```
forks/<repo>/helm-charts/<chart>/values.yaml    # Chart defaults
configs/values/<chart>/
├── base.yaml                                    # Shared values
└── <context>.yaml                               # Context-specific
```

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

# Find chart path
find forks -path "*/helm-charts/*" -name "Chart.yaml" | xargs grep -l "name: <chart>"

# Read chart defaults
cat <chart-path>/values.yaml
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
Configuration Review: infisical-standalone-postgres
Context: cloud-prod
═══════════════════════════════════════════════════════════════

Overall Score: 78/100

───────────────────────────────────────────────────────────────
SECURITY (Score: 85/100)
───────────────────────────────────────────────────────────────

✅ PASS: No privileged containers
✅ PASS: Security context defined
✅ PASS: Non-root user configured
⚠️  WARN: Image tag is mutable (:latest)
         Fix: Pin to specific version

───────────────────────────────────────────────────────────────
RESOURCES (Score: 70/100)
───────────────────────────────────────────────────────────────

✅ PASS: CPU requests defined (500m)
✅ PASS: Memory requests defined (512Mi)
⚠️  WARN: CPU limit missing
         Recommendation: Set limit to 1000m

───────────────────────────────────────────────────────────────
HIGH AVAILABILITY (Score: 75/100)
───────────────────────────────────────────────────────────────

✅ PASS: Replicas: 3 (appropriate for production)
⚠️  WARN: PodDisruptionBudget not configured
         Recommendation: Set minAvailable: 2

───────────────────────────────────────────────────────────────
RECOMMENDATIONS
───────────────────────────────────────────────────────────────

Priority 1 (Must Fix):
  1. Pin image to specific version
  2. Set CPU and memory limits

Priority 2 (Should Fix):
  3. Add PodDisruptionBudget
  4. Add priorityClass
```

## Review Modes

- **Quick Review**: Critical security and production issues only
- **Full Review**: Comprehensive analysis
- **Pre-Deploy Review**: Final checks before deployment

## Invocation Examples

- "Review infisical-standalone-postgres values for production"
- "Is the configuration secure?"
- "Pre-deployment check for cloud-prod"

## Related Commands

- `/charts-values-validate <chart>` - Schema validation
- `/charts-values-diff <chart> <c1> <c2>` - Compare contexts
