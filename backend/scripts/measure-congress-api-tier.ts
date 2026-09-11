// backend/scripts/measure-congress-api-tier.ts
/**
 * measure-congress-api-tier — re-measure the congress.gov official-API tier.
 * Dev/ops tool (not part of the server bundle).
 *
 * Two metrics:
 *   default    = SNIPPET VERIFICATION. Of tier-1-failing congress.gov URLs that
 *                Wayback/CDX also misses, how many the API tier makes the stored
 *                snippet VERIFY (matchSnippet + name proximity, the real matcher).
 *                Input rows need { url, snippet, full_name, last_name }.
 *   --recovery = PAGE RECOVERY (mirrors the original STEP 1 measurement). Of
 *                tier-1-failing congress.gov URLs that Wayback/CDX also misses,
 *                how many the API tier returns a real page for (looksLikeRealPage).
 *                URL-only: input rows need just { url } (deduped by url).
 *
 * Both metrics fetch live (congress.gov, archive.org, api.congress.gov) and the
 * API step needs CONGRESS_GOV_API_KEY in the ENVIRONMENT (not the Render env — the
 * shell you run this in). --dry runs parse-only: no key, no network.
 *
 * Usage:
 *   npx tsx scripts/measure-congress-api-tier.ts --dry rows.json
 *   CONGRESS_GOV_API_KEY=... npx tsx scripts/measure-congress-api-tier.ts rows.json
 *   CONGRESS_GOV_API_KEY=... npx tsx scripts/measure-congress-api-tier.ts --recovery urls.json
 *
 * Input is a JSON array of objects. Build it against prod (congress.gov only):
 *   recovery URL list (public schema):
 *     SELECT DISTINCT url FROM public.source_verifications WHERE url ILIKE '%congress.gov%';
 *   snippet rows (inform schema):
 *     SELECT e.source_url AS url, e.snippet, p.full_name, p.last_name
 *       FROM inform.politician_context_evidence e
 *       JOIN inform.politicians p ON p.id = e.politician_id
 *      WHERE e.source_url ILIKE '%congress.gov%';
 *   Save the query result as a JSON array of objects (Supabase SQL editor: "Export
 *   as JSON", or `\copy (…) to …` with row_to_json).
 */
import { readFileSync } from 'node:fs';
import {
  fetchViaHttp,
  fetchViaWayback,
  looksLikeRealPage,
} from '../src/lib/verificationFetch.js';
import { fetchCongressPageText, parseCongressUrl } from '../src/lib/adapters/congressAdapter.js';
import { matchSnippet, checkNameProximity } from '../src/lib/researchVerifier.js';

interface Row { url: string; snippet?: string; full_name?: string; last_name?: string }

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.length > 0;
}

// Defensive: prod rows vary in shape, so a null/missing snippet or name must not
// throw — it must just fail to verify. matchSnippet/checkNameProximity/normalizeText
// all call string methods directly on their inputs with no guard of their own.
function verifies(text: string, row: Row): boolean {
  if (!isNonEmptyString(text)) return false;
  if (!isNonEmptyString(row.snippet)) return false;
  if (!isNonEmptyString(row.full_name)) return false;
  if (!isNonEmptyString(row.last_name)) return false;
  const m = matchSnippet(row.snippet, text);
  if (m.verdict !== 'verified') return false;
  const p = checkNameProximity({
    fullName: row.full_name, lastName: row.last_name, pageText: text,
    matchOffsetInNormalized: m.matchOffset,
  });
  return p.verdict === 'verified';
}

// Belt-and-suspenders around the defensive checks above: contain any unanticipated
// throw (malformed row shape we didn't foresee) to this one row/tier rather than
// aborting the whole run and losing every tally.
function safeVerifies(text: string, row: Row): boolean {
  try {
    return verifies(text, row);
  } catch {
    return false;
  }
}

/** Page-recovery success: a fetch returned real, human-visible text. */
function recovered(text: string | null): boolean {
  return !!text && looksLikeRealPage(text);
}

async function runRecovery(congress: Row[]): Promise<void> {
  // Recoverability is a property of the URL, not the snippet — dedup so a URL
  // cited by many evidence rows is fetched (and counted) once.
  const urls = [...new Set(congress.map((r) => r.url))];
  console.log(`distinct congress.gov URLs: ${urls.length}`);
  let tier1Fail = 0, waybackRecovered = 0, apiNewlyRecovered = 0;
  for (const url of urls) {
    let t1: string | null = null;
    try { t1 = await fetchViaHttp(url); } catch { /* 403/err */ }
    if (recovered(t1)) continue;
    tier1Fail++;

    let wb: string | null = null;
    try { wb = await fetchViaWayback(url); } catch { /* none */ }
    if (recovered(wb)) { waybackRecovered++; continue; }

    let api: string | null = null;
    try { api = await fetchCongressPageText(url); } catch { /* none */ }
    if (recovered(api)) apiNewlyRecovered++;
  }
  console.log('--- congress.gov API tier re-measure (PAGE RECOVERY) ---');
  console.log(`tier-1 fails:            ${tier1Fail}`);
  console.log(`Wayback/CDX recovered:   ${waybackRecovered}`);
  console.log(`API NEWLY recovered:     ${apiNewlyRecovered}   <-- recovered count`);
}

async function runVerify(congress: Row[]): Promise<void> {
  let tier1Fail = 0, waybackRecovered = 0, apiNewlyVerified = 0;
  for (const row of congress) {
    // 1) tier 1 alone
    let tier1Text: string | null = null;
    try { tier1Text = await fetchViaHttp(row.url); } catch { /* 403/err */ }
    const tier1Ok = !!tier1Text && looksLikeRealPage(tier1Text) && safeVerifies(tier1Text, row);
    if (tier1Ok) continue;
    tier1Fail++;

    // 2) Wayback/CDX (the current recovery path)
    let wb: string | null = null;
    try { wb = await fetchViaWayback(row.url); } catch { /* none */ }
    if (wb && looksLikeRealPage(wb) && safeVerifies(wb, row)) { waybackRecovered++; continue; }

    // 3) the API tier — does it NEWLY verify what the baseline could not?
    let api: string | null = null;
    try { api = await fetchCongressPageText(row.url); } catch { /* none */ }
    if (api && safeVerifies(api, row)) apiNewlyVerified++;
  }
  console.log('--- congress.gov API tier re-measure (SNIPPET VERIFICATION) ---');
  console.log(`tier-1 fails:            ${tier1Fail}`);
  console.log(`Wayback/CDX recovered:   ${waybackRecovered}`);
  console.log(`API NEWLY verified:      ${apiNewlyVerified}   <-- recovered count`);
}

async function main() {
  const args = process.argv.slice(2);
  const dry = args.includes('--dry');
  const recovery = args.includes('--recovery');
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) { console.error('usage: measure-congress-api-tier.ts [--dry] [--recovery] rows.json'); process.exit(2); }

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

  if (recovery) {
    await runRecovery(congress);
  } else {
    await runVerify(congress);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
