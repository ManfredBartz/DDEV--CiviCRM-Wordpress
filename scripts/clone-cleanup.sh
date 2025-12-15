#!/usr/bin/env bash
# clone-cleanup.sh — post-snapshot cleanup for a cloned ddev WP+CiviCRM project

set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -d .ddev ]] || die "No .ddev/ found. Run from project root."
[[ -f wp-config.php ]] || die "No wp-config.php found. Run from WP root."
command -v ddev >/dev/null 2>&1 || die "ddev not in PATH."

PROJECT_DIR="$(basename "$PWD")"
NEWURL="https://${PROJECT_DIR}.ddev.site"
CONFIG=".ddev/config.yaml"
CIVI_SETTINGS="/var/www/html/wp-content/uploads/civicrm/civicrm.settings.php"

# Fail fast if .ddev/config.yaml name does not match folder name
CFG_NAME="$(awk -F': *' '/^name:/ {print $2; exit}' "${CONFIG}" || true)"
if [[ -n "${CFG_NAME}" && "${CFG_NAME}" != "${PROJECT_DIR}" ]]; then
  die "Mismatch: folder='${PROJECT_DIR}' but ${CONFIG} has name='${CFG_NAME}'. Run clone-prepare.sh first."
fi

echo "Project directory : ${PROJECT_DIR}"
echo "Target base URL   : ${NEWURL}"
echo

echo "Starting ddev..."
ddev start >/dev/null

# 2) Update WP URL settings (skip civicrm to avoid WP-CLI bootstrap warnings)
echo "Updating WordPress home/siteurl (skipping civicrm plugin for WP-CLI)..."
ddev wp --skip-plugins=civicrm option update home    "${NEWURL}" >/dev/null || true
ddev wp --skip-plugins=civicrm option update siteurl "${NEWURL}" >/dev/null || true

# 3) Fix/neutralise Civi URL overrides in civicrm.settings.php
echo "Fixing Civi base URL and neutralising URL overrides in civicrm.settings.php (if present)..."
ddev exec bash -lc "
set -e
if [ -f '${CIVI_SETTINGS}' ]; then

  # Ensure CIVICRM_UF_BASEURL matches this clone
  sed -i -E \"s#define\\('CIVICRM_UF_BASEURL',\\s*'[^']*'\\);#define('CIVICRM_UF_BASEURL', '${NEWURL}/');#\" '${CIVI_SETTINGS}'

  # Comment out host-specific URL overrides (match literal keys; do NOT match leading \$)
  sed -i -E \
    -e '/^[[:space:]]*\\/\\//b' \
    -e \"/civicrm_paths\\['wp\\.frontend\\.base'\\]\\['url'\\][[:space:]]*=/ s#^#//#\" \
    -e \"/civicrm_paths\\['wp\\.backend\\.base'\\]\\['url'\\][[:space:]]*=/ s#^#//#\" \
    -e \"/civicrm_setting\\['domain'\\]\\['userFrameworkResourceURL'\\][[:space:]]*=/ s#^#//#\" \
    '${CIVI_SETTINGS}'

  # Comment out CIVICRM_UF_DSN define if present (portable clones should not hard-code it)
  sed -i -E \"s#^[[:space:]]*define\\('CIVICRM_UF_DSN',.*\\);#//& #\" '${CIVI_SETTINGS}' 2>/dev/null || true

  # FAIL FAST if any active overrides remain
  if grep -nE \"^[[:space:]]*(civicrm_paths\\['wp\\.(frontend|backend)\\.base'\\]\\['url'\\]|civicrm_setting\\['domain'\\]\\['userFrameworkResourceURL'\\])\" \
        '${CIVI_SETTINGS}' >/dev/null; then
    echo 'ERROR: Host-specific Civi URL overrides still active in civicrm.settings.php' >&2
    exit 1
  fi

fi
"

# 4) Remove generated/persisted assets that embed absolute URLs
echo "Removing generated Civi persisted assets and compiled templates..."
ddev exec bash -lc "
rm -rf /var/www/html/wp-content/uploads/civicrm/persist/* \
       /var/www/html/wp-content/uploads/civicrm/templates_c/*
"

# 5) Flush Civi caches
echo "Flushing Civi caches..."
ddev cv flush >/dev/null

echo
echo "Done."
echo "Quick checks:"
echo "  ddev wp --skip-plugins=civicrm eval 'echo home_url().\"\\n\".site_url().\"\\n\";'"
echo "  ddev cv status | grep CIVICRM_UF_BASEURL"
echo "  Browser: ${NEWURL}/wp-admin/admin.php?page=CiviCRM"
