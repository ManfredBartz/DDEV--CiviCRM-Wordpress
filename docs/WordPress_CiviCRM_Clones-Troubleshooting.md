# Troubleshooting --- DDEV WordPress + CiviCRM Clones

This guide documents common problems encountered when cloning a
DDEV-based\
WordPress + CiviCRM project from a baseline snapshot, how to diagnose
them,\
and how to fix them.

The most important diagnostic tool is your browser's **Inspect /
Developer Tools**,\
which will usually reveal the problem within seconds.

## Symptom 1: CiviCRM Home page is blank or mostly empty

### Typical signs

-   CiviCRM admin page loads but shows little or no content
-   Top navigation menu is missing
-   Page background loads, but the main content area is empty
-   No obvious PHP fatal error in WordPress admin

### Common browser console errors

*CRM.url is not a function*

*angular is not defined*

*\$ is not a function*

*Failed to load resource: the server responded with a status of 502*

These errors almost always indicate that **CiviCRM JavaScript did not
load correctly**.

## Diagnosing with Browser Inspect (Developer Tools)

Using your browser's developer tools is the fastest way to determine
whether\
this is a CiviCRM asset problem rather than a WordPress or PHP issue.

### Step 1: Open Developer Tools

-   Chrome / Chromium / Edge:

    -   Right-click on the page → **Inspect**
    -   Or press **F12**

-   Firefox:

    -   Right-click → **Inspect**
    -   Or press **Ctrl+Shift+I**

### Step 2: Check the Console tab

Open the **Console** tab and look for red error messages.

Key indicators of a broken CiviCRM clone:

-   *CRM.url is not a function*
-   *angular is not defined*
-   *Uncaught ReferenceError*
-   Errors mentioning *.js* or *.css* files

These indicate that required CiviCRM JavaScript files were not loaded.

### Step 3: Check the Network tab

1.  Click the **Network** tab
2.  Reload the page (Ctrl-F5 / Shift-Reload)
3.  Filter by **JS** and **CSS**

Look for:

-   HTTP **502**, **404**, or **blocked** responses

-   Asset URLs pointing to the **baseline hostname**, for example:

    *https://base-wp-civi.ddev.site/wp-content/plugins/civicrm/\...*

If you see requests going to the baseline host instead of the clone
host,\
the cause is confirmed.

### Step 4: Inspect a failed asset

Click a failed JS or CSS request and check the **Request URL**.\
If it contains the old baseline hostname, CiviCRM is regenerating
assets\
with stale absolute URLs.

## Root cause

The CiviCRM WordPress installer writes **host-specific absolute URL
overrides**\
into:

*wp-content/uploads/civicrm/civicrm.settings.php*

Common examples include:

*\$civicrm_paths\[\'wp.frontend.base\'\]\[\'url\'\]*

*\$civicrm_paths\[\'wp.backend.base\'\]\[\'url\'\]*

*\$civicrm_setting\[\'domain\'\]\[\'userFrameworkResourceURL\'\]*

When a site is cloned or restored from snapshot:

-   these overrides remain unchanged

-   CiviCRM regenerates assets under:

    *wp-content/uploads/civicrm/persist/*

-   regenerated assets embed the **wrong hostname**

-   JavaScript and CSS fail to load

-   the CiviCRM admin UI appears blank or incomplete

## Symptom 2: CiviCRM admin partially works, then breaks after refresh

### Likely cause

-   Cleanup was incomplete
-   Persisted assets were regenerated **before** URL overrides were
    neutralised

### Fix

Force a full regeneration:

*ddev exec bash -lc \"rm -rf \\*

* /var/www/html/wp-content/uploads/civicrm/persist/\* \\*

* /var/www/html/wp-content/uploads/civicrm/templates_c/\*\"*

*ddev cv flush*

Reload the page with a hard refresh.

## Symptom 3: *ddev cv status* shows the wrong base URL

Example:

*CIVICRM_UF_BASEURL = https://base-wp-civi.ddev.site*

### Diagnosis

*ddev cv status \| grep CIVICRM_UF_BASEURL*

### Fix

Run the cleanup script:

*../clone-cleanup.sh*

Verify again:

*ddev cv status \| grep CIVICRM_UF_BASEURL*

It must match the clone hostname, for example:

*https://clone4.ddev.site/*

## Symptom 4: *clone-cleanup.sh* fails with shell syntax errors

### Examples

*syntax error near unexpected token \'(\'*

*event not found*

*unbound variable*

### Causes

-   Unquoted parentheses in regular expressions
-   Shell expansion of *\$civicrm_paths* or *\$civicrm_setting*
-   History expansion (*!*) inside *bash -lc*

### Resolution

Use **only** the version of *clone-cleanup.sh* provided in this
repository.

Key implementation rules used in the script:

-   Never match *\$civicrm\_\** directly
-   Match literal keys such as *civicrm_paths\[\...\]*
-   Quote all regex patterns
-   Avoid constructs that trigger history expansion

## Symptom 5: Cleanup script runs but overrides are still present

### Diagnosis

*ddev exec bash -lc \"grep -n \\*

*
\\\"wp.frontend.base\\\\\|wp.backend.base\\\\\|userFrameworkResourceURL\\\"
\\*

* /var/www/html/wp-content/uploads/civicrm/civicrm.settings.php\"*

If uncommented lines appear, overrides are still active.

### Fix

Re-run:

*../clone-cleanup.sh*

The script is designed to fail fast if overrides remain.

## Symptom 6: WordPress URLs are correct, but CiviCRM is still broken

### Diagnosis

*ddev wp eval \'echo home_url().\"\\n\".site_url().\"\\n\";\'*

If these are correct:

-   the problem is **not WordPress**
-   the problem is almost certainly stale CiviCRM persisted assets

### Fix

*ddev exec bash -lc \"rm -rf \\*

* /var/www/html/wp-content/uploads/civicrm/persist/\* \\*

* /var/www/html/wp-content/uploads/civicrm/templates_c/\*\"*

*ddev cv flush*

## Symptom 7: Clone uses the wrong DDEV project name

### Diagnosis

*basename \"\$PWD\"*

*grep \'\^name:\' .ddev/config.yaml*

If these differ, DDEV may start or reuse the wrong containers.

### Fix

*../clone-prepare.sh*

This enforces:

-   *name:* matches the folder name
-   *docroot: \"\"*

## Quick debug checklist

When something looks wrong, check these in order:

1.  WordPress URLs

    *ddev wp eval \'echo home_url().\"\\n\".site_url().\"\\n\";\'*

2.  Civi base URL

    *ddev cv status \| grep CIVICRM_UF_BASEURL*

3.  Host-specific overrides (must be commented)

    *ddev exec bash -lc \"grep -n \\*

    *
    \\\"wp.frontend.base\\\\\|wp.backend.base\\\\\|userFrameworkResourceURL\\\"
    \\*

    * /var/www/html/wp-content/uploads/civicrm/civicrm.settings.php\"*

4.  Persisted assets must not reference the baseline host

    *ddev exec bash -lc \"grep -R \'base-wp-civi\' \\*

    * /var/www/html/wp-content/uploads/civicrm/persist \|\| true\"*

## Key takeaway

If CiviCRM behaves strangely after cloning:

1.  Use **Inspect** first
2.  Look for JS/CSS loading errors
3.  Check where assets are being loaded from
4.  Neutralise URL overrides
5.  Delete persisted assets
6.  Flush caches

The provided scripts encode the correct sequence --- use them rather
than manual edits wherever possible.
