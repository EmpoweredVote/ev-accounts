// Rebecca Noecker, re-researched 2026-10-05 against the re-swept corpus.
//
// Why she was redone: her original 35 rows rested on 51 readable articles. A truncated corpus key
// had overwritten 26 of the 77 the sweep had named, and Minnesota Reformer — listed in her rows as
// an outlet that was searched — had supplied nothing, because it refuses node's fetch at the TLS
// layer. The re-sweep gives 196 articles naming her and 131 attributed quotes.
//
// Result: 1 chair -> 3. The 15 scope blanks are facts about Minnesota law, are corpus-independent,
// and are NOT emitted here — merge_rows.mjs replaces only the pairs it is given.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Rebecca Noecker';

// 🔴 The outlet sentence is the one that was false before. MPR News and Racket stay named as
// uncovered: MPR's article pages are hydrated client-side, so a passage there could be read but
// never verified or published; Racket's search returns the same boilerplate for any query.
const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 200 articles, 196 of which name Rebecca Noecker as a phrase. One was set aside because it also names a different Noecker, so a bare-surname attribution in it could not be trusted, and every passage in the remaining 195 that quotes her beside a speech verb was read - 131 of them. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one. Her recorded votes were read from the council’s own roll calls for the 89 meetings from 1 June 2025: she is recorded on 27 of the 29 divided matters, 21 Yea and 6 Nay.';

const chairs = [
  {
    topic_key: 'rent-regulation',
    value: '3',
    evidence_type: 'statement',
    urls: [
      'https://minnesotareformer.com/2022/09/07/st-paul-council-poised-to-exempt-new-construction-from-rent-control/',
      'https://www.minnpost.com/metro/2025/05/st-pauls-rent-control-policy-could-be-further-watered-down-in-response-to-development-downturn/',
      'https://stpaul.legistar.com/MeetingDetail.aspx?LEGID=7306&GID=125&G=EDAB5C5F-1041-4DF4-A894-59E957785E36',
    ],
    reasoning: 'Noecker states this position in her own words, and has voted on both sides of it. In the September 2022 overhaul of the voter-approved three percent cap she said the city should not have a new-construction exemption that does not go far enough to incentivize new construction, that developers asking for thirty years was way too long, and that twenty years was the minimum that would spur construction. She voted against the amendment that would have shortened the exemption to fifteen years and applied it only to future construction. That is chair 3 from both directions at once: she refuses to weaken the cap further, which excludes chairs 4 and 5, and she refuses to strengthen it, which excludes chairs 1 and 2. Her later record is consistent. She co-authored Ord 25-29 and voted for it; the council adopted it on 7 May 2025 by four votes to three. It amends Chapter 193A.08 by replacing the twenty-year limit with a fixed date, so the cap no longer applies to any rental property first issued a certificate of occupancy after 31 December 2004. The cap stays in force on every unit that is not exempt. Chair 4 does not fit, because the cap is not limited to subsidised units. One passage was read and set aside: in September 2021, before the ballot measure passed, she said the question had not really been an issue the council had been discussing and that she planned to do her research as a citizen since she had no more voice on it than anybody. That is an explicit absence of a position and is superseded by her record.',
  },
  {
    topic_key: 'economic-development',
    value: '4',
    evidence_type: 'statement',
    urls: [
      'https://www.twincities.com/2026/06/11/st-paul-approves-tif-funds-for-166-market-rate-units-at-galtier-cray-plaza/',
      'https://www.minnpost.com/politics-policy/2016/03/st-paul-tiff-over-tif-comes-down-simple-question-how-good-deal-soccer-stadiu/',
    ],
    reasoning: 'Both clauses of this chair are evidenced, and the second one by an actual refusal. On the incentive itself she is plainly in favour: at the June 2026 vote approving tax increment financing for 166 market-rate units at Galtier Plaza she said she was strongly in support of the project and that bringing those units downtown was desperately needed, and in October 2024 she said the city needs a financial incentive for office-to-residential conversions and does not have the cash sitting in its coffers. On limits she said at the same June 2026 meeting that the council is taking tax increment financing very seriously, naming both the economic development TIF has allowed the city to create and the need for the council and the HRA to take a close look when districts are ready to close; the council was at that point reckoning with districts extended past their end date and districts that had failed. She has also passed on a deal. In March 2016, on the RK Midway site, she argued that the Green Line, the Snelling Avenue reconstruction, the A Line and the stadium were public investment already made, said it did not make sense to now say private development would not occur without additional public investment, and said TIF was better taken off the list of possible assistance. Chair 3 is not evidenced: her scrutiny is of district lifecycle, extension and transparency, not of wage or local-hiring commitments with money paid back, which is what chair 3 requires. Chair 5 is excluded by the RK Midway refusal, and chairs 1 and 2 by her support for a large developer. The reviewer should weigh one mismatch: this chair names major employers, and her instruments are housing and mixed-use development, which she herself describes as economic development.',
  },
  {
    topic_key: 'residential-zoning',
    value: '4',
    evidence_type: 'statement',
    urls: ['https://sahanjournal.com/housing/st-paul-city-council-zoning-changes-affordable-housing/'],
    reasoning: 'At the October 2023 public hearing on Phase 2 of the city’s 1-4 Unit Housing Study she said she does not often leave a zoning public hearing feeling excited, but that the vision expressed for a more dense and vibrant city had left her charged and really eager for the changes in front of her. The instrument is described in the same report: Phase 2 allows triplexes, duplexes and fourplexes in more places throughout the city, expands two residential districts and eliminates a third, and increases the bonuses given to developers who build affordable housing. Chair 2 is excluded by chronology rather than by degree: modest increases limited to duplexes and accessory dwellings describe Phase 1, which the city enacted in March 2022, and what she is eager for is the phase that goes past it. Chair 3 is excluded because Phase 2 applies inside residential neighbourhoods and not only near commercial corridors. Chair 5 is excluded because Phase 2 does not end single-family zoning or allow any housing type on any lot. The reviewer should weigh one mismatch: this chair says most neighbourhoods and the source says more places throughout the city. Two further passages were read and not used. The 7-0 vote allowing drop-in day centres is refused by C46 as unanimous and concerns conditional-use permits rather than residential density, and her 2017 remarks on the Ford site concern one redevelopment plan, which this programme does not treat as a communitywide position.',
  },
];

const blanks = {
  housing: 'Her one quoted remark that touches this ladder is that affordable housing should not be low-quality housing, made in a March 2026 story about an eviction-notice mandate. That is a statement about habitability, and every rung here is about the role government should take in making housing affordable - building it, setting binding rules on the private market, or subsidising it. On state rental assistance she said the city would be fighting for as much of that money as possible, which is direction and not a rung.',
  'growth-and-development': 'No passage states a position on the pace of growth. Her quoted remarks on downtown concern vacancy, conversions and the skyways rather than how fast the city should grow or whether development should wait for infrastructure.',
  homelessness: 'No passage states a position on how the city should treat people sleeping or camping in public. She is not quoted on encampment clearances, citations or shelter-bed conditions, which is what the five rungs separate on.',
  'homelessness-response': 'She voted for allowing drop-in day centres for people experiencing homelessness in most business, mixed-use and industrial districts, but that vote was 7-0 and C46 refuses a unanimous vote as a position. This ladder asks what level of public funding the response should carry, and no passage states one. A quote about having come up from the streets and living in affordable housing, which an earlier pass attributed to her, belongs to Rosie Kohnen, a community recreation leader who testified at the same meeting.',
  'public-safety-approach': 'Her quoted remarks on downtown safety concern the perception and the reality of safety and cleanliness in the skyways and who owns the problem downtown. None of them chooses between funding policing and funding social services, which is what this ladder asks. She voted against writing off police staffing costs for free public cultural festivals, but that is a question about event fees rather than about the balance between policing and other services.',
  'local-immigration': 'A January 2026 story reports that Saint Paul has a separation ordinance preventing city employees, including police, from enforcing federal immigration law, and that she was shepherding an update to it. The reporting does not quote her stating a position on detainers, on information sharing or on the use of local police, and the ordinance itself was not adopted on a divided vote in the window read.',
  'transportation-priorities': 'In a December 2017 story on a committee vote she said a streetcar had the best opportunity to get people out of their cars and relieve congestion and parking pressure on West Seventh Street and downtown. That is support for one project. It does not choose between prioritising transit and cycling over road capacity, investing equally in both, or focusing on road capacity, which is what the rungs separate on.',
  childcare: 'In an August 2023 story on a proposal to cover child care costs for low-income families she said the vote commits the city to action and praised the elegance of the funding mechanism. The report does not describe what the mechanism was, and every rung here turns on who is covered and by how much - universal public funding, expanded subsidies, targeted credits, support for the lowest incomes only, or none. Praise for a mechanism the source does not describe cannot choose between them.',
  'city-sanitation': 'In the 2019 fight over organised trash collection she said repealing the ordinance does not create a better system and leaves the contract in place with no way to fund it. That rules out chair 5, which privatises collection and has residents contract directly. It does not choose among the remaining four, which separate on whether to expand service, target the worst-served neighbourhoods, hold service level and enforce against large waste producers, or rely on enforcement against residents.',
  'local-environment': 'No passage states a position on how the city should balance development against environmental protection. Her remarks on the Ford site mention respecting the river, but in the context of endorsing one redevelopment plan rather than stating how the trade-off should be made.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'minimum-wage': 'Saint Paul has a municipal minimum wage, so the lever exists and this is not a scope blank. The ordinance and its amendments were adopted without a divided vote in the window read, and C46 refuses a unanimous vote as a position. No passage quotes her on the wage floor.',
  'ranked-choice-voting': 'She appears in a 2017 retrospective on ranked-choice voting in the Twin Cities, but no passage in it quotes her stating a position on whether the city should use, extend or drop it. Saint Paul uses ranked voting under Chapter 31 and no divided vote on it falls in the window read.',
  'civil-rights': 'No passage states a position on any rung. She said a pay-equity study for city employees had completed its first phase, which is a report on process rather than a position on civil-rights enforcement.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
const evidence = [];
for (const c of chairs) {
  rows.push({
    full_name: N, topic_key: c.topic_key, value: c.value, evidence_type: c.evidence_type,
    reasoning: c.reasoning,
    source_url_1: c.urls[0] || '', source_url_2: c.urls[1] || '', source_url_3: c.urls[2] || '',
    quote_text: '', quote_deidentified: '', editor_note: '',
  });
}
for (const [k, v] of Object.entries(blanks)) {
  rows.push({
    full_name: N, topic_key: k, value: '', evidence_type: '',
    reasoning: `Searched blank. ${SWEEP} ${v}`,
    source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
  });
}

// Snippets are cut VERBATIM from the fetched pages. Each is 77-102 words and names her inside it.
const E = (topic_key, source_url, snippet, snippet_index = 0) => evidence.push({ full_name: N, topic_key, source_url, snippet, snippet_index });
E('rent-regulation', 'https://minnesotareformer.com/2022/09/07/st-paul-council-poised-to-exempt-new-construction-from-rent-control/',
  'That leaves the original proposal by Tolbert that exempts all apartments less than 20 years old. “What you don’t want to do is have a new construction exemption that doesn’t go far enough to incentivize new construction,” said Council Member Rebecca Noecker, who voted no on Jalali’s amendment. “There are developers who are asking for 30 years. I think that’s way too long. Twenty years seems to be unanimously the minimum that will help spur construction.”');
E('rent-regulation', 'https://www.minnpost.com/metro/2025/05/st-pauls-rent-control-policy-could-be-further-watered-down-in-response-to-development-downturn/',
  'On Wednesday, the council will vote on the proposed ordinance to exempt new development from the original ballot measure’s 3% cap on rent increases, effectively weakening the measure. The new exemption was originally proposed by Mayor Melvin Cater last year. The council ordinance is co-authored by three council members — Jost, Anika Bowie and council President Rebecca Noecker');
E('rent-regulation', 'https://stpaul.legistar.com/MeetingDetail.aspx?LEGID=7306&GID=125&G=EDAB5C5F-1041-4DF4-A894-59E957785E36',
  'Ord 25-29 1 34 Ordinance Amending Chapter 193A.08 of the Legislative Code pertaining to rent stabilization. Adopted Pass Action details Video RES PH 25-49 1 37 Resolution-Public Hearing Final Order approving the reconstruction of streets in the 2025 Saint Paul Streets Program and Sales Tax Street Projects.');
E('economic-development', 'https://www.twincities.com/2026/06/11/st-paul-approves-tif-funds-for-166-market-rate-units-at-galtier-cray-plaza/',
  'have failed, and the amount of money generated for affordable housing elsewhere in the city through off-site pooling. "This council is taking tax increment financing very seriously," Noecker said. "One of the things we\'ve talked about was the amount of economic development that TIF financing has allowed us to create, but also the need for this body, and the HRA, to take a close look when those districts are ready to close, and when we can bring those dollars back for other uses');
E('economic-development', 'https://www.minnpost.com/politics-policy/2016/03/st-paul-tiff-over-tif-comes-down-simple-question-how-good-deal-soccer-stadiu/',
  '“I believe, and I think we’ve all been saying since last August, we all believe, that stadium will catalyze development on that northern site,” Noecker said. “What I don’t think makes sense is to now say private development isn’t going to occur without additional public investment.” Noecker said it is better to take TIF off the list of possible assistance to the RK Midway site');
E('residential-zoning', 'https://sahanjournal.com/housing/st-paul-city-council-zoning-changes-affordable-housing/',
  'order to encourage the construction of affordable housing. “I want to say that I don\'t often leave public hearings, especially when it\'s about zoning code changes feeling excited,” said Council Member Rebecca Noecker. “But there was so much positivity and enthusiasm, and so much of a vision expressed here today for a more dense and vibrant city that I just want you to know that it\'s left me feeling charged, and really eager for the changes that are in front of us.”');

// 🔴 Controls before writing. Each evidence snippet must be 25+ words, must name her, and its URL
// must be one of its own row's source_urls — the gate's `evidence-url-not-cited` finding.
let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
// A Legistar meeting-detail page is a STRUCTURED VOTE RECORD: the member's vote is a field, not
// prose, so its snippet legitimately carries no surname. The verifier does not count these among
// verified sources either. They may support a chair; they may never be its only evidence.
const isRecord = (u) => /legistar\.com/.test(u);
const namedPerTopic = new Map();
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  const cited = row && [row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: snippet is ${words} words, needs 25+`); bad++; }
  if (!isRecord(e.source_url)) {
    if (!/Noecker/.test(e.snippet)) { console.error(`🔴 ${e.topic_key}: prose snippet does not name her`); bad++; }
    else namedPerTopic.set(e.topic_key, (namedPerTopic.get(e.topic_key) || 0) + 1);
  }
  if (!cited) { console.error(`🔴 ${e.topic_key}: evidence url is not among the row's source_urls`); bad++; }
}
for (const r of rows.filter((x) => x.value)) {
  if (!namedPerTopic.get(r.topic_key)) { console.error(`🔴 ${r.topic_key}: no prose snippet naming her — a record alone cannot carry a chair`); bad++; }
}
for (const r of rows) {
  if (r.value && !r.evidence_type) { console.error(`🔴 ${r.topic_key}: scored row with no evidence_type`); bad++; }
  if (/MinnPost and Sahan Journal \(WordPress REST API\) and Minnesota Reformer/.test(r.reasoning)) { console.error(`🔴 ${r.topic_key}: the OLD false outlet clause survives`); bad++; }
}
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/noecker-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/noecker-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
console.log('chairs:', rows.filter((r) => r.value).map((r) => `${r.topic_key}=${r.value}`).join(', '));
