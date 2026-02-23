# Configuration Reference

Complete reference for Infisical Helm chart values.

## Table of Contents

- [Global](#global)
- [Image](#image)
- [Infisical Configuration](#infisical-configuration)
- [Service Account](#service-account)
- [Service](#service)
- [Ingress](#ingress)
- [Resources](#resources)
- [Autoscaling](#autoscaling)
- [Pod Configuration](#pod-configuration)
- [Probes](#probes)
- [PostgreSQL](#postgresql)
- [Redis](#redis)
- [External Database](#external-database)
- [External Redis](#external-redis)

---

## Global

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `replicaCount` | int | `2` | Number of Infisical pod replicas |
| `nameOverride` | string | `""` | Override chart name in resource names |
| `fullnameOverride` | string | `""` | Override full resource names |
| `imagePullSecrets` | list | `[]` | Docker registry pull secrets |

## Image

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image.repository` | string | `"infisical/infisical"` | Container image repository |
| `image.tag` | string | `""` | Image tag (defaults to `.Chart.AppVersion`) |
| `image.pullPolicy` | string | `"IfNotPresent"` | Image pull policy: `Always`, `IfNotPresent`, `Never` |

## Infisical Configuration

Core application configuration.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `infisical.existingSecret` | string | `"infisical-secrets"` | Name of existing secret with required keys |
| `infisical.siteUrl` | string | `""` | Public URL (only if not using existingSecret) |
| `infisical.extraEnv` | list | `[]` | Additional environment variables |
| `infisical.extraEnvFrom` | list | `[]` | Additional env sources (secrets/configmaps) |

### Required Secret Keys

The secret specified in `infisical.existingSecret` must contain:

| Key | Required | Description |
|-----|----------|-------------|
| `ENCRYPTION_KEY` | Yes | 32-character hex string for data encryption |
| `AUTH_SECRET` | Yes | Random string for JWT token signing |
| `SITE_URL` | Yes | Public URL of your Infisical instance |
| `DB_CONNECTION_URI` | No | Override database connection (if not using subchart) |
| `REDIS_URL` | No | Override Redis connection (if not using subchart) |
| `DB_ROOT_CERT` | No | Root certificate for SSL database connections |

### Extra Environment Variables Example

```yaml
infisical:
  extraEnv:
    - name: SMTP_HOST
      value: "smtp.example.com"
    - name: SMTP_PORT
      value: "587"
    - name: SMTP_USERNAME
      valueFrom:
        secretKeyRef:
          name: smtp-credentials
          key: username
```

### Extra Env From Example

```yaml
infisical:
  extraEnvFrom:
    - secretRef:
        name: additional-secrets
    - configMapRef:
        name: feature-flags
```

## Service Account

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `serviceAccount.create` | bool | `true` | Create a service account |
| `serviceAccount.annotations` | object | `{}` | Annotations for the service account |
| `serviceAccount.name` | string | `""` | Service account name (auto-generated if empty) |

### AWS IRSA Example

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/infisical-role
```

## Service

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `service.type` | string | `"ClusterIP"` | Service type: `ClusterIP`, `LoadBalancer`, `NodePort` |
| `service.port` | int | `80` | Service port |
| `service.targetPort` | int | `8080` | Container target port |
| `service.annotations` | object | `{}` | Service annotations |

### Load Balancer Example

```yaml
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

## Ingress

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ingress.enabled` | bool | `false` | Enable ingress |
| `ingress.className` | string | `"nginx"` | Ingress class name |
| `ingress.annotations` | object | `{}` | Ingress annotations |
| `ingress.hosts` | list | `[{host: "infisical.local", paths: [{path: "/", pathType: "Prefix"}]}]` | Ingress hosts configuration |
| `ingress.tls` | list | `[]` | TLS configuration |

### Ingress with TLS Example

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
  hosts:
    - host: infisical.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: infisical-tls
      hosts:
        - infisical.example.com
```

## Resources

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `resources.limits.memory` | string | `"1000Mi"` | Memory limit |
| `resources.requests.cpu` | string | `"350m"` | CPU request |
| `resources.requests.memory` | string | `"512Mi"` | Memory request |

### Production Resources Example

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

## Autoscaling

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `autoscaling.enabled` | bool | `false` | Enable HorizontalPodAutoscaler |
| `autoscaling.minReplicas` | int | `2` | Minimum replicas |
| `autoscaling.maxReplicas` | int | `10` | Maximum replicas |
| `autoscaling.targetCPUUtilizationPercentage` | int | `80` | Target CPU utilization |
| `autoscaling.targetMemoryUtilizationPercentage` | int | - | Target memory utilization |

### Autoscaling Example

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

## Pod Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `podAnnotations` | object | `{}` | Additional pod annotations |
| `podSecurityContext` | object | `{}` | Pod security context |
| `securityContext` | object | `{}` | Container security context |
| `nodeSelector` | object | `{}` | Node selector labels |
| `tolerations` | list | `[]` | Pod tolerations |
| `affinity` | object | `{}` | Pod affinity rules |

### Pod Disruption Budget

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `podDisruptionBudget.enabled` | bool | `false` | Enable PodDisruptionBudget |
| `podDisruptionBudget.minAvailable` | int | `1` | Minimum available pods |
| `podDisruptionBudget.maxUnavailable` | int | - | Maximum unavailable pods |

### Pod Anti-Affinity Example

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: infisical
          topologyKey: kubernetes.io/hostname
```

## Probes

### Liveness Probe

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `livenessProbe.enabled` | bool | `true` | Enable liveness probe |
| `livenessProbe.initialDelaySeconds` | int | `30` | Initial delay before probing |
| `livenessProbe.periodSeconds` | int | `10` | Probe interval |
| `livenessProbe.timeoutSeconds` | int | `5` | Probe timeout |
| `livenessProbe.failureThreshold` | int | `3` | Failures before unhealthy |

### Readiness Probe

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `readinessProbe.enabled` | bool | `true` | Enable readiness probe |
| `readinessProbe.initialDelaySeconds` | int | `10` | Initial delay before probing |
| `readinessProbe.periodSeconds` | int | `5` | Probe interval |
| `readinessProbe.timeoutSeconds` | int | `3` | Probe timeout |
| `readinessProbe.failureThreshold` | int | `3` | Failures before not ready |

---

## PostgreSQL

Bitnami PostgreSQL subchart configuration. See [full documentation](https://github.com/bitnami/charts/tree/main/bitnami/postgresql).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `postgresql.enabled` | bool | `true` | Deploy PostgreSQL in-cluster |
| `postgresql.auth.database` | string | `"infisical"` | Database name |
| `postgresql.auth.username` | string | `"infisical"` | Database username |
| `postgresql.auth.password` | string | `""` | Database password (use existingSecret) |
| `postgresql.auth.existingSecret` | string | `""` | Existing secret with credentials |
| `postgresql.primary.persistence.enabled` | bool | `true` | Enable persistence |
| `postgresql.primary.persistence.size` | string | `"10Gi"` | PVC size |

### PostgreSQL HA Note

For production high availability, consider:
- [Zalando Postgres Operator](https://github.com/zalando/postgres-operator)
- Managed services (RDS, Cloud SQL, Azure Database)

## Redis

Bitnami Redis subchart configuration. See [full documentation](https://github.com/bitnami/charts/tree/main/bitnami/redis).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `redis.enabled` | bool | `true` | Deploy Redis in-cluster |
| `redis.auth.password` | string | `""` | Redis password (use existingSecret) |
| `redis.auth.existingSecret` | string | `""` | Existing secret with credentials |
| `redis.architecture` | string | `"standalone"` | Redis architecture |
| `redis.master.persistence.enabled` | bool | `true` | Enable persistence |
| `redis.master.persistence.size` | string | `"5Gi"` | PVC size |

---

## External Database

Configuration when using an external PostgreSQL database (`postgresql.enabled: false`).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `externalDatabase.uri` | string | `""` | Full connection URI |
| `externalDatabase.existingSecret` | string | `""` | Secret containing connection URI |
| `externalDatabase.secretKey` | string | `"DB_CONNECTION_URI"` | Key in secret with URI |
| `externalDatabase.rootCert` | string | `""` | Root certificate for SSL |

### Connection URI Format

```
postgres://username:password@hostname:5432/database?sslmode=require
```

### AWS RDS Example

```yaml
postgresql:
  enabled: false

externalDatabase:
  existingSecret: rds-credentials
  secretKey: connection-string
```

## External Redis

Configuration when using an external Redis (`redis.enabled: false`).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `externalRedis.url` | string | `""` | Full Redis URL |
| `externalRedis.existingSecret` | string | `""` | Secret containing Redis URL |
| `externalRedis.secretKey` | string | `"REDIS_URL"` | Key in secret with URL |

### Redis URL Format

```
redis://:password@hostname:6379
redis://username:password@hostname:6379
rediss://:password@hostname:6379  # TLS
```

### AWS ElastiCache Example

```yaml
redis:
  enabled: false

externalRedis:
  existingSecret: elasticache-credentials
  secretKey: redis-url
```
