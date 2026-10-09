#!/usr/bin/env bash
# ids.sh: list the planning IDs a document defines or cites, and cross-check them.
set -eu

usage() {
	cat >&2 <<'EOF'
usage: ids.sh defined <doc.md>
       ids.sh cited <doc.md>
       ids.sh xref [--prefixes R,S,A,C,CD,NB,P,T,WU,§] <citing.md> <defining.md> [<defining.md> ...]

IDs are R A S C P T (with digits, e.g. R12, T07a), CD NB WU (CD3, NB7, WU2)
and plan steps §N. Text inside code fences and inline code is ignored.

defined  ID<TAB>line<TAB>excerpt for every definition: "**R12:**", "**S3**," or
         "**R12 (removed …):**", a table row whose first cell is the ID
         ("| CD3 |"), or a heading that starts with the ID ("### §3.",
         "## P4 —", "### T07 —", "## WU1 —").
cited    ID<TAB>count<TAB>first line, for every ID mentioned. Ranges such as
         "R3–R6", "R3-6" and "§1–§4" cite every ID in between.
xref     UNDEFINED<TAB>ID<TAB>line: cited in <citing> but defined in none of
         the defining docs. UNCITED<TAB>ID<TAB>line: defined (with a prefix in
         --prefixes, default all) but never cited in <citing>.

Exit: 0 clean (or IDs found, for defined / cited), 1 xref found gaps or
nothing was found, 2 usage error.
EOF
	exit 2
}

# The awk library shared by every command.
read -r -d '' LIB <<'AWK' || true
function clean(s) { sub(/\r$/, "", s); return s }
# Skip fenced code; returns 1 if the line should be ignored.
function in_fence(l,   p) {
	p = l; sub(/^   ?/, "", p)
	if (FENCE != "") { if (index(p, FENCE) == 1) FENCE = ""; return 1 }
	if (p ~ /^```/) { FENCE = "```"; return 1 }
	if (p ~ /^~~~/) { FENCE = "~~~"; return 1 }
	return 0
}
function strip_code(l,   out, n, parts, i) {
	n = split(l, parts, "`")
	out = parts[1]
	for (i = 2; i <= n; i++) out = out ((i % 2 == 0) ? " " : parts[i])
	return out
}
function excerpt(l) {
	sub(/^[ \t>*#|-]+/, "", l); gsub(/\t/, " ", l)
	return (length(l) > 100) ? substr(l, 1, 100) "…" : l
}
function is_word(c) { return c ~ /[A-Za-z0-9_]/ }
# Calls cite(id, line) for every ID cited in the line.
function scan(l, ln,   rest, pos, tok, before, after, pfx, num, m, n2, k, tail) {
	rest = l; pos = 0
	while (match(rest, /(CD|NB|WU|[RASCPT])[0-9]+[a-z]?|§[0-9]+[a-z]?/)) {
		tok = substr(rest, RSTART, RLENGTH)
		before = (RSTART > 1) ? substr(rest, RSTART - 1, 1) : ""
		after = substr(rest, RSTART + RLENGTH, 1)
		tail = substr(rest, RSTART + RLENGTH)
		rest = tail
		if (substr(tok, 1, 1) != "§" && is_word(before)) continue
		if (is_word(after)) continue
		cite(tok, ln)
		# Ranges: R3–R6, R3-R6, R3–6, §1–§4
		pfx = tok; sub(/[0-9]+[a-z]?$/, "", pfx)
		num = tok; sub(/^[^0-9]+/, "", num); sub(/[a-z]$/, "", num)
		if (match(tail, /^(–|-)/)) {
			m = substr(tail, RLENGTH + 1)
			if (index(m, pfx) == 1) m = substr(m, length(pfx) + 1)
			if (match(m, /^[0-9]+/) && !is_word(substr(m, RLENGTH + 1, 1))) {
				n2 = substr(m, 1, RLENGTH) + 0
				if (n2 > num + 0 && n2 - num <= 50)
					for (k = num + 1; k <= n2; k++) cite(pfx k, ln)
			}
		}
	}
}
# Returns the ID a line defines, or "".
function definition(l,   t) {
	if (match(l, /\*\*(CD|NB|WU|[RASCPT])[0-9]+[a-z]?(:| \(|\*\*[:,])/)) {
		t = substr(l, RSTART + 2, RLENGTH - 2); sub(/(:| \(|\*\*[:,])$/, "", t); return t
	}
	if (match(l, /^\|[ \t]*(\*\*)?(CD|NB|WU|[RASCPT])[0-9]+[a-z]?(\*\*)?[ \t]*\|/)) {
		t = substr(l, RSTART, RLENGTH); gsub(/[| \t*]/, "", t); return t
	}
	if (match(l, /^#+[ \t]+((CD|NB|WU|[RASCPT])[0-9]+[a-z]?|§[0-9]+[a-z]?)([.:]|[ \t]|$)/)) {
		t = substr(l, RSTART, RLENGTH); sub(/^#+[ \t]+/, "", t); sub(/[.: \t]$/, "", t); return t
	}
	return ""
}
AWK

[ $# -ge 1 ] || usage
cmd=$1
shift
case "$cmd" in
	defined | cited)
		[ $# -eq 1 ] || usage
		[ -f "$1" ] || { echo "ids.sh: no such file: $1" >&2; exit 2; }
		;;
	xref) ;;
	*) usage ;;
esac

case "$cmd" in
	defined)
		awk "$LIB"'
		{ l = clean($0); if (in_fence(l)) next
		  id = definition(l); if (id != "") { printf "%s\t%d\t%s\n", id, NR, excerpt(l); n++ } }
		END { exit (n > 0 ? 0 : 1) }' "$1"
		;;
	cited)
		awk "$LIB"'
		function cite(id, ln) { if (!(id in cnt)) { order[++n] = id; first[id] = ln }; cnt[id]++ }
		{ l = clean($0); if (in_fence(l)) next; scan(strip_code(l), NR) }
		END { for (i = 1; i <= n; i++) printf "%s\t%d\t%d\n", order[i], cnt[order[i]], first[order[i]]; exit (n > 0 ? 0 : 1) }' "$1"
		;;
	xref)
		prefixes=""
		if [ "${1:-}" = --prefixes ]; then prefixes=${2:-}; shift 2 || usage; fi
		[ $# -ge 2 ] || usage
		for f in "$@"; do [ -f "$f" ] || { echo "ids.sh: no such file: $f" >&2; exit 2; }; done
		citing=$1
		shift
		awk -v PREFIXES="$prefixes" "$LIB"'
		function cite(id, ln) { if (FILENAME == CITING && !(id in cited)) { cited[id] = ln; corder[++nc] = id } }
		function prefix(id,   p) { p = id; sub(/[0-9]+[a-z]?$/, "", p); return p }
		BEGIN { if (PREFIXES != "") { np = split(PREFIXES, ps, ","); for (i = 1; i <= np; i++) want[ps[i]] = 1 } }
		FNR == 1 { FENCE = ""; if (NR == 1) CITING = FILENAME }
		{
			l = clean($0); if (in_fence(l)) next
			if (FILENAME == CITING) scan(strip_code(l), FNR)
			else { id = definition(l); if (id != "" && !(id in defd)) { defd[id] = FNR; dorder[++nd] = id } }
		}
		END {
			for (i = 1; i <= nc; i++) if (!(corder[i] in defd)) { printf "UNDEFINED\t%s\t%d\n", corder[i], cited[corder[i]]; bad++ }
			for (i = 1; i <= nd; i++) {
				id = dorder[i]
				if (PREFIXES != "" && !(prefix(id) in want)) continue
				if (!(id in cited)) { printf "UNCITED\t%s\t%d\n", id, defd[id]; bad++ }
			}
			printf "# %d cited, %d defined, %d gaps\n", nc, nd, bad
			exit (bad > 0 ? 1 : 0)
		}' "$citing" "$@"
		;;
esac
