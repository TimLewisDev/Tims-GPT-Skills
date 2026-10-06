---
name: tims-mr-review
description: Comprehensive code review of a GitLab MR. Fetches the diff, reads changed files for context, then reviews for correctness, logic, security, performance, code style, test coverage, and Unity/C# conventions. Posts inline comments on specific lines and a summary comment. Gated: presents findings for approval before posting anything.
metadata:
  version: "0.1"
---

# el-mr-review

Perform a comprehensive, line-level code review of a GitLab Merge Request and
(with approval) post the findings as inline comments.

## Overview

This skill:
1. Resolves the target MR and gathers its diff and context
2. Reads the full changed files for deep understanding
3. Reviews across multiple dimensions: correctness, logic, security, performance, code style, Unity/C# conventions, and test coverage
4. Presents all findings to the user for approval
5. Posts approved findings as GitLab inline comments, plus an overall summary comment

> All comment posting is **gated on explicit user approval**. Nothing is posted
> without confirmation.

### Usage

```
/el-mr-review [mr]
```

**MR** (optional): the MR to review — an **MR number** (e.g. `8421`) or a
**source branch** (e.g. `features/STAR-39596_spike_merge`). If omitted,
resolves from the **current branch**. If the match is ambiguous, ask the user.

## Preconditions

1. **GitLab auth** — `glab auth status` or GitLab MCP must be available. **FAIL** if not.
2. **MR resolvable** — a single open (or recently merged) MR can be found. **FAIL** if none or ambiguous — ask the user.
3. **Repo is present** — the working tree must exist so changed files can be
   read for full context (not just the diff). If the repo is absent, skip
   full-file reads and work from the diff only; note this limitation.

## Steps

### 1. Resolve the MR

```bash
glab mr view <mr>                                                   # by number
glab mr list --source-branch "$(git rev-parse --abbrev-ref HEAD)"   # by current branch
```

Record:
- **MR number** and **project path** (URL-encoded, e.g. `scopely%2Felectrum%2Fclient%2Felectrum-client`)
- **title**, **description**, **source branch**, **target branch**
- **head SHA** (the latest commit on the MR)
- **author**

### 2. Fetch the diff

Retrieve the full diff for the MR. Prefer the GitLab API over a local git diff
so the review targets exactly what GitLab will show reviewers:

```bash
glab api "projects/<url-encoded-path>/merge_requests/<mr>/diffs?per_page=100"
# or, if working locally with the branch checked out:
git diff origin/<target>...origin/<source> -- '*.cs' '*.shader' '*.hlsl' '*.json' '*.yaml' '*.yml' '*.asmdef' '*.asmref'
```

Collect: **file path**, **old SHA**, **new SHA**, **diff hunks** (with line
numbers), and whether each file is **new**, **deleted**, or **modified**.

Exclude from review (don't open, don't comment):
- `*.meta` files (Unity-managed — only flag if a `.cs` file has a missing paired `.meta`)
- `*.fbx`, `*.png`, `*.jpg`, `*.tga`, `*.asset`, `*.prefab`, `*.unity` (binary / Unity-managed)
- `*.dll`, `*.exe`, `*.so`, `*.a` (binaries)
- Auto-generated files (`.csproj`, files explicitly marked auto-generated in their header)
- `Library/`, `Temp/`, `UserSettings/` paths

### 3. Read changed files for context

For each **text file** in the diff (respecting the exclusions above), read the
**full file** from the working tree (or via the GitLab API at the head SHA).
Reading the full file — not just the diff hunk — is essential for:
- understanding surrounding logic and call sites
- detecting issues in unchanged lines that the diff touched (e.g. a renamed
  variable leaves a bug in an unchanged conditional)
- checking interface contracts, base classes, and asmdef membership

If a file is very large (>1000 lines), read the relevant sections: the changed
hunks ± 100 lines, the class/struct declaration, and any referenced methods.

Also fetch the MR description (Step 1) and read the linked JIRA ticket if a
`STAR-XXXXX` reference is present and the Jira MCP/glab issue is available —
it clarifies the intent and helps judge whether the implementation matches.

### 4. Review — dimensions

Apply **all** dimensions below to every changed file. Be thorough: this is
meant to replace a senior engineer's manual review, not rubber-stamp the code.
For each finding, record:

| Field | Content |
|---|---|
| **file** | repo-relative path |
| **line** | line number in the **new** file (for inline posting) |
| **severity** | `critical` / `major` / `minor` / `nit` |
| **dimension** | which category (see below) |
| **summary** | one sentence — what is wrong |
| **detail** | why it matters, concrete scenario where it breaks / degrades |
| **suggestion** | specific fix, with a code snippet where helpful |

#### 4a. Correctness & Logic

- Off-by-one errors, incorrect boundary conditions
- Null/uninitialized reference dereferences (Unity objects: destroyed objects,
  unassigned serialized fields used before `Awake`/`Start`)
- Race conditions in `async`/`await`, `Coroutine`, or multi-threaded code
- Incorrect state machine transitions or missing guard conditions
- Incorrect math: wrong sign, wrong axis, wrong coordinate space (world vs. local),
  wrong units (degrees vs. radians)
- Missing `return` or fall-through in switch/if chains
- Methods that mutate data they were only expected to read
- Unity lifecycle ordering bugs (e.g. reading a value in `Awake` set in another
  component's `Start`)
- Incorrect use of `Destroy` vs `DestroyImmediate`

#### 4b. Security

- User-controlled data passed directly to shell commands, SQL, file paths, or
  network URLs without sanitisation
- Hardcoded credentials, API keys, or secrets (even in comments)
- Overly permissive file/directory access
- Unsafe deserialization of untrusted data
- Missing `[SerializeField]` + `private` discipline (unintended public exposure
  of Unity inspector fields)

#### 4c. Performance

- Allocations per frame in hot paths (`Update`, `FixedUpdate`, `LateUpdate`,
  coroutines that run every frame): `new`, LINQ, string concatenation, boxing
- `Camera.main`, `FindObjectOfType`, `GameObject.Find`, `GetComponent` in
  hot paths (cache these)
- Physics queries in `Update` without result caching
- `Resources.Load` in hot paths (should be preloaded)
- Texture/mesh reads back from GPU (stalls pipeline)
- Large `Instantiate`/`Destroy` calls that should use pooling
- O(n²) or worse loops over large collections
- Unnecessary `yield return null` in tight coroutine loops

#### 4d. Code style & maintainability

- Violations of `.editorconfig` rules visible in the diff (indentation, brace
  style, naming — use editorconfig as source of truth)
- Unexplained magic numbers or strings (should be named constants or enums)
- Dead code (unreachable branches, unused variables/parameters not prefixed `_`)
- Excessively long methods (>80 lines is a smell; >150 lines is a flag)
- Deeply nested conditionals that could be flattened with early returns
- Misleading names (names that contradict what the code actually does)
- Comments that describe *what* the code does rather than *why* — flag only
  when the comment is actively misleading, not merely redundant
- Inconsistent patterns with adjacent code in the same file
- `TODO` / `FIXME` left in production code without a JIRA ticket reference

#### 4e. Unity & C# conventions

- `[SerializeField] private` preferred over `public` for inspector-exposed fields
- Missing `[RequireComponent]` for components that assume another component
  exists on the same GameObject
- `MonoBehaviour` event methods (`Awake`, `OnEnable`, `Start`, `Update`, etc.)
  called directly (should be via Unity's lifecycle, not manual calls)
- Calling `StopAllCoroutines` when only one coroutine should be stopped
- Using `string` overloads of `StartCoroutine`/`Invoke` (use the method-reference
  overloads instead)
- `GetComponent` in `Update` rather than cached in `Awake`/`Start`
- Using `transform.position +=` in `FixedUpdate` (use `rigidbody.MovePosition`
  for physics objects)
- Assembly definition (`asmdef`) violations: file is in a directory whose
  `asmdef` doesn't reference the types it uses, or creates a circular reference
- Editor-only code (using `UnityEditor` namespace) not guarded by `#if UNITY_EDITOR`
- Missing `null` checks after `GetComponent<T>()` where T is optional

#### 4f. Test coverage

- New public methods or complex logic paths with no corresponding test
- Changed behaviour of a method that existing tests covered but the tests were
  not updated
- Test assertions that are trivially true and don't actually verify behaviour
- Tests with no `[Test]` or `[UnityTest]` attribute (silently not run)

### 5. Synthesise findings

After reviewing all files:

1. **De-duplicate** findings that are the same issue in different locations —
   group them into a single finding with multiple locations if identical.
2. **Rank** by severity: `critical` → `major` → `minor` → `nit`.
3. **Prune nits** that are purely stylistic and are consistent with the rest
   of the file (i.e. the author wasn't introducing a new inconsistency). The
   bar for a nit is that a reasonable reviewer would actually mention it.
4. **Write an overall summary**: 2–5 sentences covering the nature of the
   change, your overall assessment, the most important issues, and whether
   you recommend approving, approving with minor fixes, or requesting changes.

### 6. Present findings for approval

Present the full review to the user **before posting anything**:

```
## MR !<number> — Review: <title>

**Overall:** <approve / approve with minor fixes / request changes>

<overall summary>

### Findings (<N> total — <C> critical, <M> major, <m> minor, <n> nits)

| # | File | Line | Sev | Dimension | Summary |
|---|------|------|-----|-----------|---------|
| 1 | … | … | critical | correctness | … |
…

### Finding details

**[1] critical — correctness** `path/to/File.cs:42`
> Summary sentence

Detail paragraph.

```suggestion
// proposed fix
```

…
```

Then ask:
- "Post all findings as inline comments? (y / n / list numbers to skip)"
- "Post the overall summary comment? (y / n)"

Respect partial approvals (e.g. "post 1, 3, 5 but skip the nits").

### 7. Post approved findings

For each approved finding, post a GitLab inline note on the exact line using
the GitLab MCP tool or `glab api`:

```bash
# post an inline note on a specific line
glab api -X POST \
  "projects/<url-encoded-path>/merge_requests/<mr>/discussions" \
  -f body="<comment text>" \
  -f position[position_type]="text" \
  -f position[base_sha]="<merge_base_sha>" \
  -f position[head_sha]="<head_sha>" \
  -f position[start_sha]="<target_branch_head_sha>" \
  -f position[new_path]="<file>" \
  -f position[new_line]=<line>
```

For the required SHAs:
```bash
git merge-base origin/<target> origin/<source>   # base_sha
git rev-parse origin/<source>                    # head_sha
git rev-parse origin/<target>                    # start_sha
```

Format each comment body using GitLab-flavoured Markdown:

```markdown
**[<severity>] <dimension>**

<detail paragraph>

```suggestion
<replacement code, if applicable>
```
```

If posting a **suggestion block**, the code in the suggestion must be a
drop-in replacement for the line(s) it anchors to — GitLab renders it as a
one-click apply. Only use suggestion blocks when the fix is mechanical and
unambiguous.

If an inline note fails (e.g. the line is in a binary file or the SHA
resolution is off), fall back to posting a general note (without position
parameters) and note the fallback in the report.

If the **overall summary comment** was approved:

```bash
glab api -X POST \
  "projects/<url-encoded-path>/merge_requests/<mr>/notes" \
  -f body="<summary markdown>"
```

### 8. Report

After posting, print:

- How many findings were posted vs. skipped
- Any findings that failed to post (with error)
- The MR URL so the user can see the comments in context
- A reminder that approving the MR is a separate step in the GitLab UI

## General rules

- **Never post without approval.** All inline comments and the summary note are
  gated on Step 6 confirmation. Honour partial approvals.
- **Be concrete.** Every finding must have a specific file + line, a clear
  failure scenario, and a suggested fix. Vague "consider refactoring this"
  comments without an actionable suggestion are not acceptable.
- **No false positives.** If you are uncertain whether something is a bug vs.
  intentional design, say so in the finding detail and mark the severity `minor`
  or `nit` rather than `critical`/`major`. Do not manufacture issues to appear
  thorough.
- **Respect scope.** Only flag issues introduced or clearly worsened by this MR.
  Pre-existing problems in unchanged code are out of scope unless the MR made
  them worse.
- **Match the project style.** The `.editorconfig` is the style source of truth.
  Don't impose external style preferences that conflict with it.
- **Binary / Unity-managed files** — skip entirely. Never comment on `.meta`,
  `.asset`, `.prefab`, `.unity`, `.fbx`, or binary files.
- **Don't re-review** findings the user explicitly skips — if they decline to
  post a finding, treat it as accepted and move on.