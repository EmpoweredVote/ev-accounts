// Blake Moore (UT, U.S. House) — the 4 surviving pairs of the 5 deferred on 2026-09-24.
// `immigration` is not among them: it was retired in Season 2 and the write gate refuses it.
//
// 🔴🔴 ALL FOUR ARE BLANKS, AND ONE OF THEM IS NOT A RESEARCH FAILURE — IT IS A CITATION FAILURE.
// His vote on the Respect for Marriage Act is established, divided, and inside his tenure. It
// cannot be cited from anything reachable here, so under the rule that a position which can be
// read but not cited does not publish, it is recorded as a blank that names what would settle it.
//
// What was searched, and what it gave:
//  - blakemoore.house.gov has NO position pages. `/issues` and `/issues/topics` are 1,886-character
//    navigation shells and every issue sub-path returns 410 Gone. His 2022 press-release archive
//    and his accomplishments page mention none of these four subjects.
//  - clerk.house.gov roll-call records ARE reachable (the modern `/evs/<year>/index.asp` index is a
//    soft 404 — status 404 with a 254 KB body — but `/evs/<year>/roll<NNN>.xml` serves the real
//    record). Roll Call 513 of 2022 is H R 8404, the Respect for Marriage Act, 8 December 2022,
//    "On Motion to Concur in the Senate Amendment", totals 258-169-1-4, and it records
//    `Moore (UT)` `Yea`.
//  - 🔴 THE CLERK NEVER WRITES A MEMBER'S FULL NAME. Both the XML and the HTML vote page render him
//    as "Moore (UT)". `moore` is in COMMON_LAST_NAMES, so checkNameProximity demands a title
//    qualifier within 30 characters, and the surrounding text is "Moore (AL) Republican Alabama AL
//    Nay Moore (UT) Moore (UT) Republican Utah UT Yea" — no title anywhere near it. The snippet
//    cannot verify.
//  - govtrack.us, which does print full names, is unreachable: node's fetch fails at the TLS layer
//    and curl times out at 60s with zero bytes.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-06-ut-slco-season2-repair';
const NAME = 'Blake Moore';

const SEARCHED = 'Searched blank. His official House site carries no position pages — the issues index and topics page are navigation shells and every issue sub-page is gone — and neither his 2022 press-release archive nor his accomplishments page mentions this subject. ';

const rows = [
  {
    full_name: NAME, topic_key: 'same-sex-marriage', value: '', evidence_type: '',
    reasoning: SEARCHED
      + 'His recorded vote was found and it is not blank for want of a position. On 8 December 2022 the House voted on the motion to concur in the Senate amendment to the Respect for Marriage Act, by 258 to 169 with 1 present and 4 not voting, and the clerk of the House records him voting Yea. He took his seat in January 2021, so the vote is his to answer for, and the margin is wide enough to count as a division. '
      + 'That record points at chair 3 rather than chair 2, because the Act both recognises these marriages and expressly provides that nonprofit religious organisations are not required to provide services or facilities for the solemnisation or celebration of a marriage — the religious protection is exactly what separates those two rungs. '
      + 'The row stays blank for a different reason: the position can be read and not cited. The clerk records every member by surname and state, never in full, so the only pages carrying this vote identify him as Moore of Utah; Moore is a common surname, and the verifier will not attribute a passage to him without his full name or a title beside it, neither of which appears. '
      + 'What would settle it is one fetchable page that names him in full beside this vote — a statement of his own, or Utah reporting on the vote.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'deportation', value: '', evidence_type: '',
    reasoning: SEARCHED
      + 'This ladder asks how far the government should go in deporting undocumented immigrants, and it separates on who is prioritised and on what due process applies. No passage read here states where he stands on that, and a border-security heading in a navigation menu is a subject, not a rung. '
      + 'What would settle it is a recorded vote on a removal or enforcement measure, cited from a page that names him in full.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'school-vouchers', value: '', evidence_type: '',
    reasoning: SEARCHED
      + 'Nothing read here states a position on directing public money to private or home schooling, which is what this ladder separates. His site has no education page at all. '
      + 'What would settle it is a vote or a statement on a federal scholarship or education savings measure, cited from a page that names him in full.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
  {
    full_name: NAME, topic_key: 'trans-athletes', value: '', evidence_type: '',
    reasoning: SEARCHED
      + 'Nothing read here states a position on who may compete in school or college sport, which is what this ladder separates. '
      + 'What would settle it is his recorded vote on a federal sports-eligibility measure, cited from a page that names him in full.',
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  },
];

const bad = [];
for (const r of rows) {
  if (r.value) bad.push(r.topic_key + ': expected a blank');
  if (!r.reasoning.trim()) bad.push(r.topic_key + ': empty reasoning');
  if (r.source_url_1) bad.push(r.topic_key + ': blank row carrying a source');
  if (/\breviewer\b|\bC\d{2}\b|[🔴⚠▶🟢✅]/u.test(r.reasoning)) bad.push(r.topic_key + ': reviewer-facing text in voter prose');
  if (/["“”]/.test(r.reasoning)) bad.push(r.topic_key + ': reasoning contains a quotation mark but cites no snippet');
}
if (rows.length !== 4) bad.push('expected 4 rows');
if (bad.length) { console.error('REFUSED:\n  ' + bad.join('\n  ')); process.exit(1); }

fs.mkdirSync(B + '/_rows', { recursive: true });
fs.writeFileSync(B + '/_rows/ut-moore-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/ut-moore-evidence.json', JSON.stringify([], null, 1));
console.log(`${NAME}: 0 scored, 4 blanks (same-sex-marriage blank records an established, uncitable Yea on the Respect for Marriage Act)`);
