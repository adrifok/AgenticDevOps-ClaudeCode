---
name: open-findings-log
description: Log of non-critical findings still open as of last audit, so future audits can confirm fixed vs still-outstanding without re-deriving from scratch
metadata:
  type: project
---

Audit date 2026-08-11 (full terraform/ review incl. new github-oidc.tf,
account 284495578524, repo adrifok/AgenticDevOps-ClaudeCode). Findings still
open at that time:

- No `aws_cloudfront_response_headers_policy` attached to
  `aws_cloudfront_distribution.site` — no CSP/X-Frame-Options/HSTS headers.
- No CloudFront access logging (`logging_config` block absent).
- No `aws_s3_bucket_versioning` on `aws_s3_bucket.site` — matters because the
  GitHub Actions role has `s3:DeleteObject`, so a leaked/compromised CI token
  or bad `--delete` sync has no rollback path.
- `viewer_certificate` uses `cloudfront_default_certificate = true` (no
  custom domain wired up yet — `var.domain_name` is declared but unused) —
  TLS floor is capped at whatever the default `*.cloudfront.net` cert allows;
  can't pin `minimum_protocol_version` without an ACM cert + custom domain.
- No WAFv2 Web ACL associated with the distribution (LOW — optional per
  [[severity-calibration]]).
- `backend.tf` is intentionally commented out (local state, bootstrap
  ordering documented in-file) — no `bootstrap.tf` exists yet with the state
  bucket/DynamoDB table. Not a finding yet, but once created, that bucket
  needs its own public-access-block + versioning + encryption — check on
  next audit if it appears.

Everything else in the checklist (S3 public access block, OAC not OAI, HTTPS
redirect, encryption at rest AES256, no wildcard IAM, OIDC repo/branch
scoping, no hardcoded account IDs/ARNs) passed clean.

**Why:** Lets a future audit quickly check "did adrifok fix the response
headers policy / versioning / logging yet?" instead of re-deriving the full
list, and avoids re-flagging something already fixed as if it were new.

**How to apply:** At the start of a new audit, skim this list and verify
each item against current file state (files may have changed) rather than
trusting it blindly. Update or delete entries once confirmed fixed.

Related: [[severity-calibration]], [[oidc-trust-baseline]]
