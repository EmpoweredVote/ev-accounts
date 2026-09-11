#!/usr/bin/env node
/**
 * check-spatial-ref-baseline — a tamper tripwire on public.spatial_ref_sys.
 *
 * 🔴 WHY THIS EXISTS. PostGIS lives in the `public` schema on this project and
 * cannot be moved by us (the extension is owned by `supabase_admin`; see ev-cto
 * decision 0006). A side effect we ALSO cannot revoke — the grantor is
 * `supabase_admin`, not us — is that `anon` and `authenticated` hold
 * INSERT/UPDATE/DELETE/TRUNCATE on `public.spatial_ref_sys`, with RLS off.
 *
 * That is an accepted risk (Option A) only because the table is a published EPSG
 * reference set nobody has written to, and no live query reads it (guarded
 * statically by check-postgis-spatial-ref-guard.mjs). This is the other half: a
 * cheap daily check that the row count has not moved. A change to it means someone
 * exercised the write grant we cannot take away — i.e. tampering with the
 * coordinate-system reference table that PostGIS distance/reprojection would read.
 *
 * BASELINE. Confirmed live against production `kxsdzaojfaibhuzmclfq` on 2026-09-11:
 * exactly 8500 rows (PostGIS 3.3.7 standard EPSG set). If a LEGITIMATE PostGIS
 * upgrade changes this, update the constant below IN THE SAME PR that causes it and
 * say so in the message. Any other change is an incident — do not just bump the
 * number; raise it against decision 0006.
 *
 * Live-DB check, so like check-child-county it runs on the daily schedule (and
 * workflow_dispatch), NOT on push/PR (a commit of ours cannot change this table),
 * and it SKIPS itself green when DATABASE_URL is absent (forks / manual runs with no
 * secret) rather than failing.
 *
 * Exit 0 = count matches baseline (or skipped). Exit 1 = count moved. Exit 2 = error.
 *
 * Usage:
 *   node scripts/check-spatial-ref-baseline.mjs
 */
import 'dotenv/config';
import { Pool } from 'pg';

/**
 * Pinned row count of public.spatial_ref_sys. See the header: bump ONLY for a
 * deliberate PostGIS upgrade, in the same PR, never to silence a surprise.
 */
const BASELINE = 8500;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const { rows } = await pool.query('SELECT count(*)::bigint AS n FROM public.spatial_ref_sys');
  const count = Number(rows[0].n);

  if (count === BASELINE) {
    console.log(`spatial_ref_sys — ${count} rows, matches the pinned baseline (${BASELINE}). Decision 0006 holds.`);
    await pool.end();
    process.exit(0);
  }

  console.error(
    `FAIL: public.spatial_ref_sys has ${count} rows; the pinned baseline is ${BASELINE}.\n\n` +
    'anon/authenticated hold an un-revocable write grant on this table (ev-cto decision\n' +
    '0006). A change to the row count means either:\n' +
    '  · a deliberate PostGIS upgrade — update BASELINE in this script, in the same PR; or\n' +
    '  · tampering via the anon write grant — treat as an incident and raise it against\n' +
    '    decision 0006 before doing anything else. Do NOT just bump the constant.',
  );
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-spatial-ref-baseline errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
