## documentation.md (end-to-end)

```markdown
# Baseline and Cloning Workflow: DDEV WordPress + CiviCRM

## Goal

Maintain a “gold baseline” DDEV project with WordPress + CiviCRM, and create clones for:
- Civi extension development/testing
- experimentation without affecting the baseline

Only this repo (docs + scripts + optional example DDEV settings) is under version control.
The baseline and clones are local working directories.

---

## Prerequisites (baseline assumptions)

### Required tools
- Docker / Docker Desktop
- DDEV
- Git

### Sanity checks
```bash
docker --version
ddev --version
git --version
