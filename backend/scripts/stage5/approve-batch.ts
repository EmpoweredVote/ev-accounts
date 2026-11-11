/**
 * approve-batch — approve the pending review rows of the named batches (STAGE5 step 7.15).
 *
 *   npx tsx --env-file=.env scripts/stage5/approve-batch.ts <editor uuid> <batch,...> [--skip "Full Name"]...
 *     [--unverifiable-blank "Full Name"]...
 *
 * 🛑 Needs the runner's own "approve", separate from the write's yes. Skip every own-words seat while the
 * topic's blind check has not passed (passed so far: voting-rights, 2026-10-31; gun-policy, 2026-11-04; RULINGS.md "Own-words seats"). Each row goes through resolveResearchReview, so a row with no verified
 * source fails here exactly as it would in the admin queue; it is reported, not forced.
 *
 * --unverifiable-blank names a queued blank whose old sources cannot be verified (OnTheIssues or Wikipedia only, a
 * page that no longer loads, a page with no passage the verifier can tie to the person): it is approved with no
 * source, and the review row's notes record each cited page's verdict (resolveResearchReview,
 * unverifiableBlankNote; ruling 2026-10-31). It replaces writing such a blank by hand. A chair, or a blank queued
 * for any reason but below-threshold, still fails.
 *
 * --hand-checked names a queued row whose one cited page the runner opened and confirmed by hand, when the verifier
 * cannot tie the passage to the person (the name is too far from it on the page). That page is passed as a
 * human-verified source, the same path the admin review page uses, and is stored with the snippet
 * "[Human verified during review]". A row citing no page or more than one is refused (handCheckedUrl). Use it only
 * on the runner's own statement that they checked that page (ruling 2026-11-11, Joe White, sc-01).
 */
import { pool } from '../../src/lib/db.js';
import { resolveResearchReview } from '../../src/lib/researchEvidenceService.js';
import { handCheckedUrl, unverifiableNote } from './lib.js';

const [editor, batches] = process.argv.slice(2);
if (!editor || !batches || editor.startsWith('--')) {
  console.error('usage: approve-batch.ts <editor uuid> <batch,...> [--skip "Full Name"]... [--unverifiable-blank "Full Name"]... [--hand-checked "Full Name"]...');
  process.exit(2);
}
const listed = (flag: string) => process.argv.flatMap((a, i) => (a === flag ? [process.argv[i + 1]] : []));
const skip = listed('--skip');
const unverifiable = listed('--unverifiable-blank');
const handChecked = listed('--hand-checked');
const rows = (await pool.query(
  "SELECT id, full_name_raw, batch_id, evidence FROM inform.stance_research_review WHERE status = 'pending' AND batch_id = ANY($1) ORDER BY batch_id, full_name_raw",
  [batches.split(',')])).rows;
const missing = [...unverifiable, ...handChecked].filter((n) => !rows.some((r) => r.full_name_raw === n));
if (missing.length) console.log('NOT PENDING in these batches (--unverifiable-blank / --hand-checked):', missing.join('; '));
let ok = 0, bad = 0;
for (const r of rows) {
  if (skip.includes(r.full_name_raw)) { console.log('SKIP', r.full_name_raw); continue; }
  const note = unverifiable.includes(r.full_name_raw) ? unverifiableNote(r.evidence) : undefined;
  try {
    const hand = handChecked.includes(r.full_name_raw) ? [handCheckedUrl(r.evidence)] : [];
    await resolveResearchReview(r.id, editor, hand, undefined, undefined, undefined, { unverifiableBlankNote: note });
    ok++; console.log(note ? 'DONE (no verified source)' : hand.length ? `DONE (hand-checked ${hand[0]})` : 'DONE', r.batch_id, r.full_name_raw);
  }
  catch (e: any) { bad++; console.log('FAIL', r.batch_id, r.full_name_raw, e.code, e.message); }
}
console.log(`approved ${ok}, failed ${bad}`);
await pool.end();
