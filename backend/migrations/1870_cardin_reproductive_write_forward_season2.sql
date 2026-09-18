-- 1870_cardin_reproductive_write_forward_season2.sql
-- Jon S. Cardin / Reproductive Rights: write the row FORWARD into Season 2 with the correct
-- instrument. Chair is UNCHANGED at 1. One context row + one answer row INSERTED. Nothing updated,
-- nothing deleted, Season 1 untouched.
--
-- 🔴 WHY A FORWARD WRITE AND NOT A FIX. The defective row is in **Season 1, which is CLOSED and
-- IMMUTABLE** -- `inform.closed_season_is_immutable()` rejects any UPDATE there (ADR 0005 §1.6 step
-- 5), and its own error text names the remedy: *"write a row in the OPEN season -- it shadows the old
-- one on read without destroying history."* This migration is that remedy. The Season 1 row stays
-- exactly as written, as the historical record of what was once claimed.
-- ⚠ Season 2 is frozen for topics/chairs but **stances remain open**, so this write is in bounds.
--
-- WHAT WAS WRONG. The Season 1 reasoning reads: *"Cardin co-sponsored HB 1171 (Pregnant Person's
-- Freedom Act of 2024)…"*. Three separate errors:
--   * 2024 HB1171 is *Nonprescription Drugs and Devices* (Delegate Williams) -- not that Act.
--   * The Pregnant Person's Freedom Act is **2022**, HB0626 / SB0669. There is no 2024 version.
--   * Cardin sponsored NEITHER real 2022 bill. Full-text search of both bill pages (97KB and 98KB)
--     returns no "Cardin": HB0626 is Delegates Williams et al., SB0669 is Senator Smith.
--
-- 🔑 BUT THE CLAIM ITSELF IS TRUE -- A BAD CITATION IS NOT A FALSE CLAIM (the class-B lesson).
-- Cardin **co-sponsored HB0937 / CH0056 (2022RS), the "Abortion Care Access Act"**, which became
-- **Chapter 56 of 2022 over a GUBERNATORIAL VETO OVERRIDE**. Verified two independent ways before
-- writing: his own 2022 session sponsorship list, and the bill page's sponsor list (177KB, names
-- Cardin). Both cited below.
--
-- ⚖ WHY THIS EVIDENCES CHAIR 1 SPECIFICALLY, and the honest limit of that. This ladder is built on
-- gestational limits -- chair 1 "all stages", chair 2 "through the second trimester", chair 3 "first
-- trimester" -- and the Act is silent on stages, so it does NOT discriminate 1 from 2 on that axis.
-- What it does do is mandate insurance coverage (including Medicaid), remove the physician-only
-- restriction, and appropriate state money for clinical training. **"publicly funded" appears in
-- chair 1's text and in NO other chair on this ladder**, so the funding clause is a real
-- discriminator. Chair 1 is retained on that basis, not on "stages". Stated so it can be argued with.
--
-- 🔑 THE MEMBER PAGE TAKES A SESSION: `…/Members/Details/<id>?ys=<YYYY>RS`. This replaces the lost
-- 73k-bill corpus for targeted work -- six fetches cover a member's career. ⚠ Needed here because
-- Cardin has TWO service periods (elected 2002 and 2018) and his default member page shows only 2026.
--
-- editor_id is NULL -- the established value for automated writes in this season (458 of 3,128
-- Season 2 context rows already carry NULL). Borrowing a human editor's uuid would misattribute
-- authorship.
--
-- ⚠ NOT IN THIS MIGRATION: Sara Love's two rows. Her reproductive row's corrected evidence
-- (co-sponsor of BOTH the 2023 Right to Reproductive Freedom amendment AND the same 2022 Act) does
-- NOT support her stored chair 2 -- nothing in her record asserts a second-trimester limit, and the
-- funding act leans chair 1. Writing that forward would launder an under-determined chair into the
-- open season. It needs an adjudication decision, not a citation fix.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_chair numeric; s2_existing int; rev_ok int;
BEGIN
  -- the Season 1 row must still be there, still chair 1, still citing the bad instrument
  SELECT pa.value INTO s1_chair
    FROM inform.politician_answers pa
   WHERE pa.politician_id = '631dac5c-fb86-41f5-a82d-5963164a9142'
     AND pa.topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND pa.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_chair IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1870: expected Season 1 chair 1 for Cardin, found % -- state has moved', s1_chair;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
     WHERE pc.politician_id = '631dac5c-fb86-41f5-a82d-5963164a9142'
       AND pc.topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
       AND pc.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
       AND pc.reasoning ILIKE '%1171%'
  ) THEN
    RAISE EXCEPTION 'migration 1870: the Season 1 row no longer cites HB1171 -- has it already been corrected?';
  END IF;

  -- and Season 2 must NOT already carry this topic for him
  SELECT count(*) INTO s2_existing
    FROM inform.politician_context pc
   WHERE pc.politician_id = '631dac5c-fb86-41f5-a82d-5963164a9142'
     AND pc.topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_existing <> 0 THEN
    RAISE EXCEPTION 'migration 1870: Season 2 already has % row(s) for this politician/topic', s2_existing;
  END IF;

  -- 🔑 the chair NUMBER only means something against a revision: Season 1 and Season 2 must pin the
  -- SAME revision of this topic, or carrying "1" forward would silently change what it asserts.
  SELECT count(*) INTO rev_ok
    FROM inform.season_questions sq
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND sq.topic_revision_id = 'dab46e5c-628a-4360-ad1d-3aaba61768f0';
  IF rev_ok <> 1 THEN
    RAISE EXCEPTION 'migration 1870: Season 2 does not pin revision dab46e5c for this topic -- chair 1 may not mean the same thing; re-adjudicate rather than carry it';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES (
  '631dac5c-fb86-41f5-a82d-5963164a9142',
  'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  'dab46e5c-628a-4360-ad1d-3aaba61768f0',
  NULL,
  'Cardin co-sponsored the Abortion Care Access Act (2022 HB0937, enacted as Chapter 56 over a gubernatorial veto override), which requires insurance and Medicaid coverage of abortion care, removes the physician-only restriction on who may provide it, and appropriates state funding for clinical training. Public funding of abortion care appears in stance 1 and in no other stance on this ladder, which is what distinguishes it here; the Act is silent on gestational limits, so it does not by itself separate stance 1 from stance 2 on that axis.',
  ARRAY[
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0937?ys=2022RS',
    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01?ys=2022RS'
  ]
);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES (
  '631dac5c-fb86-41f5-a82d-5963164a9142',
  'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  'dab46e5c-628a-4360-ad1d-3aaba61768f0',
  NULL,
  1
);

DO $$
DECLARE ctx int; ans numeric; bad int; s1 int;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE politician_id='631dac5c-fb86-41f5-a82d-5963164a9142'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1870: expected exactly 1 Season 2 context row, found %', ctx;
  END IF;

  SELECT value INTO ans FROM inform.politician_answers
   WHERE politician_id='631dac5c-fb86-41f5-a82d-5963164a9142'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ans IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1870: expected Season 2 chair 1, found %', ans;
  END IF;

  -- the new row must not repeat the bad instrument
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='631dac5c-fb86-41f5-a82d-5963164a9142'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning ILIKE '%1171%' OR reasoning ILIKE '%Pregnant Person%');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1870: the corrected row still cites the bad instrument';
  END IF;

  -- history must be intact and untouched
  SELECT count(*) INTO s1 FROM inform.politician_context
   WHERE politician_id='631dac5c-fb86-41f5-a82d-5963164a9142'
     AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND reasoning ILIKE '%1171%';
  IF s1 <> 1 THEN
    RAISE EXCEPTION 'migration 1870: the Season 1 historical row was altered -- it must survive verbatim';
  END IF;
END $$;

COMMIT;
