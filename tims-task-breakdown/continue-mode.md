# Continue mode

The Task Status document is the resume point. Assume the session starting now
knows nothing else. `<skill>` is this skill's folder, `<common>` is
`<skill>/../tims-common`, and `<run>` is
`<doc folder>/.tims/<Prefix> - Task Status/` (validation logs).

The main agent is the orchestrator and the **only writer of the Task Status**.
It keeps its context small: it never loads cards it isn't about to hand over,
never implements a task itself, and never reads whole documents when a section
will do.

## 1. Load

- Invoke `tims-task-status` once (its rules stay loaded for later updates).
- Read the status doc's `# Status` header, `# Resume Here` and the two boards
  (`md-section.sh get <status> "# Status" "# Resume Here" "# Work Unit Board" "# Task Board"`).
- Read the breakdown's header, Work Units and Task Map, and the current unit's
  block (`md-section.sh get <breakdown> "## WU3 —"` gives the unit heading and
  everything under it, including its cards; use `"## WU3 —"` alone only when
  you need the cards, otherwise stop at the unit's Validation). Read the plan
  sections those cards cite only when a step needs them.
- `git fetch` once and pin `BASE_SHA`.

## 2. Reconcile and check for plan drift (subagents, in parallel)

- **Reconcile:** a subagent (`model: sonnet`) following
  `<skill>/../tims-task-status/briefs/reconcile.md`, given the status and
  breakdown paths and the repo. Read-only. It returns discrepancies with a
  proposed correction for each.
- **Plan drift:** a subagent (`model: sonnet`) following
  `<skill>/briefs/plan-drift.md`, given the plan, the breakdown's "Plan read"
  revision, the current unit and the later units' IDs. Read-only. It returns the
  plan's Change Log rows since that revision, mapped to the cards and checks
  they affect.

Present the discrepancies and drift together. Apply reconcile corrections
through `tims-task-status` only after the engineer confirms. A plan change that
affects a card or a unit's checks goes through the amendment rules in
`SKILL.md`.

## 3. Report

Give the engineer the `tims-task-status summary`, plus:

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
2. **Start.** Mark the task `In Progress` (and the unit, if it wasn't) with
   `tims-task-status set`. This is saved **before** the subagent starts.
3. **Execute.**
   - **Agent task:** spawn one implementation subagent on the default model
     (general-purpose, foreground), with the handoff in
     `<skill>/templates/handoff.md` filled in. Don't paste the card: the
     subagent reads it from the breakdown.
   - **Engineer task:** show the card's Steps as a checklist, wait, and record
     what the engineer reports.
4. **Escalation.** If the RESULT contains a Critical Decision: mark the task
   `Blocked` (`set`, naming the decision), present the decision to the
   engineer, and record their choice (`record` a decision). Then continue the
   same subagent with SendMessage, giving the decision. If it can't be
   continued, spawn a new one with the handoff, the decision, and "inspect `git
   diff` on the card's Files to see the work so far".
5. **Record.** From the RESULT, write the task's Step Log entry (`log`: Files
   Modified, Summary, Validation `Deferred to <WU>`, To validate, Follow-up
   Concerns), then `set` the task `Implemented` (or `In Progress` / `Blocked`
   if it stopped early), and `record` each risk and Identified Improvement it
   reported. For an Engineer task, write the entry yourself from what they
   reported.
6. **Next.** Continue with the unit's next task, or go to step 6 if this was
   the last.

**Two at once (optional).** Two Agent tasks may run side by side only when all
of these hold: they're in the same unit, the breakdown marks them as parallel,
their Files lists don't overlap, and neither depends on the other. Never more
than two. Set both `In Progress` first; record each as it returns. If either
escalates, start nothing new until it's resolved. Otherwise, one at a time.

## 6. Validate the work unit

When every task in the unit is `Implemented`:

1. Mark the unit `Ready to Validate` (`set`).
2. **Agent checks:** a subagent (`model: sonnet`) following
   `<skill>/briefs/run-agent-checks.md`, given the breakdown path and unit ID,
   the Build check, `<run>/validation/<WU>-attempt<n>/` for its logs, and the
   repo. It runs exactly the unit's Agent checks and returns, per check: passed
   / failed / blocked, the command, and up to 10 lines of evidence. Agent
   results from an earlier session count only if reconcile found no change to
   the unit's files since that run; otherwise re-run them as a new attempt.
3. **Report the agent results** inline: the check, what was run, passed or
   failed, and the evidence. Record the attempt (`record` a unit validation
   run).
4. If the unit needs the engineer, give them the **Engineer** checks **inline,
   in chat**. Build the checklist from the unit's Validation and How to
   validate, plus its tasks' **To validate** notes in the Step Log:
   - a numbered list, one check per item;
   - each item: what to open and do (exact steps), what they should see, and
     what to report back;
   - name everything concretely: file and asset paths, menu items, field
     names, values to set and expect. If the breakdown is vague, look the
     concrete target up in the repo first (a quick `git grep`);
   - edge cases worth trying, as their own items;
   - end with: "Ask me about any step if you need more detail."

   A check marked **Agent + Engineer** passes only when both parts pass.
5. Wait for the answers, and answer follow-up questions in the same session. A
   question isn't a result: keep the check open until the engineer reports it.
   Update the attempt as answers arrive.
6. **All checks pass:** mark the unit `Done`, which marks each of its tasks
   `Done`.
7. **Any check fails:** mark the unit `Failed`. Trace the failure to the task
   that caused it, and propose a fix task (the next unused ID, added to this
   unit) through the amendment rules. Once it's approved and implemented,
   re-run the **whole** unit's validation as a new attempt.
8. Stop and report: the unit's check results, what changed, and the next unit.

Never offer to commit. When a unit is `Done`, say so; the engineer decides what
to commit and when.
