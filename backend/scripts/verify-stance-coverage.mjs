// Reusable per-batch stance-coverage check for Phase 142/143 (state-exec stance waves).
// Usage (DATABASE_URL must be in env — prefix with `set -a && source .env && set +a`):
//   node backend/scripts/verify-stance-coverage.mjs <expectedCount> <id1> <id2> ...
// Asserts:
//   (1) coverage: count(DISTINCT external_id) with >=1 inform.politician_answers row == expectedCount
//   (2) zero unsourced: no answer row for these ids lacks a paired inform.politician_context
//       row whose sources[1] starts with 'http'
// Exits non-zero (and prints FAIL) if either assertion is violated; prints PASS otherwise.
import { Pool } from 'pg';

const argv = process.argv.slice(2);
const expected = Number(argv[0]);
const ids = argv.slice(1).map(Number);
if (!Number.isInteger(expected) || ids.length === 0 || ids.some((n) => !Number.isInteger(n))) {
  console.error('usage: node verify-stance-coverage.mjs <expectedCount> <id1> <id2> ...');
  process.exit(2);
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
try {
  const cov = await pool.query(
    `SELECT count(DISTINCT p.external_id)::int AS cov
       FROM inform.politician_answers pa
       JOIN essentials.politicians p ON p.id = pa.politician_id
      WHERE p.external_id = ANY($1::int[])`,
    [ids]
  );
  const un = await pool.query(
    `SELECT count(*)::int AS un
       FROM inform.politician_answers pa
       JOIN essentials.politicians p ON p.id = pa.politician_id
       LEFT JOIN inform.politician_context c
         ON c.politician_id = pa.politician_id AND c.topic_id = pa.topic_id
      WHERE p.external_id = ANY($1::int[])
        AND (c.politician_id IS NULL OR c.sources[1] IS NULL OR c.sources[1] NOT LIKE 'http%')`,
    [ids]
  );
  const covered = cov.rows[0].cov;
  const unsourced = un.rows[0].un;
  if (covered < expected) {
    console.error(`FAIL coverage ${covered}/${expected}`);
    process.exit(1);
  }
  if (unsourced > 0) {
    console.error(`FAIL unsourced rows: ${unsourced}`);
    process.exit(1);
  }
  console.log(`PASS covered=${covered}/${expected} unsourced=${unsourced}`);
} finally {
  await pool.end();
}
