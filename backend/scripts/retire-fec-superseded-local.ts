/**
 * retire-fec-superseded-local.ts — retire the pre-fix FEC amendment double-count using ONLY
 * local SQL, once `file_number` has been backfilled (scripts/backfill-fec-file-numbers.ts).
 *
 * This replaces retire-fec-amendment-dupes.mjs, which had to resolve every duplicate group
 * against the live API one at a time — 5 s/request, and 31% of groups came back UNRESOLVABLE
 * because the donor-name query no longer returned two matches. With file_number present on the
 * rows themselves, supersession is decidable locally: no API calls, no rate-limit contention with
 * the 06:00 UTC ingest, and no unresolvable bucket.
 *
 * THE RULE — per contribution LINE, never per whole report
 * -------------------------------------------------------
 * A row is retired only when the SAME line (donor, amount, date) also exists in the SAME report
 * (committee_id, report_year, report_type) under a HIGHER file_number. That is exactly what the
 * double-count is: one line carried by two filings of one report.
 *
 * It deliberately does NOT delete "everything below the report's max file_number". That rule
 * assumed an amendment re-reports the whole report; measured against live data on 2026-07-25, of
 * 24 superseded filings sampled ZERO were supersets of their successor — many FEC amendments are
 * DELTA filings. Committee C00574889 report Q1/2016, date 2016-03-11: 114 lines in original file
 * 1066886, only 2 in amendment 1081569. The whole-report rule would delete all 114 and keep 2.
 *
 * Cases this gets right:
 *   - C00256925 12P/2020 — Chamblee's $250 2020-05-07 in BOTH 1409022 and 1484476 → the 1409022
 *     copy is retired. The real double-count is fixed.
 *   - C00574889 Q1/2016 — PARKER's $50 exists only in 1066886 → nothing retired.
 *   - FEC's legitimate repeated identical lines in ONE filing (five $1.00 recurring donations on
 *     one day) share that filing's file_number, so none is the "higher" version of another.
 *   - The same contribution legitimately in DIFFERENT reports (C00575209's $2,800 in Q1/2020 AND
 *     Q3/2020) is never touched — matching is scoped within one (report_year, report_type).
 *
 * Mirrors the predicate in fecAdapter.retireSupersededFilings deliberately: one rule, two call
 * sites (forward path + backlog). Change both together.
 *
 *   tsx scripts/retire-fec-superseded-local.ts [--sources N] [--apply]
 *
 * Dry run by default. Snapshots every deleted row to data/fec-superseded-local-snapshot.json.
 */

import 'dotenv/config';
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { pool } from '../src/lib/db.js';

const sIdx = process.argv.indexOf('--sources');
const MAX = sIdx > -1 ? parseInt(process.argv[sIdx + 1]!, 10) : 1000;
const oneIdx = process.argv.indexOf('--source');
const ONLY = oneIdx > -1 ? process.argv[oneIdx + 1]! : null;
const APPLY = process.argv.includes('--apply');

const SNAP = 'data/fec-superseded-local-snapshot.json';
const snapshot: { retired_at: string | null; rows: unknown[] } = existsSync(SNAP)
  ? JSON.parse(readFileSync(SNAP, 'utf8'))
  : { retired_at: null, rows: [] };

// Per-source so every scan/delete rides idx_contrib_src_cycle. An unscoped JSONB self-join over
// 26.7M rows is the shape of the 2026-07-22 P1 pool-saturation incident.
// --from <detector.json>: sweep only the sources the detector flagged. Sources with no duplicate
// signature have nothing for this rule to find, and scanning them means a full pass over their
// rows anyway (there is no index for `raw_record ? 'file_number'`) — so this is the same coverage
// for roughly a quarter of the work.
const fromIdx = process.argv.indexOf('--from');
const FROM: string[] | null = fromIdx > -1
  ? (JSON.parse(readFileSync(process.argv[fromIdx + 1]!, 'utf8')) as
      { findings: { politician_source_id: string }[] }).findings.map((f) => f.politician_source_id)
  : null;

const { rows: sources } = ONLY
  ? { rows: [{ id: ONLY }] }
  : FROM
  ? { rows: FROM.slice(0, MAX).map((id) => ({ id })) }
  : await pool.query<{ id: string }>(
      `SELECT id FROM transparent_motivations.politician_sources
        WHERE source_system IN ('fec','fec_house','fec_senate')
        ORDER BY updated_at DESC NULLS LAST LIMIT $1`, [MAX]
    );
console.log(`scanning ${sources.length} politician_source(s)`);
console.log(APPLY ? 'MODE: APPLY\n' : 'MODE: DRY RUN (pass --apply to delete)\n');

interface Victim {
  id: string; source_transaction_id: string; amount: string;
  contribution_date: string | null; donor_name_normalized: string | null;
  cmte: string; ry: string; rt: string; fn: string;
  survivor_fn: string;
}

let totalVictims = 0, totalDeleted = 0, affectedSources = 0;

for (const s of sources) {
  // The largest sources exceed the 8s statement_timeout the `postgres` role carries (2026-07-22
  // P1 remediation), and this self-join has no index to ride (there is no GIN index on
  // raw_record). Take a DEDICATED client: `pool.query('SET ...')` lands on whatever pooled
  // connection it is handed, so the next query can get a different one and the raised timeout
  // silently does not apply — which is exactly how this failed the first time.
  const client = await pool.connect();
  let victims: Victim[];
  try {
    await client.query(`SET statement_timeout = '300s'`);
    // Per-line supersession via a window MAX. Deliberately NOT a self-join: that plans as a
    // nested loop with the JSONB extraction in the join filter, so cost is quadratic in the
    // source's row count and it does not complete (>10 min on a single committee, measured).
    // Mirrors fecAdapter.retireSupersededFilings — change both together.
    ({ rows: victims } = await client.query<Victim>(
    `WITH slice AS (
       SELECT id, source_transaction_id, amount, contribution_date, donor_name_normalized,
              raw_record->>'committee_id'        AS cmte,
              (raw_record->>'report_year')::int  AS ry,
              raw_record->>'report_type'         AS rt,
              (raw_record->>'file_number')::bigint AS fn
         FROM transparent_motivations.contributions
        WHERE politician_source_id = $1
          AND data_source = 'fec'
          AND raw_record ? 'file_number'
     ), ranked AS (
       SELECT *,
              max(fn) OVER (
                PARTITION BY cmte, ry, rt, donor_name_normalized, amount, contribution_date
              ) AS survivor_fn
         FROM slice
     )
     SELECT id, source_transaction_id, amount::text AS amount,
            contribution_date::text AS contribution_date, donor_name_normalized,
            cmte, ry::text AS ry, rt, fn::text AS fn, survivor_fn::text AS survivor_fn
       FROM ranked
      WHERE fn < survivor_fn`,
      [s.id]
    ));
  } catch (e) {
    // One slow source must never abort the sweep; report it rather than shrink coverage silently.
    console.log(`  ! ${s.id}: SKIPPED (${(e as Error).message})`);
    continue;
  } finally {
    client.release();
  }

  if (victims.length === 0) continue;
  affectedSources++;
  totalVictims += victims.length;
  const money = victims.reduce((a, v) => a + Number(v.amount), 0);
  console.log(`  ${s.id}: ${victims.length} superseded row(s), $${money.toLocaleString()}`);
  for (const v of victims.slice(0, 3)) {
    console.log(`      ${v.cmte} ${v.ry}/${v.rt} file ${v.fn} -> ${v.survivor_fn}`
              + `  ${v.donor_name_normalized} $${v.amount} ${v.contribution_date}`);
  }

  if (!APPLY) continue;

  // Snapshot BEFORE deleting so every removal is reversible, as with the stance retirements.
  snapshot.rows.push(...victims.map((v) => ({ ...v, politician_source_id: s.id })));
  const res = await pool.query(
    `DELETE FROM transparent_motivations.contributions
      WHERE politician_source_id = $1 AND data_source = 'fec' AND id = ANY($2::uuid[])`,
    [s.id, victims.map((v) => v.id)]
  );
  totalDeleted += res.rowCount ?? 0;
  snapshot.retired_at = new Date().toISOString();
  writeFileSync(SNAP, JSON.stringify(snapshot, null, 2));
}

console.log(`\naffected sources : ${affectedSources}`);
console.log(`superseded rows  : ${totalVictims}`);
console.log(APPLY ? `DELETED          : ${totalDeleted}` : 'DRY RUN — pass --apply to delete');
if (APPLY) console.log(`snapshot -> ${SNAP} (${snapshot.rows.length} row(s) cumulative)`);
await pool.end();
