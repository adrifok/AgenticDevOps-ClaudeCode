---
name: cloudfront-price-class-portfolio
description: CloudFront PriceClass_200 is over-provisioned for personal portfolio; downgrade to PriceClass_100 for 40% savings
metadata:
  type: reference
---

**Resource:** `aws_cloudfront_distribution.site` in terraform/main.tf (line 79)

**Current Setting:** `price_class = "PriceClass_200"`

Includes: US, Canada, Europe, Asia, Australia, Middle East, Africa

**Optimization:** Change to `price_class = "PriceClass_100"`

Includes: US, Canada, Europe (sufficient for personal portfolio with no stated global audience requirement)

**Cost Impact:** ~40% reduction in CloudFront data transfer pricing tier costs. For a low-traffic portfolio site, this is ~$0.20-0.30/month savings on an already minimal bill (~$0.50-1/month total).

**Implementation:** Single line change in terraform/main.tf. Run `terraform plan` to verify no resource recreation. Apply to take effect immediately for new requests.

**Trade-off:** Geographic reach is reduced. If audience has significant Asia/Australia/MiddleEast traffic, keep PriceClass_200. Otherwise, this is safe optimization.
