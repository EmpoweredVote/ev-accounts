import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Roger J. Reinert';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const read = (u) => fs.readFileSync('data/stance-news/reinert/' + key(u) + '.txt', 'utf8');

const H = 'https://www.duluthnewstribune.com/news/local/duluth-tackles-homeless-encampments-other-public-safety-issues';
const Z = 'https://www.duluthnewstribune.com/news/local/duluth-considers-changing-zoning-rules-in-hopes-of-boosting-housing';
const L = 'https://www.wdio.com/local-news/mayor-reinert-weighs-in-on-lester-park-debate/';

const cut = (u, from, to, last) => {
  const t = read(u);
  const i = last ? t.lastIndexOf(from) : t.indexOf(from);
  const j = t.indexOf(to, i);
  if (i < 0 || j < 0) throw new Error('snippet anchor not found: ' + from);
  const s = t.slice(i, j + to.length);
  if (!t.includes(s)) throw new Error('not verbatim: ' + from);
  if (s.split(/\s+/).length < 25) throw new Error('under 25 words: ' + from);
  return s;
};

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, returned 398 unique articles. Minnesota Reformer could not be searched and is not covered by this count. 146 of them name him, the densest corpus in this slice, and 141 were used; five were set aside because they also name a different Reinert. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. A mayor casts no votes, so his record was read from his own acts instead: across 1,914 event items in 76 meetings he has vetoed nothing and let exactly one ordinance pass unsigned.';

const TERM = ' He took office in January 2024. He served six years in the Minnesota Senate and two in the Minnesota House, ending about a decade ago, and that legislative record is not used here: it belongs to a different office and a different time.';

const seated = [
  {
    topic_key: 'homelessness', value: '5', evidence_type: 'statement',
    reasoning: 'Reinert proposed that city staff be empowered to charge people living in unauthorized encampments on city land with a misdemeanor carrying up to a $1,000 fine and as many as 90 days in jail. He argued for the criminal route by rejecting the civil one: the city’s only existing tool is an administrative citation with a financial penalty, and in his words individuals can tear those up and walk away, and many know it. He said a misdemeanor is not what the public safety team would lead with, but that when it is needed it creates a connection to the legal system and to justice that does not currently exist, a system that can provide resources and also hold individuals accountable for their behavior. He framed the package around public safety and the quality of life issues residents call about, and said the rules would be enforced uniformly across the community. That is chair 5: banning public camping with criminal penalties to maintain public safety and order. Chair 4 is excluded by his own argument, because civil penalties are exactly what he called ineffective. Chair 3 is excluded for the same reason in reverse: it routes people to services rather than into the criminal justice system, and he argues the criminal connection is what makes services reachable. Two things cut the other way and the reviewer should weigh them: his proposal applied only where other housing was available, and he noted the city had invested nearly $24 million over three years in housing, shelter and services. The council refused the misdemeanor and cut the penalty to a $200 fine.',
    source_url_1: H, source_url_2: '', source_url_3: '',
  },
  {
    topic_key: 'residential-zoning', value: '4', evidence_type: 'statement',
    reasoning: 'Reinert supports the Unified Development Chapter rewrite and summed up his position as needing all the kinds of housing in all the places, saying the changes are meant to make it easier and faster to build single family, duplex, triplex and higher density housing, and that the city cannot afford a reputation for being hard to build in when it badly needs more. The ordinance he is backing allows fourplexes in areas zoned Residential-Traditional, cuts minimum lot widths and setbacks, raises height maximums and lets housing types that now need a special-use permit go into more districts. That is chair 4: upzoning broadly so multifamily is allowed by right in most neighborhoods. Chair 5 is the rhetorical reading of all the kinds in all the places, and it is excluded by what the instrument actually does, because it neither eliminates single-family zoning nor allows any type on any lot. Chairs 2 and 3 are excluded because fourplexes in traditional residential areas go well beyond duplexes and accessory units, and well beyond multifamily confined to commercial corridors. Chair 1 is excluded outright.' + TERM,
    source_url_1: Z, source_url_2: '', source_url_3: '',
  },
  {
    topic_key: 'growth-and-development', value: '4', evidence_type: 'statement',
    reasoning: 'Reinert argues the city must grow its way out of its finances. He puts the deferred maintenance liability on city and park facilities at $118 million and says the only way a city running year-on-year deficits can do better than a C minus job on its parks is by generating more tax base, and that the best way to raise revenue without adding to the burden on homeowners and businesses is to grow the housing stock and the commercial tax base. On the former Lester Park golf course he said what the city cannot afford is to do nothing, because the site has sat for six years deteriorating in place. The zoning rewrite he backs is explicitly about making building easier and faster. That is chair 4: actively pushing for faster growth and cutting red tape, while keeping basic guardrails, and the guardrails are there too, because he insists the Lester Park question goes through the planning commission and the council and expects the land use study alone to take at least a year. Chair 3 is excluded by his own reasoning rather than by silence: investing in infrastructure ahead of demand is precisely what he says the city cannot afford, which is why he wants the growth first. Chair 5 is excluded because he keeps the public process. Chairs 1 and 2 are excluded outright.',
    source_url_1: L, source_url_2: '', source_url_3: '',
  },
];

const searched = {
  housing: 'Searched blank. ' + SWEEP + ' He wants far more housing built and says a lack of it limits the city’s ability to grow employment, business and the tax base. That is a supply argument, and it is recorded on his zoning and growth rows. This ladder asks something different: whether government should build housing itself, impose binding rules on the private market, or subsidise. No passage states a position on that.',
  'rent-regulation': 'Searched blank. ' + SWEEP + ' The one ordinance he let pass without his signature is the council’s tenant ordinance on landlord training, notification and timely repairs. Not signing has two readings, disapproval or simply letting a measure take effect, and no reporting in the corpus says which, so it is a lead and not a position. In any case every rung of this ladder is about the price of rent, Duluth has no rent stabilization, and he has proposed none. The gap is written up as defect 8 for Season 3.',
  'public-safety-approach': 'Searched blank. ' + SWEEP + ' He brought forward a public safety ordinance package, says the data shows Duluth remains a safe community, and describes his aim as a balance between caring for people on the margins and the public safety concerns residents raise. The balance is the problem: this ladder’s chairs 1 and 3 do not separate a member who funds both, which is the defect Charlotte recorded for Season 3. Nothing in the corpus chooses between policing and social services as the primary response.',
  'homelessness-response': 'Searched blank. ' + SWEEP + ' He noted the city had invested nearly $24 million over three years in housing, shelter and services, and that the city, county and state relationship is critical as the city looks for financial resources. That is a description of what has been spent and an appeal for partners. No passage states what level of city funding he thinks the response should carry, which is what this ladder asks.',
  'economic-development': 'Searched blank. ' + SWEEP + ' He wants to grow the commercial tax base and joined a Great Lakes initiative board citing regional economic opportunity, but no passage states a position on business incentives: whether to offer them, on what conditions, or at what scale. His predecessors’ and the council’s tax increment financing decisions are council votes, which a mayor does not cast.',
  'local-environment': 'Searched blank. ' + SWEEP + ' On Lester Park he speaks about hiking, biking, skiing, snowshoeing, birding and disc golf as uses to incorporate, and about the city’s deferred maintenance liability. That is about park programming and finance. No passage states how he thinks the city should balance development against environmental preservation as a general matter.',
  'transportation-priorities': 'Searched blank. ' + SWEEP + ' His quoted remarks touching transport concern closing streets for a marathon and lobbying the legislature. Nothing states where he thinks transportation investment should go.',
  'local-immigration': 'Searched blank. ' + SWEEP + ' The ordinance barring the use of city resources to assist federal civil immigration enforcement was brought by councilors and adopted unanimously by voice vote, which C46 refuses as a position for any member, and no passage records the mayor stating a position on detainers, information sharing or the use of local police.',
  'city-sanitation': 'Searched blank. ' + SWEEP + ' He has spoken about focusing the city on what it must do, naming animal control, and about partnering with a humane society for animal care. That is a position about which services the city runs directly, and animal control is not sanitation. No passage states a position on any rung of this ladder.',
  'civil-rights': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'climate-change': 'Searched blank. ' + SWEEP + ' No passage states a position on clean energy mandates, subsidies or permitting.',
  'data-centers': 'Searched blank. ' + SWEEP + ' No passage names a data centre proposal or states a position on one.',
  childcare: 'Searched blank. ' + SWEEP + ' He has spoken about long term care for older residents, which is a different subject. No passage states a position on childcare.',
  'religious-freedom': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  '2020-election': 'Searched blank. ' + SWEEP + ' No passage states a view of the 2020 presidential election.',
  'minimum-wage': 'Searched blank. ' + SWEEP + ' Duluth has no city minimum wage ordinance, so there is no local instrument, and no passage states a position on the wage floor. The lever exists, because Minn. Stat. 177.24 carries no local preemption clause, so this is not a scope blank.',
  'ranked-choice-voting': 'Searched blank. ' + SWEEP + ' Duluth’s only ranked choice matter is 15-0516R from 2015, which predates his term as mayor and is excluded. No passage states a position on the electoral method.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/reinert-blanks.json', 'utf8'))];
for (const s of seated) rows.push({ full_name: N, ...s, quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const ev = [
  { topic_key: 'homelessness', source_url: H, snippet: cut(H, 'Mayor Roger Reinert had proposed', 'unless other housing is available for them.') },
  { topic_key: 'homelessness', source_url: H, snippet: cut(H, 'He noted Duluth does not have the option', 'no more than a financial penalty.') },
  { topic_key: 'homelessness', source_url: H, snippet: cut(H, 'A misdemeanor is not something our public safety team', 'which sometimes needs to happen,') },
  { topic_key: 'residential-zoning', source_url: Z, snippet: cut(Z, 'Mayor Roger Reinert told the News Tribune', 'triplex, higher density.') },
  { topic_key: 'residential-zoning', source_url: Z, snippet: cut(Z, 'He added that he hopes it helps buck', 'when we desperately need more,') },
  { topic_key: 'growth-and-development', source_url: L, snippet: cut(L, 'Reinert said the city is facing $118 million', 'grow our commercial tax base.') },
];
const idx = {};
const evRows = ev.map((e) => { idx[e.topic_key] = (idx[e.topic_key] || 0) + 1; return { full_name: N, ...e, snippet_index: String(idx[e.topic_key]) }; });

fs.writeFileSync(B + '/_rows/reinert-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/reinert-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
console.log('unique topics:', new Set(rows.map((r) => r.topic_key)).size);
for (const e of evRows) console.log(`  ${e.topic_key} #${e.snippet_index}: ${e.snippet.split(/\s+/).length} words`);
