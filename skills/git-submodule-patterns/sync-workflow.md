# Fork Sync Workflow

Step-by-step workflow for syncing a forked chart with upstream changes.

## Pre-Sync Checklist

- [ ] No uncommitted local changes
- [ ] Upstream remote configured
- [ ] Current branch is main/master
- [ ] Local commits documented

## Standard Sync Workflow

### 1. Prepare Environment

```bash
# Navigate to fork
cd forks/<chart-name>

# Ensure clean working directory
git status
# If dirty:
git stash  # or commit changes

# Checkout main branch
git checkout main
```

### 2. Fetch Upstream

```bash
# Fetch all upstream changes
git fetch upstream

# Fetch tags too
git fetch upstream --tags
```

### 3. Analyze Divergence

```bash
# Commits you're behind
git log HEAD..upstream/main --oneline

# Your local commits (ahead)
git log upstream/main..HEAD --oneline

# Files that will conflict
git diff --name-only HEAD upstream/main
```

### 4. Choose Merge Strategy

#### Option A: Merge (Recommended)
Preserves local commit history, creates merge commit.

```bash
git merge upstream/main
```

**Pros:**
- History preserved
- Easy to revert
- Clear audit trail

**Cons:**
- Creates merge commits
- History can be complex

#### Option B: Rebase
Replays local commits on top of upstream.

```bash
git rebase upstream/main
```

**Pros:**
- Linear history
- Cleaner git log

**Cons:**
- Rewrites history
- Must force push
- Can be complex with conflicts

### 5. Resolve Conflicts

If conflicts occur:

```bash
# See conflicting files
git status

# For each file, resolve manually then:
git add <file>

# Continue merge/rebase
git merge --continue  # or
git rebase --continue
```

### 6. Verify Changes

```bash
# Check merge result
git log --oneline -10

# Verify important files
git diff HEAD~1 -- values.yaml
git diff HEAD~1 -- Chart.yaml

# Test helm template
helm template test . > /dev/null
```

### 7. Push to Fork

```bash
# For merge
git push origin main

# For rebase (requires force)
git push origin main --force-with-lease
```

### 8. Update Parent Repository

```bash
# Return to parent
cd ../..

# Commit submodule update
git add forks/<chart-name>
git commit -m "Sync <chart-name> with upstream

Upstream version: v1.x.x
Changes included:
- Feature X
- Bug fix Y"
```

## Conflict Resolution Guide

### values.yaml Conflicts

Most common conflict. Local customizations vs upstream changes.

```yaml
<<<<<<< HEAD
# Your local version
replicaCount: 3
resources:
  requests:
    cpu: 500m
=======
# Upstream version
replicaCount: 1
resources:
  requests:
    cpu: 100m
>>>>>>> upstream/main
```

**Resolution strategy:**
1. Keep local values (your customizations)
2. Add new upstream keys
3. Remove deprecated keys

### Chart.yaml Conflicts

Version and metadata changes.

**Resolution strategy:**
1. Use upstream version number
2. Keep local metadata if needed
3. Update dependencies

### Template Conflicts

More complex, requires careful review.

**Resolution strategy:**
1. Review upstream changes
2. Re-apply local customizations
3. Test with `helm template`

## Emergency Rollback

If sync goes wrong:

```bash
# Abort ongoing merge
git merge --abort

# Or abort ongoing rebase
git rebase --abort

# Reset to previous state
git reset --hard HEAD~1

# Or reset to specific commit
git reset --hard <commit-hash>
```

## Automation Script

```bash
#!/bin/bash
# sync-fork.sh <chart-name>

CHART=$1
cd forks/$CHART || exit 1

# Stash any changes
git stash

# Fetch and merge
git fetch upstream
git merge upstream/main

# Check result
if [ $? -eq 0 ]; then
    echo "Sync successful"
    git stash pop 2>/dev/null
else
    echo "Conflicts detected - manual resolution needed"
    exit 1
fi
```
