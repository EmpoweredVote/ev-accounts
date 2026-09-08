BEGIN;

-- =============================================================================
-- CA_0104: Gun Policy (gun-policy) — reword rung 4 as a CLARIFYING revision
--          (v2 rev 3) and publish it into the OPEN Season 2.
-- =============================================================================
-- Slot CA_0104 reserved via `steward slot CA` before this file existed.
-- Ruling 2026-09-08, Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2),
-- on Chris Cantrell's Senate research memo "Fifty-Three Empty Chairs" (2026-09-05).
--
-- TOPIC 56125933-… ('gun-policy', "Gun Policy"). Question UNCHANGED:
--   "How should the government regulate firearms?"
-- Current revision: rev 2 / version 2 / substantive (1a72d5df-…), published when
-- Season 2 opened on 2026-09-04. Season 2 pins that revision.
--
-- ── THE PROBLEM ──────────────────────────────────────────────────────────────
--
-- The Senate research pass can place all 47 members of the Democratic caucus on
-- this ladder from their own bills (CC_0074 applied two; CC_0078 holds 45 more)
-- and 0 of the 53 Republicans. 47 Republicans cosponsor S. 65, the Constitutional
-- Concealed Carry Reciprocity Act of 2025 (two more sit only on its 2023 text,
-- S. 214). No rung describes what that bill does:
--
--   rung 4  "Keep current gun laws, adding no new restrictions."
--           A status-quo position. Nobody legislates the status quo, so a record
--           of introduced bills can never land here — and a senator cosponsoring
--           a change in the law is not "keeping current gun laws".
--   rung 5  "Repeal major gun restrictions and let adults carry a firearm
--           without a permit."
--           S. 65 repeals no federal restriction. It requires each State to
--           honour the carry law of a visitor's home State — a permit, or the
--           home State's permitless-carry rule — and it does not create
--           permitless carry anywhere. Reading it as rung 5 overstates 47 named
--           sitting senators.
--
-- The honest outcome under the old wording was an absent row for every one of
-- them: a corpus with one caucus seated and the other blank. True against the
-- ladder, and it would still read as a thumb on the scale. The rungs, not the
-- research, had to move.
--
-- ── THE FIX: ONE RUNG, REWORDED ──────────────────────────────────────────────
--
--   rung 4 (old)  Keep current gun laws, adding no new restrictions.
--   rung 4 (new)  Add no new restrictions, and at most loosen rules on carrying,
--                 such as honoring permits across state lines.
--
-- Cantrell's draft ("expand where lawful gun owners may carry, without adding
-- new restrictions") was not taken because it removes the status-quo voter's
-- home. The wording above keeps it: a voter who wants nothing changed reads "add
-- no new restrictions" and sits here; a reciprocity cosponsor's furthest step is
-- also here. Rungs 1, 2, 3 and 5 are byte-identical to rev 2. The 4↔5 line is
-- now clean and exclusive, like the 2↔3 line CA_0095 drew: do the major federal
-- gun laws stay (4) or go (5)?
--
-- ── WHY CLARIFYING, NOT SUBSTANTIVE (the ruling) ─────────────────────────────
--
-- The 2026-08-28 rule says a widened claim is material because the seats'
-- evidence was gathered against a sentence that no longer exists. Measured on
-- prod 2026-09-08, immediately before this file was written:
--
--   politician_answers on gun-policy at rung 4 or 5, any season ....... 0
--   politician_answers on gun-policy at all (both rung 2, CC_0074) ..... 2
--   compass_responses (voter answers) on gun-policy, any season ........ 0
--   seasons that contain the topic ..................................... Season 2 only
--
-- No seated row and no voter answer was evidenced or chosen against the old
-- rung 4, so nothing is mis-seated and there is nothing to re-audit. That is the
-- test CA_0053 / CA_0055 / CA_0059 / CA_0061 applied when they reclassified a
-- reword to minor. The precondition block below re-measures the two zero counts
-- and refuses if either has moved — the classification depends on them.
--
-- Season 2 is OPEN, so its pins are frozen (`admin_season_pin_revision` raises
-- NOT_DRAFT). Under ADR 0006 a season is bound to a VERSION and serves the
-- latest published revision of it, so a clarifying revision (version stays 2)
-- is the only change Season 2 can see; a substantive v3 would wait for a
-- Season 3. The Season 2 pin row keeps pointing at rev 2, and every
-- politician_answers row keeps referencing it (`politician_answers_pin_fkey`
-- needs the pinned id) — the served TEXT comes from version resolution, exactly
-- as taxes (CA_0053) works in Season 1.
--
-- ── WHAT THIS DOES ───────────────────────────────────────────────────────────
--
--   1. PROPOSE a clarifying revision (rev 3 / version 2): rev 2's five rungs,
--      copied, with rung 4's text replaced. rung_map identity.
--   2. APPROVE it.
--   3. PUBLISH it — supersedes rev 2, becomes is_current; Season 2 serves it.
--
-- NO answer or context rows are written or deleted. The follow-on research pass
-- (a `CC_` migration) seats the reciprocity cosponsors at rung 4; its rule is
-- "the instrument proves rung 4 — check the record for a rung-5 instrument
-- first", and it is out of scope here.
--
-- IDEMPOTENT: find-or-create the rev by (version 2, clarifying, rung-4 = new
-- text); approve only from draft; publish only from approved; a second run is a
-- no-op. Model: CA_0053 (clarifying revision published into an open season),
-- without its reject step — there is no substantive draft to reclassify.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';               -- gun-policy
  v_topickey CONSTANT text := 'gun-policy';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (open)
  v_rev2     CONSTANT uuid := '1a72d5df-746f-4469-ab9b-1d3e8bc33b8d';               -- v2 rev 2 (substantive)
  v_stem     CONSTANT text := 'How should the government regulate firearms?';
  v_old4     CONSTANT text := 'Keep current gun laws, adding no new restrictions.';
  v_new4     CONSTANT text := 'Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across state lines.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  jsonb;
  v_new      uuid;
  v_status   text;
  v_n        int;
  v_pub      jsonb;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0104: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0104: Season 2 is not open — this reword was ruled clarifying so that the OPEN season serves it; re-check the ruling if the season state changed';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id = v_season2 AND topic_id = v_topic AND topic_revision_id = v_rev2) THEN
    RAISE EXCEPTION 'CA_0104: Season 2 does not pin v2 rev 2 (%) for gun-policy', v_rev2;
  END IF;

  -- The classification rests on these two zeros. Re-measure; refuse if moved.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id = v_topic AND value IN (4, 5);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0104: % politician answer(s) now sit at rung 4/5 — the clarifying classification assumed none; re-audit them against the new wording before applying', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM inform.compass_responses
   WHERE topic_id = v_topic AND deleted_at IS NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0104: % voter answer(s) exist on gun-policy — the clarifying classification assumed none; decide whether a rung-4 reword changes what they chose', v_n;
  END IF;

  -- Step 1: find-or-create the clarifying revision (rev 3 / v2). Idempotent. ---
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'clarifying'
    AND r.version = 2
    AND r.status IN ('draft', 'approved', 'published')
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 4 AND s.text = v_new4);

  IF v_new IS NULL THEN
    -- The revision we are about to supersede must be the one this file was
    -- written against, still current, still carrying the old rung 4.
    IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                   WHERE id = v_rev2 AND topic_id = v_topic AND revision = 2 AND version = 2
                     AND change_class = 'substantive' AND status = 'published' AND is_current) THEN
      RAISE EXCEPTION 'CA_0104: v2 rev 2 (%) is not the published/current revision', v_rev2;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                   WHERE topic_revision_id = v_rev2 AND value = 4 AND text = v_old4) THEN
      RAISE EXCEPTION 'CA_0104: rev 2 rung 4 is not the expected old text; the ladder moved under this file';
    END IF;
    SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft', 'approved');
    IF v_n <> 0 THEN
      RAISE EXCEPTION 'CA_0104: an unexpected open (draft/approved) revision exists (%); resolve before proposing', v_n;
    END IF;

    -- rev 2's five rungs, copied byte-for-byte, rung 4 text replaced.
    SELECT jsonb_agg(
             jsonb_strip_nulls(jsonb_build_object(
               'value',                s.value,
               'text',                 CASE WHEN s.value = 4 THEN v_new4 ELSE s.text END,
               'description',          s.description,
               'example_perspectives', to_jsonb(s.example_perspectives)))
             ORDER BY s.value)
      INTO v_stances
      FROM inform.compass_stance_revisions s
     WHERE s.topic_revision_id = v_rev2;
    IF v_stances IS NULL OR jsonb_array_length(v_stances) <> 5 THEN
      RAISE EXCEPTION 'CA_0104: expected 5 stances on rev 2, built %', COALESCE(jsonb_array_length(v_stances), 0);
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'clarifying',
      'Gun Policy', 'Gun Policy',
      v_stem, v_stances,
      -- rationale
      'Ruling 2026-09-08 (Chris Andrews) on the Senate research memo "Fifty-Three Empty Chairs" (Chris Cantrell, '
      || '2026-09-05). Rung 4 "Keep current gun laws, adding no new restrictions" was a status-quo position no bill '
      || 'can evidence, and rung 5 ("repeal major restrictions AND permitless carry") overstates the 47 senators who '
      || 'cosponsor S. 65, the Constitutional Concealed Carry Reciprocity Act of 2025 — it repeals no federal '
      || 'restriction and creates no permitless carry; it makes each State honour a visitor''s home-State carry law. '
      || 'The result was a ladder that seated all 47 of one caucus and 0 of 53 of the other. Rung 4 is reworded to '
      || 'keep the status-quo voter''s home ("add no new restrictions") and admit the modest-loosening position ("at '
      || 'most loosen rules on carrying, such as honoring permits across state lines"). The 4-vs-5 line is now '
      || 'whether the major federal gun laws stay. Rungs 1, 2, 3 and 5 unchanged. CLASSIFIED CLARIFYING: measured '
      || '2026-09-08, 0 politician answers at rung 4 or 5 in any season, 2 answers on the topic at all (both rung 2, '
      || 'CC_0074), 0 voter answers on the topic, and the topic is in Season 2 only — no seated row or voter choice '
      || 'was made against the old rung 4, so there is nothing to re-audit (precedent CA_0053/0055/0059/0061). '
      || 'Season 2 is open, so a clarifying revision is the only path by which it can serve new wording. rung_map '
      || 'identity. Applied by CA_0104.',
      -- public_note
      'Reworded one option so it describes a position people actually hold: "add no new restrictions, and at most '
      || 'loosen rules on carrying, such as honoring permits across state lines." It replaces "keep current gun laws, '
      || 'adding no new restrictions." The other four options are unchanged.',
      -- review_ref
      'Gun Policy rung-4 wording ruling 2026-09-08 (Chris Andrews); Cantrell memo "Fifty-Three Empty Chairs", Senate cohort, 2026-09-05.',
      v_rungmap);
    RAISE NOTICE 'CA_0104: proposed clarifying revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0104: clarifying revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved). Idempotent. ---------------------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0104: clarifying revision approved.';
    v_status := 'approved';
  END IF;

  -- Step 3: publish (approved -> published, supersedes rev 2). Idempotent. -----
  IF v_status = 'approved' THEN
    v_pub := inform.admin_publish_topic_revision(v_new, v_actor);
    IF (v_pub ->> 'published_version')::int <> 2 THEN
      RAISE EXCEPTION 'CA_0104: publish reported version % — a clarifying revision must keep version 2', v_pub ->> 'published_version';
    END IF;
    RAISE NOTICE 'CA_0104: published % (%)', v_new, v_pub::text;
  ELSIF v_status = 'published' THEN
    RAISE NOTICE 'CA_0104: clarifying revision already published; nothing to do.';
  ELSE
    RAISE EXCEPTION 'CA_0104: clarifying revision in unexpected status % (expected draft, approved or published)', v_status;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev2     CONSTANT uuid := '1a72d5df-746f-4469-ab9b-1d3e8bc33b8d';
  v_new4     CONSTANT text := 'Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across state lines.';
  v_cur      uuid;
  v_ver      int;
  v_rev      int;
  v_class    inform.change_class;
  v_n        int;
  v_eff      uuid;
BEGIN
  -- Exactly one published + current revision, and it is clarifying v2 rev 3.
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0104 verify: expected exactly 1 published/current revision, found %', v_n;
  END IF;
  SELECT id, version, revision, change_class INTO v_cur, v_ver, v_rev, v_class
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published';
  IF v_ver <> 2 THEN
    RAISE EXCEPTION 'CA_0104 verify: current revision must be version 2, is %', v_ver;
  END IF;
  IF v_class <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0104 verify: current revision must be clarifying, is %', v_class;
  END IF;
  IF v_rev <> 3 THEN
    RAISE EXCEPTION 'CA_0104 verify: current revision must be rev 3, is %', v_rev;
  END IF;

  -- rev 2 superseded, no longer current; no open draft/approved left behind.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev2 AND status = 'superseded' AND NOT is_current) THEN
    RAISE EXCEPTION 'CA_0104 verify: v2 rev 2 (%) is not superseded', v_rev2;
  END IF;
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND status IN ('draft', 'approved');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0104 verify: % open draft/approved revision(s) remain', v_n;
  END IF;

  -- Five rungs: rung 4 is the new text, rungs 1/2/3/5 byte-identical to rev 2.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_cur;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0104 verify: expected 5 stances, found %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_cur AND value = 4 AND text = v_new4) THEN
    RAISE EXCEPTION 'CA_0104 verify: rung 4 does not carry the ruled wording';
  END IF;
  SELECT count(*) INTO v_n
    FROM inform.compass_stance_revisions n
    JOIN inform.compass_stance_revisions o
      ON o.topic_revision_id = v_rev2 AND o.value = n.value AND o.text = n.text
   WHERE n.topic_revision_id = v_cur AND n.value IN (1, 2, 3, 5);
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CA_0104 verify: rungs 1/2/3/5 must match rev 2 byte-for-byte; % of 4 match', v_n;
  END IF;

  -- Season 2 still pins rev 2 (pins are frozen) and, resolved by version as the
  -- read path does (ADR 0006), serves the new revision.
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id = v_season2 AND topic_id = v_topic AND topic_revision_id = v_rev2) THEN
    RAISE EXCEPTION 'CA_0104 verify: the Season 2 pin moved — it must still be rev 2 (%)', v_rev2;
  END IF;
  SELECT e.id INTO v_eff
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
    JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
    JOIN inform.compass_topic_revisions e
      ON e.topic_id = pin.topic_id AND e.version = pin.version
     AND e.status IN ('published', 'superseded')
   WHERE sq.topic_id = v_topic
   ORDER BY e.revision DESC
   LIMIT 1;
  IF v_eff IS DISTINCT FROM v_cur THEN
    RAISE EXCEPTION 'CA_0104 verify: open season resolves to % but current is %', v_eff, v_cur;
  END IF;

  -- No answer row was touched: still none at rung 4/5, and the existing answers
  -- still reference the pinned revision.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id = v_topic AND value IN (4, 5);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0104 verify: % answer(s) at rung 4/5 — this file writes no answers', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id = v_topic AND season_id = v_season2 AND topic_revision_id <> v_rev2;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0104 verify: % Season 2 answer(s) reference a revision other than the pin', v_n;
  END IF;

  RAISE NOTICE 'CA_0104 verify OK: gun-policy now clarifying v2 rev 3 (%), published/current; Season 2 serves the reworded rung 4.', v_cur;
END $$;

COMMIT;
