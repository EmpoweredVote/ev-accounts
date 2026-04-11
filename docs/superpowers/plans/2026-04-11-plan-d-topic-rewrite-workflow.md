# Plan D — Topic Rewrite Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build admin-facing machinery that lets Chris rewrite a compass topic's framing and stance scale without silently invalidating every politician's existing stance — enforcing a two-gate human review workflow (framing review, then per-stance re-evaluation) before any new version goes live.

**Architecture:** A new `inform.topic_rewrites` table tracks the workflow state machine (`draft → pending_framing_review → re_evaluation_queue → publish_ready → published`) and links an `old_topic_id` to a `new_topic_id` in `inform.compass_topics`. Per-politician stance proposals live in `inform.topic_rewrite_stance_proposals`, each with its own `pending/approved/rejected` status. The existing `compass_topics` unique index is relaxed from `UNIQUE(topic_key)` to `UNIQUE(topic_key, version)` plus a partial `UNIQUE(topic_key) WHERE is_live = true`, so draft and live versions can coexist. Publish is a single transactional RPC that (a) inserts approved proposals into `politician_answers`/`politician_context` against the new `topic_id`, (b) flips `is_live` on the new row to `true`, (c) flips `is_live` on the old row to `false`, (d) marks the rewrite row `published`. Old answers remain referencing the old (now is_live=false) topic row — append-only, no destructive updates.

**Tech Stack:** Node.js 20 + TypeScript + Express + Zod (ev-accounts backend), Supabase PostgreSQL + PostgREST RPCs (`adminRpc`), React 19 + Vite + Tailwind 4 (CompassV2 admin UI), Vitest (backend tests — CI-safe 401 enforcement pattern, consistent with `tests/integration/admin-compass.test.ts`).

**Out of scope per spec:** No actual topic rewrites shipped in this plan. No autonomous agents — a proposed-value editor field is enough; Chris can run `research-stances` externally and paste results. No voter-facing changes.

---

## File Structure

**Backend (ev-accounts/backend, committed to `master` of the inner `ev-accounts` repo):**

- Create: `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql` — schema + constraints + RPCs (state machine transitions + atomic publish).
- Create: `ev-accounts/backend/src/lib/topicRewriteService.ts` — thin service wrappers around the RPCs; all business logic lives in SQL for atomicity.
- Create: `ev-accounts/backend/src/routes/topicRewrites.ts` — Express router mounted at `/api/admin/topic-rewrites`, all admin-gated.
- Modify: `ev-accounts/backend/src/index.ts` — wire the new router after `adminRouter`.
- Create: `ev-accounts/tests/integration/topic-rewrites.test.ts` — 401 enforcement tests, matching `admin-compass.test.ts` pattern.

**Frontend (CompassV2, standalone repo — commits go to CompassV2 `main`):**

- Create: `CompassV2/src/lib/topicRewriteApi.js` — typed fetchers for the new endpoints, using the existing `API_BASE_URL` + admin JWT auth pattern.
- Create: `CompassV2/src/components/admin/TopicRewriteWorkflow.jsx` — single page with three sub-views (list / framing gate / re-evaluation queue), rendered inside `AdminDashboard` via a new tab.
- Modify: `CompassV2/src/components/admin/AdminDashboard.jsx` — add a "Rewrite Workflow" tab entry that mounts `<TopicRewriteWorkflow />`.

**Monorepo-level (spec/plan only):**

- Modify (commit at end): `docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md` — this plan document itself, committed up front so Plan D is reproducible.

---

## Pre-flight checks (must pass before Task 1)

Run each and confirm before proceeding. Do **not** skip.

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
ls migrations/ | tail -5
# Expected: highest migration number is 060_chambers_slug.sql. Next number is 061.

# Confirm the schema shape assumed by the plan:
set -a && source .env && set +a
node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT column_name, data_type, is_nullable, column_default
  FROM information_schema.columns
  WHERE table_schema='inform' AND table_name='compass_topics'
    AND column_name IN ('id','topic_key','version','is_live','went_live_at')
  ORDER BY column_name;
\`);
console.log(rows);
await pool.end();
"
# Expected: all 5 columns present. topic_key text not null, version int default 1, is_live bool, went_live_at timestamptz nullable.

# Confirm existing unique constraint is on topic_key alone (we need to relax it):
node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT indexname, indexdef FROM pg_indexes
  WHERE schemaname='inform' AND tablename='compass_topics';
\`);
console.log(rows);
await pool.end();
"
# Expected: idx_compass_topics_topic_key is UNIQUE on (topic_key).
```

If any expectation fails, **stop and report** — the plan assumptions are wrong and need updating before any code is written.

---

### Task 1: Migration 061 — schema foundations + relaxed uniqueness

**Files:**
- Create: `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql`

**Intent:** Relax the existing unique index on `compass_topics.topic_key`, add a `(topic_key, version)` unique index, add a partial unique on `topic_key WHERE is_live = true` (enforces "one live version per key"), and create the two new tables for the rewrite state machine and per-stance proposals. No RPCs yet — those come in Task 2.

- [ ] **Step 1: Write the migration file**

Create `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql` with exactly this content:

```sql
BEGIN;

-- =============================================================================
-- Migration 061: Topic Rewrite Workflow
-- =============================================================================
-- Adds the machinery to safely rewrite a compass topic's framing and stance
-- scale by enforcing two human review gates (framing review, then per-stance
-- re-evaluation). See:
--   docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md
--   docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: Relax the unique index on compass_topics.topic_key
-- ---------------------------------------------------------------------------
-- The current idx_compass_topics_topic_key is UNIQUE on (topic_key) alone,
-- which makes it impossible to stage a new version alongside the live one.
-- Replace with:
--   * UNIQUE (topic_key, version) — each version of a topic is distinct
--   * Partial UNIQUE (topic_key) WHERE is_live = true — only one live version
-- ---------------------------------------------------------------------------

DROP INDEX IF EXISTS inform.idx_compass_topics_topic_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_compass_topics_topic_key_version
  ON inform.compass_topics (topic_key, version);

CREATE UNIQUE INDEX IF NOT EXISTS idx_compass_topics_topic_key_live
  ON inform.compass_topics (topic_key)
  WHERE is_live = true;

-- ---------------------------------------------------------------------------
-- Section 2: topic_rewrites — the state machine row, one per rewrite attempt
-- ---------------------------------------------------------------------------

DO $$ BEGIN
  CREATE TYPE inform.topic_rewrite_state AS ENUM (
    'draft',
    'pending_framing_review',
    're_evaluation_queue',
    'publish_ready',
    'published',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS inform.topic_rewrites (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_key        TEXT NOT NULL,
  old_topic_id     UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,
  new_topic_id     UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,
  state            inform.topic_rewrite_state NOT NULL DEFAULT 'draft',
  created_by       UUID REFERENCES public.users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  framing_approved_by   UUID REFERENCES public.users(id),
  framing_approved_at   TIMESTAMPTZ,
  published_by     UUID REFERENCES public.users(id),
  published_at     TIMESTAMPTZ,
  notes            TEXT
);

-- At most one open rewrite per topic_key (rows in states other than
-- 'published' and 'cancelled'). Prevents parallel rewrites colliding.
CREATE UNIQUE INDEX IF NOT EXISTS idx_topic_rewrites_open_per_key
  ON inform.topic_rewrites (topic_key)
  WHERE state NOT IN ('published', 'cancelled');

CREATE INDEX IF NOT EXISTS idx_topic_rewrites_state
  ON inform.topic_rewrites (state);

-- ---------------------------------------------------------------------------
-- Section 3: topic_rewrite_stance_proposals — per-politician proposed values
-- ---------------------------------------------------------------------------
-- One row per (rewrite_id, politician_id). Seeded from the set of politicians
-- that have an existing politician_answers row for old_topic_id. Each proposal
-- carries the old snapshot (value + reasoning + sources) so the admin UI can
-- render side-by-side without another JOIN.
-- ---------------------------------------------------------------------------

DO $$ BEGIN
  CREATE TYPE inform.stance_proposal_status AS ENUM (
    'pending',
    'approved',
    'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS inform.topic_rewrite_stance_proposals (
  rewrite_id         UUID NOT NULL REFERENCES inform.topic_rewrites(id) ON DELETE CASCADE,
  politician_id      UUID NOT NULL REFERENCES inform.politicians(id) ON DELETE CASCADE,

  -- Snapshot of the stance under the OLD framing (copied at seed time)
  old_value          INT NOT NULL CHECK (old_value BETWEEN 1 AND 5),
  old_reasoning      TEXT,
  old_sources        TEXT[] NOT NULL DEFAULT '{}',

  -- Proposed stance under the NEW framing (editable until approved)
  proposed_value     NUMERIC CHECK (proposed_value IS NULL OR proposed_value BETWEEN 1 AND 5),
  proposed_reasoning TEXT,
  proposed_sources   TEXT[] NOT NULL DEFAULT '{}',

  status             inform.stance_proposal_status NOT NULL DEFAULT 'pending',
  reviewed_by        UUID REFERENCES public.users(id),
  reviewed_at        TIMESTAMPTZ,
  reviewer_notes     TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  PRIMARY KEY (rewrite_id, politician_id)
);

CREATE INDEX IF NOT EXISTS idx_stance_proposals_status
  ON inform.topic_rewrite_stance_proposals (rewrite_id, status);

COMMIT;
```

- [ ] **Step 2: Stage the migration file**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/migrations/061_topic_rewrite_workflow.sql
git status
```

Expected: one new file staged.

- [ ] **Step 3: Commit**

```bash
git commit -m "migration(061): topic rewrite workflow schema

Relax compass_topics.topic_key unique constraint to (topic_key, version)
plus partial unique on is_live=true. Add inform.topic_rewrites state
machine table and inform.topic_rewrite_stance_proposals for per-politician
proposed values. RPCs land in the next commit."
```

Do **not** apply this migration to the database yet — that happens in Task 9 after the RPCs are added and the backend is wired up.

---

### Task 2: Migration 061 addendum — create_rewrite RPC + framing gate RPC

**Files:**
- Modify: `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql` (append)

**Intent:** Add two RPC functions to migration 061: `admin_create_topic_rewrite` (creates the draft `compass_topics` row + `topic_rewrites` row atomically) and `admin_approve_rewrite_framing` (transitions state from `pending_framing_review` → `re_evaluation_queue` and seeds `topic_rewrite_stance_proposals` from `politician_answers` + `politician_context` of the old topic).

- [ ] **Step 1: Append the RPCs to the existing migration file**

Open `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql` and append the following **before** the `COMMIT;` line (move the `COMMIT;` to the end):

```sql
-- ---------------------------------------------------------------------------
-- Section 4: admin_create_topic_rewrite
-- ---------------------------------------------------------------------------
-- Takes a topic_key plus the proposed new framing. Creates a new row in
-- compass_topics with version = old_version + 1, is_live = false, and an
-- accompanying topic_rewrites row in state 'draft'. Also copies the stance
-- scale into compass_stances so the new version is independently editable.
-- Returns the new rewrite_id.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_create_topic_rewrite(
  p_topic_key      TEXT,
  p_actor_id       UUID,
  p_new_title      TEXT,
  p_new_short_title TEXT,
  p_new_question_text TEXT,
  p_new_stances    JSONB,  -- array of {value: int, text: text}
  p_notes          TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_topic    inform.compass_topics%ROWTYPE;
  v_new_topic_id UUID;
  v_rewrite_id   UUID;
  v_stance       JSONB;
BEGIN
  -- Find the current live version
  SELECT * INTO v_old_topic
  FROM inform.compass_topics
  WHERE topic_key = p_topic_key AND is_live = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_LIVE_TOPIC: topic_key % has no live version', p_topic_key;
  END IF;

  -- Guard: disallow if there is already an open rewrite for this topic_key
  IF EXISTS (
    SELECT 1 FROM inform.topic_rewrites
    WHERE topic_key = p_topic_key
      AND state NOT IN ('published', 'cancelled')
  ) THEN
    RAISE EXCEPTION 'OPEN_REWRITE_EXISTS: an open rewrite already exists for %', p_topic_key;
  END IF;

  -- Insert the new topic version (is_live=false, version bumped)
  INSERT INTO inform.compass_topics (
    topic_key, title, short_title, question_text,
    is_live, version, went_live_at
  ) VALUES (
    p_topic_key, p_new_title, p_new_short_title, p_new_question_text,
    false, v_old_topic.version + 1, NULL
  )
  RETURNING id INTO v_new_topic_id;

  -- Copy the proposed stance scale into compass_stances for the new topic id
  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_new_stances)
  LOOP
    INSERT INTO inform.compass_stances (topic_id, value, text)
    VALUES (
      v_new_topic_id,
      (v_stance->>'value')::int,
      v_stance->>'text'
    );
  END LOOP;

  -- Create the rewrite row in 'draft' state
  INSERT INTO inform.topic_rewrites (
    topic_key, old_topic_id, new_topic_id, state, created_by, notes
  ) VALUES (
    p_topic_key, v_old_topic.id, v_new_topic_id, 'draft', p_actor_id, p_notes
  )
  RETURNING id INTO v_rewrite_id;

  RETURN v_rewrite_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 5: admin_submit_rewrite_for_framing_review
-- ---------------------------------------------------------------------------
-- State transition: draft → pending_framing_review.
-- No-op for the data; just gates the next step.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_submit_rewrite_for_framing_review(
  p_rewrite_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrites
  SET state = 'pending_framing_review'
  WHERE id = p_rewrite_id AND state = 'draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % is not in draft state', p_rewrite_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 6: admin_approve_rewrite_framing
-- ---------------------------------------------------------------------------
-- State transition: pending_framing_review → re_evaluation_queue.
-- Also seeds topic_rewrite_stance_proposals with one row per politician that
-- has an existing politician_answers row on the OLD topic. Each seed row
-- copies the old value/reasoning/sources and leaves proposed_* NULL.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_approve_rewrite_framing(
  p_rewrite_id UUID,
  p_actor_id   UUID
)
RETURNS INT  -- number of stance proposals seeded
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rewrite       inform.topic_rewrites%ROWTYPE;
  v_seeded_count  INT;
BEGIN
  SELECT * INTO v_rewrite FROM inform.topic_rewrites WHERE id = p_rewrite_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;

  IF v_rewrite.state <> 'pending_framing_review' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in pending_framing_review (is %)',
      p_rewrite_id, v_rewrite.state;
  END IF;

  -- Seed proposals from politician_answers joined with politician_context
  INSERT INTO inform.topic_rewrite_stance_proposals (
    rewrite_id, politician_id, old_value, old_reasoning, old_sources
  )
  SELECT
    p_rewrite_id,
    pa.politician_id,
    pa.value,
    COALESCE(pc.reasoning, ''),
    COALESCE(pc.sources, '{}')
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id
   AND pc.topic_id = pa.topic_id
  WHERE pa.topic_id = v_rewrite.old_topic_id;

  GET DIAGNOSTICS v_seeded_count = ROW_COUNT;

  UPDATE inform.topic_rewrites
  SET state = 're_evaluation_queue',
      framing_approved_by = p_actor_id,
      framing_approved_at = now()
  WHERE id = p_rewrite_id;

  RETURN v_seeded_count;
END;
$$;
```

- [ ] **Step 2: Commit the RPC addition**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/migrations/061_topic_rewrite_workflow.sql
git commit -m "migration(061): add create/submit/approve-framing RPCs

admin_create_topic_rewrite stages a new compass_topics row + copies the
new stance scale + creates a draft topic_rewrites row atomically.
admin_submit_rewrite_for_framing_review flips draft → pending.
admin_approve_rewrite_framing seeds per-politician stance proposal rows
from the old topic's answers+context and flips to re_evaluation_queue."
```

---

### Task 3: Migration 061 addendum — proposal upsert + approve/reject RPCs

**Files:**
- Modify: `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql` (append)

**Intent:** RPCs for Chris to edit proposed stance values/reasoning, approve a proposal, reject a proposal, and transition the whole rewrite to `publish_ready` once every proposal is decided (approved OR rejected).

- [ ] **Step 1: Append the RPCs before COMMIT**

```sql
-- ---------------------------------------------------------------------------
-- Section 7: admin_upsert_stance_proposal
-- ---------------------------------------------------------------------------
-- Used by the admin UI to write proposed_value / proposed_reasoning /
-- proposed_sources. Does NOT change status — that requires explicit approve.
-- Only valid while the proposal is still 'pending'.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_upsert_stance_proposal(
  p_rewrite_id   UUID,
  p_politician_id UUID,
  p_proposed_value NUMERIC,
  p_proposed_reasoning TEXT,
  p_proposed_sources TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrite_stance_proposals
  SET proposed_value     = p_proposed_value,
      proposed_reasoning = p_proposed_reasoning,
      proposed_sources   = COALESCE(p_proposed_sources, '{}'),
      updated_at         = now()
  WHERE rewrite_id = p_rewrite_id
    AND politician_id = p_politician_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND_OR_LOCKED: proposal (%, %) is missing or already decided',
      p_rewrite_id, p_politician_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 8: admin_approve_stance_proposal / admin_reject_stance_proposal
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_approve_stance_proposal(
  p_rewrite_id    UUID,
  p_politician_id UUID,
  p_actor_id      UUID,
  p_reviewer_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrite_stance_proposals
  SET status         = 'approved',
      reviewed_by    = p_actor_id,
      reviewed_at    = now(),
      reviewer_notes = p_reviewer_notes,
      updated_at     = now()
  WHERE rewrite_id = p_rewrite_id
    AND politician_id = p_politician_id
    AND status = 'pending'
    AND proposed_value IS NOT NULL;  -- cannot approve an empty proposal

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID: proposal (%, %) missing, already decided, or has no proposed_value',
      p_rewrite_id, p_politician_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION inform.admin_reject_stance_proposal(
  p_rewrite_id    UUID,
  p_politician_id UUID,
  p_actor_id      UUID,
  p_reviewer_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrite_stance_proposals
  SET status         = 'rejected',
      reviewed_by    = p_actor_id,
      reviewed_at    = now(),
      reviewer_notes = p_reviewer_notes,
      updated_at     = now()
  WHERE rewrite_id = p_rewrite_id
    AND politician_id = p_politician_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID: proposal (%, %) missing or already decided',
      p_rewrite_id, p_politician_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 9: admin_mark_rewrite_publish_ready
-- ---------------------------------------------------------------------------
-- State transition: re_evaluation_queue → publish_ready.
-- Only allowed when every proposal has status IN ('approved','rejected').
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_mark_rewrite_publish_ready(
  p_rewrite_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_pending_count INT;
  v_state         inform.topic_rewrite_state;
BEGIN
  SELECT state INTO v_state FROM inform.topic_rewrites WHERE id = p_rewrite_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;

  IF v_state <> 're_evaluation_queue' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in re_evaluation_queue (is %)',
      p_rewrite_id, v_state;
  END IF;

  SELECT count(*) INTO v_pending_count
  FROM inform.topic_rewrite_stance_proposals
  WHERE rewrite_id = p_rewrite_id AND status = 'pending';

  IF v_pending_count > 0 THEN
    RAISE EXCEPTION 'PROPOSALS_PENDING: % proposals still need review', v_pending_count;
  END IF;

  UPDATE inform.topic_rewrites
  SET state = 'publish_ready'
  WHERE id = p_rewrite_id;
END;
$$;
```

- [ ] **Step 2: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/migrations/061_topic_rewrite_workflow.sql
git commit -m "migration(061): add stance proposal upsert/approve/reject + publish_ready RPCs"
```

---

### Task 4: Migration 061 addendum — atomic publish RPC

**Files:**
- Modify: `ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql` (append)

**Intent:** The publish step. Must be atomic: (1) write approved proposals into `politician_answers` and `politician_context` under the **new** `topic_id`, (2) flip `is_live=true` on the new topic row and set `went_live_at`, (3) flip `is_live=false` on the old topic row, (4) mark the rewrite `published`. All in a single SQL function (implicit transaction).

- [ ] **Step 1: Append the publish RPC**

```sql
-- ---------------------------------------------------------------------------
-- Section 10: admin_publish_topic_rewrite
-- ---------------------------------------------------------------------------
-- Atomic publish. Copies approved stance proposals to politician_answers and
-- politician_context under the NEW topic_id, flips is_live on new and old
-- topic rows, marks the rewrite as published. Append-only: no DELETE on old
-- politician_answers/politician_context rows — they stay referencing the old
-- (now is_live=false) topic version for audit.
--
-- Rejected proposals do NOT get their values copied forward. Those politicians
-- end up with no answer on the new topic until someone manually re-researches.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_publish_topic_rewrite(
  p_rewrite_id UUID,
  p_actor_id   UUID
)
RETURNS JSONB  -- { approved_copied: int, rejected_skipped: int }
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rewrite           inform.topic_rewrites%ROWTYPE;
  v_approved_count    INT;
  v_rejected_count    INT;
BEGIN
  SELECT * INTO v_rewrite FROM inform.topic_rewrites WHERE id = p_rewrite_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;

  IF v_rewrite.state <> 'publish_ready' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in publish_ready (is %)',
      p_rewrite_id, v_rewrite.state;
  END IF;

  -- Copy approved proposals into politician_answers (NEW topic id)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT p.politician_id, v_rewrite.new_topic_id, round(p.proposed_value)::int
  FROM inform.topic_rewrite_stance_proposals p
  WHERE p.rewrite_id = p_rewrite_id AND p.status = 'approved'
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET value = EXCLUDED.value;

  GET DIAGNOSTICS v_approved_count = ROW_COUNT;

  -- Copy approved proposals into politician_context
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT p.politician_id, v_rewrite.new_topic_id,
         COALESCE(p.proposed_reasoning, ''),
         COALESCE(p.proposed_sources, '{}')
  FROM inform.topic_rewrite_stance_proposals p
  WHERE p.rewrite_id = p_rewrite_id AND p.status = 'approved'
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning,
        sources   = EXCLUDED.sources;

  SELECT count(*) INTO v_rejected_count
  FROM inform.topic_rewrite_stance_proposals
  WHERE rewrite_id = p_rewrite_id AND status = 'rejected';

  -- Atomic swap: flip new live first, then old off.
  -- The partial unique on is_live=true prevents two-live windows even on error.
  UPDATE inform.compass_topics
  SET is_live = false
  WHERE id = v_rewrite.old_topic_id;

  UPDATE inform.compass_topics
  SET is_live = true,
      went_live_at = now()
  WHERE id = v_rewrite.new_topic_id;

  UPDATE inform.topic_rewrites
  SET state = 'published',
      published_by = p_actor_id,
      published_at = now()
  WHERE id = p_rewrite_id;

  RETURN jsonb_build_object(
    'approved_copied',  v_approved_count,
    'rejected_skipped', v_rejected_count
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 11: Grants
-- ---------------------------------------------------------------------------
-- All RPCs are SECURITY DEFINER, but we still need EXECUTE for the pg pool
-- role used by supabaseAdmin. Default Supabase grants service_role EXECUTE
-- on functions in schemas it owns — verify via information_schema after
-- migration apply.
-- ---------------------------------------------------------------------------

GRANT EXECUTE ON FUNCTION inform.admin_create_topic_rewrite(TEXT, UUID, TEXT, TEXT, TEXT, JSONB, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_submit_rewrite_for_framing_review(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_approve_rewrite_framing(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_upsert_stance_proposal(UUID, UUID, NUMERIC, TEXT, TEXT[]) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_approve_stance_proposal(UUID, UUID, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_reject_stance_proposal(UUID, UUID, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_mark_rewrite_publish_ready(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_publish_topic_rewrite(UUID, UUID) TO service_role;
```

- [ ] **Step 2: Confirm `COMMIT;` is the last line of the file**

```bash
tail -3 ev-accounts/backend/migrations/061_topic_rewrite_workflow.sql
```

Expected: the last non-blank line is `COMMIT;`.

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/migrations/061_topic_rewrite_workflow.sql
git commit -m "migration(061): atomic publish RPC + service_role grants"
```

---

### Task 5: Backend service wrapper — topicRewriteService.ts

**Files:**
- Create: `ev-accounts/backend/src/lib/topicRewriteService.ts`

**Intent:** Thin TypeScript wrappers around each RPC. All business logic lives in SQL; this file just handles adminRpc calls, error translation, and typing.

- [ ] **Step 1: Create the service file**

```typescript
// ev-accounts/backend/src/lib/topicRewriteService.ts
//
// Service wrappers for topic rewrite workflow RPCs (migration 061).
// All functions invoke SECURITY DEFINER RPCs via the admin client.

import { adminRpc } from './supabase.js';

export type RewriteState =
  | 'draft'
  | 'pending_framing_review'
  | 're_evaluation_queue'
  | 'publish_ready'
  | 'published'
  | 'cancelled';

export type ProposalStatus = 'pending' | 'approved' | 'rejected';

export interface NewStance {
  value: number;
  text: string;
}

export interface CreateRewriteInput {
  topicKey: string;
  actorId: string;
  newTitle: string;
  newShortTitle: string;
  newQuestionText: string;
  newStances: NewStance[];
  notes?: string;
}

export async function createTopicRewrite(input: CreateRewriteInput): Promise<string> {
  const { data, error } = await adminRpc('admin_create_topic_rewrite', {
    p_topic_key: input.topicKey,
    p_actor_id: input.actorId,
    p_new_title: input.newTitle,
    p_new_short_title: input.newShortTitle,
    p_new_question_text: input.newQuestionText,
    p_new_stances: input.newStances,
    p_notes: input.notes ?? null,
  });
  if (error) throw new Error(`createTopicRewrite failed: ${error.message}`);
  return data as string;
}

export async function submitRewriteForFramingReview(rewriteId: string): Promise<void> {
  const { error } = await adminRpc('admin_submit_rewrite_for_framing_review', {
    p_rewrite_id: rewriteId,
  });
  if (error) throw new Error(`submitRewriteForFramingReview failed: ${error.message}`);
}

export async function approveRewriteFraming(
  rewriteId: string,
  actorId: string,
): Promise<number> {
  const { data, error } = await adminRpc('admin_approve_rewrite_framing', {
    p_rewrite_id: rewriteId,
    p_actor_id: actorId,
  });
  if (error) throw new Error(`approveRewriteFraming failed: ${error.message}`);
  return (data as number) ?? 0;
}

export interface UpsertProposalInput {
  rewriteId: string;
  politicianId: string;
  proposedValue: number | null;
  proposedReasoning: string | null;
  proposedSources: string[];
}

export async function upsertStanceProposal(input: UpsertProposalInput): Promise<void> {
  const { error } = await adminRpc('admin_upsert_stance_proposal', {
    p_rewrite_id: input.rewriteId,
    p_politician_id: input.politicianId,
    p_proposed_value: input.proposedValue,
    p_proposed_reasoning: input.proposedReasoning,
    p_proposed_sources: input.proposedSources,
  });
  if (error) throw new Error(`upsertStanceProposal failed: ${error.message}`);
}

export async function approveStanceProposal(
  rewriteId: string,
  politicianId: string,
  actorId: string,
  reviewerNotes: string | null,
): Promise<void> {
  const { error } = await adminRpc('admin_approve_stance_proposal', {
    p_rewrite_id: rewriteId,
    p_politician_id: politicianId,
    p_actor_id: actorId,
    p_reviewer_notes: reviewerNotes,
  });
  if (error) throw new Error(`approveStanceProposal failed: ${error.message}`);
}

export async function rejectStanceProposal(
  rewriteId: string,
  politicianId: string,
  actorId: string,
  reviewerNotes: string | null,
): Promise<void> {
  const { error } = await adminRpc('admin_reject_stance_proposal', {
    p_rewrite_id: rewriteId,
    p_politician_id: politicianId,
    p_actor_id: actorId,
    p_reviewer_notes: reviewerNotes,
  });
  if (error) throw new Error(`rejectStanceProposal failed: ${error.message}`);
}

export async function markRewritePublishReady(rewriteId: string): Promise<void> {
  const { error } = await adminRpc('admin_mark_rewrite_publish_ready', {
    p_rewrite_id: rewriteId,
  });
  if (error) throw new Error(`markRewritePublishReady failed: ${error.message}`);
}

export async function publishTopicRewrite(
  rewriteId: string,
  actorId: string,
): Promise<{ approved_copied: number; rejected_skipped: number }> {
  const { data, error } = await adminRpc('admin_publish_topic_rewrite', {
    p_rewrite_id: rewriteId,
    p_actor_id: actorId,
  });
  if (error) throw new Error(`publishTopicRewrite failed: ${error.message}`);
  return data as { approved_copied: number; rejected_skipped: number };
}

// ---------------------------------------------------------------------------
// Read helpers (plain SELECTs via pg pool — no RPC needed)
// ---------------------------------------------------------------------------

import { pool } from './db.js';

export async function listRewrites(): Promise<unknown[]> {
  const { rows } = await pool.query(`
    SELECT r.id, r.topic_key, r.state, r.old_topic_id, r.new_topic_id,
           r.created_at, r.framing_approved_at, r.published_at, r.notes,
           ot.title AS old_title, ot.version AS old_version,
           nt.title AS new_title, nt.version AS new_version
    FROM inform.topic_rewrites r
    JOIN inform.compass_topics ot ON ot.id = r.old_topic_id
    JOIN inform.compass_topics nt ON nt.id = r.new_topic_id
    ORDER BY r.created_at DESC
    LIMIT 100
  `);
  return rows;
}

export async function getRewriteDetail(rewriteId: string): Promise<unknown> {
  const { rows: rewriteRows } = await pool.query(
    `SELECT r.*, ot.title AS old_title, ot.question_text AS old_question_text,
            nt.title AS new_title, nt.question_text AS new_question_text
     FROM inform.topic_rewrites r
     JOIN inform.compass_topics ot ON ot.id = r.old_topic_id
     JOIN inform.compass_topics nt ON nt.id = r.new_topic_id
     WHERE r.id = $1`,
    [rewriteId],
  );
  if (rewriteRows.length === 0) return null;

  const { rows: oldStances } = await pool.query(
    `SELECT value, text FROM inform.compass_stances WHERE topic_id = $1 ORDER BY value`,
    [rewriteRows[0].old_topic_id],
  );
  const { rows: newStances } = await pool.query(
    `SELECT value, text FROM inform.compass_stances WHERE topic_id = $1 ORDER BY value`,
    [rewriteRows[0].new_topic_id],
  );
  const { rows: proposals } = await pool.query(
    `SELECT p.*, pol.full_name AS politician_name
     FROM inform.topic_rewrite_stance_proposals p
     JOIN inform.politicians pol ON pol.id = p.politician_id
     WHERE p.rewrite_id = $1
     ORDER BY pol.full_name`,
    [rewriteId],
  );

  return {
    ...rewriteRows[0],
    old_stances: oldStances,
    new_stances: newStances,
    proposals,
  };
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
npm run typecheck
```

Expected: PASS with zero errors. If `adminRpc` or `pool` signatures don't match, fix before commit.

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/src/lib/topicRewriteService.ts
git commit -m "backend: add topicRewriteService — wrappers for migration 061 RPCs"
```

---

### Task 6: Backend Express router — topicRewrites.ts + wire into index.ts

**Files:**
- Create: `ev-accounts/backend/src/routes/topicRewrites.ts`
- Modify: `ev-accounts/backend/src/index.ts`

**Intent:** Admin-gated Express router mounted at `/api/admin/topic-rewrites`. Uses `requireAuth` + `requireAdmin` at router level. Zod-validated request bodies. Each route logs the action via `logAdminAction` matching the existing `compassAdmin.ts` pattern.

- [ ] **Step 1: Create the router**

```typescript
// ev-accounts/backend/src/routes/topicRewrites.ts
import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  createTopicRewrite,
  submitRewriteForFramingReview,
  approveRewriteFraming,
  upsertStanceProposal,
  approveStanceProposal,
  rejectStanceProposal,
  markRewritePublishReady,
  publishTopicRewrite,
  listRewrites,
  getRewriteDetail,
} from '../lib/topicRewriteService.js';

const router = Router();

// eslint-disable-next-line @typescript-eslint/no-explicit-any
router.use(requireAuth as any, requireAdmin as any);

const actorId = (req: AuthenticatedRequest) => req.userId!;

// ---------- LIST / DETAIL ----------

router.get('/', async (_req, res, next) => {
  try {
    res.json({ rewrites: await listRewrites() });
  } catch (err) { next(err); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const detail = await getRewriteDetail(req.params.id);
    if (!detail) return res.status(404).json({ error: 'NOT_FOUND' });
    res.json(detail);
  } catch (err) { next(err); }
});

// ---------- CREATE ----------

const CreateBody = z.object({
  topic_key: z.string().min(1),
  new_title: z.string().min(1),
  new_short_title: z.string().min(1),
  new_question_text: z.string().min(1),
  new_stances: z.array(z.object({
    value: z.number().int().min(1).max(5),
    text: z.string().min(1),
  })).length(5),
  notes: z.string().optional(),
});

router.post('/', async (req: AuthenticatedRequest, res, next) => {
  try {
    const body = CreateBody.parse(req.body);
    const rewriteId = await createTopicRewrite({
      topicKey: body.topic_key,
      actorId: actorId(req),
      newTitle: body.new_title,
      newShortTitle: body.new_short_title,
      newQuestionText: body.new_question_text,
      newStances: body.new_stances,
      notes: body.notes,
    });
    await logAdminAction(actorId(req), 'topic_rewrite.create', { rewriteId, topic_key: body.topic_key });
    res.status(201).json({ rewrite_id: rewriteId });
  } catch (err) { next(err); }
});

// ---------- STATE TRANSITIONS ----------

router.post('/:id/submit-framing', async (req: AuthenticatedRequest, res, next) => {
  try {
    await submitRewriteForFramingReview(req.params.id);
    await logAdminAction(actorId(req), 'topic_rewrite.submit_framing', { rewriteId: req.params.id });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

router.post('/:id/approve-framing', async (req: AuthenticatedRequest, res, next) => {
  try {
    const seeded = await approveRewriteFraming(req.params.id, actorId(req));
    await logAdminAction(actorId(req), 'topic_rewrite.approve_framing', { rewriteId: req.params.id, seeded });
    res.json({ ok: true, seeded_proposals: seeded });
  } catch (err) { next(err); }
});

router.post('/:id/mark-publish-ready', async (req: AuthenticatedRequest, res, next) => {
  try {
    await markRewritePublishReady(req.params.id);
    await logAdminAction(actorId(req), 'topic_rewrite.mark_publish_ready', { rewriteId: req.params.id });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

router.post('/:id/publish', async (req: AuthenticatedRequest, res, next) => {
  try {
    const result = await publishTopicRewrite(req.params.id, actorId(req));
    await logAdminAction(actorId(req), 'topic_rewrite.publish', { rewriteId: req.params.id, ...result });
    res.json({ ok: true, ...result });
  } catch (err) { next(err); }
});

// ---------- STANCE PROPOSALS ----------

const UpsertProposalBody = z.object({
  proposed_value: z.number().min(1).max(5).nullable(),
  proposed_reasoning: z.string().nullable(),
  proposed_sources: z.array(z.string()).default([]),
});

router.put('/:id/proposals/:politicianId', async (req: AuthenticatedRequest, res, next) => {
  try {
    const body = UpsertProposalBody.parse(req.body);
    await upsertStanceProposal({
      rewriteId: req.params.id,
      politicianId: req.params.politicianId,
      proposedValue: body.proposed_value,
      proposedReasoning: body.proposed_reasoning,
      proposedSources: body.proposed_sources,
    });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

const DecideBody = z.object({ reviewer_notes: z.string().nullable().optional() });

router.post('/:id/proposals/:politicianId/approve', async (req: AuthenticatedRequest, res, next) => {
  try {
    const { reviewer_notes } = DecideBody.parse(req.body);
    await approveStanceProposal(req.params.id, req.params.politicianId, actorId(req), reviewer_notes ?? null);
    await logAdminAction(actorId(req), 'topic_rewrite.approve_proposal', {
      rewriteId: req.params.id, politicianId: req.params.politicianId,
    });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

router.post('/:id/proposals/:politicianId/reject', async (req: AuthenticatedRequest, res, next) => {
  try {
    const { reviewer_notes } = DecideBody.parse(req.body);
    await rejectStanceProposal(req.params.id, req.params.politicianId, actorId(req), reviewer_notes ?? null);
    await logAdminAction(actorId(req), 'topic_rewrite.reject_proposal', {
      rewriteId: req.params.id, politicianId: req.params.politicianId,
    });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

export default router;
```

- [ ] **Step 2: Wire into `backend/src/index.ts`**

Read `ev-accounts/backend/src/index.ts` to find the `app.use('/api/admin', adminRouter);` line and the imports block. Add these in the correct positions:

Import (group with other route imports near the top):
```typescript
import topicRewritesRouter from './routes/topicRewrites.js';
```

Mount (immediately after `app.use('/api/admin', adminRouter);`):
```typescript
app.use('/api/admin/topic-rewrites', topicRewritesRouter);
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
npm run typecheck
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/src/routes/topicRewrites.ts backend/src/index.ts
git commit -m "backend: add /api/admin/topic-rewrites router + wire into index.ts"
```

---

### Task 7: 401 enforcement tests

**Files:**
- Create: `ev-accounts/tests/integration/topic-rewrites.test.ts`

**Intent:** CI-safe auth-enforcement tests matching the `admin-compass.test.ts` pattern. Every route must return 401 without a valid admin JWT. This is the testing convention Chris uses — see `tests/integration/admin-compass.test.ts` — and is sufficient for CI. Workflow correctness is verified manually in Task 14.

- [ ] **Step 1: Write the test file**

```typescript
// ev-accounts/tests/integration/topic-rewrites.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';

process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';

let app: Express;

beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

describe('Topic rewrites routes — 401 enforcement (CI-safe)', () => {
  it('GET /api/admin/topic-rewrites requires auth', async () => {
    const res = await request(app).get('/api/admin/topic-rewrites');
    expect(res.status).toBe(401);
  });

  it('GET /api/admin/topic-rewrites/:id requires auth', async () => {
    const res = await request(app).get('/api/admin/topic-rewrites/00000000-0000-0000-0000-000000000000');
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/submit-framing requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/submit-framing').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/approve-framing requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/approve-framing').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/mark-publish-ready requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/mark-publish-ready').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/publish requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/publish').send({});
    expect(res.status).toBe(401);
  });

  it('PUT /api/admin/topic-rewrites/:id/proposals/:politicianId requires auth', async () => {
    const res = await request(app)
      .put('/api/admin/topic-rewrites/x/proposals/y')
      .send({ proposed_value: 3, proposed_reasoning: '', proposed_sources: [] });
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/proposals/:politicianId/approve requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/proposals/y/approve').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/proposals/:politicianId/reject requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/proposals/y/reject').send({});
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: Run the tests**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
npm test -- tests/integration/topic-rewrites.test.ts
```

Expected: 10 tests PASS.

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add tests/integration/topic-rewrites.test.ts
git commit -m "test: 401 enforcement for topic rewrites routes"
```

---

### Task 8: Apply migration 061 to production Supabase

**Files:** none — infrastructure step.

**Intent:** Run migration 061 against the prod Supabase project (ID `kxsdzaojfaibhuzmclfq`). Plan C ran against prod because the dev DB isn't active; this is authorized per the handoff prompt.

- [ ] **Step 1: Confirm the project target WITHOUT echoing DATABASE_URL**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
set -a && source .env && set +a
echo "$DATABASE_URL" | sed -E 's|.*postgres\.([a-z0-9]+):.*|\1|'
```

Expected output: `kxsdzaojfaibhuzmclfq`. If anything else, STOP and ask Chris.

- [ ] **Step 2: Dry-run by reading the migration back**

```bash
wc -l migrations/061_topic_rewrite_workflow.sql
head -5 migrations/061_topic_rewrite_workflow.sql
tail -3 migrations/061_topic_rewrite_workflow.sql
```

Expected: starts with `BEGIN;`, ends with `COMMIT;`.

- [ ] **Step 3: Apply the migration via psql**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
psql "$DATABASE_URL" -f migrations/061_topic_rewrite_workflow.sql
```

Expected: series of `CREATE`/`ALTER`/`DROP INDEX` notices and final `COMMIT`. Any ERROR halts here — investigate before retrying.

- [ ] **Step 4: Verify objects exist**

```bash
psql "$DATABASE_URL" -c "
  SELECT 'table' AS kind, table_name AS name
  FROM information_schema.tables
  WHERE table_schema='inform'
    AND table_name IN ('topic_rewrites','topic_rewrite_stance_proposals')
  UNION ALL
  SELECT 'type', typname
  FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname='inform' AND typname IN ('topic_rewrite_state','stance_proposal_status')
  UNION ALL
  SELECT 'function', proname
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname='inform' AND proname LIKE 'admin_%topic%rewrite%'
     OR (n.nspname='inform' AND proname IN ('admin_upsert_stance_proposal','admin_approve_stance_proposal','admin_reject_stance_proposal','admin_mark_rewrite_publish_ready'))
  ORDER BY 1, 2;
"
```

Expected: 2 tables, 2 types, 8 functions. If any are missing, the migration half-applied — investigate.

- [ ] **Step 5: Verify the unique index swap**

```bash
psql "$DATABASE_URL" -c "
  SELECT indexname, indexdef FROM pg_indexes
  WHERE schemaname='inform' AND tablename='compass_topics'
    AND indexname LIKE '%topic_key%'
  ORDER BY indexname;
"
```

Expected: `idx_compass_topics_topic_key_live` (partial on is_live=true) and `idx_compass_topics_topic_key_version`. The old `idx_compass_topics_topic_key` is gone.

---

### Task 9: Frontend API client — topicRewriteApi.js

**Files:**
- Create: `CompassV2/src/lib/topicRewriteApi.js`

**Intent:** Small fetch wrapper that follows the same admin-auth pattern as the existing admin fetchers in CompassV2. Reads `API_BASE_URL` and the admin JWT from wherever the existing admin API client gets them.

- [ ] **Step 1: Find the existing admin API pattern**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
grep -rn "API_BASE_URL\|getAdminToken\|adminFetch" src/lib/ src/components/admin/ | head -20
```

Note the existing pattern. If there's an `adminApi.js` or similar, reuse its helpers. If not, copy the auth pattern from an existing admin component that fetches (e.g., `AdminDashboard.jsx`).

- [ ] **Step 2: Create the client, matching the discovered pattern**

Template — **adapt the auth mechanism to match what the existing admin fetchers use**:

```javascript
// CompassV2/src/lib/topicRewriteApi.js
const API_BASE = import.meta.env.VITE_API_URL || 'https://api.empowered.vote';

function authHeaders() {
  // REPLACE THIS with the same mechanism used by the other admin fetchers
  // in CompassV2 (e.g., reading a JWT from localStorage or a React context).
  const token = localStorage.getItem('ev_admin_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function j(method, path, body) {
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${method} ${path} failed: ${res.status} ${text}`);
  }
  return res.json();
}

export const topicRewriteApi = {
  list: () => j('GET', '/api/admin/topic-rewrites'),
  detail: (id) => j('GET', `/api/admin/topic-rewrites/${id}`),
  create: (payload) => j('POST', '/api/admin/topic-rewrites', payload),
  submitFraming: (id) => j('POST', `/api/admin/topic-rewrites/${id}/submit-framing`),
  approveFraming: (id) => j('POST', `/api/admin/topic-rewrites/${id}/approve-framing`),
  markPublishReady: (id) => j('POST', `/api/admin/topic-rewrites/${id}/mark-publish-ready`),
  publish: (id) => j('POST', `/api/admin/topic-rewrites/${id}/publish`),
  upsertProposal: (id, politicianId, payload) =>
    j('PUT', `/api/admin/topic-rewrites/${id}/proposals/${politicianId}`, payload),
  approveProposal: (id, politicianId, reviewerNotes) =>
    j('POST', `/api/admin/topic-rewrites/${id}/proposals/${politicianId}/approve`, { reviewer_notes: reviewerNotes }),
  rejectProposal: (id, politicianId, reviewerNotes) =>
    j('POST', `/api/admin/topic-rewrites/${id}/proposals/${politicianId}/reject`, { reviewer_notes: reviewerNotes }),
};
```

**Critical:** Before committing, replace `authHeaders` with the exact same call used by existing admin fetchers. Do not leave the localStorage placeholder if the rest of the admin UI uses a different method.

- [ ] **Step 3: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
git add src/lib/topicRewriteApi.js
git commit -m "frontend(admin): topic rewrite API client"
```

---

### Task 10: Frontend UI — TopicRewriteWorkflow (list + create + framing gate)

**Files:**
- Create: `CompassV2/src/components/admin/TopicRewriteWorkflow.jsx`

**Intent:** A single admin page with three views: (a) list of existing rewrites, (b) "create new rewrite" form, (c) detail view showing the framing gate (old vs. new side-by-side + submit/approve buttons) AND the re-evaluation queue (proposal cards with edit/approve/reject). Keep it rough per spec — form fields, minimal Tailwind, no fancy state management.

- [ ] **Step 1: Create the component**

```jsx
// CompassV2/src/components/admin/TopicRewriteWorkflow.jsx
import { useEffect, useState } from 'react';
import { topicRewriteApi } from '../../lib/topicRewriteApi';

export default function TopicRewriteWorkflow() {
  const [rewrites, setRewrites] = useState([]);
  const [selectedId, setSelectedId] = useState(null);
  const [detail, setDetail] = useState(null);
  const [showCreate, setShowCreate] = useState(false);
  const [err, setErr] = useState(null);

  async function refreshList() {
    try {
      const { rewrites } = await topicRewriteApi.list();
      setRewrites(rewrites);
    } catch (e) { setErr(e.message); }
  }

  async function refreshDetail(id) {
    try {
      setDetail(await topicRewriteApi.detail(id));
    } catch (e) { setErr(e.message); }
  }

  useEffect(() => { refreshList(); }, []);
  useEffect(() => { if (selectedId) refreshDetail(selectedId); }, [selectedId]);

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-4">Topic Rewrite Workflow</h2>
      {err && <div className="bg-red-100 text-red-800 p-3 mb-4 rounded">{err}</div>}

      <div className="grid grid-cols-3 gap-6">
        {/* LEFT: list */}
        <div className="col-span-1 border-r pr-4">
          <button
            className="mb-4 px-3 py-1 bg-ev-muted-blue text-white rounded"
            onClick={() => { setShowCreate(true); setSelectedId(null); setDetail(null); }}
          >
            + New rewrite
          </button>
          <ul className="space-y-2">
            {rewrites.map((r) => (
              <li
                key={r.id}
                className={`p-2 border rounded cursor-pointer ${selectedId === r.id ? 'bg-yellow-50' : ''}`}
                onClick={() => { setShowCreate(false); setSelectedId(r.id); }}
              >
                <div className="font-semibold">{r.topic_key}</div>
                <div className="text-xs text-gray-600">
                  v{r.old_version} → v{r.new_version} · {r.state}
                </div>
              </li>
            ))}
            {rewrites.length === 0 && <li className="text-gray-500">No rewrites yet.</li>}
          </ul>
        </div>

        {/* RIGHT: detail or create form */}
        <div className="col-span-2">
          {showCreate && <CreateRewriteForm onDone={async (id) => {
            setShowCreate(false);
            await refreshList();
            if (id) setSelectedId(id);
          }} />}
          {!showCreate && detail && (
            <RewriteDetail
              detail={detail}
              refreshDetail={() => refreshDetail(selectedId)}
              refreshList={refreshList}
            />
          )}
          {!showCreate && !detail && !selectedId && (
            <div className="text-gray-500">Select a rewrite or create a new one.</div>
          )}
        </div>
      </div>
    </div>
  );
}

function CreateRewriteForm({ onDone }) {
  const [form, setForm] = useState({
    topic_key: '',
    new_title: '',
    new_short_title: '',
    new_question_text: '',
    new_stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: '' })),
    notes: '',
  });
  const [err, setErr] = useState(null);
  const [busy, setBusy] = useState(false);

  async function submit() {
    setErr(null); setBusy(true);
    try {
      const { rewrite_id } = await topicRewriteApi.create(form);
      onDone(rewrite_id);
    } catch (e) {
      setErr(e.message);
    } finally { setBusy(false); }
  }

  return (
    <div className="space-y-3">
      <h3 className="text-xl font-bold">New topic rewrite</h3>
      {err && <div className="bg-red-100 text-red-800 p-2 rounded">{err}</div>}
      <label className="block">
        <span className="text-sm font-semibold">topic_key (must match the current live topic)</span>
        <input
          className="w-full border rounded p-2"
          value={form.topic_key}
          onChange={(e) => setForm({ ...form, topic_key: e.target.value })}
        />
      </label>
      <label className="block">
        <span className="text-sm font-semibold">New title</span>
        <input className="w-full border rounded p-2"
          value={form.new_title}
          onChange={(e) => setForm({ ...form, new_title: e.target.value })} />
      </label>
      <label className="block">
        <span className="text-sm font-semibold">New short title</span>
        <input className="w-full border rounded p-2"
          value={form.new_short_title}
          onChange={(e) => setForm({ ...form, new_short_title: e.target.value })} />
      </label>
      <label className="block">
        <span className="text-sm font-semibold">New question text</span>
        <textarea className="w-full border rounded p-2" rows={3}
          value={form.new_question_text}
          onChange={(e) => setForm({ ...form, new_question_text: e.target.value })} />
      </label>
      <div>
        <span className="text-sm font-semibold">New stance scale (1–5)</span>
        {form.new_stances.map((s, i) => (
          <input
            key={s.value}
            className="w-full border rounded p-2 mt-1"
            placeholder={`Stance ${s.value}`}
            value={s.text}
            onChange={(e) => {
              const next = [...form.new_stances];
              next[i] = { ...s, text: e.target.value };
              setForm({ ...form, new_stances: next });
            }}
          />
        ))}
      </div>
      <label className="block">
        <span className="text-sm font-semibold">Notes (optional)</span>
        <textarea className="w-full border rounded p-2" rows={2}
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })} />
      </label>
      <button
        disabled={busy}
        className="px-4 py-2 bg-ev-coral text-white rounded disabled:opacity-50"
        onClick={submit}
      >
        {busy ? 'Creating…' : 'Create draft'}
      </button>
    </div>
  );
}

function RewriteDetail({ detail, refreshDetail, refreshList }) {
  const [err, setErr] = useState(null);

  async function act(fn) {
    setErr(null);
    try { await fn(); await refreshDetail(); await refreshList(); }
    catch (e) { setErr(e.message); }
  }

  return (
    <div className="space-y-4">
      <h3 className="text-xl font-bold">
        {detail.topic_key} · <span className="text-sm text-gray-600">{detail.state}</span>
      </h3>
      {err && <div className="bg-red-100 text-red-800 p-2 rounded">{err}</div>}

      {/* Framing comparison */}
      <section className="grid grid-cols-2 gap-4 border p-3 rounded">
        <div>
          <div className="text-xs font-bold text-gray-500">OLD (v{detail.version ?? ''})</div>
          <div className="font-semibold">{detail.old_title}</div>
          <div className="text-sm">{detail.old_question_text}</div>
          <ol className="text-xs mt-2 list-decimal pl-4">
            {detail.old_stances?.map((s) => <li key={s.value}>{s.text}</li>)}
          </ol>
        </div>
        <div>
          <div className="text-xs font-bold text-gray-500">NEW</div>
          <div className="font-semibold">{detail.new_title}</div>
          <div className="text-sm">{detail.new_question_text}</div>
          <ol className="text-xs mt-2 list-decimal pl-4">
            {detail.new_stances?.map((s) => <li key={s.value}>{s.text}</li>)}
          </ol>
        </div>
      </section>

      {/* State transition buttons */}
      <div className="flex gap-2 flex-wrap">
        {detail.state === 'draft' && (
          <button className="px-3 py-1 bg-ev-muted-blue text-white rounded"
            onClick={() => act(() => topicRewriteApi.submitFraming(detail.id))}>
            Submit for framing review
          </button>
        )}
        {detail.state === 'pending_framing_review' && (
          <button className="px-3 py-1 bg-ev-coral text-white rounded"
            onClick={() => act(() => topicRewriteApi.approveFraming(detail.id))}>
            Approve framing → seed proposals
          </button>
        )}
        {detail.state === 're_evaluation_queue' && (
          <button className="px-3 py-1 bg-ev-muted-blue text-white rounded"
            onClick={() => act(() => topicRewriteApi.markPublishReady(detail.id))}>
            Mark publish-ready
          </button>
        )}
        {detail.state === 'publish_ready' && (
          <button className="px-3 py-1 bg-ev-yellow text-black rounded font-bold"
            onClick={() => {
              if (window.confirm('Publish this rewrite? This flips is_live on the new topic.')) {
                act(() => topicRewriteApi.publish(detail.id));
              }
            }}>
            PUBLISH
          </button>
        )}
      </div>

      {/* Proposal queue */}
      {detail.proposals?.length > 0 && (
        <section>
          <h4 className="font-bold mb-2">Stance re-evaluation queue</h4>
          <div className="space-y-3">
            {detail.proposals.map((p) => (
              <ProposalCard
                key={p.politician_id}
                rewriteId={detail.id}
                proposal={p}
                onChange={refreshDetail}
                setErr={setErr}
              />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

function ProposalCard({ rewriteId, proposal, onChange, setErr }) {
  const [draft, setDraft] = useState({
    proposed_value: proposal.proposed_value ?? '',
    proposed_reasoning: proposal.proposed_reasoning ?? '',
    proposed_sources: (proposal.proposed_sources ?? []).join('\n'),
  });

  async function save() {
    try {
      await topicRewriteApi.upsertProposal(rewriteId, proposal.politician_id, {
        proposed_value: draft.proposed_value === '' ? null : Number(draft.proposed_value),
        proposed_reasoning: draft.proposed_reasoning || null,
        proposed_sources: draft.proposed_sources.split('\n').map((s) => s.trim()).filter(Boolean),
      });
      await onChange();
    } catch (e) { setErr(e.message); }
  }

  async function approve() {
    try {
      await topicRewriteApi.approveProposal(rewriteId, proposal.politician_id, null);
      await onChange();
    } catch (e) { setErr(e.message); }
  }

  async function reject() {
    const notes = window.prompt('Rejection notes (optional)') || null;
    try {
      await topicRewriteApi.rejectProposal(rewriteId, proposal.politician_id, notes);
      await onChange();
    } catch (e) { setErr(e.message); }
  }

  const locked = proposal.status !== 'pending';

  return (
    <div className={`border p-3 rounded ${proposal.status === 'approved' ? 'bg-green-50' : proposal.status === 'rejected' ? 'bg-gray-100' : ''}`}>
      <div className="font-semibold">{proposal.politician_name} <span className="text-xs text-gray-500">({proposal.status})</span></div>
      <div className="grid grid-cols-2 gap-3 mt-2">
        <div className="text-xs">
          <div className="font-bold text-gray-500">OLD</div>
          <div>value: {proposal.old_value}</div>
          <div className="italic">{proposal.old_reasoning}</div>
        </div>
        <div className="text-xs space-y-1">
          <div className="font-bold text-gray-500">NEW (proposed)</div>
          <input
            type="number" min="1" max="5" step="0.1"
            className="border rounded p-1 w-24"
            disabled={locked}
            value={draft.proposed_value}
            onChange={(e) => setDraft({ ...draft, proposed_value: e.target.value })}
          />
          <textarea
            className="border rounded p-1 w-full"
            rows={3}
            disabled={locked}
            placeholder="Reasoning"
            value={draft.proposed_reasoning}
            onChange={(e) => setDraft({ ...draft, proposed_reasoning: e.target.value })}
          />
          <textarea
            className="border rounded p-1 w-full"
            rows={2}
            disabled={locked}
            placeholder="Sources (one per line)"
            value={draft.proposed_sources}
            onChange={(e) => setDraft({ ...draft, proposed_sources: e.target.value })}
          />
        </div>
      </div>
      {!locked && (
        <div className="flex gap-2 mt-2">
          <button className="px-2 py-1 bg-ev-muted-blue text-white rounded text-xs" onClick={save}>Save draft</button>
          <button className="px-2 py-1 bg-green-600 text-white rounded text-xs" onClick={approve}>Approve</button>
          <button className="px-2 py-1 bg-red-600 text-white rounded text-xs" onClick={reject}>Reject</button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Build to verify no syntax errors**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
npm run build
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/components/admin/TopicRewriteWorkflow.jsx
git commit -m "frontend(admin): TopicRewriteWorkflow page with framing gate + re-eval queue"
```

---

### Task 11: Wire TopicRewriteWorkflow into AdminDashboard

**Files:**
- Modify: `CompassV2/src/components/admin/AdminDashboard.jsx`

**Intent:** Add a new tab/section in the admin dashboard that renders `<TopicRewriteWorkflow />`. Follow whatever nav pattern the dashboard already uses — tabs, sidebar links, routed sub-pages, whatever is in place.

- [ ] **Step 1: Read the current dashboard structure**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
sed -n '1,80p' src/components/admin/AdminDashboard.jsx
```

Identify the pattern used to switch between existing admin views (topic editor, politician admin, etc.).

- [ ] **Step 2: Add the import and a new nav entry**

At the top with other imports:
```javascript
import TopicRewriteWorkflow from './TopicRewriteWorkflow';
```

Add a nav entry/tab that mounts `<TopicRewriteWorkflow />` when selected. Match the exact pattern used by existing entries — don't invent new structure.

- [ ] **Step 3: Run dev server and manually click the tab**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
npm run dev
```

In browser: navigate to admin dashboard, click the new "Rewrite Workflow" tab, confirm the page renders (it will show "No rewrites yet." which is correct — production has zero rewrites at this point).

- [ ] **Step 4: Commit**

```bash
git add src/components/admin/AdminDashboard.jsx
git commit -m "frontend(admin): add Rewrite Workflow tab to AdminDashboard"
```

---

### Task 12: Deploy backend + frontend

**Files:** none — deployment step.

**Intent:** Push commits to trigger Render auto-deploy for both `ev-accounts` backend and `CompassV2`. Verify both redeploys succeed before the end-to-end smoke test.

- [ ] **Step 1: Push backend**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git push origin master
```

Expected: push succeeds. Render will start an `ev-accounts` deploy.

- [ ] **Step 2: Push frontend**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
git push origin main
```

Expected: push succeeds. Render will start a `CompassV2` deploy.

- [ ] **Step 3: Wait for both deploys to complete**

Monitor Render dashboard or hit `https://api.empowered.vote/api/health` until the new commit is live. Similarly hit `https://compass.empowered.vote` and confirm the admin dashboard shows the new tab.

- [ ] **Step 4: Commit the plan document itself to the monorepo**

```bash
cd /Users/chrisandrews/Documents/GitHub
git add docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md
git commit -m "docs(plan-d): commit topic rewrite workflow implementation plan"
git push origin feat/compass-how-it-works
```

---

### Task 13: End-to-end smoke test (manual, walks through the whole workflow)

**Files:** none — verification step.

**Intent:** Prove Chris can run a test rewrite on ONE non-critical topic end-to-end without any stance data being silently invalidated. The test topic is chosen as low-stakes so rollback is trivial. If anything breaks at any step, stop and report.

**Choose the test topic:** pick a topic_key that has at least 1 but ideally fewer than 10 politicians with existing stances. Query to pick:

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
set -a && source .env && set +a
psql "$DATABASE_URL" -c "
  SELECT t.topic_key, t.title, COUNT(pa.politician_id) AS answer_count
  FROM inform.compass_topics t
  LEFT JOIN inform.politician_answers pa ON pa.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.topic_key, t.title
  HAVING COUNT(pa.politician_id) BETWEEN 1 AND 10
  ORDER BY answer_count
  LIMIT 5;
"
```

Pick the lowest-count entry. Record as `TEST_TOPIC_KEY` below.

- [ ] **Step 1: Snapshot the pre-test state**

```bash
psql "$DATABASE_URL" -c "
  SELECT id, version, is_live, title FROM inform.compass_topics
  WHERE topic_key='TEST_TOPIC_KEY'
  ORDER BY version;
  SELECT COUNT(*) AS answers FROM inform.politician_answers pa
  JOIN inform.compass_topics t ON t.id=pa.topic_id
  WHERE t.topic_key='TEST_TOPIC_KEY';
"
```

Record the output — you'll compare against it at the end.

- [ ] **Step 2: Create the rewrite via the admin UI**

Open `https://compass.empowered.vote` → Admin → Rewrite Workflow → "+ New rewrite". Fill in:
- `topic_key`: `TEST_TOPIC_KEY`
- `new_title`: append "(rewrite test)" to existing title
- `new_short_title`: existing short title
- `new_question_text`: existing question text + " [TEST REWRITE]"
- 5 stance texts: copy existing stance texts, append " (test)" to each
- notes: "Plan D smoke test, delete after"

Click "Create draft". Expected: the rewrite appears in the left list in `draft` state.

- [ ] **Step 3: Walk through each state transition via the UI**

1. Click "Submit for framing review" → state flips to `pending_framing_review`.
2. Click "Approve framing → seed proposals" → state flips to `re_evaluation_queue` and the queue shows one card per politician with existing answers.
3. For each proposal: type a `proposed_value` (copy the old value), add short reasoning, click Save → then Approve.
4. Once all are approved, click "Mark publish-ready" → state flips to `publish_ready`.
5. Click "PUBLISH" and confirm the dialog → state flips to `published`.

- [ ] **Step 4: Verify the post-publish state**

```bash
psql "$DATABASE_URL" -c "
  SELECT id, version, is_live, went_live_at, title FROM inform.compass_topics
  WHERE topic_key='TEST_TOPIC_KEY'
  ORDER BY version;

  -- Answers on the new version (should equal the old count)
  SELECT COUNT(*) AS new_answers FROM inform.politician_answers pa
  JOIN inform.compass_topics t ON t.id=pa.topic_id
  WHERE t.topic_key='TEST_TOPIC_KEY' AND t.is_live=true;

  -- Old version rows are still present but is_live=false
  SELECT COUNT(*) AS old_answers FROM inform.politician_answers pa
  JOIN inform.compass_topics t ON t.id=pa.topic_id
  WHERE t.topic_key='TEST_TOPIC_KEY' AND t.is_live=false;
"
```

Expected:
- Two compass_topics rows with the same topic_key, one at the old version (`is_live=false`) and one at version+1 (`is_live=true`, `went_live_at` set).
- `new_answers` equals the pre-test answer count (all proposals were approved).
- `old_answers` equals the pre-test answer count (old rows untouched, append-only).

If either count mismatches, stop and investigate **before** running any further rewrites.

- [ ] **Step 5: Verify voter-facing API still returns exactly one live version of the topic**

```bash
curl -s "https://api.empowered.vote/api/compass/topics" | python3 -c "
import sys, json
data = json.load(sys.stdin)
hits = [t for t in data if t.get('topic_key') == 'TEST_TOPIC_KEY']
print(f'live topic rows returned: {len(hits)}')
print(hits[0] if hits else 'MISSING')
"
```

Expected: exactly one row with the " [TEST REWRITE]" question text.

- [ ] **Step 6: Clean up the test (optional — Chris's call)**

The test rewrite is intentionally cosmetic and safe to leave in prod. If Chris wants to roll back:

```bash
psql "$DATABASE_URL" <<SQL
BEGIN;
-- Flip old back to live, new to inactive
UPDATE inform.compass_topics SET is_live=false WHERE topic_key='TEST_TOPIC_KEY' AND title LIKE '%(rewrite test)%';
UPDATE inform.compass_topics SET is_live=true WHERE topic_key='TEST_TOPIC_KEY' AND title NOT LIKE '%(rewrite test)%';
COMMIT;
SQL
```

Do NOT DELETE rows — append-only. Leaving the test version around is fine; only its `is_live` flag matters.

---

### Task 14: Report completion

**Files:** none.

- [ ] **Step 1: Write a short completion summary**

Report back in conversation:

1. Confirmation that migration 061 is applied to prod and all 2 tables / 2 types / 8 RPCs exist.
2. Confirmation that `/api/admin/topic-rewrites/*` routes are deployed and return 401 unauth'd.
3. Confirmation that the admin UI tab renders and the end-to-end smoke test in Task 13 reached `published` state with counts matching.
4. Any quirks or gotchas discovered (for updating this plan or future plans).

---

## Self-review notes

**Spec coverage (cross-checked against the "Topic rewrite workflow" section, lines 270–303):**

- ✅ Workflow state machine (`draft → pending_framing_review → re_evaluation_queue → publish_ready → published`) — Task 1 enum + Tasks 2–4 transition RPCs.
- ✅ Two human gates — Task 2 (framing) and Tasks 3–4 (per-stance).
- ✅ Uses existing `version`, `is_live`, `went_live_at` — Task 1.
- ✅ New row with `version = old_version + 1`, initially `is_live = false` — Task 2 `admin_create_topic_rewrite`.
- ✅ Staging table for proposed new values per `(politician_id, new_topic_id)` — Task 1 `topic_rewrite_stance_proposals`.
- ✅ Atomic publish — Task 4 `admin_publish_topic_rewrite` is a single SQL function (implicit txn).
- ✅ Admin UI exists and reuses existing admin dashboard pattern — Tasks 10–11.
- ✅ Rough v1 — no agent automation; Chris pastes proposals manually.
- ✅ Append-only — old politician_answers rows are not deleted.
- ✅ One-open-rewrite-per-topic guard — partial unique index in Task 1.

**Placeholder scan:** None. Every step has either exact SQL, exact code, or an exact shell command.

**Type consistency:** RPC names match between SQL, `topicRewriteService.ts`, `topicRewrites.ts`, and `topicRewriteApi.js`. State enum values match across all layers.

**Known risks:**
- Task 9 `authHeaders` placeholder: flagged as requiring adaptation to match existing admin client pattern. Do not skip.
- Task 11 nav pattern: must match existing AdminDashboard structure; reading it first is Step 1 of the task.
- Publish RPC rounds `proposed_value` to int because `politician_answers.value` is `INT` (see migration 026). If Chris has since moved to decimal values elsewhere, the round is fine for this table.
