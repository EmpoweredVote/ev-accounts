/**
 * window-check — the passage of a saved page that the verifier will accept as a blank's examined source.
 *
 *   npx tsx scripts/stage5/window-check.ts      # one JSON object per stdin line → one JSON line back
 *     in:  {"page": "<saved page path>" | "text": "<page text>", "full_name": "...", "aliases": ["..."]}
 *     out: "<passage>" or null
 *
 * It answers with verifiableWindow (lib.ts), built from the verifier's own matchSnippet, matchedSpan and
 * checkNameProximity plus sweepHit, so a passage a builder keeps is one the verifier verifies. The Python
 * tools reach it through _window.py, one process per run.
 */
import { readFileSync } from 'node:fs';
import { createInterface } from 'node:readline';
import { verifiableWindow } from './lib.js';

const rl = createInterface({ input: process.stdin, terminal: false });
for await (const line of rl) {
  let w: string | null = null;
  try {
    const q = JSON.parse(line) as { page?: string; text?: string; full_name: string; aliases?: string[] };
    const text = q.text ?? readFileSync(q.page as string, 'utf8');
    w = verifiableWindow(text, { fullName: q.full_name, aliases: q.aliases ?? [] });
  } catch { process.stdout.write('"E"\n'); continue; }
  process.stdout.write(JSON.stringify(w) + '\n');
}
