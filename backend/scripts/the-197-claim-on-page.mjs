#!/usr/bin/env node
/**
 * GUARD ON THE 197 — before treating "topic keyword absent" as "page holds no evidence",
 * test the page against the ROW'S OWN WORDS.
 *
 * 🔴 WHY THIS EXISTS: the coverage cut keys on a TOPIC lexicon. A row can rest on a passage that
 * never uses the topic's vocabulary — Casey Shepard's abortion row rests on the phrase "bodily
 * autonomy", which contains none of {abortion, reproductive, roe v, pro-choice, pro-life, pregnan}.
 * The same failure mode already burned this workstream once: probe-topic-evidence.mjs scored
 * passages on topic-lexicon hits, so the sentence ten rows actually rested on scored 0 and never
 * appeared in its own output. TOPIC_ABSENT is a sort. Claim-absent is the verdict.
 *
 * Extracts from the reasoning: quoted phrases, multiword proper nouns, bill/resolution numbers and
 * distinctive rare words — then greps the CACHED RAW HTML (never extracted text) for each.
 *
 * 🔴 Reads only. A hit does not prove the row is sourced; it proves the page is not silent, which is
 * enough to disqualify the row from any "absent topic = no stance" retirement.
 *   node scripts/the-197-claim-on-page.mjs --cache <dir> --out <out.json>
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CACHE = flag('--cache', 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/tierb-cache');
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-the-197-claim-on-page.json');

const G = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197.json', 'utf8'));
const fileFor = (u) => path.join(CACHE, encodeURIComponent(u).replace(/[^A-Za-z0-9%._-]/g, '_').slice(-180) + '.html');

// Words too common to be evidence of anything. A hit on one of these is noise.
const STOP = new Set(`the a an and or of in on for to with as at by from his her their its this that
 he she they it not no is was were has have had been be being are will would could should may might
 who whom which what when where why how all any both each few more most other some such only own same
 so than too very can just also including consistent record support supports supported supporting
 position stance value voted vote votes voting legislation bill bills law laws act acts state states
 federal government public private new first second third district county city town political
 politics party democrat democratic republican gop caucus member members committee house senate
 senator representative delegate governor mayor council board chair ranking leader majority minority
 progressive conservative moderate liberal rights right access reform policy policies program
 programs issue issues care health people families working american americans year years session`
  .split(/\s+/).filter(Boolean));

const clean = (s) => (s || '').replace(/\s+/g, ' ').trim();

function signals(reasoning) {
  const t = clean(reasoning);
  const out = [];
  // 1. Anything the author put in quotes — the strongest signal, it claims to be verbatim.
  for (const m of t.matchAll(/["'\u2018\u2019\u201c\u201d]([^"'\u2018\u2019\u201c\u201d]{6,80})["'\u2018\u2019\u201c\u201d]/g)) {
    out.push({ kind: 'quoted', text: m[1] });
  }
  // 2. Bill / resolution / roll-call designators.
  for (const m of t.matchAll(/\b(?:H\.?R\.?|S\.?|H\.?B\.?|S\.?B\.?|H\.?Res\.?|H\.?Con\.?Res\.?|LD|SB|HB)\s?\d{1,5}\b/gi)) {
    out.push({ kind: 'instrument', text: clean(m[0]) });
  }
  // 3. Multiword proper nouns — "Congressional Equality Caucus", "Planned Parenthood".
  for (const m of t.matchAll(/\b([A-Z][a-z'’]+(?:\s+(?:of|for|the|and|to|in)\s+)?(?:\s?[A-Z][A-Za-z'’]+){1,5})\b/g)) {
    const s = clean(m[1]);
    if (s.split(/\s+/).length >= 2) out.push({ kind: 'propernoun', text: s });
  }
  // 4. Rare single words — long, not stopwords, not the politician's own name.
  for (const m of t.matchAll(/\b([a-z]{8,})\b/g)) {
    if (!STOP.has(m[1])) out.push({ kind: 'rareword', text: m[1] });
  }
  // dedupe, keep order
  const seen = new Set();
  return out.filter((s) => { const k = s.kind + '|' + s.text.toLowerCase(); if (seen.has(k)) return false; seen.add(k); return true; });
}

const htmlCache = new Map();
function lowerHtml(u) {
  if (htmlCache.has(u)) return htmlCache.get(u);
  const f = fileFor(u);
  const v = fs.existsSync(f) ? fs.readFileSync(f, 'utf8').toLowerCase() : null;
  htmlCache.set(u, v);
  return v;
}

const rows = G.rows.map((r) => {
  const h = lowerHtml(r.article);
  if (!h) return { ...r, page_cached: false };
  const surname = r.full_name.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop().toLowerCase();
  const sig = signals(r.reasoning).filter((s) => !s.text.toLowerCase().includes(surname));
  const hits = sig.filter((s) => h.includes(s.text.toLowerCase()));
  // A quoted phrase or an instrument on the page is a strong hit; a bare rare word is weak.
  const strong = hits.filter((s) => s.kind === 'quoted' || s.kind === 'instrument' || s.kind === 'propernoun');
  return {
    politician_id: r.politician_id, topic_id: r.topic_id, full_name: r.full_name, topic: r.topic,
    answer_value: r.answer_value, article: r.article, reasoning: r.reasoning, sources: r.sources,
    page_cached: true, n_signals: sig.length, n_hits: hits.length,
    strong_hits: strong.map((s) => `${s.kind}:${s.text}`),
    weak_hits: hits.filter((s) => s.kind === 'rareword').map((s) => s.text),
    class: strong.length ? 'PAGE_NOT_SILENT' : hits.length ? 'WEAK_ONLY' : 'PAGE_SILENT',
  };
});

const tally = rows.reduce((m, r) => { m[r.class || 'NO_CACHE'] = (m[r.class || 'NO_CACHE'] || 0) + 1; return m; }, {});
fs.writeFileSync(OUT, JSON.stringify({
  pass: 'The 197 — is the cited page silent on the ROW\'S OWN WORDS, not just on the topic lexicon?',
  caveat: 'PAGE_NOT_SILENT disqualifies a row from absent-topic retirement; it does NOT source it. '
        + 'PAGE_SILENT is a reading queue, still not a delete list.',
  tally, rows,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
