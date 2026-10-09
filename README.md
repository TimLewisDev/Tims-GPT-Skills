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
| [`tims-familiarise`](tims-familiarise/SKILL.md) | Explores a part of the codebase with you, a question at a time, until you've pinned down what you actually care about. |
| [`tims-familiarisation-doc`](tims-familiarisation-doc/SKILL.md) | Writes up only the part of that exploration you said you're interested in, as a readable doc. |
| [`tims-adversarial-plan`](tims-adversarial-plan/SKILL.md) | Runs planning stage by stage, has an adversary challenge each stage, and gets you to a signed-off plan. |
| [`tims-requirements`](tims-requirements/SKILL.md) | Planning stage 1: pins down what the feature must do. |
| [`tims-scope`](tims-scope/SKILL.md) | Planning stage 2: what the feature is and isn't, and the hard constraints. |
| [`tims-approach`](tims-approach/SKILL.md) | Planning stage 3: weighs candidate approaches against the repo and records the choice. |
| [`tims-technical-design`](tims-technical-design/SKILL.md) | Planning stage 4: verifies repo facts, resolves critical decisions, outlines the steps. |
| [`tims-plan-signoff`](tims-plan-signoff/SKILL.md) | Final stage: your sign-off, then the finished plan, Tech Plan and Future Iterations. |
| [`tims-tech-proposals`](tims-tech-proposals/SKILL.md) | Lays out each decision's options side by side for review, and records what was chosen. |
| [`tims-tech-plan`](tims-tech-plan/SKILL.md) | Writes a short, five-minute summary of the plan for reviewers. |
| [`tims-tech-plan-review`](tims-tech-plan-review/SKILL.md) | Talks a written plan through with you, answers questions, and makes the changes you confirm. |
| [`tims-task-breakdown`](tims-task-breakdown/SKILL.md) | Splits the plan into small tasks grouped into work units, then works through them one unit at a time. |
| [`tims-task-status`](tims-task-status/SKILL.md) | Keeps the progress record that lets any new session pick up where the last one stopped. |
| [`tims-implementation-agent`](tims-implementation-agent/SKILL.md) | Writes the code for one task (or a small plan), strictly within scope. |
| [`tims-mr-review`](tims-mr-review/SKILL.md) | Reviews a GitLab merge request and posts only the comments you approve. |
| [`tims-common`](tims-common/SKILL.md) | Not run directly: the shared rules for long runs and for planning, shared templates, and the helper scripts the other skills call. |

## How they fit together

```text
"I want to explore how X works"          Spec or ticket
  │                                        │
  ▼                                        │
tims-familiarise ──► Focus Log             │
tims-familiarisation-doc ──► Familiarisation
  │                                        │
  ▼                                        ▼
tims-adversarial-plan (orchestrator), one stage at a time:
  ├─ tims-requirements       ┐ each writes into the draft
  ├─ tims-scope              │ Comprehensive Tech Plan, with
  ├─ tims-approach           │ decisions via tims-tech-proposals ──► Tech Proposals
  ├─ tims-technical-design   ┘
  │    after every stage (and the whole plan): an adversary subagent ──► Challenges
  │    then a break point: carry on, or resume in a fresh session
  └─ tims-plan-signoff, on your sign-off, writes:
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

1. **Explore (optional).** `tims-familiarise` starts from a loose question,
   shows you the code a piece at a time and follows your lead until the focus
   is clear. `tims-familiarisation-doc` writes up just that focus. The doc
   stands on its own, and it's where planning starts.
2. **Plan.** `tims-adversarial-plan` runs the stages in order. Each stage asks
   one question at a time and adds what you agree to the *Consensus Ledger* in
   the draft plan. Each choice between options becomes a proposal you can read
   before deciding. After each stage, an adversary that sees only the written
   documents and the code attacks the stage's reasoning, and you settle each
   challenge. You can stop after any stage and resume later in a fresh
   session. Planning only finishes when you explicitly sign off the whole
   ledger.
3. **Review.** Read the Tech Plan and Tech Proposals. Run
   `tims-tech-plan-review` to walk through the plan, ask about it, or change it.
4. **Break down.** `tims-task-breakdown` checks the plan against the repo,
   proposes tasks and work units, and writes them once you approve.
5. **Build and validate, one unit at a time.** Continue mode picks up from the
   Task Status, does the unit's tasks, then validates the whole unit. It stops
   after each unit.
6. **Commit and publish yourself.** No skill stages, commits, pushes or creates
   branches. Once there's an MR, `tims-mr-review` can review it.

## Where to start

| You want to… | Run |
|---|---|
| explore how something in the codebase works | `/tims-familiarise <what you want to explore>` |
| write up an exploration | `/tims-familiarisation-doc [focus log]` |
| plan a feature from an idea, exploration, spec or ticket | `/tims-adversarial-plan [description, familiarisation doc, spec or ticket]` |
| carry on planning (next stage, or the pending challenge) | `/tims-adversarial-plan resume <draft plan>` |
| work on one planning stage in its own session | `/tims-requirements`, `/tims-scope`, `/tims-approach`, `/tims-technical-design` or `/tims-plan-signoff` `<draft plan>` |
| review, question or change a written plan | `/tims-tech-plan-review [tech plan] [comprehensive tech plan]` |
| break a signed-off plan into tasks | `/tims-task-breakdown <comprehensive tech plan>` |
| carry on building | `/tims-task-breakdown continue <task status doc>` |
| see where things stand | `/tims-task-status <task status doc>` |
| implement a small plan or ticket without a breakdown | `/tims-implementation-agent <plan, spec or ticket>` |
| rebuild the brief Tech Plan | `/tims-tech-plan <comprehensive tech plan>` |
| tidy a proposals doc, or create one for an existing plan | `/tims-tech-proposals <proposals doc or comprehensive tech plan>` |
| review a GitLab MR | `/tims-mr-review [MR number or branch]` |

`[…]` is optional and `<…>` is required. If you're new to these skills, start with
`tims-adversarial-plan`; it offers to explore the code first when that helps.

## Key ideas

### The documents

All the documents for a feature sit in one folder (an Obsidian vault or a
folder in the repo, agreed during planning) and share a prefix, usually the
feature name. Links are `[[wiki-links]]` in a vault and relative Markdown links
elsewhere.

| Document | File name | Written by | What it's for |
|---|---|---|---|
| Familiarisation | `<Prefix> - Familiarisation.md` | `tims-familiarisation-doc` | How the part of the code you care about works today, with open questions. Description only; where planning starts. |
| Comprehensive Tech Plan | `<Prefix> - Comprehensive Tech Plan.md` | the planning stages, run by `tims-adversarial-plan`; changed only through `tims-tech-plan-review` once signed off | The authority: requirements, approach, scope, constraints, decisions, verified repo facts and step-by-step design. While it's a draft, its **Stages** table records where planning is. |
| Tech Proposals | `<Prefix> - Tech Proposals.md` | `tims-tech-proposals` | Each decision's options, the recommendation, and the outcome. |
| Challenges | `<Prefix> - Challenges.md` | `tims-adversarial-plan` | What each stage's adversary attacked, the evidence, and how you settled it. |
| Tech Plan | `<Prefix> - Tech Plan.md` | `tims-tech-plan` | A brief view of the comprehensive plan. Adds nothing of its own. |
| Future Iterations | `<Prefix> - Future Iterations.md` | `tims-plan-signoff` | Work that came up and was deliberately left out. |
| Task Breakdown | `<Prefix> - Task Breakdown.md` | `tims-task-breakdown` | Task cards and work units, each with an *In plain English* summary for non-technical readers. |
| Task Status | `<Prefix> - Task Status.md` | `tims-task-status` | Progress, logs, decisions and validation results. A new session reads this first. |

### IDs and revisions

Everything agreed in planning gets a stable ID that is never renumbered or
reused: `R` requirements, `A` approach, `S` scope and non-goals, `C`
constraints, `CD` blocking decisions, `NB` non-blocking review items, `P`
proposals, `CH` challenges, `§N` plan steps. Every line of the Tech Plan cites
the IDs it summarises.

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

### Long runs: small responses, drafts on disk, subagents

A single model response has a time limit (a few minutes, thinking included),
and one ever-growing conversation gets slow. So the skills follow
[`tims-common/orchestration.md`](tims-common/orchestration.md):

- **No response writes a whole document.** Large documents are built from part
  files in a hidden draft folder beside them (`.tims/<Prefix> - <Doc>/`) and
  stitched together by a script. If a session stalls, re-running the skill (or
  saying "continue") picks up at the first missing part instead of starting
  again.
- **Reading, verifying and mechanical writing run in subagents**, up to four at
  a time, mostly on Sonnet: repo research while you're being interviewed,
  checking every reference a plan cites, writing task cards from a skeleton
  you've approved, audits, and rendering the Tech Plan. Questions, decisions
  and design writing always stay in the main conversation.
- **The adversary is a subagent too**, on the default model because it weighs
  reasoning. It gets only the documents and the code, never the conversation,
  so it also tests whether each stage's handover stands on its own.
- **Planning is split into stages** so no session has to hold all of it. Each
  stage reads only the sections it needs from disk, and the draft plan's
  Stages table says where to pick up.
- **Implementation is one subagent per task**, so the conversation that
  coordinates a work unit stays small. The coordinator is the only writer of
  the Task Status.
- **Scripts do the mechanical checks** (bash and git only):
  `verify-refs.sh` (every path and `path:line` a doc cites, at a commit),
  `check-planning-ids.sh`, `assemble.sh`, `md-section.sh`, `ids.sh`,
  `status-boards.sh` and `status-counts.sh`.

Agents that can't spawn subagents do the same steps themselves, still one part
per response.

### Repo rules come from the repo

The skills don't assume a language or engine. How to build or compile-check,
which files are owned by a tool and must not be hand-edited, and branch rules
are read from the repo's agent instructions (`AGENTS.md`, `CLAUDE.md` or
equivalent). If they don't say how to compile-check, the breakdown asks once
and records the answer.

## Skill reference

### [`tims-familiarise`](tims-familiarise/SKILL.md): explore the code

A guide, not a planner: you start with a loose question, and it shows you the
code a piece at a time until you've boiled it down to what you care about.

- **Run it:** `/tims-familiarise <what you want to explore>`, e.g. "how
  notifications are sent when an order ships"; carry on later with
  `/tims-familiarise resume <focus log>`.
- **How a session goes:** it asks why you're exploring (to change, debug,
  plan or learn), maps the area with read-only subagents, describes what it
  finds in plain words with `path:line` references and small diagrams, then
  asks which way to dig. Every few turns it plays back what it thinks you're
  really after and asks you to rate the topics: **Focus**, **Context** or
  **Parked**.
- **Writes:** a Focus Log in `.tims/<Prefix> - Familiarisation/`, updated
  every turn, so a fresh session can carry on or write it up.
- **Won't:** design, recommend or plan, or decide for you what you're
  interested in.

### [`tims-familiarisation-doc`](tims-familiarisation-doc/SKILL.md): write up the exploration

- **Run it:** `/tims-familiarisation-doc [focus log]`, straight after
  exploring or in a fresh session.
- **Writes:** `<Prefix> - Familiarisation.md`, covering only your Focus
  topics and the context needed to read them: the question, the answer in
  short, how it works today, key parts, data and contracts, rules the code
  imposes, gotchas, open questions (not agreed), and what was left out. Every
  reference is checked at the pinned commit.
- **Then:** read it on its own, or plan from it with
  `/tims-adversarial-plan <familiarisation doc>`.

### [`tims-adversarial-plan`](tims-adversarial-plan/SKILL.md): plan a feature

An orchestrator. It runs the planning stages in order, has an adversary
challenge each one, and only finishes on your explicit sign-off.

- **Run it:** `/tims-adversarial-plan [description, familiarisation doc, spec
  or ticket]`; carry on with `/tims-adversarial-plan resume <draft plan>`.
- **Stages:** familiarisation (optional) → `tims-requirements` →
  `tims-scope` → `tims-approach` → `tims-technical-design` → a whole-plan
  challenge → `tims-plan-signoff`. Each stage is a skill of its own that writes
  its Ledger sections into the draft plan. Shared rules live in
  [`tims-common/planning-protocol.md`](tims-common/planning-protocol.md).
- **The adversary:** after each stage, a subagent that sees only the written
  documents and the code attacks that stage's assumptions, using the stage's
  own `challenge-lens.md`. Every challenge is put to you: accept and change,
  rebut, or defer. The outcomes are kept in `<Prefix> - Challenges.md`. A
  stage closes only when no blocking challenge is still unresolved.
- **Break points:** after each stage it summarises, gives the resume command,
  and asks whether to carry on or stop. The draft plan's Stages table is the
  handover.
- **The Ledger is on disk:** the Comprehensive Tech Plan exists from Setup
  with Status `Draft`, and fills in as items are agreed. Chat shows only what
  changed. Other skills refuse to work from a `Draft` plan.
- **Key rules:** one question at a time; a contradiction stops progress until
  you resolve it, even if it reopens a closed stage; blocking decisions wait
  for your choice, while review items apply the recommendation and stay open
  for review; it never decides you're finished, and "looks fine" doesn't count
  as sign-off.
- **Won't:** write production code, or add test plans, rollout plans or
  speculative work unless you ask.

### The planning stages

Normally run by `tims-adversarial-plan`. Each can also be run on its own with
the draft plan's path, to work on one stage in a session of its own. It then
ends by pointing you to `/tims-adversarial-plan resume <plan>`, so that the
stage still gets challenged.

| Stage | Settles | Notes |
|---|---|---|
| [`tims-requirements`](tims-requirements/SKILL.md) | `R`: what the feature must do | Probes with hypotheticals; builds on the Familiarisation doc's description and open questions; maps the repo in the background if there's no Familiarisation doc. |
| [`tims-scope`](tims-scope/SKILL.md) | `S`, `C`: what it is and isn't; hard constraints | Seeds non-goals from what the exploration left out, and constraints from the repo's rules; records excluded work for Future Iterations. |
| [`tims-approach`](tims-approach/SKILL.md) | `A`, Rejected Alternatives | At least two candidates, each researched against the repo by a subagent; the choice is a proposal you decide. |
| [`tims-technical-design`](tims-technical-design/SKILL.md) | Repo Facts, `CD`, `NB`, step outline | Verifies every claim at the pinned commit; hunts critical decisions; outlines the steps in dependency order. |
| [`tims-plan-signoff`](tims-plan-signoff/SKILL.md) | sign-off, finished plan set | The termination gate, then the full steps, audits, Revision 1, Tech Plan and Future Iterations. |

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
  branch; drafts a skeleton (units, tasks, files, where each "Done when" check
  lands) for you to approve; then has subagents write the self-contained task
  cards, one unit each; audits coverage; assembles the documents.
- **Continue mode:** reconciles the Task Status with the repo and flags plan
  changes since the breakdown (both in subagents); confirms the next unit with
  you once; runs each task in its own implementation subagent, back to back;
  then validates the unit.
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
- **Checks:** correctness, security, performance, style (the repo's rules and
  `.editorconfig` are the source of truth), test coverage, and stack-specific
  checks from `references/` when the repo uses that stack (Unity and C#
  today). Changed files are reviewed in parallel groups, and every critical or
  major finding is challenged by a separate subagent before it's shown. Each
  finding has a file, line, severity and suggested fix. Binary and generated
  files are skipped.
- **Key rules:** shows every finding before posting anything; posts only the
  inline comments and summary you approve (partial approvals work); flags only
  issues the MR introduced or made worse.
- **Won't:** approve or merge the MR.

## Requirements

- **Claude Code features:** the skills call each other through the Skill tool,
  ask questions with `AskUserQuestion`, and spawn subagents with the Agent tool
  (asking for `model: sonnet` for mechanical work). Other agents may need
  equivalents, or do the subagents' work themselves.
- **bash and git** for the scripts (Git Bash on Windows). No other runtime.
- **A Sonnet model your provider serves.** The `sonnet` alias resolves through
  `ANTHROPIC_DEFAULT_SONNET_MODEL`; on Bedrock or a gateway, set it to a model
  ID your account accepts if the default doesn't. If a Sonnet subagent fails
  to start, the skills fall back to the default model.
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

`tims-common` must be linked too: the other skills find their scripts at
`../tims-common/` from their own folder. When a new skill folder appears after
a pull, link it the same way.

### Measuring a run

[`tools/transcript-metrics.sh`](tools/transcript-metrics.sh) reads Claude Code's
session transcripts and prints, per session and subagent: model minutes, the
largest single response, responses over 8k tokens, the largest context,
responses over 4 minutes, stalls, and subagent calls. Use it to compare runs:

```sh
bash tools/transcript-metrics.sh --since 2026-10-08 ~/.claude/projects/<project>
```

## License

[MIT](LICENSE).
