-- CC_0308: close Mark Wallach's Boulder council term and flag the seat vacant.
--
-- WHAT A VOTER SEES TODAY. Essentials answers a Boulder address with nine council members, one of
-- whom resigned on 2026-07-23 and has not held the seat since. `office_terms` carries his term
-- open-ended (`term_end IS NULL`) from 2021-11-16, so `current_office_holders`' date containment
-- still matches it and `office_current_holder` still returns him. Nothing errors. This is the
-- failure mode CLAUDE.md names: the occupancy model is only as honest as the dates written into it.
--
-- WHAT HAPPENED. On 2026-07-23 the Boulder City Council voted 8-1 to let the city pursue Federal
-- Aviation Administration grants for Boulder Municipal Airport. Wallach, who had long argued for
-- redeveloping the airport land as housing, cast the lone "no" and announced his resignation from
-- the dais, effective immediately. He was in his third term, re-elected in 2025.
--
-- 🔴 THIS IS A VACANCY, NOT A SUCCESSION, AND THE CHARTER IS WHY. Because he resigned BEFORE
-- Aug. 1, Boulder's Home Rule Charter holds the seat empty until the next general election rather
-- than letting council appoint a replacement. So the correct write is `vacate_office` — close the
-- term, flag the seat, name the first vacant day — and NOT `seat_officeholder`. The seat is filled
-- at the 2026-11-03 election, which is a separate, later change (see the ▶ note at the end).
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- HOW IT WAS CAUGHT, AND THE RULE IT PAID FOR
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- The detector was the city's own council page, read as RAW BYTES and counted:
--
--     Brockett 3 · Adams 3 · Benjamin 3 · Kaplan 3 · Marquis 3 · Schuchard 3 · Speer 3 · Winer 3
--     Wallach 1
--
-- Eight members appear three times each (nav, member list, profile link). Wallach appears once —
-- and that once is inside the `alt` attribute of `/sites/default/files/2025-12/
-- council-group-photo-outside-2025.png`:
--
--     alt="City Council: Tina Marquis, Matt Benjamin, Rob Kaplan, Tara Winer (Mayor Pro Tem),
--          Aaron Brockett (Mayor), Ryan Schuchard, Taishya Adams, Mark Wallach, and Nicole Speer"
--
-- 🔴 A GROUP-PHOTO CAPTION IS A DATE-STAMPED ROSTER, NOT A CURRENT ONE. It is exactly as old as
-- the photograph — December 2025 — and it outlived the membership list sitting beside it on the
-- same page. A roster scraped from captions would have re-confirmed the stale row.
--
-- ⚠ WEBFETCH COULD NOT SETTLE IT. Asked for the current members, its summary said only that
-- Wallach "does not appear in the Members list" while also naming him from the caption — a
-- genuinely ambiguous answer. The 3-vs-1 count that settled it came from the bytes, and the eight
-- members at 3 each are the positive control proving the count could see names at all.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- WHICH DAY, AND WHY IT IS NOT THE DAY HE RESIGNED
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- `essentials.vacate_office(office_id, p_as_of, ...)` sets `term_end = p_as_of - 1` and
-- `vacant_since = COALESCE(vacant_since, p_as_of)`. `p_as_of` is THE FIRST DAY THE SEAT WAS EMPTY.
-- He resigned effective immediately on 2026-07-23, so that day was still his: p_as_of is
-- 2026-07-24 and the term closes at 2026-07-23. This is the same departure + 1 rule CC_0298
-- established and calibrated against primary records.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- `is_incumbent` IS CLEARED IN THE SAME TRANSACTION
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- CLAUDE.md: `true` when you seat the person, `false` for a candidate or former officeholder. It
-- is a cached flag the incumbents-only reads filter on, and closing a term does not touch it. He
-- is a former officeholder from 2026-07-24, so it is set false here. Leaving it true would keep
-- him in incumbent-filtered reads with no seat — the exact cohort CA_0181-CA_0187 had to clear.
--
-- He is NOT archived and NOT deleted: one row per person, and he may stand again. He holds no
-- `politician_answers` row in any season (measured: 0), so no stance or context is affected.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- WHAT THIS DOES NOT MOVE
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- `essentials.offices_missing_terms` counts offices with NO `office_terms` row at all. This office
-- keeps its row — now closed — so the three-part measurement must come out UNCHANGED at
-- 293 / 55 / 238 (total / flagged / unflagged). The post-verify gate asserts exactly that. A move
-- here would mean the term row was deleted rather than closed.
--
-- Measured on prod immediately before writing this file, 2026-10-28:
--   offices_missing_terms      293 total / 55 flagged / 238 unflagged
--   Boulder seated people      9  (becomes 8)
--   Wallach term rows          1  (stays 1, gains an end date)
--   Wallach politician_answers 0
--
-- ▶ 2026-11-03 / early December 2026: this seat is filled at the general election, together with
--   five other council seats and the mayoralty. Seat the winner with `seat_officeholder` then —
--   it closes nothing here, because this term is already closed. Re-measure the roster first; the
--   December 2025 precedent is that new members are sworn in on 2025-12-04.

BEGIN;

-- ── PRE-FLIGHT ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n int;
  v_office  uuid := '88f4bd55-c862-4b07-84d2-80fe7acd6dae';
  v_person  uuid := 'e9a76fec-9104-484e-bcc6-0e2160315d6f';
BEGIN
  -- (a) The office is the one we think it is: Mark Wallach's Boulder City Council seat.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.chambers c   ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.id = v_office
     AND o.title = 'Council Member'
     AND c.name  = 'Boulder City Council'
     AND g.geo_id = '0807850' AND g.mtfcc = 'G4110';
  IF n <> 1 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: office % is not the Boulder City Council seat (found %)', v_office, n;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                  WHERE id = v_person AND full_name = 'Mark Wallach') THEN
    RAISE EXCEPTION 'PRE-FLIGHT: politician % is not Mark Wallach', v_person;
  END IF;

  -- (b) Exactly one term row, his, still open-ended. If it is already closed, this migration has
  --     run (or someone else closed it) and the act below is a no-op — but the shape must match.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = v_office;
  IF n <> 1 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: expected exactly 1 term row on the seat, found %', n;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_office
                    AND politician_id = v_person
                    AND term_start = DATE '2021-11-16'
                    AND (term_end IS NULL OR term_end = DATE '2026-07-23')) THEN
    RAISE EXCEPTION 'PRE-FLIGHT: the term row is not Wallach''s open-ended 2021-11-16 term';
  END IF;

  -- (c) He must hold no other seat — this closes one term, not a career.
  SELECT count(*) INTO n FROM essentials.office_current_holder WHERE politician_id = v_person;
  IF n > 1 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: Wallach holds % current seats; this migration assumes one', n;
  END IF;

  -- (d) No stance rows ride on this. If this ever fails, STOP: closing a term is fine, but the
  --     answers and their context would need their own decision.
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id = v_person;
  IF n <> 0 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: Wallach now holds % politician_answers row(s); decide what '
                    'happens to them before closing the term', n;
  END IF;

  -- (e) The three-part occupancy measurement, pinned before the act.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> 293 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: offices_missing_terms total is %, expected 293 — re-measure all '
                    'three numbers and update this migration before running it', n;
  END IF;
END $$;

-- ── THE ACT ─────────────────────────────────────────────────────────────────────────────────
-- Idempotent: vacate_office only writes when term_end differs, and COALESCEs vacant_since.
SELECT essentials.vacate_office(
  '88f4bd55-c862-4b07-84d2-80fe7acd6dae'::uuid,
  DATE '2026-07-24',
  'Mark Wallach resigned 2026-07-23, effective immediately, as the lone no vote in an 8-1 vote to '
  'pursue FAA grants for Boulder Municipal Airport; seat held vacant until the 2026-11-03 general '
  'election per the Boulder Home Rule Charter (resignation before Aug. 1). Sources: KUNC '
  '2026-07-29 Boulder news roundup; Axios Boulder 2026-07-24. Absent from the member list at '
  'bouldercolorado.gov/government/city-council, read as raw bytes 2026-10-28 (CC_0308)',
  'resigned'
);

-- Former officeholder: clear the cached incumbency flag. Guarded, so a re-run writes nothing.
UPDATE essentials.politicians
   SET is_incumbent = false
 WHERE id = 'e9a76fec-9104-484e-bcc6-0e2160315d6f'
   AND is_incumbent IS DISTINCT FROM false;

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n int;
  v_office uuid := '88f4bd55-c862-4b07-84d2-80fe7acd6dae';
  v_person uuid := 'e9a76fec-9104-484e-bcc6-0e2160315d6f';
  t_total int; t_flag int; t_unflag int;
BEGIN
  -- (a) The term is closed on the right day, for the right reason, and the citation travelled.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_office
                    AND politician_id = v_person
                    AND term_end = DATE '2026-07-23'
                    AND how_ended = 'resigned'
                    AND source LIKE '%vacated:%CC_0308%') THEN
    RAISE EXCEPTION 'POST-VERIFY: Wallach''s term is not closed at 2026-07-23 with how_ended '
                    '= resigned and the CC_0308 citation';
  END IF;

  -- (b) The seat is flagged, and dated to the first VACANT day — not the day he left.
  IF NOT EXISTS (SELECT 1 FROM essentials.offices
                  WHERE id = v_office AND is_vacant AND vacant_since = DATE '2026-07-24') THEN
    RAISE EXCEPTION 'POST-VERIFY: the seat is not flagged vacant since 2026-07-24';
  END IF;

  -- (c) The read path agrees: the seat now returns no holder, by date containment.
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder
              WHERE office_id = v_office AND politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'POST-VERIFY: office_current_holder still returns a holder for the seat';
  END IF;

  -- (d) Boulder seats eight people, not nine. Counted as CLAUDE.md requires — on
  --     och.politician_id, never count(*), because this view LEFT JOINs from offices and a
  --     vacancy is a NULL that would pass a count(*) check vacuously.
  SELECT count(DISTINCT och.politician_id) INTO n
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = 'd5a4026b-7218-4337-9a47-291633e554b6'
     AND och.politician_id IS NOT NULL;
  IF n <> 8 THEN
    RAISE EXCEPTION 'POST-VERIFY: Boulder seats % people, expected 8', n;
  END IF;

  -- (e) He is no longer a cached incumbent, and he still exists.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                  WHERE id = v_person AND is_incumbent = false) THEN
    RAISE EXCEPTION 'POST-VERIFY: Wallach is still flagged is_incumbent, or the row is gone';
  END IF;

  -- (f) The term row was CLOSED, not deleted. If it had been deleted the office would fall into
  --     offices_missing_terms and the three-part measurement would move.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = v_office;
  IF n <> 1 THEN
    RAISE EXCEPTION 'POST-VERIFY: the seat now has % term rows, expected 1', n;
  END IF;

  SELECT count(*),
         count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE NOT o.is_vacant)
    INTO t_total, t_flag, t_unflag
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF (t_total, t_flag, t_unflag) IS DISTINCT FROM (293, 55, 238) THEN
    RAISE EXCEPTION 'POST-VERIFY: offices_missing_terms moved to % / % / %, expected 293 / 55 / 238',
      t_total, t_flag, t_unflag;
  END IF;

  RAISE NOTICE 'CC_0308 OK: Boulder council seat vacated 2026-07-24 (Wallach term closed '
               '2026-07-23, resigned); Boulder seats 8; offices_missing_terms % / % / % unchanged',
    t_total, t_flag, t_unflag;
END $$;

COMMIT;
