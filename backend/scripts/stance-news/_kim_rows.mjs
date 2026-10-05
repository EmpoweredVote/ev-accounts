// HwaJeong Kim, re-researched 2026-10-05. 0 chairs -> 1.
//
// 🔴 HER THIN YIELD WAS THE TOOLING, FOUR TIMES OVER, and the checks are worth recording because
// every one of them produced a confident wrong number first:
//   1. The sweep under the database spelling alone found 8 articles; the newsroom's "Hwa Jeong Kim"
//      found 27. The re-sweep ran both: 479 files, 44 naming her.
//   2. attribute_quotes run without the alt spelling gated out 24 of her 44 articles as "not about
//      her". 5 quotes -> 11.
//   3. nameRe regex-ESCAPED the alternation attribute_quotes built, so the alt spelling was inert
//      in the matcher and every match quietly fell back to the bare surname. Fixed: 11 -> 13.
//   4. `Added Council Member HwaJeong Kim, "…"` — an inverted tag, verb BEFORE the name — was not
//      matched at all. Fixed.
// And a fifth that no fix reaches: her strongest homelessness passage is attributed with a PRONOUN
// after the subject was established ("…she said, pointing to more permanent supportive housing").
// quoted_passages.mjs is how that was read. It is not citable: her full name sits 6,197 characters
// away and "Kim" is a common surname, so the verifier needs a title qualifier within 30 characters.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'HwaJeong Kim';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer were run under BOTH spellings of her name, "HwaJeong Kim" as our records hold it and "Hwa Jeong Kim" as the newsrooms print it, because the first alone finds less than a third of her coverage. They returned 479 articles, 44 of which name her. One was set aside because it also names a different Kim, and every passage in the remaining 43 that quotes her beside a speech verb was read - 13 of them - together with the passages where a reporter attributes her by pronoun after naming her earlier, which the strict rule does not catch. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one.';

const chairs = [
  {
    topic_key: 'housing',
    value: '4',
    evidence_type: 'statement',
    urls: ['https://www.twincities.com/2026/04/27/st-paul-2-developers-pitch-affordable-housing-on-jackson-street/'],
    reasoning: 'She states the general position and backs the instrument that matches it. At the April 2026 presentation of two proposals for affordable housing on Jackson Street she said she could not be more supportive of the project, noting the land had been vacant for decades, and said that when people raise property taxes the first thing she tells them is that the city has to build, and that it needs more people invested in the city in that way. The instrument is described in the same report: land owned by the Housing and Redevelopment Authority is offered to private developers to build units targeted at thirty, fifty and sixty percent of area median income, with twelve units for very low-income residents with disabilities backed by the federal Section 811 programme. That is public land and public subsidy used to get affordable housing built by others, which is chair 4. Chairs 1 and 2 do not fit, because the city is not building or operating the housing. Chair 5 does not fit, because this is not the market left to itself with regulations cut. The reviewer should weigh one qualification: chair 4 opens by setting no binding rules on the private market, and she voted to put the Right to Repair tenant ordinance on the ballot, which is a binding rule. That measure concerns repairs and habitability rather than the price or supply of housing, so it does not establish a rent-cap or inclusionary position, and chair 3 is not evidenced.',
  },
];

const blanks = {
  'rent-regulation': 'She voted to place the Right to Repair ordinance on the November 2026 ballot, one of only two members to do so, and said that there are ways that on the front end we think the sky is going to fall and in the end it ends up being OK. Right to Repair lets tenants act on unmade repairs; it is a habitability measure and not a rent measure. Every rung of this ladder turns on the price of rent - expanding rent control, strengthening stabilization, maintaining current protections, limiting regulation to subsidised units, or opposing control. No passage quotes her on the cap, its exemptions or its coverage.',
  homelessness: 'She said she disagrees that the city’s only role should be enforcement in addressing homelessness, which excludes the two rungs that prohibit encampments through civil penalties or ban camping with criminal penalties. It does not choose among the remaining three, which separate on protecting sleeping in public with no penalties, decriminalising it, or enforcing only where adequate shelter is available with citations diverting people to services. She also brokered an agreement with city leadership at the Pig’s Eye closure to keep heavy machinery out of the camp and to give residents time to move their belongings, which is an intervention in how a clearance was carried out rather than a position on whether clearances should happen.',
  'homelessness-response': 'Ahead of further encampment closures she said adding emergency shelter beds alone cannot be the solution, asked what other housing options the city can offer if what it is offering is not good, and pointed to more permanent supportive housing and wraparound services. On the 2027 budget she said that in lieu of government entities like the state and county there are community members and organisations more than willing to help fill gaps in the short term, and that the response has to be regional. Those are positions about what the response should consist of and about which level of government should pay, and this ladder asks what level of funding the community itself should carry. The short-term gap-filling she describes is explicitly a stopgap pending state and county resources, which is not the same as the rung where limited public funding has nonprofits lead the response. Her clearest statement here is also not citable: she is attributed in it by pronoun after being named six thousand characters earlier, and her surname is common enough that the verifier requires a title beside it.',
  'minimum-wage': 'With Molly Coleman and Nelsie Yang she proposed eliminating the ninety-day youth training wage, which stood at $13.95 against $16.37 for other employers, and the council adopted the amendment in August 2026 to take effect on 1 January. That removes a sub-minimum carve-out and raises the floor for workers aged fourteen to seventeen, which excludes the rungs that hold the floor where it is or remove it entirely. It does not choose among the three that remain, which separate on whether the floor should rise automatically with the cost of living, rise to a set level by vote, or stay modest nationally while cities set their own. The quotations reported in that story on basic fairness and on fair pay for fair work are Coleman’s, not hers.',
  'public-safety-approach': 'She opposed the city’s Flock camera contract and said she had even greater concerns about rapidly expanding artificial-intelligence-powered mass surveillance, and she said she would vote against the federal grant application to expand the police drone programme and moved to delay that vote to gather more information. Those are positions on police technology and data privacy. This ladder separates on the balance between the police budget and other services, and no passage states her position on police staffing, police funding, co-responders or crisis teams.',
  'economic-development': 'Her remarks on the city budget concern finding savings and the burden on residents who are pinching pennies, rather than business incentives. No passage states a position on whether the city should offer incentives, to whom, or with what conditions and limits.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character. Her support for one affordable housing development on Housing and Redevelopment Authority land is about what gets built on a specific public site and names no zoning instrument.',
  'growth-and-development': 'She said the city has to build and needs more people invested in it in that way. That is a supply argument about housing rather than a position on the pace of growth or on whether development should wait for infrastructure capacity.',
  'local-immigration': 'No passage quotes her on detainers, on information sharing, or on the use of local police for immigration enforcement. She is reported among council members hearing from immigrant business owners about the impacts of a federal enforcement surge, which is a report of constituent contact rather than a position.',
  'transportation-priorities': 'She noted that ample parking would matter at one development because Jackson Street will lose parking on one side when a bike lane is added. That is an observation about one site. It does not choose between prioritising transit, cycling and pedestrian infrastructure, investing equally, or focusing on road capacity.',
  'local-environment': 'No passage states a position on how the city should balance development against environmental protection.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'city-sanitation': 'No passage states a position on any rung.',
  childcare: 'No passage states a position on childcare funding or provision.',
  'civil-rights': 'She said she believes the council will intrinsically govern differently because its members understand the ways this body and government have systematically left people out, and she has spoken about identity as a piece of representation and power. Those are statements about representation. The rungs here separate on how far civil-rights enforcement and race-conscious programmes should go, and no passage states a position on that.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'ranked-choice-voting': 'Saint Paul elects by ranked voting under Chapter 31 of its Legislative Code and she was elected under it. No passage quotes her stating a position on whether the city should keep, extend or drop the method.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
const evidence = [];
for (const c of chairs) {
  rows.push({
    full_name: N, topic_key: c.topic_key, value: c.value, evidence_type: c.evidence_type, reasoning: c.reasoning,
    source_url_1: c.urls[0] || '', source_url_2: c.urls[1] || '', source_url_3: c.urls[2] || '',
    quote_text: '', quote_deidentified: '', editor_note: '',
  });
}
for (const [k, v] of Object.entries(blanks)) {
  rows.push({
    full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: `Searched blank. ${SWEEP} ${v}`,
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  });
}

evidence.push({
  full_name: N, topic_key: 'housing',
  source_url: 'https://www.twincities.com/2026/04/27/st-paul-2-developers-pitch-affordable-housing-on-jackson-street/',
  snippet: '“I could not be more supportive of this project,” said Council Member HwaJeong Kim, noting the HRA land has been vacant for decades. “When we talk about property taxes, at least for me, the Number 1 thing I tell folks is that we have to build. … We just need more folks that are invested in the city in this way.”',
  snippet_index: 0,
});

let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
const named = new Map();
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  const cited = row && [row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: ${words} words, needs 25+`); bad++; }
  // 🔴 "Kim" is a COMMON surname, so the verifier wants a title beside the full name, not just the
  // surname. This snippet carries "said Council Member HwaJeong Kim" — assert it rather than hope.
  if (!/Council Member HwaJeong Kim|HwaJeong Kim/.test(e.snippet)) { console.error(`🔴 ${e.topic_key}: snippet lacks her FULL name — a bare "Kim" will not verify`); bad++; } else named.set(e.topic_key, 1);
  if (!cited) { console.error(`🔴 ${e.topic_key}: evidence url not among the row's sources`); bad++; }
}
for (const r of rows.filter((x) => x.value)) if (!named.get(r.topic_key)) { console.error(`🔴 ${r.topic_key}: no snippet naming her in full`); bad++; }
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/kim-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/kim-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
console.log('chairs:', rows.filter((r) => r.value).map((r) => `${r.topic_key}=${r.value}`).join(', ') || '(none)');
