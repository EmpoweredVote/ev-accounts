/**
 * split-codes.ts — Stage 5 step 4: check one coder batch file and write its codes (STAGE5.md "4. Code").
 *
 *   npx tsx scripts/stage5/split-codes.ts <coded>/<batch>.json --config <stage5>/coder-config.json \
 *     --codes <stage5>/codes [--ids <code-briefs>/<batch>.ids.txt] [--store <source-store dir>] [--replace]
 *
 * The coder writes `{ "batch": "...", "codes": [ ... ] }`. Each entry is finished (lib/stage5Ingest.ts
 * `finalizeCode`: season fields from the config, `coded_at` now, `evidence_basis` from the cited findings) and
 * checked (`checkAtIngest`: `checkCode` plus the bill, label and quote checks). A passing code is written to
 * `<codes>/<politician_id>.json`. A failing one is not written: it goes, with every problem in plain words, to
 * `<batch>.sendback.md` beside the coder's file, ready to hand back to a coder. `--ids` also reports anyone in
 * the batch the file leaves out, or anyone it adds. An existing code file is never overwritten without
 * `--replace` (a re-code after a ruling).
 *
 * Exit 0: every code written. Exit 3: some sent back (the rest written). Exit 1: the file cannot be read.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { checkAtIngest, finalizeCode, rungTextsFromLadder } from '../lib/stage5Ingest.js';
import { STORE, instrumentIndex, instrumentTexts, parseArgs, readConfig, readPersonFindings } from './coder-io.js';

function main(): number {
  const { pos, flags } = parseArgs(process.argv.slice(2));
  const file = pos[0];
  const configPath = flags.get('config')?.[0];
  const codesDir = flags.get('codes')?.[0];
  if (!file || !configPath || !codesDir) {
    console.error('usage: split-codes.ts <batch file> --config <coder-config.json> --codes <dir> [--ids <file>] [--store <dir>] [--replace]');
    return 1;
  }
  const config = readConfig(configPath);
  const store = flags.get('store')?.[0] ?? STORE;
  const replace = flags.has('replace');
  let body: { batch?: string; codes?: unknown };
  try {
    body = JSON.parse(readFileSync(file, 'utf8'));
  } catch (e) {
    console.error(`${file}: not readable JSON (${(e as Error).message}). Ask the coder to write the file again.`);
    return 1;
  }
  const entries = Array.isArray(body) ? body : body.codes;
  if (!Array.isArray(entries)) { console.error(`${file}: no "codes" list`); return 1; }

  const index = instrumentIndex(store);
  const ctx = { instruments: new Map(), rungTexts: rungTextsFromLadder(config.ladder_text) };
  const now = new Date();
  const sendback: string[] = [];
  const seen = new Set<string>();
  let written = 0;
  mkdirSync(codesDir, { recursive: true });
  for (const raw of entries as Record<string, unknown>[]) {
    const pid = String(raw?.politician_id ?? '');
    const label = `${pid || '(no politician_id)'}`;
    if (seen.has(pid)) { sendback.push(`### ${label}\n- this person appears twice in the file: give one code`); continue; }
    seen.add(pid);
    const pf = /^[0-9a-f-]{36}$/.test(pid) ? readPersonFindings(store, pid) : undefined;
    if (!pf) { sendback.push(`### ${label}\n- no findings file in the store for this id: check the id against the batch list`); continue; }
    const code = finalizeCode(raw, config, pf, now);
    ctx.instruments = instrumentTexts(store, index, pf.findings.flatMap((f) => (f.instrument_id ? [f.instrument_id] : [])));
    const problems = checkAtIngest(code, pf, ctx);
    const target = join(codesDir, `${pid}.json`);
    if (!problems.length && existsSync(target) && !replace) problems.push(`a code is already on file (${target}); run with --replace if this is a re-code`);
    if (problems.length) { sendback.push(`### ${label}\n${problems.map((p) => `- ${p}`).join('\n')}`); continue; }
    writeFileSync(target, JSON.stringify(code, null, 2) + '\n');
    written++;
  }
  const idsPath = flags.get('ids')?.[0];
  if (idsPath) {
    const want = readFileSync(idsPath, 'utf8').split(/\s+/).filter(Boolean);
    const left = want.filter((p) => !seen.has(p));
    const extra = [...seen].filter((p) => p && !want.includes(p));
    if (left.length) sendback.push(`### missing from the file\n${left.map((p) => `- ${p}: no code given; code this person`).join('\n')}`);
    if (extra.length) sendback.push(`### not in this batch\n${extra.map((p) => `- ${p}: not in the batch list; nothing written for them`).join('\n')}`);
  }
  const sbPath = file.replace(/\.json$/, '') + '.sendback.md';
  if (sendback.length) {
    writeFileSync(sbPath, `# Sent back: ${body.batch ?? file}\n\nFix each code below and write them again, in the same one-file shape, `
      + `with only these people. Everything else in the batch was written.\n\n${sendback.join('\n\n')}\n`);
  }
  console.log(`${body.batch ?? file}: ${written} written, ${sendback.length} sent back${sendback.length ? ` (${sbPath})` : ''}`);
  return sendback.length ? 3 : 0;
}

process.exit(main());
