# ---------------------------------------------------------------------------
# GitHub OIDC — keyless CI/CD auth for GitHub Actions (no long-lived AWS keys)
# ---------------------------------------------------------------------------

# Thumbprint of GitHub's OIDC issuer, fetched live rather than hardcoded so it
# stays valid if GitHub ever rotates their TLS certificate chain.
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]

  tags = local.common_tags
}

# Trust policy scoped to the exact repo + exact branch ref, since the CI
# workflow only ever triggers on push to main (no wildcard across
# branches/tags/PRs).
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "AllowGitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # GitHub's OIDC subject claim embeds immutable owner/repo IDs alongside the
    # current login/repo name (repo:{login}@{ownerId}/{repoName}@{repoId}:ref:...).
    # Do not shorten this back to the plain "repo:owner/repo:ref:..." form —
    # that omits the immutable IDs and would let a repo/org rename hijack
    # the trust relationship (a renamed/recreated repo could reuse the old
    # plain name and still assume this role).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:adrifok@97637423/AgenticDevOps-ClaudeCode@1331082217:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = local.common_tags
}

# Least-privilege deploy policy: only what `aws s3 sync --delete` and a
# CloudFront invalidation require, scoped to this project's own resources.
data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "S3ListBucket"
    effect = "Allow"

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid    = "S3ObjectReadWriteDelete"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid    = "CloudFrontInvalidation"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.project_name}-github-actions-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}
