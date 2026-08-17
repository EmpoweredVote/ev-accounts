-- 1821_bainbridge_kitsap_first_stances.sql
--
-- The first four compass chairs for the Bainbridge Island / Kitsap County cohort.
--
-- FOUR. Out of a possible 484 (22 people x 22 local topics). That is the honest yield of a full
-- evidence sweep, and the sparseness is the finding, not a shortfall:
--
--   * SIX of the 22 are Assessor, Auditor, Clerk and Treasurer. Those are administrative offices.
--     None of the 22 local-scope topics applies to them, and their pamphlet statements are about
--     assessment accuracy, e-filing and payment options. A blank compass there is CORRECT. Do not
--     let a later pass "fill them in".
--   * THE BAINBRIDGE COUNCIL'S DEFINING VOTES HAVE NOT HAPPENED YET. The Comprehensive Plan and
--     Winslow Subarea Plan — which decide residential zoning, growth pace, affordable housing and
--     tree canopy for the island — were still in Planning Commission as of 2026-07-24, after a
--     UNANIMOUS council remand of the mandatory inclusionary zoning provisions. Adoption is
--     expected SEPTEMBER 2026. There is no roll call to read yet.
--     → .planning/todos/2026-08-17-bainbridge-kitsap-stance-evidence.md
--   * The rest were refused one at a time, on the record, in that same todo.
--
-- 🔴 THE 6-1 INTERIM DEVELOPMENT REGULATIONS VOTE IS NOT USED HERE, DELIBERATELY. It is a real
--    recorded roll call and it is tempting, but the council was acting under a state mandate with
--    the builder's remedy in play. A compliance vote taken under legal duress evidences the
--    duress, not a preference chair. Six people would have been seated on it wrongly.
--
-- Sources are first-person and primary: the Washington Secretary of State's official 2026 primary
-- voters' pamphlet (the candidate's own filed statement) and the Bainbridge Conservation
-- Coalition's 2025 council candidate survey (the candidate's own written answer).
--
-- ⚠ On the chair-evidence gate: `scripts/audit-chair-evidence.mjs` tests whether the reasoning
--   names a bill, ordinance or recorded vote. None of these four do, because none of these four
--   people cast a relevant vote — two are challengers, who by definition have no voting record.
--   An instrument-only rule would make it structurally impossible to ever seat a challenger. The
--   standard these rows are held to is the one in CLAUDE.md: evidence that names THAT CHAIR rather
--   than a direction. Each reasoning below quotes the person's own words and states which
--   neighbouring chair the quote excludes and why. The regex was NOT widened to admit them; 17% of
--   the existing 33,383-row corpus names an instrument, so these are ordinary for the corpus.
--
-- reasoning is VOTER-FACING (essentials Citations.jsx renders it under "Why this position?").
-- Written for a voter, not for us.
--
-- Idempotent.

BEGIN;

CREATE TEMP TABLE _st (
  pid       uuid NOT NULL,
  tid       uuid NOT NULL,
  name      text NOT NULL,
  chair     numeric(3,1) NOT NULL,
  reasoning text NOT NULL,
  sources   text[] NOT NULL,
  PRIMARY KEY (pid, tid)
) ON COMMIT DROP;

INSERT INTO _st (pid, tid, name, chair, reasoning, sources) VALUES

-- Brandon L. Myers — candidate for Kitsap County Sheriff — Public Safety Approach = 4
('01119ca2-d252-4c9d-8052-57164ace14b8','e9ebefcd-c496-45e8-b816-a79f8442ba85','Brandon L. Myers',4,
 'In his filed statement for the 2026 Washington voters'' pamphlet, Myers writes that the Sheriff'''
 's Office "must be properly staffed, supported, and equipped to meet the growing needs of Kitsap '
 'County," names "staffing shortages" among the challenges he has seen in twenty years at the '
 'agency, and commits to "strengthening recruitment and retention." That is an argument for more '
 'deputies, better equipment and more competitive pay — the position at chair 4. It rules out '
 'chair 3, which holds current funding steady, because he states plainly that current staffing is '
 'not adequate. It also stops short of chair 5: he never argues that the Sheriff''s Office budget '
 'should come ahead of other county services.',
 ARRAY['https://voter.votewa.gov/GenericVoterGuide.aspx?e=898']),

-- Katie Walters — Kitsap County Commissioner, District 3 — Growth and Development Pace = 3
('c6a92f10-a49c-40b0-90bd-4d12f2ae4a97','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4','Katie Walters',3,
 'Walters''s filed statement for the 2026 Washington voters'' pamphlet accepts growth and argues '
 'for building ahead of it: "Kitsap is growing. We must manage growth thoughtfully, protecting our '
 'rural character and natural environment while investing in infrastructure, public safety, and '
 'economic opportunity." Pairing continued growth with infrastructure investment is chair 3. Her '
 'own record rules out chair 2, which requires slowing approvals until capacity catches up — in the '
 'same statement she lists "streamlining permitting" among her accomplishments as commissioner. It '
 'is not chair 4 either, since she frames growth as something to be managed and rural character as '
 'something to be protected, rather than development as something to recruit.',
 ARRAY['https://voter.votewa.gov/GenericVoterGuide.aspx?e=898']),

-- Mike Nelson — Bainbridge Island Councilmember, Position 3 — Growth and Development Pace = 2
('579f8af4-303c-4a7d-87de-6c473b07d29a','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4','Mike Nelson',2,
 'Answering the Bainbridge Conservation Coalition''s 2025 council candidate survey, Nelson wrote '
 'that "new development and population growth must yield to the carrying capacity we find," and '
 'that the island should plan "for reasonable growth, not massive growth." On Bainbridge the '
 'binding capacity is the aquifer rather than roads or sewers, but the position is the same one '
 'chair 2 describes: growth is allowed only as far as existing capacity supports it, and approvals '
 'wait until it does. He does not go as far as chair 1, which would impose outright growth limits '
 'or send major projects to a public vote. Nor is it chair 3, which invests in capacity so that '
 'expansion can proceed — Nelson subordinates the growth to the capacity, not the other way round.',
 ARRAY['https://bainbridgeconservationcoalition.org/2025-survey-of-candidates-for-bainbridge-island-city-council/']),

-- Lara Lant — Bainbridge Island Councilmember, Position 7 — Growth and Development Pace = 2
('6fe01c62-6a73-418c-975c-c59ea55bc61f','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4','Lara Lant',2,
 'In the Bainbridge Conservation Coalition''s 2025 council candidate survey, Lant wrote that "the '
 'Comprehensive Plan cannot address issues like housing before addressing groundwater limitations," '
 'adding that "Good planning requires good data." Sequencing the island''s housing decisions behind '
 'its groundwater capacity is chair 2: growth proceeds only where capacity supports it, and '
 'approvals wait until that capacity is established. She does not call for fixed growth limits or '
 'voter approval of projects, which is chair 1, and she is not at chair 3, which would build '
 'capacity ahead of growth rather than pause growth to measure it.',
 ARRAY['https://bainbridgeconservationcoalition.org/2025-survey-of-candidates-for-bainbridge-island-city-council/']);

-- ---------------------------------------------------------------------------
-- Pre-flight
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _st;
  IF n <> 4 THEN RAISE EXCEPTION 'staging holds % rows, expected 4', n; END IF;

  SELECT count(*) INTO bad FROM _st s
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = s.pid);
  IF bad > 0 THEN RAISE EXCEPTION '% staged politician_ids do not exist', bad; END IF;

  SELECT count(*) INTO bad FROM _st s
  WHERE NOT EXISTS (SELECT 1 FROM inform.compass_topics t WHERE t.id = s.tid);
  IF bad > 0 THEN RAISE EXCEPTION '% staged topic_ids do not exist', bad; END IF;

  -- every topic must genuinely be on the LOCAL scale for this cohort
  SELECT count(*) INTO bad FROM _st s
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_roles r
    WHERE r.topic_id = s.tid AND r.role_scope = 'local');
  IF bad > 0 THEN RAISE EXCEPTION '% staged topics are not local-scope', bad; END IF;

  -- the chair must actually exist on that ladder (guards a mis-typed value)
  SELECT count(*) INTO bad FROM _st s
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.compass_stances cs
    WHERE cs.topic_id = s.tid AND cs.value = s.chair);
  IF bad > 0 THEN RAISE EXCEPTION '% staged chairs do not exist on their ladder', bad; END IF;

  -- refuse to overwrite an existing answer we did not put there
  SELECT count(*) INTO bad FROM _st s
  JOIN inform.politician_answers a ON a.politician_id = s.pid AND a.topic_id = s.tid
  WHERE a.value <> s.chair;
  IF bad > 0 THEN RAISE EXCEPTION '% staged rows would overwrite a DIFFERENT existing chair', bad; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Answers, then context. Never an answer without its context: the chair is a
-- voter-facing claim and Citations.jsx renders the reasoning beside it.
-- ---------------------------------------------------------------------------
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT s.pid, s.tid, s.chair FROM _st s
ON CONFLICT (politician_id, topic_id) DO NOTHING;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT s.pid, s.tid, s.reasoning, s.sources FROM _st s
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---------------------------------------------------------------------------
-- Post-verify
-- ---------------------------------------------------------------------------
DO $$
DECLARE ans int; ctx int; orphan int; mismatched int;
BEGIN
  SELECT count(*) INTO ans
  FROM _st s JOIN inform.politician_answers a
    ON a.politician_id = s.pid AND a.topic_id = s.tid AND a.value = s.chair;
  IF ans <> 4 THEN RAISE EXCEPTION 'expected 4 answers at the staged chair, found %', ans; END IF;

  SELECT count(*) INTO ctx
  FROM _st s JOIN inform.politician_context c
    ON c.politician_id = s.pid AND c.topic_id = s.tid;
  IF ctx <> 4 THEN RAISE EXCEPTION 'expected 4 context rows, found %', ctx; END IF;

  -- no seated chair may be missing its reasoning, for ANY of these 22 people
  SELECT count(*) INTO orphan
  FROM inform.politician_answers a
  LEFT JOIN inform.politician_context c
    ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
  WHERE a.politician_id IN (SELECT pid FROM _st) AND c.politician_id IS NULL;
  IF orphan > 0 THEN RAISE EXCEPTION '% seated chairs have no context row', orphan; END IF;

  -- and no context row may be left asserting a position with no chair under it
  SELECT count(*) INTO orphan
  FROM inform.politician_context c
  LEFT JOIN inform.politician_answers a
    ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE c.politician_id IN (SELECT pid FROM _st) AND a.politician_id IS NULL;
  IF orphan > 0 THEN RAISE EXCEPTION '% context rows are gate-visible orphans', orphan; END IF;

  -- every source must be a real URL, not a research breadcrumb
  SELECT count(*) INTO mismatched
  FROM inform.politician_context c, unnest(c.sources) AS src
  WHERE c.politician_id IN (SELECT pid FROM _st) AND src NOT LIKE 'http%';
  IF mismatched > 0 THEN RAISE EXCEPTION '% sources are not URLs', mismatched; END IF;

  RAISE NOTICE 'OK: 4 chairs seated with reasoning and sources; no orphans either direction.';
END $$;

COMMIT;
