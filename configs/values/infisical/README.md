# Infisical

> Open source secret management platform for teams

## Overview

Infisical is an open-source, end-to-end encrypted secret management platform that helps teams centralize secrets like API keys, database credentials, and environment variables.

This Helm chart deploys a self-hosted Infisical instance with:
- **Infisical Core**: The main application server
- **PostgreSQL**: Primary data storage (optional, can use external)
- **Redis**: Caching and session management (optional, can use external)

### Architecture

```
                    ┌─────────────┐
                    │   Ingress   │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Infisical  │
                    │   (2+ pods) │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐ ┌───▼───┐ ┌─────▼─────┐
       │  PostgreSQL │ │ Redis │ │  External │
       │  (in-cluster│ │       │ │  Services │
       │  or managed)│ │       │ │           │
       └─────────────┘ └───────┘ └───────────┘
```

## Prerequisites

- Kubernetes 1.25+
- Helm 3.10+
- PV provisioner support (for persistence)
- 2GB+ RAM available for the cluster

### Required Secrets

Before installation, create a Kubernetes secret with required values:

```bash
kubectl create secret generic infisical-secrets \
  --from-literal=ENCRYPTION_KEY=$(openssl rand -hex 16) \
  --from-literal=AUTH_SECRET=$(openssl rand -base64 32) \
  --from-literal=SITE_URL=https://infisical.example.com \
  -n infisical
```

## Installation

### Using this Repository

1. Create your values configuration:
   ```bash
   /charts-values-create infisical local
   ```

2. Edit base values:
   ```bash
   $EDITOR configs/values/infisical/base.yaml
   ```

3. Install:
   ```bash
   helm install infisical forks/infisical \
     -f configs/values/infisical/base.yaml \
     -f configs/values/infisical/local.yaml \
     -n infisical --create-namespace
   ```

### Quick Start (Development)

```bash
# Create namespace
kubectl create namespace infisical

# Create minimal secret (NOT for production!)
kubectl create secret generic infisical-secrets \
  --from-literal=ENCRYPTION_KEY=$(openssl rand -hex 16) \
  --from-literal=AUTH_SECRET=$(openssl rand -base64 32) \
  --from-literal=SITE_URL=http://localhost:8080 \
  -n infisical

# Install with defaults
helm install infisical forks/infisical -n infisical

# Port forward to access
kubectl port-forward svc/infisical 8080:80 -n infisical
```

### Production Deployment

```bash
# Create namespace
kubectl create namespace infisical

# Create production secrets (use proper secret management!)
kubectl create secret generic infisical-secrets \
  --from-literal=ENCRYPTION_KEY=<your-32-char-hex-key> \
  --from-literal=AUTH_SECRET=<your-secure-auth-secret> \
  --from-literal=SITE_URL=https://infisical.example.com \
  -n infisical

# Install with production values
helm install infisical forks/infisical \
  -f configs/values/infisical/base.yaml \
  -f configs/values/infisical/cloud-prod.yaml \
  -n infisical
```

## Configuration

See [CONFIGURATION.md](CONFIGURATION.md) for complete reference.

### Essential Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of Infisical replicas | `2` |
| `infisical.existingSecret` | Secret with ENCRYPTION_KEY, AUTH_SECRET, SITE_URL | `infisical-secrets` |
| `postgresql.enabled` | Deploy PostgreSQL in-cluster | `true` |
| `redis.enabled` | Deploy Redis in-cluster | `true` |
| `ingress.enabled` | Enable ingress | `false` |

### Secrets Management

The `infisical-secrets` Kubernetes secret must contain:

| Key | Description | Required |
|-----|-------------|----------|
| `ENCRYPTION_KEY` | 32-character hex string for encryption | Yes |
| `AUTH_SECRET` | Random string for JWT signing | Yes |
| `SITE_URL` | Public URL of your Infisical instance | Yes |

For production, integrate with:
- **External Secrets Operator**: Sync from Vault, AWS Secrets Manager, etc.
- **Sealed Secrets**: GitOps-friendly encrypted secrets

### Persistence

Both PostgreSQL and Redis use persistent volumes by default:

| Component | Default Size | Storage Class |
|-----------|--------------|---------------|
| PostgreSQL | 10Gi | default |
| Redis | 5Gi | default |

### Networking

Service types available:
- `ClusterIP` (default) - Internal access only
- `LoadBalancer` - Direct external access
- `NodePort` - Access via node IP

## Dependencies

| Repository | Chart | Version | Purpose |
|------------|-------|---------|---------|
| bitnami | postgresql | 15.x | Primary database |
| bitnami | redis | 19.x | Cache and sessions |

### Using External Services

For production, disable bundled dependencies and use managed services:

```yaml
# Disable in-cluster PostgreSQL
postgresql:
  enabled: false

# Configure external database
externalDatabase:
  uri: "postgres://user:pass@rds.amazonaws.com:5432/infisical"
  # Or use existing secret:
  existingSecret: "db-credentials"
  secretKey: "DB_CONNECTION_URI"

# Disable in-cluster Redis
redis:
  enabled: false

# Configure external Redis
externalRedis:
  url: "redis://:password@elasticache.amazonaws.com:6379"
```

## Upgrading

### General Upgrade Process

1. **Backup database**:
   ```bash
   kubectl exec -it infisical-postgresql-0 -n infisical -- \
     pg_dump -U infisical infisical > backup.sql
   ```

2. **Update chart**:
   ```bash
   helm upgrade infisical forks/infisical \
     -f configs/values/infisical/base.yaml \
     -f configs/values/infisical/cloud-prod.yaml \
     -n infisical
   ```

3. **Verify**:
   ```bash
   kubectl get pods -n infisical -w
   helm test infisical -n infisical
   ```

### Version-Specific Notes

Check [Infisical releases](https://github.com/Infisical/infisical/releases) for breaking changes before upgrading `appVersion`.

## Troubleshooting

### Pods Not Starting

**Issue**: Pods stuck in `CrashLoopBackOff`

Check logs:
```bash
kubectl logs -l app.kubernetes.io/name=infisical -n infisical
```

Common causes:
- Missing `infisical-secrets` secret
- Database connection failed
- Invalid ENCRYPTION_KEY format

### Database Connection Failed

**Issue**: Cannot connect to PostgreSQL

Verify PostgreSQL is running:
```bash
kubectl get pods -l app.kubernetes.io/name=postgresql -n infisical
```

Check connection from Infisical pod:
```bash
kubectl exec -it deploy/infisical -n infisical -- \
  nc -zv infisical-postgresql 5432
```

### Ingress Not Working

**Issue**: Cannot access via ingress

Verify ingress controller:
```bash
kubectl get ingressclass
kubectl get ingress -n infisical
```

Check ingress controller logs for errors.

## Uninstallation

```bash
# Uninstall release
helm uninstall infisical -n infisical

# Delete PVCs (WARNING: destroys data!)
kubectl delete pvc -l app.kubernetes.io/instance=infisical -n infisical

# Delete namespace
kubectl delete namespace infisical
```

## References

- [Infisical Documentation](https://infisical.com/docs)
- [Infisical GitHub](https://github.com/Infisical/infisical)
- [Self-Hosting Guide](https://infisical.com/docs/self-hosting/deployment-options/kubernetes-helm)
- [Environment Variables Reference](https://infisical.com/docs/self-hosting/configuration/envars)
