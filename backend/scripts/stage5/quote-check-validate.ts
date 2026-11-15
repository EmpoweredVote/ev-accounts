/**
 * Validate a batch's quote-check answers and append them to the topic's quote-checks.jsonl, once per batch.
 * (Each state used to keep its own copy of this file with a worktree path written into it.)
 *
 *   npx tsx scripts/stage5/quote-check-validate.ts <batch dir> <stage5 dir>
 *
 * Reads <batch>/qc/qc-<n>.jsonl against <batch>/qc/to-check.json (written by `stage5_prompts.py quote-check`).
 * Exit 1, appending nothing, when a line does not parse or a finding on the list has no answer. A second run on an
 * appended batch does nothing (the marker is <batch>/qc/appended.txt).
 */
import { appendFileSync, existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { readQuoteChecks } from '../lib/stage5QuoteCheck.js';

const [B, S] = process.argv.slice(2);
if (!B || !S) { console.error('usage: quote-check-validate.ts <batch dir> <stage5 dir>'); process.exit(1); }
const want: string[][] = JSON.parse(readFileSync(join(B, 'qc/to-check.json'), 'utf8'));
const files = readdirSync(join(B, 'qc')).filter((f) => /^qc-\d+\.jsonl$/.test(f)).sort();
const text = files.map((f) => readFileSync(join(B, 'qc', f), 'utf8').trim()).filter(Boolean).join('\n') + '\n';
const checks = readQuoteChecks(text);
const got = new Set(checks.map((c) => `${c.finding_id}|${c.politician_id}`));
const missing = want.filter(([f, p]) => !got.has(`${f}|${p}`));
console.log(`lines ${checks.length}, passed ${checks.filter((c) => c.verdict === 'passed').length}, missing ${missing.length}`);
if (missing.length) { console.log(missing); process.exit(1); }
const mark = join(B, 'qc/appended.txt');
if (existsSync(mark)) { console.log('already appended'); process.exit(0); }
appendFileSync(join(S, 'quote-checks.jsonl'), text);
writeFileSync(mark, `${new Date().toISOString()} ${checks.length}\n`);
console.log('appended');
