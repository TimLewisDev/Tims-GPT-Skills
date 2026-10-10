# Smaller subagents and shell scripts for repetitive work

- **Commit:** 2b957ec (main)
- **Date:** 2026-10-09

## Added
- `tt-common/subagent-rules.md`.
- Scripts replacing token-heavy repetitive steps: `status-init/log/record/set.sh`, `skeleton-check/render/tsv.sh`, `card-scaffold.sh`, `continue-preflight.sh`, `coverage.sh`, `donewhen.sh`, `run-checks.sh`, `validation-checklist.sh`.
- `tt-implementation-agent/templates/result.md`.
- `tools/test-scripts.sh`, demo fixtures under `tools/fixtures/`, `tools/metrics/record-session.sh`.

## Changed
- Breakdown/continue modes, task-status and implementation-agent updated to call the scripts.
- `tools/transcript-metrics.sh` expanded.
- Briefs given consistent subagent rules; `README.md` updated.
