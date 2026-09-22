/**
 * stance-gate.ts — deterministic pre-write gate for a stance-research batch. No network, no DB.
 *
 * Reads <dir>/research.csv, evidence.csv, topics.json, politicians.json (see
 * build-stance-topic-bundle.ts). Writes gate-findings.json and stances.csv (the input
 * verify-stance-research.ts expects).
 *
 *   npx tsx scripts/stance-gate.ts --dir data/stance-research/<batch>
 * Exit: 0 clean, 1 high-severity findings (fix research.csv/evidence.csv and re-run), 2 usage.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { parseEvidenceCsv, writeStancesCsv } from '../src/lib/stanceResearchCsv.js';
import { checkBatch, toStanceRows, type ResearchRow, type BundleTopic, type BundlePolitician } from './lib/stanceGate.js';

const i = process.argv.indexOf('--dir');
const DIR = i !== -1 ? process.argv[i + 1] : undefined;
if (!DIR) { console.error('usage: stance-gate.ts --dir <batch>'); process.exit(2); }
for (const f of ['research.csv', 'topics.json', 'politicians.json']) {
  if (!existsSync(join(DIR, f))) { console.error(`ERROR: ${join(DIR, f)} not found`); process.exit(2); }
}

const records = parse(readFileSync(join(DIR, 'research.csv'), 'utf8'),
  { columns: true, skip_empty_lines: true, relax_column_count: true }) as Record<string, string>[];
const research: ResearchRow[] = records
  .map((r) => ({
    full_name: (r.full_name ?? '').trim(),
    topic_key: (r.topic_key ?? '').trim(),
    value: r.value && r.value.trim() !== '' ? Number(r.value) : null,
    reasoning: r.reasoning ?? '',
    evidence_type: (r.evidence_type ?? '').trim(),
    source_urls: [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s ?? '').trim()).filter(Boolean),
  }))
  .filter((r) => r.full_name);
// Positive-control rule (CLAUDE.md): a detector that parsed nothing must not report "clean".
if (research.length === 0) {
  console.error('REFUSING VERDICT: parsed 0 research rows from research.csv — an empty parse is not a clean batch');
  process.exit(2);
}
const evidence = existsSync(join(DIR, 'evidence.csv')) ? parseEvidenceCsv(readFileSync(join(DIR, 'evidence.csv'), 'utf8')) : [];
const topics: BundleTopic[] = JSON.parse(readFileSync(join(DIR, 'topics.json'), 'utf8'));
const politicians: BundlePolitician[] = JSON.parse(readFileSync(join(DIR, 'politicians.json'), 'utf8'));

const findings = checkBatch(research, topics, politicians, evidence);
const by_check: Record<string, number> = {};
for (const f of findings) by_check[f.check_id] = (by_check[f.check_id] ?? 0) + 1;
const summary = {
  rows: research.length,
  high: findings.filter((f) => f.severity === 'high').length,
  medium: findings.filter((f) => f.severity === 'medium').length,
  by_check,
};
writeFileSync(join(DIR, 'gate-findings.json'), JSON.stringify({ findings, summary }, null, 2));
writeFileSync(join(DIR, 'stances.csv'), writeStancesCsv(toStanceRows(research, politicians)));

console.log(`stance-gate: ${summary.rows} rows · high=${summary.high} medium=${summary.medium} · evidence rows=${evidence.length}`);
for (const f of findings) console.log(`  ${f.severity.padEnd(6)} ${f.check_id.padEnd(24)} ${f.full_name} / ${f.topic_key}: ${f.what}`);
process.exit(summary.high > 0 ? 1 : 0);
