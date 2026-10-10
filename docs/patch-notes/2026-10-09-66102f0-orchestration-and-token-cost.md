# Better orchestration, subagent flow and lower token cost

- **Commit:** 66102f0 (main)
- **Date:** 2026-10-09

## Added
- `tt-common`: shared orchestration rules and helper scripts (`assemble.sh`, `ids.sh`, `md-section.sh`, `verify-refs.sh`, `check-planning-ids.sh`, `status-boards.sh`, `status-counts.sh`).
- Per-skill `briefs/` (subagent prompts) and `templates/` for adversarial-plan, task-breakdown, task-status, tech-plan, tech-plan-review, tech-proposals and mr-review.
- `tt-task-breakdown` split into `breakdown-mode.md` and `continue-mode.md`.
- `tt-mr-review`: `references/unity-csharp.md` and `scripts/post-notes.sh`.
- `tools/transcript-metrics.sh`; `.gitattributes`.

## Changed
- `SKILL.md` files slimmed down by moving detail into briefs, templates and scripts.
- `README.md` updated.
