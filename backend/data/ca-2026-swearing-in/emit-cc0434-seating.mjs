#!/usr/bin/env node
// Emit CC_0434: seat the single-seat LA County school board members who were appointed in lieu
// of election, at the Educ. Code 5017 commencement of 2026-12-11.
//
// 🔴 WHAT THIS REFUSES TO EMIT, AND WHY EACH REFUSAL IS A FINDING RATHER THAN A FILTER:
//
//   · A race with MORE THAN ONE seat. An at-large board is five identical `Board Member` office
//     rows and the race points at ONE of them, so "three winners" have no determinate office to
//     go into. Picking one would invent a fact about who replaced whom. Those 10 boards are left
//     for a decision; see NOTES.md.
//   · A candidate with NO `politician_id`. There is no person to seat.
//   · An office that is NOT on the county's FINAL cancelled list. A held-but-uncontested race
//     looks identical in our data and must be certified, not appointed.
//
// ⚠ The office each person takes is determinate here precisely because the race carries ONE seat
//   and points at ONE office. That is the whole reason this subset is safe and the other is not.
//
//   node emit-cc0434-seating.mjs <final.json> > ../../migrations/CC_0434_....sql
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

const listPath = process.argv[2];
if (!listPath) { console.error('usage: emit-cc0434-seating.mjs <final.json>'); process.exit(2); }
const seats = JSON.parse(readFileSync(listPath, 'utf8'));
const schoolSeats = seats.filter(s =>
  /COMMUNITY COLLEGE|HIGH SCHOOL|UNIFIED|ELEMENTARY/i.test(s.section) ||
  /school|board of education/i.test(s.raw));

const typeOfSection = sec => /COMMUNITY COLLEGE/i.test(sec) ? 'cc' : /HIGH SCHOOL/i.test(sec) ? 'hs'
  : /UNIFIED/i.test(sec) ? 'unified' : /ELEMENTARY/i.test(sec) ? 'elem' : null;
const typeOfName = n => /community college/i.test(n) ? 'cc'
  : /union high school|high school/i.test(n) ? 'hs' : /unified/i.test(n) ? 'unified' : 'elem';
const norm = s => s.toLowerCase()
  .replace(/\bjoint\b|\bunion\b|\bcity\b|\bunified\b|\belementary\b|\bhigh school\b|\bschool\b|\bdistrict\b|\bboard of education\b|\bboard\b|\bcommunity college\b|\barea\b/g, ' ')
  .replace(/[^a-z0-9]+/g, ' ').trim();
const seatToken = s => {
  const m = s.match(/(?:Board of Education|Trustee Area|Division|District|Area)\s+(\d+[A-Za-z]?|[A-Za-z])(?=\s|$|,)/i);
  if (m) return m[1].toLowerCase();
  if (/full term|entire jurisdiction/i.test(s)) return 'full';
  const n = s.match(/\b([0-9]+)\b/);
  return n ? n[1] : 'full';
};
const onList = positionName => {
  const head = positionName.split(' - ')[0];
  const t = typeOfName(head), d = norm(head), st = seatToken(positionName);
  return schoolSeats.some(s =>
    (typeOfSection(s.section) ?? typeOfName(s.raw)) === t &&
    (d.startsWith(norm(s.district)) || norm(s.district).startsWith(d)) &&
    seatToken(s.seat) === st);
};

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const { rows } = await pool.query(`
  SELECT r.position_name, r.seats, si.office_id, o.title,
         rc.politician_id, p.full_name,
         (SELECT count(*) FROM essentials.race_candidates x WHERE x.race_id = r.id)::int AS cands,
         (SELECT h.politician_id FROM essentials.office_current_holder h
           WHERE h.office_id = si.office_id) AS sitting
    FROM essentials.office_swearing_in si
    JOIN essentials.offices o ON o.id = si.office_id
    JOIN essentials.races r ON r.office_id = si.office_id
     AND r.election_id IN (SELECT id FROM essentials.elections WHERE election_date = '2026-11-03')
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
    LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE si.election_date = '2026-11-03' AND si.swearing_in_date = '2026-12-11'
     AND (SELECT count(*) FROM essentials.race_candidates y
           WHERE y.race_id = r.id AND y.result = 'won') = 0
     AND (SELECT count(*) FROM essentials.race_candidates z WHERE z.race_id = r.id) <= r.seats
   ORDER BY r.position_name`);
await pool.end();

const emit = [], skipped = [];
for (const r of rows) {
  if (!onList(r.position_name)) { skipped.push([r, 'not on the county FINAL cancelled list']); continue; }
  if (r.seats !== 1 || r.cands !== 1) { skipped.push([r, `at-large board (${r.cands} of ${r.seats} seats) — no determinate office`]); continue; }
  if (!r.politician_id) { skipped.push([r, 'candidate has no politician_id']); continue; }
  emit.push(r);
}

const q = s => `'${String(s).replace(/'/g, "''")}'`;
if (!emit.length) { console.error('nothing to emit'); process.exit(1); }

const skipLines = skipped.map(([r, why]) => `--   ${r.position_name} :: ${why}`).join('\n');
const values = emit.map(r =>
  `    (${q(r.office_id)}::uuid, ${q(r.politician_id)}::uuid, ${q(r.full_name)}, ${q(r.position_name)})`
).join(',\n');

process.stdout.write(`-- CC_0434 — seat the LA County school board members appointed in lieu of election,
-- at the Educ. Code 5017 commencement of 2026-12-11.
--
-- 🟢 THE PATTERN THIS COPIES IS RENO'S, AND IT IS THE POINT. \`CC_0387\` wrote Reno's three terms
-- in advance at day precision; on 2026-11-13 the view flipped by itself and nobody had to be
-- awake. These ${emit.length} terms start on 2026-12-11, so until that date
-- \`office_current_holder\` keeps returning the sitting member and on the day it changes with no
-- further migration. ⚠ The flip happens at UTC midnight, which is 16:00 Pacific on 12-10.
--
-- ── WHY THESE PEOPLE ARE SEATED WITHOUT A RESULT ────────────────────────────────────────────
-- Their elections were CANCELLED. Under Elec. Code 10515 a county may cancel an election where
-- the candidates do not exceed the seats, and Educ. Code 5328 then seats those who filed as if
-- elected. So there is no vote to wait for and no certification to come: the outcome was settled
-- in August, and 2026-12-11 is simply when the term begins.
--
-- 🔴🔴 OUR OWN DATA CANNOT TELL A CANCELLED ELECTION FROM A HELD, UNCONTESTED ONE. Both are
-- one candidate against one seat, \`result\` NULL and \`candidate_status\` 'active'. They need
-- OPPOSITE handling — one is seated now, the other must be certified first — and the only thing
-- that distinguishes them is the county's own publication:
--
--   **FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF ELECTION DUE TO INSUFFICIENCY
--   OF CANDIDATES**, Los Angeles County Registrar-Recorder/County Clerk, revised 8/25/2026
--   (content.lavote.gov/docs/rrcc/documents/canceled-elections-november-2026657f209d-ee3c-40ff-9167-8d1bd772b5c8.pdf)
--
-- 🟢 THE SHAPE AND THE AUTHORITY AGREE ROW FOR ROW. 96 of the 197 offices in the 2026-12-11
-- cohort match \`candidates <= seats and no winner\`; 96 appear on the county's final list; and
-- they are the SAME 96 — nothing is on one and not the other. That is why the shape predicate is
-- trusted here, and it is a measurement rather than an assumption. The reconciliation is
-- \`backend/data/ca-2026-swearing-in/reconcile-12-11-cohort.mjs\`.
--
-- ⚠ THE TENTATIVE LIST IS NOT THE FINAL ONE, AND BOTH ARE PUBLISHED. No school election was
-- un-cancelled between them, checked rather than assumed; the only row that left was a
-- placeholder reading "Information is forth coming" where the CITIES section had not yet been
-- compiled.
--
-- 🔴 A SCHOOL SEAT IS NOT ALWAYS UNDER A SCHOOL HEADING. The list files
-- "Pasadena (Pasadena Unified School District Board of Education 5)" under **CITIES**, because
-- that seat is consolidated with the city's election. A reader bounded to the four school
-- sections drops it silently, which is why the parser reads every section and the caller filters.
--
-- 🔴 THE ASTERISK ON THAT LIST IS A SECOND, OPPOSITE REASON. Its footnote reads "*Cancelled
-- Elections Due to No Candidates" — nobody filed, so there is nobody to appoint and the seat
-- becomes a vacancy for the board to fill. Gorman Joint Elementary (Full Term) is the only
-- school seat so marked, we hold no office for it, and it is NOT seated here. Seating an
-- asterisked row would invent an officeholder out of an empty race.
--
-- ── WHAT THIS FILE DELIBERATELY LEAVES OUT: ${String(skipped.length).padStart(2)} CANDIDACIES ───────────────────────────
${skipLines}
--
-- 🔴 THE AT-LARGE BOARDS ARE A MODELLING PROBLEM, NOT A MISSING SOURCE. Each is FIVE office rows
-- all titled \`Board Member\`, all currently seated, and the race points at exactly ONE of them
-- while carrying \`seats = 3\`. Three people cannot enter one office, and nothing in the title
-- says which three of the five seats are up. The discriminator exists — the five rows carry
-- different \`term_start\` values, and El Monte City's own sources even record "Unexpired term
-- ending December 11, 2026" — so this is solvable, but choosing WHICH seat a NEWCOMER takes is a
-- claim about who replaced whom. That is a decision, so it is not guessed here. See
-- \`backend/data/ca-2026-swearing-in/NOTES.md\`.
--
-- ⚠ Norwalk-La Mirada Trustee Area 5's filed candidate has no \`politicians\` row, so there is no
-- person to seat. It needs a person created first and is the only one of its kind here.
--
-- @incumbency-decision: gated — this inserts an \`essentials.office_terms\` row per seat and
-- \`seat_officeholder\` closes each predecessor, so it writes dates on BOTH sides of ${emit.length} seatings.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0434_la_school_boards_appointed_in_lieu_2026_12_11.sql

BEGIN;

-- The seatings this file performs. Generated by
-- backend/data/ca-2026-swearing-in/emit-cc0434-seating.mjs, which refuses every row described above.
CREATE TEMP TABLE cc0434_seatings ON COMMIT DROP AS
SELECT * FROM (VALUES
${values}
) AS t(office_id, politician_id, full_name, position_name);

-- 🔴 THE PLAN IS BOTH SIDES OF EVERY SEATING. \`seat_officeholder\` closes the predecessor's term,
-- so a scope naming only the arrivals would leave the outgoing members' dates unguarded.
CREATE TEMP TABLE cc0434_plan ON COMMIT DROP AS
SELECT politician_id FROM cc0434_seatings
UNION
SELECT och.politician_id
  FROM essentials.office_current_holder och
  JOIN cc0434_seatings s ON s.office_id = och.office_id
 WHERE och.politician_id IS NOT NULL;

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0434_seatings;
  IF v_n <> ${emit.length} THEN
    RAISE EXCEPTION 'CC_0434: expected ${emit.length} seatings, found %.', v_n;
  END IF;

  -- Every office must be in the 2026-12-11 cohort. If one is not, the generator has drifted from
  -- the swearing-in table and the whole premise of the date is gone.
  SELECT count(*) INTO v_bad
    FROM cc0434_seatings s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in si
                      WHERE si.office_id = s.office_id
                        AND si.election_date = DATE '2026-11-03'
                        AND si.swearing_in_date = DATE '2026-12-11');
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0434: % office(s) are not in the 2026-12-11 cohort.', v_bad;
  END IF;

  -- One office must appear once. Two rows for one office would mean an at-large board slipped
  -- through the generator's refusal, and the second seating would silently displace the first.
  SELECT count(*) INTO v_bad FROM (
    SELECT office_id FROM cc0434_seatings GROUP BY office_id HAVING count(*) > 1) x;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0434: % office(s) appear more than once.', v_bad;
  END IF;

  -- Nobody may already hold a term starting on the target date: this must not run twice in a way
  -- that writes a second 2026-12-11 term.
  SELECT count(*) INTO v_bad
    FROM cc0434_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
   WHERE ot.term_start = DATE '2026-12-11';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0434: % office(s) already carry a 2026-12-11 term.', v_bad;
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0434_plan);

-- Measure the occupancy drift metric before the writes, so the post-verify can gate on the DELTA
-- rather than on a total another session can move (CLAUDE.md).
CREATE TEMP TABLE cc0434_drift_before ON COMMIT DROP AS
SELECT count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ── Change ───────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT * FROM cc0434_seatings ORDER BY position_name LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id,
      r.politician_id,
      DATE '2026-12-11',
      'CC_0434: appointed in lieu of election (Elec. Code 10515; seated as if elected, Educ. Code '
      '5328). LA County RR/CC, FINAL LIST OF CANCELED ELECTIONS, November 3, 2026 General '
      'Election, revised 8/25/2026. Term commences 2026-12-11 per Educ. Code 5017.',
      -- 🔴 'appointed', NOT 'elected'. No election was held for these seats; the county's own
      -- document is titled "APPOINTMENT IN LIEU OF ELECTION" and Elec. Code 10515 is an
      -- appointment power. The statute then DEEMS the appointee elected, which is why they take
      -- the seat for a full term — but how they started is an appointment, and that is the fact
      -- this column records.
      p_how_started => 'appointed',
      -- 🔴 MOST OF THESE PEOPLE ALREADY HOLD THE SEAT. An uncontested filing is usually the
      -- sitting member, so the helper's re-election guard fires on them by design: it refuses a
      -- second term for a current holder unless the caller says the re-election is intended.
      -- It is intended here, and the guard did its job — the first run of this file was refused.
      p_allow_reelection => true);
  END LOOP;
END $$;

-- 🔴 \`seat_officeholder\` DOES NOT CLEAR \`is_vacant\` — the names suggest symmetry and there is
-- none. A seat left held AND flagged emits a spurious all-NULL office row for the holder.
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id IN (SELECT office_id FROM cc0434_seatings)
   AND is_vacant;

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_seated int; v_closed int; v_before int; v_after int;
BEGIN
  SELECT count(*) INTO v_seated
    FROM cc0434_seatings s
    JOIN essentials.office_terms ot
      ON ot.office_id = s.office_id AND ot.politician_id = s.politician_id
     AND ot.term_start = DATE '2026-12-11';
  IF v_seated <> ${emit.length} THEN
    RAISE EXCEPTION 'CC_0434: expected ${emit.length} terms starting 2026-12-11; found %.', v_seated;
  END IF;

  -- Every predecessor must close the day BEFORE, never on the day: two terms may not overlap.
  SELECT count(*) INTO v_closed
    FROM cc0434_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
   WHERE ot.term_end = DATE '2026-12-10';
  RAISE NOTICE 'CC_0434: % predecessor term(s) closed at 2026-12-10', v_closed;

  -- 🔴 NOBODY IS IN OFFICE YET. The whole design is that these terms are in the future, so the
  -- current holder must be UNCHANGED today. If one of these people is already current, the date
  -- went in wrong and voters would be told the wrong officeholder for 26 days.
  IF EXISTS (
    SELECT 1 FROM cc0434_seatings s
      JOIN essentials.office_current_holder och ON och.office_id = s.office_id
     WHERE och.politician_id = s.politician_id
       -- 🔴 \`term_start IS NULL\` IS AN EARLIER TERM, AND LEAVING IT OUT MAKES THIS GATE LIE.
       -- \`current_office_holders\` reads a NULL start as "current" (\`term_start IS NULL OR
       -- term_start <= CURRENT_DATE\`), and a NULL never satisfies \`< DATE\`, so the first draft
       -- of this gate flagged 9 legitimately-sitting members as impossible and failed the dry
       -- run. The members were right and the comparison was NULL-unsafe.
       AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                        WHERE t.office_id = s.office_id AND t.politician_id = s.politician_id
                          AND (t.term_start IS NULL OR t.term_start < DATE '2026-12-11'))
  ) THEN
    RAISE EXCEPTION 'CC_0434: somebody seated here is already the CURRENT holder without an '
      'earlier term — a 2026-12-11 term must not be current before 2026-12-11.';
  END IF;

  -- No office may be flagged vacant and held at once.
  IF EXISTS (SELECT 1 FROM cc0434_seatings s
               JOIN essentials.offices o ON o.id = s.office_id
              WHERE o.is_vacant) THEN
    RAISE EXCEPTION 'CC_0434: an office seated here is still flagged is_vacant.';
  END IF;

  -- Drift must not rise. It may FALL, if an office here had no term row at all.
  SELECT unflagged INTO v_before FROM cc0434_drift_before;
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_after
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  RAISE NOTICE 'CC_0434: unflagged occupancy drift % -> %', v_before, v_after;
  IF v_after > v_before THEN
    RAISE EXCEPTION 'CC_0434: unflagged drift rose from % to %.', v_before, v_after;
  END IF;
END $$;

`);

// Block B of the incumbency guard, pasted verbatim from the template with the plan table renamed.
process.stdout.write(readFileSync(new URL('./_incumbency_block_b.sql', import.meta.url), 'utf8'));
process.stdout.write('\nCOMMIT;\n');

