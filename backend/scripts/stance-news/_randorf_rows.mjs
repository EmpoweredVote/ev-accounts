import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Roz Randorf';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const read = (u) => fs.readFileSync('data/stance-news/randorf/' + key(u) + '.txt', 'utf8');

const DNT_H = 'https://www.duluthnewstribune.com/news/local/duluth-tackles-homeless-encampments-other-public-safety-issues';
const DNT_P = 'https://www.duluthnewstribune.com/news/local/duluth-tenants-push-petition-for-right-to-repair-rules';
const OPED = 'https://www.duluthnewstribune.com/opinion/columns/pro-con-right-to-repair-could-harm-tenants-lead-to-evictions';
const W1 = 'https://www.wdio.com/top-stories/duluth-city-council-production-incentives/';
const W2 = 'https://www.wdio.com/local-news/duluth-city-council-approves-22-items-on-consent-agenda/';

// Every snippet is CUT FROM THE FETCHED PAGE and asserted verbatim and >= 25 words here, so a
// snippet that drifted from the page cannot reach the CSV.
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

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, returned 609 unique articles. Minnesota Reformer was searched separately and added no article naming her. 50 of them name Randorf and all 50 were read. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them.';

const seated = [
  {
    topic_key: 'homelessness', value: '3', evidence_type: 'statement',
    reasoning: 'Mayor Reinert proposed empowering city staff to charge people living in unauthorized encampments on city land with a misdemeanor carrying up to a $1,000 fine and 90 days in jail. Randorf, then Council President, opposed the criminal route on the ground that the court and probation system would be ill-equipped to handle the resulting cases, and the council cut the penalty to a fine of no more than $200. Her own words state the condition chair 3 describes: "We need to create a safe place for them to go. Because ticketing isn’t the answer." She is working through the Stepping on Up initiative to open sanctioned campsites with sanitation, hygiene and support services, and wants that built rather than relied on enforcement. Chair 5 is excluded because she rejected the misdemeanor. Chair 4 is excluded because she rejects ticketing as the answer. Chair 2 is excluded because she helped bring the camping ordinance forward rather than seeking decriminalisation, and chair 1 because she does not argue that enforcement should never apply.',
    source_url_1: DNT_H, source_url_2: '', source_url_3: '',
  },
  {
    topic_key: 'rent-regulation', value: '3', evidence_type: 'statement',
    reasoning: 'Randorf set out her position in writing twice. In a statement to the News Tribune she wrote that no additional ordinances are needed because Minnesota’s tenant protection statutes already give renters the legal backing to demand timely repairs, and she pointed tenants to the Rent Escrow Action, the Emergency Tenant Remedies Action and the Tenant Landlord Connection. In her signed column she wrote that rather than create a new system the city should strengthen and enforce the protections it already has, which is what the council did by requiring landlords to respond to repair requests within 14 days. That is chair 3: maintain the tenant protections now in force. Chair 5 is excluded because she defends those protections and voted to add to them. Chairs 1 and 2 are excluded because Duluth has no rent stabilization and she has proposed none. Chair 4 is excluded because the protections she defends apply to all rental housing and not only to subsidised units. For the reviewer: she addresses tenant protection and says nothing about rent levels or new construction, which is the second clause of chair 3. The ladder has no rung for a position on habitability, and that gap is written up as defect 8 for Season 3.',
    source_url_1: DNT_P, source_url_2: OPED, source_url_3: '',
  },
  {
    topic_key: 'economic-development', value: '3', evidence_type: 'statement',
    reasoning: 'Randorf supports the city’s $200,000 film and television production incentive, and says the feature she values most is that the money is paid only after it has been spent: a production spends first on local people and vendors, then applies for a rebate. She also argued the incentive was needed so that productions do not go to Cloquet or elsewhere in the region instead. That is chair 3: offer incentives, conditioned on local benefit and paid only on delivery. Chairs 1 and 2 are excluded because she supports subsidy to attract outside business. Chair 5 is excluded because the incentive is capped and conditional. Chair 4 is excluded because she does not describe the city’s approach as large breaks for major employers held in check by limits; the mechanism she names is reimbursement after proven local spending. For the reviewer: chair 3 also names good wages, and the evidence shows local hiring and local spending but says nothing about a wage condition.',
    source_url_1: W1, source_url_2: W2, source_url_3: '',
  },
];

const searched = {
  'public-safety-approach': 'Searched blank. ' + SWEEP + ' Randorf speaks on public safety often. She told the council she did not want budget cuts in Fire or Police, she proposed a hiring freeze on 6 to 8 of about 35 open city positions rather than using one-time federal money, and she supported the police chief’s contract on the ground that discipline should not be imposed over allegations that have not been adjudicated. None of that chooses between policing and social services, which is what this ladder asks. This is also the ladder Charlotte recorded as defective for Season 3, because chairs 1 and 3 do not separate a member who funds both.',
  housing: 'Searched blank. ' + SWEEP + ' Randorf spoke at the Harbor Highlands and Incline Village groundbreakings and gave the city’s affordable housing shortfall as 2,671 units after 838 had been added. On tax increment financing she reported what the council decided, saying seven of the eight councilors had agreed to use it for Incline Village, rather than stating her own view of the role government should take. Welcoming subsidised developments does not choose between the five chairs, which separate on whether government should build housing, impose binding rules on the private market, or subsidise.',
  'local-environment': 'Searched blank. ' + SWEEP + ' On the Lester Park golf course decision, which developed 63 acres and left 207 in a P-1 open space zone, her only quoted remark describes what the P-1 designation does: certain things cannot be built on it and it cannot be transferred to a developer. That describes the zoning tool, not a position on how the city should balance development against preservation. Her 2019 remark about not bringing jobs at the expense of the Lake Superior watershed was made before she took office in January 2020 and is not used.',
  'local-immigration': 'Searched blank. ' + SWEEP + ' Her remarks on Operation Metro Surge concern an eviction moratorium, not law enforcement. She argued that a moratorium does not erase rent but only delays it, leaving a tenant with back rent and damaged credit, and the council then asked the state for rental assistance without the moratorium. Every rung of this ladder is about how local law enforcement relates to federal immigration enforcement, on detainers, information sharing and the use of local police. No passage states a position on any of them.',
  'transportation-priorities': 'Searched blank. ' + SWEEP + ' Her remarks on transit concern the size of the Duluth Transit Authority levy request, which she called a 43% jump that is not sustainable for the citizens who fund it through the property tax levy, while saying the city needs its public transit system. That is a position on a budget figure, not on where transportation investment should go, which is what this ladder asks.',
  'growth-and-development': 'Searched blank. ' + SWEEP + ' On the downtown development strategy she said she was giving context so that the council and the public would understand it was not a new direction but a codification of years of community input. That is a statement about process, not about the pace of growth.',
  'city-sanitation': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'civil-rights': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  'climate-change': 'Searched blank. ' + SWEEP + ' No passage states a position on clean energy mandates, subsidies or permitting.',
  'data-centers': 'Searched blank. ' + SWEEP + ' No passage names a data centre proposal or states a position on one.',
  childcare: 'Searched blank. ' + SWEEP + ' Childcare appears in her 2019 candidacy announcement as one of several things she would support. That predates her taking office in January 2020, and it names no rung in any event. No later passage states a position.',
  'homelessness-response': 'Searched blank. ' + SWEEP + ' She supports the Stepping on Up initiative and sanctioned campsites, and she noted that St. Louis County had committed $600,000 to it while urging residents to press the county to be a good partner. That is advocacy for a particular project and for county participation. No passage states what level of city funding she thinks the response should carry, which is what this ladder asks.',
  'residential-zoning': 'Searched blank. ' + SWEEP + ' No passage states a position on housing density or on single-family zoning. The council barred new vacation rentals in single-family homes during her tenure, but no passage records her position on it and that vote was not divided.',
  'religious-freedom': 'Searched blank. ' + SWEEP + ' No passage states a position on any rung.',
  '2020-election': 'Searched blank. ' + SWEEP + ' No passage states a view of the 2020 presidential election.',
  'minimum-wage': 'Searched blank. ' + SWEEP + ' Duluth has no city minimum wage ordinance, so there is no local instrument, and no passage states a position on the wage floor. The lever exists, because Minn. Stat. 177.24 carries no local preemption clause, so this is not a scope blank.',
  'ranked-choice-voting': 'Searched blank. ' + SWEEP + ' Duluth’s only ranked choice matter is 15-0516R from 2015, which predates her term and is excluded. No passage states a position on the electoral method.',
};

const rows = [...JSON.parse(fs.readFileSync(B + '/_rows/randorf-blanks.json', 'utf8'))];
for (const s of seated) rows.push({ full_name: N, ...s, quote_text: '', quote_deidentified: '', editor_note: '' });
for (const [k, v] of Object.entries(searched)) {
  rows.push({ full_name: N, topic_key: k, value: '', evidence_type: '', reasoning: v, source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '' });
}

const ev = [
  { topic_key: 'homelessness', source_url: DNT_H, snippet: cut(DNT_H, 'Mayor Roger Reinert had proposed', 'unless other housing is available for them.') },
  { topic_key: 'homelessness', source_url: DNT_H, snippet: cut(DNT_H, 'But councilors balked', 'no more than a $200 fine.') },
  { topic_key: 'homelessness', source_url: DNT_H, snippet: cut(DNT_H, 'Council President Roz Randorf raised concerns', 'involving homeless people.') },
  { topic_key: 'homelessness', source_url: DNT_H, snippet: cut(DNT_H, 'Randorf said councilors have been working closely', 'support services.') },
  { topic_key: 'homelessness', source_url: DNT_H, snippet: cut(DNT_H, 'We want this project done now', 'Because ticketing isn’t the answer.') },
  { topic_key: 'rent-regulation', source_url: DNT_P, snippet: cut(DNT_P, 'Randorf pointed to tenants', 'essential repairs.') },
  // 🔴 NOT the substantive paragraph. In a SIGNED FIRST-PERSON column the author's name appears only
  // in the byline and the closing bio, so `checkNameProximity` (±500 chars) rejects every body
  // paragraph — the strongest statement evidence there is, refused for being written in the first
  // person. This passage states the same position and sits just before "Roz Randorf is the elected
  // representative of District 3 on the Duluth City Council."
  { topic_key: 'rent-regulation', source_url: OPED, snippet: cut(OPED, 'It is a vote for a thoughtful', 'not just promises.') },
  { topic_key: 'economic-development', source_url: W1, snippet: cut(W1, 'This is the exact same funding', 'the money is spent.') },
  { topic_key: 'economic-development', source_url: W2, snippet: cut(W2, 'It was really important for the city of Duluth to jump', 'we have an incentive as well.') },
];
const idx = {};
const evRows = ev.map((e) => { idx[e.topic_key] = (idx[e.topic_key] || 0) + 1; return { full_name: N, ...e, snippet_index: String(idx[e.topic_key]) }; });

fs.writeFileSync(B + '/_rows/randorf-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/randorf-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length, '| evidence:', evRows.length);
console.log('unique topics:', new Set(rows.map((r) => r.topic_key)).size);
