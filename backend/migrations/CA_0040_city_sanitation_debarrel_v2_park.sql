-- CA_0040_city_sanitation_debarrel_v2_park.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- =============================================================================
-- CA_0040: City Sanitation — substantive v2 (chairs 1-3 de-barrel), parked for Season 2
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Rejects the open draft v2 (revision c8e2bf7e, a chair-1-only split), proposes a
--   FRESH substantive revision that de-barrels chairs 1, 2 AND 3, approves it, and
--   PARKS it (approved, unpublished, is_current=false). Chairs 4 and 5 are
--   BYTE-IDENTICAL to the published v1, so their 27 seatings are untouched. Identity
--   rung map (rungs stay in place; reworded only). This migration writes NO change to
--   politician_answers or politician_context, so no answer-delete guard applies.
--
-- THE AXIS (decision 2026-08-30, Chris Andrews)
--   "Who is responsible for keeping public spaces clean, and how" — from maximum
--   public provision (chair 1) to market/individual responsibility (chair 5). The
--   review considered a "theory-of-the-problem" reframe (each rung a distinct
--   diagnosis) but the author chose to KEEP the public->private provision spine. The
--   dial risk of a pure provision spine is mitigated by de-barreling: each rung is one
--   position, and chairs 2/3/4 vary by mechanism (targeting / commercial enforcement /
--   individual responsibility), not by volume alone.
--
-- THE THREE REWORDS
--   Chair 1  (already split in draft v2; carried forward)
--     OLD (v1) "Significantly expand sanitation staffing, cleaning frequency, and free
--               community disposal access; treat poor conditions as a services failure"
--               — a four-part double-barrel (staffing + frequency + free disposal +
--               framing clause).
--     NEW (v2) "Significantly expand public sanitation services, treating cleanliness as
--               the city's responsibility" — one position (max public provision); the
--               participial clause restates it (the benign kind).
--     Grounding: Philadelphia Mayor Parker (citywide expansion: twice-weekly pickup
--     pilot, per-district crews, 1,500 cans).
--
--   Chair 2  (de-barrel: KEEP the equity/targeting position, DROP the standalone
--             general-increase conjunction)
--     OLD (v1) "Increase sanitation crews and prioritize historically underserved
--               neighborhoods to equalize cleanliness communitywide" — two independent
--               positions ("increase crews" AND "prioritize underserved"); also a
--               superset of chair 1 (its expansion PLUS an equity clause), which is why
--               it overlapped chair 1.
--     NEW (v2) "Concentrate sanitation resources on the most neglected, worst-served
--               neighborhoods to close long-standing service gaps" — one position
--               (equity/targeting). Distinct from chair 1: CONCENTRATE vs SPREAD
--               citywide, not "chair 1 plus a clause". Overlap resolved.
--     Grounding: Philadelphia $3.8M focused on underserved districts; NYC "A Clean City
--     For All"; Helen Gym's equity framing.
--
--   Chair 3  (tighten; the two elements are kept as the recognized centrist model)
--     OLD (v1) "Maintain current sanitation services while enforcing anti-dumping laws
--               for businesses and large property owners"
--     NEW (v2) "Maintain current public sanitation services and target enforcement at
--               the businesses and large property owners who create the most waste"
--     BORDERLINE double-barrel, kept deliberately: this is the shared-responsibility
--     pivot of the axis (steady public service + commercial-targeted enforcement) and
--     the position 50 seated officials actually hold. Stripping the enforcement clause
--     would make a thin "do nothing" middle and force heavy re-seating.
--     Grounding: Philadelphia Illegal Dumping Task Force (property owners fined); San
--     Diego "Clean SD".
--
--   Chairs 4 & 5  BYTE-IDENTICAL to v1 (single positions, already clean). Not touched.
--
-- WHY SUBSTANTIVE, NOT CLARIFYING (decision 2026-08-30, Chris Andrews)
--   Reviewed against the CA_0028 residential-zoning test (a split is CLARIFYING only if
--   the dropped clause is an off-axis limb no seating depended on). Chair 2 lands the
--   other way, like CA_0030/CA_0034: the dropped "increase crews" conjunction is
--   LOAD-BEARING. Of the 30 answers seated on chair 2, a lexical pass finds 13 seated on
--   general expansion with no equity/targeting signal — under the narrowed (equity-only)
--   v2 wording they are not described by chair 2. That is a version bump; it waits for a
--   season change and does not enter open Season 1 (ADR 0006 sec 2).
--
-- WHY PARKED (approved, NOT published) AND NO SEASON-1 EDITS
--   The affected rows are CORRECTLY seated under v1 — v1's broader wording names the
--   clause each rests on. Editing Season 1 would corrupt correct, live data. This is the
--   CA_0030/CA_0034 shape: park the revision, defer the honest disposition to a Season-2
--   CARRY step applied to the Season-2 answer set at assembly (Season 2 has no answers
--   yet). A parked revision is is_current=false and serves no one; Season 1 keeps
--   showing v1 through the open season's pin.
--
-- WHY NOT PUBLISH NOW (the machinery gate)
--   admin_publish_topic_revision refuses any rung map that moves or invalidates a rung
--   (REPOINTING_NOT_IMPLEMENTED). The only publishable map is all-identity, which
--   asserts "every old chair-2 answer belongs at new chair 2" — false for the 13 above.
--   Parking at `approved` sidesteps that false assertion.
--
-- WHY NOT PIN SEASON 2 HERE
--   The Season-2 pin waits for assembly, alongside the answer carry + orphan
--   disposition. Pinning v2 while the 13 are undispositioned would falsely seat them the
--   moment Season 2 opens.
--
-- SEASON-2 CARRY LIST (handled at Season 2 assembly, NOT here)
--   backend/data/season2-carry/city-sanitation-reaudit.json — all 86 rows on chairs 1-3
--   classified by lexical heuristic (13 chair-2 axis-orphans, 17 thin/no-instrument, 56
--   likely-carry), shaped as audit-chair-evidence --check input. The authoritative gate
--   (scripts/audit-chair-evidence.mjs --check) reads 75/86 as naming no instrument, but
--   it is calibrated for state/federal bills/acts/votes and under-credits LOCAL
--   instruments (budget lines, council initiatives, district programs, questionnaires),
--   so it over-counts here. The debt is PRE-EXISTING under v1; this migration neither
--   creates nor resolves it. Decision: re-source first, blank if none, at assembly.
--
-- Idempotent: re-running after success is a no-op (guarded on the approved v2 chair-2
--   text). The whole body is one transaction, so a mid-run failure rolls back cleanly.
-- =============================================================================

BEGIN;

DO $mig$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'city-sanitation';
  v_draft_v2 CONSTANT uuid := 'c8e2bf7e-c937-4ec2-8f20-5c854dee3888';
  v_c1 CONSTANT text := $c1$Significantly expand public sanitation services, treating cleanliness as the city's responsibility$c1$;
  v_c2 CONSTANT text := $c2$Concentrate sanitation resources on the most neglected, worst-served neighborhoods to close long-standing service gaps$c2$;
  v_c3 CONSTANT text := $c3$Maintain current public sanitation services and target enforcement at the businesses and large property owners who create the most waste$c3$;
  v_c4 CONSTANT text := $c4$Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible$c4$;
  v_c5 CONSTANT text := $c5$Privatize sanitation services and require residents and businesses to contract for cleanup directly$c5$;
  v_rung_map CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_topic_id uuid;
  v_draft_id uuid;
  v_new_rev  uuid;
  v_stances  jsonb;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0040: topic % not found', v_key;
  END IF;

  -- Idempotency: an approved/published substantive v2 carrying the reworded chair 2
  -- already exists? Nothing to do.
  IF EXISTS (
    SELECT 1
    FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s
      ON s.topic_revision_id = r.id AND s.value = 2
    WHERE r.topic_id = v_topic_id
      AND r.change_class = 'substantive'
      AND r.version = 2
      AND r.status IN ('approved', 'published')
      AND s.text = v_c2
  ) THEN
    RAISE NOTICE 'CA_0040 already applied — substantive v2 with reworded chair 2 is approved/published; skipping.';
    RETURN;
  END IF;

  -- Reject every open draft (the chair-1-only draft v2, plus any lingering draft):
  -- propose needs the single open-revision slot clear. Rejected rows are retained, so
  -- the next revision number steps past them.
  FOR v_draft_id IN
    SELECT id FROM inform.compass_topic_revisions
    WHERE topic_id = v_topic_id AND status = 'draft'
  LOOP
    PERFORM inform.admin_reject_topic_revision(
      v_draft_id, v_actor,
      'Superseded by CA_0040: chair-1-only split widened to a full chairs 1-3 de-barrel on the provision spine.');
    RAISE NOTICE 'CA_0040: rejected draft %', v_draft_id;
  END LOOP;

  -- Propose the fresh substantive revision (identity rung map; ladder differs from v1,
  -- so the map is required and validated by the RPC).
  v_stances := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', v_c1),
    jsonb_build_object('value', 2, 'text', v_c2),
    jsonb_build_object('value', 3, 'text', v_c3),
    jsonb_build_object('value', 4, 'text', v_c4),
    jsonb_build_object('value', 5, 'text', v_c5)
  );

  v_new_rev := inform.admin_propose_topic_revision(
    v_key,
    v_actor,
    'substantive',
    'City Sanitation and Cleanliness',
    'City Sanitation and Cleanliness',
    'How should your community approach street cleanliness and sanitation?',
    v_stances,
    $rat$De-barrel chairs 1-3 on the public->private provision spine (decision 2026-08-30, Chris Andrews). Chair 1 keeps the draft-v2 split (four clauses -> one: max public provision, city responsibility). Chair 2 drops the standalone "increase crews" conjunction and keeps the equity/targeting position, resolving its overlap with chair 1 (CONCENTRATE vs SPREAD, not a superset). Chair 3 keeps the recognized centrist hybrid (steady public service + commercial-targeted enforcement) tightened. Chairs 4 and 5 are byte-identical to v1 and untouched. Substantive, not clarifying: chair 2's dropped conjunction is load-bearing for ~13 of its 30 seatings (general-expansion, no equity signal). Parked for Season 2; Season 1 keeps v1.$rat$,
    $pub$Reworded three options so each is a single, distinct position. Option 1: the city significantly expands public sanitation because cleanliness is its job. Option 2: concentrate resources on the most neglected neighborhoods (rather than "chair 1 plus an equity clause"). Option 3: hold services steady and target enforcement at the biggest waste generators. Options 4 and 5 are unchanged.$pub$,
    'Season-2 carry worklist: backend/data/season2-carry/city-sanitation-reaudit.json; provision-spine decision 2026-08-30 (Chris Andrews)',
    v_rung_map
  );
  RAISE NOTICE 'CA_0040: proposed fresh substantive revision %', v_new_rev;

  -- Approve it. DO NOT publish — park for Season 2.
  PERFORM inform.admin_approve_topic_revision(v_new_rev, v_actor);
  RAISE NOTICE 'CA_0040: approved (parked, unpublished) substantive v2 %', v_new_rev;
END $mig$;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $verify$
DECLARE
  v_topic_id uuid;
  v_v1_id    uuid;
  v_v2_id    uuid;
  v_ver      int;
  v_stat     text;
  v_curr     boolean;
  v_map      jsonb;
  v_rungs    int;
  v_c1 CONSTANT text := $c1$Significantly expand public sanitation services, treating cleanliness as the city's responsibility$c1$;
  v_c2 CONSTANT text := $c2$Concentrate sanitation resources on the most neglected, worst-served neighborhoods to close long-standing service gaps$c2$;
  v_c3 CONSTANT text := $c3$Maintain current public sanitation services and target enforcement at the businesses and large property owners who create the most waste$c3$;
  v_txt      text;
  v_diff     int;
  v_open_drafts int;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'city-sanitation';

  -- Locate the parked v2 by its reworded chair-2 text.
  SELECT r.id, r.version, r.status::text, r.is_current, r.rung_map
    INTO v_v2_id, v_ver, v_stat, v_curr, v_map
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s
    ON s.topic_revision_id = r.id AND s.value = 2
  WHERE r.topic_id = v_topic_id
    AND r.change_class = 'substantive'
    AND s.text = v_c2
  ORDER BY r.revision DESC
  LIMIT 1;

  IF v_v2_id IS NULL THEN
    RAISE EXCEPTION 'CA_0040 post-verify: reworded substantive v2 not found';
  END IF;
  IF v_ver <> 2 THEN
    RAISE EXCEPTION 'CA_0040 post-verify: version is % (expected 2)', v_ver;
  END IF;
  IF v_stat <> 'approved' THEN
    RAISE EXCEPTION 'CA_0040 post-verify: status is % (expected approved — must NOT be published)', v_stat;
  END IF;
  IF v_curr THEN
    RAISE EXCEPTION 'CA_0040 post-verify: v2 is is_current (expected false — a parked revision serves no one)';
  END IF;
  IF v_map <> '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb THEN
    RAISE EXCEPTION 'CA_0040 post-verify: rung_map is % (expected identity)', v_map;
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0040 post-verify: v2 has % rungs (expected 5)', v_rungs;
  END IF;

  -- Chairs 1 and 3 carry the reworded text.
  SELECT text INTO v_txt FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2_id AND value = 1;
  IF v_txt <> v_c1 THEN RAISE EXCEPTION 'CA_0040 post-verify: chair 1 is "%" (expected reworded)', v_txt; END IF;
  SELECT text INTO v_txt FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2_id AND value = 3;
  IF v_txt <> v_c3 THEN RAISE EXCEPTION 'CA_0040 post-verify: chair 3 is "%" (expected reworded)', v_txt; END IF;

  -- Chairs 4 and 5 are byte-identical to the published v1.
  SELECT id INTO v_v1_id
  FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id AND version = 1 AND status IN ('published','superseded')
  ORDER BY revision DESC LIMIT 1;
  IF v_v1_id IS NULL THEN
    RAISE EXCEPTION 'CA_0040 post-verify: no published v1 revision to compare against';
  END IF;

  SELECT count(*) INTO v_diff
  FROM inform.compass_stance_revisions s2
  JOIN inform.compass_stance_revisions s1
    ON s1.topic_revision_id = v_v1_id AND s1.value = s2.value
  WHERE s2.topic_revision_id = v_v2_id
    AND s2.value IN (4,5)
    AND s2.text <> s1.text;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'CA_0040 post-verify: % of chairs 4/5 drifted from v1 (expected 0 — must be byte-identical)', v_diff;
  END IF;

  -- No open draft should remain (the prior draft was rejected; the new revision is approved).
  SELECT count(*) INTO v_open_drafts
  FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id AND status = 'draft';
  IF v_open_drafts <> 0 THEN
    RAISE EXCEPTION 'CA_0040 post-verify: % open draft(s) remain (expected 0)', v_open_drafts;
  END IF;

  -- v1 remains the one current revision (parking must not steal is_current).
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions
    WHERE topic_id = v_topic_id AND version = 1 AND is_current
  ) THEN
    RAISE EXCEPTION 'CA_0040 post-verify: v1 is no longer is_current (parking must leave Season 1 untouched)';
  END IF;

  RAISE NOTICE 'CA_0040 post-verify OK: parked substantive v2 % (approved, is_current=false, chairs 1-3 reworded, 4-5 identical to v1, identity rung_map, no open draft, v1 still current)', v_v2_id;
END $verify$;

COMMIT;
