#!/usr/bin/env bash
# record-session.sh: Claude Code SessionEnd hook. Records the ending session's
# token use in the token log when it used a tims-* skill. On by default; never
# fails or delays the session. Needs bash, sed and awk only.

case "${1:-}" in
	-h | --help)
		cat >&2 <<'EOF'
usage: record-session.sh < <SessionEnd hook input JSON>

Install as a SessionEnd hook in ~/.claude/settings.json:
  "hooks": { "SessionEnd": [ { "hooks": [ { "type": "command",
    "command": "bash \"<skills repo>/tools/metrics/record-session.sh\"" } ] } ] }

Reads transcript_path from the hook input, then runs
transcript-metrics.sh --record in the background and returns at once.

Environment:
  TIMS_METRICS        off | 0 | false | no: record nothing (default: on)
  TIMS_METRICS_LOG    the log to write (default: token-log.md beside this script)
  TIMS_METRICS_LABEL  label for the row (default: none)
  TIMS_METRICS_MATCH  ERE the session's skills must match (default: (^|,)tims-)

Always exits 0.
EOF
		exit 0 ;;
esac

case "${TIMS_METRICS:-on}" in off | OFF | 0 | false | no) exit 0 ;; esac

here=$(cd "$(dirname "$0")" && pwd) || exit 0
log=${TIMS_METRICS_LOG:-$here/token-log.md}
match=${TIMS_METRICS_MATCH:-(^|,)tims-}

# The hook input is one JSON object; JSON escapes Windows backslashes as \\.
# Any run of backslashes becomes one forward slash.
input=$(cat 2>/dev/null) || exit 0
tp=$(printf '%s' "$input" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed 's#\\\+#/#g')
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

args=(--record "$log" --match "$match")
[ -n "${TIMS_METRICS_LABEL:-}" ] && args+=(--label "$TIMS_METRICS_LABEL")

# Detached, so the session can exit while the transcript is read.
nohup bash "$here/../transcript-metrics.sh" "${args[@]}" "$tp" </dev/null >/dev/null 2>&1 &
exit 0
