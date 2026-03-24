# Git Workflow

- NEVER commit directly to main.
- NEVER use non-conventional commit formats. See ~/.claude/CONVENTIONAL-COMMITS.md
- NEVER leave commits unpushed.
- NEVER use git for remote operations if GitHub CLI (gh) is available. Prefer `gh` over `git ls-remote`, `git clone`, etc.
- NEVER rely on global git email. Before committing, check `git config --local user.email`. If not set, copy from global: `git config --local user.email "$(git config --global user.email)"`.

# Memory

- NEVER store memories to MEMORY.md or memory files. NEVER store memories anywhere other than CLAUDE.md.
- NEVER store memories in project-local directories unless explicitly asked. NEVER use any location other than `~/.claude/CLAUDE.md` (global).
- NEVER frame memories as SHOULD/MUST. NEVER use positive framing. NEVER store a memory without reframing it as a NEVER rule.

# Superpowers

- NEVER store plans and design specs in `docs/plans/`. Store plans in `docs/superpower/plans/` and design specs in `docs/superpower/specs/`.
- NEVER default plans to sequential execution. Optimize for parallelization.
- NEVER dispatch parallel subagents into the same worktree. Each subagent MUST use `isolation: "worktree"`.
