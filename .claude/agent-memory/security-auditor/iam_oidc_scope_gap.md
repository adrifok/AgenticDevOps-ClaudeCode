---
name: iam-oidc-scope-gap
description: GitHub OIDC provider + IAM CI role are not yet implemented anywhere in the repo (as of 2026-08-06) — nothing to audit for trust-policy scoping/least-privilege yet
metadata:
  type: project
---

Repo-wide grep for `oidc|iam_role|iam_openid|assume_role_policy|github_actions` on 2026-08-06 found no matches under `terraform/` or anywhere else except the tf-writer agent's own doc (`.claude/agents/tf-writer.md`). No `.github/workflows/` directory exists yet either.

CLAUDE.md describes GitHub OIDC provider + IAM role for keyless CI/CD as part of the target architecture, and lists `/scaffold-cicd [aws-account-id]` as the skill that generates it — it just hasn't been run yet.

**Why:** without this context, a future audit could wrongly report "IAM OIDC trust policy is overly broad / missing" as a finding when actually the resources simply don't exist yet — that's a different (informational/scope) situation, not a misconfiguration to fix.
**How to apply:** before flagging IAM/OIDC issues, re-run the grep above (or check for `aws_iam_openid_connect_provider` / `aws_iam_role` resources) to confirm whether `/scaffold-cicd` has since been run. Once it exists, audit the trust policy `sub` claim for exact repo:ref scoping (e.g. `repo:ORG/REPO:ref:refs/heads/main`, not `repo:ORG/REPO:*`) and check attached IAM policy for wildcard actions/resources — this repo only needs `s3:PutObject/DeleteObject/ListBucket` on the one site bucket and `cloudfront:CreateInvalidation` on the one distribution, so any broader grant is a finding. See [[terraform_baseline_2026-08-06]] for the rest of the terraform/ audit state.
