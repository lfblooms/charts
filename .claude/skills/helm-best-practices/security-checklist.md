# Helm Security Checklist

## Container Security

- [ ] `runAsNonRoot: true`
- [ ] `readOnlyRootFilesystem: true`
- [ ] `allowPrivilegeEscalation: false`
- [ ] Capabilities dropped (at minimum `ALL`)
- [ ] No privileged containers unless justified
- [ ] User/group IDs specified

## Image Security

- [ ] Images from trusted registries
- [ ] Image tags pinned (no `:latest` in prod)
- [ ] Image pull secrets configured
- [ ] Regular vulnerability scanning

## Network Security

- [ ] Network policies enabled
- [ ] Ingress restricted to required sources
- [ ] Egress restricted where possible
- [ ] TLS for all external communication

## Secrets Management

- [ ] No hardcoded secrets in values
- [ ] External secrets referenced
- [ ] Secret rotation strategy
- [ ] Minimal secret scope

## RBAC

- [ ] ServiceAccount created
- [ ] Minimal RBAC permissions
- [ ] No cluster-admin bindings
- [ ] Role vs ClusterRole appropriately chosen

## Resource Limits

- [ ] CPU requests defined
- [ ] Memory requests defined
- [ ] CPU limits defined
- [ ] Memory limits defined
- [ ] No unbounded resources

## Pod Security Standards

- [ ] Baseline or Restricted policy compliance
- [ ] Pod Security Admission labels set
- [ ] Security context at pod and container level
