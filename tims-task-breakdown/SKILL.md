---
name: tims-task-breakdown
description: >
  Break an execution-ready Comprehensive Tech Plan (from
  tims-adversarial-plan) into atomic, dependency-ordered tasks that an AI agent can implement one at a
  time, grouped into work units: the tasks that are validated together.
  Validation and confirmation happen only per work unit, never per task. Each
  task card and work unit carries a plain-English summary for non-technical
  readers plus every detail, reference and link needed to execute it. Keeps a
  Task Status document (through tims-task-status) as the resume point for
  later sessions; in continue mode it reconciles that document with the repo,
  works the current work unit's tasks through tims-implementation-agent, then
  validates the unit with the engineer, giving validation steps inline in chat.
  Never commits. Use when handed a tech
  plan and asked for a task breakdown, or when asked to continue, resume or
  report progress on an existing breakdown.
---

# tims-task-breakdown

## Usage

```
/tims-task-breakdown <comprehensive tech plan>     # Breakdown mode
/tims-task-breakdown continue <task status doc>    # Continue mode
```

- **Breakdown mode** (the argument is a Comprehensive Tech Plan): produce the
  Task Breakdown and initialise the Task Status document.
- In this skill, "the plan" and "the tech plan" always mean the **Comprehensive
  Tech Plan**. If you're handed the brief Tech Plan or the Tech Proposals
  instead, follow its header link to the comprehensive plan and use that. Never
  take design from the brief Tech Plan or the Proposals: they are views of the
  comprehensive plan for human review.
- **Continue mode** (the argument is a Task Status document, or starts with
  `continue`, `resume` or `status`): reconcile the status with the repo, report
  progress, and work the current work unit.
- If the argument is missing or it's unclear which document is meant, ask and
  stop. Do not guess from the working tree.

## Where this fits

```
tims-adversarial-plan ──► tims-task-breakdown ──► tims-implementation-agent
 (Comprehensive Tech Plan)   (Breakdown + Status)     (one task per handoff)
  ├─ Tech Proposals, Future Iterations
  └─ Tech Plan (brief, for human review, via tims-tech-plan)
tims-tech-plan-review amends the plan and keeps its views in sync
```

This is a **decomposition, tracking and validation skill**, not a planning skill
and not an implementation skill:

- It does **not** change the design. The tech plan decided *what* to build;
  this skill decides only how to slice it into tasks, how to group the tasks
  into work units, and in what order.
- It does **not** write production code. Implementation is delegated to
  `tims-implementation-agent`, one task per handoff.
- It does **not** commit. Every git operation (staging, committing, pushing,
  branching) belongs to the engineer.
- It never fills a gap in the plan with an assumption. A gap becomes a
  question, an explicit "Confirm" step on a card, or a Critical Decision.

## Authority order

1. Existing codebase, on the plan's base branch
2. Explicit engineer instructions
3. The Comprehensive Tech Plan, then the Future Iterations doc it links
4. The Task Breakdown

A card never overrides the plan. If a card and the plan disagree, the plan
wins: correct the card and log the amendment. If the plan and the codebase
disagree, escalate a Critical Decision. The plan itself only changes through
`tims-tech-plan-review`, so its brief Tech Plan and Proposals stay in sync.

## The two documents

| Document | Written by | Changes | Purpose |
|---|---|---|---|
| **Task Breakdown** | this skill (breakdown mode) | rarely, only through logged amendments | The work units and task cards: what the agent does, how each unit is validated, and what it means to a human. |
| **Task Status** | the `tims-task-status` skill, called by this skill and by `tims-implementation-agent` | at every state change | The single resume point. A fresh session reads this first. |

**`tims-task-status` owns the Task Status document**: its template, its status
values, and every write to it. This skill never edits it by hand; each
"update the Task Status" below means an operation of that skill (`init`, `set`,
`log`, `record`, `reconcile`, `summary`). Invoke it once per session and follow
its loaded rules for later updates.

There is **no Testing Framework document**. Validation instructions are given
to the engineer inline, in chat, when a unit is validated (see Continue mode
step 8). Older breakdowns may link one; it is no longer updated.

**Location and naming.** Put both beside the comprehensive plan and follow its
naming:

- `<Prefix> - Comprehensive Tech Plan.md` (e.g. in an Obsidian vault) →
  `<Prefix> - Task Breakdown.md`, `<Prefix> - Task Status.md`
- `Tasks/STAR-XXXXX/STAR-XXXXX.techplan-full.md` → `STAR-XXXXX.tasks.md`,
  `STAR-XXXXX.status.md`

Match the sibling documents' conventions: header or tag block, and link style
(Obsidian `[[wiki-links]]` in a vault, relative Markdown links in the repo).
Confirm the location before writing.

**Older plans (written before 2026-10-05).** These are a *Tech Plan + Feature
Consensus* pair (`<Prefix> - Tech Plan.md` and `<Prefix> - Feature
Consensus.md`, or `STAR-XXXXX.plan.md`), with no Comprehensive Tech Plan.
Recognise one by structure, not by date: its Tech Plan has no `Revision` or
Change Log and links a Feature Consensus doc as its intake. Treat
the pair together as the comprehensive plan: the `R`, `A`, `S` and `C` IDs come
from the Feature Consensus, and the `CD`, `NB` and `§` IDs from the Tech Plan.
For plan drift, fall back to comparing the files' modified dates with the
breakdown's "Plan read" date. Breakdowns already written against such a pair
keep working unchanged.

## Tasks and work units

There are two levels, and they have different jobs:

- A **task** is the unit of *implementation*: one handoff to the agent, or one
  checklist for the engineer. Tasks carry **no validation**. A task is finished
  when its Steps are done.
- A **work unit** is the unit of *validation*: a group of consecutive tasks
  whose results are tested and confirmed together. **All validation and
  confirmation happens at work-unit level**, once every task in the unit is
  finished. That includes compile checks, test runs, Editor checks and the
  plan's "Done when" items.

Validating per unit lets the plan's checks land where they can actually be
observed, and keeps the engineer's round trips (Editor refresh, Test Runner,
Scene view) to one per unit instead of one per task.

### What "atomic" means for a task

A task is atomic when **all** of these hold:

- **One concern.** It can be stated in one sentence without "and also".
- **One session, one reviewable change.** An agent can finish it in a single
  session, and its diff can be reviewed in one sitting.
- **Written to leave the project whole.** It is designed so that the code
  compiles afterwards and nothing that worked before breaks. No task needs a
  later task in order to compile. (This is confirmed when the unit is
  validated, not per task.)
- **Self-contained.** An agent given only the card, plus the files under "Read
  first", can do it without reading the rest of the breakdown.
- **One executor.** Agent work and work that needs a human in a tool are
  separate tasks.
- **No open design choices.** Everything a design choice needs is decided in
  the plan or on the card. If it isn't, escalate before writing the card.

Split a plan step into several tasks when:

- it creates a contract and its consumers (an interface and the classes that
  use it) and they can compile in stages;
- it mixes code with Editor-authored assets (scenes, prefabs, assets);
- it spans more than one assembly;
- it wouldn't fit in one session, or its diff would be too large to review in
  one sitting.

Don't split when:

- the pieces can't compile apart;
- the split just mirrors files one-to-one with no gain in reviewability.

A task no longer needs to be verifiable on its own: a task whose output can
only be observed through a later task belongs in the same work unit as that
later task.

### What makes a good work unit

A work unit is well formed when **all** of these hold:

- **Testable as a whole.** Every one of its checks can be run once its last
  task is finished, without any task from a later unit.
- **Complete for its checks.** Every task its checks need is in this unit or in
  an earlier one.
- **Leaves the project whole.** After its last task the code compiles and
  nothing that worked before is broken.
- **Something to notice.** Its outcome can be described to a non-technical
  reader as "after this unit you can…". Work units replace milestones.
- **Traceable failures.** It's small enough that a failed check can be traced
  to the task that caused it. Prefer 2–5 tasks; a single-task unit is fine
  when that task is testable alone.
- **Consecutive.** Its tasks are consecutive in ID order, and every task
  belongs to exactly one unit.

Draw unit boundaries where the engineer would naturally stop to test: after a
new assembly first gets sources (it needs an Editor refresh to compile), when a
test becomes runnable, when something first appears in the Scene view or a
window. Group checks that need the same engineer action into the same unit.

A unit may contain only Engineer tasks (e.g. authoring a scene), or mix Agent
and Engineer tasks. A unit's validation may be run by the agent alone or need
the engineer; record which.

## Executors

Every task names exactly one executor:

| Executor | Use for | In continue mode |
|---|---|---|
| **Agent** | Code and text files the agent can write. | Handed to `tims-implementation-agent`. |
| **Engineer** | Work that must be done in a tool: authoring scenes, prefabs or assets in the Unity Editor; creating tickets; creating branches; anything the plan says must not be hand-edited. | Present the card's Steps as a checklist, wait for the engineer, record what they report. |

Every work unit names who **validates** it:

| Validated by | Use when |
|---|---|
| **Agent** | Every check can be run by the agent (e.g. an out-of-band compile check, a grep, reading a file). |
| **Agent + Engineer** | At least one check needs the engineer (Editor compile, Test Runner, Inspector, Scene view behaviour). The agent runs its checks first, then hands the engineer the rest as a checklist. |

Electrum rules that decide executors and validation (see `AGENTS.md`):

- `.unity`, `.prefab`, `.asset` and `.meta` files are managed through Unity.
  Authoring them is an **Engineer** task unless the plan and the engineer
  explicitly say otherwise. The agent never writes `.meta` files; Unity
  generates them.
- There is no CLI build from the repo root, and no CLI Test Runner while the
  Editor has the project open. The agent can compile-check an assembly out of
  band with Unity's `csc` (method: the `verify-unity-assembly-compiles` memory,
  `~/.claude/projects/P--Electrum-electrum-client/memory/verify-unity-assembly-compiles.md`).
  That only works for assemblies Unity has already generated a `.csproj` for,
  and new `.cs` files must be added to the source list by hand. A unit that
  creates a brand-new assembly therefore needs an Editor refresh, which makes
  its validation **Agent + Engineer**.
- Unity doesn't compile an assembly definition that has no scripts. It warns
  that the assembly "will not be compiled", and doesn't generate a `.csproj`.
  Create an asmdef in the same task, or at least the same unit, as its first
  script.
- Branch names are validated. Branches, commits and pushes are the engineer's.

## Breakdown mode

### 1. Intake

- Read the comprehensive plan in full, then the Future Iterations doc it
  links. If no plan was provided, ask for it and stop.
- Note the plan's `Revision`. The breakdown records it as "Plan read".
- Build a glossary of every ID the plan uses (`R` requirements, `A` approach,
  `S` scope, `C` constraints, `CD` critical decisions, `NB` review items, `P`
  proposals, `§N` steps), each with a one-line excerpt. All of them are defined
  in the comprehensive plan. Cards cite these.
- Note the plan's base branch, prerequisites, step order, which steps it says
  can run in parallel, its Affected Files table and its Non-Goals.
- If the plan has unresolved Blocking Decisions, or an `Open` blocking proposal,
  stop. They belong to `tims-adversarial-plan` (or `tims-tech-plan-review`
  for a plan already written), not here.

### 2. Verify the plan against the repo

The plan was written at a point in time, possibly against a different branch
from the one checked out. Before slicing it:

- After a `git fetch`, check every file path, symbol, line reference and
  precedent the plan cites **on the plan's base branch**
  (`git show origin/<base>:<path>`, `git grep <symbol> origin/<base> -- <path>`),
  not in the working tree.
- Check that files the plan marks **new** don't already exist, and that no step
  needs a file the plan marks **unchanged**.
- Check the state the work will start from: the current branch, whether the
  working tree is clean, and what the Editor has open. A prerequisite the
  engineer must resolve (e.g. uncommitted work on another branch) goes on the
  prerequisite task and into the review.
- Anything that changes a task's content, boundary or order is a Critical
  Decision. Trivial drift (a moved line number) goes in the breakdown's Plan
  Verification Notes with the corrected reference.
- Do not edit the plan. The engineer decides, and if the plan needs
  correcting they amend it with `tims-tech-plan-review`, which adds the
  amendment note and keeps the brief Tech Plan in sync. Re-read the amended
  sections before slicing them.

### 3. Decompose into tasks

- Walk the plan in order and turn each step into one or more tasks using the
  atomic rules above.
- Plan prerequisites (a ticket, a branch, a setup step) become the first
  tasks, from `T00`. Point to the repo skill that performs one where it exists.
- Put every detail the implementer needs on the card: signatures, constants,
  exact strings, snippets, gotchas, precedent file and line. Copy the plan's
  wording where it is exact. The card must never send the agent back to
  re-derive something the plan already settled.
- Copy snippets **without planning IDs in their code comments**: no task, unit,
  plan or decision IDs (`T07`, `WU3`, `R14`, `CD1`, `NB7`, `D2`) and no
  planning-level names (`L0`). Reword such a comment so it reads on its own, or
  drop it if it was only an ID, and cite the IDs in the card text instead. Code
  copied from a card ends up committed.
- Anything the plan leaves to "confirm when implementing" becomes an explicit
  **Confirm** step: what to confirm, how, and what to do with each answer. If
  the answer could change the design, escalate now instead.

### 4. Group into work units

- Walk the tasks in order and close a unit at each natural testing boundary,
  using the work-unit rules above.
- Move every "Done when" item of every plan step onto exactly one unit's
  Validation, verbatim, tagged with its plan step. Put each item on the
  **first unit where it can actually be observed**, which may be later than
  the unit holding that plan step's tasks. Record where an item moved and why.
- Add the unit's own checks: it compiles (every assembly the unit touches),
  guard tests, and any behaviour its tasks introduce that the plan's items
  don't cover. Never drop a plan item.
- Write each check so its executor can run it exactly: commands for the agent;
  for the engineer, numbered Editor steps, each with its expected result. The
  engineer's part is read out inline when the unit is validated, so write it as
  instructions, not notes.
- Write each unit's plain-English summary, then each card's, once the
  technical content is fixed.

### 5. Order

- Task IDs are `T01`, `T02`… in execution order, with prerequisites at `T00`
  (`T00a`, `T00b` for several). Unit IDs are `WU0` (prerequisites), `WU1`,
  `WU2`… in order.
- Record task dependencies explicitly. Depend on a task only when its output is
  needed, and don't serialise what the plan allows in parallel within a unit.
- Record unit dependencies. A unit depends on every earlier unit whose output
  its tasks or checks need.

### 6. Coverage check

Before presenting, confirm, and record in the breakdown's Coverage section:

- every plan step maps to at least one task;
- every task belongs to exactly one work unit;
- every "Done when" item in the plan appears in exactly one unit's Validation;
- every ID the plan cites in its steps appears on at least one card;
- every row of the plan's Affected Files table is covered by a task, and the
  task that creates each new file is identified;
- no task does anything the plan lists as a Non-Goal, or touches a file
  outside its Affected Files.

A gap or an extra is a defect in the breakdown. Fix it, or escalate if fixing
it needs a design decision.

### 7. Review with the engineer

- Present the Work Units (ID, outcome, tasks, validated by, depends on) and the
  Task Map (ID, title, executor, dependencies, unit), plus any Critical
  Decisions and Plan Verification Notes. Show full cards or unit validation
  lists only on request.
- Iterate on splits, merges, grouping and ordering until the engineer approves.
  Confirm the document locations.

### 8. Write

- Write the Task Breakdown.
- Create the Task Status document with `tims-task-status init`, from the
  breakdown: every task and unit `Todo`, Resume Here pointing at the first
  unit.
- Offer to start the first ready unit in continue mode.

## Continue mode

The Task Status document is the resume point. Assume the session starting now
knows nothing else.

### 1. Load

Invoke `tims-task-status` on the Task Status document. Then read the Task
Breakdown's header, Work Units, Task Map, the current unit (its Validation and
its cards), then the plan sections those cards cite. Don't read everything else
up front.

### 2. Reconcile with reality

The document may be stale, since a session can end mid-task. Before trusting
it:

- Run `tims-task-status reconcile`: branch, files on disk, in-progress work and
  internal consistency. It reports discrepancies and applies corrections only
  once the engineer confirms.
- **Plan drift** (this skill's check): if the plan's `Revision` is newer than
  the breakdown's "Plan read" revision, read the plan's Change Log rows since
  then, re-read the sections they changed, and flag every change that affects
  the current unit or a later one. (For an older plan pair, compare modified
  dates instead.) A change that affects a card or a unit's checks is handled
  through the amendment rules.

### 3. Report

Give the engineer the `tims-task-status summary`, plus:

- for a unit that is `Ready to Validate`: go straight to step 8 and give the
  inline validation checklist;
- the next action: the next task in the current unit, or the next unit (ID,
  outcome, plain-English summary, who validates it).

### 4. Choose the next work

- Finish the current unit (all its tasks, then its validation) before starting
  another.
- Otherwise take the first `Todo` unit whose dependencies are all `Done`.
  Confirm with the engineer **once, before starting the unit**.
- Within the unit, work its tasks in ID order as their dependencies allow,
  back to back, without per-task confirmation. Stop at every Critical Decision
  and every Engineer task. Pause between tasks only if the engineer asks.

### 5. Pre-flight (each task)

- Re-check the card's "Read first" references against the current code. If
  something moved, correct the card and log it. If it changed materially,
  escalate.
- Mark the task `In Progress` (and the unit `In Progress` if it wasn't) with
  `tims-task-status set`, which saves the document **before any code
  changes.**

### 6. Execute (each task)

- **Agent:** invoke the `tims-implementation-agent` skill with the handoff
  below as its arguments.
- **Engineer:** show the card's Steps as a checklist, wait, and record what
  the engineer reports (`tims-task-status log`).

```
Implement exactly one task: <ID> — <title>. Do not start any other task.

Task card (verbatim):
<full card>

This task belongs to work unit <WU ID> — <name>. It is validated with that
unit, not on its own:
- Do not run compile checks, tests or other validation for this task, and do
  not report it as verified. The unit's validation covers it.
- Do not stage or commit anything. The engineer handles all git operations.
- Do not write task, unit, plan or decision IDs (or "L0"-style level names) in
  code, comments, test names or messages. Strip them from any snippet you copy
  from the card.

Documents:
- Comprehensive tech plan: <path> (design authority for this task, below the codebase)
- Task Breakdown: <path>
- Task Status: <path>. Update it only through tims-task-status, and do not
  create another. Log this task under its ID with Validation "Deferred to
  <WU ID>", and "To validate" notes: what to check, how, the expected result
  and edge cases. Repeat those notes in your final report.

Escalate any conflict between the card, the plan and the codebase as a
Critical Decision. Stop once this task's Steps are done.
```

### 7. Record (each task)

When the task stops, whether finished, blocked or interrupted:

- Set the task's status with `tims-task-status set`: `Implemented` when its
  Steps are done, otherwise `In Progress` or `Blocked`.
- Check that the task has a Step Log entry with **To validate** notes (the
  implementation agent writes it; write it for an Engineer task). Record any
  decisions or risks through `tims-task-status record`. The skill keeps the
  boards, header and Resume Here in step.
- Continue with the unit's next task, or go to unit validation if this was the
  last.

### 8. Validate the work unit

When every task in the unit is `Implemented`:

1. Mark the unit `Ready to Validate` (`tims-task-status set`).
2. Run every **Agent** check in the unit's Validation, and report each result
   inline: the check, what you ran, passed or failed, and the evidence. Agent
   results recorded in an earlier session count only if `reconcile` found no
   change to the unit's files since that run; otherwise re-run them as a new
   attempt.
3. If the unit needs the engineer, give them the **Engineer** checks **inline,
   in chat** (there is no validation document). Build the checklist from the
   unit's Validation and How to validate, plus its tasks' **To validate**
   notes in the Step Log:
   - a numbered list, one check per item;
   - each item: what to open and do (exact steps), what they should see, and
     what to report back;
   - name everything concretely: asset and scene paths, menu items, field
     names, values to set and expect. If the breakdown is vague ("edit a
     resolved settings asset"), look the concrete target up in the repo first;
   - edge cases worth trying, as their own items;
   - end with: "Ask me about any step if you need more detail."

   A check marked **Agent + Engineer** has both parts: run the agent part in
   step 2, put the engineer part on this checklist, and count the check as
   passed only when both parts pass.
4. Wait for the answers, and answer follow-up questions about any step in the
   same session. A question isn't a result: keep the check open until the
   engineer reports it.
5. Record the run with `tims-task-status record` (each check passed or failed,
   with evidence).
6. **All checks pass:** mark the unit `Done`, which marks each of its tasks
   `Done`.
7. **Any check fails:** mark the unit `Failed`. Trace the failure to the task
   that caused it, and propose a fix task (the next unused ID, added to this
   unit) through the amendment rules. Once it's approved and implemented,
   re-run the **whole** unit's validation, not just the failed check.
8. Stop and report: the unit's check results, what changed, and the next unit.

Never offer to commit. When a unit is `Done`, say so; the engineer decides what
to commit and when.

### Status values

Task and work-unit statuses (`Todo`, `In Progress`, `Blocked`, `Implemented`,
`Ready to Validate`, `Failed`, `Done`, `Dropped`) and the rules tying them
together are defined in `tims-task-status`.

## Amending the breakdown

- IDs are stable. Never renumber or reuse a task or unit ID.
- Split a task into `T07a`, `T07b`. Give a new task the next unused number and
  place it in the Task Map by dependency and in its unit.
- Mark a removed task `Dropped` with the reason. Never delete a card.
- Moving a task between units, or a check between units, is an amendment.
- Log every amendment with `tims-task-status record` (a breakdown change), and
  change the breakdown and the boards together.
- Amendments that change scope, contracts, behaviour or a unit's checks need
  engineer approval first. Fixing a path or line reference doesn't, but is
  still logged.
- If an amendment shows the plan itself is wrong, escalate. Don't edit the plan
  from here; the engineer amends it with `tims-tech-plan-review`.

## Critical Decisions

Escalate when:

- the plan conflicts with the codebase on its base branch;
- a plan step can't be made atomic without choosing between designs;
- the plan is ambiguous in a way that changes a task's content, boundary or
  order;
- a plan "Done when" item can't be met as written by any unit;
- anything on `tims-adversarial-plan`'s or `tims-implementation-agent`'s
  Critical Decision lists comes up.

Placing a plan check on a later unit than its plan step, because that's where
it can first be observed, is normal grouping, not a Critical Decision. Record
it in the unit and in Coverage.

A Blocking Decision marks the affected tasks `Blocked` and pauses them. A
Non-Blocking Review Item is recorded and work continues. Record every
resolution with `tims-task-status record` (a decision), with the tasks and
units it affects.

```markdown
## Critical Decision

### Type
Blocking Decision | Non-Blocking Review Item

### Tasks / Units Affected
<IDs>

### Problem
Clear explanation, in the context of the repository and the plan.

### Options

#### Option A
- Explanation
- Benefits
- Risks/Tradeoffs

#### Option B
- Explanation
- Benefits
- Risks/Tradeoffs

### Recommendation
Recommended option and why. Prefer repository consistency and the plan as written.

### Example Implementation
Only where needed for clarity.
```

## The plain-English summary

Every work unit and every task card opens with **In plain English**, written
for a non-technical colleague such as a producer or designer:

- 2–4 short sentences. For a task: what it adds or changes and why it's
  needed. For a unit: what someone can do or see once it's validated. If
  nothing is visible yet, say so and say what it makes possible.
- No code names, file paths, class names or acronyms. If a term can't be
  avoided, explain it in the same sentence.
- Describe outcomes, not mechanics.

Good: *"Adds the record that stores the result of a bake: where each ship is at
every moment of the run. Nothing is visible yet; later tasks use it to play the
run back and to draw each ship's path."*

Bad: *"Implements `CombatShapeBake` with `GetFrame`/`Sample` (Lerp/Slerp) over a
`frameCount × n` array."*

## Templates

### Task Breakdown

```markdown
<header or tag block matching sibling docs>

# <Feature>: Task Breakdown

- **Comprehensive tech plan:** <link> (plan read: revision <N>, <YYYY-MM-DD>)
- **Also:** Future Iterations <link> · Tech Plan (summary) <link> · Tech Proposals <link>
- **Task Status (resume here):** <link>
- **Repo:** `<absolute path>` · base `<branch>` · working branch `<branch, or "created in T00">`
- **Plan verified against:** `<base>` @ `<short sha>` on <YYYY-MM-DD>
- **ID key:** <each prefix the plan uses and where it is defined>

## Overview
<Plain English, 3–6 sentences: what's being built, in what order, and when there
is first something to see.>

## Work Units
| ID | After this unit you can… | Tasks | Validated by | Depends on |
|---|---|---|---|---|

## Task Map
| ID | Task | Executor | Depends on | Work unit | Plan step | Traces to |
|---|---|---|---|---|---|---|

<Which tasks can run in parallel within a unit.>

## Units and Tasks
<For each unit in order: the unit block, then the cards of its tasks in ID order.>

## Coverage
| Plan step | Tasks | Its "Done when" items validated in |
|---|---|---|

| Plan ID | Tasks |
|---|---|

| Affected file | Created / changed by |
|---|---|

Not covered by design: see the plan's Non-Goals (<link>).

## Plan Verification Notes
| Plan reference | Checked on `<base>` | Result | Resolution |
|---|---|---|---|
```

### Work unit

```markdown
## <WU ID> — <outcome-style name>

**In plain English:** <2–4 sentences: what someone can do or see once this unit is validated>

| | |
|---|---|
| **Tasks** | <IDs> |
| **Depends on** | <unit IDs, or —> |
| **Validated by** | Agent · Agent + Engineer |

**Why these tasks are validated together:** <one or two sentences: what can only be observed once all of them are done>

**Validation**
- [ ] <unit check, e.g. "Electrum.X compiles"> (Agent | Engineer | Agent + Engineer)
- [ ] <plan "Done when" item, verbatim> (plan §N) (Agent | Engineer | Agent + Engineer)
- [ ] <plan "Done when" item moved here from §M, verbatim> (plan §M; observable from this unit) (Agent | Engineer | Agent + Engineer)

**How to validate**
- Agent: <exact commands or inspections, in order>
- Engineer (read out inline at validation time):
  1. <what to open and do> → expect <what they should see>
  2. …
```

### Task card

```markdown
### <ID> — <imperative title>

**In plain English:** <2–4 sentences, per the rules above>

| | |
|---|---|
| **Executor** | Agent · Engineer |
| **Work unit** | <WU ID> |
| **Depends on** | <IDs, or —> |
| **Plan step** | <link to the plan section> |
| **Traces to** | <IDs> |

**Goal:** <one technical sentence>

**Read first**
- Plan: <section link>, for <what to take from it>
- Plan IDs: `R23` "<one-line excerpt>"; `C1` "<one-line excerpt>"
- Precedent: `<repo path>:<lines>`, for <the pattern to copy>
- Repo rules: <only the ones that apply here: AGENTS.md section, guard test, .editorconfig>
- API docs: <official, version-matched docs (e.g. the Unity Scripting API for the version in
  `ProjectSettings/ProjectVersion.txt`) for any API with no precedent in the repo>

**Files** (nothing outside this list)
- new `<path>`: <purpose>
- change `<path>`: <what changes>

**Steps**
1. <Concrete and ordered. Include the plan's signatures, constants and snippets, with no planning IDs in their code comments.>
2. …
3. **Confirm:** <anything the plan left open: what, how, and what to do with each answer>

**Not in this task**
- <adjacent work, naming the task that owns it, or the Non-Goal it falls under>

**Validated in:** <WU ID>, checks <which of the unit's checks cover this task>
```

### Task Status

The Task Status template, in full and standalone variants, is defined in
`tims-task-status`.

## Guardrails

- Slice the design; never change it.
- Never fabricate. Every card and unit detail traces to the comprehensive plan
  or code verified on the base branch. Unknowns become questions.
- Validate only at work-unit level. Never validate, or mark `Done`, a single
  task on its own.
- Update the Task Status document through `tims-task-status` at every state
  change, not only at the end of a session. A session can end at any moment.
- One unit at a time, and within it one task at a time. Never mark a unit
  `Done` while a check still needs the engineer.
- Give validation instructions inline, never in a separate document.
- Keep the breakdown and the status document in step.
- Keep planning IDs out of code: never put them in a snippet's code comments on
  a card, and tell the implementation agent not to write them.
- Never stage, commit, push or create branches, and never offer to. Git is the
  engineer's. Don't create tickets without the engineer's go-ahead.
