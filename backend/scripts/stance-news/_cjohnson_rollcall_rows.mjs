// Cheniqua Johnson rent-regulation — add the roll call that evidences her Nay on Ord 25-29.
//
// Her row cited MinnPost for "the reporting places her among the members interested in restoring
// parts of the stricter policy". That snippet reads "Kim, Jalali, Yang and Johnson have all
// expressed interest…" — a bare COMMON surname with no title, so checkNameProximity declines it,
// and it should: a group attribution is not a statement by her. The page names "Cheniqua Johnson"
// only in election-result context, so no passage on it can be attributed to her.
// ▶ The citation stays, because the reasoning describes it accurately AS a group attribution. What
//   it gains is the Saint Paul action-details page, which carries "Cheniqua Johnson Nay" against
//   Ord 25-29 — the strongest claim in the row, previously uncited.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar, sliceSnippet } from './_legistar_text.mjs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const HIST = 'https://stpaul.legistar.com/HistoryDetail.aspx?ID=33396952&GUID=808097B7-59D1-42C8-B93A-81BDAB7D45CE';
const N = 'Cheniqua Johnson';

const doc = await fetchLegistar(HIST);
const i = doc.page.indexOf('action: adopted');
const tail = 'matt privratsky yea';
const end = doc.page.indexOf(tail, i) + tail.length;
const snippet = sliceSnippet(doc, i, end);
if (snippet.toLowerCase() !== doc.page.slice(i, end)) throw new Error('REFUSING: slice misaligned');
for (const p of ['votes (4:3)', 'cheniqua johnson nay']) if (!doc.page.slice(i, end).includes(p)) throw new Error('REFUSING: snippet lost ' + p);
if (snippet.split(/\s+/).length < 25) throw new Error('REFUSING: under 25 words');
const v = checkNameProximity({ fullName: N, lastName: 'Johnson', pageText: doc.stripped, matchOffsetInNormalized: i });
if (v.verdict !== 'verified') throw new Error('REFUSING: proximity for ' + N + ' is ' + v.verdict + ' — Johnson is a COMMON surname and needs the full name or a title in the window');

const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const ev = parse(fs.readFileSync(B + '/evidence.csv'), { columns: true, skip_empty_lines: true });
const r = csv.find((x) => x.full_name === N && x.topic_key === 'rent-regulation');
if (!r) throw new Error('row not found');
if (r.source_url_3) throw new Error('source_url_3 is occupied — re-read before overwriting it');

const rows = [{ ...r, source_url_3: HIST }];
const kept = ev.filter((e) => e.full_name === N && e.topic_key === 'rent-regulation');
let n = 0;
const evRows = [...kept.map((k) => ({ ...k, snippet_index: String(++n) })),
  { full_name: N, topic_key: 'rent-regulation', source_url: HIST, snippet, snippet_index: String(++n) }];

fs.writeFileSync(B + '/_rows/cjohnson-rollcall-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/cjohnson-rollcall-evidence.json', JSON.stringify(evRows, null, 1));
console.log('roll-call snippet:', snippet.split(/\s+/).length, 'words | proximity', v.verdict, '| snippets now', evRows.length);
