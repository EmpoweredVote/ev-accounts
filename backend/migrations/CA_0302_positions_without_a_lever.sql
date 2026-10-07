-- =============================================================================
-- CA_0302 — positions without a lever (ruling 2026-10-06, Chris Andrews, option B)
-- =============================================================================
-- Until now a level was asked a topic only where its officeholders hold a lever
-- on the rungs (CLAUDE.md "Scope is a per-rung question", ruling 2026-08-28).
-- Option B splits that rule in two:
--
--   * WHICH TOPICS A LEVEL IS ASKED: every topic, at federal, state and local,
--     unless there is a good reason not to. Named exclusions (2026-10-06):
--       - judicial topics stay judge-only, and judges keep judicial topics only;
--       - school boards keep the school topics only (2026-09-24 ruling stands, for now);
--       - local-only topics ("your community") wait until their question text
--         reads at every level;
--       - education-charter-authorization is not asked at federal: its question
--         says "the board".
--   * WHAT EVIDENCE CAN SEAT A CHAIR: a record needs a lever. At a level with no
--     lever, only the person's own words can (codebook V2 "No-lever level").
--
-- compass_topic_roles.evidence_basis records the second half per (topic, level):
--   'record'    — records and own words both count (the level holds a lever);
--   'own-words' — only the person's own words count (no lever at this level).
-- It is a topic-level summary used to route rows and to split reliability strata.
-- The annex's per-rung "Levels that hold a lever" lines still govern the coder.
--
-- New rows are is_required = false, so get_compass_completeness (which counts
-- is_required rows) asks no voter to answer more than before.
--
-- Four existing rows were already own-words in practice (their annexes say no lever
-- at that level on any rung): abortion/local, deportation/state, education-ai/local and
-- education-gender-identity/local. They are re-labelled here. Every other
-- existing row defaults to 'record'; an audit of those is owed
-- (.planning/todos/2026-10-06-positions-without-a-lever.md).
--
-- New 'own-words' rows are a CONSERVATIVE default: where a level does hold some
-- lever (local taxes, federal transportation money), a coder drops a record it
-- could have used, giving a blank rather than a wrong chair. Review list in the memo.
--
-- reliability_certifications.evidence_basis: a stratum is now
-- level × evidence class × evidence basis. The one recorded certification
-- (eb2f791a, state × record) was measured on lever rows, so it takes 'record'.
--
-- Additive. Idempotent. No answer, context or gold row is touched.
-- =============================================================================

BEGIN;

-- 1. compass_topic_roles.evidence_basis -----------------------------------------
ALTER TABLE inform.compass_topic_roles
  ADD COLUMN IF NOT EXISTS evidence_basis text NOT NULL DEFAULT 'record';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'compass_topic_roles_evidence_basis_check'
       AND conrelid = 'inform.compass_topic_roles'::regclass
  ) THEN
    ALTER TABLE inform.compass_topic_roles
      ADD CONSTRAINT compass_topic_roles_evidence_basis_check
      CHECK (evidence_basis IN ('record', 'own-words'));
  END IF;
END $$;

COMMENT ON COLUMN inform.compass_topic_roles.evidence_basis IS
  'CA_0302 (ruling 2026-10-06, option B): record = the level holds a lever, so records and own words '
  'both count; own-words = no lever at this level, only the person''s own words can seat a chair '
  '(codebook V2 "No-lever level"). Topic-level summary for routing and reliability strata; the annex '
  'per-rung lever lines govern the coder.';

-- 2. Existing rows that were already own-words ----------------------------------
UPDATE inform.compass_topic_roles r
   SET evidence_basis = 'own-words'
  FROM inform.compass_topics t
 WHERE t.id = r.topic_id
   AND (t.topic_key, r.role_scope) IN (('abortion', 'local'), ('deportation', 'state'),
                                       ('education-ai', 'local'), ('education-gender-identity', 'local'))
   AND r.evidence_basis <> 'own-words';

-- 3. New asked levels, own words only -------------------------------------------
INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required, evidence_basis)
SELECT t.id, v.role_scope, false, 'own-words'
  FROM (VALUES
    -- federal-only topics → state and local
    ('border-security', 'state'), ('border-security', 'local'),
    ('defense-spending', 'state'), ('defense-spending', 'local'),
    ('israel-military-aid', 'state'), ('israel-military-aid', 'local'),
    ('military-intervention', 'state'), ('military-intervention', 'local'),
    ('social-security', 'state'), ('social-security', 'local'),
    ('tariffs', 'state'), ('tariffs', 'local'),
    ('ukraine-support', 'state'), ('ukraine-support', 'local'),
    -- federal + state topics → local
    ('ai-regulation', 'local'), ('deportation', 'local'), ('healthcare', 'local'),
    ('medicare/aid', 'local'), ('misinformation', 'local'), ('redistricting', 'local'),
    ('same-sex-marriage', 'local'), ('school-vouchers', 'local'), ('taxes', 'local'),
    ('voting-rights', 'local'),
    -- local + state topics → federal
    ('economic-development', 'federal'), ('growth-and-development', 'federal'),
    ('jail-capacity', 'federal'), ('rent-regulation', 'federal'),
    ('transportation-priorities', 'federal'),
    -- education topics → federal (charter-authorization excluded: "the board")
    ('education-ai', 'federal'), ('education-curriculum', 'federal'),
    ('education-equity-programs', 'federal'), ('education-gender-identity', 'federal'),
    ('education-library-books', 'federal'), ('education-school-budget', 'federal'),
    ('education-school-police', 'federal')
  ) AS v(topic_key, role_scope)
  JOIN inform.compass_topics t ON t.topic_key = v.topic_key
ON CONFLICT (topic_id, role_scope) DO NOTHING;

-- 4. reliability_certifications.evidence_basis ----------------------------------
ALTER TABLE inform.reliability_certifications
  ADD COLUMN IF NOT EXISTS evidence_basis text NOT NULL DEFAULT 'record';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'reliability_certifications_evidence_basis_check'
       AND conrelid = 'inform.reliability_certifications'::regclass
  ) THEN
    ALTER TABLE inform.reliability_certifications
      ADD CONSTRAINT reliability_certifications_evidence_basis_check
      CHECK (evidence_basis IN ('record', 'own-words'));
  END IF;
END $$;

COMMENT ON COLUMN inform.reliability_certifications.evidence_basis IS
  'CA_0302: the stratum''s evidence basis (compass_topic_roles.evidence_basis of the rows measured). '
  'A certification on record rows never covers own-words rows.';

-- Post-verify gate.
DO $$
DECLARE
  n_new int;
  n_own int;
  n_judicial_mixed int;
  n_school_new int;
  n_missing int;
BEGIN
  -- All 36 (topic, level) pairs exist, own-words, not required.
  SELECT count(*) INTO n_new
    FROM inform.compass_topic_roles r JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE r.evidence_basis = 'own-words' AND NOT r.is_required;
  IF n_new <> 36 THEN
    RAISE EXCEPTION 'CA_0302: expected 36 own-words not-required rows, found %', n_new;
  END IF;

  SELECT count(*) INTO n_own FROM inform.compass_topic_roles WHERE evidence_basis = 'own-words';
  IF n_own <> 40 THEN
    RAISE EXCEPTION 'CA_0302: expected 40 own-words rows (36 new + 4 re-labelled), found %', n_own;
  END IF;

  -- Exclusions held: no judicial topic gained a level, no school row was added.
  SELECT count(*) INTO n_judicial_mixed
    FROM inform.compass_topic_roles r JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE t.topic_key LIKE 'judicial-%' AND r.evidence_basis = 'own-words';
  SELECT count(*) INTO n_school_new
    FROM inform.compass_topic_roles WHERE role_scope = 'school' AND evidence_basis = 'own-words';
  IF n_judicial_mixed <> 0 OR n_school_new <> 0 THEN
    RAISE EXCEPTION 'CA_0302: exclusion broken (judicial %, school %)', n_judicial_mixed, n_school_new;
  END IF;

  -- Every topic key in the list resolved (a renamed key would silently insert nothing).
  SELECT count(*) INTO n_missing
    FROM unnest(ARRAY['border-security','defense-spending','israel-military-aid','military-intervention',
                      'social-security','tariffs','ukraine-support','ai-regulation','deportation','healthcare',
                      'medicare/aid','misinformation','redistricting','same-sex-marriage','school-vouchers',
                      'taxes','voting-rights','economic-development','growth-and-development','jail-capacity',
                      'rent-regulation','transportation-priorities','education-ai','education-curriculum',
                      'education-equity-programs','education-gender-identity','education-library-books',
                      'education-school-budget','education-school-police']) k
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_topics t WHERE t.topic_key = k);
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'CA_0302: % topic keys in the list do not exist', n_missing;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.reliability_certifications WHERE evidence_basis <> 'record') THEN
    RAISE EXCEPTION 'CA_0302: an existing certification is not record-basis';
  END IF;
END $$;

COMMIT;
