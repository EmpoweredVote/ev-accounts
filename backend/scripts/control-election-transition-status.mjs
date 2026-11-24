/**
 * Positive control for election-transition-status.mjs.
 *
 * A status script that reports "nothing outstanding" looks identical to a status script whose
 * query matches no rows. This plants known faults inside a transaction, re-runs the real
 * buildStatus against that uncommitted state, asserts the seats MOVED and their neighbours did
 * not, and rolls back.
 *
 * It also prints the COUNT it examined at every step, because a control proves a verifier CAN
 * move, not that it read the right rows.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THIS CONTROL WAS RED FOR SIX DAYS AND NOBODY SAW IT, BECAUSE ITS FIXTURE WAS A LITERAL
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 *
 * It opened by asserting "35 senate seats examined, all at state 1" and ended by asserting the
 * rollback had returned them all to state 1. That was true when it was written and stopped being
 * true on 2026-11-18, when CC_0340, CC_0453 and CC_0454 seated the whole federal tier: the
 * baseline became {"4": 35} and SIX assertions failed at once — including the rollback check,
 * which reported "rollback did not revert: 35 seats still moved" when the rollback had worked
 * perfectly. It is not wired into CI and is run by hand, so nothing announced it.
 *
 * ▶ **A CONTROL WHOSE FIXTURE THE PROGRAMME WILL MOVE PAST IS A CONTROL WITH A SHELF LIFE.**
 *   This version LOCATES its own fixture by measuring — a race that is still at state 1 today —
 *   and compares the WHOLE state histogram before and after rather than a hardcoded 35. It also
 *   refuses to report if it cannot find a fixture, rather than passing vacuously.
 *
 * ⚠ **AND THE FAILING ASSERTIONS WERE NOT ALL OF THE SAME KIND.** Three were the stale fixture
 *   (states 1 and 2, and the rollback). Three steps still passed throughout — the future-dated
 *   term, the date comparison and the unknown winner — because those plant their own state
 *   instead of assuming one. **The ones that assumed survived; the ones that planted did not.**
 */
import 'dotenv/config';
import pg from 'pg';
import { buildStatus } from './election-transition-status.mjs';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const fail = (m) => { console.error('  ✗ ' + m); process.exitCode = 1; };
const ok = (m) => console.log('  ✓ ' + m);
const histogram = (seats) =>
  seats.reduce((a, s) => { a[s.seatState] = (a[s.seatState] || 0) + 1; return a; }, {});

try {
  await client.query('BEGIN');

  // ── PART ONE: the ladder, 1 → 2 → 3 → 4 → 5, on a fixture this control finds for itself. ────
  const before = await buildStatus(client);
  const baseline = histogram(before.seats);
  console.log(`baseline: ${before.seats.length} races examined, states = ${JSON.stringify(baseline)}`);
  if (before.seats.length < 100) fail(`only ${before.seats.length} races examined — the query is not reading the corpus`);

  // 🔴 THE FIXTURE IS MEASURED, NOT NAMED. It must be a race with no recorded result (state 1),
  // an office, and at least two candidate rows — the second is what the unknown-winner step
  // needs. If the programme ever finishes, this control says so instead of passing vacuously.
  const { rows: fx } = await client.query(
    `SELECT r.id AS race_id, o.id AS office_id, count(rc.id) AS candidates
       FROM essentials.races r
       JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
       JOIN essentials.offices o   ON o.id = r.office_id
       JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id IS NOT NULL
      WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates w
                         WHERE w.race_id = r.id AND w.result = 'won')
      GROUP BY r.id, o.id HAVING count(rc.id) >= 2
      ORDER BY r.id LIMIT 1`);
  if (!fx.length) {
    fail('no race with no recorded result and two identified candidates — this control has no fixture left and asserted NOTHING. Point it at a different election date.');
    throw new Error('no fixture');
  }
  const target = { raceId: fx[0].race_id, officeId: fx[0].office_id };
  const targetBefore = before.seats.find((s) => s.raceId === target.raceId);
  if (targetBefore?.seatState !== 1) fail(`the chosen fixture reads state ${targetBefore?.seatState}, expected 1`);
  else ok(`fixture located by measurement: one of the ${baseline[1] ?? 0} races still at state 1`);

  const { rows: cand } = await client.query(
    `SELECT id, full_name FROM essentials.race_candidates
      WHERE race_id = $1 AND politician_id IS NOT NULL ORDER BY id LIMIT 1`, [target.raceId]);

  await client.query(
    `UPDATE essentials.race_candidates
        SET result = 'won', result_certainty = 'called',
            result_source = 'POSITIVE CONTROL — rolled back'
      WHERE id = $1`, [cand[0].id]);
  console.log(`planted: ${cand[0].full_name} (won/called) on race ${target.raceId}`);

  const after = await buildStatus(client);
  const moved = after.seats.find((s) => s.raceId === target.raceId);
  console.log(`after:    ${after.seats.length} races examined, states = ${JSON.stringify(histogram(after.seats))}`);

  if (after.seats.length !== before.seats.length) fail(`race count changed to ${after.seats.length}`);
  if (!moved) fail('planted race vanished from the output');
  else {
    if (moved.seatState !== 2) fail(`planted seat reads state ${moved.seatState}, expected 2`);
    if (!moved.winner) fail('planted seat has no winner in the output');
    if (moved.resultCertainty !== 'called') fail(`certainty reads ${moved.resultCertainty}`);
  }
  // 🔴 THE NEIGHBOURS, AS A DELTA RATHER THAN A LITERAL. Exactly one race leaves state 1 and
  // exactly one arrives at state 2; everything else is untouched.
  const afterHist = histogram(after.seats);
  if ((afterHist[1] ?? 0) !== (baseline[1] ?? 0) - 1) fail(`state 1 went ${baseline[1]} -> ${afterHist[1]}, expected a fall of exactly 1`);
  if ((afterHist[2] ?? 0) !== (baseline[2] ?? 0) + 1) fail(`state 2 went ${baseline[2]} -> ${afterHist[2]}, expected a rise of exactly 1`);
  if ((afterHist[4] ?? 0) !== (baseline[4] ?? 0)) fail(`state 4 moved ${baseline[4]} -> ${afterHist[4]} and this step writes no term`);
  if (!process.exitCode) ok('exactly one race moved 1 → 2 and no other state changed');

  console.log(`planted seat flags: noHeadshot=${moved?.flags.noHeadshot} noStances=${moved?.flags.noStances}`);

  // 🔴 STATES 3, 4 AND 5, WHICH THIS CONTROL USED TO SKIP ENTIRELY. Stopping at state 2 is how
  // a real defect survived review: the term-start subquery was anchored on TODAY, so state 5
  // was unreachable by construction and a seat fell BACKWARDS from 4 to 3 on the morning its
  // term began. A control that never looks past state 2 cannot see that.
  await client.query(
    `UPDATE essentials.race_candidates SET result_certainty = 'certified' WHERE id = $1`, [cand[0].id]);
  const certified = await buildStatus(client);
  const cRow = certified.seats.find((s) => s.raceId === target.raceId);
  if (cRow?.seatState !== 3) fail(`certified seat reads state ${cRow?.seatState}, expected 3`);
  else ok('certified → state 3');

  // Seat the winner on a future date, the way a real wave will.
  const { rows: pol } = await client.query(
    `SELECT politician_id FROM essentials.race_candidates WHERE id = $1`, [cand[0].id]);
  await client.query(
    `SELECT essentials.seat_officeholder($1, $2, DATE '2027-01-03', 'CONTROL — rolled back', 'elected', 'day', 'term_expired', true)`,
    [target.officeId, pol[0].politician_id]);

  const seated = await buildStatus(client, { today: '2026-11-04' });
  const sRow = seated.seats.find((s) => s.raceId === target.raceId);
  if (sRow?.seatState !== 4) fail(`a term dated ahead reads state ${sRow?.seatState}, expected 4`);
  else ok('seated with a future term → state 4');

  // The same data, read as if the calendar had reached the term start. Nothing is written: the
  // whole model turns on this being a date comparison, so this is the assertion that matters.
  const started = await buildStatus(client, { today: '2027-01-03' });
  const wRow = started.seats.find((s) => s.raceId === target.raceId);
  if (wRow?.seatState !== 5) fail(`on the term-start date the seat reads state ${wRow?.seatState}, expected 5 — it must not regress`);
  else ok('on 2027-01-03 the same row reads state 5, with nothing written');

  // 🔴 FAILURE MODE 4 — A WINNER WE HAVE NEVER SEEN BEFORE. Their gap flags are the whole point:
  // nobody can research a stance for a person who has no row, so the tracker must say so loudly
  // rather than report the seat as quietly fine.
  const { rows: fresh } = await client.query(
    `SELECT id FROM essentials.race_candidates WHERE race_id = $1 AND id <> $2 LIMIT 1`,
    [target.raceId, cand[0].id]);
  if (fresh.length) {
    await client.query(
      `UPDATE essentials.office_terms SET term_end = NULL WHERE office_id = $1 AND politician_id = $2
         AND term_start = DATE '2027-01-03'`, [target.officeId, pol[0].politician_id]);
    await client.query(
      `DELETE FROM essentials.office_terms WHERE office_id = $1 AND politician_id = $2
         AND term_start = DATE '2027-01-03'`, [target.officeId, pol[0].politician_id]);
    await client.query(
      `UPDATE essentials.race_candidates SET result = NULL, result_certainty = NULL WHERE id = $1`,
      [cand[0].id]);
    await client.query(
      `UPDATE essentials.race_candidates
          SET result = 'won', result_certainty = 'called', politician_id = NULL,
              result_source = 'POSITIVE CONTROL — unknown winner, rolled back'
        WHERE id = $1`, [fresh[0].id]);

    const unknown = await buildStatus(client);
    const uRow = unknown.seats.find((s) => s.raceId === target.raceId);
    if (uRow?.seatState !== 2) fail(`a winner with no politicians row reads state ${uRow?.seatState}, expected 2`);
    else if (!uRow.winner) fail('a winner with no politicians row vanished from the output');
    else if (!uRow.flags.noHeadshot || !uRow.flags.noStances) {
      fail(`a winner with no politicians row must flag BOTH gaps, got noHeadshot=${uRow.flags.noHeadshot} noStances=${uRow.flags.noStances}`);
    } else ok('a winner with no politicians row: state 2, named, both gaps flagged');
  } else {
    fail('no second candidate on the target race — could not exercise the unknown-winner case');
  }

  await client.query('ROLLBACK');

  // Prove the rollback reverted — against the baseline histogram, not a literal.
  const post = await buildStatus(client);
  const postHist = histogram(post.seats);
  if (JSON.stringify(postHist) !== JSON.stringify(baseline)) {
    fail(`rollback did not revert: ${JSON.stringify(baseline)} -> ${JSON.stringify(postHist)}`);
  } else ok('rollback reverted — the whole state histogram is back to its baseline');

  // ── PART TWO: a multi-seat race is seated only when EVERY winner is. ─────────────────────────
  //
  // 🔴🔴 THE RISK IN ASKING THE QUESTION OVER THE WHOLE ELIGIBLE SET IS OVER-COUNTING. The
  // seating question used to be "does this winner hold a term on the office the race hangs on",
  // which reported a fully seated multi-seat body as `called`; it is now "on any of the offices
  // this race can fill" — same district, chamber and title. If that widening were sloppy, a race
  // could read seated while a winner was not. So this takes a race that really IS fully seated,
  // removes ONE winner's term, and requires the race to fall back.
  //
  // ⚠ It locates its fixture by measurement too, and says so when there is none.
  await client.query('BEGIN');
  const base2 = await buildStatus(client);
  const multi = base2.seats.find((s) => s.winnerCount > 1 && s.seatState >= 4);
  if (!multi) {
    fail('no fully seated multi-winner race in the corpus — the eligible-set question is UNTESTED here. Run this again after a multi-seat wave.');
  } else {
    const { rows: victims } = await client.query(
      `SELECT t.id, t.politician_id, p.full_name
         FROM essentials.race_candidates rc
         JOIN essentials.office_terms t ON t.politician_id = rc.politician_id
                                       AND t.term_start >= DATE '2026-11-03'
         JOIN essentials.offices o2 ON o2.id = t.office_id
         JOIN essentials.offices ro ON ro.id = (SELECT office_id FROM essentials.races WHERE id = $1)
         JOIN essentials.politicians p ON p.id = rc.politician_id
        WHERE rc.race_id = $1 AND rc.result = 'won'
          AND o2.district_id = ro.district_id
          AND o2.chamber_id IS NOT DISTINCT FROM ro.chamber_id
          AND o2.title = ro.title
        ORDER BY t.id LIMIT 1`, [multi.raceId]);
    if (!victims.length) {
      fail(`the chosen multi-winner race reads seated but no term of its winners sits in its eligible set — the widened question is matching something unexpected`);
    } else {
      console.log(`multi-seat fixture: ${multi.state} ${multi.title} — ${multi.winnerCount} winners, state ${multi.seatState}; removing ${victims[0].full_name}'s term`);
      await client.query(`DELETE FROM essentials.office_terms WHERE id = $1`, [victims[0].id]);
      const broken = await buildStatus(client);
      const bRow = broken.seats.find((s) => s.raceId === multi.raceId);
      if (bRow?.seatState >= 4) {
        fail(`one winner's term removed and the race still reads state ${bRow.seatState} — the widened question is over-counting`);
      } else if (!bRow?.flags.partlySeated) {
        fail(`one winner's term removed and partlySeated is ${bRow?.flags.partlySeated}, expected true`);
      } else {
        ok(`one winner unseated → state ${bRow.seatState}, partlySeated true: every winner must have a term`);
      }
    }
  }
  await client.query('ROLLBACK');

  const post2 = await buildStatus(client);
  if (JSON.stringify(histogram(post2.seats)) !== JSON.stringify(baseline)) {
    fail('the second rollback did not revert');
  } else ok('second rollback reverted');

  console.log(process.exitCode ? 'CONTROL FAILED' : 'CONTROL PASSED — detector moves, neighbours do not, rollback reverted');
} finally {
  await client.end();
}
