/**
 * seed-judicial-smoketest-judges.ts — inserts the 2-3 Chris-confirmed CA appellate
 * justices (Corrigan/Liu/Kruger shortlist) into judicial.judges with their
 * Cal-Access retention-committee filer IDs in external_ids.cal_access_filer_ids.
 *
 * Usage:
 *   cd /c/EV-Accounts/backend && npx tsx scripts/seed-judicial-smoketest-judges.ts
 *
 * Requires environment variables:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * IMPORTANT: All ingest is via direct function calls (not HTTP). Cloudflare blocks
 * POST to accounts.empowered.vote / powersearch.sos.ca.gov automated fetches —
 * never use curl/fetch against those hosts. Cal-Access filer IDs for this script's
 * JUDGES array CANNOT be looked up automatically (SoS PowerSearch/Cal-Access tools
 * are JS-rendered/Cloudflare-blocked to automated fetches, confirmed in
 * 30-RESEARCH.md). An operator must manually look up each justice's retention-
 * committee Filer/Entity ID via https://powersearch.sos.ca.gov/ (see 30-RESEARCH.md
 * "Cal-Access Filer ID Lookup Procedure") and edit the real ID(s) into the JUDGES
 * array below BEFORE running this script. Do not hardcode guessed/unverified IDs —
 * a wrong filer ID silently attributes another committee's donors to the wrong
 * judge (defamation-adjacent risk per the phase's threat model, T-30-08).
 *
 * What it does:
 *   1. Guards: refuses to seed any judge whose cal_access_filer_ids is still the
 *      empty/sentinel default — prints which judge needs IDs and exits non-zero.
 *   2. INSERTs each judge via parameterized $n INSERT with
 *      ON CONFLICT (full_name, court) DO NOTHING (idempotent re-run).
 *   3. Logs INSERT vs SKIP per judge.
 *   4. Logs all judicial.judges rows (id, full_name, court, external_ids) to
 *      confirm final state.
 */

import 'dotenv/config';
import { Pool } from 'pg';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

/** Sentinel marking a not-yet-filled filer ID slot — never a real Cal-Access ID. */
const OPERATOR_FILL_SENTINEL = '<OPERATOR: fill from PowerSearch>';

interface JudgeSeed {
  full_name: string;
  court: 'ca_supreme' | 'ca_court_of_appeal' | 'ca_superior';
  cal_access_filer_ids: string[];
}

/**
 * PIVOT (2026-07-21, see 30-DATA-VIABILITY-MEMO.md): the original Corrigan/Liu/Kruger
 * appellate shortlist was proven to have ZERO Cal-Access contribution data — CA
 * appellate/Supreme justices face uncontested retention and never form contribution-
 * receiving committees. A full scan of the Cal-Access bulk export confirmed 0 receipt
 * rows for all three. CA judicial campaign money lives at the SUPERIOR (trial) COURT
 * level, where judges run contested, funded races.
 *
 * These three LA County Superior Court judges are seeded to prove the ingest pipeline
 * end-to-end against REAL donor data (SC#2). Filer IDs were extracted directly from the
 * Cal-Access bulk FILERNAME_CD.TSV + verified to hold itemized receipts in RCPT_CD.TSV
 * (NOT via the Cloudflare-blocked PowerSearch UI):
 *   - Susan Jung Townsend — filer 1377866 — ~$468K, 77 rows (2016 cycle)
 *   - Dayan Mathai        — filer 1359949 — ~$392K, 79 rows (2014 cycle)
 *   - Sydne Michel        — filer 1401161 — ~$355K, 70 rows (2018 cycle)
 */
const JUDGES: JudgeSeed[] = [
  {
    full_name: 'Susan Jung Townsend',
    court: 'ca_superior',
    cal_access_filer_ids: ['1377866'],
  },
  {
    full_name: 'Dayan Mathai',
    court: 'ca_superior',
    cal_access_filer_ids: ['1359949'],
  },
  {
    full_name: 'Sydne Michel',
    court: 'ca_superior',
    cal_access_filer_ids: ['1401161'],
  },
];

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

/** True if a judge's filer-ID slot is still empty or holds only the sentinel value. */
function hasNoRealFilerIds(j: JudgeSeed): boolean {
  if (j.cal_access_filer_ids.length === 0) return true;
  return j.cal_access_filer_ids.every(
    (id) => !id || id === OPERATOR_FILL_SENTINEL || id.trim().length === 0
  );
}

async function main() {
  console.log('[seed-judicial-smoketest-judges] Starting...');

  try {
    // Step 1: Startup guard — refuse to seed any judge with no real filer IDs.
    const unfilled = JUDGES.filter(hasNoRealFilerIds);
    if (unfilled.length > 0) {
      console.error(
        '[seed-judicial-smoketest-judges] ABORT: the following judges have no ' +
          'operator-supplied cal_access_filer_ids — edit the JUDGES array with real ' +
          'PowerSearch-verified filer IDs before re-running:'
      );
      for (const j of unfilled) {
        console.error(`  - ${j.full_name} (${j.court})`);
      }
      console.error(
        '[seed-judicial-smoketest-judges] See file header + 30-RESEARCH.md ' +
          '"Cal-Access Filer ID Lookup Procedure" for the manual lookup steps.'
      );
      process.exit(1);
    }

    // Step 2: INSERT each judge, parameterized, idempotent via ON CONFLICT.
    console.log('[seed-judicial-smoketest-judges] Inserting judges...');
    for (const j of JUDGES) {
      const insertRes = await pool.query<{ id: string }>(
        `INSERT INTO judicial.judges (full_name, court, external_ids)
         VALUES ($1, $2, $3::jsonb)
         ON CONFLICT (full_name, court) DO NOTHING
         RETURNING id`,
        [j.full_name, j.court, JSON.stringify({ cal_access_filer_ids: j.cal_access_filer_ids })]
      );

      if (insertRes.rows.length > 0) {
        console.log(
          `  [INSERT] ${j.full_name} (${j.court}) -> id=${insertRes.rows[0].id}`
        );
      } else {
        console.log(`  [SKIP] ${j.full_name} (${j.court}) already exists (ON CONFLICT DO NOTHING)`);
      }
    }

    // Step 3: Log all judicial.judges rows to confirm final state.
    console.log('\n[seed-judicial-smoketest-judges] All judicial.judges rows:');
    const allRes = await pool.query<{
      id: string;
      full_name: string;
      court: string;
      external_ids: Record<string, unknown>;
    }>(`SELECT id, full_name, court, external_ids FROM judicial.judges ORDER BY full_name`);

    for (const row of allRes.rows) {
      console.log(
        `  id=${row.id} | ${row.full_name} | ${row.court} | external_ids=${JSON.stringify(row.external_ids)}`
      );
    }
    console.log(`  Total: ${allRes.rows.length} judge row(s)`);

    console.log('\n[seed-judicial-smoketest-judges] Completed.');
    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[seed-judicial-smoketest-judges] Fatal error:', err);
  process.exit(1);
});
