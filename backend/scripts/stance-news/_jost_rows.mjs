// Saura Jost, re-researched 2026-10-05. 1 chair -> 2.
//
// Her old rows claimed every one of 21 articles was read; 16 were on disk, and they named Minnesota
// Reformer as searched when it had supplied nothing. Re-swept: 58 files, 40 naming her, including 1
// from Reformer. 20 attributed quotes.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Saura Jost';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 58 articles, 40 of which name Saura Jost as a phrase. One was set aside because it also names a different person surnamed Jost, so a bare-surname attribution in it could not be trusted, and every passage in the remaining 39 that quotes her beside a speech verb was read - 20 of them. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one.';

const chairs = [
  {
    topic_key: 'rent-regulation',
    value: '3',
    evidence_type: 'statement',
    urls: [
      'https://www.minnpost.com/metro/2025/05/st-pauls-rent-control-policy-could-be-further-watered-down-in-response-to-development-downturn/',
      'https://stpaul.legistar.com/MeetingDetail.aspx?LEGID=7306&GID=125&G=EDAB5C5F-1041-4DF4-A894-59E957785E36',
    ],
    reasoning: 'She co-authored Ord 25-29 with Anika Bowie and Council President Noecker and voted for it; the council adopted it on 7 May 2025 by four votes to three. The ordinance amends Chapter 193A.08 by replacing the twenty-year limit on the new-construction exemption with a fixed date, so the three percent cap no longer applies to any rental property first issued a certificate of occupancy after 31 December 2004. The cap stays in force on every unit that is not exempt. The re-swept corpus adds her own account of why, which states the chair directly: she said the council is trying to apply the right policy tool to the right problem, that tenant protections are there to help with renter stability and keeping people in their homes, and that rent stabilization will still be able to do that too, but that the council is recognising the issues it has created in housing supply. That is chair 3 in her own words - current protections maintained, new construction released to market rents. Chair 4 does not fit, because the cap is not limited to subsidised units, and chair 2 does not fit, because she is narrowing coverage rather than extending it. She also said she shared the values of the people pushing for rent stabilization and wanted to find ways to keep rents down, which is why the exemption rather than repeal is the instrument she chose.',
  },
];

const blanks = {
  housing: 'She said construction costs continue to rise, that interest rates are challenging, that housing is such a priority and the city is so far behind that it really needs to do something, and that overall housing supply goals in the Twin Cities had not been met. That is an argument that supply is short and that the city should act. The rungs here separate on the instrument - whether government builds and operates housing, sets binding rules on the private market, or subsidises construction - and her stated instrument in the window read is the rent stabilization exemption, which is recorded on that ladder rather than this one.',
  // 🔴 A CHAIR WAS REASONED, DRAFTED, AND THEN REFUSED BY THE VERIFIER. It is recorded here in
  // full so the next pass can finish it rather than rediscover it.
  'transportation-priorities': 'On the Summit Avenue reconstruction and its bike trail she said the city needs to build multiple types of transit for everyone, no matter how they want to get around, and that a solution can be found that is built to last and works for everyone. She framed it as maintenance first: Summit is like many Saint Paul streets past their design life and must be replaced, with climate-resilient infrastructure and foresters advising on minimising tree loss. Read with the instrument - a street rebuild that carries a bike trail within it - that is the position of investing in roads and multimodal options together rather than prioritising one over the other. It is recorded as a blank, not as a chair, for one reason: the only source carrying it does not verify. The October 2023 MinnPost report is live and carries the words, but the verifier cannot confirm them against the page, while a different MinnPost article verifies for her on another ladder. A position that can be read but not verified does not publish. A second source would settle it.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character.',
  'growth-and-development': 'No passage states a position on the pace of growth or on whether development should wait for infrastructure capacity.',
  'economic-development': 'No passage states a position on business incentives, their conditions or their limits.',
  homelessness: 'No passage states a position on how the city should treat people sleeping or camping in public.',
  'homelessness-response': 'No passage states what level of funding the city’s homelessness response should carry.',
  'public-safety-approach': 'No passage states her position on police staffing, police funding, co-responders or crisis teams, which is what this ladder separates on.',
  'local-immigration': 'No passage quotes her on detainers, on information sharing, or on the use of local police for immigration enforcement.',
  'local-environment': 'She said streets past their design life should be replaced with climate-resilient infrastructure and that foresters should advise on minimising tree loss in the Summit Avenue reconstruction. That is a position about how one rebuild should be carried out. It does not choose among the rungs, which separate on how far environmental protection should constrain development generally.',
  'climate-change': 'Her reference to climate-resilient infrastructure concerns how streets are rebuilt. No passage states a position on clean-energy mandates, subsidies or permitting, which is what this ladder asks.',
  'city-sanitation': 'No passage states a position on any rung.',
  childcare: 'No passage states a position on childcare funding or provision.',
  'minimum-wage': 'Saint Paul has a municipal minimum wage, so the lever exists and this is not a scope blank. No passage quotes her on the wage floor, and she was not among the three members who proposed eliminating the youth training wage in August 2026.',
  'civil-rights': 'She declined to support a resolution and said it was not because of the person it honoured but because information arrived too late for her to make an informed decision, and she has spoken about the network of women in city politics. Those are statements about process and about representation. The rungs here separate on how far civil-rights enforcement and race-conscious programmes should go, and no passage states a position on that.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'ranked-choice-voting': 'Saint Paul elects by ranked voting under Chapter 31 of its Legislative Code and she was elected under it. No passage quotes her stating a position on whether the city should keep, extend or drop the method.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
for (const c of chairs) rows.push({ full_name: N, topic_key: c.topic_key, value: c.value, evidence_type: c.evidence_type, reasoning: c.reasoning, source_url_1: c.urls[0], source_url_2: c.urls[1] || '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(blanks)) rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: `Searched blank. ${SWEEP} ${v}`, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });

const evidence = [
  { full_name: N, topic_key: 'rent-regulation', source_url: 'https://www.minnpost.com/metro/2025/05/st-pauls-rent-control-policy-could-be-further-watered-down-in-response-to-development-downturn/', snippet: 'The vote on the measure to amend rent stabilization is being taken in tandem with action on a new tenant protections ordinance — a situation Jost and other council members have emphasized leading up to the Wednesday meeting. “We’re trying to apply the right policy tool to the right problem we\'re trying to solve. So we\'ve got tenant protections to help with renter stability, keeping folks in their homes and finding housing,” Jost said. “Rent stabilization will still be able to also do that, but we\'re recognizing the issues that it\'s created in housing supply.”', snippet_index: 0 },
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
  if (!isRecord(e.source_url)) { if (!/Jost/.test(e.snippet)) { console.error(`🔴 ${e.topic_key}: snippet does not name her`); bad++; } else named.set(e.topic_key, 1); }
}
for (const r of rows.filter((x) => x.value)) if (!named.get(r.topic_key)) { console.error(`🔴 ${r.topic_key}: no prose snippet naming her`); bad++; }
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/jost-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/jost-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
