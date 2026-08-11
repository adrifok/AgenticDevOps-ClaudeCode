---
name: severity-calibration
description: How to calibrate finding severity for this specific project (personal static portfolio site, not enterprise workload)
metadata:
  type: project
---

This repo (`AgenticDevOps-ClaudeCode`, terraform/) hosts adrifok's personal static
HTML/CSS portfolio site (S3 + CloudFront, no backend, no user data, no auth,
no PII collected). Traffic is low and the blast radius of most findings is
reputational/defacement, not data breach.

Calibrate severity accordingly:
- CRITICAL/HIGH: reserved for things that expose the S3 bucket publicly,
  broaden the OIDC trust policy beyond the exact repo+branch, add wildcard
  (`*`) IAM actions/resources, or disable HTTPS enforcement. Also HIGH:
  missing CloudFront security headers (CSP/X-Frame-Options) since that's an
  explicit checklist item and cheap to fix.
- MEDIUM: missing defense-in-depth that's cheap/idiomatic to add — S3
  versioning (mitigates a compromised CI token running `--delete` sync),
  CloudFront access logging, TLS floor weaker than TLSv1.2.
- LOW: WAF, KMS-encrypted S3 (vs AES256), custom domain/ACM — these are
  legitimate hardening but overkill for a static portfolio with no
  sensitive data. Don't push these as HIGH; note them as optional.

**Why:** Avoids over-flagging enterprise-grade controls on a low-stakes personal
project, which would erode signal on the findings that actually matter (OIDC
scope creep, public bucket exposure, wildcard IAM).

**How to apply:** When triaging new findings in `terraform/`, check this
calibration before assigning severity. If the project's risk profile changes
(e.g., a custom domain + real user data is added), revisit this file.

Related: [[oidc-trust-baseline]], [[open-findings-log]]
