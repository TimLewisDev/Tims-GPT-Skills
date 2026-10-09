---
name: tims-metrics
description: >
  Switch the automatic token logging for the tims-* skills on or off on this
  machine, check its state, and read the log. The switch persists across
  sessions; once on, every session that uses a tims-* skill is recorded when it
  ends (tokens, context size, subagents, stalls; never transcript content).
  Use when the user wants to enable or disable metrics logging, asks whether it
  is on, or wants to see or compare their token use.
argument-hint: "on | off | status | report [--last N] [--since YYYY-MM-DD] [--skill name]"
disable-model-invocation: true
allowed-tools: Bash
metadata:
  version: "1.0"
---

# tims-metrics

Run `scripts/metrics.sh` in this skill's folder with the user's argument
(`on`, `off`, `status` or `report ...`; no argument means `status`):

```sh
bash "<this skill's folder>/scripts/metrics.sh" <argument>
```

Show the output to the user as it is, then add a line on what it means.

- **`on`** creates the flag at `~/.claude/tims-metrics/enabled`. Logging then
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

The log is `~/.claude/tims-metrics/token-log.md`, a markdown table that can be
opened or shared as it is. Don't read transcripts or edit the log by hand.
