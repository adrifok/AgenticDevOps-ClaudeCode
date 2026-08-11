---
name: gitignore-state-exposure
description: terraform/.gitignore patterns are double-anchored and silently fail to ignore terraform.tfstate, .terraform/ cache, tfplan — confirmed real exposure risk 2026-08-07, not yet fixed
metadata:
  type: project
---

`terraform/.gitignore` (i.e. the .gitignore file that lives *inside* `terraform/`, separate from the root `.gitignore` which only contains `.mcp.json`) contains these patterns:

```
terraform/.terraform
terraform/*tfstate
terraform*tfvars
terraform/tfplan
terraform/.terraform.lock.hcl
```

Per git's gitignore(5) rules: a pattern containing a `/` in the middle is anchored to the directory of the `.gitignore` file itself, not to the repo root. Since this file lives in `terraform/`, `terraform/.terraform` resolves to `terraform/terraform/.terraform` — a path that doesn't exist — not the real `terraform/.terraform`. Same double-anchoring breaks `terraform/*tfstate`, `terraform/tfplan`, and `terraform/.terraform.lock.hcl`. Only `terraform*tfvars` works as intended (no `/`, so it matches at any depth under `terraform/`).

**Net effect confirmed by manual pattern analysis on 2026-08-07** (no Bash/git tool available to this agent — see note below): `terraform/terraform.tfstate` (~15KB, contains real AWS account ID `284495578524`, CloudFront distribution ARN, S3 bucket ARN, full bucket policy JSON) and `terraform/.terraform/` (provider binary cache) are **not actually gitignored**. `git status` at the start of the 2026-08-07 session showed `?? terraform/` as a single collapsed untracked-directory line, which is consistent with either outcome (git collapses untracked dirs regardless of internal ignore state) — it does NOT prove the files are ignored. State file has not been committed yet (repo has one prior commit, "chore: initial commit of DMI portfolio site", predating `terraform/`), but is one `git add .` away from being staged.

**Why this matters:** this is a portfolio site repo, and CLAUDE.md describes a GitHub Actions CI/CD architecture — strongly implying this repo is headed to GitHub, plausibly as a public showcase repo. Committing the state file would leak the real AWS account ID and full resource ARN inventory.

**Fix (not yet applied as of 2026-08-07):** edit `terraform/.gitignore` to strip the redundant `terraform/` prefix since patterns are already scoped to that directory:
```
.terraform/
*.tfstate
*.tfstate.*
tfplan
```
Do NOT add a bare `.terraform.lock.hcl` ignore — HashiCorp best practice is to commit the lock file for reproducible provider pins; the current (buggy) pattern accidentally does the right thing by not matching it, but only by accident. Root-cause fix (defense in depth, not just the gitignore patch): bootstrap the S3 remote backend per `backend.tf`'s own instructions so state never lives in the working tree at all — see [[terraform_baseline_2026-08-06]] open gap #4.

**Tooling note:** this agent (security-auditor) is Read-only by design (per CLAUDE.md's agent roster) and has no Bash tool in this environment — cannot run `git check-ignore`, `git status`, or `git log` directly. Conclusions on ignore-status must come from static analysis of gitignore anchoring semantics; always hand the user the exact verification commands (`git check-ignore -v <path>`, `git status --porcelain`, `git log --all --oneline -- <path>`) rather than claiming to have run them.

**How to apply:** on next audit, re-read `terraform/.gitignore` and `terraform/terraform.tfstate` presence; if the pattern above still has the `terraform/` prefix bug, keep reporting as open (HIGH/CRITICAL depending on repo visibility). Once fixed, verify no earlier commit already leaked the state file (`git log --all --oneline -- terraform/terraform.tfstate`).
