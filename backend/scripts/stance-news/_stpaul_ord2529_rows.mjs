// Re-source the three Saint Paul rent-regulation rows that cited a page which cannot evidence them.
//
// 🔴 THE OLD CITATION WAS A PAGE WITHOUT THE PEOPLE ON IT. All three rows cited
// `MeetingDetail.aspx?LEGID=7306…` with the same 47-word agenda-table row. The page is not broken —
// 1,065,089 bytes, and the snippet IS on it at offset 10,791 — but it is an agenda listing:
// "Bowie" and "Jost" appear ZERO times on it, "Noecker" twice and both ~24,000 characters away,
// and there is no roll call at all. checkNameProximity returned `name_not_present` for all three,
// correctly. A snippet can be perfectly verbatim and still be unable to say anything about the
// member whose row cites it.
// ▶ When a citation fails, ask first whether the PAGE can carry the claim. This one never could.
//
// 🟢 The meeting-walk found the two pages that can. The agenda row links both:
//     LegislationDetail  ID=7282238  GUID=60463898-…   File #: Ord 25-29 + "Sponsors: Anika Bowie,
//                                                      Saura Jost, Rebecca Noecker"
//     HistoryDetail      ID=33396952 GUID=808097B7-…   "Votes (4:3) … Rebecca Noecker Yea … Anika
//                                                      Bowie Yea … Saura Jost Yea", and "Mover: Saura Jost"
// Between them they evidence exactly what the three reasonings assert — co-authorship, each
// member's own vote, and the 4-3 tally — none of which the old page could support.
//
// ⚠ HistoryDetail prints the file number as "Ord 2529", unhyphenated. It canonicalizes to the same
// token as "Ord 25-29", but the hyphenated form is carried by the LegislationDetail snippet anyway,
// which is what Bowie's `record` row needs for the gate's instrument check.
//
// No value, evidence_type or reasoning is changed. This is a re-source and nothing else.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar, sliceSnippet } from './_legistar_text.mjs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const OLD = 'https://stpaul.legistar.com/MeetingDetail.aspx?LEGID=7306&GID=125&G=EDAB5C5F-1041-4DF4-A894-59E957785E36';
const LEG = 'https://stpaul.legistar.com/LegislationDetail.aspx?ID=7282238&GUID=60463898-B948-4757-B9D9-128B514C7BDD';
const HIST = 'https://stpaul.legistar.com/HistoryDetail.aspx?ID=33396952&GUID=808097B7-59D1-42C8-B93A-81BDAB7D45CE';

const MEMBERS = [['Rebecca Noecker', 'Noecker'], ['Anika Bowie', 'Bowie'], ['Saura Jost', 'Jost']];

const build = async (url, from, to, probes) => {
  const doc = await fetchLegistar(url);
  const i = doc.page.indexOf(from);
  const j = doc.page.indexOf(to, i);
  if (i < 0 || j < 0) throw new Error('REFUSING: anchors not on ' + url);
  const end = j + to.length;
  const text = sliceSnippet(doc, i, end);
  const lower = doc.page.slice(i, end);
  if (text.toLowerCase() !== lower) throw new Error('REFUSING: case-preserving slice misaligned on ' + url);
  for (const p of probes) if (!lower.includes(p)) throw new Error('REFUSING: snippet lost "' + p + '" on ' + url);
  if (text.split(/\s+/).length < 25) throw new Error('REFUSING: under 25 words on ' + url);
  for (const [full, last] of MEMBERS) {
    const v = checkNameProximity({ fullName: full, lastName: last, pageText: doc.stripped, matchOffsetInNormalized: i });
    if (v.verdict !== 'verified') throw new Error('REFUSING: ' + full + ' is ' + v.verdict + ' on ' + url);
  }
  return text;
};

const legSnip = await build(LEG, 'ord 25-29 version: 1', 'sponsors: anika bowie, saura jost, rebecca noecker',
  ['ord 25-29', 'rent stabilization', 'sponsors: anika bowie, saura jost, rebecca noecker']);
const histSnip = await build(HIST, 'action: adopted', 'matt privratsky yea',
  ['votes (4:3)', 'rebecca noecker yea', 'anika bowie yea', 'saura jost yea']);

// Negative control: the page the rows used to cite must still FAIL, or this fix is addressing
// something that was never the problem.
{
  const doc = await fetchLegistar(OLD);
  const i = doc.page.indexOf('ord 25-29 1 34 ordinance amending chapter 193a.08');
  if (i < 0) throw new Error('control broken: the old snippet is not on the old page');
  for (const [full, last] of MEMBERS) {
    const v = checkNameProximity({ fullName: full, lastName: last, pageText: doc.stripped, matchOffsetInNormalized: i });
    if (v.verdict === 'verified') throw new Error('control broken: ' + full + ' VERIFIES on the old page — re-diagnose before replacing anything');
  }
}

const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const ev = parse(fs.readFileSync(B + '/evidence.csv'), { columns: true, skip_empty_lines: true });

const rows = [];
const evRows = [];
for (const [full] of MEMBERS) {
  const r = csv.find((x) => x.full_name === full && x.topic_key === 'rent-regulation');
  if (!r) throw new Error('no row for ' + full);
  const urls = [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean).filter((u) => u !== OLD);
  if (urls.length === [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean).length) {
    throw new Error(full + ' does not cite the old meeting URL — re-read before changing it');
  }
  // Noecker already cites two news sources, so she has one slot and takes the roll call.
  const add = urls.length >= 2 ? [HIST] : [LEG, HIST];
  const next = [...urls, ...add];
  if (next.length > 3) throw new Error(full + ' would exceed three sources');
  rows.push({ ...r, source_url_1: next[0] || '', source_url_2: next[1] || '', source_url_3: next[2] || '' });

  // Keep every existing snippet except the ones on the page being dropped.
  const kept = ev.filter((e) => e.full_name === full && e.topic_key === 'rent-regulation' && e.source_url !== OLD);
  let n = 0;
  for (const k of kept) evRows.push({ ...k, snippet_index: String(++n) });
  for (const u of add) evRows.push({ full_name: full, topic_key: 'rent-regulation', source_url: u, snippet: u === LEG ? legSnip : histSnip, snippet_index: String(++n) });
}

// Every cited URL must have a snippet, and no snippet may sit on an uncited URL.
for (const r of rows) {
  const cited = new Set([r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean));
  const mine = evRows.filter((e) => e.full_name === r.full_name);
  for (const u of cited) if (!mine.some((e) => e.source_url === u)) throw new Error('no snippet for ' + u + ' (' + r.full_name + ')');
  for (const e of mine) if (!cited.has(e.source_url)) throw new Error('snippet on an uncited URL for ' + r.full_name);
  if ([r.source_url_1, r.source_url_2, r.source_url_3].includes(OLD)) throw new Error('old URL survived on ' + r.full_name);
}

fs.writeFileSync(B + '/_rows/stpaul-ord2529-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/stpaul-ord2529-evidence.json', JSON.stringify(evRows, null, 1));
console.log('legislation snippet:', legSnip.split(/\s+/).length, 'words | history snippet:', histSnip.split(/\s+/).length, 'words');
for (const r of rows) console.log('  ', r.full_name.padEnd(16), [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean).length, 'sources |', evRows.filter((e) => e.full_name === r.full_name).length, 'snippets');
