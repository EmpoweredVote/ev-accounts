import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Wendy Durrwachter';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const read = (u) => fs.readFileSync('data/stance-news/durrwachter/' + key(u) + '.txt', 'utf8');

const CAR = 'https://www.wdio.com/top-stories/duluth-city-councilors-advocate-strong-federal-clean-car-standards/';
const MILL = 'https://www.duluthnewstribune.com/news/local/duluth-city-council-backs-paper-mill-subsidy-despite-skeptics';
const TIF = 'https://www.duluthnewstribune.com/news/local/duluth-shapes-policy-to-guide-future-use-of-tax-subsidies-for-developers';

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

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost, Sahan Journal and Minnesota Reformer, over 46 queries covering both spellings of her surname, returned 586 unique articles. 38 of them name her and all 38 were read. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. Her recorded votes were read from the council’s own roll calls: 31 divided votes across 76 meetings since she took office on 4 January 2024.';

const seated = [
  {
    topic_key: 'climate-change', value: '1', evidence_type: 'statement',
    reasoning: 'Durrwachter publicly campaigned for stronger federal clean car standards, framed around a zero emission target for Minnesota by 2050. Her own words name a mandate and a deadline: the councilors were calling on the federal administration and the EPA to finalize the strongest possible federal clean car standards by the end of that month. That is chair 1, which requires a shift to clean energy through mandates and firm deadlines. Chair 2 is excluded because she asks for standards rather than subsidies or public investment; the only money she mentions is what a driver saves, not what government spends. Chair 3 is excluded because she says nothing about permitting or the grid. Chairs 4 and 5 are excluded outright by the act of calling for stronger standards. The article is dated 14 March 2024, inside the term that began on 4 January 2024.',
    source_url_1: CAR, source_url_2: '', source_url_3: '',
  },
  {
    topic_key: 'economic-development', value: '2', evidence_type: 'statement',
    reasoning: 'Durrwachter was the lone vote against both city instruments subsidising Sofidel, an Italian paper company expanding its Duluth mill, and she gave her reason in public: she questioned the need to provide a $3 billion multi-national company with tax relief at a time when the city was raising its own property tax levy, and said the city should wait until a more compelling case for a subsidy was made. On the city’s wider use of the tool she said she felt the city had been abusing tax increment financing to push projects forward, so that the public loses access to its tax base for years and the burden shifts onto other local property owners. That is chair 2, which refuses subsidy offered to attract a large outside company. Chair 1 is excluded because she did not call for an end to incentives; she supported giving staff and developers clearer guidance on how the city intends to use tax increment financing, and asked for greater specificity in that policy. Chair 3 is excluded because she names no wage or local hiring condition and no clawback. Chairs 4 and 5 are excluded because she opposed the large tax break rather than treating it as the approach to keep within limits. Two things the reviewer should weigh. First, chair 2 also says a city should help small and local businesses grow, and nothing in the record evidences that half. Second, she was also the lone vote against two subsidies for local housing projects, but in both cases she said she wanted the project built and objected to the vetting of the developer and to the public not having the documents, so those votes are not evidence of this position.',
    source_url_1: MILL, source_url_2: TIF, source_url_3: '',
  },
];

const searched = {
  homelessness: 'Searched blank. ' + SWEEP + ' She voted against the camping ordinance of 29 July 2024, which prohibited camping on city property and which the council amended down from the mayor’s proposed misdemeanor to a fine of no more than $200. The News Tribune reports that she and two colleagues voted against it citing what they viewed as a need for more work, and that a fourth member joined the minority for the opposite reason, wanting the tougher line the mayor had proposed. A need for more work is not a rung, and a 5 to 4 tally whose minority contains both poles cannot be read as a position. She voted for the same evening’s resolution committing $500,000 to accelerate new capacity, which is consistent with several rungs rather than one.',
  'rent-regulation': 'Searched blank. ' + SWEEP + ' Her tenant record is the strongest on the council and none of it is about rent. She voted for the tenants’ petition ordinance on repairs and against the council’s own alternative on the same night, argued that the petition was simple and would not cost taxpayer dollars, and co-authored the resolution asking the state for a temporary eviction moratorium with $50 million in rental assistance. Every rung of this ladder is about the price of rent. Duluth has no rent stabilization and she has proposed none. The gap is written up as defect 8 for Season 3.',
  housing: 'Searched blank. ' + SWEEP + ' She was the lone vote against tax subsidies for a housing project near Lake Superior College and against the Incline Village development agreement. In both cases she said she wanted the housing built: of the first that it was a project she would like to see built, and of the second that she would love for the property to be developed for housing. Her objections were that the public did not have the documents and that the administration had not vetted the developer. Those are objections to process, and they do not choose between the five chairs, which separate on whether government should build housing, impose binding rules, or subsidise.',
  'local-immigration': 'Searched blank. ' + SWEEP + ' Her own initiative on the ICE enforcement surge was the eviction moratorium, which is a housing measure. The resolution barring any city resource from being used to assist or facilitate enforcement of federal civil immigration laws was brought by four other councilors and adopted unanimously by voice vote, which C46 refuses as a position for any member. Her quoted remarks are about the conduct of federal agents rather than about detainers, information sharing or the use of local police, which is what this ladder asks.',
  'public-safety-approach': 'Searched blank. ' + SWEEP + ' Her quoted remarks on police concern spending restraint, telling the council that it must moderate its spending and not forget the struggles of citizens. Nothing chooses between policing and social services, which is what this ladder asks. This is also the ladder Charlotte recorded as defective for Season 3, because chairs 1 and 3 do not separate a member who funds both.',
  'growth-and-development': 'Searched blank. ' + SWEEP + ' On the Lester Park golf course land use decision she urged the council to consider how local overflowing schools would handle more students, which is the reasoning chair 2 describes. It is a single remark, reported indirectly as a call to consider rather than as a position, and that decision carries no recorded vote at all. One remark asking colleagues to weigh a factor is closer to a study call than to a chair.',
  'transportation-priorities': 'Searched blank. ' + SWEEP + ' She opposed the amendment that would have halved the Duluth Transit Authority levy increase, saying that some of the most vulnerable people in the community use the bus and that she supported making the service as efficient yet useful as possible. That defends transit funding but never compares transit with road capacity, which is what every rung of this ladder turns on.',
  'residential-zoning': 'Searched blank. ' + SWEEP + ' She supported barring new vacation rentals from neighborhoods of single-family homes and said she supported that part fully, while wanting the city to address unlicensed rentals. Short-term rental permitting is not housing density. No passage states a position on duplexes, accessory dwellings, upzoning or single-family-only zoning, which is what this ladder asks.',
  'local-environment': 'Searched blank. ' + SWEEP + ' She asked the city to advocate formally for the future of the federal Great Lakes Toxicology and Ecology Division laboratory in Duluth. That is advocacy for one federal facility, not a position on how the city should balance development against environmental preservation.',
  childcare: 'Searched blank. ' + SWEEP + ' Her remarks on childcare come from a campaign meet and greet in Lester Park, where she said she had been hearing that child care is hard to find and that waiting lists are long. That was before she took office on 4 January 2024, and reporting what she heard from residents names no rung in any event.',
  'city-sanitation': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'civil-rights': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'data-centers': 'Searched blank. ' + SWEEP + ' No passage names a data centre proposal or states a position on one.',
  'homelessness-response': 'Searched blank. ' + SWEEP + ' She voted for the resolution committing $500,000 of American Rescue Plan funding to accelerate new capacity, and she argued for $50 million of state rental assistance to prevent displacement. Both are support for particular allocations, one of them from the state rather than the city. No passage states what level of city funding she thinks the response should carry, which is what this ladder asks.',
  'religious-freedom': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  '2020-election': 'Searched blank. ' + SWEEP + ' No passage states a view of the 2020 presidential election.',
  'minimum-wage': 'Searched blank. ' + SWEEP + ' Duluth has no city minimum wage ordinance, so there is no local instrument, and no passage states a position on the wage floor. The lever exists, because Minn. Stat. 177.24 carries no local preemption clause, so this is not a scope blank.',
  'ranked-choice-voting': 'Searched blank. ' + SWEEP + ' Duluth’s only ranked choice matter is 15-0516R from 2015, which predates her term and is excluded. No passage states a position on the electoral method.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/durrwachter-blanks.json', 'utf8'))];
for (const s of seated) rows.push({ full_name: N, ...s, quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const ev = [
  { topic_key: 'climate-change', source_url: CAR, snippet: cut(CAR, 'Duluth City Councilors Mike Mayou and Wendy Durrwachter advocate for stronger federal clean car standards to help', 'zero emission future.') },
  { topic_key: 'climate-change', source_url: CAR, snippet: cut(CAR, 'Councilor Wendy Durrwachter also said one way', "the vehicle's lifetime,") },
  { topic_key: 'climate-change', source_url: CAR, snippet: cut(CAR, 'all for cars being preserved', 'by the end of this month.') },
  { topic_key: 'economic-development', source_url: MILL, snippet: cut(MILL, 'At a time when Duluth is considering increases', 'could be made for a tax subsidy.') },
  { topic_key: 'economic-development', source_url: TIF, snippet: cut(TIF, 'That scrutiny is justified in the eyes of', 'onto other local property owners.') },
];
const idx = {};
const evRows = ev.map((e) => { idx[e.topic_key] = (idx[e.topic_key] || 0) + 1; return { full_name: N, ...e, snippet_index: String(idx[e.topic_key]) }; });

fs.writeFileSync(B + '/_rows/durrwachter-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/durrwachter-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
console.log('unique topics:', new Set(rows.map((r) => r.topic_key)).size);
for (const e of evRows) console.log(`  ${e.topic_key} #${e.snippet_index}: ${e.snippet.split(/\s+/).length} words`);
