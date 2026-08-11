-- 1678_retire_md_absent_topic_stances.sql
--
-- Retire 82 published stance answers across 47 Maryland legislators whose cited page says
-- NOTHING on the topic. An absent topic is no stance: the chair rested purely on inference.
--   Rollback record: data/stance-retirement/2026-08-10-md-absent-topic-retirements-rollback.json
--                    (the ONLY surviving copy of these rows' reasoning and sources)
--
-- Follows migration 1677, which retired the 8 politicians whose citations pointed at pages that do
-- not exist. These 47 are the opposite case: the cited page is real and live, and simply does
-- not discuss the topic the stance claims to derive from it.
--
-- THE TEST, and why it is trustworthy. A topic counts as ABSENT only when EVERY keyword for it
-- occurs ZERO times in the RAW HTML of every page the stance cites. Navigation, sidebars, infoboxes
-- and script blocks all count as "present", so this is strictly more conservative than searching the
-- article body, and it cannot be fooled by an extraction bug. Keyword sets are deliberately generous
-- (Reproductive Rights matches abortion|reproductive|contracept|pregnan|family planning|maternal|
-- fetal), so a single mention anywhere keeps the row. Doubt resolves toward KEEPING, exactly as in
-- 1520/1521.
--
-- ⚠ AN EARLIER PASS OF THIS SAME AUDIT WAS WRONG AND WAS DISCARDED. Working from extracted article
-- text it reported 109 absent rows. It sliced every Ballotpedia page at the first "See also" -- which
-- occurs around character 2,078, inside the header furniture -- and threw the entire article away;
-- it also searched for the attribute `mw-parser-output` in text whose tags had already been
-- stripped, so that marker could never match. Both bugs manufacture FALSE ABSENCE, the one direction
-- that destroys data. The rule is now: measure on raw HTML, and treat any extractor as suspect until
-- its failures are shown to be safe. The raw pass returns 82.
--
-- WHAT THESE ROWS LOOK LIKE. The reasoning states specifics the source cannot support:
--   * Arthur Ellis / Reproductive Rights -- "voted YES on the Abortion Care Access Act", while
--     abortion|reproductive|contracept|pregnan|maternal|fetal occur ZERO times on the cited page.
--   * Alonzo T. Washington / Immigration -- "represents a district with a large immigrant community
--     ... supports comprehensive immigration reform", from a page with no immigration vocabulary at
--     all. That is demography plus party, not evidence.
--   * C. Anthony Muse / Same-Sex Marriage -- "as a pastor and Democrat, has expressed more
--     conservative views on same-sex marriage", a socially charged claim about a named person,
--     sourced to a page where marriage|same-sex|lgbt|gay|lesbian never appear.
--   * Ron Watson / Police Accountability -- "backed the Maryland Police Accountability Act of 2021",
--     while police|accountab|misconduct occur ZERO times across his 237KB member page.
--   * Nancy J. King and Terri L. Hill / Medicare-Medicaid -- detailed claims about defending both
--     programmes, from pages where medicaid|medicare|nursing never appear.
--
-- ⚠ NOBODY IS EMPTIED. Every one of these 47 politicians keeps the stances whose topic the page
-- does discuss, so no last_stances_researched_at needs clearing -- but the migration asserts that
-- each retains at least one answer rather than assuming it. The people stay; only unsupported
-- chairs go. All 82 topics are OWED RE-RESEARCH.

BEGIN;

CREATE TEMP TABLE _retire_1678 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1678 (politician_id, topic_id) VALUES
  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Alonzo T. Washington / Immigration and Treatment of Immigrants
  ('ddfd43d3-023d-417e-9b68-af5a693e601e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Andrew C. Pruski / Reproductive Rights and Abortion Access
  ('04e1a744-acf5-4453-9172-7135b6bfce96', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Antonio Hayes / Immigration and Treatment of Immigrants
  ('04e1a744-acf5-4453-9172-7135b6bfce96', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Antonio Hayes / Same-Sex Marriage
  ('4754dede-4a3b-4280-a8b1-7497530107f7', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Arthur Ellis / Immigration and Treatment of Immigrants
  ('4754dede-4a3b-4280-a8b1-7497530107f7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Arthur Ellis / Reproductive Rights and Abortion Access
  ('7a2d1548-3268-4767-97a8-bb8b142d5a33', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Benjamin F. Kramer / Immigration and Treatment of Immigrants
  ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Brian Chisholm / Immigration and Treatment of Immigrants
  ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Brian Chisholm / Reproductive Rights and Abortion Access
  ('898845f9-cb93-4162-b0ed-6842eacda5d6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Brian M. Crosby / Reproductive Rights and Abortion Access
  ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Bryan W. Simonaire / Immigration and Treatment of Immigrants
  ('47823046-7dea-4a4f-a11b-0c5890539891', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- C. Anthony Muse / Immigration and Treatment of Immigrants
  ('47823046-7dea-4a4f-a11b-0c5890539891', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- C. Anthony Muse / Same-Sex Marriage
  ('7ced90a8-39dc-447e-ba33-e3af4cd47473', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Chao Wu / Reproductive Rights and Abortion Access
  ('7ced90a8-39dc-447e-ba33-e3af4cd47473', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Chao Wu / Same-Sex Marriage
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'), -- Cheryl C. Kagan / Transgender Athletes
  ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Cheryl E. Pasteur / Reproductive Rights and Abortion Access
  ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Chris West / Immigration and Treatment of Immigrants
  ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Cory V. McCray / Immigration and Treatment of Immigrants
  ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Cory V. McCray / Same-Sex Marriage
  ('a4b61b58-9006-4e58-952d-abeb2521cda0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Courtney Watson / Reproductive Rights and Abortion Access
  ('fb714c92-166f-4cc1-bb6b-19988a81cefe', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Dalya Attar / Immigration and Treatment of Immigrants
  ('fb714c92-166f-4cc1-bb6b-19988a81cefe', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Dalya Attar / Reproductive Rights and Abortion Access
  ('fb714c92-166f-4cc1-bb6b-19988a81cefe', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Dalya Attar / Same-Sex Marriage
  ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Dana Jones / Reproductive Rights and Abortion Access
  ('e94337e1-4776-4058-87b4-32dfeb7732a0', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Dana Stein / Same-Sex Marriage
  ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Darrell Odom / Immigration and Treatment of Immigrants
  ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Debra Davis / Reproductive Rights and Abortion Access
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Dylan Behler / Reproductive Rights and Abortion Access
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Dylan Behler / Taxation and Public Spending
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Gabriel M. Moreno / Same-Sex Marriage
  ('6d95657c-6c46-4aab-886f-f9688adc7b33', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Harry Bhandari / Reproductive Rights and Abortion Access
  ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Jack Bailey / Immigration and Treatment of Immigrants
  ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Jack Bailey / Reproductive Rights and Abortion Access
  ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Jack Bailey / Same-Sex Marriage
  ('e2ca1bfd-255d-417b-a9d7-424e6c10749d', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Jason C. Gallion / Immigration and Treatment of Immigrants
  ('e2ca1bfd-255d-417b-a9d7-424e6c10749d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Jason C. Gallion / Reproductive Rights and Abortion Access
  ('f45e2178-2a05-4974-8af8-379662412060', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Jen Terrasa / Same-Sex Marriage
  ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Jessica Feldmark / Same-Sex Marriage
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Jim Rosapepe / Immigration and Treatment of Immigrants
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Jim Rosapepe / Same-Sex Marriage
  ('4a7dc8a6-2138-4472-8197-8b878034f029', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Joanne C. Benson / Immigration and Treatment of Immigrants
  ('4a7dc8a6-2138-4472-8197-8b878034f029', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Joanne C. Benson / Same-Sex Marriage
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Kevin M. Harris / Reproductive Rights and Abortion Access
  ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Kim Ross / Same-Sex Marriage
  ('13462ee2-0dd9-4f70-809f-a813c23951d4', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- LaToya Nkongolo / Immigration and Treatment of Immigrants
  ('13462ee2-0dd9-4f70-809f-a813c23951d4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- LaToya Nkongolo / Reproductive Rights and Abortion Access
  ('13462ee2-0dd9-4f70-809f-a813c23951d4', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'), -- LaToya Nkongolo / Transgender Athletes
  ('9d191d69-084f-4941-bc0a-c59d336f032e', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Malcolm Augustine / Immigration and Treatment of Immigrants
  ('9d191d69-084f-4941-bc0a-c59d336f032e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Malcolm Augustine / Reproductive Rights and Abortion Access
  ('9d191d69-084f-4941-bc0a-c59d336f032e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Malcolm Augustine / Same-Sex Marriage
  ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Mary Beth Carozza / Immigration and Treatment of Immigrants
  ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Mary Beth Carozza / Same-Sex Marriage
  ('18313901-28d8-464c-9368-2873577e9d44', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Mary-Dulany James / Immigration and Treatment of Immigrants
  ('18313901-28d8-464c-9368-2873577e9d44', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Mary-Dulany James / Reproductive Rights and Abortion Access
  ('18313901-28d8-464c-9368-2873577e9d44', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Mary-Dulany James / Same-Sex Marriage
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- N. Scott Phillips / Reproductive Rights and Abortion Access
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- N. Scott Phillips / Same-Sex Marriage
  ('81b8bae9-0b0f-43de-8079-c0b605e12cec', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Nancy J. King / Immigration and Treatment of Immigrants
  ('81b8bae9-0b0f-43de-8079-c0b605e12cec', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), -- Nancy J. King / Medicare / Medicaid
  ('81b8bae9-0b0f-43de-8079-c0b605e12cec', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Nancy J. King / Same-Sex Marriage
  ('38b5030a-aa8b-4363-8b62-3ec384d22088', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Natalie Ziegler / Reproductive Rights and Abortion Access
  ('38b5030a-aa8b-4363-8b62-3ec384d22088', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Natalie Ziegler / Same-Sex Marriage
  ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Nicholaus R. Kipke / Same-Sex Marriage
  ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'), -- Nicholaus R. Kipke / Transgender Athletes
  ('cf190bac-9369-4175-bd4b-8ba776697d9c', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Nick Charles / Immigration and Treatment of Immigrants
  ('cf190bac-9369-4175-bd4b-8ba776697d9c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Nick Charles / Reproductive Rights and Abortion Access
  ('cf190bac-9369-4175-bd4b-8ba776697d9c', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Nick Charles / Same-Sex Marriage
  ('589ed7af-602a-4ec9-8072-448b05446772', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Pam Lanman Guzzone / Reproductive Rights and Abortion Access
  ('589ed7af-602a-4ec9-8072-448b05446772', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Pam Lanman Guzzone / Same-Sex Marriage
  ('409ad653-a4fc-41d0-bb61-a933c5bc45c7', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Pamela Beidle / Immigration and Treatment of Immigrants
  ('409ad653-a4fc-41d0-bb61-a933c5bc45c7', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Pamela Beidle / Same-Sex Marriage
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Ron Watson / Immigration and Treatment of Immigrants
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c', '7bad33eb-e93e-4d94-8822-97212d49bde5'), -- Ron Watson / Police Accountability
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Ron Watson / Reproductive Rights and Abortion Access
  ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Seth A. Howard / Immigration and Treatment of Immigrants
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac', '4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Shaneka Henson / Immigration and Treatment of Immigrants
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Shaneka Henson / Reproductive Rights and Abortion Access
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'), -- Shaneka Henson / Same-Sex Marriage
  ('55d9d0b6-78a3-460b-97b9-87913ffc8e85', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Stuart Michael Schmidt, Jr. / Reproductive Rights and Abortion Access
  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), -- Terri L. Hill / Medicare / Medicaid
  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6')  -- Terri L. Hill / Same-Sex Marriage
;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM _retire_1678;
  IF v <> 82 THEN RAISE EXCEPTION 'expected 82 target pairs, got %', v; END IF;

  -- Every target must still exist and still be published, or the corpus moved under the audit.
  SELECT count(*) INTO v FROM _retire_1678 r
    JOIN inform.politician_answers a ON a.politician_id=r.politician_id AND a.topic_id=r.topic_id;
  IF v <> 82 THEN RAISE EXCEPTION 'expected 82 live answers to retire, found % -- corpus changed since audit', v; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1678 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1678 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM inform.politician_answers a
    JOIN _retire_1678 r ON r.politician_id=a.politician_id AND r.topic_id=a.topic_id;
  IF v <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v; END IF;

  SELECT count(*) INTO v FROM inform.politician_context c
    JOIN _retire_1678 r ON r.politician_id=c.politician_id AND r.topic_id=c.topic_id;
  IF v <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v; END IF;

  -- No profile may be emptied by this migration: a politician left with zero answers but a SET
  -- research timestamp reads as "we looked and found nothing", which would be a lie here.
  SELECT count(*) INTO v FROM (
    SELECT DISTINCT politician_id FROM _retire_1678) t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = t.politician_id);
  IF v <> 0 THEN RAISE EXCEPTION '% politician(s) emptied by this migration -- not expected, handle timestamps explicitly', v; END IF;
END $$;

COMMIT;
