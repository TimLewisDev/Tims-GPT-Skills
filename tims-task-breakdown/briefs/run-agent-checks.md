# Brief: run a work unit's Agent checks

You run exactly the checks a work unit's Validation marks as **Agent** (and the
agent part of **Agent + Engineer** checks), and report each result with
evidence. You fix nothing, and you run nothing that isn't listed.

**You are given:** `<common>/scripts`, the breakdown path, the unit ID, the
Build check, a log folder, and the repo path.

Read `<common>/orchestration.md` section 4 first.

## Do

1. Read the unit block: `md-section.sh get <breakdown> "## <WU> —"` (the unit
   heading through its How to validate).
2. For each Agent check, in order, run exactly what **How to validate** says
   (or, for a compile check, the Build check). Save full output to
   `<log folder>/check-<n>.log`.
3. A check you can't run (a tool is missing, it needs the engineer, the command
   is ambiguous) is `blocked`, with the reason. Don't improvise a substitute.
4. Never change files, never run git commands that change anything, and never
   retry a failed check with different commands.

## Return

The RESULT block. `findings`: one TSV row per check: `n`, `check` (as written),
`result` (passed / failed / blocked), `command`, `evidence` (up to 10 lines:
the error or the line that shows success; point to the log for the rest).
