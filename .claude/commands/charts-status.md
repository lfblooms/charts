# Charts Repository Status

Show the overall status of the charts repository including forks, contexts, and values configurations.

## Instructions

1. **List Forks**: Check submodules and their status
   ```bash
   git submodule status
   ```

2. **List Helm Charts**: Find all charts in forks
   ```bash
   find forks/*/helm-charts -name "Chart.yaml" 2>/dev/null | while read f; do
     dirname "$f"
     yq '.name + " v" + .version' "$f"
   done
   ```

3. **List Contexts**: Read all YAML files in `configs/contexts/`
   ```bash
   ls configs/contexts/*.yaml 2>/dev/null
   ```

4. **List Values**: Scan `configs/values/` for chart value configurations
   ```bash
   for chart in configs/values/*/; do
     echo "$(basename $chart): $(ls $chart/*.yaml 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
   done
   ```

5. **Check Makefiles**: List available makefiles
   ```bash
   ls makefiles/*.mk 2>/dev/null
   ```

## Output Format

```
Charts Repository Status
========================

Forks (git submodules):
  forks/infisical @ f515a76
    Origin:   lfblooms/Infisical.infisical
    Upstream: Infisical/infisical
    Status:   Up to date

Helm Charts:
  infisical-standalone-postgres (v0.8.0)
    Path: forks/infisical/helm-charts/infisical-standalone-postgres
    Makefile: makefiles/infisical.mk
    Values: base.yaml, local.yaml

  infisical-gateway (v0.2.0)
    Path: forks/infisical/helm-charts/infisical-gateway
    Makefile: (none)
    Values: (none)

Contexts:
  - local (minikube, default namespace)
  - cloud-prod (gke-prod, infisical namespace)

Summary:
  Forks: 1
  Charts: 2
  Contexts: 2
  Charts with values: 1
```

## Empty State

If the repository is newly initialized:
```
Charts Repository Status
========================

Forks: None configured
  Add a fork: /charts-fork-add <upstream-url>

Contexts: None defined
  Create context: /charts-context-create local

Values: None configured
  Create values: /charts-values-create <chart> <context>
```

## Commands

```bash
# Submodule status
git submodule status

# List forks
ls -la forks/

# List contexts
ls configs/contexts/*.yaml

# List values
ls -la configs/values/

# List makefiles
ls makefiles/*.mk
```
