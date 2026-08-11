#!/usr/bin/env node
/**
 * Resolve the CORRECT mgaleg member slug for every Maryland politician whose stances cite a wrong or
 * dead one (input: md-cited-member-slug-audit.json).
 *
 * 🔑 Slugs are resolved FROM THE MGA ROSTER, never guessed. Guessing a numeric suffix is precisely the
 *    defect that created this mess (pass 1 found 38 cited slugs that were plausible-but-wrong suffixes).
 *    Rosters are read per session 2013RS-2026RS and both chambers, because a member's slug changes when
 *    they switch chamber and former members only appear in historical rosters.
 *
 * Every proposed slug is then CONFIRMED by fetching its member page and reading the title. A slug that
 * cannot be confirmed is HELD, never applied.
 *
 * ⚠ Name comparison must tolerate abbreviations/nicknames -- "Dan Cox" IS "Daniel L. Cox". A strict
 *    first-name equality test reported that as a wrong person; it is the same man.
 *
 * 🔴 Reads only. Writes a proposal file.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const AUDIT = flag('--audit'), CACHE = flag('--cache'), MEMCACHE = flag('--members'), OUT = flag('--out');
if (!AUDIT || !CACHE || !MEMCACHE || !OUT) { console.error('need --audit --cache --members --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const strip = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '');
const clean = (s) => strip(s).toLowerCase().replace(/[^a-z\- ]/g, ' ').replace(/\s+/g, ' ').trim();
const dropSuffix = (s) => s.replace(/,?\s+(jr|sr|ii|iii|iv)\b\.?/gi, '').trim();
const lastOf = (full) => { const c = dropSuffix(clean(full)); return c.split(' ').pop(); };
const firstOf = (full) => { const c = dropSuffix(clean(full)); return c.split(' ')[0]; };
/** "Dan" vs "Daniel" -> same. One being a prefix of the other counts as agreement. */
const firstAgrees = (a, b) => a === b || (a.length >= 3 && b.length >= 3 && (a.startsWith(b) || b.startsWith(a)));

// ---------- roster ----------
const SESSIONS = []; for (let y = 2013; y <= 2026; y++) SESSIONS.push(`${y}RS`);
const roster = [];
for (const session of SESSIONS) {
  for (const chamber of ['senate', 'house']) {
    const file = path.join(CACHE, `roster-${chamber}-${session}.html`);
    let html = null;
    if (fs.existsSync(file) && fs.statSync(file).size > 20_000) html = fs.readFileSync(file, 'utf8');
    else {
      const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Members/Index/${chamber}?ys=${session}`, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await res.text();
      await sleep(1300);
      if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) { console.log(`  skip roster ${chamber} ${session}`); continue; }
      html = body; fs.writeFileSync(file, html);
    }
    const root = parse(html);
    let n = 0;
    for (const a of root.querySelectorAll('a[href*="Members/Details/"]')) {
      const slug = (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9]+)/)?.[1];
      const nm = a.text.replace(/\s+/g, ' ').trim();
      if (!slug || !nm || !nm.includes(',')) continue;   // roster entries are "Last, First"
      const [last, first] = nm.split(',').map((x) => x.trim());
      roster.push({ session, chamber, slug: slug.toLowerCase(), roster_name: nm, last: clean(dropSuffix(last)), first: firstOf(first) });
      n++;
    }
    console.log(`roster ${chamber} ${session}: ${n}`);
  }
}
console.log(`roster entries: ${roster.length}`);

// ---------- confirm a slug by its member page ----------
const nameCache = new Map();
async function pageName(slug, session = null) {
  const key = `${slug}|${session ?? ''}`;
  if (nameCache.has(key)) return nameCache.get(key);
  const file = path.join(MEMCACHE, `${slug}${session ? '-' + session : ''}.html`);
  let html = null;
  if (fs.existsSync(file) && fs.statSync(file).size > 10_000) {
    const c = fs.readFileSync(file, 'utf8');
    if (!/Error\/NotFound/.test(c.slice(0, 4000))) html = c;
  }
  if (!html) {
    const urls = [`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}`];
    if (session) urls.push(`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}?ys=${session}`);
    for (const u of urls) {
      const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await res.text();
      await sleep(1300);
      if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) continue;
      html = body; fs.writeFileSync(file, html); break;
    }
  }
  if (!html) { nameCache.set(key, null); return null; }
  const t = parse(html).querySelector('title')?.text ?? '';
  const nm = t.replace(/^\s*Members\s*-\s*/i, '').replace(/^(Senator|Delegate)\s+/i, '').trim();
  const val = nm && !/^NotFound$/i.test(nm) ? nm : null;
  nameCache.set(key, val);
  return val;
}

// ---------- resolve ----------
const audit = JSON.parse(fs.readFileSync(AUDIT, 'utf8'));
const broken = audit.rows.filter((r) => r.verdict !== 'OK');

const out = [];
for (const b of broken) {
  const last = lastOf(b.politician), first = firstOf(b.politician);

  // Was the audit's "wrong person" actually just an abbreviation of the same name?
  if (b.slug_belongs_to) {
    const sameLast = lastOf(b.slug_belongs_to) === last;
    if (sameLast && firstAgrees(firstOf(b.slug_belongs_to), first)) {
      out.push({ ...b, resolution: 'AUDIT_FALSE_POSITIVE_SAME_PERSON', correct_slug: b.cited_slug, confirmed_as: b.slug_belongs_to });
      continue;
    }
  }

  const hits = roster.filter((r) => r.last === last && firstAgrees(r.first, first));
  const slugs = [...new Set(hits.map((h) => h.slug))];
  // Prefer the slug seen in the most recent session.
  slugs.sort((x, y) => {
    const ly = (s) => Math.max(...hits.filter((h) => h.slug === s).map((h) => parseInt(h.session, 10)));
    return ly(y) - ly(x);
  });

  let resolution = 'HOLD_NO_ROSTER_MATCH', correct = null, confirmed = null;
  for (const s of slugs) {
    if (s === b.cited_slug) continue;                       // the known-bad one
    const sess = hits.filter((h) => h.slug === s).sort((a, c) => parseInt(c.session) - parseInt(a.session))[0].session;
    const nm = await pageName(s, sess);
    if (!nm) continue;
    if (lastOf(nm) === last && firstAgrees(firstOf(nm), first)) { resolution = 'RESOLVED'; correct = s; confirmed = nm; break; }
  }
  if (resolution !== 'RESOLVED' && slugs.length === 0) resolution = 'HOLD_NO_ROSTER_MATCH';
  else if (resolution !== 'RESOLVED') resolution = 'HOLD_UNCONFIRMED';

  out.push({ ...b, resolution, correct_slug: correct, confirmed_as: confirmed, roster_candidates: slugs.slice(0, 5) });
}

const tally = out.reduce((m, x) => { m[x.resolution] = (m[x.resolution] || 0) + 1; return m; }, {});
console.log('\n' + JSON.stringify(tally, null, 2));
for (const x of out) {
  console.log(`\n[${x.resolution}] ${x.politician} (${x.rows} rows)`);
  console.log(`   cited ${x.cited_slug} -> ${x.slug_belongs_to ?? 'DEAD'}`);
  if (x.correct_slug) console.log(`   CORRECT: ${x.correct_slug} = "${x.confirmed_as}"`);
  else console.log(`   roster candidates: ${JSON.stringify(x.roster_candidates ?? [])}`);
}
fs.writeFileSync(OUT, JSON.stringify({ audit: 'MD correct member slug resolution', tally, rows: out }, null, 1));
