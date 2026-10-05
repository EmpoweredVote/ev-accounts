// Nelsie Yang, re-researched 2026-10-05. 0 chairs -> 1.
//
// Her original rows claimed "every passage in the remaining 47 ... was read" when only 39 of the
// 50 named articles were ever written to disk. Re-swept: 393 files, 63 naming her — her surname is
// extremely common in Saint Paul, so the corpus is 84% other Yangs and the profiler is what says
// which 63 to read. 58 clean articles, 15 attributed quotes.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Nelsie Yang';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 393 articles. Yang is a very common surname in Saint Paul, so the full phrase was required: 63 of those articles name Nelsie Yang. Five were set aside because they also name a different person surnamed Yang, so a bare-surname attribution in them could not be trusted, and every passage in the remaining 58 that quotes her beside a speech verb was read - 15 of them - together with the passages where a reporter names her without a speech verb, which the strict rule does not catch. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one.';

const chairs = [{
  topic_key: 'ranked-choice-voting',
  value: '2',
  evidence_type: 'statement',
  urls: ['https://www.minnpost.com/politics-policy/2023/03/senate-advances-bill-that-could-move-minnesota-toward-ranked-choice-voting/'],
  reasoning: 'She says it in her own words. Testifying to a Minnesota Senate elections committee in March 2023 she said ranked choice voting levels the political playing field for immigrant communities and people of colour, and that no one is at a disadvantage from the start with it, which is why she is such a strong supporter of it. Saint Paul already elects by ranked voting for single-winner offices under Chapter 31 of its Legislative Code, and she holds her seat under it. That is chair 2. Chair 1 is not evidenced: nothing she says calls for proportional multi-member ranked voting, which is what distinguishes it. Chairs 4 and 5 are excluded outright by her support. The reviewer should weigh one nuance. The bill she was testifying for was a local-option measure that would let other Minnesota cities adopt ranked voting if they chose, which is the mechanism chair 3 describes - but chair 3 also keeps single-choice voting as the standard, and she argues the opposite, that ranked voting removes a disadvantage. The local-option bill was the instrument available to her at the Capitol, not the limit of her position.',
}];

const blanks = {
  'rent-regulation': 'She was one of only two council members who voted on 5 August 2026 to put the Right to Repair question on the November ballot, and she noted that the same ordinance language had won overwhelming ballot approval in Duluth the previous year without subsequent controversy. Right to Repair lets tenants act on unmade repairs; it is a habitability measure. Every rung here turns on the price of rent - expanding rent control, strengthening stabilization, maintaining current protections, limiting regulation to subsidised units, or opposing control. The reporting in 2023 places her among members interested in restoring parts of the stricter rent policy, but no passage quotes her stating which part or how far.',
  'minimum-wage': 'With Molly Coleman and HwaJeong Kim she proposed eliminating the ninety-day youth training wage, which stood at $13.95 against $16.37 for other employers, and the council adopted the amendment in August 2026. That removes a sub-minimum carve-out and raises the floor for workers aged fourteen to seventeen, which excludes the rungs that hold the floor where it is or remove it. It does not choose among the three that remain, which separate on whether the floor should rise automatically with the cost of living, rise to a set level by vote, or stay modest nationally while cities set their own. The quotations on basic fairness in that report are Coleman’s.',
  childcare: 'On the 2023 proposal to cover child care costs for low-income families she said other cities’ experiments with similar policies have shown that child care initiatives have a huge impact on preparing children for kindergarten and helping parents enter the workforce. That is an argument that such programmes work, not a position on who should be covered and by how much, which is what the rungs separate on. The passage is also not citable: her full name sits 628 characters away, only a bare "Yang" stands beside the quote, and her surname is common enough that a citation needs a title next to the full name.',
  'economic-development': 'She said the East Side has experienced decades of divestment that put the community into a cycle of poverty, and that the city should build on prosperity for East Side residents because equity takes work, investment and time. That is an argument for investment in a neglected part of the city. It names no incentive, no condition and no limit, which is what the five rungs separate on.',
  housing: 'No passage states a position on the role government should take in making housing affordable. Her housing-adjacent remarks concern eviction protections and East Side investment rather than whether government should build, regulate or subsidise.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character.',
  'growth-and-development': 'No passage states a position on the pace of growth or on whether development should wait for infrastructure capacity.',
  homelessness: 'No passage states a position on how the city should treat people sleeping or camping in public.',
  'homelessness-response': 'No passage states what level of funding the city’s homelessness response should carry.',
  'public-safety-approach': 'She sponsored the council hearing on police surveillance technology and data privacy with Anika Bowie. That is a position on oversight of police technology. This ladder separates on the balance between the police budget and other services, and no passage states her position on police staffing, funding, co-responders or crisis teams.',
  'local-immigration': 'No passage quotes her on detainers, on information sharing, or on the use of local police for immigration enforcement.',
  'transportation-priorities': 'No passage states a position on where transportation investment should go.',
  'local-environment': 'She has described good leadership as making decisions with a long-term positive impact and working toward a greener, cleaner, sustainable and racially equitable community. That is a statement of values. It does not choose among the rungs, which separate on how far environmental protection should constrain development.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'city-sanitation': 'No passage states a position on any rung.',
  'civil-rights': 'She speaks often about immigrant communities, people of colour, and Hmong, queer and trans residents, and argues that representation changes who government works for. Those are statements about representation. The rungs here separate on how far civil-rights enforcement and race-conscious programmes should go, and no passage states a position on that.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
for (const c of chairs) rows.push({ full_name: N, topic_key: c.topic_key, value: c.value, evidence_type: c.evidence_type, reasoning: c.reasoning, source_url_1: c.urls[0] || '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(blanks)) rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: `Searched blank. ${SWEEP} ${v}`, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });

const evidence = [{
  full_name: N, topic_key: 'ranked-choice-voting',
  source_url: 'https://www.minnpost.com/politics-policy/2023/03/senate-advances-bill-that-could-move-minnesota-toward-ranked-choice-voting/',
  snippet: 'St. Paul City Council Member Nelsie Yang told the committee that she thinks RCV levels the political playing field for immigrant communities and people of color. “No one is at a disadvantage from the start with ranked choice voting … which is why I’m such a strong supporter of it,” Yang said.',
  snippet_index: 0,
}];

let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: ${words} words`); bad++; }
  // 🔴 "Yang" alone will not verify — the surname is common here. Require the full name.
  if (!/Nelsie Yang/.test(e.snippet)) { console.error(`🔴 ${e.topic_key}: snippet lacks her full name`); bad++; }
  if (!row || ![row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url)) { console.error(`🔴 ${e.topic_key}: url not among the row's sources`); bad++; }
}
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/yang-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/yang-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
