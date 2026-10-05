// Kaohly Her, Mayor of Saint Paul, re-researched 2026-10-05 against the re-swept corpus.
//
// Original corpus: 72 articles on disk of 96 the sweep had named — 24 lost to a truncated corpus
// key — and no Minnesota Reformer at all. Re-swept: 265 articles, every one naming her, plus 25
// from Reformer. 85 attributed quotes. Result: 0 chairs -> 1.
//
// 🔴 A MAYOR LEAVES ALMOST NO ROLL-CALL RECORD, so she is researched from proposals and statements
// (the Reinert finding). Her corpus is also unusual: 265 articles and only a handful bear on any
// ladder, because her coverage is dominated by her being the first Hmong woman to lead the city and
// by a sexual-harassment investigation involving the police chief. Volume is not evidence.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Kaohly Her';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 265 articles, every one of which names her. The sweep ran under both "Kaohly Her" and "Kaohly Vang Her", and the two spellings newsrooms use in error, "Khaoly" and "Kaoly", were read as hers. Eight articles were set aside because they also name a different person surnamed Her, which is a common Hmong surname in Saint Paul, so a bare-surname attribution in them could not be trusted; every passage in the remaining 257 that quotes her beside a speech verb was read - 85 of them. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one. She is the mayor, so there is no roll-call record to read: a mayor is researched from proposals and statements.';

const chairs = [
  {
    topic_key: 'local-immigration',
    value: '1',
    evidence_type: 'statement',
    urls: [
      'https://www.twincities.com/2026/01/05/minneapolis-st-paul-30-day-immigration-surge/',
      'https://sahanjournal.com/immigration/st-paul-immigration-raid-protest-rapid-response/',
    ],
    reasoning: 'She names instruments, not only a direction, and she rules out the middle of this ladder in her own words. In January 2026 she said she was ready to work with the City Council on ordinances intended to oppose aggressive sweeps by ICE, that the city faces an unprecedented incursion it must meet head on, and that she plans to bar ICE from staging in the city’s parks and public spaces and from wearing complete mask coverings that obscure identity. At a rapid-response rally she said the city is only beginning to build its rapid response capacity and that a rapid response communication system would have helped, because the federal administration benefits when residents are confused and unsure what is happening on their streets. Saint Paul has also joined the state’s litigation against the Department of Homeland Security over the enforcement surge. Chair 3, which follows federal law while declining to use local resources for proactive enforcement, is excluded by her own standard: writing as a candidate she said the city needs to do more than just passively say it is not collaborating with ICE, and named real-time alerts, forbidding masked agents and training residents as constitutional observers. Chairs 4 and 5 are excluded by every part of that record, and chair 2, a compliance posture turning on court-ordered detainers, does not describe a city suing the department and barring its agents from public property. The reviewer should weigh one mismatch: this chair names detainers and information sharing, and her instruments are access to city property, masked agents and resident alerts. She is at this pole of the ladder by different levers.',
  },
];

const blanks = {
  'economic-development': 'As a candidate she said local government must maintain the infrastructure that delivers essential public services so the city can welcome residents, businesses and development and expand its tax base, that funding the city can no longer fall on residents through increased taxes, and that she proposes an Urban Wealth Fund to diversify revenue beyond taxes. That is a revenue and service-delivery argument. Every rung here turns on business incentives - whether to offer them, to whom, and with what conditions and limits - and she names no incentive, condition or clawback. Chair 1 is the closest in spirit, because it funds public services so businesses come on their own, but its defining clause is a refusal to give tax breaks or subsidies and she does not state one.',
  housing: 'As a candidate she said building affordable and abundant housing will help the city welcome more neighbours, increase the tax base and bring down the cost of living. That is a goal, and the five rungs here separate on the instrument - whether government builds and operates housing, sets binding rules on the private market, or subsidises. No passage states which she would use.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character. Her housing remarks are about supply and cost and name no zoning instrument, and she is not quoted on duplexes, accessory dwellings, upzoning or single-family zoning.',
  'growth-and-development': 'No passage states a position on the pace of growth or on whether development should wait for infrastructure capacity. Her remarks about expanding the tax base are about revenue rather than pace.',
  homelessness: 'Her administration cleared the Pig’s Eye encampment, the city’s largest closure in more than a year, and her administration said conditions there had become unsafe for residents. A city official told the Safety Committee that the number who accepted emergency shelter was lower than hoped and that this was not a success. That is an action taken and an outcome reported, not a stated posture: no passage quotes her choosing among protecting sleeping in public, decriminalising it, enforcing only when shelter beds are available, prohibiting encampments with civil penalties, or banning camping with criminal penalties.',
  'homelessness-response': 'After the Pig’s Eye closure she said people are suffering, that the city cannot accept it and cannot solve it by asking cities to carry the burden alone, that it is a regional and statewide challenge and ultimately a shared responsibility, and that she plans to advocate for more resources. That is advocacy for other levels of government to contribute. This ladder asks what level of funding the community itself should carry, and no passage states one.',
  'public-safety-approach': 'As a candidate she said guaranteeing safe neighbourhoods encompasses more than violent crime, naming access to city resources for children, the public health crisis of addiction and mental health, and support for emergency medical services, which in Saint Paul are delivered by firefighters. That broadens what public safety means. It does not choose among the rungs, which separate on the balance between the police budget and other services: she names no position on police staffing, police funding, co-responders or crisis teams. Her quoted remarks on the police department concern accountability and her dispute with the chief rather than the allocation of public safety spending. Two further passages were read and set aside because they date from her service in the Legislature and address state police reform rather than the city budget.',
  'transportation-priorities': 'No passage states a position on where transportation investment should go. Her remarks on downtown concern vacancy and retail rather than the balance between road capacity, transit, cycling and pedestrian infrastructure.',
  'local-environment': 'No passage states a position on how the city should balance development against environmental protection. She is quoted encouraging one industrial neighbour, Northern Iron, to engage with community concerns, which is a call for engagement rather than a position on the trade-off.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'rent-regulation': 'No passage quotes her on the rent stabilization cap, its exemptions or its coverage. She is quoted saying that years ago the city could have worked with renters to put rent in escrow so that a downtown landlord would have had to fix its properties, which concerns habitability and repair leverage rather than the price of rent, which is what every rung of this ladder turns on.',
  'city-sanitation': 'No passage states a position on any rung.',
  childcare: 'No passage states a position on childcare funding. Her remarks on supporting families concern housing cost and public safety rather than the subsidy, credit or provider-support questions this ladder separates on.',
  'minimum-wage': 'Saint Paul has a municipal minimum wage, so the lever exists and this is not a scope blank. No passage quotes her on the wage floor, on the ordinance or on its amendments.',
  'ranked-choice-voting': 'Saint Paul elects by ranked voting under Chapter 31 of its Legislative Code and she was elected under it. No passage quotes her stating a position on whether the city should keep, extend or drop the method.',
  'civil-rights': 'She speaks often about the Hmong community, about being the first Hmong woman to lead the city, and about the disparate treatment of Black and Brown residents. Those are statements about experience and about why representation matters. No passage states a position on the rungs here, which separate on how far civil-rights enforcement and race-conscious programmes should go.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
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

const E = (topic_key, source_url, snippet, snippet_index = 0) => evidence.push({ full_name: N, topic_key, source_url, snippet, snippet_index });
E('local-immigration', 'https://www.twincities.com/2026/01/05/minneapolis-st-paul-30-day-immigration-surge/',
  'new St. Paul Mayor Kaohly Her said she was ready to work with the St. Paul City Council on ordinances intended to oppose aggressive sweeps by ICE. "From cutting funding to our city or targeting our neighbors, we are facing an unprecedented incursion that we must meet head on," said Her, who said she plans to ban ICE from staging in the city\'s parks and public spaces, and from wearing complete mask coverings that obscure identity.');
E('local-immigration', 'https://sahanjournal.com/immigration/st-paul-immigration-raid-protest-rapid-response/',
  'Kaohly Vang Her, spoke to a crowd of more than 200 people. Her said the city is just beginning to build its rapid response capacity to such actions. “The federal administration benefits when we are confused, divided and unsure of what actually is happening on our streets,” Her said. “This is exactly the kind of situation where a rapid response communication system would have helped. There is much we need to do in our city in creating this network and this infrastructure.”');

// Controls — the same ones that stopped Noecker's file being written with an uncitable snippet.
let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
const isRecord = (u) => /legistar\.com/.test(u);
const namedPerTopic = new Map();
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  const cited = row && [row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: snippet is ${words} words, needs 25+`); bad++; }
  if (!isRecord(e.source_url)) {
    // 🔴 The verifier needs the person named WITHIN the snippet. A candidate questionnaire puts the
    // name at the top of a 3,000-character block: her best statement of this position sits 2,788
    // characters from her name and is therefore UNCITABLE from that page, however clearly she says
    // it. Both snippets below were chosen because her name sits inside them.
    if (!/Kaohly|\bHer\b/.test(e.snippet)) { console.error(`🔴 ${e.topic_key}: prose snippet does not name her`); bad++; }
    else namedPerTopic.set(e.topic_key, (namedPerTopic.get(e.topic_key) || 0) + 1);
  }
  if (!cited) { console.error(`🔴 ${e.topic_key}: evidence url is not among the row's source_urls`); bad++; }
}
for (const r of rows.filter((x) => x.value)) {
  if (!namedPerTopic.get(r.topic_key)) { console.error(`🔴 ${r.topic_key}: no prose snippet naming her`); bad++; }
}
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/kher-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/kher-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
console.log('chairs:', rows.filter((r) => r.value).map((r) => `${r.topic_key}=${r.value}`).join(', ') || '(none)');
