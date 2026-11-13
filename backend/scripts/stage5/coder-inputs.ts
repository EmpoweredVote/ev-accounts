/**
 * coder-inputs.ts — Stage 5 step 4: the lean inputs for each coder batch (STAGE5.md "4. Code").
 *
 *   npx tsx scripts/stage5/coder-inputs.ts --config <stage5>/coder-config.json --rulings <stage5>/coder-rulings.md \
 *     --roster <stage5>/roster.tsv [--roster <more.tsv>] --ids <ids file> --unit state:mo --name mo \
 *     --out <stage5>/code-briefs --coded-dir <stage5>/coded [--size 20] [--store <source-store dir>] [--record-only]
 *     [--bill-table <stage5>/bill-table-xx.json]
 *
 * For each batch of `--size` people it writes, in `--out`:
 *   <name>-NN.findings.json  this topic's findings for the batch, compacted (lib/stage5CoderInputs.ts)
 *   <name>-NN.md             the coder brief: the template, the ladder, the batch, and only the rulings this unit needs
 *   <name>-NN.ids.txt        the batch's politician ids, for split-codes.ts
 * The coder writes ONE file, <coded-dir>/<name>-NN.json; `split-codes.ts` checks it and writes the codes.
 *
 * It refuses to write a batch whose compact file does not rebuild to exactly what the store holds, and prints,
 * per batch, the characters a coder read before (the whole findings files) and reads now. Each ruling the
 * filter drops is printed once, so the runner can see what this unit's coders will not be shown.
 *
 * `--bill-table` (round three, 2026-11-13) collapses each person's plain record to one line per bill and act and
 * states the bill table's rung and deciding words once per bill. A record whose note says more than the
 * pre-fill's fixed sentence is never collapsed: it stays word for word. The same refusal applies: the collapsed
 * file must rebuild every finding, note included, exactly as the store holds it.
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { batchLine, collapseBatch, collapsedRoundTripProblems, compactBatch, filterRulings, onTopic, roundTripProblems, type BillTableRow, type CollapsedBatch, type CompactBatch } from '../lib/stage5CoderInputs.js';
import { REPO, STORE, findingsFileSize, instrumentIndex, parseArgs, readConfig, readPersonFindings, readRosters } from './coder-io.js';

const TEMPLATE = join(REPO, '.claude/skills/season-topic-prep/templates/stage5-coder-prompt.md');

/** Put first in a record-first brief (`--record-only`): what the pass is, and why no-stance never fits it. */
export const RECORD_ONLY_NOTE = `**This is the record-first pass.** Your file holds each person's records only (votes and
sponsorships); their own words have not been searched yet. Code each person on the record alone, by every rule
above. Never code no-stance: if the record seats no one, code doesnt-fit with the fitting blank_class. Your codes
decide who is searched next, so do not lean either way to save or force a search.

`;

/** One person per block and one finding per line, so the Read tool never meets a line it would cut. */
export function formatCompact(c: CompactBatch): string {
  const j = (v: unknown) => JSON.stringify(v);
  const bills = Object.entries(c.bills).map(([k, v]) => `  ${j(k)}: ${j(v)}`).join(',\n');
  const people = c.people.map((p) => {
    const head = `{"politician_id": ${j(p.politician_id)}, "name": ${j(p.name)}, "level": ${j(p.level)}, "state": ${j(p.state)}, "scope": ${j(p.scope)},`;
    const searches = p.searches.map((s) => `    ${j(s)}`).join(',\n');
    const findings = p.findings.map((f) => `    ${j(f)}`).join(',\n');
    return ` ${head}\n  "searches": [${searches ? `\n${searches}\n  ` : ''}],\n  "findings": [${findings ? `\n${findings}\n  ` : ''}]}`;
  }).join(',\n');
  return `{"about": ${j(c.about)},\n"topic_key": ${j(c.topic_key)}, "season": ${c.season},\n"search_subjects": ${j(c.search_subjects)},\n`
    + `"bills": {\n${bills}\n},\n"people": [\n${people}\n]}\n`;
}

/** Put first when the batch file carries the bill table (`--bill-table`). */
export const BILL_TABLE_NOTE = `**Your findings file states each bill's reading once.** In its "bills" table, "rung" is the rung a
Yes (a vote or a sponsorship) on that bill supports, decided once for the whole state from the bill's text and the
runner's answers; null means a Yes supports no rung, and "why" says why. Use that reading unless the person's own
finding shows a different version was voted on, or a ruling below reads a named vote differently. Open the bill's
file when you quote it, when "rung" is absent (the table does not list the bill), or when a note raises a doubt.
The table reads bills, not people: gates, both-sides records, later votes on the same provision and every rule
above are still yours to apply.

`;

/** The collapsed layout: one bill per line, one person per block, one record line or finding per line. */
export function formatCollapsed(c: CollapsedBatch): string {
  const j = (v: unknown) => JSON.stringify(v);
  const bills = Object.entries(c.bills).map(([k, v]) => `  ${j(k)}: ${j(v)}`).join(',\n');
  const people = c.people.map((p) => {
    const head = `{"politician_id": ${j(p.politician_id)}, "name": ${j(p.name)}, "level": ${j(p.level)}, "state": ${j(p.state)}, "scope": ${j(p.scope)},`;
    const block = (xs: unknown[]) => (xs.length ? `\n${xs.map((x) => `    ${j(x)}`).join(',\n')}\n  ` : '');
    return ` ${head}\n  "searches": [${block(p.searches)}],\n  "record": [${block(p.record)}],\n  "findings": [${block(p.findings)}]}`;
  }).join(',\n');
  return `{"about": ${j(c.about)},\n"collapsed": true, "topic_key": ${j(c.topic_key)}, "season": ${c.season},\n"search_subjects": ${j(c.search_subjects)},\n`
    + `"bills": {\n${bills}\n},\n"people": [\n${people}\n]}\n`;
}

const recordOnlyFlag = (flags: Map<string, string[]>) => flags.has('record-only');

function main() {
  const { flags } = parseArgs(process.argv.slice(2));
  const one = (k: string, dflt?: string) => {
    const v = flags.get(k)?.[0] ?? dflt;
    if (v === undefined) throw new Error(`--${k} is required`);
    return v;
  };
  const config = readConfig(one('config'));
  const unit = one('unit');
  const name = one('name');
  const out = one('out');
  const codedDir = one('coded-dir');
  const size = Number(one('size', '20'));
  const store = one('store', STORE);
  const rosters = readRosters((flags.get('roster') ?? []).flatMap((r) => r.split(',')));
  if (!rosters.size) throw new Error('--roster is required');
  const listed = readFileSync(one('ids'), 'utf8').split(/\s+/).filter(Boolean);
  const missing = listed.filter((p) => !rosters.has(p));
  if (missing.length) throw new Error(`not on any roster: ${missing.join(', ')}`);
  const config0 = readConfig(one('config'));
  // The record-first pass codes only people with a record on file; the rest go straight to the search list.
  const ids = recordOnlyFlag(flags) ? listed.filter((p) => onTopic(readPersonFindings(store, p), config0.topic_key, new Set(['record'] as const)).length) : listed;
  if (ids.length < listed.length) {
    const none = listed.filter((p) => !ids.includes(p));
    mkdirSync(out, { recursive: true });
    writeFileSync(join(out, `${name}-no-record.txt`), none.join('\n') + '\n');
    console.log(`${none.length} of ${listed.length} have no record on file: not in the record-first pass (${join(out, `${name}-no-record.txt`)})`);
  }

  const recordOnly = recordOnlyFlag(flags);
  // A record-only code may be kept without a second pass (search_list.py recode), so its coder must know the
  // seat: rebuild the roster (topic:stage5-roster writes an `office` column since 2026-11-12).
  const noOffice = ids.filter((p) => !rosters.get(p)!.office?.trim());
  if (noOffice.length) {
    const msg = `${noOffice.length} of ${ids.length} have no office title on the roster, e.g. ${rosters.get(noOffice[0])!.full_name}`;
    if (recordOnly) throw new Error(`${msg}. The record-only pass needs it: rebuild the roster with topic:stage5-roster, or add the office column by hand.`);
    console.log(`warning: ${msg}; their brief lines name no office`);
  }
  const kinds = recordOnly ? new Set(['record'] as const) : undefined;
  const rulings = filterRulings(readFileSync(one('rulings'), 'utf8'), unit);
  if (recordOnly) rulings.text = RECORD_ONLY_NOTE + rulings.text;
  const tablePath = flags.get('bill-table')?.[0];
  const table = tablePath ? (JSON.parse(readFileSync(tablePath, 'utf8')) as { bills: Record<string, BillTableRow> }).bills : undefined;
  if (table) rulings.text = BILL_TABLE_NOTE + rulings.text;
  const index = instrumentIndex(store);
  const template = readFileSync(one('template', TEMPLATE), 'utf8').replace(/<!--[\s\S]*?-->\n?/g, '');
  mkdirSync(out, { recursive: true });

  console.log(`rulings for ${unit}: ${rulings.kept} kept, ${rulings.dropped.length} dropped`);
  for (const d of rulings.dropped) console.log(`  dropped: ${d.slice(0, 140)}${d.length > 140 ? '…' : ''}`);
  console.log('batch\tpeople\tfindings\tbefore_chars\tafter_chars\tbrief_chars');
  let failed = false;
  const totals = { before: 0, after: 0, brief: 0 };
  for (let i = 0, n = 1; i < ids.length; i += size, n++) {
    const batch = `${name}-${String(n).padStart(2, '0')}`;
    const people = ids.slice(i, i + size).map((p) => ({ row: rosters.get(p)!, pf: readPersonFindings(store, p) }));
    const plain = compactBatch(people, config.topic_key, config.season, (id) => index.get(id), kinds);
    const c = table ? collapseBatch(people, config.topic_key, config.season, (id) => index.get(id), table, kinds) : plain;
    const text = table ? formatCollapsed(c as CollapsedBatch) : formatCompact(plain);
    const problems = [
      ...(JSON.stringify(JSON.parse(text)) === JSON.stringify(c) ? [] : ['the written file does not parse back to the batch']),
      ...(table
        ? collapsedRoundTripProblems(people, JSON.parse(text) as CollapsedBatch, config.topic_key, config.season, kinds)
        : roundTripProblems(people, JSON.parse(text) as CompactBatch, config.topic_key, config.season, kinds)),
    ];
    const noFile = Object.keys(c.bills).filter((id) => !c.bills[id].file);
    if (problems.length) {
      failed = true;
      console.error(`${batch}: NOT WRITTEN\n  ${problems.join('\n  ')}`);
      continue;
    }
    const findingsPath = join(out, `${batch}.findings.json`);
    const lines = people.map(({ row }) => batchLine(row));
    const brief = template
      .replaceAll('{{REPO}}', REPO).replaceAll('{{TOPIC_KEY}}', config.topic_key).replaceAll('{{DATE}}', config.date)
      .replaceAll('{{CODEBOOK_VERSION}}', config.codebook).replaceAll('{{SEASON_NUMBER}}', String(config.season))
      .replaceAll('{{REVISION_ID}}', config.revision_id).replaceAll('{{SEASON_ID}}', config.season_id)
      .replaceAll('{{LADDER_TEXT}}', config.ladder_text).replaceAll('{{EVIDENCE_BASIS_BY_LEVEL}}', config.evidence_basis_by_level)
      .replaceAll('{{BATCH_LINES}}', lines.join('\n')).replaceAll('{{FINDINGS_FILE}}', findingsPath)
      .replaceAll('{{INSTRUMENTS_DIR}}', join(store, 'instruments')).replaceAll('{{BATCH}}', batch)
      .replaceAll('{{CODED_FILE}}', join(codedDir, `${batch}.json`)).replaceAll('{{RULINGS}}', rulings.text.trim());
    const left = brief.match(/\{\{\w+\}\}/g);
    if (left) throw new Error(`template slots left unfilled: ${[...new Set(left)].join(', ')}`);
    writeFileSync(findingsPath, text);
    writeFileSync(join(out, `${batch}.md`), brief);
    writeFileSync(join(out, `${batch}.ids.txt`), people.map((p) => p.row.politician_id).join('\n') + '\n');
    const before = people.reduce((s, p) => s + findingsFileSize(store, p.row.politician_id), 0);
    totals.before += before; totals.after += text.length; totals.brief += brief.length;
    const nf = plain.people.reduce((s, p) => s + p.findings.length, 0);
    console.log(`${batch}\t${people.length}\t${nf}\t${before}\t${text.length}\t${brief.length}`);
    if (table) {
      const cc = c as CollapsedBatch;
      const lines = cc.people.reduce((s, p) => s + p.record.length, 0);
      const kept = cc.people.reduce((s, p) => s + p.findings.filter((f) => f.kind === 'record').length, 0);
      const offTable = Object.keys(cc.bills).filter((id) => !table[id]);
      console.log(`  ${batch}: ${nf} findings -> ${lines} record lines; ${kept} record finding(s) kept word for word (their notes say more than the plain facts); plain layout ${formatCompact(plain).length} chars`);
      if (offTable.length) console.log(`  ${batch}: not in the bill table: ${offTable.join(', ')}`);
    }
    if (noFile.length) console.log(`  ${batch}: no instrument file in the store for ${noFile.join(', ')}`);
    const long = text.split('\n').filter((l) => l.length > 2000).length;
    if (long) console.log(`  ${batch}: ${long} line(s) over 2,000 characters (one long passage or note)`);
  }
  console.log(`total\t${ids.length}\t\t${totals.before}\t${totals.after}\t${totals.brief}`);
  if (failed) process.exit(1);
}

main();
