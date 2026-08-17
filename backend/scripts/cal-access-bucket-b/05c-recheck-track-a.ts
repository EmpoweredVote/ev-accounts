// 05c-recheck-track-a.ts
// Re-runs Track A's ordered rule with the FIXED officeKeywords() and diffs against the decisions
// migration 1790 actually applied. READ-ONLY -- it never rewrites track-a-decisions.json.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 6, step 1)
// Run from backend/:  npx tsx scripts/cal-access-bucket-b/05c-recheck-track-a.ts
//
// ⚠ WHY THIS EXISTS
// Task 6 step 1 says to fix officeKeywords() before reusing the office route. But Track A imported the
// same function and its purges are ALREADY APPLIED -- migration 1790 deleted $12,683,421.80. Widening
// the office route retroactively changes what Track A's rule WOULD have decided. If any of those 18
// purges flips to keep, we deleted money the corrected rule would have spared, and that is a defect to
// surface now rather than discover later. A silent fix would have buried it.
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { namesThem, officeKeywords, conflictingGivenName, OPERATOR_KEEPS } from './03-classify-track-a';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');

async function main() {
  const decisions = JSON.parse(fs.readFileSync(path.join(DIR, 'track-a-decisions.json'), 'utf8'));
  const filers = JSON.parse(fs.readFileSync(path.join(DIR, 'filer-records.json'), 'utf8'));

  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows: officeRows } = await pool.query(
    `SELECT t.politician_id, o.title, c.name AS chamber
       FROM essentials.office_terms t
       JOIN essentials.offices o ON o.id = t.office_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
      WHERE t.politician_id = ANY($1::uuid[])`,
    [decisions.map((r: any) => r.politician_id)]);
  await pool.end();

  const officesByPid: Record<string, { title: string | null; chamber: string | null }[]> = {};
  for (const o of officeRows) (officesByPid[o.politician_id] ??= []).push({ title: o.title, chamber: o.chamber });

  let flips = 0;
  for (const d of decisions) {
    const kws = officeKeywords(officesByPid[d.politician_id] ?? []);
    let now: string;
    if (d.verdict === 'names-them') now = 'keep';
    else if (OPERATOR_KEEPS[d.filer_id]) now = 'keep';
    else {
      const rec = filers[d.filer_id];
      const official = rec?.status === 'ok' ? rec.official_name : '';
      const surnameRe = new RegExp('\\b' + d.last_name.trim().toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b', 'i');
      if (!official) now = 'purge';
      else if (namesThem(official, d.first_name, d.last_name)) now = 'keep';
      else if (!surnameRe.test(official)) now = 'purge';
      else if (conflictingGivenName(official, d.first_name)) now = 'purge';
      else if (kws.find(k => official.toLowerCase().includes(k))) now = 'keep';
      else now = 'purge';
    }
    if (now !== d.decision) {
      flips++;
      console.log(`🔴 FLIP ${d.decision} -> ${now}  $${d.dollars.toFixed(2)}  ${d.politician_name}  <- "${d.official_name}"  [holds: ${kws.join(', ') || 'none'}]`);
    }
  }

  console.log(`\n${decisions.length} Track A decisions rechecked with the fixed officeKeywords(): ${flips} flip(s).`);
  if (flips === 0) {
    console.log('✅ Migration 1790 stands. The widened office route changes no applied decision.');
  } else {
    console.log('🔴 Migration 1790 purged money the corrected rule would keep. Report before proceeding.');
    process.exit(1);
  }
}
main();
