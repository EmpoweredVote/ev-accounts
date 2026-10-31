/**
 * party-sweep — list evidence snippets (or research-text rows) that name a party.
 *
 *   npx tsx scripts/stage5/party-sweep.ts <evidence.csv>            # STAGE5 step 7.6
 *   npx tsx scripts/stage5/party-sweep.ts --research <research.csv> # step 7.10: the reasoning text
 *
 * One JSON line per hit on stdout ({ n, u, i, s }); exit 0 either way, so count the lines. A hit is
 * namesParty() (src/lib/partyLabels.ts) or a roll-call party letter the detector does not read as a
 * label ("CLANCY D N", "(R)", "R-Dist", "D-12"). A party word inside a source ADDRESS is fine
 * (RULINGS.md "A party word in a source address is fine"), so URLs are never swept.
 */
import { readFileSync } from 'node:fs';
import { parseEvidenceCsv } from '../../src/lib/stanceResearchCsv.js';
import { readCsv, sweepHit } from './lib.js';

const args = process.argv.slice(2);
const research = args[0] === '--research';
const file = research ? args[1] : args[0];
if (!file) {
  console.error('usage: party-sweep.ts <evidence.csv> | --research <research.csv>');
  process.exit(2);
}
const text = readFileSync(file, 'utf8');
const rows = research
  ? readCsv(text).map((r, k) => ({ full_name: r.full_name, source_url: 'research-text', snippet_index: k + 1, snippet: r.reasoning ?? '' }))
  : parseEvidenceCsv(text);
for (const r of rows as any[]) {
  if (sweepHit(r.snippet)) console.log(JSON.stringify({ n: r.full_name, u: r.source_url, i: r.snippet_index, s: r.snippet.slice(0, 160) }));
}
