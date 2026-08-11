---
name: settings-local-json-public-exposure
description: stray .claude/skills/settings.local.json tracked in public repo, missed by global gitignore anchor — confirmed 2026-08-11, remediation pending
metadata:
  type: project
---

`.claude/skills/settings.local.json` exists as a second, stray copy of the legitimate `.claude/settings.local.json`. Confirmed on 2026-08-11:

- Content (16 lines): `AWS_PROFILE=default`, `AWS_REGION=us-east-1`, `enabledMcpjsonServers: [terraform, aws]`, `permissions.allow: [Bash(python3:*), Bash(open:*)]`. No access keys, secret keys, session tokens, or account IDs present in this version.
- The user's global gitignore (`~/.config/git/ignore`) contains only `**/.claude/settings.local.json` — this anchors to files whose *immediate parent* is literally named `.claude`. Since this file's parent is `.claude/skills/`, the pattern does not match, so the file is not protected and got committed/pushed to the public repo `adrifok/AgenticDevOps-ClaudeCode`.
- Root `.gitignore` in the repo itself only lists `.mcp.json`, `terraform.tfstate`, `terraform.tfstate.backup` — no `settings.local.json` protection at the project level at all, so this isn't just a global-gitignore gap, the repo has zero local defense-in-depth for this file class.
- `Glob` mtime ordering showed `.claude/skills/settings.local.json` as the most recently modified of the three `.claude/**/*.json` files, consistent with it being a recent stray artifact (likely a session/skill invoked with cwd resolving inside `.claude/skills/`, causing Claude Code to persist local settings there) rather than a long-standing intentional file.

**Why this matters:** `settings.local.json` is exactly the file class meant to carry local env vars — in other setups this legitimately holds real `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. This instance is clean today, but the gitignore gap means any future session that writes real secrets into a `settings.local.json` outside the exact `.claude/` root will get silently committed to a public repo. This is the same *anchoring-pattern-too-narrow* failure mode as [[gitignore_state_exposure]] (terraform/.gitignore double-anchoring) — recurring theme in this repo: gitignore patterns are written assuming a specific directory depth/name and silently no-op when a file shows up one level off from where the author assumed.

**Fix recommended (not yet applied as of 2026-08-11):** `git rm` the stray file; add `**/settings.local.json` to the project's own root `.gitignore` (don't rely solely on the user's machine-local global gitignore — it doesn't protect collaborators/CI); since content is already public, still needs `git log -p -- .claude/skills/settings.local.json` run by the user (this agent has no Bash tool, read-only by design) to confirm no earlier revision ever held real credentials before treating this as fully closed.

**Tooling note:** same constraint as [[gitignore_state_exposure]] — this agent has no Bash access in this environment, cannot run `git log -p`, `git blame`, or `git check-ignore` itself. Always hand the user/parent agent the exact commands rather than claim to have run them.

**How to apply:** on next audit, re-check whether `.claude/skills/settings.local.json` still exists / is still tracked, and whether root `.gitignore` now includes a `settings.local.json` pattern. If gone and gitignored, close this out. If any `settings.local.json` anywhere in the repo ever contains real AWS keys/tokens (not just profile name/region), escalate immediately to CRITICAL and recommend credential rotation regardless of history-rewrite status.
