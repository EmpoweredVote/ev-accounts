-- 1568_reresearch_carson_council_stances.sql
--
-- Restore THREE Carson City Council stance rows, re-researched from the city's Legistar minutes after
-- migration 1564 retired all 34 of Carson's rows as fabricated-source citations.
--
--   Review:   data/stance-research/reresearch-carson/FINDINGS.md   (per-row basis, and why 31 stay blank)
--   Base:     data/stance-research/reresearch-carson/EVIDENCE-BASE.md (corpus, tooling, vote-block trap)
--   Rollback: DELETE the 3 (politician_id, topic_id) pairs from inform.politician_answers and
--             inform.politician_context, then set last_stances_researched_at = NULL for the 3 members.
--   Follows:  1564 (retired all 34), 1567 (the same exercise for Alhambra, which yielded 16 of 19)
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1568_reresearch_carson_council_stances.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THREE OF THIRTY-FOUR. THE LOW NUMBER IS THE FINDING, NOT A SHORTFALL.
-- ---------------------------------------------------------------------------------------------------
-- The full 2023-2024 Legistar corpus (73 minutes PDFs) was downloaded, text-extracted and searched
-- topic by topic. Carson yields almost nothing for a structural reason:
--
--   1. Nearly every substantive item is approved ON CONSENT with no recorded deliberation — the LASD
--      Service Level Agreement, the Homeless Employment Initiative, the PLHA homeless-prevention
--      allocations, and even the post-Grants Pass camping-enforceability update. A consent vote is a
--      recorded act, but nobody deliberated, so it carries no individual position.
--   2. Members' recorded remarks are overwhelmingly ceremonial or informational. Under the standard
--      applied at Alhambra in 1567 — a QUESTION IS NOT A POSITION, which is why Katherine Lee's Police
--      HOME Team question left her spoke blank — almost all of it is unusable.
--
-- ⚠ Carson's `hasContext` chip is left FALSE. Three rows across two topics for three of five members
-- is not coverage, and flipping it on this basis would repeat what this audit exists to correct.
-- Operator call, flagged not taken.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 LOCAL IMMIGRATION ENFORCEMENT IS VERIFIED ABSENT FOR ALL FIVE
-- ---------------------------------------------------------------------------------------------------
-- The retired rows rested on a claimed 2017 "Trust Act resolution" at dailybreeze.com. It does not exist:
--   * Zero immigration content in the 2023-2024 minutes. EVERY `ICE` match in all 73 files is
--     "Ken's Ice Cream" — a word-boundary grep still hit it, the substring trap yet again.
--   * The Legistar Web API, searching ALL YEARS BACK TO 2001, returns 0 matters for `immigration`,
--     `immigrant`, `deportation`, `TRUST ACT` and `SB 54`. The only `sanctuary` hit is a pastor's
--     church name; the only `welcoming` hit is "WELCOMING THE XFL WILDCATS TO CARSON."
-- Carson has never had an immigration matter before its council. Verified absent, not merely unfound.
--
-- ---------------------------------------------------------------------------------------------------
-- ⚠ TWO TOPICS WHERE THE OBVIOUS EVIDENCE WAS THE WRONG EVIDENCE
-- ---------------------------------------------------------------------------------------------------
-- Both were nearly assigned before the chair texts were read:
--   * Environmental Protection vs. Development — Carson has real air-quality material (Hicks on the
--     AQMD report and methane/sulfur odours; Davis-Holmes on SBCCOG Rule 118 governing REFINERY FLARE
--     emissions). But this topic asks how to balance new development against environmental
--     PRESERVATION, and its chairs are about green space, tree canopy, environmental review and
--     developer offsets. Industrial air pollution is a different subject. The topic-correct search
--     (trees, green space, CEQA, EIR, mitigation) returns one hit: a tree-maintenance status request.
--   * Economic Development Incentives — the council adopted an Economic Development Strategic Plan
--     with all five participating, but the chairs are specifically about tax incentives, abatements,
--     subsidies and community benefit agreements, and no member statement on any of those exists.
--     Adopting an economic development plan is not a position on incentives.
--
-- 🔑 MATCH THE STATEMENT TO THE CHAIR TEXTS, NOT TO THE TOPIC'S TITLE. Both would have produced
-- authoritative-looking rows resting on evidence about a different question.
--
-- ---------------------------------------------------------------------------------------------------
-- ⚠ THE VOTE-BLOCK TRAP IS WORSE IN CARSON THAN IN ALHAMBRA (no vote is relied on below, but record it)
-- ---------------------------------------------------------------------------------------------------
-- Carson's tallies interleave the label column THROUGH the wrapped name list, and it survives plain
-- pdftotext without -layout:
--     Ayes:     Mayor Davis-Holmes, Mayor Pro
--               Tempore ... Dr. Hilton, Council
--     Noes:     Member ... Dear, Council Member/Agency
--     Abstain:  Member ... Hicks, and Council Member/Agency
--     Absent:   Member ... Rojas
--               None / None / None
-- Read naively that is Dear voting No, Hicks abstaining and Rojas absent. It is one continuous list of
-- five ayes on a motion the same paragraph calls "unanimously carried". Always confirm against the
-- ACTION narrative.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _car (
  politician_id uuid, full_name text, topic_id uuid, topic text,
  value numeric, reasoning text, sources text[]
) ON COMMIT DROP;

INSERT INTO _car (politician_id, full_name, topic_id, topic, value, reasoning, sources) VALUES

-- Homelessness Response — 2024-01-23 homeless services team presentation, the one homelessness item in
-- the corpus pulled for discussion rather than passed on consent.
('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5', 'Cedric L. Hicks Sr.',
 '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'Homelessness Response', 2,
 'As Chair of the South Bay Cities Council of Governments, he pressed the City''s homeless services team at the January 23, 2024 meeting on how often it coordinates with the SBCCOG and whether it has the resources available to it, and reported that he is working on additional grant funding that will become available. He also identified an undercounted population, noting that many people experiencing homelessness in Carson live in their cars and naming the streets where he had seen it.',
 ARRAY['https://carson.legistar.com/View.ashx?M=M&ID=1141751&GUID=4AEB539D-24E0-4D6B-8DB5-9FDC78DDF4EB']),

('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e', 'Lula Davis-Holmes',
 '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'Homelessness Response', 2,
 'At the January 23, 2024 meeting, after staff explained that managing donated goods was unworkable for lack of storage, she proposed that staff obtain vouchers from restaurants and stores through the City''s term purchase order so that assistance could be delivered directly, and the City Manager undertook to pursue it.',
 ARRAY['https://carson.legistar.com/View.ashx?M=M&ID=1141751&GUID=4AEB539D-24E0-4D6B-8DB5-9FDC78DDF4EB']),

-- Affordable Housing
('1581974b-2a8c-4439-acae-377bc06e1788', 'Jim Dear',
 '669cac97-66a6-4087-b036-936fbe62efb3', 'Affordable Housing', 3,
 'Speaking to Assemblyman Gipson on April 4, 2023 he raised the housing crisis and asked that it be made part of the return of redevelopment, seeking to use redevelopment authority as a housing tool. At the Economic Development Strategic Plan hearing on September 19, 2023 he raised housing concerns again, particularly market-rate housing for new families and how to make the plan actually happen.',
 ARRAY['https://carson.legistar.com/View.ashx?M=M&ID=1075668&GUID=3AB64993-6B41-49B9-A9FC-A6634BED8F0A',
       'https://carson.legistar.com/View.ashx?M=M&ID=1107621&GUID=DAF7B914-61ED-442A-A966-99F0971EB65F']);

-- --- PRE-CONDITIONS -------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int; v_bad text;
BEGIN
  IF (SELECT count(*) FROM _car) <> 3 THEN
    RAISE EXCEPTION 'PRE: expected 3 proposed rows, found %', (SELECT count(*) FROM _car);
  END IF;

  -- All three are seated Carson councilmembers.
  SELECT count(*) INTO v_cnt
  FROM (SELECT DISTINCT politician_id FROM _car) d
  JOIN essentials.office_terms ot ON ot.politician_id = d.politician_id
  JOIN essentials.offices o  ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '0611530';
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'PRE: expected 3 seated Carson members, found %', v_cnt; END IF;

  -- 1564 left every Carson member at zero; nothing may be overwritten.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT politician_id FROM _car);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: members already hold % answers', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT politician_id FROM _car);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: members already hold % context rows', v_cnt; END IF;

  -- Topics live, chair values real.
  SELECT count(*) INTO v_cnt FROM _car a
   JOIN inform.compass_topics t ON t.id = a.topic_id AND t.is_live;
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 map to a live topic', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM _car a
   JOIN inform.compass_stances s ON s.topic_id = a.topic_id AND s.value = a.value;
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 carry a value on their topic scale', v_cnt; END IF;

  -- Every source must be a Carson Legistar minutes URL.
  SELECT string_agg(DISTINCT s, ', ') INTO v_bad
  FROM _car a, unnest(a.sources) s
  WHERE s NOT LIKE 'https://carson.legistar.com/View.ashx?M=M&ID=%';
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'PRE: non-minutes source(s): %', v_bad; END IF;

  -- Local Immigration Enforcement is verified absent for all five and must not be assigned here.
  SELECT count(*) INTO v_cnt FROM _car
   WHERE topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: immigration is verified absent, found % row(s)', v_cnt; END IF;
END $$;

-- --- CHANGES --------------------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
SELECT politician_id, topic_id, value, NULL FROM _car;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, topic_id, reasoning, sources FROM _car;

UPDATE essentials.politicians
   SET last_stances_researched_at = now()
 WHERE id IN (SELECT DISTINCT politician_id FROM _car);

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT politician_id FROM _car);
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'POST: expected 3 answers, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT politician_id FROM _car);
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'POST: expected 3 context rows, found %', v_cnt; END IF;

  -- Answers and context pair exactly; no orphan either way.
  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  FULL OUTER JOIN inform.politician_answers a
    ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE COALESCE(a.politician_id, c.politician_id) IN (SELECT politician_id FROM _car)
    AND (a.politician_id IS NULL OR c.politician_id IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % unpaired rows', v_cnt; END IF;

  -- Hilton and Rojas gained nothing and must still be at zero — they had no usable evidence at all.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN ('d1b1bc73-575f-444e-a2f8-46c04b07d3f8',   -- Jawane Hilton
                           '258b185a-5b28-45a0-9e7f-a05a58080197');  -- Arleen B. Rojas
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: Hilton/Rojas unexpectedly hold % answers', v_cnt; END IF;

  -- Nobody has a stance with no citation.
  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT politician_id FROM _car)
     AND (sources IS NULL OR array_length(sources, 1) IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % rows carry no citation', v_cnt; END IF;
END $$;

COMMIT;
