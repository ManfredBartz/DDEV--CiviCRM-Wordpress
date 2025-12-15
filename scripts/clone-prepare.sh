#!/usr/bin/env bash
# clone-prepare.sh — normalise .ddev/config.yaml based on current folder name

set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -d .ddev ]] || die "No .ddev/ found. Run from project root."
CONFIG=".ddev/config.yaml"
[[ -f "${CONFIG}" ]] || die "Missing ${CONFIG}"

PROJECT_DIR="$(basename "$PWD")"

# Update (or insert) name: <folder>
if grep -qE '^name:\s*' "${CONFIG}"; then
  sed -i -E "s/^name:\s*.*/name: ${PROJECT_DIR}/" "${CONFIG}"
else
  sed -i "1iname: ${PROJECT_DIR}" "${CONFIG}"
fi

# Normalise docroot to "" (project root)
if grep -qE '^docroot:\s*' "${CONFIG}"; then
  sed -i -E 's/^docroot:\s*.*/docroot: ""/' "${CONFIG}"
else
  awk -v ins='docroot: ""' '
    {print}
    $0 ~ /^type:\s*/ && !done {print ins; done=1}
  ' "${CONFIG}" > "${CONFIG}.new" && mv "${CONFIG}.new" "${CONFIG}"
fi

echo "Prepared .ddev/config.yaml:"
echo "  name:    ${PROJECT_DIR}"
echo '  docroot: ""'
