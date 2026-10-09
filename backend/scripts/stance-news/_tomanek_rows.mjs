// Terese Tomanek — Duluth at large. 35 rows, 1 chair.
//
// The longest record of the four remaining members: appointed 12 June 2020, elected November 2021,
// vice president in 2024, president in 2025, re-elected November 2025. Recorded on all 31 divided
// matters since January 2024, 27 Yea and 4 Nay.
//
// 🔴 THE CHAIR CAME FROM THE PASSAGES THE STRICT ATTRIBUTOR DROPPED. `attribute_quotes` returned 7
// quotes from 39 clean articles, which looked like "rarely quoted" and was not: WDIO's candidate
// questionnaires carry five answers each and the strict rule cannot see them, because the name sits
// at the head of the section and never beside the speech. `quoted_passages.mjs` is what found them.
//
// 🔴 AND THE SNIPPET HAS TO START AT HER NAME. checkNameProximity windows ±500 characters around the
// SNIPPET START, and in a questionnaire her name is 2,096 characters above the answer. This is the
// defect that made Mayor Her's questionnaire uncitable. It is survivable here only because the text
// from her name down to the answer is one contiguous run on the page, so the snippet opens with the
// name and the window is satisfied at offset 0. That is why this snippet is long.
import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Terese Tomanek';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const readAny = (u) => {
  for (const slug of ['tomanek', 'kennedy', 'forsman', 'durrwachter', 'randorf', 'nephew', 'reinert']) {
    const p = `data/stance-news/${slug}/${key(u)}.txt`;
    if (fs.existsSync(p)) return fs.readFileSync(p, 'utf8').replace(/\s+/g, ' ');
  }
  throw new Error('not in any corpus: ' + u);
};

// The same WDIO interview, published before and after the August 2025 primary.
const W_PRIMARY = 'https://www.wdio.com/top-stories/meet-the-candidates-running-for-duluths-at-large-city-council-seats/';
const W_ADVANCE = 'https://www.wdio.com/top-stories/four-candidates-advance-in-duluth-city-council-at-large-race/';

const cut = (u, from, to) => {
  const t = readAny(u);
  const i = t.indexOf(from);
  if (i < 0) throw new Error('start anchor not on page: ' + from + ' @ ' + u);
  const j = t.indexOf(to, i);
  if (j < 0) throw new Error('end anchor not on page: ' + to + ' @ ' + u);
  const s = t.slice(i, j + to.length);
  const w = s.split(/\s+/).length;
  if (w < 25) throw new Error('under 25 words (' + w + '): ' + from);
  // The chair rests on these two clauses; neither may drop out of the cut.
  for (const need of ['proponent of supporting our police', 'funding for our crisis response team']) {
    if (!s.includes(need)) throw new Error('cut lost the clause the chair rests on: ' + need);
  }
  // checkNameProximity windows +/-500 chars from the snippet START, so the name must be at the top.
  if (s.indexOf(N) > 500) throw new Error('name is ' + s.indexOf(N) + ' chars into the snippet, over the 500 window');
  return s;
};

const ANCHOR_A = 'Terese Tomanek is the only at-large incumbent';
const ANCHOR_B = "begun work on, but we need to continue and that's really important.";
const SNIP_PRIMARY = cut(W_PRIMARY, ANCHOR_A, ANCHOR_B);
const SNIP_ADVANCE = cut(W_ADVANCE, ANCHOR_A, ANCHOR_B);

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, fetched 507 unique articles, 41 of which name Terese Tomanek. All 41 name her in full, so this corpus carries no same-surname noise; two were set aside because they also name a different Tomanek, leaving 39, and every attributed passage in them was read, together with the passages where the name sits at the head of a section rather than beside the speech, which the strict rule does not catch. Minnesota Reformer was searched separately, with a control run at both ends, and added no article naming her - a measured zero, not a blocked one. The Saint Paul Pioneer Press returned nothing and is blind here rather than empty. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. MPR News and Racket are not covered either: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one. Her recorded votes were read from the council’s own roll calls: she is recorded on all 31 divided matters since January 2024, 27 Yea and 4 Nay. She was appointed to an at large seat on 12 June 2020, elected to it in November 2021, served as council vice president in 2024 and council president in 2025, and was re-elected in November 2025. Her statements as a candidate are used, under the ruling of 2026-10-05.';

// 🔴 The antecedent of Forsman's "this" is ambiguous, and the two readings were used inconsistently
// in this batch. Recorded once here and referred to from both homelessness rows.
const COAUTHOR = ' On the night of 29 July 2024 Forsman thanked three colleagues by name, Randorf, Tomanek and Nephew, for collaborating on what he put forward. What "this" refers to is ambiguous in the article: the paragraph before it is entirely about the $500,000 for Stepping on Up, while his own homelessness row in this batch reads it as the camping ordinance. Neither reading seats a chair for her, for the reasons given here and on the funding ladder, so the ambiguity is recorded rather than resolved.';

const seated = [
  {
    topic_key: 'public-safety-approach',
    value: '3',
    evidence_type: 'statement',
    source_url_1: W_ADVANCE,
    source_url_2: W_PRIMARY,
    reasoning: 'Tomanek names this chair in her own words, as a sitting councilor seeking re-election. ' + SWEEP + ' Asked by WDIO what her priorities would be if re-elected, she named three - vibrant neighbourhoods, the budget and community safety - and said of the third that she is a proponent of supporting our police and fire and life safety, and that the council voted for funding for the crisis response team. That is chair 3 in both of its halves: police kept as the main responders, and a crisis team funded to work alongside them. Chair 1 is excluded because she does not shift public safety away from policing - she states support for it in the same breath. Chair 2 is excluded because she adds the crisis team to the police rather than sending unarmed responders instead of them. Chair 4 is excluded on a measured absence, not on silence alone: every one of the 41 articles naming her was searched for police staffing, hiring, officer numbers and patrol levels, and no passage in the corpus has her calling for more officers or a wider police presence. Chair 5 is excluded because she funds the crisis response team and, in the same answer, names parks, libraries and lead line replacement as things the budget protects, so policing is not placed ahead of other services. The answer appears in two WDIO pieces, published before and after the August 2025 primary; both carry the same interview and both are cited because both verify. The cited passage is long for a reason worth stating: in a candidate questionnaire her name sits at the head of her section and never beside the answer, so a shorter cut would not carry her name close enough to be attributable, and this is the defect that left Mayor Her’s questionnaire unusable in this same batch. For the reviewer: she also voted for the $1.92 million Axon drone-as-first-responder and report-writing package in October 2025. That is a procurement rather than a staffing decision and is not read here as chair 4, but a reviewer who reads an expanded police presence into it should weigh it against the rest.',
  },
];

const searched = {
  homelessness: 'She voted for the amended 2024 camping ordinance, which the council cut from the mayor’s proposed misdemeanor to a fine of no more than $200, and for the $500,000 that went with it.' + COAUTHOR + ' She is not quoted anywhere in the corpus on what the enforcement should look like, and that is what this ladder needs: nothing separates enforcement conditioned on somewhere to go, which is chair 3, from a prohibition with civil penalties, which is chair 4. Randorf and Forsman reached chair 3 on this ordinance only because each was quoted on the condition. Kennedy, who voted the same way and was not quoted, is recorded blank, and this row follows her.',
  'homelessness-response': 'She voted for the $500,000 increase that took the city’s investment in Stepping on Up to $1.15 million.' + COAUTHOR + ' No passage quotes her on what level of funding the city’s response should carry, which is what this ladder asks. The reason this is a blank rather than chair 2 is settled in this batch and does not depend on her silence: Forsman, who put the money forward and spoke to it, is also blank here, because the vote reads as chair 2 while his words - the city cannot do this alone, partners and foundations must close the gaps - read as chair 4, and nothing separates them. Randorf, Nephew and Kennedy are blank on the same ladder for the same reason.',
  'rent-regulation': 'She has a record here and it belongs to no rung on this ladder. In May 2025 she introduced, with Randorf and Nephew, the ordinance requiring landlords to inform tenants of the rights and resources already available to them, and she voted for it on 1 July 2025 when it passed 6-2 as Ord 25-016-O. On the same evening she voted against Ord 25-015-O, the right to repair petition ordinance brought by the Duluth Tenants Union and the Housing Justice Center, which failed 2-6. Both votes are divided and both would pass C46. Neither is evidence here, because every rung of this ladder is about the price of rent - control, stabilisation, or market rents - and both instruments are about habitability and tenant information. The organiser of the petition campaign said so directly when asked whether it was a precursor to rent control: this is not rent control. Reading either vote as a rent position would be a confident wrong row.',
  housing: 'Her material on housing is substantial and it names no instrument. She said the city has done so much in the area of affordable housing, naming the final phase of Harbor Highlands, Sky Ridge Flats for seniors, Brave View, Plover Place and Brewery Creek, and that the city needs housing across the entire spectrum from market rate and luxury to affordable. On the RiverWest development in West Duluth she said the city needs housing available for families and housing that lets long-term owners downsize, that it opens opportunities and adds to the tax base, and that it is crucial for adding housing for all types of employees. Those are reasons for building housing, not a choice among the rungs. The rungs separate on who makes housing affordable and how - government building and operating it, binding rules on the private market, or subsidy - and the projects she lists point in different directions at once: Harbor Highlands is a housing authority redevelopment, Sky Ridge Flats and Brewery Creek are subsidised private developments, and RiverWest is market rate single family. She never says which of those the city should rely on, and she states no position for or against binding rules, so chairs 3, 4 and 5 all remain open.',
  'economic-development': 'She argues for economic development and never names an incentive, a condition or a limit. Her case is a revenue one: the city needs economic development desperately, and developing the commercial tax base takes pressure off homeowners who are worried about rising taxes, with the county, the school board and the city all looking at levies. That is a reason to pursue growth, not a position on how to pay for it. Her votes are with the majority on every subsidy instrument in the window - the Sofidel development agreement and its Minnesota Investment Fund subgrant, the Incline Plaza and paper mill tax increment districts, the Madden Media tourism contract - all carried 8-1 or 7-1 with Durrwachter the lone dissenter, and she is not quoted on any of them. She is not one of the three councilors on the Duluth Economic Development Authority who shaped the city’s tax increment financing policy; those are Forsman, Kennedy and Randorf. Chairs 1 and 2 are excluded because she votes for subsidy to attract outside business. Nothing separates chair 3 from chair 4, because she names no wage condition, no local hiring condition, no clawback and no spending limit.',
  'climate-change': 'She said the city is really working on being carbon neutral by 2030, that it has done a lot of work and has a good sustainability officer, and that it has worked with Minnesota Power to try and get their carbon footprint down. That is a target the city has adopted for itself and a description of cooperation with the utility. This ladder asks how government should expand clean energy, and the rungs separate on the instrument. Chair 1 requires a shift through mandates and firm deadlines, and she names no mandate - working with a utility to try to reduce its footprint is persuasion, not a requirement. Chair 2 is excluded because she names no subsidy, tax credit or public investment in clean energy; the only spending she names in the same answer is lead line replacement. Chair 3 is excluded because she says nothing about permitting or the grid. Durrwachter holds chair 1 on this ladder because she called for the strongest possible federal clean car standards by a stated deadline, which is the kind of evidence this row does not have.',
  'local-environment': 'Her only environment-adjacent instrument is the ordinance she introduced with Forsman and Randorf in July 2023 restricting cannabis and tobacco smoking and vaping in city parks, Wade Stadium, near transit shelters and within 100 feet of medical facilities. That is a public health restriction on conduct in parks, not a position on how far environmental protection should constrain development. No passage states a view on the balance this ladder asks about.',
  'transportation-priorities': 'She names road maintenance and nothing else. She said the city has been fixing potholes at an unprecedented rate and fixing streets, and listed those among the things a tight budget must protect. In August 2022 she brought forward, with Forsman and Mayou, an ordinance limiting ebikes and motorised scooters to 10 mph on the Lakewalk and the Baywalk after residents raised concerns about the danger to pedestrians. That is a safety rule on a shared path, not a decision about where investment should go. This ladder separates on the balance between road capacity and transit, cycling and pedestrian infrastructure, and she states no position on transit, bike lanes or sidewalk investment anywhere in the corpus.',
  'growth-and-development': 'Asked how Duluth can attract new residents and businesses, she said the city already has what people want - the outdoors, the symphony, the ballet, three colleges - and that what it needs is housing and childcare, that young people need starter homes and seniors need somewhere to move to so family homes open up, and that if those two things are expanded then economic growth and jobs can expand. That is an argument about what must come first, not about how fast growth should be allowed to go. It is the same shape as Nephew’s sequencing argument and it falls short here for the same reason: chair 2 makes development wait for capacity and chair 3 invests ahead of demand, and building the housing stock so that growth becomes possible is consistent with both.',
  'residential-zoning': 'She said the city is working on its unified development chapter, its regulations for people wanting to build, and asked how Duluth could take some of its empty corporate buildings downtown and turn them into housing. Adaptive reuse of commercial buildings is not a position on residential density, and she names no level of it - nothing on duplexes, accessory dwellings, multifamily by right, or single-family-only zoning, which is what the five chairs separate on. She does not say whether the regulations she is working on should be loosened or tightened.',
  childcare: 'Childcare is one of the two things she names as what Duluth most needs, and she describes effort rather than a funding level: childcare is hugely important and a critical issue throughout the country, the city has really been working with childcare providers, a childcare organisation held a summit a few weeks earlier, and the city is really trying to help them. She also notes that the Brave View development coming online carries 100 childcare places. This ladder separates on how much public support to provide and to whom. Working with providers and welcoming places in a subsidised development states no level of public support, so it names no rung.',
  'city-sanitation': 'The city services she names are lead pipe replacement, which she voted to fund for schools and childcare centres first and then in the Gary and Central Hillside neighbourhoods, and city-wide sanitary sewer lining. Both are water infrastructure. This ladder is about street cleanliness and litter, and about who is held responsible for it. No passage states a position on any rung.',
  'public-safety-approach-placeholder': null,
  'local-immigration': 'No passage quotes her on detainers, on information sharing, or on the use of local police for immigration enforcement.',
  'civil-rights': 'Her remarks on this subject are about conduct rather than policy. She reads the Civility Pledge at the beginning of every meeting in memory of a former council president, says the council needs to be not only tolerant and civil but kind and accepting, notes the city’s new human rights and equity officer, and says the council needs to accept diversity of opinion. This ladder separates on how far government should go in addressing racial and social inequality - from mandated equity requirements to ending race-based programmes - and none of that material states a position on enforcement or on race-conscious programmes.',
  'data-centers': 'No passage names a data centre proposal in Duluth or states a position on one.',
  'minimum-wage': 'Duluth has no city minimum wage ordinance, so there is no local instrument, and Minn. Stat. 177.24 carries no local preemption clause, so the lever exists and this is not a scope blank. No passage states a position on the wage floor.',
  'ranked-choice-voting': 'Duluth’s only ranked choice matter is 15-0516R from 2015, which predates her appointment in June 2020 and is excluded by C44. No passage states a position on the electoral method.',
  'religious-freedom': 'She is a retired chiropractor and an on-call chaplain, and the corpus shows her leading prayers as a member of Peace Church and Temple Israel at the relocation of the Chum drop-in centre. That is her own ministry, not a position on the role of religion in public policy. No passage states a position on any rung.',
  '2020-election': 'No passage states a view of the 2020 presidential election.',
};
delete searched['public-safety-approach-placeholder'];

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/tomanek-blanks.json', 'utf8'))];
for (const s of seated) {
  rows.push({ full_name: N, topic_key: s.topic_key, value: s.value, evidence_type: s.evidence_type, reasoning: s.reasoning, source_url_1: s.source_url_1, source_url_2: s.source_url_2 || '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: 'Searched blank. ' + SWEEP + ' ' + v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const ev = [
  { topic_key: 'public-safety-approach', source_url: W_ADVANCE, snippet: SNIP_ADVANCE },
  { topic_key: 'public-safety-approach', source_url: W_PRIMARY, snippet: SNIP_PRIMARY },
];
const idx = {};
const evRows = ev.map((e) => { idx[e.topic_key] = (idx[e.topic_key] || 0) + 1; return { full_name: N, ...e, snippet_index: String(idx[e.topic_key]) }; });

const topics = new Set(rows.map((r) => r.topic_key));
if (topics.size !== rows.length) throw new Error('duplicate topic in rows');
if (rows.length !== 35) throw new Error('expected 35 rows, got ' + rows.length);

fs.writeFileSync(B + '/_rows/tomanek-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/tomanek-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
for (const e of evRows) console.log(`  ${e.topic_key} #${e.snippet_index}: ${e.snippet.split(/\s+/).length} words, name at char ${e.snippet.indexOf(N)}`);
