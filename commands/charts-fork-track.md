# Initialize Fork Tracking

Initialize or update submodule tracking for chart forks.

## Arguments

- `[chart]` - Optional chart name. If omitted, tracks all forks.

## Instructions

1. **Initialize Submodules**: If not already done
   ```bash
   git submodule init
   git submodule update
   ```

2. **For Specific Chart**: Initialize only that submodule
   ```bash
   git submodule init forks/<chart>
   git submodule update forks/<chart>
   ```

3. **Verify Tracking**: Check submodules are properly tracked
   ```bash
   git submodule status
   ```

4. **Report Status**: Show which submodules are tracked

## Use Cases

### After Fresh Clone
When someone clones the repository, submodules need initialization:
```
/charts-fork-track
```

### After Adding New Fork
When a new fork was added by someone else:
```
/charts-fork-track cert-manager
```

### Fix Detached HEAD
If a submodule is in detached HEAD state:
```
cd forks/<chart>
git checkout main
```

## Output Format

### Success
```
Submodule Tracking Initialized

| Chart         | Status      | Branch | Commit  |
|---------------|-------------|--------|---------|
| cert-manager  | initialized | main   | abc1234 |
| ingress-nginx | initialized | main   | def5678 |

All submodules are tracked and ready.
```

### Already Tracked
```
Submodule 'cert-manager' is already tracked.
  Branch: main
  Commit: abc1234
```

### Empty State
```
No submodules configured in .gitmodules

To add a fork:
  /charts-fork-add <fork-url>
```

## Error Handling

- **Network error**: "Failed to fetch submodule. Check network and try again."
- **Missing submodule**: "Submodule '<chart>' not found in .gitmodules"
- **Invalid state**: "Submodule in invalid state. Try: git submodule deinit forks/<chart> && git submodule update --init forks/<chart>"
