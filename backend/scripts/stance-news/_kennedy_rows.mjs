import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Janet Kennedy';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
// 🔴 Her own sweep missed the paper-mill article, which another member's sweep caught. A per-member
// corpus is not exhaustive, and a citation does not have to come from the member's own corpus — the
// snippet is verified against the live page either way.
const readAny = (u) => {
  for (const slug of ['kennedy', 'forsman', 'durrwachter', 'randorf', 'nephew', 'reinert']) {
    const p = `data/stance-news/${slug}/${key(u)}.txt`;
    if (fs.existsSync(p)) return fs.readFileSync(p, 'utf8');
  }
  throw new Error('not in any corpus: ' + u);
};

const MILL = 'https://www.duluthnewstribune.com/news/local/duluth-city-council-backs-paper-mill-subsidy-despite-skeptics';
const TIFPOL = 'https://www.duluthnewstribune.com/news/local/duluth-shapes-policy-to-guide-future-use-of-tax-subsidies-for-developers';

const cut = (u, from, to) => {
  const t = readAny(u);
  const i = t.indexOf(from), j = t.indexOf(to, i);
  if (i < 0 || j < 0) throw new Error('anchor not found: ' + from);
  const s = t.slice(i, j + to.length);
  if (!t.includes(s)) throw new Error('not verbatim');
  if (s.split(/\s+/).length < 25) throw new Error('under 25 words: ' + from);
  return s;
};

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, returned 740 unique articles. Minnesota Reformer could not be searched and is not covered by this count. Kennedy is a common surname and the sweep keeps an article on the surname alone, so only 23 of the 359 it kept actually name Janet Kennedy; 290 were excluded because they name a different Kennedy, leaving 69 usable, and every attributed passage was read. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. Her recorded votes were read from the council’s own roll calls: she is recorded on all 31 divided matters since January 2024, 25 Yea and 6 Nay. She has held the 5th District seat since January 2020.';

const seated = [
  {
    topic_key: 'economic-development', value: '4', evidence_type: 'statement',
    reasoning: 'Kennedy represents the neighborhood around the Sofidel paper mill and argued for the subsidy package on the council floor, against a speaker who called the company incredibly profitable and asked for a delay. She said she did not want the perfect to get in the way of the good, that the city needs this economic development and that this was not the time to stand back, and she voted for the tax increment financing district, the development agreement and the state investment fund subgrant. That is chair 4’s first half: large tax breaks and infrastructure to attract a major employer. The second half is evidenced too, because she is one of the three councilors sitting on the Duluth Economic Development Authority who helped shape and introduce the resolution setting policy on how the city should use tax increment financing in future. Chairs 1 and 2 are excluded because she supports subsidy for a large outside company. Chair 5 is excluded because she helped write the limits. Chair 3 is excluded because she names no wage or local hiring condition and no clawback.',
    source_url_1: MILL, source_url_2: TIFPOL, source_url_3: '',
  },
];

const searched = {
  housing: 'Searched blank. ' + SWEEP + ' On the tax subsidy for student housing near Lake Superior College she spoke about the legacy the city can build and said public-private partnerships are important for housing, drawing on having ridden the bus to that campus as a young mother. That endorses the partnership and subsidy model, which is chair 4’s mechanism, but it is a single clause in support of one project rather than a position on the role government should take. The five chairs separate on whether government should build housing, impose binding rules on the private market, or subsidise, and one phrase does not choose between them. The same judgement was applied to two colleagues on the same evidence.',
  'rent-regulation': 'Searched blank. ' + SWEEP + ' She voted against the tenants’ petition ordinance on repairs and for the council’s own alternative, and is not quoted on either. Every rung of this ladder is about the price of rent, Duluth has no rent stabilization, and she has proposed none. The gap is written up as defect 8 for Season 3.',
  homelessness: 'Searched blank. ' + SWEEP + ' She voted for the amended 2024 camping ordinance and for the $500,000 that went with it, but is not quoted on what the enforcement should look like, so there is nothing to separate enforcement conditioned on shelter being available from a prohibition with civil penalties.',
  'homelessness-response': 'Searched blank. ' + SWEEP + ' She voted for the $500,000 increase for the Stepping on Up initiative. No passage states what level of city funding she thinks the response should carry, which is what this ladder asks.',
  'transportation-priorities': 'Searched blank. ' + SWEEP + ' She marked Transit Equity Day by speaking about the tradition of Rosa Parks and saying transit systems should be affordable and accessible to people of varying heritages and ethnicities. That is advocacy for transit access and not a choice between transit and road capacity, which is what every rung of this ladder turns on.',
  'civil-rights': 'Searched blank. ' + SWEEP + ' On being elected council president she said the result lifts up the voices of the African American community that has supported her, and she speaks at Black History Month events. Those are statements about representation and commemoration. No passage states a position on any rung, which ask about mandates, enforcement and race-based programs.',
  'residential-zoning': 'Searched blank. ' + SWEEP + ' She voted to uphold the Planning Commission’s denial of a vacation dwelling permit and to deny a setback variance, both single-property decisions. No passage states a position on housing density or single-family zoning.',
  'growth-and-development': 'Searched blank. ' + SWEEP + ' Announcing her re-election campaign she said she was most proud of the new businesses and development being attracted to western Duluth. That is pride in an outcome in her own district, not a position on the pace of growth.',
  'public-safety-approach': 'Searched blank. ' + SWEEP + ' She voted for the 2024 public safety ordinance package and against the 2026 budget, and no passage records her choosing between policing and social services. This is also the ladder Charlotte recorded as defective for Season 3, because chairs 1 and 3 do not separate a member who funds both.',
  'local-immigration': 'Searched blank. ' + SWEEP + ' The ordinance barring the use of city resources to assist federal civil immigration enforcement was adopted unanimously by voice vote, which C46 refuses as a position for any member, and no passage records her position on detainers, information sharing or the use of local police.',
  'local-environment': 'Searched blank. ' + SWEEP + ' No passage states a position on how the city should balance development against environmental preservation.',
  'city-sanitation': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'climate-change': 'Searched blank. ' + SWEEP + ' No passage states a position on clean energy mandates, subsidies or permitting.',
  'data-centers': 'Searched blank. ' + SWEEP + ' No passage names a data centre proposal or states a position on one.',
  childcare: 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'religious-freedom': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  '2020-election': 'Searched blank. ' + SWEEP + ' No passage states a view of the 2020 presidential election. 🔴 This corpus is full of other Kennedys, including a US cabinet secretary and three senators, and every passage was checked against that before being set aside.',
  'minimum-wage': 'Searched blank. ' + SWEEP + ' Duluth has no city minimum wage ordinance, so there is no local instrument, and no passage states a position on the wage floor. The lever exists, because Minn. Stat. 177.24 carries no local preemption clause, so this is not a scope blank.',
  'ranked-choice-voting': 'Searched blank. ' + SWEEP + ' Duluth’s only ranked choice matter is 15-0516R from 2015, which predates her term and is excluded. No passage states a position on the electoral method.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/kennedy-blanks.json', 'utf8'))];
for (const s of seated) rows.push({ full_name: N, ...s, quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const ev = [
  // 🔴 Kennedy is a COMMON surname, so checkNameProximity needs a title qualifier within 30 chars of
  // the name. Both snippets carry "5th District Councilor Janet Kennedy" or the full name.
  { topic_key: 'economic-development', source_url: MILL, snippet: cut(MILL, 'But 5th District Councilor Janet Kennedy', 'this is the time to stand back,') },
  { topic_key: 'economic-development', source_url: TIFPOL, snippet: cut(TIFPOL, 'Three city councilors who are members of the Duluth Economic Development Authority', 'the need for further direction.') },
];
const idx = {};
const evRows = ev.map((e) => { idx[e.topic_key] = (idx[e.topic_key] || 0) + 1; return { full_name: N, ...e, snippet_index: String(idx[e.topic_key]) }; });

fs.writeFileSync(B + '/_rows/kennedy-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/kennedy-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
console.log('unique topics:', new Set(rows.map((r) => r.topic_key)).size);
for (const e of evRows) console.log(`  ${e.topic_key} #${e.snippet_index}: ${e.snippet.split(/\s+/).length} words`);
