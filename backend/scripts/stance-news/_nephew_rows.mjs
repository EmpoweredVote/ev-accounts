import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Lynn Marie Nephew';

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost, Sahan Journal and Minnesota Reformer, over 23 queries covering both the three-token and two-token forms of her name, returned 804 unique articles. 42 of them name her and 36 were used; six were set aside because they also name a different Nephew, and the region has several, including a Fargo figure and an unrelated family in a news story. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. Her recorded votes were read from the council’s own roll calls: she is recorded on 30 of the 31 divided matters since she took office on 4 January 2024, 26 Yea and 4 Nay.';

const TERM = ' She took office on 4 January 2024. Statements she made as a candidate in the 2023 campaign are not used, which is how this slice has treated every member.';

const searched = {
  housing: 'Searched blank. ' + SWEEP + ' Her one substantive in-term housing remark is about short-term rentals: she said she would like the cap on vacation rentals to come down and licences for single-family homes to dwindle, to help alleviate the housing shortage, and she asked staff whether single-family vacation rentals could instead be capped per ZIP code as a percentage of housing stock. That is a preference about one regulatory cap, put partly as a question to staff. The five chairs here separate on whether government should build housing, impose binding rules on the private market, or subsidise, and one cap on one licence type does not choose between them.' + TERM,
  'residential-zoning': 'Searched blank. ' + SWEEP + ' She supported the ordinance barring new short-term rentals in single-family homes and said it has holes and is a place to start, and she and a colleague planned a resolution requiring the council to revisit it annually. Short-term rental licensing is not housing density. No passage states a position on duplexes, accessory dwellings, upzoning or single-family-only zoning.' + TERM,
  childcare: 'Searched blank. ' + SWEEP + ' She spoke for a zoning change opening childcare facilities to more neighborhoods, saying there are limited things the city can do to support childcare providers and that zoning is one of them. That is a supply measure delivered through zoning. Every rung of this ladder is about public money - universal public funding, expanded subsidies and provider grants, targeted tax credits, support limited to the lowest incomes, or none - and none of them describes using zoning. Her own framing, that the city’s levers here are limited, says why.',
  'homelessness-response': 'Searched blank. ' + SWEEP + ' She voted for the $500,000 increase for the Stepping on Up initiative and used her remarks to press St. Louis County, whose human services budget she put at about $114 million, to be a better partner, saying the work will not get done unless everyone works together and that this is a really great start. That is advocacy for another government to contribute. No passage states what level of city funding she thinks the response should carry, which is what this ladder asks.',
  homelessness: 'Searched blank. ' + SWEEP + ' She was one of the four councilors credited with preparing the 2024 public safety package and voted for the amended camping ordinance and for the $500,000 that went with it. Unlike two colleagues she is not quoted on what the enforcement should look like, so there is nothing to separate enforcement conditioned on shelter being available from a prohibition with civil penalties.',
  'economic-development': 'Searched blank. ' + SWEEP + ' Her quoted remarks on economic development come from the 2023 campaign, when she argued the city has little money coming in and that economic development is the biggest driver of revenue but is not currently possible because of housing.' + TERM + ' In office she voted with the majority on every subsidy and development instrument in the window and is not quoted on any of them.',
  'growth-and-development': 'Searched blank. ' + SWEEP + ' On the Lester Park golf course transfer she explained the mechanism, that the land use study is a condition of closing and that if the land cannot be developed it will not be transferred. That is a description of what the council decided, not a position on the pace of growth.',
  'public-safety-approach': 'Searched blank. ' + SWEEP + ' She voted for the 2024 public safety ordinance package and was credited with helping prepare it, but no passage records her choosing between policing and social services, which is what this ladder asks. This is also the ladder Charlotte recorded as defective for Season 3, because chairs 1 and 3 do not separate a member who funds both.',
  'rent-regulation': 'Searched blank. ' + SWEEP + ' She voted against the tenants’ petition ordinance on repairs and for the council’s own alternative, and she is not quoted on either. Every rung of this ladder is about the price of rent, Duluth has no rent stabilization, and she has proposed none. The gap is written up as defect 8 for Season 3.',
  'local-immigration': 'Searched blank. ' + SWEEP + ' She voted to table the eviction moratorium resolution, which is a procedural vote and not a position on the merits, and the ordinance barring the use of city resources to assist federal civil immigration enforcement was adopted unanimously by voice vote, which C46 refuses as a position for any member. No passage states a position on detainers, information sharing or the use of local police.',
  'transportation-priorities': 'Searched blank. ' + SWEEP + ' The ordinance creating a transportation commission was tabled at a meeting she chaired, and no passage records her view of it. Nothing states where she thinks transportation investment should go.',
  'local-environment': 'Searched blank. ' + SWEEP + ' No passage states a position on how the city should balance development against environmental preservation.',
  'city-sanitation': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'civil-rights': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'climate-change': 'Searched blank. ' + SWEEP + ' No passage states a position on clean energy mandates, subsidies or permitting.',
  'data-centers': 'Searched blank. ' + SWEEP + ' No passage names a data centre proposal or states a position on one.',
  'religious-freedom': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  '2020-election': 'Searched blank. ' + SWEEP + ' No passage states a view of the 2020 presidential election.',
  'minimum-wage': 'Searched blank. ' + SWEEP + ' Duluth has no city minimum wage ordinance, so there is no local instrument, and no passage states a position on the wage floor. The lever exists, because Minn. Stat. 177.24 carries no local preemption clause, so this is not a scope blank.',
  'ranked-choice-voting': 'Searched blank. ' + SWEEP + ' Duluth’s only ranked choice matter is 15-0516R from 2015, which predates her term and is excluded. No passage states a position on the electoral method.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/nephew-blanks.json', 'utf8'))];
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

fs.writeFileSync(B + '/_rows/nephew-rows.json', JSON.stringify(rows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length);
console.log('unique topics:', new Set(rows.map((r) => r.topic_key)).size);
