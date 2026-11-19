-- CC_0456 — seat wave 3: the 72 California winners who take office in December 2026
--
-- Writes 72 `essentials.office_terms` rows, dated in advance at day precision, so
-- `office_current_holder` flips by itself on each handover day and nobody has to be awake.
-- That is the Reno pattern (CC_0385-CC_0387) and the same shape as CC_0453's 427 federal seats.
--
--   2026-12-04   11 seats   special districts — water, irrigation, CSD   (Water Code / EC 10554)
--   2026-12-11   59 seats   school and community-college boards         (Educ. Code 5017)
--   2026-12-14    2 seats   City of Los Angeles                         (Charter § 205(c))
--                 --
--                 72
--
-- ▶ THE DATE IS READ FROM `essentials.office_swearing_in`, NEVER WRITTEN INTO THIS FILE.
--   A literal would agree with itself however wrong it was. P2 refuses any row whose date
--   does not come from that table, for that office, for the 2026-11-03 election.
--   Ruling 2 (CC_0382) fixes the school date at the Educ. Code 5017 COMMENCEMENT, not the
--   § 35143 oath up to 15 days later: "seat whichever is earliest", everywhere.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY THIS IS 72 AND THE TRACKER SAYS 60
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- `office_swearing_in` carries one row per OFFICE, and a race hangs off ONE office. For a
-- by-trustee-area seat those are the same thing. For an AT-LARGE board they are not: the body
-- has N offices, one race with `seats = N`, and only the race-carrying office ever got a
-- swearing-in row. So an office-keyed count sees 1 seat where N are being filled, and every
-- office-keyed read of this wave undercounts it by N-1.
--
-- Five bodies are in that shape here, and they account for all 12 of the difference:
--
--   Crescenta Valley Water District          3 seats, 1 swearing-in row   (2026-12-04)
--   Culver City Unified                      3 seats, 1 row               (2026-12-11)
--   Mountain View Elementary                 3 seats, 1 row               (2026-12-11)
--   Santa Monica Community College District  4 seats, 1 row               (2026-12-11)
--   Santa Monica-Malibu Unified              4 seats, 1 row               (2026-12-11)
--
-- ⚠ This is not new and it is not a defect this file introduces: CC_0437 already seated 11
--   offices at 2026-12-11 that carry no swearing-in row, for exactly this reason. The count is
--   what is wrong, not the data. Recorded here so the next reader does not re-derive it.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE AT-LARGE SEAT ASSIGNMENT, AND WHY THREE ROWS ARE PINNED BY HAND
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- An at-large board has no numbered seats. Our `offices` rows are an internal fiction that has
-- to be mapped onto real people, and 14 of the 17 map themselves: the winner already holds a
-- seat in that body, so they keep it (CC_0437's rule, and the only reason that file could
-- resolve 6 of its 10 boards).
--
-- Three winners hold nothing, so somebody must say which departing member's seat they take.
-- 🔴 "SEAT THE OLDEST `term_start`" IS THE WRONG RULE — CC_0437 paid for that at El Monte City,
--   where an unexpired term carried the same date as two members who were not up. THE DATE DOES
--   NOT DISCRIMINATE; THE SOURCE DOES. So each of the three is pinned to an office, and P5
--   refuses unless production still shows the departing member this file names holding it:
--
--   Carla D. Dillon     → Kerry D. Erickson's seat        Crescenta Valley Water District
--       LA County RR/CC "List of Offices to be Filled, General Election November 3, 2026"
--       names the three officeholders whose seats are up: James Bodnar, Kerry Erickson,
--       Jeffery W. Johnson. Bodnar and Johnson were re-elected; Erickson was not on the ballot.
--       Corroborated by the district general manager's column in Crescenta Valley Weekly
--       ("first elected in 2009 … will not be running for re-election").
--
--   Robbie Staenberg    → Richard Tahvildaran-Jesswein's  Santa Monica-Malibu Unified
--       The district's own roster, smmusd.org/board-of-education/board-of-education, read
--       2026-11-18: "Board of Education Member's Terms — Jon Kean, December 2028; Maria
--       Leon-Vazquez, December 2028; Laurie Lieberman, December 2026; Alicia Mignano,
--       December 2026; Stacy Rouse, December 2026; Jennifer Smith, December 2028;
--       Dr. Richard Tahvildaran-Jesswein, December 2026." Exactly four expire, and three of
--       the four won re-election. 🟢 This also settles the three SMMUSD seats whose
--       `term_start` is NULL from the phase-2 backfill: Kean and Leon-Vazquez run to 2028, so
--       no amount of date arithmetic on our side could have answered it, and none was used.
--
--   Kera Blades-Snell   → Nancy Greenstein's seat          Santa Monica CCD
--       ⚠ WEAKEST OF THE THREE, AND SAID SO. smc.edu/BOT names all seven trustees and our
--       seven holders match it one for one, but it publishes NO term dates, and the City of
--       Santa Monica's notice of offices would not serve (HTTP failure, both plain and in a
--       browser). The assignment therefore rests on our own cohorts, which here are
--       unambiguous: four seats are up; Roy, Peters and Greenstein hold the only 2022-12-01
--       terms and Barrera Castañón holds a distinct 2025-02-04 unexpired term — four, exactly.
--       Rader, Foster and Quiñones-Perez are all 2024-12-01 and continue to 2028. Three of the
--       four up won; Greenstein is the remainder. There is NO TIE, which is the condition El
--       Monte failed on. ▶ If anyone can reach the City's notice, confirm it.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT THIS FILE DELIBERATELY DOES NOT DO: IT CLEARS NO `is_vacant` FLAG
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- Six of the 72 seats are flagged `is_vacant` and hold no term at all — they are empty TODAY
-- and stay empty until 2026-12-11. `seat_officeholder` never touches `essentials.offices`, so
-- the flag survives this file, and V5 asserts that it did.
--
-- 🔴 CLEARING THEM NOW IS THE MISTAKE, NOT CLEARING THEM LATE. CC_0434 cleared `is_vacant`
--   across "every office this migration touched" — a predicate on the migration's scope, not on
--   what the column means — and `check:reachability` fired a new `DEAD_GEOGRAPHY ca|SCHOOL 6`
--   bucket within minutes; CC_0436 put it back. Measured again for these six: every one is the
--   ONLY office in its district, with 0 active holders and 1 vacant office, so clearing the flag
--   gives `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim the classifier
--   at `backend/scripts/check-address-reachability.mjs:287-289`. That gate is MASTER-ONLY, so it
--   would fail the next person's PR and name an innocent author.
--
--   Keppel Union TA 1 · Keppel Union TA 2 · Little Lake City TA 5 (vacant since 2026-05-11) ·
--   Palmdale TA 3 · Paramount Unified TA 4 · Torrance Unified TA D
--
-- ▶ OWED, AND DATED: clear those six on 2026-12-11, the day the terms begin — the same act
--   CC_0455 performs for TX-23 and FL-20 on 2027-01-03, and for the same reason. `is_vacant` is
--   a cached boolean and cannot flip itself; the terms do.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- Results basis: every one of the 72 is `result_certainty = 'called'`; none is `certified` yet.
-- LA County certifies 2026-12-01, before all three handover dates, so there is a checkpoint
-- between this file and the first term beginning. The calls themselves were made by the bound
-- (CC_0377's rule: record only what the trailing candidate could not overtake if EVERY
-- uncounted ballot broke their way), which cannot be reversed by a later count.
--
-- Overwrites nothing. Every row is an INSERT of a new `office_terms` row plus, where a
-- predecessor exists, a `term_end` written onto their open-ended term by the helper. No
-- `UPDATE` of any value this file did not first record. No row is deleted.
--
-- @incumbency-decision: no-effect — every term boundary this writes lands on 2026-12-03/04,
-- 2026-12-10/11 or 2026-12-13/14, all AFTER the 2026-11-03 election, so no incumbency flag
-- computed against that election moves. Same disposition and same check as CC_0453.

BEGIN;

-- ─── The selection, derived by query so no name or id is transcribed ───────────────────────

CREATE TEMP TABLE cc0456_seatings (
  office_id       uuid PRIMARY KEY,
  politician_id   uuid NOT NULL,
  seat_date       date NOT NULL,
  kind            text NOT NULL,
  allow_reelect   boolean NOT NULL,
  CONSTRAINT cc0456_kind CHECK (kind IN ('single','at-large-incumbent','at-large-new'))
) ON COMMIT DROP;

WITH sw AS (
  SELECT * FROM essentials.office_swearing_in
   WHERE basis = 'statute'
     AND swearing_in_date BETWEEN DATE '2026-12-01' AND DATE '2026-12-31'
), unseated AS (
  SELECT sw.* FROM sw
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = sw.office_id AND t.term_start = sw.swearing_in_date)
), single AS (
  -- one office, one seat, one winner. 55 rows.
  SELECT u.office_id, rc.politician_id, u.swearing_in_date AS seat_date, 'single'::text AS kind
    FROM unseated u
    JOIN essentials.races r ON r.office_id = u.office_id AND r.seats = 1
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = u.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won'
), alrace AS (
  SELECT g.id AS gov_id, u.swearing_in_date AS seat_date, r.id AS race_id, r.seats
    FROM unseated u
    JOIN essentials.races r ON r.office_id = u.office_id AND r.seats > 1
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = u.election_date
    JOIN essentials.offices o ON o.id = u.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   GROUP BY 1,2,3,4
), al_inc AS (
  -- the winner already sits on this body: they keep their own seat. 14 rows.
  SELECT och.office_id, rc.politician_id, a.seat_date, 'at-large-incumbent'::text AS kind
    FROM alrace a
    JOIN essentials.race_candidates rc ON rc.race_id = a.race_id AND rc.result = 'won'
    JOIN essentials.office_current_holder och ON och.politician_id = rc.politician_id
    JOIN essentials.offices o2 ON o2.id = och.office_id
    JOIN essentials.chambers c2 ON c2.id = o2.chamber_id AND c2.government_id = a.gov_id
), al_new AS (
  -- the three newcomers, pinned to the departing member's seat. Authorities in the header.
  SELECT * FROM (VALUES
    ('2709a8c4-5af1-5dcf-bbe2-bff6032da2fd'::uuid, 'fa96c857-1efa-498a-b582-bd3ba990d36a'::uuid,
     DATE '2026-12-04', 'at-large-new'),   -- Dillon      ← Erickson            (CVWD)
    ('e14ebd74-4cb2-5f6c-86a0-bbb97dc8c8eb'::uuid, '01d5492a-2368-4c61-b1ff-dc44f441f055'::uuid,
     DATE '2026-12-11', 'at-large-new'),   -- Blades-Snell ← Greenstein          (SMCCD)
    ('d1e51625-36c9-4f39-9df0-081774ee00ae'::uuid, '10e74442-b1ee-435c-8ff6-6f260c87dfb5'::uuid,
     DATE '2026-12-11', 'at-large-new')    -- Staenberg   ← Tahvildaran-Jesswein (SMMUSD)
  ) v(office_id, politician_id, seat_date, kind)
)
INSERT INTO cc0456_seatings (office_id, politician_id, seat_date, kind, allow_reelect)
SELECT x.office_id, x.politician_id, x.seat_date, x.kind,
       -- 🔴 PER ROW, NOT TRUE EVERYWHERE. `seat_officeholder` refuses by default when the
       -- person already holds the seat, and that refusal is what guards the seats that CHANGE
       -- HANDS. Setting it true globally would disarm the guard on all 72.
       (och.politician_id IS NOT DISTINCT FROM x.politician_id) AS allow_reelect
  FROM (SELECT * FROM single UNION ALL SELECT * FROM al_inc UNION ALL SELECT * FROM al_new) x
  LEFT JOIN essentials.office_current_holder och ON och.office_id = x.office_id;

-- ─── Pre-flight ────────────────────────────────────────────────────────────────────────────

DO $cc0456$
DECLARE
  n int; bad text; d text;
BEGIN
  -- P1 — the pinned selection. Count AND digest, captured 2026-11-18 against production.
  -- A derivation that drifts (a new result recorded, a seat taken by another session) changes
  -- this and the file refuses rather than silently seating a set nobody reviewed.
  SELECT count(*) INTO n FROM cc0456_seatings;
  IF n <> 72 THEN
    RAISE EXCEPTION 'CC_0456 P1: selection is % rows, expected 72', n;
  END IF;
  SELECT md5(string_agg(office_id::text||'|'||politician_id::text||'|'||seat_date::text, E'\n'
                        ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0456_seatings;
  IF d <> 'f3b904bd9eaa6746194bb8d97ea7fb2d' THEN
    RAISE EXCEPTION 'CC_0456 P1: selection digest is %, expected f3b904bd9eaa6746194bb8d97ea7fb2d', d;
  END IF;

  SELECT count(*) INTO n FROM cc0456_seatings WHERE kind = 'single';
  IF n <> 55 THEN RAISE EXCEPTION 'CC_0456 P1b: % single-seat rows, expected 55', n; END IF;
  SELECT count(*) INTO n FROM cc0456_seatings WHERE kind = 'at-large-incumbent';
  IF n <> 14 THEN RAISE EXCEPTION 'CC_0456 P1b: % at-large incumbents, expected 14', n; END IF;
  SELECT count(*) INTO n FROM cc0456_seatings WHERE kind = 'at-large-new';
  IF n <> 3  THEN RAISE EXCEPTION 'CC_0456 P1b: % at-large newcomers, expected 3', n; END IF;

  -- P2 — every date is one the repo can cite, for THIS office or for this office's body.
  -- A by-area seat carries its own swearing-in row; an at-large seat inherits its body's.
  SELECT string_agg(DISTINCT s.office_id::text, ', ') INTO bad
    FROM cc0456_seatings s
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.office_swearing_in sw
       JOIN essentials.offices o  ON o.id  = sw.office_id
       JOIN essentials.chambers c ON c.id  = o.chamber_id
       JOIN essentials.offices o2 ON o2.id = s.office_id
       JOIN essentials.chambers c2 ON c2.id = o2.chamber_id AND c2.government_id = c.government_id
      WHERE sw.basis = 'statute'
        AND sw.election_date = DATE '2026-11-03'
        AND sw.swearing_in_date = s.seat_date);
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0456 P2: office(s) whose seat date is cited nowhere: %', bad;
  END IF;

  SELECT string_agg(DISTINCT seat_date::text, ', ') INTO d FROM cc0456_seatings;
  IF d <> '2026-12-04, 2026-12-11, 2026-12-14' THEN
    RAISE EXCEPTION 'CC_0456 P2b: seat dates are %, expected the three December handovers', d;
  END IF;

  -- P3 — nobody is already seated at that date on that office. Makes the file idempotent and
  -- refuses to double-seat a board another session reached first.
  SELECT string_agg(s.office_id::text, ', ') INTO bad
    FROM cc0456_seatings s
    JOIN essentials.office_terms t ON t.office_id = s.office_id AND t.term_start = s.seat_date;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0456 P3: already seated at that date: %', bad;
  END IF;

  -- P4 — every winner is a real, active person. An id that resolves to nothing seats nobody
  -- and raises no error.
  SELECT string_agg(s.politician_id::text, ', ') INTO bad
    FROM cc0456_seatings s
    LEFT JOIN essentials.politicians p ON p.id = s.politician_id
   WHERE p.id IS NULL OR p.is_active = false;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0456 P4: winner missing or inactive: %', bad;
  END IF;

  -- P5 — 🔴 THE AT-LARGE PINS, CHECKED AGAINST THE PEOPLE THIS FILE'S HEADER NAMES.
  -- This is the one place a human judgement entered the selection, so it is the one place
  -- production must agree with the source before anything is written. If somebody re-seated or
  -- re-dated one of these three offices since 2026-11-18, the name stops matching and the file
  -- refuses — rather than putting a new member into a seat whose occupant has changed.
  SELECT string_agg(v.who || ' expected on ' || v.office_id::text ||
                    ', found ' || coalesce(p.full_name, '(nobody)'), '; ') INTO bad
    FROM (VALUES
      ('2709a8c4-5af1-5dcf-bbe2-bff6032da2fd'::uuid, 'Kerry D. Erickson'),
      ('e14ebd74-4cb2-5f6c-86a0-bbb97dc8c8eb'::uuid, 'Nancy Greenstein'),
      ('d1e51625-36c9-4f39-9df0-081774ee00ae'::uuid, 'Richard Tahvildaran-Jesswein')
    ) v(office_id, who)
    LEFT JOIN essentials.office_current_holder och ON och.office_id = v.office_id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM v.who;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0456 P5: departing holder does not match the source: %', bad;
  END IF;

  -- P5b — and none of those three departing members won anything in 2026. If one had, this
  -- file would be moving a re-elected member out of their own seat.
  SELECT string_agg(p.full_name, ', ') INTO bad
    FROM cc0456_seatings s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE s.kind = 'at-large-new'
     AND EXISTS (SELECT 1 FROM essentials.race_candidates rc
                   JOIN essentials.races r ON r.id = rc.race_id
                   JOIN essentials.elections e ON e.id = r.election_id
                        AND e.election_date = DATE '2026-11-03'
                  WHERE rc.politician_id = p.id AND rc.result = 'won');
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0456 P5b: a departing at-large holder won in 2026: %', bad;
  END IF;

  -- P6 — `allow_reelect` is true exactly where the person already holds that office, and
  -- nowhere else. Derived, then checked against the view independently of how it was derived.
  SELECT count(*) INTO n
    FROM cc0456_seatings s
    LEFT JOIN essentials.office_current_holder och ON och.office_id = s.office_id
   WHERE s.allow_reelect <> (och.politician_id IS NOT DISTINCT FROM s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0456 P6: % row(s) where allow_reelect disagrees with the current holder', n;
  END IF;
  SELECT count(*) INTO n FROM cc0456_seatings WHERE allow_reelect;
  IF n <> 40 THEN
    RAISE EXCEPTION 'CC_0456 P6b: % re-elections, expected 40', n;
  END IF;

  -- P7 — no office twice and no person twice. A person holding two of these seats would be a
  -- real finding, not something to write through quietly.
  SELECT count(*) INTO n FROM (
    SELECT politician_id FROM cc0456_seatings GROUP BY 1 HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0456 P7: % person(s) appear on more than one seat', n;
  END IF;

  RAISE NOTICE 'CC_0456 pre-flight OK — 72 seatings (55 single, 14 at-large incumbent, 3 at-large new), 40 re-elections';
END
$cc0456$;

-- ─── Capture the pre-state, in this transaction, for the deltas ────────────────────────────

CREATE TEMP TABLE cc0456_before AS
SELECT (SELECT count(*) FROM essentials.office_terms)                      AS terms,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)           AS vacant,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id
         WHERE NOT o.is_vacant)                                            AS unflagged_baseline,
       (SELECT count(*) FROM essentials.office_current_holder
         WHERE politician_id IS NOT NULL)                                  AS held_today;

CREATE TEMP TABLE cc0456_vacant_before AS
SELECT id, is_vacant, vacant_since FROM essentials.offices WHERE is_vacant;

-- ─── Seat ──────────────────────────────────────────────────────────────────────────────────

DO $cc0456$
DECLARE
  r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0456_seatings ORDER BY seat_date, office_id LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id,
      r.politician_id,
      r.seat_date,
      'CC_0456: 2026-11-03 California general, ' ||
        CASE r.kind
          WHEN 'single'             THEN 'by-area seat; date from essentials.office_swearing_in'
          WHEN 'at-large-incumbent' THEN 'at-large board, member keeps the seat they already hold'
          ELSE 'at-large board, seat of the departing member named in the migration header'
        END,
      p_allow_reelection => r.allow_reelect);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'CC_0456 seated % office(s)', n;
END
$cc0456$;

-- ─── Post-verify ───────────────────────────────────────────────────────────────────────────

DO $cc0456$
DECLARE
  n int; bad text; b record;
BEGIN
  SELECT * INTO b FROM cc0456_before;

  -- V1 — exactly 72 new term rows, one per selected office, at the selected date, for the
  -- selected person. Checked row for row, not by a total somebody else can move.
  SELECT count(*) INTO n
    FROM cc0456_seatings s
    JOIN essentials.office_terms t
      ON t.office_id = s.office_id AND t.term_start = s.seat_date
     AND t.politician_id = s.politician_id;
  IF n <> 72 THEN
    RAISE EXCEPTION 'CC_0456 V1: % of 72 seatings landed', n;
  END IF;

  -- V2 — and the table grew by exactly 72. Catches a helper that wrote a row this file did
  -- not ask for.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms + 72 THEN
    RAISE EXCEPTION 'CC_0456 V2: office_terms moved % -> % (delta %), expected +72',
                    b.terms, n, n - b.terms;
  END IF;

  -- V3 — every predecessor closed the day before, and the ones with no predecessor closed
  -- nothing. 🔴 A SEATING THAT CLOSES NO PREDECESSOR TERM IS THE SIGNATURE OF A VACANT SEAT
  -- (CC_0453 found TX-23 and FL-20 exactly this way), so the blank is asserted, not tolerated:
  -- it must be the six flagged-vacant offices and nobody else.
  SELECT count(*) INTO n
    FROM cc0456_seatings s
    JOIN essentials.offices o ON o.id = s.office_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.term_end = s.seat_date - 1);
  IF n <> 6 THEN
    RAISE EXCEPTION 'CC_0456 V3: % seat(s) closed no predecessor, expected exactly 6', n;
  END IF;
  SELECT string_agg(s.office_id::text, ', ') INTO bad
    FROM cc0456_seatings s
    JOIN essentials.offices o ON o.id = s.office_id
   WHERE NOT o.is_vacant
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.term_end = s.seat_date - 1);
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0456 V3b: seat closed no predecessor and is NOT flagged vacant: %', bad;
  END IF;

  -- V4 — nothing was unseated. The helper closes a predecessor at seat_date - 1, which is in
  -- the future, so every person holding office TODAY must still hold it.
  SELECT count(*) INTO n FROM essentials.office_current_holder WHERE politician_id IS NOT NULL;
  IF n <> b.held_today THEN
    RAISE EXCEPTION 'CC_0456 V4: offices held today moved % -> %; a future seating must move nothing today',
                    b.held_today, n;
  END IF;

  -- V5 — 🔴 NOT ONE `is_vacant` FLAG MOVED, in either direction, anywhere in the repo.
  -- This is the gate CC_0434 did not have.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant THEN
    RAISE EXCEPTION 'CC_0456 V5: vacant offices moved % -> %; this file clears no flag', b.vacant, n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0456_vacant_before v
    FULL OUTER JOIN (SELECT id, is_vacant, vacant_since FROM essentials.offices WHERE is_vacant) a
      ON a.id = v.id
   WHERE v.id IS NULL OR a.id IS NULL
      OR a.vacant_since IS DISTINCT FROM v.vacant_since;
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0456 V5b: % office(s) changed is_vacant or vacant_since', n;
  END IF;

  -- V6 — the occupancy drift baseline. Seating moves `total` and `flagged`; the UNFLAGGED
  -- number is the baseline and must not move. 🔴 Never raise it to clear a red.
  SELECT count(*) INTO n
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id
   WHERE NOT o.is_vacant;
  IF n <> b.unflagged_baseline THEN
    RAISE EXCEPTION 'CC_0456 V6: unflagged drift baseline moved % -> %', b.unflagged_baseline, n;
  END IF;
  IF n <> 238 THEN
    RAISE EXCEPTION 'CC_0456 V6b: unflagged drift baseline is %, expected 238', n;
  END IF;

  -- V7 — no office ends up held by two people on any handover day. The exclusion constraint
  -- forbids it, so this asserts the constraint was actually in force rather than trusting it.
  SELECT count(*) INTO n FROM (
    SELECT t.office_id, s.seat_date
      FROM cc0456_seatings s
      JOIN essentials.office_terms t ON t.office_id = s.office_id
     WHERE t.politician_id IS NOT NULL
       AND s.seat_date BETWEEN t.term_start AND coalesce(t.term_end, DATE '9999-12-31')
     GROUP BY 1,2 HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0456 V7: % office(s) resolve to two holders on their handover day', n;
  END IF;

  RAISE NOTICE 'CC_0456 OK — 72 seated, 66 predecessors closed, 6 vacant seats filled, 0 flags touched, baseline 238';
END
$cc0456$;

COMMIT;
