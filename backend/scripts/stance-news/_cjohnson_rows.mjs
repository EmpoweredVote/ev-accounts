// Cheniqua Johnson, re-researched 2026-10-05 against the re-swept corpus. 1 chair, unchanged.
//
// Her original rows rested on 20 articles of the 27 the sweep named — seven lost to a truncated
// corpus key — and named Minnesota Reformer as searched when it had supplied nothing. The re-sweep
// gives 101 articles, every one naming her, and 45 attributed quotes.
//
// 🔴 THE CHAIR DID NOT MOVE, AND THAT IS THE RESULT. Five times the evidence confirmed what one
// fifth of it had already established. Her rent-regulation 2 rests on the rent stabilization
// ordinance itself, not on adjacent tenant protections, which is the distinction that matters:
// she voted AGAINST Ord 25-29, the ordinance Rebecca Noecker co-authored and was seated at chair 3
// for. Same instrument, opposite votes, adjacent chairs — the slice is internally consistent.
//
// ⚠ A HOUSING CHAIR WAS READ AND REFUSED FOR WANT OF A CITATION. As chair of the Housing and
// Redevelopment Authority she helped craft the emergency rental assistance programme and is quoted
// on it. Her full name sits 702 and 1,693 characters from those two passages, with only a bare
// "Johnson" adjacent, and her surname is common enough that the verifier requires a title beside
// it. A position that can be read but not cited is not publishable. It is recorded in the blank.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Cheniqua Johnson';

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 101 articles, every one of which names Cheniqua Johnson as a phrase. The full phrase was required rather than the surname alone, because Johnson is a very common surname in Minnesota coverage. Ten were set aside because they also name a different person surnamed Johnson, so a bare-surname attribution in them could not be trusted, and every passage in the remaining 91 that quotes her beside a speech verb was read - 45 of them. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one.';

const chairs = [
  {
    topic_key: 'rent-regulation',
    value: '2',
    evidence_type: 'statement',
    urls: [
      'https://sahanjournal.com/housing/st-paul-city-council-extends-pre-eviction-filing-period/',
      'https://www.minnpost.com/elections/2023/11/st-paul-voters-appear-to-have-sent-7-women-to-city-council-in-historic-election-highlighting-rent-control-sales-tax/',
    ],
    reasoning: 'Her own words name the chair, and the re-swept corpus of 101 articles confirms it without changing it. At a League of Women Voters forum in September 2023 she said the rent stabilization ordinance personally needs to be reworked and is not, right now, working for the people it was supposed to, and the reporting places her among the members interested in restoring parts of the stricter policy voters first approved. On the tenant protections ordinance she said it is counterproductive and contradictory to pass such an ordinance and then exempt the largest landlord in the city from it, and the council voted five to two against granting that exemption. She also voted against Ord 25-29 on 7 May 2025, which removed the twenty-year limit on the new-construction exemption from the rent stabilization cap. Together those name chair 2: strengthening what already exists and keeping more units covered. Chair 1 is excluded, because nothing she has said calls for covering every rental unit communitywide and the reporting describes her interest as restoring parts of the stricter policy. Chair 3 is excluded because she voted against the new-construction exemption that chair 3 describes - the same ordinance for which Council President Noecker, who co-authored it, is seated at chair 3. For completeness, on 5 August 2026 she was one of five members voting against RES 26-1253, which would have put a tenant repair-and-deduct question on the November 2026 ballot. That was a vote on whether to refer a question to voters, it concerns repairs rather than the price of rent, and it names no rung here; it is recorded so the reviewer sees the whole record rather than only what supports the chair.',
  },
];

const blanks = {
  housing: 'She chairs the city’s Housing and Redevelopment Authority and helped craft the emergency rental assistance programme, which the council and mayor funded with more than $1.9 million in March 2026 and roughly $3.8 million since the previous autumn, raising the maximum award from $2,500 to $3,500. She said her ward has one of the highest eviction rates in Ramsey County and that this is simply not okay, that the programme needed to be brought back and widened so resources reach people faster, and that everyone deserves stable housing. Two things keep this a blank. Rental assistance is relief paid to tenants, and the rungs here separate on how housing is made affordable - whether government builds and operates it, sets binding rules on the private market, or subsidises its construction. And neither passage can be cited: her full name sits 702 and 1,693 characters away from them, only a bare "Johnson" stands beside the quotes, and her surname is common enough that a citation needs a title next to the full name. The position was read; it cannot be sourced to the standard this programme requires.',
  'public-safety-approach': 'After an incident involving officers’ use of force she said that whatever explanations were offered or intentions held, the impact remains the same and trust between the community, the police department and the city has been broken, and she joined the council’s call for an investigation. That is a statement about accountability and trust. This ladder separates on the balance between the police budget and other services, and no passage states her position on police staffing, police funding, co-responders or crisis teams.',
  'homelessness': 'No passage states a position on how the city should treat people sleeping or camping in public. She is not quoted on encampment clearances, citations or shelter-bed conditions.',
  'homelessness-response': 'No passage states what level of funding the city’s homelessness response should carry. Her housing work in the window read concerns eviction prevention and rental assistance rather than the shelter and services spending this ladder asks about.',
  'residential-zoning': 'No passage states a position on density or neighbourhood character. She is not quoted on duplexes, accessory dwellings, upzoning or single-family zoning.',
  'growth-and-development': 'No passage states a position on the pace of growth or on whether development should wait for infrastructure capacity.',
  'economic-development': 'No passage states a position on business incentives, their conditions or their limits. Her budget remarks concern restoring library and recreation-centre services without requiring additional levy capacity, which is a spending question rather than a position on attracting business.',
  'local-immigration': 'No passage quotes her on detainers, on information sharing, or on the use of local police for immigration enforcement.',
  'transportation-priorities': 'No passage states a position on where transportation investment should go.',
  'local-environment': 'No passage states a position on how the city should balance development against environmental protection. Her remarks on the Hamm’s Brewery heritage preservation district concern historic designation rather than environmental trade-offs.',
  'climate-change': 'No passage states a position on clean-energy mandates, subsidies or permitting.',
  'city-sanitation': 'No passage states a position on any rung.',
  childcare: 'No passage states a position on childcare funding or provision.',
  'minimum-wage': 'Saint Paul has a municipal minimum wage, so the lever exists and this is not a scope blank. No passage quotes her on the wage floor. She was not among the three members who proposed eliminating the youth training wage in August 2026.',
  'ranked-choice-voting': 'Saint Paul elects by ranked voting under Chapter 31 of its Legislative Code and she was elected under it. No passage quotes her stating a position on whether the city should keep, extend or drop the method.',
  'civil-rights': 'She has spoken about women stepping forward as candidates and about representing distinct communities that will not agree on every proposal. Those are statements about representation and about how the council works. The rungs here separate on how far civil-rights enforcement and race-conscious programmes should go, and no passage states a position on that.',
  'data-centers': 'No passage names a data centre proposal in Saint Paul or states a position on one.',
  'religious-freedom': 'No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};

const rows = [];
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

// Her two existing evidence rows are carried forward verbatim: merge_rows replaces a pair's
// evidence wholesale, so omitting them would delete them.
const evidence = [
  {
    full_name: N, topic_key: 'rent-regulation',
    source_url: 'https://sahanjournal.com/housing/st-paul-city-council-extends-pre-eviction-filing-period/',
    snippet: 'Advocates pushed back against an exemption for the agency. Data provided from HOMELine showed that the SPPHA filed 45 evictions on March 20, more than half of which were for allegedly less than $1,000 owed. “It is counterproductive and contradictory to pass a tenant protections ordinance and then to exempt the largest landlord in the city from that ordinance,” said Council Member Cheniqua Johnson',
    snippet_index: 0,
  },
  {
    full_name: N, topic_key: 'rent-regulation',
    source_url: 'https://www.minnpost.com/elections/2023/11/st-paul-voters-appear-to-have-sent-7-women-to-city-council-in-historic-election-highlighting-rent-control-sales-tax/',
    snippet: 'Kim, Jalali, Yang and Johnson have all expressed interest in restoring parts of the stricter policy that voters initially approved. In a Pioneer Press op-ed , Jalali said the future council “must work to uphold, strengthen and improve [the rent stabilization ordinance] as we would with any other policy.” “This ordinance, I think, personally needs to be reworked,” Johnson said at a League of Women Voters forum in September. “It’s not necessarily, right now, working for the people it was supposed to.”',
    snippet_index: 0,
  },
];

let bad = 0;
const byPair = new Map(rows.map((r) => [r.topic_key, r]));
const named = new Map();
for (const e of evidence) {
  const words = e.snippet.split(/\s+/).length;
  const row = byPair.get(e.topic_key);
  const cited = row && [row.source_url_1, row.source_url_2, row.source_url_3].includes(e.source_url);
  if (words < 25) { console.error(`🔴 ${e.topic_key}: ${words} words`); bad++; }
  if (!cited) { console.error(`🔴 ${e.topic_key}: url not among the row's sources`); bad++; }
  // At least one snippet per chair must carry the FULL name — "Johnson" alone will not verify.
  if (/Cheniqua Johnson/.test(e.snippet)) named.set(e.topic_key, 1);
}
for (const r of rows.filter((x) => x.value)) if (!named.get(r.topic_key)) { console.error(`🔴 ${r.topic_key}: no snippet carries her full name`); bad++; }
if (bad) { console.error(`\n${bad} control failure(s) — refusing to write`); process.exit(1); }

fs.writeFileSync(`${B}/_rows/cjohnson-rows.json`, JSON.stringify(rows, null, 1));
fs.writeFileSync(`${B}/_rows/cjohnson-evidence.json`, JSON.stringify(evidence, null, 1));
console.log(`rows: ${rows.length} | scored: ${rows.filter((r) => r.value).length} | evidence: ${evidence.length}`);
console.log('chairs:', rows.filter((r) => r.value).map((r) => `${r.topic_key}=${r.value}`).join(', '));
