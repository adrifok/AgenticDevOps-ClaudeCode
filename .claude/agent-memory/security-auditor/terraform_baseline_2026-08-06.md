---
name: terraform-baseline-2026-08-06
description: Snapshot of terraform/ security posture from first full audit (2026-08-06) — what's solid vs. open gaps, to track remediation over time
metadata:
  type: project
---

First full audit of `terraform/` (backend.tf, main.tf, outputs.tf, providers.tf, variables.tf) on 2026-08-06 found no CRITICAL issues. Core S3/CloudFront/OAC wiring is correctly implemented.

Confirmed solid (don't re-flag as unknown in future audits, only re-verify nothing regressed):
- S3 public access block: all four flags true, `aws_s3_bucket_public_access_block.site`.
- Bucket ownership controls set to `BucketOwnerEnforced` (ACLs disabled entirely).
- Bucket policy scoped to `cloudfront.amazonaws.com` principal + `AWS:SourceArn` condition tied to the specific distribution ARN — correct least-privilege OAC pattern, not a wildcard.
- `aws_s3_bucket_policy` has explicit `depends_on` the public access block to avoid apply-order races.
- CloudFront uses `aws_cloudfront_origin_access_control` (OAC, not legacy OAI) and correctly references `bucket_regional_domain_name` (not the S3 static-website endpoint, which would break OAC/SigV4). This is a common misconfiguration elsewhere — this repo gets it right.
- `viewer_protocol_policy = "redirect-to-https"` on default_cache_behavior.
- No hardcoded account IDs, ARNs, or credentials anywhere in the 5 files.

Open gaps as of 2026-08-06 (check on next audit whether resolved):
- No `aws_cloudfront_response_headers_policy` attached to the distribution — no CSP/X-Frame-Options/HSTS/X-Content-Type-Options at all.
- No `aws_s3_bucket_server_side_encryption_configuration` or `aws_s3_bucket_versioning` resource for the site bucket (relies on implicit AWS default SSE-S3 only).
- Terraform state backend (`backend.tf`) is bootstrap-commented — the actual state bucket + DynamoDB lock table resources live outside this repo (per the file's own comment, "add in a separate bootstrap.tf"). No bootstrap.tf exists anywhere in the repo as of this audit, so state-bucket security controls (public access block, encryption, versioning) are unverifiable from code.
- No S3 access logging or CloudFront logging_config — no audit trail.
- `viewer_certificate` uses `cloudfront_default_certificate = true` (fine while `domain_name` var is unset/default `""`). If a custom domain is ever added, must pair with an ACM cert + `minimum_protocol_version = "TLSv1.2_2021"`, otherwise flag as regression.

**Why:** tracking this baseline avoids re-explaining the same "what's already good" analysis every audit and lets future audits focus on diffing against known gaps instead of re-deriving everything from scratch.
**How to apply:** on future `/infra-audit` or manual audits of `terraform/`, check each "open gap" above for remediation status before re-reporting it fresh; check "confirmed solid" items didn't regress (e.g. someone loosens the bucket policy or swaps back to OAI).

**Re-verified 2026-08-07 (first pass):** all 5 files byte-for-byte unchanged from the 2026-08-06 baseline at that point in the day — no remediation applied yet.

**Re-verified 2026-08-07 (second pass, later same day):** `aws_s3_bucket_server_side_encryption_configuration.site` has since been added to `main.tf` (lines 37-47) — SSE-S3 (AES256), `bucket_key_enabled = true` (note: bucket key setting is a no-op for AES256/SSE-S3, only matters for SSE-KMS; harmless but not doing anything). **SSE gap is now FIXED — move it out of "open gaps" on next audit.** All other open gaps (response headers policy, versioning, state backend bootstrap, logging, TLS-min-version-if-custom-domain-added) are still open, confirmed by fresh read of all 5 files. No regressions in the "confirmed solid" list. Still no `bootstrap.tf`, no `.github/workflows/`, no OIDC/IAM resources beyond the expected `data.aws_iam_policy_document.site_oac_access` (see [[iam_oidc_scope_gap]]).

New minor observation (not yet a tracked gap, low severity, informational): `main.tf`'s `custom_error_response` only maps `error_code = 404` to `/index.html`. With a private OAC-only bucket (no `s3:ListBucket` granted to the CloudFront principal), S3 typically returns 403 for missing keys, not 404 — so this remap may rarely trigger. Worth a low-priority fix (add a matching 403 block, or drop the remap since this is a static multi-page site, not an SPA) but not a security vulnerability.

Additional detail worth keeping for fix recommendations: `index.html` loads Font Awesome from `https://cdnjs.cloudflare.com` (style + font) and course thumbnail images from `https://img-c.udemycdn.com`, and has no JavaScript anywhere in the site. This matters for writing an accurate CSP in the still-open "no response headers policy" gap — `script-src 'none'` is safe (no JS at all), but `style-src`/`font-src` must allow `cdnjs.cloudflare.com` and `img-src` must allow `img-c.udemycdn.com`, or Font Awesome icons and course images will silently break. A generic locked-down `default-src 'self'` CSP without these allowances would ship a broken page.

**Re-verified 2026-08-07 (third pass, full fresh re-read of all 5 .tf files + both .gitignore files + terraform.tfstate + .terraform.lock.hcl):** No regressions, no new remediation since second pass. Confirmed still-open: no response headers policy, no versioning, backend still fully commented out (live state is LOCAL ONLY — `terraform/terraform.tfstate`, 7 resources live in AWS account `284495578524`/us-east-1, bucket `portfolio-site-adri-site`, distribution `EDQF51LVPQRDM`), no S3/CloudFront logging. New findings this pass, not previously tracked:
- **Gitignore double-anchoring bug** actively fails to ignore `terraform.tfstate` and `.terraform/` — real, live exposure risk (state has real account ID + ARNs, untracked but one `git add` away from being committed). Full detail in [[gitignore-state-exposure]] — this is now the top-priority fix, ahead of the CSP/versioning/logging gaps.
- **Provider version pin stale**: `providers.tf` pins `~> 5.0`; lock file confirms `5.100.0` installed; latest available is reportedly 6.58.0 (a full major version behind — v6 likely has breaking changes, needs `terraform plan` review before bumping, don't just edit the constraint).
- Confirmed (no regression): the single `*` in `main.tf:67` (`"${aws_s3_bucket.site.arn}/*"`) is the correct least-privilege object-scoping pattern, not a dangerous wildcard — don't flag this as an IAM wildcard finding in future passes.
- No `aws_iam_role`/`aws_iam_openid_connect_provider` anywhere in the repo — [[iam-oidc-scope-gap]] still fully applies, re-confirmed via repo-wide grep.
