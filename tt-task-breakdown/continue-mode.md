# Continue mode

The Task Status document is the resume point. Assume the session starting now
knows nothing else. `<skill>` is this skill's folder, `<common>` is
`<skill>/../tt-common`, `<scripts>` is `<common>/scripts`, and `<run>` is
`<doc folder>/.tt/<Prefix> - Task Status/` (result files and validation
logs).

The main agent is the orchestrator and the **only writer of the Task Status**.
It keeps its context small: it never loads cards it isn't about to hand over,
never implements a task itself, never reads whole documents when a section
will do, and **never re-types into the Task Status what a script can write**.
Every routine update is one script call:

| Update | Script |
|---|---|
| A task's or unit's status (with the unit and header following) | `status-set.sh <status> <ID> "<Status>" [--note <text>]` |
| A task's Step Log entry, risks and improvements, from its result file | `status-log.sh <status> <run>/results/<ID>.md` |
| A decision, breakdown change, risk, improvement, validation attempt or one check's result | `status-record.sh <status> <kind> …` |

Each prints one line per change, never the document. Run any of them with `-h`
for its options. If one exits `2` (it can't parse the document), make that
update by hand under `tt-task-status`'s rules and tell the engineer which
script failed.

## 1. Load

- Read the status doc's `# Status` header, `# Resume Here` and the two boards
  (`md-section.sh get <status> "# Status" "# Resume Here" "# Work Unit Board" "# Task Board"`).
- Read the breakdown's header, Work Units and Task Map, and the current unit's
  block up to its first card (`md-section.sh get <breakdown> "## WU3 —"`, read
  to the end of How to validate). Read the plan sections the cards cite only
  when a step needs them.
- `git fetch` once and pin `BASE_SHA`.
- Invoke `tt-task-status` only when you need an operation no script covers
  (a reconcile correction that needs judgement, a hand-made update after a
  script failed).

## 2. Pre-flight: reconcile and plan drift

```
bash "<scripts>/continue-preflight.sh" "<status>" "<breakdown>"
```

It checks, without a model: the boards against the breakdown, the branch,
files on disk for Implemented, Done and Todo tasks, git changes to In Progress
tasks' files, validation evidence made stale by later commits, the header's
derived fields, and the plan's revision against "Plan read". Read its TSV and
its two summary lines.

- `derived` rows: fix with `status-set.sh <status> --refresh`, no confirmation
  needed.
- `fact` rows: present each with its proposed correction; apply it only after
  the engineer confirms (through the scripts, and log it with
  `status-record.sh <status> change …`).
- `judge` rows (an In Progress task): read `git diff` on that task's card files
  against its Steps and say how far it got.
- `plan: … (drift)`: only now spawn the plan-drift subagent (`model: sonnet`,
  `<skill>/briefs/plan-drift.md`), given the plan, the "Plan read" revision,
  the current unit and the later units' IDs. A plan change that affects a card
  or a unit's checks goes through the amendment rules in `SKILL.md`.
- `needs_model: no` and no rows: nothing to reconcile; say so in one line.

If the script exits `2`, fall back to the reconcile subagent (`model: sonnet`,
`<skill>/../tt-task-status/briefs/reconcile.md`) and, if the plan's revision
can't be read, the plan-drift one.

## 3. Report

Give the engineer the `tt-task-status summary` (from the header, Resume Here
and the boards already read), plus:

- for a unit that is `Ready to Validate`: go straight to step 6 and give the
  inline validation checklist;
- the next action: the next task in the current unit, or the next unit (ID,
  outcome, plain-English summary, who validates it).

## 4. Choose the next work

- Finish the current unit (all its tasks, then its validation) before starting
  another.
- Otherwise take the first `Todo` unit whose dependencies are all `Done`.
  Confirm with the engineer **once, before starting the unit**.
- Within the unit, work its tasks in ID order as their dependencies allow,
  back to back, without per-task confirmation. Stop at every Critical Decision
  and every Engineer task. Pause between tasks only if the engineer asks.

## 5. Each task

1. **Pre-flight.** Check the card's references against the working tree:
   `md-section.sh get <breakdown> "### T07 —" | verify-refs.sh --worktree --only-problems -`.
   If something moved, correct the card and log it. If it changed materially,
   escalate.
2. **Start.** `status-set.sh <status> T07 "In Progress"` (the unit follows).
   This is saved **before** the subagent starts.
3. **Execute.**
   - **Agent task:** spawn one implementation subagent on the default model
     (general-purpose, foreground), with the handoff in
     `<skill>/templates/handoff.md` filled in. Don't paste the card: the
     subagent reads it from the breakdown, and writes its result to
     `<run>/results/T07.md`.
   - **Engineer task:** show the card's Steps as a checklist, wait, then write
     what the engineer reports as a result file in the same format
     (`<skill>/../tt-implementation-agent/templates/result.md`) and apply it
     as in step 5.
4. **Record.** `status-log.sh <status> <run>/results/T07.md`. It writes the
   Step Log entry, adds each risk and improvement, and sets the task
   `Implemented` (`Blocked` or `In Progress` if it stopped early). Don't read
   the result file back unless the script reports a critical decision or
   fails.
5. **Escalation.** If `status-log.sh` reports `critical decision: yes`: read
   only that section of the result file, check its evidence, and present it
   with `<skill>/templates/critical-decision.md`. Record the choice with
   `status-record.sh <status> decision …` (it prints the decision's ID), and
   name it on the task: `status-set.sh <status> T07 Blocked --note "<D-ID>: <one line>"`
   while waiting, then `"In Progress" --note ""` once decided. Continue the
   same subagent with SendMessage, giving the decision; it rewrites its result
   file when it finishes. If it can't be continued, spawn a new one with the
   handoff, the decision, and "inspect `git diff` on the card's Files to see
   the work so far".
6. **Next.** Continue with the unit's next task, or go to step 6 if this was
   the last.

**Two at once (optional).** Two Agent tasks may run side by side only when all
of these hold: they're in the same unit, the breakdown marks them as parallel,
their Files lists don't overlap, and neither depends on the other. Never more
than two. Set both `In Progress` first; apply each result file as it returns.
If either escalates, start nothing new until it's resolved. Otherwise, one at a
time.

## 6. Validate the work unit

When every task in the unit is `Implemented`:

1. `status-set.sh <status> WU3 "Ready to Validate"`.
2. **Agent checks:**
   ```
   bash "<scripts>/run-checks.sh" "<breakdown>" WU3 "<run>/validation/WU3-attempt<n>" --why "<first run | after fix T09 | evidence stale>"
   ```
   It runs the commands in the unit's `checks` block, saves each output to
   `check-<n>.log`, prints one row per check, and writes `attempt.md`: agent
   checks passed or failed, engineer checks pending. Check by hand any it
   reports `blocked` (an Agent check with no command), and record the result
   as in step 5. If it exits `2` (the unit has no `checks` block, as in
   breakdowns written before it existed), use a subagent (`model: sonnet`,
   `<skill>/briefs/run-agent-checks.md`) instead, given the breakdown path and
   unit ID, the Build check, the same log folder and the repo, and write its
   results as an attempt file in the same format. Agent results from an
   earlier session count only if the pre-flight reported nothing stale for the
   unit; otherwise run them again as a new attempt.
3. **Record and report.** `status-record.sh <status> validation WU3 --file <run>/validation/WU3-attempt<n>/attempt.md`.
   Report the agent results inline: the check, what was run, passed or failed,
   and the evidence (the rows `run-checks.sh` printed).
4. If the unit needs the engineer, draft the checklist with
   `validation-checklist.sh <breakdown> <status> WU3`. It gathers the open
   Engineer checks, the unit's engineer steps and its tasks' To validate notes.
   Turn it into the inline checklist, **in chat**:
   - a numbered list, one check per item;
   - each item: what to open and do (exact steps), what they should see, and
     what to report back;
   - name everything concretely: file and asset paths, menu items, field
     names, values to set and expect. If the draft is vague, look the concrete
     target up in the repo first (a quick `git grep`);
   - edge cases worth trying, as their own items;
   - end with: "Ask me about any step if you need more detail."

   A check marked **Agent + Engineer** passes only when both parts pass.
5. Wait for the answers, and answer follow-up questions in the same session. A
   question isn't a result: keep the check open until the engineer reports it.
   Record each answer as it arrives:
   `status-record.sh <status> check WU3 <n> passed|failed|waived --evidence "<what they reported>"`.
   It recomputes the attempt's Outcome.
6. **Outcome Done:** `status-set.sh <status> WU3 Done`, which marks each of its
   tasks `Done`.
7. **Any check fails:** `status-set.sh <status> WU3 Failed --note "check <n>"`.
   Trace the failure to the task that caused it, and propose a fix task (the
   next unused ID, added to this unit) through the amendment rules. Once it's
   approved and implemented, re-run the **whole** unit's validation as a new
   attempt.
8. Stop and report: the unit's check results, what changed, and the next unit.

Never offer to commit. When a unit is `Done`, say so; the engineer decides what
to commit and when.
