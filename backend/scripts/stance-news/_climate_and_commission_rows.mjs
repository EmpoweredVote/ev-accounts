// The last two sponsorship leads on the slice-3 open list, worked through. NEITHER MOVES A CHAIR.
//
// 1. The 2021 climate emergency declaration (Randorf, with Sipress, Anderson and Forsman; adopted
//    2021-04-12). 🔴 THE OPERATIVE CLAUSES ARE A DECLARATION, A TARGET AND A PLANNING DIRECTIVE.
//    C47 refuses a study or plan directive as a chair. The one number in it is an emissions target
//    for the city, not a position on how energy is produced, and this ladder asks how much
//    government should do to EXPAND CLEAN ENERGY — mandates, subsidies, permitting. Renewable
//    energy development appears once, as one bullet among nine subjects the plan should cover.
//    ▶ It touches TWO members: Forsman co-sponsored it, and his blank on the same ladder is
//      rewritten here for the same reason. The sponsor list is the only place either name appears.
//
// 2. Kennedy's ordinance integrating the city's LGBTQ+ commission (introduced 2025-10-07, read once,
//    WITHDRAWN 2025-10-27), together with the follow-on ordinance she co-sponsored that was adopted
//    2025-12-15. 🔴 THE STATEMENT OF PURPOSE GIVES BOTH READINGS IN ONE SENTENCE — "improve equity,
//    increase efficiency, and strengthen the impact of the human rights-related work". Strengthening
//    is chair 2; consolidating advisory bodies for efficiency with the enforcement powers untouched
//    is chair 3. Two adjacent chairs survive, so the row stays blank.
//    ⚠ The gender-identity insertion looks like an expansion and is not: the same ordinance adopts
//      the state human rights act definitions "as it may be amended from time to time", and
//      Minnesota added that ground in 2023, so the insertion CONFORMS the city code to state law.
//      This was only visible in the RTF amendment marks — MatterTextPlain shows the inserted words
//      with no indication that they are new, and shows nothing of what was struck.
//
// 🔴 `/matters/{id}/texts` RETURNS 405 ON duluth-mn. The route that works, and that
//    `_matter_text.mjs` does not use, is `/matters/{id}/versions` -> [{Key, Value}] ->
//    `/matters/{id}/texts/{Key}`. Key is the MatterTextId; Value is the version number, and
//    passing Value gives a 404 that reads like a matter with no text.
//
// File numbers are deliberately absent from the reasonings: no Legistar web GUID has been resolved
// for these matters, so none is citable, and this batch describes an uncitable instrument rather
// than numbering it. Sponsorship is attributed to the council's own legislative record.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const ev = parse(fs.readFileSync(B + '/evidence.csv'), { columns: true, skip_empty_lines: true });
const get = (n, t) => {
  const r = csv.find((x) => x.full_name === n && x.topic_key === t);
  if (!r) throw new Error('no row ' + n + '/' + t);
  return r;
};

const RANDORF_CLIMATE = ' Her sponsorships were read from the council’s own legislative record. In April 2021 she brought forward, with Sipress, Anderson and Forsman, the resolution declaring a climate emergency in Duluth, and the council adopted it that same month. It is a real climate instrument and it does not reach this ladder, which asks how much government should do to expand clean energy. Its resolving clauses declare the emergency; commit the city to accelerate its own work so as to exceed an existing pledge to cut the city’s emissions 80 percent by 2050; direct the administration to bring a climate action work plan to the council before the end of that year; list the subjects that plan should cover; ask for an annual progress report; and ask the city to seek state, federal, philanthropic and private money for the effort. A direction to prepare a plan is a refusal rather than a position, which C47 states directly. The emissions pledge is a target for the city’s own operations and community rather than a requirement about how energy is produced, so it does not reach chair 1, which turns on mandates and firm deadlines imposed on the shift itself. Seeking money from other governments and from donors is not the major subsidies, tax credits and public investment of chair 2. Nothing in it addresses permitting or the grid, which is chair 3. Renewable energy development appears once, as one bullet among nine subjects the plan should address, which names a subject and not a level. No article in any of the nine corpora in this slice reports her position on it; the sponsor list is the only place her name appears on it.';

const FORSMAN_CLIMATE = ' His sponsorships were read from the council’s own legislative record, and the one that touches this ladder is the April 2021 resolution declaring a climate emergency in Duluth, which he brought forward with Sipress, Anderson and Randorf and which the council adopted that month. It does not settle this ladder, for the reasons recorded on Randorf’s row: its resolving clauses declare the emergency, commit the city to exceed an existing pledge about its own emissions, direct the administration to prepare a climate action work plan, and ask the city to seek money from other governments and from donors. A planning directive is a refusal rather than a position, an emissions target for the city is not a requirement about how energy is produced, and seeking outside money is not the public investment of chair 2. None of it chooses among mandates, subsidies and permitting. Coverage of his position on the regional utility is closer to the subject and still names no rung: MinnPost reports that he helps lead economic development for that utility and that he has recused himself from votes related to it.';

const KENNEDY_CIVIL = ' Her sponsorships were read from the council’s own legislative record, and the one that touches this ladder is substantial. In October 2025 she brought forward an ordinance that would have dissolved the city’s standalone commission for nonbinary, queer, trans, two spirit, lesbian, gay, bisexual, intersex and asexual residents and re-established it as a standing committee inside the Duluth human rights commission, with the committee’s elected chair holding a vote on the commission itself. The council read it once and she withdrew it two weeks later, after a colleague introduced a broader ordinance doing the same thing for every protected class commission; she then co-sponsored the follow-on ordinance, adopted in December 2025, that repealed the old article and raised the commission’s membership so that those committee chairs could vote. The record is real and it does not settle this ladder, which asks what role government should play in addressing racial and social inequality. Her own statement of purpose carries both readings in a single sentence: the consolidation is to improve equity, increase efficiency and strengthen the impact of the city’s human rights work. Strengthening that work points at chair 2. Consolidating advisory bodies for efficiency, while the enforcement powers of the city’s human rights chapter and of its human rights officer are left exactly as they stand, is chair 3. Her withdrawn version also inserted gender identity into the chapter’s list of prohibited grounds, which reads as an expansion until it is read beside the same ordinance’s adoption of the state human rights act definitions as they may be amended from time to time: Minnesota added that ground in 2023, so the insertion conforms the city code to state law rather than widening it. Two adjacent chairs survive the evidence, so the row stays blank. The ordinances are not cited here because no citable rendering of either has been found; the detail pages are described rather than numbered.';

const rows = [
  { ...get('Roz Randorf', 'climate-change'), reasoning: get('Roz Randorf', 'climate-change').reasoning + RANDORF_CLIMATE },
  { ...get('Arik Forsman', 'climate-change'), reasoning: get('Arik Forsman', 'climate-change').reasoning + FORSMAN_CLIMATE },
  { ...get('Janet Kennedy', 'civil-rights'), reasoning: get('Janet Kennedy', 'civil-rights').reasoning + KENNEDY_CIVIL },
];

// Controls.
// 1. No uncitable file number may leak into a reasoning — that is what trips `instrument-not-cited`.
for (const r of rows) {
  const m = r.reasoning.match(/\b2[0-6]-\d{3,4}R\b|\b2[0-6]-\d{3}-O\b/);
  if (m) throw new Error('uncitable file number leaked into ' + r.full_name + '/' + r.topic_key + ': ' + m[0]);
}
// 2. Every row here must stay blank, and must have been blank before.
for (const r of rows) {
  if (r.value !== '') throw new Error(r.full_name + '/' + r.topic_key + ' must stay blank, value is ' + JSON.stringify(r.value));
}
// 3. A blank carries no citation, so nothing may claim one.
for (const r of rows) {
  if (r.source_url_1 || r.source_url_2 || r.source_url_3) throw new Error('blank row with a source url: ' + r.full_name + '/' + r.topic_key);
}
// 4. Positive control on the reasoning edit itself: each row must have grown, and must end with the
//    new text. A silent no-op here would look exactly like a successful run.
for (let i = 0; i < rows.length; i++) {
  const before = [get('Roz Randorf', 'climate-change'), get('Arik Forsman', 'climate-change'), get('Janet Kennedy', 'civil-rights')][i];
  if (rows[i].reasoning.length <= before.reasoning.length) throw new Error('reasoning did not grow for ' + rows[i].topic_key);
}

const evRows = rows.flatMap((r) => ev.filter((e) => e.full_name === r.full_name && e.topic_key === r.topic_key));
if (evRows.length) throw new Error('these pairs were blank and should carry no evidence rows; found ' + evRows.length);

fs.writeFileSync(B + '/_rows/climate-commission-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/climate-commission-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.map((r) => r.full_name.split(' ').pop() + '/' + r.topic_key + '=' + JSON.stringify(r.value)).join(' '), '| evidence carried:', evRows.length);
