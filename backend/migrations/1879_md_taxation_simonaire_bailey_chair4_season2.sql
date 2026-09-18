-- 1879_md_taxation_simonaire_bailey_chair4_season2.sql
-- Bryan W. Simonaire and Jack Bailey / Taxation and Public Spending: correct two FLAT INVERSIONS and
-- write both forward into Season 2 at chair 4. 4 rows INSERTED. Season 1 untouched.
--
-- 🔴🔴 THE DEFECT IS AN INVERSION, NOT A CITATION. Both rows state the OPPOSITE of the politician's
-- own described position:
--   * **Simonaire, Season 1 chair 1** = *"Significantly raise taxes on wealthy people and large
--     companies"*, with reasoning *"is a consistent tax opponent… has led opposition to tax increases
--     including Blueprint for Maryland's Future funding mechanisms and corporate tax hikes."*
--   * **Bailey, Season 1 chair 2** = *"Moderately raise taxes…"*, with reasoning *"consistently votes
--     against tax increases… has argued for lower business taxes."*
-- Both are Republicans **displayed to voters as tax-raisers**. The evidence below confirms each row's
-- own reasoning and refutes its chair.
-- ⚠ [[project_chair_reasoning_inversion]] is marked CLOSED. **These two survived it**, and surfaced
-- only because a different pass happened to read their rows. That memory now says so.
--
-- EVIDENCE, verified 2026-09-18:
--   * **NAY on HB0732 (2020)**, the tax package funding the Blueprint, which the Senate passed
--     **29-16** and which became **Chapter 37 of 2021** over the Governor's veto. Both appear in the
--     Nay block of Senate sheet 0906.
--     🔴 The sheet renders Yea and Nay **side by side**, so Nay names sit on lines ABOVE the "Voting
--     Nay" label; a line-range read scores Simonaire as a YEA. Each block was counted back to its
--     declared total (29 Yea / 16 Nay) before this was trusted.
--   * **Both are among the thirteen senate sponsors of SB0748 (2024), the "Economic Prosperity Act of
--     2024"** (Corderman, Hershey, Ready, Bailey, Carozza, Folden, Gallion, Jennings, Mautz, McKay,
--     Salling, Simonaire, West), which rewrites the individual income tax brackets and rates. **The
--     fiscal note estimates general fund revenues falling by about $4.8 billion in FY2025**, reflecting
--     one and a half tax years. ⚠ It **died in committee** (hearing 2/21), so this is a sponsorship,
--     not an enactment — a statement of position rather than a change in law, and the row says so.
--   * Their own tax bills in this period are reductions: Simonaire's **Retirement Tax Elimination Act
--     of 2022** and a back-to-school sales tax holiday; Bailey's military-retirement and
--     public-safety subtraction modifications and a long-term care credit.
--
-- 🔑🔑 THE TITLE AND THE TEXT DISAGREE, AND ONLY THE FISCAL NOTE SETTLES IT. SB0748's synopsis is
-- direction-neutral ("altering the rates and rate brackets"), and the bill text shows **every bracket
-- RATE going UP** — [2%] 4%, [3%] 4.5%, … [5.25%] 5.75% — while the **thresholds jump** ($1 →
-- $15,000, and so on up). Read alone, the text looks like a tax increase; read with the fiscal note it
-- is a **$4.8B cut**. ⚠ Neither the title ("Economic Prosperity Act") nor the rate column alone is
-- sufficient — this is [[feedback_read_the_enacted_text_not_the_title]] with a second step.
--
-- ⚖ CHAIR 4 — **OPERATOR CALL 2026-09-18.** The evidence excludes chairs 1, 2 and 3 on its own: a NAY
-- on a tax increase plus sponsorship of a multi-billion-dollar reduction is not "raise taxes"
-- (1, 2) and not "keep the current system mostly as-is with small adjustments" (3). What it does NOT
-- do is separate **chair 4** ("Cut taxes for everyone and scale back public services to match") from
-- **chair 5** ("Drastically cut taxes and shrink government"). ⚠ **Picking 4 because it is the milder
-- option is exactly the tiebreaker the chair-evidence rule forbids**, so it was put to the operator,
-- who chose 4.
-- ⚠ HONEST LIMIT, written into both rows: **neither has proposed scaling back particular services**,
-- so chair 4's second clause is not separately evidenced — it follows from the size of the revenue
-- reduction, not from a companion bill of their own.
--
-- 🔑 The pins MATCH for this topic (both seasons on revision 1, `87f8c011-…`), so chair 4 means the
-- same thing in both. Asserted below, as in 1878.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE sim numeric; bai numeric; s2_rows int; s1_rev uuid; s2_rev uuid;
BEGIN
  SELECT value INTO sim FROM inform.politician_answers
   WHERE politician_id='4aa50ee7-aeed-48ae-96e7-142bd9ac731b'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  SELECT value INTO bai FROM inform.politician_answers
   WHERE politician_id='0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF sim IS DISTINCT FROM 1 OR bai IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1879: expected Season 1 Simonaire=1 and Bailey=2, found % and % -- the inversion may already be corrected', sim, bai;
  END IF;

  SELECT count(*) INTO s2_rows FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b','0abc8345-1fbb-4994-b39c-c3c4f4eefc9f');
  IF s2_rows <> 0 THEN
    RAISE EXCEPTION 'migration 1879: Season 2 already holds % of these rows', s2_rows;
  END IF;

  SELECT sq.topic_revision_id INTO s1_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id=sq.topic_revision_id
   WHERE sq.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND tr.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  SELECT sq.topic_revision_id INTO s2_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id=sq.topic_revision_id
   WHERE sq.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND tr.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF s1_rev IS DISTINCT FROM s2_rev OR s2_rev IS DISTINCT FROM '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid THEN
    RAISE EXCEPTION 'migration 1879: the seasons no longer share revision 87f8c011 (S1 %, S2 %)', s1_rev, s2_rev;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions
     WHERE topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
       AND value=4 AND text ILIKE '%Cut taxes for everyone%'
  ) THEN
    RAISE EXCEPTION 'migration 1879: revision 1 chair 4 no longer reads "Cut taxes for everyone" -- re-read before seating';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid,
       'f7e5678d-dadd-4556-a2fc-446e24642ceb',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '87f8c011-5c70-4f39-a1ea-5cc53c010c60',
       NULL, v.reasoning, v.sources
FROM (VALUES
  ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
   'Simonaire voted against the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which the Senate passed 29 to 16 and which became law as Chapter 37 of 2021 over the Governor''s veto. He is also one of thirteen senate sponsors of the Economic Prosperity Act of 2024 (SB0748), which rewrites the individual income tax brackets and rates; the fiscal note estimates it would reduce general fund revenues by about $4.8 billion in fiscal 2025. That bill did not pass, so it records a position rather than a change in the law. His own tax bills in this period reduce rather than raise, including the Retirement Tax Elimination Act of 2022 and a back-to-school sales tax holiday. Reducing income tax across the brackets is what stance 4 describes, rather than raising taxes as stances 1 and 2 do, or leaving the system broadly in place as stance 3 does. One limit belongs on this: he has not separately proposed scaling back particular public services, so the second half of stance 4 follows from the size of the revenue reduction rather than from a companion bill of his own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0906.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0748?ys=2024RS',
         'https://mgaleg.maryland.gov/2024RS/fnotes/bil_0008/sb0748.pdf']),

  ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
   'Bailey voted against the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which the Senate passed 29 to 16 and which became law as Chapter 37 of 2021 over the Governor''s veto. He is also one of thirteen senate sponsors of the Economic Prosperity Act of 2024 (SB0748), which rewrites the individual income tax brackets and rates; the fiscal note estimates it would reduce general fund revenues by about $4.8 billion in fiscal 2025. That bill did not pass, so it records a position rather than a change in the law. His own tax bills in this period reduce rather than raise, including subtraction modifications for military retirement income and for public safety volunteers, and a long-term care insurance credit. Reducing income tax across the brackets is what stance 4 describes, rather than raising taxes as stances 1 and 2 do, or leaving the system broadly in place as stance 3 does. One limit belongs on this: he has not separately proposed scaling back particular public services, so the second half of stance 4 follows from the size of the revenue reduction rather than from a companion bill of his own.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/senate/0906.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0748?ys=2024RS',
         'https://mgaleg.maryland.gov/2024RS/fnotes/bil_0008/sb0748.pdf'])
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid,
       'f7e5678d-dadd-4556-a2fc-446e24642ceb',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '87f8c011-5c70-4f39-a1ea-5cc53c010c60',
       NULL, 4
FROM (VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b'),('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f')) AS v(pid);

DO $$
DECLARE ctx int; ans int; bad int; sim numeric; bai numeric;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
     AND politician_id IN ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b','0abc8345-1fbb-4994-b39c-c3c4f4eefc9f');
  IF ctx <> 2 THEN
    RAISE EXCEPTION 'migration 1879: expected 2 Season 2 context rows, found %', ctx;
  END IF;

  SELECT count(*) INTO ans FROM inform.politician_answers
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND value=4
     AND politician_id IN ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b','0abc8345-1fbb-4994-b39c-c3c4f4eefc9f');
  IF ans <> 2 THEN
    RAISE EXCEPTION 'migration 1879: expected 2 Season 2 answers at chair 4, found %', ans;
  END IF;

  -- both rows must name the instruments, cite the SENATE sheet, and carry no Ballotpedia
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b','0abc8345-1fbb-4994-b39c-c3c4f4eefc9f')
     AND (reasoning NOT ILIKE '%SB0748%' OR reasoning NOT ILIKE '%HB0732%'
          OR NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%/2020RS/votes/senate/0906.pdf%')
          OR EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%ballotpedia%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1879: % new row(s) fail the sourcing contract', bad;
  END IF;

  -- history intact: the inverted Season 1 rows survive verbatim as the record of what was claimed
  SELECT value INTO sim FROM inform.politician_answers
   WHERE politician_id='4aa50ee7-aeed-48ae-96e7-142bd9ac731b'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  SELECT value INTO bai FROM inform.politician_answers
   WHERE politician_id='0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF sim IS DISTINCT FROM 1 OR bai IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1879: Season 1 moved (% / %) -- history must survive verbatim', sim, bai;
  END IF;
END $$;

COMMIT;
