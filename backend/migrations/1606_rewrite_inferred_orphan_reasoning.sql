-- 1606_rewrite_inferred_orphan_reasoning.sql
--
-- Rewrites 7 orphan rows whose reasoning inferred a stance instead of citing one. None is published,
-- so none is voter-facing today -- this defuses them BEFORE anyone can promote them, which is the
-- entire purpose of isolating the ORPHAN_CONTEXT cohort.
--   Research record: data/stance-research/2026-08-07-orphan-58-triage.md
--   Rollback record: data/stance-retirement/2026-08-07-inferred-reasoning-rollback.json
--
-- 🔴 THE DETECTOR OVER-FIRED AND WAS NOT TRUSTED. A regex for inference verbs matched 9 rows; 7 are
-- real. Excluded after reading them:
--   · Rae Huang / Residential Zoning -- matched ONLY because "displacement" contains "placement".
--     The reasoning contains no inference at all. Sixteenth first-cut over-fire on this workstream.
--   · Andrew Kim / Housing -- says he "addresses affordability ... without a detailed housing
--     development strategy". That STATES an absence rather than inferring a stance from one, and the
--     LAist guide independently records "lacks specific strategies". Honest, and left alone.
-- The distinction that matters: inferring a POSITION from an absence is the defect; reporting the
-- absence is the remedy.
--
-- ---------------------------------------------------------------------------------------------
-- WHAT WAS WRONG, ROW BY ROW. All seven reasoned from something other than the person's own words.
--
-- Amy Bartley / Growth -- "Her leans-slow-growth SCORE reflects Prosper's broader COUNCIL posture".
--   Two defects in one sentence: it narrates a score that does not exist (the signature of the
--   partial write that created this cohort), and it attributes the council's collective posture to
--   an individual member. Its only citation is the town council ROSTER page, which records that she
--   holds the seat and nothing else.
-- Marcus Ray / Taxes -- "His Finance Committee role and ... background ... SUGGEST a fiscally
--   conservative orientation". Attribute-prior from committee membership and a former job title.
--   Cited to a staff directory entry and a biography; neither states a tax position.
-- Andy Barr / Medicare-aid -- "his 0% ARA rating ... SIGNALS strong support for reducing Medicare and
--   Medicaid". A stance inferred from an interest-group rating. 🔴 And his OWN healthcare page points
--   the other way on the specifics: he cosponsored legislation "fix[ing] the Medicare physician fee
--   schedule, preventing further cuts to physicians pay" and supported expediting coverage
--   determinations "ensuring that seniors have access" to breakthrough devices. The page does not
--   mention Medicaid, repeal, or entitlements at all. Re-sourced to it.
-- Andy Barr / Misinformation -- "His conservative alignment SUGGESTS strong opposition to government
--   content moderation mandates". Textbook attribute-prior: a position deduced from party alignment.
--   Verified while re-sourcing him: his official policy-issues menu carries no technology or
--   online-speech section at all.
-- Andrew Kim / Taxes -- "No specific tax policy positions stated ... SUGGESTS a preference for fiscal
--   restraint". Argues from absence: the sentence concedes there is no evidence and then scores one.
-- Andrew Kim / Local Immigration Enforcement -- "framing SUGGESTS neither full sanctuary nor
--   aggressive deportation cooperation". Replaced with what he actually said, which the LAist guide
--   carries verbatim -- the one row here that gains real evidence rather than a blank.
-- Bryant Acosta / Immigration -- "takes a supportive stance toward immigrant communities ... though
--   detailed policy positions were not publicly available". Same shape as his Local Immigration
--   Enforcement row corrected in 1605.
--
-- ⚠ ontheissues.org citations are KEPT on both Barr rows. The host resolves (A 68.178.204.78) but
-- will not connect from here, so it is UNKNOWN, not dead -- and unknown is never grounds for removal.
-- The verified .gov page is added ahead of it. The defect being fixed is the reasoning's inference
-- structure, which does not depend on what ontheissues says.
--
-- GATE: six rows become documented blanks and leave the cohort by the existing carve-out;
-- Kim / Local Immigration Enforcement keeps a substantive characterisation and stays.
-- ORPHAN_CONTEXT 56 -> 50. Baseline ratcheted in the same commit.

BEGIN;

DO $$
DECLARE
  v_n          int;
  v_orph_after int;
  laist_mayor text := 'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor';
  p_bartley uuid := '3631dd31-cb1a-46e1-ae2d-da54ea911411'; t_growth uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  p_ray     uuid := 'e89206d9-e960-472f-8402-691dc498355e'; t_taxes  uuid := 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
  p_barr    uuid := 'd6d297f5-5319-4be1-b938-6bcce63368e7';
  t_medicare uuid := 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
  t_misinfo  uuid := 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
  p_kim     uuid := '7f6c4fa3-192b-4abf-885b-2006c43a3fc9';
  t_lie     uuid := 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
  p_acosta  uuid := 'ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe';
  t_immig   uuid := '4e2c69ce-591e-4197-9cd5-7aceff79d390';
BEGIN
  -- ---- guards: all seven must still be unpublished orphans ----
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE (politician_id = p_bartley AND topic_id = t_growth)
      OR (politician_id = p_ray     AND topic_id = t_taxes)
      OR (politician_id = p_barr    AND topic_id IN (t_medicare, t_misinfo))
      OR (politician_id = p_kim     AND topic_id IN (t_taxes, t_lie))
      OR (politician_id = p_acosta  AND topic_id = t_immig);
  IF v_n <> 0 THEN RAISE EXCEPTION '1606: % of the target rows already have an answer', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE (politician_id = p_bartley AND topic_id = t_growth)
      OR (politician_id = p_ray     AND topic_id = t_taxes)
      OR (politician_id = p_barr    AND topic_id IN (t_medicare, t_misinfo))
      OR (politician_id = p_kim     AND topic_id IN (t_taxes, t_lie))
      OR (politician_id = p_acosta  AND topic_id = t_immig);
  IF v_n <> 7 THEN RAISE EXCEPTION '1606: expected 7 target context rows, found %', v_n; END IF;

  -- ---- the six that become documented blanks ----
  UPDATE inform.politician_context SET reasoning = $txt$No public record found on Bartley's own position on the pace of growth and development. She holds a seat on the Prosper Town Council, but the cited town roster records only that she holds it: no statement, vote or position of hers on development approvals, density or growth management appears there.$txt$
   WHERE politician_id = p_bartley AND topic_id = t_growth;

  UPDATE inform.politician_context SET reasoning = $txt$No public record found on Ray's own tax positions. The cited town directory entry records his council seat and his Finance Committee membership, and his professional biography records a private-sector background; neither states a position of his on tax rates, the tax base, or new revenue measures.$txt$
   WHERE politician_id = p_ray AND topic_id = t_taxes;

  UPDATE inform.politician_context SET
    reasoning = $txt$No public record found establishing a position on reducing Medicare or Medicaid. Barr's official healthcare page describes cosponsoring legislation that "fixes the Medicare physician fee schedule, preventing further cuts to physicians pay", supporting legislation to expedite coverage determinations for FDA-approved breakthrough devices "ensuring that seniors have access to the most innovative and cutting-edge treatments", and backing robust funding for Community Health Centers. The page does not mention Medicaid, entitlement reform, or repeal.$txt$,
    sources = ARRAY['https://barr.house.gov/healthcare'] || sources
   WHERE politician_id = p_barr AND topic_id = t_medicare;

  UPDATE inform.politician_context SET reasoning = $txt$No public record found establishing a position on misinformation or government content moderation. Barr's official policy-issues menu covers agriculture, education, energy, financial services, healthcare, immigration, jobs and the economy, national defense, the opioid epidemic, spending and debt, values and veterans, and contains no technology or online-speech section.$txt$
   WHERE politician_id = p_barr AND topic_id = t_misinfo;

  -- ⚠ Phrased as "No public record found" deliberately. The first draft opened "No specific tax
  -- policy position stated", which is equally true but does NOT match the gate's documented-blank
  -- carve-out, so the row stayed in the cohort and the dry run failed at 51 instead of 50. The fix
  -- is to word the blank the way every other blank is worded -- NOT to widen the carve-out regex,
  -- which would exempt other rows nobody has read.
  UPDATE inform.politician_context SET reasoning = $txt$No public record found of a tax policy position in Kim's public campaign materials. His campaign emphasises accountability, reducing costs for working families, and opposing waste; none of these states a position on tax rates, tax structure, or new revenue measures.$txt$
   WHERE politician_id = p_kim AND topic_id = t_taxes;

  UPDATE inform.politician_context SET
    reasoning = $txt$No public record found on immigration admission levels or on access to public services for undocumented residents. Acosta's only stated position on federal matters is that he will "work with the White House when it benefits Los Angeles and push back hard when it doesn't", which takes no position on how many people should be admitted legally or on who should be eligible for public services.$txt$,
    sources = ARRAY[laist_mayor] || sources
   WHERE politician_id = p_acosta AND topic_id = t_immig;

  -- ---- the one that gains real evidence and stays a characterisation ----
  UPDATE inform.politician_context SET
    reasoning = $txt$Kim states that "while any type of blatant human right abuses by the federal agents will be called out and be confronted, the necessary and measured enforcement of U.S. immigration laws for the well-being of law-abiding Angelenos will be respected and supported." He supports federal enforcement while undertaking to confront abuses, but sets out no position on whether Los Angeles should honour ICE detainers, share immigration status information with federal agencies, or commit local police resources to immigration enforcement.$txt$,
    sources = ARRAY[laist_mayor] || sources
   WHERE politician_id = p_kim AND topic_id = t_lie;

  -- ---- post-verify ----
  -- Not one inference marker may survive on the seven.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE ((politician_id = p_bartley AND topic_id = t_growth)
       OR (politician_id = p_ray     AND topic_id = t_taxes)
       OR (politician_id = p_barr    AND topic_id IN (t_medicare, t_misinfo))
       OR (politician_id = p_kim     AND topic_id IN (t_taxes, t_lie))
       OR (politician_id = p_acosta  AND topic_id = t_immig))
     AND reasoning ~* 'suggests?|signals?|appears to|consistent with (his|her|their) overall|leans-|\yscore\y';
  IF v_n <> 0 THEN RAISE EXCEPTION '1606: % rewritten rows still infer a stance', v_n; END IF;

  -- None may gain an answer: rewriting is not promoting.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE (politician_id = p_bartley AND topic_id = t_growth)
      OR (politician_id = p_ray     AND topic_id = t_taxes)
      OR (politician_id = p_barr    AND topic_id IN (t_medicare, t_misinfo))
      OR (politician_id = p_kim     AND topic_id IN (t_taxes, t_lie))
      OR (politician_id = p_acosta  AND topic_id = t_immig);
  IF v_n <> 0 THEN RAISE EXCEPTION '1606: a rewritten row gained an answer'; END IF;

  -- ontheissues must survive on both Barr rows: unknown is not dead.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_barr AND topic_id IN (t_medicare, t_misinfo)
     AND sources::text ILIKE '%ontheissues%';
  IF v_n <> 2 THEN RAISE EXCEPTION '1606: ontheissues was dropped from a Barr row; unknown is not dead'; END IF;

  -- The verified .gov page must lead Barr's Medicare row.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_barr AND topic_id = t_medicare AND sources[1] = 'https://barr.house.gov/healthcare';
  IF v_n <> 1 THEN RAISE EXCEPTION '1606: Barr/Medicare does not lead with the verified source'; END IF;

  -- Nothing emptied, no duplicates introduced by the array prepends.
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE cardinality(sources) = 0;
  IF v_n <> 404 THEN RAISE EXCEPTION '1606: empty-sources rows moved to %, expected 404', v_n; END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT pc.politician_id, pc.topic_id, s
      FROM inform.politician_context pc, unnest(pc.sources) s
     WHERE pc.politician_id IN (p_barr, p_kim, p_acosta)
     GROUP BY pc.politician_id, pc.topic_id, s HAVING count(*) > 1) d;
  IF v_n <> 0 THEN RAISE EXCEPTION '1606: % duplicate citations created by the prepends', v_n; END IF;

  -- Six leave the cohort as documented blanks; Kim/Local Immigration Enforcement stays.
  SELECT count(*) INTO v_orph_after
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers a
      ON a.politician_id = pc.politician_id AND a.topic_id = pc.topic_id
   WHERE a.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF v_orph_after <> 50 THEN
    RAISE EXCEPTION '1606: ORPHAN_CONTEXT is % after, expected 50', v_orph_after; END IF;

  RAISE NOTICE '1606: 7 rows rewritten (6 to documented blanks, 1 re-evidenced); ORPHAN_CONTEXT -> %', v_orph_after;
END $$;

COMMIT;
