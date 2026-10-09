#!/usr/bin/env bash
# metrics.sh: switch the tims-* token logging on or off for this machine, and
# read the log it has written. The switch is a flag file, so it persists across
# sessions. Needs bash, grep, sed and awk only.
set -u

usage() {
	cat >&2 <<'EOT'
usage: metrics.sh on | off | status
       metrics.sh report [--last N] [--since YYYY-MM-DD] [--skill <text>] [--raw]

  on      create the flag; check the SessionEnd hook is registered
  off     remove the flag (the hook stays registered and then does nothing)
  status  flag, hook, log path and row count
  report  summary per skill set, then the matching rows (--raw: rows only)

State lives in ${CLAUDE_CONFIG_DIR:-~/.claude}/tims-metrics/ (override with
TIMS_METRICS_HOME): the `enabled` flag and `token-log.md`.

Exit: 0 ok, 3 on succeeded but the hook is not registered (snippet printed),
1 nothing to report, 2 usage error.
EOT
	exit 2
}

here=$(cd -P "$(dirname "$0")" && pwd) || exit 2
root=$(cd -P "$here/../.." && pwd) || exit 2
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
home=${TIMS_METRICS_HOME:-$cfg/tims-metrics}
flag=$home/enabled
log=${TIMS_METRICS_LOG:-$home/token-log.md}
settings=$cfg/settings.json
hook=$root/tools/metrics/record-session.sh

hook_registered() { [ -f "$settings" ] && grep -q 'record-session\.sh' "$settings"; }

rows() { [ -f "$log" ] && grep -c '^| [0-9]\{4\}-' "$log" || echo 0; }

cmd=${1:-status}; [ $# -gt 0 ] && shift
case "$cmd" in
	on)
		mkdir -p "$home" && : >"$flag" || { echo "metrics.sh: cannot write $flag" >&2; exit 2; }
		echo "logging: on ($flag)"
		echo "log: $log"
		if hook_registered; then
			echo "hook: registered in $settings"
		else
			echo "hook: NOT registered in $settings. Add this to its \"hooks\" object:"
			cat <<EOT
    "SessionEnd": [ { "hooks": [ { "type": "command",
      "command": "bash \"$hook\"" } ] } ]
EOT
			echo "It takes effect in the next Claude Code session."
			exit 3
		fi ;;
	off)
		rm -f "$flag"
		echo "logging: off" ;;
	status)
		[ -f "$flag" ] && echo "logging: on" || echo "logging: off"
		hook_registered && echo "hook: registered" || echo "hook: not registered"
		echo "log: $log ($(rows) sessions)" ;;
	report)
		last=0; since=""; skill=""; raw=0
		while [ $# -gt 0 ]; do
			case "$1" in
				--last) last=${2:?}; shift 2 ;;
				--since) since=${2:?}; shift 2 ;;
				--skill) skill=${2:?}; shift 2 ;;
				--raw) raw=1; shift ;;
				*) usage ;;
			esac
		done
		[ -f "$log" ] || { echo "no log at $log; run: metrics.sh on" >&2; exit 1; }
		sel=$(grep '^| [0-9]\{4\}-' "$log" | awk -F' [|] ' -v S="$since" -v K="$skill" '
			{ d = substr($1, 3, 10) }
			(S == "" || d >= S) && (K == "" || index($4, K)) { print }')
		[ -n "$sel" ] && [ "$last" -gt 0 ] && sel=$(printf '%s\n' "$sel" | tail -n "$last")
		[ -n "$sel" ] || { echo "no sessions match" >&2; exit 1; }
		if [ "$raw" = 0 ]; then
			printf '%s\n' "$sel" | awk -F' [|] ' '
				function n(s,   u) { u = substr(s, length(s)); if (u == "k") return s * 1e3; if (u == "M") return s * 1e6; return s + 0 }
				function h(v) { return v >= 1e6 ? sprintf("%.2fM", v / 1e6) : v >= 1e3 ? sprintf("%.0fk", v / 1e3) : sprintf("%d", v) }
				{ k = $4; c[k]++; w[k] += n($14); s[k] += $16 + 0
				  if (n($15) > m[k]) m[k] = n($15) }
				END {
					printf "%-44s %8s %10s %10s %10s %7s\n", "skills", "sessions", "avg wtd", "total wtd", "max ctx", "stalls"
					for (k in c) printf "%-44s %8d %10s %10s %10s %7d\n", substr(k, 1, 44), c[k], h(w[k] / c[k]), h(w[k]), h(m[k]), s[k]
				}' | sort
			echo
		fi
		sed -n '/^| Start/,/^|---/p' "$log"
		printf '%s\n' "$sel" ;;
	*) usage ;;
esac
