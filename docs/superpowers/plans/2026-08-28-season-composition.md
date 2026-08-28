# Season Composition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An admin screen to compose Season 2 from Season 1 (carry / drop / add / re-pin topics in a `draft` season), with a board-facing dark presentation view of the change set, backed by new season-management RPCs.

**Architecture:** New SECURITY DEFINER RPCs in `inform` (migration `CA_0022`) perform all season writes; a new `seasonCompositionService` reads composition facts via `pool.query` and calls the RPCs via `adminRpc`; a new `/api/admin/seasons` router gates everything behind `requireAuth + requireCompassReviewer`; a new admin page renders one screen with two modes (compose / presentation) sharing one payload, with classification logic in a pure module.

**Tech Stack:** Postgres (plpgsql RPCs), Express + zod, pg pool, supabase adminRpc, React + TypeScript + Tailwind v4 + HeadlessUI, vitest (+supertest).

## Global Constraints

- Chris's decisions (do not re-litigate): one screen two modes; board reviews a DRAFT season; four categories carried/changed/dropped/added; per-jurisdiction variation OUT OF SCOPE; **pins are set at compose time** (the `season_questions_pin_immutable` trigger already enforces draft-only pin movement).
- 🔴 Runtime is least-privilege `ev_api`: reads via `pool`, writes via `adminRpc(fn, args, 'inform')` — never write inform via `pool`.
- 🔴 Auth gate is `requireCompassReviewer` (editor role OR `public.admin_users`); record `capacity: reviewerCapacity(req)` in every `logAdminAction`. Do not raise the zero-editor-holders state as a defect.
- Migration slot: `CA_0022_season_composition_rpcs.sql` (verified free after `git fetch origin`; `CA_0014` stays reserved). House style: `BEGIN/COMMIT`, `SECURITY DEFINER SET search_path = ''`, `RAISE EXCEPTION 'NAMED_CODE: sentence'`, `REVOKE ALL FROM PUBLIC` + `GRANT EXECUTE TO service_role` only, closing `DO $$ ... $$` post-verify gate.
- 🔴 Opening a season while the CC_0002 scaffold indexes exist must be REFUSED (`SCAFFOLD_INDEXES_PRESENT`) — dropping them is rollout step 3 (ADR 0005 §1.6), an explicit ops decision, not a side effect.
- Every admin mutation calls `logAdminAction()` before returning 200 (ADMN-05). No `supabaseAdmin` in `src/routes/` (architecture test).
- CI billing is broken; verify locally: backend `npm run typecheck|lint|test:unit|check:migrations|check:answer-seasons`; admin `npx tsc --noEmit && npm run build && npm test`.
- Dry-run the migration against prod (`node scripts/dry-run-migration.mjs migrations/CA_0022_season_composition_rpcs.sql` from `backend/`) before applying.
- Reuse `admin/src/lib/wordDiff.ts` (`diffWords`, `hasChanged`) for the changed-topic diff. Do not write another differ.
- zod-4 UUID fixtures in tests need RFC 4122 nibbles, e.g. `'11111111-1111-4111-8111-111111111111'`.

## Design facts verified against prod (2026-08-28)

- Season 1 (`2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3`) is `open`, 44 `season_questions`, all pins = current revisions except Bail & Pretrial (pinned rev 1; current rev 3 "Deference to Prosecutors").
- `seasons_dates_follow_status` CHECK: draft = no timestamps; open = opened_at only; closed = both.
- `season_questions`: PK (season_id, topic_id); UNIQUE (season_id, question_number), (season_id, display_order), (season_id, topic_id, topic_revision_id) ← composite-FK target, never drop.
- Scaffold indexes `politician_answers_legacy_pair_scaffold`, `politician_context_legacy_pair_scaffold` are LIVE.
- 33,164 answers / 4,070 politicians in Season 1; values are integers 1–5.
- No season RPCs, routes, or UI exist. `question_number`/`display_order` are labels, not identity.

---

### Task 1: Migration `CA_0022_season_composition_rpcs.sql`

**Files:**
- Create: `backend/migrations/CA_0022_season_composition_rpcs.sql`

**Interfaces:**
- Produces RPCs (all `p_actor_id uuid` for audit symmetry, all return `jsonb`):
  - `inform.admin_create_draft_season(p_actor_id uuid, p_name text, p_public_note text, p_carry_from_open boolean DEFAULT true)` → `{season_id, number, question_count}`
  - `inform.admin_update_draft_season(p_season_id uuid, p_actor_id uuid, p_name text, p_public_note text)` → `{season_id}` (NULL arg = keep)
  - `inform.admin_delete_draft_season(p_season_id uuid, p_actor_id uuid)` → `{deleted_season_id, question_count}`
  - `inform.admin_season_add_topic(p_season_id uuid, p_topic_id uuid, p_actor_id uuid)` → `{topic_id, topic_revision_id, question_number}`
  - `inform.admin_season_remove_topic(p_season_id uuid, p_topic_id uuid, p_actor_id uuid)` → `{removed_topic_id}`
  - `inform.admin_season_repin_topic(p_season_id uuid, p_topic_id uuid, p_actor_id uuid)` → `{repinned boolean, from_revision_id, to_revision_id}`
  - `inform.admin_open_season(p_season_id uuid, p_actor_id uuid)` → `{opened_season_id, closed_season_id, question_count}`
- Error codes (message prefix contract for the route layer): `DRAFT_EXISTS`, `NO_OPEN_SEASON`, `NAME_REQUIRED`, `NOTE_REQUIRED`, `NO_SUCH_SEASON`, `NOT_DRAFT`, `NO_SUCH_TOPIC`, `ALREADY_IN_SEASON`, `NOT_IN_SEASON`, `NO_CURRENT_REVISION`, `EMPTY_SEASON`, `SCAFFOLD_INDEXES_PRESENT`.

Key semantics (the compose-time pin rule): carry/add/re-pin always pin the topic's **current published revision at call time** (`is_current AND status='published'`), never copy the old season's pin. Carrying preserves the source season's `question_number`/`display_order`; adds take max+1; `admin_open_season` renumbers 1..N by `display_order` (two-pass negation to dodge the UNIQUE constraints), closes the incumbent open season, and opens the draft in one transaction. One draft at a time (`DRAFT_EXISTS`).

- [ ] **Step 1: Write the migration** (full SQL below — copy verbatim)

```sql
BEGIN;

-- =============================================================================
-- CA_0022: Season composition RPCs — author a draft season, then open it
-- =============================================================================
-- ADR 0005 deferred "how a season is authored"; this is that, for the
-- single-national-set case (per-jurisdiction stays out of scope, §3.1).
--
-- THE PIN IS SET AT COMPOSE TIME (decision 2026-08-28, Chris Andrews): every
-- write here pins the topic's CURRENT published revision at the moment of the
-- call. A revision published later does not move a draft's pin; the admin sees
-- a "newer revision available" flag and may re-pin explicitly while the season
-- is still draft. season_questions_pin_immutable (CC_0002) already freezes
-- pins once the season leaves draft, so the schema agrees.
--
-- admin_open_season REFUSES while the CC_0002 scaffolding indexes exist:
-- dropping them is rollout step 3 (ADR 0005 §1.6) and irreversible — an
-- explicit operational decision that must not happen as a side effect.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: admin_create_draft_season
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_create_draft_season(
  p_actor_id        UUID,
  p_name            TEXT,
  p_public_note     TEXT,
  p_carry_from_open BOOLEAN DEFAULT TRUE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_open_id  UUID;
  v_new_id   UUID;
  v_number   INTEGER;
  v_missing  TEXT;
  v_count    INTEGER := 0;
BEGIN
  IF p_name IS NULL OR btrim(p_name) = '' THEN
    RAISE EXCEPTION 'NAME_REQUIRED: a season needs a name';
  END IF;
  IF p_public_note IS NULL OR btrim(p_public_note) = '' THEN
    RAISE EXCEPTION 'NOTE_REQUIRED: seasons are a transparency surface (ADR 0005); write the public note first';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'draft') THEN
    RAISE EXCEPTION 'DRAFT_EXISTS: a draft season already exists — edit it or delete it first';
  END IF;

  SELECT id INTO v_open_id FROM inform.seasons WHERE status = 'open';
  IF p_carry_from_open AND v_open_id IS NULL THEN
    RAISE EXCEPTION 'NO_OPEN_SEASON: nothing to carry from — no season is open';
  END IF;

  SELECT COALESCE(max(number), 0) + 1 INTO v_number FROM inform.seasons;

  INSERT INTO inform.seasons (number, name, status, public_note)
  VALUES (v_number, btrim(p_name), 'draft', p_public_note)
  RETURNING id INTO v_new_id;

  IF p_carry_from_open THEN
    -- Compose-time pin: every carried topic needs a current published revision.
    SELECT string_agg(t.topic_key, ', ') INTO v_missing
      FROM inform.season_questions sq
      JOIN inform.compass_topics t ON t.id = sq.topic_id
     WHERE sq.season_id = v_open_id
       AND NOT EXISTS (
         SELECT 1 FROM inform.compass_topic_revisions r
          WHERE r.topic_id = sq.topic_id AND r.is_current AND r.status = 'published');
    IF v_missing IS NOT NULL THEN
      RAISE EXCEPTION 'NO_CURRENT_REVISION: cannot pin at compose time — no current published revision for: %', v_missing;
    END IF;

    INSERT INTO inform.season_questions
      (season_id, topic_id, topic_revision_id, question_number, display_order)
    SELECT v_new_id, sq.topic_id, r.id, sq.question_number, sq.display_order
      FROM inform.season_questions sq
      JOIN inform.compass_topic_revisions r
        ON r.topic_id = sq.topic_id AND r.is_current AND r.status = 'published'
     WHERE sq.season_id = v_open_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
  END IF;

  RETURN jsonb_build_object(
    'season_id', v_new_id, 'number', v_number, 'question_count', v_count);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 2: admin_update_draft_season (NULL argument = keep current value)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_update_draft_season(
  p_season_id   UUID,
  p_actor_id    UUID,
  p_name        TEXT,
  p_public_note TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, only drafts are editable', p_season_id, v_status;
  END IF;
  IF p_name IS NOT NULL AND btrim(p_name) = '' THEN
    RAISE EXCEPTION 'NAME_REQUIRED: a season needs a name';
  END IF;
  IF p_public_note IS NOT NULL AND btrim(p_public_note) = '' THEN
    RAISE EXCEPTION 'NOTE_REQUIRED: the public note cannot be blanked';
  END IF;

  UPDATE inform.seasons
     SET name        = COALESCE(btrim(p_name), name),
         public_note = COALESCE(p_public_note, public_note),
         updated_at  = now()
   WHERE id = p_season_id;

  RETURN jsonb_build_object('season_id', p_season_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 3: admin_delete_draft_season (cascade removes its question rows)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_delete_draft_season(
  p_season_id UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
  v_count  INTEGER;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, only drafts may be deleted', p_season_id, v_status;
  END IF;

  SELECT count(*)::int INTO v_count FROM inform.season_questions WHERE season_id = p_season_id;
  DELETE FROM inform.seasons WHERE id = p_season_id;

  RETURN jsonb_build_object('deleted_season_id', p_season_id, 'question_count', v_count);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 4: admin_season_add_topic — pin the CURRENT revision at call time
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_season_add_topic(
  p_season_id UUID,
  p_topic_id  UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
  v_rev    UUID;
  v_qn     INTEGER;
  v_do     INTEGER;
BEGIN
  -- FOR UPDATE serialises concurrent adds so max()+1 numbering cannot collide.
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its question set is frozen', p_season_id, v_status;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id) THEN
    RAISE EXCEPTION 'NO_SUCH_TOPIC: topic % does not exist', p_topic_id;
  END IF;
  IF EXISTS (SELECT 1 FROM inform.season_questions
              WHERE season_id = p_season_id AND topic_id = p_topic_id) THEN
    RAISE EXCEPTION 'ALREADY_IN_SEASON: topic % is already in this season', p_topic_id;
  END IF;

  SELECT r.id INTO v_rev
    FROM inform.compass_topic_revisions r
   WHERE r.topic_id = p_topic_id AND r.is_current AND r.status = 'published';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has no current published revision to pin', p_topic_id;
  END IF;

  SELECT COALESCE(max(question_number), 0) + 1, COALESCE(max(display_order), 0) + 1
    INTO v_qn, v_do
    FROM inform.season_questions WHERE season_id = p_season_id;

  INSERT INTO inform.season_questions
    (season_id, topic_id, topic_revision_id, question_number, display_order)
  VALUES (p_season_id, p_topic_id, v_rev, v_qn, v_do);

  RETURN jsonb_build_object(
    'topic_id', p_topic_id, 'topic_revision_id', v_rev, 'question_number', v_qn);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 5: admin_season_remove_topic
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_season_remove_topic(
  p_season_id UUID,
  p_topic_id  UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its question set is frozen', p_season_id, v_status;
  END IF;

  DELETE FROM inform.season_questions
   WHERE season_id = p_season_id AND topic_id = p_topic_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_IN_SEASON: topic % is not in this season', p_topic_id;
  END IF;

  RETURN jsonb_build_object('removed_topic_id', p_topic_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 6: admin_season_repin_topic — move a draft pin to the newest revision
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_season_repin_topic(
  p_season_id UUID,
  p_topic_id  UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
  v_old    UUID;
  v_new    UUID;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    -- The season_questions_pin_immutable trigger would refuse anyway; refuse
    -- here first so the caller gets the same NOT_DRAFT code as everywhere else.
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its pins are frozen', p_season_id, v_status;
  END IF;

  SELECT topic_revision_id INTO v_old
    FROM inform.season_questions
   WHERE season_id = p_season_id AND topic_id = p_topic_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_IN_SEASON: topic % is not in this season', p_topic_id;
  END IF;

  SELECT r.id INTO v_new
    FROM inform.compass_topic_revisions r
   WHERE r.topic_id = p_topic_id AND r.is_current AND r.status = 'published';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has no current published revision to pin', p_topic_id;
  END IF;

  IF v_new = v_old THEN
    RETURN jsonb_build_object(
      'repinned', false, 'from_revision_id', v_old, 'to_revision_id', v_new);
  END IF;

  UPDATE inform.season_questions
     SET topic_revision_id = v_new
   WHERE season_id = p_season_id AND topic_id = p_topic_id;

  RETURN jsonb_build_object(
    'repinned', true, 'from_revision_id', v_old, 'to_revision_id', v_new);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 7: admin_open_season — the changeover, one transaction
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_open_season(
  p_season_id UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status  inform.season_status;
  v_count   INTEGER;
  v_closed  UUID;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, only a draft can be opened', p_season_id, v_status;
  END IF;

  SELECT count(*)::int INTO v_count
    FROM inform.season_questions WHERE season_id = p_season_id;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'EMPTY_SEASON: season % has no questions — an empty open season blanks every compass surface', p_season_id;
  END IF;

  -- Rollout interlock (ADR 0005 §1.6 step 3). While the CC_0002 scaffold
  -- indexes exist, the database cannot hold answers in two seasons; opening a
  -- second season would make every write fail at insert time instead. Dropping
  -- the indexes is irreversible and belongs to an explicit ops migration, so
  -- this function refuses rather than "helpfully" dropping them.
  IF EXISTS (
    SELECT 1 FROM pg_indexes
     WHERE schemaname = 'inform'
       AND indexname IN ('politician_answers_legacy_pair_scaffold',
                         'politician_context_legacy_pair_scaffold')
  ) THEN
    RAISE EXCEPTION 'SCAFFOLD_INDEXES_PRESENT: the CC_0002 scaffolding indexes still limit answers to one season. Dropping them is rollout step 3 (ADR 0005 §1.6) and an explicit operational migration — apply that first, then open the season';
  END IF;

  -- Renumber 1..N by display_order. Two passes: the UNIQUE constraints are not
  -- deferrable, so shift out of range first, then land on the final numbers.
  UPDATE inform.season_questions
     SET question_number = -question_number, display_order = -display_order
   WHERE season_id = p_season_id;
  WITH ordered AS (
    SELECT topic_id, row_number() OVER (ORDER BY display_order DESC) AS rn
      FROM inform.season_questions
     WHERE season_id = p_season_id
  )
  UPDATE inform.season_questions sq
     SET question_number = o.rn, display_order = o.rn
    FROM ordered o
   WHERE sq.season_id = p_season_id AND sq.topic_id = o.topic_id;

  -- Close the incumbent, then open the draft. seasons_one_open is checked per
  -- statement, so this order never trips it.
  UPDATE inform.seasons
     SET status = 'closed', closed_at = now(), updated_at = now()
   WHERE status = 'open'
  RETURNING id INTO v_closed;

  UPDATE inform.seasons
     SET status = 'open', opened_at = now(), updated_at = now()
   WHERE id = p_season_id;

  RETURN jsonb_build_object(
    'opened_season_id', p_season_id,
    'closed_season_id', v_closed,
    'question_count', v_count);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 8: Grants — service_role ONLY (authorisation is the API's job)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION inform.admin_create_draft_season(UUID, TEXT, TEXT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_update_draft_season(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_delete_draft_season(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_season_add_topic(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_season_remove_topic(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_season_repin_topic(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_open_season(UUID, UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION inform.admin_create_draft_season(UUID, TEXT, TEXT, BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_update_draft_season(UUID, UUID, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_delete_draft_season(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_season_add_topic(UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_season_remove_topic(UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_season_repin_topic(UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_open_season(UUID, UUID) TO service_role;

-- ---------------------------------------------------------------------------
-- Section 9: Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_missing TEXT[] := '{}';
  v_fn TEXT;
BEGIN
  FOREACH v_fn IN ARRAY ARRAY[
    'admin_create_draft_season', 'admin_update_draft_season',
    'admin_delete_draft_season', 'admin_season_add_topic',
    'admin_season_remove_topic', 'admin_season_repin_topic',
    'admin_open_season'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'inform' AND p.proname = v_fn AND p.prosecdef
    ) THEN
      v_missing := v_missing || v_fn;
    END IF;
  END LOOP;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'CA_0022 INCOMPLETE: missing security-definer functions: %',
      array_to_string(v_missing, ', ');
  END IF;

  -- This migration must not have touched data.
  IF (SELECT count(*) FROM inform.seasons) <> 1 THEN
    RAISE EXCEPTION 'season count changed: expected 1, got %',
      (SELECT count(*) FROM inform.seasons);
  END IF;
  IF (SELECT count(*) FROM inform.season_questions) <> 44 THEN
    RAISE EXCEPTION 'season_questions count changed: expected 44, got %',
      (SELECT count(*) FROM inform.season_questions);
  END IF;

  RAISE NOTICE 'CA_0022 OK — 7 season RPCs, data untouched';
END $$;

COMMIT;
```

- [ ] **Step 2: Numbering check.** Run `git fetch origin && npm run check:migrations --prefix backend`. Expected: OK, 1 added vs origin/master.
- [ ] **Step 3: Dry-run against prod.** From `backend/`: `node scripts/dry-run-migration.mjs migrations/CA_0022_season_composition_rpcs.sql`. Expected: post-verify NOTICE fires, rollback confirmed. Then exercise the RPCs in a rolled-back probe transaction (create draft w/ carry → expect 44 rows; add/remove/repin a topic; open → expect `SCAFFOLD_INDEXES_PRESENT`; verify DRAFT_EXISTS on second create).
- [ ] **Step 4: Commit** `git add backend/migrations/CA_0022_season_composition_rpcs.sql && git commit -m "feat(seasons): CA_0022 season composition RPCs"`.

### Task 2: `seasonCompositionService` — reads

**Files:**
- Create: `backend/src/lib/seasonCompositionService.ts`
- Test: `backend/src/lib/seasonCompositionService.test.ts`

**Interfaces (produces):**

```ts
export interface SeasonRow {
  id: string; number: number; name: string;
  status: 'draft' | 'open' | 'closed';
  opened_at: string | null; closed_at: string | null;
  public_note: string; question_count: number;
}
export interface RevisionContent {
  revision_id: string; revision: number; title: string;
  short_title: string; question_text: string;
  ladder: { value: number; text: string }[];
}
export interface CompositionTopic {
  topic_id: string; topic_key: string;
  current: RevisionContent | null;                      // null = no published current revision
  in_open: { question_number: number; display_order: number; pin: RevisionContent } | null;
  in_draft: { question_number: number; display_order: number; pin: RevisionContent } | null;
  distribution: Record<number, number>;                 // open-season answer counts by value
  answer_total: number;
}
export interface CompositionPayload {
  open_season: SeasonRow | null;
  draft_season: SeasonRow | null;
  topics: CompositionTopic[];
}
export async function listSeasons(): Promise<SeasonRow[]>
export async function getComposition(): Promise<CompositionPayload>
```

Reads go through `pool.query` (the §12 views and season tables are not in the PostgREST types). `getComposition` resolves the open and draft season itself (one of each at most; drafts are capped at one by `DRAFT_EXISTS`), then makes three queries: topic matrix, ladders for all referenced revision ids, distribution for the open season. Classification (carried/changed/…) is deliberately NOT computed here — the UI derives it (Task 5) so both modes share one derivation.

- [ ] **Step 1: Write the failing tests** — mock `pool` via the `vi.hoisted` pattern from `seasonService.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { listSeasons, getComposition } from './seasonCompositionService.js';

beforeEach(() => mockQuery.mockReset());

const OPEN = {
  id: '11111111-1111-4111-8111-111111111111', number: 1, name: 'Season 1',
  status: 'open', opened_at: '2025-01-01', closed_at: null, public_note: 'n', question_count: '2',
};
const DRAFT = {
  id: '22222222-2222-4222-8222-222222222222', number: 2, name: 'Season 2',
  status: 'draft', opened_at: null, closed_at: null, public_note: 'n2', question_count: '1',
};

describe('listSeasons', () => {
  it('returns seasons with numeric question_count', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [OPEN, DRAFT], rowCount: 2 });
    const rows = await listSeasons();
    expect(rows[0].question_count).toBe(2);
    expect(rows[1].status).toBe('draft');
  });
});

describe('getComposition', () => {
  it('assembles topics with pins, ladders and distribution', async () => {
    const topicId = '33333333-3333-4333-8333-333333333333';
    const revA = '44444444-4444-4444-8444-444444444444';  // open pin
    const revB = '55555555-5555-4555-8555-555555555555';  // current + draft pin
    mockQuery
      // 1: seasons
      .mockResolvedValueOnce({ rows: [OPEN, DRAFT], rowCount: 2 })
      // 2: topic matrix
      .mockResolvedValueOnce({ rows: [{
        topic_id: topicId, topic_key: 'healthcare',
        current_revision_id: revB, current_revision: 2,
        current_title: 'Healthcare Access', current_short_title: 'Healthcare',
        current_question: 'Q v2',
        open_qn: 13, open_do: 13, open_pin_id: revA,
        open_pin_revision: 1, open_pin_title: 'Healthcare Access',
        open_pin_short_title: 'Healthcare', open_pin_question: 'Q v1',
        draft_qn: 13, draft_do: 13, draft_pin_id: revB,
        draft_pin_revision: 2, draft_pin_title: 'Healthcare Access',
        draft_pin_short_title: 'Healthcare', draft_pin_question: 'Q v2',
      }], rowCount: 1 })
      // 3: ladders
      .mockResolvedValueOnce({ rows: [
        { topic_revision_id: revA, value: 1, text: 'old rung 1' },
        { topic_revision_id: revB, value: 1, text: 'new rung 1' },
      ], rowCount: 2 })
      // 4: distribution
      .mockResolvedValueOnce({ rows: [
        { topic_id: topicId, value: 1, n: 10 },
        { topic_id: topicId, value: 3, n: 5 },
      ], rowCount: 2 });

    const c = await getComposition();
    expect(c.open_season?.number).toBe(1);
    expect(c.draft_season?.number).toBe(2);
    const t = c.topics[0];
    expect(t.in_open?.pin.revision_id).toBe(revA);
    expect(t.in_open?.pin.ladder).toEqual([{ value: 1, text: 'old rung 1' }]);
    expect(t.in_draft?.pin.revision_id).toBe(revB);
    expect(t.current?.revision_id).toBe(revB);
    expect(t.distribution).toEqual({ 1: 10, 3: 5 });
    expect(t.answer_total).toBe(15);
  });

  it('skips the distribution query when no season is open', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [DRAFT], rowCount: 1 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 });
    const c = await getComposition();
    expect(c.open_season).toBeNull();
    expect(c.topics).toEqual([]);
    expect(mockQuery).toHaveBeenCalledTimes(3);
  });

  it('names the season explicitly in the distribution SQL (check:answer-seasons)', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [OPEN], rowCount: 1 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 });
    await getComposition();
    const distCall = mockQuery.mock.calls[3];
    expect(distCall[0]).toMatch(/season_id\s*=\s*\$1/);
  });
});
```

- [ ] **Step 2: Run to verify failure** — `npx vitest run src/lib/seasonCompositionService.test.ts` from `backend/`. Expected: module not found.
- [ ] **Step 3: Implement** `backend/src/lib/seasonCompositionService.ts`:

```ts
import { pool } from './db.js';

/**
 * Season composition — the reads behind the admin compose/presentation screen.
 *
 * Facts only. carried/changed/dropped/added is a presentation judgement and is
 * derived once, in the admin UI, so the compose grid and the board view cannot
 * disagree. This module answers: which seasons exist, what does each pin say,
 * what is current, and how did politicians answer in the open season.
 *
 * Reads use pool.query directly: seasons, season_questions and the revision
 * tables are not in the generated PostgREST types (matches getCompassLenses).
 */

export interface SeasonRow {
  id: string; number: number; name: string;
  status: 'draft' | 'open' | 'closed';
  opened_at: string | null; closed_at: string | null;
  public_note: string; question_count: number;
}

export interface RevisionContent {
  revision_id: string; revision: number; title: string;
  short_title: string; question_text: string;
  ladder: { value: number; text: string }[];
}

export interface CompositionTopic {
  topic_id: string; topic_key: string;
  current: RevisionContent | null;
  in_open: { question_number: number; display_order: number; pin: RevisionContent } | null;
  in_draft: { question_number: number; display_order: number; pin: RevisionContent } | null;
  distribution: Record<number, number>;
  answer_total: number;
}

export interface CompositionPayload {
  open_season: SeasonRow | null;
  draft_season: SeasonRow | null;
  topics: CompositionTopic[];
}

const SEASONS_SQL = `
  SELECT s.id, s.number, s.name, s.status, s.opened_at, s.closed_at, s.public_note,
         (SELECT count(*) FROM inform.season_questions sq WHERE sq.season_id = s.id) AS question_count
    FROM inform.seasons s
   ORDER BY s.number`;

export async function listSeasons(): Promise<SeasonRow[]> {
  const { rows } = await pool.query(SEASONS_SQL);
  return rows.map((r: Record<string, unknown>) => ({
    ...(r as unknown as SeasonRow),
    question_count: Number(r.question_count ?? 0),
  }));
}

/**
 * One row per topic that has a current published revision OR sits in the open
 * or draft season. LEFT JOINs against NULL season ids simply never match, so
 * "no draft yet" needs no special casing.
 */
const TOPIC_MATRIX_SQL = `
  SELECT t.id AS topic_id, t.topic_key,
         cur.id  AS current_revision_id, cur.revision AS current_revision,
         cur.title AS current_title, cur.short_title AS current_short_title,
         cur.question_text AS current_question,
         osq.question_number AS open_qn, osq.display_order AS open_do,
         opr.id AS open_pin_id, opr.revision AS open_pin_revision,
         opr.title AS open_pin_title, opr.short_title AS open_pin_short_title,
         opr.question_text AS open_pin_question,
         dsq.question_number AS draft_qn, dsq.display_order AS draft_do,
         dpr.id AS draft_pin_id, dpr.revision AS draft_pin_revision,
         dpr.title AS draft_pin_title, dpr.short_title AS draft_pin_short_title,
         dpr.question_text AS draft_pin_question
    FROM inform.compass_topics t
    LEFT JOIN inform.compass_topic_revisions cur
      ON cur.topic_id = t.id AND cur.is_current AND cur.status = 'published'
    LEFT JOIN inform.season_questions osq
      ON osq.season_id = $1::uuid AND osq.topic_id = t.id
    LEFT JOIN inform.compass_topic_revisions opr ON opr.id = osq.topic_revision_id
    LEFT JOIN inform.season_questions dsq
      ON dsq.season_id = $2::uuid AND dsq.topic_id = t.id
    LEFT JOIN inform.compass_topic_revisions dpr ON dpr.id = dsq.topic_revision_id
   WHERE cur.id IS NOT NULL OR osq.topic_id IS NOT NULL OR dsq.topic_id IS NOT NULL
   ORDER BY COALESCE(osq.display_order, dsq.display_order, 2147483647), t.topic_key`;

const LADDERS_SQL = `
  SELECT sr.topic_revision_id, sr.value::int AS value, sr.text
    FROM inform.compass_stance_revisions sr
   WHERE sr.topic_revision_id = ANY($1::uuid[])
   ORDER BY sr.value`;

/**
 * Answer distribution for ONE named season (the open one). The season is a
 * parameter, never inferred from the pair — a bare (politician_id, topic_id)
 * read fans out the moment a second season exists (ADR 0005 §1.2).
 */
const DISTRIBUTION_SQL = `
  SELECT a.topic_id, a.value::int AS value, count(*)::int AS n
    FROM inform.politician_answers a
   WHERE a.season_id = $1::uuid
   GROUP BY a.topic_id, a.value`;

export async function getComposition(): Promise<CompositionPayload> {
  const seasons = await listSeasons();
  const open = seasons.find((s) => s.status === 'open') ?? null;
  const draft = seasons.find((s) => s.status === 'draft') ?? null;

  const { rows: matrix } = await pool.query(TOPIC_MATRIX_SQL, [
    open?.id ?? null, draft?.id ?? null,
  ]);

  const revisionIds = new Set<string>();
  for (const r of matrix) {
    for (const id of [r.current_revision_id, r.open_pin_id, r.draft_pin_id]) {
      if (id) revisionIds.add(id as string);
    }
  }
  const { rows: ladderRows } = await pool.query(LADDERS_SQL, [[...revisionIds]]);
  const ladders = new Map<string, { value: number; text: string }[]>();
  for (const row of ladderRows) {
    const list = ladders.get(row.topic_revision_id) ?? [];
    list.push({ value: row.value, text: row.text });
    ladders.set(row.topic_revision_id, list);
  }

  const dist = new Map<string, Record<number, number>>();
  if (open) {
    const { rows: distRows } = await pool.query(DISTRIBUTION_SQL, [open.id]);
    for (const row of distRows) {
      const d = dist.get(row.topic_id) ?? {};
      d[row.value] = row.n;
      dist.set(row.topic_id, d);
    }
  }

  const content = (
    id: string | null, revision: number | null, title: string | null,
    shortTitle: string | null, question: string | null,
  ): RevisionContent | null =>
    id == null ? null : {
      revision_id: id, revision: revision ?? 0, title: title ?? '',
      short_title: shortTitle ?? '', question_text: question ?? '',
      ladder: ladders.get(id) ?? [],
    };

  const topics: CompositionTopic[] = matrix.map((r) => {
    const d = dist.get(r.topic_id) ?? {};
    const openPin = content(r.open_pin_id, r.open_pin_revision, r.open_pin_title,
      r.open_pin_short_title, r.open_pin_question);
    const draftPin = content(r.draft_pin_id, r.draft_pin_revision, r.draft_pin_title,
      r.draft_pin_short_title, r.draft_pin_question);
    return {
      topic_id: r.topic_id,
      topic_key: r.topic_key,
      current: content(r.current_revision_id, r.current_revision, r.current_title,
        r.current_short_title, r.current_question),
      in_open: openPin == null ? null
        : { question_number: r.open_qn, display_order: r.open_do, pin: openPin },
      in_draft: draftPin == null ? null
        : { question_number: r.draft_qn, display_order: r.draft_do, pin: draftPin },
      distribution: d,
      answer_total: Object.values(d).reduce((a, b) => a + b, 0),
    };
  });

  return { open_season: open, draft_season: draft, topics };
}
```

- [ ] **Step 4: Run tests** — expected PASS.
- [ ] **Step 5: Commit** `feat(seasons): composition read service`.

### Task 3: `seasonCompositionService` — mutations (adminRpc wrappers)

**Files:**
- Modify: `backend/src/lib/seasonCompositionService.ts` (append)
- Test: `backend/src/lib/seasonCompositionService.test.ts` (append)

**Interfaces (produces):**

```ts
export async function createDraftSeason(actorId: string, name: string, publicNote: string, carryFromOpen: boolean):
  Promise<{ season_id: string; number: number; question_count: number }>
export async function updateDraftSeason(seasonId: string, actorId: string, name: string | null, publicNote: string | null):
  Promise<{ season_id: string }>
export async function deleteDraftSeason(seasonId: string, actorId: string):
  Promise<{ deleted_season_id: string; question_count: number }>
export async function addTopicToSeason(seasonId: string, topicId: string, actorId: string):
  Promise<{ topic_id: string; topic_revision_id: string; question_number: number }>
export async function removeTopicFromSeason(seasonId: string, topicId: string, actorId: string):
  Promise<{ removed_topic_id: string }>
export async function repinTopic(seasonId: string, topicId: string, actorId: string):
  Promise<{ repinned: boolean; from_revision_id: string; to_revision_id: string }>
export async function openSeason(seasonId: string, actorId: string):
  Promise<{ opened_season_id: string; closed_season_id: string | null; question_count: number }>
```

All follow the `approveRevision` contract: call `adminRpc(fn, args, 'inform')`, `if (error) throw new Error(error.message)` (the `NAMED_CODE:` prefix is the route contract), return `data`.

- [ ] **Step 1: Append failing tests** — add to the existing test file a hoisted `mockAdminRpc`, `vi.mock('./supabase.js', () => ({ adminRpc: mockAdminRpc }))`:

```ts
const { mockAdminRpc } = vi.hoisted(() => ({ mockAdminRpc: vi.fn() }));
vi.mock('./supabase.js', () => ({ adminRpc: mockAdminRpc }));
// (import the mutation fns in the main import block)

describe('mutations', () => {
  beforeEach(() => mockAdminRpc.mockReset());

  it('createDraftSeason calls the RPC in the inform schema and returns data', async () => {
    mockAdminRpc.mockResolvedValueOnce({ data: { season_id: 's', number: 2, question_count: 44 }, error: null });
    const out = await createDraftSeason('actor', 'Season 2', 'note', true);
    expect(mockAdminRpc).toHaveBeenCalledWith('admin_create_draft_season',
      { p_actor_id: 'actor', p_name: 'Season 2', p_public_note: 'note', p_carry_from_open: true },
      'inform');
    expect(out.question_count).toBe(44);
  });

  it('rethrows the RPC error message unchanged (route maps the prefix)', async () => {
    mockAdminRpc.mockResolvedValueOnce({ data: null, error: { message: 'DRAFT_EXISTS: a draft season already exists — edit it or delete it first' } });
    await expect(createDraftSeason('a', 'n', 'p', true)).rejects.toThrow(/^DRAFT_EXISTS:/);
  });

  it('openSeason passes ids through', async () => {
    mockAdminRpc.mockResolvedValueOnce({ data: { opened_season_id: 'x', closed_season_id: 'y', question_count: 44 }, error: null });
    const out = await openSeason('x', 'actor');
    expect(mockAdminRpc).toHaveBeenCalledWith('admin_open_season',
      { p_season_id: 'x', p_actor_id: 'actor' }, 'inform');
    expect(out.closed_season_id).toBe('y');
  });
});
```

- [ ] **Step 2: Run to verify failure.**
- [ ] **Step 3: Implement** — append to the service:

```ts
import { adminRpc } from './supabase.js';   // (top of file)

/** Rethrow contract: the RPC's own 'NAMED_CODE: sentence' message, unchanged. */
async function seasonRpc<T>(fn: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await adminRpc(fn, args, 'inform');
  if (error) throw new Error(error.message);
  return data as T;
}

export async function createDraftSeason(
  actorId: string, name: string, publicNote: string, carryFromOpen: boolean,
): Promise<{ season_id: string; number: number; question_count: number }> {
  return seasonRpc('admin_create_draft_season', {
    p_actor_id: actorId, p_name: name, p_public_note: publicNote,
    p_carry_from_open: carryFromOpen,
  });
}

export async function updateDraftSeason(
  seasonId: string, actorId: string, name: string | null, publicNote: string | null,
): Promise<{ season_id: string }> {
  return seasonRpc('admin_update_draft_season', {
    p_season_id: seasonId, p_actor_id: actorId, p_name: name, p_public_note: publicNote,
  });
}

export async function deleteDraftSeason(
  seasonId: string, actorId: string,
): Promise<{ deleted_season_id: string; question_count: number }> {
  return seasonRpc('admin_delete_draft_season', { p_season_id: seasonId, p_actor_id: actorId });
}

export async function addTopicToSeason(
  seasonId: string, topicId: string, actorId: string,
): Promise<{ topic_id: string; topic_revision_id: string; question_number: number }> {
  return seasonRpc('admin_season_add_topic', {
    p_season_id: seasonId, p_topic_id: topicId, p_actor_id: actorId,
  });
}

export async function removeTopicFromSeason(
  seasonId: string, topicId: string, actorId: string,
): Promise<{ removed_topic_id: string }> {
  return seasonRpc('admin_season_remove_topic', {
    p_season_id: seasonId, p_topic_id: topicId, p_actor_id: actorId,
  });
}

export async function repinTopic(
  seasonId: string, topicId: string, actorId: string,
): Promise<{ repinned: boolean; from_revision_id: string; to_revision_id: string }> {
  return seasonRpc('admin_season_repin_topic', {
    p_season_id: seasonId, p_topic_id: topicId, p_actor_id: actorId,
  });
}

export async function openSeason(
  seasonId: string, actorId: string,
): Promise<{ opened_season_id: string; closed_season_id: string | null; question_count: number }> {
  return seasonRpc('admin_open_season', { p_season_id: seasonId, p_actor_id: actorId });
}
```

- [ ] **Step 4: Run tests** — PASS. (Reads tests must still pass; the new `vi.mock('./supabase.js')` is additive.)
- [ ] **Step 5: Commit** `feat(seasons): composition mutation wrappers`.

### Task 4: Router `/api/admin/seasons`

**Files:**
- Create: `backend/src/routes/seasonsAdmin.ts`
- Modify: `backend/src/index.ts` (import + mount before the generic `adminRouter` mounts, beside line ~132)
- Modify: `backend/src/lambda/api.ts` if it mirrors mounts (check; mirror the same mount)
- Test: `backend/src/routes/seasonsAdmin.test.ts`

**Interfaces (produces the HTTP API the admin UI consumes):**
- `GET  /api/admin/seasons` → `{ seasons: SeasonRow[] }`
- `GET  /api/admin/seasons/composition` → `CompositionPayload`
- `POST /api/admin/seasons/draft` `{name, public_note, carry_from_open}` → create result
- `PATCH /api/admin/seasons/draft/:id` `{name?, public_note?}`
- `DELETE /api/admin/seasons/draft/:id`
- `POST /api/admin/seasons/draft/:id/topics` `{topic_id}`
- `DELETE /api/admin/seasons/draft/:id/topics/:topicId`
- `POST /api/admin/seasons/draft/:id/topics/:topicId/repin`
- `POST /api/admin/seasons/draft/:id/open`

All behind `requireAuth, requireCompassReviewer` (router-level). Mutations log `logAdminAction(actorId, 'compass:season:<verb>', null, {..., capacity: reviewerCapacity(req)})`. Error mapping copies `compassRevisions.sendRpcError` with this map:

```ts
const CLIENT_ERRORS: Record<string, number> = {
  NO_SUCH_SEASON: 404, NO_SUCH_TOPIC: 404, NOT_IN_SEASON: 404,
  NOT_DRAFT: 409, DRAFT_EXISTS: 409, ALREADY_IN_SEASON: 409,
  NO_OPEN_SEASON: 409, NO_CURRENT_REVISION: 409, EMPTY_SEASON: 409,
  SCAFFOLD_INDEXES_PRESENT: 409, PIN_IMMUTABLE: 409,
  NAME_REQUIRED: 422, NOTE_REQUIRED: 422,
};
```

- [ ] **Step 1: Write failing route tests** (`seasonsAdmin.test.ts`) using the supertest pattern; mock `../lib/db.js`, `../lib/supabase.js`, `../middleware/auth.js` (sets `req.userId = 'admin-1'`), `../middleware/requireCompassReviewer.js` (`requireCompassReviewer: (req,_res,next)=>{(req as any).reviewerCapacity='admin';next();}`, `reviewerCapacity: () => 'admin'`), `../lib/adminService.js` (`logAdminAction: vi.fn()`), and `../lib/seasonCompositionService.js` (every exported fn `vi.fn()`). Cases:
  - `GET /api/admin/seasons` 200 returns `{seasons}` from the service.
  - `GET /api/admin/seasons/composition` 200 passthrough.
  - `POST /draft` with missing name → 422 (zod), does not call the service.
  - `POST /draft` happy path → 201, `logAdminAction` called with `capacity: 'admin'` and action `compass:season:create-draft`.
  - `POST /draft` service throws `Error('DRAFT_EXISTS: …')` → 409 `{code:'DRAFT_EXISTS'}`.
  - `POST /draft/:id/open` service throws `SCAFFOLD_INDEXES_PRESENT: …` → 409 with the human message preserved.
  - `POST /draft/:id/topics` invalid uuid → 422 `VALIDATION_ERROR`.
  - `DELETE /draft/:id/topics/:topicId` happy path → 200, logs `compass:season:remove-topic`.
  - Unknown RPC error → 500 `INTERNAL_ERROR`.
- [ ] **Step 2: Run to verify failure.**
- [ ] **Step 3: Implement the router:**

```ts
import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import {
  requireCompassReviewer,
  reviewerCapacity,
} from '../middleware/requireCompassReviewer.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  listSeasons, getComposition,
  createDraftSeason, updateDraftSeason, deleteDraftSeason,
  addTopicToSeason, removeTopicFromSeason, repinTopic, openSeason,
} from '../lib/seasonCompositionService.js';

/**
 * Season composition (ADR 0005: "how a season is authored", national set only).
 * Reviewer-gated like compassRevisions — composing a season is the same
 * editorial act as publishing a revision, and records the same capacity.
 */
const router = Router();
router.use(requireAuth, requireCompassReviewer);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const createSchema = z.object({
  name: z.string().trim().min(1).max(120),
  public_note: z.string().trim().min(1).max(4000),
  carry_from_open: z.boolean().default(true),
});
const updateSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  public_note: z.string().trim().min(1).max(4000).optional(),
}).refine((b) => b.name !== undefined || b.public_note !== undefined, {
  message: 'nothing to update',
});
const addTopicSchema = z.object({
  topic_id: z.string().regex(UUID_RE, 'Invalid topic id'),
});

/** RPC error names that are the caller's fault; anything else is a real 500. */
const CLIENT_ERRORS: Record<string, number> = {
  NO_SUCH_SEASON: 404, NO_SUCH_TOPIC: 404, NOT_IN_SEASON: 404,
  NOT_DRAFT: 409, DRAFT_EXISTS: 409, ALREADY_IN_SEASON: 409,
  NO_OPEN_SEASON: 409, NO_CURRENT_REVISION: 409, EMPTY_SEASON: 409,
  SCAFFOLD_INDEXES_PRESENT: 409, PIN_IMMUTABLE: 409,
  NAME_REQUIRED: 422, NOTE_REQUIRED: 422,
};

function sendRpcError(res: Response, err: unknown, where: string): void {
  const message = err instanceof Error ? err.message : String(err);
  const code = message.split(':')[0]?.trim() ?? '';
  const status = CLIENT_ERRORS[code];
  if (status) {
    res.status(status).json({ code, message: message.replace(/^[A-Z_]+:\s*/, '') });
    return;
  }
  console.error(`[${where}] unexpected error:`, err);
  res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
}

function invalidId(res: Response, what: string): void {
  res.status(422).json({ code: 'VALIDATION_ERROR', message: `Invalid ${what}` });
}

router.get('/', async (_req: Request, res: Response): Promise<void> => {
  try {
    res.json({ seasons: await listSeasons() });
  } catch (err) {
    sendRpcError(res, err, 'GET /admin/seasons');
  }
});

router.get('/composition', async (_req: Request, res: Response): Promise<void> => {
  try {
    res.json(await getComposition());
  } catch (err) {
    sendRpcError(res, err, 'GET /admin/seasons/composition');
  }
});

router.post('/draft', async (req: Request, res: Response): Promise<void> => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.issues[0]?.message ?? 'Invalid body' });
    return;
  }
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await createDraftSeason(
      actorId, parsed.data.name, parsed.data.public_note, parsed.data.carry_from_open);
    await logAdminAction(actorId, 'compass:season:create-draft', null, {
      season_id: out.season_id, number: out.number,
      question_count: out.question_count, carry_from_open: parsed.data.carry_from_open,
      capacity: reviewerCapacity(req),
    });
    res.status(201).json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft');
  }
});

router.patch('/draft/:id', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.issues[0]?.message ?? 'Invalid body' });
    return;
  }
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await updateDraftSeason(
      id, actorId, parsed.data.name ?? null, parsed.data.public_note ?? null);
    await logAdminAction(actorId, 'compass:season:update-draft', null, {
      season_id: id, capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'PATCH /admin/seasons/draft/:id');
  }
});

router.delete('/draft/:id', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await deleteDraftSeason(id, actorId);
    await logAdminAction(actorId, 'compass:season:delete-draft', null, {
      season_id: id, question_count: out.question_count, capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'DELETE /admin/seasons/draft/:id');
  }
});

router.post('/draft/:id/topics', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const parsed = addTopicSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.issues[0]?.message ?? 'Invalid body' });
    return;
  }
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await addTopicToSeason(id, parsed.data.topic_id, actorId);
    await logAdminAction(actorId, 'compass:season:add-topic', null, {
      season_id: id, topic_id: parsed.data.topic_id,
      pinned_revision_id: out.topic_revision_id, capacity: reviewerCapacity(req),
    });
    res.status(201).json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft/:id/topics');
  }
});

router.delete('/draft/:id/topics/:topicId', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const topicId = req.params.topicId as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  if (!UUID_RE.test(topicId)) return invalidId(res, 'topic id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await removeTopicFromSeason(id, topicId, actorId);
    await logAdminAction(actorId, 'compass:season:remove-topic', null, {
      season_id: id, topic_id: topicId, capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'DELETE /admin/seasons/draft/:id/topics/:topicId');
  }
});

router.post('/draft/:id/topics/:topicId/repin', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const topicId = req.params.topicId as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  if (!UUID_RE.test(topicId)) return invalidId(res, 'topic id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await repinTopic(id, topicId, actorId);
    await logAdminAction(actorId, 'compass:season:repin-topic', null, {
      season_id: id, topic_id: topicId, repinned: out.repinned,
      from_revision_id: out.from_revision_id, to_revision_id: out.to_revision_id,
      capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft/:id/topics/:topicId/repin');
  }
});

router.post('/draft/:id/open', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await openSeason(id, actorId);
    await logAdminAction(actorId, 'compass:season:open', null, {
      opened_season_id: out.opened_season_id, closed_season_id: out.closed_season_id,
      question_count: out.question_count, capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft/:id/open');
  }
});

export default router;
```

Mount in `backend/src/index.ts` beside the other admin mounts (BEFORE the bare `/api/admin` routers so the longer prefix wins is not required — Express matches by path — but keep the admin block tidy):

```ts
import seasonsAdminRouter from './routes/seasonsAdmin.js';
// ...
app.use('/api/admin/seasons', seasonsAdminRouter);
```

Mirror in `backend/src/lambda/api.ts` if that file lists mounts explicitly (read it first).

- [ ] **Step 4: Run route tests** — PASS.
- [ ] **Step 5: Commit** `feat(seasons): /api/admin/seasons composition router`.

### Task 5: Admin UI pure module — classification

**Files:**
- Create: `admin/src/pages/admin/seasonComposition.ts`
- Test: `admin/src/pages/admin/seasonComposition.test.ts`

**Interfaces (produces — mirrors the server payload plus derivation):**

```ts
export type TopicStatus = 'carried' | 'changed' | 'dropped' | 'added' | 'available';
export interface Classified { topic: CompositionTopic; status: TopicStatus; pin_is_stale: boolean; }
export function classifyTopic(t: CompositionTopic, hasDraft: boolean): Classified
export function classifyAll(topics: CompositionTopic[], hasDraft: boolean): Classified[]
export function statCounts(rows: Classified[]): { carried: number; changed: number; dropped: number; added: number }
// plus: SeasonRow, RevisionContent, CompositionTopic, CompositionPayload
// type definitions duplicated from the backend service (admin has no shared
// types package; TopicsPage duplicates its Topic type the same way).
```

Rules (with no draft, everything in the open season is `carried` and nothing is `dropped`/`added` — the presentation view of Season 1 alone):
- in_open && in_draft && same pin → `carried`
- in_open && in_draft && different pin → `changed`
- in_open && !in_draft → hasDraft ? `dropped` : `carried`
- !in_open && in_draft → `added`
- !in_open && !in_draft → `available` (topic pool)
- `pin_is_stale` = `in_draft && current && in_draft.pin.revision_id !== current.revision_id`

- [ ] **Step 1: Write the failing tests** — pure-data fixtures, cover all five statuses, the no-draft collapse (`dropped`→`carried`), stale-pin flag, and statCounts. Use a `mk()` fixture helper so each case is 3 lines.
- [ ] **Step 2: Run** `npm test --prefix admin` — FAIL (module missing).
- [ ] **Step 3: Implement** the module exactly per the rules table.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat(admin): season composition classification module`.

### Task 6: Admin UI — SeasonCompositionPage (compose mode)

**Files:**
- Create: `admin/src/pages/admin/SeasonCompositionPage.tsx`
- Modify: `admin/src/App.tsx` (import + `<Route path="seasons" element={<SeasonCompositionPage />} />` in the `/admin` block)
- Modify: `admin/src/components/AdminLayout.tsx` (`{ label: 'Seasons', to: '/admin/seasons' }` in `navItems`)

**Consumes:** `apiFetch` (admin/src/lib/api.ts), `diffWords`/`hasChanged` (admin/src/lib/wordDiff.ts), Task 5 module, HeadlessUI `Dialog`.

Page structure (single fetch of `/admin/seasons/composition` into state; `reload()` after each mutation; `busy` disables buttons; errors surfaced in an amber `role="alert"` banner like TopicRevisionReviewPage):

1. **Header row**: title "Season composition", open-season card (name, number, count, opened_at), draft card:
   - no draft → "Start Season N+1 draft" button → HeadlessUI create modal (name prefilled `Season {N+1}`, public_note textarea, carry_from_open checkbox default on) → `POST /admin/seasons/draft`.
   - draft exists → name/note inline edit (PATCH), "Delete draft" (confirm dialog → DELETE), "Open season…" (confirm dialog quoting the consequences: closes Season N, freezes pins; surfaces `SCAFFOLD_INDEXES_PRESENT` 409 message verbatim in the dialog) → `POST /draft/:id/open`.
2. **Stat band**: carried / changed / dropped / added from `statCounts` (colored like the approved board design: green/amber/gray/teal).
3. **Bridge**: two columns (open season | draft). Rows from `classifyAll` sorted by display_order. Row = number, short_title (current content), status badge, mini distribution bar (open column only, colors `#2f6fb0 #59B0C4 #9ca3af #e0a63a #FF5740`), and compose actions in the draft column:
   - carried/changed row → "Drop" button (DELETE topic)
   - dropped row (rendered struck-through in draft column) → "Re-add" (POST topic)
   - stale pin (`pin_is_stale`) → amber "rev {pin} → {current} available" chip + "Re-pin" button (POST repin)
4. **Add topics** section under the draft column: `available` topics with "Add" buttons.
5. **Detail modal** (HeadlessUI, `max-w-3xl max-h-[90vh] overflow-y-auto`): opens on row click; shows category chip, title, question, five options with distribution bars (open-season data), and for `changed`/stale pins a field-by-field word diff (title, short_title, question_text via `diffWords`, using the INS/DEL classes from TopicRevisionReviewPage; ladder rungs diffed pairwise by value when texts differ per `hasChanged`).
6. **Mode toggle** button "Presentation view" (Task 7) — `?view=presentation` via `useSearchParams`.

No component tests (none exist in the app); all logic lives in Task 5's tested module. Keep every `dark:` variant in compose mode like sibling pages.

- [ ] **Step 1: Implement the page** per structure above.
- [ ] **Step 2: Register route + nav.**
- [ ] **Step 3: Typecheck + build**: `npx tsc --noEmit && npm run build` in `admin/`. PASS.
- [ ] **Step 4: Visual verify** via the temp vite harness with stubbed fetch (memory: no dev auth bypass — stub `apiFetch`-level fetch with a canned CompositionPayload built from the real prod data snapshot) OR against the local backend if running. Screenshot compose mode.
- [ ] **Step 5: Commit** `feat(admin): season composition page (compose mode)`.

### Task 7: Presentation mode

**Files:**
- Modify: `admin/src/pages/admin/SeasonCompositionPage.tsx` (presentation subtree)

Render the approved board design (round-3 prototype) from the SAME `CompositionPayload` + `classifyAll` output:
- On mount of presentation mode: add `dark` class to `document.documentElement`; restore prior state on exit (the HeadlessUI modal portals to `<body>`, so forcing the class at the root is what keeps the modal dark).
- Full-width dark hero (`bg-[#17181a]` page, panels `#212226`): eyebrow "Empowered Compass · Board review", title "Season {draft.number}: what's changing", the four big stat blocks, equation line `{open.count} − {dropped} + {added} = {draft.count}`.
- Two season columns (name + status pill + count), every row clickable → the same detail modal as compose mode; retired rows struck through; changed rows amber; added rows teal; mini distribution bars on open-season rows; the option-color legend.
- No compose actions, no draft-management buttons — read-only.
- "Exit presentation" pill fixed bottom-right (returns to `?view=` unset).
- If there is no draft season: presentation mode shows Season 1 alone with all rows `carried` and the equation hidden (statCounts already collapses correctly per Task 5).

- [ ] **Step 1: Implement.**
- [ ] **Step 2: Typecheck + build + visual verify** both modes (screenshot presentation view; verify a changed topic's modal shows the S1→S2 diff).
- [ ] **Step 3: Commit** `feat(admin): season composition presentation view`.

### Task 8: Full verification, prod apply, cleanup, PR

- [ ] **Step 1: Backend gates**: from `backend/`: `npm run typecheck && npm run lint && npm run test:unit && npm run check:migrations && npm run check:answer-seasons`. All PASS (fix anything that isn't).
- [ ] **Step 2: Admin gates**: from `admin/`: `npx tsc --noEmit && npm run build && npm test`. All PASS.
- [ ] **Step 3: Apply CA_0022 to prod** (functions only, additive): run the migration via the dry-run script's apply mode or psql equivalent; verify the post-verify NOTICE; then add the `-- ✅ APPLIED TO PRODUCTION 2026-08-28` header (house style) and re-commit.
- [ ] **Step 4: Live smoke** — with the backend pointing at prod (read-only endpoints): `GET /api/admin/seasons/composition` returns 44 topics, Bail & Pretrial shows open pin rev 1 / current rev 3.
- [ ] **Step 5: Delete the prototype** `admin/prototypes/season-composition-board.prototype.html` (its answer — the approved design — now lives in the page; note this in the PR).
- [ ] **Step 6: PR** to `master` via `gh pr create`: title `feat(compass): season composition — compose a draft season, board presentation view`; body covers the decided shape, the compose-time pin rule, the scaffold interlock refusal, verification evidence. Do not touch PRs #206/#207.

## Self-review notes

- Spec coverage: one screen/two modes (T6+T7), draft lifecycle reuse (T1 §7), four categories (T5), revision diff reuse (T6 modal via wordDiff), per-jurisdiction excluded (nowhere added), pin-at-compose (T1 semantics + repin), board-informal-review (open action logs capacity; no new gate table), add-from-pool only (`available` = topics with current revision not in draft; authoring brand-new topics stays in the compass-topic-builder skill / revision workflow — the page links nowhere else).
- Open question 4 (diff scope): title/short_title/question_text + ladder rung diffs shown together in one modal, sectioned — matches TopicRevisionReviewPage's field-by-field pattern.
- Type consistency: `CompositionTopic`/`RevisionContent` defined once in T2, duplicated verbatim in T5 for the frontend (house pattern: no shared types package).
