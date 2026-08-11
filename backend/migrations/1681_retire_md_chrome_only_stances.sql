-- 1681_retire_md_chrome_only_stances.sql
--
-- Retire 40 stance answers across 33 Maryland legislators where the topic vocabulary appears
-- ONLY IN SITE NAVIGATION on the cited pages, never in anything about the politician.
--   Rollback record: data/stance-retirement/2026-08-10-md-chrome-only-retirements-rollback.json
--
-- Third and final mechanical pass over the Maryland single-source queue:
--   1677 -- citations pointing at pages that do not exist            (85 rows, 8 legislators)
--   1678 -- topic absent from the cited page's RAW HTML entirely     (82 rows, 47 legislators)
--   1681 -- topic present in raw HTML but ONLY as site chrome        (40 rows, 33 legislators)
--
-- WHY CHROME-ONLY IS THE SAME DEFECT. 1678 measured on raw HTML deliberately, because raw HTML
-- cannot be corrupted by an extraction bug and counting navigation as "support" errs toward keeping
-- rows. The cost is that site furniture registers as a hit: mgaleg puts a REDISTRICTING item in the
-- nav bar of every member page, and Ballotpedia links its policy sections from every article. So
-- `redistrict` matched on pages that never discuss it -- 16 of the 40 rows here are exactly that.
-- Navigation is not about the officeholder, so a chrome-only match is an absent topic.
--
-- THE CONTENT BOUNDARY, and how it was validated. mgaleg content = everything from the
-- "Committee Assignment" marker onward (committee list + sponsored bill titles). Ballotpedia content
-- = the MediaWiki body between id="mw-content-text" and catlinks/printfooter, located in the RAW
-- html because that is where the attribute exists -- pass 1 of this audit searched for that marker
-- in tag-stripped text, where it can never appear, and silently produced false absences.
-- This time the extractor was validated before use: content lengths run min 9,060 / median 32,716 /
-- max 106,515 with ZERO regions below 20% of median, the exact distribution check that exposed the
-- earlier bug (one page at 2KB against a 29KB median). One page (mautz01) lacked the marker and its
-- politician was held back from consideration; he had no chrome-only rows in any case.
--
-- SPOT-CHECKED BY HAND, not just by script:
--   * Adrienne A. Jones / Redistricting -- 10 raw hits for redistrict|census on her member page and
--     17 on her Ballotpedia article, and ZERO in either content region.
--   * Debra Davis / Healthcare Access -- reasoning claims she "co-sponsored multiple healthcare
--     expansion bills including HB 1196 expanding Medicaid coverage"; her cited Ballotpedia body is
--     22,999 characters containing zero occurrences of care, career, health, medicaid, insurance,
--     coverage or 1196. It is an infobox plus election-result tables, with no policy content at all.
--   * Antonio Hayes / Police Accountability -- 2 raw hits for police, 0 in content.
--
-- ⚠ NOBODY IS EMPTIED; every legislator keeps the stances their page genuinely discusses. Asserted
-- below rather than assumed. All 40 topics are OWED RE-RESEARCH.
--
-- ▶ WHAT REMAINS AFTER THIS. The queue drops to ~933 rows whose topic really is discussed in the
-- member content. Those CANNOT be settled mechanically: a sponsored bill title proves the subject
-- was touched, not that the politician holds the charted position, and "on-topic by vocabulary" is
-- not "on-topic by rationale". Closing them needs a human reading bill titles against chairs.

BEGIN;

CREATE TEMP TABLE _retire_1681 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1681 (politician_id, topic_id) VALUES
  ('760cd4a7-235c-472f-a0ba-fb07098dfd57', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Adrienne A. Jones / State Redistricting and Gerrymandering
  ('b592e432-6411-48b3-bca3-d5596d0d81e9', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Andre V. Johnson, Jr. / State Redistricting and Gerrymandering
  ('ddfd43d3-023d-417e-9b68-af5a693e601e', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Andrew C. Pruski / Childcare Affordability & Access
  ('04e1a744-acf5-4453-9172-7135b6bfce96', '9db07b16-1076-4b7d-ad89-ebe7b51f4336'), -- Antonio Hayes / Criminal Justice Approach
  ('04e1a744-acf5-4453-9172-7135b6bfce96', '7bad33eb-e93e-4d94-8822-97212d49bde5'), -- Antonio Hayes / Police Accountability
  ('04e1a744-acf5-4453-9172-7135b6bfce96', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Antonio Hayes / Public Safety Approach
  ('7a2d1548-3268-4767-97a8-bb8b142d5a33', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Benjamin F. Kramer / Childcare Affordability & Access
  ('69870c10-cea2-43c2-8cf9-bfcaf0b82265', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- C. T. Wilson / Public Safety Approach
  ('c017b328-4469-45c4-aa8a-7b9035c77e22', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Catherine M. Forbes / State Redistricting and Gerrymandering
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Cheryl C. Kagan / State Redistricting and Gerrymandering
  ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae', '9db07b16-1076-4b7d-ad89-ebe7b51f4336'), -- Chris West / Criminal Justice Approach
  ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Cory V. McCray / Childcare Affordability & Access
  ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd', '9db07b16-1076-4b7d-ad89-ebe7b51f4336'), -- Cory V. McCray / Criminal Justice Approach
  ('fb714c92-166f-4cc1-bb6b-19988a81cefe', '9db07b16-1076-4b7d-ad89-ebe7b51f4336'), -- Dalya Attar / Criminal Justice Approach
  ('fb714c92-166f-4cc1-bb6b-19988a81cefe', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Dalya Attar / Public Safety Approach
  ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), -- Dana Jones / Healthcare Access
  ('e94337e1-4776-4058-87b4-32dfeb7732a0', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Dana Stein / State Redistricting and Gerrymandering
  ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Debra Davis / Childcare Affordability & Access
  ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), -- Debra Davis / Healthcare Access
  ('192e8ffb-e576-41f1-915a-dbc0c30d4769', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Diana M. Fennell / State Redistricting and Gerrymandering
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Dylan Behler / Childcare Affordability & Access
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a', '0bc588c6-39e1-4084-b5de-cac909b8b762'), -- Dylan Behler / Civil Rights and Social Justice
  ('22610d7f-eaca-4802-b486-0e48544e6e7d', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Eric Ebersole / State Redistricting and Gerrymandering
  ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Jackie Addison / State Redistricting and Gerrymandering
  ('631dac5c-fb86-41f5-a82d-5963164a9142', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Jon S. Cardin / State Redistricting and Gerrymandering
  ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Joshua J. Stonko / State Redistricting and Gerrymandering
  ('69bf6043-4546-4804-ae04-311cff54a986', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Julian Ivey / State Redistricting and Gerrymandering
  ('768ac1cf-a599-4ddb-943c-c985fafb2607', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Kriselda Valderrama / State Redistricting and Gerrymandering
  ('71542618-59c8-4b06-a765-e3df60cca763', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Mark N. Fisher / State Redistricting and Gerrymandering
  ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Mary Beth Carozza / Public Safety Approach
  ('38404814-7be0-40e3-b044-062f98b2a5b0', '7bad33eb-e93e-4d94-8822-97212d49bde5'), -- Mary Washington / Police Accountability
  ('18313901-28d8-464c-9368-2873577e9d44', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Mary-Dulany James / Public Safety Approach
  ('81b8bae9-0b0f-43de-8079-c0b605e12cec', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Nancy J. King / Public Safety Approach
  ('38b5030a-aa8b-4363-8b62-3ec384d22088', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Natalie Ziegler / Childcare Affordability & Access
  ('38b5030a-aa8b-4363-8b62-3ec384d22088', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), -- Natalie Ziegler / Healthcare Access
  ('589ed7af-602a-4ec9-8072-448b05446772', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'), -- Pam Lanman Guzzone / Childcare Affordability & Access
  ('9285f590-79b5-48de-a1c0-a022629e6ebb', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Robbyn Lewis / State Redistricting and Gerrymandering
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Shaneka Henson / State Redistricting and Gerrymandering
  ('848ac881-004b-436a-9a17-dfacbd33de5a', '48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Stephanie Smith / State Redistricting and Gerrymandering
  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3', 'c1ac1330-47f7-44ec-baf3-c913d926b97c')  -- Terri L. Hill / Childcare Affordability & Access
;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM _retire_1681;
  IF v <> 40 THEN RAISE EXCEPTION 'expected 40 target pairs, got %', v; END IF;

  SELECT count(*) INTO v FROM _retire_1681 r
    JOIN inform.politician_answers a ON a.politician_id=r.politician_id AND a.topic_id=r.topic_id;
  IF v <> 40 THEN RAISE EXCEPTION 'expected 40 live answers, found % -- corpus changed since audit', v; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1681 r
 WHERE c.politician_id=r.politician_id AND c.topic_id=r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1681 r
 WHERE a.politician_id=r.politician_id AND a.topic_id=r.topic_id;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM inform.politician_answers a
    JOIN _retire_1681 r ON r.politician_id=a.politician_id AND r.topic_id=a.topic_id;
  IF v <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v; END IF;

  SELECT count(*) INTO v FROM inform.politician_context c
    JOIN _retire_1681 r ON r.politician_id=c.politician_id AND r.topic_id=c.topic_id;
  IF v <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v; END IF;

  SELECT count(*) INTO v FROM (SELECT DISTINCT politician_id FROM _retire_1681) t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id=t.politician_id);
  IF v <> 0 THEN RAISE EXCEPTION '% politician(s) emptied by this migration', v; END IF;
END $$;

COMMIT;
