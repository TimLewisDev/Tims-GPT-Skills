# Template: breakdown skeleton

The skeleton is the breakdown before any card is written: what the engineer
reviews and approves. It lives at `<draft>/skeleton.md` and is written one plan
step per response. Card writers work from it, so it must hold every decision
about slicing: nothing about task boundaries, files or check placement is left
for them to decide.

```markdown
# Skeleton: <Feature>

- Plan: <path> · revision <N> · BASE_SHA <sha>
- Approved: no            <!-- set to the date when the engineer approves -->

## Tasks

### From §1. <step title> (plan lines <a>–<b>)
| Task | Title | Executor | Files | Depends on | Traces to | Confirm | Why split this way |
|---|---|---|---|---|---|---|---|
| T01 | <imperative title> | Agent | new `<path>`; change `<path>` | T00 | R1, C2, §1 | <what to confirm, or —> | <one line> |

### From §2. …

## Units
| Unit | After this unit you can… | Tasks | Validated by | Depends on | May run in parallel |
|---|---|---|---|---|---|
| WU0 | <outcome> | T00 | Agent + Engineer | — | — |
| WU1 | <outcome> | T01–T03 | Agent | WU0 | T02 ∥ T03 |

## Done-when map
| Item | First words | Unit | Why here (if not the step's own unit) |
|---|---|---|---|
| §1 #1 | <first ~8 words, verbatim> | WU1 | |
| §2 #3 | <…> | WU3 | only observable once the scene exists (T09) |

## Unit checks
- WU1: <unit's own check, e.g. "the navigation assembly compiles"> (Agent)
- WU1: <…> (Engineer)
```

Rules:

- One plan step's rows per response. The units, the Done-when map and the unit
  checks take one response each.
- "May run in parallel" lists only Agent tasks that the plan allows in parallel,
  whose Files lists don't overlap, and that don't depend on each other.
- Every "Done when" item of every step appears exactly once in the map.

## `manifest.txt`

Written from the skeleton once the units are fixed; card writers fill the
parts it names. One relative path per line, in document order:

```
parts/00-header.md
parts/10-work-units.md
parts/20-task-map.md
parts/30-WU0.md
parts/31-WU0-T00.md
parts/30-WU1.md
parts/31-WU1-T01.md
parts/31-WU1-T02.md
parts/80-coverage.md
parts/90-verification.md
```
