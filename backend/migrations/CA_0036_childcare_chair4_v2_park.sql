-- CA_0036_childcare_chair4_v2_park.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- =============================================================================
-- CA_0036: Childcare — substantive v2 (option-4 double-barrel split), parked for Season 2
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Advances the existing draft substantive v2 (revision 0e9fe0f2, version 2) of the
--   `childcare` topic to `approved` and PARKS it (unpublished). The v2 splits option
--   4's double-barrel, KEEPING the means-tested-subsidy clause and DROPPING the
--   deregulation clause:
--       OLD (v1)  "Reducing regulations on childcare providers to increase supply and
--                  lower costs, with limited subsidies reserved for the lowest-income
--                  families"
--       NEW (v2)  "Limiting government support to childcare subsidies for the
--                  lowest-income families, relying on the private market for everyone
--                  else"
--   Options 1, 2, 3 and 5 are byte-identical to v1. Identity rung map (no rung moves;
--   option 4 is reworded in place). This migration writes NO change to
--   politician_answers or politician_context, so no answer-delete guard applies.
--
-- WHY SUBSTANTIVE, NOT MINOR (decision 2026-08-30, Chris Andrews)
--   Reviewed against the CA_0028 residential-zoning test (a split is CLARIFYING only
--   if the dropped clause is an off-axis limb no seating depended on). This lands the
--   other way, like CA_0030 religious-freedom. The dropped clause — "reducing
--   regulations on childcare providers" — is LOAD-BEARING: of the 85 answers seated on
--   option 4, twelve rest on a specific deregulation instrument and are not described
--   by the new wording (several state their subsidy view was left untouched):
--       Aaron Márquez (HB4024 licensure exemption), Dean Arp / Donny Lambeth /
--       Erin Paré / Heather H. Rhyne (HB412 "Child Care Regulatory Reforms"),
--       Wren M. Williams (HB744 licensure exemption), Tara A. Durant (SB75/SB76
--       licensure exemptions), Christie New Craig (SB170 licensing exemption),
--       Russell J. Black (loosen staff-to-child ratios), Nancy Mace ("D.C. has
--       overregulated the childcare industry"), Jake Johnson ("cut red tape"),
--       Julie Jackson ("removing regulation... not subsidy expansion").
--   The new option 4 does not describe them. Per CLAUDE.md ("evidence must describe
--   THAT chair"), those seatings become unevidenced under the new wording, so the
--   change bumps `version` and waits for a season change. It does not enter open
--   Season 1 (ADR 0006 sec 2).
--
-- WHY PARKED (approved, NOT published) AND NO SEASON-1 EDITS
--   Unlike CA_0033 (data-centers), whose re-audited rows were wrong under v1 too (bad
--   citations, off-axis opposition) and so were fixed in the live Season-1 set, these
--   twelve are CORRECTLY seated under v1 — v1 option 4 names the deregulation clause.
--   Editing Season 1 would corrupt correct, live data. This is the CA_0030
--   religious-freedom shape: park the revision and defer the honest disposition to a
--   Season-2 CARRY step, applied to the Season-2 answer set at assembly (Season 2 has
--   no answers yet). A parked (approved, unpublished) revision is is_current=false and
--   serves no one; reads resolve through the open season's pin to the latest
--   published/superseded revision of the PINNED version (v1), so Season 1 keeps showing
--   v1r1 untouched.
--
-- WHY NOT PUBLISH NOW (the machinery gate)
--   admin_publish_topic_revision REFUSES any rung map that moves or invalidates a rung
--   (REPOINTING_NOT_IMPLEMENTED). The only publishable map is all-identity, which
--   asserts "every old-option-4 answer belongs at new option 4" — false for the twelve
--   above. Parking at `approved` sidesteps that false assertion entirely.
--
-- WHY NOT PIN SEASON 2 HERE
--   The Season-2 pin waits for assembly, alongside the answer carry + orphan
--   disposition (decision 2026-08-30). Pinning v2 while the twelve are undispositioned
--   would falsely seat them the moment Season 2 opens. Season 2 keeps its v1 pin until
--   the carry runs.
--
-- SEASON-2 CARRY LIST (handled at Season 2 assembly, NOT here)
--   backend/data/season2-carry/childcare-chair4-reaudit.json — all 85 option-4 rows
--   classified (12 axis-orphans, 14 thin/no-primary-instrument, 59 likely-carry).
--   Decision: re-source first, blank if none. Disposition applies to the Season-2
--   answer rows at assembly; Season 1 is not touched.
--
-- Idempotent: re-running after success is a no-op; each lifecycle step is guarded.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'childcare';
  v_rev2     CONSTANT uuid := '0e9fe0f2-cfab-4553-99cd-c3195d08e236';
  v_chair4   CONSTANT text := 'Limiting government support to childcare subsidies for the lowest-income families, relying on the private market for everyone else';
  v_topic_id uuid;
  v_status   text;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0036: topic % not found', v_key;
  END IF;

  -- Idempotency: an approved/published substantive v2 carrying the reworded option 4
  -- already exists? Nothing to do.
  IF EXISTS (
    SELECT 1
    FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s
      ON s.topic_revision_id = r.id AND s.value = 4
    WHERE r.topic_id = v_topic_id
      AND r.change_class = 'substantive'
      AND r.version = 2
      AND r.status IN ('approved', 'published')
      AND s.text = v_chair4
  ) THEN
    RAISE NOTICE 'CA_0036 already applied — substantive v2 is approved/published; skipping.';
    RETURN;
  END IF;

  -- Locate the draft v2 (by id, cross-checked on topic/version/class/option-4 text).
  SELECT r.status INTO v_status
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s
    ON s.topic_revision_id = r.id AND s.value = 4
  WHERE r.id = v_rev2
    AND r.topic_id = v_topic_id
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND s.text = v_chair4;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'CA_0036: expected draft v2 % (substantive, version 2, reworded option 4) not found for %',
      v_rev2, v_key;
  END IF;

  -- Approve if still draft. DO NOT publish — park for Season 2.
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_rev2, v_actor);
  END IF;

  RAISE NOTICE 'CA_0036: approved (parked, unpublished) substantive v2 %', v_rev2;
END $$;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_topic_id  uuid;
  v_v1_id     uuid;
  v_v2_id     CONSTANT uuid := '0e9fe0f2-cfab-4553-99cd-c3195d08e236';
  v_ver       int;
  v_stat      text;
  v_curr      boolean;
  v_rungs     int;
  v_chair4    text;
  v_diff      int;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'childcare';

  -- The parked v2 is substantive version 2, approved (NOT published), is_current=false.
  SELECT version, status::text, is_current
    INTO v_ver, v_stat, v_curr
  FROM inform.compass_topic_revisions
  WHERE id = v_v2_id AND topic_id = v_topic_id;

  IF v_ver IS NULL THEN
    RAISE EXCEPTION 'CA_0036 post-verify: v2 revision % not found', v_v2_id;
  END IF;
  IF v_ver <> 2 THEN
    RAISE EXCEPTION 'CA_0036 post-verify: version is % (expected 2)', v_ver;
  END IF;
  IF v_stat <> 'approved' THEN
    RAISE EXCEPTION 'CA_0036 post-verify: status is % (expected approved — must NOT be published)', v_stat;
  END IF;
  IF v_curr THEN
    RAISE EXCEPTION 'CA_0036 post-verify: v2 is is_current (expected false — a parked revision serves no one)';
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0036 post-verify: v2 has % rungs (expected 5)', v_rungs;
  END IF;

  -- Option 4 carries the reworded (v2) text.
  SELECT text INTO v_chair4 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_v2_id AND value = 4;
  IF v_chair4 <> 'Limiting government support to childcare subsidies for the lowest-income families, relying on the private market for everyone else' THEN
    RAISE EXCEPTION 'CA_0036 post-verify: option 4 is "%" (expected the reworded v2 text)', v_chair4;
  END IF;

  -- Options 1, 2, 3, 5 are byte-identical to the published v1 (revision 1). Compare
  -- against the topic's version-1 current revision rather than hardcoding the strings.
  SELECT id INTO v_v1_id
  FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id AND version = 1 AND status IN ('published','superseded')
  ORDER BY revision DESC LIMIT 1;
  IF v_v1_id IS NULL THEN
    RAISE EXCEPTION 'CA_0036 post-verify: no published v1 revision to compare against';
  END IF;

  SELECT count(*) INTO v_diff
  FROM inform.compass_stance_revisions s2
  JOIN inform.compass_stance_revisions s1
    ON s1.topic_revision_id = v_v1_id AND s1.value = s2.value
  WHERE s2.topic_revision_id = v_v2_id
    AND s2.value IN (1,2,3,5)
    AND s2.text <> s1.text;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'CA_0036 post-verify: % of options 1/2/3/5 drifted from v1 (expected 0)', v_diff;
  END IF;

  RAISE NOTICE 'CA_0036 post-verify OK: parked substantive v2 % (approved, is_current=false, option 4 reworded, 1/2/3/5 unchanged)', v_v2_id;
END $$;

COMMIT;
