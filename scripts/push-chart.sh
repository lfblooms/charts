#!/usr/bin/env bash
#
# push-chart.sh — Package and push a Helm chart to an OCI registry.
#
# Reads registry configuration from registry/registries.yaml and uses
# helm package + helm push to publish charts.
#
# Dependencies: helm, yq
#
# Usage:
#   ./scripts/push-chart.sh --chart <chart-path> --registry <name>
#   ./scripts/push-chart.sh --chart <chart-path> --all
#   ./scripts/push-chart.sh --chart <chart-path> --package-only
#
# Examples:
#   ./scripts/push-chart.sh --chart forks/infisical/helm-charts/infisical-standalone-postgres --registry local
#   ./scripts/push-chart.sh --chart forks/harbor-helm --all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRIES_FILE="$REPO_ROOT/registry/registries.yaml"
PACKAGE_DIR="$REPO_ROOT/.packages"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
	echo "Usage: $0 --chart <chart-path> [--registry <name> | --all | --package-only]"
	echo ""
	echo "Options:"
	echo "  --chart <path>       Path to Helm chart directory (required)"
	echo "  --registry <name>    Push to a specific registry defined in registries.yaml"
	echo "  --all                Push to all registries defined in registries.yaml"
	echo "  --package-only       Only package the chart, do not push"
	echo "  --help               Show this help"
	exit 1
}

# Check dependencies
check_deps() {
	local missing=()
	command -v helm >/dev/null 2>&1 || missing+=("helm")
	command -v yq >/dev/null 2>&1 || missing+=("yq")

	if [[ ${#missing[@]} -gt 0 ]]; then
		echo -e "${RED}Missing required tools: ${missing[*]}${NC}" >&2
		exit 1
	fi
}

# Read a registry field from registries.yaml
# Args: $1=registry name, $2=field name
registry_field() {
	yq ".registries.$1.$2" "$REGISTRIES_FILE"
}

# List all registry names
list_registries() {
	yq '.registries | keys | .[]' "$REGISTRIES_FILE"
}

# Package a chart, output the .tgz path
# Args: $1=chart path
package_chart() {
	local chart_path="$1"

	if [[ ! -f "$chart_path/Chart.yaml" ]]; then
		echo -e "${RED}Error: No Chart.yaml found at $chart_path${NC}" >&2
		exit 1
	fi

	local chart_name chart_version
	chart_name=$(yq '.name' "$chart_path/Chart.yaml")
	chart_version=$(yq '.version' "$chart_path/Chart.yaml")

	echo -e "${GREEN}Packaging $chart_name $chart_version ...${NC}"

	mkdir -p "$PACKAGE_DIR"

	# Build dependencies if Chart.lock or dependencies exist
	if [[ -f "$chart_path/Chart.lock" ]] || yq -e '.dependencies' "$chart_path/Chart.yaml" >/dev/null 2>&1; then
		echo -e "${YELLOW}Building chart dependencies...${NC}"
		helm dependency build "$chart_path" --skip-refresh 2>/dev/null || helm dependency build "$chart_path"
	fi

	helm package "$chart_path" --destination "$PACKAGE_DIR"

	echo "$PACKAGE_DIR/$chart_name-$chart_version.tgz"
}

# Push a packaged chart to a registry
# Args: $1=package path (.tgz), $2=registry name
push_to_registry() {
	local pkg_path="$1"
	local reg_name="$2"

	local reg_url reg_plain_http
	reg_url=$(registry_field "$reg_name" "url")
	reg_plain_http=$(registry_field "$reg_name" "plain-http")

	if [[ "$reg_url" == "null" || -z "$reg_url" ]]; then
		echo -e "${RED}Error: Registry '$reg_name' not found in $REGISTRIES_FILE${NC}" >&2
		exit 1
	fi

	local push_args=()
	if [[ "$reg_plain_http" == "true" ]]; then
		push_args+=(--plain-http)
	fi

	local chart_name
	chart_name=$(basename "$pkg_path" | sed 's/-[0-9].*$//')

	echo -e "${GREEN}Pushing $chart_name to oci://$reg_url ...${NC}"

	helm push "$pkg_path" "oci://$reg_url" "${push_args[@]}"

	echo -e "${GREEN}Published: oci://$reg_url/$chart_name${NC}"
}

# Main
main() {
	local chart_path=""
	local registry=""
	local push_all=false
	local package_only=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--chart)
			chart_path="$2"
			shift 2
			;;
		--registry)
			registry="$2"
			shift 2
			;;
		--all)
			push_all=true
			shift
			;;
		--package-only)
			package_only=true
			shift
			;;
		--help | -h)
			usage
			;;
		*)
			echo -e "${RED}Unknown option: $1${NC}" >&2
			usage
			;;
		esac
	done

	if [[ -z "$chart_path" ]]; then
		echo -e "${RED}Error: --chart is required${NC}" >&2
		usage
	fi

	# Resolve relative paths from repo root
	if [[ ! "$chart_path" = /* ]]; then
		chart_path="$REPO_ROOT/$chart_path"
	fi

	check_deps

	if [[ ! -f "$REGISTRIES_FILE" ]]; then
		echo -e "${RED}Error: Registry config not found at $REGISTRIES_FILE${NC}" >&2
		exit 1
	fi

	# Package
	local pkg_path
	pkg_path=$(package_chart "$chart_path" | tail -1)

	if $package_only; then
		echo -e "${GREEN}Package created: $pkg_path${NC}"
		return 0
	fi

	# Push
	if $push_all; then
		local registries
		registries=$(list_registries)
		for reg in $registries; do
			push_to_registry "$pkg_path" "$reg"
		done
	elif [[ -n "$registry" ]]; then
		push_to_registry "$pkg_path" "$registry"
	else
		echo -e "${RED}Error: Specify --registry <name>, --all, or --package-only${NC}" >&2
		usage
	fi
}

main "$@"
