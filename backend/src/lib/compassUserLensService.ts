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
 * 🔴 THE RECALIBRATION RULE IS NOT IN THIS FILE. IT IS CC_0061.
 * `inform.compass_answer_disposition()` and the view over it,
 * `inform.compass_answer_dispositions`, answer "does this answer still mean what
 * it meant" in one place, for every consumer, in four words:
 *
 *   fresh        nothing to say. Keep the value, no prompt.
 *   reworded     their rung still means their rung, wording near it changed.
 *                KEEP the value, raise a flag.
 *   moved        their rung maps somewhere else. The value is wrong.
 *                SUPPRESS it, raise a flag.
 *   invalidated  their rung no longer exists. SUPPRESS, raise a flag.
 *
 * `getRecalibrationFlags` reads that view and translates those words into
 * RecalibrationFlag. It does nothing else, and it must stay that way.
 *
 * ⚠ IT USED TO DERIVE THE RULE ITSELF, IN `compareRungs`, AND THAT IS WHY THE
 * RULE MOVED. Measured against Season 2's pins on real data, the TypeScript
 * flagged 96 of 178 live answers — fine as a prompt, catastrophic as the
 * suppression rule it was about to become (40–59% of every user's compass). It
 * also mis-reported invalidation: it fired when ANY rung in the neighbourhood
 * was invalidated rather than the user's own, so a user sitting safely on rung 4
 * would have been told their stated view no longer existed. CC_0061 splits the
 * 96 into 89 flagged-but-kept and 7 suppressed, and decides moved/invalidated
 * from the user's OWN rung only. Do not reimplement any part of it here: two
 * implementations of one editorial rule is how the suppression path and the
 * prompt path come to disagree about the same answer, and that disagreement is
 * a real person's answer disappearing with no explanation.
 *
 * ADR 0006 §2 still does the cheap half of the work, inside the function:
 * `editorial` and `clarifying` revisions do NOT bump `version`, so they resolve
 * to the version the answer was stamped against and can never raise a flag
 * without anything testing `change_class` at all.
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

/**
 * CC_0061's verdict on one answer, passed through verbatim.
 *
 * 🔴 THIS IS THE FIELD THAT DECIDES SUPPRESSION, AND `reason` IS NOT.
 * `moved` and `reworded` both surface as `question_revised` — the user is told
 * the same thing either way — but only `moved` and `invalidated` mean the
 * stored value now points somewhere else and must be withheld. Read
 * `disposition`, never `reason`, when deciding whether to show a value.
 */
export type AnswerDisposition = 'fresh' | 'reworded' | 'moved' | 'invalidated';

/** Whether an answer's stored value still points where the user put it. */
export function isSuppressed(disposition: AnswerDisposition): boolean {
  return disposition === 'moved' || disposition === 'invalidated';
}

export interface RecalibrationFlag {
  topicId: string;
  reason: RecalibrationReason;
  /**
   * CC_0061's word for what happened to this answer. `not_asked_this_season`
   * carries `fresh`, because nothing changed under them — the topic simply is
   * not on the board, which `reason` is the field that says.
   */
  disposition: AnswerDisposition;
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

interface DispositionRow {
  topic_id: string;
  value: string | number | null;
  disposition: AnswerDisposition;
  answered_revision_id: string | null;
  effective_revision_id: string | null;
  answered_version: number | null;
  effective_version: number | null;
  public_note: string | null;
}

/**
 * Which topics in this set the owner should recalibrate, and what to do with
 * each stored value.
 *
 * 🔴 THE RULE IS CC_0061, NOT THIS FUNCTION. All this does is read
 * `inform.compass_answer_dispositions` and translate its four words into the
 * wire contract. It used to derive the rule itself, in `compareRungs`, and that
 * is deleted: two implementations of one editorial rule is how the suppression
 * path and the prompt path come to disagree about the same answer, and the
 * disagreement would be a person's stated view vanishing without explanation.
 *
 * Only topics the user has actually ANSWERED can be flagged — the view is built
 * on `compass_responses_current`, so an unanswered topic in a lens simply is not
 * in the result. An unanswered topic is a gap to fill, not a stale calibration,
 * and the two must not be confused in the UI.
 */
export async function getRecalibrationFlags(
  ownerId: string,
  topicIds: string[]
): Promise<RecalibrationFlag[]> {
  if (topicIds.length === 0) return [];

  const unique = [...new Set(topicIds)];

  // The view already resolves the effective revision through the open season's
  // pins (ADR 0006 Option Y) and already excludes soft-deleted answers. What it
  // does not carry is the two versions and editorial's note, so they are joined
  // back on here — a LEFT JOIN on each side, because a topic the open season
  // dropped has no effective revision at all and must survive as NULL rather
  // than disappearing from the flags.
  const { rows } = await pool.query<DispositionRow>(
    `SELECT d.topic_id::text             AS topic_id,
            d.value                      AS value,
            d.disposition                AS disposition,
            d.answered_revision_id::text AS answered_revision_id,
            d.effective_revision_id::text AS effective_revision_id,
            ar.version                   AS answered_version,
            eff.version                  AS effective_version,
            eff.public_note              AS public_note
       FROM inform.compass_answer_dispositions d
       LEFT JOIN inform.compass_topic_revisions ar  ON ar.id  = d.answered_revision_id
       LEFT JOIN inform.compass_topic_revisions eff ON eff.id = d.effective_revision_id
      WHERE d.user_id = $1
        AND d.topic_id = ANY($2::uuid[])`,
    [ownerId, unique]
  );

  const flags: RecalibrationFlag[] = [];

  for (const row of rows) {
    const value = row.value === null ? null : Number(row.value);

    // Checked BEFORE the disposition, and it has to be. A topic this season
    // does not ask has no effective revision, so CC_0061 returns 'fresh' for
    // it — correct on its own terms, since nothing changed under them, but it
    // would read as "nothing to say" and drop the topic silently.
    if (row.effective_revision_id === null) {
      flags.push({
        topicId: row.topic_id,
        reason: 'not_asked_this_season',
        disposition: 'fresh',
        currentValue: value,
        publicNote: '',
        answeredVersion: row.answered_version,
        effectiveVersion: null,
      });
      continue;
    }

    if (row.disposition === 'fresh') continue;

    flags.push({
      topicId: row.topic_id,
      // `moved` joins `reworded` here deliberately: what the user is told is
      // "this question was revised" in both cases. Only `invalidated` claims
      // their rung is gone, and it may only do so when CC_0061 says their OWN
      // rung was the one invalidated.
      reason: row.disposition === 'invalidated' ? 'answer_invalidated' : 'question_revised',
      disposition: row.disposition,
      currentValue: value,
      publicNote: row.public_note ?? '',
      answeredVersion: row.answered_version,
      effectiveVersion: row.effective_version,
    });
  }

  return flags;
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
