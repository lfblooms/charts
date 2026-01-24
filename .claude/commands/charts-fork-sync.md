# Sync Chart Fork

Sync a fork with upstream changes, handling conflicts and preserving local customizations.

## Arguments

- `<repo>` - Name of the repository to sync (required)

## Repository Structure

```
forks/<repo>/                    # Git submodule (fork)
├── helm-charts/                 # Helm charts location
│   └── <chart-name>/            # Individual chart
└── ...                          # Other repo contents
```

## Instructions

1. **Validate Fork Exists**: Check `forks/<repo>` exists and is a submodule

2. **Check Upstream Remote**: Verify upstream remote is configured
   ```bash
   git -C forks/<repo> remote get-url upstream
   ```

3. **Fetch Upstream**: Get latest upstream changes
   ```bash
   git -C forks/<repo> fetch upstream
   ```

4. **Analyze Divergence**: Compare local vs upstream
   ```bash
   git -C forks/<repo> log --oneline HEAD..upstream/main | wc -l  # commits behind
   git -C forks/<repo> log --oneline upstream/main..HEAD | wc -l  # local commits ahead
   ```

5. **Check for Conflicts**: Preview merge
   ```bash
   git -C forks/<repo> merge-tree $(git -C forks/<repo> merge-base HEAD upstream/main) HEAD upstream/main
   ```

6. **Present Options**:
   - If clean merge possible: Offer to merge
   - If conflicts: Show conflicting files, suggest manual resolution
   - If local ahead: Warn about rebasing implications

7. **Execute Sync** (with user confirmation):
   ```bash
   git -C forks/<repo> merge upstream/main
   ```

8. **Update Parent Repo**: Commit submodule update
   ```bash
   git add forks/<repo>
   git commit -m "Sync <repo> with upstream"
   ```

## Output Format

### Status Report
```
Sync Status: infisical

Fork: forks/infisical
  Origin:   MisterGrinvalds/Infisical.infisical
  Upstream: Infisical/infisical

Current:    main @ abc1234
Upstream:   upstream/main @ xyz9876

Divergence:
  - 5 commits behind upstream
  - 2 local commits (customizations)

Changed Files in Upstream:
  - helm-charts/infisical-standalone-postgres/values.yaml (modified)
  - helm-charts/infisical-standalone-postgres/Chart.yaml (version bump)

Conflict Analysis: No conflicts detected
```

### Merge Options
```
Options:
  1. Merge upstream (preserves history)
  2. Rebase on upstream (cleaner history, rewrites local commits)
  3. Cherry-pick specific commits
  4. Cancel

Recommendation: Option 1 (merge) - Your local customizations will be preserved.
```

## Error Handling

- **No upstream**: "Upstream remote not configured. Run: git -C forks/<repo> remote add upstream <url>"
- **Uncommitted changes**: "Local changes detected. Commit or stash before syncing."
- **Conflicts**: "Conflicts detected in: <files>. Manual resolution required."

## Post-Sync Actions

After successful sync:
1. Update chart dependencies: `make <repo>-deps`
2. Run `/charts-values-validate <chart>` to check values compatibility
3. Push fork changes: `git -C forks/<repo> push origin main`
4. Commit and push parent repo
