// Traci Crockett (Salt Lake County Council District 5 candidate) — the 8 pairs deferred 2026-09-24,
// re-researched against the Season 2 local ladders. Her campaign site is the source; it is the URL
// already stored on her politician row.
//
// 🔴 HER NAME APPEARS AT OFFSET 15 AND THEN NOT AGAIN UNTIL 18,901. The issues page states every
// position in the body and never repeats her name there, so a snippet cut at the position fails the
// ±500 name window. The scored row therefore carries ONE long contiguous run from the top of the
// page through the housing section — the same shape the MN slice used for a questionnaire whose
// name sits at the head of the section. It is long for a reason and says so.
//
// One chair of eight. Seven blanks, each naming what the ladder separates on and what her page does
// not say. Her site states priorities and directions across all eight subjects; a direction is not
// a rung.
import fs from 'node:fs';
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar as fetchPage, sliceSnippet } from './_legistar_text.mjs';

const B = 'data/stance-research/2026-10-06-ut-slco-season2-repair';
const NAME = 'Traci Crockett';
const URL = 'https://www.traci4countycouncil.com/issues/';

const doc = await fetchPage(URL);
const start = doc.page.indexOf('issues | traci crockett for county council');
const tail = 'promote fair, predictable housing policies that protect both renters and property owners';
const tIdx = doc.page.indexOf(tail, start);
if (start < 0 || tIdx < 0) throw new Error('anchors not on the page — re-read it before trusting this row');
const end = tIdx + tail.length;
const lower = doc.page.slice(start, end);
const SNIP = sliceSnippet(doc, start, end);

for (const [what, probe] of Object.entries({
  'her name': 'traci crockett',
  'the free-market clause': 'empower the free market',
  'the red-tape clause': "the county's role is to work with cities to remove red tape",
  'the zoning caveat': 'respecting local zoning and neighborhood character',
})) {
  if (!lower.includes(probe)) throw new Error('REFUSING: the snippet no longer carries ' + what);
}
if (SNIP.split(/\s+/).length < 25) throw new Error('snippet under 25 words');
if (SNIP.toLowerCase() !== lower) throw new Error('case-preserving slice does not match the normalized one');
const v = checkNameProximity({ fullName: NAME, lastName: 'Crockett', pageText: doc.stripped, matchOffsetInNormalized: start });
if (v.verdict !== 'verified') throw new Error('REFUSING: name proximity is ' + v.verdict);

const SEARCHED = 'Searched blank. Her campaign site was read in full, including the issues page, which states a position under eight headings. ';

const rows = [
  {
    full_name: NAME, topic_key: 'housing', value: '5', evidence_type: 'statement',
    reasoning:
      'Crockett states the market position in her own words and names no instrument of the kinds the other four rungs require. '
      + 'On her campaign site she writes that the county’s role is to work with cities to remove red tape while preserving neighborhood character, that she will fight state or federal mandates, and, as a heading of its own, that she will empower the free market. '
      + 'That is chair 5: leave prices and supply to the market, and at most cut the regulation that blocks private building. '
      + 'Chairs 1 and 2 are excluded outright — she proposes no public housing of any size and describes open-ended government programs as something she does not believe in. '
      + 'Chair 3 is excluded because it requires binding rules on the private market, such as rent caps or required affordable units, and she commits instead to fighting mandates; the nearest thing she offers is housing policy that is fair and predictable for renters and owners alike, which is a standard of process rather than a binding rule. '
      + 'Chair 4 is excluded because she names no subsidy and no tax break for affordable building anywhere on the site. '
      + 'One qualification a reader should weigh: chair 5 names cutting zoning limits, and she couples her red-tape pledge to respecting local zoning and neighborhood character, so the regulation she would cut is process rather than density.',
    source_url_1: URL, source_url_2: '', source_url_3: '',
    quote_text: '', quote_deidentified: '', editor_note: '',
  },
  { full_name: NAME, topic_key: 'residential-zoning', value: '', evidence_type: '',
    reasoning: SEARCHED + 'This ladder separates on density: whether to oppose increases, allow duplexes and accessory units, allow multifamily near commercial corridors, upzone broadly, or end single-family-only zoning. She writes that she will preserve neighborhood character, respect local zoning and fight statewide mandates, and also that she will support housing options that meet community needs and encourage responsible development that addresses affordability. Those are claims about who decides and about process, and together they do not name a density level.' },
  { full_name: NAME, topic_key: 'growth-and-development', value: '', evidence_type: '',
    reasoning: SEARCHED + 'She writes that growth should not outmatch infrastructure, that the county should plan ahead and invest so infrastructure keeps pace, and that she will push back on development that does not make sense. The first and third of those point at making development wait for capacity, which is chair 2; the second points at investing ahead of demand so expansion is not held back, which is chair 3. The page does not choose between them.' },
  { full_name: NAME, topic_key: 'transportation-priorities', value: '', evidence_type: '',
    reasoning: SEARCHED + 'She writes that she will prioritise well-maintained roads and sidewalks, reduce congestion through planning and regional coordination, and support safe, efficient transportation options while keeping roads functional for drivers. Maintaining roads while adding other options is chair 3; treating investment as something that should serve the majority who drive is chair 4. Her sentence contains both halves and settles neither, and she does not state the condition chair 3 turns on, which is adding transit where density supports it.' },
  { full_name: NAME, topic_key: 'local-environment', value: '', evidence_type: '',
    reasoning: SEARCHED + 'This ladder asks how the community should balance new development against environmental preservation. Her conservation section commits to protecting natural resources without overregulation or one-size-fits-all policies, to planning for long-term water availability, and to preserving open spaces and trails. It is about stewardship and does not address the trade-off with development, which is what the five rungs separate on.' },
  { full_name: NAME, topic_key: 'economic-development', value: '', evidence_type: '',
    reasoning: SEARCHED + 'Every rung of this ladder is a position on business incentives — whether to offer none, to help local firms but not court outside ones, to attach wage and hiring conditions, to offer large breaks with limits, or to offer the largest with none. Her economic section is about clear and predictable policy, reducing burdens on local employers and keeping business districts safe and welcoming. It never mentions an incentive, a tax break or a subsidy.' },
  { full_name: NAME, topic_key: 'homelessness', value: '', evidence_type: '',
    reasoning: SEARCHED + 'This ladder is about enforcement: whether public sleeping is protected, decriminalised, enforced only where shelter exists, prohibited with civil penalties, or banned with criminal ones. She commits to treatment, accountability and pathways to stability, to working with city and state partners, and to balancing compassion with the cleanliness and accessibility of shared spaces. That is a position on services and does not name any enforcement rung.' },
  { full_name: NAME, topic_key: 'climate-change', value: '', evidence_type: '',
    reasoning: SEARCHED + 'The site says nothing about energy. This ladder asks how much government should do to expand clean energy, and no passage addresses mandates, subsidies, permitting, the grid, or market neutrality among sources.' },
];

for (const r of rows) {
  if (!r.value) { r.evidence_type = ''; r.source_url_1 = ''; r.source_url_2 = ''; r.source_url_3 = ''; r.quote_text = ''; r.quote_deidentified = ''; r.editor_note = ''; }
}

const evRows = [{ full_name: NAME, topic_key: 'housing', source_url: URL, snippet: SNIP, snippet_index: '1' }];

const bad = [];
for (const r of rows) {
  if (!r.reasoning.trim()) bad.push(r.topic_key + ': empty reasoning');
  if (/\breviewer\b|\bC\d{2}\b|[🔴⚠▶🟢✅]/u.test(r.reasoning)) bad.push(r.topic_key + ': reviewer-facing text');
  if (/["“”]/.test(r.reasoning)) bad.push(r.topic_key + ': quotation mark in reasoning');
  if (/\bconservative\b|\brepublican\b|\bdemocrat/i.test(r.reasoning)) bad.push(r.topic_key + ': party or party label in reasoning');
}
if (rows.filter((r) => r.value).length !== 1) bad.push('expected exactly one scored row');
if (rows.length !== 8) bad.push('expected 8 rows');
if (bad.length) { console.error('REFUSED:\n  ' + bad.join('\n  ')); process.exit(1); }

fs.mkdirSync(B + '/_rows', { recursive: true });
fs.writeFileSync(B + '/_rows/ut-crockett-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/ut-crockett-evidence.json', JSON.stringify(evRows, null, 1));
console.log(`${NAME}: 1 scored (housing=5), 7 blanks | snippet ${SNIP.split(/\s+/).length} words, name verdict ${v.verdict}`);
