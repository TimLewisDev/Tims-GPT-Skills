---
name: tims-adversarial-plan
description: >
  Run an adversarial planning session that pressure-tests a feature and produces
  its Comprehensive Tech Plan, the single authority that tims-task-breakdown
  works from. It interrogates the engineer with hypothetical questions to lock
  down requirements, weighs candidate approaches against the actual repository,
  boils down scope (what the feature is and is not), resolves every critical
  technical decision, reconciles contradictions, and only stops on the
  engineer's explicit confirmation. Options are written live to a Tech Proposals
  doc (via tims-tech-proposals) for human review; on sign-off it writes the
  Comprehensive Tech Plan and Future Iterations, then has tims-tech-plan write a
  brief Tech Plan for review. Use when the user wants to align on a feature, or
  hands over a spec, ticket or brief and asks for a tech plan / tech design /
  implementation plan before any code is written.
metadata:
  version: "2.0"
---

# tims-adversarial-plan

## Usage

```
/tims-adversarial-plan <optional feature description, spec or ticket>
```

Seed input is optional. If none is provided, the first questions establish the
feature at a high level before probing deeper. If intake documents (a spec,
design doc, brief) are provided, read every one in full before the first probe.
If an issue or ticket is referenced, or inferable from the branch, note its key
for the plan's header.

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
| **Tech Proposals** | `tims-tech-proposals`, called live by this skill | human reviewers | Every decision point's options, laid out for review, with the outcome. |
| **Future Iterations** | this skill | engineer | Adjacent work that came up and was deliberately left out. |
| **Tech Plan** | `tims-tech-plan`, called by this skill at hand-off | human reviewers | A brief summary that mirrors the comprehensive plan and adds nothing. |

**Location and naming.** All four documents share one folder, chosen with the
engineer (an Obsidian vault, or a folder in the repo), and one prefix, usually
the feature name:

- `<Prefix> - Comprehensive Tech Plan.md`
- `<Prefix> - Tech Plan.md`
- `<Prefix> - Tech Proposals.md`
- `<Prefix> - Future Iterations.md`

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
   to go into the Consensus Ledger.

This skill does **not** write production code. It owns every decision and
every fact in the plan; `tims-tech-proposals` and `tims-tech-plan` only
present what this skill established.

## Planning philosophy

Optimise for:
- clarity
- engineer readability
- execution readiness
- minimal ambiguity
- repository alignment
- minimal implementation churn

Do **not** optimise for:
- speculative architecture
- future-proofing unless explicitly requested
- generic engineering advice
- excessive prose
- unnecessary abstraction
- idealised redesigns

The plan must:
- remain tightly scoped to what the engineer agreed;
- align with existing repository architecture and conventions;
- prefer the smallest coherent implementation approach;
- minimise unnecessary system churn;
- avoid speculative abstractions or extensibility work;
- avoid introducing new frameworks, dependencies, infrastructure, or
  architectural patterns unless explicitly required.

**The existing codebase is the primary architectural constraint and source of
truth.** When the intake or the engineer's wishes conflict with an established
pattern, the pattern wins until the engineer decides otherwise through a
Critical Decision.

## The Consensus Ledger

Maintain a running **Consensus Ledger** throughout the session. Re-display it
(or the changed sections) as it evolves so the engineer can always see the
emerging agreement. It has five sections:

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

Only agreed answers are recorded. The Ledger becomes the first half of the
Comprehensive Tech Plan.

## Procedure — the interrogation loop

Ask **one focused probe at a time**. Keep momentum; do not batch long
questionnaires. The phases are a default order, not a rigid pipeline — a later
answer can send you back to an earlier phase (see **Contradiction handling**).

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

**First, confirm where the documents go** (folder and prefix, per **Location
and naming**). The Tech Proposals doc is written from this phase on, so the
location can't wait until the end.

Then present **at least two** candidate approaches. Ground every tradeoff in
the **actual repository and its conventions**: search the codebase, cite
precedents as `path:line`, align to the repo's existing patterns, and avoid
idealised redesigns or generic engineering advice. Adversarially probe the
tradeoffs the engineer seems to favour.

For the approach choice:

1. Write it as a proposal (`P1`, status `Open`, type `Approach`) in the Tech
   Proposals doc, through `tims-tech-proposals` (see **Proposals**).
2. Ask with **`AskUserQuestion`**: the approaches as options in the same order
   as the proposal, recommended first and labelled as recommended. Tell the
   engineer the proposal's path so they can read the full breakdown there.
3. Record the answer: the proposal's Decision, and the chosen approach plus
   rejected alternatives (with rationale and the `P` link) under **Approach**.

An approach usually breaks into several sub-choices (for example, where the
data is stored and how it's displayed). Give each real choice its own
proposal.

### Phase 3 — Scope & constraints

Force the boundary into the open:

- "Is <capability> in scope, or explicitly out?"
- "What is the smallest version of this that is still worth shipping?"
- "What must this **not** do or break?"

Drive explicit **is / is-not** statements and non-goals, and surface hard
constraints. Record under **Scope & Non-Goals** and **Constraints**.

### Phase 4 — Technical design

Ground the agreed approach in the codebase before anything is written:

- **Base branch.** Establish the branch the work starts from (a Constraint, if
  it isn't one already). After a `git fetch`, check facts **on that branch**
  (`git show origin/<base>:<path>`, `git grep <symbol> origin/<base> -- <path>`),
  not in the working tree.
- **Repository alignment pass.** Identify the systems, components, contracts,
  schemas and services the feature touches. Locate the patterns those areas
  already use (search the repo; do not rely on memory or training data). Note
  where the approach aligns with existing architecture and where it conflicts.
  Record each verified fact with its `path:line` for the plan's **Repo Facts
  Verified**.
- **Critical Decisions.** Hunt for them systematically (see **Critical
  Decisions**) and resolve each one through a proposal before writing anything.
- **Implementation outline.** Sketch the steps in dependency order, the files
  each one creates or changes, and how each is known to be done. Anything this
  surfaces that isn't settled is a question or a Critical Decision, never an
  assumption.

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
so the engineer can read the options in a clear layout before choosing. That
includes choices in Phases 1 and 3 (type `Requirement or scope`, e.g. manual
versus automatic refresh), not only the approach and Critical Decisions. A
plain agreed statement with no alternatives goes straight into the Ledger with
no proposal.

- Invoke the **`tims-tech-proposals`** skill (Skill tool) for the first
  proposal. For later proposals, follow its already-loaded rules; re-invoke it
  if they've dropped out of context.
- You supply the content: the question, the options and every fact about them,
  grounded in the repo. `tims-tech-proposals` only lays it out.
- When the engineer decides, record the Decision in the proposal straight away.
- Every Ledger entry decided through a proposal (`R`, `S`, `C`, `A`, `CD`,
  `NB`), and every Rejected Alternatives row, cites the `P` that decided it.

## Termination gate

The loop ends **only** when the engineer explicitly confirms they are happy with
the full Consensus Ledger.

Before ending:

- Make sure no `Blocking decision` proposal is still `Open`.
- Present the **complete** Ledger, plus the list of proposals with their
  statuses, for final review, and ask for explicit sign-off.

Silence, "looks fine", "sure", or your own sense that it looks complete are
**not** sufficient — require an affirmative confirmation that they are happy
with the whole thing. If any hesitation or new information surfaces, treat it
as another answer and keep looping.

## Output & handoff

On explicit confirmation:

1. **Write the Comprehensive Tech Plan** (template below) at `Revision 1`, at
   the location confirmed in Phase 2. If drafting surfaces a decision that
   isn't settled, it goes through a proposal and the engineer before the plan
   is written; never resolve it silently.
2. **Write Future Iterations** (template below), only if out-of-scope work was
   identified. Do not blend it into the plan.
3. **Check the Tech Proposals doc**: every entry decided between options has a
   proposal and cites it, every status is current, and the At-a-glance table
   matches.
4. **Invoke the `tims-tech-plan` skill** with the comprehensive plan's path. It
   writes the brief Tech Plan for human review.
5. **Hand off.** Give the engineer the four paths and the next steps:
   - review the Tech Plan and the Tech Proposals;
   - amend anything with `/tims-tech-plan-review <tech plan> <comprehensive tech plan>`;
   - then `/tims-task-breakdown <comprehensive tech plan>`.

### Plan content rules

The Implementation Plan should:

- be concise and skimmable;
- contain coherent, engineer-executable steps (call them **steps**, never "work
  units", which belong to `tims-task-breakdown`);
- avoid excessive micro-steps, and avoid vague high-level statements;
- clearly identify affected systems/components, and impacted contracts,
  schemas, services or infrastructure where relevant;
- preserve sequencing where sequencing matters, and say which steps can run in
  parallel;
- put every detail the implementer needs in the step: signatures, constants,
  exact strings, snippets, gotchas, precedent `path:line`;
- keep planning IDs out of snippets' code comments (no `// R14`, `(CD1)`, `L0`):
  snippets are copied into cards and then into committed code. Cite the IDs in
  the prose around the snippet instead;
- give every step a **Done when** list of observable checks.

Do **not** include the following unless the engineer explicitly asked for them:

- test plans
- QA procedures
- rollout plans
- monitoring plans
- generic documentation tasks
- project-management process
- speculative future work
- unrelated refactors
- architectural redesign proposals

## Templates

### Comprehensive Tech Plan

```markdown
<header or tag block matching sibling docs>

# <Feature>: Comprehensive Tech Plan

- **Status:** Signed off <YYYY-MM-DD> · **Revision:** 1 (see Change Log)
- **Tech Plan (summary for review):** <link> · **Tech Proposals:** <link> · **Future Iterations:** <link>
- **Ticket:** <issue key; omit this line if there isn't one>
- **Base branch:** `<base>` · **Verified against:** `<base>` @ `<short sha>` on <YYYY-MM-DD>
- **ID key:** `R` Requirements · `A` Chosen Approach · `S` Scope / Non-Goals · `C` Constraints · `CD` Resolved Critical Decisions · `NB` Non-Blocking Review Items · `P` Tech Proposals · `§N` Implementation Plan step N

**Context.** <What is being built, for whom, and why now. Links to parent docs.
What earlier material is, and is not, a source of truth.>

---

## Requirements
### <short group heading>
- **R1:** <agreed statement>

## Chosen Approach
- **A1:** <agreed statement> (P1)

**Implied consequences, agreed:** <if any>

## Rejected Alternatives
| Alternative | Why rejected | Proposal |
|---|---|---|

## Scope / Non-Goals
**In scope:** <IDs, with a one-line summary>

**Not in scope:**
- **S1:** <statement>
  - Why: <reason>

## Constraints
### <short group heading>
- **C1:** <statement>

## Repo Facts Verified
Checked on `<base>` @ `<short sha>` on <YYYY-MM-DD>. Paths are relative to the repo root.
- <fact>: `<path>:<lines>`

## Resolved Critical Decisions
| # | Decision | Outcome | Proposal |
|---|---|---|---|

## Non-Blocking Review Items
| # | Item | Applied in plan | Alternative | Proposal |
|---|---|---|---|---|

## Architectural Pressure Points
| Area | Pressure | Handling |
|---|---|---|

## Implementation Plan
**Prerequisites:** <ticket, branch, setup, or "none">

<Step order, and which steps can run in parallel.>

### §1. <title>
**Files:**
- new `<path>`: <purpose>
- change `<path>`: <what changes>

**Work:** <signatures, constants, snippets, precedent `path:line`>

**Done when:**
- <observable check> (<IDs it proves>)

## Affected Files
| File | Status | Assembly / area |
|---|---|---|
| `<path>` | new · changed · **unchanged** | |

## Open Items (don't block)
- <item, or "None">

## Change Log
| Rev | Date | Change | IDs | Source |
|---|---|---|---|---|
| 1 | <YYYY-MM-DD> | Signed off | — | tims-adversarial-plan |
```

### Future Iterations

```markdown
<header or tag block matching sibling docs>

# <Feature>: Future Iterations

Work that came up during planning and was deliberately left out. It goes with
<Comprehensive Tech Plan link>.

## <n>. <title>
- **Description:**
- **Rationale:**
- **Expected benefits:**
- **Risks/tradeoffs:**
- **Estimated impact:**
- **Why excluded:** <the S, NB or P IDs that excluded it>
```

## Behavioural guardrails

- One probe at a time; avoid interrogation fatigue from overly long batches.
- Ground approach tradeoffs and repo facts in the actual repo on the base
  branch, not generic advice or memory.
- Never fabricate consensus or fill gaps with assumptions — unknowns become
  questions.
- Keep the Ledger visible and current so the engineer always sees the emerging
  agreement.
- Write proposals as decisions arise, not after the fact.
- You are the one holding the loop open. Do not close it early.
- Never write production code. Never stage, commit or push.
