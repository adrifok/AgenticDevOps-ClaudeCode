Portfolio site — AWS infrastructure and CI/CD

This repository holds a static portfolio website (About, Services, Courses, Books, Community, Contact) and all the infrastructure code that deploys it to AWS. There is no build step and no JavaScript — the site is plain HTML and CSS, and everything else in the repo exists to get those files onto the internet safely and repeatably.

How it is hosted

  The site lives in an S3 bucket that is private end to end. Public access is blocked at the bucket level, and the only way to reach the files is through a CloudFront distribution in front of it, using Origin Access Control rather than the older, less secure OAI method. CloudFront terminates HTTPS and serves the site from AWS edge locations.

How deploys work

  All of the AWS resources are defined in Terraform, under terraform/. State is local for now while the project is still being bootstrapped — backend.tf documents the exact steps to move it into S3 with DynamoDB locking once that bucket exists.

  Pushing to main triggers a GitHub Actions workflow that syncs the site files to S3 and invalidates the CloudFront cache, so changes go live within minutes. The workflow authenticates to AWS using OpenID Connect: GitHub issues a short-lived identity token, AWS exchanges it for temporary credentials scoped to one IAM role, and that role can only be assumed by this exact repository on pushes to main. There are no long-lived AWS access keys anywhere in this repo or in GitHub.

Working with Claude Code

  This project also doubles as a practice ground for using Claude Code on real infrastructure work, safely. A few things are worth knowing if you open this repo in Claude Code.

  Skills define the exact steps for common tasks — scaffolding Terraform, planning, applying, deploying, running security and cost audits — so infrastructure changes go through the same reviewed path every time instead of ad hoc commands.

  Agents split responsibility by concern. One writes Terraform, one audits it for security issues, one reviews cost, one checks for drift between state and what is actually running in AWS. Keeping these separate means the agent generating code is never the same one grading it.

  Hooks enforce guardrails at the shell level, independent of what any agent or model decides to do. Destructive commands like terraform destroy or an unscoped aws s3 rm are blocked before they run, regardless of intent.

Repository layout

  index.html, style.css, privacy.html, terms.html, images/
      the site itself

  terraform/
      all AWS infrastructure as code — S3 bucket, CloudFront distribution, GitHub OIDC provider and IAM role

  .github/workflows/
      the deploy pipeline, triggers on push to main

  .claude/
      skills, agents, hooks, and settings used to work on this repo with Claude Code

Full command reference and conventions live in CLAUDE.md.
