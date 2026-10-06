// Duluth resolution 26-0100R — shared evidence for every member who sponsored it.
//
// 🔴🔴 THIS INSTRUMENT WAS INVISIBLE TO EVERY TOOL THIS SLICE HAS USED.
//  - `divided_votes.mjs` cannot see it: the council adopted it without a divided roll call, so it
//    is not among the 31 divided matters any member's vote list reports.
//  - The news sweeps cannot see it: no article in any of the nine Duluth corpora NAMES its sponsors.
//    MinnPost says only "four of their colleagues", and WDIO's agenda piece names neither.
//  - Nobody in this programme had ever called `/matters/{id}/sponsors`. Authorship is a separate
//    evidence channel from voting, and C37 says sponsorship evidences the instrument as filed.
//
// 🟢 AND THE PAGE IS CITABLE, WHICH instruments.md SAYS IT IS NOT. That note records "the detail
// page returns a 19-byte 200". Measured here: the 19 bytes are what you get from the ID-ONLY URL,
// or from an ID that does not match the GUID. WITH the matching GUID the same page serves ~116 KB
// including the sponsor list and the full operative text, to curl AND to node's fetch.
//     ID only                -> 200, 19 bytes
//     ID + matching GUID     -> 200, 116,377 bytes
// That correction unlocks record citations for the whole Duluth slice, not just this row.
import { checkNameProximity } from '../../src/lib/researchVerifier.js';
import { fetchLegistar, sliceSnippet } from './_legistar_text.mjs';

export const URL_26_0100R = 'https://duluth-mn.legistar.com/LegislationDetail.aspx?ID=7864734&GUID=B105F04C-45ED-4AC9-B451-9E69CD2774D2';

// One contiguous run that carries, in this order: the file number (so the gate's
// instrument-not-cited check is satisfied), the full title, all four sponsors in FULL NAME form,
// and the operative resolved clauses. It starts at the SECOND occurrence of the file number,
// which is the only start point that puts "Jordon Johnson" inside the +/-500 character name
// window — Johnson is a COMMON_LAST_NAME, and the body's "BY COUNCILORS JOHNSON" does not help
// because TITLE_PATTERN matches "councilor" and not the plural "councilors".
export async function buildSnippet() {
  const doc = await fetchLegistar(URL_26_0100R);
  const start = doc.page.indexOf('26-0100r', 100);
  const tail = 'to assist in or otherwise facilitate the enforcement of federal civil immigration laws.';
  const end = doc.page.indexOf(tail, start);
  if (start < 0 || end < 0) throw new Error('26-0100R anchors not on the page — re-read it before trusting this row');
  const lower = doc.page.slice(start, end + tail.length);
  const snippet = sliceSnippet(doc, start, end + tail.length);   // original case; see _legistar_text.mjs

  // Controls. Each is a thing the row asserts; if the page stops saying it, refuse the row.
  const must = {
    'the file number': '26-0100r',
    'all four sponsors': 'sponsors: jordon johnson , terese tomanek , diane desotelle , lynn nephew',
    'the no-enforcement clause': 'will not enforce or operate its programs for the purpose of enforcing federal civil immigration laws',
    'the city-resources clause': 'shall not use city resources',
    'the federal-law carve-out': 'except as required by federal law or court order',
  };
  for (const [what, probe] of Object.entries(must)) {
    if (!lower.includes(probe)) throw new Error('REFUSING: the snippet no longer carries ' + what);
  }
  if (snippet.split(/\s+/).length < 25) throw new Error('snippet under 25 words');
  if (snippet.toLowerCase() !== lower) throw new Error('REFUSING: case-preserving slice does not match the normalized one');

  // Every sponsor this snippet is used for must pass the verifier's own proximity check.
  for (const [full, last] of [['Jordon Johnson', 'Johnson'], ['Terese Tomanek', 'Tomanek'], ['Diane Desotelle', 'Desotelle'], ['Lynn Marie Nephew', 'Nephew']]) {
    const v = checkNameProximity({ fullName: full, lastName: last, pageText: doc.stripped, matchOffsetInNormalized: start });
    if (v.verdict !== 'verified') throw new Error('REFUSING: name proximity for ' + full + ' is ' + v.verdict);
  }
  return snippet;
}

// The chair argument, identical for every sponsor because it rests on the instrument they all signed.
export const CHAIR_3_REASONING =
  'Duluth resolution 26-0100R states this chair in the city’s own words, and the sponsors signed it. It was introduced on 30 January 2026 and adopted on 9 February 2026, by Councilors Johnson, Tomanek, Desotelle and President Nephew. It resolves that although the federal government has the legal authority to enforce immigration laws, the city of Duluth will not enforce or operate its programs for the purpose of enforcing federal civil immigration laws, and that except as required by federal law or court order, city agencies, departments, officers, employees or agents shall not use city resources, including monies, equipment, personnel, or city facilities, buildings or property, to assist in or otherwise facilitate the enforcement of federal civil immigration laws. That is chair 3 clause for clause: follow federal law where it is required, and keep local resources out of proactive immigration enforcement. ' +
  'Chair 1 is excluded by the document itself rather than by inference. Chair 1 would prohibit local employees from sharing immigration status information with federal agencies, and this resolution expressly provides that nothing in it shall be construed to prohibit any city department or employee from complying with 8 U.S.C. 1373, which is the federal statute that bars exactly such restrictions. It also preserves responses to a properly issued subpoena, and preserves public safety personnel assisting federal officers investigating criminal activity. A city at chair 1 does not write those carve-outs. Chair 2 is a detainer-compliance posture and this instrument addresses the use of city resources, not detainers. Chairs 4 and 5 are excluded outright by a measure that refuses to put city resources behind enforcement. ' +
  '🔴 The vote is deliberately not relied on. The council adopted 26-0100R without a divided roll call, so C46 would refuse the vote as a position. This row rests on sponsorship, which evidences the instrument as filed (C37) - and the operative text here is the text that passed. ' +
  'For the reviewer: a companion ordinance codified the same policy into the city code on 23 February 2026 and was authored by Councilor Randorf alone. Her row on this ladder has not been changed in this pass, because that ordinance’s Legistar detail page could not be resolved to a citable URL - the numeric id must match the GUID or the page serves a 19-byte stub - so its text can be read and not cited. Resolving that URL is the one thing that would settle her row.';
