# Usage Examples

Practical configuration examples for deploying Infisical in different scenarios.

## Local Development

Minimal resources for local testing with minikube or kind.

```yaml
# configs/values/infisical/local.yaml
replicaCount: 1

resources:
  limits:
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi

# Disable probes for faster startup during development
livenessProbe:
  enabled: true
  initialDelaySeconds: 60

readinessProbe:
  enabled: true
  initialDelaySeconds: 30

# Smaller database for local
postgresql:
  primary:
    persistence:
      size: 1Gi

redis:
  master:
    persistence:
      size: 1Gi
```

**Installation:**
```bash
# Create minimal secret
kubectl create secret generic infisical-secrets \
  --from-literal=ENCRYPTION_KEY=$(openssl rand -hex 16) \
  --from-literal=AUTH_SECRET=$(openssl rand -base64 32) \
  --from-literal=SITE_URL=http://localhost:8080 \
  -n infisical

# Install
helm install infisical forks/infisical \
  -f configs/values/infisical/local.yaml \
  -n infisical --create-namespace

# Access
kubectl port-forward svc/infisical 8080:80 -n infisical
```

---

## Staging Environment

Production-like configuration with reduced resources.

```yaml
# configs/values/infisical/staging.yaml
replicaCount: 2

resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
  hosts:
    - host: infisical.staging.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: infisical-staging-tls
      hosts:
        - infisical.staging.example.com

postgresql:
  primary:
    persistence:
      size: 5Gi

redis:
  master:
    persistence:
      size: 2Gi
```

---

## Production with High Availability

Full production deployment with HA, autoscaling, and pod distribution.

```yaml
# configs/values/infisical/cloud-prod.yaml
replicaCount: 3

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

podDisruptionBudget:
  enabled: true
  minAvailable: 2

# Spread pods across nodes
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: infisical
          topologyKey: kubernetes.io/hostname

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
  hosts:
    - host: infisical.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: infisical-prod-tls
      hosts:
        - infisical.example.com

# Production database sizing
postgresql:
  primary:
    persistence:
      size: 50Gi
      storageClass: fast-ssd

redis:
  master:
    persistence:
      size: 10Gi
      storageClass: fast-ssd
```

---

## With External Database (AWS RDS)

Using AWS RDS for PostgreSQL and ElastiCache for Redis.

```yaml
# configs/values/infisical/aws-prod.yaml
replicaCount: 3

# Disable in-cluster databases
postgresql:
  enabled: false

redis:
  enabled: false

# External database configuration
externalDatabase:
  existingSecret: rds-credentials
  secretKey: DB_CONNECTION_URI

externalRedis:
  existingSecret: elasticache-credentials
  secretKey: REDIS_URL

# Use IRSA for AWS access
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/infisical-role

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10

ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
  hosts:
    - host: infisical.example.com
      paths:
        - path: /
          pathType: Prefix
```

**Secret setup:**
```bash
# Create database secret
kubectl create secret generic rds-credentials \
  --from-literal=DB_CONNECTION_URI="postgres://user:pass@rds.amazonaws.com:5432/infisical?sslmode=require" \
  -n infisical

# Create Redis secret
kubectl create secret generic elasticache-credentials \
  --from-literal=REDIS_URL="redis://:auth-token@elasticache.amazonaws.com:6379" \
  -n infisical
```

---

## With SMTP Configuration

Enable email notifications and invitations.

```yaml
# configs/values/infisical/with-smtp.yaml
infisical:
  existingSecret: infisical-secrets
  extraEnv:
    - name: SMTP_HOST
      value: "smtp.sendgrid.net"
    - name: SMTP_PORT
      value: "587"
    - name: SMTP_SECURE
      value: "true"
    - name: SMTP_FROM_ADDRESS
      value: "noreply@example.com"
    - name: SMTP_FROM_NAME
      value: "Infisical"
  extraEnvFrom:
    - secretRef:
        name: smtp-credentials
```

**SMTP secret:**
```bash
kubectl create secret generic smtp-credentials \
  --from-literal=SMTP_USERNAME=apikey \
  --from-literal=SMTP_PASSWORD=SG.xxx \
  -n infisical
```

---

## Air-Gapped / Private Registry

For environments without internet access.

```yaml
# configs/values/infisical/airgapped.yaml
image:
  repository: registry.internal.example.com/infisical/infisical
  pullPolicy: Always

imagePullSecrets:
  - name: registry-credentials

# Also override subchart images
postgresql:
  image:
    registry: registry.internal.example.com
    repository: bitnami/postgresql
  volumePermissions:
    image:
      registry: registry.internal.example.com
      repository: bitnami/os-shell

redis:
  image:
    registry: registry.internal.example.com
    repository: bitnami/redis
  volumePermissions:
    image:
      registry: registry.internal.example.com
      repository: bitnami/os-shell
```

**Registry secret:**
```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=registry.internal.example.com \
  --docker-username=user \
  --docker-password=password \
  -n infisical
```

---

## With External Secrets Operator

Sync secrets from HashiCorp Vault.

```yaml
# First, create ExternalSecret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: infisical-secrets
  namespace: infisical
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: infisical-secrets
  data:
    - secretKey: ENCRYPTION_KEY
      remoteRef:
        key: secret/infisical
        property: encryption_key
    - secretKey: AUTH_SECRET
      remoteRef:
        key: secret/infisical
        property: auth_secret
    - secretKey: SITE_URL
      remoteRef:
        key: secret/infisical
        property: site_url
```

```yaml
# configs/values/infisical/with-eso.yaml
infisical:
  # ExternalSecret creates this secret
  existingSecret: infisical-secrets
```

---

## Minimal Base Values

Shared base configuration for all environments.

```yaml
# configs/values/infisical/base.yaml

# Common configuration across all environments
infisical:
  existingSecret: infisical-secrets

serviceAccount:
  create: true

service:
  type: ClusterIP
  port: 80

# Standard probes
livenessProbe:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  initialDelaySeconds: 10
  periodSeconds: 5

# Security context
podSecurityContext:
  fsGroup: 1000

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

**Usage:**
```bash
# Local
helm install infisical forks/infisical \
  -f configs/values/infisical/base.yaml \
  -f configs/values/infisical/local.yaml \
  -n infisical

# Production
helm install infisical forks/infisical \
  -f configs/values/infisical/base.yaml \
  -f configs/values/infisical/cloud-prod.yaml \
  -n infisical
```
