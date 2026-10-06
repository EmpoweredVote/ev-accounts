// Corrections forced by the Legistar sponsor list, 2026-10-05.
//
// Scanning every Duluth matter for sponsors did two things beyond seating 26-0100R: it RESOLVED an
// ambiguity this batch had recorded, and it DISPROVED a sentence already sitting in a scored row.
//
// 🔴 24-030-O, THE 2024 CAMPING ORDINANCE, HAS NO SPONSORS OF RECORD. It came from the
//    administration; the mayor proposed it. Forsman's row says "Forsman put forward the 2024
//    camping ordinance with three colleagues and voted for it." He did not put it forward.
// 🟢 WHAT HE PUT FORWARD WAS THE MONEY. 24-0588R, the resolution requesting the $500,000, is
//    sponsored by Randorf, Nephew, Forsman and Tomanek — Forsman plus exactly the three colleagues
//    he thanked by name that night. That is the antecedent of his "this", which Tomanek's rows had
//    to record as ambiguous because nothing readable settled it. The sponsor list settles it.
//
// Forsman keeps chair 3: it never depended on the authorship clause. It rests on his own words
// about balancing the city's obligations while providing a safe place to be, and on his votes for
// the ordinance with the criminal penalty removed and for the money that went with it.
//
// ⚠ File numbers are deliberately NOT written into these reasonings. The gate requires an
// instrument named in reasoning to appear in a cited snippet, and no citable page has been found
// for these matters — their Legistar web GUIDs are unknown. The instruments are described instead,
// and attributed to the council's own legislative record, which is how this batch already reports
// roll calls in blanks.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const get = (name, topic) => {
  const r = csv.find((x) => x.full_name === name && x.topic_key === topic);
  if (!r) throw new Error('missing row ' + name + '/' + topic);
  return r;
};
const sweepOf = (name, topic) => {
  const r = get(name, topic);
  const markers = ['Racket returns the same results for any query including a nonsense one.', 'so no outlet count here covers them.'];
  let end = -1;
  for (const mk of markers) { const i = r.reasoning.indexOf(mk); if (i >= 0) end = Math.max(end, i + mk.length); }
  if (end < 0) throw new Error('sweep paragraph not found for ' + name + '/' + topic);
  return r.reasoning.slice(0, end).replace(/^Searched blank\.\s*/, '');
};

const SPONSORSHIP_NOTE = ' Sponsorship was read from the council’s own legislative record, matter by matter, for every Duluth matter introduced since June 2020 - the same record the roll calls in this batch come from. It is reported here and not cited, because no citable page has been found for these matters: a Legistar detail page needs a web GUID that the Web API does not supply.';

const rows = [];

// ---- Forsman: the authorship clause is false and comes out. The chair stands on the rest. ----
{
  const r = get('Arik Forsman', 'homelessness');
  const OLD = 'Forsman put forward the 2024 camping ordinance with three colleagues and voted for it.';
  if (!r.reasoning.startsWith(OLD)) throw new Error('Forsman opener has changed — re-read before correcting');
  const NEW = '🔴 Correction, 2026-10-05: this row previously opened by saying Forsman put forward the 2024 camping ordinance with three colleagues. He did not. The ordinance carries no sponsors at all in the council’s legislative record, because the administration proposed it - the mayor did. What Forsman put forward, with exactly the three colleagues he thanked by name that night, was the companion resolution requesting the $500,000. The chair below never rested on the authorship and does not change. He voted for the camping ordinance.';
  rows.push({ ...r, reasoning: NEW + r.reasoning.slice(OLD.length) });
}

// ---- Tomanek: three rows, all blanks, all corrected on fact. ----
rows.push({
  full_name: 'Terese Tomanek', topic_key: 'homelessness', value: '', evidence_type: '',
  reasoning: 'Searched blank. ' + sweepOf('Terese Tomanek', 'homelessness') + ' She voted for the amended 2024 camping ordinance, which the council cut from the mayor’s proposed misdemeanor to a fine of no more than $200, and for the $500,000 that went with it. She did not author the camping ordinance: it carries no sponsors in the council’s legislative record, because the administration brought it.' + SPONSORSHIP_NOTE + ' An earlier version of this row had to record the antecedent of Forsman’s thanks as ambiguous, because the reporting could be read as crediting three colleagues with either the ordinance or the money; the sponsor list resolves it, and it was the money. She is not quoted anywhere in the corpus on what the enforcement should look like, and that is what this ladder needs: nothing separates enforcement conditioned on somewhere to go, which is chair 3, from a prohibition with civil penalties, which is chair 4. Randorf and Forsman reached chair 3 on this ordinance only because each was quoted on the condition. Kennedy, who voted the same way and was not quoted, is recorded blank, and this row follows her.',
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
});
rows.push({
  full_name: 'Terese Tomanek', topic_key: 'homelessness-response', value: '', evidence_type: '',
  reasoning: 'Searched blank. ' + sweepOf('Terese Tomanek', 'homelessness-response') + ' She is a co-sponsor, with Randorf, Nephew and Forsman, of both of the council’s homelessness funding measures in this window: the July 2024 resolution requesting $500,000 in American Rescue Plan funding, which took the city’s investment in the Stepping on Up initiative to $1.15 million, and the November 2024 resolution confirming that support, amending the allocation to draw on the proceeds of the Cirrus incubator sale, and requesting up to a further $500,000 from the development authority to build a 120-bed temporary shelter at the Damiano Center.' + SPONSORSHIP_NOTE + ' That is authorship rather than a vote, and it is better evidence than this row previously had. It still does not seat a chair, and the reason is the instruments themselves rather than her silence. Putting roughly a million dollars of public money into shelter and services reads as chair 2, expanding housing and support services by increasing public funding. The money goes to a nonprofit-led initiative and to a shelter run by the Damiano Center rather than to a programme the city runs, which is the description chair 4 gives. The same document supports both readings. Forsman, who co-sponsored both and spoke to them, is blank on this ladder for exactly this reason: his vote reads chair 2 and his words - the city cannot do this alone, partners and foundations must close the gaps - read chair 4. Randorf, Nephew and Kennedy are blank here too.',
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
});
rows.push({
  full_name: 'Terese Tomanek', topic_key: 'transportation-priorities', value: '', evidence_type: '',
  reasoning: 'Searched blank. ' + sweepOf('Terese Tomanek', 'transportation-priorities') + ' She names road maintenance and nothing else in her own words: the city has been fixing potholes at an unprecedented rate and fixing streets, and those are among the things a tight budget must protect. In August 2022 she brought forward, with Forsman and Mayou, an ordinance limiting ebikes and motorised scooters to 10 mph on the Lakewalk and the Baywalk after residents raised concerns about the danger to pedestrians, which is a safety rule on a shared path rather than a decision about where investment should go. In December 2025 she co-sponsored, with DeLuca, Randorf and Awal, a resolution asking the Transportation Commission to consider a proposal to advance safe, equitable and sustainable street design in downtown Duluth, to gather information, collect public input and bring back recommendations on converting First Street to a flow street.' + SPONSORSHIP_NOTE + ' That last one is the closest she comes to this ladder and it is a request for study and recommendations, which C47 refuses as a chair: a direction to look into something is not a position on where investment should go. She states no position on transit, bike lanes or sidewalk investment anywhere in the corpus.',
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
});

// Controls: no file numbers may leak into these reasonings, because none of them is citable here.
for (const r of rows) {
  const m = r.reasoning.match(/\b2[0-6]-\d{3,4}[A-Z]?\b|\b2[0-6]-\d{3}-O\b/);
  if (m) throw new Error('uncitable file number leaked into ' + r.full_name + '/' + r.topic_key + ': ' + m[0]);
}
if (rows.length !== 4) throw new Error('expected 4 rows');

fs.writeFileSync(B + '/_rows/sponsor-corrections-rows.json', JSON.stringify(rows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length);
for (const r of rows) console.log('  ', r.full_name, '/', r.topic_key, '=', JSON.stringify(r.value));
