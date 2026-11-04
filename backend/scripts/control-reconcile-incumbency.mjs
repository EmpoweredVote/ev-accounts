/**
 * Positive control for reconcile-incumbency.mjs.
 *
 * 🔴 THE OBVIOUS CONTROL PROVES NOTHING HERE. "Plant drift, run the reconciler, watch it get
 * fixed" passes whether or not the fix survives — it never exercises the writer that used to
 * revert it. `stagingService`'s promotion forced `is_incumbent = true` on every ON CONFLICT
 * update, so a reconciled value was undone by the next promotion and nothing reported it.
 *
 * So this control runs BOTH shapes of that promotion against the planted row:
 *
 *   1. the OLD set-list, with `is_incumbent = true`   → must REVERT the fix (control goes red)
 *   2. the NEW set-list, without it                   → must LEAVE the fix alone
 *
 * Step 1 is the part that makes step 2 mean anything: it is the tamper, and watching it work is
 * what proves the assertion in step 2 can fail at all.
 *
 * Everything runs inside one transaction and is rolled back.
 */
import 'dotenv/config';
import pg from 'pg';
import { computeIncumbencyDrift, applyIncumbencyFixes } from './reconcile-incumbency.mjs';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
let failed = false;
const fail = (m) => { console.error('  ✗ ' + m); failed = true; };
const ok = (m) => console.log('  ✓ ' + m);

const SET_LIST = (withIncumbent) => `
  INSERT INTO essentials.politicians (full_name, is_active, is_incumbent, external_id)
  VALUES ($1, true, true, $2)
  ON CONFLICT (external_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    is_active = true${withIncumbent ? ',\n    is_incumbent = true' : ''}`;

try {
  await client.query('BEGIN');

  const baseline = await computeIncumbencyDrift(client);
  console.log(`baseline drift in production: ${baseline.length} row(s)`);

  // Pick a real current holder who has an external_id, so the promotion's ON CONFLICT fires.
  const { rows: picks } = await client.query(`
    SELECT p.id, p.full_name, p.external_id
      FROM essentials.politicians p
      JOIN essentials.office_current_holder och ON och.politician_id = p.id
     WHERE p.is_active = true AND p.is_incumbent = true AND p.external_id IS NOT NULL
     LIMIT 1`);
  if (!picks.length) throw new Error('no seated politician with an external_id to test on');
  const who = picks[0];
  console.log(`planting drift on: ${who.full_name}`);

  // 1. Plant: a sitting holder marked NOT an incumbent.
  await client.query('UPDATE essentials.politicians SET is_incumbent = false WHERE id = $1', [who.id]);

  const withDrift = await computeIncumbencyDrift(client);
  const found = withDrift.find((d) => d.politicianId === who.id && d.column === 'politicians.is_incumbent');
  if (!found) fail('the reconciler did NOT see the planted drift — it is reading the wrong rows');
  else ok(`drift detected: expected ${found.expected}, found ${found.current}`);
  console.log(`  (examined ${withDrift.length} drift row(s); baseline was ${baseline.length})`);

  // 2. Fix it.
  await applyIncumbencyFixes(client, withDrift.filter((d) => d.politicianId === who.id));
  const afterFix = await client.query('SELECT is_incumbent FROM essentials.politicians WHERE id = $1', [who.id]);
  if (afterFix.rows[0].is_incumbent !== true) fail('the reconciler did not apply the fix');
  else ok('fix applied: is_incumbent = true');

  // 3. THE TAMPER. Run the OLD promotion set-list. It MUST revert the fix; if it does not, this
  //    control cannot detect the defect it exists for, and step 4 below proves nothing.
  await client.query('UPDATE essentials.politicians SET is_incumbent = false WHERE id = $1', [who.id]);
  await applyIncumbencyFixes(client, withDrift.filter((d) => d.politicianId === who.id));
  await client.query(SET_LIST(true), [who.full_name, who.external_id]);
  const afterOld = await client.query('SELECT is_incumbent FROM essentials.politicians WHERE id = $1', [who.id]);
  if (afterOld.rows[0].is_incumbent !== true) {
    ok('TAMPER CONFIRMED: the old set-list reverts a reconciled value');
  } else {
    // The planted row's expected value is true, so the old set-list writing true is invisible
    // here. Re-run the tamper against a row whose correct value is FALSE.
    const { rows: ghosts } = await client.query(`
      SELECT p.id, p.full_name, p.external_id FROM essentials.politicians p
       WHERE p.is_active = true AND p.external_id IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id)
       LIMIT 1`);
    if (!ghosts.length) throw new Error('no seatless politician to test the tamper on');
    const g = ghosts[0];
    await client.query('UPDATE essentials.politicians SET is_incumbent = false WHERE id = $1', [g.id]);
    await client.query(SET_LIST(true), [g.full_name, g.external_id]);
    const t = await client.query('SELECT is_incumbent FROM essentials.politicians WHERE id = $1', [g.id]);
    if (t.rows[0].is_incumbent !== true) fail('TAMPER DID NOT APPLY — the old set-list did not revert anything, so this control tests nothing');
    else ok(`TAMPER CONFIRMED on ${g.full_name}: the old set-list forced is_incumbent back to true on a seatless row`);

    // 4. The real assertion: the NEW set-list must leave it alone.
    await client.query('UPDATE essentials.politicians SET is_incumbent = false WHERE id = $1', [g.id]);
    await client.query(SET_LIST(false), [g.full_name, g.external_id]);
    const n = await client.query('SELECT is_incumbent FROM essentials.politicians WHERE id = $1', [g.id]);
    if (n.rows[0].is_incumbent !== false) fail('the NEW set-list still reverted the value');
    else ok('the new set-list leaves a reconciled value alone');
  }

  await client.query('ROLLBACK');

  const post = await computeIncumbencyDrift(client);
  if (post.length !== baseline.length) fail(`rollback did not revert: drift is ${post.length}, was ${baseline.length}`);
  else ok(`rollback reverted (drift back to ${post.length})`);

  console.log(failed ? '\nCONTROL FAILED' : '\nCONTROL PASSED');
  process.exitCode = failed ? 1 : 0;
} finally {
  await client.end();
}
