/**
 * topic-blindness-check.ts — scan a blind drafter's transcript for reads of forbidden folders.
 *
 *   npm run topic:blindness-check --prefix backend -- --transcript <jsonl> --forbid <path> [--forbid <path> ...] \
 *     --out <file> [--cwd <dir>]
 *
 * --out is overwritten at start, so a stale PASS can never survive a failed run. It then holds one of:
 *   PASS (N tool calls scanned, M lines skipped)          exit 0
 *   one `line N: TOOL touched PATH` per hit               exit 1
 *   NO EVIDENCE: ...  (zero tool calls scanned)           exit 3
 *   ERROR: ...        (bad flags, unreadable transcript)  exit 2
 * --cwd is the base for relative paths on transcript lines that carry no `cwd`.
 * Reads one file and writes one file; no database.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { flags } from './lib/cliEnv.js';
import { isEmptyForbidden, scanTranscript, summarise } from './lib/blindnessCheck.js';

const values = (name: string) => flags(process.argv, name);

function main(): number {
  let out: string | undefined;
  try {
    [out] = values('--out');
  } catch (e) {
    console.error(`ERROR: ${(e as Error).message}`);
    return 2;
  }
  if (!out) {
    console.error('usage: topic-blindness-check --transcript <jsonl> --forbid <path> [--forbid <path> ...] --out <file> [--cwd <dir>]');
    return 2;
  }
  try {
    writeFileSync(out, '');
    const [transcript] = values('--transcript');
    const forbid = values('--forbid');
    const [cwd] = values('--cwd');
    if (!transcript || !forbid.length) throw new Error('--transcript and at least one --forbid are required');
    const home = homedir();
    const bad = forbid.find((f) => isEmptyForbidden(f, home));
    if (bad !== undefined) throw new Error(`--forbid "${bad}" is empty after normalising`);
    const scan = scanTranscript(readFileSync(transcript, 'utf8'), forbid, home, { cwd });
    const v = summarise(scan);
    writeFileSync(out, v.text + '\n');
    console.log(`${v.status}: ${scan.hits.length} hit(s), ${scan.toolCalls} tool call(s) scanned, ${scan.skippedLines} unparseable line(s) skipped`);
    return v.exitCode;
  } catch (e) {
    const msg = `ERROR: ${(e as Error).message}`;
    console.error(msg);
    try { writeFileSync(out, msg + '\n'); } catch { /* out itself unwritable: stderr already has it */ }
    return 2;
  }
}

process.exit(main());
