BEGIN;

-- =============================================================================
-- CA_0011: Compass content revisions — additive tables only
-- =============================================================================
-- Implements ADR 0004 §1–§6 (docs/adr/0004-compass-content-versioning.md), the
-- schema half. PURELY ADDITIVE: no existing table is altered, no data moves, no
-- read path changes. A DROP of these four objects reverts it completely.
--
-- Supersedes the migration-061 rewrite workflow, which is still present and
-- still holds 0 rows. 061 is NOT dropped here — that happens only after the
-- read path has moved (ADR 0004, migration path step 5).
--
-- The backfill is CA_0012. This migration deliberately leaves the tables empty
-- so that "create the shape" and "interpret 44 existing topics" are separately
-- reviewable and separately revertible.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- Section 1: Enums
-- ---------------------------------------------------------------------------
-- change_class drives TWO things, and they must not be conflated:
--   * whether `version` bumps (substantive only)
--   * whether a stale-answer notice fires for users (ADR §10 — version gap only)
-- 'clarifying' exists for a change that alters wording enough to be worth
-- reading but not enough to invalidate an answer. It does NOT bump `version`.
-- ---------------------------------------------------------------------------

DO $$ BEGIN
  CREATE TYPE inform.change_class AS ENUM ('editorial', 'clarifying', 'substantive');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE inform.revision_status AS ENUM (
    'draft',       -- written by an author's tooling; NOT publicly readable
    'approved',    -- signed off by a Compass Stance Editor, not yet live
    'published',   -- has been live at some point; publicly readable forever
    'superseded',  -- was published, a later revision took over as current
    'rejected'     -- died in review; retained so the record shows what was refused
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ---------------------------------------------------------------------------
-- Section 2: rung_map validator
-- ---------------------------------------------------------------------------
-- ADR 0004 left the shape loose ("identity | {"1":2,...} | invalidated"). Pinned
-- here to ONE representation, because two spellings of the same fact is how the
-- compass-topics-reference file drifted (migrations 1729/1730).
--
-- Shape: a JSONB object with exactly the five keys '1'..'5', one per rung of the
-- PRIOR ladder. Each value is either
--   * an integer 1..5  — an answer at this old rung becomes that new rung
--                        (an unchanged ladder is therefore {"1":1,...,"5":5})
--   * "invalidated"    — the old rung has no successor; blank the answer
--
-- There is no 'identity' shorthand: the object is always written out in full, so
-- reading a rung's disposition never requires knowing a special case.
--
-- NULL means "no mapping applies" and is legal in exactly two situations:
--   * revision 1 of a topic — there is no prior ladder to map from
--   * a revision whose ladder text is byte-identical to its predecessor
-- Both are asserted by the RPC that writes revisions, not here; a CHECK cannot
-- see the predecessor row.
--
-- A CHECK constraint cannot contain a subquery, so this must be a function.
-- Caveat accepted: a function-backed CHECK is restored after its function by
-- pg_dump, which is correct, but the dependency is invisible in the table DDL.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.is_valid_rung_map(p_map JSONB)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $$
  -- 🔴 CASE, not a chain of ANDs, ON PURPOSE. jsonb_object_keys() RAISES on a
  -- scalar ('"identity"'::jsonb), so the type guard must be evaluated BEFORE the
  -- key count. An AND chain happened to short-circuit when tested against prod on
  -- 2026-08-21 — but Postgres does not guarantee evaluation order for AND, and the
  -- plan can differ once this is inlined into a CHECK over a populated column.
  -- CASE is documented to evaluate its WHEN clauses in order. Do not "simplify".
  SELECT CASE
    WHEN p_map IS NULL                    THEN true
    WHEN jsonb_typeof(p_map) <> 'object'  THEN false
    WHEN (SELECT count(*) FROM jsonb_object_keys(p_map)) <> 5 THEN false
    WHEN EXISTS (
      SELECT 1 FROM jsonb_object_keys(p_map) AS k
      WHERE k NOT IN ('1', '2', '3', '4', '5')
    ) THEN false
    WHEN EXISTS (
      SELECT 1 FROM jsonb_each(p_map) AS e
      WHERE NOT (
        -- '^[1-5]$' also rejects 1.5 and 0, which a BETWEEN cast would accept or error on.
        (jsonb_typeof(e.value) = 'number' AND (e.value #>> '{}') ~ '^[1-5]$')
        OR (jsonb_typeof(e.value) = 'string' AND (e.value #>> '{}') = 'invalidated')
      )
    ) THEN false
    ELSE true
  END;
$$;

COMMENT ON FUNCTION inform.is_valid_rung_map(JSONB) IS
  'ADR 0004 §4. Validates a rung mapping: exactly keys 1-5, each value an int 1-5 or the string "invalidated". NULL is valid (revision 1, or an unchanged ladder).';


-- ---------------------------------------------------------------------------
-- Section 3: compass_topic_revisions
-- ---------------------------------------------------------------------------
-- Append-only. Nothing in this table is ever UPDATEd except `status` and
-- `is_current` (lifecycle) — the CONTENT columns are immutable once written.
-- That is enforced by a trigger in Section 6, not by convention.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_topic_revisions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id       UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,

  -- Two-level identity (ADR §3). revision bumps on EVERY write; version only on
  -- 'substantive'. Both are public — version is the citable milestone.
  revision       INT  NOT NULL CHECK (revision >= 1),
  version        INT  NOT NULL CHECK (version  >= 1),
  change_class   inform.change_class NOT NULL,

  -- Content snapshot. Never a diff: a stored diff cannot render a prior version
  -- without replaying the chain (ADR §9).
  title          TEXT NOT NULL CHECK (btrim(title) <> ''),
  short_title    TEXT,
  question_text  TEXT NOT NULL CHECK (btrim(question_text) <> ''),

  -- Reasoning (ADR §6). Two fields on purpose: one candid, one publishable.
  rationale      TEXT NOT NULL CHECK (btrim(rationale)   <> ''),  -- internal, never served
  public_note    TEXT NOT NULL CHECK (btrim(public_note) <> ''),  -- reader-facing edit summary
  review_ref     TEXT,                                            -- Doc / Slack / PR URL

  rung_map       JSONB CONSTRAINT compass_topic_revisions_rung_map_shape
                   CHECK (inform.is_valid_rung_map(rung_map)),

  status         inform.revision_status NOT NULL DEFAULT 'draft',
  is_current     BOOLEAN NOT NULL DEFAULT false,

  proposed_by    UUID REFERENCES public.users(id),
  proposed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_by    UUID REFERENCES public.users(id),
  approved_at    TIMESTAMPTZ,
  published_by   UUID REFERENCES public.users(id),
  published_at   TIMESTAMPTZ,

  CONSTRAINT compass_topic_revisions_topic_revision_uniq UNIQUE (topic_id, revision),

  -- A draft can never be the revision users are served.
  CONSTRAINT compass_topic_revisions_current_is_published
    CHECK (NOT is_current OR status = 'published'),

  -- Lifecycle timestamps must accompany their state, not trail it.
  CONSTRAINT compass_topic_revisions_published_stamped
    CHECK (status NOT IN ('published', 'superseded') OR published_at IS NOT NULL),
  CONSTRAINT compass_topic_revisions_approved_stamped
    CHECK ((approved_by IS NULL) = (approved_at IS NULL))
);

-- Exactly one current revision per topic. Same mechanism as the existing
-- partial unique on compass_topics(topic_key) WHERE is_live, which works.
CREATE UNIQUE INDEX IF NOT EXISTS compass_topic_revisions_one_current
  ON inform.compass_topic_revisions (topic_id) WHERE is_current;

-- The public record reads newest-first per topic.
CREATE INDEX IF NOT EXISTS compass_topic_revisions_topic_rev_desc
  ON inform.compass_topic_revisions (topic_id, revision DESC);

-- The review queue reads by state.
CREATE INDEX IF NOT EXISTS compass_topic_revisions_status
  ON inform.compass_topic_revisions (status)
  WHERE status IN ('draft', 'approved');

COMMENT ON TABLE inform.compass_topic_revisions IS
  'ADR 0004. Append-only content revisions of a compass topic. inform.compass_topics is immutable identity; this holds every version of its prose. Content columns are immutable once written (trigger); only status/is_current change.';


-- ---------------------------------------------------------------------------
-- Section 4: compass_stance_revisions
-- ---------------------------------------------------------------------------
-- The ladder belongs to a TOPIC REVISION, not to a topic (ADR §2): a rung's
-- meaning is relational, so the five rungs version as one unit.
--
-- Nothing FKs inform.compass_stances today (verified 2026-08-21), which is why
-- this can be a clean parallel table rather than a migration of that one.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_stance_revisions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_revision_id    UUID NOT NULL
                         REFERENCES inform.compass_topic_revisions(id) ON DELETE CASCADE,
  value                INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  text                 TEXT NOT NULL CHECK (btrim(text) <> ''),
  description          TEXT,
  supporting_points    TEXT[] NOT NULL DEFAULT '{}',
  example_perspectives TEXT[] NOT NULL DEFAULT '{}',

  CONSTRAINT compass_stance_revisions_rev_value_uniq UNIQUE (topic_revision_id, value)
);

CREATE INDEX IF NOT EXISTS compass_stance_revisions_rev
  ON inform.compass_stance_revisions (topic_revision_id, value);

COMMENT ON TABLE inform.compass_stance_revisions IS
  'ADR 0004 §2. The five-rung ladder for one topic revision. Rungs never version independently — rung meaning is relational, fixed by contrast with its neighbours.';


-- ---------------------------------------------------------------------------
-- Section 5: Row-level security
-- ---------------------------------------------------------------------------
-- 🔴 NOT specified by ADR 0004, decided here: the public record is
-- anonymous-readable, but a DRAFT is unapproved content and must never leak.
-- 'rejected' is likewise withheld — publishing wording the team refused would
-- misrepresent it as something we considered saying.
--
-- So public read is gated on status, matching the existing
-- "compass_topics: public read" / "compass_stances: public read" policy shape
-- but with a predicate instead of `true`.
--
-- Admin and service paths read everything via service_role, which bypasses RLS.
-- No INSERT/UPDATE/DELETE policies: all writes go through SECURITY DEFINER RPCs,
-- exactly as compass_responses does today.
-- ---------------------------------------------------------------------------

ALTER TABLE inform.compass_topic_revisions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_stance_revisions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "compass_topic_revisions: public read published"
  ON inform.compass_topic_revisions;
CREATE POLICY "compass_topic_revisions: public read published"
  ON inform.compass_topic_revisions
  FOR SELECT TO anon, authenticated
  USING (status IN ('published', 'superseded'));

DROP POLICY IF EXISTS "compass_stance_revisions: public read published"
  ON inform.compass_stance_revisions;
CREATE POLICY "compass_stance_revisions: public read published"
  ON inform.compass_stance_revisions
  FOR SELECT TO anon, authenticated
  USING (EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions r
    WHERE r.id = compass_stance_revisions.topic_revision_id
      AND r.status IN ('published', 'superseded')
  ));

GRANT SELECT ON inform.compass_topic_revisions  TO anon, authenticated;
GRANT SELECT ON inform.compass_stance_revisions TO anon, authenticated;


-- ---------------------------------------------------------------------------
-- Section 6: Immutability trigger
-- ---------------------------------------------------------------------------
-- "Append-only" is the load-bearing property of this whole design — it is the
-- only reason a prior revision is trustworthy to serve, and in-place editing is
-- what deleted the v1 rows of six live topics in April 2026. A convention will
-- not hold that line across future migrations written under time pressure.
--
-- So: content columns are physically immutable. Only lifecycle columns move.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.compass_topic_revisions_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.topic_id     IS DISTINCT FROM OLD.topic_id
  OR NEW.revision     IS DISTINCT FROM OLD.revision
  OR NEW.version      IS DISTINCT FROM OLD.version
  OR NEW.change_class IS DISTINCT FROM OLD.change_class
  OR NEW.title        IS DISTINCT FROM OLD.title
  OR NEW.short_title  IS DISTINCT FROM OLD.short_title
  OR NEW.question_text IS DISTINCT FROM OLD.question_text
  OR NEW.rationale    IS DISTINCT FROM OLD.rationale
  OR NEW.public_note  IS DISTINCT FROM OLD.public_note
  OR NEW.rung_map     IS DISTINCT FROM OLD.rung_map
  OR NEW.proposed_by  IS DISTINCT FROM OLD.proposed_by
  OR NEW.proposed_at  IS DISTINCT FROM OLD.proposed_at
  THEN
    RAISE EXCEPTION
      'IMMUTABLE_REVISION: content of compass_topic_revisions % cannot be edited (ADR 0004 §3). Write a new revision instead.',
      OLD.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS compass_topic_revisions_no_content_edits
  ON inform.compass_topic_revisions;
CREATE TRIGGER compass_topic_revisions_no_content_edits
  BEFORE UPDATE ON inform.compass_topic_revisions
  FOR EACH ROW EXECUTE FUNCTION inform.compass_topic_revisions_immutable();

-- A published ladder is likewise frozen. Editing a rung in place would silently
-- change what every answer indexing into it means.
CREATE OR REPLACE FUNCTION inform.compass_stance_revisions_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_status inform.revision_status;
BEGIN
  SELECT status INTO v_status
  FROM inform.compass_topic_revisions
  WHERE id = COALESCE(OLD.topic_revision_id, NEW.topic_revision_id);

  IF v_status IN ('published', 'superseded') THEN
    RAISE EXCEPTION
      'IMMUTABLE_LADDER: rungs of a published topic revision cannot be changed (ADR 0004 §2/§3). Write a new revision instead.';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS compass_stance_revisions_no_published_edits
  ON inform.compass_stance_revisions;
CREATE TRIGGER compass_stance_revisions_no_published_edits
  BEFORE UPDATE OR DELETE ON inform.compass_stance_revisions
  FOR EACH ROW EXECUTE FUNCTION inform.compass_stance_revisions_immutable();


-- ---------------------------------------------------------------------------
-- Section 7: Post-verify gate
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_missing TEXT[] := '{}';
  v_bad     TEXT;
BEGIN
  -- Objects exist
  IF to_regclass('inform.compass_topic_revisions')  IS NULL THEN v_missing := v_missing || 'compass_topic_revisions'; END IF;
  IF to_regclass('inform.compass_stance_revisions') IS NULL THEN v_missing := v_missing || 'compass_stance_revisions'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE n.nspname='inform' AND t.typname='change_class') THEN v_missing := v_missing || 'change_class'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE n.nspname='inform' AND t.typname='revision_status') THEN v_missing := v_missing || 'revision_status'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='inform'
                 AND indexname='compass_topic_revisions_one_current') THEN v_missing := v_missing || 'one_current index'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='compass_topic_revisions_no_content_edits'
                 AND NOT tgisinternal) THEN v_missing := v_missing || 'immutability trigger'; END IF;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'CA_0011 INCOMPLETE: missing %', array_to_string(v_missing, ', ');
  END IF;

  -- Tables must be EMPTY: the backfill is CA_0012, deliberately separate.
  IF (SELECT count(*) FROM inform.compass_topic_revisions) <> 0 THEN
    RAISE EXCEPTION 'CA_0011: compass_topic_revisions is not empty — CA_0012 may already have run';
  END IF;

  -- rung_map validator: the 17 cases proved read-only against prod on 2026-08-21.
  -- The scalar and array cases are the ones that matter — they are what RAISE if
  -- the type guard is ever moved after the key count. See the note on the function.
  SELECT string_agg(c.label, ', ')
    INTO v_bad
  FROM (VALUES
    ('NULL',              NULL::jsonb,                                        true),
    ('identity map',      '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb,           true),
    ('one invalidated',   '{"1":1,"2":2,"3":"invalidated","4":4,"5":5}'::jsonb, true),
    ('collapse 2 and 3',  '{"1":1,"2":2,"3":2,"4":3,"5":4}'::jsonb,           true),
    ('all invalidated',   '{"1":"invalidated","2":"invalidated","3":"invalidated","4":"invalidated","5":"invalidated"}'::jsonb, true),
    ('only four keys',    '{"1":1,"2":2,"3":3,"4":4}'::jsonb,                 false),
    ('six keys',          '{"1":1,"2":2,"3":3,"4":4,"5":5,"6":1}'::jsonb,     false),
    ('rung 6 target',     '{"1":1,"2":2,"3":3,"4":4,"5":6}'::jsonb,           false),
    ('rung 0 target',     '{"1":0,"2":2,"3":3,"4":4,"5":5}'::jsonb,           false),
    ('key 0',             '{"0":1,"2":2,"3":3,"4":4,"5":5}'::jsonb,           false),
    ('bad string value',  '{"1":1,"2":2,"3":"dunno","4":4,"5":5}'::jsonb,     false),
    ('null value',        '{"1":1,"2":2,"3":null,"4":4,"5":5}'::jsonb,        false),
    ('float target',      '{"1":1.5,"2":2,"3":3,"4":4,"5":5}'::jsonb,         false),
    ('nested object',     '{"1":{"a":1},"2":2,"3":3,"4":4,"5":5}'::jsonb,     false),
    ('scalar shorthand',  '"identity"'::jsonb,                                false),
    ('array',             '[1,2,3,4,5]'::jsonb,                               false),
    ('empty object',      '{}'::jsonb,                                        false)
  ) AS c(label, m, expected)
  WHERE inform.is_valid_rung_map(c.m) IS DISTINCT FROM c.expected;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0011: is_valid_rung_map is wrong on: %', v_bad;
  END IF;

  RAISE NOTICE 'CA_0011 OK — revision tables created empty, rung_map validator passes all 17 cases.';
END $$;

COMMIT;
