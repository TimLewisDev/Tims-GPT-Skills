# Template: Focus Log

The Focus Log is the exploration's memory on disk: `tt-familiarisation-doc`
writes the Familiarisation doc from it (possibly in a fresh session), and the
Familiarisation challenge checks the doc against it. Keep it short and factual.
Edit it in place; never rewrite it whole.

Interest values: `Unrated` (not yet asked) · `Focus` (the engineer is very
interested) · `Context` (needed to understand a Focus topic) · `Parked` (not
interested).

```markdown
# Focus Log: <seed, in a few words>

- **Seed:** "<the engineer's first message, verbatim>"
- **Purpose:** <change · debug · plan a feature · learn>: "<their words>"
- **Folder:** `<doc folder>` · **Prefix:** <Prefix>
- **Base:** `<base>` @ `<short sha>` (<full sha>), pinned <YYYY-MM-DD> (or "working tree")
- **Status:** Exploring · **Next:** <the next direction, in a few words>
  (later: `Focus confirmed <YYYY-MM-DD>` · then `Documented <YYYY-MM-DD>: <doc path>`)

## Focus statement
<What the engineer is really after, in one or two sentences. "(draft)" until
they confirm it, then "(confirmed <YYYY-MM-DD>)".>

## Topics

### <topic name>
- **Interest:** Unrated
- **Shown:** <one line per thing described> (`path:line`)
- **Engineer:** "<short quote>"; "<short quote>"
- **Open questions:** <questions raised and not answered by the code, or none>
- **Research:** `research/<file>.md`
```
