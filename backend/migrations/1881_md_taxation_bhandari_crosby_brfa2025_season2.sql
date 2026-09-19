-- 1881_md_taxation_bhandari_crosby_brfa2025_season2.sql
-- Harry Bhandari (chair 1 -> 2) and Brian M. Crosby (chair 2 -> 3) / Taxation and Public Spending:
-- seat both on the 2025 Budget Reconciliation and Financing Act roll calls and write forward into
-- Season 2. 4 rows INSERTED. Season 1 untouched.
--
-- 🔴 THIS CORRECTS MIGRATION 1878's OWN HEADER. That migration excluded these two and said Bhandari's
-- row *"has no instrument at all"* and that Crosby's position *"has no rung on this ladder"*. **Both
-- statements were wrong, and wrong the same way: they rested on ONE vote (HB0732 in 2020) plus a
-- sponsorship-TITLE scan.** The 2025 BRFA settles both, in opposite directions.
-- 🔑 **A "no evidence" verdict is only as wide as the corpus you actually searched.** Two extra
-- fetches — one bill page, one fiscal note — moved one row and reversed the reasoning under the other.
--
-- THE INSTRUMENT: **HB0352 (2025), the Budget Reconciliation and Financing Act of 2025, Chapter 604.**
--   * Its synopsis is direction-neutral — *"altering the rates and rate brackets under the State income
--     tax on certain income of individuals"* — exactly like SB0748 in migration 1879. 🔑 **Again only
--     the FISCAL NOTE settles direction: general fund revenues INCREASE by $765.6 million in FY2025
--     and $1.6 BILLION in FY2026.**
--   * What it does to whom: adds new **6.25% and 6.50%** income tax brackets reaching the upper bands
--     (to $500,001-$1,000,000 and the excess of $1,000,000 for single filers), and imposes a **net
--     capital gain surtax**. That is a tax increase aimed at high earners.
--   * ⚠ It is also a BUNDLE, like HB0732 before it: the same Act raises the **vehicle excise tax from
--     6.0% to 6.5%**, a broad consumer tax that is not a tax on the wealthy. Both rows say so.
--   * Votes, both DIVIDED: House third reading **93-46** (sheet 0881) and final passage after the
--     conference report **97-41** (sheet 1311).
-- 🔴 Read by COLUMN, not line range — these sheets render Yea and Nay side by side (migrations
-- 1878/1879). **Bhandari is in the left column of the Yea block on BOTH sheets; Crosby is in the Nay
-- block on both**, and on sheet 0881 his name sits on the "Voting Nay - 46" line itself.
--
-- ⚖ BHANDARI — chair 1 -> chair 2, ON THE PURPOSE TEST.
-- His Season 1 row claimed *"higher income taxes on top earners"* and migration 1878 called that
-- unevidenced, because he voted NAY on HB0732 in 2020. **That NAY does not mean what 1878 implied:**
-- the House vote on HB0732's third reading was on a **tobacco-only** bill (the digital advertising tax
-- arrived later by Senate amendment), so voting against it is not evidence against taxing top earners.
-- His YEA on the 2025 BRFA is direct evidence for it.
-- **But the chair still moves, because chair 1 vs chair 2 is a PURPOSE test, not a magnitude one:**
--   chair 1: raise taxes on the wealthy "to fund **MORE** public services"
--   chair 2: raise taxes on the wealthy "to fund **EXISTING** services"
-- The BRFA is a deficit-closing package: alongside the $1.6B revenue increase, **general fund
-- EXPENDITURES DECREASE by $897.9 million in FY2026**. It sustains the existing budget rather than
-- funding new services — the opposite of HB0732, which fed a dedicated new programme fund and put nine
-- members at chair 1 in migration 1878. Same ladder, same test, different answer because the
-- instrument's purpose differs.
-- ⚠ Limit: "moderately" is not independently evidenced; chair 2 is reached on purpose, not size.
--
-- ⚖ CROSBY — chair 2 -> chair 3.
-- **He voted NAY on BOTH 2025 BRFA votes and NAY on HB0732 in 2020** — three recorded votes against
-- tax increases — so his Season 1 claim of *"generally supported progressive revenue measures"* is
-- contradicted, and chairs 1 and 2 are excluded.
-- What his own record contains is **targeted relief, not wholesale cuts**: sales tax exemptions for
-- diapers and baby products, subtraction modifications for military and public-safety retirement
-- income, and a long-term care insurance credit. **Chair 4 requires cutting taxes "for everyone" and
-- scaling back services to match; he proposes neither** — no bracket restructure, no service
-- reductions. **Chair 3, "keep the current tax system mostly as-is with small adjustments", is what
-- that record looks like.**
-- ⚠ Limit, written into the row: chair 3 describes its small adjustments as closing **unfair
-- loopholes**, and his run the other way — they are targeted exemptions. He matches the "mostly as-is
-- with small adjustments" half, not the loophole half.
-- 🔴 **THIS ALSO RETRACTS A CLAIM I FILED THE SAME DAY.** Migration 1878 logged Crosby as a third-corpus
-- corroboration of the `taxes` ladder-scope hole (register instance 2). **That was an overstatement.**
-- His *relief instruments* have no rung, but his *votes* do discriminate — they exclude chairs 1 and 2
-- outright, and chair 3 holds him. A position that a ladder CAN seat is not a scope finding. The
-- register entry has been corrected.
--
-- 🔑 The pins MATCH for this topic (both seasons on revision 1, `87f8c011-…`), asserted below.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE bh numeric; cr numeric; s2_rows int; s1_rev uuid; s2_rev uuid;
BEGIN
  SELECT value INTO bh FROM inform.politician_answers
   WHERE politician_id='6d95657c-6c46-4aab-886f-f9688adc7b33'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  SELECT value INTO cr FROM inform.politician_answers
   WHERE politician_id='898845f9-cb93-4162-b0ed-6842eacda5d6'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF bh IS DISTINCT FROM 1 OR cr IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1881: expected Season 1 Bhandari=1 and Crosby=2, found % and %', bh, cr;
  END IF;

  SELECT count(*) INTO s2_rows FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN ('6d95657c-6c46-4aab-886f-f9688adc7b33','898845f9-cb93-4162-b0ed-6842eacda5d6');
  IF s2_rows <> 0 THEN
    RAISE EXCEPTION 'migration 1881: Season 2 already holds % of these rows', s2_rows;
  END IF;

  SELECT sq.topic_revision_id INTO s1_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id=sq.topic_revision_id
   WHERE sq.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND tr.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  SELECT sq.topic_revision_id INTO s2_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id=sq.topic_revision_id
   WHERE sq.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND tr.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF s1_rev IS DISTINCT FROM s2_rev OR s2_rev IS DISTINCT FROM '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid THEN
    RAISE EXCEPTION 'migration 1881: the seasons no longer share revision 87f8c011 (S1 %, S2 %)', s1_rev, s2_rev;
  END IF;

  -- the two clauses the adjudications turn on
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                  WHERE topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
                    AND value=2 AND text ILIKE '%existing services%') THEN
    RAISE EXCEPTION 'migration 1881: chair 2 no longer says "existing services" -- the purpose test is what moves Bhandari';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                  WHERE topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
                    AND value=3 AND text ILIKE '%as-is%') THEN
    RAISE EXCEPTION 'migration 1881: chair 3 no longer reads "mostly as-is" -- that is what seats Crosby';
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
  ('6d95657c-6c46-4aab-886f-f9688adc7b33',
   'Bhandari voted for the Budget Reconciliation and Financing Act of 2025 (HB0352, Chapter 604), both on third reading, which passed 93 to 46, and on final passage after the conference report, which passed 97 to 41. The Act adds new income tax brackets at 6.25% and 6.5% reaching the upper income bands, and imposes a surtax on net capital gains; the fiscal note estimates general fund revenues rising by $765.6 million in fiscal 2025 and $1.6 billion in fiscal 2026. Backing higher taxes on high earners is what stances 1 and 2 share. What separates them is purpose: stance 1 funds more public services, while stance 2 funds existing ones, and this Act is a deficit-closing package, since the same fiscal note shows general fund spending falling by $897.9 million in fiscal 2026. It sustains the existing budget rather than paying for new programmes. Two limits belong on this: the word moderately is not separately evidenced, and the Act is a bundle, because it also raises the vehicle excise tax from 6% to 6.5%, which is a broad consumer tax rather than a tax on the wealthy.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0352?ys=2025RS',
         'https://mgaleg.maryland.gov/2025RS/votes/house/0881.pdf',
         'https://mgaleg.maryland.gov/2025RS/votes/house/1311.pdf',
         'https://mgaleg.maryland.gov/2025RS/fnotes/bil_0002/hb0352.pdf']),

  ('898845f9-cb93-4162-b0ed-6842eacda5d6',
   'Crosby voted against the Budget Reconciliation and Financing Act of 2025 (HB0352, Chapter 604) on both recorded votes, the third reading that passed 93 to 46 and the final passage that passed 97 to 41. The Act adds income tax brackets at 6.25% and 6.5% on the upper income bands and a surtax on net capital gains, raising general fund revenues by an estimated $1.6 billion in fiscal 2026. He also voted against the 2020 tax package that funded the Blueprint for Maryland''s Future (HB0732). Three recorded votes against tax increases rule out stances 1 and 2, which raise taxes on the wealthy and on large companies. His own bills are targeted relief rather than broad cuts: sales tax exemptions for diapers and baby products, subtraction modifications for military and public safety retirement income, and a long-term care insurance credit. That rules out stance 4, which cuts taxes for everyone and scales back public services to match, since he has proposed neither a general rate cut nor service reductions. Keeping the system broadly as it is while making small adjustments is what stance 3 describes. One limit belongs on this: stance 3 frames its small adjustments as closing unfair loopholes, and his run the other way, being targeted exemptions rather than loophole closures.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0352?ys=2025RS',
         'https://mgaleg.maryland.gov/2025RS/votes/house/0881.pdf',
         'https://mgaleg.maryland.gov/2025RS/votes/house/1311.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?ys=2023RS'])
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid,
       'f7e5678d-dadd-4556-a2fc-446e24642ceb',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '87f8c011-5c70-4f39-a1ea-5cc53c010c60',
       NULL, v.chair
FROM (VALUES
  ('6d95657c-6c46-4aab-886f-f9688adc7b33', 2),
  ('898845f9-cb93-4162-b0ed-6842eacda5d6', 3)
) AS v(pid, chair);

DO $$
DECLARE bh numeric; cr numeric; ctx int; bad int; s1bh numeric; s1cr numeric;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
     AND politician_id IN ('6d95657c-6c46-4aab-886f-f9688adc7b33','898845f9-cb93-4162-b0ed-6842eacda5d6');
  IF ctx <> 2 THEN
    RAISE EXCEPTION 'migration 1881: expected 2 Season 2 context rows, found %', ctx;
  END IF;

  SELECT value INTO bh FROM inform.politician_answers
   WHERE politician_id='6d95657c-6c46-4aab-886f-f9688adc7b33'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  SELECT value INTO cr FROM inform.politician_answers
   WHERE politician_id='898845f9-cb93-4162-b0ed-6842eacda5d6'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF bh IS DISTINCT FROM 2 OR cr IS DISTINCT FROM 3 THEN
    RAISE EXCEPTION 'migration 1881: expected Season 2 Bhandari=2 and Crosby=3, found % and %', bh, cr;
  END IF;

  -- both must rest on the BRFA, cite a 2025 roll call, and carry no Ballotpedia
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN ('6d95657c-6c46-4aab-886f-f9688adc7b33','898845f9-cb93-4162-b0ed-6842eacda5d6')
     AND (reasoning NOT ILIKE '%HB0352%'
          OR NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%/2025RS/votes/house/%')
          OR EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%ballotpedia%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1881: % new row(s) fail the sourcing contract', bad;
  END IF;

  -- history intact
  SELECT value INTO s1bh FROM inform.politician_answers
   WHERE politician_id='6d95657c-6c46-4aab-886f-f9688adc7b33'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  SELECT value INTO s1cr FROM inform.politician_answers
   WHERE politician_id='898845f9-cb93-4162-b0ed-6842eacda5d6'
     AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1bh IS DISTINCT FROM 1 OR s1cr IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1881: Season 1 moved (% / %) -- history must survive verbatim', s1bh, s1cr;
  END IF;
END $$;

COMMIT;
