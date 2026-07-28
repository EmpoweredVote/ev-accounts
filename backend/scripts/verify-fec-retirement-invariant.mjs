/**
 * Verify the FEC per-line supersession invariant across a set of sources.
 *
 * PASS CONDITION: zero last-copy deletions. Every line the retirement would
 * remove must still have a surviving row in the SAME report
 * (committee_id, report_year, report_type) at the survivor file_number.
 *
 * Why: FEC amendments are DELTA filings, not full re-reports. FEC-04b assumed
 * otherwise and deleted every row below the max file_number per REPORT, which
 * destroyed lines the amendment never restated. The per-LINE rule only retires
 * a line when the SAME line reappears at a higher file_number, so an orphan
 * should be structurally impossible — this proves it rather than asserting it.
 *
 * READ-ONLY. Run before --apply (is the plan safe?) and after (did anything
 * get orphaned?).
 *
 *   node scripts/verify-fec-retirement-invariant.mjs data/_retire-affected-ids.json
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import pg from 'pg';

// Deliberately a self-contained Pool rather than importing ../src/lib/db.js:
// that module is TypeScript and only resolves under tsx, so a plain `node` run
// dies with ERR_MODULE_NOT_FOUND before the first query. A verification script
// should have as few moving parts as the thing it verifies.
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

const ids = JSON.parse(readFileSync(process.argv[2], 'utf8'));
console.log(`verifying ${ids.length} source(s)\n`);

// Mirrors retire-fec-superseded-local.ts's window exactly — if that partition
// changes, this must change with it or the check stops proving anything.
const SQL = `
WITH slice AS (
  SELECT id,
         raw_record->>'committee_id'          AS cmte,
         (raw_record->>'report_year')::int    AS ry,
         raw_record->>'report_type'           AS rt,
         donor_name_normalized                AS donor,
         amount, contribution_date,
         (raw_record->>'file_number')::bigint AS fn
    FROM transparent_motivations.contributions
   WHERE politician_source_id = $1 AND data_source = 'fec' AND raw_record ? 'file_number'
), ranked AS (
  SELECT *, max(fn) OVER (
           PARTITION BY cmte, ry, rt, donor, amount, contribution_date
         ) AS survivor_fn
    FROM slice
), victims AS (SELECT * FROM ranked WHERE fn < survivor_fn),
   survivors AS (SELECT DISTINCT cmte, ry, rt, donor, amount, contribution_date, fn
                   FROM ranked WHERE fn = survivor_fn)
SELECT
  (SELECT count(*) FROM victims)::int AS victims,
  (SELECT count(*) FROM (
     SELECT DISTINCT v.cmte, v.ry, v.rt, v.donor, v.amount, v.contribution_date, v.survivor_fn
       FROM victims v
       LEFT JOIN survivors s
         ON  s.cmte = v.cmte AND s.ry = v.ry AND s.rt = v.rt
         AND s.donor IS NOT DISTINCT FROM v.donor
         AND s.amount = v.amount
         AND s.contribution_date IS NOT DISTINCT FROM v.contribution_date
         AND s.fn = v.survivor_fn
      WHERE s.fn IS NULL) o)::int AS last_copy,
  (SELECT count(*) FROM victims WHERE fn = survivor_fn)::int AS self_supersession`;

let victims = 0, lastCopy = 0, selfSup = 0, failed = 0, done = 0;
for (const id of ids) {
  const c = await pool.connect();
  try {
    await c.query(`SET statement_timeout = '300s'`);
    const { rows: [r] } = await c.query(SQL, [id]);
    victims += r.victims; lastCopy += r.last_copy; selfSup += r.self_supersession;
    if (r.last_copy > 0 || r.self_supersession > 0) {
      console.log(`  !! ${id}: last_copy=${r.last_copy} self_supersession=${r.self_supersession}`);
    }
  } catch (e) {
    // A skipped source is NOT a pass — count it so partial coverage can't read as clean.
    failed++;
    console.log(`  ! ${id}: SKIPPED (${e.message})`);
  } finally { c.release(); }
  if (++done % 15 === 0) console.log(`  ...${done}/${ids.length}`);
}

console.log(`\nvictims checked      : ${victims.toLocaleString()}`);
console.log(`self-supersession    : ${selfSup}   (must be 0)`);
console.log(`LAST-COPY DELETIONS  : ${lastCopy}   (must be 0 — the pass condition)`);
console.log(`sources not verified : ${failed}   (must be 0 for full coverage)`);
console.log(
  lastCopy === 0 && selfSup === 0 && failed === 0
    ? '\nPASS — every retired line keeps a surviving row at the survivor file_number.'
    : '\nFAIL — do NOT run --apply.'
);
await pool.end();
