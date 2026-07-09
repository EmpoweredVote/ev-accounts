/**
 * gen-fec-review-html.ts — turn the enriched review JSON into a self-contained
 * HTML review tool for adjudicating needs_research FEC matches.
 *
 * Reads the JSON from run-fec-review-enrich.ts, computes a recommendation per case
 * (office+state eligibility, then incumbency / current-cycle / history), and writes
 * a single HTML file (inline CSS+JS, no external assets — Artifact-CSP safe).
 *
 * Usage: tsx scripts/gen-fec-review-html.ts <in.json> <out.html>
 */

import { readFile, writeFile } from 'node:fs/promises';

const IN = process.argv[2] ?? 'fec-review.json';
const OUT = process.argv[3] ?? 'fec-review.html';
const CURRENT_CYCLE = 2026;

interface Opt {
  candidate_id: string; fec_name: string; party: string | null; score: number | null;
  office_full: string | null; state: string | null; district: string | null;
  incumbent_challenge: string | null; cycles: number[];
}
interface Case {
  source_id: string; politician_id: string; full_name: string; bioguide_id: string | null;
  source_system: string; representing_state: string; chamber: string; district_id: string | null;
  options: Opt[];
}

const esc = (s: unknown): string =>
  String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function wantOffice(sourceSystem: string): 'Senate' | 'House' {
  return sourceSystem === 'fec_senate' ? 'Senate' : 'House';
}

interface Ranked extends Opt { eligible: boolean; incumbent: boolean; hasCurrent: boolean }

function rankOptions(c: Case): { ranked: Ranked[]; recIdx: number; confidence: 'high' | 'medium' | 'low' | 'none' } {
  const want = wantOffice(c.source_system);
  const ranked: Ranked[] = c.options.map(o => ({
    ...o,
    eligible: o.office_full === want && o.state === c.representing_state,
    incumbent: /incumbent/i.test(o.incumbent_challenge ?? ''),
    hasCurrent: o.cycles.includes(CURRENT_CYCLE),
  }));
  const order = [...ranked].sort((a, b) => {
    if (a.eligible !== b.eligible) return a.eligible ? -1 : 1;
    if (a.incumbent !== b.incumbent) return a.incumbent ? -1 : 1;
    if (a.hasCurrent !== b.hasCurrent) return a.hasCurrent ? -1 : 1;
    if (b.cycles.length !== a.cycles.length) return b.cycles.length - a.cycles.length;
    return (b.score ?? 0) - (a.score ?? 0);
  });
  const top = order[0];
  const eligible = order.filter(o => o.eligible);
  let confidence: 'high' | 'medium' | 'low' | 'none' = 'none';
  if (top && top.eligible) {
    if (eligible.length === 1) confidence = (top.incumbent || top.hasCurrent) ? 'high' : 'medium';
    else confidence = (top.incumbent && !eligible[1]!.incumbent) ? 'high' : 'low';
  }
  const recIdx = top && top.eligible ? ranked.indexOf(top) : -1;
  return { ranked, recIdx, confidence };
}

function cycleRange(cy: number[]): string {
  if (cy.length === 0) return '—';
  const lo = Math.min(...cy), hi = Math.max(...cy);
  return lo === hi ? `${lo}` : `${lo}–${hi}`;
}

function optionRow(c: Case, o: Ranked, isRec: boolean): string {
  const incClass = o.incumbent ? 'inc-in' : /open/i.test(o.incumbent_challenge ?? '') ? 'inc-open' : 'inc-ch';
  const loc = o.office_full === 'Senate'
    ? `${esc(o.state)} · Senate`
    : `${esc(o.state)}-${esc(o.district ?? '??')} · House`;
  return `
    <label class="opt${isRec ? ' opt-rec' : ''}${o.eligible ? '' : ' opt-inelig'}">
      <input type="radio" name="pick-${esc(c.source_id)}" value="${esc(o.candidate_id)}"${isRec ? ' checked' : ''} />
      <span class="opt-body">
        <span class="opt-line1">
          <span class="cid">${esc(o.candidate_id)}</span>
          <span class="fecname">${esc(o.fec_name)}</span>
          ${isRec ? '<span class="badge badge-rec">Recommended</span>' : ''}
          ${!o.eligible ? '<span class="badge badge-off">off-office/state</span>' : ''}
        </span>
        <span class="opt-line2">
          <span class="chip">${loc}</span>
          <span class="chip chip-inc ${incClass}">${esc(o.incumbent_challenge ?? '—')}</span>
          <span class="chip">${esc(o.party ?? '—')}</span>
          <span class="chip mono">cycles ${cycleRange(o.cycles)} · ${o.cycles.length}${o.hasCurrent ? ' · <b>2026</b>' : ''}</span>
          <span class="chip chip-score mono">score ${o.score ?? 0}</span>
        </span>
      </span>
    </label>`;
}

function caseCard(c: Case, i: number): string {
  const { ranked, recIdx, confidence } = rankOptions(c);
  const confPill = confidence === 'high' ? '<span class="pill pill-ok">clear match</span>'
    : confidence === 'medium' ? '<span class="pill pill-ok">likely</span>'
    : confidence === 'low' ? '<span class="pill pill-warn">needs a look</span>'
    : '<span class="pill pill-warn">no clear match</span>';
  const chamber = wantOffice(c.source_system);
  const recValue = recIdx >= 0 ? ranked[recIdx]!.candidate_id : '';
  const optsHtml = ranked.length
    ? ranked.map((o, idx) => optionRow(c, o, idx === recIdx)).join('')
    : '<p class="no-opts">No FEC candidates were returned for this politician. Mark “No match”.</p>';
  return `
  <article class="card" data-source="${esc(c.source_id)}" data-rec="${esc(recValue)}" data-conf="${confidence}" data-resolved="0" id="case-${i}">
    <header class="card-head">
      <div class="who">
        <h2>${esc(c.full_name)}</h2>
        <div class="who-meta">
          <span class="chip chip-strong">${esc(c.representing_state)} · U.S. ${chamber}</span>
          ${c.bioguide_id ? `<span class="chip mono">bioguide ${esc(c.bioguide_id)}</span>` : '<span class="chip chip-muted">no bioguide</span>'}
        </div>
      </div>
      <div class="head-right">${confPill}<span class="done-mark" aria-hidden="true">✓</span></div>
    </header>
    <div class="opts">${optsHtml}</div>
    <footer class="card-foot">
      <label class="opt opt-none">
        <input type="radio" name="pick-${esc(c.source_id)}" value="__none__" />
        <span class="opt-body"><span class="opt-line1"><span class="fecname">No match — mark not applicable</span></span></span>
      </label>
    </footer>
  </article>`;
}

async function main(): Promise<void> {
  const cases: Case[] = JSON.parse(await readFile(IN, 'utf8'));
  const ranks = cases.map(rankOptions);
  const nClear = ranks.filter(r => r.confidence === 'high' || r.confidence === 'medium').length;
  const nLook = ranks.filter(r => r.confidence === 'low' || r.confidence === 'none').length;

  const cardsHtml = cases.map((c, i) => caseCard(c, i)).join('\n');

  const html = `<title>FEC Match Review — ${cases.length} candidates</title>
<style>
:root{
  --ground:#f5f6f8; --surface:#ffffff; --surface-2:#eef1f5; --ink:#16202e; --muted:#5a6675;
  --line:#dfe3ea; --accent:#1f5fa8; --accent-soft:#e7effa; --ok:#1f8a5b; --ok-soft:#e6f3ec;
  --warn:#b7791f; --warn-soft:#f6eddb; --bad:#8a94a3;
  --shadow:0 1px 2px rgba(16,32,46,.06),0 3px 12px rgba(16,32,46,.05);
}
@media (prefers-color-scheme:dark){:root{
  --ground:#0e1520; --surface:#151d2b; --surface-2:#1c2536; --ink:#e6ebf2; --muted:#94a1b2;
  --line:#26303f; --accent:#5b9bd8; --accent-soft:#17293d; --ok:#3fae7d; --ok-soft:#12261d;
  --warn:#d4a548; --warn-soft:#2a2312; --bad:#5a6675;
  --shadow:0 1px 2px rgba(0,0,0,.3),0 3px 12px rgba(0,0,0,.25);
}}
:root[data-theme="light"]{
  --ground:#f5f6f8; --surface:#ffffff; --surface-2:#eef1f5; --ink:#16202e; --muted:#5a6675;
  --line:#dfe3ea; --accent:#1f5fa8; --accent-soft:#e7effa; --ok:#1f8a5b; --ok-soft:#e6f3ec;
  --warn:#b7791f; --warn-soft:#f6eddb; --bad:#8a94a3;
  --shadow:0 1px 2px rgba(16,32,46,.06),0 3px 12px rgba(16,32,46,.05);
}
:root[data-theme="dark"]{
  --ground:#0e1520; --surface:#151d2b; --surface-2:#1c2536; --ink:#e6ebf2; --muted:#94a1b2;
  --line:#26303f; --accent:#5b9bd8; --accent-soft:#17293d; --ok:#3fae7d; --ok-soft:#12261d;
  --warn:#d4a548; --warn-soft:#2a2312; --bad:#5a6675;
  --shadow:0 1px 2px rgba(0,0,0,.3),0 3px 12px rgba(0,0,0,.25);
}
*{box-sizing:border-box}
body,.wrap{margin:0}
.wrap{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;color:var(--ink);
  background:var(--ground);min-height:100vh;line-height:1.45;-webkit-font-smoothing:antialiased}
.mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-variant-numeric:tabular-nums}
.bar{position:sticky;top:0;z-index:10;background:color-mix(in srgb,var(--surface) 92%,transparent);
  backdrop-filter:blur(8px);border-bottom:1px solid var(--line);padding:14px clamp(16px,4vw,40px);
  display:flex;flex-wrap:wrap;align-items:center;gap:16px}
.bar h1{font-size:16px;margin:0;letter-spacing:.01em;font-weight:650}
.bar .sub{color:var(--muted);font-size:13px}
.counts{display:flex;gap:14px;margin-left:auto;align-items:center;flex-wrap:wrap}
.count{font-size:13px;color:var(--muted);display:flex;align-items:center;gap:6px}
.count b{color:var(--ink);font-size:15px}
.dot{width:9px;height:9px;border-radius:50%}
.dot-ok{background:var(--ok)} .dot-warn{background:var(--warn)} .dot-done{background:var(--accent)}
.actions{display:flex;gap:8px}
button{font:inherit;cursor:pointer;border-radius:8px;border:1px solid var(--line);
  background:var(--surface);color:var(--ink);padding:8px 13px;font-size:13px;font-weight:550;
  transition:background .12s,border-color .12s}
button:hover{border-color:var(--accent)}
button.primary{background:var(--accent);border-color:var(--accent);color:#fff}
button.primary:hover{filter:brightness(1.06)}
button:focus-visible,label.opt:focus-within{outline:2px solid var(--accent);outline-offset:2px}
main{padding:clamp(16px,4vw,40px);max-width:1000px;margin:0 auto;display:flex;flex-direction:column;gap:14px}
.legend{color:var(--muted);font-size:12.5px;display:flex;gap:16px;flex-wrap:wrap;padding:2px 2px 8px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow);
  overflow:hidden}
.card[data-resolved="1"]{border-color:var(--ok)}
.card[data-hidden="1"]{display:none}
.card-head{display:flex;align-items:flex-start;gap:12px;padding:16px 18px 12px;
  border-bottom:1px solid var(--line)}
.who h2{margin:0 0 7px;font-size:18px;font-weight:640;text-wrap:balance}
.who-meta{display:flex;gap:7px;flex-wrap:wrap}
.head-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.done-mark{width:24px;height:24px;border-radius:50%;background:var(--ok);color:#fff;display:grid;
  place-items:center;font-size:14px;opacity:0;transform:scale(.6);transition:opacity .15s,transform .15s}
.card[data-resolved="1"] .done-mark{opacity:1;transform:scale(1)}
.pill{font-size:11.5px;font-weight:650;padding:3px 9px;border-radius:999px;letter-spacing:.02em;white-space:nowrap}
.pill-ok{background:var(--ok-soft);color:var(--ok)}
.pill-warn{background:var(--warn-soft);color:var(--warn)}
.opts{display:flex;flex-direction:column;padding:8px}
.opt{display:flex;gap:11px;align-items:flex-start;padding:11px 12px;border-radius:10px;cursor:pointer;
  border:1px solid transparent}
.opt:hover{background:var(--surface-2)}
.opt input{margin-top:3px;accent-color:var(--accent);width:16px;height:16px;flex:none}
.opt-rec{background:var(--ok-soft);border-color:color-mix(in srgb,var(--ok) 35%,transparent);
  box-shadow:inset 3px 0 0 var(--ok)}
.opt-rec:hover{background:var(--ok-soft)}
.opt-inelig{opacity:.62}
.opt-body{display:flex;flex-direction:column;gap:6px;min-width:0;flex:1}
.opt-line1{display:flex;gap:9px;align-items:center;flex-wrap:wrap}
.cid{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12.5px;font-weight:600;
  color:var(--accent);background:var(--accent-soft);padding:2px 7px;border-radius:6px}
.fecname{font-weight:600;font-size:14.5px}
.opt-line2{display:flex;gap:6px;flex-wrap:wrap}
.chip{font-size:12px;color:var(--muted);background:var(--surface-2);border:1px solid var(--line);
  padding:2px 8px;border-radius:6px;white-space:nowrap}
.chip.mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:11.5px}
.chip b{color:var(--ink)}
.chip-strong{background:var(--accent-soft);border-color:transparent;color:var(--accent);font-weight:600}
.chip-muted{opacity:.7}
.chip-inc{font-weight:600}
.inc-in{color:var(--ok);background:var(--ok-soft);border-color:transparent}
.inc-open{color:var(--warn);background:var(--warn-soft);border-color:transparent}
.inc-ch{color:var(--bad)}
.badge{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;padding:2px 7px;border-radius:5px}
.badge-rec{background:var(--ok);color:#fff}
.badge-off{background:transparent;border:1px solid var(--bad);color:var(--bad)}
.card-foot{padding:2px 8px 10px}
.opt-none .fecname{color:var(--muted);font-weight:550}
.no-opts{color:var(--muted);padding:10px 14px;font-size:13.5px}
.footer{position:sticky;bottom:0;z-index:10;background:color-mix(in srgb,var(--surface) 94%,transparent);
  backdrop-filter:blur(8px);border-top:1px solid var(--line);padding:12px clamp(16px,4vw,40px);
  display:flex;align-items:center;gap:16px;flex-wrap:wrap}
.footer .prog{font-size:14px}
.footer .prog b{font-size:16px}
.toast{position:fixed;bottom:70px;left:50%;transform:translateX(-50%) translateY(20px);opacity:0;
  background:var(--ink);color:var(--ground);padding:10px 18px;border-radius:8px;font-size:13.5px;
  font-weight:550;transition:opacity .2s,transform .2s;pointer-events:none;z-index:20}
.toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
@media (max-width:640px){.card-head{flex-wrap:wrap}.counts{width:100%;margin-left:0}}
</style>

<div class="wrap">
  <div class="bar">
    <div>
      <h1>FEC match review</h1>
      <div class="sub">Confirm which FEC candidate each politician is — ${cases.length} to resolve</div>
    </div>
    <div class="counts">
      <span class="count"><span class="dot dot-ok"></span><b>${nClear}</b> clear</span>
      <span class="count"><span class="dot dot-warn"></span><b>${nLook}</b> needs a look</span>
      <span class="count"><span class="dot dot-done"></span><b id="doneCount">0</b>/${cases.length} selected</span>
      <div class="actions">
        <button id="acceptAll">Accept all recommended</button>
        <button id="toggleUnresolved">Show only unresolved</button>
        <button class="primary" id="copyPicks">Copy picks</button>
      </div>
    </div>
  </div>
  <main>
    <div class="legend">
      <span>▎<b style="color:var(--ok)">Green stripe</b> = recommended (office + state match, incumbent / current-cycle preferred)</span>
      <span>Chips show FEC office·district, incumbency, party, active cycles, and the name-match score</span>
      <span>Pick one per card, or “No match”. Then <b>Copy picks</b> and paste back.</span>
    </div>
    ${cardsHtml}
  </main>
  <div class="footer">
    <span class="prog"><b id="doneCount2">0</b> of ${cases.length} resolved</span>
    <span class="sub" style="color:var(--muted)">Recommended picks are pre-selected — review, adjust, then copy.</span>
    <div class="actions" style="margin-left:auto"><button class="primary" id="copyPicks2">Copy picks</button></div>
  </div>
  <div class="toast" id="toast"></div>
</div>

<script>
(function(){
  var cards = Array.prototype.slice.call(document.querySelectorAll('.card'));
  var meta = {};
  cards.forEach(function(card){
    var src = card.getAttribute('data-source');
    meta[src] = { full_name: card.querySelector('h2').textContent, card: card };
    card.addEventListener('change', function(){ markResolved(card); update(); });
    markResolved(card);
  });
  function markResolved(card){
    var checked = card.querySelector('input[type=radio]:checked');
    card.setAttribute('data-resolved', checked ? '1' : '0');
  }
  function selected(){
    var out = [];
    cards.forEach(function(card){
      var src = card.getAttribute('data-source');
      var checked = card.querySelector('input[type=radio]:checked');
      if(checked) out.push({ source_id: src, candidate_id: checked.value, full_name: meta[src].full_name });
    });
    return out;
  }
  function update(){
    var n = selected().length;
    document.getElementById('doneCount').textContent = n;
    document.getElementById('doneCount2').textContent = n;
  }
  function toast(msg){
    var t = document.getElementById('toast'); t.textContent = msg; t.classList.add('show');
    clearTimeout(t._t); t._t = setTimeout(function(){ t.classList.remove('show'); }, 1900);
  }
  document.getElementById('acceptAll').addEventListener('click', function(){
    cards.forEach(function(card){
      var rec = card.getAttribute('data-rec');
      if(rec){ var r = card.querySelector('input[value="'+rec+'"]'); if(r){ r.checked = true; } }
      markResolved(card);
    });
    update(); toast('Recommended picks selected');
  });
  var onlyUnres = false;
  document.getElementById('toggleUnresolved').addEventListener('click', function(){
    onlyUnres = !onlyUnres; this.textContent = onlyUnres ? 'Show all' : 'Show only unresolved';
    cards.forEach(function(card){
      var res = card.getAttribute('data-resolved') === '1';
      card.setAttribute('data-hidden', (onlyUnres && res) ? '1' : '0');
    });
  });
  function copyPicks(){
    var picks = selected();
    var lines = picks.map(function(p){ return p.source_id + '\\t' + p.candidate_id + '\\t' + p.full_name; });
    var text = lines.join('\\n');
    navigator.clipboard.writeText(text).then(
      function(){ toast(picks.length + ' picks copied — paste them back to apply'); },
      function(){ window.prompt('Copy these picks:', text); }
    );
  }
  document.getElementById('copyPicks').addEventListener('click', copyPicks);
  document.getElementById('copyPicks2').addEventListener('click', copyPicks);
  update();
})();
</script>`;

  await writeFile(OUT, html, 'utf8');
  console.log(`[gen] ${cases.length} cases (${nClear} clear, ${nLook} needs-a-look) -> ${OUT}`);
}

main().catch(err => { console.error('[gen] Fatal:', err instanceof Error ? err.message : String(err)); process.exit(1); });
