# Orchestration rules for tims-* skills

Read this before running any `tims-*` skill that writes a large document or
spawns subagents. These rules exist because a single model response has a
hard time limit (in practice, a few minutes, and thinking counts towards it),
and because one ever-growing context is slow and fragile. A response that
tries to write a whole document, or think through a whole plan, at once can be
cut off; retrying it fails the same way.

`<common>` below means this folder: the skill's own directory with
`/../tims-common` appended (`${CLAUDE_SKILL_DIR}/../tims-common` in Claude
Code). Scripts are `<common>/scripts/<name>.sh`.

## 1. Output budget

- **One bounded task per response.** At most about 6k tokens of visible output,
  or about 200 lines of document, and one bounded piece of reasoning:
  "decompose §3", not "decompose the plan"; "write the cards for WU2", not
  "write the breakdown".
- **Never write a large document in one tool call.** Build it from part files
  (section 2) and stitch them with `assemble.sh`, or write a skeleton and
  append one section per response.
- **Never re-emit content that is already on disk.** Point at it, stitch it,
  or Edit the lines that change.
- **Show deltas in chat, not whole documents.** Give the path, and show a full
  section only when the engineer asks, one section per turn.

## 2. Drafts on disk

A long write keeps a draft folder beside its document:

```
<doc folder>/.tims/<Prefix> - <Doc>/
  context.md      the run's facts: paths, revision, BASE_SHA, repo rules, line ranges
  manifest.txt    the final document's part files, in order (one relative path per line)
  parts/          one file per section or card; each ends with the line <!-- tims:end -->
  verify/         subagent verification output
  research/       subagent research output
```

- A part is **complete** only when its last non-blank line is
  `<!-- tims:end -->`. `assemble.sh status <manifest>` lists parts as
  `complete`, `incomplete` or `missing`.
- `assemble.sh build <out> <manifest>` writes the final document (markers
  stripped). It refuses while any part is missing or incomplete.
- Dot-folders are hidden in Obsidian. Delete the draft folder once the final
  document is written and audited, and say so.

## 3. Stall recovery

After a stall, a connection error, or "continue" following one: **never retry
the same output.** Check what exists on disk (`assemble.sh status`, the
draft's header lines), and write the next missing part, smaller than the one
that failed. If one part keeps failing, split it.

On a fresh session, the draft folder and the documents are the state. Read
them; don't regenerate what is already complete.

## 4. Subagents

Spawn subagents for reading, verifying, auditing and writing from an approved
skeleton. Keep every decision, every question to the engineer, and all design
writing in the main agent: only it holds what was agreed.

**The prompt** is short (10–20 lines) and gives:

- the absolute path of the brief to follow ("Read `<path>` and follow it");
- absolute paths of `<common>/scripts`, the documents, the repo and the draft
  folder (subagents don't get `${CLAUDE_SKILL_DIR}`);
- the pinned `BASE_SHA` and any IDs or line ranges it works on.

Never paste a brief, a whole plan or a whole card into the prompt; the
subagent reads them from disk.

**Every subagent:**

- never talks to the engineer; questions and decisions come back as
  escalations;
- never decides a Critical Decision, and never adds content the documents and
  the repo don't support;
- never runs a git command that changes anything (no fetch, add, commit,
  checkout, stash, branch or worktree); reads with `git --no-optional-locks`,
  at `<BASE_SHA>:<path>`, not at `origin/<base>`, which may move mid-run;
- never writes planning IDs into code;
- follows the output budget itself: one part per Write;
- ends with a RESULT block of 60 lines or fewer, with details in files.

```
RESULT
status: done | partial | blocked | failed
wrote: <absolute path per line, or none>
summary: <up to 5 lines>
escalations: <none, or one per line:>
- E1 | blocking | review | question | <where: task, step or ref> | <issue> | <evidence path:line @sha> | <options seen>
findings: <none, a TSV of up to 40 rows, or "see <file>">
END RESULT
```

**Concurrency.**

- At most 4 subagents at once; at most 2 that change code.
- Use parallel foreground calls for fan-out. Waiting on subagents doesn't count
  against the main agent's response time. Use background subagents only to
  overlap with talking to the engineer.
- On a rate-limit or 5xx error, carry on serially. On a budget or quota error,
  stop and tell the engineer.
- Re-spawn a failed subagent for its missing parts only.

**Models.**

- `model: sonnet` for verifying, auditing, rendering a signed-off document and
  writing from an approved skeleton.
- The default model for implementation, code review, and anything that
  weighs tradeoffs.
- If a subagent on the chosen model fails to start, re-run the same brief on
  the default model.

## 5. Git

- The orchestrator runs `git fetch` once per run and pins
  `BASE_SHA=$(git rev-parse origin/<base>)`. Subagents never fetch.
- No `tims-*` skill stages, commits, pushes, or creates branches or worktrees.

## 6. Scripts

```
bash "<common>/scripts/<name>.sh" -h
```

Always quote paths: document names contain spaces. Exit `0` clean, `1`
findings, `2` usage or environment error. Script output is meant for the
agent; summarise it for the engineer.

## 7. Agents without subagents

If you can't spawn subagents, do each brief yourself, in the same order, still
one part per response. If `${CLAUDE_SKILL_DIR}` isn't expanded, `<common>` is
`../tims-common/` relative to the skill's own `SKILL.md`.
