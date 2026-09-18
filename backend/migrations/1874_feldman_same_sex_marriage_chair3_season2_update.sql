-- 1874_feldman_same_sex_marriage_chair3_season2_update.sql
-- Brian J. Feldman / Same-Sex Marriage: re-source the EXISTING Season 2 row onto the instrument that
-- is actually on this ladder, and move it chair 2 -> chair 3 on that instrument's ENACTED TEXT.
-- Season 1 untouched.
--
-- 🔴🔴 THE FIRST ROW IN THIS SERIES THAT IS AN **UPDATE**, NOT TWO INSERTS. 1870/1871/1872/1873 all
-- wrote forward into an EMPTY Season 2 slot. Here Season 2 **already carries this topic** (written
-- 2026-09-03) and it is **voter-facing right now**, so there is nothing to write forward INTO --
-- the open-season row itself is the defective one and must be corrected in place. Season 2 is frozen
-- for topics/chairs but **stances remain open**, so an UPDATE here is in bounds; the immutable season
-- is Season 1, which this migration does not touch.
-- ⚠ Therefore the guards below assert **exactly one existing S2 row** and check `ROW_COUNT` on each
-- UPDATE. A forward-write guard ("S2 must have 0 rows") would be exactly wrong here.
--
-- WHAT WAS WRONG. The Season 2 reasoning reads: *"Feldman has consistently voted with the Democratic
-- caucus on LGBTQ+ rights and supported the expansion of legally protected healthcare to include
-- gender-affirming treatments (SB119 2024)."* Two separate defects:
--   * 🔴 **SB0119 (2024) IS OFF THIS LADDER.** It is *Legally Protected Health Care - Gender-Affirming
--     Treatment*. It is a real law and he really did vote for it (33-13) -- but it is trans health
--     care, and **it says nothing about marriage**. An instrument cannot seat a chair on a ladder it
--     does not speak to. (The same bill legitimately sources his Civil Rights row -- migration 1873.)
--   * 🔴 **"consistently voted with the Democratic caucus" is a PARTY PRIOR, not evidence.** Caucus
--     alignment is an inference about a group; a chair is a claim about a person.
-- ⚠ Sources were `ballotpedia.org/Brian_Feldman` plus a **bare, session-less** `Members/Details/feldman`
-- page -- which shows ONE session and so cannot carry a 2012 instrument at all.
--
-- 🔑 THE INSTRUMENT THAT IS ACTUALLY ON THIS LADDER: **HB0438 / CH0002 (2012RS), the Civil Marriage
-- Protection Act** -- Maryland's marriage-equality law -- which **Feldman CO-SPONSORED as a Delegate**.
-- 🔑🔑 IDENTITY IS SETTLED BY THE BILL PAGE ITSELF, NOT BY THE SURNAME. The sponsor list shows only
-- "Feldman", but the same page prints **"Delegate Brian J. Feldman, District 15"** in full. That is
-- the test; a surname in an MD sponsor list is not an identity.
-- 🔑 **PRE-2015 mgaleg NEEDS THE LEGACY PATH.** `Legislation/Details/HB0438?ys=2012RS` returns
-- **HTTP 500**. The bill file lives at `/2012rs/billfile/hb0438.htm` and the enacted text at
-- `/2012rs/chapters_noln/Ch_2_hb0438T.pdf`. Without that path this instrument is invisible.
--
-- ⚖ WHY CHAIR 3 AND NOT CHAIR 2 -- **DECIDED BY THE OPERATOR 2026-09-18**, on the enacted text.
-- The two rungs differ by exactly one thing:
--   chair 2: "Guarantee same-sex marriage the same benefits and protections as any other marriage."
--   chair 3: "Allow same-sex marriage, but protect religious organizations' right to decline to
--             perform or host these marriages."
-- The Act does BOTH halves of chair 3. Section 2 protects officials from being required to solemnize,
-- which is only the constitutional floor -- but the Act goes further: a religious organization
-- **"may not be required to provide services, accommodations, advantages, FACILITIES, goods, or
-- privileges"** related to the solemnization or celebration of a marriage, or to the promotion of
-- marriage through social or religious programs, in violation of its beliefs. **"Facilities" is the
-- hosting right in chair 3's own words.** Chair 2's only distinguishing feature against chair 3 is
-- the ABSENCE of such an exemption, and the bill he put his name to contains one.
-- ⚠ **READ THE ENACTED TEXT, NOT THE SYNOPSIS.** The bill-page synopsis mentions only the officiant
-- protection ("in violation of the constitutional right to free exercise"), which reads as the
-- clergy-only floor and would NOT have moved this row. The facilities/services clause appears only in
-- the chapter text.
-- ⚖ **THIS IS A CLASS-LEVEL PRECEDENT, WHICH IS WHY IT WENT TO THE OPERATOR:** essentially every
-- state marriage-equality act carries a religious exemption, so "the co-sponsor is seated at the
-- compromise he co-sponsored" will move other rows too, not only this one.
-- ✅ EXHAUSTIVENESS CHECKED BEFORE MOVING IT: his member pages for **all 13 sessions 2013-2025**
-- contain **zero** occurrences of "marriage". HB0438 is the whole of his record on this ladder, so
-- there is no later, exemption-free instrument that would override it.
-- ⚠ HONEST LIMIT, written into the row: this describes the framework he co-sponsored. It is not a
-- separate statement by him that religious organizations ought to be able to decline.
--
-- 🔑 `editor_id` on the context row moves from the human editor uuid `4e6dde8f-…` to **NULL**. After
-- this migration the row's text is entirely machine-written, and NULL is this season's established
-- marker for that; leaving a person's id on text they did not write would misattribute it. (The
-- answer row already carried NULL.)
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_chair numeric; s1_rev uuid; s2_ctx int; s2_chair numeric; s2_rev uuid;
BEGIN
  -- Season 1 must be intact and is NOT the target
  SELECT pa.value, pa.topic_revision_id INTO s1_chair, s1_rev
    FROM inform.politician_answers pa
   WHERE pa.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
     AND pa.topic_id      = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND pa.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_chair IS DISTINCT FROM 1 OR s1_rev IS DISTINCT FROM '5d26a058-0678-449e-ab76-85a31562c1f1'::uuid THEN
    RAISE EXCEPTION 'migration 1874: Season 1 is not chair 1 on revision 5d26a058 (found chair %, revision %) -- state has moved', s1_chair, s1_rev;
  END IF;

  -- 🔴 the Season 2 row MUST already exist -- this migration corrects it in place
  SELECT count(*) INTO s2_ctx FROM inform.politician_context pc
   WHERE pc.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
     AND pc.topic_id      = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1874: expected exactly 1 existing Season 2 context row to correct, found % -- this is an UPDATE migration, not a forward write', s2_ctx;
  END IF;

  SELECT pa.value, pa.topic_revision_id INTO s2_chair, s2_rev
    FROM inform.politician_answers pa
   WHERE pa.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
     AND pa.topic_id      = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND pa.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_chair IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1874: expected the Season 2 row at chair 2, found % -- has it already been re-adjudicated?', s2_chair;
  END IF;
  IF s2_rev IS DISTINCT FROM '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid THEN
    RAISE EXCEPTION 'migration 1874: Season 2 pins % for this topic, not revision 2 (8bc3d240) -- the adjudication was written against revision 2', s2_rev;
  END IF;

  -- it must still be the defective text
  IF NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
     WHERE pc.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
       AND pc.topic_id      = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
       AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
       AND pc.reasoning ILIKE '%SB119%'
  ) THEN
    RAISE EXCEPTION 'migration 1874: the Season 2 row no longer cites SB119 -- has it already been corrected?';
  END IF;

  -- chair 3 must still say the thing this adjudication rests on
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'
       AND sr.value = 3
       AND sr.text ILIKE '%decline to perform or host%'
  ) THEN
    RAISE EXCEPTION 'migration 1874: revision 2 chair 3 no longer reads "decline to perform or host" -- that clause is the whole basis';
  END IF;
END $$;

-- ⚠ Both UPDATEs run INSIDE a DO block on purpose. `GET DIAGNOSTICS n = ROW_COUNT` reports the last
-- statement executed **within the same PL/pgSQL function**, so a DO block placed after a bare UPDATE
-- would read 0 and fire a false failure. Keeping statement and check in one block makes the guard real.
DO $$
DECLARE n int;
BEGIN

UPDATE inform.politician_context SET
  reasoning = 'As a Delegate, Feldman co-sponsored the Civil Marriage Protection Act (2012 HB0438, enacted as Chapter 2), the law that opened civil marriage to same-sex couples in Maryland. The same Act provides that an official of a religious body may not be required to solemnize a marriage against the free exercise of religion, and that a religious organization may not be required to provide services, accommodations, advantages, facilities, goods, or privileges connected to the celebration or promotion of a marriage that violates its religious beliefs. Allowing same-sex marriage while protecting religious organizations that decline to perform or host one is the framework this Act creates, and it is the framework he put his name to. No marriage measure appears anywhere in his legislative record from 2013 through 2025, so this Act is the whole of it. Stance 2 differs from stance 3 only in leaving that exemption out. This describes the law he co-sponsored rather than a separate statement by him about religious exemptions.',
  sources = ARRAY[
    'https://mgaleg.maryland.gov/2012rs/billfile/hb0438.htm',
    'https://mgaleg.maryland.gov/2012rs/chapters_noln/Ch_2_hb0438T.pdf'
  ],
  editor_id = NULL
WHERE politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
  AND topic_id      = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
  AND season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1874: context UPDATE touched % rows, expected exactly 1', n;
  END IF;

UPDATE inform.politician_answers SET
  value = 3
WHERE politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
  AND topic_id      = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
  AND season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1874: answer UPDATE touched % rows, expected exactly 1', n;
  END IF;

END $$;

DO $$
DECLARE ctx int; ans numeric; ans_rev uuid; bad int; s1_chair numeric; s1_cites int;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1874: Season 2 should still hold exactly 1 context row, found % -- an UPDATE must not duplicate', ctx;
  END IF;

  SELECT value, topic_revision_id INTO ans, ans_rev FROM inform.politician_answers
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ans IS DISTINCT FROM 3 THEN
    RAISE EXCEPTION 'migration 1874: expected Season 2 chair 3, found %', ans;
  END IF;
  IF ans_rev IS DISTINCT FROM '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid THEN
    RAISE EXCEPTION 'migration 1874: the revision pin moved to % -- the chair number would assert a different ladder', ans_rev;
  END IF;

  -- the corrected row must cite the Act, and must carry none of the three original defects
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning NOT ILIKE '%HB0438%'
          OR reasoning ILIKE '%SB119%'
          OR reasoning ILIKE '%Democratic caucus%'
          OR EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%ballotpedia%' OR s ILIKE '%Members/Details%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1874: the corrected row still carries an off-ladder citation, the party prior, or a non-probative source';
  END IF;

  -- Season 1 must be untouched: still chair 1, still citing SB119 as the record of what was claimed
  SELECT value INTO s1_chair FROM inform.politician_answers
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_revision_id='5d26a058-0678-449e-ab76-85a31562c1f1';
  IF s1_chair IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1874: the Season 1 answer or its revision pin moved -- history must survive verbatim';
  END IF;

  SELECT count(*) INTO s1_cites FROM inform.politician_context
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND reasoning ILIKE '%SB119%';
  IF s1_cites <> 1 THEN
    RAISE EXCEPTION 'migration 1874: the Season 1 context row was altered -- it must survive verbatim';
  END IF;
END $$;

COMMIT;
