-- CC_0215 — merge the two John Fleming rows, and correct what the duplicate was hiding.
--
-- One man, three stages: U.S. Representative (LA-4) -> candidate for U.S. Senate -> State Treasurer
-- of Louisiana. We hold him twice. Adjudication:
-- `.planning/todos/2026-10-09-finance-surname-buckets.md`. Decision page for the one editorial call:
-- https://claude.ai/artifact/QxK7QC1t9AzKTveGDGw7JL
--
--   canonical  a750bce8-a3ec-45fb-9812-5bb6f726e32f   Treasurer, Louisiana — ACTIVE, holds the seat
--   retired    8be7e981-77a6-4ef7-b8d7-891fd9cc26d8   Candidate, U.S. Senate — inactive
--
-- Identity, two sources: `treasury.la.gov/about/meet-the-treasurer` names "John Fleming, MD" as
-- Treasurer; Ballotpedia's "John Fleming (Louisiana)" gives the Treasurer tenure from 2024, the 4th
-- District service, and the Republican Senate primary runoff loss on 2026-06-27 — which is exactly
-- the `term_end` `CA_0222` wrote on the retired row.
--
--
-- ══ THE ONE EDITORIAL DECISION: SEASON 2 SAME-SEX-MARRIAGE, 4 -> 5 ════════════════════════════
--
-- The two rows disagreed on 5 of their 15 shared pairs. Four are in CLOSED Season 1 and are not
-- editable; the canonical values stand as history. One is in OPEN Season 2 and had to be decided.
--
--   rung 4  Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples.
--   rung 5  Make same-sex marriage illegal and define marriage as only between one man and one woman.
--
-- 🔴 **THE CANONICAL ROW'S REASONING WAS FACTUALLY WRONG, AND IT WAS THE WHOLE BASIS FOR THE 4.**
-- It read: "His position is state authority to restrict SSM, *not a federal constitutional ban*."
-- He cosponsored a federal constitutional ban.
--
-- 🟢 **PRIMARY SOURCE, READ 2026-10-09.** congress.gov lists `Rep. Fleming, John [R-LA-4]*` as an
-- ORIGINAL cosponsor (the asterisk) of **H.J.Res.32, "Marriage Protection Amendment", 114th
-- Congress**, dated **02/12/2015**, one of 37. Its operative text proposes to write into the U.S.
-- Constitution:
--
--     "Marriage in the United States shall consist only of the union of a man and a woman. Neither
--      this Constitution, nor the constitution of any State, shall be construed to require that
--      marriage or the legal incidents thereof be conferred upon any union other than the union of
--      a man and a woman."
--
-- ▶ **RUNG 4 IS EXCLUDED BY THE INSTRUMENT.** Rung 4 requires recognising civil unions. The second
-- sentence bars any requirement to confer "the legal incidents" of marriage on a union other than a
-- man and a woman, which is what a civil union is. Rungs 1-3 all permit same-sex marriage, which he
-- acted to forbid. **Rung 5 is what remains**, reached by elimination from the document itself.
--
-- ⚠ **ONE CAVEAT, KEPT IN THE VOTER-FACING PROSE.** The amendment denies legal recognition
-- nationwide; it does not make same-sex marriage a crime, and rung 5's wording says "illegal". The
-- reasoning says so plainly, so a reader can weigh it. It is a balancing fact, not bookkeeping —
-- strip the bookkeeping, keep the caveat (the rule CC_0213's slice paid for).
--
-- 🔴 congress.gov answers 403 to curl even with a browser user-agent. It was read in Playwright.
-- Both rows previously rested on ontheissues.org, an aggregator, for a claim this strong.
--
--
-- ══ WHAT ELSE MOVES, AND WHY THE PRIMARY KEY DECIDES MOST OF IT ═══════════════════════════════
--
-- `inform.politician_answers` is PRIMARY KEY (politician_id, topic_id, season_id).
--
--   15 overlapping pairs   cannot be re-pointed — the key collides. The retired copies are DELETED.
--                          10 of them agree outright; 4 disagree inside closed Season 1, where the
--                          canonical value is the historical record and stays.
--    5 retired-row-only    re-point cleanly: campaign-finance, childcare, housing, tariffs (S1) and
--                          housing (S2). Their context rows re-point with them. Content untouched.
--
-- 🔴 **THE CLOSED-SEASON HATCH IS USED, AND ONLY FOR WHAT IT IS FOR.** `SET LOCAL
-- inform.allow_closed_season_write = 'on'` below. Season 1 is closed, so re-pointing a Season 1 row's
-- `politician_id` and deleting a retired duplicate's Season 1 rows both trip
-- `inform.closed_season_is_immutable()`. Neither changes a value, a reasoning or a source in a closed
-- season: one moves a row between rows of the SAME PERSON, the other removes a duplicate of a row the
-- canonical already holds. That is the `CC_0186` use. **No closed-season CONTENT is edited anywhere in
-- this file** — the only value that changes is in OPEN Season 2.
--
-- Also moved: the Senate candidacy `office_terms` row (2024-12-13 .. 2026-06-27, closed by `CA_0222`
-- off the official LA SOS result, Letlow 180,002 / Fleming 136,591) and the campaign-finance source
-- `fec_senate:S6LA00318`, which the canonical row did not have.
-- ⚠ The candidacy term is PAST, and `essentials.current_office_holders` filters on
-- `term_end >= CURRENT_DATE`, so it cannot make a politician-rooted join report the candidacy as his
-- current office. Checked before moving it.
--
-- 🔴 **THE PHOTO: KEEP THE CANONICAL ONE, DELETE THE DUPLICATE ROW, AND DO NOT MOVE THE ORIGIN.**
-- I looked at both files. Same man. The canonical row serves a large, well-composed portrait; the
-- retired row serves the 225x275 congressional thumbnail. Moving its `politician_images` row would
-- make TWO `type='default'` rows and the grid's `find()` would pick arbitrarily — the `CC_0195`
-- hazard — so it is deleted. ⚠ Its `photo_origin_url`
-- (`unitedstates.github.io/images/congress/225x275/F000456.jpg`) is the provenance of the SMALL file
-- and is NOT copied across; attaching it to the canonical row would assert a false source for a
-- different image. The canonical row's missing origin is a real gap and is left visible rather than
-- papered over.
--
-- 🟢 All five CASCADE / SET NULL foreign keys measure ZERO on BOTH rows (`politician_name_aliases`,
-- `inform.evidence_items`, `inform.politician_context_evidence`, `topic_rewrite_stance_proposals`,
-- `quest_verified_facts`). The pre-flight asserts it and aborts on a single row: two of those hold
-- stance research and vanish silently.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). Re-running is a no-op.

BEGIN;

-- Re-pointing and de-duplicating rows of ONE person across a closed season. No closed-season value,
-- reasoning or source is edited. See the block above.
SET LOCAL inform.allow_closed_season_write = 'on';

DO $$
DECLARE
  v_cnt   int;
  v_moved int;
  k_in  uuid := '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8';  -- retired
  k_ok  uuid := 'a750bce8-a3ec-45fb-9812-5bb6f726e32f';  -- canonical
  k_ssm uuid;
  k_s2  uuid;
  v_reasoning CONSTANT text :=
    'Fleming was an original cosponsor of the Marriage Protection Amendment (H.J.Res. 32 in the 114th Congress), joining it on 12 February 2015. The amendment would have written into the United States Constitution that marriage "shall consist only of the union of a man and a woman", and that neither the federal constitution nor any state constitution could be read to require that marriage, or the legal incidents of marriage, be conferred on any other union. He also cosponsored the State Marriage Defense Act, which would have let states decide whether same-sex marriages were recognised for federal purposes, and the Marriage and Religious Freedom Act. One qualification a reader should weigh: the amendment would have denied same-sex marriage legal recognition across the country rather than made it a crime. It also forecloses civil unions as a middle course, because it bars any requirement to confer the legal incidents of marriage on a union other than that of a man and a woman.';
  v_sources CONSTANT text[] := ARRAY[
    'https://www.congress.gov/bill/114th-congress/house-joint-resolution/32/text',
    'https://www.congress.gov/bill/114th-congress/house-joint-resolution/32/cosponsors'];
BEGIN

  -- ─────────────────────────────────────────────── already applied? verify and stop.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = k_in) THEN
    SELECT count(*) INTO v_cnt FROM essentials.politician_merges WHERE retired_id = k_in AND canonical_id = k_ok;
    IF v_cnt <> 1 THEN
      RAISE EXCEPTION 'CC_0215: the retired row is gone but the merge ledger holds % rows for it, expected 1', v_cnt;
    END IF;
    SELECT count(*) INTO v_cnt FROM inform.politician_answers WHERE politician_id = k_ok;
    IF v_cnt <> 21 THEN
      RAISE EXCEPTION 'CC_0215: already applied, but the canonical row holds % answers, expected 21', v_cnt;
    END IF;
    RAISE NOTICE 'CC_0215: already applied — retired row absent, ledger row present, canonical holds 21 answers. Nothing to do.';
    RETURN;
  END IF;

  SELECT id INTO k_ssm FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage';
  SELECT id INTO k_s2  FROM inform.seasons        WHERE number = 2;
  IF k_ssm IS NULL OR k_s2 IS NULL THEN
    RAISE EXCEPTION 'CC_0215: could not resolve the same-sex-marriage topic or season 2';
  END IF;

  -- ─────────────────────────────────────────────── PRE-FLIGHT
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = k_ok AND is_active = true AND full_name = 'John Fleming';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: the canonical row is not an active John Fleming'; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = k_in AND is_active = false AND full_name = 'John Fleming';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: the retired row is not an inactive John Fleming'; END IF;

  -- 🔴 the five that would vanish silently
  SELECT (SELECT count(*) FROM essentials.politician_name_aliases    WHERE politician_id IN (k_in,k_ok))
       + (SELECT count(*) FROM inform.evidence_items                 WHERE politician_id IN (k_in,k_ok))
       + (SELECT count(*) FROM inform.politician_context_evidence    WHERE politician_id IN (k_in,k_ok))
       + (SELECT count(*) FROM inform.topic_rewrite_stance_proposals WHERE politician_id IN (k_in,k_ok))
       + (SELECT count(*) FROM essentials.quest_verified_facts       WHERE politician_id IN (k_in,k_ok))
    INTO v_cnt;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0215: % CASCADE/SET NULL child rows hang off these two rows, expected 0 — STOP and count them by hand', v_cnt;
  END IF;

  -- the shape this file was written against
  SELECT count(*) INTO v_cnt FROM inform.politician_answers WHERE politician_id = k_in;
  IF v_cnt <> 20 THEN RAISE EXCEPTION 'CC_0215: retired row holds % answers, expected 20', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM inform.politician_context WHERE politician_id = k_in;
  IF v_cnt <> 22 THEN RAISE EXCEPTION 'CC_0215: retired row holds % context rows, expected 22 (20 + 2 orphans)', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM inform.politician_answers WHERE politician_id = k_ok;
  IF v_cnt <> 16 THEN RAISE EXCEPTION 'CC_0215: canonical row holds % answers, expected 16', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = k_ok AND topic_id = k_ssm AND season_id = k_s2 AND value = 4;
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0215: canonical Season 2 same-sex-marriage is not 4 — somebody has already changed it, re-read before running this';
  END IF;

  -- the retired row must hold nothing this file does not account for
  SELECT (SELECT count(*) FROM essentials.politician_contacts WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.identifiers         WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.race_candidates     WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.addresses           WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.degrees             WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.experiences         WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.legislative_service WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.politician_committees WHERE politician_id = k_in)
       + (SELECT count(*) FROM inform.stance_research_review  WHERE politician_id = k_in)
       + (SELECT count(*) FROM inform.stance_coder_labels     WHERE politician_id = k_in)
       + (SELECT count(*) FROM inform.stance_gold_labels      WHERE politician_id = k_in)
       + (SELECT count(*) FROM empower.empowered_profiles     WHERE politician_id = k_in)
    INTO v_cnt;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0215: the retired row carries % rows in tables this migration does not handle — read them before deleting', v_cnt;
  END IF;

  -- ⚠ `politician_id_bridge` is deliberately NOT in that sum: prod authenticates as `ev_api`, which
  -- has no SELECT on it, and the count above is a plain belt-and-braces check. Its foreign key to
  -- essentials.politicians is NO ACTION, so the FK itself refuses the DELETE below if a row exists —
  -- the real guard is the constraint, not this query. Measured 0 out of band on 2026-10-09.
  IF has_table_privilege('politician_id_bridge', 'SELECT') THEN
    EXECUTE 'SELECT count(*) FROM politician_id_bridge WHERE essentials_id = $1' INTO v_cnt USING k_in;
    IF v_cnt <> 0 THEN
      RAISE EXCEPTION 'CC_0215: politician_id_bridge holds % rows for the retired id', v_cnt;
    END IF;
  ELSE
    RAISE NOTICE 'CC_0215: cannot read politician_id_bridge as this role; relying on its NO ACTION foreign key to refuse the delete if it holds a row.';
  END IF;

  -- ─────────────────────────────────────── PART 1: the editorial decision, in the OPEN season
  UPDATE inform.politician_answers
     SET value = 5, updated_at = now()
   WHERE politician_id = k_ok AND topic_id = k_ssm AND season_id = k_s2;

  UPDATE inform.politician_context
     SET reasoning = v_reasoning, sources = v_sources, updated_at = now()
   WHERE politician_id = k_ok AND topic_id = k_ssm AND season_id = k_s2;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: rewrote % context rows for Season 2 same-sex-marriage, expected 1', v_cnt; END IF;

  -- ─────────────────────────────────────── PART 2: carry the five across, content untouched
  WITH only_there AS (
    SELECT pa.topic_id, pa.season_id
      FROM inform.politician_answers pa
     WHERE pa.politician_id = k_in
       AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pb
                        WHERE pb.politician_id = k_ok AND pb.topic_id = pa.topic_id AND pb.season_id = pa.season_id)
  ), moved_ctx AS (
    UPDATE inform.politician_context pc
       SET politician_id = k_ok
      FROM only_there o
     WHERE pc.politician_id = k_in AND pc.topic_id = o.topic_id AND pc.season_id = o.season_id
    RETURNING 1
  ), moved_ans AS (
    UPDATE inform.politician_answers pa
       SET politician_id = k_ok
      FROM only_there o
     WHERE pa.politician_id = k_in AND pa.topic_id = o.topic_id AND pa.season_id = o.season_id
    RETURNING 1
  )
  SELECT (SELECT count(*) FROM moved_ans) INTO v_moved;
  IF v_moved <> 5 THEN
    RAISE EXCEPTION 'CC_0215: carried % answers across, expected 5', v_moved;
  END IF;

  -- ─────────────────────────────────────── PART 3: the retired row's remaining rows go
  DELETE FROM inform.politician_context WHERE politician_id = k_in;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 17 THEN
    RAISE EXCEPTION 'CC_0215: deleted % context rows from the retired row, expected 17 (15 duplicates + 2 orphans)', v_cnt;
  END IF;

  DELETE FROM inform.politician_answers WHERE politician_id = k_in;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 15 THEN
    RAISE EXCEPTION 'CC_0215: deleted % answers from the retired row, expected 15 duplicates', v_cnt;
  END IF;

  -- ─────────────────────────────────────── PART 4: history and money move to the surviving row
  UPDATE essentials.office_terms SET politician_id = k_ok WHERE politician_id = k_in;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: re-pointed % office_terms rows, expected 1 (the Senate candidacy)', v_cnt; END IF;

  UPDATE transparent_motivations.politician_sources
     SET essentials_politician_id = k_ok, updated_at = now()
   WHERE essentials_politician_id = k_in;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: re-pointed % finance sources, expected 1 (fec_senate:S6LA00318)', v_cnt; END IF;

  -- the duplicate default image is DELETED, not moved — two type='default' rows break the grid
  DELETE FROM essentials.politician_images WHERE politician_id = k_in;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: deleted % image rows from the retired row, expected 1', v_cnt; END IF;

  -- ─────────────────────────────────────── PART 5: the ledger, then the row
  INSERT INTO essentials.politician_merges (retired_id, canonical_id, retired_name, migration, merged_at, evidence, moved)
  VALUES (k_in, k_ok, 'John Fleming', 'CC_0215', now(),
    'One man: US Representative LA-4 (2009-2017), candidate for US Senate (FEC Form 2 receipt 2024-12-13, lost the Republican second party primary 2026-06-27, Letlow 180,002 / Fleming 136,591 per LA SOS), then Treasurer of Louisiana. treasury.la.gov/about/meet-the-treasurer names "John Fleming, MD" as Treasurer; Ballotpedia "John Fleming (Louisiana)" records the Treasurer tenure from 2024, the 4th District service and the runoff loss on 2026-06-27, which is exactly the term_end CA_0222 wrote on the retired row.',
    jsonb_build_object(
      'answers_carried', 5,
      'answers_deleted_as_duplicates', 15,
      'context_carried', 5,
      'context_deleted', 17,
      'context_deleted_orphans', jsonb_build_array('homelessness season 1', 'voting-rights season 1'),
      'office_terms_repointed', 1,
      'finance_sources_repointed', jsonb_build_array('fec_senate:S6LA00318'),
      'images_deleted', 1,
      'photo_origin_url_not_copied', 'https://unitedstates.github.io/images/congress/225x275/F000456.jpg'));

  DELETE FROM essentials.politicians WHERE id = k_in;
  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: deleted % politician rows, expected 1', v_cnt; END IF;

  -- ─────────────────────────────────────── VERIFY the end state
  SELECT count(*) INTO v_cnt FROM inform.politician_answers WHERE politician_id = k_ok;
  IF v_cnt <> 21 THEN RAISE EXCEPTION 'CC_0215: canonical row holds % answers, expected 21 (16 + 5)', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = k_ok AND topic_id = k_ssm AND season_id = k_s2 AND value = 5;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: Season 2 same-sex-marriage did not land on 5'; END IF;

  -- the reasoning must name the instrument it rests on, and must not carry the sentence it replaced
  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id = k_ok AND topic_id = k_ssm AND season_id = k_s2
     AND reasoning LIKE '%H.J.Res. 32%' AND reasoning NOT LIKE '%not a federal constitutional ban%';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: the Season 2 same-sex-marriage reasoning does not cite H.J.Res. 32, or still carries the sentence it replaced'; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.office_terms WHERE politician_id = k_ok;
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'CC_0215: canonical row holds % office_terms, expected 2 (Treasurer + the Senate candidacy)', v_cnt; END IF;

  -- ⚠ and the past candidacy must NOT read as a current office
  SELECT count(*) INTO v_cnt FROM essentials.office_current_holder WHERE politician_id = k_ok;
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0215: the canonical row reads as holding % current offices, expected 1 — the closed candidacy must not be current', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politician_images WHERE politician_id = k_ok;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: canonical row holds % image rows, expected exactly 1', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources WHERE essentials_politician_id = k_ok;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: canonical row holds % finance sources, expected 1', v_cnt; END IF;

  -- nothing anywhere may still point at the retired id
  SELECT (SELECT count(*) FROM inform.politician_answers     WHERE politician_id = k_in)
       + (SELECT count(*) FROM inform.politician_context     WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.office_terms       WHERE politician_id = k_in)
       + (SELECT count(*) FROM essentials.politician_images  WHERE politician_id = k_in)
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id = k_in)
    INTO v_cnt;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0215: % rows still point at the retired id', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politician_merges WHERE retired_id = k_in AND canonical_id = k_ok;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0215: the merge ledger holds % rows for this pair, expected 1', v_cnt; END IF;

  RAISE NOTICE 'CC_0215: merged John Fleming. Season 2 same-sex-marriage 4 -> 5 on H.J.Res.32 (original cosponsor, 2015-02-12); 5 answers carried across; 15 duplicates and 17 context rows deleted; the Senate candidacy term and fec_senate:S6LA00318 re-pointed; 8be7e981 retired with a ledger row.';
END $$;

-- @context-decision: deleted — the two orphan context rows on the retired row (homelessness and
-- voting-rights, both Season 1) had NO answer to begin with, so nothing was un-chaired here. They
-- belong to a duplicate row that no longer exists. Season 1 is closed, so a documented blank cannot
-- be written there, and re-pointing them to the canonical row would park prose that Citations.jsx
-- would render verbatim if an answer for that pair ever appeared. Both are gate-visible orphans by
-- ORPHAN_CONTEXT's own predicate (sources non-empty, no carve-out phrasing), so deleting them lowers
-- the gate's count by two rather than raising it. Captured verbatim first, as the template requires:
-- `backend/data/stance-retirement/2026-10-09-cc0215-fleming-orphan-context.json`.

-- GUARD: the answers deleted above must not leave gate-visible orphan context behind. This is
-- check-stance-sources.mjs's ORPHAN_CONTEXT predicate applied to the rows THIS migration touched.
-- ⚠ Keep the two regexes character-identical to the gate's.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM inform.politician_context pc
   WHERE pc.politician_id IN ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8'::uuid,
                              'a750bce8-a3ec-45fb-9812-5bb6f726e32f'::uuid)
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = pc.politician_id
                        AND pa.topic_id = pc.topic_id
                        AND pa.season_id = pc.season_id)
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';

  IF new_orphans > 0 THEN
    RAISE EXCEPTION
      'context guard: % row(s) lost their answer but kept reasoning that still describes a position. '
      'Delete that context, or rewrite it as a documented blank, IN THIS MIGRATION -- not later.',
      new_orphans;
  END IF;
END $$;

COMMIT;
