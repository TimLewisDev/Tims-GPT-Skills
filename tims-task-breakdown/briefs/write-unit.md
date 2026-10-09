# Brief: write one work unit's block and task cards

You write the parts of a Task Breakdown for one work unit, from a skeleton the
engineer has already approved. You do not slice, regroup or redesign anything:
every decision about tasks, files, dependencies and check placement is in the
skeleton. Your job is to put every detail the implementer needs on each card,
taken from the plan and the verified code.

**You are given:** `<skill>` (the tims-task-breakdown folder),
`<common>/scripts`, `<draft>`, the unit ID, the plan path, and the line ranges
of the plan steps the unit's tasks come from.

Read first, in this order:

1. `<common>/orchestration.md`, section 4 (applies to you).
2. `<skill>/SKILL.md`, sections "Tasks and work units", "Executors" and "The
   plain-English summary".
3. `<skill>/templates/work-unit.md` and `<skill>/templates/task-card.md`.
4. `<draft>/context.md` and `<draft>/skeleton.md` (your unit's rows, its
   Done-when items, its unit checks).
5. The plan steps (by line range), and `<draft>/verify/§N.md` for each.

## Do

Write one part per Write call, each ending with the line `<!-- tims:end -->`:

1. `<draft>/parts/30-<WU>.md`: the unit block. Its **Validation** lists the
   unit checks from the skeleton and every "Done when" item the Done-when map
   places on this unit, **copied verbatim** from the plan with its step tag.
   **How to validate** gives exact commands for the agent (using the Build
   check in `context.md`) and numbered steps with expected results for the
   engineer.
2. `<draft>/parts/31-<WU>-<task>.md` for each task, in ID order: the card.
   - Files, dependencies, traces and Confirm items exactly as the skeleton has
     them.
   - Steps carry the plan's signatures, constants, exact strings and snippets.
   - References use the corrected line from the verification notes where one
     moved.
   - **Plan IDs** in "Read first" carry their one-line excerpt from
     `<draft>/glossary.tsv`.
   - Snippets lose planning IDs in their code comments (reword or drop).
   - Write the **In plain English** paragraphs last, once the technical content
     is fixed.
3. Check your parts:
   `bash "<common>/scripts/check-planning-ids.sh" --md <your parts>`. Fix every
   hit inside a snippet; IDs in card text outside code blocks are expected.

## Escalate, don't decide

Return an escalation (and leave that card's Steps with a `**Confirm:**` or stop
the card) when:

- the skeleton and the plan disagree about a task's files or content;
- the plan doesn't give what a step needs, and the verified code doesn't settle
  it;
- a "Done when" item can't be checked by anything in this unit;
- a snippet can't be copied without changing what it does.

Type `question` for a gap the engineer can answer, `blocking` for anything that
would need a design choice.

## Return

The RESULT block: every part you wrote, a summary (tasks written, checks
placed), escalations, and `findings: none` or the planning-ID hits you couldn't
resolve.
