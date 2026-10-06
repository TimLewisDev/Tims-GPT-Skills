---
name: tims-task-status
description: >
  Own the Task Status document: the single resume point for work done from a
  task breakdown (or, standalone, from a plan). Defines its template and status
  values, and performs every update to it: initialise it, set task and work
  unit statuses, write Step Log entries (including "To validate" notes for
  later inline validation), record decisions, risks, improvements, breakdown
  changes and work-unit validation results, keep the header, boards and Resume
  Here consistent, and reconcile the document with the repo. Called by
  tims-task-breakdown and tims-implementation-agent whenever they change the
  status; run directly to get a resume summary and a reconcile. Never commits.
metadata:
  version: "1.0"
---

# tims-task-status

## Usage

```
/tims-task-status <task status doc>
```

Run directly, it gives a **resume summary**, checks the document is internally
consistent, then **reconciles** it with the repo (see Operations). It changes
nothing without the engineer's confirmation.

Normally it's invoked by another skill, and the operation follows from what that
skill needs:

| Caller | Uses |
|---|---|
| `tims-task-breakdown` | `init` (breakdown mode); `summary` and `reconcile` (continue mode); `set` at every task and unit state change; `record` for decisions, breakdown changes and work-unit validation runs |
| `tims-implementation-agent` | `log` for its task's Step Log entry; `set` to `Blocked` on a Critical Decision; `record` for risks and Identified Improvements; `init` (standalone mode only) |

A caller that has already loaded this skill follows its rules for later
updates; it re-invokes it if they've dropped out of context.

## Role

You keep one document true. A fresh session reads it first and trusts it, so:

- **One document.** Never create a second Task Status doc for the same work.
  If one exists, use it.
- **Save at every state change**, not at the end of a session. A session can end
  at any moment. When a task starts, the `In Progress` state is saved **before
  any code change**.
- **Consistent after every write.** The `# Status` header, the boards, the
  progress counts, Resume Here and each Step Log entry's **Status** line must
  agree. These are *derived* fields: recompute them on every write, without
  asking, and never update one and leave the others. Changing a *recorded fact*
  (a task or unit status, a file list, a decision, a validation result) is
  different: that only happens as the caller or the engineer reports it, or as
  a confirmed reconcile correction.
- **Stable records.** IDs are never renumbered or reused, and rows are never
  deleted. A removed task is `Dropped` with its reason.
- **No fabrication.** Record what happened, as reported by the caller or the
  engineer, with evidence where there is any. Unknowns are left blank or asked,
  never guessed.
- Never stage, commit, push or create branches. Whether work is committed is the
  engineer's business.

## Status values

Tasks:

| Status | Meaning |
|---|---|
| `Todo` | Not started. |
| `In Progress` | Started. Work may be on disk. |
| `Blocked` | Waiting on a Critical Decision or external input. The board says which. |
| `Implemented` | Its Steps are done. Not yet validated; that happens with its unit. |
| `Done` | Its work unit passed validation. |
| `Dropped` | Removed from scope by an engineer decision. Kept on record with the reason. |

Work units:

| Status | Meaning |
|---|---|
| `Todo` | No task started. |
| `In Progress` | At least one task started; not every task is `Implemented`. |
| `Blocked` | A task in it is `Blocked`. |
| `Ready to Validate` | Every task is `Implemented`; validation is running or waiting on the engineer. |
| `Failed` | At least one check failed. A fix task is proposed or in progress. |
| `Done` | Every check in its Validation passed. |

Rules that tie them together:

- A task becomes `Done` only when its unit becomes `Done`, and then all of the
  unit's non-`Dropped` tasks do (their boards and Step Log Status lines
  included).
- A unit is never `Done` while any of its engineer checks is unanswered.
- The header **State** follows from the boards: `Not Started` (all `Todo`),
  `Blocked` (any unit `Blocked`), `Ready to Validate` (the current unit is),
  `Complete` (every unit `Done`), otherwise `In Progress`.

In **standalone** mode there are no work units: a task goes `Todo` →
`In Progress` → `Done` (or `Blocked` / `Dropped`), and State follows the tasks.

## Operations

### `init`

- **From a Task Breakdown** (called by `tims-task-breakdown`): write the full
  template. Every unit and task is `Todo`, every board row is filled from the
  breakdown's Work Units and Task Map, and Resume Here points at the first unit.
  Name and place it per the breakdown (`<Prefix> - Task Status.md`), matching
  the sibling documents' header or tag block and link style.
- **Standalone, from a plan** (called by `tims-implementation-agent` when there
  is no breakdown): write the minimal variant. Its tasks are the plan's steps,
  numbered as the plan numbers them. Put it beside the plan. Confirm the
  location first.
- If a Task Status doc already exists for this work, don't initialise. Use it.

### `set`

Set a task's or unit's status, with a note when there's a reason (the
blocking decision, the failed check, the drop reason). Then recompute the
header (State, Progress, Current Unit, Current Task, Next, Last Updated,
Blocking Decisions) and Resume Here, and save.

### `log`

Write or update one task's Step Log entry, under `## <ID> — <title>`:

- **Status**: the task's status.
- **Files Modified**: every file created or changed.
- **Summary**: what was done, in a few lines.
- **Validation**: `Deferred to <WU ID>` when the task belongs to a work unit;
  otherwise (standalone) what was actually run and its result.
- **To validate**: what the engineer or the agent should check for this task,
  how, the expected result, and edge cases worth trying. This feeds the unit's
  inline validation checklist, and survives a session ending. Write it so it
  can be read out as steps.
- **Follow-up Concerns**: anything the next task or the engineer should know.

Then recompute the derived fields and save.

### `record`

Add one entry to the right section, then recompute and save:

- **Decision** → Decisions Taken (decision, resolution, tasks and units
  affected, date).
- **Risk** → Outstanding Risks in the header (add it, or mark it closed with the
  date and how).
- **Improvement** → Identified Improvements (description, benefits,
  risks/tradeoffs, why high impact).
- **Breakdown change** → Breakdown Changes (date, tasks/units, change, why,
  approved by).
- **Unit validation run** → Work Unit Validation, under the unit. One block per
  **attempt**, numbered 1, 2… per unit. An attempt covers all of the unit's
  checks, agent and engineer; a new attempt starts only when validation is
  re-run after a fix task or because earlier evidence went stale. Each block
  has the run time, each check with passed / failed / pending and its evidence,
  and an outcome: `Done`, `Failed → <fix task ID>`, or `Pending engineer
  (checks <n>, …)` while the engineer's answers are outstanding. Update the
  same block as answers arrive.

### `reconcile`

The document may be stale, since a session can end mid-task. Check it against
the repo before anyone trusts it:

- **Branch:** the current branch matches the Status header.
- **Files:** files created by `Implemented` or `Done` tasks exist; files a
  `Todo` task will create don't yet.
- **In-progress work:** for an `In Progress` task, compare `git status` and
  `git diff` on its files against its card's Steps to see how far it got.
- **Changed since validation:** for each `Done` unit, and a unit whose
  validation attempt has recorded results, check `git log` and `git status` for
  changes to its tasks' files after that attempt's run time. Code can change
  outside a task (review fixes, renames). Report each one: the unit's evidence
  is stale, and the proposed correction is a new validation attempt (for a
  `Done` unit, the engineer decides whether to re-validate) plus a recorded
  risk.
- **Breakdown agreement:** the boards match the Task Breakdown: the same task
  and unit IDs, the same executors, the same unit membership.
- **Internal consistency:** the derived fields agree (see Role). Fix those
  directly; they aren't corrections.

Report whether work is committed only if it bears on a discrepancy (e.g. a
`Done` task's files are missing from the working tree). Report every
discrepancy with a proposed correction. Apply corrections only after the
engineer confirms, and log each one under Breakdown Changes (or, standalone,
Decisions Taken).

Plan drift is not this skill's job; `tims-task-breakdown` checks it.

### `summary`

A short resume summary:

- progress (`n of m` units Done, `n of m` tasks Implemented or Done) and the
  current unit;
- anything `In Progress` or `Blocked`, and why;
- a unit that is `Ready to Validate`, and which checks are still waiting on the
  engineer;
- the next action, from Resume Here.

## Templates

### Task Status (from a Task Breakdown)

```markdown
<header or tag block matching sibling docs>

# Status
- State: Not Started | In Progress | Blocked | Ready to Validate | Complete
- Progress: <n> of <m> units Done · <n> of <m> tasks Implemented or Done
- Current Unit: <WU ID — name, or None>
- Current Task: <ID — title, or None>
- Next: <next task, or "Validate WU<n>", or next unit>
- Last Updated: <YYYY-MM-DD HH:MM>
- Branch: `<working branch>` (base `<base>`)
- Blocking Decisions: <list, or None>
- Outstanding Risks: <list, or None>

# Resume Here
1. Read this document, then <unit ID> and its cards in <Task Breakdown link>.
2. Reconcile: expect branch `<branch>`; <files expected on disk, or none>.
3. Waiting on the engineer: <checks or decisions, or nothing>.
4. Next action: <one concrete action, e.g. "Start T08 — Load saved settings (Agent)" or "Validate WU3 (Agent + Engineer)">.

**Documents:** Comprehensive tech plan <link> · Task Breakdown <link> · Repo `<path>`

# Work Unit Board
| ID | Outcome | Tasks | Validated by | Status | Notes |
|---|---|---|---|---|---|

# Task Board
| ID | Task | Executor | Work unit | Depends on | Status | Notes |
|---|---|---|---|---|---|---|

# Work Unit Validation

## <WU ID> — <name>

### Attempt <n>
- Run: <YYYY-MM-DD HH:MM> (<why: first run, after fix T<nn>, evidence stale after <commit or change>>)
- Results: <each check: passed / failed / pending, with evidence>
- Outcome: Done | Failed → <fix task ID> | Pending engineer (checks <n>, …)

# Decisions Taken
| # | Decision | Resolution | Tasks / Units | Date |
|---|---|---|---|---|

# Breakdown Changes
| Date | Tasks / Units | Change | Why | Approved by |
|---|---|---|---|---|

# Step Log

## <ID> — <title>
- Status:
- Files Modified:
- Summary:
- Validation: Deferred to <WU ID>
- To validate:
- Follow-up Concerns:

# Identified Improvements

## Improvement <n>
- Description:
- Benefits:
- Risks/Tradeoffs:
- Why High Impact:
```

### Task Status (standalone)

The same template without **Current Unit**, the **Work Unit Board**, **Work
Unit Validation** and **Breakdown Changes**. Progress reads `<n> of <m> tasks
Done`. The Documents line links the plan, and the Task Board drops its Work unit
column.
