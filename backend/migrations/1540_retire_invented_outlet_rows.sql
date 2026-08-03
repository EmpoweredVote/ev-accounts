-- 1540_retire_invented_outlet_rows.sql
--
-- Retire 58 stance rows whose evidence rests on FIVE NEWS OUTLETS THAT DO NOT EXIST, and strip the
-- invented citation from 3 more that keep a verified working source.
--   Rollback record: data/stance-retirement/2026-08-02-invented-outlet-rollback.json
--   Review:          data/stance-retirement/2026-08-02-invented-domain-sweep.md
--   Disposition:     data/stance-retirement/2026-08-02-invented-outlet-disposition.json
--
-- The hosts: medfordmirror.com · newtonvillearea.com · alhambraource.com · walthamtribunenews.com
-- · walthamatch.com. Absence was REPRODUCED across 3 rounds x 3 query forms (availability API, CDX
-- matchType=domain, CDX prefix). For a local paper publishing for years, zero captures across the
-- archive's entire history is not a crawl gap.
--
-- 🔴 TWO ARE ONE-CHARACTER CORRUPTIONS OF REAL PAPERS, and the matched pair is the proof:
--   alhambraource.com  has ZERO captures · alhambrasource.com is richly archived
--   walthamatch.com    has ZERO captures · walthampatch.com  is richly archived
-- Both real hosts were tested in the SAME run under identical conditions.
--
-- ⚠ RE-POINTING IS NOT AVAILABLE, and that was tested rather than assumed. For alhambraource.com the
-- real site's root IS archived (capture 2025-01-25, control passed) and NONE of the three cited paths
-- exist there. Host and path are both fabricated, so unlike clark.house.gov (1539) there is no real
-- page to point at.
--
-- ⚠ THE OTHER SOURCES WERE FETCHED, NOT ASSUMED. 60 of the 61 rows carry a second citation, but
-- "has another source" is not "is supported" -- conflating those is what made the composed-citation
-- headline wrong by 3.4x. Of 29 distinct other citations: 46 row-level verdicts HTTP 404, 4
-- unreachable, 7 readable but never naming the politician, and only 3 SUPPORTS.
--
-- ⚠ ALL 61 TOPICS ARE OWED RE-RESEARCH. The chairs may well be right; the evidence cited was not.

BEGIN;

CREATE TEMP TABLE _retire_1540 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1540 (politician_id, topic_id) VALUES
  ('dee11bee-c034-49b1-ba4c-30f94622ddd3', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Brittany Hume Charm: Affordable Housing
  ('583a5fab-16d5-40c5-8c6c-25b9ea4b97ae', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Cyrus Dahmubed: Residential Zoning
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Brian Golden: Affordable Housing
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Brian Golden: Rent Regulation
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Brian Golden: Growth and Development Pace
  ('5b590765-e701-41cf-b0c3-e7efdeea16d3', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Lisa Gordon: Residential Zoning
  ('f22187bb-dc57-4088-bb19-8bc39bcb95c9', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Katherine Lee: Growth and Development Pace
  ('f22187bb-dc57-4088-bb19-8bc39bcb95c9', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Katherine Lee: Environmental Protection vs. Development
  ('27441d13-d90b-48e8-bb35-3b7da5d24c6e', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Ross J. Maza: Growth and Development Pace
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Breanna Lungo-Koehn: Environmental Protection vs. Development
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Breanna Lungo-Koehn: Economic Development Incentives
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Breanna Lungo-Koehn: Public Safety Approach
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Breanna Lungo-Koehn: Local Immigration Enforcement
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Breanna Lungo-Koehn: Growth and Development Pace
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Breanna Lungo-Koehn: Homelessness Response
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Breanna Lungo-Koehn: Taxation and Public Spending
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Breanna Lungo-Koehn: Civil Rights and Social Justice
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Breanna Lungo-Koehn: Healthcare Access
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Breanna Lungo-Koehn: Childcare Affordability & Access
  ('a4320764-6ba2-4563-9a58-abb1333c2f40', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Breanna Lungo-Koehn: Rent Regulation
  ('df7397a9-5735-4d08-b113-e1684e11a144', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Isaac Bears: Affordable Housing
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Isaac Bears: Transportation Priorities
  ('df7397a9-5735-4d08-b113-e1684e11a144', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Isaac Bears: Environmental Protection vs. Development
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Isaac Bears: Public Safety Approach
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Isaac Bears: Local Immigration Enforcement
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Isaac Bears: Healthcare Access
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Isaac Bears: Rent Regulation
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Isaac Bears: Residential Zoning
  ('df7397a9-5735-4d08-b113-e1684e11a144', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Isaac Bears: Taxation and Public Spending
  ('9abe66cb-eea8-4f6c-afa1-9ee7297473e5', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Emily Lazzaro: Affordable Housing
  ('9abe66cb-eea8-4f6c-afa1-9ee7297473e5', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Emily Lazzaro: Transportation Priorities
  ('9abe66cb-eea8-4f6c-afa1-9ee7297473e5', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Emily Lazzaro: Environmental Protection vs. Development
  ('9abe66cb-eea8-4f6c-afa1-9ee7297473e5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Emily Lazzaro: Local Immigration Enforcement
  ('cab6c573-7335-4c8f-8100-5063908dba32', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Anna Callahan: Affordable Housing
  ('cab6c573-7335-4c8f-8100-5063908dba32', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Anna Callahan: Transportation Priorities
  ('cab6c573-7335-4c8f-8100-5063908dba32', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Anna Callahan: Local Immigration Enforcement
  ('cab6c573-7335-4c8f-8100-5063908dba32', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Anna Callahan: Rent Regulation
  ('cab6c573-7335-4c8f-8100-5063908dba32', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Anna Callahan: Public Safety Approach
  ('81a83387-4166-4d97-9983-2f9f6473f9d1', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Matt Leming: Affordable Housing
  ('81a83387-4166-4d97-9983-2f9f6473f9d1', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Matt Leming: Local Immigration Enforcement
  ('e4df4fce-9289-43db-8568-e316a73ae931', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Jeff Maloney: Public Safety Approach
  ('a3244566-232e-461a-842a-36149374b2e2', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- George Scarpelli: Public Safety Approach
  ('a3244566-232e-461a-842a-36149374b2e2', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- George Scarpelli: Affordable Housing
  ('a3244566-232e-461a-842a-36149374b2e2', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- George Scarpelli: Taxation and Public Spending
  ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Noya Wang: Growth and Development Pace
  ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Noya Wang: Environmental Protection vs. Development
  ('aeb29c2c-69f6-4447-8522-1404b614fd62', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Justin Tseng: Affordable Housing
  ('aeb29c2c-69f6-4447-8522-1404b614fd62', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Justin Tseng: Local Immigration Enforcement
  ('f6d52199-b1d1-48d3-9972-66b8d229acdc', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Adele Andrade-Stadler: Growth and Development Pace
  ('3eab65f7-083a-49c6-9944-1a20a5373538', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Arthur Donahue: Residential Zoning
  ('3eab65f7-083a-49c6-9944-1a20a5373538', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Arthur Donahue: Economic Development Incentives
  ('28d25ed6-6a0f-428e-8b42-85a448ffb0c2', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Paul Brasco: Growth and Development Pace
  ('ab208b92-9067-4f3d-9791-60b404793b3a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Tim King: Taxation and Public Spending
  ('73a1f2f1-9112-4820-b853-8a8542c72d85', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Randall LeBlanc: Economic Development Incentives
  ('9c64b145-cce4-4b31-a4e0-c041a12af62b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Marc C. Laredo: Residential Zoning
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Susan Albright: Residential Zoning
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Susan Albright: Rent Regulation
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4')  -- Susan Albright: Growth and Development Pace
;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _retire_1540 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 58 THEN RAISE EXCEPTION '1540: expected 58 targeted answers, found % — target set has moved', v_n; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1540 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1540 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- 11 politicians are emptied. Clear last_stances_researched_at so they read as
-- UNRESEARCHED and resurface, rather than asserting "we looked and found nothing" on the strength of
-- the very pass being corrected (rule from 1494, reaffirmed in 1525 and 1538).
UPDATE essentials.politicians SET last_stances_researched_at = NULL
 WHERE id IN ('41c14549-89c4-451c-91d7-22a578a4dc7d',
               '583a5fab-16d5-40c5-8c6c-25b9ea4b97ae',
               '5b590765-e701-41cf-b0c3-e7efdeea16d3',
               '773aa577-9e09-4721-80ee-6219edb151e7',
               '81a83387-4166-4d97-9983-2f9f6473f9d1',
               '9abe66cb-eea8-4f6c-afa1-9ee7297473e5',
               'a3244566-232e-461a-842a-36149374b2e2',
               'aeb29c2c-69f6-4447-8522-1404b614fd62',
               'cab6c573-7335-4c8f-8100-5063908dba32',
               'dee11bee-c034-49b1-ba4c-30f94622ddd3',
               'df7397a9-5735-4d08-b113-e1684e11a144');

-- ---- strip: a verified working citation remains, so the row stays ---------------------------
-- Marc C. Laredo / Affordable Housing — supported by https://newtonma.gov/government/mayor
UPDATE inform.politician_context
   SET sources = ARRAY['https://newtonma.gov/government/mayor']::text[]
 WHERE politician_id = '9c64b145-cce4-4b31-a4e0-c041a12af62b' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Marc C. Laredo / Transportation Priorities — supported by https://newtonma.gov/government/mayor
UPDATE inform.politician_context
   SET sources = ARRAY['https://newtonma.gov/government/mayor']::text[]
 WHERE politician_id = '9c64b145-cce4-4b31-a4e0-c041a12af62b' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Marc C. Laredo / Growth and Development Pace — supported by https://newtonma.gov/government/mayor
UPDATE inform.politician_context
   SET sources = ARRAY['https://newtonma.gov/government/mayor']::text[]
 WHERE politician_id = '9c64b145-cce4-4b31-a4e0-c041a12af62b' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

DO $$
DECLARE v_n int; v_bad text;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _retire_1540 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION '1540: expected 0 targeted answers to remain, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context c
    JOIN _retire_1540 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION '1540: expected 0 orphaned context rows, found %', v_n; END IF;

  -- 🔴 NO CITATION TO ANY OF THE FIVE INVENTED HOSTS MAY SURVIVE ANYWHERE IN THE TABLE.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
    CROSS JOIN LATERAL unnest(pc.sources) s
   WHERE s ~* '(medfordmirror\.com|newtonvillearea\.com|alhambraource\.com|walthamtribunenews\.com|walthamatch\.com)';
  IF v_n <> 0 THEN RAISE EXCEPTION '1540: % invented-outlet citations survive', v_n; END IF;

  -- Stripped rows must keep their working citation and must not end up sourceless.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (('9c64b145-cce4-4b31-a4e0-c041a12af62b','669cac97-66a6-4087-b036-936fbe62efb3'), ('9c64b145-cce4-4b31-a4e0-c041a12af62b','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('9c64b145-cce4-4b31-a4e0-c041a12af62b','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'))
     AND (sources IS NULL OR cardinality(sources) = 0);
  IF v_n <> 0 THEN RAISE EXCEPTION '1540: % stripped rows left sourceless', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id IN ('41c14549-89c4-451c-91d7-22a578a4dc7d', '583a5fab-16d5-40c5-8c6c-25b9ea4b97ae', '5b590765-e701-41cf-b0c3-e7efdeea16d3', '773aa577-9e09-4721-80ee-6219edb151e7', '81a83387-4166-4d97-9983-2f9f6473f9d1', '9abe66cb-eea8-4f6c-afa1-9ee7297473e5', 'a3244566-232e-461a-842a-36149374b2e2', 'aeb29c2c-69f6-4447-8522-1404b614fd62', 'cab6c573-7335-4c8f-8100-5063908dba32', 'dee11bee-c034-49b1-ba4c-30f94622ddd3', 'df7397a9-5735-4d08-b113-e1684e11a144') AND last_stances_researched_at IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '1540: % emptied politicians still carry a research timestamp', v_n; END IF;

  -- These people must KEEP stances; an empty compass would mean the retirement went out of scope.
  SELECT string_agg(DISTINCT p.full_name, ', ') INTO v_bad
    FROM essentials.politicians p
   WHERE p.id IN ('a4320764-6ba2-4563-9a58-abb1333c2f40', '3eab65f7-083a-49c6-9944-1a20a5373538', 'abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', 'f22187bb-dc57-4088-bb19-8bc39bcb95c9', '27441d13-d90b-48e8-bb35-3b7da5d24c6e', '28d25ed6-6a0f-428e-8b42-85a448ffb0c2', '73a1f2f1-9112-4820-b853-8a8542c72d85', '9c64b145-cce4-4b31-a4e0-c041a12af62b', 'ab208b92-9067-4f3d-9791-60b404793b3a', 'e4df4fce-9289-43db-8568-e316a73ae931', 'f6d52199-b1d1-48d3-9972-66b8d229acdc')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers x WHERE x.politician_id = p.id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION '1540: unexpectedly emptied: %', v_bad; END IF;
END $$;

COMMIT;
