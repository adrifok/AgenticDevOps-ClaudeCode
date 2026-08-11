# ---------------------------------------------------------------------------
# Remote state backend
#
# Bootstrap order:
#   1. Run `terraform init` with this block commented out (uses local state).
#   2. `terraform apply` to create the state bucket + DynamoDB lock table
#      (add those resources, e.g. in a separate bootstrap.tf, before relying
#      on this backend — this block only configures where state is stored).
#   3. Uncomment the backend block below, filling in the real bucket/table
#      names created in step 2.
#   4. Run `terraform init -migrate-state` to move local state into S3.
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "portfolio-site-adri-tfstate"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "portfolio-site-adri-tf-locks"
#     encrypt        = true
#   }
# }
