/**
 * contributionTotals.ts — refresh transparent_motivations.contribution_totals (CA_0379).
 *
 * One row of whole-table campaign-finance totals (contributions, dollars, politicians, cycles), so
 * readers such as ev-landing/briefing/refresh.mjs stop aggregating the 33 GB contributions table
 * themselves. ev-cto decision 0038 (Part A2): that briefing query read 19.2 GB per run.
 *
 * Runs once a day as the last step of the 'fec-burst' job (src/jobs/registry.ts), after the FEC
 * ingest has written its rows. The refresh is one sequential scan of contributions, so it needs a
 * statement_timeout far above the server's 30 s default; it sets one on its own connection only.
 *
 * Never throws: a failed refresh leaves yesterday's row in place and is logged. The ingest it
 * follows has already succeeded, and must not be reported as failed because of a summary.
 */
import { pool } from './db.js';

/** A full scan of ~29M rows takes ~5 minutes on Small; leave room for a slow day. */
const REFRESH_TIMEOUT = '30min';

export interface ContributionTotals {
  contributions: string;
  dollars: string;
  politicians: number;
  cycles: number;
  min_cycle: string | null;
  max_cycle: string | null;
  refreshed_at: string;
  refresh_ms: number | null;
}

export async function refreshContributionTotals(): Promise<ContributionTotals | null> {
  const client = await pool.connect();
  try {
    // SET LOCAL inside a transaction, so the long timeout cannot leak to the next pool user.
    await client.query('BEGIN');
    await client.query(`SET LOCAL statement_timeout = '${REFRESH_TIMEOUT}'`);
    const { rows } = await client.query<ContributionTotals>(
      'SELECT * FROM transparent_motivations.refresh_contribution_totals()'
    );
    await client.query('COMMIT');
    const t = rows[0] ?? null;
    if (t) {
      console.log(
        `[contributionTotals] refreshed: ${t.contributions} contributions, $${t.dollars}, ` +
          `${t.politicians} politicians, ${t.cycles} cycles (${t.min_cycle}-${t.max_cycle}) in ${t.refresh_ms} ms`
      );
    }
    return t;
  } catch (err) {
    await client.query('ROLLBACK').catch(() => undefined);
    console.error(
      '[contributionTotals] refresh failed (non-fatal; the previous row stays):',
      err instanceof Error ? err.message : String(err)
    );
    return null;
  } finally {
    client.release();
  }
}
