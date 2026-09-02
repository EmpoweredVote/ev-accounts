/**
 * measure-extraction.ts — run the verificationFetch ladder over a frozen sample
 * and record, per URL: which tier answered, extracted char count, and the
 * deterministic matcher's verdict for every snippet. This is the evidence for
 * decision 0003 rung 1 (article extraction quality).
 *
 * FAITHFUL TO PRODUCTION:
 *   · Uses the real createVerificationFetchSession ladder and the real
 *     researchVerifier matcher (matchSnippet + checkNameProximity), so the
 *     verdicts are exactly what verify-stance-research would compute.
 *   · TIER 2 (headless Chromium) IS DISABLED. Production has no browser (Alpine,
 *     Playwright not installed, path unexercised — decision 0003 Problem 3), and
 *     the extractor change touches only tier 1 (HTTP) and tier 3 (Wayback),
 *     never renderPage. Disabling tier 2 both matches production and isolates the
 *     variable under test.
 *
 * The EXTRACTOR env var selects legacy vs readability inside fetchViaHttp /
 * fetchViaWayback (added in step 2). For the legacy baseline it has no effect.
 *
 * Read-only over the network. No DB. Writes one JSON report + a stdout summary.
 *
 * Usage:
 *   EXTRACTOR=legacy      npx tsx scripts/measure-extraction.ts --sample data/stance-research/extraction-sample-2026-09-01.json --extractor legacy      --date 2026-09-01
 *   EXTRACTOR=readability npx tsx scripts/measure-extraction.ts --sample <same file>                                            --extractor readability --date 2026-09-01
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  createVerificationFetchSession,
  fetchViaHttp,
  fetchViaWayback,
  robotsAllows,
  RobotsDisallowedError,
} from '../src/lib/verificationFetch.js';
import {
  matchSnippet,
  checkNameProximity,
  type SnippetVerdict,
} from '../src/lib/researchVerifier.js';

function opt(name: string, def?: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : def;
}

const SAMPLE = opt('--sample');
const EXTRACTOR = opt('--extractor', process.env.EXTRACTOR ?? 'legacy')!;
const DATE = opt('--date', new Date().toISOString().slice(0, 10))!;
const CONCURRENCY = Number(opt('--concurrency', '4'));
if (!SAMPLE) {
  console.error('ERROR: --sample <path> is required');
  process.exit(2);
}

interface SnippetEntry {
  snippet: string;
  snippet_index: number;
  full_name: string;
  last_name: string;
}
interface SampleItem {
  url: string;
  snippets: SnippetEntry[];
}
interface Slice {
  source: string;
  minWords: number;
  minCoverage: number;
  items: SampleItem[];
}

const sample = JSON.parse(readFileSync(SAMPLE, 'utf8')) as {
  slices: Record<string, Slice>;
};

interface SnippetResult {
  snippet_index: number;
  full_name: string;
  verdict: SnippetVerdict['verdict'];
  reason?: string;
}
interface UrlResult {
  slice: string;
  url: string;
  tier: string;
  extracted_chars: number;
  robots_disallowed: boolean;
  fetch_error: string | null;
  snippets: SnippetResult[];
}

/** Fetch one URL through the ladder with tier 2 disabled, recording the tier. */
async function fetchOne(url: string): Promise<{
  text: string | null;
  tier: string;
  robotsDisallowed: boolean;
  fetchError: string | null;
}> {
  const rec: { http: string | null; wb: string | null; allowed: boolean | null } = {
    http: null,
    wb: null,
    allowed: null,
  };
  const session = createVerificationFetchSession({
    robotsAllows: async (u) => {
      const a = await robotsAllows(u);
      rec.allowed = a;
      return a;
    },
    httpFetch: async (u) => {
      const t = await fetchViaHttp(u);
      rec.http = t;
      return t;
    },
    render: async () => {
      throw new Error('tier2_disabled');
    },
    wayback: async (u) => {
      const t = await fetchViaWayback(u);
      rec.wb = t;
      return t;
    },
  });

  let text: string | null = null;
  let robotsDisallowed = false;
  let fetchError: string | null = null;
  try {
    text = await session.fetch(url);
  } catch (e: any) {
    if (e instanceof RobotsDisallowedError || e?.code === 'robots_disallowed') {
      robotsDisallowed = true;
    } else {
      fetchError = String(e?.message ?? e);
    }
  } finally {
    await session.close();
  }

  let tier = 'none';
  if (text != null) {
    if (rec.http != null && text === rec.http) tier = 'http';
    else if (rec.wb != null && text === rec.wb) tier = rec.allowed === false ? 'wayback_robots' : 'wayback';
    else tier = 'best_effort';
  } else if (robotsDisallowed) {
    tier = 'robots_disallowed';
  }
  return { text, tier, robotsDisallowed, fetchError };
}

function judge(item: SampleItem, slice: Slice, fetched: Awaited<ReturnType<typeof fetchOne>>): SnippetResult[] {
  return item.snippets.map((s) => {
    let v: SnippetVerdict;
    if (fetched.robotsDisallowed) {
      v = { verdict: 'robots_disallowed', reason: 'robots_disallowed' };
    } else if (fetched.text == null) {
      v = { verdict: 'url_broken', reason: fetched.fetchError ?? 'all tiers failed' };
    } else {
      const mv = matchSnippet(s.snippet, fetched.text, {
        minWords: slice.minWords,
        minCoverage: slice.minCoverage,
      });
      if (mv.verdict !== 'verified') {
        v = mv;
      } else {
        v = checkNameProximity({
          fullName: s.full_name,
          lastName: s.last_name,
          pageText: fetched.text,
          matchOffsetInNormalized: mv.matchOffset,
        });
      }
    }
    return {
      snippet_index: s.snippet_index,
      full_name: s.full_name,
      verdict: v.verdict,
      ...('reason' in v && v.reason ? { reason: v.reason } : {}),
    };
  });
}

/** Bounded-concurrency map. */
async function mapPool<T, R>(items: T[], n: number, fn: (t: T, i: number) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  async function worker() {
    while (true) {
      const i = next++;
      if (i >= items.length) return;
      out[i] = await fn(items[i], i);
    }
  }
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, worker));
  return out;
}

const startedAt = new Date().toISOString();
const allResults: UrlResult[] = [];
let done = 0;
const total = Object.values(sample.slices).reduce((a, s) => a + s.items.length, 0);

for (const [sliceName, slice] of Object.entries(sample.slices)) {
  const results = await mapPool(slice.items, CONCURRENCY, async (item) => {
    const fetched = await fetchOne(item.url);
    done++;
    if (done % 20 === 0) console.error(`  ... ${done}/${total} fetched`);
    const r: UrlResult = {
      slice: sliceName,
      url: item.url,
      tier: fetched.tier,
      extracted_chars: fetched.text?.length ?? 0,
      robots_disallowed: fetched.robotsDisallowed,
      fetch_error: fetched.fetchError,
      snippets: judge(item, slice, fetched),
    };
    return r;
  });
  allResults.push(...results);
}

// ── aggregates ───────────────────────────────────────────────────────────────
function median(nums: number[]): number {
  if (!nums.length) return 0;
  const s = [...nums].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : Math.round((s[m - 1] + s[m]) / 2);
}
function sliceAgg(slice: string) {
  const urls = allResults.filter((r) => r.slice === slice);
  const snips = urls.flatMap((r) => r.snippets);
  const byVerdict: Record<string, number> = {};
  for (const s of snips) byVerdict[s.verdict] = (byVerdict[s.verdict] ?? 0) + 1;
  const byTier: Record<string, number> = {};
  for (const u of urls) byTier[u.tier] = (byTier[u.tier] ?? 0) + 1;
  return {
    urls: urls.length,
    snippets: snips.length,
    verified: byVerdict['verified'] ?? 0,
    median_extracted_chars: median(urls.filter((u) => u.extracted_chars > 0).map((u) => u.extracted_chars)),
    by_verdict: byVerdict,
    by_tier: byTier,
  };
}

const report = {
  extractor: EXTRACTOR,
  tier2: 'disabled (matches production: no browser)',
  sample_path: SAMPLE,
  started_at: startedAt,
  finished_at: new Date().toISOString(),
  per_slice: Object.fromEntries(Object.keys(sample.slices).map((s) => [s, sliceAgg(s)])),
  urls: allResults,
};

const outPath = join('data', 'stance-research', `extraction-${EXTRACTOR}-${DATE}.json`);
writeFileSync(outPath, JSON.stringify(report, null, 2));

console.log(`\nwrote ${outPath}  (extractor=${EXTRACTOR}, tier2 disabled)`);
for (const [name, agg] of Object.entries(report.per_slice)) {
  const a = agg as ReturnType<typeof sliceAgg>;
  console.log(
    `  ${name.padEnd(6)}: ${a.verified}/${a.snippets} snippets verified | median chars ${a.median_extracted_chars} | tiers ${JSON.stringify(a.by_tier)}`,
  );
  console.log(`           verdicts ${JSON.stringify(a.by_verdict)}`);
}

// Pending keep-alive sockets / abort timers can keep the event loop open after
// the report is written. The work is done — exit deterministically.
process.exit(0);
