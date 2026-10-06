---
name: tims-tech-plan-review
description: >
  Review and amend a tech plan after it has been written. Takes the brief Tech
  Plan and the Comprehensive Tech Plan, accepts amendments given in chat
  (referring to either document or to an ID), and propagates each one so both
  plans, and the Tech Proposals and Future Iterations docs where affected, stay
  in sync. Applies changes to the comprehensive plan first as the authority,
  adds an amendment note to every signed-off item it changes, bumps the
  revision and logs it, then updates the Tech Plan through tims-tech-plan's
  rules. Escalates any critical decision through a proposal. Never edits a
  Task Breakdown and never commits. Use when the engineer wants to change,
  correct or re-decide anything in an existing tech plan.
metadata:
  version: "1.0"
---

# tims-tech-plan-review

## Usage

```
/tims-tech-plan-review <tech plan> <comprehensive tech plan>
```

- The two paths can come in either order. One is enough if its header links
  the other.
- The Tech Proposals and Future Iterations docs are found from the header links
  (or by name: same folder and prefix).
- If the comprehensive plan can't be found, ask for it and stop.
- An older plan (written before 2026-10-05) is a *Tech Plan + Feature
  Consensus* pair: a Tech Plan with no `Revision` or Change Log, next to a
  `Feature Consensus` doc, and no Comprehensive Tech Plan. Recognise it by that
  structure, not by date. Tell the engineer this skill needs the newer format,
  and stop.

## Role

You are the **only route** by which a written plan changes. Your job is to
apply exactly what the engineer asks, everywhere it applies, and nothing else.

- **The comprehensive plan is the authority.** Every change of meaning lands
  there first; the Tech Plan and the Proposals follow it.
- **Never fabricate.** Apply only what the engineer asked for and confirmed.
  Anything the amendment leaves open becomes a question.
- **Never rewrite a signed-off item silently.** Every substantive change leaves
  an amendment note and a Change Log row.
- Never edit a Task Breakdown or Task Status doc. Those belong to
  `tims-task-breakdown` and `tims-task-status`.
- Never write production code. Never stage, commit or push.

## Procedure

### 1. Load and check sync

- Read the comprehensive plan in full, then the Tech Plan, then the Tech
  Proposals and Future Iterations docs.
- Compare the Tech Plan's `Mirrors revision` with the comprehensive plan's
  `Revision`. If they differ, report it, and offer to re-sync first by
  regenerating the Tech Plan through `tims-tech-plan`. Don't amend an
  out-of-sync pair without the engineer's say-so.
- Note the plan's base branch. When an amendment needs a repo fact checked,
  `git fetch` first and check it on `origin/<base>`, not in the working tree.

### 2. Check for a Task Breakdown

Look for a Task Breakdown beside the plan (`<Prefix> - Task Breakdown.md` or
`STAR-XXXXX.tasks.md`). If one exists, read it and its Task Status doc
(read-only), so you know which tasks and units cite which plan IDs and which
are already `Implemented` or `Done`. Then tell the engineer up front:

- amendments will show as plan drift when `tims-task-breakdown` next runs in
  continue mode, through the Change Log;
- a change to scope, contracts, behaviour or a step's Done when may need
  breakdown amendments there, which this skill doesn't make;
- a change that affects work already `Implemented` or `Done` will be flagged in
  the change set.

### 3. Take amendments

Amendments come as instructions in chat. They may quote either document, name
an ID (`R15`, `§6`, `NB3`, `P2`), or describe the change in plain words. Work
**one amendment at a time**. If the engineer gives several, list them back
first, then take them in order.

For each amendment:

1. **Map.** Find the comprehensive-plan IDs it affects. When the engineer quotes
   the Tech Plan, use the IDs that line cites. If the mapping is ambiguous, ask.
   If the engineer hasn't said why they want the change, ask once; the reason
   goes into the amendment note. If they'd rather not say, write "no reason
   given".
2. **Analyse impact.** Follow the chain from what changes to everything that
   depends on it: Requirements → Approach → Constraints → Critical Decisions and
   review items → Implementation steps (Work, Done when) → Affected Files →
   Non-Goals → Pressure Points → Open Items → Future Iterations → Proposals.
3. **Cross-check.** Compare the result against the whole plan. If it
   contradicts an agreed item, stop, quote both entries, and ask the engineer
   which one gives way. A plain answer ("drop the old rationale") is applied as
   part of this amendment. If settling it means choosing between real
   alternatives with tradeoffs, or it's on the Critical Decisions list, take it
   to step 5 as a proposal instead.
4. **Classify:**
   - **Editorial**: wording, typos or layout in one document, with no change
     of meaning. Apply it to that document alone, with no amendment note and no
     revision change. If you can't be sure the meaning is unchanged, treat it
     as substantive.
   - **Substantive**: changes what an item says (a requirement, scope line,
     constraint, step, Done when, file).
   - **Decision change**: changes or reopens a decision (`A`, `CD`, `NB`), or the
     amendment is itself a Critical Decision.
5. **Escalate decisions.** For a decision change, or anything on the Critical
   Decisions list below:
   - ground the options in the repo on the base branch, citing `path:line`;
   - write the proposal through `tims-tech-proposals` (supersede a `Decided`
     one; decide a `Default applied` one in place);
   - ask with `AskUserQuestion`, recommended first, pointing at the proposal;
   - continue with the chosen option.
6. **Verify facts.** Any new path, symbol or precedent the amendment introduces
   is checked on the base branch before it goes in.
7. **Show the change set** and get explicit confirmation. For each document,
   per ID, show before and after:
   - comprehensive plan (including the new Revision and Change Log row);
   - Tech Plan;
   - Tech Proposals, if a decision changed;
   - Future Iterations, if an item moves in or out of scope;
   - and, if a Task Breakdown exists, which units or tasks it touches.
8. **Apply**, in this order:
   1. **Comprehensive plan.**
      - Under each changed item, add
        `*Amended <YYYY-MM-DD> (rev <N>):* originally said "<old text>". <why>. Approved by the engineer.`
      - A removed item keeps its ID: strike its text and mark it
        `**R12 (removed <YYYY-MM-DD>, rev <N>):** ~~<old text>~~ <why>`.
      - A new item takes the next unused ID in its series. IDs are never
        renumbered or reused.
      - Increment `Revision` in the header, and add a Change Log row: rev, date,
        change, IDs, `tims-tech-plan-review`.
   2. **Tech Plan.** Update the affected lines following `tims-tech-plan`'s
      **Update** mode and rules (invoke it, or follow its loaded rules), and set
      `Mirrors revision` to the new revision.
   3. **Tech Proposals**, if a decision changed: decided or superseded per step 5,
      with **At a glance** updated.
   4. **Future Iterations**, if an item left scope (add an entry citing the
      amendment), came into scope (mark its entry `Moved into scope
      <YYYY-MM-DD>, rev <N>` rather than deleting it), or the amendment changes
      what an existing entry says (update it, with a one-line note).
9. **Re-verify.** Every ID the Tech Plan cites exists in the comprehensive plan
   and says the same thing, and `Mirrors revision` matches `Revision`.

### 4. Wrap up

When the engineer has no more amendments, report:

- the new revision, and each change with its IDs;
- the documents that changed;
- if a Task Breakdown exists: run `/tims-task-breakdown continue <task status
  doc>` next, which will flag the Change Log rows that affect the current unit.

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

When uncertainty exists, err on the side of escalation.

The engineer's amendment is the starting point. Recommend **how** to carry it
out, preferring repository consistency and minimal churn, not **whether** to.
Recommend against it only when it conflicts with the codebase or with another
agreed item, and then say exactly which one.

## Guardrails

- One amendment at a time; confirm every change set before applying it.
- The comprehensive plan first, then the views. Never the other way round.
- Never fabricate, never infer an amendment the engineer didn't ask for, and
  never apply an "obvious" follow-on change without showing it.
- Never rewrite signed-off items silently, never delete IDs, never reuse them.
- Keep the Tech Plan brief: an amendment updates its lines; it doesn't import
  the comprehensive plan's detail.
- Never edit breakdown documents, write production code, or commit.
