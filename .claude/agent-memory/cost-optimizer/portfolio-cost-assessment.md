---
name: portfolio-infra-cost-assessment
description: Complete cost assessment for personal portfolio static site on S3+CloudFront; primarily within AWS free tier
metadata:
  type: project
---

**Project:** Personal portfolio website (static HTML/CSS)

**Infrastructure:** S3 bucket + CloudFront distribution + Terraform state backend

**Estimated Monthly Cost Baseline (current config):**

- CloudFront (PriceClass_200, low traffic): $0.50-1.00
- S3 storage (content, likely <1GB): $0.02-0.05
- DynamoDB lock table (on-demand, when created): $0.01-0.05
- **Total: $0.53-1.10/month**

Most of this is absorbed by AWS free tier (1GB CloudFront transfer/mo, 5GB S3 storage, 25 DynamoDB on-demand write units).

**Primary Optimization (High Impact):**
- Change CloudFront to PriceClass_100 → saves ~$0.20-0.30/month (40% reduction on data transfer tier costs)

**Secondary Considerations (Medium Impact, Security-Cost Tradeoff):**
1. Enable S3 versioning (security best practice) + add lifecycle rule to delete old versions after 30-60 days
   - Cost: +$0.50-2/month potential (negligible for small bucket)
   - Benefit: Disaster recovery, accidental deletion protection
   - Recommendation: Enable both together

2. Skip S3 access logging and CloudFront logging for this scale (low-traffic site)
   - Cost would exceed benefit: ~$0.50-1/month in log storage/transfer
   - Recommendation: Skip unless audit requirements demand it

**No-Cost Good Practices Already Implemented:**
- CloudFront default certificate (not custom domain) — free
- OAC-based S3 access (secure, no legacy OAI) — no cost difference
- Managed-CachingOptimized cache policy — appropriate TTL

**Future Decision Points:**
- When bootstrap.tf is created: use on-demand DynamoDB billing (not provisioned)
- If adding custom domain: ACM certificate is free for CloudFront use
- If traffic spike occurs: CloudFront costs scale with transfer, but infrastructure handles it elastically

**Net Assessment:** This infrastructure is already lean and cost-optimized. Single actionable change is PriceClass_100. Security recommendations (versioning, logging) have minimal cost impact at this scale and should be implemented for governance, not cost reasons.
