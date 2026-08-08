#!/usr/bin/env node
// Scope the 57 owed Portland rows: for each (politician, topic) pair, find on-topic council
// documents in that member's own roll-call record and report their individual vote.
// Titles are printed so they are judged by hand -- keyword counts are NOT evidence.

import { readFileSync, writeFileSync } from 'fs';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
const B = 'https://www.portland.gov';

const PATH = {
  'Candace Avalos':      '/council/districts/1/candace-avalos/votes',
  'Jamie Dunphy':        '/council/districts/1/jamie-dunphy/votes',
  'Loretta Smith':       '/council/districts/1/loretta-smith/votes',
  'Dan Ryan':            '/council/districts/2/dan-ryan/votes',
  'Elana Pirtle-Guiney': '/council/districts/2/elana-pirtle-guiney/votes',
  'Sameer Kanal':        '/council/districts/2/sameer-kanal/votes',
  'Angelita Morillo':    '/council/districts/3/angelita-morillo/votes',
  'Steve Novick':        '/council/districts/3/steve-novick/votes',
  'Tiffany Koyama Lane': '/council/districts/3/tiffany-koyama-lane/votes',
  'Eric Zimmerman':      '/council/districts/4/eric-zimmerman/votes',
  'Mitch Green':         '/council/districts/4/mitch-green/votes',
  'Keith Wilson':        '/mayor/keith-wilson/votes',
};

// Probe terms per compass topic. Chosen to match DOCUMENT TITLES, then filtered by hand.
const TOPIC_QUERIES = {
  'Affordable Housing':                        ['Affordable Housing'],
  'Criminalization of Homelessness':           ['camping', 'Impact Reduction'],
  'Local Immigration Enforcement':             ['Sanctuary City', 'Immigration Enforcement'],
  'Public Safety Approach':                    ['Portland Street Response', 'Community Safety'],
  'Rent Regulation':                           ['anti-competitive', 'Eviction'],
  'Residential Zoning':                        ['Zoning Map', 'housing production'],
  'Homelessness Response':                     ['Homelessness Response System'],
  'Environmental Protection vs. Development':  ['Tree Preservation', 'Environmental Code'],
  'Economic Development Incentives':           ['Prosper Portland', 'Tax Increment'],
  'Transportation Priorities':                 ['Vision Zero', 'Transportation Utility Fee'],
  'School Vouchers & Public Education Funding':['school', 'education'],
};

const dec = s => s.replace(/<[^>]*>/g, '')
  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&#039;/g, "'")
  .replace(/&quot;/g, '"').replace(/&rsquo;/g, "'").replace(/&hellip;/g, '...')
  .replace(/​/g, '').replace(/\s+/g, ' ').trim();

function parse(html) {
  const out = [];
  for (const part of html.split(/<div class="table-group">/).slice(1)) {
    const date = (part.match(/<time datetime="([\d-]+)"/) || [])[1] || '?';
    const tb = part.match(/<tbody>([\s\S]*?)<\/tbody>/);
    if (!tb) continue;
    for (const tr of tb[1].split(/<tr>/).slice(1)) {
      const cells = tr.match(/<(?:th|td)[^>]*class="views-field[^"]*"[^>]*>([\s\S]*?)(?=<\/(?:th|td)>|<(?:th|td)\b)/g) || [];
      const v = cells.map(c => dec(c.replace(/^<(?:th|td)[^>]*>/, '')));
      if (v.length < 3 || !v[1]) continue;
      out.push({ date, doc: v[0] || '(none)', title: v[1], vote: v[2] });
    }
  }
  return out;
}

const owed = JSON.parse(readFileSync('C:/EV-Accounts/backend/data/stance-retirement/2026-08-04-willametteweek-rollback.json', 'utf8'));
const rows = Array.isArray(owed) ? owed : owed.rows;

const cache = new Map();
async function votes(person, q) {
  const k = person + '|' + q;
  if (cache.has(k)) return cache.get(k);
  const url = `${B}${PATH[person]}?council_document=${encodeURIComponent(q)}`;
  const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
  const r = parse(await res.text());
  cache.set(k, r);
  await new Promise(x => setTimeout(x, 200));
  return r;
}

// Everyone except Ryan was sworn in January 2025; only votes from their own term can evidence them.
const NEW_COUNCIL = p => p !== 'Dan Ryan';
const inTerm = (p, d) => (NEW_COUNCIL(p) ? d >= '2025-01-01' : true);

const out = [];
for (const r of rows) {
  const person = r.full_name, topic = r.topic;
  const qs = TOPIC_QUERIES[topic] || [];
  const hits = [];
  for (const q of qs) {
    for (const v of await votes(person, q)) {
      if (!inTerm(person, v.date)) continue;
      if (!hits.some(h => h.doc === v.doc && h.title === v.title)) hits.push(v);
    }
  }
  out.push({ person, topic, retired_chair: r.value, hits });
}

let md = '# Scoping the 57 owed Portland rows against per-member roll-call records\n\n';
const byPerson = {};
for (const o of out) (byPerson[o.person] ||= []).push(o);

for (const [person, list] of Object.entries(byPerson)) {
  md += `\n## ${person}  (${list.length} owed)\n\n`;
  for (const o of list) {
    md += `### ${o.topic}  — retired chair ${o.retired_chair}\n`;
    if (!o.hits.length) { md += `**NO IN-TERM ON-TOPIC VOTE FOUND**\n\n`; continue; }
    for (const h of o.hits) md += `- ${h.date}  **${h.vote}**  ${h.doc}  ${h.title}\n`;
    md += '\n';
  }
}
writeFileSync('scope57.md', md);

const withEv = out.filter(o => o.hits.length).length;
console.log(`rows scoped: ${out.length}`);
console.log(`with >=1 in-term on-topic vote: ${withEv}`);
console.log(`with none: ${out.length - withEv}`);
console.log('\n--- rows with NO in-term on-topic vote ---');
for (const o of out.filter(o => !o.hits.length)) console.log(`  ${o.person.padEnd(20)} ${o.topic}`);
console.log('\n--- coverage by topic ---');
const t = {};
for (const o of out) { (t[o.topic] ||= [0, 0]); t[o.topic][1]++; if (o.hits.length) t[o.topic][0]++; }
for (const [k, [a, b]] of Object.entries(t).sort((x, y) => y[1][1] - x[1][1])) console.log(`  ${String(a)}/${String(b)}  ${k}`);
console.log('\nwrote scope57.md');
