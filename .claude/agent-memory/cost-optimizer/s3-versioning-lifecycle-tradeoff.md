---
name: s3-versioning-cost-security-tradeoff
description: Enabling S3 versioning (security best practice) requires lifecycle rules to prevent runaway storage costs
metadata:
  type: reference
---

**Resource:** `aws_s3_bucket.site` in terraform/main.tf (line 14)

**Current State:** Versioning disabled (default)

**Security Audit Flag:** Missing S3 versioning (disaster recovery risk)

**Cost Consideration:** If versioning is enabled without lifecycle rules, old object versions accumulate indefinitely. Cost grows ~$0.023/GB/month per additional version stored.

**Recommendation if Versioning Enabled:**

Add lifecycle rule to S3 bucket:
```
aws_s3_bucket_lifecycle_configuration "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30  # or 60, adjust as needed
    }
  }
}
```

**Cost Impact:** Prevents storage cost accumulation. For site bucket (likely <1GB), impact is minor (~$0.50-2/month max), but compound over time.

**Decision:** Version control and disaster recovery benefit from versioning. Cost is minimal for a small static site. Recommended: enable versioning + lifecycle rule together.

**Related:** [[cloudfront-price-class-portfolio]] (primary optimization), [[dynamodb-billing-terraform-locks]] (state backend cost)
