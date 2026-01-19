# Helm Best Practices Skill

Domain knowledge for Helm chart configuration, values management, and security best practices.

## Triggers

This skill activates on:
- "helm values"
- "chart config"
- "helm security"

## Knowledge Areas

### Values Configuration

#### Structure
- Use flat keys where possible for clarity
- Group related settings under logical parents
- Provide sensible defaults
- Document all values with comments

#### Best Practices
```yaml
# Good: Clear, documented values
replicaCount: 3  # Number of pod replicas

resources:
  requests:
    cpu: 100m      # Minimum CPU
    memory: 128Mi  # Minimum memory
  limits:
    cpu: 500m      # Maximum CPU
    memory: 512Mi  # Maximum memory

# Bad: Unclear, undocumented
r: 3
res:
  rq:
    c: 100m
```

### Security Best Practices

#### Container Security
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

#### Pod Security
```yaml
podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true
```

#### Network Security
```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
```

### Resource Management

#### Always Define Resources
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

#### Context-Appropriate Sizing
- Development: Lower requests/limits, single replica
- Production: Higher resources, multiple replicas, HPA

### High Availability

#### Replicas and PDB
```yaml
replicaCount: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

#### Anti-Affinity
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          topologyKey: kubernetes.io/hostname
```

### Health Checks

#### Probes
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Image Configuration

#### Production
```yaml
image:
  repository: myregistry/myapp
  tag: v1.2.3  # Pin specific version
  pullPolicy: IfNotPresent
```

#### Development
```yaml
image:
  repository: myregistry/myapp
  tag: latest  # OK for dev
  pullPolicy: Always
```

### Secrets Management

#### Never Hardcode Secrets
```yaml
# Bad
database:
  password: "mysecretpassword"

# Good - reference external secret
database:
  existingSecret: my-db-credentials
  existingSecretKey: password
```

#### Use External Secrets
- Kubernetes Secrets with external-secrets operator
- Vault integration
- Cloud provider secret managers

### Observability

#### Metrics
```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

#### Logging
```yaml
logging:
  level: info  # debug, info, warn, error
  format: json  # json for production
```

## Anti-Patterns to Avoid

1. **Hardcoded secrets** in values files
2. **Missing resource limits** in production
3. **Using :latest tag** in production
4. **No health checks** defined
5. **Running as root** without justification
6. **No network policies** in multi-tenant clusters
7. **Missing PDB** for critical workloads
8. **Overly complex values** structure

## Environment Differences

| Setting | Development | Production |
|---------|-------------|------------|
| Replicas | 1 | 3+ |
| Resources | Low | Appropriate |
| Image tag | latest OK | Pinned |
| Debug | Enabled | Disabled |
| Metrics | Optional | Required |
| PDB | Optional | Required |
