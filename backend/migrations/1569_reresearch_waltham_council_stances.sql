-- 1569_reresearch_waltham_council_stances.sql
--
-- Restore all FOUR remaining Waltham City Council stance rows, re-researched from the city's own
-- council minutes after migration 1564 retired Waltham's five rows as fabricated-source citations.
--
--   Review:   data/stance-research/reresearch-waltham/FINDINGS.md
--   Rollback: DELETE the 4 (politician_id, topic_id) pairs from inform.politician_answers and
--             inform.politician_context, then set last_stances_researched_at = NULL for the 4.
--   Follows:  1564 (retired all 5), 1566 (removed the fifth "member" — a fabricated person),
--             1567 Alhambra 16/19, 1568 Carson 3/34
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1569_reresearch_waltham_council_stances.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WALTHAM IS THE CLEANEST CLUSTER SO FAR: 4 OF 4
-- ---------------------------------------------------------------------------------------------------
-- All five retired rows were the same claim on the same two sources — `walthampatch.com` (DNS dead) and
-- `mass.gov/info-details/mbta-communities-compliance-status` — asserting a 2024 MBTA Communities Act
-- zoning vote. One of the five belonged to "Arthur Donahue", who does not exist; migration 1566 unseated
-- him. That leaves four real at-large councillors, all owed Affordable Housing.
--
-- ✅ The mass.gov denylist entry from 1564 is CORRECT and was re-checked rather than assumed. My probe
-- returned 403, which is a bot block and proves nothing (rule #2), so the real page was located instead:
-- Massachusetts publishes this at `/info-details/multi-family-zoning-requirement-for-mbta-communities`
-- (and `/info-details/mbta-communities-law-qa`). The cited slug is composed. No correction needed.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE 2024 VOTE THE RETIRED ROWS CLAIMED IS REAL — AND IT CONVICTS THE ROWS ANYWAY
-- ---------------------------------------------------------------------------------------------------
-- Waltham really did adopt MBTA Communities zoning: first reading 2024-12-23, third and final reading
-- 2025-01-13, approved 12-0-2-1. But the roll call does not say what the retired rows said:
--
--     In favor: Brasco, Dunn, Durkee, Hanley, Harris, Katz, LaCava, LaFauci, Logan, McMenimen,
--               Vidal and McLaughlin.
--     Opposed: None.   Absent: LeBlanc, Stanley.   Present: Bradley-MacArthur.
--
--   * BRASCO voted in favour.
--   * BRADLEY-MACARTHUR was recorded "Present" — present and deliberately NOT voting.
--   * LEBLANC was ABSENT.
--   * TIM KING IS NOT ON THE ROLL AT ALL, because he was not a councillor. 🔴 PRE-TENURE — he took
--     office 2026-01-04, a year after this vote. The 2025 roster seats McMenimen and Stanley, whom
--     King and Tzioumis replaced. This is the 1537 pre-tenure defect appearing in LOCAL government
--     again (as it did in Newton), and no tenure detector can catch it while `term_start` is NULL for
--     local officials.
--
-- ⚠ Name-matching trap avoided: "King" appears in 2025 minutes months before he took office — as
-- "King First West Owner, LLC". Substring matching on surnames over-fires exactly as `Chan`/`channel`
-- and `ICE`/`Ken's Ice Cream` did. The first councillor-King appearance is the 2026-01-04 inaugural.
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT THE ROWS NOW REST ON — a current-term roll call covering all four
-- ---------------------------------------------------------------------------------------------------
-- 2026-06-22, Affordable Housing Zoning Amendment (Article IX Sec. 9.1), third and final reading:
--
--     In favor: Bradley-MacArthur, Brasco, Dunn, Durkee, Hanley, Harris, Katz, King, LaCava,
--               LaFauci, LeBlanc, McLaughlin and Tzioumis.
--     Opposed: None.   Absent: Vidal.   Approved 13-0-1-1.
--
-- All four owed members voted in favour, in the current term, on the owed topic, in a deliberated
-- roll call — not on consent. Article IX Sec. 9.1 is Waltham's INCLUSIONARY ZONING article: developers
-- must set aside 15% of units at or below 80% AMI (8+ unit developments) and a further 5% at or below
-- 50% AMI (19+ units). Voting to amend and re-adopt that article affirms a regime that REQUIRES NEW
-- DEVELOPMENTS TO INCLUDE AFFORDABLE UNITS — chair 2 on this scale.
--
-- ⚠ HONEST LIMIT ON THE CLAIM: the minutes name the amendment but never state its substance, and no
-- primary description of what it changes was found. The reasoning below therefore says what the record
-- supports — a vote to amend and re-adopt the city's affordable-housing zoning article, at a hearing
-- where 16 residents stood in favour and nobody opposed — and does NOT assert that the amendment
-- strengthened or weakened the requirement. Chair 2 rests on the standing ordinance the vote affirms,
-- not on an assumed direction of change.
--
-- ⚠ 17 of Waltham's 61 published minutes PDFs are SCANNED IMAGES with no text layer and could not be
-- read. They are unassessed, not empty. 2024 minutes are absent from the CivicPlus archive entirely
-- (the city migrated from Drupal), which is why the 2025-01-13 minutes are the earliest record of the
-- 2024-12-23 first reading.
--
-- ⚠ Waltham's `hasContext` chip is left FALSE, consistent with the Carson ruling: four rows on one
-- topic for four of sixteen officials is not coverage. Operator call, flagged not taken.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _wal (
  politician_id uuid, full_name text, topic_id uuid, value numeric, reasoning text, sources text[]
) ON COMMIT DROP;

INSERT INTO _wal (politician_id, full_name, topic_id, value, reasoning, sources) VALUES

('28d25ed6-6a0f-428e-8b42-85a448ffb0c2', 'Paul Brasco',
 '669cac97-66a6-4087-b036-936fbe62efb3', 2,
 'Voted in favour of amending Article IX Section 9.1, Waltham''s affordable housing zoning article, at its third and final reading on June 22, 2026 (approved 13-0). The article requires developers to set aside 15 percent of units for households at or below 80 percent of area median income in developments of eight or more units, and a further 5 percent at or below 50 percent AMI in developments of nineteen or more. He had also voted in favour of the city''s MBTA Communities zoning, which allows multi-family housing as of right near transit, at its third and final reading on January 13, 2025.',
 ARRAY['https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_06222026-623',
       'https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_01132025-396']),

('42550273-382a-481f-afc9-ccdf32329bf6', 'Colleen Bradley-MacArthur',
 '669cac97-66a6-4087-b036-936fbe62efb3', 2,
 'Voted in favour of amending Article IX Section 9.1, Waltham''s affordable housing zoning article, at its third and final reading on June 22, 2026 (approved 13-0), and questioned Councillor Harris on the proposal at the joint public hearing on April 13, 2026. The article requires developers to set aside 15 percent of units for households at or below 80 percent of area median income in developments of eight or more units, and a further 5 percent at or below 50 percent AMI in developments of nineteen or more.',
 ARRAY['https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_06222026-623',
       'https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_04132026-434']),

('73a1f2f1-9112-4820-b853-8a8542c72d85', 'Randall LeBlanc',
 '669cac97-66a6-4087-b036-936fbe62efb3', 2,
 'Voted in favour of amending Article IX Section 9.1, Waltham''s affordable housing zoning article, at its third and final reading on June 22, 2026 (approved 13-0), and questioned Councillor Harris on the proposal at the joint public hearing on April 13, 2026. The article requires developers to set aside 15 percent of units for households at or below 80 percent of area median income in developments of eight or more units, and a further 5 percent at or below 50 percent AMI in developments of nineteen or more.',
 ARRAY['https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_06222026-623',
       'https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_04132026-434']),

('ab208b92-9067-4f3d-9791-60b404793b3a', 'Tim King',
 '669cac97-66a6-4087-b036-936fbe62efb3', 2,
 'Voted in favour of amending Article IX Section 9.1, Waltham''s affordable housing zoning article, at its third and final reading on June 22, 2026 (approved 13-0). The article requires developers to set aside 15 percent of units for households at or below 80 percent of area median income in developments of eight or more units, and a further 5 percent at or below 50 percent AMI in developments of nineteen or more. He took office on January 4, 2026, so this is his first recorded action on housing.',
 ARRAY['https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_06222026-623',
       'https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/_01042026-503']);

-- --- PRE-CONDITIONS -------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int; v_bad text;
BEGIN
  IF (SELECT count(*) FROM _wal) <> 4 THEN
    RAISE EXCEPTION 'PRE: expected 4 rows, found %', (SELECT count(*) FROM _wal);
  END IF;

  -- All four are seated Waltham councillors.
  SELECT count(*) INTO v_cnt
  FROM (SELECT DISTINCT politician_id FROM _wal) d
  JOIN essentials.office_terms ot ON ot.politician_id = d.politician_id
  JOIN essentials.offices o  ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2572600';
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'PRE: expected 4 seated Waltham councillors, found %', v_cnt; END IF;

  -- The fabricated Arthur Donahue must already be unseated by 1566 and must not appear here.
  IF EXISTS (SELECT 1 FROM _wal WHERE politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538') THEN
    RAISE EXCEPTION 'PRE: the fabricated Waltham mayor must never receive a stance row';
  END IF;
  SELECT count(*) INTO v_cnt FROM essentials.office_terms
   WHERE politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: Donahue is seated again (%) — 1566 was reverted', v_cnt; END IF;

  -- 1564 left all four at zero.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT politician_id FROM _wal);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: members already hold % answers', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT politician_id FROM _wal);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: members already hold % context rows', v_cnt; END IF;

  -- Topic live, chair value real.
  SELECT count(*) INTO v_cnt FROM _wal a
   JOIN inform.compass_topics t ON t.id = a.topic_id AND t.is_live
   JOIN inform.compass_stances s ON s.topic_id = a.topic_id AND s.value = a.value;
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 map to a live topic + real chair', v_cnt; END IF;

  -- Every source must be a Waltham minutes URL — never walthampatch.com or the composed mass.gov slug.
  SELECT string_agg(DISTINCT s, ', ') INTO v_bad
  FROM _wal a, unnest(a.sources) s
  WHERE s NOT LIKE 'https://www.city.waltham.ma.us/AgendaCenter/ViewFile/Minutes/%';
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'PRE: non-minutes source(s): %', v_bad; END IF;

  -- No row may cite a url on the fabricated denylist.
  IF EXISTS (SELECT 1 FROM _wal a, unnest(a.sources) s
              WHERE s ILIKE '%walthampatch%' OR s ILIKE '%mbta-communities-compliance-status%') THEN
    RAISE EXCEPTION 'PRE: a retired/fabricated source was reused';
  END IF;
END $$;

-- --- CHANGES --------------------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
SELECT politician_id, topic_id, value, NULL FROM _wal;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, topic_id, reasoning, sources FROM _wal;

UPDATE essentials.politicians
   SET last_stances_researched_at = now()
 WHERE id IN (SELECT DISTINCT politician_id FROM _wal);

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT politician_id FROM _wal);
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'POST: expected 4 answers, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT politician_id FROM _wal);
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'POST: expected 4 context rows, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  FULL OUTER JOIN inform.politician_answers a
    ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE COALESCE(a.politician_id, c.politician_id) IN (SELECT politician_id FROM _wal)
    AND (a.politician_id IS NULL OR c.politician_id IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % unpaired rows', v_cnt; END IF;

  -- The fabricated person still holds nothing.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: the fabricated mayor acquired % answers', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT politician_id FROM _wal)
     AND (sources IS NULL OR array_length(sources, 1) IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % rows carry no citation', v_cnt; END IF;
END $$;

COMMIT;
