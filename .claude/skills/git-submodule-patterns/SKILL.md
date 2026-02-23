# Git Submodule Patterns Skill

Domain knowledge for git submodule management and fork synchronization patterns.

## Triggers

This skill activates on:
- "submodule"
- "fork management"
- "upstream sync"

## Knowledge Areas

### Submodule Basics

#### Adding a Submodule
```bash
# Add submodule
git submodule add <repository-url> <path>

# Example
git submodule add https://github.com/user/chart forks/chart
```

#### Initializing Submodules
```bash
# After cloning a repo with submodules
git submodule init
git submodule update

# Or in one command
git submodule update --init

# Recursive (for nested submodules)
git submodule update --init --recursive
```

#### Checking Submodule Status
```bash
# Show submodule status
git submodule status

# Detailed status
git submodule foreach 'git status'
```

### Fork Management Pattern

#### Setting Up a Fork with Upstream
```bash
# Clone your fork
git clone https://github.com/you/forked-repo

# Add upstream remote
cd forked-repo
git remote add upstream https://github.com/original/repo

# Verify remotes
git remote -v
# origin    https://github.com/you/forked-repo (fetch)
# origin    https://github.com/you/forked-repo (push)
# upstream  https://github.com/original/repo (fetch)
# upstream  https://github.com/original/repo (push)
```

#### Syncing Fork with Upstream
```bash
# Fetch upstream changes
git fetch upstream

# Check divergence
git log HEAD..upstream/main --oneline  # commits behind
git log upstream/main..HEAD --oneline  # commits ahead

# Merge upstream (preserves history)
git merge upstream/main

# Or rebase (cleaner history)
git rebase upstream/main

# Push to your fork
git push origin main
```

### Submodule Workflows

#### Updating Submodules to Latest
```bash
# Update all submodules to latest commit on their branch
git submodule update --remote

# Update specific submodule
git submodule update --remote forks/chart

# Merge strategy (instead of checkout)
git submodule update --remote --merge
```

#### Working Within Submodules
```bash
# Enter submodule
cd forks/chart

# Make changes
git checkout -b my-feature
# ... edit files ...
git commit -m "Add feature"

# Push to fork
git push origin my-feature

# Return to parent and commit pointer update
cd ../..
git add forks/chart
git commit -m "Update chart submodule"
```

#### Handling Detached HEAD
```bash
# Submodules default to detached HEAD
cd forks/chart

# Checkout the branch you want to track
git checkout main

# Or configure submodule to track a branch
git config -f .gitmodules submodule.forks/chart.branch main
git submodule update --remote
```

### Common Issues and Solutions

#### Submodule Not Initialized
```bash
# Error: No submodule mapping found
git submodule init
git submodule update
```

#### Submodule Has Local Changes
```bash
# Check what changed
cd forks/chart
git status
git diff

# Stash changes
git stash

# Or commit changes
git add .
git commit -m "Local changes"
```

#### Submodule Conflicts During Merge
```bash
# When parent repo has submodule conflicts
git checkout --theirs forks/chart
git add forks/chart

# Or resolve manually
cd forks/chart
git checkout <desired-commit>
cd ../..
git add forks/chart
```

#### Removing a Submodule
```bash
# Deinitialize
git submodule deinit forks/chart

# Remove from .gitmodules and .git/config
git rm forks/chart

# Remove cached data
rm -rf .git/modules/forks/chart

# Commit
git commit -m "Remove chart submodule"
```

### Best Practices

#### 1. Track Specific Branches
```gitmodules
[submodule "forks/chart"]
    path = forks/chart
    url = https://github.com/user/chart
    branch = main
```

#### 2. Document Upstream Remotes
Keep a record of upstream URLs for each fork:
```
# forks/chart
# Origin: https://github.com/user/chart
# Upstream: https://github.com/original/chart
```

#### 3. Regular Sync Schedule
- Check for upstream updates weekly
- Apply security patches immediately
- Plan major version upgrades

#### 4. Commit Submodule Updates Atomically
```bash
# Update submodule
cd forks/chart
git pull origin main
cd ../..

# Commit with clear message
git add forks/chart
git commit -m "Update chart to v1.2.3

- Security fix for CVE-xxxx
- New feature: thing"
```

#### 5. Use .gitmodules for Configuration
```gitmodules
[submodule "forks/cert-manager"]
    path = forks/cert-manager
    url = https://github.com/user/cert-manager
    branch = main

[submodule "forks/ingress-nginx"]
    path = forks/ingress-nginx
    url = https://github.com/user/ingress-nginx
    branch = main
```

### Submodule vs Subtree

| Aspect | Submodule | Subtree |
|--------|-----------|---------|
| Storage | Pointer only | Full copy |
| History | Separate | Merged |
| Updates | Manual fetch | Merge/pull |
| Complexity | Higher | Lower |
| Use case | Active development | Vendoring |

**Use submodules when:**
- You need to track upstream changes
- You want to contribute back
- You need to maintain fork customizations

**Use subtrees when:**
- You want a snapshot
- You don't need to sync frequently
- You want simpler workflow
