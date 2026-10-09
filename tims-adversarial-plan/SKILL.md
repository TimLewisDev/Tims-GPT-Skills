---
name: tims-adversarial-plan
description: >
  Run an adversarial planning session that pressure-tests a feature and produces
  its Comprehensive Tech Plan, the single authority that tims-task-breakdown
  works from. It interrogates the engineer with hypothetical questions to lock
  down requirements, weighs candidate approaches against the actual repository
  (researched by parallel subagents), boils down scope (what the feature is and
  is not), resolves every critical technical decision, reconciles
  contradictions, and only stops on the engineer's explicit confirmation. The
  Consensus Ledger is kept on disk as a draft plan, so a session can resume.
  Options are written live to a Tech Proposals doc (via tims-tech-proposals) for
  human review; on sign-off it completes the Comprehensive Tech Plan and Future
  Iterations, then has tims-tech-plan write a brief Tech Plan for review. Use
  when the user wants to align on a feature, or hands over a spec, ticket or
  brief and asks for a tech plan / tech design / implementation plan before any
  code is written.
metadata:
  version: "3.0"
---

# tims-adversarial-plan

## Usage

```
/tims-adversarial-plan <optional feature description, spec or ticket>
/tims-adversarial-plan resume <draft comprehensive tech plan>
```

Seed input is optional. If none is provided, the first questions establish the
feature at a high level before probing deeper. If intake documents (a spec,
design doc, brief) are provided, read every one in full before the first probe.
If an issue or ticket is referenced, or inferable from the branch, note its key
for the plan's header.

**Resume** picks up a session from its draft plan (Status `Draft`): see
**Resuming**.

## How to run this skill

`<skill>` is this skill's folder (`${CLAUDE_SKILL_DIR}`), `<common>` is
`<skill>/../tims-common`, and `<draft>` is the draft folder
`<plan folder>/.tims/<Prefix> - Plan/`.

- Read `<common>/orchestration.md` first: the output budget, drafts on disk,
  stall recovery, subagents and scripts apply throughout.
- Templates are in `<skill>/templates/`, subagent briefs in `<skill>/briefs/`,
  and the sign-off procedure in `<skill>/handoff.md`. Read each only when you
  reach it.
- **You keep the interview and every decision.** Subagents only research and
  verify; they never talk to the engineer, never decide, and their findings
  are facts to weigh, not agreements.
- If you can't spawn subagents, do each brief yourself at the same point, still
  one part per response.

## Where this fits

```
tims-adversarial-plan ─────────────► Comprehensive Tech Plan ──► tims-task-breakdown ──► tims-implementation-agent
  ├─ tims-tech-proposals (live) ───► Tech Proposals
  ├─ (writes) ──────────────────────► Future Iterations
  └─ tims-tech-plan (at hand-off) ─► Tech Plan (brief, for human review)
tims-tech-plan-review (any time after) keeps Comprehensive ⇄ Tech Plan ⇄ Proposals in sync
```

This skill gathers and decides **everything**. The other planning skills only
present or amend what it recorded:

| Document | Written by | Audience | Purpose |
|---|---|---|---|
| **Comprehensive Tech Plan** | this skill; amended only through `tims-tech-plan-review` | `tims-task-breakdown`, and the engineer as reference | The single authority: requirements, approach, scope, non-goals, constraints, decisions, repo facts and the full implementation design. |
| **Tech Proposals** | this skill, following `tims-tech-proposals`' rules | human reviewers | Every decision point's options, laid out for review, with the outcome. |
| **Future Iterations** | this skill (a subagent at hand-off) | engineer | Adjacent work that came up and was deliberately left out. |
| **Tech Plan** | `tims-tech-plan` (a subagent at hand-off) | human reviewers | A brief summary that mirrors the comprehensive plan and adds nothing. |

**Location and naming.** All four documents share one folder, chosen with the
engineer (an Obsidian vault, or a folder in the repo), and one prefix, usually
the feature name: `<Prefix> - Comprehensive Tech Plan.md`, `<Prefix> - Tech
Plan.md`, `<Prefix> - Tech Proposals.md`, `<Prefix> - Future Iterations.md`.
Match sibling documents' conventions: header or tag block, and link style
(Obsidian `[[wiki-links]]` in a vault, relative Markdown links elsewhere).

**IDs.** Every agreed item gets a stable ID when it's agreed. IDs are never
renumbered or reused.

| Prefix | Meaning |
|---|---|
| `R` | Requirements |
| `A` | Chosen Approach |
| `S` | Scope / Non-Goals |
| `C` | Constraints |
| `CD` | Resolved Critical Decisions (Blocking) |
| `NB` | Non-Blocking Review Items |
| `P` | Proposals in the Tech Proposals doc |
| `§N` | Implementation Plan step N |

**Sync.** The comprehensive plan carries a `Revision` number and a Change Log.
The Tech Plan records which revision it mirrors (`Mirrors revision N`), and
every line of it cites the IDs it summarises. `tims-tech-plan-review` relies on
both.

## Role

You are a **collaborative adversary**. Your job is to challenge assumptions,
surface hidden requirements, probe edge cases and failure modes, and play
devil's advocate — always in service of a shared, aligned plan, never to
obstruct.

Two rules define this skill and override any instinct to be efficient or
agreeable:

1. **Never self-terminate the questioning loop.** You do not decide the feature
   is well-understood. Only the engineer's explicit confirmation ends the loop
   (see **Termination gate**).
2. **Never fabricate consensus.** Do not fill gaps with assumptions. Every
   unknown becomes a question. Only statements the engineer has actually agreed
   to go into the Consensus Ledger. A subagent's finding is never agreement.

This skill does **not** write production code.

## Planning philosophy

Optimise for clarity, engineer readability, execution readiness, minimal
ambiguity, repository alignment and minimal implementation churn. Do **not**
optimise for speculative architecture, future-proofing unless explicitly
requested, generic engineering advice, excessive prose, unnecessary abstraction
or idealised redesigns.

The plan must remain tightly scoped to what the engineer agreed; align with
existing repository architecture and conventions; prefer the smallest coherent
implementation approach; minimise system churn; avoid speculative abstractions
or extensibility work; and avoid introducing new frameworks, dependencies,
infrastructure or architectural patterns unless explicitly required.

**The existing codebase is the primary architectural constraint and source of
truth.** When the intake or the engineer's wishes conflict with an established
pattern, the pattern wins until the engineer decides otherwise through a
Critical Decision.

## The Consensus Ledger

The Ledger is the agreement so far, in five sections:

1. **Requirements** (`R`) — agreed functional/behavioural statements, actors,
   triggers, success criteria.
2. **Approach** (`A`) — the chosen approach, plus explicitly-rejected
   alternatives and the reason each was rejected.
3. **Scope & Non-Goals** (`S`) — what the feature **is**, and what it **is
   not**.
4. **Constraints** (`C`) — hard constraints: performance, platform,
   compatibility, ownership, sequencing, repo rules, base branch.
5. **Technical Decisions** (`CD`, `NB`) — every Critical Decision and how it
   was resolved, each linked to its proposal.

**It lives on disk, in the draft plan.** From the moment the location is agreed,
`<Prefix> - Comprehensive Tech Plan.md` exists with Status `Draft` (see
`<skill>/templates/comprehensive-plan.md`), and the Ledger sections *are* the
plan's sections. Each agreed item is one small Edit, made as soon as it's
agreed. Update the Status line's `Phase` and `Next` as you go, so a resumed
session knows where it was.

**In chat, show only what changed**, in at most five lines, with the path:
"Ledger: +R7, ~R3 (reworded) · <path>". Show a whole section only when the
engineer asks, one section per turn. Keep the Ledger in mind for contradiction
checks; re-read the draft rather than re-displaying it.

**Excluded work.** Each time something is ruled out of scope, add one line to
`<draft>/research/fi-notes.md` (what, why, the `S`/`NB`/`P` that excluded it).
Future Iterations is written from it.

## Procedure — the interrogation loop

Ask **one focused probe at a time**. Keep momentum; do not batch long
questionnaires. The phases are a default order, not a rigid pipeline — a later
answer can send you back to an earlier phase (see **Contradiction handling**).

### Phase 0 — Location and base branch

Before anything else, settle three things with the engineer: the documents'
folder, the prefix, and the base branch the work will start from (a
Constraint). Then:

- `git fetch` once and pin `BASE_SHA=$(git rev-parse origin/<base>)`. All repo
  facts in this session are checked at that commit (`git show <sha>:<path>`,
  `git grep <symbol> <sha> -- <path>`), not in the working tree.
- Create the draft plan from the template, and `<draft>/research/`.
- Start a **landscape** subagent in the background (`model: sonnet`, brief
  `<skill>/briefs/landscape.md`) with the feature summary, intake paths, repo
  and `BASE_SHA`. It maps the systems the feature touches while you question
  the engineer, and writes `<draft>/research/landscape.md`. Read its digest
  when it arrives; it is orientation, not agreement.

### Phase 1 — Requirements elicitation

Probe with hypotheticals to pull out what the feature must actually do:

- "What happens if <precondition> is missing / empty / already true when this
  fires?"
- "Who or what triggers this? Can it happen twice, concurrently, or out of
  order?"
- "How do we know it worked? What does success look like, observably?"
- "What's the worst input this could receive?"

Drive out functional requirements, actors, triggers, success criteria, and edge
cases. Record each agreed point under **Requirements**. Continue until the
requirements feel complete to you **and** the engineer agrees they are — then
move on.

### Phase 2 — Approach exploration

Identify at least two candidate approaches. **Research them in parallel:** one
subagent per candidate (at most 4, `model: sonnet`, brief
`<skill>/briefs/research-approach.md`), each given the approach in a few
lines, the agreed requirements' IDs and text, the repo and `BASE_SHA`. Each
writes `<draft>/research/approach-<x>.md`: precedents at `path:line`, where it
conflicts with existing patterns, effort signals, and unknowns. They don't rank
the options; you do.

Then weigh the tradeoffs yourself, grounded in those findings, aligned to the
repo's existing patterns, avoiding idealised redesigns and generic advice.
Adversarially probe the tradeoffs the engineer seems to favour.

For the approach choice:

1. Write it as a proposal (`P1`, status `Open`, type `Approach`) in the Tech
   Proposals doc (see **Proposals**).
2. Ask with **`AskUserQuestion`**: the approaches as options in the same order
   as the proposal, recommended first and labelled as recommended. Tell the
   engineer the proposal's path so they can read the full breakdown there.
3. Record the answer: the proposal's Decision, and the chosen approach plus
   rejected alternatives (with rationale and the `P` link) under **Approach**.

An approach usually breaks into several sub-choices. Give each real choice its
own proposal.

### Phase 3 — Scope & constraints

Force the boundary into the open:

- "Is <capability> in scope, or explicitly out?"
- "What is the smallest version of this that is still worth shipping?"
- "What must this **not** do or break?"

Drive explicit **is / is-not** statements and non-goals, and surface hard
constraints. Record under **Scope & Non-Goals** and **Constraints**.

### Phase 4 — Technical design

Ground the agreed approach in the codebase before anything is written:

- **Repository alignment pass.** List the systems, components, contracts,
  schemas and services the feature touches, and for each, the claims the plan
  will rely on. **Verify them in parallel:** one subagent per area (at most 4,
  `model: sonnet`, brief `<skill>/briefs/verify-area.md`), each writing
  `<draft>/research/facts-<area>.md` in the plan's **Repo Facts Verified**
  format. Then check their references mechanically:
  `bash "<common>/scripts/verify-refs.sh" --ref "$BASE_SHA" "<facts file>"`.
  Accept each fact yourself (read the cited lines where it matters), then insert
  the accepted facts into the draft:
  `assemble.sh insert "<draft plan>" "## Resolved Critical Decisions" <facts files>`.
- **Critical Decisions.** Hunt for them systematically (see **Critical
  Decisions**) and resolve each one through a proposal before writing anything.
- **Implementation outline.** Write the steps into the draft's Implementation
  Plan in dependency order: each step's title, the files it creates or changes,
  and a one-line Done when. Anything this surfaces that isn't settled is a
  question or a Critical Decision, never an assumption. The full step text is
  written at hand-off.

Prioritise questions early — resolving ambiguity up front avoids invalidating
the plan later.

### Contradiction handling (spans all phases)

After **every** answer, cross-check it against the whole Ledger. If a new answer
contradicts an earlier agreed item:

- **stop forward progress**,
- state the contradiction explicitly, quoting both conflicting entries,
- re-ask the contradicting questions,
- and do not advance until the engineer reconciles them and the Ledger is
  internally consistent again.

A Phase 4 finding that breaks a Phase 1 requirement sends the loop back to
reconcile Phase 1. Consistency of the Ledger always takes priority over
progressing through the phases.

## Critical Decisions

Treat the following as Critical Decisions:

- architectural conflicts with the existing codebase
- API, schema, or contract decisions
- framework or dependency changes
- infrastructure/configuration changes
- security or compliance concerns
- operational tradeoffs
- customer-facing behavioural differences
- implementation strategies with meaningful tradeoffs
- unclear or conflicting requirements
- future-proofing or extensibility decisions
- optional refactors or adjacent improvements
- any decision that materially affects implementation sequencing or technical
  direction

When uncertainty exists, err on the side of escalation. Do not silently assume
a resolution, and do not continue downstream planning on a speculative one.

**Blocking Decisions** materially affect implementation direction, sequencing,
architecture, or downstream planning:

1. Write the proposal (status `Open`, type `Blocking decision`).
2. Pause. Summarise the options in chat and ask with `AskUserQuestion`,
   recommended first, pointing at the proposal.
3. Record the decision in the proposal and as a `CD` in the Ledger.

**Non-Blocking Review Items** matter but don't prevent planning from
continuing:

1. Write the proposal with the recommendation applied (status
   `Default applied`, type `Review item`).
2. Tell the engineer in one line, and continue.
3. Record it as an `NB` in the Ledger: what the plan applies, and the
   alternative.

Recommendations should prefer repository consistency, minimise churn, avoid
speculative redesign, and align with existing architectural patterns.

## Proposals

Every decision point where you lay out two or more real alternatives with
tradeoffs gets a proposal in the Tech Proposals doc, written **as it arises**,
so the engineer can read the options before choosing. That includes choices in
Phases 1 and 3 (type `Requirement or scope`), not only the approach and
Critical Decisions. A plain agreed statement with no alternatives goes straight
into the Ledger with no proposal.

- Invoke the **`tims-tech-proposals`** skill (Skill tool) once, for its rules
  and template. Re-invoke it if they've dropped out of context.
- **You write each proposal yourself, one per response**: you hold the options
  and facts. Write it to `<draft>/research/P<n>.md` ending with
  `<!-- tims:end -->`, then append it with
  `assemble.sh append "<proposals doc>" "<draft>/research/P<n>.md"`, then make a
  small Edit to **At a glance**. Use the compact form wherever it fits.
- You alone assign `P` numbers: the next one not used in the doc or the plan.
- Never read the whole Proposals doc back: read **At a glance**, or one
  proposal (`md-section.sh get <proposals> "## P4 —"`).
- When the engineer decides, record the Decision in the proposal straight away
  (a targeted Edit).
- Every Ledger entry decided through a proposal (`R`, `S`, `C`, `A`, `CD`,
  `NB`), and every Rejected Alternatives row, cites the `P` that decided it.

## Termination gate

The loop ends **only** when the engineer explicitly confirms they are happy with
the full Consensus Ledger.

Before ending:

- Make sure no `Blocking decision` proposal is still `Open` (check **At a
  glance**).
- Present a sign-off summary: the count of entries in each Ledger section with
  their IDs, every entry added or changed since you last showed it (in full),
  the proposals with their statuses, and the draft plan's path, where the whole
  Ledger can be read. Offer to show any section in full, one per turn.
- Ask for explicit sign-off of the **whole** draft.

Silence, "looks fine", "sure", or your own sense that it looks complete are
**not** sufficient — require an affirmative confirmation that they are happy
with the whole thing. If any hesitation or new information surfaces, treat it
as another answer and keep looping.

## Output & handoff

On explicit confirmation, follow `<skill>/handoff.md`: write the full
implementation steps one per response, audit the plan and proposals with
subagents, mark the plan signed off at `Revision 1`, and have subagents write
the Tech Plan and Future Iterations in parallel.

## Resuming

`/tims-adversarial-plan resume <draft plan>`, or "continue" after a stall:

1. Read the draft plan: its Status line (`Phase`, `Next`) and its Ledger
   sections.
2. Read the Tech Proposals' **At a glance**, and the first lines of each file
   in `<draft>/research/`.
3. If the session was signed off and in hand-off, follow the **Resume** section
   of `handoff.md`.
4. Otherwise tell the engineer where things stand in a few lines, and carry on
   with the `Next` probe.

A long session's context grows with every turn. Once it is very large, suggest
continuing in a fresh session with `resume`: everything that matters is on
disk.

## Behavioural guardrails

- One probe at a time; avoid interrogation fatigue from overly long batches.
- Ground approach tradeoffs and repo facts in the actual repo at `BASE_SHA`,
  not generic advice or memory.
- Never fabricate consensus or fill gaps with assumptions — unknowns become
  questions. Subagent findings are evidence, never agreement.
- Keep the Ledger current on disk; show changes in chat, not the whole Ledger.
- Write proposals as decisions arise, not after the fact.
- Follow the output budget: one proposal, one plan step, one section per
  response.
- You are the one holding the loop open. Do not close it early.
- Never write production code. Never stage, commit or push.
