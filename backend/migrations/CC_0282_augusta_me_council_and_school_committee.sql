-- CC_0282_augusta_me_council_and_school_committee.sql
--
-- Seats all 18 elected offices of the City of Augusta, Maine, and clears the `is_vacant` flag on
-- exactly the seats it fills. **This is the pattern-setter for the other 16 Maine cities.**
--
--   people created 18 · terms 18 · is_vacant cleared 18 · offices created 0
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ 🔴🔴 WHY SEAT AND UN-FLAG IN THE SAME MIGRATION ═══
-- Every one of Augusta's 18 offices already existed, flagged `is_vacant = true` with a NULL
-- `vacant_since` and no `office_terms` row. That is not 18 vacancies — it is "we have not seeded a
-- holder" wearing "this seat is empty"'s clothes. The same shape covers **all 17 Maine cities,
-- 138 offices, 100% of them**.
--
-- Neither half of the obvious two-step is safe on its own:
--
-- 🔴 **CLEARING THE FLAG FIRST BREAKS CI.** `check-address-reachability.mjs` classifies
-- `DEAD_GEOGRAPHY` as *"district has a guard-satisfying polygon and offices, but no active holder
-- and is NOT flagged vacant"*, and it fires on **any new bucket**. Un-flagging an unseated Augusta
-- would create a new `me|LOCAL` bucket. That gate runs on **master-push and cron, not PRs**, so it
-- reddens on the next merge and blames an innocent PR.
--
-- 🔴 **SEATING WITHOUT CLEARING LEAVES THE OTHER LANDMINE.** Nothing clears `is_vacant` when you
-- seat someone: there is **no trigger on `offices` or `office_terms` at all** (checked), and
-- `seat_officeholder`'s body never touches the column — only `vacate_office` sets it, and nothing
-- unsets it. A seated office still flagged vacant is exactly CLAUDE.md's `is_vacant` trap, which
-- emits a spurious all-NULL office row for that holder.
-- 🟢 Measured before this migration: **ZERO offices anywhere are seated-and-flagged.** The
-- invariant is clean, and a careless Maine wave would be the first thing to break it. A gate below
-- asserts it is still zero afterwards.
--
-- ▶ So: seat, and clear the flag on the seats actually filled, in one transaction. No window
-- exists in which an office is unflagged-and-unseated.
--
-- ═══ WHAT THIS DOES TO THE BASELINE ═══
-- `offices_missing_terms` is `total / flagged / unflagged`, and only **unflagged** is the baseline
-- (CLAUDE.md). These 18 were FLAGGED, so they were never in the 239.
--   before  433 / 194 / 239      after  415 / 176 / 239
-- 🟢 **Unflagged is unchanged at 239 and must be** — a gate asserts it. The total falls by 18.
-- That is the shape every Maine city should produce: total down, unflagged untouched.
--
-- ═══ THE ROSTERS, FROM EACH BODY'S OWN PAGE ═══
-- CITY COUNCIL — augustamaine.gov/182/City-Council, read 2026-10-21. Nine members "including the
-- Mayor", per the city's own overview text.
--   Mayor                  Mark O'Brien
--   Ward 1                 Robert Eric Austin        Ward 2   Kevin Judkins
--   Ward 3                 Michael Michaud           Ward 4   Eric Lind
--   At-Large               Courtney Gary-Allen · Annalee Morris-Polley ·
--                          Stephanie Sienkiewicz · Joshua Lilley
-- BOARD OF EDUCATION — augustaschools.org Board of Education page, read 2026-10-21.
--   Chair                  Martha Witham             (term expires 12/31/2026)
--   Ward 1                 Samuel Baker      (2028)  Ward 2   Susan Parks       (2026)
--   Ward 3                 James Orr         (2027)  Ward 4   Bobby Jo Bechard  (2028)
--   At Large               Jonathan Reynolds (2027) · Gabrielle Bérubé Pierce (2027) ·
--                          Rita Pello        (2028) · Charles Hicks            (2026)
--
-- 🟢 **THE SCHOOL BOARD CHAIR IS A REAL, SEPARATELY ELECTED SEAT HERE — NOT A ROTATING ROLE.**
-- The house rule is that a rotating role (vice chair, mayor pro tem) is a parenthetical on a seat
-- title and never its own office, and that rule would have had me delete this office. It does not
-- apply: the board's own page lists the Chair as a ninth row with **her own term expiry** and no
-- ward or at-large label, alongside 4 ward + 4 at-large seats. Augusta elects its school board
-- chair citywide. **Checking stopped a correct general rule from doing damage to a specific city.**
--
-- 🟢 CORROBORATED BY A CERTIFIED RETURN. The City Clerk's signed "RETURN OF VOTES CAST, MUNICIPAL
-- ELECTION - 11/4/2025" elects Lilley and Sienkiewicz (Council At-Large), Michaud (Council Ward 3),
-- Pello and Smith (Board At-Large), Baker (Board Ward 1) and Bechard (Board Ward 4) — every one of
-- them on the rosters above, in the seat the roster gives them. ⚠ Kelly Smith won a Board At-Large
-- seat in that return and is NOT on the board's current page; Charles Hicks and Gabrielle Bérubé
-- Pierce are. The rosters are current and the return is history — this migration follows the
-- rosters.
--
-- ═══ 🔴 DATES: ALL EIGHTEEN ARE 'unknown', ON PURPOSE ═══
-- `term_start` is the start of CONTINUOUS OCCUPANCY, so only a FIRST win dates anyone. The 2025
-- return carries **no incumbency markers at all**, so it cannot distinguish a first win from a
-- re-election, and the memory rule is explicit: a document must be controlled for the marker
-- before its absence on a name means anything. Walking back through Augusta's earlier returns
-- until each name disappears would date them — and multiplied by 17 cities that is ~85 documents.
-- ▶ **Deliberate trade for the pattern: seat now with `start_precision => 'unknown'`, date later.**
-- The holder is what makes the office visible at all; the date is a refinement. CLAUDE.md
-- sanctions exactly this, and the returns are online and named in ROSTERS.md for a dating pass.
--
-- 🔴 **THE PUBLISHED "Term Expires" DATES ARE NOT WRITTEN TO `term_end`, AND MUST NOT BE.**
-- The board publishes an expiry for all nine of its seats, and writing it would look like free
-- data. In this schema a re-election never opens a new `office_terms` row, so `term_end` is the
-- end of the person's OCCUPANCY, not of their current term. Writing 2026-12-31 for Witham, Parks
-- and Hicks would **silently un-seat three sitting officials on 1 January 2027** — the view would
-- simply stop returning them, with nothing erroring. The expiries are recorded in ROSTERS.md as a
-- re-check schedule instead.
--
-- ⚠ THE AT-LARGE SEAT NUMBERS ARE OURS, NOT AUGUSTA'S. Neither body numbers its at-large seats;
-- our schema has `At-Large 1..4`. Assignment follows each body's own listed order and carries no
-- meaning — all four at-large members represent the whole city identically. Do not read
-- `At-Large 2` as a fact about anyone.
--
-- ⚠ AND ONE THING THIS MIGRATION DOES NOT FIX: all nine council seats and all nine school seats
-- hang off ONE citywide district, so an Augusta address returns all 18 — including the three ward
-- councillors a given voter does NOT elect. Augusta's ward seats are ward-elected. That is a
-- pre-existing modelling question (the same one El Paso raises from the other direction) and
-- restructuring it is not this migration's job. Recorded in ROSTERS.md.
--
-- ⚠ Jared Mills is Augusta's City Manager and Aahana Bhatt its student representative. Neither is
-- an elected public office; neither gets a row.
--
-- Safe to re-run: every insert is guarded and the flag clear is idempotent.

BEGIN;

CREATE TEMP TABLE _roster (
  office_id     uuid NOT NULL,
  seat          text NOT NULL,
  full_name     text NOT NULL,
  first_name    text NOT NULL,
  last_name     text NOT NULL,
  src           text NOT NULL,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO _roster (office_id, seat, full_name, first_name, last_name, src) VALUES
-- ── City Council (augustamaine.gov/182/City-Council, read 2026-10-21) ──
('8a371b13-c305-48f5-baa6-cc0bc83ecb1d','Mayor','Mark O''Brien','Mark','O''Brien','augustamaine.gov/182/City-Council, read 2026-10-21 (CC_0282)'),
('5d6f58f5-3faa-4eed-8a23-6b858082496f','Council Ward 1','Robert Eric Austin','Robert Eric','Austin','augustamaine.gov/182/City-Council, read 2026-10-21 (CC_0282)'),
('13c5f64e-6b76-45ed-bf94-7054f31f6646','Council Ward 2','Kevin Judkins','Kevin','Judkins','augustamaine.gov/182/City-Council, read 2026-10-21 (CC_0282)'),
('b584e6fb-d47e-4ea2-bacd-9e1774eac88a','Council Ward 3','Michael Michaud','Michael','Michaud','augustamaine.gov/182/City-Council, read 2026-10-21; elected per the City Clerk''s certified Return of Votes Cast, Municipal Election 11/4/2025 (CC_0282)'),
('04f7bb73-af93-4c55-8259-5c39dd404384','Council Ward 4','Eric Lind','Eric','Lind','augustamaine.gov/182/City-Council, read 2026-10-21 (CC_0282)'),
('32d88f9d-4172-40dc-9fa6-2d25edc21159','Council At-Large 1','Courtney Gary-Allen','Courtney','Gary-Allen','augustamaine.gov/182/City-Council, read 2026-10-21; at-large seat number is ours, assigned in the city''s listed order (CC_0282)'),
('e75c6e63-9659-4edc-9bbc-cdb059f912d7','Council At-Large 2','Annalee Morris-Polley','Annalee','Morris-Polley','augustamaine.gov/182/City-Council, read 2026-10-21; at-large seat number is ours, assigned in the city''s listed order (CC_0282)'),
('0729a7c6-3580-4640-bb14-54b4d0071c27','Council At-Large 3','Stephanie Sienkiewicz','Stephanie','Sienkiewicz','augustamaine.gov/182/City-Council, read 2026-10-21 (the certified 11/4/2025 return spells her Stephanie-Ann); at-large seat number is ours (CC_0282)'),
('92ebcb7d-34a5-4aac-b11d-92cdcee27d75','Council At-Large 4','Joshua Lilley','Joshua','Lilley','augustamaine.gov/182/City-Council, read 2026-10-21; elected per the certified Return of Votes Cast, Municipal Election 11/4/2025; at-large seat number is ours (CC_0282)'),
-- ── Board of Education (augustaschools.org Board of Education page, read 2026-10-21) ──
('19fc2b5d-8e16-4556-87fb-7c41d255e95c','School Chair','Martha Witham','Martha','Witham','augustaschools.org Board of Education, read 2026-10-21; listed as the Chair seat with its own term expiry, not a rotating role (CC_0282)'),
('204a5bd2-824b-4c21-bc91-7441fca82f7d','School Ward 1','Samuel Baker','Samuel','Baker','augustaschools.org Board of Education, read 2026-10-21; elected per the certified Return of Votes Cast, Municipal Election 11/4/2025 (CC_0282)'),
('b2a3f1ee-f8e0-4288-9192-3e1ee794cdfb','School Ward 2','Susan Parks','Susan','Parks','augustaschools.org Board of Education, read 2026-10-21 (CC_0282)'),
('178356ab-deab-4a59-bae8-0eeeb71d6e9a','School Ward 3','James Orr','James','Orr','augustaschools.org Board of Education, read 2026-10-21 (CC_0282)'),
('0eafec3a-197c-4077-ab7f-cf0f5485f27e','School Ward 4','Bobby Jo Bechard','Bobby Jo','Bechard','augustaschools.org Board of Education, read 2026-10-21; elected per the certified Return of Votes Cast, Municipal Election 11/4/2025 (CC_0282)'),
('81e8321e-f194-4e4d-9d38-c2cbb7e84d27','School At-Large 1','Jonathan Reynolds','Jonathan','Reynolds','augustaschools.org Board of Education, read 2026-10-21; at-large seat number is ours, assigned in the board''s listed order (CC_0282)'),
('7919d61f-4830-4d7d-a017-f8fa42740373','School At-Large 2','Gabrielle Bérubé Pierce','Gabrielle Bérubé','Pierce','augustaschools.org Board of Education, read 2026-10-21; at-large seat number is ours (CC_0282)'),
('8d588d59-d9ca-425b-bbc1-bf533f41c42e','School At-Large 3','Rita Pello','Rita','Pello','augustaschools.org Board of Education, read 2026-10-21; elected per the certified Return of Votes Cast, Municipal Election 11/4/2025; at-large seat number is ours (CC_0282)'),
('3182b209-4812-4540-af46-0b9338254b0e','School At-Large 4','Charles Hicks','Charles','Hicks','augustaschools.org Board of Education, read 2026-10-21; at-large seat number is ours (CC_0282)');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _roster;
  IF n <> 18 THEN RAISE EXCEPTION 'CC_0282: expected 18 roster rows, found %', n; END IF;

  -- every office id must exist, belong to Augusta, be flagged vacant and carry NO term
  SELECT count(*) INTO bad FROM _roster r
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.offices o
       JOIN essentials.chambers c ON c.id = o.chamber_id
       JOIN essentials.governments g ON g.id = c.government_id
      WHERE o.id = r.office_id AND g.name = 'City of Augusta, Maine, US');
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0282: % office id(s) are not Augusta offices', bad; END IF;

  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.offices o ON o.id = r.office_id WHERE NOT o.is_vacant;
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0282: % Augusta office(s) are already unflagged - an unflagged, unseated '
                    'office is a DEAD_GEOGRAPHY bucket. Investigate before seating', bad;
  END IF;

  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0282: % Augusta office(s) already carry a term', bad; END IF;

  -- Augusta must have exactly these 18 offices: nothing seeded here is missed, nothing invented
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Augusta, Maine, US';
  IF n <> 18 THEN
    RAISE EXCEPTION 'CC_0282: Augusta holds % offices, expected 18 - the structure moved', n;
  END IF;

  -- 🔴 no name may collide with an existing person on the duplicate guard's own key
  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
                    AND lower(btrim(p.last_name))  = lower(btrim(r.last_name)));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0282: % name(s) collide with an existing person - the dedupe pass measured '
                    'ZERO against controls that fired. REFUSING', bad;
  END IF;

  -- and the batch must not repeat a name against itself (CC_0278's lesson)
  SELECT count(*) INTO bad FROM (
    SELECT full_name FROM _roster GROUP BY full_name HAVING count(*) > 1) q;
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0282: % name(s) repeated within the batch', bad; END IF;
END $$;

-- ─── People ──────────────────────────────────────────────────────────────────────────────
-- 🔴 is_incumbent TRUE: they hold the seat. It is a cached flag the incumbents-only reads filter
-- on, it defaults to false since CA_0188, and `seat_officeholder` never sets it.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.src FROM _roster r;

UPDATE _roster r SET politician_id = p.id
FROM essentials.politicians p
WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
  AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
  AND p.is_active;

-- ─── Seat them ───────────────────────────────────────────────────────────────────────────
-- `seat_officeholder` REFUSES a NULL term_start by design, so an 'unknown' open-ended term uses
-- its own column list verbatim. Safe here: no office has a predecessor to close.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT r.office_id, r.politician_id, NULL, 'unknown', 'unknown', r.src
FROM _roster r
WHERE r.politician_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);

-- ─── 🔴 Clear the flag on exactly the seats filled, in the same transaction ───────────────
UPDATE essentials.offices o
   SET is_vacant = false, vacant_since = NULL
FROM _roster r
WHERE o.id = r.office_id AND o.is_vacant;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int;
BEGIN
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id AND t.politician_id = r.politician_id;
  IF n <> 18 THEN RAISE EXCEPTION 'CC_0282: expected 18 terms, found %', n; END IF;

  SELECT count(*) INTO bad FROM _roster r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0282: % seated person(s) are not active incumbents', bad; END IF;

  -- no Augusta office is still flagged, and none is unflagged-and-unseated
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Augusta, Maine, US' AND o.is_vacant;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0282: % Augusta office(s) are still flagged vacant', bad; END IF;

  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Augusta, Maine, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0282: % Augusta office(s) are unflagged AND unseated - that is a new '
                    'me|LOCAL DEAD_GEOGRAPHY bucket and will redden the reachability gate', bad;
  END IF;

  -- 🔴 THE GLOBAL INVARIANT: nobody anywhere is seated AND flagged vacant. Measured zero before.
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0282: % office(s) are seated AND flagged vacant - the is_vacant trap', bad;
  END IF;

  -- 🔴 THE BASELINE: unflagged must be untouched at 239; total must fall by exactly 18.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*)
    INTO v_unflagged, v_total
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0282: unflagged offices_missing_terms is %, expected the 239 baseline - '
                    'this migration must not move it', v_unflagged;
  END IF;
  IF v_total <> 415 THEN
    RAISE EXCEPTION 'CC_0282: total offices_missing_terms is %, expected 433 - 18 = 415', v_total;
  END IF;

  RAISE NOTICE 'CC_0282 OK - Augusta 18 seated, 18 unflagged; missing_terms 415/176/239';
END $$;

DROP TABLE _roster;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE FOR THE REMAINING 16 MAINE CITIES: SEAT AND UN-FLAG TOGETHER, NEVER SEPARATELY.
-- Clearing the flag first creates a DEAD_GEOGRAPHY bucket and reddens a master-only gate that
-- blames the next innocent PR. Seating without clearing leaves a seated-and-flagged office, which
-- is the is_vacant trap. One transaction does both, and the two gates above — "none still flagged"
-- and "none unflagged and unseated" — are what prove it.
-- 🟢 AND THE BASELINE IS THE TELL: a correct Maine city moves `offices_missing_terms` TOTAL down by
-- its office count and leaves UNFLAGGED at 239. If unflagged moves, the migration is wrong.
-- ───────────────────────────────────────────────────────────────────────────────────────────
