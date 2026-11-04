/**
 * fallback-fetch — load each old-season source through the verifier's own fetch steps
 * (robots gate → live → Wayback) and save its text (STAGE5 step 7.5).
 *
 *   npx tsx --env-file=.env scripts/stage5/fallback-fetch.ts <batch dir>/fallback
 *
 * Reads <fallback>/urls.txt (one URL per line; drop OnTheIssues and Wikipedia first, RULINGS.md W3-R16).
 * Writes <fallback>/pages/<sha1>.txt, pages/index.json (url → file) and pages/failed.json (url → error).
 * A page that fails every step fails the verifier too. Already-saved pages are not fetched again.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { createVerificationFetchSession } from '../../src/lib/verificationFetch.js';

const dir = process.argv[2];
if (!dir) { console.error('usage: fallback-fetch.ts <batch dir>/fallback'); process.exit(2); }
mkdirSync(`${dir}/pages`, { recursive: true });
const s = createVerificationFetchSession() as any;
const idx: Record<string, string> = {}; const failed: Record<string, string> = {};
for (const u of readFileSync(`${dir}/urls.txt`, 'utf8').split('\n').map((l) => l.trim()).filter(Boolean)) {
  const f = createHash('sha1').update(u).digest('hex') + '.txt';
  if (existsSync(`${dir}/pages/${f}`)) { idx[u] = f; continue; }
  try {
    const r = await s.fetch(u);
    const t = typeof r === 'string' ? r : (r?.text ?? '');
    writeFileSync(`${dir}/pages/${f}`, t); idx[u] = f;
    console.log(t.length, u);
  } catch (e: any) { failed[u] = String(e?.message ?? e); console.log('FAILED', u); }
}
writeFileSync(`${dir}/pages/index.json`, JSON.stringify(idx, null, 1));
writeFileSync(`${dir}/pages/failed.json`, JSON.stringify(failed, null, 1));
await s.close?.();
