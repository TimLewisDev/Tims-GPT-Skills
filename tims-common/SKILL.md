---
name: tims-common
description: >
  Shared orchestration rules and helper scripts used by the other tims-* skills
  (output budget, checkpointed drafts, subagent briefs and the RESULT contract,
  and bash scripts for verifying references, assembling documents, extracting
  sections and cross-checking IDs). Not run directly; the other skills read
  orchestration.md and call scripts/ from here.
user-invocable: false
disable-model-invocation: true
metadata:
  version: "1.0"
---

# tims-common

Support files for the `tims-*` skills. Nothing here runs on its own.

- [`orchestration.md`](orchestration.md): the rules every `tims-*` skill follows
  for output size, drafts on disk, stall recovery, subagents and models. Skills
  that orchestrate read it before they start.
- [`scripts/`](scripts/): POSIX bash plus git helpers. Run them as
  `bash "<this folder>/scripts/<name>.sh" …`. Each one prints usage with `-h`.

| Script | Use |
|---|---|
| `verify-refs.sh` | Check every file path and `path:line` a markdown doc cites, at a commit or in the working tree |
| `check-planning-ids.sh` | Find planning IDs (task, unit, plan, decision IDs) in code or in a card's code blocks |
| `assemble.sh` | Build a document from part files; report which parts are missing or incomplete; append or insert parts |
| `md-section.sh` | Index a markdown doc's headings; print one section by heading |
| `ids.sh` | List the IDs a plan defines or a doc cites; cross-check one against another |
| `status-boards.sh` | Build a new Task Status's boards from a Task Breakdown's tables |
| `status-counts.sh` | Recompute a Task Status's derived header fields from its boards; flag inconsistencies |

Exit codes for every script: `0` clean, `1` findings (or nothing found), `2`
usage or environment error.
