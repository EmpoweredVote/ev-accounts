-- 1605_promote_lopez_correct_acosta.sql
--
-- The two rows that survived working the LA orphan cluster: 1 promoted to a published stance,
-- 1 false inference corrected to an honest documented blank.
--   Research record: data/stance-research/2026-08-07-orphan-58-triage.md
--   Rollback record: data/stance-retirement/2026-08-07-lopez-acosta-rollback.json
--
-- ⚠ SCOPE, STATED PLAINLY: the LA cluster was 34 rows and this migration touches 2. The cluster's
-- citations are live and rich -- LAist voter guides, Patch profiles, 43 of 60 URLs returning
-- substantial bodies -- but they answer DIFFERENT QUESTIONS than the compass topics ask, so the
-- other 32 are not scorable from them. Rich live sourcing is not the same as scorable. Full
-- reasoning in the research record; do not read this migration as the cluster being done.
--
-- ---------------------------------------------------------------------------------------------
-- 1. JUANITA LOPEZ / HOMELESSNESS RESPONSE -- promoted, chair 4.
--
-- This is the first promotion out of the ORPHAN_CONTEXT cohort, so it is the case that proves the
-- gate's premise: writing an answer PUBLISHES the existing reasoning verbatim under "Why this
-- position?". Her reasoning was therefore verified against a live source BEFORE the answer was
-- written, not after. The LAist LA-mayor voter guide -- already cited on the row, HTTP 200, 57k
-- visible characters -- carries her programme in the same terms the row uses: a database of unhoused
-- people with photographs and fingerprints, returning those with outstanding warrants, detaining
-- those who refuse assistance for mandatory detoxification, and Permanent Supportive Housing for the
-- rest. The reasoning is accurate as written and is NOT rewritten; only the answer is added.
--
-- Chair 4, "enforce anti-camping ordinances as the primary tool while maintaining basic outreach
-- programs": coercive intervention is her primary instrument. NOT chair 5 -- she proposes Permanent
-- Supportive Housing and hiring social workers, so she is not minimising spending on services.
-- NOT chair 3 -- "enforcing reasonable public space rules" does not describe court-ordered detention.
--
-- 2. BRYANT ACOSTA / LOCAL IMMIGRATION ENFORCEMENT -- false inference corrected, stays unpublished.
--
-- 🔴 THE OLD REASONING WAS REFUTED BY THE EVIDENCE, NOT MERELY UNSUPPORTED. It said he "appears to
-- support sanctuary city policies ... consistent with his overall progressive-to-moderate
-- positioning on social issues" -- a stance inferred from positioning, with no quote. His actual
-- words in the LAist guide: "I'll work with the White House when it benefits Los Angeles and push
-- back hard when it doesn't." That is not sanctuary advocacy. This is the attribute-prior class
-- (1521) caught before publication rather than after.
--
-- It is NOT retired: the row is a real research artifact with a real citation, and what he actually
-- said is worth recording. It becomes an honest documented blank -- which is what it always should
-- have been -- and therefore leaves the ORPHAN_CONTEXT queue by the same carve-out that exempts the
-- other documented blanks. No chair is assigned; his quote takes no position on ICE detainers,
-- information sharing, or use of local police resources.
--
-- ⚠ `acostaforla.com` is KEPT, not dropped. It resolves (A 64.207.152.120) but will not connect from
-- here -- UNKNOWN, not dead, and unknown is never grounds for removal. The LAist guide is added
-- ahead of it because it is the source actually read.
--
-- GATE: ORPHAN_CONTEXT 58 -> 56. Lopez leaves the cohort by gaining an answer; Acosta leaves it by
-- becoming a documented blank. Baseline ratcheted in the same commit.

BEGIN;

DO $$
DECLARE
  v_n          int;
  v_orph_after int;
  p_lopez  uuid := '1e76d1d0-ca06-47bd-a9a1-fd8a34a676b0';
  t_homel  uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  p_acosta uuid := 'ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe';
  t_ice    uuid := 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
  laist    text := 'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor';
BEGIN
  -- ---- guards ----
  -- Both must still be ORPHANS, or someone else has already acted on them.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE (politician_id = p_lopez AND topic_id = t_homel)
      OR (politician_id = p_acosta AND topic_id = t_ice);
  IF v_n <> 0 THEN RAISE EXCEPTION '1605: expected both rows to be orphans, found % answers', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE (politician_id = p_lopez AND topic_id = t_homel)
      OR (politician_id = p_acosta AND topic_id = t_ice);
  IF v_n <> 2 THEN RAISE EXCEPTION '1605: expected 2 context rows, found %', v_n; END IF;

  -- Lopez's reasoning is being published UNCHANGED, so the source that verifies it must be on the
  -- row already. If it is not, the verification does not belong to this row.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_lopez AND topic_id = t_homel AND laist = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1605: Lopez row does not already cite the verifying LAist guide'; END IF;

  -- ---- 1. promote Lopez ----
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  VALUES (p_lopez, t_homel, 4);

  -- ---- 2. correct Acosta ----
  UPDATE inform.politician_context SET
    reasoning = $txt$No public record found on local immigration enforcement. Acosta's only stated position on federal relations is that he will "work with the White House when it benefits Los Angeles and push back hard when it doesn't" — a general posture toward federal cooperation that takes no position on ICE detainers, on sharing immigration status information with federal agencies, or on the use of local police resources for immigration enforcement.$txt$,
    sources = ARRAY[laist, 'https://acostaforla.com']
   WHERE politician_id = p_acosta AND topic_id = t_ice;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_lopez AND topic_id = t_homel AND value = 4;
  IF v_n <> 1 THEN RAISE EXCEPTION '1605: Lopez was not promoted to chair 4'; END IF;

  -- Acosta must remain UNPUBLISHED -- correcting a row is not promoting it.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_acosta AND topic_id = t_ice;
  IF v_n <> 0 THEN RAISE EXCEPTION '1605: Acosta must not gain an answer'; END IF;

  -- The refuted claim must be gone, and the row must now read as a documented blank.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_acosta AND topic_id = t_ice
     AND (reasoning ILIKE '%sanctuary%' OR reasoning ILIKE '%appears to support%');
  IF v_n <> 0 THEN RAISE EXCEPTION '1605: the refuted sanctuary claim survived'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_acosta AND topic_id = t_ice
     AND reasoning ~* 'no (scorable |substantive |specific |detailed )?public record';
  IF v_n <> 1 THEN RAISE EXCEPTION '1605: Acosta row does not read as a documented blank'; END IF;

  -- acostaforla.com resolves but will not connect from here: UNKNOWN, never grounds for removal.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_acosta AND topic_id = t_ice AND 'https://acostaforla.com' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1605: acostaforla.com was dropped; unknown is not dead'; END IF;

  -- The ORPHAN_CONTEXT cohort must fall by exactly 2, computed the same way the gate computes it.
  SELECT count(*) INTO v_orph_after
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers a
      ON a.politician_id = pc.politician_id AND a.topic_id = pc.topic_id
   WHERE a.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF v_orph_after <> 56 THEN
    RAISE EXCEPTION '1605: ORPHAN_CONTEXT is % after, expected 56', v_orph_after; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE cardinality(sources) = 0;
  IF v_n <> 404 THEN RAISE EXCEPTION '1605: empty-sources rows moved to %, expected 404', v_n; END IF;

  RAISE NOTICE '1605: Lopez promoted to chair 4; Acosta corrected to a documented blank; ORPHAN_CONTEXT -> %', v_orph_after;
END $$;

COMMIT;
