-- 1878_md_taxation_blueprint_revenue_nine_season2.sql
-- Maryland / Taxation and Public Spending: re-source the NINE rows whose members voted FOR the
-- Blueprint's revenue bill, and write them forward into Season 2. Chair UNCHANGED at 1 for all nine.
-- 18 rows INSERTED. Season 1 untouched.
--
-- 🔑 THE PINS MATCH HERE (unlike 1872/1873/1875). Season 1 and Season 2 both pin revision 1
-- (`87f8c011-…`) for this topic, so chair 1 means the same thing in both and the number carries. The
-- guard asserts that rather than assuming it -- the opposite assertion to migration 1872's.
--
-- WHY THESE NINE. Of the 13 Season 1 taxation rows citing the Blueprint, **12 named no instrument**
-- and 12 cited Ballotpedia. The shared, enacted instrument is **HB0732 (2020) "Taxation - Tobacco Tax,
-- Sales and Use Tax, and Digital Advertising Gross Revenues Tax"**, which became **Chapter 37 of 2021
-- over the Governor's veto** and whose synopsis requires the Comptroller to distribute revenue to
-- **The Blueprint for Maryland's Future Fund**. These nine voted YEA on it. The other four did not,
-- and are deliberately NOT in this migration (see the bottom of this header).
--
-- 🔴🔴 READ THE RIGHT SHEET: THE DIGITAL ADVERTISING TAX WAS ADDED BY SENATE AMENDMENT. The vote
-- sheets still carry the bill's ORIGINAL title, *"Electronic Smoking Devices, Other Tobacco Products,
-- and Cigarettes - Taxation and Regulation"*. So the House **third reading** (sheet 0522) was a vote
-- on a **tobacco-only** bill and does NOT evidence a tax on large companies. The probative House vote
-- is the **post-concurrence final passage, sheet 1218, 88-47**, which is the full package. Senators
-- voted on sheet 0906, **29-16**. Both DIVIDED, so both discriminate.
--
-- 🔴🔴 THESE VOTE SHEETS RENDER THE YEA AND NAY BLOCKS **SIDE BY SIDE**, so Nay names appear on lines
-- ABOVE the "Voting Nay" label. A naive line-range read of `pdftotext -layout` output puts them in the
-- Yea block and **silently inverts the vote**. On the Senate sheet this initially read Simonaire as a
-- Yea; he is a Nay. **Read the column structure, never the line number.** Confirmed by counting each
-- block back to its declared total (29 Yea / 16 Nay; 88 Yea / 47 Nay).
-- 🔑 And the presiding officers are by title again: **Jones is "Speaker"** on sheet 1218, not "Jones".
--
-- ⚖ WHY CHAIR 1 AND NOT CHAIR 2 -- THE PURPOSE TEST, NOT THE ADVERB. The two rungs are:
--   chair 1: "Significantly raise taxes on wealthy people and large companies to fund **MORE** public
--             services"
--   chair 2: "Moderately raise taxes on wealthy people and large companies to fund **EXISTING**
--             services"
-- **The discriminator is the purpose, not the adverb.** HB0732 dedicates its revenue to the Blueprint
-- Fund -- a new statutory programme the fiscal note scores as needing an additional $2.8B state and
-- $1.2B local by FY2030 -- so the money funds MORE services, not the existing base. That is chair 1.
-- (Same basis as the Elo-Rivera seating.)
-- ⚠ TWO HONEST LIMITS, written into every row:
--   * **"Significantly" is not independently evidenced.** Chair 1 is reached on purpose, not size.
--   * **The Act is a BUNDLE.** Its digital advertising gross revenues tax reaches large companies, but
--     the same Act raises tobacco taxes and taxes electronic smoking devices at 12% -- consumer taxes
--     that are **not** taxes on wealthy people or large companies. The row says so rather than
--     describing the Act as if it were purely a large-company tax.
--
-- ⚠ NOT IN THIS MIGRATION -- the four who voted NAY, each for a different reason and none seatable here:
--   * **Bryan W. Simonaire (S1 chair 1)** and **Jack Bailey (S1 chair 2)** are **FLAT INVERSIONS**:
--     their own reasoning says *"consistent tax opponent"* and *"consistently votes against tax
--     increases"* while the chairs say raise taxes. The roll call CONFIRMS the reasoning and REFUTES
--     the chairs, and both sponsor **SB0748 (2024)**, which the fiscal note scores at **-$4.8 billion**
--     in general fund revenue. That excludes chairs 1, 2 and 3 -- but the evidence **cannot
--     discriminate chair 4 from chair 5**, so seating them is an operator call, not a default.
--     ⚠ Reaching for "4 because it is less extreme" is the tiebreaker the chair-evidence rule warns
--     about, so it was not reached for.
--   * **Harry Bhandari (S1 chair 1)** voted NAY, and his whole 2021-2024 tax record is a single
--     disabled-veterans property tax exemption. The row's claim of *"higher income taxes on top
--     earners"* has **no instrument at all** and is contradicted by his vote.
--   * **Brian M. Crosby (S1 chair 2)** voted NAY, and his record is consistent **targeted tax RELIEF**
--     -- sales tax exemptions for diapers and baby products, military and public safety retirement
--     subtractions, a long-term care credit. **That position has no rung on this ladder**: chairs 1-2
--     are taxes "on wealthy people and large companies" and chair 4 requires scaling back services.
--     This is the `taxes` ladder-scope hole (register instance 2) reached from a THIRD corpus.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_rows int; s2_rows int; s1_rev uuid; s2_rev uuid;
BEGIN
  SELECT count(*) INTO s1_rows
    FROM inform.politician_answers pa
   WHERE pa.topic_id  = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND pa.value = 1
     AND pa.politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
       'e94337e1-4776-4058-87b4-32dfeb7732a0','41749b94-11b8-4047-8421-95db0900d4b2',
       'f45e2178-2a05-4974-8af8-379662412060','fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
       '631dac5c-fb86-41f5-a82d-5963164a9142','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       'f6a237a0-34ff-4a93-b05a-335ec38b6da3');
  IF s1_rows <> 9 THEN
    RAISE EXCEPTION 'migration 1878: expected 9 Season 1 rows at chair 1, found % -- state has moved', s1_rows;
  END IF;

  SELECT count(*) INTO s2_rows
    FROM inform.politician_context pc
   WHERE pc.topic_id  = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND pc.politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
       'e94337e1-4776-4058-87b4-32dfeb7732a0','41749b94-11b8-4047-8421-95db0900d4b2',
       'f45e2178-2a05-4974-8af8-379662412060','fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
       '631dac5c-fb86-41f5-a82d-5963164a9142','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       'f6a237a0-34ff-4a93-b05a-335ec38b6da3');
  IF s2_rows <> 0 THEN
    RAISE EXCEPTION 'migration 1878: Season 2 already holds % of these rows', s2_rows;
  END IF;

  -- 🔑 INVERSE of 1872's guard: here the two seasons must pin the SAME revision, or chair 1 would not
  -- mean what this migration argues it means.
  SELECT sq.topic_revision_id INTO s1_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   WHERE sq.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND tr.topic_id  = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
  SELECT sq.topic_revision_id INTO s2_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND tr.topic_id  = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF s1_rev IS DISTINCT FROM s2_rev OR s2_rev IS DISTINCT FROM '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid THEN
    RAISE EXCEPTION 'migration 1878: the seasons no longer share revision 87f8c011 (S1 %, S2 %) -- chair 1 may not mean the same thing', s1_rev, s2_rev;
  END IF;

  -- the purpose clause chair 1 is seated on must still be there
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '87f8c011-5c70-4f39-a1ea-5cc53c010c60'
       AND sr.value = 1 AND sr.text ILIKE '%more public services%'
  ) THEN
    RAISE EXCEPTION 'migration 1878: revision 1 chair 1 no longer says "more public services" -- the purpose test is the whole basis';
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
  ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
   'As Speaker, Jones voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto. The House passed the final version 88 to 47, and the vote sheet records the presiding officer as Speaker rather than by surname. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme whose recommendations the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2, which funds existing services. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf',
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones?ys=2020RS']),

  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
   'Washington was the sole sponsor of HB0695 in the 2020 session, which imposed a tax on the annual gross revenues from digital advertising services and directed the proceeds, after administration costs, to the Blueprint for Maryland''s Future Fund. The tax reaches only large companies: the fiscal note records that it applies to businesses with at least $100 million in global annual gross revenues, and estimates special fund revenues rising by as much as $250 million in the first full year of collection. He also voted for the enacted package carrying the same digital advertising tax (2020 HB0732, Chapter 37 of 2021, passed over the Governor''s veto), which the House approved 88 to 47 on final passage. Directing new revenue to a new programme, rather than to the existing base, is what separates stance 1 from stance 2. One limit: the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0695?ys=2020RS',
         'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('e94337e1-4776-4058-87b4-32dfeb7732a0',
   'Stein voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('41749b94-11b8-4047-8421-95db0900d4b2',
   'Bagnall voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('f45e2178-2a05-4974-8af8-379662412060',
   'Terrasa voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
   'Feldmark voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('631dac5c-fb86-41f5-a82d-5963164a9142',
   'Cardin voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
   'Chang voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf']),

  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
   'Hill voted for the tax package that funds the Blueprint for Maryland''s Future (2020 HB0732), which became law as Chapter 37 of 2021 after the General Assembly overrode the Governor''s veto and which the House passed 88 to 47 on final passage. The Act imposes a tax on the gross revenues of digital advertising services, which reaches large companies, and requires the Comptroller to distribute revenue to the Blueprint for Maryland''s Future Fund, a new programme the fiscal note expects to need an additional $2.8 billion in state and $1.2 billion in local funding by fiscal 2030. Raising revenue to fund services beyond the existing base is what separates stance 1 from stance 2. Two limits belong on this: the word significantly is not separately evidenced here, and the same Act also raises tobacco taxes and taxes electronic smoking devices at 12%, which are consumer taxes rather than taxes on the wealthy or on large companies.',
   ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0732?ys=2020RS',
         'https://mgaleg.maryland.gov/2020RS/votes/house/1218.pdf'])
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid,
       'f7e5678d-dadd-4556-a2fc-446e24642ceb',
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
       '87f8c011-5c70-4f39-a1ea-5cc53c010c60',
       NULL, 1
FROM (VALUES
  ('760cd4a7-235c-472f-a0ba-fb07098dfd57'),('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'),
  ('e94337e1-4776-4058-87b4-32dfeb7732a0'),('41749b94-11b8-4047-8421-95db0900d4b2'),
  ('f45e2178-2a05-4974-8af8-379662412060'),('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'),
  ('631dac5c-fb86-41f5-a82d-5963164a9142'),('4a409af4-8568-42c3-bb72-7bb7500c96ce'),
  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3')
) AS v(pid);

DO $$
DECLARE ctx int; ans int; bad int; s1 int;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
       'e94337e1-4776-4058-87b4-32dfeb7732a0','41749b94-11b8-4047-8421-95db0900d4b2',
       'f45e2178-2a05-4974-8af8-379662412060','fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
       '631dac5c-fb86-41f5-a82d-5963164a9142','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       'f6a237a0-34ff-4a93-b05a-335ec38b6da3');
  IF ctx <> 9 THEN
    RAISE EXCEPTION 'migration 1878: expected 9 Season 2 context rows, found %', ctx;
  END IF;

  SELECT count(*) INTO ans FROM inform.politician_answers
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_revision_id='87f8c011-5c70-4f39-a1ea-5cc53c010c60'
     AND value = 1
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
       'e94337e1-4776-4058-87b4-32dfeb7732a0','41749b94-11b8-4047-8421-95db0900d4b2',
       'f45e2178-2a05-4974-8af8-379662412060','fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
       '631dac5c-fb86-41f5-a82d-5963164a9142','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       'f6a237a0-34ff-4a93-b05a-335ec38b6da3');
  IF ans <> 9 THEN
    RAISE EXCEPTION 'migration 1878: expected 9 Season 2 answers at chair 1, found %', ans;
  END IF;

  -- every new row must name HB0732, cite the POST-CONCURRENCE sheet (1218, the one that includes the
  -- digital advertising tax) and NOT the tobacco-only third reading (0522), and carry no Ballotpedia
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
       'e94337e1-4776-4058-87b4-32dfeb7732a0','41749b94-11b8-4047-8421-95db0900d4b2',
       'f45e2178-2a05-4974-8af8-379662412060','fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
       '631dac5c-fb86-41f5-a82d-5963164a9142','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       'f6a237a0-34ff-4a93-b05a-335ec38b6da3')
     AND (reasoning NOT ILIKE '%HB0732%'
          OR NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%/2020RS/votes/house/1218.pdf%')
          OR EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%ballotpedia%' OR s LIKE '%house/0522%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1878: % new row(s) fail the sourcing contract', bad;
  END IF;

  -- history intact
  SELECT count(*) INTO s1 FROM inform.politician_answers
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND value = 1
     AND politician_id IN (
       '760cd4a7-235c-472f-a0ba-fb07098dfd57','8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
       'e94337e1-4776-4058-87b4-32dfeb7732a0','41749b94-11b8-4047-8421-95db0900d4b2',
       'f45e2178-2a05-4974-8af8-379662412060','fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
       '631dac5c-fb86-41f5-a82d-5963164a9142','4a409af4-8568-42c3-bb72-7bb7500c96ce',
       'f6a237a0-34ff-4a93-b05a-335ec38b6da3');
  IF s1 <> 9 THEN
    RAISE EXCEPTION 'migration 1878: Season 1 moved (% of 9 still at chair 1)', s1;
  END IF;
END $$;

COMMIT;
