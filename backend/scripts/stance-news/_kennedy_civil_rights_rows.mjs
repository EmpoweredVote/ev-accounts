// Janet Kennedy — civil-rights 2, on her authorship of the Duluth human rights commission
// ordinances. Ruled by Chris Cantrell, 2026-10-06: "make it chair 2".
//
// This row was blank one commit ago, and the blank's reason was that two adjacent chairs survived:
// "strengthen the impact of the human rights-related work" (chair 2) sits in the same sentence of
// her own statement of purpose as "increase efficiency" (chair 3). The ruling reads the first as
// controlling. What the blank did NOT have, and this row does, is a citable page for either
// ordinance — see below.
//
// 🟢🟢 `Gateway.aspx?M=L&ID=<API MatterId>` 302s STRAIGHT TO THE CITABLE PAIR. The slice-3 note said
// one known ID+GUID pair had to bootstrap the rest by walking meetings → agendas, because
// `Calendar.aspx` does not expose pairs and `?ID=` alone returns a 19-byte stub. It does not: the
// gateway takes the API's MatterId — which `/matters?$filter=MatterFile eq '…'` gives for any file
// number — and redirects to `LegislationDetail.aspx?ID=<webId>&GUID=<webGuid>` in full. That makes
// EVERY Duluth matter citable, not just the ones some news story happened to link.
// 🔴 It also takes any integer and will serve a DIFFERENT matter, so `_legistar_gateway.mjs`
//    asserts the file number appears on the page it reached. Never skip that control.
//
// 🔴 THE FILE NUMBER AND THE SPONSOR NAME ARE 545 CHARACTERS APART ON A LEGISTAR HEADER, AND THE
//    NAME WINDOW IS 500. A snippet cannot start at "File #: 25-026-O" and still carry "Janet
//    Kennedy" within ±500. It does not matter here: `25-026-O` matches no pattern in
//    INSTRUMENT_IDENTIFIER_PATTERNS, so naming it in the reasoning does not oblige a snippet to
//    carry it. ⚠ `Chapter 2` DOES match, which is why no reasoning below says it.
//
// 🔴🔴 `kennedy` IS NOT IN `COMMON_LAST_NAMES`, AND THE TRACKER SAID IT WAS. Measured here:
//    `COMMON_LAST_NAMES.has('kennedy') === false` (`johnson` is true). So `checkNameProximity`
//    never demanded a title qualifier for her, on this row or on the two economic-development rows
//    whose note claims the guard is what their "5th District Councilor Janet Kennedy" snippets
//    satisfy. Those snippets are good practice; they were not being enforced. ▶ A guard you have
//    not watched fail is a guard you have not seen run — her corpus was 94% other Kennedys and the
//    verifier was never the thing catching that.
//
// Snippet starts, both measured and both asserted by checkNameProximity before anything is cut.
// Both verify by the BARE SURNAME route, since the common-surname branch does not apply to her:
//   25-026-O  @ "BY COUNCILOR KENNEDY"  — the surname is at the start itself.
//   25-033-O  @ the second rendering of the title — "Janet Kennedy" sits 429 characters earlier in
//             the sponsors line, and the body line 335 characters later reads "BY COUNCILORS AWAL
//             AND KENNEDY". ⚠ That plural would NOT satisfy the title branch if it ever applied:
//             TITLE_PATTERN matches `councilor` and not `councilors`.
// ⚠ The control fires. Proved by moving the 25-033-O start to offset 2500, where no occurrence of
//   the surname is within ±500: the verdict becomes `name_not_present`. A nearer tamper, offset
//   2039, still VERIFIES — the body line is inside that window — which is the earlier-gate-shadows
//   -a-later-one trap. A tamper that cannot trip the comparison proves nothing.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar, sliceSnippet } from './_legistar_text.mjs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const NAME = 'Janet Kennedy';

const URL_26 = 'https://duluth-mn.legistar.com/LegislationDetail.aspx?ID=7693374&GUID=F535C3F2-463E-4072-81C9-973B1C939EAC';
const URL_33 = 'https://duluth-mn.legistar.com/LegislationDetail.aspx?ID=7770940&GUID=E31ABEE4-9606-4DEC-B375-9DADBE307208';

/** Cut one contiguous run, with every control the precedent runs, and refuse rather than guess. */
async function cut(url, startAnchor, tailAnchor, must) {
  const doc = await fetchLegistar(url);
  const start = doc.page.indexOf(startAnchor.toLowerCase());
  if (start < 0) throw new Error('start anchor not on ' + url + ': ' + startAnchor);
  const t = tailAnchor.toLowerCase();
  const tIdx = doc.page.indexOf(t, start);
  if (tIdx < 0) throw new Error('tail anchor not on ' + url + ': ' + tailAnchor);
  const end = tIdx + t.length;
  const lower = doc.page.slice(start, end);
  const snippet = sliceSnippet(doc, start, end);

  for (const [what, probe] of Object.entries(must)) {
    if (!lower.includes(probe.toLowerCase())) throw new Error('REFUSING ' + url + ': the snippet no longer carries ' + what);
  }
  if (snippet.split(/\s+/).length < 25) throw new Error('snippet under 25 words: ' + url);
  if (snippet.toLowerCase() !== lower) throw new Error('REFUSING: case-preserving slice does not match the normalized one for ' + url);
  const v = checkNameProximity({ fullName: NAME, lastName: 'Kennedy', pageText: doc.stripped, matchOffsetInNormalized: start });
  if (v.verdict !== 'verified') throw new Error('REFUSING: name proximity on ' + url + ' is ' + v.verdict);
  return snippet;
}

// 25-026-O — her own ordinance, as she filed it. Runs from the authorship line through the
// amended declaration of policy, so it carries the enforceability sentence and the ground she added.
const SNIP_26 = await cut(
  URL_26,
  'BY COUNCILOR KENNEDY',
  'to support the ability of parties to resolve complaints through dispute resolution processes.',
  {
    'the authorship line': 'by councilor kennedy',
    'the repeal of the standalone commission': 'is hereby repealed in its entirety',
    'the enforceability sentence': 'enforceable through compliance actions by the city of duluth',
    'the enforcement purpose': 'mediation, conciliation and enforcement',
    'the ground she added': 'sexual orientation, gender identity, marital status',
  },
);

// 25-033-O — the follow-on she co-sponsored and the council adopted. Runs from the second rendering
// of the title through the operative sentence that gives a committee chair a vote.
const SNIP_33 = await cut(
  URL_33,
  'AN ORDINANCE REPEALING ARTICLE XXXVII (37)',
  'There shall be no more than six committee chairs.',
  {
    'the co-authorship line': 'by councilors awal and kennedy',
    'the voting-member clause': 'shall be deemed nominated as eligible to serve as voting members of the human rights commission',
  },
);

// Keep her measured corpus account verbatim; only the topic tail is rewritten.
const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const existing = csv.find((x) => x.full_name === NAME && x.topic_key === 'civil-rights');
if (!existing) throw new Error('no existing civil-rights row for ' + NAME);
const MARKER = 'so no outlet count here covers them.';
const mIdx = existing.reasoning.indexOf(MARKER);
if (mIdx < 0) throw new Error('sweep paragraph not found');
const sweep = existing.reasoning.slice(0, mIdx + MARKER.length).replace(/^Searched blank\.\s*/, '');

const REASONING =
  'Kennedy authored the restructuring of Duluth’s human rights machinery, and the ordinances are the evidence here rather than anything she told a reporter. ' +
  sweep +
  ' Her sponsorships were read from the council’s own legislative record. On 7 October 2025 she introduced, as sole author, Ordinance 25-026-O, dissolving the city’s standalone commission for nonbinary, queer, trans, two spirit, lesbian, gay, bisexual, intersex and asexual residents and re-establishing it as a standing committee inside the Duluth human rights commission, with the committee’s elected chair holding a vote on the commission itself. ' +
  'That ordinance does three things beyond moving a body. It repeals the old article in its entirety and rewrites the city’s declaration of policy, which states that the chapter is enforceable through compliance actions by the city and that its purposes are to be effectuated by providing information, education, mediation, conciliation and enforcement. It adds gender identity to the grounds on which discriminatory practices are prohibited. And it gives the new committee standing duties to advise the mayor and council, to provide research to the commission and to the human rights and equity officer, and to recommend legislation. ' +
  'That is chair 2: strengthen civil rights enforcement and address systemic discrimination. Her own statement of purpose names the aim in those terms — to strengthen the impact of the human rights-related work of the city. Chair 1 is excluded by the instrument: it mandates nothing of any institution outside the city’s own advisory structure, and sets no equity requirement on employers, contractors or schools. Chair 3 is excluded because she does not leave the law where it stands; she rewrites the operative chapter and widens the grounds it reaches. Chairs 4 and 5 are excluded outright by the direction of the whole measure. ' +
  '🔴 For the reviewer, two things that cut against a careless reading of this row. First, 25-026-O was read once and WITHDRAWN on 27 October 2025, after a colleague filed a broader ordinance covering every protected class commission; Kennedy then co-sponsored the follow-on, 25-033-O, which the council adopted on 15 December 2025 and which carries the voting-member clause into the code. So the chair rests on an authored text she withdrew plus an adopted text she co-signed, not on a single enacted ordinance of her own. Second, the gender-identity insertion reads as an expansion and is partly a conforming one: the same ordinance adopts the state human rights act definitions as they may be amended from time to time, and Minnesota added that ground in 2023. The chair does not rest on that clause alone. ' +
  '⚠ This row was blank until 6 October 2026 and the blank’s reasoning is worth knowing: her statement of purpose puts improving equity, increasing efficiency and strengthening the impact of the work in a single sentence, and the efficiency half of it is a chair 3 reading of the same consolidation. Ruled chair 2 by Chris Cantrell on 6 October 2026.';

const row = {
  full_name: NAME,
  topic_key: 'civil-rights',
  value: '2',
  evidence_type: 'record',
  reasoning: REASONING,
  source_url_1: URL_26,
  source_url_2: URL_33,
  source_url_3: '',
  quote_text: '', quote_deidentified: '', editor_note: '',
};

const evRows = [
  { full_name: NAME, topic_key: 'civil-rights', source_url: URL_26, snippet: SNIP_26, snippet_index: '1' },
  { full_name: NAME, topic_key: 'civil-rights', source_url: URL_33, snippet: SNIP_33, snippet_index: '2' },
];

// Controls on the row itself.
// 🔴 `Chapter 2` is an extracted instrument identifier. If it ever enters this reasoning it must be
//    in a snippet, or the gate raises a high finding — the same way an aside cost four of them.
const ids = row.reasoning.match(/\bChapter\s?\d+\b/g) ?? [];
for (const id of ids) {
  if (!(SNIP_26 + ' ' + SNIP_33).includes(id)) throw new Error('reasoning names "' + id + '" and no snippet carries it');
}
if (row.value !== '2') throw new Error('this row is the chair-2 ruling');
if (!/ordinance/i.test(row.reasoning)) throw new Error('record evidence must name the instrument');
for (const e of evRows) if (![row.source_url_1, row.source_url_2].includes(e.source_url)) throw new Error('evidence url not cited');

fs.writeFileSync(B + '/_rows/kennedy-civil-rights-rows.json', JSON.stringify([row], null, 1));
fs.writeFileSync(B + '/_rows/kennedy-civil-rights-evidence.json', JSON.stringify(evRows, null, 1));
console.log(`row: ${NAME}/civil-rights=${row.value} | snippets ${SNIP_26.split(/\s+/).length} + ${SNIP_33.split(/\s+/).length} words`);
