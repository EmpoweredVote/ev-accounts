#!/usr/bin/env node
/**
 * PASS 4b -- does the legislator actually attach to the bill their stance credits them with?
 *
 * Input : md-pass4-worklist.json (rows whose named instruments all resolved to real MD bills)
 * Method: fetch each distinct bill page once, read its "Sponsored by" member links, and match the
 *         politician by their OWN mgaleg SLUG (taken from the URL their stance already cites).
 *
 * 🔑 Slug matching, not surname matching. Surname substrings have produced thousands of bad links on
 *    this project before ("Tran" matching "Transportation"). A slug is exact.
 *    Surname is recorded ONLY as a separate, weaker signal so that "cited slug is wrong" stays
 *    distinguishable from "not a sponsor". They are never merged.
 *
 * 🔴 A sponsor list is not a vote list. Rows saying "voted for" are NOT settled by a sponsor miss --
 *    roll calls live in separate PDFs. A miss here is UNVERIFIED, never "false".
 * 🔴 Writes no database changes. Emits a worklist.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), OUT = flag('--out'), CACHE = flag('--cache');
if (!IN || !OUT || !CACHE) { console.error('need --in --out --cache'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const wl = JSON.parse(fs.readFileSync(IN, 'utf8'));
const rows = wl.rows.filter((r) => r.has_instrument && r.all_resolved);

/** The politician's own mgaleg slug, from the URL their stance already cites. */
function citedSlug(sources) {
  for (const s of sources || []) {
    const m = String(s).match(/mgaleg\.maryland\.gov\/mgawebsite\/Members\/Details\/([A-Za-z0-9]+)/i);
    if (m) return m[1].toLowerCase();
  }
  return null;
}
function surnameOf(fullName) {
  const clean = fullName.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim();
  return clean.split(/\s+/).pop().toLowerCase();
}

const wanted = new Map();
for (const r of rows) for (const i of r.instruments) for (const h of i.hits) wanted.set(`${h.slug}|${h.session}`, h);
console.log(`fetching ${wanted.size} distinct bill pages…`);

const sponsorsOf = new Map();
let n = 0, failed = 0;
for (const [key, b] of wanted) {
  const file = path.join(CACHE, `${b.slug}-${b.session}.html`);
  let html = null;
  if (fs.existsSync(file) && fs.statSync(file).size > 20_000) html = fs.readFileSync(file, 'utf8');
  else {
    const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}`;
    try {
      const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await res.text();
      // 🔴 mgaleg answers 200 on its own NotFound page -- trust the landing URL, never the status.
      if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) { failed++; sponsorsOf.set(key, null); await sleep(1200); continue; }
      html = body; fs.writeFileSync(file, html);
      await sleep(1300);
    } catch { failed++; sponsorsOf.set(key, null); continue; }
  }
  const root = parse(html);
  let dd = null;
  for (const dt of root.querySelectorAll('dt')) {
    if (/sponsored by/i.test(dt.text)) { dd = dt.nextElementSibling; break; }
  }
  const slugs = new Set(), names = [];
  if (dd) {
    for (const a of dd.querySelectorAll('a[href*="Members/Details/"]')) {
      const m = (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9]+)/);
      if (m) slugs.add(m[1].toLowerCase());
      names.push(a.text.trim());
    }
    if (!slugs.size) names.push(dd.text.replace(/\s+/g, ' ').trim()); // committee bills have no member links
  }
  sponsorsOf.set(key, { slugs: [...slugs], names, title: b.title, number: b.number, session: b.session, slug: b.slug });
  if (++n % 40 === 0) console.log(`  …${n}/${wanted.size}`);
}
console.log(`fetched; ${failed} page(s) unavailable`);

const out = rows.map((r) => {
  const slug = citedSlug(r.sources);
  const surname = surnameOf(r.politician);
  const cands = [];
  for (const i of r.instruments) for (const h of i.hits) {
    const s = sponsorsOf.get(`${h.slug}|${h.session}`);
    if (!s) continue;
    const bySlug = slug ? s.slugs.includes(slug) : false;
    const byName = s.names.some((nm) => nm.toLowerCase().includes(surname));
    if (bySlug || byName) cands.push({ instrument: i.instrument, number: s.number, session: s.session, slug: s.slug, title: s.title, matched_slug: bySlug, matched_surname_only: !bySlug && byName });
  }
  const strong = cands.filter((c) => c.matched_slug);
  return {
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    value: r.value, cited_slug: slug, reasoning: r.reasoning, sources: r.sources,
    verdict: strong.length ? 'SPONSOR_CONFIRMED' : cands.length ? 'SURNAME_ONLY_CHECK' : 'NO_SPONSOR_LINK',
    evidence: (strong.length ? strong : cands).slice(0, 6),
    proposed_source: strong.length ? `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${strong[0].slug}?ys=${strong[0].session}` : null,
  };
});

const tally = out.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
fs.writeFileSync(OUT, JSON.stringify({
  pass: 'MD pass 4b - sponsorship verification',
  caveats: [
    'Sponsor lists only. A NO_SPONSOR_LINK row may still be true via a floor vote (roll calls are separate PDFs) -- it is UNVERIFIED, not false.',
    'SURNAME_ONLY_CHECK means the cited mgaleg slug did not appear but a same-surname member did. Never auto-accept: Maryland has multiple same-surname legislators.',
  ],
  tally, rows: out,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
