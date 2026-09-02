BEGIN;

-- =============================================================================
-- CC_0041: give the 14 uncategorized Season 2 topics a category
-- =============================================================================
-- Created 2026-09-01 with Chris Cantrell, before Season 2 opens.
--
-- THE BUG THIS FIXES: 14 of the 17 topics added for Season 2 have no row in
-- inform.compass_topic_categories, and the calibration UI cannot render a topic
-- that has none. /api/compass/categories assembles its response by walking
-- compass_categories -> compass_topic_categories -> the promoted set
-- (backend/src/lib/compassService.ts, getCompassCategories). There is no
-- "Uncategorized" bucket, so a topic with no join row has no path into that
-- response at all. Every picker surface reads that shape:
--
--     BuildCompass.jsx:117        categories.map(category => ...)
--     CalibrationOverlay.jsx:1590 dedupedCategories.map(category => ...)
--     Quiz.jsx:148                for (const cat of categories) ...   (full mode)
--
-- So without this migration, Border Security, Gun Policy, Cannabis Policy, the
-- two remaining foreign-policy topics, the 2020 election topic and all eight
-- school-board topics ship unpickable: returned by the flat /compass/topics
-- list, absent from every screen a user actually calibrates on.
--
-- Only Ranked-Choice Voting, Minimum Wage and Defense Spending were categorized
-- on the way in. They are already correct and are not touched here.
--
-- WHY A NEW CATEGORY. Eight school-board topics arrived at once and none of the
-- nine existing categories fits them. The single pre-existing school topic,
-- School Vouchers & Public Education Funding, had been filed under "Governance,
-- Democracy, and Institutional Reform" -- defensible when it was the only one,
-- indefensible as the home for a nine-topic school set. This adds "Education and
-- Schools" and ADDS it to School Vouchers without removing that topic's
-- Governance tag, so nothing moves out from under anyone who has already
-- answered it. Chris approved the new category 2026-09-01.
--
-- MULTI-CATEGORY TAGS ARE THE EXISTING PATTERN, not a workaround: Religious
-- Freedom is already in both Civil Rights and Governance, Misinformation in both
-- Governance and Technology, Jail Capacity in both Judicial and Public Safety.
-- CalibrationOverlay.jsx:648 dedupes topics across categories before rendering.
--
-- BORDER SECURITY goes to Civil Rights and Social Policy, not Foreign Policy --
-- Chris's call 2026-09-01. It joins the immigration cluster already there
-- (Immigration and Treatment of Immigrants, Local Immigration Enforcement,
-- Deportation Priorities), which is where a user looking for it would look.
--
-- CANNABIS POLICY goes to Public Safety and Law Enforcement only. A second
-- Healthcare tag was considered and dropped: the ladder runs from "keep it fully
-- illegal and enforce criminal penalties" to "treat it like an ordinary legal
-- product", which is a criminalization axis. Only rung 2 (medical use) touches
-- healthcare, and one rung does not make it a healthcare question.
--
-- WHAT THIS IS NOT: this does not touch compass_topic_revisions, season_questions,
-- change_class, version, or any answer row. Categories are presentation metadata
-- keyed on topic_id -- outside the revision/season model entirely, and outside
-- everything CA_0011's immutability trigger covers. It is therefore NOT gated on
-- the Season 2 draft window and could in principle land after the open; it lands
-- before because shipping 14 invisible topics is the thing we are preventing.
--
-- SAFE TO RE-RUN. Both inserts are ON CONFLICT DO NOTHING against real unique
-- constraints (compass_categories UNIQUE (title); compass_topic_categories
-- PRIMARY KEY (topic_id, category_id)).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The new category.
-- -----------------------------------------------------------------------------
-- The id is a literal, not gen_random_uuid(), so this file and prod agree and a
-- re-run in another environment produces the same row. getCompassCategories
-- orders by title, so this sorts between "Economic Policy and Labor" and
-- "Environment and Climate Policy".

INSERT INTO inform.compass_categories (id, title)
VALUES ('c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430', 'Education and Schools')
ON CONFLICT (title) DO NOTHING;


-- -----------------------------------------------------------------------------
-- 2. The 19 topic->category rows.
-- -----------------------------------------------------------------------------
-- Topic ids are literal rather than title-matched: a title typo in a join would
-- silently drop a row and leave the topic invisible, which is the exact failure
-- being fixed. The DO block below re-checks the outcome regardless.

INSERT INTO inform.compass_topic_categories (topic_id, category_id)
VALUES
  -- Education and Schools (new) -----------------------------------------------
  ('49f0b171-2ddf-4e68-887f-0ba78a2562f1', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- School Budget and Spending Priorities
  ('6c43fdec-d084-415d-a15d-d78f48d4fb34', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- Curriculum and Contested Topics
  ('66b389c7-86fc-45e9-bf34-964bb747f27b', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- Equity and Inclusion Programs in Schools
  ('d96f987e-3404-4667-909d-5889116ba6e5', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- Parental Notification and Transgender Students
  ('1fcff1e8-c913-4d97-91da-1145952d7c65', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- School Library Books and Instructional Materials
  ('15d7e730-119b-43a2-a351-1efb7352b86b', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- Police in Schools
  ('c8807d3d-4264-47ce-b8c4-08c6c9c33ce3', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- Charter Schools
  ('61269f44-9c7f-4b27-818a-3508009f6ae2', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- Artificial Intelligence in Schools
  ('00b95a6a-75db-4521-b523-3326bba938de', 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430'), -- School Vouchers (KEEPS its existing Governance tag)

  -- Civil Rights and Social Policy ---------------------------------------------
  ('407614a8-ba2c-4145-8224-233655e6ac3f', 'eff63c93-dab4-498b-9868-28742caa0132'), -- Border Security -> the immigration cluster
  ('66b389c7-86fc-45e9-bf34-964bb747f27b', 'eff63c93-dab4-498b-9868-28742caa0132'), -- Equity and Inclusion Programs in Schools
  ('d96f987e-3404-4667-909d-5889116ba6e5', 'eff63c93-dab4-498b-9868-28742caa0132'), -- Parental Notification and Transgender Students

  -- Governance, Democracy, and Institutional Reform -----------------------------
  ('b5260e5a-5576-4071-8b2a-088af8d1f9eb', '6e958103-8877-4421-9279-39e96e00e6f9'), -- 2020 Presidential Election

  -- Public Safety and Law Enforcement -------------------------------------------
  ('56125933-b82a-46c5-847b-b2e9a146b89f', '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c'), -- Gun Policy
  ('2d893b95-9365-48f3-b7d6-1d0db8216518', '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c'), -- Cannabis Policy
  ('15d7e730-119b-43a2-a351-1efb7352b86b', '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c'), -- Police in Schools

  -- Foreign Policy and National Security ----------------------------------------
  ('710396dc-e618-4011-8118-43c62a786111', 'f41cef76-e438-4a0a-a9f3-13beba247f73'), -- Foreign Military Intervention
  ('6783e65c-0722-45d9-8579-65327af7c15c', 'f41cef76-e438-4a0a-a9f3-13beba247f73'), -- U.S. Military Aid to Israel

  -- Technology, Data, and Innovation --------------------------------------------
  ('61269f44-9c7f-4b27-818a-3508009f6ae2', 'b15168c7-19bb-44a2-b462-4e75b2d9cf8c')  -- Artificial Intelligence in Schools
ON CONFLICT (topic_id, category_id) DO NOTHING;


-- -----------------------------------------------------------------------------
-- 3. Verification. Fails the transaction rather than reporting a false success.
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_season_2  uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_edu       uuid := 'c7f4a1e8-3b96-4d52-8a07-51e2c9d6b430';
  v_orphans   int;
  v_edu_count int;
  v_titles    text;
BEGIN
  -- (a) The actual goal: no Season 2 topic is unreachable from the picker.
  SELECT count(*), coalesce(string_agg(t.title, ', ' ORDER BY t.title), '')
    INTO v_orphans, v_titles
    FROM inform.season_questions sq
    JOIN inform.compass_topics t ON t.id = sq.topic_id
   WHERE sq.season_id = v_season_2
     AND NOT EXISTS (
       SELECT 1 FROM inform.compass_topic_categories tc WHERE tc.topic_id = t.id
     );

  IF v_orphans <> 0 THEN
    RAISE EXCEPTION
      'CC_0041: % Season 2 topic(s) still have no category and would be invisible in calibration: %',
      v_orphans, v_titles;
  END IF;

  -- (b) The new category holds the nine-topic school set.
  SELECT count(*) INTO v_edu_count
    FROM inform.compass_topic_categories WHERE category_id = v_edu;

  IF v_edu_count <> 9 THEN
    RAISE EXCEPTION 'CC_0041: expected 9 topics in "Education and Schools", found %', v_edu_count;
  END IF;

  -- (c) School Vouchers kept Governance as well as gaining Education.
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_categories
     WHERE topic_id = '00b95a6a-75db-4521-b523-3326bba938de'
       AND category_id = '6e958103-8877-4421-9279-39e96e00e6f9'
  ) THEN
    RAISE EXCEPTION 'CC_0041: School Vouchers lost its Governance tag';
  END IF;

  RAISE NOTICE 'CC_0041 OK: 0 uncategorized Season 2 topics; Education and Schools holds 9.';
END $$;

COMMIT;
