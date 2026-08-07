/**
 * discoverySweep — node-cron registration for the weekly candidate discovery sweep.
 *
 * Registers a job that fires at 02:00 UTC every Sunday and calls
 * runDiscoverySweep() from discoveryCron. The sweep iterates all
 * discovery_jurisdictions with elections within SWEEP_HORIZON_DAYS,
 * processing them sequentially with auto-upsert for high-confidence
 * candidates and a single combined sweep-summary email at the end.
 *
 * Lock collisions (manual trigger running): the sweep skips that run and
 * waits for the next Sunday — no catch-up logic.
 *
 * NOT started in test environments. Cron registration is guarded in
 * index.ts via `if (env.NODE_ENV !== 'test')`.
 */

import cron from 'node-cron';
import { runDiscoverySweep } from '../lib/discoveryCron.js';

/**
 * OPERATOR POLICY (2026-07-26): scheduled jobs must not spend API credits unattended.
 *
 * This is the only cron in the service that spends money — one paid Anthropic agent run per
 * in-horizon jurisdiction, every Sunday. On 2026-07-26 it drained the Anthropic balance
 * mid-sweep: 25 jurisdictions completed, the remaining 21 failed, and each sent its own
 * failure email. Spend is now opt-in and OFF unless someone deliberately turns it on.
 *
 * This gates the SCHEDULE only. The on-demand admin routes (essentialsDiscovery,
 * discoveryDashboard) still work, because a human triggering a run is an attended,
 * intentional spend — which is precisely the distinction the policy draws.
 *
 * To re-enable: set DISCOVERY_SWEEP_ENABLED=true in the Render environment. Any other value,
 * or unset, leaves it off. Default-off is deliberate: forgetting this variable must fail
 * toward not spending money, never toward spending it.
 *
 * ---------------------------------------------------------------------------------------------
 * MEASURED RETURN BEFORE RE-ENABLING (audited 2026-08-07, covering 2026-04-26 → 2026-07-26)
 * ---------------------------------------------------------------------------------------------
 * Read this before setting the variable. The sweep's lifetime output was:
 *
 *     526 cron runs .................. 279 completed, 247 FAILED (47%)
 *   1,043 candidates "found"
 *      37 rows actually written to race_candidates
 *      26 of those 37 were DUPLICATES (70%)
 *   -----
 *       7 net-new real candidates in three months
 *
 * The seven: three Beaverton council candidates, one CA Governor candidate, two NV Secretary of
 * State candidates, and one Covina city treasurer. Every run costs a paid Anthropic agent call.
 *
 * 🔴 It did not merely underperform — it CORRUPTED DATA. Its 26 duplicates were the single worst
 * integrity defect found in the August 2026 election sweep, caused by autoUpsertToRaceCandidates
 * normalising names differently in TypeScript and SQL (see migration 1586). Beverly Hills City
 * Council held 22 rows for 12 people; Sharona Nazarian appeared five times in a three-seat race.
 * Migration 1586 added a unique index so a repeat would now fail loudly rather than silently — but
 * the cost/benefit above is unchanged by that fix.
 *
 * For comparison, the hand-curated feeds we already ingest — clerk_official, sos_filing,
 * county_clerk — produced 311 rows between them with ZERO duplicates.
 */
export function isDiscoverySweepCronEnabled(): boolean {
  return process.env.DISCOVERY_SWEEP_ENABLED === 'true';
}

export function startDiscoverySweepCron(): void {
  if (!isDiscoverySweepCronEnabled()) {
    console.log(
      '[cron] Discovery sweep NOT registered — scheduled Anthropic spend is disabled by policy. ' +
        'Set DISCOVERY_SWEEP_ENABLED=true to re-enable. On-demand runs are unaffected.'
    );
    return;
  }

  cron.schedule(
    // OPS-04: weekly (not daily) cadence is a deliberate cost choice. Each sweep
    // spends paid Anthropic calls proportional to the number of
    // discovery_jurisdictions whose election_date falls within
    // SWEEP_HORIZON_DAYS (see discoveryCron.ts) — running weekly instead of
    // daily bounds the recurring spend to ~1/7th while still catching upstream
    // source changes well ahead of any election. Sunday 02:00 UTC — one hour
    // before districtStaleness ('0 3 * * 0').
    '0 2 * * 0',
    async () => {
      try {
        await runDiscoverySweep();
      } catch (err) {
        console.error('[cron] Unhandled error in discovery sweep:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'discovery-sweep',
    }
  );
  console.log('[cron] Discovery sweep registered (weekly Sunday 02:00 UTC)');
}
