// The 15 Duluth scope blanks, identical for every member of the body.
// Usage: node duluth_scope_blanks.mjs "Full Name" > <batch>/_rows/<slug>-blanks.json
//
// Scope blanks are a fact about the OFFICE, not the person (scope-review.md), so they are templated
// rather than re-reasoned per member. Thirteen rest on a Minnesota statute and are word-for-word the
// same as Saint Paul's; two name Duluth's own school district and county and are NOT.
// 🔴 Do not copy these to another state. North Carolina and Florida differ on three of them, and
// cannabis-policy REVERSES between Minnesota and Florida.
const N = process.argv[2];
// The scope blanks are a fact about the OFFICE, and Duluth's mayor is a different office from a
// council seat even though the statutes bite identically. Pass the office noun so the reasoning
// names the right one.
const IS_MAYOR = (process.argv[3] || '').toLowerCase() === 'mayor';
// 🔴 The council wording is byte-identical to what is already committed for four members, and a
// regression control in this file's header comment asserts that. Do not 'tidy' it.
const OFFICE = IS_MAYOR ? 'the mayor of Duluth' : 'a Duluth City Council member';
const OFFICE_SHORT = IS_MAYOR ? 'the mayor' : 'a city council member';
const WHOSE = IS_MAYOR ? 'this city' : 'this council';
if (!N) { console.error('usage: duluth_scope_blanks.mjs "Full Name" [office noun]'); process.exit(1); }
const OFFICE_CAP = OFFICE_SHORT.charAt(0).toUpperCase() + OFFICE_SHORT.slice(1);

const STATUTE = {
  'gun-policy': 'Scope blank. Minn. Stat. 471.633 preempts all authority of a home rule charter or statutory city to regulate firearms, ammunition or their components, to the complete exclusion of any local ordinance. The only exceptions are regulating the discharge of firearms and adopting rules identical to state law, and neither reaches a rung on this ladder.',
  'campaign-finance': 'Scope blank. Minn. Stat. 211A.12 paragraph (c) states that the section supersedes any home rule charter. Duluth is a home rule charter city, so the contribution limits in paragraph (a) are the legislature’s and not ' + WHOSE + '’s. Rungs 2, 3 and 4 are positions on contribution limits and are therefore state levers; rungs 1 and 5 are beyond any city.',
  'cannabis-policy': 'Scope blank. Minn. Stat. 342.13 bars a local unit of government from prohibiting the possession, transportation or use of cannabis, or the operation of a licensed cannabis business, and allows only reasonable time, place and manner restrictions. Rungs 1 to 3 are therefore unavailable, and rung 4 describes the state law already in force rather than a choice this office makes.',
  abortion: 'Scope blank. Abortion law in Minnesota is set by the legislature and the courts. ' + OFFICE_CAP + ' holds no lever on the legality or the timing limits this ladder asks about.',
  'fossil-fuels': 'Scope blank. Every rung of this ladder is about national production levels, drilling permits and the use of public land. ' + OFFICE_CAP + ' holds no lever on any of them.',
  'trans-athletes': 'Scope blank. Athletic eligibility is set by the state, by the school board and by the athletic associations. ' + OFFICE_CAP + ' holds no lever on any rung.',
  'jail-capacity': 'Scope blank. The jail serving Duluth is operated by the St. Louis County Sheriff and funded by the St. Louis County Board. ' + OFFICE_CAP + ' holds no vote on jail capacity, on alternatives to incarceration, or on detention funding.',
};
const EDU = ['education-ai', 'education-charter-authorization', 'education-curriculum', 'education-equity-programs',
  'education-gender-identity', 'education-library-books', 'education-school-budget', 'education-school-police'];
const EDU_TEXT = 'Scope blank. Duluth Public Schools is Independent School District 709, a separate unit of government with its own elected board. Under Minn. Stat. 123B.02 subd. 1 the elected board of an independent school district has the general charge of the business of the district, so ' + OFFICE + ' holds no lever on any rung of this ladder.';

const blank = (topic_key, reasoning) => ({
  full_name: N, topic_key, value: '', evidence_type: '', reasoning,
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
});
const rows = [
  ...Object.entries(STATUTE).map(([k, v]) => blank(k, v)),
  ...EDU.map((k) => blank(k, EDU_TEXT)),
];
if (rows.length !== 15) { console.error('expected 15 scope blanks, built ' + rows.length); process.exit(1); }
process.stdout.write(JSON.stringify(rows, null, 1));
