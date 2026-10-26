-- CA_0324_torrance_council_2026_turnover.sql
--
-- Torrance (LA County, geo_id 0680000) — the June 2, 2026 election and the District 4
-- appointment that followed it. Fixes EmpoweredVote/ev-accounts#1090.
--
-- The ev-qa self-check found Jon Kaji still seated on the council. He is not the only stale
-- row: four of our seven Torrance seats name the wrong person.
--
-- ── WHAT IS WRONG ────────────────────────────────────────────────────────────────────────
--
--   seat         we hold            the city lists (T1)    what happened
--   Mayor        George Chen        Sharon Kalani          Chen left office 2026-07-14 (T2)
--   District 1   Jon Kaji           David Kartsonis        Kartsonis beat Kaji on 2026-06-02 (T2, T3)
--   District 2   Bridgett Lewis     Bridgett Lewis         unchanged
--   District 3   Asam Sheikh        Asam Sheikh            re-elected 2026-06-02, same seat
--   District 4   Sharon Kalani      Linda Barnett          Kalani became Mayor; seat vacant
--                                                          2026-07-14, Barnett appointed 2026-08-25 (T2, T4)
--   District 5   Aurelio Mattucci   Betty Lieu             Mattucci termed out, became Treasurer (T2)
--   District 6   Jeremy Gerson      Jeremy Gerson          unchanged
--
-- ── SOURCES ─────────────────────────────────────────────────────────────────────────────
--
--   T1  City of Torrance, City Council & Elected Officials, read 2026-10-26:
--       https://www.torranceca.gov/Government/City-Council
--       "Sharon Kalani was elected as the Mayor on June 2, 2026." / "David Kartsonis was
--       elected to Torrance City Council representing District 1 on June 2, 2026." / "Betty
--       Lieu was elected to Torrance City Council representing District 5 on June 2, 2026."
--   T2  City of Torrance newsroom, "City of Torrance Installs Newly Elected City Officials",
--       published 2026-07-15, describing "Tuesday evening's" meeting — 2026-07-14:
--       https://www.torranceca.gov/Government/Newsroom/City-of-Torrance-Installs-Newly-Elected-City-Officials
--       Kalani "sworn in as Mayor"; Kartsonis "newly elected District 1"; Lieu District 5;
--       "Former District 5 Councilmember Aurelio Mattucci ... took the oath of office as the
--       City's new Treasurer"; farewell to "outgoing Mayor George K. Chen, Councilmembers Jon
--       Kaji and Aurelio Mattucci"; "With Kalani's transition to the Mayor's Office, the
--       District 4 City Council seat is now vacant."
--   T3  Rafu Shimpo, May 2026: the June 2 ballot has "a race in Council District 1 between
--       incumbent Jon Kaji and challenger David Kartsonis". Secondary; used only to say Kaji's
--       term ended by defeat rather than retirement, and to tie him to District 1.
--       https://rafu.com/2026/05/incumbent-councilman-challenged-in-torrance-election/
--   T4  City of Torrance, Linda Barnett profile, read 2026-10-26: "appointed to the Torrance
--       City Council on August 25, 2026, to represent District 4."
--       https://www.torranceca.gov/Government/City-Council/Barnett
--
-- Every new term starts 2026-07-14 (the installation, T2), except Barnett's, which starts on
-- her appointment date (T4). An election date is not an occupancy date, so nobody is dated
-- June 2. Every date is 'day' precision from a city source.
--
-- ── ⚠ WHAT IS **NOT** CHANGED, AND WHY ───────────────────────────────────────────────────
--
-- ⚠ THE SIX COUNCIL SEATS STAY "At-Large". Torrance elects by district (1-6); our data holds
--   six unnumbered at-large offices, each on its own citywide district row. Which office is
--   which district is fixed here by WHO HELD IT (the table above), and the office ids below
--   say so in comments. Real district geometry is the fix, and is a separate pass — the same
--   wart CC_0063 documented for La Mirada. Until then every Torrance address sees all six.
-- ⚠ MATTUCCI'S NEW OFFICE (City Treasurer) IS NOT MODELLED. Torrance has no Treasurer or
--   Clerk office in our data, so his council term is closed and he holds no seat here.
-- ⚠ THE D4 VACANCY SPAN (2026-07-14 .. 2026-08-24) IS LEFT IMPLICIT: Kalani's council term
--   ends 07-13 and Barnett's starts 08-25, with no row between. The office is NOT left
--   flagged vacant — it is seated today.
-- ⚠ PARTY IS NOT WRITTEN for the three new people (antipartisan rule).
--
-- ── EFFECT ──────────────────────────────────────────────────────────────────────────────
--   +3 politicians   (David Kartsonis, Betty Lieu, Linda Barnett)
--   +4 office_terms  (Kalani Mayor, Kartsonis D1, Barnett D4, Lieu D5)
--   4 terms closed   (Chen 07-13, Kaji 07-13, Kalani D4 07-13, Mattucci 07-13)
--   is_incumbent -> false for Chen, Kaji, Mattucci (no seat left in our data)
--   Torrance ends at 7 seated offices, 0 vacant, 0 missing a term.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 0. PRE-FLIGHT. The seven offices must still be held by the people this file believes hold
--    them. If anyone has already moved, refuse rather than seat on top of it.
-- ─────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_txt text;
BEGIN
  SELECT string_agg(x.office_id || '->' || coalesce(p.full_name, 'NOBODY'), ', ' ORDER BY x.office_id)
    INTO v_txt
    FROM (VALUES
      ('c5b5b1b3-6e68-41a0-9722-b02d9e1e34f3'::uuid, 'George Chen'),       -- Mayor
      ('8391fb00-171a-4984-8bc7-2d080fc03a24'::uuid, 'Jon Kaji'),          -- District 1
      ('95879f8c-5cd2-4042-86eb-b11c14fea767'::uuid, 'Bridgett Lewis'),    -- District 2
      ('0542b22b-61e1-4a3d-be3c-104a33252d21'::uuid, 'Asam Sheikh'),       -- District 3
      ('143f683f-96a8-4924-92fa-fbc6bc3444e9'::uuid, 'Sharon Kalani'),     -- District 4
      ('220e2cb5-f268-423a-b9a8-2f187f94d9b5'::uuid, 'Aurelio Mattucci'),  -- District 5
      ('7f596dd4-1480-408f-bef8-b7b951b57142'::uuid, 'Jeremy Gerson')      -- District 6
    ) AS x(office_id, expected)
    LEFT JOIN essentials.office_terms t
           ON t.office_id = x.office_id AND t.term_start IS NULL AND t.term_end IS NULL
    LEFT JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.full_name IS DISTINCT FROM x.expected;

  -- A re-run finds the old terms closed; that is fine only if the new holders are already in.
  IF v_txt IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM essentials.office_terms
        WHERE office_id = '143f683f-96a8-4924-92fa-fbc6bc3444e9'
          AND term_start = DATE '2026-08-25') THEN
    RAISE EXCEPTION 'CA_0324: Torrance seats are not held as expected: %', v_txt;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 1. THE THREE NEW PEOPLE. None has an active namesake (checked 2026-10-26); the name guard
--    trigger is left on, so a namesake appearing since would stop this file.
--    🔴 is_incumbent is explicit: it defaults to false and would hide them from address search.
-- ─────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT v.id::uuid, v.full_name, v.first_name, v.last_name, true, true,
       'City of Torrance, City Council & Elected Officials, https://www.torranceca.gov/Government/City-Council read 2026-10-26 (CA_0324)'
  FROM (VALUES
    ('5b0f6a7e-2c1d-4e8a-9f3b-6d1c0a9e7b21', 'David Kartsonis', 'David', 'Kartsonis'),
    ('8e3d2c41-7a5b-4f69-b0c8-1e2f3a4d5c62', 'Betty Lieu',      'Betty', 'Lieu'),
    ('c4a7e9b2-3f8d-4d16-a5e0-7b9c2d1f8e43', 'Linda Barnett',   'Linda', 'Barnett')
  ) AS v(id, full_name, first_name, last_name)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id::uuid);

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 2. THE INSTALLATION, 2026-07-14 (T2). seat_officeholder closes each predecessor at 07-13.
-- ─────────────────────────────────────────────────────────────────────────────────────────
SELECT essentials.seat_officeholder(
         'c5b5b1b3-6e68-41a0-9722-b02d9e1e34f3'::uuid,          -- Torrance Mayor
         '0695e308-a400-426d-9f1b-4e674e5daf02'::uuid,          -- Sharon Kalani
         DATE '2026-07-14',
         'City of Torrance newsroom 2026-07-15, "City of Torrance Installs Newly Elected City Officials": Kalani "sworn in as Mayor" at the 2026-07-14 meeting; elected 2026-06-02. CA_0324_torrance_council_2026_turnover.',
         'elected', 'day', 'term_expired');                     -- Chen: two terms, outgoing

SELECT essentials.seat_officeholder(
         '8391fb00-171a-4984-8bc7-2d080fc03a24'::uuid,          -- Council, District 1
         '5b0f6a7e-2c1d-4e8a-9f3b-6d1c0a9e7b21'::uuid,          -- David Kartsonis
         DATE '2026-07-14',
         'City of Torrance newsroom 2026-07-15: "newly elected District 1 Councilmember David Kartsonis", installed 2026-07-14; elected 2026-06-02 over incumbent Jon Kaji. CA_0324_torrance_council_2026_turnover.',
         'elected', 'day', 'defeated');                         -- Kaji lost the D1 race (T3)

SELECT essentials.seat_officeholder(
         '220e2cb5-f268-423a-b9a8-2f187f94d9b5'::uuid,          -- Council, District 5
         '8e3d2c41-7a5b-4f69-b0c8-1e2f3a4d5c62'::uuid,          -- Betty Lieu
         DATE '2026-07-14',
         'City of Torrance newsroom 2026-07-15: "District 5 Councilmember Betty Lieu", installed 2026-07-14; elected 2026-06-02. CA_0324_torrance_council_2026_turnover.',
         'elected', 'day', 'term_expired');                     -- Mattucci: two terms, now Treasurer

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 3. DISTRICT 4: vacant from Kalani's move (2026-07-14), filled by appointment 2026-08-25.
--    vacate_office closes her council term at 07-13 and sets is_vacant; seating Barnett
--    clears it again in the same transaction (seat and un-flag together, never apart).
--    'resigned' is the nearest how_ended: she left the seat mid-term to take another office.
-- ─────────────────────────────────────────────────────────────────────────────────────────
SELECT essentials.vacate_office(
         '143f683f-96a8-4924-92fa-fbc6bc3444e9'::uuid,          -- Council, District 4
         DATE '2026-07-14',
         'City of Torrance newsroom 2026-07-15: "With Kalani''s transition to the Mayor''s Office, the District 4 City Council seat is now vacant." CA_0324',
         'resigned');

SELECT essentials.seat_officeholder(
         '143f683f-96a8-4924-92fa-fbc6bc3444e9'::uuid,          -- Council, District 4
         'c4a7e9b2-3f8d-4d16-a5e0-7b9c2d1f8e43'::uuid,          -- Linda Barnett
         DATE '2026-08-25',
         'City of Torrance, Linda Barnett profile: "appointed to the Torrance City Council on August 25, 2026, to represent District 4." https://www.torranceca.gov/Government/City-Council/Barnett read 2026-10-26. CA_0324_torrance_council_2026_turnover.',
         'appointed', 'day', 'resigned');

UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id = '143f683f-96a8-4924-92fa-fbc6bc3444e9'
   AND (is_vacant OR vacant_since IS NOT NULL);

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 4. THE THREE WHO LEFT hold no seat in our data any more. Kalani stays an incumbent (Mayor).
-- ─────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians
   SET is_incumbent = false
 WHERE id IN ('3dfd7349-e0e2-486d-8767-8dfc203ca986',   -- George Chen
              'e9af3b91-ab9c-4f97-bc18-c1baef871e85',   -- Jon Kaji
              '2b4b35a8-1498-46ad-aa9b-04650b454262')   -- Aurelio Mattucci
   AND is_incumbent IS DISTINCT FROM false
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                    WHERE och.politician_id = essentials.politicians.id);

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 5. POST-VERIFY. The current Torrance roster must be exactly the city's (T1).
-- ─────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_txt text; bad int;
BEGIN
  SELECT string_agg(x.office_id || ' holds ' || coalesce(p.full_name, 'NOBODY')
                    || ', expected ' || x.expected, '; ')
    INTO v_txt
    FROM (VALUES
      ('c5b5b1b3-6e68-41a0-9722-b02d9e1e34f3'::uuid, 'Sharon Kalani'),
      ('8391fb00-171a-4984-8bc7-2d080fc03a24'::uuid, 'David Kartsonis'),
      ('95879f8c-5cd2-4042-86eb-b11c14fea767'::uuid, 'Bridgett Lewis'),
      ('0542b22b-61e1-4a3d-be3c-104a33252d21'::uuid, 'Asam Sheikh'),
      ('143f683f-96a8-4924-92fa-fbc6bc3444e9'::uuid, 'Linda Barnett'),
      ('220e2cb5-f268-423a-b9a8-2f187f94d9b5'::uuid, 'Betty Lieu'),
      ('7f596dd4-1480-408f-bef8-b7b951b57142'::uuid, 'Jeremy Gerson')
    ) AS x(office_id, expected)
    LEFT JOIN essentials.office_current_holder och ON och.office_id = x.office_id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM x.expected;
  IF v_txt IS NOT NULL THEN RAISE EXCEPTION 'CA_0324: roster wrong after apply: %', v_txt; END IF;

  -- every current holder is an active incumbent (else address search hides them)
  SELECT count(*) INTO bad
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '0680000'
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF bad <> 0 THEN RAISE EXCEPTION 'CA_0324: % Torrance holder(s) are not active incumbents', bad; END IF;

  -- nothing in Torrance flagged vacant, nothing missing a term
  SELECT count(*) INTO bad
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '0680000' AND o.is_vacant;
  IF bad <> 0 THEN RAISE EXCEPTION 'CA_0324: % Torrance office(s) flagged vacant', bad; END IF;
  SELECT count(*) INTO bad
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '0680000';
  IF bad <> 0 THEN RAISE EXCEPTION 'CA_0324: % Torrance office(s) missing a term', bad; END IF;

  -- the three who left are no longer incumbents, and hold nothing
  SELECT count(*) INTO bad FROM essentials.politicians
   WHERE id IN ('3dfd7349-e0e2-486d-8767-8dfc203ca986','e9af3b91-ab9c-4f97-bc18-c1baef871e85',
                '2b4b35a8-1498-46ad-aa9b-04650b454262')
     AND is_incumbent;
  IF bad <> 0 THEN RAISE EXCEPTION 'CA_0324: % departed Torrance official(s) still is_incumbent', bad; END IF;

  -- Kalani holds exactly one current seat: Mayor
  SELECT count(*) INTO bad FROM essentials.office_current_holder
   WHERE politician_id = '0695e308-a400-426d-9f1b-4e674e5daf02';
  IF bad <> 1 THEN RAISE EXCEPTION 'CA_0324: Kalani holds % current seat(s), expected 1 (Mayor)', bad; END IF;
END $$;

COMMIT;
