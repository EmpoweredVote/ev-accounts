-- 1877_md_childcare_blueprint_eleven_forward_season2.sql
-- Maryland / Childcare Affordability & Access: write the ELEVEN instrument-cited Blueprint rows
-- forward into Season 2, and repair two bad member-page slugs while doing it. Chair is UNCHANGED at 2
-- for all eleven. 22 rows INSERTED. Plus ONE correction to a row this workstream wrote an hour ago
-- (migration 1875, Ferguson). Season 1 untouched.
--
-- WHY THESE ELEVEN. Surfaced by migration 1875: of the 18 Season 1 childcare rows naming the
-- Blueprint, 7 cited no instrument (fixed in 1875) and these 11 already cited HB1300 or SB1030 with a
-- roll-call tally. They were correct **but Season 1 only** -- living on the closed revision-1 ladder
-- with no open-season row, so a reader gets the old ladder's meaning. This writes them forward.
--
-- 🔑 THEY WERE RE-VERIFIED, NOT COPIED FORWARD ON TRUST. A prior pass's verdict is not evidence; the
-- claims were checked again against the sheets and the enacted text:
--   * **All 11 voted YEA**, each a single word-bounded hit in the Yea block of the correct chamber's
--     sheet -- House Third Reading **96-41** (`/2020RS/votes/house/0397.pdf`), Senate Third Reading
--     **37-9** (`/2020RS/votes/senate/0866.pdf`). Both DIVIDED, so both discriminate.
--   * **"one of 7 sponsors of HB1300"** (Washington) -- CONFIRMED: the sponsor line is The Speaker
--     (By Request - Commission on Innovation and Excellence in Education) and Delegates McIntosh,
--     Kaiser, B. Barnes, Ebersole, M. Jackson, Luedtke, **and Washington** = exactly 7.
--   * **"one of 19 sponsors of SB1030 (2019)"** (Ellis, Waldstreicher) -- CONFIRMED: King, Pinsky,
--     Ferguson, Young, Peters, Zucker, Elfreth, McCray, Guzzone, Feldman, Hayes, Kelley, Lam,
--     Patterson, Lee, Hester, **Ellis**, **Waldstreicher**, Zirkin = exactly 19.
--   * The pre-K description was checked in the ENACTED TEXT rather than the synopsis: Ch. 36 defines
--     **"full day"** as not less than 7 and not more than 12 hours, and §(F) gives **income-eligible
--     families access to extended day services through the CHILD CARE SCHOLARSHIP PROGRAM**. Both
--     halves of the original sentence hold.
--
-- 🔴🔴 **TWO WATSONS, AND THE SHEET DISAMBIGUATES THEM.** The 2020 House Yea list carries
-- **"Watson, C."** and **"Watson, R."** on consecutive lines. Ron Watson is **Watson, R.**; Courtney
-- Watson is a different delegate who is ALSO in our data with her own rows. A bare `grep Watson`
-- returns two hits and settles nothing.
-- ⚠ **The roster note listing the House collisions as "Johnson, Jones, Long, Morgan" is INCOMPLETE --
-- add WATSON.** Slugs: **`watson03` = Ron Watson**, **`watson02` = Courtney Watson**.
--
-- 🔴 TWO BAD SOURCES REPAIRED IN PASSING (both would survive any link-checker that only tests HTTP):
--   * **Ron Watson's row cited `Members/Details/watson04`, which does not resolve (302).** Replaced
--     with the session-scoped `watson03?ys=2020RS`, whose title reads "Delegate Ron Watson".
--   * **Sara Love's row cited `Members/Details/love02` -- her SENATOR page -- for a 2020 HOUSE vote.**
--     This is the third row in this workstream carrying that exact defect (see 1871, 1872). Replaced
--     with `love01?ys=2020RS`, "Delegate Sara Love".
-- ⚠ Every one of the eleven also carried a **Ballotpedia** link and a **session-less** member page.
-- Both are dropped: a session-less mgaleg page shows ONE session and cannot carry a 2020 vote.
-- ⚠ William C. Smith's row additionally carried `hb1372?ys=2021RS` and a 2021 Senate sheet that its
-- own reasoning never mentions. Dropped -- cite what the text actually claims.
--
-- ⚖ CHAIR 2 IS UNCHANGED AND IS RE-ARGUED AGAINST REVISION 2, not carried on trust. Ch. 36 orders a
-- **sliding scale for the FAMILY SHARE** -- $0 per pupil at **300% of the federal poverty level**,
-- rising to the **full per pupil amount between 300% and 600%** -- so the programme is means-tested by
-- construction and chair 1's *"regardless of income"* is contradicted by the instrument itself.
-- Chair 2's *"low- and middle-income"* is what the scale describes. Same basis as migration 1875.
--
-- 🔴 Season 1 pins revision 1 (`30cb4666-…`), Season 2 pins revision 2 (`0e9fe0f2-…`). Chairs 1, 2, 3
-- and 5 are textually identical across them and only chair 4 was rewritten, but the pin is asserted
-- rather than assumed.
--
-- ⚠ ALSO IN THIS MIGRATION: a correction to **Bill Ferguson's Season 2 row from migration 1875**.
-- That row cites only his HB1300 vote -- but he is **one of the 19 sponsors of SB1030 (2019)**, the
-- Blueprint's originating bill, which is stronger evidence than a vote and was missed an hour ago.
-- The chair does not change; the row now states the sponsorship. **Understating the evidence is a
-- smaller defect than overstating it, but it is still worth fixing in the row rather than in a note.**
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_rows int; s2_rows int; s2_rev uuid; fergie int;
BEGIN
  SELECT count(*) INTO s1_rows
    FROM inform.politician_answers pa
   WHERE pa.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND pa.topic_revision_id = '30cb4666-836f-4f13-a8c3-2c3caadf6337'
     AND pa.value = 2
     AND pa.politician_id IN (
       '8c8b0896-dfd0-4d3c-8492-e594d93b78ca','4754dede-4a3b-4280-a8b1-7497530107f7',
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1','da75c207-bb23-477e-b3c0-7c462394b570',
       '9c400214-f007-4a8d-92fe-5f5d23b3838e','4a7dc8a6-2138-4472-8197-8b878034f029',
       'cf190bac-9369-4175-bd4b-8ba776697d9c','9aef8bfb-8e0c-4f00-9898-c738abe4970c',
       'c5d2cd24-170a-4f87-8fde-84216fe62806','05c9b5b9-cb2b-4387-ab6b-350b69553fac',
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc');
  IF s1_rows <> 11 THEN
    RAISE EXCEPTION 'migration 1877: expected 11 Season 1 rows at chair 2 on revision 30cb4666, found % -- state has moved', s1_rows;
  END IF;

  SELECT count(*) INTO s2_rows
    FROM inform.politician_context pc
   WHERE pc.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND pc.politician_id IN (
       '8c8b0896-dfd0-4d3c-8492-e594d93b78ca','4754dede-4a3b-4280-a8b1-7497530107f7',
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1','da75c207-bb23-477e-b3c0-7c462394b570',
       '9c400214-f007-4a8d-92fe-5f5d23b3838e','4a7dc8a6-2138-4472-8197-8b878034f029',
       'cf190bac-9369-4175-bd4b-8ba776697d9c','9aef8bfb-8e0c-4f00-9898-c738abe4970c',
       'c5d2cd24-170a-4f87-8fde-84216fe62806','05c9b5b9-cb2b-4387-ab6b-350b69553fac',
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc');
  IF s2_rows <> 0 THEN
    RAISE EXCEPTION 'migration 1877: Season 2 already holds % of these rows -- this is a forward write', s2_rows;
  END IF;

  SELECT sq.topic_revision_id INTO s2_rev
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND tr.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
  IF s2_rev IS DISTINCT FROM '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid THEN
    RAISE EXCEPTION 'migration 1877: Season 2 pins % for this topic, not revision 2 (0e9fe0f2)', s2_rev;
  END IF;
  IF s2_rev = '30cb4666-836f-4f13-a8c3-2c3caadf6337'::uuid THEN
    RAISE EXCEPTION 'migration 1877: Season 1 and Season 2 now pin the SAME revision -- re-read both ladders';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '0e9fe0f2-cfab-4553-99cd-c3195d08e236'
       AND sr.value = 2 AND sr.text ILIKE '%low- and middle-income%'
  ) THEN
    RAISE EXCEPTION 'migration 1877: revision 2 chair 2 no longer says "low- and middle-income"';
  END IF;

  -- the Ferguson row written by migration 1875 must be there, at chair 2, and must NOT yet mention SB1030
  SELECT count(*) INTO fergie
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id AND pa.season_id=pc.season_id
   WHERE pc.politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'
     AND pc.topic_id      = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND pa.value = 2
     AND pc.reasoning NOT ILIKE '%SB1030%';
  IF fergie <> 1 THEN
    RAISE EXCEPTION 'migration 1877: expected exactly 1 Ferguson Season 2 row at chair 2 without SB1030, found % -- has 1875 changed?', fergie;
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid,
       'c1ac1330-47f7-44ec-baf3-c913d926b97c',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '0e9fe0f2-cfab-4553-99cd-c3195d08e236',
       NULL, v.reasoning, v.sources
FROM (VALUES
  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
   'Washington was one of the seven delegate sponsors of the Blueprint for Maryland''s Future (2020 HB1300), alongside McIntosh, Kaiser, B. Barnes, Ebersole, M. Jackson and Luedtke, and he voted for it on third reading in the House, which passed it 96 to 41. It became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('4754dede-4a3b-4280-a8b1-7497530107f7',
   'Ellis was one of the nineteen senate sponsors of the 2019 Blueprint for Maryland''s Future bill (SB1030), and he voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9. It became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB1030?ys=2019RS',
         'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
   'Kagan voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('da75c207-bb23-477e-b3c0-7c462394b570',
   'Waldstreicher was one of the nineteen senate sponsors of the 2019 Blueprint for Maryland''s Future bill (SB1030), and he voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9. It became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB1030?ys=2019RS',
         'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
   'Rosapepe voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('4a7dc8a6-2138-4472-8197-8b878034f029',
   'Benson voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('cf190bac-9369-4175-bd4b-8ba776697d9c',
   'Charles voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
   'Watson voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. Two delegates named Watson sat in that chamber, and the vote sheet separates them: Ron Watson is recorded as Watson, R. and Courtney Watson as Watson, C., both voting in favour. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson03?ys=2020RS']),

  ('c5d2cd24-170a-4f87-8fde-84216fe62806',
   'As a Delegate, Love voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love01?ys=2020RS']),

  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
   'Henson voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
   'Smith voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and it became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf'])
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid,
       'c1ac1330-47f7-44ec-baf3-c913d926b97c',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '0e9fe0f2-cfab-4553-99cd-c3195d08e236',
       NULL, 2
FROM (VALUES
  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'),('4754dede-4a3b-4280-a8b1-7497530107f7'),
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'),('da75c207-bb23-477e-b3c0-7c462394b570'),
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e'),('4a7dc8a6-2138-4472-8197-8b878034f029'),
  ('cf190bac-9369-4175-bd4b-8ba776697d9c'),('9aef8bfb-8e0c-4f00-9898-c738abe4970c'),
  ('c5d2cd24-170a-4f87-8fde-84216fe62806'),('05c9b5b9-cb2b-4387-ab6b-350b69553fac'),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc')
) AS v(pid);

-- ⚠ the UPDATE runs inside a DO block so GET DIAGNOSTICS ROW_COUNT actually sees it (see 1874).
DO $$
DECLARE n int;
BEGIN
UPDATE inform.politician_context SET
  reasoning = 'Ferguson was one of the nineteen senate sponsors of the 2019 Blueprint for Maryland''s Future bill (SB1030), and as Senate President he voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading, which the Senate passed 37 to 9. It became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Senate vote sheet records the presiding officer as Mr. President rather than by surname, and Ferguson was Senate President on that date. The Act creates a publicly funded prekindergarten programme, defines a full day as no less than seven and no more than twelve hours, and gives income-eligible families access to extended day services through the Child Care Scholarship Program. It is not universal: the Department must set a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Public subsidy aimed at low- and middle-income families is what stance 2 describes, and that sliding scale is what rules out stance 1, which requires access regardless of income.',
  sources = ARRAY[
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB1030?ys=2019RS',
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
    'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
    'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf',
    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson?ys=2020RS'
  ]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'
  AND topic_id      = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
  AND season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1877: Ferguson UPDATE touched % rows, expected exactly 1', n;
  END IF;
END $$;

DO $$
DECLARE ctx int; ans int; bad int; s1 int; ferg int;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='0e9fe0f2-cfab-4553-99cd-c3195d08e236'
     AND politician_id IN (
       '8c8b0896-dfd0-4d3c-8492-e594d93b78ca','4754dede-4a3b-4280-a8b1-7497530107f7',
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1','da75c207-bb23-477e-b3c0-7c462394b570',
       '9c400214-f007-4a8d-92fe-5f5d23b3838e','4a7dc8a6-2138-4472-8197-8b878034f029',
       'cf190bac-9369-4175-bd4b-8ba776697d9c','9aef8bfb-8e0c-4f00-9898-c738abe4970c',
       'c5d2cd24-170a-4f87-8fde-84216fe62806','05c9b5b9-cb2b-4387-ab6b-350b69553fac',
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc');
  IF ctx <> 11 THEN
    RAISE EXCEPTION 'migration 1877: expected 11 Season 2 context rows, found %', ctx;
  END IF;

  SELECT count(*) INTO ans FROM inform.politician_answers
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='0e9fe0f2-cfab-4553-99cd-c3195d08e236'
     AND value = 2
     AND politician_id IN (
       '8c8b0896-dfd0-4d3c-8492-e594d93b78ca','4754dede-4a3b-4280-a8b1-7497530107f7',
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1','da75c207-bb23-477e-b3c0-7c462394b570',
       '9c400214-f007-4a8d-92fe-5f5d23b3838e','4a7dc8a6-2138-4472-8197-8b878034f029',
       'cf190bac-9369-4175-bd4b-8ba776697d9c','9aef8bfb-8e0c-4f00-9898-c738abe4970c',
       'c5d2cd24-170a-4f87-8fde-84216fe62806','05c9b5b9-cb2b-4387-ab6b-350b69553fac',
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc');
  IF ans <> 11 THEN
    RAISE EXCEPTION 'migration 1877: expected 11 Season 2 answers at chair 2 on revision 2, found %', ans;
  END IF;

  -- the sourcing contract: names HB1300, cites its own 2020RS sheet, and carries none of the
  -- three defects found in the Season 1 sources (Ballotpedia, the love02 Senator page, the dead
  -- watson04 slug)
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN (
       '8c8b0896-dfd0-4d3c-8492-e594d93b78ca','4754dede-4a3b-4280-a8b1-7497530107f7',
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1','da75c207-bb23-477e-b3c0-7c462394b570',
       '9c400214-f007-4a8d-92fe-5f5d23b3838e','4a7dc8a6-2138-4472-8197-8b878034f029',
       'cf190bac-9369-4175-bd4b-8ba776697d9c','9aef8bfb-8e0c-4f00-9898-c738abe4970c',
       'c5d2cd24-170a-4f87-8fde-84216fe62806','05c9b5b9-cb2b-4387-ab6b-350b69553fac',
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc')
     AND (reasoning NOT ILIKE '%HB1300%'
          OR NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%/2020RS/votes/%')
          OR EXISTS (SELECT 1 FROM unnest(sources) s
                      WHERE s ILIKE '%ballotpedia%' OR s ILIKE '%love02%' OR s ILIKE '%watson04%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1877: % new row(s) fail the sourcing contract', bad;
  END IF;

  -- Ferguson now carries the sponsorship, still at chair 2
  SELECT count(*) INTO ferg FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id AND pa.season_id=pc.season_id
   WHERE pc.politician_id='6e3c30f5-52be-48b0-b5b4-383e5d745c57'
     AND pc.topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND pc.reasoning ILIKE '%SB1030%'
     AND pa.value = 2;
  IF ferg <> 1 THEN
    RAISE EXCEPTION 'migration 1877: Ferguson row does not carry SB1030 at chair 2 after the update';
  END IF;

  -- history intact: all 11 still at chair 2 on revision 1
  SELECT count(*) INTO s1 FROM inform.politician_answers
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_revision_id='30cb4666-836f-4f13-a8c3-2c3caadf6337'
     AND value = 2
     AND politician_id IN (
       '8c8b0896-dfd0-4d3c-8492-e594d93b78ca','4754dede-4a3b-4280-a8b1-7497530107f7',
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1','da75c207-bb23-477e-b3c0-7c462394b570',
       '9c400214-f007-4a8d-92fe-5f5d23b3838e','4a7dc8a6-2138-4472-8197-8b878034f029',
       'cf190bac-9369-4175-bd4b-8ba776697d9c','9aef8bfb-8e0c-4f00-9898-c738abe4970c',
       'c5d2cd24-170a-4f87-8fde-84216fe62806','05c9b5b9-cb2b-4387-ab6b-350b69553fac',
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc');
  IF s1 <> 11 THEN
    RAISE EXCEPTION 'migration 1877: Season 1 moved (% of 11 still at chair 2) -- history must survive verbatim', s1;
  END IF;
END $$;

COMMIT;
