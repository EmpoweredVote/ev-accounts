// local-immigration 3 for the three other sponsors of Duluth resolution 26-0100R.
//
// 🔴🔴 THE PREVIOUS PASS KNEW ABOUT THIS INSTRUMENT AND STOPPED AT THE WRONG RULE.
// Nephew's blank says, correctly, that "the ordinance barring the use of city resources to assist
// federal civil immigration enforcement was adopted unanimously by voice vote, which C46 refuses
// as a position for any member." That is true of the VOTE. C37 admits SPONSORSHIP, which is a
// different act and a different rule, and nobody had called `/matters/{id}/sponsors`.
// The sponsors are Johnson (lead), Tomanek, Desotelle and Nephew.
//
// ▶ A unanimous instrument is invisible to C46 and fully visible to C37. When a measure passes
//   without division, stop asking how people voted and ask who wrote it.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';
import { URL_26_0100R, CHAIR_3_REASONING, buildSnippet } from './_legistar_26_0100R.mjs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const SNIP = await buildSnippet();

// Keep each member's existing sweep paragraph verbatim — it is their measured corpus account and
// nothing about it has changed. Only the topic-specific tail is replaced.
const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const sweepOf = (name) => {
  const r = csv.find((x) => x.full_name === name && x.topic_key === 'local-immigration');
  if (!r) throw new Error('no existing local-immigration row for ' + name);
  // Two sweep paragraph shapes exist in this batch: the Saint Paul one ends at the Racket
  // sentence, the Duluth one at the unsearchable-outlets sentence. Take whichever ends later.
  const markers = ['Racket returns the same results for any query including a nonsense one.',
                   'so no outlet count here covers them.'];
  let end = -1;
  for (const mk of markers) { const i = r.reasoning.indexOf(mk); if (i >= 0) end = Math.max(end, i + mk.length); }
  if (end < 0) throw new Error('sweep paragraph not found for ' + name);
  return r.reasoning.slice(0, end).replace(/^Searched blank\.\s*/, '');
};

const members = [
  {
    name: 'Jordon Johnson',
    opener: 'Johnson is the FIRST-NAMED sponsor of this resolution, and it is the legislation he told the council he was drafting. ',
    tail: ' This row previously read as a blank, and the reason it gave was sound on what it had: at the council meeting after the Pretti shooting he said he was working on draft legislation about the city’s relationship with federal agencies and that the city’s agencies are not there for the purpose of federal immigration laws, and the reporter noted he offered no specifics. That sentence alone could not choose between chair 1 and chair 3. The blank said what would settle it - the instrument itself, once introduced and readable. It was introduced on 30 January 2026 with his name first on it, and it settles it at chair 3.',
  },
  {
    name: 'Terese Tomanek',
    opener: 'Tomanek is the second-named sponsor of this resolution. ',
    tail: ' This row previously read as a blank on the ground that no passage quotes her on detainers, information sharing or the use of local police. That remains true and it is not the point: the chair here rests on her signature on the instrument, not on anything she said to a reporter. A member who co-authors the text is evidenced by the text.',
  },
  {
    name: 'Lynn Marie Nephew',
    opener: 'Nephew is the fourth-named sponsor of this resolution, signing it as council president. ',
    tail: ' 🔴 This row previously read as a blank and it named this very instrument, saying that the measure barring the use of city resources to assist federal civil immigration enforcement was adopted unanimously by voice vote, which C46 refuses as a position for any member. That is correct about the VOTE and it stopped one rule short. C46 governs votes; C37 governs sponsorship, and she is a sponsor. A unanimous instrument is invisible to the divided-vote scan and fully visible to the sponsor list. This is her first chair in this batch, and it comes from an act rather than a quotation.',
  },
];

const rows = members.map((m) => ({
  full_name: m.name,
  topic_key: 'local-immigration',
  value: '3',
  evidence_type: 'record',
  reasoning: m.opener + sweepOf(m.name) + ' ' + CHAIR_3_REASONING + m.tail,
  source_url_1: URL_26_0100R,
  source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
}));

const evRows = members.map((m) => ({ full_name: m.name, topic_key: 'local-immigration', source_url: URL_26_0100R, snippet: SNIP, snippet_index: '1' }));

// Control: every row must name the instrument, and the instrument must be in its snippet.
for (const r of rows) {
  if (!r.reasoning.includes('26-0100R')) throw new Error('reasoning does not name the instrument: ' + r.full_name);
}
if (!SNIP.includes('26-0100r')) throw new Error('snippet does not carry the instrument number');

fs.writeFileSync(B + '/_rows/sponsors-26-0100R-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/sponsors-26-0100R-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.length, '| all scored 3 |', rows.map((r) => r.full_name).join(', '));
