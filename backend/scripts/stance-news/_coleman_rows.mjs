// Molly Coleman, re-researched 2026-10-05. 0 chairs -> 2.
//
// Seated January 2026, so a documented zero was the expected and acceptable outcome. It is not what
// the record shows. Her old rows rested on 11 readable articles of the 12 named; the re-sweep gives
// 515 files, 44 naming her (her surname also returns Chris Coleman, a former mayor of this city),
// including 37 from Minnesota Reformer. 29 attributed quotes.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Molly Coleman';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 515 articles, 44 of which name Molly Coleman as a phrase. The full phrase was required rather than the surname alone, because Chris Coleman, a former mayor of this city, appears throughout the surname results. Two were set aside because they also name a different Coleman, so a bare-surname attribution in them could not be trusted, and every passage in the remaining 42 that quotes her beside a speech verb was read - 29 of them. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one. She took her seat in January 2026, so the record is short by nature.';

const chairs = [
  {
    topic_key: 'homelessness',
    value: '3',
    evidence_type: 'statement',
    urls: ['https://www.twincities.com/2026/08/04/st-paul-homeless-encampment-pigs-eye/'],
    reasoning: 'She conditions enforcement on adequate provision, which is precisely what separates this chair from the two above and the two below it. Before the Pig’s Eye and associated closures she said she did not believe the city was prepared to responsibly close the encampments the following day, that it is abundantly clear the city needs to act with deep urgency because the status quo for unsheltered residents is unacceptable, but that such urgency cannot justify policy decisions that exacerbate rather than mitigate harm. The reporting places her among the council members whose support for the closures was conditional on having enough shelter beds and other resources available to absorb the people displaced. That is chair 3: enforcement permitted only where adequate shelter exists, with people routed to services. Chairs 1 and 2 do not fit, because she does not oppose closure as such or argue for a right to remain. Chairs 4 and 5 do not fit, because she withheld support for a closure that would have proceeded without the resources to absorb residents, which is the opposite of prohibiting encampments through penalties. She separately said that saying encampments are inadequate is not enough.',
  },
  {
    topic_key: 'local-immigration',
    value: '3',
    evidence_type: 'statement',
    urls: ['https://www.twincities.com/2026/04/01/st-paul-training-separation-ordinance/'],
    reasoning: 'She authored the April 2026 ordinance strengthening how Saint Paul’s separation ordinance is carried out, and said the separation ordinance had been tested over the preceding five months like never before, and that January 2026 could not possibly have been imagined when the body passed it in April 2004. Her ordinance formalises training for all city workers and public safety employees so that, in her words, every person who works for the city understands how the separation ordinance works and what their rights and obligations are when ICE or other federal immigration enforcement officers are present; it requires department-specific training for officers on best practices for responding to calls for service involving immigration enforcement; and it develops reporting mechanisms for the public to notify the city of suspected violations, providing a pathway for accountability if the city fails to live up to its obligations. A separation ordinance is the instrument that keeps local resources out of federal immigration enforcement, and hers makes that commitment auditable. That is chair 3. Chairs 4 and 5 are excluded outright. Chair 1 is not evidenced: its distinguishing clauses are refusing all detainers and prohibiting employees from sharing immigration status information, and the reporting describes training and accountability for the existing commitments rather than either of those. Chair 2, a compliance posture turning on court-ordered detainers, is likewise not what she legislated.',
  },
];

const blanks = {
  'minimum-wage': 'She led the August 2026 amendment eliminating the ninety-day youth training wage with Nelsie Yang and HwaJeong Kim, citing basic fairness, and said it would mean young workers start at the minimum wage at a minimum, that there had been interest in revisiting it since before she joined the council, and that the notion of a seventeen-year-old and an eighteen-year-old working shoulder to shoulder for different pay is not fair. That removes a sub-minimum carve-out and raises the floor for workers aged fourteen to seventeen, which excludes the rungs that hold the floor where it is or remove it entirely. It does not choose among the three that remain, which separate on whether the floor should rise automatically with the cost of living, rise to a set level by vote, or stay modest nationally while cities set their own. This is the clearest instrument she has on any ladder and it still does not name a rung.',
  'public-safety-approach': 'She said she would vote against the federal grant application to expand the police drone programme and that it is really critical the council does not make these decisions one contract or grant at a time without a bigger understanding of how it wants to approach them. She also objected that the council was being asked to write a blank check with taxpayers’ money when it hired outside counsel. Those are positions on police technology and on procurement process. This ladder separates on the balance between the police budget and other services, and no passage states her position on police staffing, funding, co-responders or crisis teams.',
  'homelessness-response': 'Her encampment statement argues that the status quo for unsheltered residents is unacceptable and that the city must act with urgency, and that closures should not proceed without the resources to absorb residents. That is a condition on enforcement, recorded on the homelessness ladder. This ladder asks what level of public funding the response should carry, and no passage states one.',
  housing: 'No passage states a position on the role government should take in making housing affordable.',
  'rent-regulation': 'No passage quotes her on the rent stabilization cap, its exemptions or its coverage. She took her seat after the May 2025 vote on Ord 25-29.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character.',
  'growth-and-development': 'No passage states a position on the pace of growth or on whether development should wait for infrastructure capacity.',
  'economic-development': 'On two CVS properties she said the city has not owned and never intended to own the land, that it will not have legal grounds to determine what comes next, and that this is a large corporation repeatedly shown to have caused harm to the city. She also said it is an exciting time for Hamline-Midway. Those are positions on particular properties and on one company. No passage states a position on whether the city should offer incentives, to whom, or with what conditions and limits.',
  'transportation-priorities': 'No passage states a position on where transportation investment should go.',
  'local-environment': 'No passage states a position on how the city should balance development against environmental protection.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'city-sanitation': 'No passage states a position on any rung.',
  childcare: 'No passage states a position on childcare funding or provision.',
  'civil-rights': 'No passage states a position on any rung. Her remarks on the mayoral investigation concern transparency and process rather than civil-rights enforcement.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'ranked-choice-voting': 'Saint Paul elects by ranked voting under Chapter 31 of its Legislative Code and she was elected under it. No passage quotes her stating a position on whether the city should keep, extend or drop the method.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
for (const c of chairs) rows.push({ full_name: N, topic_key: c.topic_key, value: c.value, evidence_type: c.evidence_type, reasoning: c.reasoning, source_url_1: c.urls[0], source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(blanks)) rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: `Searched blank. ${SWEEP} ${v}`, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });

const evidence = [
  { full_name: N, topic_key: 'homelessness', source_url: 'https://www.twincities.com/2026/08/04/st-paul-homeless-encampment-pigs-eye/', snippet: 'Councilmember Molly Coleman released the following statement after the hearing Tuesday: "…I do not believe we are prepared to responsibly close the encampments beginning tomorrow," Coleman said. "It’s abundantly clear that we need to act with deep urgency to improve the situation of Saint Paul’s unsheltered residents, because the status quo is unacceptable. However, that urgency cannot justify policy decisions that unintentionally exacerbate, rather than mitigate, harm."', snippet_index: 0 },
  { full_name: N, topic_key: 'local-immigration', source_url: 'https://www.twincities.com/2026/04/01/st-paul-training-separation-ordinance/', snippet: '"Our separation ordinance has been tested over the last five months like never before," said City Council Member Molly Coleman. "… Suffice it to say … that January 2026 cannot possibly have been imagined when the separation ordinance was passed by this body in April 2004."', snippet_index: 0 },
];

let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: ${words} words`); bad++; }
  // 🔴 "Coleman" alone will not verify — a former mayor of this city shares it. Require the full name.
  if (!/Molly Coleman/.test(e.snippet)) { console.error(`🔴 ${e.topic_key}: snippet lacks her full name`); bad++; }
  if (!row || ![row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url)) { console.error(`🔴 ${e.topic_key}: url not among sources`); bad++; }
}
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/coleman-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/coleman-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
