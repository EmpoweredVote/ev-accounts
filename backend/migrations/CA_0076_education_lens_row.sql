-- CA_0076_education_lens_row.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
-- NUMBERING: CA_0076 is the next free slot after CA_0074 on master (0072/0073 are taken by
--   economic-development and homelessness). Must run AFTER CA_0075 (references the 8
--   education-* topics by key). Applied to prod 2026-08-31 via psql.
--
-- =============================================================================
-- CA_0076: Education lens row + wiring — claim SCHOOL + STATE_BOARD_EDUCATION, group the 8 topics
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- WHAT THIS ADDS
--   1. A new `education` lens (inform.compass_lenses). key='education' is REQUIRED — essentials
--      hardcodes educators:'education' (Phase 209 / EDU-01/EDU-02). Do NOT rename.
--   2. auto_district_types = {SCHOOL, STATE_BOARD_EDUCATION} — the education lens becomes the
--      per-office default for local school boards AND elected state boards of education.
--   3. Removes SCHOOL from the `local` lens's auto_district_types (education TAKES SCHOOL from
--      local, per the 2026-08-31 decision). local keeps LOCAL, LOCAL_EXEC, COUNTY.
--   4. Groups the 8 CA_0075 topics under the education lens via inform.compass_lens_topics
--      (ordered) — this is what "grouped by the education lens" means; it is the lens's
--      ordered topic list, the same mechanism federal/judicial use (see 1337).
--
-- WHY THE SCHOOL FLIP IS SAFE NOW (verified against prod 2026-08-31)
--   There are ZERO politicians with district_type SCHOOL or STATE_BOARD_EDUCATION, so no office
--   is served the local lens for a school seat today. compassService refuses to render a lens
--   with zero promoted topics, so this flip must land BEFORE any school office goes live — which
--   is exactly the current state. The 8 education topics stay STAGED (CA_0075 set is_live=false and
--   nothing pins them to a season), so they show to no voter yet; they go live only when pinned to
--   an open season. This migration sets up the lens + grouping; it does not make anything voter-visible.
--
-- IDEMPOTENT: lens upsert on (key); local update is a fixed target array; lens_topics upsert on
--   (lens_id, topic_id). Re-run is a no-op. Post-verify gate asserts the end state either way.
--   To revert: delete the education lens row (its lens_topics cascade) and restore SCHOOL to the
--   local lens's auto_district_types.
-- =============================================================================

BEGIN;

-- ── 1. Upsert the education lens (claims SCHOOL + STATE_BOARD_EDUCATION) ───────────────────────────
INSERT INTO inform.compass_lenses (key, name, description, color, icon, is_active, auto_district_types)
VALUES ('education', 'Education Lens',
        '8 questions for school board and state board of education candidates',
        '#7A4FA3', 'graduation-cap', true,
        ARRAY['SCHOOL','STATE_BOARD_EDUCATION'])
ON CONFLICT (key) DO UPDATE
  SET name               = EXCLUDED.name,
      description        = EXCLUDED.description,
      color             = EXCLUDED.color,
      icon              = EXCLUDED.icon,
      is_active         = EXCLUDED.is_active,
      auto_district_types = EXCLUDED.auto_district_types;

-- ── 2. Remove SCHOOL from the local lens (education takes it) ──────────────────────────────────────
UPDATE inform.compass_lenses
   SET auto_district_types = ARRAY['LOCAL','LOCAL_EXEC','COUNTY']
 WHERE key = 'local';

-- ── 3. Group the 8 education topics under the education lens (ordered) ─────────────────────────────
INSERT INTO inform.compass_lens_topics (lens_id, topic_id, sort_order)
SELECT (SELECT id FROM inform.compass_lenses WHERE key='education'), t.id, v.ord
  FROM (VALUES
    ('education-curriculum',            0),
    ('education-library-books',         1),
    ('education-gender-identity',       2),
    ('education-equity-programs',       3),
    ('education-school-police',         4),
    ('education-charter-authorization', 5),
    ('education-school-budget',         6),
    ('education-ai',                    7)
  ) AS v(topic_key, ord)
  JOIN inform.compass_topics t ON t.topic_key = v.topic_key
ON CONFLICT (lens_id, topic_id) DO UPDATE SET sort_order = EXCLUDED.sort_order;

-- ── 4. Post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_lens uuid;
  v_dts  text[];
  v_n    int;
BEGIN
  SELECT id, auto_district_types INTO v_lens, v_dts
    FROM inform.compass_lenses WHERE key='education';
  IF v_lens IS NULL THEN RAISE EXCEPTION 'CA_0076: education lens missing'; END IF;
  IF NOT (v_dts @> ARRAY['SCHOOL','STATE_BOARD_EDUCATION'] AND array_length(v_dts,1)=2) THEN
    RAISE EXCEPTION 'CA_0076: education auto_district_types wrong: %', v_dts;
  END IF;

  -- local must no longer claim SCHOOL
  SELECT auto_district_types INTO v_dts FROM inform.compass_lenses WHERE key='local';
  IF 'SCHOOL' = ANY(v_dts) THEN
    RAISE EXCEPTION 'CA_0076: local lens still claims SCHOOL: %', v_dts;
  END IF;

  -- exactly the 8 education topics grouped, all resolved (no missing keys)
  SELECT count(*) INTO v_n
    FROM inform.compass_lens_topics lt
   WHERE lt.lens_id = v_lens;
  IF v_n <> 8 THEN
    RAISE EXCEPTION 'CA_0076: expected 8 education lens_topics, got % (CA_0075 applied first?)', v_n;
  END IF;

  RAISE NOTICE 'CA_0076 OK — education lens claims {SCHOOL, STATE_BOARD_EDUCATION}, local dropped SCHOOL, 8 topics grouped. Topics remain STAGED until pinned to a season.';
END $$;

COMMIT;
