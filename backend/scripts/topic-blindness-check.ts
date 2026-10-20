/**
 * topic-blindness-check.ts — scan a blind drafter's transcript for reads of forbidden folders.
 *
 *   npm run topic:blindness-check --prefix backend -- --transcript <jsonl> --forbid <path> [--forbid <path> ...] --out <file>
 *
 * Writes `PASS` or one `line N: TOOL touched PATH` per hit to --out. Exit 1 on any hit, 2 on bad usage.
 * Reports how many transcript lines could not be parsed (they are skipped, never fatal).
 * Reads one file and writes one file; no database.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { scanTranscript } from './lib/blindnessCheck.js';

function values(name: string): string[] {
  const out: string[] = [];
  for (let i = 0; i < process.argv.length; i++) {
    if (process.argv[i] === name) {
      const v = process.argv[i + 1];
      if (!v || v.startsWith('--')) throw new Error(`${name} needs a value`);
      out.push(v);
    }
  }
  return out;
}

function main(): number {
  const [transcript] = values('--transcript');
  const forbid = values('--forbid');
  const [out] = values('--out');
  if (!transcript || !forbid.length || !out) {
    console.error('usage: topic-blindness-check --transcript <jsonl> --forbid <path> [--forbid <path> ...] --out <file>');
    return 2;
  }
  const { hits, skippedLines } = scanTranscript(readFileSync(transcript, 'utf8'), forbid, homedir());
  const body = hits.length ? hits.map((h) => `line ${h.line}: ${h.tool} touched ${h.path}`).join('\n') : 'PASS';
  writeFileSync(out, body + '\n');
  console.log(`${hits.length ? 'FAIL' : 'PASS'}: ${hits.length} hit(s); ${skippedLines} unparseable line(s) skipped`);
  return hits.length ? 1 : 0;
}

process.exit(main());
