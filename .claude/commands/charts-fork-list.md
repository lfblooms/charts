# List Chart Forks

List all tracked forks with their sync status and available Helm charts.

## Instructions

1. **List Submodules**: Get all configured submodules
   ```bash
   git submodule status
   ```

2. **For Each Fork**: Gather information
   ```bash
   # Check remotes
   git -C forks/<repo> remote -v

   # Get current commit
   git -C forks/<repo> rev-parse --short HEAD

   # Check if behind upstream
   git -C forks/<repo> fetch upstream 2>/dev/null
   git -C forks/<repo> rev-list --count HEAD..upstream/main 2>/dev/null
   ```

3. **Find Helm Charts**: Locate charts in each fork
   ```bash
   find forks/<repo> -name "Chart.yaml" -exec dirname {} \;
   ```

4. **Check Values**: List configured values for each chart
   ```bash
   ls configs/values/<chart>/
   ```

## Output Format

```
Chart Forks Status
==================

forks/infisical
  Origin:   https://github.com/MisterGrinvalds/Infisical.infisical.git
  Upstream: https://github.com/Infisical/infisical.git
  Branch:   main @ f515a76
  Status:   Up to date with upstream

  Helm Charts:
    - helm-charts/infisical-standalone-postgres (v0.8.0)
      Values: base.yaml, local.yaml
    - helm-charts/infisical-gateway (v0.2.0)
      Values: (none configured)

forks/cert-manager
  Origin:   https://github.com/MisterGrinvalds/cert-manager.cert-manager.git
  Upstream: https://github.com/cert-manager/cert-manager.git
  Branch:   main @ abc1234
  Status:   3 commits behind upstream

  Helm Charts:
    - deploy/charts/cert-manager (v1.14.0)
      Values: base.yaml, local.yaml, cloud-prod.yaml

Summary:
  Total forks: 2
  Charts: 3
  Forks needing sync: 1
```

## Empty State

```
No forks configured.

To add a fork:
  /charts-fork-add <upstream-url>

Example:
  /charts-fork-add https://github.com/Infisical/infisical
```

## Commands

```bash
# List submodules
git submodule status

# List forks directory
ls -la forks/

# Check specific fork
git -C forks/<repo> remote -v
git -C forks/<repo> log --oneline -1
```
