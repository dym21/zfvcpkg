#!/usr/bin/env bash

set -euo pipefail

readonly VCPKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TRIPLET="cross-loongarch64-linux-x86-newworld"
readonly STATUS_FILE="${1:-${VCPKG_ROOT}/.backup/newworld-gcc15-20260806/installed/vcpkg/status}"
readonly OVERLAY_PORTS="${VCPKG_ROOT}/ai-registry/ports"
readonly MAX_ATTEMPTS="${VCPKG_REBUILD_MAX_ATTEMPTS:-30}"

if [[ ! -f "${STATUS_FILE}" ]]; then
  echo "vcpkg status snapshot not found: ${STATUS_FILE}" >&2
  exit 2
fi

mapfile -t base_specs < <(
  awk -v triplet="${TRIPLET}" '
    BEGIN { RS="" }
    $0 ~ ("Architecture: " triplet) &&
    $0 ~ /Status: install ok installed/ &&
    $0 !~ /\nFeature:/ {
      package=""
      count=split($0, lines, "\n")
      for (i=1; i<=count; i++) {
        if (lines[i] ~ /^Package: /) {
          sub(/^Package: /, "", lines[i])
          package=lines[i]
        }
      }
      if (package != "") {
        print package ":" triplet
      }
    }
  ' "${STATUS_FILE}" | sort -u
)

mapfile -t feature_specs < <(
  awk -v triplet="${TRIPLET}" '
    BEGIN { RS="" }
    $0 ~ ("Architecture: " triplet) &&
    $0 ~ /Status: install ok installed/ &&
    $0 ~ /\nFeature:/ {
      package=""
      feature=""
      count=split($0, lines, "\n")
      for (i=1; i<=count; i++) {
        if (lines[i] ~ /^Package: /) {
          sub(/^Package: /, "", lines[i])
          package=lines[i]
        }
        if (lines[i] ~ /^Feature: /) {
          sub(/^Feature: /, "", lines[i])
          feature=lines[i]
        }
      }
      if (package != "" && feature != "") {
        print package "[" feature "]:" triplet
      }
    }
  ' "${STATUS_FILE}" | sort -u
)

if printf '%s\n' "${base_specs[@]}" "${feature_specs[@]}" |
    grep -Eq '^icu(:|\[)'; then
  echo "target ICU package found in rebuild request" >&2
  exit 3
fi

echo "newworld rebuild request: ${#base_specs[@]} packages, ${#feature_specs[@]} features"

for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
  echo "vcpkg rebuild attempt ${attempt}/${MAX_ATTEMPTS}"
  if VCPKG_MAX_CONCURRENCY=30 CMAKE_BUILD_PARALLEL_LEVEL=30 \
      "${VCPKG_ROOT}/vcpkg" install \
      --recurse \
      --binarysource=clear \
      --overlay-ports="${OVERLAY_PORTS}" \
      "${base_specs[@]}" \
      "${feature_specs[@]}"; then
    exit 0
  fi
  sleep 5
done

echo "vcpkg rebuild did not finish after ${MAX_ATTEMPTS} attempts" >&2
exit 4
