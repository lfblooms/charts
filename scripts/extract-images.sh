#!/usr/bin/env bash
#
# extract-images.sh — Extract container image references from a Helm chart.
#
# Renders chart templates and extracts all unique container image references.
# Outputs one fully-qualified image per line to stdout.
#
# Dependencies: helm
#
# Usage:
#   ./scripts/extract-images.sh <chart-path-or-tgz>
#   ./scripts/extract-images.sh <chart-path-or-tgz> --values <file>
#   ./scripts/extract-images.sh <chart-path-or-tgz> --values <file1> --values <file2>
#
# Examples:
#   ./scripts/extract-images.sh forks/harbor-helm
#   ./scripts/extract-images.sh .packages/nextcloud-6.6.6.tgz
#   ./scripts/extract-images.sh forks/vault-helm --values configs/values/vault/base.yaml

set -euo pipefail

usage() {
	echo "Usage: $(basename "$0") <chart-path-or-tgz> [--values <file>]..."
	echo ""
	echo "Extracts container image references from a Helm chart."
	echo "Outputs one fully-qualified image per line to stdout."
	exit 1
}

# Normalize a bare image reference to a fully-qualified form.
#   "nginx:alpine"           → "docker.io/library/nginx:alpine"
#   "stakater/reloader:v1.0" → "docker.io/stakater/reloader:v1.0"
#   "ghcr.io/foo/bar:v1"     → "ghcr.io/foo/bar:v1" (unchanged)
normalize_image() {
	local img="$1"

	# Remove surrounding quotes if present
	img="${img%\"}"
	img="${img#\"}"
	img="${img%\'}"
	img="${img#\'}"

	# Skip empty or placeholder images
	if [[ -z "$img" || "$img" == *"{{"* || "$img" == "null" ]]; then
		return
	fi

	# If no slash at all, it's a bare image name: library image on Docker Hub
	#   "nginx:alpine" → "docker.io/library/nginx:alpine"
	if [[ "$img" != */* ]]; then
		echo "docker.io/library/$img"
		return
	fi

	# If the first component has no dot (no registry host), it's a Docker Hub user image
	#   "stakater/reloader:v1.0" → "docker.io/stakater/reloader:v1.0"
	local first="${img%%/*}"
	if [[ "$first" != *.* && "$first" != *:* ]]; then
		echo "docker.io/$img"
		return
	fi

	# Already fully qualified
	echo "$img"
}

# --- Main ---

if [[ $# -eq 0 ]]; then
	usage
fi

CHART="$1"
shift

VALUES_ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
	--values | -f)
		VALUES_ARGS+=("--values" "$2")
		shift 2
		;;
	--help | -h)
		usage
		;;
	*)
		echo "Unknown option: $1" >&2
		usage
		;;
	esac
done

if ! command -v helm >/dev/null 2>&1; then
	echo "Error: 'helm' is required but not installed." >&2
	exit 1
fi

# Render templates and extract image references
# We use --no-hooks to skip test/hook templates that may have unusual images.
# We also suppress errors from missing CRDs or values — best-effort extraction.
RENDERED=$(helm template extract-images "$CHART" \
	--no-hooks \
	--include-crds=false \
	"${VALUES_ARGS[@]}" 2>/dev/null || true)

if [[ -z "$RENDERED" ]]; then
	echo "Warning: helm template produced no output for $CHART" >&2
	exit 0
fi

# Extract image references from rendered manifests.
# Handles patterns:
#   image: "registry.example.com/repo/image:tag"
#   image: registry.example.com/repo/image:tag
#   image: 'registry.example.com/repo/image:tag'
#   - image: registry.example.com/repo/image:tag
echo "$RENDERED" |
	grep -E '^\s*image:\s' |
	sed -E 's/^[[:space:]]*image:[[:space:]]*//' |
	sed -E 's/^["'"'"']//; s/["'"'"']$//' |
	sed -E 's/[[:space:]]*$//' |
	while IFS= read -r img; do
		normalize_image "$img"
	done |
	sort -u
