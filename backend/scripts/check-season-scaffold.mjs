#!/usr/bin/env node
/**
 * check-season-scaffold.mjs
 *
 * Reports the state of the compass two-season INTERLOCK, and fails only on a
 * state that cannot be correct at any point in the rollout.
 *
 *   cd backend && npm run check:season-scaffold
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 WHY THIS SCRIPT EXISTS AT ALL — A DETECTOR THAT COULD NOT SEE ITS SUBJECT.
 *
 * `CC_0002` deliberately left two scaffolding UNIQUE INDEXES up
 * (`politician_answers_legacy_pair_scaffold`, `politician_context_legacy_pair_scaffold`).
 * While they are up the database physically cannot hold a second season. That is
 * an interlock, not an oversight — see docs/adr/0005-compass-question-seasons.md
 * section 1.6, step 3 of which is "drop the scaffolding indexes".
 *
 * On 2026-08-28 that fact was checked ad hoc with:
 *
 *     select count(*) from information_schema.tables
 *      where table_name like '%legacy_pair_scaffold%';       -- returns 0
 *
 * It returns 0 because `information_schema.tables` lists TABLES AND VIEWS. An
 * index is neither. The scaffolding was fully present and the query said absent,
 * with no error and no warning — and "absent" is the reading that invites someone
 * to proceed to step 4 and open Season 2.
 *
 * That is the general shape: a query that cannot see its subject returns zero,
 * and zero reads as "not there". So this script looks in `pg_class` / `pg_index`,
 * where indexes actually live, and it prints what it found rather than reducing
 * the answer to a bare count.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * PASS / FAIL. Both "up" and "gone" are correct at different points in the
 * rollout, so neither can be the failure condition. What cannot be correct:
 *
 *   EXACTLY ONE index present   -> half an interlock. One table would accept a
 *                                  second season while the other refuses, so a
 *                                  write would half-land. FAIL.
 *   Both present, >1 season     -> the interlock claims this is impossible and
 *                                  reality disagrees, so the indexes are not
 *                                  doing what the ADR says. FAIL.
 *
 * Zero OPEN seasons is reported loudly but does not fail: it is a real hazard
 * (every write refuses NO_OPEN_SEASON, which is how `CA_0019` broke writing), but
 * it is also the transient state during the drop-close-open move. `check:season-floor`
 * is the gate that watches corpus loss; this one watches the interlock.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const SCAFFOLD_INDEXES = [
  'politician_answers_legacy_pair_scaffold',
  'politician_context_legacy_pair_scaffold',
];

if (!process.env.DATABASE_URL) {
  console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
  process.exit(0);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  // 🔴 pg_class, NOT information_schema.tables. An index is not a table.
  const idx = await pool.query(
    `SELECT c.relname          AS name,
            n.nspname          AS schema,
            t.relname          AS on_table,
            i.indisunique      AS is_unique,
            i.indisvalid       AS is_valid,
            pg_get_indexdef(c.oid) AS definition
       FROM pg_class c
       JOIN pg_index i ON i.indexrelid = c.oid
       JOIN pg_class t ON t.oid = i.indrelid
       JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind = 'i' AND c.relname = ANY($1::text[])
      ORDER BY c.relname`,
    [SCAFFOLD_INDEXES],
  );

  const seasons = await pool.query(
    `SELECT count(*)::int AS total,
            count(*) FILTER (WHERE status = 'open')::int AS open,
            coalesce(string_agg(name || ' (' || status || ')', ', ' ORDER BY number), '-') AS listing
       FROM inform.seasons`,
  );

  const found = idx.rows.map((r) => r.name);
  const missing = SCAFFOLD_INDEXES.filter((n) => !found.includes(n));
  const s = seasons.rows[0];

  console.log('compass season interlock');
  console.log(`  scaffolding indexes present: ${found.length} of ${SCAFFOLD_INDEXES.length}`);
  for (const r of idx.rows) {
    const flags = [r.is_unique ? 'unique' : 'NOT UNIQUE', r.is_valid ? 'valid' : 'INVALID'].join(', ');
    console.log(`    UP      ${r.schema}.${r.name} on ${r.on_table}  (${flags})`);
  }
  for (const n of missing) {
    console.log(`    DROPPED ${n}`);
  }
  console.log(`  seasons: ${s.total} total, ${s.open} open — ${s.listing}`);

  const failures = [];

  if (found.length === 1) {
    failures.push(
      `HALF AN INTERLOCK: ${found[0]} is up but ${missing[0]} is not. One table would accept a ` +
        `second season while the other refuses it, so a write would half-land. Either drop both ` +
        `(ADR 0005 step 3) or restore the missing one.`,
    );
  }

  if (found.length === SCAFFOLD_INDEXES.length && s.total > 1) {
    failures.push(
      `CONTRADICTION: both scaffolding indexes are up, which ADR 0005 says makes a second season ` +
        `physically impossible — but inform.seasons holds ${s.total}. The interlock is not doing ` +
        `what it is documented to do. Do not trust it as a guard until this is explained.`,
    );
  }

  const anyInvalid = idx.rows.filter((r) => !r.is_valid || !r.is_unique);
  if (anyInvalid.length) {
    failures.push(
      `NOT ENFORCING: ${anyInvalid.map((r) => r.name).join(', ')} exists but is not a valid unique ` +
        `index, so it constrains nothing. An index that is present and inert is worse than an absent ` +
        `one, because its presence reads as protection.`,
    );
  }

  if (s.open === 0) {
    console.log('');
    console.log(
      '  ⚠ NO OPEN SEASON. Every write refuses NO_OPEN_SEASON while this holds — this is how ' +
        'CA_0019 broke writing. Correct only as a transient during the drop-close-open move. ' +
        'Not failing, because the rollout phase decides whether it is expected.',
    );
  }

  console.log('');
  if (failures.length) {
    for (const f of failures) console.error(`FAIL: ${f}`);
    await pool.end();
    process.exit(1);
  }

  const state =
    found.length === SCAFFOLD_INDEXES.length
      ? 'ENGAGED — prod cannot hold a second season (ADR 0005 step 3 not done)'
      : 'RELEASED — the scaffolding is gone, a second season is physically possible';
  console.log(`OK — interlock ${state}.`);
  await pool.end();
}

main().catch(async (err) => {
  console.error(err);
  await pool.end().catch(() => {});
  process.exit(1);
});
