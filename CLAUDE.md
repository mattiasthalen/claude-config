# Git Workflow

- NEVER commit directly to main.
- NEVER use non-conventional commit formats. See ~/.claude/CONVENTIONAL-COMMITS.md
- NEVER leave commits unpushed.
- NEVER use git for remote operations if GitHub CLI (gh) is available. Prefer `gh` over `git ls-remote`, `git clone`, etc.

# Superpowers

- NEVER store plans and design specs in `docs/plans/`. Store plans in `docs/superpower/plans/` and design specs in `docs/superpower/specs/`.
- NEVER default plans to sequential execution. Optimize for parallelization.
- NEVER dispatch parallel subagents into the same worktree. Each subagent MUST use `isolation: "worktree"`.
