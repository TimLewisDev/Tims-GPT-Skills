# Breakdown mode

Produce the Task Breakdown and initialise the Task Status, without any one
response writing more than a part. `<skill>` is this skill's folder,
`<common>` is `<skill>/../tims-common`, `<draft>` is the draft folder:
`<plan folder>/.tims/<Prefix> - Task Breakdown/`.

The engineer reviews and approves a **skeleton** (units, tasks, files,
dependencies, check placement) before any card is written, so cards are
written once.

## Resume first

If `<draft>` already exists, this is a resumed run:

1. Read `<draft>/context.md` and the header of `<draft>/skeleton.md`.
2. Run `assemble.sh status "<draft>/manifest.txt"` if the manifest exists.
3. Continue from the first incomplete step below: no skeleton → step 6; skeleton
   not `Approved` → step 9; parts missing or incomplete → step 10 for those
   units only; all parts complete → step 12.

Tell the engineer what was found and where you're resuming.

## 1. Setup (main)

- Read the plan's header (`md-section.sh get <plan> "# "` or its first 30 lines)
  and its heading index (`md-section.sh index <plan>`). Note the `Revision`
  ("Plan read"), the base branch, prerequisites, step order and which steps can
  run in parallel.
- **Stop** if the plan's Status is `Draft`, or the plan has unresolved Blocking
  Decisions, or its Tech Proposals' **At a glance** table shows an `Open`
  `Blocking decision` (read only that table:
  `md-section.sh get <proposals> "## At a glance"`). They belong to
  `tims-adversarial-plan` or `tims-tech-plan-review`.
- Confirm the documents' location with the engineer, and create `<draft>`.
- `git fetch` once and pin `BASE_SHA=$(git rev-parse origin/<base>)`.
- Read the repo's agent instructions (`AGENTS.md`, `CLAUDE.md` or equivalent)
  for the Build check, tool-managed files and branch rules. If they don't say
  how to compile-check, ask the engineer once.
- Check the state the work will start from: the current branch, whether the
  working tree is clean, and anything holding the project open. A prerequisite
  the engineer must resolve goes on the prerequisite task and into the review.

## 2. Context pack (main, one response)

- `ids.sh defined <plan> > "<draft>/glossary.tsv"`: every ID the plan defines,
  with a one-line excerpt.
- Write `<draft>/context.md` (about 100 lines; no plan content beyond
  pointers): plan, Future Iterations, Tech Plan and Proposals paths; plan
  revision; repo path, base branch and `BASE_SHA`; the link style and a sample
  header block from the sibling docs; the Build check; the repo rules that apply
  (tool-managed files, assemblies or modules, guard tests); and each plan
  step's line range from the heading index (`§3: lines 445–521`), plus the line
  ranges of Affected Files and Scope / Non-Goals.

## 3. Mechanical verification

```
bash "<common>/scripts/verify-refs.sh" --ref "$BASE_SHA" "<plan>" > "<draft>/verify/refs.tsv"
```

Read only its problem rows (`--only-problems` or `grep`) and the summary.

## 4. Semantic verification (subagents)

One subagent per plan step `§N`, at most 4 at a time, `model: sonnet`, brief
`<skill>/briefs/verify-step.md`. Give each: the brief path, `<common>/scripts`,
`<draft>`, the plan path and the step's line range, the repo path and
`BASE_SHA`. Each writes `<draft>/verify/§N.md` and returns a RESULT with its
problems. Skip steps whose `refs.tsv` rows are all `OK` and that cite no
symbols, if any.

## 5. Triage (main)

- Trivial drift (a moved line, a renamed-but-identical reference): goes in
  Plan Verification Notes with the corrected reference.
- Anything that changes a task's content, boundary or order: a Critical
  Decision for the engineer. Do not edit the plan; if it needs correcting, the
  engineer amends it with `tims-tech-plan-review`, then re-read the amended
  sections.

## 6. Skeleton (main, one plan step per response)

Read `<skill>/templates/skeleton.md` once. Then, for each plan step in order,
read that step (`md-section.sh get <plan> "§N."`) and append its tasks to
`<draft>/skeleton.md`, applying the atomic rules in `SKILL.md`:

- prerequisites (ticket, branch, setup) become `T00`, `T00a`…; point to the
  repo skill that performs one where it exists;
- every task: ID, title, executor, files (new / change), dependencies, the IDs
  it traces to, any **Confirm** items (what the plan leaves to "confirm when
  implementing"; if the answer could change the design, escalate now instead),
  and why it is split the way it is.

Then, in one response each:

- the **Units** table: ID, outcome ("after this unit you can…"), tasks,
  validated by, depends on, and which tasks may run in parallel (only Agent
  tasks the plan allows in parallel, with Files lists that don't overlap);
- the **Done-when map**: every "Done when" item of every plan step, by step and
  number, placed on the **first** unit where it can be observed, with the reason
  if that's not the unit holding the step's tasks; and each unit's own checks
  (it compiles, guard tests, behaviour its tasks add that the plan's items
  don't cover).

Write `<draft>/manifest.txt` from the skeleton (see the template).

## 7. Skeleton coverage (main, scripts and grep)

Before showing the engineer, confirm and fix:

- every plan step maps to at least one task;
- every task belongs to exactly one unit; units are consecutive;
- every "Done when" item appears exactly once in the Done-when map;
- every row of the plan's Affected Files table has a task that creates or
  changes it; no task touches a file outside it;
- no task does anything the plan lists as a Non-Goal.

## 8. Engineer review

Present the Work Units (ID, outcome, tasks, validated by, depends on) and the
Task Map (ID, title, executor, dependencies, unit), plus any Critical Decisions
and Plan Verification Notes. Show a step's tasks or a unit's checks in full only
on request, one at a time. Iterate on splits, merges, grouping and ordering;
edit the skeleton in place. When the engineer approves, set the skeleton's
`Approved:` line to the date.

## 9. Card writing (subagents)

One subagent per work unit, at most 4 at a time, `model: sonnet`, brief
`<skill>/briefs/write-unit.md`. Give each: the brief path, `<skill>`,
`<common>/scripts`, `<draft>`, the unit ID, the plan path, and the line ranges
of the plan steps its tasks come from. Each writes `<draft>/parts/30-<WU>.md`
(the unit block) and `<draft>/parts/31-<WU>-<task>.md` (one per card).

Handle each RESULT:

- `done`: nothing to do yet.
- escalations: a skeleton fix (re-approve that change with the engineer, edit
  the skeleton, re-spawn that unit's writer), or a Critical Decision.
- `partial` or `failed`: re-spawn the writer for the missing parts only.

## 10. Header parts (main, at most two responses)

- `<draft>/parts/00-header.md`: the header block and **Overview** (plain
  English, 3–6 sentences) from `<skill>/templates/task-breakdown.md`.
- `<draft>/parts/10-work-units.md` and `<draft>/parts/20-task-map.md`: the two
  tables, from the skeleton, plus the line on which tasks can run in parallel.

## 11. Coverage audit (subagent)

One fresh-context subagent, `model: sonnet`, brief
`<skill>/briefs/coverage-audit.md`, with the plan, `<draft>` and
`<common>/scripts`. It writes `<draft>/parts/80-coverage.md` and returns the
defects. Fix each with a small Edit to the affected part, or re-spawn that
unit's writer. Write `<draft>/parts/90-verification.md` (Plan Verification
Notes) yourself.

## 12. Assemble and initialise

```
bash "<common>/scripts/assemble.sh" status "<draft>/manifest.txt"
bash "<common>/scripts/assemble.sh" build "<folder>/<Prefix> - Task Breakdown.md" "<draft>/manifest.txt"
```

Then create the Task Status: a subagent (`model: sonnet`) following
`<skill>/../tims-task-status/briefs/init.md`, given the breakdown and the status
path. Spot-check its boards against the Task Map (task and unit counts,
executors).

## 13. Finish

Delete `<draft>` and say so. Report the two paths and the unit count, and offer
to start the first ready unit in continue mode. Never offer to commit.
