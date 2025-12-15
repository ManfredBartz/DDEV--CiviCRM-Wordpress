## Part A --- Create the baseline project (one-time)

Baseline directory: *\~/dev/base-wp-civi*

### A1) Create directory and configure DDEV

*mkdir -p \~/dev/base-wp-civi*

*cd \~/dev/base-wp-civi*

*\# WordPress at project root (docroot: \"\")*

*ddev config \--project-type=wordpress \--docroot=\"\"
\--php-version=8.3*

*ddev start*

### A2) Install WordPress (via WP-CLI inside DDEV)

*ddev wp core download*

*ddev wp config create \--dbname=db \--dbuser=db \--dbpass=db
\--dbhost=db*

*ddev wp core install \\*

* \--url=\"https://base-wp-civi.ddev.site\" \\*

* \--title=\"Baseline WP+Civi\" \\*

* \--admin_user=admin \\*

* \--admin_password=admin \\*

* \--admin_email=admin@example.com*

Confirm:

*ddev wp option get home*

*ddev wp option get siteurl*

### A3) Install and activate CiviCRM plugin

Option 1 (WP plugin repo):

*ddev wp plugin install civicrm \--activate*

Option 2 (manual install):

-   place the CiviCRM plugin under *wp-content/plugins/civicrm/*
-   then:

*ddev wp plugin activate civicrm*

### A4) Create separate Civi DB/schema (recommended)

If you use a separate database/schema for Civi (as in our setup), create
it:

*ddev exec bash -lc \"mysql -e \\\"*

*CREATE DATABASE IF NOT EXISTS civicrm;*

*CREATE USER IF NOT EXISTS \'civi\'@\'%\' IDENTIFIED BY \'civi\';*

*GRANT ALL ON civicrm.\* TO \'civi\'@\'%\';*

*FLUSH PRIVILEGES;*

*\\\"\"*

### A5) Run the CiviCRM web installer

Open WP admin:

-   *https://base-wp-civi.ddev.site/wp-admin/*
-   go to CiviCRM and complete the installer

Use the separate DB credentials if applicable:

-   schema: *civicrm*
-   user: *civi*
-   pass: *civi*
-   host: *db*

### A6) Verify baseline

*ddev cv status*

*ddev cv flush*

Confirm in browser:

-   *https://base-wp-civi.ddev.site/wp-admin/admin.php?page=CiviCRM*
-   Civi home renders and the top navigation menu is present

## Part B --- Create a baseline snapshot (one-time, then repeat only when baseline changes)

From *\~/dev/base-wp-civi*:

*ddev snapshot \--name v1.0-wp_civi_baseline*

*ddev snapshot \--list*

## Part C --- Create a clone (repeatable)

Example clone directory: *\~/dev/clone4*

### C1) Copy baseline filesystem to a new clone directory

*cd \~/dev*

*rsync -a \--delete base-wp-civi/ clone4/*

*cd clone4*

### C2) Prepare DDEV config (name/docroot)

Run the repo script from inside the clone directory:

*/path/to/repo/scripts/clone-prepare.sh*

This ensures:

-   *.ddev/config.yaml* has *name: clone4*
-   *.ddev/config.yaml* has *docroot: \"\"*

### C3) Restore a snapshot (manual choice)

You choose the snapshot:

*ddev snapshot list*

*ddev snapshot restore v1.0-wp_civi_baseline*

### C4) Run clone cleanup

*/path/to/repo/scripts/clone-cleanup.sh*

This:

-   updates WordPress home/siteurl
-   rewrites *CIVICRM_UF_BASEURL*
-   comments out host-specific Civi URL overrides in
    *civicrm.settings.php*
-   deletes Civi persisted assets and compiled templates (*persist/\**,
    *templates_c/\**)
-   flushes Civi caches

### C5) Verify clone

*ddev wp \--skip-plugins=civicrm eval \'echo
home_url().\"\\n\".site_url().\"\\n\";\'*

*ddev cv status \| grep CIVICRM_UF_BASEURL*

Browser:

-   *https://clone4.ddev.site/wp-admin/admin.php?page=CiviCRM*

## Notes: why cleanup is necessary

CiviCRM's WordPress installer can write host-specific URL overrides
into:\
*wp-content/uploads/civicrm/civicrm.settings.php*

In clones, these stale values can cause regenerated assets in:\
*wp-content/uploads/civicrm/persist/\**\
to embed the wrong host (e.g. *base-wp-civi.ddev.site*), resulting in:

-   empty/partial Civi admin pages
-   missing menu
-   JS/CSS load failures

The cleanup script neutralises those overrides and forces regeneration.
