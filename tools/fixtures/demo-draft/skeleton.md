# Skeleton: Demo

- Plan: PLAN · revision 2 · BASE_SHA abc1234
- Approved: 2026-10-09

## Tasks

### From §1. Settings store (plan lines 16–26)
| Task | Title | Executor | Files | Depends on | Traces to | Confirm | Why split this way |
|---|---|---|---|---|---|---|---|
| T01 | Add the settings store | Agent | new `src/store.sh` | — | R1, §1 | — | the store compiles alone |
| T02 | Add the settings loader | Agent | new `src/loader.sh` | T01 | R2, §1 | Where the loader logs | consumer of the store |

### From §2. Greeting (plan lines 28–33)
| Task | Title | Executor | Files | Depends on | Traces to | Confirm | Why split this way |
|---|---|---|---|---|---|---|---|
| T03 | Add the greeting | Agent | new `src/greet.sh` | T02 | R3, §2 | — | one file |
| T04 | Check the greeting in the tool | Engineer | — | T03 | R3 | — | needs the tool |

## Units
| Unit | After this unit you can… | Tasks | Validated by | Depends on | May run in parallel |
|---|---|---|---|---|---|
| WU1 | Save settings | T01–T02 | Agent | — | — |
| WU2 | See a greeting | T03, T04 | Agent + Engineer | WU1 | — |

## Done-when map
| Item | First words | Unit | Checked by | Why here (if not the step's own unit) |
|---|---|---|---|---|
| §1 #1 | It compiles. | WU1 | Agent | |
| §1 #2 | After a restart: the settings are still there. | WU1 | Engineer | |
| §1 #3 | After a restart: the loader ran once. | WU1 | Agent | |
| §2 #1 | The greeting is printed. | WU2 | Agent + Engineer | |

## Unit checks
- WU1: No debug prints remain (Agent)
- WU2: The greeting looks right in the tool (Engineer)
