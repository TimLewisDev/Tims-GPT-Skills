# Tims-GPT-Skills

Skills for planning and building a feature with an AI coding agent while the
engineer keeps control: every consequential decision is theirs, every plan
change is confirmed, and git is never touched. A separate skill reviews GitLab
merge requests.

Each skill is a `SKILL.md` file in its own folder, written for Claude Code and
usable with other agents that read the same format (Codex, GitHub Copilot).
They are instructions and document templates, not code.

## The skills

| Skill | What it does |
|---|---|
| [`tims-adversarial-plan`](tims-adversarial-plan/SKILL.md) | Interviews you about a feature, pressure-tests it against the repo, and writes the plan once you sign off. |
| [`tims-tech-proposals`](tims-tech-proposals/SKILL.md) | Lays out each decision's options side by side for review, and records what was chosen. |
| [`tims-tech-plan`](tims-tech-plan/SKILL.md) | Writes a short, five-minute summary of the plan for reviewers. |
| [`tims-tech-plan-review`](tims-tech-plan-review/SKILL.md) | Talks a written plan through with you, answers questions, and makes the changes you confirm. |
| [`tims-task-breakdown`](tims-task-breakdown/SKILL.md) | Splits the plan into small tasks grouped into work units, then works through them one unit at a time. |
| [`tims-task-status`](tims-task-status/SKILL.md) | Keeps the progress record that lets any new session pick up where the last one stopped. |
| [`tims-implementation-agent`](tims-implementation-agent/SKILL.md) | Writes the code for one task (or a small plan), strictly within scope. |
| [`tims-mr-review`](tims-mr-review/SKILL.md) | Reviews a GitLab merge request and posts only the comments you approve. |

## How they fit together

```text
Idea, spec or ticket
  │
  ▼
tims-adversarial-plan ──(live)──► tims-tech-proposals ──► Tech Proposals
  │  on sign-off, writes:
  ├─► Comprehensive Tech Plan   (the authority)
  ├─► Future Iterations         (only if work was left out)
  └─► tims-tech-plan ──────────► Tech Plan (brief summary for review)
  │
  ▼
You review the Tech Plan and Proposals
  └─ tims-tech-plan-review: questions and changes, at any time
  │
  ▼
tims-task-breakdown  (breakdown mode)
  ├─► Task Breakdown            (task cards, grouped into work units)
  └─► tims-task-status ────────► Task Status (progress and resume point)
  │
  ▼
tims-task-breakdown  (continue mode), one work unit at a time:
  ├─ Agent tasks    ──► tims-implementation-agent
  ├─ Engineer tasks ──► a checklist for you
  └─ validate the unit, then stop and report

tims-mr-review stands apart: run it on any open GitLab MR.
```

In order:

1. **Plan.** `tims-adversarial-plan` asks one question at a time and keeps a
   visible *Consensus Ledger* of everything agreed. Each choice between options
   becomes a proposal you can read before deciding. It only finishes when you
   explicitly sign off the whole ledger.
2. **Review.** Read the Tech Plan and Tech Proposals. Run
   `tims-tech-plan-review` to walk through the plan, ask about it, or change it.
3. **Break down.** `tims-task-breakdown` checks the plan against the repo,
   proposes tasks and work units, and writes them once you approve.
4. **Build and validate, one unit at a time.** Continue mode picks up from the
   Task Status, does the unit's tasks, then validates the whole unit. It stops
   after each unit.
5. **Commit and publish yourself.** No skill stages, commits, pushes or creates
   branches. Once there's an MR, `tims-mr-review` can review it.

## Where to start

| You want to… | Run |
|---|---|
| plan a feature from an idea, spec or ticket | `/tims-adversarial-plan [description, spec or ticket]` |
| review, question or change a written plan | `/tims-tech-plan-review [tech plan] [comprehensive tech plan]` |
| break a signed-off plan into tasks | `/tims-task-breakdown <comprehensive tech plan>` |
| carry on building | `/tims-task-breakdown continue <task status doc>` |
| see where things stand | `/tims-task-status <task status doc>` |
| implement a small plan or ticket without a breakdown | `/tims-implementation-agent <plan, spec or ticket>` |
| rebuild the brief Tech Plan | `/tims-tech-plan <comprehensive tech plan>` |
| tidy a proposals doc, or create one for an existing plan | `/tims-tech-proposals <proposals doc or comprehensive tech plan>` |
| review a GitLab MR | `/tims-mr-review [MR number or branch]` |

`[…]` is optional and `<…>` is required. If you're new to these skills, start with
`tims-adversarial-plan`.

## Key ideas

### The documents

All the documents for a feature sit in one folder (an Obsidian vault or a
folder in the repo, agreed during planning) and share a prefix, usually the
feature name. Links are `[[wiki-links]]` in a vault and relative Markdown links
elsewhere.

| Document | File name | Written by | What it's for |
|---|---|---|---|
| Comprehensive Tech Plan | `<Prefix> - Comprehensive Tech Plan.md` | `tims-adversarial-plan`; changed only through `tims-tech-plan-review` | The authority: requirements, approach, scope, constraints, decisions, verified repo facts and step-by-step design. |
| Tech Proposals | `<Prefix> - Tech Proposals.md` | `tims-tech-proposals` | Each decision's options, the recommendation, and the outcome. |
| Tech Plan | `<Prefix> - Tech Plan.md` | `tims-tech-plan` | A brief view of the comprehensive plan. Adds nothing of its own. |
| Future Iterations | `<Prefix> - Future Iterations.md` | `tims-adversarial-plan` | Work that came up and was deliberately left out. |
| Task Breakdown | `<Prefix> - Task Breakdown.md` | `tims-task-breakdown` | Task cards and work units, each with an *In plain English* summary for non-technical readers. |
| Task Status | `<Prefix> - Task Status.md` | `tims-task-status` | Progress, logs, decisions and validation results. A new session reads this first. |

### IDs and revisions

Everything agreed in planning gets a stable ID that is never renumbered or
reused: `R` requirements, `A` approach, `S` scope and non-goals, `C`
constraints, `CD` blocking decisions, `NB` non-blocking review items, `P`
proposals, `§N` plan steps. Every line of the Tech Plan cites the IDs it
summarises.

The comprehensive plan has a `Revision` and a Change Log. Each review session
that changes its meaning bumps the revision once, and every change leaves an
amendment note quoting the old text. The Tech Plan records the revision it
mirrors, and the breakdown records the revision it was built from, so later
plan changes show up as drift.

### Tasks, work units and who does what

- A **task** is one change: one concern, small enough for one session and one
  review. Every task has one **executor**:
  - **Agent**: code and text files the agent can write.
  - **Engineer**: work done by hand in a tool (an editor, a designer tool, an
    admin console), plus tickets and branches.
- A **work unit** is a few consecutive tasks (usually 2–5) that are **validated
  together**. Tasks are never validated on their own: compile checks, tests and
  the plan's "Done when" checks all run per unit, where their results can
  actually be seen.
- A unit is validated by the **Agent**, or by **Agent + Engineer** when some
  checks need you. Your checks are given inline in chat as numbered steps, with
  what you should see.
- A task is `Implemented` when its steps are done, and `Done` only when its
  unit passes validation. If a check fails, a fix task is added to the unit and
  the whole unit is validated again.

### Repo rules come from the repo

The skills don't assume a language or engine. How to build or compile-check,
which files are owned by a tool and must not be hand-edited, and branch rules
are read from the repo's agent instructions (`AGENTS.md`, `CLAUDE.md` or
equivalent). If they don't say how to compile-check, the breakdown asks once
and records the answer.

## Skill reference

### [`tims-adversarial-plan`](tims-adversarial-plan/SKILL.md): plan a feature

Acts as a *collaborative adversary*: challenges assumptions, probes edge cases
and pushes for an explicit "is / is not" scope, without blocking progress.

- **Run it:** `/tims-adversarial-plan [description, spec or ticket]`
- **Reads → writes:** your intake and the repo → Comprehensive Tech Plan
  (revision 1), Tech Proposals, Future Iterations (if needed), Tech Plan.
- **Calls:** `tims-tech-proposals` as each decision comes up;
  `tims-tech-plan` at hand-off.
- **Key rules:** one question at a time; at least two approaches, each grounded
  in the repo's existing patterns (`path:line`); a contradiction stops progress
  until you resolve it; blocking decisions wait for your choice, while review
  items apply the recommendation and stay open for review; it never decides
  you're finished, and "looks fine" doesn't count as sign-off.
- **Won't:** write production code, or add test plans, rollout plans or
  speculative work unless you ask.

### [`tims-tech-proposals`](tims-tech-proposals/SKILL.md): present decisions

Makes each decision easy to review later without the conversation that
produced it: the question, a side-by-side table, each option under the same
headings, the recommendation, and the decision.

- **Run it:** normally called by the planner or plan review. Run directly to
  tidy a proposals doc and check it against its plan, or to create proposals
  for a plan that has none, using only the alternatives the plan records.
- **Statuses:** `Open`, `Default applied` (recommendation in use, open for
  review), `Decided`, `Superseded`.
- **Key rules:** the calling skill supplies every option and fact, and this
  skill only arranges them; proposals are never deleted, and reopening a
  decided one creates a new proposal that supersedes it.
- **Won't:** invent options, benefits or risks; change plan content (it
  reports mismatches to `tims-tech-plan-review`).

### [`tims-tech-plan`](tims-tech-plan/SKILL.md): summarise the plan

A renderer, not a planner: it turns the comprehensive plan into a five-minute
read (about 60–120 lines, no code blocks).

- **Run it:** `/tims-tech-plan <comprehensive tech plan>`. Usually called by
  other skills.
- **Modes:** *Write* (new), *Regenerate* (full rewrite), *Update* (only the
  lines citing changed IDs).
- **Key rules:** every line cites its IDs; records `Mirrors revision`; anything
  missing from the plan is reported, not patched into the summary.
- **Won't:** add, infer or reinterpret anything. Given a spec or ticket, it
  points you to `tims-adversarial-plan`.

### [`tims-tech-plan-review`](tims-tech-plan-review/SKILL.md): review and change a plan

A conversational review partner, and the only way a written plan changes.

- **Run it:** `/tims-tech-plan-review [tech plan] [comprehensive tech plan]`.
  Either order works; one path is enough if it links the other; with none, it
  asks.
- **How a session goes:** it reads the whole plan set (and any breakdown,
  read-only), then gives a short orientation: revision, whether the Tech Plan
  is in sync, open proposals and breakdown progress. Then it asks what you'd
  like: a section-by-section walkthrough, the open proposals, a specific
  change, or questions. It loops until you say you're done, then summarises.
- **Changes:** one at a time. It shows the impact and a before/after for every
  affected document, and writes only after you confirm. The comprehensive plan
  changes first, then the Tech Plan, Proposals and Future Iterations.
- **Key rules:** one revision per session however many changes it makes;
  confirming a `Default applied` proposal records the decision without a new
  revision; switching a decision's option goes through a proposal.
- **Won't:** edit the Task Breakdown or Task Status. Changes show up as drift
  the next time `tims-task-breakdown` continues.

### [`tims-task-breakdown`](tims-task-breakdown/SKILL.md): slice and deliver

Turns the plan into tasks and work units, then drives the build one unit at a
time. It slices the design but never changes it.

- **Run it:** `/tims-task-breakdown <comprehensive tech plan>` (breakdown
  mode), or `/tims-task-breakdown continue <task status doc>` (continue mode;
  `resume` and `status` also work).
- **Breakdown mode:** verifies every path and symbol the plan cites on its base
  branch; writes self-contained task cards; places every "Done when" check on
  exactly one unit; checks coverage; writes the documents only after you
  approve.
- **Continue mode:** reconciles the Task Status with the repo; flags plan
  changes since the breakdown; confirms the next unit with you once; runs its
  tasks back to back; then validates the unit.
- **Calls:** `tims-task-status` for every status change;
  `tims-implementation-agent` for each Agent task.
- **Won't:** redesign the feature, edit the plan (it sends you to
  `tims-tech-plan-review`), or offer to commit.

### [`tims-task-status`](tims-task-status/SKILL.md): keep the resume point

Owns every write to the Task Status doc, so it stays something a fresh session
can trust.

- **Run it:** `/tims-task-status <task status doc>` for a summary, a
  consistency check and a reconcile with the repo. Usually called by other
  skills.
- **Operations:** `init`, `set`, `log`, `record`, `reconcile`, `summary`.
- **Key rules:** saves at every state change, including `In Progress` before
  any code changes; boards, header and *Resume Here* always agree; corrections
  found by reconcile are applied only after you confirm; nothing is deleted.
- **Standalone mode:** when `tims-implementation-agent` works from a plan with
  no breakdown, the doc has no work units and a task is `Done` once its
  compile check passes.
- **Won't:** check for plan drift (that's the breakdown's job), or stage,
  commit, push or branch.

### [`tims-implementation-agent`](tims-implementation-agent/SKILL.md): write the code

Implements exactly what it's given and escalates everything else.

- **Run it:** called by `tims-task-breakdown` with one task card, or directly
  with a plan, spec or ticket (standalone).
- **Via a breakdown:** one task only; no validation, but it leaves *To
  validate* notes for the unit's checks.
- **Standalone:** works the plan's steps in order, keeps a minimal Task Status,
  runs a compile check using the repo's method, and gives you inline
  validation steps.
- **Key rules:** the codebase is the source of truth, ahead of your
  instructions, the task card and the plan; it makes only small local
  decisions itself; anything bigger is a *Critical Decision* that marks the
  task `Blocked` and waits for you; it records improvements it spots instead of
  making them; no planning IDs (`T07`, `R14`, `CD1`…) in code, comments or test
  names.
- **Won't:** expand scope, refactor nearby code, add dependencies, or touch
  git.

### [`tims-mr-review`](tims-mr-review/SKILL.md): review a GitLab MR

A line-by-line review meant to stand in for a senior engineer's review.

- **Run it:** `/tims-mr-review [MR number or branch]`. With no argument, it
  uses the MR for the current branch.
- **Needs:** `glab` (authenticated) or a GitLab MCP server; ideally the repo
  checked out, otherwise it reviews from the diff alone.
- **Checks:** correctness, security, performance, style (`.editorconfig` is the
  source of truth), Unity and C# conventions, and test coverage. Each finding
  has a file, line, severity and suggested fix. Binary and Unity-managed files
  are skipped.
- **Key rules:** shows every finding before posting anything; posts only the
  inline comments and summary you approve (partial approvals work); flags only
  issues the MR introduced or made worse.
- **Won't:** approve or merge the MR.

## Requirements

- **Claude Code features:** the skills call each other through the Skill tool
  and ask questions with `AskUserQuestion`. Other agents may need equivalents.
- **A git repo with a base branch:** facts are checked on `origin/<base>`
  after a `git fetch`, not in the working tree.
- **Agent instructions in the repo** (`AGENTS.md`, `CLAUDE.md` or equivalent)
  for build checks and tool-managed files. Without them, the skills ask you.
- **For `tims-mr-review`:** GitLab, with `glab` or a GitLab MCP server. An
  issue-tracker integration is optional and used to read the linked issue.

## Setup (Claude Code)

Claude Code finds personal skills at `~/.claude/skills/<skill-name>/SKILL.md`,
exactly one folder deep, so it won't see them inside a cloned repo folder.
Clone the repo anywhere, then link each skill folder into `~/.claude/skills`:

```powershell
# Windows (PowerShell): directory junctions, no admin rights needed
Get-ChildItem <clone path> -Directory -Filter "tims-*" | ForEach-Object {
  New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\$($_.Name)" -Target $_.FullName
}
```

```sh
# macOS / Linux
for d in <clone path>/tims-*/; do ln -s "${d%/}" ~/.claude/skills/; done
```

A `git pull` in the clone updates every skill, and edits made through
`~/.claude/skills` show up as changes in the clone. Restart Claude Code to pick
up new skills.

## License

[MIT](LICENSE).
