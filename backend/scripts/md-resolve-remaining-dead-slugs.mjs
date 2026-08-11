#!/usr/bin/env node
/**
 * Resolve the 5 politicians the URL-exact re-audit found still citing a DEAD member page.
 *
 * These were hidden by the old audit's cache bug: `hayes01?ys=2019RS` names Antonio Hayes (his slug as a
 * Delegate), so the buggy fetcher recorded "OK" while the STORED bare `hayes01` is NotFound. A slug
 * changes when a member moves chamber; the old page stops resolving without a session.
 *
 * Candidates come from the roster (current members) or enumeration; the guarantee comes from CONFIRMING
 * the page title of the URL IN THE FORM IT WILL BE STORED. Never a guessed suffix.
 * 🔴 Reads only.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CACHE = flag('--cache'), OUT = flag('--out');
if (!CACHE || !OUT) { console.error('need --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const strip = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '');
const clean = (s) => strip(s).toLowerCase().replace(/[^a-z\- ]/g, ' ').replace(/\s+/g, ' ').trim();
const dropSuffix = (s) => s.replace(/,?\s+(jr|sr|ii|iii|iv)\b\.?/gi, '').trim();
const lastOf = (f) => dropSuffix(clean(f)).split(' ').pop();
const firstOf = (f) => dropSuffix(clean(f)).split(' ')[0];
const firstAgrees = (a, b) => a === b || (a.length >= 3 && b.length >= 3 && (a.startsWith(b) || b.startsWith(a)));

async function nameAt(url) {
  const file = path.join(CACHE, Buffer.from(url).toString('base64url').slice(-120) + '.html');
  let html = null;
  if (fs.existsSync(file)) {
    const c = fs.readFileSync(file, 'utf8');
    if (c === '<DEAD>') return null;
    if (c.length > 5_000) html = c;
  }
  if (!html) {
    const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(1300);
    if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) { fs.writeFileSync(file, '<DEAD>'); return null; }
    html = body; fs.writeFileSync(file, html);
  }
  const t = parse(html).querySelector('title')?.text ?? '';
  const nm = t.replace(/^\s*Members\s*-\s*/i, '').replace(/^(Senator|Delegate)\s+/i, '').trim();
  return nm && !/^NotFound$/i.test(nm) ? nm : null;
}

const MEMBER = (slug, ys = null) =>
  `https://mgaleg.maryland.gov/mgawebsite/Members/Details/${encodeURI(slug)}${ys ? `?ys=${ys}` : ''}`;
const SESSIONS = ['2026RS', '2025RS', '2023RS', '2021RS', '2019RS', '2017RS'];

const TARGETS = [
  { who: 'Antonio Hayes', dead: 'hayes01' },
  { who: 'Chris West', dead: 'west01' },
  { who: 'Cory V. McCray', dead: 'mccray01' },
  { who: 'Dalya Attar', dead: 'attar01' },
  { who: 'Mary Beth Carozza', dead: 'carozza01' },
];

const out = [];
for (const t of TARGETS) {
  const last = lastOf(t.who), first = firstOf(t.who);
  const matches = (nm) => nm && lastOf(nm) === last && firstAgrees(firstOf(nm), first);
  const base = last.replace(/[^a-z]/g, '');
  const cands = [base, `${base} ${first[0]}`, ...Array.from({ length: 6 }, (_, i) => `${base}0${i + 1}`)];

  let chosen = null;
  for (const slug of [...new Set(cands)]) {
    if (slug === t.dead) continue;
    const bare = await nameAt(MEMBER(slug));
    if (matches(bare)) { chosen = { slug, url: MEMBER(slug), confirmed_as: bare, form: 'BARE' }; break; }
    if (bare) continue;               // resolves to somebody else: do not rescue with a session
    for (const ys of SESSIONS) {
      const nm = await nameAt(MEMBER(slug, ys));
      if (matches(nm)) { chosen = { slug, ys, url: MEMBER(slug, ys), confirmed_as: nm, form: 'SESSION_QUALIFIED' }; break; }
      if (nm) break;                  // different person in that session
    }
    if (chosen) break;
  }
  // last resort: the dead slug itself may resolve WITH a session (it is his old chamber page)
  if (!chosen) {
    for (const ys of SESSIONS) {
      const nm = await nameAt(MEMBER(t.dead, ys));
      if (matches(nm)) { chosen = { slug: t.dead, ys, url: MEMBER(t.dead, ys), confirmed_as: nm, form: 'SESSION_QUALIFIED_SAME_SLUG' }; break; }
    }
  }
  out.push({ ...t, replacement: chosen, final: chosen ? 'REPLACE' : 'HOLD_UNRESOLVED' });
  console.log(`${chosen ? '✅' : '❌'} ${t.who}: ${t.dead} -> ${chosen ? `${chosen.url}  = "${chosen.confirmed_as}" [${chosen.form}]` : 'UNRESOLVED'}`);
}
fs.writeFileSync(OUT, JSON.stringify({ audit: 'remaining dead member slugs', rows: out }, null, 1));
