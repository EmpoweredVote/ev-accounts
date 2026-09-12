BEGIN;

-- =============================================================================
-- CA_0111: "Surveillance Technology" — a new compass topic (revision model)
-- =============================================================================
-- Created 2026-09-12.
--
-- WHAT THIS ADDS
-- A voter-facing compass topic covering what a community does with police
-- surveillance technology — licence plate readers, facial recognition, predictive
-- policing, camera networks — and, just as importantly, WHO AUTHORISES IT.
-- topic_key is frozen at 'surveillance-technology' (essentials.quotes joins on it).
--
-- WHY IT EXISTS: EVIDENCE WE ALREADY HOLD AND CURRENTLY THROW AWAY.
-- The Nashville Metro Council pass (2026-09-11, 104 rows from the Banner 2023
-- Voter's Guide) found candidates answering on licence plate readers and facial
-- recognition at length and with conviction — Councilmember Johnston lead-sponsored
-- the LPR ordinance; Councilmember Parker described himself as "generally opposed to
-- building up surveillance infrastructure". ALL OF IT WAS DISCARDED, because no
-- topic in the corpus maps to it. Every plausible neighbour was checked against the
-- live season set before writing this migration and each one is a different question:
--   public-safety-approach      police FUNDING LEVEL and the social-services mix
--   local-immigration           the city's relationship to FEDERAL IMMIGRATION
--   education-school-police     police IN SCHOOLS
--   ai-regulation               oversight of AI DEVELOPERS, a private-sector axis
--   data-centers                SITING large data centres
--   misinformation              PLATFORM content moderation
-- A live, locally salient axis the compass could not represent.
--
-- WHY THE LADDER IS ORIENTED THIS WAY (the decision most expensive to reverse —
-- reversing it later means rewriting every stored answer, so it is argued here)
--
--   VALUE 1 = PROHIBITION. VALUE 5 = MAXIMAL BUILDOUT.
--
--   Do NOT "correct" this against the old summary "chair 1 = maximum government
--   action". That summary does not survive contact with the live rows: on
--   economic-development chair 1 is NO incentives, and on ai-regulation chair 1 is
--   FREE development. It is a rough description, not an invariant, and the deleted
--   reference-file header ("1 = progressive, 5 = conservative") was retired for
--   manufacturing wrong positions off exactly this kind of generalisation.
--
--   The orientation is taken instead from THIS topic's two nearest siblings, read
--   from their own chair text:
--     public-safety-approach  1 = redirect police budget to social services
--                             5 = expanding the police budget is the top priority
--     local-immigration       1 = refuse all ICE detainers
--                             5 = actively assist federal enforcement
--   Both run restraint-on-the-enforcement-apparatus -> maximal enforcement.
--   Surveillance is plainly in that family, so it is aligned with them. An official
--   sitting at chair 1 on all three then produces a coherent radar shape.
--
--   🔴 THIS MATTERS AT THE PIXEL, NOT JUST IN THEORY. Nothing in the client derives
--   spoke orientation from the ladder: ev-ui plots `value` directly as radius, and
--   the only hook, `invertedSpokes`, is a per-VIEWER toggle defaulting to {}. So
--   every spoke means "higher chair = further from centre" unless a viewer flips it.
--   A ladder pointing the opposite way to its own neighbours misreads BY DEFAULT —
--   which is the standing defect on AI Oversight and Tariffs. Creation is the one
--   cheap moment to get this right.
--
-- THE TWO WAYS A LADDER FAILS, BOTH CHECKED BEFORE WRITING
--
--   * IT MUST DISCRIMINATE. Adjacent rungs here differ by INSTRUMENT, never by an
--     adverb. That is the defect that killed all 13 Maryland `taxes` rows, where
--     "significantly" vs "moderately" raise had no documentary discriminator:
--         1  an ordinance PROHIBITING acquisition
--         2  an ordinance GATING acquisition on council approval + use policy
--         3  a DEPARTMENTAL policy with after-the-fact public reporting
--         4  an interagency DATA-SHARING posture, routine use
--         5  a CAPITAL BUILDOUT with real-time monitoring and database integration
--     Each is separately documentable in a record a reader can check. The 2/3 line
--     is deliberately WHO AUTHORISES (council before acquisition vs department
--     after), because that is the line real CCOPS-style ordinances actually draw.
--
--   * IT MUST BE REACHABLE. Rung 1 is not hypothetical — San Francisco, Boston and
--     Portland have each banned municipal face recognition.
--     ⚠ STILL CHECK STATE PREEMPTION BEFORE SPENDING A PASS IN A NEW STATE.
--     This is the `rent-regulation` trap: Washington preempts local rent control, so
--     the most tenant-protective vote a WA local official can physically cast
--     evidences no chair at all. If a state forbids its cities from restricting
--     police surveillance technology, rungs 1-2 are out of bounds there and a pass
--     will return nothing.
--
--     ✅ TENNESSEE: VERIFIED 2026-09-12. NOT PREEMPTED — RUNGS 1-2 ARE REACHABLE.
--     Established from ENACTED TEXT, not from the absence of a statute. Nashville has
--     already exercised both powers, in Metro Code 13.08.080(G) via BL2021-961
--     (Johnston, passed 2022-02-01, 22-14):
--       - ACQUISITION GATE: a department "wishing to acquire or enter into an
--         agreement to acquire" LPR "shall comply with" a published usage-and-privacy
--         policy. That is rung 2's instrument, almost verbatim.
--       - "An LPR system authorized under this section shall not be capable of facial
--         recognition." A local facial-recognition PROHIBITION — rung 1's instrument.
--       - A 10-DAY RETENTION CAP, against the STATE's 90-day cap in TCA 55-10-302.
--         This is the cleanest disproof available: a locality legislating STRICTER
--         than the state provision, and standing since 2022, settles that the statute
--         is a ceiling on retention and not a floor barring stricter local rules.
--       - plus sharing limited to law-enforcement agencies on written request with
--         Custodian approval, annual audits, a 3-year audit trail readable by the DA /
--         Public Defender / COB chair, and race-and-ethnicity recording on LPR stops.
--
--     🔴 ONE REAL BOUNDARY, AND IT IS ABOUT IMMIGRATION, NOT SURVEILLANCE.
--     Tenn. Code Ann. Title 7, ch. 68, pt. 101 et seq. (the 2018 anti-sanctuary Act)
--     bars a local policy limiting cooperation with federal agencies "to verify or
--     report the immigration status of any alien". BL2022-1115 (passed 2022-08-16)
--     excluded immigration enforcement as an allowed LPR use, and Metro Legal's own
--     agenda analysis says it "could be interpreted by the State as a sanctuary
--     policy" — costing eligibility for any state ECD grant contract until repealed,
--     plus exposure to a resident's Chancery Court complaint. Council passed it anyway,
--     after an Aug 2 amendment carving out cooperation "to verify or report the
--     immigration status of a person" — tracking the Act's own words to mitigate.
--     ⚠ So seating someone at rung 2 on the strength of an IMMIGRATION-sharing
--     restriction specifically means seating them on a CONTESTED provision. Rung 2's
--     other instruments — council gate, published use policy, retention limit — are
--     clean and uncontested.
--
--     🔑 SOURCE: nashville.legistar.com has an OPEN REST API, no key, no WAF.
--     webapi.legistar.com/v1/nashville/matters/{id}/versions gives text ids, then
--     .../matters/{id}/texts/{textId} returns MatterTextPlain — the full enacted text
--     AND the Metro Legal agenda analysis quoted above. (.../texts with no id returns
--     405, not a list; read the JSON as UTF-8 explicitly.) There are 7 passed LPR
--     measures 2021-2023, BL2023-71 among them inside the CURRENT council term — the
--     instrument-rich path to seating officials on this topic.
--
-- ROLE SCOPES: local + state. The question is community-framed ("your community"),
-- like public-safety-approach and local-immigration, which are both local-only. state
-- is included because legislatures set surveillance law and preemption directly — and
-- because it gives the 131 Tennessee legislators seeded in migration 1855 a reachable
-- topic. NOT federal, and never judicial.
--
-- CATEGORIES: both "Public Safety and Law Enforcement" and "Technology, Data, and
-- Innovation". Dual assignment is established practice (data-centers,
-- education-school-police); this topic genuinely sits on both and belongs in either
-- browse path.
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via inform.admin_create_topic_with_revision
-- (CA_0026), which writes all five layers atomically — identity row, legacy 1..5
-- ladder, founding v1 revision (revision=1, version=1, change_class='substantive',
-- status='published', is_current=true, rung_map=NULL), the five stance revisions, and
-- the role scopes. The legacy admin_create_topic_with_stances RPC is INSUFFICIENT: it
-- writes no revision. The RPC takes no argument for design rationale, so it lives in
-- these comments (CA_0092 and CA_0101 are the models).
--
-- Rung descriptions, supporting_points and example_perspectives are left empty, which
-- is what the RPC writes and what every topic created through it currently holds.
-- Prose is a separate enrichment pass and is not a precondition for going live — the
-- eight live judicial topics carry none either.
--
-- 🔴 DELIBERATELY NOT PINNED TO A SEASON, AND IT CANNOT BE.
-- Season 2 OPENED 2026-09-04. inform.admin_season_add_topic raises
--   NOT_DRAFT: season % is open, its question set is frozen
-- so pinning is refused by the database, not by choice. CA_0101 could pin
-- ranked-choice-voting only because Season 2 was still a draft then.
--
-- That constraint happens to prevent the failure CA_0101 warned about in its own
-- header: a brand-new topic has no answers, so pinning it into an OPEN season would
-- put a spoke on every official's compass that is blank for all of them. The correct
-- order is: create now (this migration) -> run the stance research, starting with the
-- Nashville evidence that motivated it -> pin into Season 3 when that draft exists.
-- is_live stays false and it appears on NO voter surface until then.
--
-- IDEMPOTENT: the create runs only when topic_key 'surveillance-technology' is
-- absent; the category links use ON CONFLICT DO NOTHING. A re-run is a no-op and the
-- post-verify gate asserts the full shape either way. To revert: delete the topic row
-- (revisions, stances, roles and category links cascade). No existing object is
-- altered, and no existing answer is touched.
--
-- IDs (verified 2026-09-12):
--   Public Safety and Law Enforcement:  699a14d1-fc6d-48ac-b3dc-492f3f59ec6c
--   Technology, Data, and Innovation:   b15168c7-19bb-44a2-b462-4e75b2d9cf8c
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
--    topic_key derives as lower(replace(short_title,' ','-')) -> the RPC only
--    replaces SPACES, so short_title must stay free of punctuation.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'surveillance-technology'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Surveillance Technology and Police Data Collection',                 -- p_title
      'How should your community use surveillance technology like license plate readers and facial recognition?',
      'Surveillance Technology',                                            -- p_short_title -> 'surveillance-technology'
      false,                                                                -- p_is_live (staged; no open season to join)
      '[
        {"value":1,"text":"Prohibit the city from acquiring or operating face recognition, predictive policing, and similar surveillance systems."},
        {"value":2,"text":"Allow specific tools only with council approval and a published use policy, strict retention limits, and no outside data sharing."},
        {"value":3,"text":"Let the police department decide deployments under its own written policy, with regular public reporting after the fact."},
        {"value":4,"text":"Use surveillance technology routinely as a standard investigative tool and share data with other law enforcement agencies."},
        {"value":5,"text":"Build out citywide camera and license plate reader networks with real-time monitoring, integrated with state and federal databases."}
      ]'::jsonb,                                                            -- p_stances
      NULL,                                                                 -- p_actor_id
      '["local","state"]'::jsonb                                            -- p_role_scopes
    );
    RAISE NOTICE 'CA_0111: created topic surveillance-technology';
  ELSE
    RAISE NOTICE 'CA_0111: topic surveillance-technology already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Category assignment (both), idempotent. No season pin — see the header.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic    uuid;
  v_cat_ps   uuid := '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c';  -- Public Safety and Law Enforcement
  v_cat_tech uuid := 'b15168c7-19bb-44a2-b462-4e75b2d9cf8c';  -- Technology, Data, and Innovation
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'surveillance-technology';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0111: topic surveillance-technology is missing before category assignment';
  END IF;

  INSERT INTO inform.compass_topic_categories (topic_id, category_id)
  VALUES (v_topic, v_cat_ps), (v_topic, v_cat_tech)
  ON CONFLICT (topic_id, category_id) DO NOTHING;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Post-verify gate. A wrong count RAISEs and aborts the transaction, so
--    nothing partial commits.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic    uuid;
  v_cat_ps   uuid := '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c';
  v_cat_tech uuid := 'b15168c7-19bb-44a2-b462-4e75b2d9cf8c';
  v_n        int;
  v_key      text;
  v_live     boolean;
  v_t1       text;
  v_t5       text;
BEGIN
  SELECT id, topic_key, is_live INTO v_topic, v_key, v_live
    FROM inform.compass_topics WHERE topic_key = 'surveillance-technology';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0111: topic surveillance-technology is missing after create';
  END IF;

  -- topic_key frozen correctly (essentials.quotes joins on it)
  IF v_key <> 'surveillance-technology' THEN
    RAISE EXCEPTION 'CA_0111: topic_key is % (expected surveillance-technology)', v_key;
  END IF;

  -- staged, not live
  IF v_live THEN
    RAISE EXCEPTION 'CA_0111: topic is is_live=true; it must stay staged until a season pins it';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0111: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0111: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0111: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly two role rows: local + state. Never federal, never judicial.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CA_0111: expected exactly 2 role rows, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state') THEN
    RAISE EXCEPTION 'CA_0111: expected local + state role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles
              WHERE topic_id = v_topic AND role_scope IN ('federal','judicial')) THEN
    RAISE EXCEPTION 'CA_0111: unexpected federal/judicial role row';
  END IF;

  -- ORIENTATION GUARD. 1 = prohibition, 5 = maximal buildout. This is the check
  -- that catches someone "fixing" the ladder to the chair-1-is-maximum-government-
  -- action generalisation, which would silently invert every stored answer.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE 'Prohibit%' OR v_t5 NOT ILIKE '%real-time monitoring%' THEN
    RAISE EXCEPTION 'CA_0111: orientation check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- both categories assigned
  SELECT count(*) INTO v_n FROM inform.compass_topic_categories
   WHERE topic_id = v_topic AND category_id IN (v_cat_ps, v_cat_tech);
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CA_0111: expected both category links (public safety + technology), got %', v_n;
  END IF;

  -- NOT pinned to any season. Season 2 is open and its question set is frozen, so
  -- a pin here would mean someone bypassed admin_season_add_topic's NOT_DRAFT guard
  -- with a raw INSERT — and would put a spoke that is blank for EVERY official onto
  -- the live compass. Pin into Season 3 when that draft exists.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE topic_id = v_topic;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0111: topic is pinned into % season(s); expected 0 until a DRAFT season exists', v_n;
  END IF;

  -- and therefore not promoted to any voter surface
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0111: topic leaked onto a voter surface before being pinned';
  END IF;

  -- no answers can exist yet; this is a brand-new topic
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0111: % answers already exist on a topic created in this migration', v_n;
  END IF;

  RAISE NOTICE 'CA_0111 OK — surveillance-technology staged (1 published/current v1, 5 rungs, 5 legacy stances, 2 roles local+state, orientation 1=prohibit/5=buildout, 2 categories, NOT pinned, NOT promoted, is_live=false)';
END $$;

COMMIT;
