// Mike Kennedy (UT, U.S. House) — the 5 pairs deferred by the 2026-09-24 ruling, re-researched
// against the Season 2 ladders.
//
// 🔴 IDENTITY FIRST, AND IT NEARLY WENT WRONG. `kennedy.house.gov` is **Timothy M. Kennedy of New
// York**. WebFetch summarised that site's issue list — "Gun Violence Prevention", "Upholding
// Democracy and Freedoms" — as though it were this member's, with no hint it was a different
// person. The right site is `mikekennedy.house.gov`, whose title names Utah. ▶ Confirm the page
// names the member before reading a position off it.
// ⚠ His site says "Utah's 3rd District" and our race rows say District 4. Both are right: Utah's
// 2026 map renumbered. A district number is not an identity check; the name on the page is.
//
// One chair of five. The other four are searched blanks, and the search is recorded in each.
import fs from 'node:fs';
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar as fetchPage, sliceSnippet } from './_legistar_text.mjs';

const B = 'data/stance-research/2026-10-06-ut-slco-season2-repair';
const NAME = 'Mike Kennedy';

const URL_ENERGY = 'https://mikekennedy.house.gov/issues/energy';
const URL_DRILL = 'https://mikekennedy.house.gov/media/press-releases/rep-kennedys-license-drill-act-its-way-presidents-desk';

async function cut(url, startAnchor, tailAnchor, must) {
  const doc = await fetchPage(url);
  const start = doc.page.indexOf(startAnchor.toLowerCase());
  if (start < 0) throw new Error('start anchor not on ' + url + ': ' + startAnchor);
  const t = tailAnchor.toLowerCase();
  const tIdx = doc.page.indexOf(t, start);
  if (tIdx < 0) throw new Error('tail anchor not on ' + url + ': ' + tailAnchor);
  const end = tIdx + t.length;
  const lower = doc.page.slice(start, end);
  const snippet = sliceSnippet(doc, start, end);
  for (const [what, probe] of Object.entries(must)) {
    if (!lower.includes(probe.toLowerCase())) throw new Error('REFUSING ' + url + ': snippet lacks ' + what);
  }
  const words = snippet.split(/\s+/).length;
  if (words < 25) throw new Error('snippet under 25 words (' + words + '): ' + url);
  if (snippet.toLowerCase() !== lower) throw new Error('case-preserving slice does not match: ' + url);
  const v = checkNameProximity({ fullName: NAME, lastName: 'Kennedy', pageText: doc.stripped, matchOffsetInNormalized: start });
  if (v.verdict !== 'verified') throw new Error('REFUSING: name proximity on ' + url + ' is ' + v.verdict);
  return { snippet, words };
}

// 🔴 The name window is ±500 characters from the SNIPPET START. On the issues page the only
// occurrence of "Mike Kennedy" is in the masthead, ~900 characters before the position statement,
// so a snippet that starts at the statement fails proximity. The press release puts
// "said Congressman Mike Kennedy" inside his own quotation, so that is where the row is anchored.
const DRILL = await cut(
  URL_DRILL,
  'We know the effects of overreliance on foreign nations for our energy',
  'start delivering the domestic production this country needs to remain independent and secure.',
  {
    'his attribution': 'said congressman mike kennedy',
    'the all-of-the-above claim': 'america needs an all-of-the-above energy strategy',
    'the instrument': 'license to drill act',
  },
);

const ENERGY = await cut(
  URL_ENERGY,
  'Energy | Congressman Mike Kennedy',
  'and all other energy production.',
  {
    'his name': 'congressman mike kennedy',
    'the all-of-the-above approach': 'all-of-the-above energy approach that embraces american oil, natural gas, nuclear, geothermal',
  },
);

const SEARCH = 'Searched blank. His own House site was read in full — all twenty issue pages, the votes and legislation page, and every press release listed there — and ontheissues.org has no page for him. ';

const CLIMATE =
  'Kennedy states a source-neutral energy position twice, in his own words, and the instrument he carried matches it. '
  + 'On his House site he writes that he supports an all-of-the-above energy approach that embraces American oil, natural gas, nuclear, geothermal, and all other energy production, and that he is committed to cutting unnecessary regulations and streamlining permitting to strengthen domestic production. '
  + 'Announcing the License to Drill Act, which passed both chambers by unanimous consent in October 2026, he said America needs an all-of-the-above energy strategy and that the Act will streamline permitting so critical energy projects stop waiting on Washington and start delivering domestic production. '
  + 'That is chair 4: no preference among sources, with the market and the states choosing. '
  + 'Chair 1 is excluded because he proposes no mandate and no deadline on anyone. Chair 2 is excluded because he names no subsidy, tax credit or public investment in clean energy; the only federal money in his Act is a permit-fee program that pays for processing. '
  + 'Chair 3 is the closest alternative and is excluded by what the permitting reform is for: chair 3 speeds up clean energy, and the Act reauthorises the fee program for Applications for Permit to Drill, with oil and natural gas named first in his own list of what the approach embraces. '
  + 'Chair 5 is excluded because nothing he says calls for ending clean energy subsidies or mandates; geothermal and nuclear sit inside the list he endorses rather than outside it.';

const rows = [
  {
    full_name: NAME, topic_key: 'climate-change', value: '4', evidence_type: 'statement',
    reasoning: CLIMATE,
    source_url_1: URL_DRILL, source_url_2: URL_ENERGY, source_url_3: '',
    quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'social-security', value: '', evidence_type: '',
    reasoning: SEARCH + 'He has no issue page on Social Security and no press release that mentions it. Nothing in the record read here states whether he would expand benefits, raise the payroll cap, make small adjustments, reduce future benefits, or move to private accounts, and those five are what this ladder separates.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'same-sex-marriage', value: '', evidence_type: '',
    reasoning: SEARCH + 'No page or release addresses marriage. He took his seat in January 2025, after the Respect for Marriage Act, so there is no vote of his on it either. A position on religious liberty generally is not a position on what legal recognition same-sex marriages should receive.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'religious-freedom', value: '', evidence_type: '',
    reasoning: SEARCH + 'No page or release addresses how the law should balance religious freedom against anti-discrimination protection. This ladder turns on that balance — whether exemptions may override employment and housing protections — and nothing read here states where he puts it.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'civil-rights', value: '', evidence_type: '',
    reasoning: SEARCH + 'No page or release addresses racial or social inequality, civil rights enforcement, or affirmative action. This ladder asks what role government should play in addressing racial and social inequality, and no passage read here states a position on any of its five rungs.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
];

const evRows = [
  { full_name: NAME, topic_key: 'climate-change', source_url: URL_DRILL, snippet: DRILL.snippet, snippet_index: '1' },
  { full_name: NAME, topic_key: 'climate-change', source_url: URL_ENERGY, snippet: ENERGY.snippet, snippet_index: '2' },
];

// Controls.
const bad = [];
for (const r of rows) {
  if (r.value && !r.evidence_type) bad.push(r.topic_key + ': scored row with no evidence_type');
  if (!r.value && (r.source_url_1 || r.source_url_2)) bad.push(r.topic_key + ': blank row carrying a source');
  if (!r.reasoning.trim()) bad.push(r.topic_key + ': empty reasoning');
  if (/\breviewer\b|\bC\d{2}\b|[🔴⚠▶🟢✅]/u.test(r.reasoning)) bad.push(r.topic_key + ': reviewer-facing text in voter prose');
}
// Quoted phrases in reasoning must be in a snippet — this reasoning deliberately paraphrases, so
// assert there are none rather than hope.
for (const r of rows) if (/["“”]/.test(r.reasoning)) bad.push(r.topic_key + ': reasoning contains a quotation mark');
if (rows.filter((r) => r.value).length !== 1) bad.push('expected exactly one scored row');
if (bad.length) { console.error('REFUSED:\n  ' + bad.join('\n  ')); process.exit(1); }

fs.mkdirSync(B + '/_rows', { recursive: true });
fs.writeFileSync(B + '/_rows/ut-kennedy-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/ut-kennedy-evidence.json', JSON.stringify(evRows, null, 1));
console.log(`${NAME}: 1 scored (climate-change=4), 4 blanks | snippets ${DRILL.words} + ${ENERGY.words} words`);
