/**
 * audit-la-socrata-gaps.ts — Find LA City politicians who appear in active races
 * but have no confirmed la_socrata source, then look them up in the Socrata API
 * and optionally seed the missing sources + trigger ingest.
 *
 * Problem this solves: candidates added to race_candidates via cityclerk.lacity.org
 * may only get a cal_access source seeded initially. Without a la_socrata source
 * they are silently skipped by runAdapterForAll('la_socrata'). This script surfaces
 * and fixes that gap.
 *
 * Usage:
 *   npx tsx scripts/audit-la-socrata-gaps.ts             # audit only, no writes
 *   npx tsx scripts/audit-la-socrata-gaps.ts --fix       # seed missing sources
 *   npx tsx scripts/audit-la-socrata-gaps.ts --fix --ingest  # seed + run ingest
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const doFix = process.argv.includes('--fix');
const doIngest = process.argv.includes('--ingest');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

interface SocrataCommittee {
  cmt_id: string;
  cmt_nm: string;
  cand_name: string;
  seat_desc: string;
}

async function fetchSocrataCommittees(): Promise<SocrataCommittee[]> {
  const url =
    'https://data.lacity.org/resource/m6g2-gc6c.json' +
    '?$select=cmt_id,cmt_nm,cand_name,seat_desc' +
    '&$where=cmt_type=%27C%27' +
    '&$group=cmt_id,cmt_nm,cand_name,seat_desc' +
    '&$limit=10000';

  const headers: Record<string, string> = { Accept: 'application/json' };
  if (process.env.SOCRATA_APP_TOKEN) {
    headers['X-App-Token'] = process.env.SOCRATA_APP_TOKEN;
  }

  const res = await fetch(url, { headers });
  if (!res.ok) throw new Error(`Socrata API error ${res.status}: ${await res.text()}`);
  return res.json() as Promise<SocrataCommittee[]>;
}

function normalize(s: string): string {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
}

async function main(): Promise<void> {
  console.log(`[audit-la-socrata-gaps] Mode: ${doFix ? (doIngest ? 'FIX + INGEST' : 'FIX') : 'AUDIT ONLY'}\n`);

  // Step 1: Find politicians in active LA races with no la_socrata source
  const gapResult = await pool.query<{
    politician_id: string;
    full_name: string;
    position_name: string;
    election_date: string;
    has_cal_access: boolean;
  }>(`
    SELECT DISTINCT
      p.id AS politician_id,
      p.full_name,
      r.position_name,
      e.election_date::text,
      EXISTS(
        SELECT 1 FROM transparent_motivations.politician_sources ps2
        WHERE ps2.essentials_politician_id = p.id
          AND ps2.source_system = 'cal_access'
          AND ps2.research_status = 'confirmed'
      ) AS has_cal_access
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.politicians p ON p.id = rc.politician_id
    WHERE e.state = 'CA'
      AND e.election_date >= CURRENT_DATE
      AND r.position_name ILIKE '%Los Angeles%'
      AND rc.candidate_status = 'active'
      AND NOT EXISTS(
        SELECT 1 FROM transparent_motivations.politician_sources ps
        WHERE ps.essentials_politician_id = p.id
          AND ps.source_system = 'la_socrata'
          AND ps.research_status = 'confirmed'
      )
    ORDER BY p.full_name
  `);

  if (gapResult.rows.length === 0) {
    console.log('No gaps found — all active LA City candidates have confirmed la_socrata sources.');
    await pool.end();
    return;
  }

  console.log(`Found ${gapResult.rows.length} LA City candidate(s) missing la_socrata source:\n`);
  for (const row of gapResult.rows) {
    const calFlag = row.has_cal_access ? ' [has cal_access]' : ' [no cal_access either]';
    console.log(`  ${row.full_name.padEnd(28)} ${row.position_name}${calFlag}`);
  }

  if (!doFix) {
    console.log('\nRun with --fix to seed missing sources, --fix --ingest to also run ingest.');
    await pool.end();
    return;
  }

  // Step 2: Fetch Socrata committee list
  console.log('\nFetching Socrata committee list...');
  const committees = await fetchSocrataCommittees();
  console.log(`  Loaded ${committees.length} committees.\n`);

  // Step 3: Match each gap politician to a Socrata committee
  let seeded = 0;
  let noMatch = 0;

  for (const row of gapResult.rows) {
    const normalizedName = normalize(row.full_name);
    // Split to get last name for matching (Socrata cand_name is "Last, First")
    const parts = row.full_name.trim().split(/\s+/);
    const lastName = normalize(parts[parts.length - 1]);

    // Find committees where cand_name contains the last name
    const matches = committees.filter(c => {
      const candNorm = normalize(c.cand_name ?? '');
      const cmtNorm = normalize(c.cmt_nm ?? '');
      return candNorm.includes(lastName) || cmtNorm.includes(lastName);
    });

    if (matches.length === 0) {
      console.log(`  [NO MATCH]  ${row.full_name}`);
      noMatch++;
      continue;
    }

    if (matches.length > 1) {
      // Try to narrow by first name
      const firstName = normalize(parts[0]);
      const narrowed = matches.filter(c =>
        normalize(c.cmt_nm ?? '').includes(firstName) ||
        normalize(c.cand_name ?? '').includes(firstName)
      );
      if (narrowed.length === 1) {
        matches.splice(0, matches.length, ...narrowed);
      } else if (narrowed.length > 1) {
        console.log(`  [AMBIGUOUS] ${row.full_name} — ${narrowed.length} matches, manual review needed:`);
        for (const m of narrowed) console.log(`    cmt_id=${m.cmt_id} "${m.cmt_nm}"`);
        noMatch++;
        continue;
      }
    }

    const match = matches[0];
    console.log(`  [MATCH]     ${row.full_name} → cmt_id=${match.cmt_id} "${match.cmt_nm}"`);

    await pool.query(
      `INSERT INTO transparent_motivations.politician_sources
         (essentials_politician_id, source_system, external_id, research_status, notes)
       VALUES ($1, 'la_socrata', $2, 'confirmed', $3)
       ON CONFLICT DO NOTHING`,
      [row.politician_id, match.cmt_id, match.cmt_nm]
    );
    seeded++;
  }

  console.log(`\nSeeded: ${seeded} | No match / ambiguous: ${noMatch}`);

  if (doIngest && seeded > 0) {
    console.log('\nTriggering runAdapterForAll("la_socrata")...');
    await runAdapterForAll('la_socrata');
    console.log('Ingest complete.');
  }

  await pool.end();
}

main().catch(async err => {
  console.error('[audit-la-socrata-gaps] Fatal:', err);
  await pool.end();
  process.exit(1);
});
