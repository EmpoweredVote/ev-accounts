-- CA_0043 — Housing (topic_key 'housing'): five-chair v2 reshuffle for Season 2
-- ============================================================================
-- Supersedes the parked rev 2 (proposed 2026-08-28), which fixed only chair 2's
-- double-barrel. This rewrite reshapes the whole ladder into five MUTUALLY
-- EXCLUSIVE chairs, ordered by how far government should go on housing, and adds
-- the "public option" chair that v1 lacked.
--
-- Axis (single, sharpened so each chair excludes its neighbours):
--   1  Main provider     — build & operate public housing; guarantee everyone a home.
--   2  Public option NEW — a large public housing sector that competes with the
--                          private market, while private housing stays the norm.
--   3  Regulate only     — build nothing, but bind the private market (rent caps
--                          or required affordable units).
--   4  Incentivize       — no mandates, but subsidies / tax breaks to get more built.
--   5  Market only        — leave prices & supply to the market; at most deregulate.
--
-- Why this is SUBSTANTIVE (major), not editorial:
--   * A new chair (2) is inserted, so the value axis re-indexes.
--   * Two double-barrels are removed, changing what a seated chair asserts:
--       - old chair 2 sheds "publicly fund new housing" (off-axis for a
--         regulate-the-market chair; funding belongs with provision/incentives);
--       - old chair 3 sheds "easier building permits" (deregulation — now folded
--         into chair 5).
--   * old chair 4 (deregulate) + old chair 5 (stay out) merge into new chair 5.
--     old chair 5 seated only 14 — a near-empty pole, per DESIGN PRINCIPLE 4.
--
-- rung_map (keys = OLD rungs, values = NEW rung; ADR 0004 §4):
--   {"1":1, "2":3, "3":4, "4":5, "5":5}
--   new chair 2 has NO old source and opens empty — it is populated only by the
--   re-audit, never by a mechanical carry.
--
-- 🔴 RE-AUDIT DEBT — a SEPARATE staged pass, BEFORE Season 2 opens. The rung_map
-- is a mechanical carry, not a verdict. Measured 2026-08-30 against live reasoning:
--   * old chair 2 (757) -> new 3:  ~133 cite a binding rule (carry/spot-check),
--       ~314 funding-only (RE-HOME to new 2/4/1), ~309 generic (BLANK candidates).
--   * old chair 3 (672) -> new 4:  ~79 deregulation-only (MOVE to new 5); the rest
--       carry; ~67 keyword-opaque (manual read).
--   * old chair 1 (113) -> new 1:  ~18 public-option candidates (MOVE to new 2);
--       87 keyword-opaque (manual read).
--   * old chairs 4+5 (243) -> new 5: stable carry.
--   Run `node scripts/audit-chair-evidence.mjs` on every re-audit migration.
--
-- Staging: this migration PROPOSES + APPROVES the revision only. It does NOT
-- publish and does NOT pin to a season. Season 1 keeps serving rev 1 (published,
-- is_current). Pin to Season 2 in a later migration, after the re-audit.
--
-- review_ref: combined five-chair v2, session 2026-08-30. Supersedes the NC wave
-- 2b chair-2-only fix (artifact 6b0a08de-90cf-4a39-bc67-29eca92b5c21).
--
-- Idempotent: reject is guarded on the old draft's id+status; propose+approve is
-- guarded on the new chair-2 text already existing in a non-rejected revision.
-- Dry-run BEGIN; ... ROLLBACK; against prod before applying.
-- ============================================================================

DO $$
DECLARE
  v_topic_id  CONSTANT uuid := '669cac97-66a6-4087-b036-936fbe62efb3';  -- 'housing'
  v_old_draft CONSTANT uuid := 'd3858cd1-8386-45a6-bf3e-bf252c9c651b';  -- parked rev 2
  v_actor     CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';  -- chrisandrewsedu
                              -- approved_by/approved_at are paired by a CHECK; a
                              -- NULL actor on approve/reject would violate it.
  v_stances   CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text',
      'Make government the main provider — build and operate public housing so everyone is guaranteed a home.'),
    jsonb_build_object('value', 2, 'text',
      'Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm.'),
    jsonb_build_object('value', 3, 'text',
      'Build no public housing, but set binding rules on the private market like rent caps or required affordable units.'),
    jsonb_build_object('value', 4, 'text',
      'Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets built.'),
    jsonb_build_object('value', 5, 'text',
      'Rely on the market to set prices and supply — at most, cut the regulations and zoning limits that block private building.')
  );
  v_rung_map  CONSTANT jsonb := '{"1":1,"2":3,"3":4,"4":5,"5":5}'::jsonb;
  v_rationale CONSTANT text :=
    'Five-chair v2 reshuffle for Season 2 (CA_0043). Supersedes the parked rev 2 (chair-2-only fix). '
    'Mutually-exclusive chairs by how far government should go: (1) main provider / universal public housing; '
    '(2) NEW public option — large public sector competing with the market, market stays the norm; '
    '(3) build nothing, binding market rules; (4) no mandates, subsidies/tax breaks; (5) market-only, at most deregulate. '
    'Re-index via rung_map {"1":1,"2":3,"3":4,"4":5,"5":5}; new chair 2 opens empty. '
    'Removed two double-barrels (old ch2 "publicly fund", old ch3 "easier permits"); merged old ch4+ch5 into new ch5. '
    'RE-AUDIT (separate pass, before S2 opens): old ch2 757 -> ~133 carry / ~314 re-home / ~309 blank; '
    'old ch3 672 -> ~79 move to 5 / rest carry; old ch1 113 -> ~18 to new 2 / 87 manual. Not published, not pinned.';
  v_public_note CONSTANT text :=
    'Reworked the five options so each is one clear, distinct approach to housing — from building public housing for '
    'everyone, to a public housing option alongside the market, to regulating the private market, to funding incentives, '
    'to leaving it to the market. Added the public-option choice, which was missing, and stopped bundling several '
    'policies into one option.';
  v_review_ref CONSTANT text :=
    'Combined five-chair v2, session 2026-08-30; supersedes NC wave 2b chair-2-only fix '
    '(https://claude.ai/code/artifact/6b0a08de-90cf-4a39-bc67-29eca92b5c21).';
  v_new_id  uuid;
BEGIN
  -- (1) Reject the parked rev 2 so the topic has one open revision. Guarded so a
  --     re-run (or a colleague's prior reject) is a no-op.
  IF EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions
    WHERE id = v_old_draft AND status IN ('draft','approved')
  ) THEN
    PERFORM inform.admin_reject_topic_revision(
      v_old_draft, v_actor,
      'Superseded by CA_0043 combined five-chair v2 — public-option chair added, ladder re-indexed.');
    RAISE NOTICE 'CA_0043: rejected parked rev 2 (%).', v_old_draft;
  ELSE
    RAISE NOTICE 'CA_0043: parked rev 2 not open — reject skipped.';
  END IF;

  -- (2) Propose + approve the new revision. Guarded on the new chair-2 text
  --     already living in a non-rejected revision, which makes the pair idempotent.
  IF NOT EXISTS (
    SELECT 1
    FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id
    WHERE r.topic_id = v_topic_id
      AND r.status IN ('draft','approved')
      AND s.value = 2
      AND s.text = (v_stances -> 1 ->> 'text')
  ) THEN
    v_new_id := inform.admin_propose_topic_revision(
      'housing', v_actor, 'substantive',
      'Affordable Housing', 'Housing',
      'What role should government play in making sure people can afford housing?',
      v_stances, v_rationale, v_public_note, v_review_ref, v_rung_map);
    PERFORM inform.admin_approve_topic_revision(v_new_id, v_actor);
    RAISE NOTICE 'CA_0043: proposed + approved new revision % (not published, not pinned).', v_new_id;
  ELSE
    RAISE NOTICE 'CA_0043: new five-chair revision already present — propose/approve skipped.';
  END IF;
END $$;

-- ============================================================================
-- Post-verify gate — RAISE on any wrong count.
-- ============================================================================
DO $$
DECLARE
  v_topic_id  CONSTANT uuid := '669cac97-66a6-4087-b036-936fbe62efb3';
  v_old_draft CONSTANT uuid := 'd3858cd1-8386-45a6-bf3e-bf252c9c651b';
  v_ch2_text  CONSTANT text :=
    'Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm.';
  v_n         int;
  v_rev_id    uuid;
BEGIN
  -- (a) Season 1 still served by exactly one published + current v1 (rung_map NULL).
  SELECT count(*) INTO v_n
  FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id AND status = 'published' AND is_current
    AND revision = 1 AND version = 1 AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0043: expected exactly 1 published/current v1 (rung_map NULL), got %', v_n;
  END IF;

  -- (b) The parked rev 2 is rejected.
  SELECT count(*) INTO v_n
  FROM inform.compass_topic_revisions
  WHERE id = v_old_draft AND status = 'rejected';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0043: expected parked rev 2 to be rejected, got % row(s)', v_n;
  END IF;

  -- (c) Exactly one APPROVED revision, version 2, not current, our rung_map,
  --     identified by the new chair-2 text.
  SELECT r.id INTO v_rev_id
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id
  WHERE r.topic_id = v_topic_id AND r.status = 'approved'
    AND s.value = 2 AND s.text = v_ch2_text;
  IF v_rev_id IS NULL THEN
    RAISE EXCEPTION 'CA_0043: no approved revision carrying the new chair-2 text';
  END IF;

  SELECT count(*) INTO v_n
  FROM inform.compass_topic_revisions
  WHERE id = v_rev_id AND status = 'approved' AND is_current = false
    AND version = 2 AND published_at IS NULL
    AND rung_map = '{"1":1,"2":3,"3":4,"4":5,"5":5}'::jsonb;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0043: approved revision failed shape check (version/current/rung_map/published_at)';
  END IF;

  -- (d) It carries exactly 5 stance revisions, values 1..5 distinct.
  SELECT count(DISTINCT value) INTO v_n
  FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev_id;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0043: approved revision must have 5 distinct rung values, got %', v_n;
  END IF;

  -- (e) Only ONE open (draft/approved) revision remains — no stray drafts.
  SELECT count(*) INTO v_n
  FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id AND status IN ('draft','approved');
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0043: expected exactly 1 open revision (the approved v2), got %', v_n;
  END IF;

  RAISE NOTICE 'CA_0043 OK — v2 five-chair revision % approved (not published, not pinned); rev 2 rejected; rev 1 still current.', v_rev_id;
END $$;
