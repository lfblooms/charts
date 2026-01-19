# Sync Chart Fork

Sync a fork with upstream changes, handling conflicts and preserving local customizations.

## Arguments

- `<chart>` - Name of the chart to sync (required)

## Instructions

1. **Validate Fork Exists**: Check `forks/<chart>` exists

2. **Check Upstream Remote**: Verify upstream remote is configured
   ```bash
   cd forks/<chart>
   git remote get-url upstream
   ```

3. **Fetch Upstream**: Get latest upstream changes
   ```bash
   git fetch upstream
   ```

4. **Analyze Divergence**: Compare local vs upstream
   ```bash
   git log --oneline HEAD..upstream/main | wc -l  # commits behind
   git log --oneline upstream/main..HEAD | wc -l  # local commits ahead
   ```

5. **Check for Conflicts**: Preview merge
   ```bash
   git merge-tree $(git merge-base HEAD upstream/main) HEAD upstream/main
   ```

6. **Present Options**:
   - If clean merge possible: Offer to merge
   - If conflicts: Show conflicting files, suggest manual resolution
   - If local ahead: Warn about rebasing implications

7. **Execute Sync** (with user confirmation):
   ```bash
   git merge upstream/main
   # OR for rebase:
   git rebase upstream/main
   ```

## Output Format

### Status Report
```
Sync Status: cert-manager

Current:    main @ abc1234
Upstream:   upstream/main @ xyz9876

Divergence:
  - 5 commits behind upstream
  - 2 local commits (customizations)

Changed Files in Upstream:
  - values.yaml (modified)
  - templates/deployment.yaml (modified)
  - Chart.yaml (version bump)

Local Customizations:
  - values.yaml (custom defaults)
  - templates/custom-resource.yaml (added)

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

- **No upstream**: "Upstream remote not configured. Add it with: cd forks/<chart> && git remote add upstream <url>"
- **Uncommitted changes**: "Local changes detected. Commit or stash before syncing."
- **Conflicts**: "Conflicts detected in: <files>. Manual resolution required."

## Post-Sync Actions

After successful sync:
1. Run `/charts-values-validate <chart>` to check values compatibility
2. Review chart version changes
3. Update values if new options available
4. Commit the merge to the main repository
