#!/usr/bin/env node
// Emit CC_0437: seat the ALL-INCUMBENT at-large LA County school boards at 2026-12-11.
//
// 🔴 WHAT MAKES THESE SIX DETERMINATE AND THE OTHER FOUR NOT. An at-large board is five office
// rows all titled `Board Member`, all seated, and the race points at ONE of them while carrying
// `seats = 3`. Three people cannot enter one office, and the title says nothing about which
// three of the five seats are up. That is why CC_0434 refused all ten.
//
// Where EVERY filer already sits on the board, the question disappears: each one returns to the
// seat they already hold. No seat has to be chosen, so no claim is made about who replaced whom.
// Where a NEWCOMER is involved (Hawthorne, Hermosa Beach City, Manhattan Beach, San Marino) the
// choice is unavoidable and those boards are still left alone.
//
// ⚠ SO THIS SCRIPT EMITS ONLY (person, the office that person ALREADY HOLDS). It refuses any
// board where a filer does not currently sit, and the migration asserts the same property again
// so a future re-run cannot quietly move somebody to a different seat.
//
// 🔴 AND THE OBVIOUS RULE — "SEAT THE MEMBERS WITH THE OLDEST term_start" — IS WRONG HERE.
// Five of the six boards do split cleanly, filers on 2022-12-01 and non-filers on 2024-12-01.
// **El Monte City does not**: Cesar Peralta carries 2024-12-01, the same date as two members who
// are NOT up, because his is an unexpired term — his own source records RR/CC 4324, "Unexpired
// term ending December 11, 2026". The date does not discriminate; the source does. Nothing here
// relies on the date, which is precisely why it is safe.
//
//   node emit-cc0437-atlarge.mjs > ../../migrations/CC_0437_....sql
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

const BOARDS = [
  'El Monte City School Board',
  'El Rancho Unified School Board',
  'El Segundo Unified School Board',
  'Rosemead School Board',
  'Walnut Valley Unified School Board',
  'West Covina Unified School Board',
];

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const { rows } = await pool.query(`
  SELECT r.position_name, r.seats,
         rc.politician_id, p.full_name,
         och.office_id AS held_office_id
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = '2026-11-03'
    JOIN essentials.offices ro ON ro.id = r.office_id
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
    JOIN essentials.politicians p ON p.id = rc.politician_id
    JOIN essentials.offices o2 ON o2.chamber_id = ro.chamber_id
    JOIN essentials.office_current_holder och ON och.office_id = o2.id
                                             AND och.politician_id = rc.politician_id
   WHERE r.position_name = ANY($1)
   ORDER BY r.position_name, p.full_name`, [BOARDS]);
await pool.end();

// Every board must be complete: as many seatings as the race has seats, every filer sitting.
const byBoard = new Map();
for (const r of rows) {
  if (!byBoard.has(r.position_name)) byBoard.set(r.position_name, { seats: r.seats, rows: [] });
  byBoard.get(r.position_name).rows.push(r);
}
for (const b of BOARDS) {
  const g = byBoard.get(b);
  if (!g) { console.error(`FATAL: ${b} resolved no rows.`); process.exit(2); }
  if (g.rows.length !== g.seats) {
    console.error(`FATAL: ${b} has ${g.rows.length} sitting filers against ${g.seats} seats — not all-incumbent.`);
    process.exit(2);
  }
}
const emit = rows;
const offices = new Set(emit.map(r => r.held_office_id));
if (offices.size !== emit.length) { console.error('FATAL: an office appears twice.'); process.exit(2); }

const q = s => `'${String(s).replace(/'/g, "''")}'`;
const values = emit.map(r =>
  `    (${q(r.held_office_id)}::uuid, ${q(r.politician_id)}::uuid, ${q(r.full_name)}, ${q(r.position_name)})`
).join(',\n');
const summary = BOARDS.map(b => `--   ${b.padEnd(38)} ${byBoard.get(b).rows.length} of ${byBoard.get(b).seats} seats`).join('\n');

process.stdout.write(`-- CC_0437 — the six at-large school boards where every filer already sits.
--
-- \`CC_0434\` seated 85 LA County school board members appointed in lieu of election and refused
-- 29 candidacies across TEN at-large boards, because an at-large board is five office rows all
-- titled \`Board Member\`, all seated, with the race pointing at ONE of them and carrying
-- \`seats = 3\`. Three people cannot enter one office, and nothing in the title says which three
-- of the five seats are up.
--
-- 🟢 FOR SIX OF THOSE TEN THE QUESTION DOES NOT ARISE, AND THAT IS THE WHOLE ARGUMENT OF THIS
-- FILE. Every filer on these six boards ALREADY SITS on it, so each returns to the seat they
-- already hold. No seat is chosen, so no claim is made about who replaced whom:
--
${summary}
--
-- 🔴 THE OTHER FOUR ARE STILL REFUSED, AND DELIBERATELY: Hawthorne (2 of 3 filers sit), Hermosa
-- Beach City (1 of 3), Manhattan Beach (2 of 3) and San Marino (2 of 3). Placing a NEWCOMER into
-- one of five indistinguishable seats is an assertion about which member they succeeded, and
-- nothing in the record supports one choice over another. Those wait for each board's own
-- organisational minutes.
--
-- 🔴🔴 AND THE RULE THAT LOOKS RIGHT IS WRONG — "SEAT THE MEMBERS WITH THE OLDEST \`term_start\`".
-- Five of these six split cleanly, filers on 2022-12-01 and non-filers on 2024-12-01. **El Monte
-- City does not.** Cesar Peralta carries 2024-12-01, the SAME DATE as Jennifer Cobian and David
-- Siegrist, who are not up — because his is an unexpired term. His own term source records it:
-- LA County RR/CC candidate list 4324, "Unexpired term ending December 11, 2026". ▶ The date does
-- not discriminate; the SOURCE does. Nothing in this file reads the date, which is exactly why
-- it is safe — the mapping is "the seat this person already holds", not "the seat that looks due".
--
-- ── WHY THEY ARE SEATED WITHOUT A RESULT ────────────────────────────────────────────────────
-- Identical to CC_0434: these elections were CANCELLED under Elec. Code 10515 and Educ. Code 5328
-- seats those who filed as if elected, so there is no vote to wait for. All six boards appear on
-- LA County RR/CC's FINAL LIST OF CANCELED ELECTIONS, revised 8/25/2026.
--
-- ⚠ Terms start 2026-12-11 and are written in advance at day precision, so the view flips by
-- itself on the day (the Reno pattern, CC_0387). It flips at UTC midnight = 16:00 Pacific on 12-10.
--
-- 🔴 AND THE \`is_vacant\` MISTAKE OF CC_0434 IS NOT REPEATED. That file cleared the flag on every
-- office it touched, which was wrong for six seats whose only term was in the future; they were
-- empty today and \`check:reachability\` fired a new DEAD_GEOGRAPHY bucket (CC_0436 restored them).
-- Here EVERY office is currently held by the very person being re-seated, so none is flagged and
-- none needs clearing. This file touches \`essentials.offices\` not at all, and asserts that.
--
-- @incumbency-decision: gated — this inserts an \`essentials.office_terms\` row per seat and
-- \`seat_officeholder\` closes each predecessor, so it writes dates on both sides of ${emit.length} seatings.
-- ⚠ Here the predecessor and the successor are the SAME PERSON on every row.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0437_la_atlarge_all_incumbent_boards_2026_12_11.sql

BEGIN;

CREATE TEMP TABLE cc0437_seatings ON COMMIT DROP AS
SELECT * FROM (VALUES
${values}
) AS t(office_id, politician_id, full_name, board);

CREATE TEMP TABLE cc0437_plan ON COMMIT DROP AS
SELECT politician_id FROM cc0437_seatings
UNION
SELECT och.politician_id FROM essentials.office_current_holder och
  JOIN cc0437_seatings s ON s.office_id = och.office_id
 WHERE och.politician_id IS NOT NULL;

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0437_seatings;
  IF v_n <> ${emit.length} THEN
    RAISE EXCEPTION 'CC_0437: expected ${emit.length} seatings, found %.', v_n;
  END IF;

  -- 🔴🔴 THE SAFETY PROPERTY OF THIS WHOLE FILE, ASSERTED RATHER THAN TRUSTED: every person is
  -- seated into the office THEY ALREADY HOLD. If that is not true of even one row, the file is
  -- choosing a seat for somebody, which is the thing it exists to avoid.
  SELECT count(*) INTO v_bad
    FROM cc0437_seatings s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = s.office_id
                        AND och.politician_id = s.politician_id);
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0437: % row(s) would seat somebody into an office they do NOT already '
      'hold. This file may only RE-seat sitting members.', v_bad;
  END IF;

  -- Each office once.
  SELECT count(*) INTO v_bad FROM (
    SELECT office_id FROM cc0437_seatings GROUP BY office_id HAVING count(*) > 1) x;
  IF v_bad > 0 THEN RAISE EXCEPTION 'CC_0437: % office(s) appear twice.', v_bad; END IF;

  -- Every office must be in the 2026-12-11 cohort's chambers and carry no 12-11 term yet.
  SELECT count(*) INTO v_bad
    FROM cc0437_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
   WHERE ot.term_start = DATE '2026-12-11';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0437: % office(s) already carry a 2026-12-11 term.', v_bad;
  END IF;

  -- 🔴 The four boards with a newcomer must still be untouched going in — they are the control
  -- that this file is not treating all ten at-large boards as one class.
  SELECT count(*) INTO v_bad
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
    JOIN essentials.office_terms ot ON ot.politician_id = rc.politician_id
                                   AND ot.term_start = DATE '2026-12-11'
   WHERE r.position_name IN ('Hawthorne School Board','Hermosa Beach City School Board',
                             'Manhattan Beach Unified School Board','San Marino Unified School Board');
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0437: % filer(s) on the four newcomer boards already carry a 2026-12-11 '
      'term. Those boards are deliberately not seated; read the header.', v_bad;
  END IF;
END $$;

-- @incumbency-decision: gated — see the header.
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0437_plan);

CREATE TEMP TABLE cc0437_drift_before ON COMMIT DROP AS
SELECT count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ── Change ───────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM cc0437_seatings ORDER BY board, full_name LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id,
      r.politician_id,
      DATE '2026-12-11',
      'CC_0437: appointed in lieu of election (Elec. Code 10515; seated as if elected, Educ. Code '
      '5328). LA County RR/CC, FINAL LIST OF CANCELED ELECTIONS, November 3, 2026 General '
      'Election, revised 8/25/2026. At-large board; this member returns to the seat they already '
      'hold. Term commences 2026-12-11 per Educ. Code 5017.',
      p_how_started => 'appointed',
      -- Every row here is by definition a re-election: the person already holds this seat.
      p_allow_reelection => true);
  END LOOP;
END $$;

-- 🔴 NO \`is_vacant\` WRITE. Every office here is held today by the person being re-seated, so
-- none is flagged and clearing would be a no-op at best. CC_0434's blanket clear was the defect
-- CC_0436 had to undo; this file does not repeat the shape.

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_seated int; v_closed int; v_before int; v_after int; v_flagged int;
BEGIN
  SELECT count(*) INTO v_seated
    FROM cc0437_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
                                   AND ot.politician_id = s.politician_id
                                   AND ot.term_start = DATE '2026-12-11';
  IF v_seated <> ${emit.length} THEN
    RAISE EXCEPTION 'CC_0437: expected ${emit.length} terms starting 2026-12-11; found %.', v_seated;
  END IF;

  -- Each predecessor term closes the day before, and the predecessor is the same person.
  SELECT count(*) INTO v_closed
    FROM cc0437_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
                                   AND ot.politician_id = s.politician_id
                                   AND ot.term_end = DATE '2026-12-10';
  IF v_closed <> ${emit.length} THEN
    RAISE EXCEPTION 'CC_0437: expected ${emit.length} predecessor terms closed at 2026-12-10 for the SAME '
      'person; found %.', v_closed;
  END IF;

  -- 🔴 NOBODY MOVED SEATS AND NOBODY LOST ONE. Each of these offices must still resolve the same
  -- holder today, because the new term has not begun.
  IF EXISTS (SELECT 1 FROM cc0437_seatings s
               LEFT JOIN essentials.office_current_holder och ON och.office_id = s.office_id
              WHERE och.politician_id IS DISTINCT FROM s.politician_id) THEN
    RAISE EXCEPTION 'CC_0437: an office changed hands today. These terms start 2026-12-11.';
  END IF;

  -- 🔴 And no office acquired a vacancy flag — the CC_0434/CC_0436 lesson, asserted.
  SELECT count(*) INTO v_flagged
    FROM cc0437_seatings s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant;
  IF v_flagged > 0 THEN
    RAISE EXCEPTION 'CC_0437: % office(s) here are flagged vacant while held.', v_flagged;
  END IF;

  SELECT unflagged INTO v_before FROM cc0437_drift_before;
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_after
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  RAISE NOTICE 'CC_0437: unflagged occupancy drift % -> %', v_before, v_after;
  IF v_after <> v_before THEN
    RAISE EXCEPTION 'CC_0437: unflagged drift moved % -> %. Every office here already had a term, '
      'so it must not move at all.', v_before, v_after;
  END IF;
END $$;

`);

process.stdout.write(readFileSync(new URL('./_incumbency_block_b.sql', import.meta.url), 'utf8')
  .replace(/cc0434_plan/g, 'cc0437_plan'));
process.stdout.write('\nCOMMIT;\n');
