// Anika Bowie, re-researched 2026-10-05. 1 chair, unchanged.
//
// Her old rows claimed every passage in 32 articles was read; 28 were on disk, and they named
// Minnesota Reformer as searched when it had supplied nothing. Re-swept: 109 files, 56 naming her,
// including 2 from Reformer. 20 attributed quotes.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Anika Bowie';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 109 articles, 56 of which name Anika Bowie as a phrase. The full phrase was required rather than the surname alone, because the surname alone also returns coverage of the musician. No article names a different person surnamed Bowie, and every passage in the 56 that quotes her beside a speech verb was read - 20 of them - together with the passages where a reporter names her without a speech verb, which the strict rule does not catch. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one.';

const chairs = [{
  topic_key: 'rent-regulation',
  value: '3',
  evidence_type: 'record',
  urls: [
    'https://www.minnpost.com/metro/2025/05/st-pauls-rent-control-policy-could-be-further-watered-down-in-response-to-development-downturn/',
    'https://stpaul.legistar.com/MeetingDetail.aspx?LEGID=7306&GID=125&G=EDAB5C5F-1041-4DF4-A894-59E957785E36',
  ],
  reasoning: 'Bowie co-authored Ord 25-29 and voted for it; the council adopted it on 7 May 2025 by four votes to three. The ordinance amends Chapter 193A.08 by removing the twenty-year limit on the new-construction exemption and replacing it with a date, so the rent stabilization ordinance’s three percent cap no longer applies to any rental property first issued a certificate of occupancy after 31 December 2004. The cap stays in force on every unit that is not exempt, which is chair 3: current tenant protections are maintained while new construction is allowed to set market rents. Chair 4 does not fit, because the cap is not limited to subsidised units. The re-swept corpus of 56 articles confirms the sponsorship and adds nothing that moves it. For the reviewer’s completeness: she is listed among the endorsers of the Right to Repair tenant initiative and then, on 5 August 2026, did not vote to put its question on the ballot, being recorded against after declining to participate. Right to Repair concerns repairs and habitability rather than the price of rent, so it names no rung on this ladder either way.',
}];

const blanks = {
  'local-immigration': 'When procedural rules stopped her moving a last-minute version of an updated separation ordinance, she said she had always deferred to the council president’s leadership but was in that moment very ashamed, and that the rules required a copy of the draft be before members, which they did not have. That records urgency to strengthen the city’s separation ordinance and a dispute about process. It does not state what the update would do, and the rungs here separate on detainers, on information sharing and on the use of local police. No passage quotes her on any of those.',
  'public-safety-approach': 'She sponsored the council hearing on police surveillance technology and data privacy with Nelsie Yang, said of a police presentation that she did not see in it how people got safer, and said the city was reviewing the docked drone programme and exploring what oversight mechanisms may be available. She also said concerns about automated city ticketing rest on examples of misuse in other cities, and that she hears from residents whose cars are towed and would hate for families to absorb that cost. Those are positions on police technology, oversight and enforcement costs. This ladder separates on the balance between the police budget and other services, and no passage states her position on police staffing, funding, co-responders or crisis teams.',
  'transportation-priorities': 'She said she wants to ensure equitable investment in all of the city’s streets, and that this past winter proved the city needs to be proactive in handling infrastructure. That is a position about maintenance and about which neighbourhoods get investment. It does not choose between prioritising transit, cycling and pedestrian infrastructure, investing equally, or focusing on road capacity, which is what the rungs separate on.',
  'economic-development': 'She said she is excited to see momentum and investment returning to Midway Marketplace. That is approval of one development returning to one site. No passage states a position on whether the city should offer incentives, to whom, or with what conditions and limits.',
  housing: 'No passage states a position on the role government should take in making housing affordable. Her rent stabilization sponsorship concerns the price cap and its exemptions rather than whether government should build, regulate or subsidise.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character.',
  'growth-and-development': 'No passage states a position on the pace of growth or on whether development should wait for infrastructure capacity.',
  homelessness: 'No passage states a position on how the city should treat people sleeping or camping in public.',
  'homelessness-response': 'No passage states what level of funding the city’s homelessness response should carry.',
  'minimum-wage': 'Saint Paul has a municipal minimum wage, so the lever exists and this is not a scope blank. No passage quotes her on the wage floor, and she was not among the three members who proposed eliminating the youth training wage in August 2026.',
  childcare: 'No passage states a position on childcare funding or provision.',
  'local-environment': 'No passage states a position on how the city should balance development against environmental protection.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'city-sanitation': 'No passage states a position on any rung.',
  'civil-rights': 'She has said that historically there were literal neighbourhoods left out of decision-making, that her ward ran a race to serve everyone regardless of race, gender, income or religion, and she objected to being lectured about how to honour African-American leaders. Those are statements about representation and about process. The rungs here separate on how far civil-rights enforcement and race-conscious programmes should go, and no passage states a position on that.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'ranked-choice-voting': 'Saint Paul elects by ranked voting under Chapter 31 of its Legislative Code and she was elected under it, leading a crowded Ward 1 field. No passage quotes her stating a position on whether the city should keep, extend or drop the method.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
for (const c of chairs) rows.push({ full_name: N, topic_key: c.topic_key, value: c.value, evidence_type: c.evidence_type, reasoning: c.reasoning, source_url_1: c.urls[0], source_url_2: c.urls[1] || '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(blanks)) rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: `Searched blank. ${SWEEP} ${v}`, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });

const evidence = [
  { full_name: N, topic_key: 'rent-regulation', source_url: 'https://www.minnpost.com/metro/2025/05/st-pauls-rent-control-policy-could-be-further-watered-down-in-response-to-development-downturn/', snippet: 'On Wednesday, the council will vote on the proposed ordinance to exempt new development from the original ballot measure’s 3% cap on rent increases, effectively weakening the measure. The new exemption was originally proposed by Mayor Melvin Cater last year. The council ordinance is co-authored by three council members — Jost, Anika Bowie and council President Rebecca Noecker', snippet_index: 0 },
  { full_name: N, topic_key: 'rent-regulation', source_url: 'https://stpaul.legistar.com/MeetingDetail.aspx?LEGID=7306&GID=125&G=EDAB5C5F-1041-4DF4-A894-59E957785E36', snippet: 'Ord 25-29 1 34 Ordinance Amending Chapter 193A.08 of the Legislative Code pertaining to rent stabilization. Adopted Pass Action details Video RES PH 25-49 1 37 Resolution-Public Hearing Final Order approving the reconstruction of streets in the 2025 Saint Paul Streets Program and Sales Tax Street Projects.', snippet_index: 0 },
];

let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
const isRecord = (u) => /legistar\.com/.test(u);
const named = new Map();
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: ${words} words`); bad++; }
  if (!row || ![row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url)) { console.error(`🔴 ${e.topic_key}: url not among sources`); bad++; }
  if (!isRecord(e.source_url) && /Anika Bowie/.test(e.snippet)) named.set(e.topic_key, 1);
}
for (const r of rows.filter((x) => x.value)) if (!named.get(r.topic_key)) { console.error(`🔴 ${r.topic_key}: no prose snippet naming her in full`); bad++; }
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/bowie-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/bowie-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
