<<<<<<< HEAD
# DDEV--CiviCRM-Wordpress
Documentation and helper scripts for maintaining a DDEV-based CiviCRM on WordPress “gold baseline” and creating clean clones for development and testing of CiviCRM extensions and WP plugins.
=======
# DDEV WordPress + CiviCRM Baseline (Docs + Scripts)

This repo contains documentation and scripts for maintaining a “gold baseline” DDEV project
with WordPress + CiviCRM, and creating clean clones for extension development/testing.

## Contents
- `documentation.md` – end-to-end instructions
- `scripts/clone-prepare.sh` – sets DDEV `name:` and `docroot:` from folder name
- `scripts/clone-cleanup.sh` – fixes WP/Civi URLs, neutralises host-specific Civi overrides, rebuilds persisted assets
- `ddev/config.yaml.example` – optional example DDEV config

## Prerequisites
- Docker (or Docker Desktop)
- DDEV
- Git

## Quick clone workflow
```bash
cd ~/dev
rsync -a --delete base-wp-civi/ cloneN/
cd cloneN
/path/to/repo/scripts/clone-prepare.sh
ddev snapshot restore v1.0-wp_civi_baseline   # choose snapshot manually
/path/to/repo/scripts/clone-cleanup.sh
>>>>>>> 22c5776 (Initial documentation and clone scripts for DDEV WordPress + CiviCRM environment)
