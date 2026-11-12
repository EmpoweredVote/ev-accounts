/**
 * coder-inputs.ts — Stage 5 step 4: the lean inputs for each coder batch (STAGE5.md "4. Code").
 *
 *   npx tsx scripts/stage5/coder-inputs.ts --config <stage5>/coder-config.json --rulings <stage5>/coder-rulings.md \
 *     --roster <stage5>/roster.tsv [--roster <more.tsv>] --ids <ids file> --unit state:mo --name mo \
 *     --out <stage5>/code-briefs --coded-dir <stage5>/coded [--size 20] [--store <source-store dir>]
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
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { compactBatch, filterRulings, roundTripProblems, type CompactBatch } from '../lib/stage5CoderInputs.js';
import { REPO, STORE, findingsFileSize, instrumentIndex, parseArgs, readConfig, readPersonFindings, readRosters } from './coder-io.js';

const TEMPLATE = join(REPO, '.claude/skills/season-topic-prep/templates/stage5-coder-prompt.md');

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
  const ids = readFileSync(one('ids'), 'utf8').split(/\s+/).filter(Boolean);
  const missing = ids.filter((p) => !rosters.has(p));
  if (missing.length) throw new Error(`not on any roster: ${missing.join(', ')}`);

  const rulings = filterRulings(readFileSync(one('rulings'), 'utf8'), unit);
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
    const c = compactBatch(people, config.topic_key, config.season, (id) => index.get(id));
    const text = formatCompact(c);
    const problems = [
      ...(JSON.stringify(JSON.parse(text)) === JSON.stringify(c) ? [] : ['the written file does not parse back to the batch']),
      ...roundTripProblems(people, JSON.parse(text) as CompactBatch, config.topic_key, config.season),
    ];
    const noFile = Object.keys(c.bills).filter((id) => !c.bills[id].file);
    if (problems.length) {
      failed = true;
      console.error(`${batch}: NOT WRITTEN\n  ${problems.join('\n  ')}`);
      continue;
    }
    const findingsPath = join(out, `${batch}.findings.json`);
    const lines = people.map(({ row }) => `- ${row.politician_id} — ${row.full_name}, ${row.level}, ${row.state.toUpperCase()}, ${row.scope}`);
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
    const nf = c.people.reduce((s, p) => s + p.findings.length, 0);
    console.log(`${batch}\t${people.length}\t${nf}\t${before}\t${text.length}\t${brief.length}`);
    if (noFile.length) console.log(`  ${batch}: no instrument file in the store for ${noFile.join(', ')}`);
    const long = text.split('\n').filter((l) => l.length > 2000).length;
    if (long) console.log(`  ${batch}: ${long} line(s) over 2,000 characters (one long passage or note)`);
  }
  console.log(`total\t${ids.length}\t\t${totals.before}\t${totals.after}\t${totals.brief}`);
  if (failed) process.exit(1);
}

main();
