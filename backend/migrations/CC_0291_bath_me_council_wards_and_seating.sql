-- CC_0291_bath_me_council_wards_and_seating.sql
-- Bath, Maine — city 3 of 17 in the Maine municipal skeleton (see
-- backend/data/seed-me-municipal-2026/ROSTERS.md). 9 offices, all flagged `is_vacant = true`
-- with a NULL `vacant_since` and no `office_terms` row.
--
-- ═══ 🔴 BATH IS NOT A PLAIN SEATING JOB: SEVEN OF ITS NINE SEATS ARE MIS-TITLED ═══
--
-- Our schema holds nine offices named `Council Member (At-Large 1..9)` on one citywide
-- district. The City of Bath's own council page says, in its own words:
--
--     "The Bath City Council is composed of nine members, one member from each of the
--      City's seven wards and two at-large members. Councilors serve three-year terms."
--
-- So seven of those nine are WARD seats, and we have been telling a Bath voter they elect all
-- nine at large. ROSTERS.md R6 says at-large seat numbers are ours and carry no meaning — that
-- rule is sound, and it does not apply here, because these are not at-large seats. R5 says to
-- check each city before applying a general rule, and this is what that check is for.
--
-- 🟢 THE FIX IS A RETITLE, NOT A REMODEL, AND IT NEEDS NO NEW RULING. Four Maine cities already
-- carry ward titles on one citywide district exactly this way — Belfast (5), Hallowell (4),
-- Saco (7) and Waterville (7). Bath joins them. The seats still hang off the single citywide
-- polygon, so R7 (an address returning every seat, including wards that voter does not elect)
-- is UNCHANGED and still owed a Maine-wide decision. This migration deliberately does not
-- touch it; it only stops the titles from asserting something false.
--
-- ═══ 🔴 TWO COUNCILLORS ARE LISTED BY THEIR ROTATING ROLE, NOT THEIR WARD ═══
--
-- The council page labels Roo Dunn "City Council Chairperson" and Caitlin McCorkle "City
-- Council Vice Chair", with no ward shown for either. Wards 4 and 6 appear nowhere on the page.
-- 🔴 Seating from the visible labels would have created a `Chairperson` office and a `Vice
-- Chair` office and left two real ward seats empty — R5's rotating-role trap in a new disguise.
--
-- 🟢 WHAT RESOLVES IT IS THE CITY'S OWN EMAIL ADDRESSES, published beside each name:
--     Dunn      ward4@cityofbathmaine.gov      -> Ward 4
--     McCorkle  ward6@cityofbathmaine.gov      -> Ward 6
-- and the same source numbers the two at-large seats, which R6 says we would otherwise have to
-- assign arbitrarily:
--     Ambrosino        atlarge1@cityofbathmaine.gov  -> At-Large 1
--     Mansfield-Pryor  atlarge2@cityofbathmaine.gov  -> At-Large 2
-- ▶ For Bath the at-large numbers are the CITY'S, not ours. Do not "correct" them.
--
-- ═══ 🟢 BATH CORRECTLY HAS NO MAYOR, AND THE SCHEMA WAS ALREADY RIGHT ═══
-- Bath is a council–manager city: the council is the legislature, a City Manager runs the
-- administration, and the Chairperson is chosen from among the councillors. There is no mayoral
-- office to create. ⚠ Nine of the other fourteen queued cities DO hold a `Mayor` office, so the
-- absence here is a fact about Bath, checked, not an omission. Gated below.
--
-- ═══ DATES: ALL NINE UNKNOWN, AND THE PAGE OFFERS NOTHING TO MISREAD ═══
-- R4. `term_start` is the start of CONTINUOUS occupancy, and a re-election never opens a new
-- `office_terms` row. Bath's council page publishes no dates at all beyond "Councilors serve
-- three-year terms", so unlike Westbrook there is not even a tempting "Date Elected" column
-- here. All nine get `start_precision => 'unknown'`, `how_started => 'unknown'`, as Augusta's
-- 18 did. No seat is dated, and the gate below refuses any that is.
--
-- ⚠ A Maine municipal election falls on 2026-11-03, nine days after this is written, and Bath
-- councillors serve three-year staggered terms. Some of these nine will change. That is not a
-- reason to wait: the alternative is to keep asserting to every Bath voter that all nine seats
-- are EMPTY, which is false today and will still be false in December. A re-check is recorded
-- in ROSTERS.md.
--
-- ═══ DEDUPE ═══
-- Run against (first_name, last_name) AND against an exact full_name match — the guard's own key
-- plus the blindness where an identical full_name is split differently. Zero hits for all nine;
-- every surname match was a different person (Sandy Marks, Susan M. Lynn, Kathryn Dunn, …).
-- 🔴 That "nothing found" was CONTROLLED: the identical predicate run over three names known to
-- be present returned Martha Witham 1, Jennifer Munro 2, Emanuel Cleaver 1. The detector
-- discriminates, so the zero means something.
--
-- SOURCE: https://www.cityofbathmaine.gov/Government/City-Council, read 2026-10-25.
-- ⚠ The site answers HTTP 403 to curl even with a browser user-agent; it was read in Playwright.
-- Names and ward assignments come from the rendered page text, never from a search summary.

BEGIN;

CREATE TEMP TABLE _roster (
  seat        text PRIMARY KEY,
  office_id   uuid NOT NULL,
  new_title   text NOT NULL,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  note        text,
  politician_id uuid
) ON COMMIT DROP;

-- office_id is pinned by UUID, not by title: the retitle below renumbers two of the at-large
-- seats, so matching on the OLD title would be order-dependent.
INSERT INTO _roster (seat, office_id, new_title, full_name, first_name, last_name, note) VALUES
  ('Ward 1',    'bb01b2af-9c5d-4441-a2f2-fba8937c1d35', 'Council Member (Ward 1)',    'Chris Marks',           'Chris',  'Marks',           NULL),
  ('Ward 2',    'fb9a0455-c806-4615-ae77-f99ecae63292', 'Council Member (Ward 2)',    'Jean Guzzetti',         'Jean',   'Guzzetti',        NULL),
  ('Ward 3',    '7931f6de-4302-4a3e-b53d-649c80edff4e', 'Council Member (Ward 3)',    'Jane Nordmann',         'Jane',   'Nordmann',        NULL),
  ('Ward 4',    'addbdd2b-19ed-4783-8808-3cbbf337654e', 'Council Member (Ward 4)',    'Roo Dunn',              'Roo',    'Dunn',            'City Council Chairperson - a ROTATING ROLE, not a seat; ward from ward4@cityofbathmaine.gov'),
  ('Ward 5',    '8f32e1b7-7915-4a3b-a66f-339871c8d8a8', 'Council Member (Ward 5)',    'Jennifer DeChant',      'Jennifer','DeChant',        NULL),
  ('Ward 6',    'e29d2512-0b43-4bef-a59e-bd0678cfff60', 'Council Member (Ward 6)',    'Caitlin McCorkle',      'Caitlin','McCorkle',        'City Council Vice Chair - a ROTATING ROLE, not a seat; ward from ward6@cityofbathmaine.gov'),
  ('Ward 7',    '8e26431b-0dfb-48ad-8f31-0ce182e8d928', 'Council Member (Ward 7)',    'Leiha Lynn',            'Leiha',  'Lynn',            NULL),
  ('At-Large 1','5a11ef00-91d9-41a1-bfc0-10481abd5ab6', 'Council Member (At-Large 1)','Julie Ambrosino',       'Julie',  'Ambrosino',       'at-large number is the CITY''S, from atlarge1@cityofbathmaine.gov'),
  ('At-Large 2','0aeb0418-5819-42d8-ad4d-26779bd3fa4c', 'Council Member (At-Large 2)','Megan Mansfield-Pryor', 'Megan',  'Mansfield-Pryor', 'at-large number is the CITY''S, from atlarge2@cityofbathmaine.gov');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int;
BEGIN
  -- every office_id must exist, belong to Bath's City Council, and be one of exactly 9
  SELECT count(*) INTO n
    FROM _roster r
    JOIN essentials.offices o     ON o.id = r.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US' AND c.name = 'City Council';
  IF n <> 9 THEN RAISE EXCEPTION 'CC_0291: % of 9 roster office_ids resolve to Bath City Council', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US';
  IF n <> 9 THEN RAISE EXCEPTION 'CC_0291: Bath holds % offices, expected 9', n; END IF;

  -- 🔴 Bath is council-manager: no mayoral office should exist, and we must not create one.
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US' AND o.title ILIKE '%mayor%';
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0291: Bath holds % mayoral office(s) - Bath has a City Manager and a '
                    'council-elected Chairperson. Re-read the city charter before proceeding', bad;
  END IF;

  -- nothing may already be seated
  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0291: % Bath office(s) already carry a term', bad; END IF;

  -- the skeleton signature: all 9 flagged, none dated
  SELECT count(*) INTO bad FROM _roster r JOIN essentials.offices o ON o.id = r.office_id
   WHERE NOT (o.is_vacant AND o.vacant_since IS NULL);
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0291: % Bath office(s) are not flagged-without-a-date - this is not the '
                    'Maine skeleton shape, read the row before seating', bad;
  END IF;
END $$;

-- ─── 🔴 Retitle: seven ward seats stop calling themselves at-large ───────────────────────
UPDATE essentials.offices o
   SET title = r.new_title
  FROM _roster r
 WHERE o.id = r.office_id AND o.title IS DISTINCT FROM r.new_title;

-- ─── People ──────────────────────────────────────────────────────────────────────────────
-- 🔴 is_incumbent EXPLICITLY true: it defaults to false, and a seated person inserted without
-- it is hidden from address search (CLAUDE.md).
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true,
       'City of Bath, Maine official council roster, cityofbathmaine.gov/Government/City-Council, '
       || 'read 2026-10-25 (CC_0291). Ward assignment for the Chair and Vice Chair taken from the '
       || 'city''s published per-ward email addresses, which the page shows in place of their ward.'
  FROM _roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

UPDATE _roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.is_active;

-- ─── Seat them ───────────────────────────────────────────────────────────────────────────
-- All nine are unknown-start, so none can go through `seat_officeholder` — it refuses a NULL
-- term_start by design. Safe here only because no seat has a predecessor to close.
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY seat LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0291: % did not resolve to a person', r.seat;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id) THEN
      INSERT INTO essentials.office_terms
        (office_id, politician_id, term_start, start_precision, how_started, source)
      VALUES (r.office_id, r.politician_id, NULL, 'unknown', 'unknown',
              'City of Bath, Maine official council roster, read 2026-10-25 (CC_0291); '
              || 'start_precision unknown - the city publishes no election dates, and a '
              || 're-election would not open a new term row in any case');
    END IF;
    n := n + 1;
  END LOOP;
  IF n <> 9 THEN RAISE EXCEPTION 'CC_0291: expected 9 seatings, got %', n; END IF;
END $$;

-- ─── 🔴 Clear the flag on exactly the seats filled, in the SAME transaction (R2) ─────────
UPDATE essentials.offices o SET is_vacant = false, vacant_since = NULL
  FROM _roster r WHERE o.id = r.office_id AND o.is_vacant;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int; v_titles text;
BEGIN
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id AND t.politician_id = r.politician_id;
  IF n <> 9 THEN RAISE EXCEPTION 'CC_0291: expected 9 terms, found %', n; END IF;

  -- the retitle landed, and Bath now reads 7 wards + 2 at-large like the city describes itself
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US' AND o.title ~ 'Ward [1-7]\)$';
  IF n <> 7 THEN RAISE EXCEPTION 'CC_0291: expected 7 Bath ward seats after the retitle, found %', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US' AND o.title ~ 'At-Large [12]\)$';
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0291: expected 2 Bath at-large seats after the retitle, found %', n; END IF;

  -- 🔴 no rotating role became an office
  SELECT string_agg(o.title, ', ') INTO v_titles FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US'
     AND (o.title ILIKE '%chair%' OR o.title ILIKE '%mayor%' OR o.title ILIKE '%president%');
  IF v_titles IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0291: a rotating role was made into a seat: %', v_titles;
  END IF;

  SELECT count(*) INTO bad FROM _roster r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0291: % seated person(s) are not active incumbents', bad; END IF;

  -- no seat may be dated: every Bath start is unknown
  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id
   WHERE t.term_start IS NOT NULL OR t.start_precision <> 'unknown';
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0291: % Bath term(s) carry a date - the city publishes none, so a date '
                    'here came from somewhere that cannot establish continuous occupancy', bad;
  END IF;

  -- R2 gate 1: nothing in Bath still flagged
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US' AND o.is_vacant;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0291: % Bath office(s) are still flagged vacant', bad; END IF;

  -- R2 gate 2: nothing in Bath unflagged-and-unseated (a new me|LOCAL DEAD_GEOGRAPHY bucket)
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Bath, Maine, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0291: % Bath office(s) are unflagged AND unseated - a new me|LOCAL '
                    'DEAD_GEOGRAPHY bucket that will redden the reachability gate', bad;
  END IF;

  -- the global invariant: zero seated-and-flagged, repo-wide
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0291: % office(s) are seated AND flagged - the is_vacant trap', bad; END IF;

  -- R3: total falls by 9, unflagged does NOT move
  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*) INTO v_unflagged, v_total
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0291: unflagged offices_missing_terms is %, expected the 239 baseline', v_unflagged;
  END IF;
  IF v_total <> 391 THEN
    RAISE EXCEPTION 'CC_0291: total offices_missing_terms is %, expected 400 - 9 = 391', v_total;
  END IF;

  RAISE NOTICE 'CC_0291 OK - Bath 9 seated and unflagged, 7 wards + 2 at-large; missing_terms 391/152/239';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS CITY ADDS: THE OFFICE TITLES THEMSELVES CAN BE THE DEFECT, AND THE SEATING
-- PASS IS WHERE YOU FIND OUT.
-- Bath's nine seats were all named "At-Large" and seven of them are ward seats. Nothing would
-- ever have caught that: every count was right, the chamber was right, the district was right,
-- and reachability does not read a title. It surfaced only because seating a city forces you to
-- read the council's own page and match a person to a seat.
-- ▶ Nine more queued Maine cities are modelled as all-at-large (Brewer, Calais, Caribou,
--   Eastport, Ellsworth, Old Town, Presque Isle, Rockland, Sanford). COUNT THE WARDS ON EACH
--   CITY'S OWN PAGE BEFORE SEATING IT. Bath proves that check is load-bearing, not ceremony.
-- 🔴 And when a councillor is listed by a rotating role instead of a seat, the per-seat contact
--   address is what tells you which seat they actually hold.
-- ───────────────────────────────────────────────────────────────────────────────────────────
