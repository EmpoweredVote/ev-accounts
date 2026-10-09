// Move reviewer bookkeeping out of `reasoning` and into `editor_note`, KEEPING THE SUBSTANCE.
//
// 🔴🔴 `reasoning` IS VOTER-FACING. `writeVerifiedStance` writes it into `inform.politician_context`
// and `Citations.jsx` renders it verbatim under "Why this position?". 21 of this batch's 30 scored
// rows carried pipeline bookkeeping: correction logs ("this row previously opened by saying…"),
// internal rule codes (C37, C46), operator glyphs, a ruling note naming the operator, and snippet
// mechanics. None of that is addressed to a voter.
//
// 🔴 A SENTENCE-LEVEL REGEX SPLIT WAS TRIED FIRST AND REJECTED, AND IT IS WORTH KNOWING WHY.
// It read the SHAPE of a sentence, not what it said, and so it did two things wrong at once:
//   - it ORPHANED continuations. "Two things the reviewer should weigh." matched; the two things
//     did not, and stayed behind as a dangling fragment.
//   - it DELETED EVIDENCE. "The re-swept corpus adds her own account of why, which states the chair
//     directly: …" matched on the bookkeeping clause and would have taken Jost's quotation with it.
// The reviewer tails in this batch are mostly BALANCING FACTS — what cuts the other way, what the
// record shows that does not support the chair. Deleting them would make these rows one-sided,
// which is worse for a voter than leaving the bookkeeping in. So every edit below is written by
// hand and asserted to match.
//
// ▶ RULE: strip the bookkeeping, keep the caveat. A voter benefits from "one qualification: this
//   chair names major employers and her instruments are housing"; a voter has no use for "C46".
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';

// The sponsorship block, identical on all four 26-0100R rows. Its last two sentences are also now
// FALSE: Randorf's row was settled on 2026-10-05, and the gateway route resolves any Duluth URL.
const BLOCK_26 = {
  old: '🔴 The vote is deliberately not relied on. The council adopted 26-0100R without a divided roll call, so C46 would refuse the vote as a position. This row rests on sponsorship, which evidences the instrument as filed (C37) - and the operative text here is the text that passed. For the reviewer: a companion ordinance codified the same policy into the city code on 23 February 2026 and was authored by Councilor Randorf alone. Her row on this ladder has not been changed in this pass, because that ordinance’s Legistar detail page could not be resolved to a citable URL - the numeric id must match the GUID or the page serves a 19-byte stub - so its text can be read and not cited. Resolving that URL is the one thing that would settle her row.',
  new: 'This position does not rest on the vote: the council adopted 26-0100R without a divided roll call, so no individual vote is recorded. It rests on sponsorship, and the text as filed is the text that passed. A companion Ordinance codified the same policy into the Duluth City Code on 23 February 2026, authored by Councilor Randorf alone.',
};

/** [full_name, topic_key, [[old, new], …]] — every `old` is asserted present before anything runs. */
const EDITS = [
  ['Diane Desotelle', 'local-immigration', [
    [BLOCK_26.old, BLOCK_26.new],
    ['so this row rests on the instrument alone.', 'so this position rests on the instrument alone.'],
  ]],
  ['Jordon Johnson', 'local-immigration', [
    [BLOCK_26.old, BLOCK_26.new],
    ['This row previously read as a blank, and the reason it gave was sound on what it had: at the council meeting after the Pretti shooting he said he was working on draft legislation about the city’s relationship with federal agencies and that the city’s agencies are not there for the purpose of federal immigration laws, and the reporter noted he offered no specifics. That sentence alone could not choose between chair 1 and chair 3. The blank said what would settle it - the instrument itself, once introduced and readable. It was introduced on 30 January 2026 with his name first on it, and it settles it at chair 3.',
     'At the council meeting after the Pretti shooting he said he was working on draft legislation about the city’s relationship with federal agencies, and that the city’s agencies are not there for the purpose of federal immigration laws; the reporter noted he offered no specifics at the time. This is that legislation, introduced on 30 January 2026 with his name first on it.'],
  ]],
  ['Terese Tomanek', 'local-immigration', [
    [BLOCK_26.old, BLOCK_26.new],
    ['This row previously read as a blank on the ground that no passage quotes her on detainers, information sharing or the use of local police. That remains true and it is not the point: the chair here rests on her signature on the instrument, not on anything she said to a reporter. A member who co-authors the text is evidenced by the text.',
     'No passage in the corpus quotes her on detainers, information sharing or the use of local police. This position rests on her signature on the instrument rather than on anything she said to a reporter: a member who co-authors the text is evidenced by the text.'],
  ]],
  ['Lynn Marie Nephew', 'local-immigration', [
    [BLOCK_26.old, BLOCK_26.new],
    ['🔴 This row previously read as a blank and it named this very instrument, saying that the measure barring the use of city resources to assist federal civil immigration enforcement was adopted unanimously by voice vote, which C46 refuses as a position for any member. That is correct about the VOTE and it stopped one rule short. C46 governs votes; C37 governs sponsorship, and she is a sponsor. A unanimous instrument is invisible to the divided-vote scan and fully visible to the sponsor list. This is her first chair in this batch, and it comes from an act rather than a quotation.',
     'Authorship is what the record carries here, and she signed it: this position comes from an act rather than from a quotation.'],
  ]],
  ['Roz Randorf', 'local-immigration', [
    ['🔴 Chair 1 is excluded', 'Chair 1 is excluded'],
    ['The vote is not relied on. The council adopted 26-005-O unanimously by voice vote, which C46 refuses as a position for any member, and that is why an earlier pass recorded this ladder as blank for her. This row rests on sole authorship, which evidences the instrument as filed (C37), and the text quoted above is the text that passed.',
     'This position does not rest on the vote: the council adopted 26-005-O unanimously by voice vote, so no individual vote is recorded. It rests on her sole authorship, and the text quoted above is the text that passed.'],
  ]],
  ['Arik Forsman', 'homelessness', [
    ['🔴 Correction, 2026-10-05: this row previously opened by saying Forsman put forward the 2024 camping ordinance with three colleagues. He did not. The ordinance carries no sponsors at all in the council’s legislative record, because the administration proposed it - the mayor did. What Forsman put forward, with exactly the three colleagues he thanked by name that night, was the companion resolution requesting the $500,000. The chair below never rested on the authorship and does not change. He voted for the camping ordinance.',
     'The 2024 camping Ordinance carries no sponsors in the council’s legislative record: the mayor’s administration proposed it. What Forsman put forward, with the three colleagues he thanked by name that night, was the companion resolution requesting the $500,000. He voted for the camping ordinance.'],
    ['Note for the reviewer: the enacted text', 'One qualification: the enacted text'],
    ['That text was read from the council’s own legislative record, which publishes no citable page, so the row rests on the reporting instead.',
     'That text was read from the council’s own legislative record, and this position is stated here from the reporting.'],
  ]],
  ['Janet Kennedy', 'civil-rights', [
    ['🔴 For the reviewer, two things that cut against a careless reading of this row. First, ', 'Two things cut against a careless reading of this position. First, '],
    [' So the chair rests on an authored text she withdrew plus an adopted text she co-signed, not on a single enacted ordinance of her own.', ' So this position rests on an authored text she withdrew plus an adopted text she co-signed, rather than on a single enacted Ordinance of her own.'],
    [' ⚠ This row was blank until 6 October 2026 and the blank’s reasoning is worth knowing: her statement of purpose puts improving equity, increasing efficiency and strengthening the impact of the work in a single sentence, and the efficiency half of it is a chair 3 reading of the same consolidation. Ruled chair 2 by Chris Cantrell on 6 October 2026.',
     ' One further qualification: her statement of purpose puts improving equity, increasing efficiency and strengthening the impact of the work in a single sentence, and the efficiency half of that reads as chair 3 applied to the same consolidation.'],
  ]],
  ['Rebecca Noecker', 'residential-zoning', [
    ['The reviewer should weigh one mismatch: ', 'One qualification: '],
    ['The 7-0 vote allowing drop-in day centres is refused by C46 as unanimous and concerns conditional-use permits rather than residential density, and her 2017 remarks on the Ford site concern one redevelopment plan, which this programme does not treat as a communitywide position.',
     'The 7-0 vote allowing drop-in day centres was unanimous, so it records no individual position, and it concerns conditional-use permits rather than residential density; her 2017 remarks on the Ford site concern one redevelopment plan rather than a communitywide position.'],
  ]],
  ['Rebecca Noecker', 'economic-development', [['The reviewer should weigh one mismatch: ', 'One qualification: ']]],
  ['Kaohly Her', 'local-immigration', [['The reviewer should weigh one mismatch: ', 'One qualification: ']]],
  ['HwaJeong Kim', 'housing', [['The reviewer should weigh one qualification: ', 'One qualification: ']]],
  ['Nelsie Yang', 'ranked-choice-voting', [['The reviewer should weigh one nuance.', 'One nuance is worth stating.']]],
  ['Wendy Durrwachter', 'economic-development', [['Two things the reviewer should weigh.', 'Two things are worth stating.']]],
  ['Roger J. Reinert', 'homelessness', [['Two things cut the other way and the reviewer should weigh them:', 'Two things cut the other way:']]],
  ['Roz Randorf', 'rent-regulation', [['For the reviewer: she addresses', 'One qualification: she addresses']]],
  ['Roz Randorf', 'economic-development', [
    ['For the reviewer: chair 3 also names good wages', 'One qualification: chair 3 also names good wages'],
    ['🔴 For the reviewer: Forsman holds chair 4 partly on his role in shaping this same policy.', 'Forsman holds chair 4 partly on his role in shaping this same policy.'],
    ['but a reviewer who reads the exhibit may want to revisit both.', 'but reading that exhibit may be reason to revisit both.'],
  ]],
  ['Terese Tomanek', 'public-safety-approach', [
    ['Her statements as a candidate are used, under the ruling of 2026-10-05.', 'Statements she made as a candidate are used here.'],
    ['The cited passage is long for a reason worth stating: in a candidate questionnaire her name sits at the head of her section and never beside the answer, so a shorter cut would not carry her name close enough to be attributable, and this is the defect that left Mayor Her’s questionnaire unusable in this same batch. ', ''],
    ['For the reviewer: she also voted for the $1.92 million Axon', 'For completeness: she also voted for the $1.92 million Axon'],
    ['but a reviewer who reads an expanded police presence into it should weigh it against the rest.', 'but anyone who reads an expanded police presence into it should weigh it against the rest.'],
  ]],
  ['Saura Jost', 'transportation-priorities', [
    ['This row carried the same chair as a blank until now for one reason, recorded at the time: the Summit report alone would not verify against the page. The Ward 3 questionnaire is the second source, it carries her own answer under her own full name, and both passages were confirmed on the live pages.',
     'The Ward 3 questionnaire is the second source: it carries her own answer under her own full name, and both passages were confirmed on the live pages.'],
    ['Both passages are from her 2023 campaign - she was elected on 7 November 2023 and took office in January 2024 - and are used under the ruling of 2026-10-05, so a reviewer should read them as three-year-old candidate statements.',
     'Both passages are from her 2023 campaign: she was elected on 7 November 2023 and took office in January 2024, so they are three-year-old candidate statements.'],
  ]],
  ['Saura Jost', 'rent-regulation', [
    ['The re-swept corpus adds her own account of why, which states the chair directly: ', 'She gave her own account of why, and it states the position directly: '],
  ]],
  ['Anika Bowie', 'rent-regulation', [
    ['The re-swept corpus of 56 articles confirms the sponsorship and adds nothing that moves it. ', ''],
    ['For the reviewer’s completeness: ', 'For completeness: '],
  ]],
  ['Cheniqua Johnson', 'rent-regulation', [
    ['Her own words name the chair, and the re-swept corpus of 101 articles confirms it without changing it.', 'Her own words name this position.'],
    ['it is recorded so the reviewer sees the whole record rather than only what supports the chair.', 'it is recorded so the whole record is visible rather than only the part that supports this position.'],
  ]],
];

const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const ev = parse(fs.readFileSync(B + '/evidence.csv'), { columns: true, skip_empty_lines: true });

const staged = [];
const missing = [];
for (const [name, topic, pairs] of EDITS) {
  const r = csv.find((x) => x.full_name === name && x.topic_key === topic);
  if (!r) { missing.push(`no row ${name}/${topic}`); continue; }
  let text = r.reasoning;
  const removed = [];
  for (const [oldS, newS] of pairs) {
    // 🔴 THE CONTROL THAT MATTERS: a replacement that does not match is a SILENT no-op, and a
    // silent no-op here ships bookkeeping to a voter. Refuse instead.
    if (!text.includes(oldS)) { missing.push(`${name}/${topic}: source text not found — ${oldS.slice(0, 70)}…`); continue; }
    if (text.split(oldS).length > 2) { missing.push(`${name}/${topic}: source text occurs more than once — ${oldS.slice(0, 50)}…`); continue; }
    text = text.replace(oldS, newS);
    removed.push(oldS);
  }
  const note = (r.editor_note ? r.editor_note + ' ' : '')
    + 'Reviewer bookkeeping moved out of the voter-facing reasoning on 2026-10-06, verbatim: '
    + removed.join(' ⏎ ');
  staged.push({ ...r, reasoning: text.replace(/\s{2,}/g, ' ').trim(), editor_note: note });
}
if (missing.length) { console.error('REFUSED — nothing staged:\n  ' + missing.join('\n  ')); process.exit(1); }

// Controls on the result.
const bad = [];
const BOOKKEEPING = [
  [/\breviewer\b/i, 'the word "reviewer"'],
  [/\bC\d{2}\b/, 'an internal rule code'],
  [/[🔴⚠▶🟢✅]/u, 'an operator glyph'],
  [/\bthis row\b/i, 'a self-reference to the row'],
  [/\bruled (chair )?\d? ?by \b/i, 'a ruling note'],
  [/\bunder the ruling of\b/i, 'a ruling note'],
  [/\bre-swept corpus\b/i, 'pipeline bookkeeping'],
  [/\bthis programme\b/i, 'pipeline bookkeeping'],
  [/\bthis batch\b/i, 'pipeline bookkeeping'],
];
for (const r of staged) {
  for (const [re, what] of BOOKKEEPING) if (re.test(r.reasoning)) bad.push(`${r.full_name}/${r.topic_key}: voter prose still carries ${what}`);
  if (!/\bchair\b/i.test(r.reasoning)) bad.push(`${r.full_name}/${r.topic_key}: no longer names a chair`);
  if (r.evidence_type === 'record' && !/(\bAct\b|\bOrdinance\b|Chapter \d|Resolution No\.|\broll call\b)/.test(r.reasoning)) {
    bad.push(`${r.full_name}/${r.topic_key}: record row no longer names an instrument`);
  }
  // Nothing substantive may vanish: the voter prose must stay within 35% of its original length.
  const orig = csv.find((x) => x.full_name === r.full_name && x.topic_key === r.topic_key).reasoning;
  const drop = 1 - r.reasoning.length / orig.length;
  if (drop > 0.35) bad.push(`${r.full_name}/${r.topic_key}: voter prose lost ${(drop * 100).toFixed(0)}% of its length`);
  console.log(`${(r.full_name + '/' + r.topic_key).padEnd(46)} ${orig.length} -> ${r.reasoning.length} (-${(drop * 100).toFixed(0)}%)`);
}

// Citations are unchanged, so every existing snippet must be carried forward: merge_rows deletes
// the evidence of any pair it replaces.
const evRows = staged.flatMap((r) => ev.filter((e) => e.full_name === r.full_name && e.topic_key === r.topic_key));
for (const r of staged) {
  for (const u of [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean)) {
    if (!evRows.some((e) => e.full_name === r.full_name && e.topic_key === r.topic_key && e.source_url === u)) {
      bad.push(`lost the snippet for ${u} on ${r.full_name}/${r.topic_key}`);
    }
  }
}

if (bad.length) { console.error('\nREFUSED — nothing written:\n  ' + bad.join('\n  ')); process.exit(1); }

fs.writeFileSync(B + '/_rows/voter-prose-rows.json', JSON.stringify(staged, null, 1));
fs.writeFileSync(B + '/_rows/voter-prose-evidence.json', JSON.stringify(evRows, null, 1));
console.log(`\nstaged ${staged.length} rows, ${evRows.length} evidence rows carried forward`);
