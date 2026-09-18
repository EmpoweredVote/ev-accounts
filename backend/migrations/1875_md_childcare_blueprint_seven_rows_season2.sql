-- 1875_md_childcare_blueprint_seven_rows_season2.sql
-- Maryland / Childcare Affordability & Access: the SEVEN Blueprint rows that cite no instrument at
-- all. Re-sourced onto the HB1300 roll calls, and FOUR of them re-adjudicated chair 1 -> chair 2.
-- 14 rows INSERTED (7 context + 7 answers). Nothing updated, nothing deleted, Season 1 untouched.
--
-- ⚠ THE HANDOFF NOTE SAID "THE THREE CHILDCARE/BLUEPRINT ROWS" AND THE THREE WERE NEVER RECORDED.
-- The note is a compressed pointer with no fact behind it, so the set was re-derived from the data
-- instead of guessed. Of the 18 Season 1 childcare rows mentioning the Blueprint, **11 already cite an
-- instrument with a roll-call tally and 7 cite none** -- only Ballotpedia and a session-less member
-- page, with reasoning like *"has co-sponsored childcare affordability legislation"* naming no bill.
-- Those 7 are this migration. 🔑 **A COUNT IN A HANDOFF NOTE IS NOT A WORKLIST — re-derive the set
-- from the defect shape.**
--
-- THE SEVEN, and what the roll calls show (all voted YEA, all verified on the sheet itself):
--   House, HB1300 Third Reading, **96-41** (sheet /2020RS/votes/house/0397.pdf):
--     Adrienne A. Jones (as SPEAKER) · C. T. Wilson · Heather Bagnall · Mark S. Chang
--   Senate, HB1300 Third Reading, **37-9** (sheet /2020RS/votes/senate/0866.pdf):
--     Bill Ferguson (as MR. PRESIDENT) · Malcolm Augustine · Pamela Beidle
-- ⚠ Both are DIVIDED votes, so agreeing with the bill is a position rather than a formality.
--
-- 🔑🔑 **THE PRESIDING OFFICERS ARE RECORDED BY TITLE, NOT BY SURNAME.** Searching these sheets for
-- "Jones" or "Ferguson" returns **ZERO** and would have produced the false verdict *"she did not
-- vote"*. Jones appears as **Speaker**, Ferguson as **Mr. President**. Both confirmed independently on
-- their own 2020 member pages ("Speaker of the House" / "Senate President"), both cited below.
-- ⚠ And the surname would have been ambiguous anyway: the era has **two Joneses** (Adrienne A. =
-- slug `jones`, Dana = slug `jones01`).
-- 🔑 **MATCH SURNAMES WORD-BOUNDED.** A first pass scored "Chang" twice and read the second hit as an
-- absence -- it was the footer *"* Indicates Vote Change"*. `grep -w`, not substring.
--
-- 🔴🔴 **THE BILL PAGE SHOWS NO CHILDCARE CONTENT AND THAT PROVES NOTHING.** HB1300's synopsis has
-- **0** occurrences of "prekindergarten", "Child Care Scholarship" or "full-day" -- it describes
-- teacher quality, workforce boards and data verification, then ends in "etc.". **The ENACTED TEXT
-- (Ch. 36 of 2021, 11,913 lines) has 159 "prekindergarten" and names the Child Care Scholarship
-- Program.** A synopsis that truncates cannot support an absence verdict --
-- [[feedback_read_the_enacted_text_not_the_title]] applied to the SYNOPSIS.
-- 🔑 This also retroactively vindicates the 11 already-shipped rows, whose pre-K claim the bill page
-- alone appears to contradict.
--
-- ⚖ WHY CHAIR 2 FOR ALL SEVEN, and why chair 1 is excluded -- settled by one clause of the enacted
-- text. The ladder:
--   chair 1: "publicly funded universal childcare so that all families have access **regardless of
--             income**"
--   chair 2: "significantly expanding **subsidies** and provider grants to make childcare affordable
--             for **low- and middle-income** families"
-- Ch. 36 requires the Department to **establish a sliding scale for the FAMILY SHARE**: a lower limit
-- of **$0 per pupil for a family at 300% of the federal poverty level**, rising linearly to the **full
-- per pupil amount for a family between 300% and 600% of FPL**. **The programme is means-tested by
-- construction**, so chair 1's "regardless of income" is affirmatively contradicted by the instrument
-- itself, and chair 2's "low- and middle-income" is what the sliding scale describes.
-- ▶ **Four rows therefore MOVE 1 -> 2** (Jones, Wilson, Bagnall, Chang); **three were already at 2**
-- (Ferguson, Augustine, Beidle) and change only their evidence.
-- ⚠ HONEST LIMIT, written into every row: this is one vote on a broad education act, not a standalone
-- childcare bill. It places them with the Blueprint's approach; it does not evidence a separate
-- childcare programme of their own. ⚠ The replaced text claimed each had "co-sponsored childcare
-- affordability legislation" -- that claim is simply dropped rather than restated, because nothing
-- was cited for it: cite the part the evidence shows and delete the rest.
--
-- 🔴 The revision differs between seasons (as in 1872/1873): Season 1 pins revision 1
-- (`30cb4666-…`), Season 2 pins revision 2 (`0e9fe0f2-…`). Chairs 1, 2, 3 and 5 are textually
-- IDENTICAL across the two, and only chair 4 was rewritten -- but the pin is still asserted below
-- rather than assumed, because a chair number means nothing except against a revision.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_rows int; s1_ch1 int; s1_ch2 int; s2_rows int; s2_rev uuid;
BEGIN
  -- all seven Season 1 rows must be present, on revision 1, with the chair split this migration assumes
  SELECT count(*) INTO s1_rows
    FROM inform.politician_answers pa
   WHERE pa.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND pa.topic_revision_id = '30cb4666-836f-4f13-a8c3-2c3caadf6337'
     AND pa.politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7');
  IF s1_rows <> 7 THEN
    RAISE EXCEPTION 'migration 1875: expected 7 Season 1 rows on revision 30cb4666, found % -- state has moved', s1_rows;
  END IF;

  SELECT count(*) FILTER (WHERE pa.value = 1), count(*) FILTER (WHERE pa.value = 2)
    INTO s1_ch1, s1_ch2
    FROM inform.politician_answers pa
   WHERE pa.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND pa.politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7');
  IF s1_ch1 <> 4 OR s1_ch2 <> 3 THEN
    RAISE EXCEPTION 'migration 1875: expected a 4/3 split at chairs 1/2 in Season 1, found %/% -- re-read before writing', s1_ch1, s1_ch2;
  END IF;

  -- none of the seven may already have a Season 2 row
  SELECT count(*) INTO s2_rows
    FROM inform.politician_context pc
   WHERE pc.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND pc.politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7');
  IF s2_rows <> 0 THEN
    RAISE EXCEPTION 'migration 1875: Season 2 already holds % of these rows -- this is a forward write', s2_rows;
  END IF;

  -- Season 2 must pin revision 2 for this topic, and it must differ from Season 1's pin
  SELECT sq.topic_revision_id INTO s2_rev
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND tr.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
  IF s2_rev IS DISTINCT FROM '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid THEN
    RAISE EXCEPTION 'migration 1875: Season 2 pins % for this topic, not revision 2 (0e9fe0f2)', s2_rev;
  END IF;
  IF s2_rev = '30cb4666-836f-4f13-a8c3-2c3caadf6337'::uuid THEN
    RAISE EXCEPTION 'migration 1875: Season 1 and Season 2 now pin the SAME revision -- re-read both ladders';
  END IF;

  -- the two rungs the adjudication turns on must still read as argued
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '0e9fe0f2-cfab-4553-99cd-c3195d08e236'
       AND sr.value = 1 AND sr.text ILIKE '%regardless of income%'
  ) THEN
    RAISE EXCEPTION 'migration 1875: revision 2 chair 1 no longer says "regardless of income" -- that is what the family-share sliding scale excludes';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '0e9fe0f2-cfab-4553-99cd-c3195d08e236'
       AND sr.value = 2 AND sr.text ILIKE '%low- and middle-income%'
  ) THEN
    RAISE EXCEPTION 'migration 1875: revision 2 chair 2 no longer says "low- and middle-income" -- re-read before seating';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid,
       'c1ac1330-47f7-44ec-baf3-c913d926b97c',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '0e9fe0f2-cfab-4553-99cd-c3195d08e236',
       NULL,
       v.reasoning,
       v.sources
FROM (VALUES
  ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
   'Jones voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The House vote sheet records the presiding officer as Speaker rather than by surname, and Jones was Speaker of the House on that date. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places her with the Blueprint''s approach rather than evidencing a separate childcare programme of her own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones?ys=2020RS']),

  ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
   'Wilson voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places him with the Blueprint''s approach rather than evidencing a separate childcare programme of his own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('41749b94-11b8-4047-8421-95db0900d4b2',
   'Bagnall voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places her with the Blueprint''s approach rather than evidencing a separate childcare programme of her own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
   'Chang voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the House, which passed it 96 to 41, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places him with the Blueprint''s approach rather than evidencing a separate childcare programme of his own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
   'Ferguson voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Senate vote sheet records the presiding officer as Mr. President rather than by surname, and Ferguson was Senate President on that date. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places him with the Blueprint''s approach rather than evidencing a separate childcare programme of his own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson?ys=2020RS']),

  ('9d191d69-084f-4941-bc0a-c59d336f032e',
   'Augustine voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places him with the Blueprint''s approach rather than evidencing a separate childcare programme of his own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1300?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf',
         'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf']),

  ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
   'Beidle voted for the Blueprint for Maryland''s Future (2020 HB1300) on third reading in the Senate, which passed it 37 to 9, and the bill became law as Chapter 36 of 2021 after the General Assembly overrode the Governor''s veto. The Act builds a publicly funded prekindergarten programme, and the enacted text sets its limits: the Department must establish a sliding scale for the family share, from no charge for a family at 300% of the federal poverty level up to the full per pupil amount for a family between 300% and 600%. Subsidy aimed at low- and middle-income families is what stance 2 describes, and the sliding scale is what rules out stance 1, which requires access regardless of income. This is one vote on a broad education act rather than a standalone childcare bill, so it places her with the Blueprint''s approach rather than evidencing a separate childcare programme of her own.',
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
       NULL,
       2
FROM (VALUES
  ('760cd4a7-235c-472f-a0ba-fb07098dfd57'),('69870c10-cea2-43c2-8cf9-bfcaf0b82265'),
  ('41749b94-11b8-4047-8421-95db0900d4b2'),('4a409af4-8568-42c3-bb72-7bb7500c96ce'),
  ('6e3c30f5-52be-48b0-b5b4-383e5d745c57'),('9d191d69-084f-4941-bc0a-c59d336f032e'),
  ('409ad653-a4fc-41d0-bb61-a933c5bc45c7')
) AS v(pid);

DO $$
DECLARE ctx int; ans int; bad int; s1_ch1 int; s1_ch2 int;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='0e9fe0f2-cfab-4553-99cd-c3195d08e236'
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7');
  IF ctx <> 7 THEN
    RAISE EXCEPTION 'migration 1875: expected 7 Season 2 context rows, found %', ctx;
  END IF;

  SELECT count(*) INTO ans FROM inform.politician_answers
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='0e9fe0f2-cfab-4553-99cd-c3195d08e236'
     AND value = 2
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7');
  IF ans <> 7 THEN
    RAISE EXCEPTION 'migration 1875: expected 7 Season 2 answers at chair 2 on revision 2, found %', ans;
  END IF;

  -- every new row must name the instrument, cite its own chamber sheet, and carry no Ballotpedia
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7')
     AND (reasoning NOT ILIKE '%HB1300%'
          OR NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%/2020RS/votes/%')
          OR EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%ballotpedia%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1875: % new row(s) fail the sourcing contract (no HB1300, no vote sheet, or a Ballotpedia source)', bad;
  END IF;

  -- history must be intact: still 4 at chair 1 and 3 at chair 2 on revision 1
  SELECT count(*) FILTER (WHERE pa.value = 1), count(*) FILTER (WHERE pa.value = 2)
    INTO s1_ch1, s1_ch2
    FROM inform.politician_answers pa
   WHERE pa.topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND pa.topic_revision_id = '30cb4666-836f-4f13-a8c3-2c3caadf6337'
     AND pa.politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','69870c10-cea2-43c2-8cf9-bfcaf0b82265',
       '41749b94-11b8-4047-8421-95db0900d4b2','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       '6e3c30f5-52be-48b0-b5b4-383e5d745c57','9d191d69-084f-4941-bc0a-c59d336f032e',
       '409ad653-a4fc-41d0-bb61-a933c5bc45c7');
  IF s1_ch1 <> 4 OR s1_ch2 <> 3 THEN
    RAISE EXCEPTION 'migration 1875: Season 1 moved (now %/% at chairs 1/2) -- history must survive verbatim', s1_ch1, s1_ch2;
  END IF;
END $$;

COMMIT;
