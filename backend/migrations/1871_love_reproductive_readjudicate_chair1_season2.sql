-- 1871_love_reproductive_readjudicate_chair1_season2.sql
-- Sara Love / Reproductive Rights: RE-ADJUDICATE chair 2 -> chair 1 and write the row FORWARD into
-- Season 2 with the real instruments. One context row + one answer row INSERTED. Nothing updated,
-- nothing deleted, Season 1 untouched.
--
-- 🔴 THIS IS AN ADJUDICATION, NOT A CITATION FIX -- and the chair MOVES. Migration 1870 (Cardin)
-- carried its chair forward unchanged because the corrected evidence still supported it. Here the
-- corrected evidence does NOT support the stored chair, so the number changes. The decision was put
-- to the operator on 2026-09-17 with both options stated (re-adjudicate to 1, or write forward as a
-- documented blank) and the operator chose **chair 1**.
--
-- 🔴 WHY A FORWARD WRITE AND NOT A FIX. The defective row is in **Season 1, which is CLOSED and
-- IMMUTABLE** -- `inform.closed_season_is_immutable()` rejects any UPDATE there (ADR 0005 §1.6 step
-- 5), and its own error text names the remedy: *"write a row in the OPEN season -- it shadows the old
-- one on read without destroying history."* Season 2 is frozen for topics/chairs but **stances remain
-- open**, so this write is in bounds. The Season 1 row stays exactly as written, as the historical
-- record of what was once claimed.
--
-- WHAT WAS WRONG. The Season 1 reasoning reads: *"She voted YES on SB 798 (2023 Abortion Care Access
-- Act) and co-sponsored reproductive health legislation. Her district is strongly pro-choice."*
--   * SB0798 (2023) is real, but it is NOT the Abortion Care Access Act -- it is the crossfile of
--     HB0705, the Right to Reproductive Freedom constitutional amendment. The Abortion Care Access
--     Act is **2022 HB0937 / SB0890**. The row welded a 2023 bill number to a 2022 act's name.
--   * "voted YES" understates and mis-describes: she was a **Delegate**, and she **CO-SPONSORED**
--     the House bill rather than voting on the Senate crossfile.
--   * "Her district is strongly pro-choice" is an inference about voters, not evidence about her.
--
-- 🔴🔴 THE `love02` TRAP IS INSIDE OUR OWN CITATION. The stored source is
-- `…/Members/Details/love02` -- her **SENATOR** page (she joined the Senate 2024-06-13), which
-- returns **0 bills for 2021-2023**. The citation pointed at a page that structurally cannot support
-- its own claim. Her Delegate-era record is **`love01`**. ⚠ "Delegate Love" is also TWO PEOPLE in
-- this corpus (Mary Ann Love is the 2013/2014 one); both pages fetched below carry the title
-- "Members - Delegate Sara Love", which is what settles the identity.
--
-- EVIDENCE, verified 2026-09-17, each instrument two independent ways (her own session-scoped
-- sponsorship list AND the bill page's own sponsor list):
--   * **HB0937 / CH0056 (2022RS) "Abortion Care Access Act"** -- appears on `love01?ys=2022RS`; the
--     bill page's sponsor list names Love and links `love01`. Synopsis: establishes the Abortion Care
--     Clinical Training Program, *"establishing certain requirements regarding abortion services,
--     including provision and coverage requirements, for the Maryland Medical Assistance Program and
--     certain insurers; requiring the Governor to include in the annual budget bill an appropriation
--     of $3,500,000 to the Program"*.
--   * **HB0705 / CH0245 (2023RS) "Declaration of Rights - Right to Reproductive Freedom"**
--     (crossfile SB0798 / CH0244) -- appears on `love01?ys=2023RS`; the bill page links `love01`.
--     Synopsis: the fundamental right to reproductive freedom, *"prohibiting the State from, directly
--     or indirectly, denying, burdening, or abridging the right unless justified by a compelling
--     State interest achieved by the least restrictive means."*
--
-- ⚖ WHY THIS EVIDENCES CHAIR 1 SPECIFICALLY, and why chair 2 cannot stand. The ladder (revision 1):
--     1 = legal, accessible, and **publicly funded**, at **all stages**
--     2 = legal and accessible **through the second trimester**, rare exceptions afterward
--     3 = first trimester + rape / incest / maternal health
--   * **"publicly funded" appears in chair 1's text and in NO other chair on this ladder.** HB0937
--     mandates Medical Assistance (Medicaid) and insurer coverage and appropriates $3.5M a year.
--     That clause is a real discriminator, not a direction.
--   * **Chair 2's distinguishing feature -- a second-trimester cutoff -- is affirmatively
--     inconsistent with HB0705**, which bars the State from burdening the right absent a compelling
--     interest pursued by the least restrictive means, with no gestational qualifier anywhere in it.
--   * ⚠ THE HONEST LIMIT: neither instrument says "all stages" in those words. Chair 1 is reached
--     because it is the only chair on this ladder that both instruments are consistent with -- the
--     funding clause puts her at 1, and nothing in her record asserts the limit that would put her at
--     2. Stated here so it can be argued with rather than inferred from her party or her district.
--   * 🔑 This is a STRONGER basis than mig 1870's. Cardin's chair 1 rested on the funding clause
--     alone with the ladder's stage axis merely silent; here a second instrument affirmatively cuts
--     against the stage limit that defines chair 2.
--
-- editor_id is NULL -- the established value for automated writes in this season (458 of 3,128
-- Season 2 context rows already carry NULL). Borrowing a human editor's uuid would misattribute
-- authorship.
--
-- ⚠ NOT IN THIS MIGRATION: Sara Love's **Medicare-Medicaid** row (topic
-- `cab61e8a-64fe-4bbd-bc08-fe9914d0091b`, S1 chair 2, revision `92e96359-…`). It cites SB0539 (2023),
-- which is *Tri-County Council for Southern Maryland - Membership*, and "medicaid" appears in ZERO of
-- her six sessions 2019-2024. But the claim says "voted YES", and **a sponsorship index cannot test a
-- vote** -- that row needs MD roll calls before it can be retired or re-sourced. Untouched here.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_chair numeric; s2_existing int; rev_ok int;
BEGIN
  -- the Season 1 row must still be there, still chair 2, still citing the fused instrument
  SELECT pa.value INTO s1_chair
    FROM inform.politician_answers pa
   WHERE pa.politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND pa.topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND pa.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_chair IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1871: expected Season 1 chair 2 for Sara Love, found % -- state has moved, re-read before writing', s1_chair;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
     WHERE pc.politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'
       AND pc.topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
       AND pc.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
       AND pc.reasoning ILIKE '%798%'
  ) THEN
    RAISE EXCEPTION 'migration 1871: the Season 1 row no longer cites SB 798 -- has it already been corrected?';
  END IF;

  -- and Season 2 must NOT already carry this topic for her
  SELECT count(*) INTO s2_existing
    FROM inform.politician_context pc
   WHERE pc.politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND pc.topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_existing <> 0 THEN
    RAISE EXCEPTION 'migration 1871: Season 2 already has % row(s) for this politician/topic', s2_existing;
  END IF;

  -- 🔑 a chair NUMBER only means something against a revision: Season 1 and Season 2 must pin the
  -- SAME revision of this topic, or "1" would not assert what this migration argues it asserts.
  -- (Season 3 pins revision 5, where chair 1 is "no time limit" -- a different claim entirely.)
  SELECT count(*) INTO rev_ok
    FROM inform.season_questions sq
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND sq.topic_revision_id = 'dab46e5c-628a-4360-ad1d-3aaba61768f0';
  IF rev_ok <> 1 THEN
    RAISE EXCEPTION 'migration 1871: Season 2 does not pin revision dab46e5c for this topic -- chair 1 may not mean the same thing; re-adjudicate rather than carry it';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES (
  'c5d2cd24-170a-4f87-8fde-84216fe62806',
  'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  'dab46e5c-628a-4360-ad1d-3aaba61768f0',
  NULL,
  'As a Delegate, Love co-sponsored the Abortion Care Access Act (2022 HB0937, enacted as Chapter 56), which requires the Maryland Medical Assistance Program and private insurers to cover abortion care, establishes a clinical training program for abortion providers, and directs the Governor to appropriate $3,500,000 a year to it. She also co-sponsored the Right to Reproductive Freedom amendment to the Maryland Declaration of Rights (2023 HB0705, Chapter 245, crossfiled as SB0798), which prohibits the State from denying, burdening, or abridging the right to reproductive freedom unless it is justified by a compelling State interest achieved by the least restrictive means. Public funding of abortion care appears in stance 1 and in no other stance on this ladder, which is what places her here, and the 2023 amendment sets no gestational limit of the kind that defines stance 2. Neither instrument uses the words "all stages": stance 1 is reached because it is the only stance on this ladder that both instruments are consistent with.',
  ARRAY[
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0937?ys=2022RS',
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0705?ys=2023RS',
    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love01?ys=2022RS',
    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love01?ys=2023RS'
  ]
);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES (
  'c5d2cd24-170a-4f87-8fde-84216fe62806',
  'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  'dab46e5c-628a-4360-ad1d-3aaba61768f0',
  NULL,
  1
);

DO $$
DECLARE ctx int; ans numeric; bad int; s1_ctx int; s1_ans numeric;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1871: expected exactly 1 Season 2 context row, found %', ctx;
  END IF;

  SELECT value INTO ans FROM inform.politician_answers
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ans IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1871: expected Season 2 chair 1, found %', ans;
  END IF;

  -- the corrected row must not repeat the fused citation or the district inference
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning ILIKE '%SB 798%' OR reasoning ILIKE '%strongly pro-choice%');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1871: the corrected row still carries the fused citation or the district inference';
  END IF;

  -- and it must not cite the Senator page that cannot support a Delegate-era claim
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%love02%');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1871: the corrected row still cites the love02 Senator page';
  END IF;

  -- history must be intact and untouched: still there, still chair 2, still the old citation
  SELECT count(*) INTO s1_ctx FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND reasoning ILIKE '%798%';
  IF s1_ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1871: the Season 1 historical context row was altered -- it must survive verbatim';
  END IF;

  SELECT value INTO s1_ans FROM inform.politician_answers
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_ans IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1871: the Season 1 answer moved off chair 2 -- history must survive verbatim';
  END IF;
END $$;

COMMIT;
