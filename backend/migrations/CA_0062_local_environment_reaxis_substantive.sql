-- CA_0062_local_environment_reaxis_substantive.sql
-- =============================================================================
-- Re-axis the `local-environment` compass topic ("Environmental Protection vs.
-- Development", topic 1935979c-b290-42e4-baa5-8cb0138b4ffa) and stage it for
-- Season 2.
--
-- WHY (substantive, NOT clarifying):
--   The live rungs (v1 rev1) are multi-barreled because the topic spans three
--   tangled dimensions: STRINGENCY (the intended protection<->development spine),
--   WHICH ENVIRONMENTAL GOOD (create green space / preserve existing assets /
--   mitigate impact / procedural review), and MECHANISM (mandate / review / pay /
--   deregulate). The pending v2 draft (rev2) "de-barreled" by keeping ONE good per
--   rung (review-only at 1, offset-only at 2); that split the ladder across
--   dimensions and DELETED the greening/preservation good that ~150 of the 251
--   rung-1/2 seatings rest on (rung 2: only 31 of 184 rows even mention offsets).
--   This revision instead rewrites every rung as a single point on the stringency
--   spine, so the specific good/mechanism becomes EVIDENCE that places a person
--   rather than the rung's claim. Every seated official keeps a home. It redefines
--   what each rung claims, so it is substantive (version bumps 1 -> 2).
--
-- RUNG MAP = IDENTITY, and why that is honest here (contrast the v2 draft):
--   admin_publish refuses any non-identity map (answer re-pointing is unbuilt,
--   CA_0015). The identity map governs ONLY the publish transaction, which touches
--   NO answers: all 357 seatings live in Season 1, which stays pinned to VERSION 1
--   (rev1, superseded but still served for a version-1 pin). Season 2 holds 0
--   answers. So publishing version 2 re-points nothing. The re-axis preserves the
--   stringency ORDER, so old rung N -> new rung N is the correct DEFAULT; only a
--   few BOUNDARY cases (1<->2, 2<->3) need adjustment, and that is a SEPARATE,
--   deferred re-audit done by hand when Season 1 answers are carried into Season 2
--   (S2 assembly), BEFORE Season 2 opens.
--
--   🔴 OPERATIONAL GUARDRAIL: do NOT open Season 2 until the boundary re-audit and
--   its re-seat migration are done. This migration only PUBLISHES the ladder and
--   PINS the draft Season 2 to it. It changes nothing a current voter sees — the
--   open Season 1 keeps serving version 1.
--
-- No answer rows are deleted or moved here, so audit-chair-evidence and the
-- answer-delete context guard are N/A (they apply to the later re-seat migration).
--
-- Sequence (all via the admin_*_topic_revision / season RPCs, one atomic DO block):
--   1) reject the pending v2 draft (rev2)
--   2) propose the re-axis as substantive  -> new rev (revision 3, version 2, draft)
--   3) approve it
--   4) publish it  -> becomes current/published; rev1 -> superseded
--   5) repin draft Season 2 (Q27) from rev1 to the new revision
--   6) post-verify gate (RAISE on any wrong count / state)
--
-- Dry-run first:  wrap this file body BEGIN; ... ROLLBACK;  and confirm it reverts.
-- Apply:          BEGIN; \i CA_0062...sql  COMMIT;  (single transaction)
-- =============================================================================

DO $migrate$
DECLARE
  v_topic      CONSTANT UUID := '1935979c-b290-42e4-baa5-8cb0138b4ffa';
  v_rev1       CONSTANT UUID := '93f16430-bb0b-4227-ae2d-de3d26535ed7'; -- v1 rev1, current
  v_rev2       CONSTANT UUID := '0432df5f-aaf9-46ae-a670-6729c02bbfb1'; -- v2 rev2, pending draft
  v_actor      CONSTANT UUID := '854fbc06-40fc-458d-b523-20ef8e5ad1b2'; -- chrisandrewsedu (rev2 proposer)
  v_s2         CONSTANT UUID := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_s1         CONSTANT UUID := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'; -- Season 1 (open)
  v_new        UUID;
  v_stances    JSONB;
  v_status     TEXT;
  v_n          INT;
BEGIN
  -- ---- Preconditions (fail loudly on a re-run) -----------------------------
  SELECT status::text INTO v_status FROM inform.compass_topic_revisions WHERE id = v_rev2;
  IF v_status IS DISTINCT FROM 'draft' THEN
    RAISE EXCEPTION 'CA_0062 precondition: rev2 % is % (expected draft) — already run?', v_rev2, v_status;
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE topic_id = v_topic AND version = 2 AND status IN ('published','approved')) THEN
    RAISE EXCEPTION 'CA_0062 precondition: a version-2 published/approved revision already exists — already run?';
  END IF;

  v_stances := $stances$
  [
    {
      "value": 1,
      "text": "Make environmental protection the overriding priority — block or sharply limit development that would harm the local environment",
      "description": "This stance treats environmental protection as the community's overriding priority: when a proposed development would harm natural areas, tree canopy, green space, water, or air, the community should be willing to block it or scale it back sharply rather than accept the harm. What matters is the outcome — the environment is preserved — not the particular tool used to get there, whether a hard green-space mandate, strict tree protection, or a demanding review that stops damaging projects before they are approved. Proponents argue that environmental assets are public goods whose loss is cumulative and often irreversible, so protecting them must come before development's other benefits rather than be traded away against them.",
      "supporting_points": [
        "Mature tree canopy, wetlands, and natural areas take decades to replace and some losses are permanent, so preventing harm up front avoids costs that no later mitigation can fully recover.",
        "Cumulative impact is the core problem: each project approved with harm accepted 'just this once' adds to flooding, heat, and habitat loss across the whole community, and only a protection-first posture interrupts that ratchet.",
        "Treating preservation as the deciding factor rather than one interest to be balanced gives the community a clear, predictable standard that developers can plan around and that does not bend under each project's economic pressure."
      ],
      "example_perspectives": [
        "A resident who has watched each development cycle shrink the neighborhood's trees and open space may support making preservation the deciding factor, because nothing weaker has stopped the steady loss.",
        "A homeowner who has experienced repeated stormwater flooding may view a willingness to block harmful projects as the only real safeguard, since after-the-fact mitigation has not protected their property.",
        "A council member who champions parks and new green space may see an overriding-priority standard as the position that matches how strongly they weight the environment against growth."
      ]
    },
    {
      "value": 2,
      "text": "Lean strongly toward protection — put the burden on development to prove it will not damage the environment before it can proceed",
      "description": "This stance leans strongly toward protection but stops short of blocking development outright: a project can proceed only if it carries the burden of showing it will leave the environment no worse off — for example by fully offsetting its impact, replacing what it removes, or strictly protecting the assets around it. The presumption favors the environment, and the developer, not the public, has to prove the project clears that bar. Proponents argue this keeps the community's total stock of environmental assets from declining while still allowing well-designed projects that genuinely internalize their costs to move forward.",
      "supporting_points": [
        "Placing the burden of proof on the developer means the community keeps its environmental assets by default and only gives ground when a project can demonstrate — not merely assert — that it will cause no net loss.",
        "A full-offset or full-replacement standard internalizes environmental costs into the project rather than externalizing them onto residents, so growth pays its own environmental way instead of drawing down a shared asset.",
        "Allowing vetted projects to proceed keeps the door open to housing and economic development, which distinguishes a strong-protection posture from an outright block and makes it durable against the charge that it stops all growth."
      ],
      "example_perspectives": [
        "An urban-forestry professional who tracks canopy cover over time may support a no-net-loss burden on developers as the minimum needed to prevent the slow depletion that unreviewed removals cause.",
        "A neighborhood resident whose local park is the only green space for blocks may back strict protection of existing assets while still accepting development that clearly replaces what it takes.",
        "A developer who prefers clear, consistent offset rules to unpredictable case-by-case fights may view a high but well-defined bar as a workable condition for proceeding."
      ]
    },
    {
      "value": 3,
      "text": "Apply consistent environmental standards while giving developers reasonable flexibility on implementation",
      "description": "This stance holds that the community should balance environmental protection and development case by case, applying clear and consistently enforced environmental standards — for tree removal, green space, stormwater, and landscaping — while giving developers reasonable flexibility in how they meet them on a specific site. It treats a protected environment as the goal and a workable project as an equally legitimate goal, and looks for the arrangement on each site that serves both. Proponents believe outcome-based standards with implementation flexibility produce better environmental results and better development than either rigid prescriptive rules or ad-hoc deals.",
      "supporting_points": [
        "Consistent standards applied to every project create predictability and prevent the sense that environmental requirements are negotiable by project size or political connection.",
        "Flexibility in how a standard is met — on-site mitigation, off-site compensation, or a fee — lets a project respond to site constraints while still delivering the required environmental outcome.",
        "Focusing rules on measurable outcomes the community actually cares about — net canopy, green space, stormwater performance — rather than on process compliance keeps regulation honest and administrable."
      ],
      "example_perspectives": [
        "A resident who wants the environment protected but also wants the community to approve good projects without excessive friction may see consistent, flexible standards as the approach most likely to achieve both.",
        "An environmental staff person who would rather enforce meaningful outcomes than police the gaming of technical rules may favor outcome-based standards as more durable.",
        "A developer who has hit both rigid rules that created needless complications and flexible standards that reached the same result more efficiently may prefer the balanced approach."
      ]
    },
    {
      "value": 4,
      "text": "Lean toward development — treat environmental cost as a manageable trade-off and approve projects with clear economic benefit",
      "description": "This stance leans toward development: when growth and environmental preservation come into direct conflict, it treats the environmental cost as a manageable trade-off and favors approving projects that bring clear economic benefit. Environmental features are seen as largely fungible — a contribution to a community greening fund, or preservation elsewhere, can stand in for what is removed on site — so the priority is to keep each parcel economically productive rather than to hold development to on-site preservation. Proponents argue that the tax revenue and jobs development generates fund the very services, parks included, that residents value.",
      "supporting_points": [
        "Fee-in-lieu and off-site arrangements let a project proceed on its most economically productive design while still directing some value to greening investments where they are most efficiently spent.",
        "Economic activity on developed land generates the property tax, sales tax, and employment that pay for community services — parks maintenance among them — so favoring development can support green space indirectly.",
        "Treating environmental features as fungible avoids letting site-specific preservation block housing and commercial projects the community needs, concentrating greenery where it is most usable instead."
      ],
      "example_perspectives": [
        "A business owner seeking a location who weights access, parking, and visibility above nearby greenery may see this stance as reflecting their real priority ordering.",
        "A finance official who views property-tax revenue as the main funding source for parks and services may favor development that generates it, trusting fees to backfill greening.",
        "A developer whose design is constrained by on-site preservation may prefer a fee-in-lieu path that keeps the project viable while still contributing to a community fund."
      ]
    },
    {
      "value": 5,
      "text": "Remove local environmental restrictions beyond what state and federal law requires",
      "description": "This stance puts development first and holds that local environmental rules going beyond state and federal requirements impose cost and delay without a proportional benefit, so the community should limit its environmental regulation to what higher levels of government mandate. Extra local tree ordinances, green-space mandates, and enhanced stormwater standards are seen as duplicative layers that slow projects and make the community less competitive for investment that would otherwise go elsewhere. Proponents argue that state and federal agencies, with broader expertise and authority, are the right level to set environmental protection, leaving local government to focus on land use, services, and infrastructure.",
      "supporting_points": [
        "State and federal regulation already sets a substantial environmental baseline, so local rules that exceed it add cost and delay without, in most cases, a commensurate environmental gain.",
        "Removing duplicative local requirements shortens approval timelines and lowers compliance costs, making the community more competitive for development that is otherwise mobile.",
        "Environmental regulation is a state and federal competency with agencies built for it; local government is better placed to concentrate on land use, services, and infrastructure within that framework."
      ],
      "example_perspectives": [
        "A developer working across jurisdictions who finds local environmental layers add time and cost without improving outcomes may see streamlining to state and federal standards as a reasonable simplification.",
        "A council member focused on removing barriers to housing production may view local rules that exceed higher-level requirements as an area of regulatory overreach.",
        "A property owner who finds local requirements stricter than state or federal standards may regard higher-level rules as the appropriate ceiling on environmental governance."
      ]
    }
  ]
  $stances$::jsonb;

  -- ---- 1) Reject the pending v2 draft --------------------------------------
  PERFORM inform.admin_reject_topic_revision(
    v_rev2, v_actor,
    'Superseded by CA_0062: re-axis to a single protection-vs-development stringency spine. The one-good-per-rung split deleted the greening/preservation position ~150 seatings rest on; re-proposing as a mechanism-neutral ladder.');

  -- ---- 2) Propose the re-axis as substantive (identity rung map) ------------
  SELECT inform.admin_propose_topic_revision(
    'local-environment',
    v_actor,
    'substantive',
    'Environmental Protection vs. Development',
    'Environmental Protection vs. Development',
    'How should your community balance new development with environmental preservation?',
    v_stances,
    'Re-axis, not a de-barrel. Rewrites every rung as one point on the protection-vs-development stringency spine so the specific good/mechanism (green space, canopy, offsets, review, fees) becomes evidence that PLACES a person, not the rung''s claim. Fixes the tangled-axes problem the v2 draft exposed and de-barrels rung 4. Identity rung map: publish touches no answers (Season 1 stays on version 1; Season 2 holds 0 answers). Boundary moves (1<->2, 2<->3) are a SEPARATE re-audit before Season 2 opens. Supersedes rejected v2 draft 0432df5f.',
    'Clearer five-point scale from protection-first to development-first, so every official has a place on the ladder.',
    NULL,
    '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
  ) INTO v_new;

  IF v_new IS NULL THEN
    RAISE EXCEPTION 'CA_0062: propose returned NULL';
  END IF;

  -- ---- 3) Approve, 4) Publish ----------------------------------------------
  PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
  PERFORM inform.admin_publish_topic_revision(v_new, v_actor);

  -- ---- 5) Repin draft Season 2 (Q27) to the new revision -------------------
  PERFORM inform.admin_season_pin_revision(v_s2, v_topic, v_new, v_actor);

  -- ========================================================================
  -- POST-VERIFY GATE
  -- ========================================================================
  -- New revision: version 2, substantive, published, current.
  SELECT version || '/' || change_class::text || '/' || status::text || '/' || is_current::text
    INTO v_status
    FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status IS DISTINCT FROM '2/substantive/published/true' THEN
    RAISE EXCEPTION 'CA_0062 verify: new rev is % (expected 2/substantive/published/true)', v_status;
  END IF;

  -- Five stances, all fully authored (3 supporting points + 3 examples, non-null description).
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_new
     AND description IS NOT NULL
     AND array_length(supporting_points, 1) = 3
     AND array_length(example_perspectives, 1) = 3;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0062 verify: expected 5 fully-authored stances, found %', v_n;
  END IF;

  -- Old draft rejected; old current superseded.
  SELECT status::text INTO v_status FROM inform.compass_topic_revisions WHERE id = v_rev2;
  IF v_status <> 'rejected' THEN
    RAISE EXCEPTION 'CA_0062 verify: rev2 is % (expected rejected)', v_status;
  END IF;
  SELECT status::text INTO v_status FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF v_status <> 'superseded' THEN
    RAISE EXCEPTION 'CA_0062 verify: rev1 is % (expected superseded)', v_status;
  END IF;

  -- Season 2 pinned to the new revision; Season 1 untouched (still rev1 / version 1).
  SELECT topic_revision_id INTO v_status FROM inform.season_questions
   WHERE season_id = v_s2 AND topic_id = v_topic;
  IF v_status::uuid IS DISTINCT FROM v_new THEN
    RAISE EXCEPTION 'CA_0062 verify: Season 2 pin is % (expected new rev %)', v_status, v_new;
  END IF;
  SELECT topic_revision_id INTO v_status FROM inform.season_questions
   WHERE season_id = v_s1 AND topic_id = v_topic;
  IF v_status::uuid IS DISTINCT FROM v_rev1 THEN
    RAISE EXCEPTION 'CA_0062 verify: Season 1 pin moved to % (expected rev1 % — S1 must be untouched)', v_status, v_rev1;
  END IF;

  RAISE NOTICE 'CA_0062 OK — new rev % published (v2, substantive); rev2 rejected; rev1 superseded; Season 2 Q27 repinned; Season 1 untouched (version 1). Re-audit boundary rows before opening Season 2.', v_new;
END
$migrate$;
