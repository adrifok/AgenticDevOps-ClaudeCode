---
name: tool-access-limits
description: tf-writer subagent has no Bash or terraform execution tools — cannot run fmt/validate/plan itself
metadata:
  type: project
---

The tf-writer subagent's tool set is Read, Write, Edit, Glob, Grep, and the
`terraform` MCP server's registry-lookup tools only (search/get provider,
module, and policy docs). There is no Bash tool and no MCP tool that actually
executes `terraform fmt`, `terraform validate`, `terraform plan`, or
`terraform apply` — the `create_run`/`apply_run`-style HCP tools mentioned in
the terraform MCP server's own instructions are not exposed to this subagent.

Why: project design separates responsibilities — tf-writer generates code
(has Write access + memory), while execution/verification happens via the
`/tf-plan` and `/tf-apply` skills or another agent with Bash access (see
project CLAUDE.md's Custom Agents / Skills sections).

How to apply: when a task asks tf-writer to "run terraform fmt/validate/plan"
after generating code, do not fabricate a result. State plainly that this
subagent has no execution access, hand formatting/validation off to the
`/tf-plan` skill or ask the user/orchestrator to run it, and manually check
the generated HCL against `terraform fmt` conventions (2-space indent,
aligned `=`, trailing newline) before returning.
