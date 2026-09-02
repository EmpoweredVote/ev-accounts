/**
 * build-extraction-sample.ts — freeze the URL/snippet sample used to measure
 * article-extraction quality (decision 0003, rung 1).
 *
 * WHY A FROZEN SAMPLE: the baseline (legacy extractor) and the post-change
 * (readability extractor) measurement passes MUST run over the identical set of
 * URLs, snippets and politician names, or the before/after comparison is
 * meaningless. This script pulls the sample ONCE and writes it to disk; both
 * measurement passes then read that file.
 *
 * SOURCE OF SNIPPETS: public.source_verifications stores only URLs, so it cannot
 * yield a snippet match rate. The real (url, snippet, name) triples live in:
 *   · inform.politician_context_evidence — stance snippets (the GOAL of the task)
 *   · essentials.quotes                  — Read & Rank verbatim quotes
 *
 * Read-only. One SELECT per slice. Writes counts to stdout, data to the file.
 *
 * Usage:
 *   npx tsx scripts/build-extraction-sample.ts --date 2026-09-01 [--quote-limit 100]
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { Pool } from 'pg';

function opt(name: string, def?: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : def;
}

const DATE = opt('--date', new Date().toISOString().slice(0, 10))!;
const QUOTE_LIMIT = Number(opt('--quote-limit', '100'));

// Production-faithful matcher settings, chosen per slice (see task notes):
//   · stance: minWords 25 — exactly what verify-stance-research.ts uses.
//   · quote : minWords 8 and only quotes >= 12 words, so the length gate does
//     not mask the extraction effect (quotes are short: median 17 words).
const STANCE_MIN_WORDS = 25;
const QUOTE_MIN_WORDS = 8;
const QUOTE_SAMPLE_FLOOR_WORDS = 12;
const MIN_COVERAGE = 0.6;

const lastToken = (name: string) =>
  name.trim().split(/\s+/).filter(Boolean).slice(-1)[0] ?? name;

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

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 4,
  connectionTimeoutMillis: 8_000,
});

function groupByUrl(
  rows: { source_url: string; snippet: string; snippet_index: number; full_name: string }[],
): SampleItem[] {
  const byUrl = new Map<string, SampleItem>();
  for (const r of rows) {
    if (!byUrl.has(r.source_url)) byUrl.set(r.source_url, { url: r.source_url, snippets: [] });
    byUrl.get(r.source_url)!.snippets.push({
      snippet: r.snippet,
      snippet_index: r.snippet_index,
      full_name: r.full_name,
      last_name: lastToken(r.full_name),
    });
  }
  return [...byUrl.values()];
}

// ── stance slice: every stored context-evidence snippet ──────────────────────
const { rows: stanceRows } = await pool.query<{
  source_url: string;
  snippet: string;
  snippet_index: number;
  full_name: string;
}>(
  `SELECT e.source_url, e.snippet, e.snippet_index, p.full_name
     FROM inform.politician_context_evidence e
     JOIN essentials.politicians p ON p.id = e.politician_id
    WHERE coalesce(e.snippet, '') <> ''
    ORDER BY e.source_url, e.snippet_index`,
);

// ── quote slice: one representative (longest) quote per URL, random N ─────────
const { rows: quoteRows } = await pool.query<{
  source_url: string;
  snippet: string;
  snippet_index: number;
  full_name: string;
}>(
  `WITH base AS (
     SELECT q.source_url,
            q.quote_text AS snippet,
            0 AS snippet_index,
            p.full_name,
            row_number() OVER (PARTITION BY q.source_url ORDER BY length(q.quote_text) DESC) AS rn
       FROM essentials.quotes q
       JOIN essentials.politicians p ON p.id = q.politician_id
      WHERE q.readrank_selected IS TRUE
        AND q.source_url IS NOT NULL
        AND array_length(regexp_split_to_array(btrim(q.quote_text), '\\s+'), 1) >= $1
   )
   SELECT source_url, snippet, snippet_index, full_name
     FROM base
    WHERE rn = 1
    ORDER BY random()
    LIMIT $2`,
  [QUOTE_SAMPLE_FLOOR_WORDS, QUOTE_LIMIT],
);

await pool.end();

const sample = {
  generated_at: new Date().toISOString(),
  note: 'Frozen sample for extraction-quality measurement (decision 0003 rung 1). Read-only; snippets are public citation data.',
  slices: {
    stance: {
      source: 'inform.politician_context_evidence',
      minWords: STANCE_MIN_WORDS,
      minCoverage: MIN_COVERAGE,
      items: groupByUrl(stanceRows),
    },
    quote: {
      source: 'essentials.quotes (readrank_selected, >=12 words, longest per URL)',
      minWords: QUOTE_MIN_WORDS,
      minCoverage: MIN_COVERAGE,
      items: groupByUrl(quoteRows),
    },
  },
};

const outPath = join('data', 'stance-research', `extraction-sample-${DATE}.json`);
writeFileSync(outPath, JSON.stringify(sample, null, 2));

const nSnip = (items: SampleItem[]) => items.reduce((a, it) => a + it.snippets.length, 0);
console.log(`wrote ${outPath}`);
console.log(
  `  stance: ${sample.slices.stance.items.length} URLs, ${nSnip(sample.slices.stance.items)} snippets (minWords ${STANCE_MIN_WORDS})`,
);
console.log(
  `  quote : ${sample.slices.quote.items.length} URLs, ${nSnip(sample.slices.quote.items)} snippets (minWords ${QUOTE_MIN_WORDS})`,
);
