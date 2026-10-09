# Template: implementation handoff

The prompt for one implementation subagent (default model, general-purpose,
foreground). Fill in the `<…>` and send it as is. Don't paste the card: the
subagent extracts it.

```
Implement exactly one task: <ID> — <title>. Do not start any other task.

Invoke the tims-implementation-agent skill and follow it in DELEGATED MODE.
Read <common>/orchestration.md first (section 4 applies to you).

Your card: run
  bash "<common>/scripts/md-section.sh" get "<breakdown path>" "### <ID> —"
and treat its output as the task card, verbatim. Read the files under its
"Read first", and the plan sections it links, from <plan path>.

This task belongs to work unit <WU ID> — <name>. It is validated with that
unit, not on its own:
- Do not run compile checks, tests or other validation for this task, and do
  not report it as verified. The unit's validation covers it.
- Do not stage, commit, fetch, branch or run any git command that changes
  anything. The engineer handles all git operations.
- Do not write task, unit, plan or decision IDs (or "L0"-style level names) in
  code, comments, test names or messages. Strip them from any snippet you copy
  from the card, and run
    bash "<common>/scripts/check-planning-ids.sh" <your changed files>
  before you finish.
- Do not write to the Task Status (<status path>). Return everything for it in
  your RESULT; the orchestrator records it.

Repo: <repo path> · base <base> @ <BASE_SHA> · Build check: <method, for reference only>

Escalate any conflict between the card, the plan and the codebase, and every
Critical Decision, in your RESULT, and stop; never resolve one yourself. Stop
once this task's Steps are done.

End with the RESULT block from orchestration.md, plus these fields:
  task_status: implemented | blocked | interrupted
  files_modified: <one path per line>
  summary: <a few lines>
  to_validate: <what to check, how (commands or exact engineer steps), the expected result, edge cases>
  follow_up: <anything the next task or the engineer should know, or none>
  risks: <none, or one per line>
  improvements: <none, or per item: description | benefits | risks | why high impact>
  critical_decision: <none, or the Critical Decision block from tims-implementation-agent>
```
