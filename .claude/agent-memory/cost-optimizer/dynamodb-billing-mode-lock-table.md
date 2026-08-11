---
name: dynamodb-billing-terraform-locks
description: When bootstrap.tf creates DynamoDB lock table for terraform state, use on-demand billing for infrequent access
metadata:
  type: reference
---

**Resource:** DynamoDB lock table (referenced in terraform/backend.tf lines 14-22, not yet created as IaC)

**Current State:** Commented out; table creation deferred to bootstrap.tf

**Optimization:** When creating the lock table in bootstrap.tf, specify:
```
billing_mode = "PAY_PER_REQUEST"
```

**Cost Impact:** On-demand (~$1.50-3/month for typical usage) vs provisioned minimum 1 RCU/1 WCU (~$1-10/month). Terraform apply/plan operations are infrequent on this project, making on-demand strictly better.

**Why This Matters:** DynamoDB has two billing models. For infrequent, unpredictable access patterns (terraform state locking), on-demand is cheaper. Provisioned is only better if you have sustained, predictable high throughput.

**Trade-off:** None. On-demand is strictly cheaper for this use case.
