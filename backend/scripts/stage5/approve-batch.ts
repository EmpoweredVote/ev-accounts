/**
 * approve-batch — approve the pending review rows of the named batches (STAGE5 step 7.15).
 *
 *   npx tsx --env-file=.env scripts/stage5/approve-batch.ts <editor uuid> <batch,...> [--skip "Full Name"]...
 *
 * 🛑 Needs the runner's own "approve", separate from the write's yes. Skip every own-words seat while the
 * topic's blind check has not passed (passed so far: voting-rights, 2026-10-31; RULINGS.md "Own-words seats"). Each row goes through resolveResearchReview, so a row with no verified
 * source fails here exactly as it would in the admin queue; it is reported, not forced.
 */
import { pool } from '../../src/lib/db.js';
import { resolveResearchReview } from '../../src/lib/researchEvidenceService.js';

const [editor, batches] = process.argv.slice(2);
if (!editor || !batches || editor.startsWith('--')) {
  console.error('usage: approve-batch.ts <editor uuid> <batch,...> [--skip "Full Name"]...');
  process.exit(2);
}
const skip = process.argv.flatMap((a, i) => (a === '--skip' ? [process.argv[i + 1]] : []));
const rows = (await pool.query(
  "SELECT id, full_name_raw, batch_id FROM inform.stance_research_review WHERE status = 'pending' AND batch_id = ANY($1) ORDER BY batch_id, full_name_raw",
  [batches.split(',')])).rows;
let ok = 0, bad = 0;
for (const r of rows) {
  if (skip.includes(r.full_name_raw)) { console.log('SKIP', r.full_name_raw); continue; }
  try { await resolveResearchReview(r.id, editor); ok++; console.log('DONE', r.batch_id, r.full_name_raw); }
  catch (e: any) { bad++; console.log('FAIL', r.batch_id, r.full_name_raw, e.code, e.message); }
}
console.log(`approved ${ok}, failed ${bad}`);
await pool.end();
