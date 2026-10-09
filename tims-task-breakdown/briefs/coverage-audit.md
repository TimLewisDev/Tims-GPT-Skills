# Brief: audit a Task Breakdown's coverage of its plan

You check, with fresh eyes, that the written parts of a Task Breakdown cover
its Comprehensive Tech Plan exactly: nothing missing, nothing extra. You write
the Coverage section and report defects. You fix nothing else.

**You are given:** `<common>/scripts`, `<draft>`, the plan path.

Read `<common>/orchestration.md` section 4 first. Then `<draft>/context.md`,
`<draft>/skeleton.md` and `<draft>/manifest.txt`. Read parts with `grep` and
`md-section.sh` rather than in full where you can.

## Checks

1. **Steps → tasks.** Every plan step `§N` has at least one card whose **Plan
   step** is that step.
2. **Tasks → units.** Every task belongs to exactly one unit; every card listed
   in the skeleton has a part, and no part exists that the skeleton doesn't
   list.
3. **Done when, exactly once.** For every "Done when" item of every plan step
   (read each step's list), the item's text appears verbatim in exactly one
   unit block: `grep -cF "<item text>" <draft>/parts/30-*.md` (use a
   distinctive substring if the item is long or has markdown). Zero or more
   than one is a defect.
4. **IDs.** Every ID the plan's steps cite appears on at least one card:
   `ids.sh cited` on the step text, against `ids.sh cited` on the card parts.
5. **Files.** Every row of the plan's Affected Files table is in some card's
   Files list; every file in a card's Files list is in the Affected Files
   table; the task that creates each new file is identified.
6. **Non-Goals.** No card's Goal or Steps does what the plan's Scope /
   Non-Goals section rules out.
7. **Plain English.** Every unit block and card has an **In plain English**
   paragraph of 2–4 sentences with no file paths, class names or code.
8. **Planning IDs in code.**
   `check-planning-ids.sh --md <draft>/parts/3*.md`: any hit is a defect.

## Write

`<draft>/parts/80-coverage.md` in one Write, in the Coverage format from
`<skill>/templates/task-breakdown.md` (`<skill>` is the folder above
`briefs/`), ending with `<!-- tims:end -->`.

## Return

The RESULT block. `findings`: one TSV row per defect: `check`, `where` (part
or plan line), `what`, `suggested fix`. `findings: none` if clean.
