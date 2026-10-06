# Tims-GPT-Skills

A library of skill workflows for use with Claude, Codex, or GitHub Copilot.

The repository contains eight skills, each defined in a top-level directory's
`SKILL.md`. These files provide agent instructions and document templates, not
an application or executable workflow engine. Installation and host-specific
skill registration are not documented here.

## Workflow at a glance

The main workflow is human-controlled feature delivery:

```text
Feature description, spec, or ticket
  |
  v
tims-adversarial-plan
  |-- tims-tech-proposals --> Tech Proposals (options and decisions)
  |-- writes -------------> Future Iterations (only when work is excluded)
  |-- writes -------------> Comprehensive Tech Plan (design authority)
  `-- tims-tech-plan ------> Tech Plan (brief human-readable view)
                                  |
                       Engineer review and amendments
                                  |
                                  v
Comprehensive Tech Plan --> tims-task-breakdown
                              |-- Task Breakdown (cards and work units)
                              `-- tims-task-status --> Task Status (resume point)
                                  |
                                  v
                     Continue one work unit at a time
                              |-- tims-implementation-agent (one Agent task)
                              |-- Engineer tasks (tool-based work)
                              `-- Work-unit validation (Agent and/or Engineer)

tims-tech-plan-review amends the comprehensive plan and synchronizes its views.
tims-mr-review separately reviews an existing GitLab merge request.
```

The planning and breakdown skills explicitly describe this pipeline:
[planning workflow, lines 34–52](tims-adversarial-plan/SKILL.md#L34-L52);
[breakdown workflow, lines 41–62](tims-task-breakdown/SKILL.md#L41-L62).

## Where to start

These entry points are inferred from the skills' documented inputs and
safeguards; the skills are not formally divided into beginner and advanced tiers.

| Your situation | Entry point | What to expect |
|---|---|---|
| You have an idea, spec, or unclear requirements | `/tims-adversarial-plan <optional description, spec or ticket>` | Guided questions, repository-grounded options, and explicit agreement before the final plan. |
| You want to review a proposed feature | Read the generated Tech Plan and Tech Proposals | A brief summary and side-by-side decision options. |
| You want a progress summary or are returning to existing work | `/tims-task-status <task status doc>` | Progress, blockers, reconciliation, and the next action. |
| You want to continue implementation | `/tims-task-breakdown continue <task status doc>` | Resume the current unit, implement its tasks, then validate it. |
| You already have an execution-ready comprehensive plan | `/tims-task-breakdown <comprehensive tech plan>` | Dependency-ordered task cards and validated work units. |
| You need to amend a signed-off plan | `/tims-tech-plan-review <tech plan> <comprehensive tech plan>` | Confirmed amendments propagated across the authoritative plan and its views. |
| You need to regenerate a summary | `/tims-tech-plan <comprehensive tech plan>` | A fresh brief view, not new design. |
| You need to tidy or backfill decision records | `/tims-tech-proposals <proposals doc or comprehensive tech plan>` | Presentation cleanup or proposals derived from already-recorded alternatives. |
| You have a tightly scoped implementation request | `tims-implementation-agent`, with a task card, plan, spec, ticket, or explicit instructions | Bounded implementation with progress records and escalation of critical decisions. |
| You have an existing GitLab MR to review | MR review workflow; documented command: `/el-mr-review [mr]` | Findings presented before any approved comments are posted. |

For beginners, the guided planner and generated review documents are the most
natural starting points. Advanced users can enter directly at decomposition,
amendment, document maintenance, or standalone implementation when the required
inputs already exist. Every task card and work unit also includes an
outcome-oriented, non-technical **In plain English** summary.
[Planner intake, lines 22–32](tims-adversarial-plan/SKILL.md#L22-L32);
[brief review format, lines 50–69](tims-tech-plan/SKILL.md#L50-L69);
[plain-English summaries, lines 569–579](tims-task-breakdown/SKILL.md#L569-L579).

## Skill inventory

### `tims-adversarial-plan` — discover requirements and design the feature

This is the planning entry point. It pressure-tests requirements, compares at
least two repository-grounded approaches, establishes scope and constraints,
and resolves technical decisions. It asks one focused question at a time and
maintains a visible Consensus Ledger; contradictions halt progress until the
engineer reconciles them.

- **Input:** optional feature description, spec, or ticket.
- **Outputs:** Comprehensive Tech Plan at revision 1, Tech Proposals, brief Tech
  Plan, and Future Iterations if excluded work was identified.
- **Dependencies:** calls `tims-tech-proposals` live as decisions arise and
  `tims-tech-plan` at handoff.
- **Gate:** every blocking proposal must be resolved, and the engineer must
  explicitly confirm agreement with the full ledger.
- **Next:** review the human-facing documents, amend through
  `tims-tech-plan-review` if needed, then run `tims-task-breakdown`.
- **Boundary:** no production code or staging, commits, or pushes.

Sources: [ledger and questioning, lines 140–164](tims-adversarial-plan/SKILL.md#L140-L164);
[approach selection, lines 182–206](tims-adversarial-plan/SKILL.md#L182-L206);
[contradictions, lines 243–256](tims-adversarial-plan/SKILL.md#L243-L256);
[proposals and handoff, lines 299–352](tims-adversarial-plan/SKILL.md#L299-L352);
[guardrails, lines 493–504](tims-adversarial-plan/SKILL.md#L493-L504).

### `tims-tech-proposals` — present options and preserve decisions

This skill maintains the Tech Proposals document for human comparison and
review. The calling planner or plan reviewer owns the options and facts; this
skill arranges them without inventing content.

- **Usage:** `/tims-tech-proposals <proposals doc or comprehensive tech plan>`.
- **Operations:** create, add, decide, and supersede.
- **Statuses:** `Open`, `Default applied`, `Decided`, and `Superseded`.
- **History:** reopening a decided proposal creates a new proposal and preserves
  the previous outcome.
- **Standalone:** tidy layout, check consistency, or backfill proposals using
  alternatives and rationale already recorded in a comprehensive plan.
- **Dependencies:** route content mismatches to `tims-tech-plan-review`; after
  confirmed backfill links, have `tims-tech-plan` update an existing summary.
- **Boundary:** no production code or staging, commits, or pushes.

Sources: [usage and ownership, lines 19–48](tims-tech-proposals/SKILL.md#L19-L48);
[statuses and operations, lines 50–85](tims-tech-proposals/SKILL.md#L50-L85);
[standalone workflow, lines 116–148](tims-tech-proposals/SKILL.md#L116-L148).

### `tims-tech-plan` — render the brief review document

Despite its name, this is a **renderer, not a planning skill**. It summarizes
the Comprehensive Tech Plan without adding, inferring, or reinterpreting design.

- **Usage:** `/tims-tech-plan <comprehensive tech plan>`.
- **Input requirement:** a comprehensive plan must already exist. Specs,
  tickets, and briefs are redirected to `tims-adversarial-plan`.
- **Modes:** Write, Regenerate, or targeted Update.
- **Dependencies:** normally called by `tims-adversarial-plan`,
  `tims-tech-plan-review`, or `tims-tech-proposals`.
- **Traceability:** every summary bullet and table row cites authoritative IDs;
  the header records `Mirrors revision`.
- **Format:** approximately 60–120 lines, a five-minute read, and no code blocks.
  Proposal content contributes only IDs and statuses.
- **Boundary:** no production code or staging, commits, or pushes.

Sources: [usage and modes, lines 18–48](tims-tech-plan/SKILL.md#L18-L48);
[renderer rules and checks, lines 50–99](tims-tech-plan/SKILL.md#L50-L99).

### `tims-tech-plan-review` — amend a written plan consistently

This is the designated route for substantive changes to an existing plan.
It applies exactly the engineer's requested amendments and follows their impact
through related requirements, decisions, steps, files, and views.

- **Usage:** `/tims-tech-plan-review <tech plan> <comprehensive tech plan>`.
  Either path order works; one path suffices if it links the other.
- **Prerequisite:** the comprehensive plan must be available; check revision
  synchronization before amending.
- **Gate:** handle amendments individually and confirm each change set.
- **Dependencies:** decision changes use `tims-tech-proposals`; summary updates
  follow `tims-tech-plan`.
- **Order:** comprehensive plan first, then brief Tech Plan, affected proposals,
  and Future Iterations.
- **History:** substantive amendments preserve notes and stable IDs, increment
  the revision, and add Change Log entries.
- **Boundary:** never edits Task Breakdown or Task Status documents, production
  code, or commits. Existing execution work is flagged for follow-up in
  breakdown continue mode.

Sources: [usage and ownership, lines 20–50](tims-tech-plan-review/SKILL.md#L20-L50);
[sync and execution impact, lines 54–77](tims-tech-plan-review/SKILL.md#L54-L77);
[amendment procedure and handoff, lines 86–157](tims-tech-plan-review/SKILL.md#L86-L157).

### `tims-task-breakdown` — decompose, orchestrate, and validate

This skill slices an execution-ready Comprehensive Tech Plan into atomic,
dependency-ordered tasks and groups them into work units. It does not redesign
the feature or write production code itself.

- **Breakdown mode:** `/tims-task-breakdown <comprehensive tech plan>`.
- **Continue mode:** `/tims-task-breakdown continue <task status doc>`.
- **Authority:** a brief Tech Plan or proposals document is only a route to the
  comprehensive plan, not an independent design source.
- **Dependencies:** `tims-task-status` owns execution records;
  `tims-implementation-agent` implements one Agent task per handoff.
- **Task:** one implementation concern, one executor, and a self-contained card.
  Tasks carry no independent validation.
- **Work unit:** consecutive tasks validated together, preferably 2–5 tasks,
  although a single-task unit is allowed.
- **Ordering:** prerequisites start at `T00`; tasks and units record explicit
  dependencies. Every plan completion check belongs to exactly one unit.
- **Boundary:** git operations belong to the engineer.

Sources: [usage and authority, lines 21–74](tims-task-breakdown/SKILL.md#L21-L74);
[status ownership, lines 76–87](tims-task-breakdown/SKILL.md#L76-L87);
[task and unit definitions, lines 116–194](tims-task-breakdown/SKILL.md#L116-L194);
[ordering and coverage, lines 291–350](tims-task-breakdown/SKILL.md#L291-L350).

### `tims-task-status` — maintain the single resume record

This skill owns all writes to the Task Status document: boards, progress,
Resume Here, Step Logs, decisions, risks, improvements, and validation attempts.

- **Usage:** `/tims-task-status <task status doc>`.
- **Standalone behavior:** give a resume summary and reconcile with repository
  reality; recorded corrections require engineer confirmation.
- **Callers:** breakdown uses initialization, state changes, summaries,
  reconciliation, and validation records; implementation uses logs, blockers,
  risks, improvements, and standalone initialization.
- **Persistence:** save every state change, including `In Progress` before code
  changes. Recompute derived fields together.
- **Completion:** `Implemented` means task steps are finished; `Done` means its
  work unit passed validation. Unanswered engineer checks prevent unit completion.
- **Reconciliation:** check branch, files, partial work, board agreement, and stale
  validation evidence. Plan drift belongs to `tims-task-breakdown`.
- **Boundary:** no staging, commits, pushes, or branch creation.

Sources: [usage and callers, lines 19–38](tims-task-status/SKILL.md#L19-L38);
[consistency and statuses, lines 40–99](tims-task-status/SKILL.md#L40-L99);
[reconciliation and summary, lines 162–201](tims-task-status/SKILL.md#L162-L201).

### `tims-implementation-agent` — implement strictly bounded changes

This is an implementation skill, not a planning skill. It needs a task card,
plan, or explicit instructions before writing code. Its file describes input
modes rather than providing a slash-command Usage section.

- **Via breakdown:** implement exactly one task, use the existing Task Status,
  and leave validation to the work unit.
- **Standalone:** implement a supplied plan/spec/ticket, initialize minimal status
  if necessary, perform a minimum compile check, and provide inline engineer
  validation steps.
- **Dependency:** all status writes go through `tims-task-status`.
- **Authority:** codebase reality, engineer instructions, task card, plan, then
  general best practices.
- **Autonomy:** tactical local decisions only. Critical decisions stop code
  changes and require engineer guidance.
- **Amendments:** plan changes go through `tims-tech-plan-review`; card changes
  go through `tims-task-breakdown`.
- **Boundary:** no unrelated cleanup, speculative improvements, unauthorized
  dependency changes, or git operations.
- **Traceability:** planning IDs belong in the Step Log, not production code,
  comments, test names, or messages.

Sources: [modes, lines 10–24](tims-implementation-agent/SKILL.md#L10-L24);
[authority and boundaries, lines 26–116](tims-implementation-agent/SKILL.md#L26-L116);
[code traceability, lines 118–151](tims-implementation-agent/SKILL.md#L118-L151);
[escalation, status, and validation, lines 172–262](tims-implementation-agent/SKILL.md#L172-L262).

### `tims-mr-review` — review an existing GitLab merge request

This separate workflow reviews correctness, security, performance,
maintainability, Unity/C# conventions, and test coverage, then optionally posts
approved findings.

- **Naming caveat:** the directory and metadata say `tims-mr-review`, but the
  heading and documented command say `el-mr-review` and `/el-mr-review [mr]`.
  The file does not resolve which command an installed host exposes.
- **Input:** MR number, source branch, or the current branch when omitted.
- **Dependencies:** authenticated `glab` or GitLab MCP, a resolvable MR, and
  preferably its working tree. Without the repository, review is diff-only.
- **Context:** fetch the MR diff, read changed text files, and optionally read
  a linked JIRA ticket.
- **Gate:** present findings before publishing; inline and summary comments
  require explicit approval, including partial approvals.
- **Ordering:** independent of the planning skills and usable after an MR exists.
  It does not create or merge the MR.

Sources: [identity, usage, and prerequisites, lines 1–41](tims-mr-review/SKILL.md#L1-L41);
[diff and context, lines 58–94](tims-mr-review/SKILL.md#L58-L94);
[review dimensions, lines 96–188](tims-mr-review/SKILL.md#L96-L188);
[approval and publishing, lines 190–303](tims-mr-review/SKILL.md#L190-L303).

## Documents and ownership

| Document | Owner | Role |
|---|---|---|
| Comprehensive Tech Plan | `tims-adversarial-plan`; amended through `tims-tech-plan-review` | Authoritative requirements, scope, constraints, decisions, repository facts, and implementation design. |
| Tech Proposals | `tims-tech-proposals` | Human-readable options and decision history. |
| Tech Plan | `tims-tech-plan` | Brief view of the comprehensive plan. |
| Future Iterations | Planner; affected amendments through plan review | Deliberately excluded work, separate from implementation scope. |
| Task Breakdown | `tims-task-breakdown` | Execution cards, dependencies, work units, and their checks. |
| Task Status | `tims-task-status` | Persistent execution evidence and the single resume point. |

Sources: [planning document ownership, lines 47–52](tims-adversarial-plan/SKILL.md#L47-L52);
[execution document ownership, lines 76–87](tims-task-breakdown/SKILL.md#L76-L87).

### Output naming

Generated documents share a folder and prefix. These are output conventions,
not example feature documents included in this repository.

| Document | Obsidian-style name | Name under `Tasks/STAR-XXXXX/` |
|---|---|---|
| Comprehensive Tech Plan | `<Prefix> - Comprehensive Tech Plan.md` | `STAR-XXXXX.techplan-full.md` |
| Tech Plan | `<Prefix> - Tech Plan.md` | `STAR-XXXXX.techplan.md` |
| Tech Proposals | `<Prefix> - Tech Proposals.md` | `STAR-XXXXX.proposals.md` |
| Future Iterations | `<Prefix> - Future Iterations.md` | `STAR-XXXXX.future.md` |
| Task Breakdown | `<Prefix> - Task Breakdown.md` | `STAR-XXXXX.tasks.md` |
| Task Status | `<Prefix> - Task Status.md` | `STAR-XXXXX.status.md` |

Vault documents use wiki-links; repository documents use relative Markdown
links. The planner avoids `STAR-XXXXX.plan.md`, which it attributes to an
external `el-start-issue` workflow.
[Planning names, lines 54–66](tims-adversarial-plan/SKILL.md#L54-L66);
[breakdown names, lines 93–103](tims-task-breakdown/SKILL.md#L93-L103).

Stable IDs connect the artifacts: `R` requirements, `A` approach, `S` scope and
non-goals, `C` constraints, `CD` blocking decisions, `NB` review items, `P`
proposals, and `§N` plan steps. The comprehensive plan carries a Revision and
Change Log; the summary records its mirrored revision. IDs are never renumbered
or reused.
[Planning IDs and sync, lines 68–85](tims-adversarial-plan/SKILL.md#L68-L85).

## Execution and validation lifecycle

1. **Agree on the feature.** Resolve blocking decisions and explicitly sign off
   the full ledger before final planning output.
2. **Review and amend.** Read the brief Tech Plan and proposals. Change meaning
   through plan review, updating the comprehensive authority first.
3. **Verify and decompose.** Check plan references on its base branch, create
   atomic cards, group them into units, and verify coverage. The engineer
   approves the breakdown before it is written and status is initialized.
4. **Resume safely.** Read Task Status first, reconcile with reality, and inspect
   newer plan Change Log entries for drift affecting current or later work.
5. **Implement one unit.** Confirm the unit once. Persist each task's
   `In Progress` state before work, then execute Agent or Engineer tasks as
   dependencies allow. Record completed steps as `Implemented`.
6. **Validate the unit.** Run Agent checks and present concrete Engineer checks
   inline. Pending answers remain pending; all checks must pass for `Done`.
7. **Handle failures.** Propose an approved fix task within the failed unit, then
   rerun the whole unit's validation, not just the failed check.
8. **Report and hand back control.** Stop after unit validation and report the
   next unit. The engineer chooses when to commit and publish; the MR review
   workflow can later review an existing GitLab MR.

Sources: [planning gate and output, lines 318–352](tims-adversarial-plan/SKILL.md#L318-L352);
[amendment order, lines 121–148](tims-tech-plan-review/SKILL.md#L121-L148);
[verification and decomposition, lines 232–350](tims-task-breakdown/SKILL.md#L232-L350);
[resume and execution, lines 352–450](tims-task-breakdown/SKILL.md#L352-L450);
[unit validation, lines 454–494](tims-task-breakdown/SKILL.md#L454-L494).

**Deferred validation is not omitted validation.** Tasks are designed to leave
the project compilable, but compilation is checked at work-unit level. Breakdown
adds compile checks, guard tests, and behavioral checks alongside the plan's
completion criteria. The planner separately avoids broad test plans unless
requested, keeping design and execution validation at different layers.
[Task atomicity, lines 133–149](tims-task-breakdown/SKILL.md#L133-L149);
[unit checks, lines 291–305](tims-task-breakdown/SKILL.md#L291-L305);
[planning exclusions, lines 373–383](tims-adversarial-plan/SKILL.md#L373-L383).

## Dependencies and portability caveats

- **Host capabilities:** planning refers to a Skill tool and `AskUserQuestion`.
  Equivalent invocation and interactive support across Claude, Codex, and
  Copilot are not established by these files.
  [Selection, lines 194–202](tims-adversarial-plan/SKILL.md#L194-L202);
  [skill invocation, lines 309–311](tims-adversarial-plan/SKILL.md#L309-L311).
- **Repository access and git:** planning, amendment verification, and breakdown
  verify facts on a fetched base branch, not just the current working tree.
  Read-only inspection is distinct from the staging, committing, pushing, and
  branching left to the engineer.
  [Base-branch checks, lines 221–238](tims-adversarial-plan/SKILL.md#L221-L238);
  [breakdown verification, lines 249–270](tims-task-breakdown/SKILL.md#L249-L270).
- **Electrum and Unity/C# assumptions:** several skills reference Electrum
  patterns, Unity-managed assets, an external `AGENTS.md`, and Editor workflows.
  Breakdown cites a local Claude memory file for out-of-band assembly compilation;
  standalone implementation uses the same external procedure. Those supporting
  files and tools are not supplied by this repository.
  [Electrum precedents, lines 188–192](tims-adversarial-plan/SKILL.md#L188-L192);
  [Unity execution assumptions, lines 212–230](tims-task-breakdown/SKILL.md#L212-L230);
  [standalone compilation, lines 247–251](tims-implementation-agent/SKILL.md#L247-L251).
- **Human tool work:** Unity scenes, prefabs, assets, and metadata are normally
  Engineer tasks; new assemblies require an Editor refresh before the described
  compilation method can work.
  [Executors and Unity rules, lines 196–230](tims-task-breakdown/SKILL.md#L196-L230).
- **GitLab and optional JIRA integration:** MR review requires GitLab
  authentication and a resolvable MR. Ticket lookup is conditional on integration
  availability. `STAR-XXXXX` is a naming convention, not a bundled ticket system.
  [MR prerequisites, lines 35–41](tims-mr-review/SKILL.md#L35-L41);
  [optional ticket context, lines 92–94](tims-mr-review/SKILL.md#L92-L94).
- **Legacy formats:** breakdown accepts older Tech Plan + Feature Consensus pairs
  as a combined plan, but plan review rejects that format. Task Status accepts
  older Testing Framework links and log fields without rewriting historical
  entries; the Testing Framework document is no longer updated.
  [Legacy breakdown, lines 105–114](tims-task-breakdown/SKILL.md#L105-L114);
  [review restriction, lines 31–35](tims-tech-plan-review/SKILL.md#L31-L35);
  [legacy status, lines 203–213](tims-task-status/SKILL.md#L203-L213).

The defining principle is separation of responsibilities: design authority,
human-readable views, execution cards, persistent evidence, and implementation
each have an owner. Consequential decisions and publication stay with the
engineer rather than becoming autonomous end-to-end delivery.

## License

[MIT](LICENSE).
