---
name: tt-metrics
description: >
  Switch the automatic token logging for the tt-* skills on or off on this
  machine, check its state, and read the log. The switch persists across
  sessions; once on, every session that uses a tt-* skill is recorded when it
  ends (tokens, context size, subagents, stalls; never transcript content).
  Use when the user wants to enable or disable metrics logging, asks whether it
  is on, or wants to see or compare their token use.
argument-hint: "on | off | status | report [--last N] [--since YYYY-MM-DD] [--skill name] | viz [--last N] [--since YYYY-MM-DD] [--skill name] [--output path]"
disable-model-invocation: true
allowed-tools: Bash
metadata:
  version: "1.0"
---

# tt-metrics

Run `scripts/metrics.sh` in this skill's folder with the user's argument
(`on`, `off`, `status` or `report ...`; no argument means `status`):

```sh
bash "<this skill's folder>/scripts/metrics.sh" <argument>
```

Show the output to the user as it is, then add a line on what it means.

- **`on`** creates the flag at `~/.claude/tt-metrics/enabled`. Logging then
  runs from a `SessionEnd` hook in `~/.claude/settings.json`.
  - Exit 0: the hook is already registered; nothing else to do.
  - Exit 3: the hook is missing. Show the user the snippet the script printed
    and say it will be added to `settings.json`. Add it with Edit, merging into
    any existing `hooks` and `SessionEnd` entries and keeping everything else.
    Stop and ask if the file isn't valid JSON or already holds a different
    `record-session.sh` entry. Tell the user it applies from the next Claude
    Code session.
- **`off`** removes the flag. The hook stays registered and then does nothing,
  so turning logging back on never edits `settings.json` again.
- **`status`** says whether logging is on, whether the hook is registered, and
  how many sessions the log holds.
- **`report`** prints a per-skill summary (sessions, average and total weighted
  tokens, largest context, stalls) then the matching rows of the log. The
  current session isn't in it until it ends. Weighted tokens are priced
  relative to plain input on one model; compare rows on the same model.
- **`viz`** generates a self-contained HTML dashboard at
  `~/.claude/tt-metrics/report.html` (override with `--output <path>`) and
  prints the path. Open the file in any browser — no server needed. The
  dashboard has three Chart.js panels (token breakdown per session, avg
  weighted by label group, intelligence signals bubble chart) and a sortable
  raw-data table with derived columns (cache efficiency %, output per
  request). Supports the same `--last N`, `--since YYYY-MM-DD`, and
  `--skill <text>` filters as `report`. The `TT_METRICS_REPORT` env var
  sets the default output path.

## Outcome tagging (determinism measurement)

Token counts alone cannot measure whether a session produced a correct result
or required rework. Use the `TT_METRICS_LABEL` env var to tag sessions
before they start:

```sh
export TT_METRICS_LABEL="outcome:success"   # session produced correct output
export TT_METRICS_LABEL="outcome:rework"    # session needed correction/follow-up
export TT_METRICS_LABEL="outcome:abandoned" # session was stopped before completing
```

The viz Panel B (Weighted by Label Group) groups rows by label, so
`outcome:*` labels form their own bars. A low weighted-token average beside
a `success` label vs a `rework` label shows where the model is efficient and
reliable. Unset the var after the session or it carries forward: `unset
TT_METRICS_LABEL`.

The log is `~/.claude/tt-metrics/token-log.md`, a markdown table that can be
opened or shared as it is. Don't read transcripts or edit the log by hand.
