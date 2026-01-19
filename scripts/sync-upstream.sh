#!/bin/bash
# sync-upstream.sh - Sync all forks with their upstream repositories
#
# Usage:
#   ./scripts/sync-upstream.sh           # Sync all forks
#   ./scripts/sync-upstream.sh <chart>   # Sync specific chart
#
# Options:
#   --dry-run    Show what would be done without making changes
#   --force      Force sync even with local changes (stashes them)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FORKS_DIR="$REPO_ROOT/forks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
FORCE=false
SPECIFIC_CHART=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            SPECIFIC_CHART="$1"
            shift
            ;;
    esac
done

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

sync_fork() {
    local chart_path="$1"
    local chart_name=$(basename "$chart_path")

    log_info "Syncing $chart_name..."

    cd "$chart_path"

    # Check if upstream remote exists
    if ! git remote get-url upstream &>/dev/null; then
        log_warning "$chart_name: No upstream remote configured. Skipping."
        return 1
    fi

    # Check for local changes
    if [[ -n $(git status --porcelain) ]]; then
        if [[ "$FORCE" == true ]]; then
            log_warning "$chart_name: Stashing local changes"
            if [[ "$DRY_RUN" != true ]]; then
                git stash
            fi
        else
            log_error "$chart_name: Has local changes. Use --force to stash them."
            return 1
        fi
    fi

    # Fetch upstream
    log_info "$chart_name: Fetching upstream..."
    if [[ "$DRY_RUN" != true ]]; then
        git fetch upstream
    fi

    # Check divergence
    local behind=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo "0")
    local ahead=$(git rev-list --count upstream/main..HEAD 2>/dev/null || echo "0")

    log_info "$chart_name: $behind commits behind, $ahead commits ahead"

    if [[ "$behind" -eq 0 ]]; then
        log_success "$chart_name: Already up to date"
        return 0
    fi

    # Attempt merge
    log_info "$chart_name: Merging upstream/main..."
    if [[ "$DRY_RUN" != true ]]; then
        if git merge upstream/main -m "Merge upstream/main into fork"; then
            log_success "$chart_name: Merge successful"
        else
            log_error "$chart_name: Merge conflicts detected. Manual resolution required."
            git merge --abort
            return 1
        fi
    else
        log_info "$chart_name: [DRY RUN] Would merge $behind commits"
    fi

    return 0
}

# Main
echo "=========================================="
echo "  Charts Fork Sync"
echo "=========================================="
echo ""

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Find forks to sync
if [[ -n "$SPECIFIC_CHART" ]]; then
    if [[ -d "$FORKS_DIR/$SPECIFIC_CHART" ]]; then
        CHARTS=("$FORKS_DIR/$SPECIFIC_CHART")
    else
        log_error "Chart '$SPECIFIC_CHART' not found in forks/"
        exit 1
    fi
else
    CHARTS=()
    for dir in "$FORKS_DIR"/*/; do
        if [[ -d "$dir/.git" ]]; then
            CHARTS+=("${dir%/}")
        fi
    done
fi

if [[ ${#CHARTS[@]} -eq 0 ]]; then
    log_warning "No forks found to sync"
    exit 0
fi

# Sync each fork
SUCCESS=0
FAILED=0

for chart in "${CHARTS[@]}"; do
    echo ""
    echo "-------------------------------------------"
    if sync_fork "$chart"; then
        ((SUCCESS++))
    else
        ((FAILED++))
    fi
    cd "$REPO_ROOT"
done

# Summary
echo ""
echo "=========================================="
echo "  Sync Summary"
echo "=========================================="
echo ""
log_info "Total: $((SUCCESS + FAILED)) forks"
log_success "Successful: $SUCCESS"
if [[ $FAILED -gt 0 ]]; then
    log_error "Failed: $FAILED"
fi

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
