/**
 * iga-pages — save the text of iga.in.gov pages through the official MyIGA API (STAGE5 step 4).
 *
 *   npx tsx --env-file=.env scripts/stage5/iga-pages.ts <pages dir> <url>...
 *
 * Writes <pages dir>/<sha1 of url>.txt for each URL: the same text the verifier reads
 * (src/lib/adapters/igaAdapter.ts). A roll-call PDF is saved as its party-free render, members listed
 * under each vote; other PDFs as their text; bill and legislator pages rebuilt from the API. A URL the
 * adapter cannot read (no IGA_API_KEY, an out-of-scope page) is reported and not written.
 * The token never reaches stdout or the saved text.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fetchIgaPageText } from '../../src/lib/adapters/igaAdapter.js';

const [dir, ...urls] = process.argv.slice(2);
if (!dir || !urls.length) { console.error('usage: iga-pages.ts <pages dir> <url>...'); process.exit(2); }
if (!process.env.IGA_API_KEY) { console.error('IGA_API_KEY is not set'); process.exit(2); }
mkdirSync(dir, { recursive: true });
let failed = 0;
for (const u of urls) {
  const t = await fetchIgaPageText(u);
  if (!t) { failed++; console.log('UNREAD', u); continue; }
  writeFileSync(`${dir}/${createHash('sha1').update(u).digest('hex')}.txt`, t);
  console.log(t.length, u);
}
process.exit(failed ? 1 : 0);
