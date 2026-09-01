BEGIN;

-- =============================================================================
-- CA_0095: Gun Policy (gun-policy) — re-axis the founding ladder onto
--          mutually-exclusive chairs, approve the new revision, and repin
--          Season 2 (a DRAFT; NOT open) from v1 to it.
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- 🔴 SLOT HISTORY: applied to prod 2026-08-31 as CA_0089, renumbered to CA_0095
-- the same day (shared-checkout collision; military_intervention held CA_0089).
-- The v2 rationale + review_ref written here (and now stored on prod) refer to the
-- founding create as "CA_0087" — its slot at apply time; that create file is now
-- CA_0093. The prose numbers in prod are historical and non-load-bearing; the
-- topic_key 'gun-policy' is the stable key.
--
-- TOPIC 56125933-… ('gun-policy', "Gun Policy"). Scope federal + state + local.
--   Season-2 question. Brand-new topic (CA_0093/CA_0094, same session): ZERO
--   seated answers. Reviewed with Chris immediately after creation, before it
--   ever went public.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (rev 2 / version 2): question UNCHANGED,
--      five re-axed chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, 61a3920e-…) to the new
--      revision. The topic is in no other season.
--
-- WHY THE RE-AXIS (review with Chris, 2026-08-31):
--   The founding v1 rungs were CUMULATIVE, not mutually exclusive. Gun measures
--   nest — a voter who wants to ban assault weapons almost always also wants
--   universal background checks — so with the measures listed as separate rungs,
--   one person sat in several chairs at once. Chair 1 was also too weak a pole
--   (an assault-weapons ban, not the true restrictive endpoint).
--
--   FIX — the abortion-ladder model: each rung is a distinct LINE ("the furthest
--   you would go"), and the voter sits at exactly one, understood to accept the
--   lesser measures below it. Value 1 is pushed out to the near-total-ban pole.
--   Each rung names the line that separates it from its neighbour:
--       1  no general civilian ownership (only licensed hunting/sport)
--       2  general ownership kept, but the most-lethal CLASS is banned
--       3  ALL types allowed, but every buyer is screened (ban nothing)
--       4  no new restrictions on top of current law
--       5  roll current restrictions back (permitless carry)
--   The 2-vs-3 boundary is the one the exclusivity worry turned on: a voter who
--   wants universal checks AND an assault-weapons ban wants more than rung 3
--   allows ("allow ALL types"), so their line is rung 2. Rung 3 seats only those
--   whose furthest step is screening buyers with no gun banned.
--
--   NO STRAWMAN POLES, ONE HONEST CAVEAT. Pole 5 (permitless carry) is law in 29
--   states. Pole 1 (near-total civilian ban, UK/Australia model — only tightly
--   licensed hunting/sport long guns) is real in the abstract and anchors the
--   endpoint, but has THIN occupancy among U.S. officeholders (most stop at rung
--   2). Accepted as the definitional pole in review.
--
--   SINGLE LEVER PER RUNG. Where a rung carries a second clause it is a BOUNDARY
--   that makes the chair exclusive, not an independent position: rung 1's "except
--   tightly licensed hunting and sport" carve-out, rung 2's "while allowing other
--   firearms", rung 3's "allow all types". Waiting periods were deliberately NOT
--   given a rung — a lesser measure that sits below rung 3's universal-checks line.
--
--   GROUNDING (2026-08-31): 1 near-total ban (definitional pole, thin US seats);
--   2 Assault Weapons Ban of 2025 (S.1531 / H.R.3115, Schiff / McBath); 3 "checks
--   not bans" — Rep. Brian Fitzpatrick (R-PA), an H.R.18 cosponsor who opposes the
--   AWB; 4 status-quo GOP hold; 5 Concealed Carry Reciprocity (H.R.38, Hudson) +
--   permitless carry in 29 states.
--
-- CLASS: substantive -> version 2. rung_map identity {"1":1,"2":2,"3":3,"4":4,"5":5}
--   (five chairs stay in their value slots; only the wording/axis changes). The
--   topic has ZERO seatings, so there is NO re-audit debt — the identity map is a
--   formality and nothing carries. A stance-research pass still must seat real
--   officials on the v2 ladder before Season 2 opens, or the topic launches blank.
--
-- Season 1 is untouched (the topic is not in it). is_current/published stay on v1
-- until Season 2 opens (admin_open_season), which publishes the pinned v2.
--
-- IDEMPOTENT: find-or-create the v2 revision by (version 2, substantive, chair-1
-- text); approve only from draft; pin only if not already pinned to v2. Model:
-- CA_0074 (same-sex-marriage substantive v2 approve + Season-2 pin).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';               -- gun-policy
  v_topickey CONSTANT text := 'gun-policy';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := '61a3920e-bdd9-479a-b5b3-237984401f0e';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'How should the government regulate firearms?';
  v_chair1   CONSTANT text := 'Ban civilian firearm ownership, except for tightly licensed hunting and sport use.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Ban civilian firearm ownership, except for tightly licensed hunting and sport use.'),
    jsonb_build_object('value',2,'text','Ban semi-automatic assault-style weapons, while allowing other firearms.'),
    jsonb_build_object('value',3,'text','Allow all types of firearms, but require universal background checks on every sale.'),
    jsonb_build_object('value',4,'text','Keep current gun laws, adding no new restrictions.'),
    jsonb_build_object('value',5,'text','Repeal major gun restrictions and let adults carry a firearm without a permit.')
  );
  v_new      uuid;
  v_open     int;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0095: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1) THEN
    RAISE EXCEPTION 'CA_0095: expected v1 (rev 1) not found';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0095: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the re-axis revision (rev 2 / v2). Idempotent. --------
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN
    SELECT count(*) INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open <> 0 THEN
      RAISE EXCEPTION 'CA_0095: an unexpected open (draft/approved) revision exists (%); resolve before proposing', v_open;
    END IF;
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Gun Policy', 'Gun Policy',
      v_stem, v_stances,
      -- rationale
      'Re-axis in review 2026-08-31 (Chris Andrews), same session as the CA_0093 founding create, before the '
      || 'topic went public. The founding v1 rungs were cumulative, not mutually exclusive — gun measures nest, '
      || 'so a voter who bans assault weapons also wants universal checks, and one person sat in several chairs. '
      || 'Re-axed onto the abortion-ladder model: each rung is a distinct LINE ("furthest you would go"), voter '
      || 'sits at exactly one. Value 1 pushed to the near-total-ban pole. Boundaries carry exclusivity: rung 1 '
      || '"except tightly licensed hunting/sport" (no general ownership), rung 2 "while allowing other firearms", '
      || 'rung 3 "allow all types" (the 2-vs-3 line: checks-AND-ban wants more than rung 3, so sits at rung 2). '
      || 'Waiting periods given no rung (sits below rung 3). Question UNCHANGED. rung_map identity {"1":1,...,"5":5}; '
      || 'ZERO seatings so no re-audit debt. A stance-research pass must seat officials on this v2 before Season 2 opens.',
      -- public_note
      'Reworked the options so no one fits two at once: each option is the furthest step you would take, from '
      || 'banning civilian firearms (with a narrow hunting and sport exception) at one end to repealing gun '
      || 'restrictions and permitless carry at the other. The middle options are a ban on assault-style weapons, '
      || 'universal background checks with no gun types banned, and keeping current law unchanged.',
      -- review_ref
      'Gun Policy design review 2026-08-31 (Chris Andrews); mutual-exclusivity fix on the CA_0093 founding ladder.',
      v_rungmap);
    RAISE NOTICE 'CA_0095: proposed re-axis revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0095: re-axis revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0095: re-axis revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0095: re-axis revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0095: re-axis revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur IS NULL THEN
    RAISE EXCEPTION 'CA_0095: gun-policy is not in Season 2 (expected CA_0094 pin present)';
  ELSIF v_cur = v_new THEN
    RAISE NOTICE 'CA_0095: Season 2 already pins the re-axis revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0095: Season 2 repinned % -> % (re-axis revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := '61a3920e-bdd9-479a-b5b3-237984401f0e';
  v_stem     CONSTANT text := 'How should the government regulate firearms?';
  v_chair1   CONSTANT text := 'Ban civilian firearm ownership, except for tightly licensed hunting and sport use.';
  v_chair5   CONSTANT text := 'Repeal major gun restrictions and let adults carry a firearm without a permit.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_new      uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_rev      int;
  v_ver      int;
  v_class    text;
  v_map      jsonb;
  v_q        text;
  v_n        int;
  v_pin      uuid;
  v_v1cur    boolean;
  v_v1stat   text;
BEGIN
  -- locate the v2 revision by its chair-1 text
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version,
         r.change_class::text, r.rung_map, r.question_text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class, v_map, v_q
    FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic
     AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                 WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0095 verify: re-axis revision not found'; END IF;

  IF v_rev <> 2 OR v_ver <> 2 THEN RAISE EXCEPTION 'CA_0095 verify: expected rev 2 / version 2, got rev %/v %', v_rev, v_ver; END IF;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0095 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_iscur IS TRUE THEN RAISE EXCEPTION 'CA_0095 verify: new rev is is_current (must not be until Season 2 opens)'; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0095 verify: new rev has published_at set (must be NULL until Season 2 opens)'; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0095 verify: new rev change_class is % (expected substantive)', v_class; END IF;
  IF v_map IS DISTINCT FROM v_rungmap THEN RAISE EXCEPTION 'CA_0095 verify: new rev rung_map is % (expected %)', v_map, v_rungmap; END IF;
  IF v_q <> v_stem THEN RAISE EXCEPTION 'CA_0095 verify: question changed (%); expected unchanged', v_q; END IF;

  -- five distinct stance values on v2
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0095 verify: v2 has % stance rows (expected 5)', v_n; END IF;
  SELECT count(DISTINCT value) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0095 verify: v2 stance values not distinct (got %)', v_n; END IF;

  -- polarity guard on v2: value 1 = ban pole, value 5 = repeal pole
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_new
     AND ( (value = 1 AND text = v_chair1) OR (value = 5 AND text = v_chair5) );
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0095 verify: v2 pole texts not in expected slots (got %/2)', v_n; END IF;

  -- v1 unchanged: still current + published (Season 2 not open yet)
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF v_v1cur IS NOT TRUE OR v_v1stat <> 'published' THEN
    RAISE EXCEPTION 'CA_0095 verify: v1 is no longer published/current (is_current=%, status=%)', v_v1cur, v_v1stat;
  END IF;

  -- Season 2 now pins v2
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0095 verify: Season 2 pins % (expected v2 %)', v_pin, v_new; END IF;

  -- not promoted (Season 2 still draft)
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0095 verify: topic leaked into an open season';
  END IF;

  RAISE NOTICE 'CA_0095 OK — gun-policy v2 (approved, not published), rung_map identity, Season 2 repinned to v2, v1 intact';
END $$;

COMMIT;
