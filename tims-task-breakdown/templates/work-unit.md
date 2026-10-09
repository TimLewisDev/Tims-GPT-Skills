# Template: work unit block

One per unit, in `parts/30-<WU>.md`, followed by its cards.

```markdown
## <WU ID> — <outcome-style name>

**In plain English:** <2–4 sentences: what someone can do or see once this unit is validated>

| | |
|---|---|
| **Tasks** | <IDs> |
| **Depends on** | <unit IDs, or —> |
| **Validated by** | Agent · Agent + Engineer |

**Why these tasks are validated together:** <one or two sentences: what can only be observed once all of them are done>

**Validation**
- [ ] <unit check, e.g. "the settings module compiles"> (Agent | Engineer | Agent + Engineer)
- [ ] <plan "Done when" item, verbatim> (plan §N) (Agent | Engineer | Agent + Engineer)
- [ ] <plan "Done when" item moved here from §M, verbatim> (plan §M; observable from this unit) (Agent | Engineer | Agent + Engineer)

**How to validate**
- Agent: <exact commands or inspections, in order>
- Engineer (read out inline at validation time):
  1. <what to open and do> → expect <what they should see>
  2. …
```

- Every plan "Done when" item placed on this unit by the skeleton's Done-when
  map appears here **verbatim**, tagged with its plan step. Never drop one.
- Write each check so its executor can run it exactly: commands for the agent;
  for the engineer, numbered steps, each with its expected result. The
  engineer's part is read out inline at validation, so write instructions, not
  notes.
