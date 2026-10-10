#!/usr/bin/env bash
# metrics.sh: switch the tt-* token logging on or off for this machine, and
# read the log it has written. The switch is a flag file, so it persists across
# sessions. Needs bash, grep, sed and awk only.
set -u

usage() {
	cat >&2 <<'EOT'
usage: metrics.sh on | off | status
       metrics.sh report [--last N] [--since YYYY-MM-DD] [--skill <text>] [--raw]
       metrics.sh viz    [--last N] [--since YYYY-MM-DD] [--skill <text>] [--output <path>]

  on      create the flag; check the SessionEnd hook is registered
  off     remove the flag (the hook stays registered and then does nothing)
  status  flag, hook, log path and row count
  report  summary per skill set, then the matching rows (--raw: rows only)

State lives in ${CLAUDE_CONFIG_DIR:-~/.claude}/tt-metrics/ (override with
TT_METRICS_HOME): the `enabled` flag and `token-log.md`.

Exit: 0 ok, 3 on succeeded but the hook is not registered (snippet printed),
1 nothing to report, 2 usage error.
EOT
	exit 2
}

here=$(cd -P "$(dirname "$0")" && pwd) || exit 2
root=$(cd -P "$here/../.." && pwd) || exit 2
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
home=${TT_METRICS_HOME:-$cfg/tt-metrics}
flag=$home/enabled
log=${TT_METRICS_LOG:-$home/token-log.md}
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
	viz)
		outfile=${TT_METRICS_REPORT:-$home/report.html}
		last=0; since=""; skill=""
		while [ $# -gt 0 ]; do
			case "$1" in
				--last)   last=${2:?}; shift 2 ;;
				--since)  since=${2:?}; shift 2 ;;
				--skill)  skill=${2:?}; shift 2 ;;
				--output) outfile=${2:?}; shift 2 ;;
				*) usage ;;
			esac
		done
		[ -f "$log" ] || { echo "no log at $log; run: metrics.sh on" >&2; exit 1; }
		sel=$(grep '^| [0-9]\{4\}-' "$log" | awk -F' [|] ' -v S="$since" -v K="$skill" '
			{ d = substr($1, 3, 10) }
			(S == "" || d >= S) && (K == "" || index($4, K)) { print }')
		[ -n "$sel" ] && [ "$last" -gt 0 ] && sel=$(printf '%s\n' "$sel" | tail -n "$last")
		[ -n "$sel" ] || { echo "no sessions match" >&2; exit 1; }
		jsdata=$(printf '%s\n' "$sel" | awk -F' [|] ' '
			function t(s,  u,v) {
				gsub(/^[ \t]+|[ \t]+$/,"",s)
				u=substr(s,length(s)); v=s+0
				if(u=="k") return v*1000; if(u=="M") return v*1000000; return v
			}
			function q(s) {
				gsub(/^[ \t]+|[ \t]+$/,"",s)
				gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); return s
			}
			NR>1 { printf "," }
			{
				printf "{\"start\":\"%s\",\"session\":\"%s\",\"label\":\"%s\",\"skills\":\"%s\",\"mode\":\"%s\",\"model\":\"%s\",\"subs\":%d,\"requests\":%d,\"cacheWrite\":%d,\"cacheRead\":%d,\"input\":%d,\"output\":%d,\"weighted\":%d,\"maxCtx\":%d,\"stalls\":%d}",
					substr($1,3,16),substr(q($2),1,8),q($3),q($4),q($5),q($6),
					$8+0,$9+0,t($10),t($11),t($12),t($13),t($14),t($15),$16+0
			}')
		{
		cat << 'TMHTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>tt-metrics</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
<style>
:root{color-scheme:light;--sf:#fcfcfb;--pg:#f9f9f7;--t1:#0b0b0b;--t2:#52514e;--tm:#898781;--gl:#e1e0d9;--ax:#c3c2b7;--c1:#2a78d6;--c2:#eb6834;--c3:#1baf7a;--c4:#eda100;--c5:#e87ba4;--c6:#008300;--c7:#4a3aa7;--c8:#e34948}
@media(prefers-color-scheme:dark){:root{color-scheme:dark;--sf:#1a1a19;--pg:#0d0d0d;--t1:#ffffff;--t2:#c3c2b7;--tm:#898781;--gl:#2c2c2a;--ax:#383835;--c1:#3987e5;--c2:#d95926;--c3:#199e70;--c4:#c98500;--c5:#d55181;--c6:#008300;--c7:#9085e9;--c8:#e66767}}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--pg);color:var(--t1);font:14px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif;padding:24px}
h1{font-size:18px;font-weight:600;margin-bottom:4px}.sub{color:var(--t2);font-size:12px;margin-bottom:24px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(460px,1fr));gap:20px;margin-bottom:24px}
.panel{background:var(--sf);border-radius:8px;padding:20px;border:1px solid var(--gl)}
.panel h2{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--t2);margin-bottom:2px}
.panel p{font-size:12px;color:var(--tm);margin-bottom:16px}
.tbl-wrap{overflow-x:auto;background:var(--sf);border-radius:8px;border:1px solid var(--gl)}
table{width:100%;border-collapse:collapse;font-size:12px}
th{position:sticky;top:0;background:var(--sf);color:var(--t2);font-weight:600;text-align:right;padding:8px 10px;border-bottom:1px solid var(--gl);cursor:pointer;user-select:none;white-space:nowrap}
th:nth-child(-n+4){text-align:left}th:hover{color:var(--t1)}
td{padding:7px 10px;border-bottom:1px solid var(--gl);color:var(--t2);text-align:right;white-space:nowrap}
td:nth-child(-n+4){text-align:left;color:var(--t1);max-width:220px;overflow:hidden;text-overflow:ellipsis}
tr:last-child td{border-bottom:none}tr:hover td{background:rgba(128,128,128,.05)}
.asc::after{content:" ↑"}.desc::after{content:" ↓"}
</style>
</head>
<body>
<h1>tt-metrics</h1>
<p class="sub" id="sub"></p>
<div class="grid">
<div class="panel">
<h2>Token Breakdown</h2>
<p>Cache write · cache read · input · output — raw token counts per session</p>
<canvas id="cA"></canvas>
</div>
<div class="panel">
<h2>Weighted by Label Group</h2>
<p>Average weighted tokens per label group (cache write ×1.25, cache read ×0.1, output ×5)</p>
<canvas id="cB"></canvas>
</div>
<div class="panel">
<h2>Intelligence Signals</h2>
<p>Requests vs weighted tokens — bubble size = stalls; color = first skill used</p>
<canvas id="cC"></canvas>
</div>
</div>
<div class="tbl-wrap">
<table id="tbl">
<thead><tr>
<th data-col="start">Date</th><th data-col="session">Session</th><th data-col="label">Label</th><th data-col="skills">Skills</th>
<th data-col="model">Model</th><th data-col="subs">Subs</th><th data-col="requests">Req</th>
<th data-col="cacheWrite">Cache W</th><th data-col="cacheRead">Cache R</th><th data-col="cacheEff">Cache%</th>
<th data-col="input">Input</th><th data-col="output">Output</th><th data-col="weighted">Weighted</th>
<th data-col="maxCtx">Max Ctx</th><th data-col="stalls">Stalls</th><th data-col="outPerReq">Out/Req</th>
</tr></thead>
<tbody id="tbody"></tbody>
</table>
</div>
<script>
const sessions=
TMHTML
		printf '[%s]' "$jsdata"
		cat << 'TMHTML'
;
function h(n){if(n>=1e6)return(n/1e6).toFixed(2)+'M';if(n>=1e3)return Math.round(n/1e3)+'k';return String(n)}
sessions.forEach(s=>{
  const tot=s.cacheWrite+s.cacheRead+s.input;
  s.cacheEff=tot?s.cacheRead/tot:0;
  s.outPerReq=s.requests?Math.round(s.output/s.requests):0;
});
document.getElementById('sub').textContent=sessions.length+' session'+(sessions.length!==1?'s':'');
const cs=getComputedStyle(document.documentElement);
const gv=p=>cs.getPropertyValue(p).trim();
const C=[gv('--c1'),gv('--c2'),gv('--c3'),gv('--c4'),gv('--c5'),gv('--c6'),gv('--c7'),gv('--c8')];
const GL=gv('--gl'),T2=gv('--t2'),TM=gv('--tm');
Chart.defaults.color=T2;Chart.defaults.borderColor=GL;
Chart.defaults.font.family='system-ui,-apple-system,"Segoe UI",sans-serif';Chart.defaults.font.size=11;

new Chart(document.getElementById('cA'),{type:'bar',data:{
  labels:sessions.map(s=>s.session+' '+s.start.slice(5,10)),
  datasets:[
    {label:'Cache write',data:sessions.map(s=>s.cacheWrite),backgroundColor:C[1],stack:'s'},
    {label:'Cache read', data:sessions.map(s=>s.cacheRead), backgroundColor:C[2],stack:'s'},
    {label:'Input',      data:sessions.map(s=>s.input),      backgroundColor:C[0],stack:'s'},
    {label:'Output',     data:sessions.map(s=>s.output),     backgroundColor:C[3],stack:'s'},
  ]},options:{responsive:true,maintainAspectRatio:true,plugins:{
    legend:{labels:{boxWidth:10,padding:10}},
    tooltip:{callbacks:{label:ctx=>ctx.dataset.label+': '+h(ctx.parsed.y)}}},
  scales:{x:{stacked:true,grid:{color:GL},ticks:{color:TM,maxRotation:45,font:{size:10}}},
    y:{stacked:true,grid:{color:GL},ticks:{color:TM,callback:h}}}}});

{const g={};sessions.forEach(s=>{const k=(!s.label||s.label==='-')?'(unlabelled)':s.label;(g[k]=g[k]||[]).push(s.weighted)});
const lbs=Object.keys(g);const avgs=lbs.map(k=>Math.round(g[k].reduce((a,b)=>a+b,0)/g[k].length));
new Chart(document.getElementById('cB'),{type:'bar',data:{
  labels:lbs.map(l=>l.length>32?l.slice(0,30)+'…':l),
  datasets:[{label:'Avg weighted',data:avgs,backgroundColor:C[0],borderRadius:4,borderSkipped:false}]},
  options:{responsive:true,maintainAspectRatio:true,plugins:{legend:{display:false},
    tooltip:{callbacks:{label:ctx=>'Avg: '+h(ctx.parsed.y)+' ('+g[lbs[ctx.dataIndex]].length+' sess)'}}},
  scales:{x:{grid:{color:'transparent'},ticks:{color:TM,maxRotation:45}},
    y:{grid:{color:GL},ticks:{color:TM,callback:h}}}}});}

{const sk={};sessions.forEach(s=>{const k=s.skills.split(',')[0];(sk[k]=sk[k]||[]).push(s)});
const ks=Object.keys(sk).slice(0,3);
new Chart(document.getElementById('cC'),{type:'bubble',data:{datasets:ks.map((k,i)=>({
  label:k,data:sk[k].map(s=>({x:s.requests,y:s.weighted,r:Math.max(s.stalls*7+5,5),ss:s.session,st:s.stalls})),
  backgroundColor:C[i]+'bb',borderColor:C[i],borderWidth:1}))},
  options:{responsive:true,maintainAspectRatio:true,plugins:{
    legend:{labels:{boxWidth:10,padding:10}},
    tooltip:{callbacks:{label:ctx=>[ctx.dataset.label+' · '+ctx.raw.ss,'Req: '+ctx.raw.x+'  Wtd: '+h(ctx.raw.y),'Stalls: '+ctx.raw.st]}}},
  scales:{x:{title:{display:true,text:'Requests',color:TM},grid:{color:GL},ticks:{color:TM}},
    y:{title:{display:true,text:'Weighted tokens',color:TM},grid:{color:GL},ticks:{color:TM,callback:h}}}}});}

const COLS=['start','session','label','skills','model','subs','requests','cacheWrite','cacheRead','cacheEff','input','output','weighted','maxCtx','stalls','outPerReq'];
const NCOLS=new Set(['subs','requests','cacheWrite','cacheRead','cacheEff','input','output','weighted','maxCtx','stalls','outPerReq']);
let sortCol='start',sortDir='asc',tdata=[...sessions];
function fmtCell(s,c){switch(c){
  case'cacheEff':return Math.round(s[c]*100)+'%';
  case'cacheWrite':case'cacheRead':case'input':case'output':case'weighted':case'maxCtx':case'outPerReq':return h(s[c]);
  default:return(s[c]===undefined||s[c]==='')?'-':String(s[c]);}}
function renderTbl(){
  const tb=document.getElementById('tbody');tb.innerHTML='';
  tdata.forEach(s=>{const tr=document.createElement('tr');
    tr.innerHTML=COLS.map(c=>`<td>${fmtCell(s,c)}</td>`).join('');tb.appendChild(tr);});}
renderTbl();
document.querySelectorAll('th[data-col]').forEach(th=>{
  th.addEventListener('click',()=>{
    const c=th.dataset.col;
    sortDir=(sortCol===c&&sortDir==='asc')?'desc':'asc';sortCol=c;
    document.querySelectorAll('th').forEach(t=>t.className='');th.className=sortDir;
    tdata.sort((a,b)=>{const cmp=NCOLS.has(c)?a[c]-b[c]:String(a[c]).localeCompare(String(b[c]));return sortDir==='asc'?cmp:-cmp;});
    renderTbl();});});
</script>
</body>
</html>
TMHTML
		} > "$outfile"
		echo "report: $outfile" ;;
	*) usage ;;
esac
