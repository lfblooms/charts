#!/usr/bin/env bash
#
# mirror-chart.sh — Mirror Helm chart versions and container images to an OCI registry.
#
# Pulls chart versions from upstream (traditional Helm repo, OCI registry, or local fork),
# pushes chart OCI artifacts to a target registry, extracts container image references,
# and copies images using crane.
#
# Dependencies: helm, yq, crane, oras (for existence checks)
#
# Usage:
#   ./scripts/mirror-chart.sh --chart <name> --registry <name>
#   ./scripts/mirror-chart.sh --chart <name> --since <version> --registry <name>
#   ./scripts/mirror-chart.sh --chart <name> --registry <name> --dry-run
#   ./scripts/mirror-chart.sh --chart <name> --registry <name> --charts-only
#   ./scripts/mirror-chart.sh --chart <name> --registry <name> --images-only
#
# Examples:
#   ./scripts/mirror-chart.sh --chart nextcloud --registry docr
#   ./scripts/mirror-chart.sh --chart vault --since 0.28.0 --registry docr --dry-run
#   ./scripts/mirror-chart.sh --chart keycloak --since 24.0.0 --registry docr --charts-only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UPSTREAMS_FILE="$REPO_ROOT/registry/upstreams.yaml"
SINCE_FILE="$REPO_ROOT/registry/mirror-since.yaml"
REGISTRIES_FILE="$REPO_ROOT/registry/registries.yaml"
EXTRACT_IMAGES="$SCRIPT_DIR/extract-images.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# Counters
CHARTS_PUSHED=0
CHARTS_SKIPPED=0
IMAGES_COPIED=0
IMAGES_SKIPPED=0
IMAGES_FAILED=0

# Detect crane binary
CRANE=""
if command -v crane >/dev/null 2>&1; then
	CRANE="crane"
elif [[ -x "$HOME/go/bin/crane" ]]; then
	CRANE="$HOME/go/bin/crane"
fi

usage() {
	echo "Usage: $(basename "$0") --chart <name> [--since <version>] [--registry <name>] [options]"
	echo ""
	echo "Options:"
	echo "  --chart <name>       Chart key from upstreams.yaml (required)"
	echo "  --since <version>    Minimum version to mirror (reads from mirror-since.yaml if omitted)"
	echo "  --registry <name>    Target registry from registries.yaml (default: docr)"
	echo "  --dry-run            List what would be mirrored without doing it"
	echo "  --charts-only        Mirror chart artifacts only, skip images"
	echo "  --images-only        Mirror images only, skip chart artifacts"
	echo "  --help               Show this help"
	exit 1
}

check_deps() {
	local missing=()
	command -v helm >/dev/null 2>&1 || missing+=("helm")
	command -v yq >/dev/null 2>&1 || missing+=("yq")

	if [[ ${#missing[@]} -gt 0 ]]; then
		echo -e "${RED}Missing required tools: ${missing[*]}${NC}" >&2
		exit 1
	fi

	if [[ -z "$CRANE" ]]; then
		echo -e "${YELLOW}Warning: 'crane' not found. Image mirroring will be skipped.${NC}" >&2
		echo -e "${YELLOW}Install with: brew install crane${NC}" >&2
	fi
}

# Read a field from upstreams.yaml for a given chart key.
# Args: $1=chart key, $2=field path
upstream_field() {
	yq ".upstreams.\"$1\".$2" "$UPSTREAMS_FILE"
}

# Read the --since threshold from mirror-since.yaml for a given chart key.
# Returns empty string if not found.
read_since() {
	local key="$1"
	local val
	val=$(yq ".since.\"$key\" // \"\"" "$SINCE_FILE" 2>/dev/null)
	echo "$val"
}

# Read registry URL from registries.yaml.
# Args: $1=registry name
registry_url() {
	yq ".registries.$1.url" "$REGISTRIES_FILE"
}

# Compare two semver strings. Returns 0 if $1 >= $2, 1 otherwise.
# Uses sort -V for natural version comparison.
version_gte() {
	local v1="$1" v2="$2"
	# Strip leading 'v' if present
	v1="${v1#v}"
	v2="${v2#v}"
	[[ "$(printf '%s\n%s' "$v2" "$v1" | sort -V | head -1)" == "$v2" ]]
}

# Check if a chart version already exists in the target registry.
# Uses oras (fastest) with crane fallback.
# Args: $1=full OCI reference (e.g., registry.digitalocean.com/greenforests/nextcloud:6.6.6)
artifact_exists() {
	local ref="$1"
	if command -v oras >/dev/null 2>&1; then
		oras manifest fetch "$ref" >/dev/null 2>&1
		return $?
	elif [[ -n "$CRANE" ]]; then
		$CRANE manifest "$ref" >/dev/null 2>&1
		return $?
	else
		helm show chart "oci://${ref%:*}" --version "${ref##*:}" >/dev/null 2>&1
		return $?
	fi
}

# Discover available versions for a chart from its upstream source.
# Outputs one version per line, sorted by version.
# Args: $1=chart key
discover_versions() {
	local key="$1"
	local source_type
	source_type=$(upstream_field "$key" "source_type")

	case "$source_type" in
	repo)
		local repo_name repo_url chart_name
		repo_name=$(upstream_field "$key" "repo_name")
		repo_url=$(upstream_field "$key" "repo_url")
		chart_name=$(upstream_field "$key" "chart_name")

		# Ensure repo is added
		helm repo add "$repo_name" "$repo_url" >/dev/null 2>&1 || true
		helm repo update "$repo_name" >/dev/null 2>&1 || true

		# List versions (skip header line, extract version column)
		helm search repo "$repo_name/$chart_name" --versions 2>/dev/null |
			tail -n +2 |
			awk '{print $2}' |
			sort -V
		;;
	oci)
		local oci_url chart_name
		oci_url=$(upstream_field "$key" "oci_url")
		chart_name=$(upstream_field "$key" "chart_name")

		# Strip oci:// prefix for crane
		local registry_path="${oci_url#oci://}/$chart_name"

		if [[ -n "$CRANE" ]]; then
			$CRANE ls "$registry_path" 2>/dev/null | sort -V
		else
			echo -e "${YELLOW}Cannot list OCI tags without crane${NC}" >&2
			return 1
		fi
		;;
	local)
		local chart_path
		chart_path=$(upstream_field "$key" "chart_path")
		local full_path="$REPO_ROOT/$chart_path"

		if [[ -f "$full_path/Chart.yaml" ]]; then
			yq '.version' "$full_path/Chart.yaml"
		else
			echo -e "${RED}Chart.yaml not found at $full_path${NC}" >&2
			return 1
		fi
		;;
	*)
		echo -e "${RED}Unknown source_type '$source_type' for chart '$key'${NC}" >&2
		return 1
		;;
	esac
}

# Pull a chart version to a temporary directory.
# Outputs the path to the .tgz file.
# Args: $1=chart key, $2=version, $3=destination directory
pull_chart() {
	local key="$1" version="$2" dest="$3"
	local source_type
	source_type=$(upstream_field "$key" "source_type")

	case "$source_type" in
	repo)
		local repo_name chart_name
		repo_name=$(upstream_field "$key" "repo_name")
		chart_name=$(upstream_field "$key" "chart_name")

		helm pull "$repo_name/$chart_name" --version "$version" --destination "$dest" 2>/dev/null
		echo "$dest/$chart_name-$version.tgz"
		;;
	oci)
		local oci_url chart_name
		oci_url=$(upstream_field "$key" "oci_url")
		chart_name=$(upstream_field "$key" "chart_name")

		helm pull "$oci_url/$chart_name" --version "$version" --destination "$dest" 2>/dev/null
		echo "$dest/$chart_name-$version.tgz"
		;;
	local)
		local chart_path chart_name
		chart_path=$(upstream_field "$key" "chart_path")
		chart_name=$(upstream_field "$key" "chart_name")
		local full_path="$REPO_ROOT/$chart_path"

		# Build dependencies if needed
		if [[ -f "$full_path/Chart.lock" ]] || yq -e '.dependencies' "$full_path/Chart.yaml" >/dev/null 2>&1; then
			helm dependency build "$full_path" --skip-refresh 2>/dev/null || helm dependency build "$full_path" 2>/dev/null || true
		fi

		helm package "$full_path" --destination "$dest" 2>/dev/null
		echo "$dest/$chart_name-$version.tgz"
		;;
	esac
}

# Map a source image to its target path in the mirror registry.
# Strips the source registry host and prepends the target registry URL.
#   ghcr.io/stakater/reloader:v1.2.1 → registry.digitalocean.com/greenforests/stakater/reloader:v1.2.1
#   docker.io/library/nginx:alpine   → registry.digitalocean.com/greenforests/library/nginx:alpine
# Args: $1=source image, $2=target registry URL
map_image_target() {
	local src="$1" target_reg="$2"

	# Split image into registry+path and tag
	local img_no_tag tag
	if [[ "$src" == *@sha256:* ]]; then
		# Digest reference — preserve as-is
		img_no_tag="${src%@*}"
		tag="@${src#*@}"
	elif [[ "$src" == *:* ]]; then
		# Last colon separates tag (but not port in registry host)
		# Handle cases like registry.k8s.io:443/foo:v1 by being careful
		img_no_tag="${src%:*}"
		tag=":${src##*:}"
	else
		img_no_tag="$src"
		tag=":latest"
	fi

	# Strip registry host (everything before first /)
	local path="${img_no_tag#*/}"

	echo "$target_reg/$path$tag"
}

# --- Main ---

main() {
	local chart_key=""
	local since=""
	local registry="docr"
	local dry_run=false
	local charts_only=false
	local images_only=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--chart)
			chart_key="$2"
			shift 2
			;;
		--since)
			since="$2"
			shift 2
			;;
		--registry)
			registry="$2"
			shift 2
			;;
		--dry-run)
			dry_run=true
			shift
			;;
		--charts-only)
			charts_only=true
			shift
			;;
		--images-only)
			images_only=true
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

	if [[ -z "$chart_key" ]]; then
		echo -e "${RED}Error: --chart is required${NC}" >&2
		usage
	fi

	check_deps

	# Validate chart exists in upstreams.yaml
	local source_type
	source_type=$(upstream_field "$chart_key" "source_type")
	if [[ "$source_type" == "null" || -z "$source_type" ]]; then
		echo -e "${RED}Error: Chart '$chart_key' not found in $UPSTREAMS_FILE${NC}" >&2
		exit 1
	fi

	# Read --since from mirror-since.yaml if not provided
	if [[ -z "$since" ]]; then
		since=$(read_since "$chart_key")
		if [[ -z "$since" ]]; then
			echo -e "${RED}Error: No --since provided and '$chart_key' not found in $SINCE_FILE${NC}" >&2
			echo -e "${RED}Provide --since <version> or add an entry to mirror-since.yaml${NC}" >&2
			exit 1
		fi
		echo -e "${DIM}Using since=$since from mirror-since.yaml${NC}"
	fi

	# Resolve target registry URL
	local target_url
	target_url=$(registry_url "$registry")
	if [[ "$target_url" == "null" || -z "$target_url" ]]; then
		echo -e "${RED}Error: Registry '$registry' not found in $REGISTRIES_FILE${NC}" >&2
		exit 1
	fi

	local chart_name
	chart_name=$(upstream_field "$chart_key" "chart_name")

	echo -e "${BLUE}Mirror: $chart_key ($chart_name) → $target_url${NC}"
	echo -e "${BLUE}Since:  $since${NC}"
	echo ""

	# Discover available versions
	echo -e "${DIM}Discovering upstream versions...${NC}"
	local all_versions
	all_versions=$(discover_versions "$chart_key")

	if [[ -z "$all_versions" ]]; then
		echo -e "${YELLOW}No versions found for '$chart_key'${NC}"
		return 0
	fi

	# Filter versions >= since
	local versions=()
	while IFS= read -r ver; do
		# Skip empty lines, pre-release suffixes that aren't semver-clean
		[[ -z "$ver" ]] && continue
		if version_gte "$ver" "$since"; then
			versions+=("$ver")
		fi
	done <<<"$all_versions"

	if [[ ${#versions[@]} -eq 0 ]]; then
		echo -e "${YELLOW}No versions >= $since found for '$chart_key'${NC}"
		return 0
	fi

	echo -e "${GREEN}Found ${#versions[@]} version(s) >= $since${NC}"
	echo ""

	# Create temp working directory
	local workdir
	workdir=$(mktemp -d -t mirror-chart-XXXXXX)
	trap "rm -rf '$workdir'" EXIT

	# Process each version
	for ver in "${versions[@]}"; do
		echo -e "${BLUE}── $chart_name:$ver ──${NC}"

		# --- Chart mirroring ---
		if ! $images_only; then
			local chart_ref="$target_url/$chart_name:$ver"

			if artifact_exists "$chart_ref"; then
				echo -e "  ${DIM}Chart: already exists, skipping${NC}"
				CHARTS_SKIPPED=$((CHARTS_SKIPPED + 1))
			elif $dry_run; then
				echo -e "  ${YELLOW}Chart: would push → oci://$target_url/$chart_name:$ver${NC}"
				CHARTS_PUSHED=$((CHARTS_PUSHED + 1))
			else
				# Pull and push
				local ver_dir="$workdir/$ver"
				mkdir -p "$ver_dir"

				local pkg_path
				pkg_path=$(pull_chart "$chart_key" "$ver" "$ver_dir")

				if [[ -f "$pkg_path" ]]; then
					echo -ne "  Chart: pushing... "
					if helm push "$pkg_path" "oci://$target_url" 2>/dev/null; then
						echo -e "${GREEN}OK${NC}"
						CHARTS_PUSHED=$((CHARTS_PUSHED + 1))
					else
						echo -e "${RED}FAILED${NC}"
					fi
				else
					echo -e "  ${RED}Chart: failed to pull $chart_name:$ver${NC}"
				fi
			fi
		fi

		# --- Image mirroring ---
		if ! $charts_only; then
			if [[ -z "$CRANE" ]] && ! $dry_run; then
				echo -e "  ${YELLOW}Images: skipped (crane not available)${NC}"
				continue
			fi

			# Pull chart if we haven't already (images-only mode)
			local ver_dir="$workdir/$ver"
			local pkg_path="$ver_dir/$chart_name-$ver.tgz"
			if [[ ! -f "$pkg_path" ]]; then
				mkdir -p "$ver_dir"
				pkg_path=$(pull_chart "$chart_key" "$ver" "$ver_dir" 2>/dev/null) || true
			fi

			if [[ ! -f "$pkg_path" ]]; then
				echo -e "  ${YELLOW}Images: could not pull chart, skipping${NC}"
				continue
			fi

			# Extract images
			local images
			images=$("$EXTRACT_IMAGES" "$pkg_path" 2>/dev/null || true)

			if [[ -z "$images" ]]; then
				echo -e "  ${DIM}Images: none found${NC}"
				continue
			fi

			local img_count
			img_count=$(echo "$images" | wc -l | tr -d ' ')
			echo -e "  Images: $img_count found"

			while IFS= read -r src_image; do
				[[ -z "$src_image" ]] && continue

				local target_image
				target_image=$(map_image_target "$src_image" "$target_url")

				if $dry_run; then
					echo -e "    ${YELLOW}$src_image → $target_image${NC}"
					IMAGES_COPIED=$((IMAGES_COPIED + 1))
					continue
				fi

				# Check if target already exists
				if $CRANE manifest "$target_image" >/dev/null 2>&1; then
					echo -e "    ${DIM}$src_image → exists${NC}"
					IMAGES_SKIPPED=$((IMAGES_SKIPPED + 1))
					continue
				fi

				# Copy image
				echo -ne "    $src_image → "
				if $CRANE copy "$src_image" "$target_image" 2>/dev/null; then
					echo -e "${GREEN}OK${NC}"
					IMAGES_COPIED=$((IMAGES_COPIED + 1))
				else
					echo -e "${RED}FAILED${NC}"
					IMAGES_FAILED=$((IMAGES_FAILED + 1))
				fi
			done <<<"$images"
		fi

		echo ""
	done

	# Summary
	echo -e "${BLUE}════════════════════════════════════════${NC}"
	echo -e "${BLUE}Mirror Summary: $chart_name → $target_url${NC}"
	echo -e "${BLUE}════════════════════════════════════════${NC}"
	echo -e "  Versions checked:  ${#versions[@]}"
	if ! $images_only; then
		echo -e "  Charts pushed:     ${GREEN}$CHARTS_PUSHED${NC}"
		echo -e "  Charts skipped:    ${DIM}$CHARTS_SKIPPED (already exist)${NC}"
	fi
	if ! $charts_only; then
		echo -e "  Images copied:     ${GREEN}$IMAGES_COPIED${NC}"
		echo -e "  Images skipped:    ${DIM}$IMAGES_SKIPPED (already exist)${NC}"
		if [[ $IMAGES_FAILED -gt 0 ]]; then
			echo -e "  Images failed:     ${RED}$IMAGES_FAILED${NC}"
		fi
	fi
	if $dry_run; then
		echo -e "  ${YELLOW}(dry-run — no changes made)${NC}"
	fi
}

main "$@"
