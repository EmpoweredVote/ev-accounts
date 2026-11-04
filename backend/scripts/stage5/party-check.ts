/**
 * party-check — the shared party-label test for every Stage 5 step that cuts text a reader will see.
 *
 *   npx tsx scripts/stage5/party-check.ts        # one JSON string per stdin line → "1" (names a party) or "0"
 *
 * It answers with sweepHit (lib.ts): namesParty() from src/lib/partyLabels.ts, which the writer and the gate
 * use, plus the roll-call party letters party-sweep.ts lists. So a snippet a builder keeps cannot be one the
 * sweep then flags. The Python tools reach it through _party.py, one process per run.
 */
import { createInterface } from 'node:readline';
import { sweepHit } from './lib.js';

const rl = createInterface({ input: process.stdin, terminal: false });
for await (const line of rl) {
  let text = '';
  try { text = String(JSON.parse(line)); } catch { process.stdout.write('E\n'); continue; }
  process.stdout.write(sweepHit(text) ? '1\n' : '0\n');
}
