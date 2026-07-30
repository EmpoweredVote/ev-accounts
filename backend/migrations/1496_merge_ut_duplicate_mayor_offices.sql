-- 1496_merge_ut_duplicate_mayor_offices.sql
--
-- Ten UT cities each carry TWO `Mayor` offices on the same LOCAL_EXEC district, each with
-- its own office_terms row seating the same person via a DUPLICATE politician record.
-- essentials.office_current_holder does not filter politicians.is_active, so both resolve
-- and each of these cities renders TWO mayors.
--
-- Affected: Layton, Lehi, Ogden, Orem, Provo, Salt Lake City, Sandy, St. George,
--           West Jordan, West Valley City.
--
-- Two systematic seeding cohorts, not ten ad-hoc mistakes:
--
--   cohort A  created 2026-05-22/28  politician external_id -3xxxxx   data_source 'ut-city-<city>-mayor'
--             office: chamber_id NULL, seats=1        politician: is_active=FALSE
--             holds ALL 11 politician_contacts rows + 9 lower-res 'sourced' images
--             holds ZERO stances
--
--   cohort B  created 2026-06-17     politician external_id -49xxxxx0001  data_source NULL
--             office: chamber_id SET, seats=NULL      politician: is_active=TRUE
--             holds ALL 19 inform.politician_answers + 19 politician_context rows
--             holds 10/10 higher-res 'press_use' images
--             holds ZERO contacts
--
-- Neither side is a clean delete: the data is SPLIT. Survivor is cohort B, because it is the
-- active cohort and holds the hand-researched stances (Orem/McCandless 8, SLC/Mendenhall 11).
--
-- Office shape was decided by the 26 UT cities that are NOT duplicated: every one of them has
-- chamber_id set to "<City> City Council" AND seats=1. So the mayor-on-council-chamber link is
-- this repo's convention, and cohort B is right to have it -- it is only missing seats=1, which
-- this migration carries over from cohort A. After this runs, all 36 UT mayor offices match.
--
-- Cohort A politician rows are deliberately NOT deleted. They are already is_active=false, ~40
-- tables across 8 schemas reference politician_id, and deletion is irreversible; leaving them
-- retired keeps this reversible and keeps their 'sourced' images as history. With no office_terms
-- row they are invisible per ADR 0002, which is the desired end state.
--
-- NOTE the detection lesson: normalizing names to find duplicates MISSES Ogden and Salt Lake
-- City, whose two rows spell the name differently ("Ben"/"Benjamin" Nadolski, "Erin"/"Erin J."
-- Mendenhall). Only the STRUCTURAL signature -- two offices on one (district, title) resolving to
-- a single seat -- catches all ten.
--
-- Idempotent: every statement is guarded or matches zero rows once applied.

BEGIN;

CREATE TEMP TABLE _ut_mayor_merge (
  city    text,
  a_office uuid,
  b_office uuid,
  a_pol    uuid,
  b_pol    uuid
) ON COMMIT DROP;

INSERT INTO _ut_mayor_merge (city, a_office, b_office, a_pol, b_pol) VALUES
 ('Layton',          'a8dec6e7-a43a-4a36-bc31-c51bd14158ed','f9f06644-4634-4ecf-8092-6b3e7f0b9b15','24844fb6-db42-40ea-a3f4-0c29bd8cbdb4','a3b670f3-9db7-47f1-87d8-5c67e073ec01'),
 ('Lehi',            '6eb06467-1a4e-43ad-9c9b-3617f960c55c','2327d00a-ae3c-485b-b9be-f870865377e0','d6f4961d-3005-4fc7-9afc-e9f3c7e9d8da','728e3e09-aecc-4fe7-a5d6-5a1ba4db98d1'),
 ('Ogden',           '27485705-4882-484e-a6ed-3915848e5a1d','404b3662-02a3-42c1-b9fb-5ecb3778a056','04fcbbc2-586f-4dfb-ac9f-508824681329','e0a0eaaf-db60-4494-98a8-ff458be1c986'),
 ('Orem',            'fc2281d5-e066-4764-908a-45357037fab5','189f1ab4-0046-4aaa-b226-ff289cc3a785','795e3171-c49a-435e-b0af-0b4c3e31945e','c47c9366-f274-4833-a1bb-a66808ef950e'),
 ('Provo',           '800089a2-dbbf-4020-b4af-7b0ae288c6ed','9cced4d3-c4e8-448d-bcd4-fe8314ee8528','999d33c9-928e-4a25-83f7-2050d2484266','a6225b20-2828-44af-a19b-4683bf3df7eb'),
 ('Salt Lake City',  '0116b97f-81a4-458c-9a1d-08e4a6c52acd','b88c7433-199b-495a-b0e5-447f88dba7bd','e5499340-d24d-447c-a7b1-92066319ad6e','2f3b7b91-581f-415a-9af2-3d0e05f2483d'),
 ('Sandy',           '92034940-8231-46e9-ac53-1945412f49a4','e2d0c333-ba37-4768-9eb3-e887771d41c2','6a7b2e72-1ea1-4b1c-8227-eb0cc2565227','c86b603d-81ab-4e9d-9ab9-a9eabe9ec8a9'),
 ('St. George',      'cc6fbe77-3430-4ca5-b498-f419794e99f0','f0472685-cc0e-4471-8188-d73432e3db3c','de9550bd-82ac-4916-9ba6-ea4a4cf12672','0c9fbc2d-f9c6-498a-b0ba-5302cd235a06'),
 ('West Jordan',     '8ad3a437-d29a-4e3c-856a-b66389d85b96','8de49571-ddb8-4749-8272-37ff62f3ab12','58e74290-6949-4e0a-9c18-742f92b537f4','f40770de-ec5a-4b84-9caf-ff5123722adb'),
 ('West Valley City','d45467a5-4cce-4ddb-a07c-3fd5d09c1e9d','c5f3896e-2329-4620-a904-7e2568564742','1ad8ac09-d97c-438f-ae93-1f65f822fe0a','77e58dd9-86af-4fc2-8286-d2d49b0e3d49');

-- Sanity: the mapping must still describe reality before we mutate anything.
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad FROM _ut_mayor_merge m
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = m.b_office)
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = m.b_pol)
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = m.a_pol);
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1496: % mapping rows reference a missing survivor office/politician', v_bad;
  END IF;
END $$;

-- 1. Carry seats=1 onto the surviving office so all 36 UT mayor offices match shape.
UPDATE essentials.offices o
   SET seats = 1
  FROM _ut_mayor_merge m
 WHERE o.id = m.b_office
   AND o.seats IS NULL;

-- 2. Move the contact rows -- the only data cohort A holds that B lacks.
UPDATE essentials.politician_contacts pc
   SET politician_id = m.b_pol
  FROM _ut_mayor_merge m
 WHERE pc.politician_id = m.a_pol;

-- 3. Carry cohort A's provenance onto the survivor (B was seeded with data_source NULL).
UPDATE essentials.politicians bp
   SET data_source = ap.data_source
  FROM _ut_mayor_merge m
  JOIN essentials.politicians ap ON ap.id = m.a_pol
 WHERE bp.id = m.b_pol
   AND bp.data_source IS NULL
   AND ap.data_source IS NOT NULL;

-- 4. Prefer the common-usage name form on the two survivors that differ from cohort A.
--    Both rows have full_name_manual_override = false, so nothing hand-set is being overwritten.
UPDATE essentials.politicians
   SET full_name = 'Ben Nadolski', first_name = 'Ben'
 WHERE id = 'e0a0eaaf-db60-4494-98a8-ff458be1c986'
   AND full_name = 'Benjamin Nadolski'
   AND full_name_manual_override = false;

UPDATE essentials.politicians
   SET full_name = 'Erin Mendenhall', middle_initial = NULL
 WHERE id = '2f3b7b91-581f-415a-9af2-3d0e05f2483d'
   AND full_name = 'Erin J. Mendenhall'
   AND full_name_manual_override = false;

-- 5. Drop the duplicate terms, then the duplicate offices.
DELETE FROM essentials.office_terms t
 USING _ut_mayor_merge m
 WHERE t.office_id = m.a_office;

DELETE FROM essentials.offices o
 USING _ut_mayor_merge m
 WHERE o.id = m.a_office
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.races        r WHERE r.office_id = o.id);

-- 6. politicians.office_id is a legacy snapshot with NO foreign key, so a deleted office would
--    leave it dangling. Clear it on the retired rows; point it at the survivor office on the
--    kept rows (CLAUDE.md: prefer the view, but do not leave a stale pointer behind).
UPDATE essentials.politicians p
   SET office_id = NULL
  FROM _ut_mayor_merge m
 WHERE p.id = m.a_pol
   AND p.office_id = m.a_office;

UPDATE essentials.politicians p
   SET office_id = m.b_office
  FROM _ut_mayor_merge m
 WHERE p.id = m.b_pol
   AND p.office_id IS DISTINCT FROM m.b_office;

-- ── post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices int; v_shape int; v_dupes int; v_answers int; v_ctx int;
  v_contacts_b int; v_contacts_a int; v_imgs int; v_dangling int; v_holders int;
BEGIN
  -- exactly one Mayor office per affected district
  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ut' AND o.title = 'Mayor' AND d.district_type = 'LOCAL_EXEC'
     AND d.label IN ('Layton Mayor','Lehi Mayor','Ogden Mayor','Orem Mayor','Provo Mayor',
                     'Salt Lake City Mayor','Sandy Mayor','St. George Mayor',
                     'West Jordan Mayor','West Valley City Mayor');
  IF v_offices <> 10 THEN
    RAISE EXCEPTION '1496: expected 10 surviving mayor offices, found %', v_offices;
  END IF;

  -- and every UT mayor office now matches the house shape: chamber set + seats=1
  SELECT count(*) INTO v_shape
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ut' AND o.title = 'Mayor' AND d.district_type = 'LOCAL_EXEC'
     AND (o.chamber_id IS NULL OR o.seats IS DISTINCT FROM 1);
  IF v_shape <> 0 THEN
    RAISE EXCEPTION '1496: % UT mayor offices still off-shape (chamber NULL or seats<>1)', v_shape;
  END IF;

  -- no seat anywhere resolves to more offices than distinct occupants (the structural detector,
  -- which unlike name-matching also catches the Ogden / Salt Lake City spelling variants)
  SELECT count(*) INTO v_dupes FROM (
    SELECT 1
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.term_end IS NULL
      LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE lower(d.state) = 'ut' AND o.title = 'Mayor'
     GROUP BY d.id, o.title
    HAVING count(*) > count(DISTINCT ot.politician_id)
  ) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION '1496: % UT mayor seats still have more offices than occupants', v_dupes;
  END IF;

  -- the stances that justified keeping cohort B must all survive
  SELECT count(*) INTO v_answers FROM inform.politician_answers a
   WHERE a.politician_id IN ('c47c9366-f274-4833-a1bb-a66808ef950e','2f3b7b91-581f-415a-9af2-3d0e05f2483d');
  IF v_answers <> 19 THEN
    RAISE EXCEPTION '1496: expected 19 surviving stance answers, found %', v_answers;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context x
   WHERE x.politician_id IN ('c47c9366-f274-4833-a1bb-a66808ef950e','2f3b7b91-581f-415a-9af2-3d0e05f2483d');
  IF v_ctx <> 19 THEN
    RAISE EXCEPTION '1496: expected 19 surviving stance context rows, found %', v_ctx;
  END IF;

  -- all 11 contacts moved to the survivors, none left stranded on the retired rows
  SELECT count(*) INTO v_contacts_b FROM essentials.politician_contacts pc
    JOIN _ut_mayor_merge m ON m.b_pol = pc.politician_id;
  SELECT count(*) INTO v_contacts_a FROM essentials.politician_contacts pc
    JOIN _ut_mayor_merge m ON m.a_pol = pc.politician_id;
  IF v_contacts_b <> 11 OR v_contacts_a <> 0 THEN
    RAISE EXCEPTION '1496: contacts not fully moved (survivor=%, retired=%)', v_contacts_b, v_contacts_a;
  END IF;

  -- every survivor still has a headshot
  SELECT count(DISTINCT m.b_pol) INTO v_imgs
    FROM _ut_mayor_merge m
    JOIN essentials.politician_images i ON i.politician_id = m.b_pol;
  IF v_imgs <> 10 THEN
    RAISE EXCEPTION '1496: only % of 10 survivors have a headshot', v_imgs;
  END IF;

  -- No politician may point at one of the offices THIS migration deleted.
  --
  -- Deliberately scoped, not a global zero-check: 11 politicians already carry a dangling
  -- politicians.office_id before this migration runs (UT city council members seeded with
  -- data_source 'ut-city-<city>', plus some inactive CA rows). That is a separate pre-existing
  -- defect and is out of scope here -- none of the 11 are among these 20 mayor rows. The
  -- near-miss worth noting: one of them is Victoria Petro, an SLC council member, who is a
  -- DIFFERENT PERSON from Layton mayor Joy Petro.
  SELECT count(*) INTO v_dangling
    FROM essentials.politicians p
    JOIN _ut_mayor_merge m ON p.office_id = m.a_office;
  IF v_dangling <> 0 THEN
    RAISE EXCEPTION '1496: % politicians still point at a deleted duplicate office', v_dangling;
  END IF;

  -- each surviving office resolves to exactly one holder
  SELECT count(*) INTO v_holders
    FROM _ut_mayor_merge m
    JOIN essentials.office_current_holder och ON och.office_id = m.b_office
   WHERE och.politician_id = m.b_pol;
  IF v_holders <> 10 THEN
    RAISE EXCEPTION '1496: expected 10 survivor offices to resolve to their holder, found %', v_holders;
  END IF;

  RAISE NOTICE '1496 OK: 10 UT mayor duplicates merged; 19 stances, 11 contacts, 10 headshots preserved';
END $$;

COMMIT;
