#!/bin/bash
# validate-values.sh - Validate all values files against chart schemas
#
# Usage:
#   ./scripts/validate-values.sh           # Validate all charts
#   ./scripts/validate-values.sh <chart>   # Validate specific chart
#
# Options:
#   --strict     Fail on warnings (default: only fail on errors)
#   --verbose    Show detailed output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FORKS_DIR="$REPO_ROOT/forks"
VALUES_DIR="$REPO_ROOT/configs/values"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
STRICT=false
VERBOSE=false
SPECIFIC_CHART=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --strict)
            STRICT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
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
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "       $1"
    fi
}

# Check for required tools
check_dependencies() {
    local missing=()

    if ! command -v yq &>/dev/null; then
        missing+=("yq")
    fi

    if ! command -v helm &>/dev/null; then
        missing+=("helm")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        echo "Install with:"
        echo "  brew install yq helm"
        exit 1
    fi
}

# Validate YAML syntax
validate_yaml_syntax() {
    local file="$1"

    if yq eval '.' "$file" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Validate with helm template
validate_helm_template() {
    local chart_path="$1"
    local values_files="$2"

    local helm_args=()
    for vf in $values_files; do
        helm_args+=("-f" "$vf")
    done

    if helm template test "$chart_path" "${helm_args[@]}" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check best practices
check_best_practices() {
    local file="$1"
    local warnings=0

    # Check for resources
    if ! yq eval '.resources.requests' "$file" 2>/dev/null | grep -q "cpu\|memory"; then
        log_warning "  No resource requests defined"
        ((warnings++))
    fi

    if ! yq eval '.resources.limits' "$file" 2>/dev/null | grep -q "cpu\|memory"; then
        log_warning "  No resource limits defined"
        ((warnings++))
    fi

    # Check for image tag
    local tag=$(yq eval '.image.tag // ""' "$file" 2>/dev/null)
    if [[ "$tag" == "latest" ]]; then
        log_warning "  Image tag is 'latest' - consider pinning version"
        ((warnings++))
    fi

    # Check for replica count in prod
    if [[ "$file" == *"prod"* ]]; then
        local replicas=$(yq eval '.replicaCount // 1' "$file" 2>/dev/null)
        if [[ "$replicas" -lt 2 ]]; then
            log_warning "  Production with replicaCount < 2"
            ((warnings++))
        fi
    fi

    return $warnings
}

# Validate a single chart
validate_chart() {
    local chart_name="$1"
    local chart_path="$FORKS_DIR/$chart_name"
    local values_path="$VALUES_DIR/$chart_name"

    log_info "Validating $chart_name..."

    local errors=0
    local warnings=0

    # Check if chart exists
    if [[ ! -d "$chart_path" ]]; then
        log_error "  Chart not found at $chart_path"
        return 1
    fi

    # Check if values exist
    if [[ ! -d "$values_path" ]]; then
        log_warning "  No values configured for $chart_name"
        return 0
    fi

    # Find all values files
    local values_files=()
    for vf in "$values_path"/*.yaml; do
        if [[ -f "$vf" ]]; then
            values_files+=("$vf")
        fi
    done

    if [[ ${#values_files[@]} -eq 0 ]]; then
        log_warning "  No values files found"
        return 0
    fi

    # Validate each values file
    for vf in "${values_files[@]}"; do
        local filename=$(basename "$vf")
        log_verbose "Checking $filename..."

        # YAML syntax
        if ! validate_yaml_syntax "$vf"; then
            log_error "  $filename: Invalid YAML syntax"
            ((errors++))
            continue
        fi
        log_verbose "  YAML syntax: OK"

        # Best practices
        local bp_warnings=0
        check_best_practices "$vf"
        bp_warnings=$?
        ((warnings += bp_warnings))
    done

    # Test helm template with merged values
    local base_file="$values_path/base.yaml"
    if [[ -f "$base_file" ]]; then
        for vf in "${values_files[@]}"; do
            if [[ "$vf" != "$base_file" ]]; then
                local context=$(basename "$vf" .yaml)
                log_verbose "Testing helm template with base + $context..."

                if ! validate_helm_template "$chart_path" "$base_file $vf"; then
                    log_error "  Helm template failed with base + $context"
                    ((errors++))
                fi
            fi
        done
    fi

    # Summary for this chart
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        log_success "$chart_name: All validations passed"
    elif [[ $errors -eq 0 ]]; then
        log_success "$chart_name: Passed with $warnings warning(s)"
    else
        log_error "$chart_name: $errors error(s), $warnings warning(s)"
    fi

    if [[ $errors -gt 0 ]]; then
        return 1
    elif [[ $warnings -gt 0 && "$STRICT" == true ]]; then
        return 1
    fi
    return 0
}

# Main
echo "=========================================="
echo "  Values Validation"
echo "=========================================="
echo ""

check_dependencies

if [[ "$STRICT" == true ]]; then
    log_info "Running in STRICT mode (warnings = failures)"
fi
echo ""

# Find charts to validate
if [[ -n "$SPECIFIC_CHART" ]]; then
    CHARTS=("$SPECIFIC_CHART")
else
    CHARTS=()
    for dir in "$VALUES_DIR"/*/; do
        if [[ -d "$dir" ]]; then
            CHARTS+=("$(basename "${dir%/}")")
        fi
    done
fi

if [[ ${#CHARTS[@]} -eq 0 ]]; then
    log_warning "No values found to validate"
    echo ""
    echo "Create values with:"
    echo "  /charts-values-create <chart> <context>"
    exit 0
fi

# Validate each chart
SUCCESS=0
FAILED=0

for chart in "${CHARTS[@]}"; do
    if validate_chart "$chart"; then
        ((SUCCESS++))
    else
        ((FAILED++))
    fi
    echo ""
done

# Summary
echo "=========================================="
echo "  Validation Summary"
echo "=========================================="
echo ""
log_info "Total: $((SUCCESS + FAILED)) charts"
log_success "Passed: $SUCCESS"
if [[ $FAILED -gt 0 ]]; then
    log_error "Failed: $FAILED"
fi

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
