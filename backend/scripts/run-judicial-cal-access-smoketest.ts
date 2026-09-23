/**
 * run-judicial-cal-access-smoketest.ts — operator-run ingest of the Cal-Access contributions
 * RECEIVED by the seeded judges' campaign committees, into judicial.donations. Drives
 * calAccessAdapter.ts (prepare + fetch + normalize only) via the Plan 30-02
 * fake-PoliticianSource wrapper.
 *
 * Usage:
 *   cd backend && npx tsx scripts/run-judicial-cal-access-smoketest.ts [--dry-run]
 *
 *   --dry-run  download and parse, print what would be written, write nothing.
 *
 * Requires environment variables:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * Prerequisite: scripts/seed-judicial-smoketest-judges.ts must have been run
 * first, with real operator-verified cal_access_filer_ids populated on each
 * judicial.judges row (this script does NOT seed judges itself).
 *
 * IMPORTANT: All ingest is via direct function calls (not HTTP). Cloudflare
 * blocks POST to accounts.empowered.vote — never use curl/fetch against the
 * deployed API for this ingest.
 *
 * 🔴 THE FIRST RUN (2026-07-21) STORED THE WRONG SIDE OF EVERY RECEIPT. The adapter then matched
 * RCPT_CD.CMTE_ID, which is the CONTRIBUTOR's committee id. All 226 rows it wrote were payments
 * the judge's own committee made to slate-mailer organisations (FORM_TYPE F401A), shown as
 * donations to the judge — e.g. "Dayan Mathai for Superior Court Judge 2014" giving to Dayan
 * Mathai. PR #659 fixed the adapter (recipient = RCPT_CD.FILING_ID -> FILER_FILINGS_CD.FILER_ID)
 * and CA_0196 deleted the 226 rows. Step 2 refuses to write while any such row remains.
 *
 * What it does:
 *   1. Queries judicial.judges for seeded rows (id, full_name, external_ids).
 *   2. Pre-flight: counts cal_access rows with no FILER_ID key in raw_record (written by the
 *      pre-#659 adapter). A real run aborts on any; --dry-run only warns. writeJudicialDonations
 *      never rewrites a stored row, so a stale row would stay beside the corrected ones.
 *   3. Constructs ONE createCalAccessAdapter({ conditional: false }) and calls
 *      prepare(every judge's filer ids): one download (~1.58 GB) and one parse (~2 min) for the
 *      whole run, not one per filer. conditional: false because this run never saves the shared
 *      ETag (see step 5), and once the scheduled cal-access job has stored it, a conditional GET
 *      is a 304 that makes fetch() return zero records without an error.
 *   4. For each judge, for each cal_access_filer_id: builds a fake PoliticianSource via
 *      buildFakePoliticianSource(judge.id, filerId), calls fetch()/normalize(), then writes via
 *      writeJudicialDonations() (or prints on --dry-run). Per-judge/per-filer errors are
 *      isolated (logged, loop continues) rather than aborting the whole run.
 *   5. Does NOT call the adapter's contributions-table write method (D-11) or
 *      its ETag-persistence method — targeted/partial runs never save the
 *      shared production Cal-Access ETag cache (mirrors
 *      campaignFinanceScheduler.ts's runAdapterForSources():
 *      "ETag ownership belongs to the full scheduled run only"). Does NOT
 *      route through the shared ingestion-run helper (couples to
 *      transparent_motivations.ingestion_runs + the adapter's own write path —
 *      wrong table, D-08/D-11). Per Discretion (a), plain structured
 *      console.log is the audit trail for this operator-run ingest.
 *   6. Before exit, runs the JUD-ING-06 post-run attribution assertion and the recipient
 *      assertion (every cal_access row's raw_record FILER_ID is one of its own judge's filer
 *      ids), then logs the total judicial.donations row count.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { createCalAccessAdapter } from '../src/lib/adapters/calAccessAdapter.js';
import type { ContributionInsert } from '../src/lib/adapters/adapterInterface.js';
import { buildFakePoliticianSource, writeJudicialDonations } from '../src/lib/judicial/judicialCalAccessIngest.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const DRY_RUN = process.argv.includes('--dry-run');

interface JudgeRow {
  id: string;
  full_name: string;
  court: string;
  external_ids: { cal_access_filer_ids?: string[] } | null;
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

/** One line of totals plus the five largest donors, so the operator can read who gave. */
function summarize(contributions: ContributionInsert[]): string {
  const sum = contributions.reduce((s, c) => s + c.amount, 0);
  const byDonor = new Map<string, number>();
  for (const c of contributions) {
    const rec = c.raw_record as Record<string, unknown>;
    const name = `${(rec['CTRIB_NAML'] as string | undefined) ?? ''} ${(rec['CTRIB_NAMF'] as string | undefined) ?? ''}`.trim();
    byDonor.set(name, (byDonor.get(name) ?? 0) + c.amount);
  }
  const top = [...byDonor.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, amt]) => `${name || '(no name)'} $${amt.toFixed(2)}`);
  return `$${sum.toFixed(2)}; top donors: ${top.join(' | ') || '(none)'}`;
}

async function main() {
  const startMs = Date.now();
  console.log(`[run-judicial-cal-access-smoketest] Starting${DRY_RUN ? ' (--dry-run: nothing is written)' : ''}...`);

  try {
    // Step 1: Load seeded judges.
    const judgesRes = await pool.query<JudgeRow>(
      `SELECT id, full_name, court, external_ids FROM judicial.judges ORDER BY full_name`
    );

    if (judgesRes.rows.length === 0) {
      console.error(
        '[run-judicial-cal-access-smoketest] ABORT: judicial.judges is empty. ' +
          'Run scripts/seed-judicial-smoketest-judges.ts first.'
      );
      process.exit(1);
    }

    console.log(`[run-judicial-cal-access-smoketest] Loaded ${judgesRes.rows.length} judge(s).`);

    // Step 2: Pre-flight — no row written by the pre-#659 (contributor-side) adapter may remain.
    const staleRes = await pool.query<{ count: string }>(
      `SELECT COUNT(*) FROM judicial.donations
        WHERE data_source = 'cal_access' AND NOT (raw_record ? 'FILER_ID')`
    );
    const staleCount = Number(staleRes.rows[0].count);
    if (staleCount > 0) {
      const msg =
        `${staleCount} cal_access row(s) have no FILER_ID key: written by the pre-#659 adapter, ` +
        'which stored the contributor side. Apply CA_0196 first.';
      if (!DRY_RUN) {
        console.error(`[run-judicial-cal-access-smoketest] ABORT: ${msg}`);
        process.exit(1);
      }
      console.warn(`[run-judicial-cal-access-smoketest] WARNING: ${msg}`);
    }

    // Step 3: One adapter, one download, one parse for every judge's filer ids.
    const allFilerIds = judgesRes.rows.flatMap((j) => j.external_ids?.cal_access_filer_ids ?? []);
    const adapter = createCalAccessAdapter({ conditional: false });
    console.log(`[run-judicial-cal-access-smoketest] Downloading and parsing the SOS export for ${allFilerIds.length} filer id(s)...`);
    await adapter.prepare(allFilerIds);
    if (adapter.zipWasSkipped()) {
      // conditional: false never sends If-None-Match, so this is not expected. A 304 would make
      // every fetch() below return zero records and the run would "succeed" with nothing.
      throw new Error('the Cal-Access download returned 304 Not Modified; nothing was parsed');
    }

    let totalInserted = 0;
    let totalSkipped = 0;
    let totalWouldWrite = 0;

    // Step 4: For each judge, for each filer ID, fetch -> normalize -> write.
    for (const judge of judgesRes.rows) {
      const filerIds = judge.external_ids?.cal_access_filer_ids ?? [];

      if (filerIds.length === 0) {
        console.warn(
          `[run-judicial-cal-access-smoketest] [judge=${judge.full_name}] no cal_access_filer_ids — skipping.`
        );
        continue;
      }

      for (const filerId of filerIds) {
        try {
          const fakePs = buildFakePoliticianSource(judge.id, filerId);
          const raw = await adapter.fetch(fakePs);
          const norm = await adapter.normalize(raw, fakePs);
          const summary =
            `  [judge=${judge.full_name}, filerId=${filerId}] fetched=${raw.totalFetched}, ` +
            `excluded=${norm.excluded ?? 0}, skipped_defects=${norm.skipped}; ${summarize(norm.contributions)}`;

          if (DRY_RUN) {
            totalWouldWrite += norm.contributions.length;
            console.log(`${summary} — would write ${norm.contributions.length}`);
            continue;
          }

          const { inserted, skipped } = await writeJudicialDonations(judge.id, norm.contributions);
          totalInserted += inserted;
          totalSkipped += skipped;
          console.log(`${summary} — inserted=${inserted}, already_stored=${skipped}`);
        } catch (err) {
          console.error(
            `  [judge=${judge.full_name}, filerId=${filerId}] error:`,
            err instanceof Error ? err.message : String(err)
          );
          // Non-aborting: continue to next filer/judge.
        }
      }
    }

    if (DRY_RUN) {
      console.log(`\n[run-judicial-cal-access-smoketest] Dry run: would write ${totalWouldWrite} row(s). Nothing written.`);
      process.exit(0);
    }

    console.log(
      `\n[run-judicial-cal-access-smoketest] Run summary: totalInserted=${totalInserted}, totalSkipped=${totalSkipped}`
    );

    // Deliberately do NOT persist the adapter's ETag here — see file header step 5.

    // Step 6a: JUD-ING-06 post-run attribution assertion.
    const badRes = await pool.query<{ count: string }>(
      `SELECT COUNT(*) FROM judicial.donations
       WHERE source_transaction_id = '' OR source_url = '' OR confidence_level IS NULL OR raw_record = '{}'::jsonb`
    );
    const badCount = Number(badRes.rows[0].count);
    if (badCount !== 0) {
      console.error(`[run-judicial-cal-access-smoketest] FAIL: attribution columns incomplete (${badCount} row(s))`);
      process.exit(1);
    }
    console.log('[run-judicial-cal-access-smoketest] JUD-ING-06 attribution assertion: PASSED (0 incomplete rows)');

    // Step 6b: every row was RECEIVED by its own judge's committee. COALESCE: `jsonb ? NULL` is
    // NULL, which would let a row with no FILER_ID key pass.
    const wrongSideRes = await pool.query<{ count: string }>(
      `SELECT COUNT(*) FROM judicial.donations d
         JOIN judicial.judges j ON j.id = d.judge_id
        WHERE d.data_source = 'cal_access'
          AND NOT (COALESCE(j.external_ids -> 'cal_access_filer_ids', '[]'::jsonb)
                   ? COALESCE(d.raw_record ->> 'FILER_ID', ''))`
    );
    const wrongSideCount = Number(wrongSideRes.rows[0].count);
    if (wrongSideCount !== 0) {
      console.error(
        `[run-judicial-cal-access-smoketest] FAIL: ${wrongSideCount} cal_access row(s) were not filed by their own judge's committee`
      );
      process.exit(1);
    }
    console.log('[run-judicial-cal-access-smoketest] Recipient assertion: PASSED (every row filed by its own judge\'s committee)');

    // Step 6c: Log total judicial.donations row count (SC#2 confirmation).
    const totalRes = await pool.query<{ count: string }>(`SELECT COUNT(*) FROM judicial.donations`);
    console.log(`[run-judicial-cal-access-smoketest] Total judicial.donations rows: ${totalRes.rows[0].count}`);

    const durationMs = Date.now() - startMs;
    console.log(`\n[run-judicial-cal-access-smoketest] Completed in ${(durationMs / 1000).toFixed(1)}s`);
    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[run-judicial-cal-access-smoketest] Fatal error:', err);
  process.exit(1);
});
