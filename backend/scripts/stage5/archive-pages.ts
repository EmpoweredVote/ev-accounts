/**
 * archive-pages — save the archive.org text of pages whose live fetch failed (STAGE5 step 4).
 *
 *   npx tsx --env-file=.env scripts/stage5/archive-pages.ts <pages dir> <url>...
 *
 * The verifier reads a page the live site refuses (HTTP 403, a challenge page) from its newest archive.org snapshot:
 * tier 3 of src/lib/verificationFetch.ts. build_evidence.py had no such step, so a page the verifier CAN read was listed
 * as unread and the person was held (wi-01, 2026-11-10: David Crowley's two wispolitics.com pages, which verified
 * through the archive once fetched the verifier's way). This reads the snapshot with the verifier's own
 * fetchViaWayback and keeps it only when looksLikeRealPage passes, the test the verifier applies, so the saved text is
 * what the verifier will read. Writes <pages dir>/<sha1 of url>.txt, whitespace collapsed. A URL with no usable
 * snapshot is reported and any cached copy of it is removed, so build_evidence.py lists it as unread.
 */
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fetchViaWayback, looksLikeRealPage } from '../../src/lib/verificationFetch.js';

const [dir, ...urls] = process.argv.slice(2);
if (!dir || !urls.length) { console.error('usage: archive-pages.ts <pages dir> <url>...'); process.exit(2); }
mkdirSync(dir, { recursive: true });
let failed = 0;
for (const u of urls) {
  const f = `${dir}/${createHash('sha1').update(u).digest('hex')}.txt`;
  const t = await fetchViaWayback(u).catch(() => null);
  if (!t || !looksLikeRealPage(t)) { failed++; if (existsSync(f)) rmSync(f); console.log('UNREAD', u); continue; }
  writeFileSync(f, t.replace(/\s+/g, ' ').trim());
  console.log(t.length, u);
}
process.exit(failed ? 1 : 0);
