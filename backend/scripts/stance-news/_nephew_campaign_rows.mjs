// Re-research of Lynn Marie Nephew's campaign-decided rows under the ruling of 2026-10-05
// (Chris Cantrell: campaign statements count, and they need a link).
//
// Three rows — housing, residential-zoning, economic-development — were decided on the old
// exclusion and carried a sentence asserting it. That sentence is now false and comes out.
// Two more — homelessness-response and growth-and-development — were never flagged, but the
// campaign material bears on them and was never weighed against them, so they are rewritten too.
//
// Result: still no chair. The campaign material names topics, not rungs.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Lynn Marie Nephew';

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries covering both the three-token and two-token forms of her name, returned 804 unique articles. Minnesota Reformer was searched separately and added no article naming her. 42 of them name her and 36 were used; six were set aside because they also name a different Nephew, and the region has several, including a Fargo figure and an unrelated family in a news story. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. Her recorded votes were read from the council’s own roll calls: she is recorded on 30 of the 31 divided matters since she took office on 4 January 2024, 26 Yea and 4 Nay.';

// Campaign statements are admissible from the ruling of 2026-10-05. Date-stamped so a reviewer can
// weigh staleness: all of it is from the 2023 campaign, two years before this research.
const CAMPAIGN = ' Her statements as a candidate were read and are used. She was elected to an at large seat on 7 November 2023 and took office on 4 January 2024, so this material is from the 2023 campaign. Three pieces carry her own words: WDIO’s report of the at large candidates’ public forum; the News Tribune editorial board’s endorsement of 26 October 2023, which quotes her from a forum it co-hosted that September; and the News Tribune’s election night report of 7 November 2023.';

const rows = [
  {
    topic_key: 'housing',
    reasoning: 'Searched blank. ' + SWEEP + ' Her one substantive in-term housing remark is about short-term rentals: she said she would like the cap on vacation rentals to come down and licences for single-family homes to dwindle, to help alleviate the housing shortage, and she asked staff whether single-family vacation rentals could instead be capped per ZIP code as a percentage of housing stock. That is a preference about one regulatory cap, put partly as a question to staff.' + CAMPAIGN + ' At the forum she said she is part of a nonprofit start up that secured a building and is creating supportive housing units, that more of these programs need to be encouraged, and that creating more housing units in general will take pressure off the system; the reporter writes that she said the council should focus on changing city ordinances in order to build more homes. That is a consistent supply argument, and it still does not choose a chair here. She never names the instruments this ladder separates on: she does not mention subsidies or tax breaks, which is chair 4, and she does not say prices and supply should be left to the market, which is chair 5. The word encouraged is not a funding posture. Her in-term position points the other way again, because a cap on vacation rental licences is a binding rule on the private market. The campaign material widens the record and leaves the same three chairs open.',
  },
  {
    topic_key: 'residential-zoning',
    reasoning: 'Searched blank. ' + SWEEP + ' She supported the ordinance barring new short-term rentals in single-family homes and said it has holes and is a place to start, and she and a colleague planned a resolution requiring the council to revisit it annually. Short-term rental licensing is not housing density.' + CAMPAIGN + ' The one campaign passage that touches zoning is the reporter’s line that she said the council should focus on changing city ordinances in order to build more homes. It names no level of density. Nothing in it states a position on duplexes, accessory dwellings, multifamily by right, or single-family-only zoning, which is what the five chairs separate on.',
  },
  {
    topic_key: 'economic-development',
    reasoning: 'Searched blank. ' + SWEEP + ' In office she voted with the majority on every subsidy and development instrument in the window and is not quoted on any of them.' + CAMPAIGN + ' Her campaign remarks on this subject are a sequencing argument, made twice. To the endorsement forum she said the city does not have a lot of money coming in, that the biggest driver for money generation is economic development, that she would argue it is currently not possible, and that the city needs to increase housing units so it can have sustainable economic development. On election night she said housing is affecting economic development because the city cannot do that, and that it leads back into the underfunding of core city services. That is a claim about what must come first. Every rung of this ladder is about business incentives - whether to offer them, to whom, and on what conditions - and she names no incentive, no condition and no clawback. The axis she argues on is not the axis this ladder measures.',
  },
  {
    topic_key: 'homelessness-response',
    reasoning: 'Searched blank. ' + SWEEP + ' She voted for the $500,000 increase for the Stepping on Up initiative and used her remarks to press St. Louis County, whose human services budget she put at about $114 million, to be a better partner, saying the work will not get done unless everyone works together and that this is a really great start. That is advocacy for another government to contribute.' + CAMPAIGN + ' The at large forum put this subject directly to the candidates, and her answer was that she is part of a nonprofit start up creating supportive housing units for people who experience long term frustration, and that more of these programs need to be encouraged to help the homeless population. This ladder asks how much the community should spend. She names no funding level and no funding source. Encouraging nonprofit programmes could be chair 4, which has limited public funding going to nonprofits to lead the response, or chair 2, which expands public funding; her words choose neither, and she does not say the city should pay for the programmes she praises.',
  },
  {
    topic_key: 'growth-and-development',
    reasoning: 'Searched blank. ' + SWEEP + ' On the Lester Park golf course transfer she explained the mechanism, that the land use study is a condition of closing and that if the land cannot be developed it will not be transferred. That is a description of what the council decided, not a position on the pace of growth.' + CAMPAIGN + ' Her campaign remarks come closer to this ladder than to any other, and still fall short of it. She said the city does not have enough housing units to support growth and needs to increase them so it can have sustainable economic development. That is a statement about a precondition for growth, not about how fast growth should be allowed to go. Chair 2 makes development wait for capacity and chair 3 invests ahead of demand so expansion is not held back; building the housing stock so that growth becomes possible is consistent with both, and she states no preferred pace.',
  },
].map((r) => ({
  full_name: N, topic_key: r.topic_key, value: '', evidence_type: '', reasoning: r.reasoning,
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
}));

// Control: the sentence asserting the old standard must not survive anywhere in this file.
const OLD = 'are not used, which is how this slice has treated every member';
const survivors = rows.filter((r) => r.reasoning.includes(OLD));
if (survivors.length) { console.error('REFUSING: old-standard sentence survives in', survivors.map((r) => r.topic_key)); process.exit(1); }

fs.writeFileSync(B + '/_rows/nephew-campaign-rows.json', JSON.stringify(rows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length);
console.log('topics:', rows.map((r) => r.topic_key).join(', '));
