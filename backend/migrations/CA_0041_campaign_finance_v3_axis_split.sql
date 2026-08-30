-- CA_0041_campaign_finance_v3_axis_split.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- =============================================================================
-- CA_0041: Campaign Finance — substantive rev3 (single-axis rewrite), parked for Season 2 + S2 repin
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   1. Rejects the open draft rev2 (id 9c492693-7952-4578-8cc7-d7a884624006). rev2 only
--      de-double-barreled option 1 ("...ban all private money in politics AND publicly fund
--      campaigns" -> "ban all private money in political campaigns"); it left the deeper axis
--      defect untouched. One open revision per topic, so it is rejected before rev3 is proposed.
--   2. Proposes rev3 (substantive, version 2, identity rung map), a single-axis rebuild:
--        1  Ban all private money in political campaigns                 (unchanged meaning; rev2 wording)
--        2  Strictly limit corporate and dark-money spending             (reworded; same "tighten limits" posture)
--        3  Keep contribution limits at current levels                   (MEANING CHANGED — was "require full disclosure...")
--        4  Reduce restrictions on political donations and spending      (unchanged)
--        5  Eliminate all campaign finance laws and limits               (unchanged)
--   3. Approves rev3 and PARKS it (approved, NOT published).
--   4. Repins Season 2 (86d893a1-c1a2-4bbf-b4e5-69ec43221194) question 3 from rev1
--      (58ebaab3-0849-446a-82f9-162f084e93e3) to the approved rev3.
--   Writes NO change to politician_answers / politician_context (no answer-delete guard applies).
--
-- THE AXIS FIX (why rev3, not just rev2)
--   Options 1/2/4/5 vary along ONE axis: how much government limits private money in campaigns
--   (ban -> strict limits -> ... -> loosen -> none). The old option 3, "require full disclosure of
--   all political donations", measured a DIFFERENT lever — transparency. A voter can want full
--   disclosure AND fewer donation limits at the same time; the two do not trade off, so disclosure
--   was not a step on the limits ladder. rev3 replaces option 3 with the status-quo limits position
--   ("keep contribution limits at current levels"), making all five rungs one monotonic axis.
--
-- WHY SUBSTANTIVE (decision 2026-08-30, Chris Andrews)
--   Option 3 changes MEANING (disclosure -> keep current limits). Of the 99 answers seated on the
--   old option 3, 96 rest on disclosure/transparency evidence and are NOT described by the new
--   wording (per CLAUDE.md: "evidence must describe THAT chair"). Those seatings become unevidenced
--   under the new option 3, so the change bumps `version` and waits for a season change. Options
--   1/4/5 keep their meaning; option 2 is reworded to the same "tighten limits" posture and sharpened
--   to sit clearly above the status-quo option 3.
--
-- DISCLOSURE IS BEING SPLIT OUT (topic HELD, not created here)
--   The 96 disclosure seatings are well-sourced (69 name a primary instrument) — they are correct
--   transparency positions on the wrong axis. The plan is to SPLIT: a new "Campaign Transparency"
--   topic (topic_key campaign-transparency) on the disclosure axis re-homes those 96 at its rung 2
--   ("require full disclosure of all donations above a small threshold"), so no evidence is thrown
--   away. That topic is NOT created in this migration and is NOT pinned to Season 2 yet (author not
--   ready, decision 2026-08-30). Its design + the row-level mapping live in the carry file below.
--
-- WHY PARK (approved, NOT published) AND NO SEASON-1 EDITS
--   The rung map is identity, so admin_publish_topic_revision would MACHINE-accept it — but an
--   identity publish asserts "every old-option-3 answer belongs at new option 3", which is false for
--   the 96. Parking at `approved` sidesteps that false assertion (the CA_0036 childcare shape).
--   Under v1 (open Season 1) option 3 names disclosure, so the 96 are CORRECTLY seated live; editing
--   Season 1 would corrupt correct data. Season 1 keeps showing v1r1 (rev3 is is_current=false and
--   serves no one until its season pin publishes it).
--
-- 🔴 SEASON-2 OPEN IS BLOCKED ON THE CAMPAIGN-FINANCE CARRY (read before opening Season 2)
--   This migration repins Season 2 q3 to rev3 at the author's request. The pin is INERT until
--   Season 2 opens. But opening Season 2 with rev3 pinned and the carry NOT run would seat all 96
--   disclosure answers at "keep current limits" — false. So the carry below is a HARD prerequisite of
--   opening Season 2: re-home the 96 to Campaign Transparency rung 2 (or blank), keep the ~3
--   genuine current-limits rows at option 3. (childcare CA_0036 avoided this by not pinning; here the
--   pin is done but the same disposition-before-open rule applies.)
--
-- SEASON-2 CARRY LIST (handled at Season 2 assembly, NOT here)
--   backend/data/season2-carry/campaign-finance-chair3-reaudit.json — all 99 option-3 rows
--   classified (96 disclosure axis-orphans -> re-home to campaign-transparency rung 2; ~3 keep-
--   current-limits -> stay at option 3; remainder -> blank if no primary instrument). Decision:
--   re-source/re-home first, blank if none. Applies to the Season-2 answer rows at assembly;
--   Season 1 is not touched.
--
-- Stances are stored capitalized to match the current house convention (childcare v2, 2020-election,
-- border-security); the read boundary capitalizes the first letter regardless.
--
-- Idempotent: re-running after success is a no-op; each step is guarded on the rev3 option-3 text.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='92730f69-ae57-401c-8ad1-2d07834a895d' AND topic_key='campaign-finance') THEN
    RAISE EXCEPTION 'CA_0041 precondition: campaign-finance topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND number=2 AND status='draft') THEN
    RAISE EXCEPTION 'CA_0041 precondition: Season 2 is not a draft (repin would be frozen)';
  END IF;
END $$;

-- ── 1. Lifecycle: reject rev2 → propose rev3 → approve (park) → repin Season 2 ────────────────────
DO $$
DECLARE
  v_actor      CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key        CONSTANT text := 'campaign-finance';
  v_s2         CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev2       CONSTANT uuid := '9c492693-7952-4578-8cc7-d7a884624006';
  v_rung3_new  CONSTANT text := 'Keep contribution limits at current levels';
  v_topic      uuid;
  v_draft_id   uuid;
  v_rev3       uuid;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = v_key;

  IF EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
    WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
      AND r.status IN ('approved','published') AND s.text = v_rung3_new
  ) THEN
    RAISE NOTICE 'CA_0041: approved substantive rev3 already present — skipping reject/propose/approve.';
  ELSE
    -- Reject the single open draft (must be rev2).
    SELECT id INTO v_draft_id FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status = 'draft';
    IF v_draft_id IS NOT NULL THEN
      IF v_draft_id <> v_rev2 THEN
        RAISE EXCEPTION 'CA_0041: unexpected open draft % (expected rev2 %)', v_draft_id, v_rev2;
      END IF;
      PERFORM inform.admin_reject_topic_revision(
        v_rev2, v_actor,
        'Superseded by rev3. rev2 only de-double-barreled option 1; rev3 fixes the axis — old option 3 (require full disclosure) measured transparency, not a limit, so it is replaced by the status-quo limits position and disclosure is split to its own topic.');
    END IF;

    -- Propose rev3: single limits axis; identity rung map (rungs stay 1..5, option 3 reworded in place).
    v_rev3 := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      'Campaign Finance Reform', 'Campaign Finance',
      'What rules should govern money in political campaigns and elections?',
      $stances$[
        {"value":1,"text":"Ban all private money in political campaigns"},
        {"value":2,"text":"Strictly limit corporate and dark-money spending"},
        {"value":3,"text":"Keep contribution limits at current levels"},
        {"value":4,"text":"Reduce restrictions on political donations and spending"},
        {"value":5,"text":"Eliminate all campaign finance laws and limits"}
      ]$stances$::jsonb,
      $rat$Single-axis rebuild of the campaign-finance ladder. All five rungs now measure one lever — how much government limits private money in campaigns (1 = replace it, 5 = no limits). The prior option 3 ("require full disclosure of all political donations") measured transparency, a lever orthogonal to the limit axis (a voter can want full disclosure AND fewer donation limits at once), so it did not belong as a step on this ladder. rev3 replaces it with the status-quo limits position ("keep contribution limits at current levels") and sharpens option 2 so it sits clearly above the status quo. Options 1/4/5 keep their meaning; option 1 keeps the rev2 de-double-barrel. Disclosure is being split into a separate "Campaign Transparency" topic (held, not yet created); the 96 disclosure seatings re-home there at assembly. Identity rung map: rungs stay 1..5; only option 3 changes meaning, so only its seated answers are re-audited (carry file). Substantive because option 3's meaning change re-seats.$rat$,
      $pub$Rebuilt the scale so all five options measure one thing — how much to limit private money in campaigns. The old middle option ("require full disclosure of donations") measured transparency, which is a separate question, so it was removed from this limits scale.$pub$,
      'compass-topic-builder review 2026-08-30 (campaign-finance axis split); carry: backend/data/season2-carry/campaign-finance-chair3-reaudit.json',
      '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
    );

    PERFORM inform.admin_approve_topic_revision(v_rev3, v_actor);  -- approve, NOT publish (park for Season 2)
    RAISE NOTICE 'CA_0041: proposed + approved (parked) substantive rev3 %', v_rev3;
  END IF;

  -- Repin Season 2 question 3 from rev1 to the approved rev3 (idempotent; inert until Season 2 opens).
  SELECT r.id INTO v_rev3 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
   WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
     AND r.status IN ('approved','published') AND s.text = v_rung3_new
   ORDER BY r.revision DESC LIMIT 1;
  IF v_rev3 IS NULL THEN
    RAISE EXCEPTION 'CA_0041: could not locate the approved rev3 to pin';
  END IF;
  PERFORM inform.admin_season_pin_revision(v_s2, v_topic, v_rev3, v_actor);
  RAISE NOTICE 'CA_0041: Season 2 q3 pinned to rev3 %', v_rev3;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic   CONSTANT uuid := '92730f69-ae57-401c-8ad1-2d07834a895d';
  v_s2      CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1    CONSTANT uuid := '58ebaab3-0849-446a-82f9-162f084e93e3';
  v_rev2    CONSTANT uuid := '9c492693-7952-4578-8cc7-d7a884624006';
  v_rev3    uuid;
  v_ver     int;
  v_stat    text;
  v_curr    boolean;
  v_rungs   int;
  v_txt     text;
  v_pin     uuid;
  v_rev2st  text;
  v_curr1   boolean;
BEGIN
  -- Locate rev3 by its option-3 text (the approved substantive rebuild).
  SELECT r.id, r.version, r.status::text, r.is_current
    INTO v_rev3, v_ver, v_stat, v_curr
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
  WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
    AND s.text = 'Keep contribution limits at current levels'
  ORDER BY r.revision DESC LIMIT 1;

  IF v_rev3 IS NULL THEN RAISE EXCEPTION 'CA_0041 verify: rev3 not found'; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0041 verify: rev3 version is % (expected 2)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0041 verify: rev3 status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0041 verify: rev3 is is_current (expected false — parked serves no one)'; END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev3;
  IF v_rungs <> 5 THEN RAISE EXCEPTION 'CA_0041 verify: rev3 has % rungs (expected 5)', v_rungs; END IF;

  -- Options 1/4/5 keep their v1 text (meaning unchanged).
  SELECT text INTO v_txt FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev3 AND value = 1;
  IF v_txt <> 'Ban all private money in political campaigns' THEN RAISE EXCEPTION 'CA_0041 verify: option 1 is "%"', v_txt; END IF;
  SELECT text INTO v_txt FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev3 AND value = 4;
  IF v_txt <> 'Reduce restrictions on political donations and spending' THEN RAISE EXCEPTION 'CA_0041 verify: option 4 is "%"', v_txt; END IF;
  SELECT text INTO v_txt FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev3 AND value = 5;
  IF v_txt <> 'Eliminate all campaign finance laws and limits' THEN RAISE EXCEPTION 'CA_0041 verify: option 5 is "%"', v_txt; END IF;

  -- rev2 is rejected; rev1 is still the current revision (Season 1 unaffected).
  SELECT status::text INTO v_rev2st FROM inform.compass_topic_revisions WHERE id = v_rev2;
  IF v_rev2st <> 'rejected' THEN RAISE EXCEPTION 'CA_0041 verify: rev2 status is % (expected rejected)', v_rev2st; END IF;
  SELECT is_current INTO v_curr1 FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_curr1 THEN RAISE EXCEPTION 'CA_0041 verify: rev1 is no longer is_current (Season 1 would drift)'; END IF;

  -- Season 2 q3 pinned to rev3; Season 1 (open) still pinned to rev1.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s2 AND topic_id = v_topic;
  IF v_pin <> v_rev3 THEN RAISE EXCEPTION 'CA_0041 verify: Season 2 pin is % (expected rev3 %)', v_pin, v_rev3; END IF;
  SELECT sq.topic_revision_id INTO v_pin
    FROM inform.season_questions sq JOIN inform.seasons s ON s.id = sq.season_id
   WHERE s.status = 'open' AND sq.topic_id = v_topic;
  IF v_pin <> v_rev1 THEN RAISE EXCEPTION 'CA_0041 verify: open-season pin is % (expected rev1 %)', v_pin, v_rev1; END IF;

  RAISE NOTICE 'CA_0041 post-verify OK: rev3 % approved/parked (v2, is_current=false), rev2 rejected, S2 q3 -> rev3, S1 -> rev1.', v_rev3;
END $$;

COMMIT;
