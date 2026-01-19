# Charts Repository Status

Show the overall status of the charts repository including forks, contexts, and values configurations.

## Instructions

1. **List Forks**: Check the `forks/` directory and `.gitmodules` for tracked chart submodules
2. **List Contexts**: Read all YAML files in `configs/contexts/`
3. **List Values**: Scan `configs/values/` for chart value configurations
4. **Check Sync Status**: For each fork, check if there are uncommitted changes or if it's behind upstream

## Output Format

Present a summary table with:

### Forks
| Chart | Branch | Local Changes | Upstream Status |
|-------|--------|---------------|-----------------|

### Contexts
| Context | Description | Cluster |
|---------|-------------|---------|

### Values Coverage
| Chart | Contexts with Values |
|-------|---------------------|

## Commands to Execute

```bash
# List submodules
git submodule status 2>/dev/null || echo "No submodules configured"

# List forks directory
ls -la forks/ 2>/dev/null || echo "forks/ directory empty"

# List contexts
ls configs/contexts/*.yaml 2>/dev/null || echo "No contexts defined"

# List values directories
ls -d configs/values/*/ 2>/dev/null || echo "No values configured"
```

## Empty State

If the repository is newly initialized:
- Report "No forks tracked yet. Use /charts-fork-add to add a chart."
- Report "No contexts defined. Use /charts-context-create to create one."
- Report "No values configured. Use /charts-values-create after adding forks and contexts."
