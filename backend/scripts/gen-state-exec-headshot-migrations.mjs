#!/usr/bin/env node
// gen-state-exec-headshot-migrations.mjs — Phase 141 Wave 2 audit-migration generator.
// Reads _state-exec-headshot-results.json (written by seed-state-exec-headshots.py) and emits one
// AUDIT-ONLY migration per batch (A-E). Actual politician_images writes + Storage uploads already
// happened live during the .py run; these migrations record them idempotently (WHERE NOT EXISTS),
// mirroring migration 271. Honest-skips are documented as comments (no INSERT).
// Usage: node backend/scripts/gen-state-exec-headshot-migrations.mjs <baseMigNum>
import { readFileSync, writeFileSync } from 'node:fs';

const BASE = parseInt(process.argv[2] || '985', 10); // A=BASE, B=BASE+1, ... E=BASE+4
const BATCH_STATES = {
  A: new Set(['AK','AL','FL','IL','MS','NC','NY','SD']),
  B: new Set(['AR','GA','HI','IA','MO','ND','OK','VT']),
  C: new Set(['CO','KS','MI','NE','NJ','OH','PA','WA']),
  D: new Set(['CT','KY','MN','NH','NV','RI','TN','WI','WV']),
  E: new Set(['AZ','DE','ID','LA','MT','NM','SC','WY']),
};
const PLAN = { A:'141-08', B:'141-09', C:'141-10', D:'141-11', E:'141-12' };
const results = JSON.parse(readFileSync('backend/scripts/_state-exec-headshot-results.json', 'utf8'));
// IN Morales/Elliott (642977/688298) belong with batch A (plan 141-08) per the plan.
const batchOf = (r) => {
  if (r.external_id === 642977 || r.external_id === 688298) return 'A';
  for (const [b, sts] of Object.entries(BATCH_STATES)) if (sts.has(r.state)) return b;
  return null;
};
const sq = (s) => String(s).replace(/'/g, "''");
let migNum = BASE;
for (const b of ['A','B','C','D','E']) {
  const rows = results.filter(r => batchOf(r) === b);
  const ok = rows.filter(r => r.success);
  const skip = rows.filter(r => !r.success);
  const inserts = ok.map(r =>
    `-- ${sq(r.full_name)} (${r.state}, ext ${r.external_id}) — ${sq(r.license)}\n` +
    `--   source: ${sq(r.source || '')}\n` +
    `INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)\n` +
    `SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=${r.external_id}),\n` +
    `       '${sq(r.cdn)}', 'default', '${sq(r.license)}'\n` +
    `WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images\n` +
    `  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=${r.external_id}));`
  ).join('\n\n');
  const skipComments = skip.length
    ? '\n-- HONEST-SKIPS (no free-licensed portrait found; McDowell precedent):\n' +
      skip.map(r => `--   ext ${r.external_id} ${sq(r.full_name)} (${r.state}): ${sq(r.skip_reason)}`).join('\n')
    : '\n-- No honest-skips in this batch.';
  const sql = `-- ${migNum}_state_exec_headshots_batch_${b.toLowerCase()}.sql
-- Phase 141 (v2.18 State Leaders), plan ${PLAN[b]}. AUDIT-ONLY (mirrors migration 271).
-- Actual headshot uploads to the politician_photos bucket + politician_images INSERTs happened LIVE via
-- backend/scripts/seed-state-exec-headshots.py (Wikipedia pageimages -> PIL crop 4:5 -> 600x750 LANCZOS q90).
-- These INSERTs reproduce that record idempotently (column \`url\`, WHERE NOT EXISTS). Re-apply = no-op.
-- Batch ${b}: ${ok.length} headshots recorded${skip.length ? `, ${skip.length} honest-skip` : ''}.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/${migNum}_state_exec_headshots_batch_${b.toLowerCase()}.sql

BEGIN;

${inserts || '-- (no successful headshots in this batch)'}
${skipComments}

COMMIT;
`;
  const path = `backend/migrations/${migNum}_state_exec_headshots_batch_${b.toLowerCase()}.sql`;
  writeFileSync(path, sql);
  console.log(`wrote ${path}: ${ok.length} inserts, ${skip.length} skips`);
  migNum++;
}
console.log('done');
