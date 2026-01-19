# Git Submodule Commands Reference

## Quick Reference

| Task | Command |
|------|---------|
| Add submodule | `git submodule add <url> <path>` |
| Initialize | `git submodule init` |
| Update | `git submodule update` |
| Init + Update | `git submodule update --init` |
| Update to latest | `git submodule update --remote` |
| Status | `git submodule status` |
| Foreach | `git submodule foreach '<cmd>'` |
| Remove | `git submodule deinit <path> && git rm <path>` |

## Detailed Commands

### Adding Submodules

```bash
# Basic add
git submodule add https://github.com/user/repo path/to/submodule

# Add with specific branch
git submodule add -b main https://github.com/user/repo path/to/submodule

# Add with custom name
git submodule add --name my-custom-name https://github.com/user/repo path
```

### Cloning with Submodules

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/user/repo

# Clone then initialize
git clone https://github.com/user/repo
cd repo
git submodule update --init --recursive
```

### Updating Submodules

```bash
# Update to commit recorded in parent
git submodule update

# Update to latest on tracked branch
git submodule update --remote

# Update with merge
git submodule update --remote --merge

# Update with rebase
git submodule update --remote --rebase

# Update specific submodule
git submodule update --remote path/to/submodule
```

### Status and Information

```bash
# Basic status
git submodule status

# Recursive status
git submodule status --recursive

# Summary of changes
git submodule summary

# Show submodule configuration
git config --file .gitmodules --list
```

### Foreach Operations

```bash
# Run command in each submodule
git submodule foreach 'git status'

# Fetch all submodules
git submodule foreach 'git fetch'

# Pull all submodules
git submodule foreach 'git pull origin main'

# With nested submodules
git submodule foreach --recursive 'git status'
```

### Configuration

```bash
# Set branch to track
git config -f .gitmodules submodule.<name>.branch main

# Set update strategy
git config -f .gitmodules submodule.<name>.update merge

# Ignore dirty submodule
git config -f .gitmodules submodule.<name>.ignore dirty
```

### Removing Submodules

```bash
# Step 1: Deinitialize
git submodule deinit path/to/submodule

# Step 2: Remove from tracking
git rm path/to/submodule

# Step 3: Clean up (optional)
rm -rf .git/modules/path/to/submodule

# Step 4: Commit
git commit -m "Remove submodule"
```

### Troubleshooting

```bash
# Reset submodule to recorded commit
git submodule update --force path/to/submodule

# Re-initialize a submodule
git submodule deinit path/to/submodule
git submodule update --init path/to/submodule

# Sync URLs (if .gitmodules changed)
git submodule sync
git submodule update --init
```

## .gitmodules Format

```gitmodules
[submodule "name"]
    path = path/to/submodule
    url = https://github.com/user/repo
    branch = main
    update = merge
    ignore = dirty
```

### Options

- `path` - Where submodule is checked out
- `url` - Repository URL
- `branch` - Branch to track (default: remote HEAD)
- `update` - Update strategy: checkout, merge, rebase, none
- `ignore` - Dirty checking: none, dirty, untracked, all
