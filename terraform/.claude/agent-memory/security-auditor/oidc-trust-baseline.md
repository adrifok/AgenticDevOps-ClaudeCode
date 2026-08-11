---
name: oidc-trust-baseline
description: Known-good GitHub OIDC trust policy scoping in terraform/github-oidc.tf, used as a diff baseline for future audits
metadata:
  type: project
---

As of the 2026-08-11 audit, `terraform/github-oidc.tf` scopes the GitHub
Actions OIDC trust policy correctly and tightly:

- `client_id_list = ["sts.amazonaws.com"]` (correct audience)
- `sub` condition pinned to exactly one repo + branch:
  `repo:adrifok/AgenticDevOps-ClaudeCode:ref:refs/heads/main`
  (no wildcard branch/tag/PR patterns, no multi-repo list)
- `aud` condition pinned to `sts.amazonaws.com`
- IAM role has a single inline policy (`github_actions_deploy`) with only
  `s3:ListBucket` on the bucket ARN, `s3:GetObject`/`PutObject`/`DeleteObject`
  on `bucket_arn/*`, and `cloudfront:CreateInvalidation`/`GetInvalidation`
  scoped to the one distribution ARN — no wildcard resources/actions.

**Why:** OIDC trust-policy scope creep (e.g., switching to
`repo:owner/repo:*` to unblock a feature branch, or adding `pull_request`
triggers) is the highest-severity regression to watch for in this file,
since it would let any branch/PR in the repo assume AWS credentials.

**How to apply:** On every audit of `github-oidc.tf`, diff the `sub` condition
value and the IAM policy's `actions`/`resources` against this baseline. Any
widening (wildcard added, new repo added, new AWS actions added) should be
flagged at least HIGH, and CRITICAL if it removes the branch/repo pin
entirely (e.g., `token.actions.githubusercontent.com:sub` condition removed).

Related: [[severity-calibration]], [[open-findings-log]]
