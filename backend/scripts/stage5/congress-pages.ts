/**
 * congress-pages — save the text of congress.gov pages through the official api.congress.gov reader (STAGE5 step 4).
 *
 *   npx tsx --env-file=.env scripts/stage5/congress-pages.ts <pages dir> <url>...
 *
 * Writes <pages dir>/<sha1 of url>.txt for each URL, whitespace collapsed: the same text the verifier reads
 * (src/lib/adapters/congressAdapter.ts). A plain fetch of congress.gov gets a bot-check page, so a snippet cut from it
 * could never verify. A URL the adapter cannot read (no CONGRESS_GOV_API_KEY, a page it does not parse) is reported,
 * and any cached copy of it is removed, so build_evidence.py lists it as unread instead of cutting from a bot check.
 * The key never reaches stdout or the saved text.
 */
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fetchCongressPageText } from '../../src/lib/adapters/congressAdapter.js';

const [dir, ...urls] = process.argv.slice(2);
if (!dir || !urls.length) { console.error('usage: congress-pages.ts <pages dir> <url>...'); process.exit(2); }
if (!process.env.CONGRESS_GOV_API_KEY) { console.error('CONGRESS_GOV_API_KEY is not set'); process.exit(2); }
mkdirSync(dir, { recursive: true });
let failed = 0;
for (const u of urls) {
  const f = `${dir}/${createHash('sha1').update(u).digest('hex')}.txt`;
  const t = await fetchCongressPageText(u).catch(() => null);
  if (!t || !t.trim()) { failed++; if (existsSync(f)) rmSync(f); console.log('UNREAD', u); continue; }
  writeFileSync(f, t.replace(/\s+/g, ' ').trim());
  console.log(t.length, u);
}
process.exit(failed ? 1 : 0);
