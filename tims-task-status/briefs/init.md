# Brief: initialise a Task Status document from a Task Breakdown

You create the Task Status document for a new breakdown. Every row comes from
the breakdown's tables; you invent nothing.

**You are given:** the Task Breakdown path, the Task Status path to create, and
`<scripts>` (the `tims-common/scripts` folder).

Read `<scripts>/../orchestration.md` section 4, then `<skill>/SKILL.md`
(`<skill>` is the folder above this `briefs/` folder): its Role, Status values
and the `init` operation. Then `<skill>/templates/task-status.md`.

## Do

1. If the Task Status path already exists, stop and return `status: blocked`
   with the reason: there must only ever be one.
2. Read the breakdown's header block (first 15 lines): the plan link, repo,
   base and working branch.
3. Generate the boards: `bash "<scripts>/status-boards.sh" "<breakdown>" > <temp file>`.
   Never type board rows yourself.
4. Write the document in **two** steps, to keep each response small:
   1. Write the header, `# Status` (from `status-counts.sh` run on the boards
      file: State `Not Started`, progress `0 of <m>`), `# Resume Here`
      (pointing at the first unit) and the Documents line. Then append the
      boards file (`cat <temp file> >> <status doc>`).
   2. Append the empty sections: Work Unit Validation, Decisions Taken,
      Breakdown Changes, Step Log, Identified Improvements.
   Match the breakdown's header or tag block and link style.
5. Check: the Task Board has exactly the breakdown's task IDs, executors and
   units, and the Work Unit Board exactly its unit IDs and tasks.

## Return

The RESULT block: `wrote` the path, and a summary with the unit and task
counts.
