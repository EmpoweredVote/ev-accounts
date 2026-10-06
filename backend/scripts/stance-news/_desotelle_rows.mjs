// Diane Desotelle — Duluth 2nd District, seated 2026-01-05. 35 rows, 1 chair.
//
// A former civil engineer in water resource management; chairs Public Works and Utilities.
// Her corpus is small and clean: 28 files, 27 naming her, 96% signal, no spelling variants.
// The chair does not come from the corpus at all — it comes from Legistar's sponsor list.
import fs from 'node:fs';
import { URL_26_0100R, CHAIR_3_REASONING, buildSnippet } from './_legistar_26_0100R.mjs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Diane Desotelle';

const SNIP = await buildSnippet();

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, fetched 509 articles and kept 28, of which 27 name Diane Desotelle: 96% signal, and the surname has one spelling across every outlet. Two of the 27 also name a different Desotelle, so no bare-surname attribution was trusted in them. Minnesota Reformer was searched separately, with a control run at both ends, and returned nothing for her - a measured zero. Sahan Journal and the Saint Paul Pioneer Press also contributed nothing and are blind here rather than empty. Because she took office recently and her own corpus is small, the other eight Duluth corpora in this slice were read for her as well; ten further articles name her there. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. MPR News and Racket are not covered either: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one. She took office on 5 January 2026, so C44 excludes everything the council did before that date. In the nine months since, the council has divided on two matters and she voted Nay on both: the resolution confirming Housing Trust Fund Committee appointments, which is an appointment rather than a policy, and a motion to table, which is procedural. Her statements as a candidate are used, under the ruling of 2026-10-05; she won the second district with 79.8% of the vote in November 2025.';

const seated = [
  {
    topic_key: 'local-immigration',
    value: '3',
    evidence_type: 'record',
    source_url_1: URL_26_0100R,
    reasoning: 'Desotelle is the third-named sponsor of this resolution. ' + CHAIR_3_REASONING + ' Nothing in her own quoted record cuts against it: the corpus carries no passage of hers on detainers, information sharing or local police and immigration, so this row rests on the instrument alone.',
  },
];

const searched = {
  'local-environment': 'She has more material here than any other member of this slice and it still names no rung. On the Lester Park decision, which developed 63 acres and left 207 in open space, she said all of these lands are very important to the city, that Duluth is fortunate to have about 25% of its lands as open space, and that studies show cities without it do not have the same water quality, diversity of habitat or happiness index. On the 2024 Tischer Creek fishkill, where treated drinking water released from a reservoir killed more than 2,000 fish, she explained the mechanism - if you put too much chlorine in an aquarium your fish will not survive - and, on the $202,000 settlement with the DNR and the Pollution Control Agency, said the biggest value lost came from recreational fishing and that this is what is meant by ecosystem services, and that the city had made a mistake and the money would go back into the resource. At her swearing in she said it would be exciting to have a councilor with an environmental background as the council thinks about open spaces and how to balance that use with housing and economics. That last sentence names the question this ladder asks and answers it with a perspective rather than a position. Everything else is a valuation of environmental assets and an account of remediation after a pollution incident. She never states how far protection should constrain development: no development she would block or sharply limit, no burden of proof on a developer, no standard. Chairs 1, 2 and 3 all remain open.',
  'city-sanitation': 'Her public works material is the Tischer Creek fishkill, the settlement that followed it, and the city’s stormwater pollution prevention programme. That is water infrastructure and pollution control. This ladder is about street cleanliness, litter and who is held responsible for it, and no passage states a position on any rung of it.',
  housing: 'Her housing material comes from before she took office and from a different role: she is quoted as a Chum delegate and a member of Pilgrim Church of Christ, describing the phases of a congregational campaign - emergency provision first, then shelter beds to save lives, then housing. Her words are that the third phase is housing, that housing is homes for all so that everybody can live a whole self-sustaining life affordable to them, and that what needs to be dealt with is deeply affordable housing, which the reporter glosses as paying no more than 30% of income. Homes for all is a goal, and deeply affordable is a standard of affordability, not an instrument. The rungs separate on who delivers it and how - government building and operating housing, binding rules on the private market, or subsidy - and she is describing what a nonprofit is building, not what the city should do. She names no city instrument.',
  'homelessness-response': 'The same Chum material is the only thing she says on this subject: that phase two is the shelter issue, that more beds are needed just to save lives because shelters save lives, and that Chum needs about $1.2 million to finish its shelter expansion. That is advocacy for a nonprofit’s capital campaign. This ladder asks what level of funding the community should carry, and her words point at two rungs at once - a city that funds the expansion would be chair 2, a city that leaves nonprofits to lead it would be chair 4 - and she does not say which. The $500,000 for Stepping on Up predates her term and is excluded by C44.',
  'rent-regulation': '🔴 Her one vote here inverts if it is read alone, so it is set out in full. On 9 February 2026 she voted Nay on the motion to table the Clanaugh and Durrwachter resolution asking the governor for a temporary statewide eviction moratorium - a vote to keep the matter alive. The Duluth News Tribune reports that the resolution then failed 7-2 on the merits on 23 February, with support only from its two authors, so she voted against the moratorium itself. The merits vote is not in the Legistar roll calls at all; only the procedural one is. Reading the anti-tabling vote as support for a moratorium would state the opposite of her position. In any case neither vote belongs on this ladder: every rung here is about the price of rent, and an eviction moratorium is a tenant protection. Duluth has no rent stabilisation ordinance for any rung to extend or narrow.',
  'economic-development': 'No passage states a position on business incentives, their conditions or their limits. The subsidy and tax increment instruments in this slice all predate her term and are excluded by C44.',
  'growth-and-development': 'Her remark about balancing open space against housing and economics names the tension and not a pace. No passage states whether development should wait for infrastructure capacity or run ahead of it.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character.',
  'transportation-priorities': 'No passage states a position on where transportation investment should go.',
  'public-safety-approach': 'No passage states a position on police staffing, police funding, co-responders or crisis teams. Her committee is Public Works and Utilities, not Public Safety.',
  homelessness: 'No passage states a position on how the city should treat people sleeping or camping in public. The 2024 camping ordinance predates her term and is excluded by C44.',
  'climate-change': 'Her environmental record is about water quality, habitat and a pollution settlement. No passage states a position on clean energy mandates, subsidies, public investment, permitting or the grid, which is what the five rungs separate on.',
  childcare: 'No passage states a position on childcare funding or provision.',
  'civil-rights': 'No passage states a position on how far government should go in addressing racial and social inequality.',
  'data-centers': 'No passage names a data centre proposal in Duluth or states a position on one.',
  'minimum-wage': 'Duluth has no city minimum wage ordinance, so there is no local instrument, and Minn. Stat. 177.24 carries no local preemption clause, so the lever exists and this is not a scope blank. No passage states a position on the wage floor.',
  'ranked-choice-voting': 'Duluth’s only ranked choice matter is 15-0516R from 2015, a decade before she took office, and C44 excludes it. No passage states a position on the electoral method.',
  'religious-freedom': 'She is a member of Pilgrim Church of Christ and served as a Chum delegate, which is a fact about her own participation and not a position on the role of religion in public policy. No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/desotelle-blanks.json', 'utf8'))];
for (const s of seated) {
  rows.push({ full_name: N, topic_key: s.topic_key, value: s.value, evidence_type: s.evidence_type, reasoning: s.reasoning, source_url_1: s.source_url_1, source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: 'Searched blank. ' + SWEEP + ' ' + v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const evRows = [{ full_name: N, topic_key: 'local-immigration', source_url: URL_26_0100R, snippet: SNIP, snippet_index: '1' }];

if (new Set(rows.map((r) => r.topic_key)).size !== rows.length) throw new Error('duplicate topic');
if (rows.length !== 35) throw new Error('expected 35 rows, got ' + rows.length);

fs.writeFileSync(B + '/_rows/desotelle-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/desotelle-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
console.log('snippet:', SNIP.split(/\s+/).length, 'words');
