# DDEV--CiviCRM-Wordpress

## Why this exists

Cloning a DDEV-based CiviCRM on WordPress site for development or testing is
surprisingly fragile.

In particular, the CiviCRM WordPress installer writes host-specific absolute
URLs into `wp-content/uploads/civicrm/civicrm.settings.php` and into generated
persistent assets. When a site is cloned (for example using DDEV snapshots),
these values are not automatically updated, which can cause the CiviCRM admin
UI to load with missing menus, broken JavaScript, or a blank home page.

This repository documents a proven, repeatable workflow for:

- maintaining a clean “gold baseline” WordPress + CiviCRM DDEV project
- creating disposable clones for development and testing
- neutralising non-portable CiviCRM URL settings
- forcing safe regeneration of persistent assets

The repository intentionally contains **only documentation and helper scripts**.
It does not include WordPress core, CiviCRM core, databases, or DDEV snapshots.

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
