---
name: tims-tech-plan
description: >
  Render a brief, human-readable Tech Plan from a Comprehensive Tech Plan, so a
  person can review the plan in a few minutes. This is a presentation skill,
  not a planning skill: it mirrors the comprehensive plan in a stripped-down
  form, cites the IDs behind every line, and never adds, infers or
  reinterprets content. Normally called by tims-adversarial-plan at hand-off
  and by tims-tech-plan-review after an amendment; can also be run directly to
  regenerate a Tech Plan. To plan a feature from a spec or ticket, use
  tims-adversarial-plan instead.
metadata:
  version: "2.0"
---

# tims-tech-plan

## Usage

```
/tims-tech-plan <comprehensive tech plan>
```

- The argument is a **Comprehensive Tech Plan** (normally written by
  `tims-adversarial-plan`). If none is given, ask for it and stop.
- If it's handed a spec, ticket, brief or anything that isn't a comprehensive
  plan, stop and point the engineer to `tims-adversarial-plan`. This skill
  doesn't plan.
- The Tech Plan goes beside the comprehensive plan, with the matching name:
  `<Prefix> - Comprehensive Tech Plan.md` → `<Prefix> - Tech Plan.md`;
  `STAR-XXXXX.techplan-full.md` → `STAR-XXXXX.techplan.md`. If the
  comprehensive plan's header already links a Tech Plan, use that path.

## Modes

- **Write**: no Tech Plan exists yet. Write it in full.
- **Regenerate**: a Tech Plan exists. Rewrite it in full from the current
  comprehensive plan. Use when the engineer asks, or when the Tech Plan is
  badly out of sync.
- **Update**: called by `tims-tech-plan-review` with the IDs an amendment
  changed, or by `tims-tech-proposals` with `P` IDs it added or whose status
  changed. Change only the lines that cite those IDs (and add or remove lines
  for added or removed IDs). Leave everything else as it is, so the diff shows
  only the amendment. If the step 4 check then finds a gap that was already
  there (an ID missing from the Tech Plan), fix it too and tell the engineer.

In every mode, set `Mirrors revision` to the comprehensive plan's current
`Revision` and the sync date to today.

## Role

You are a **renderer**. The comprehensive plan is the authority; the Tech Plan
is a view of it for human review.

- **Never add, infer or reinterpret content.** Every statement must be
  traceable to the comprehensive plan. The only thing taken from the Tech
  Proposals doc is proposal IDs and statuses. If something seems missing or
  wrong in the plan, say so to the engineer; don't patch it in the Tech Plan.
- **Every bullet and table row cites the IDs it summarises** (`R3–R6`, `S2`,
  `A1`, `§4`, `P2`, or a named section such as "Pressure Points: Stale
  correctness"). The one-paragraph summary cites its IDs once at the end. This
  is how `tims-tech-plan-review` maps an amendment made against either doc.
- **Brief.** Aim for a five-minute read: about 60–120 lines. If it runs longer,
  group more. Group related requirements into one line rather than listing each.
- **Simple.** Plain English and short sentences. Use technical names only where
  a reviewer needs them to judge the plan.
- **No code blocks**, and no file-level detail outside **Footprint**.
- **Don't repeat options.** Decisions get one line; the options live in the
  Tech Proposals doc, so link the `P` instead.
- Never write production code. Never stage, commit or push.

## Procedure

1. Read the comprehensive plan in full, and note its `Revision`.
2. Read the Tech Proposals doc it links, for proposal IDs and statuses only.
   - A decision's `P` link comes from the plan entry. If the plan doesn't link
     one, use the proposal whose **Decides** names that entry. If neither
     exists, write `—`. Use the link format in `tims-tech-proposals`
     (**Linking a proposal**).
   - A decided `Requirement or scope` proposal gets no line of its own: the
     Scope lines citing its `R`, `S` or `C` IDs cover it.
   - **Open for review** lists every proposal that is `Open` or `Default
     applied`.
   - If there is no Tech Proposals doc, the Options column is `—` throughout,
     and **Open for review** lists the plan's `NB` items (each is applied by
     default and open for review) and its Open Items. Say nothing about the
     missing doc beyond that.
3. Write the Tech Plan per the template. Match the comprehensive plan's header
   or tag block and link style.
4. Check before saving:
   - every cited ID exists in the comprehensive plan, and every cited `P`
     exists in the Tech Proposals doc;
   - every `R`, `S` and `§` step is covered by at least one line, every `A` and
     `CD` appears under **Key decisions**, and every `NB` appears exactly once:
     under **Open for review** while it's open, otherwise under **Key
     decisions**;
   - nothing is stated that the comprehensive plan doesn't say;
   - it's within the length target.
5. Report the path and the revision it mirrors.

## Template

```markdown
<header or tag block matching the comprehensive plan>

# <Feature>: Tech Plan

> A short summary of the <Comprehensive Tech Plan link> for review. The
> comprehensive plan is the authority. To change anything, use
> `/tims-tech-plan-review`.

- **Mirrors revision:** <N> of the comprehensive plan · synced <YYYY-MM-DD, the day this doc was last written or updated>
- **Tech Proposals:** <link> · **Future Iterations:** <link>
- **Ticket:** <STAR-XXXXX, or "none yet"> · **Base branch:** `<base>`

## In one paragraph
<3–5 sentences: what is being built, for whom, what it lets them do, and the
overall approach.> (<IDs>)

## Scope
**In**
- <grouped capability> (<R IDs>)

**Out**
- <non-goal> (<S IDs>)

## Key decisions
| ID | Decision | Why | Options |
|---|---|---|---|
| A1 | <one line> | <one line> | P1 |
| CD1 | <one line> | <one line> | P4 |

## How it will be built
**Before step 1:** <prerequisites, or "nothing">

| Step | What | Done when |
|---|---|---|
| §1 | <one line> | <short> |

<One line on order, and which steps can run in parallel.>

## Footprint
- **New:** <one line> (Affected Files)
- **Changed:** <one line, or "no existing file"> (Affected Files)
- **Ships to players:** <yes / no, and why> (<C IDs>)

## Risks to watch
- <one line> (Pressure Points: <area>)

## Open for review
| Proposal | Question | Status | Applied for now |
|---|---|---|---|
| P6 | <question> | Default applied | <option> |

<Or "Nothing open.">
```

Keep **Risks to watch** to 3–5 lines, picking the pressure points a reviewer
most needs to know about. **Open for review** follows step 2 of the Procedure.
