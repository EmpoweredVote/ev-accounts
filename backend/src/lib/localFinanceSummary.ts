/**
 * localFinanceSummary — the one writer of essentials.politicians.finance_summary for LOCAL itemized sources
 * (la_socrata, la_county_netfile). Federal summaries come from run-fec-finance-summary.ts (FEC receipts).
 *
 * Rules, matching the campaign-finance summary API (CA_0255, #714):
 *   - Own fundraising only: OWN_FUNDRAISING_SQL (confirmed AND candidate_committee). An ie_committee link is
 *     outside spending, not the politician's money.
 *   - total_raised is GROSS (amount >= 0 rows). A negative row is a RETURNED CONTRIBUTION: it is reported as
 *     total_refunded (positive) + refund_count, never netted out of raised. The old writers called it
 *     `total_spent`, which it is not — spending is not in the contributions table at all.
 *   - A summary this writer owns (same `source`) is CLEARED when the person no longer has own money. Before
 *     this, a person whose links were later disputed kept the old snapshot forever: measured 2026-09-24, 78 of
 *     132 LA_SOCRATA summaries claimed money their confirmed own committees no longer hold.
 *   - A summary from ANOTHER source (e.g. FEC) is never overwritten or cleared.
 *
 * WHEN IT RUNS: after every NetFile ingest (runNetfileIngestWithSummaries — the `la-county-netfile` job and the
 * in-process monthly cron), and on demand as the `local-finance-summary` job or the two write-la-*.ts scripts.
 * Until 2026-09-24 it ran only by hand, so every ingest and every disputed link left the stored summary behind.
 */

import { pool } from './db.js';
import { OWN_FUNDRAISING_SQL } from './campaignFinanceService.js';
import { runAdapterForAll } from './campaignFinanceScheduler.js';

export type LocalSource = { sourceSystem: 'la_socrata' | 'la_county_netfile'; label: 'LA_SOCRATA' | 'LA_COUNTY_NETFILE' };

export interface LocalFinanceSummary {
  total_raised: number;
  total_refunded: number;
  refund_count: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: 'all';
  source: LocalSource['label'];
}

export interface OwnTotals { gross: number; refunded: number; refundCount: number }

export type Plan =
  | { action: 'write'; summary: LocalFinanceSummary; changed: boolean }
  | { action: 'clear' }
  | { action: 'keep-other-source'; otherSource: string }
  | { action: 'nothing' };

/** Pure decision: what to do with one politician's finance_summary. */
export function planLocalSummary(
  existing: Record<string, unknown> | null,
  totals: OwnTotals,
  label: LocalSource['label']
): Plan {
  const existingSource = existing == null ? null : String(existing.source ?? '');
  if (existingSource !== null && existingSource !== label) {
    return { action: 'keep-other-source', otherSource: existingSource || '(no source)' };
  }
  if (totals.gross <= 0) return existingSource === label ? { action: 'clear' } : { action: 'nothing' };

  const summary: LocalFinanceSummary = {
    total_raised: totals.gross,
    total_refunded: totals.refunded,
    refund_count: totals.refundCount,
    top_donors: [],
    cycle: 'all',
    source: label,
  };
  return { action: 'write', summary, changed: canonical(existing) !== canonical(summary) };
}

/** JSON with keys sorted: jsonb comes back from Postgres in its own key order, not insertion order. */
function canonical(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map(canonical).join(',')}]`;
  if (v && typeof v === 'object') {
    return `{${Object.keys(v).sort().map((k) => `${JSON.stringify(k)}:${canonical((v as Record<string, unknown>)[k])}`).join(',')}}`;
  }
  return JSON.stringify(v ?? null);
}

interface Candidate { id: string; full_name: string; finance_summary: Record<string, unknown> | null }

/**
 * Everyone with a confirmed own committee in this system, PLUS everyone whose summary this writer owns —
 * the second half is how a stale summary gets cleared once its links are gone.
 */
async function getCandidates(src: LocalSource): Promise<Candidate[]> {
  const r = await pool.query<Candidate>(
    `SELECT p.id, p.full_name, p.finance_summary
       FROM essentials.politicians p
      WHERE EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
                     WHERE ps.essentials_politician_id = p.id AND ps.source_system = $1 AND ${OWN_FUNDRAISING_SQL})
         OR p.finance_summary->>'source' = $2
      ORDER BY p.full_name, p.id`,
    [src.sourceSystem, src.label]
  );
  return r.rows;
}

async function getOwnTotals(politicianId: string, src: LocalSource): Promise<OwnTotals> {
  const r = await pool.query<{ gross: string; refunded: string; refund_count: string }>(
    `SELECT COALESCE(SUM(c.amount) FILTER (WHERE c.amount >= 0), 0) AS gross,
            COALESCE(-SUM(c.amount) FILTER (WHERE c.amount < 0), 0) AS refunded,
            COUNT(*) FILTER (WHERE c.amount < 0) AS refund_count
       FROM transparent_motivations.contributions c
       JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
      WHERE ps.essentials_politician_id = $1 AND ps.source_system = $2 AND ${OWN_FUNDRAISING_SQL}`,
    [politicianId, src.sourceSystem]
  );
  const row = r.rows[0];
  return { gross: Number(row?.gross ?? 0), refunded: Number(row?.refunded ?? 0), refundCount: Number(row?.refund_count ?? 0) };
}

export type RunCounts = { written: number; unchanged: number; cleared: number; keptOtherSource: number; nothing: number; errors: number };

/** Runs the writer for one source. With dryRun, computes and prints every decision and writes nothing. */
export async function runLocalFinanceSummary(src: LocalSource, dryRun: boolean): Promise<RunCounts> {
  const tag = `[finance-summary ${src.label}${dryRun ? ' DRY RUN' : ''}]`;
  const candidates = await getCandidates(src);
  console.log(`${tag} ${candidates.length} candidate politician(s).`);

  const counts: RunCounts = { written: 0, unchanged: 0, cleared: 0, keptOtherSource: 0, nothing: 0, errors: 0 };
  for (const p of candidates) {
    try {
      const plan = planLocalSummary(p.finance_summary, await getOwnTotals(p.id, src), src.label);
      if (plan.action === 'write') {
        if (!plan.changed) { counts.unchanged++; continue; }
        const before = p.finance_summary as { total_raised?: number } | null;
        console.log(`  [WRITE] ${p.full_name}: raised $${before?.total_raised ?? '-'} -> $${plan.summary.total_raised}` +
          `, refunded $${plan.summary.total_refunded} (${plan.summary.refund_count})`);
        if (!dryRun) {
          await pool.query(`UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
            [JSON.stringify(plan.summary), p.id]);
        }
        counts.written++;
      } else if (plan.action === 'clear') {
        console.log(`  [CLEAR] ${p.full_name}: no own ${src.sourceSystem} money any more (was $${(p.finance_summary as { total_raised?: number })?.total_raised ?? '-'})`);
        if (!dryRun) {
          await pool.query(
            `UPDATE essentials.politicians SET finance_summary = NULL WHERE id = $1 AND finance_summary->>'source' = $2`,
            [p.id, src.label]);
        }
        counts.cleared++;
      } else if (plan.action === 'keep-other-source') {
        console.log(`  [KEEP] ${p.full_name}: summary belongs to ${plan.otherSource}; not touched`);
        counts.keptOtherSource++;
      } else {
        counts.nothing++;
      }
    } catch (err) {
      counts.errors++;
      console.error(`  [ERROR] ${p.full_name}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
  console.log(`${tag} done ${JSON.stringify(counts)}${dryRun ? ' — nothing was written' : ''}`);
  return counts;
}

export const LA_SOCRATA: LocalSource = { sourceSystem: 'la_socrata', label: 'LA_SOCRATA' };
export const LA_COUNTY_NETFILE: LocalSource = { sourceSystem: 'la_county_netfile', label: 'LA_COUNTY_NETFILE' };

/**
 * Both local writers, CITY FIRST. The order matters: a person whose Socrata links were disputed but who has
 * NetFile money (Erik Miller, Robert Luna on 2026-09-24) holds a stale LA_SOCRATA summary that the county writer
 * must not overwrite. The city run clears it, and then the county run may write theirs.
 * Throws when any row errored, so an on-demand job exits non-zero.
 */
export async function runLocalFinanceSummaries(): Promise<void> {
  const city = await runLocalFinanceSummary(LA_SOCRATA, false);
  const county = await runLocalFinanceSummary(LA_COUNTY_NETFILE, false);
  const errors = city.errors + county.errors;
  if (errors > 0) throw new Error(`local finance_summary: ${errors} row(s) failed (city ${city.errors}, county ${county.errors})`);
}

/**
 * The NetFile ingest, then the local summaries. A summary failure is logged and does NOT fail the ingest: the
 * contributions are the product, the summary is a derived snapshot the next run rewrites. An ingest failure
 * skips the summaries (nothing new to summarise) and propagates as before.
 */
export async function runNetfileIngestWithSummaries(): Promise<void> {
  await runAdapterForAll('la_county_netfile');
  try {
    await runLocalFinanceSummaries();
  } catch (err) {
    console.error('[local-finance-summary] after NetFile ingest — summaries NOT fully refreshed:', err);
  }
}
