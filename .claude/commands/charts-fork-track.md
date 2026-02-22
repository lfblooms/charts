# Initialize Fork Tracking

Initialize or update submodule tracking for chart forks.

## Arguments

- `[repo]` - Optional repo name. If omitted, tracks all forks.

## Instructions

1. **Initialize Submodules**: If not already done
   ```bash
   git submodule init
   git submodule update --recursive
   ```

2. **For Specific Repo**: Initialize only that submodule
   ```bash
   git submodule init forks/<repo>
   git submodule update forks/<repo>
   ```

3. **Configure Upstream**: Ensure upstream remote is set
   ```bash
   git -C forks/<repo> remote add upstream <upstream-url>
   ```

4. **Verify Tracking**: Check submodules are properly tracked
   ```bash
   git submodule status
   ```

## Use Cases

### After Fresh Clone
When someone clones the repository, submodules need initialization:
```bash
git clone https://github.com/lfblooms/charts.git
cd charts
/charts-fork-track
```

### After Adding New Fork
When a new fork was added by someone else:
```bash
git pull
/charts-fork-track infisical
```

### Fix Detached HEAD
If a submodule is in detached HEAD state:
```bash
git -C forks/<repo> checkout main
```

## Output Format

### Success
```
Submodule Tracking Initialized

forks/infisical
  Status:   initialized
  Branch:   main
  Commit:   f515a76
  Upstream: configured

forks/cert-manager
  Status:   initialized
  Branch:   main
  Commit:   abc1234
  Upstream: configured

All submodules are tracked and ready.
```

### Already Tracked
```
Submodule 'infisical' is already tracked.
  Branch: main
  Commit: f515a76
  Upstream: https://github.com/Infisical/infisical.git
```

### Empty State
```
No submodules configured in .gitmodules

To add a fork:
  /charts-fork-add <upstream-url>
```

## Error Handling

- **Network error**: "Failed to fetch submodule. Check network and try again."
- **Missing submodule**: "Submodule '<repo>' not found in .gitmodules"
- **Invalid state**: "Submodule in invalid state. Try: git submodule deinit forks/<repo> && git submodule update --init forks/<repo>"
