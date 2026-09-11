// backend/scripts/measure-congress-api-tier.ts
/**
 * measure-congress-api-tier — re-measure the STEP 1 sample for the congress.gov
 * official-API tier. Dev/ops tool (not part of the server bundle).
 *
 * Usage:
 *   # smoke test, no key, no network — reports URL parse coverage only:
 *   npx tsx scripts/measure-congress-api-tier.ts --dry rows.json
 *
 *   # full measurement (needs CONGRESS_GOV_API_KEY in the environment):
 *   CONGRESS_GOV_API_KEY=... npx tsx scripts/measure-congress-api-tier.ts rows.json
 *
 * rows.json: [{ "url": "...", "snippet": "...", "full_name": "...", "last_name": "..." }]
 * Produce it from prod source_verifications (congress.gov rows only) with whatever
 * query matches the live column names — this script intentionally does not guess them.
 */
import { readFileSync } from 'node:fs';
import {
  createVerificationFetchSession,
  fetchViaHttp,
  fetchViaWayback,
  looksLikeRealPage,
} from '../src/lib/verificationFetch.js';
import { fetchCongressPageText, parseCongressUrl } from '../src/lib/adapters/congressAdapter.js';
import { matchSnippet, checkNameProximity } from '../src/lib/researchVerifier.js';

interface Row { url: string; snippet: string; full_name: string; last_name: string }

function verifies(text: string, row: Row): boolean {
  const m = matchSnippet(row.snippet, text);
  if (m.verdict !== 'verified') return false;
  const p = checkNameProximity({
    fullName: row.full_name, lastName: row.last_name, pageText: text,
    matchOffsetInNormalized: m.matchOffset,
  });
  return p.verdict === 'verified';
}

async function main() {
  const args = process.argv.slice(2);
  const dry = args.includes('--dry');
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) { console.error('usage: measure-congress-api-tier.ts [--dry] rows.json'); process.exit(2); }

  const rows: Row[] = JSON.parse(readFileSync(file, 'utf8'));
  const congress = rows.filter((r) => parseCongressUrl(r.url) !== null);
  console.log(`rows: ${rows.length} | congress.gov bill/member (parseable): ${congress.length}`);

  if (dry) {
    const unparsed = rows.filter((r) => /congress\.gov/i.test(r.url) && parseCongressUrl(r.url) === null);
    console.log(`congress.gov URLs the parser SKIPS (out of scope): ${unparsed.length}`);
    for (const r of unparsed.slice(0, 20)) console.log('  skip:', r.url);
    return;
  }

  if (!process.env.CONGRESS_GOV_API_KEY) { console.error('CONGRESS_GOV_API_KEY is not set'); process.exit(2); }

  // Ladder WITHOUT the adapter (tier 1 -> Wayback) — the current prod baseline.
  const baseline = createVerificationFetchSession({ congressAdapter: async () => null });

  let tier1Fail = 0, waybackRecovered = 0, apiNewlyVerified = 0;
  for (const row of congress) {
    // 1) tier 1 alone
    let tier1Text: string | null = null;
    try { tier1Text = await fetchViaHttp(row.url); } catch { /* 403/err */ }
    const tier1Ok = !!tier1Text && looksLikeRealPage(tier1Text) && verifies(tier1Text, row);
    if (tier1Ok) continue;
    tier1Fail++;

    // 2) Wayback/CDX (the current recovery path)
    let wb: string | null = null;
    try { wb = await fetchViaWayback(row.url); } catch { /* none */ }
    if (wb && looksLikeRealPage(wb) && verifies(wb, row)) { waybackRecovered++; continue; }

    // 3) the API tier — does it NEWLY verify what the baseline could not?
    let api: string | null = null;
    try { api = await fetchCongressPageText(row.url); } catch { /* none */ }
    if (api && verifies(api, row)) apiNewlyVerified++;
  }

  console.log('--- congress.gov API tier re-measure ---');
  console.log(`tier-1 fails:            ${tier1Fail}`);
  console.log(`Wayback/CDX recovered:   ${waybackRecovered}`);
  console.log(`API NEWLY verified:      ${apiNewlyVerified}   <-- recovered count`);
  await baseline.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
