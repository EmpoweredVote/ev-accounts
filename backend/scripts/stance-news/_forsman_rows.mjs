import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Arik Forsman';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const read = (u) => fs.readFileSync('data/stance-news/forsman/' + key(u) + '.txt', 'utf8');

const HOMELESS = 'https://www.duluthnewstribune.com/news/local/duluth-tackles-homeless-encampments-other-public-safety-issues';
const MILL = 'https://www.duluthnewstribune.com/news/local/duluth-city-council-backs-paper-mill-subsidy-despite-skeptics';
const TIFPOL = 'https://www.duluthnewstribune.com/news/local/duluth-shapes-policy-to-guide-future-use-of-tax-subsidies-for-developers';

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

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, returned 547 unique articles. Minnesota Reformer was searched separately and added one article naming him. 79 of them name him and 67 were used; 12 were set aside because they also name a different Forsman, and there are six of those in the region, including a St. Louis County commissioner. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. His recorded votes were read from the council’s own roll calls: he is recorded on all 31 divided matters since January 2024, 26 Yea and 5 Nay.';

const seated = [
  {
    topic_key: 'homelessness', value: '3', evidence_type: 'statement',
    reasoning: 'Forsman put forward the 2024 camping ordinance with three colleagues and voted for it. The mayor had proposed charging people who camp on city land with a misdemeanor carrying up to a $1,000 fine and 90 days in jail; councilors refused to charge people with a crime for having no other suitable place to go, and cut the penalty to a fine of no more than $200. Forsman described the result as balancing the city’s obligations while trying to provide a safe place for people to be, and on the same night he voted for a further $500,000 that brought the city’s investment in the Stepping on Up initiative, which is opening sanctioned campsites, to $1.15 million. That combination is chair 3: enforcement that stays out of the criminal justice system, paired with creating somewhere for people to go. Chair 5 is excluded because he voted to remove the criminal penalty. Chair 4 is the closest alternative and is excluded because the measure is not a bare prohibition with penalties: the council conditioned it on people having an alternative, which is what chair 3 adds. Chairs 1 and 2 are excluded because he voted for a prohibition rather than against one. Note for the reviewer: the enacted text of Duluth City Code section 34-46 goes further than the reporting does, allowing prosecution only after an officer has told the person what shelter and services are available and, at night, has confirmed and documented that overnight shelter is available to them. That text was read from the council’s own legislative record, which publishes no citable page, so the row rests on the reporting instead.',
    source_url_1: HOMELESS, source_url_2: '', source_url_3: '',
  },
  {
    topic_key: 'economic-development', value: '4', evidence_type: 'statement',
    reasoning: 'Forsman is the council’s most consistent supporter of large incentives for large employers, and he also writes the limits on them. On the Sofidel package, which offered an Italian paper company up to $18.425 million in tax increment financing alongside state funds, he called the expansion a fantastic investment in our community, said he could not be happier to see a $250 million investment and roughly 160 more jobs, and argued Duluth should not risk losing the opportunity when other communities would compete for it, adding that the city needs to step up when it has the chance. That is chair 4’s first half. The second half is evidenced too: as one of three councilors on the Duluth Economic Development Authority he helped shape and introduce the resolution setting policy on how the city should use tax increment financing in future, pointing to an agreement that went off the rails as the reason further direction was needed. Chairs 1 and 2 are excluded because he supports subsidy for a large outside company. Chair 5 is excluded because he is building limits rather than refusing them. Chair 3 is excluded because the conditions he works on are city-side policy direction, and he names no wage or local hiring commitment and no clawback.',
    source_url_1: MILL, source_url_2: TIFPOL, source_url_3: '',
  },
];

const searched = {
  'homelessness-response': 'Searched blank. ' + SWEEP + ' He voted for the $500,000 increase that took the city’s investment in Stepping on Up to $1.15 million, which reads as chair 2, and in the same breath bounded it: the city as an entity does not have the funding to do this alone, partners and foundations and private citizens must step up and close the gaps, and the city has many other responsibilities and many claims on its tax dollars, which reads as chair 4. The vote and the words point at different chairs and nothing in the corpus separates them.',
  'residential-zoning': 'Searched blank. ' + SWEEP + ' He speaks about zoning constantly, but as a decision maker explaining particular parcels: what the residential planned zoning area tool allows, that a developer with land already zoned for development has a legal right to proceed, what the Planning Commission will consider next. He supported rezonings for density at Woodland Avenue and Hawk Ridge against neighbourhood objection, and he supported barring new short-term rentals in single-family neighborhoods. None of that states a policy for housing density, which is what every rung here asks: by-right multifamily, duplexes and accessory dwellings, or the end of single-family-only zoning.',
  'growth-and-development': 'Searched blank. ' + SWEEP + ' He argued the Lester Park golf course is not at its highest and best use and that the city should plan it with the lens that it is a housing development site, welcomed a proposed $500 million redevelopment of the Central High School site with more than 1,300 units, and after a withdrawn rezoning said the city should decide its approach for developers whose projects do not fit the code. That is a direction, and it is consistent with chair 4. But he pairs it with insisting on a full public process and taking time, which is chair 4’s opposite on red tape, and no passage states a view on the pace of growth as such.',
  'public-safety-approach': 'Searched blank. ' + SWEEP + ' He told the council that cutting its way to greatness to preserve public safety is not sustainable financially and that the city has to grow its revenues, and he wanted police and fire funding restored while saying the city offers too many other services for all of its focus and funding to go to public safety. Those are budget positions. Nothing chooses between policing and social services, which is what this ladder asks. This is also the ladder Charlotte recorded as defective for Season 3, because chairs 1 and 3 do not separate a member who funds both.',
  'rent-regulation': 'Searched blank. ' + SWEEP + ' He voted against the tenants’ petition ordinance on repairs and for the council’s own alternative, and on the ICE rent relief he said rental assistance is the fastest path and that nobody on the council would vote against doing something. All of that is habitability and emergency assistance. Every rung of this ladder is about the price of rent, Duluth has no rent stabilization, and he has proposed none. The gap is written up as defect 8 for Season 3.',
  housing: 'Searched blank. ' + SWEEP + ' He supports large housing developments and said affordable housing within existing gaps should be in the mix for unspent authority funds, while wanting the authority’s flexibility used for maximum impact. That welcomes supply and keeps options open. It does not choose between the five chairs, which separate on whether government should build housing, impose binding rules on the private market, or subsidise.',
  'local-immigration': 'Searched blank. ' + SWEEP + ' His remarks on the ICE enforcement surge concern rental assistance rather than law enforcement, and the ordinance barring the use of city resources to assist federal civil immigration enforcement was adopted unanimously by voice vote, which C46 refuses as a position for any member. No passage states a position on detainers, information sharing or the use of local police.',
  'transportation-priorities': 'Searched blank. ' + SWEEP + ' On the transit levy he made a procedural point, that no cut was proposed and the reduction was from a proposed 43% increase. That is a correction about a budget figure, not a position on where transportation investment should go.',
  'local-environment': 'Searched blank. ' + SWEEP + ' On the Lester Park golf course and on the Hawk Ridge and Woodland Avenue rezonings his quoted remarks describe zoning tools, green space provisions and what the Planning Commission will weigh. No passage states how he thinks the city should balance development against environmental preservation.',
  'city-sanitation': 'Searched blank. ' + SWEEP + ' His quoted remarks on the skywalk concern a study of the system and whether it feels safe. No passage states a position on any rung of this ladder.',
  'climate-change': 'Searched blank. ' + SWEEP + ' He works for a regional electric utility, which the coverage notes, but no passage states a position on clean energy mandates, subsidies or permitting.',
  childcare: 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'civil-rights': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'data-centers': 'Searched blank. ' + SWEEP + ' No passage names a data centre proposal or states a position on one.',
  'religious-freedom': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  '2020-election': 'Searched blank. ' + SWEEP + ' No passage states a view of the 2020 presidential election.',
  'minimum-wage': 'Searched blank. ' + SWEEP + ' Duluth has no city minimum wage ordinance, so there is no local instrument, and no passage states a position on the wage floor. The lever exists, because Minn. Stat. 177.24 carries no local preemption clause, so this is not a scope blank.',
  'ranked-choice-voting': 'Searched blank. ' + SWEEP + ' Duluth’s only ranked choice matter is 15-0516R from 2015, which predates his term and is excluded. No passage states a position on the electoral method.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/forsman-blanks.json', 'utf8'))];
for (const s of seated) rows.push({ full_name: N, ...s, quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const ev = [
  { topic_key: 'homelessness', source_url: HOMELESS, snippet: cut(HOMELESS, 'Mayor Roger Reinert had proposed', 'unless other housing is available for them.') },
  { topic_key: 'homelessness', source_url: HOMELESS, snippet: cut(HOMELESS, 'But councilors balked', 'no more than a $200 fine.') },
  { topic_key: 'homelessness', source_url: HOMELESS, snippet: cut(HOMELESS, 'So, as we balance all those things', 'to get this ready,') },
  { topic_key: 'homelessness', source_url: HOMELESS, snippet: cut(HOMELESS, 'The city as an entity does not have the funding', 'to $1.15 million.') },
  { topic_key: 'economic-development', source_url: MILL, snippet: cut(MILL, 'At large Councilor Arik Forsman referred to', 'that already employs about 80 workers.') },
  { topic_key: 'economic-development', source_url: MILL, snippet: cut(MILL, 'Forsman suggested Duluth should not risk losing out', 'when we have the opportunity to do so,') },
  { topic_key: 'economic-development', source_url: TIFPOL, snippet: cut(TIFPOL, 'Three city councilors who are members of the Duluth Economic Development Authority', 'the need for further direction.') },
];
const idx = {};
const evRows = ev.map((e) => { idx[e.topic_key] = (idx[e.topic_key] || 0) + 1; return { full_name: N, ...e, snippet_index: String(idx[e.topic_key]) }; });

fs.writeFileSync(B + '/_rows/forsman-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/forsman-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
console.log('unique topics:', new Set(rows.map((r) => r.topic_key)).size);
for (const e of evRows) console.log(`  ${e.topic_key} #${e.snippet_index}: ${e.snippet.split(/\s+/).length} words`);
