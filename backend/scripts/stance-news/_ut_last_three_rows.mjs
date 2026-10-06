// Jiro Johnson (5), Zach Robinson (2) and Kent Davis (1) — the last 8 of the 25.
// All eight are blanks, and the reasons differ. Davis's is the strong one: his platform is
// detailed and it is orthogonal to the ladder.
//
// 🟢 SALT LAKE COUNTY RUNS CivicClerk, NOT LEGISTAR, AND ITS OData API IS OPEN:
// `https://saltlakecounty.api.civicclerk.com/v1/Events` answers without a key. 🔴 But its entity
// sets are Emails, EventCategories, EventsMedia, Events, EventTemplate, Meetings, Search, Sections,
// Settings, Subscriptions — there is NO vote entity. A CivicClerk county gives agendas and media
// and no per-member roll call, so the sponsorship-and-vote channel that worked for Duluth's
// Legistar does not exist here.
//
// 🔴 A SECOND IDENTITY TRAP, AFTER kennedy.house.gov. `ballotpedia.org/Zach_Robinson` is a Utah
// HOUSE candidate from 2012 and 2014, not the 2026 county council candidate — its campaign themes
// are dated 2014. Reading it as his would have attributed another man's platform to him.
//
// What was searched for Johnson and Robinson, and what it gave:
//  - slco.org council pages: Johnson's is biographical (law school, public defender career) and
//    states no position. Robinson holds no office and has no county page.
//  - Campaign sites: zachrobinson.com and davisforda.com return 114-byte parked pages; the
//    jirojohnson.com variants do not resolve at all.
//  - Utah outlets, measured: fox13now.com is both searchable and fetchable; sltrib.com, kuer.org
//    and deseret.com return client-rendered search pages with no links in the HTML; and
//    utahnewsdispatch.com and buildingsaltlake.com refuse node's fetch with 403.
//  - 🟢 POSITIVE CONTROL ON THE ONE CHANNEL THAT WORKS: the fox13now article on the county's legal
//    action over the planned ICE detention centre fetches clean at 6,929 characters and names
//    council members Stringham and Theodore. It does not name Johnson or Robinson. The detector
//    found names in that page, so the absence of these two is a measurement, not a broken search.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-06-ut-slco-season2-repair';

const COUNTY = 'Searched blank. The county council pages on slco.org were read, the county’s CivicClerk agenda interface was queried, and the Utah outlets that can be both searched and fetched were searched. ';
const NO_SITE = 'He has no campaign site that resolves and no Ballotpedia page of his own, so there is no statement of his to read. ';
const NO_VOTES = 'Salt Lake County publishes its agendas through a system that exposes meetings and documents but no per-member roll calls, so his votes as a council member could not be read the way a council’s own roll calls can be elsewhere. ';

const JJ = 'Jiro Johnson';
const ZR = 'Zach Robinson';
const KD = 'Kent Davis';

const rows = [
  { full_name: JJ, topic_key: 'growth-and-development', reasoning: COUNTY + NO_SITE + NO_VOTES + 'Nothing read here states whether he would cap growth, make development wait for infrastructure capacity, invest ahead of demand, actively recruit development, or leave the pace to the market.' },
  { full_name: JJ, topic_key: 'jail-capacity', reasoning: COUNTY + NO_SITE + NO_VOTES + 'This ladder separates on whether to shrink the jail system, use alternatives instead of building capacity, upgrade only to meet constitutional standards, build additional capacity, or expand detention as the primary response. His county page records that he is an assistant director of the county public defender office, which is a professional role and not a stated position on any of those five.' },
  { full_name: JJ, topic_key: 'local-environment', reasoning: COUNTY + NO_SITE + NO_VOTES + 'Nothing read here states how he would balance new development against environmental preservation, which is what the five rungs separate on.' },
  { full_name: JJ, topic_key: 'public-safety-approach', reasoning: COUNTY + NO_SITE + NO_VOTES + 'Nothing read here states whether he would shift public safety away from policing, send unarmed responders to non-violent calls, add crisis teams alongside police, expand the force, or make policing the top priority.' },
  { full_name: JJ, topic_key: 'local-immigration', reasoning: COUNTY + NO_SITE + NO_VOTES + 'This question is a real one for a county that runs a jail and a sheriff, and the county has been in public conflict over a planned federal detention facility. The reporting on that conflict names other council members and does not name him, and no passage read here states his position on detainers, on information sharing, or on the use of county resources for federal immigration enforcement. What would settle it is a recorded county vote on a detainer or resources policy, or a statement of his, from a page that names him.' },

  { full_name: ZR, topic_key: 'homelessness', reasoning: COUNTY + NO_SITE + 'This ladder is about enforcement against sleeping or camping in public — whether it is protected, decriminalised, allowed only where shelter exists, prohibited with civil penalties, or banned with criminal ones. No passage read here states his position on any of them.' },
  { full_name: ZR, topic_key: 'local-immigration', reasoning: COUNTY + NO_SITE + 'The county has been in public conflict over a planned federal detention facility, and the reporting on it names other council members rather than him. No passage read here states his position on detainers, on information sharing, or on the use of county resources for federal immigration enforcement.' },

  {
    full_name: KD, topic_key: 'judicial-prosecution-priorities',
    reasoning:
      'Searched blank, and not for want of material. His campaign site and his Ballotpedia candidate survey were both read in full, and he has a detailed platform: written filing standards so that similar cases receive similar treatment regardless of assignment, a documented reason recorded for every declination, documented plea terms and rationale, published performance metrics and a public dashboard, and clear admission criteria for alternatives to incarceration focused on public safety and on the drivers of criminal activity, including drug dependency and mental-health needs. He grounds all of it in a state audit of the office. '
      + 'The platform answers how decisions should be made and recorded. This ladder asks which way they should go, and three of its five rungs can be excluded from his own words while the remaining two cannot be separated. '
      + 'Chair 1 is excluded because he nowhere treats prosecution as a last resort; he is strengthening filing standards, not narrowing charging. Chair 5 is excluded because he keeps alternatives to incarceration and aims them at drug dependency and mental-health needs, which is precisely the social ground that rung refuses. Chair 3 is excluded by the most direct statement he makes: it turns on the decision being a judgment call every time, and he commits to a written standard set in advance and applied the same way every time, so that similar cases are treated alike. '
      + 'That leaves chair 2 and chair 4, and the evidence holds one half of each. Keeping and targeting alternatives to incarceration points at chair 2; requiring a documented reason for every declination points at chair 4. Documenting a reason is not the same as making declination exceptional, and defining admission criteria is not the same as reserving prosecution for when safety requires it, so neither rung is named. '
      + 'What would settle it is a statement of how much of the caseload he would divert or decline, rather than how those decisions would be recorded.',
  },
];

for (const r of rows) {
  r.value = ''; r.evidence_type = ''; r.source_url_1 = ''; r.source_url_2 = ''; r.source_url_3 = '';
  r.quote_text = ''; r.quote_deidentified = ''; r.editor_note = '';
}

const bad = [];
for (const r of rows) {
  if (!r.reasoning.trim()) bad.push(r.topic_key + ': empty reasoning');
  if (/\breviewer\b|\bC\d{2}\b|[🔴⚠▶🟢✅]/u.test(r.reasoning)) bad.push(r.full_name + '/' + r.topic_key + ': reviewer-facing text');
  if (/["“”]/.test(r.reasoning)) bad.push(r.full_name + '/' + r.topic_key + ': quotation mark with no snippet');
  if (/\brepublican\b|\bdemocrat|\bGOP\b/i.test(r.reasoning)) bad.push(r.full_name + '/' + r.topic_key + ': party in reasoning');
}
if (rows.length !== 8) bad.push('expected 8 rows, got ' + rows.length);
if (rows.filter((r) => r.full_name === JJ).length !== 5) bad.push('expected 5 Johnson rows');
if (bad.length) { console.error('REFUSED:\n  ' + bad.join('\n  ')); process.exit(1); }

fs.mkdirSync(B + '/_rows', { recursive: true });
fs.writeFileSync(B + '/_rows/ut-last-three-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/ut-last-three-evidence.json', JSON.stringify([], null, 1));
console.log('Johnson 5, Robinson 2, Davis 1 — 8 blanks written');
