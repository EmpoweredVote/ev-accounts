/**
 * Positive control for election-transition-status.mjs.
 *
 * A status script that reports "nothing outstanding" looks identical to a status script whose
 * query matches no rows. All 35 Senate seats currently read "state 1", which is exactly what a
 * broken query also returns. This plants ONE known result inside a transaction, re-runs the
 * real buildStatus against that uncommitted state, asserts the seat MOVED and its neighbours
 * did not, and rolls back.
 *
 * It also asserts the COUNT the script examined (35), because a control proves a verifier CAN
 * move, not that it read the right rows.
 */
import 'dotenv/config';
import pg from 'pg';
import { buildStatus } from './election-transition-status.mjs';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const fail = (m) => { console.error('  ✗ ' + m); process.exitCode = 1; };
const ok = (m) => console.log('  ✓ ' + m);

try {
  await client.query('BEGIN');

  const before = await buildStatus(client, { levels: ['federal'] });
  const senBefore = before.seats.filter((s) => s.districtType === 'NATIONAL_UPPER');
  console.log(`baseline: ${senBefore.length} senate seats examined, states = ` +
    JSON.stringify(senBefore.reduce((a, s) => { a[s.seatState] = (a[s.seatState] || 0) + 1; return a; }, {})));

  if (senBefore.length !== 35) fail(`expected 35 senate seats examined, got ${senBefore.length}`);

  // Plant exactly one result.
  const target = senBefore[0];
  const { rows: cand } = await client.query(
    `SELECT id, full_name FROM essentials.race_candidates
      WHERE race_id = $1 AND politician_id IS NOT NULL LIMIT 1`, [target.raceId]);
  if (!cand.length) throw new Error('no candidate to plant on');

  await client.query(
    `UPDATE essentials.race_candidates
        SET result = 'won', result_certainty = 'called',
            result_source = 'POSITIVE CONTROL — rolled back'
      WHERE id = $1`, [cand[0].id]);
  console.log(`planted: ${target.state} -> ${cand[0].full_name} (won/called)`);

  const after = await buildStatus(client, { levels: ['federal'] });
  const senAfter = after.seats.filter((s) => s.districtType === 'NATIONAL_UPPER');
  const moved = senAfter.find((s) => s.raceId === target.raceId);

  console.log(`after:    ${senAfter.length} senate seats examined, states = ` +
    JSON.stringify(senAfter.reduce((a, s) => { a[s.seatState] = (a[s.seatState] || 0) + 1; return a; }, {})));

  if (senAfter.length !== 35) fail(`seat count changed to ${senAfter.length}`);
  if (!moved) fail('planted race vanished from the output');
  else {
    if (moved.seatState !== 2) fail(`planted seat reads state ${moved.seatState}, expected 2`);
    if (!moved.winner) fail('planted seat has no winner in the output');
    if (moved.resultCertainty !== 'called') fail(`certainty reads ${moved.resultCertainty}`);
  }
  const othersAt1 = senAfter.filter((s) => s.raceId !== target.raceId && s.seatState === 1).length;
  if (othersAt1 !== 34) fail(`expected the other 34 seats to stay at state 1, got ${othersAt1}`);

  // The winner's gap flags must now be computable (they are meaningless with no winner).
  console.log(`planted seat flags: noHeadshot=${moved?.flags.noHeadshot} noStances=${moved?.flags.noStances}`);

  // 🔴 STATES 3, 4 AND 5, WHICH THIS CONTROL USED TO SKIP ENTIRELY. Stopping at state 2 is how
  // a real defect survived review: the term-start subquery was anchored on TODAY, so state 5
  // was unreachable by construction and a seat fell BACKWARDS from 4 to 3 on the morning it was
  // sworn in. A control that never looks past state 2 cannot see that.
  await client.query(
    `UPDATE essentials.race_candidates SET result_certainty = 'certified' WHERE id = $1`, [cand[0].id]);
  const certified = await buildStatus(client, { levels: ['federal'] });
  const cRow = certified.seats.find((s) => s.raceId === target.raceId);
  if (cRow?.seatState !== 3) fail(`certified seat reads state ${cRow?.seatState}, expected 3`);
  else ok('certified → state 3');

  // Seat the winner on a future date, the way a real wave will.
  const { rows: pol } = await client.query(
    `SELECT politician_id FROM essentials.race_candidates WHERE id = $1`, [cand[0].id]);
  await client.query(
    `SELECT essentials.seat_officeholder($1, $2, DATE '2027-01-03', 'CONTROL — rolled back', 'elected', 'day', 'term_expired', true)`,
    [target.officeId, pol[0].politician_id]);

  const seated = await buildStatus(client, { levels: ['federal'], today: '2026-11-04' });
  const sRow = seated.seats.find((s) => s.raceId === target.raceId);
  if (sRow?.seatState !== 4) fail(`seated-but-not-sworn reads state ${sRow?.seatState}, expected 4`);
  else ok('seated with a future term → state 4');

  // The same data, read as if the calendar had reached the swearing-in date. Nothing is written:
  // the whole model turns on this being a date comparison, so this is the assertion that matters.
  const sworn = await buildStatus(client, { levels: ['federal'], today: '2027-01-03' });
  const wRow = sworn.seats.find((s) => s.raceId === target.raceId);
  if (wRow?.seatState !== 5) fail(`on swearing-in day the seat reads state ${wRow?.seatState}, expected 5 — it must not regress`);
  else ok('on 2027-01-03 the same row reads state 5, with nothing written');

  await client.query('ROLLBACK');

  // Prove the rollback reverted.
  const post = await buildStatus(client, { levels: ['federal'] });
  const stillPlanted = post.seats.filter((s) => s.seatState !== 1 && s.districtType === 'NATIONAL_UPPER');
  if (stillPlanted.length) fail(`rollback did not revert: ${stillPlanted.length} seat(s) still moved`);

  console.log(process.exitCode ? 'CONTROL FAILED' : 'CONTROL PASSED — detector moves, neighbours do not, rollback reverted');
} finally {
  await client.end();
}
