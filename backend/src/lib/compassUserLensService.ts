/**
 * compassUserLensService — custom (user-authored) compass lenses.
 *
 * Two jobs, and the second is the interesting one:
 *
 *   1. Store and return a user's named lenses (migration 1849).
 *   2. Tell the owner which topics in a lens they need to RECALIBRATE, and never
 *      invalidate the lens itself.
 *
 * WHY A LENS IS NEVER INVALIDATED BY A SEASON.
 * PUT /selected-topics validates against `getPromotedTopics()` — the open season's
 * question set — and 422s anything outside it. That is right for the live compass
 * and wrong for a saved lens: a lens is a thing the user made and named, and a
 * season rollover silently emptying it is a data-loss bug wearing a validation
 * costume. So lens writes validate only that a topic EXISTS, and the staleness
 * question is answered on read, as a prompt.
 *
 * THE RECALIBRATION RULE (Chris, 2026-08-29) AND HOW ADR 0006 ALREADY ENCODES IT.
 * "If the question wasn't updated, or the answer or the answers either side of
 * theirs weren't changed, we don't need to update it."
 *
 * ADR 0006 §2 makes the first half free. `editorial` and `clarifying` revisions do
 * NOT bump `version`, so a season bound to that version picks them up immediately
 * and the answer's stamped revision still resolves to the same version — those can
 * never raise a flag, without this file testing `change_class` at all.
 * `substantive` revisions DO bump `version`, and only a new season shows them. So:
 *
 *   version(answered_revision) === version(effective_revision)  →  nothing to do.
 *
 * That leaves the second half, which is a genuine narrowing: even across a version
 * bump, if the rungs at and adjacent to the user's answer are untouched, their
 * calibration still means what it meant. Only then do we ask them to recalibrate.
 *
 * 🔴 THE RUNG NEIGHBOURHOOD IS [floor(v) - 1, ceil(v) + 1], CLAMPED TO 1..5, AND
 * THE floor/ceil PAIR IS NOT DECORATION. Compass values run 0.5–5.5 in half steps:
 * a whole number is one of the 5 pre-written stances, and a half value is a
 * write-in sitting BETWEEN two rungs — so at 2.5 the user's own answer spans rungs
 * 2 and 3 and the neighbourhood must reach 1 through 4. The single formula covers
 * both cases and the 0.5 / 5.5 edges collapse correctly against the clamp.
 *
 * DISPOSITION VOCABULARY IS BORROWED, NOT REINVENTED. compassRevisionService
 * resolves a rung's fate from `rung_map` as unchanged | reworded | moved |
 * replaced. The same words mean the same things here; the difference is only which
 * two revisions are compared — there, current vs proposed for a reviewer; here,
 * the revision the user ANSWERED against vs the one their season now serves.
 *
 * All reads go through `pool` (lib/db.ts). inform.compass_user_lenses is RLS-on
 * with no policies and no grants, exactly like inform.compass_lenses — PostgREST
 * cannot see it, and `WHERE owner_id = $1` is the enforcement, matching
 * saveSelectedTopics().
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface UserLens {
  key: string;
  name: string;
  topicIds: string[];
  visibility: 'private' | 'unlisted';
  createdAt: string;
  updatedAt: string;
}

export interface UserLensInput {
  key: string;
  name: string;
  topic_ids: string[];
  visibility?: 'private' | 'unlisted';
}

/** Why a topic in a lens is asking for the owner's attention. */
export type RecalibrationReason =
  /** The wording moved to a new major version and the rungs near their answer changed. */
  | 'question_revised'
  /** The rung they sat on no longer exists in the new ladder. */
  | 'answer_invalidated'
  /** The topic is not in the open season's question set at all. */
  | 'not_asked_this_season';

export interface RecalibrationFlag {
  topicId: string;
  reason: RecalibrationReason;
  /** The user's stored value, so the UI can show what it is asking them to revisit. */
  currentValue: number | null;
  /** Editorial's own words for what changed. Empty string when there is no note. */
  publicNote: string;
  /** Version they answered against → version their season now serves. */
  answeredVersion: number | null;
  effectiveVersion: number | null;
}

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

/**
 * A user's lenses, newest last (creation order — the order they built them in,
 * which is the order the management UI lists them in).
 */
export async function getUserLenses(ownerId: string): Promise<UserLens[]> {
  const { rows } = await pool.query(
    `SELECT key, name, topic_ids, visibility, created_at, updated_at
       FROM inform.compass_user_lenses
      WHERE owner_id = $1
      ORDER BY created_at, key`,
    [ownerId]
  );

  return rows.map(mapLens);
}

/**
 * Which of these topic ids do not exist at all.
 *
 * Deliberately NOT `validateTopicIds()`, which checks membership in the open
 * season's promoted set. A lens is allowed to hold a topic this season does not
 * ask — that is a recalibration prompt, not a validation error. What a lens may
 * never hold is an id that names nothing.
 */
export async function findUnknownTopicIds(topicIds: string[]): Promise<string[]> {
  if (topicIds.length === 0) return [];

  const unique = [...new Set(topicIds)];
  const { rows } = await pool.query<{ id: string }>(
    `SELECT t.id::text AS id
       FROM unnest($1::uuid[]) AS t(id)
      WHERE NOT EXISTS (
        SELECT 1 FROM inform.compass_topics ct WHERE ct.id = t.id
      )`,
    [unique]
  );

  return rows.map(r => r.id);
}

// ---------------------------------------------------------------------------
// Writes
// ---------------------------------------------------------------------------

/** Raised when a requested lens key is already held by a different owner. */
export class LensKeyConflictError extends Error {
  readonly code = 'LENS_KEY_TAKEN';
  constructor(readonly keys: string[]) {
    super(`Lens key already in use: ${keys.join(', ')}`);
    this.name = 'LensKeyConflictError';
  }
}

export function isLensKeyConflictError(e: unknown): e is LensKeyConflictError {
  return e instanceof LensKeyConflictError;
}

/** Which of these keys exist and belong to somebody other than `ownerId`. */
async function findKeysOwnedByOthers(ownerId: string, keys: string[]): Promise<string[]> {
  if (keys.length === 0) return [];

  const { rows } = await pool.query<{ key: string }>(
    `SELECT key FROM inform.compass_user_lenses
      WHERE key = ANY($2::text[]) AND owner_id <> $1`,
    [ownerId, keys]
  );

  return rows.map(r => r.key);
}

/**
 * Replace the owner's entire lens set.
 *
 * Whole-set replace, not per-lens CRUD, because that is how the client holds them:
 * a guest builds lenses in local storage with no server round-trip, and sign-in
 * promotes the whole collection at once. Per-lens endpoints would make that
 * promotion an N-request loop that can half-fail.
 *
 * Runs in one transaction so a failed promotion leaves the previous set intact
 * rather than a partially-written one. `created_at` is preserved across a rewrite
 * of an existing key — the lens is the same lens, so its age should not reset
 * every time the user renames it or reorders a topic.
 */
export async function replaceUserLenses(
  ownerId: string,
  lenses: UserLensInput[]
): Promise<UserLens[]> {
  // 🔴 CHECKED BEFORE THE UPSERT, BECAUSE THE UPSERT CANNOT COMPLAIN. Keys are
  // globally unique, so a key can already belong to somebody else. The conflict
  // target's `WHERE owner_id = $1` correctly refuses to overwrite their row —
  // verified against prod — but ON CONFLICT DO UPDATE whose predicate fails
  // updates nothing AND inserts nothing, with no error and row_count = 0. Left
  // to that, the caller gets 200 and a lens list quietly missing a lens, which
  // reads as data loss. Collisions are vanishingly unlikely by construction and
  // that is exactly why this must be explicit rather than swallowed.
  const takenKeys = await findKeysOwnedByOthers(ownerId, lenses.map(l => l.key));
  if (takenKeys.length > 0) {
    throw new LensKeyConflictError(takenKeys);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const keys = lenses.map(l => l.key);
    await client.query(
      `DELETE FROM inform.compass_user_lenses
        WHERE owner_id = $1 AND NOT (key = ANY($2::text[]))`,
      [ownerId, keys]
    );

    for (const lens of lenses) {
      await client.query(
        `INSERT INTO inform.compass_user_lenses
           (owner_id, key, name, topic_ids, visibility)
         VALUES ($1, $2, $3, $4::uuid[], $5)
         ON CONFLICT (key) DO UPDATE
           SET name       = EXCLUDED.name,
               topic_ids  = EXCLUDED.topic_ids,
               visibility = EXCLUDED.visibility,
               updated_at = now()
           -- Ownership is re-asserted in the conflict target, not assumed. Keys are
           -- globally unique so another user's key CAN collide here; without this
           -- predicate the upsert would hand them someone else's row.
           WHERE inform.compass_user_lenses.owner_id = $1`,
        [ownerId, lens.key, lens.name.trim(), lens.topic_ids, lens.visibility ?? 'private']
      );
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  return getUserLenses(ownerId);
}

// ---------------------------------------------------------------------------
// Recalibration
// ---------------------------------------------------------------------------

interface StaleCandidateRow {
  topic_id: string;
  value: string | number | null;
  answered_revision_id: string | null;
  answered_version: number | null;
  effective_revision_id: string | null;
  effective_version: number | null;
  public_note: string | null;
}

/**
 * Which topics in this set the owner should recalibrate.
 *
 * Only topics the user has actually ANSWERED can be flagged — an unanswered topic
 * in a lens is a gap to fill, not a stale calibration, and the two must not be
 * confused in the UI.
 */
export async function getRecalibrationFlags(
  ownerId: string,
  topicIds: string[]
): Promise<RecalibrationFlag[]> {
  if (topicIds.length === 0) return [];

  const unique = [...new Set(topicIds)];

  // `eff` mirrors getPromotedTopics()'s lateral exactly (ADR 0006 Option Y): the
  // season serves the LATEST revision of the version it pinned, not is_current.
  // A LEFT JOIN, not an inner one — a topic the open season dropped must survive
  // this query as effective_version = NULL so it can be reported as
  // 'not_asked_this_season' instead of silently disappearing from the flags.
  const { rows } = await pool.query<StaleCandidateRow>(
    `SELECT r.topic_id::text            AS topic_id,
            r.value                     AS value,
            r.answered_revision_id::text AS answered_revision_id,
            ar.version                  AS answered_version,
            eff.id::text                AS effective_revision_id,
            eff.version                 AS effective_version,
            eff.public_note             AS public_note
       FROM inform.compass_responses_current r
       LEFT JOIN inform.compass_topic_revisions ar ON ar.id = r.answered_revision_id
       LEFT JOIN inform.compass_topics_promoted p  ON p.id = r.topic_id
       LEFT JOIN LATERAL (
         SELECT e.id, e.version, e.public_note
           FROM inform.compass_topic_revisions pin
           JOIN inform.compass_topic_revisions e
             ON e.topic_id = pin.topic_id
            AND e.version  = pin.version
            AND e.status IN ('published', 'superseded')
          WHERE pin.id = p.season_revision_id
          ORDER BY e.revision DESC
          LIMIT 1
       ) eff ON true
      WHERE r.user_id = $1
        AND r.deleted_at IS NULL
        AND r.topic_id = ANY($2::uuid[])`,
    [ownerId, unique]
  );

  const flags: RecalibrationFlag[] = [];

  for (const row of rows) {
    const value = row.value === null ? null : Number(row.value);

    // The topic exists in the lens and the user answered it, but this season does
    // not ask it. Nothing changed under them — it is simply not on the board.
    if (row.effective_version === null) {
      flags.push({
        topicId: row.topic_id,
        reason: 'not_asked_this_season',
        currentValue: value,
        publicNote: '',
        answeredVersion: row.answered_version,
        effectiveVersion: null,
      });
      continue;
    }

    // Same major version — an editorial or clarifying edit at most (ADR 0006 §2),
    // or no edit at all. Their calibration still stands.
    //
    // An answer with no stamped revision (3 of 187 rows in prod, pre-dating
    // stamping) is treated as fresh rather than flagged. Nagging someone because
    // of a NULL we wrote is worse than missing a genuine revision.
    if (row.answered_version === null || row.answered_version === row.effective_version) {
      continue;
    }

    const neighbourhood = rungNeighbourhood(value);
    const change = await compareRungs(
      row.answered_revision_id!,
      row.effective_revision_id!,
      neighbourhood
    );

    if (change === 'unchanged') continue;

    flags.push({
      topicId: row.topic_id,
      reason: change === 'invalidated' ? 'answer_invalidated' : 'question_revised',
      currentValue: value,
      publicNote: row.public_note ?? '',
      answeredVersion: row.answered_version,
      effectiveVersion: row.effective_version,
    });
  }

  return flags;
}

/**
 * The rungs whose wording bears on an answer at `value`.
 *
 * See the header note: a half value is a write-in between two rungs, so both of
 * those rungs are "their answer" and the neighbours sit outside them. Returns
 * whole rungs only, clamped to the 1..5 ladder.
 */
export function rungNeighbourhood(value: number | null): number[] {
  if (value === null || Number.isNaN(value)) return [1, 2, 3, 4, 5];

  const lo = Math.max(1, Math.floor(value) - 1);
  const hi = Math.min(5, Math.ceil(value) + 1);

  const rungs: number[] = [];
  for (let r = lo; r <= hi; r++) rungs.push(r);
  return rungs;
}

type RungChange = 'unchanged' | 'changed' | 'invalidated';

/**
 * Did any rung in `values` change between two revisions?
 *
 * Compares the stance snapshots directly (compass_stance_revisions holds a full
 * snapshot per revision, so this is a straight pairing) and consults the newer
 * revision's rung_map for the two things text cannot show: a rung that MOVED to a
 * different position, and a rung that was INVALIDATED outright.
 *
 * ⚠ rung_map is read from the effective revision only. Across a multi-revision
 * gap the maps would need composing hop by hop; the snapshot comparison already
 * catches any wording change in that gap, so the map is used here strictly for
 * the move/invalidate signal it uniquely carries. A rung that moved and moved
 * back over three revisions reads as unchanged — correct, because it is.
 */
async function compareRungs(
  answeredRevisionId: string,
  effectiveRevisionId: string,
  values: number[]
): Promise<RungChange> {
  const { rows } = await pool.query<{
    value: number;
    old_text: string | null;
    new_text: string | null;
    old_description: string | null;
    new_description: string | null;
    mapped: string | null;
  }>(
    // Each side is narrowed to its own revision in a CTE BEFORE the join — the
    // same trap compassRevisionService documents: filtering in the join instead
    // leaves one side unconstrained and rungs can drop out of the result.
    `WITH answered AS (
       SELECT value, text, description
         FROM inform.compass_stance_revisions
        WHERE topic_revision_id = $1 AND value = ANY($3::int[])
     ), effective AS (
       SELECT value, text, description
         FROM inform.compass_stance_revisions
        WHERE topic_revision_id = $2 AND value = ANY($3::int[])
     )
     SELECT COALESCE(a.value, e.value)      AS value,
            a.text                          AS old_text,
            e.text                          AS new_text,
            a.description                   AS old_description,
            e.description                   AS new_description,
            (SELECT rung_map ->> COALESCE(a.value, e.value)::text
               FROM inform.compass_topic_revisions WHERE id = $2) AS mapped
       FROM answered a
       FULL OUTER JOIN effective e ON e.value = a.value`,
    [answeredRevisionId, effectiveRevisionId, values]
  );

  let changed = false;

  for (const r of rows) {
    if (r.mapped === 'invalidated') return 'invalidated';

    // A rung present on one side and absent on the other is a ladder change.
    if (r.old_text === null || r.new_text === null) {
      changed = true;
      continue;
    }

    const mappedNum = r.mapped === null ? null : Number(r.mapped);
    if (mappedNum !== null && !Number.isNaN(mappedNum) && mappedNum !== Number(r.value)) {
      changed = true;
      continue;
    }

    if (r.old_text !== r.new_text || r.old_description !== r.new_description) {
      changed = true;
    }
  }

  return changed ? 'changed' : 'unchanged';
}

// ---------------------------------------------------------------------------
// Mapping
// ---------------------------------------------------------------------------

function mapLens(row: {
  key: string;
  name: string;
  topic_ids: string[] | null;
  visibility: string;
  created_at: Date | string;
  updated_at: Date | string;
}): UserLens {
  return {
    key: row.key,
    name: row.name,
    topicIds: row.topic_ids ?? [],
    visibility: row.visibility === 'unlisted' ? 'unlisted' : 'private',
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}
