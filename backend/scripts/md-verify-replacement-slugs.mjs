#!/usr/bin/env node
/**
 * Gate before writing any member-slug repair: EVERY replacement URL must resolve EXACTLY AS IT WILL BE
 * STORED, and must name the right politician.
 *
 * 🔴 WHY THIS EXISTS -- two bugs in my own earlier audit, both of which faked evidence:
 *  1. CACHE KEY DID NOT RECORD WHICH URL WON. nameFor() tried the bare slug then session-qualified
 *     URLs but wrote them all to `<slug>.html`. So `jacobs` was recorded as "Senator Nancy Jacobs"
 *     when the BARE url is actually NotFound -- a verdict about a URL nobody stores.
 *  2. SLUG REGEX `[A-Za-z0-9]+` TRUNCATED AT `%`. Jay A. Jacobs is `jacobs%20j` (slugs may contain
 *     spaces); truncation yielded `jacobs`, a DIFFERENT PERSON.
 * So: fetch bare first and judge the stored form on that. Only if bare fails do we consider a
 * session-qualified URL, and then the SESSION IS PART OF THE STORED URL.
 *
 * Also enumerates candidate slugs for FORMER members, who are absent from the roster (it is
 * current-only regardless of ?ys=). Enumerating is fine -- the guarantee comes from CONFIRMING the
 * page title, never from the guess.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), CACHE = flag('--cache'), OUT = flag('--out');
if (!IN || !CACHE || !OUT) { console.error('need --in --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const strip = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '');
const clean = (s) => strip(s).toLowerCase().replace(/[^a-z\- ]/g, ' ').replace(/\s+/g, ' ').trim();
const dropSuffix = (s) => s.replace(/,?\s+(jr|sr|ii|iii|iv)\b\.?/gi, '').trim();
const lastOf = (f) => dropSuffix(clean(f)).split(' ').pop();
const firstOf = (f) => dropSuffix(clean(f)).split(' ')[0];
const firstAgrees = (a, b) => a === b || (a.length >= 3 && b.length >= 3 && (a.startsWith(b) || b.startsWith(a)));

/** Fetch exactly this URL. Returns the member name or null. Cache key = the full URL. */
async function nameAt(url) {
  const safe = url.replace(/[^A-Za-z0-9]/g, '_').slice(-120);
  const file = path.join(CACHE, `${safe}.html`);
  let html = null;
  if (fs.existsSync(file) && fs.statSync(file).size > 5_000) {
    const c = fs.readFileSync(file, 'utf8');
    html = /Error\/NotFound/.test(c.slice(0, 4000)) ? null : c;
    if (html === null) return null;
  }
  if (!html) {
    const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(1300);
    if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) { fs.writeFileSync(file, '<Error/NotFound>'); return null; }
    html = body; fs.writeFileSync(file, html);
  }
  const t = parse(html).querySelector('title')?.text ?? '';
  const nm = t.replace(/^\s*Members\s*-\s*/i, '').replace(/^(Senator|Delegate)\s+/i, '').trim();
  return nm && !/^NotFound$/i.test(nm) ? nm : null;
}

const MEMBER = (slug, ys = null) =>
  `https://mgaleg.maryland.gov/mgawebsite/Members/Details/${encodeURI(slug)}${ys ? `?ys=${ys}` : ''}`;
const SESSIONS = ['2026RS', '2025RS', '2023RS', '2021RS', '2019RS', '2017RS', '2015RS', '2013RS'];

const res = JSON.parse(fs.readFileSync(IN, 'utf8'));
const out = [];

for (const r of res.rows) {
  if (r.resolution === 'AUDIT_FALSE_POSITIVE_SAME_PERSON') { out.push({ ...r, final: 'NO_ACTION_SAME_PERSON' }); continue; }

  const last = lastOf(r.politician), first = firstOf(r.politician);
  const matches = (nm) => nm && lastOf(nm) === last && firstAgrees(firstOf(nm), first);

  // Candidate slugs: the resolver's answer first, then enumeration for former members.
  const cands = [];
  if (r.correct_slug) cands.push(r.correct_slug);
  const base = last.replace(/[^a-z]/g, '');
  cands.push(base, `${base} ${first[0]}`, ...Array.from({ length: 6 }, (_, i) => `${base}0${i + 1}`));

  let chosen = null;
  for (const slug of [...new Set(cands)]) {
    if (slug === r.cited_slug) continue;
    // bare first -- that is the form we intend to store
    const bare = await nameAt(MEMBER(slug));
    if (matches(bare)) { chosen = { slug, ys: null, url: MEMBER(slug), confirmed_as: bare, form: 'BARE' }; break; }
    if (bare) continue; // resolves to somebody else -- do not try to rescue it with a session
    for (const ys of SESSIONS) {
      const nm = await nameAt(MEMBER(slug, ys));
      if (matches(nm)) { chosen = { slug, ys, url: MEMBER(slug, ys), confirmed_as: nm, form: 'SESSION_QUALIFIED' }; break; }
      if (nm) break; // resolves to a different person in that session; stop probing this slug
    }
    if (chosen) break;
  }

  // What does the CURRENTLY STORED (bare) citation actually resolve to, for a voter?
  const storedNow = await nameAt(MEMBER(r.cited_slug));
  out.push({
    politician: r.politician, politician_id: r.politician_id, rows: r.rows,
    cited_slug: r.cited_slug,
    stored_url_resolves_to: storedNow,
    stored_verdict: storedNow === null ? 'DEAD' : matches(storedNow) ? 'OK' : 'WRONG_PERSON',
    replacement: chosen,
    final: chosen ? (matches(storedNow) ? 'NO_ACTION_STORED_IS_FINE' : 'REPLACE') : 'HOLD_UNRESOLVED',
  });
}

const tally = out.reduce((m, x) => { m[x.final] = (m[x.final] || 0) + 1; return m; }, {});
console.log(JSON.stringify(tally, null, 2));
let rowsFixed = 0;
for (const x of out) {
  if (x.final === 'REPLACE') rowsFixed += x.rows;
  console.log(`\n[${x.final}] ${x.politician} (${x.rows} rows)`);
  console.log(`   stored ${x.cited_slug} -> ${x.stored_url_resolves_to ?? 'DEAD'}  (${x.stored_verdict ?? '-'})`);
  if (x.replacement) console.log(`   REPLACE WITH ${x.replacement.form}: ${x.replacement.url}  = "${x.replacement.confirmed_as}"`);
}
console.log(`\nrows that would be repaired: ${rowsFixed}`);
fs.writeFileSync(OUT, JSON.stringify({ gate: 'MD replacement slug verification', tally, rows: out }, null, 1));
