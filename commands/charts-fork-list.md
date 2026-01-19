# List Chart Forks

List all tracked chart forks with their sync status.

## Instructions

1. **Read .gitmodules**: Parse the gitmodules file for submodule entries
2. **Check Each Fork**: For each fork in `forks/`:
   - Get current branch and commit
   - Check for local uncommitted changes
   - Check if upstream remote is configured
   - Compare with upstream if available

3. **Format Output**: Present as a table

## Commands to Execute

```bash
# List all submodules with status
git submodule foreach --quiet 'echo "$name|$(git rev-parse --short HEAD)|$(git branch --show-current)|$(git status --porcelain | wc -l | tr -d " ")"'

# Or if no submodules, check forks directory
ls -1 forks/ 2>/dev/null | grep -v '.gitkeep'
```

## Output Format

### With Forks
```
Chart Forks:

| Chart          | Branch | Commit  | Local Changes | Upstream |
|----------------|--------|---------|---------------|----------|
| cert-manager   | main   | abc1234 | clean         | 3 behind |
| ingress-nginx  | main   | def5678 | 2 modified    | current  |

Total: 2 forks tracked
```

### Empty State
```
No forks tracked.

To add a fork:
  /charts-fork-add <fork-url>
```

## Sync Status Meanings

- **clean**: No local changes
- **N modified**: N files with uncommitted changes
- **N behind**: Commits behind upstream
- **current**: Up to date with upstream
- **no upstream**: Upstream remote not configured
