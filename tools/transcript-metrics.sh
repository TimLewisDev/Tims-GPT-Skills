#!/usr/bin/env bash
# transcript-metrics.sh: per-session response size, context size, slow
# responses, stalls and subagent use, from Claude Code session transcripts.
# Used to compare skill runs before and after a change. Needs bash and awk only.
set -eu

usage() {
	cat >&2 <<'EOF'
usage: transcript-metrics.sh [--since YYYY-MM-DD] [--slow SECONDS] <project dir | session.jsonl> ...

A project dir is ~/.claude/projects/<project>; its subagent transcripts
(<session>/subagents/*.jsonl) are included as kind "sub".

Columns: session kind start minutes skills responses max_out out_gt8k max_ctx
slow stalls other_err agent_calls
  minutes      summed model time (request to last streamed chunk)
  max_out      largest output_tokens of one response (thinking included)
  out_gt8k     responses over 8k output tokens
  max_ctx      largest input + cache tokens of one request
  slow         responses longer than --slow seconds (default 240)
  stalls       "response stopped arriving" / "connection lost" errors
EOF
	exit 2
}

since=""; slow=240
while [ $# -gt 0 ]; do
	case "$1" in
		--since) since=${2:?}; shift 2 ;;
		--slow) slow=${2:?}; shift 2 ;;
		-h | --help) usage ;;
		*) break ;;
	esac
done
[ $# -gt 0 ] || usage

files=()
for a in "$@"; do
	if [ -d "$a" ]; then
		for f in "$a"/*.jsonl "$a"/*/subagents/*.jsonl; do [ -f "$f" ] && files+=("$f"); done
	else
		files+=("$a")
	fi
done

printf 'session\tkind\tstart\tminutes\tskills\tresponses\tmax_out\tout_gt8k\tmax_ctx\tslow\tstalls\tother_err\tagent_calls\n'
for f in "${files[@]}"; do
	case "$f" in */subagents/*) kind=sub ;; *) kind=main ;; esac
	awk -v F="$f" -v KIND="$kind" -v SINCE="$since" -v SLOW="$slow" '
	function num(re, off) { return match($0, re) ? substr($0, RSTART + off, RLENGTH - off) + 0 : 0 }
	function str(re, off, tr) { return match($0, re) ? substr($0, RSTART + off, RLENGTH - off - tr) : "" }
	# Seconds since an epoch, from an ISO timestamp (days from civil date).
	function ep(t,   y, m, d) {
		y = substr(t, 1, 4) + 0; m = substr(t, 6, 2) + 0; d = substr(t, 9, 2) + 0
		if (m <= 2) { y--; m += 12 }
		return (365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d) * 86400 \
			+ substr(t, 12, 2) * 3600 + substr(t, 15, 2) * 60 + substr(t, 18, 6)
	}
	function addsk(s) {
		if (s ~ /^(clear|model|compact|resume|config|help|context|cost|exit|effort|memory|permissions|agents|mcp|hooks|ide|doctor|status|login|logout|fast|init|plan)$/ || (s in sk)) return
		sk[s] = 1; skills = skills (skills == "" ? "" : ",") s
	}
	{ ts = str("\"timestamp\":\"[^\"]*\"", 13, 1) }
	ts == "" { next }
	KIND == "main" && /"isSidechain":true/ { next }
	{ if (first == "") first = ts; last = ts }
	match($0, /command-name>\/[A-Za-z0-9:_-]+/) { addsk(substr($0, RSTART + 14, RLENGTH - 14)) }
	match($0, /"name":"Skill","input":\{"skill":"[^"]*"/) { addsk(substr($0, RSTART + 33, RLENGTH - 34)) }
	/"type":"assistant"/ && /"role":"assistant"/ {
		if (/"isApiErrorMessage":true/ || /"text":"API Error/) { if (/stopped arriving|[Cc]onnection lost/) stalls++; else other++; next }
		id = str("\"id\":\"msg_[^\"]*\"", 6, 1); if (id == "") next
		if (!(id in st)) { st[id] = lastU; ids[++n] = id }
		en[id] = ts
		o = num("\"output_tokens\":[0-9]+", 16); if (o > out[id]) out[id] = o
		c = num("\"input_tokens\":[0-9]+", 15) + num("\"cache_read_input_tokens\":[0-9]+", 26) + num("\"cache_creation_input_tokens\":[0-9]+", 30)
		if (c > mc) mc = c
		rest = $0
		while (match(rest, /"type":"tool_use","id":"[^"]*","name":"Agent"/)) {
			t = substr(rest, RSTART, RLENGTH); if (!(t in seen)) { seen[t] = 1; ag++ }
			rest = substr(rest, RSTART + RLENGTH)
		}
		next
	}
	/"type":"user"/ { lastU = ts }
	END {
		if (n == 0 && stalls == 0 && other == 0) exit
		if (SINCE != "" && first < SINCE) exit
		for (i = 1; i <= n; i++) {
			id = ids[i]
			if (out[id] > mo) mo = out[id]
			if (out[id] > 8000) big++
			if (st[id] != "") { d = ep(en[id]) - ep(st[id]); if (d > 0) ms += d; if (d > SLOW) sl++ }
		}
		sub(/.*\//, "", F); sub(/\.jsonl$/, "", F)
		printf "%s\t%s\t%s\t%.1f\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", F, KIND, substr(first, 1, 16), ms / 60, (skills == "" ? "-" : skills), n, mo, big, mc, sl, stalls, other, ag
	}' "$f"
done
