// Roz Randorf — local-immigration 3. The row the last pass had to leave as readable-and-not-citable.
//
// 🟢 THE WEB GUID IS FOUND, AND THE ROUTE TO IT GENERALISES.
// A Legistar LegislationDetail page lists, under History, the MeetingDetail links for every meeting
// the matter appeared at — WITH their own ID+GUID pairs. A MeetingDetail page then lists every
// matter on that agenda, each as a LegislationDetail link carrying ITS ID+GUID. So one known pair
// bootstraps the rest:
//     26-0100R (pair from a MinnPost hyperlink)
//       -> MeetingDetail 1381311 / 75A5A26D-…   (the 2026-02-23 council meeting)
//         -> 26-005-O = ID 7869631 / GUID B9A84056-7F2A-4E7A-ADD4-B55A575AF296
// ▶ `Calendar.aspx` does not expose the pairs, but ANY one matter page does. That is the scripted
//   route instruments.md said did not exist.
//
// 🔴 THE HEADER SNIPPET MISSES NAME PROXIMITY BY ONE CHARACTER, AND THAT IS NOT A TYPO.
// checkNameProximity windows [start-500, start+500]. The file number sits at 246 and "randorf"
// spans 740..746, so the window `slice(0, 746)` cuts the final letter. Starting at 247 verifies and
// would begin mid-number. So this row carries TWO snippets off the one page: the header, which is
// verbatim and carries the file number the gate needs; and the body, which verifies and carries the
// operative text. Both are cut from the page, neither is composed.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar, sliceSnippet } from './_legistar_text.mjs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Roz Randorf';
const URL_26_005_O = 'https://duluth-mn.legistar.com/LegislationDetail.aspx?ID=7869631&GUID=B9A84056-7F2A-4E7A-ADD4-B55A575AF296';

const doc = await fetchLegistar(URL_26_005_O);
const { page, stripped } = doc;

// `text` is the stored snippet, in the page's own case. `lower` is what the controls read.
const cut = (from, to, fromIdx = 0) => {
  const i = page.indexOf(from, fromIdx);
  const j = page.indexOf(to, i);
  if (i < 0 || j < 0) throw new Error('REFUSING: anchor not on the page — re-read 26-005-O before trusting this row: ' + from);
  const end = j + to.length;
  const text = sliceSnippet(doc, i, end);
  const lower = page.slice(i, end);
  if (text.toLowerCase() !== lower) throw new Error('REFUSING: case-preserving slice does not match the normalized one');
  return { text, lower, start: i };
};

const header = cut('26-005-o', 'sponsors: roz randorf', 100);
const body = cut('by councilor randorf', 'at maritime, aviation, or international transit facilities.');

// Controls — each is a thing this row asserts.
const must = {
  'the file number': [header, '26-005-o'],
  'the sole sponsor': [header, 'sponsors: roz randorf'],
  'the authorship line': [body, 'by councilor randorf'],
  'the no-enforcement clause': [body, 'will not act or operate its programs for the purpose of enforcing civil federal immigration laws'],
  'the city-resources prohibition': [body, 'shall not use city resources'],
  'the required-by-law carve-out': [body, 'other than when required by law'],
  'the data-sharing clause': [body, 'shall not share private or nonpublic data with federal immigration authorities'],
  'the 1373 exemption': [body, '1373'],
  'the criminal-investigation carve-out': [body, 'assisting federal law enforcement officers in the investigation of criminal activity'],
};
for (const [what, [snip, s]] of Object.entries(must)) {
  if (!snip.lower.includes(s)) throw new Error('REFUSING: the page no longer carries ' + what);
}
for (const [label, snip] of [['header', header], ['body', body]]) {
  if (snip.text.split(/\s+/).length < 25) throw new Error(label + ' snippet under 25 words');
}
// The body snippet is the one that must verify. Assert it, rather than hope.
const v = checkNameProximity({ fullName: N, lastName: 'Randorf', pageText: stripped, matchOffsetInNormalized: body.start });
if (v.verdict !== 'verified') throw new Error('REFUSING: body snippet name proximity is ' + v.verdict);

// Keep her measured sweep paragraph verbatim.
const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const existing = csv.find((x) => x.full_name === N && x.topic_key === 'local-immigration');
if (!existing) throw new Error('no existing row');
const mk = 'so no outlet count here covers them.';
const i = existing.reasoning.indexOf(mk);
if (i < 0) throw new Error('sweep paragraph not found');
const SWEEP = existing.reasoning.slice(0, i + mk.length).replace(/^Searched blank\.\s*/, '');

const reasoning = 'Randorf is the sole author of Duluth ordinance 26-005-O, which codified the city’s immigration-enforcement policy into Article XXXIX of Chapter 2 of the city code. It was introduced on 5 February 2026 and adopted on 23 February 2026, and the enacted text opens "BY COUNCILOR RANDORF". ' + SWEEP +
  ' The ordinance states this chair in its operative sections, not in its recitals. Section 2-195 provides that although the federal government has the legal authority to enforce immigration laws in the United States, in Minnesota and in the city, the city of Duluth will not act or operate its programs for the purpose of enforcing civil federal immigration laws. Section 2-196(c) provides that other than when required by law, city employees, officers or agents shall not use city resources, including city facilities, buildings, property, monies or equipment, to assist in or otherwise facilitate the enforcement of federal civil immigration laws. That is chair 3 clause for clause: follow federal law where it is required, and keep local resources out of proactive immigration enforcement. ' +
  '🔴 Chair 1 is excluded by the ordinance in the sharpest way available, because this text addresses information sharing directly rather than passing over it. Chair 1 would prohibit local employees from sharing immigration status information with federal agencies. Section 2-196(d) bars employees from sharing private or nonpublic data with federal immigration authorities to facilitate enforcement - and then exempts data subject to 8 U.S.C. 1373 and 1644, which are the federal provisions governing the exchange of citizenship and immigration status information. The ordinance restricts data sharing in general and carves out precisely the category chair 1 names. It also preserves compliance with judicial subpoenas, the completion and audit of I-9 forms, joint task force duties, assisting federal officers investigating criminal activity, and federal agencies working at maritime, aviation and international transit facilities. ' +
  'Chair 2 is a detainer-compliance posture; this ordinance contains no detainer provision at all. Chairs 4 and 5 are excluded outright by a measure that forbids city resources being put behind enforcement. ' +
  'The vote is not relied on. The council adopted 26-005-O unanimously by voice vote, which C46 refuses as a position for any member, and that is why an earlier pass recorded this ladder as blank for her. This row rests on sole authorship, which evidences the instrument as filed (C37), and the text quoted above is the text that passed. ' +
  'Her four colleagues who sponsored the companion resolution a fortnight earlier hold the same chair on the same reasoning. Randorf did not sign that resolution; she wrote the ordinance that codified it.';

const rows = [{
  full_name: N, topic_key: 'local-immigration', value: '3', evidence_type: 'record',
  reasoning, source_url_1: URL_26_005_O, source_url_2: '', source_url_3: '',
  quote_text: '', quote_deidentified: '', editor_note: '',
}];
const evRows = [
  { full_name: N, topic_key: 'local-immigration', source_url: URL_26_005_O, snippet: header.text, snippet_index: '1' },
  { full_name: N, topic_key: 'local-immigration', source_url: URL_26_005_O, snippet: body.text, snippet_index: '2' },
];

if (!reasoning.includes('26-005-O')) throw new Error('reasoning must name the instrument');
if (!header.lower.includes('26-005-o')) throw new Error('no snippet carries the instrument number');

fs.writeFileSync(B + '/_rows/randorf-immigration-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/randorf-immigration-evidence.json', JSON.stringify(evRows, null, 1));
console.log('header snippet:', header.text.split(/\s+/).length, 'words (start', header.start + ', carries the file number)');
console.log('body snippet  :', body.text.split(/\s+/).length, 'words (start', body.start + ', proximity', v.verdict + ')');
