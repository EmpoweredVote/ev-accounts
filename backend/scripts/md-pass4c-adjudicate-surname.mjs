#!/usr/bin/env node
/**
 * PASS 4c -- adjudicate the SURNAME_ONLY rows from pass 4b.
 *
 * A row lands here when the bill has a sponsor sharing the politician's surname, but NOT under the slug
 * the row cites. There are exactly two explanations and they need opposite actions:
 *
 *   (a) the sponsor is a DIFFERENT legislator with the same surname  -> REJECT
 *   (b) the row's CITED SLUG IS WRONG (pass 1 found 38 guessed numeric suffixes) and the sponsoring
 *       slug is really the same person                               -> ACCEPT, and cite the right bill
 *
 * The decisive test: fetch the SPONSOR's member page and read whose name it is
 * (`<title>Members - Senator Mary Washington</title>`), then compare to the row's politician.
 * Maryland genuinely has washington01 (Mary) and washington02 (Alonzo), jones01 and other Joneses --
 * so surname alone can never decide this.
 *
 * Writes nothing to the DB.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), BILLCACHE = flag('--bills'), MEMCACHE = flag('--members'), OUT = flag('--out');
if (!IN || !BILLCACHE || !MEMCACHE) { console.error('need --in --bills --members'); process.exit(2); }
fs.mkdirSync(MEMCACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const sp = JSON.parse(fs.readFileSync(IN, 'utf8'));
const rows = sp.rows.filter((r) => r.verdict === 'SURNAME_ONLY_CHECK');

const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop().toLowerCase();
const firstOf = (n) => n.trim().split(/\s+/)[0].toLowerCase();

/**
 * slug -> the name on that member page; null only when it is genuinely unresolvable.
 *
 * 🔑 A BARE SLUG THAT 404s IS NOT A DEAD MEMBER -- retry it with the BILL'S SESSION.
 *    `washington` 404s bare but `washington?ys=2019RS` is "Delegate Mary L. Washington";
 *    `young03?ys=2017RS` is "Delegate Pat Young". Slugs change when a member moves chamber, so the
 *    historical identity is only visible with the session attached. Without this the adjudicator
 *    called both UNKNOWN and (worse, in its first version) rejected them.
 * 🔴 Unresolvable => null => the caller must treat it as UNKNOWN, never as "different person".
 */
const memberName = new Map();
async function nameFor(slug, session = null) {
  const key = `${slug}|${session ?? ''}`;
  if (memberName.has(key)) return memberName.get(key);
  const urls = [`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}`];
  if (session) urls.push(`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}?ys=${session}`);
  const file = path.join(MEMCACHE, `${slug}${session ? '-' + session : ''}.html`);
  let html = null;
  if (fs.existsSync(file) && fs.statSync(file).size > 10_000 && !/Error\/NotFound/.test(fs.readFileSync(file, 'utf8').slice(0, 4000))) {
    html = fs.readFileSync(file, 'utf8');
  } else {
    for (const u of urls) {
      const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await res.text();
      await sleep(1500);
      // mgaleg answers 200 on its NotFound page -- judge by the landing URL, never the status code.
      if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) continue;
      html = body; fs.writeFileSync(file, html); break;
    }
  }
  if (!html) { memberName.set(key, null); return null; }
  const t = parse(html).querySelector('title')?.text ?? '';
  const nm = t.replace(/^\s*Members\s*-\s*/i, '').replace(/^(Senator|Delegate)\s+/i, '').trim();
  const val = nm && !/^NotFound$/i.test(nm) ? nm : null;
  memberName.set(key, val);
  return val;
}

/** sponsors of a cached bill page: [{slug, display}] */
function sponsorsOfBill(slug, session) {
  const f = path.join(BILLCACHE, `${slug}-${session}.html`);
  if (!fs.existsSync(f)) return null;
  const root = parse(fs.readFileSync(f, 'utf8'));
  let dd = null;
  for (const dt of root.querySelectorAll('dt')) if (/sponsored by/i.test(dt.text)) { dd = dt.nextElementSibling; break; }
  if (!dd) return [];
  return dd.querySelectorAll('a[href*="Members/Details/"]').map((a) => ({
    slug: (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9]+)/)?.[1]?.toLowerCase() ?? null,
    display: a.text.trim(),
  })).filter((x) => x.slug);
}

const out = [];
for (const r of rows) {
  const surname = surnameOf(r.politician);
  const first = firstOf(r.politician);
  const citedName = r.cited_slug ? await nameFor(r.cited_slug) : null;

  const cands = [];
  for (const e of r.evidence) {
    const sponsors = sponsorsOfBill(e.slug, e.session);
    if (!sponsors) continue;
    for (const s of sponsors.filter((s) => s.display.toLowerCase().includes(surname))) {
      if (s.slug === r.cited_slug) continue; // would have been confirmed already
      // Resolve against THE BILL'S SESSION -- slugs change when a member switches chamber.
      const nm = await nameFor(s.slug, e.session);
      // true / false / null(=unknown). Never collapse null into false.
      const same = nm === null ? null : (surnameOf(nm) === surname && firstOf(nm) === first);
      cands.push({ bill: `${e.session} ${e.number}`, title: e.title, sponsor_slug: s.slug, sponsor_name: nm, same_person: same,
        url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${e.slug}?ys=${e.session}` });
    }
  }
  const accept = cands.filter((c) => c.same_person === true);
  const unknown = cands.filter((c) => c.same_person === null);
  out.push({
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    cited_slug: r.cited_slug, cited_slug_resolves_to: citedName,
    cited_slug_is_this_person: citedName ? (surnameOf(citedName) === surname && firstOf(citedName) === first) : null,
    reasoning: r.reasoning, sources: r.sources,
    verdict: accept.length ? 'ACCEPT_SLUG_WAS_WRONG'
      : unknown.length ? 'HOLD_IDENTITY_UNKNOWN'
      : cands.length ? 'REJECT_DIFFERENT_PERSON' : 'REJECT_NO_CANDIDATE',
    candidates: cands,
    proposed_sources: accept.length ? [...new Set(accept.map((c) => c.url))].slice(0, 4) : [],
  });
}

const tally = out.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
console.log(JSON.stringify(tally, null, 2));
for (const r of out) {
  console.log(`\n[${r.verdict}] ${r.politician} / ${r.topic}`);
  console.log(`  cited slug ${r.cited_slug} -> "${r.cited_slug_resolves_to}"  (is this person: ${r.cited_slug_is_this_person})`);
  for (const c of r.candidates.slice(0, 4)) {
    console.log(`  ${c.same_person ? 'SAME' : 'DIFF'}  ${c.bill}  sponsor ${c.sponsor_slug} = "${c.sponsor_name}"`);
  }
}
if (OUT) fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD pass 4c - surname adjudication', tally, rows: out }, null, 1));
