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
 * HOW THIS TABLE IS ACTUALLY PROTECTED (measured 2026-11-22).
 * ⚠ THIS PARAGRAPH USED TO SAY "no policies and no grants". THE SECOND HALF WAS
 * WRONG, and wrong in the direction that invites a bad conclusion. The truth:
 * `inform.compass_user_lenses` has RLS ON with NO POLICIES, and `ev_api` holds
 * `arwd` on it — and `ev_api` BYPASSES RLS, which is the only reason the backend
 * pool can read the table at all. RLS is therefore not what is protecting
 * anything here. What protects it is that PostgREST's roles (`anon`,
 * `authenticated`) have no grant on the table and so cannot see it, and that
 * every statement in this file carries `WHERE owner_id = $1`. That predicate is
 * the enforcement, exactly as in saveSelectedTopics(). Remove it from a query
 * and nothing else stops that query returning another user's lenses.
 *
 * All reads go through `pool` (lib/db.ts).
 *
 * A DELETED LENS IS NOT A GONE LENS (CC_0468).
 * `deleted_at` makes a deletion reversible, and an AFTER-ROW trigger writes
 * every insert, update, restore, soft_delete and hard_delete to
 * `inform.compass_user_lens_history` with before- and after-images. So the reads
 * here filter on `deleted_at IS NULL` — with ONE deliberate exception,
 * `findKeysOwnedByOthers`, which is marked in full at its definition because
 * dropping the filter out of it is not an omission but a decision. The unique
 * index on `key` still covers soft-deleted rows; that is load-bearing, and the
 * exception exists because of it. See
 * docs/superpowers/plans/2026-11-22-lens-durability.md.
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
  /**
   * The revision the user's season serves for this topic, by id.
   *
   * 🔴 AN ID, BECAUSE A VERSION NUMBER MATCHES NOTHING. `effectiveVersion` is
   * per-topic — every topic has a version 2 — so a client holding a journal
   * entry's `revisionId` had no way to ask "is this the edit that flagged me?".
   * Spec §7 marks exactly that entry as the one that explains the flag, and
   * without this field it could not be built.
   *
   * Null for `not_asked_this_season`: nothing is being served, so no entry may
   * claim to be the cause.
   */
  effectiveRevisionId: string | null;
  /**
   * The option at their value, in each of those two revisions.
   *
   * 🔴 WHY THE WORDS AND NOT JUST THE VERSIONS. Editorial's note identifies what
   * changed by POSITION — "reworded option 4" — so reading it means counting
   * options to find which one that was, and it never says what the old one said.
   * These two fields let the UI show the sentence the user picked beside the one
   * that replaced it, which answers the question the note cannot.
   *
   * ⚠ THEY ARE THE SAME SLOT, NOT THE SAME POSITION. For `moved` and
   * `invalidated` the user's rung is precisely what did not survive, so
   * `effectiveText` is "what sits at that number now" and NOT "their answer,
   * restated" — the client must not present it as the latter. This is the same
   * distinction `disposition` exists to carry.
   *
   * Null where the slot has nothing behind it: a write-in sits between rungs
   * (0.5, 5.5) and matches no option, and a topic the open season dropped has no
   * effective revision at all.
   */
  answeredText: string | null;
  effectiveText: string | null;
}

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

/**
 * A user's LIVE lenses, newest last (creation order — the order they built them
 * in, which is the order the management UI lists them in).
 *
 * `deleted_at IS NULL` is the whole of what "live" means here. A soft-deleted
 * lens is still a row — that is the point of CC_0468 — but it is gone from every
 * ordinary read, so deleting one still looks and feels like deleting one. The
 * row exists so that a mistaken deletion can be undone, not so that the owner
 * has to keep seeing it.
 */
export async function getUserLenses(ownerId: string): Promise<UserLens[]> {
  const { rows } = await pool.query(
    `SELECT key, name, topic_ids, visibility, created_at, updated_at
       FROM inform.compass_user_lenses
      WHERE owner_id = $1 AND deleted_at IS NULL
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

/**
 * Raised when a write would destroy a stored lens the caller never mentioned.
 *
 * 🔴 THIS IS THE GUARD THE 2026-11-22 MEASUREMENT BOUGHT. Three lenses stored, a
 * one-lens PUT, two gone, HTTP 200, and no history table to get them back. The
 * caller did not ask for a deletion — it simply sent a short list, which this
 * endpoint used to read as one. A client that has lost its copy of the set (a
 * failed GET rendered as an empty list) sends exactly that payload, and it reaches here
 * with no user having touched anything.
 *
 * So a deletion is now something a caller SAYS, in deleteKeys, and silence
 * means keep. An omission can no longer destroy anything.
 */
export class UnacknowledgedLensDeletionError extends Error {
  readonly code = 'LENS_DELETE_NOT_ACKNOWLEDGED';
  constructor(readonly keys: string[]) {
    super(`Refusing to delete lenses the caller did not name: ${keys.join(', ')}`);
    this.name = 'UnacknowledgedLensDeletionError';
  }
}

export function isUnacknowledgedLensDeletionError(
  e: unknown
): e is UnacknowledgedLensDeletionError {
  return e instanceof UnacknowledgedLensDeletionError;
}

/**
 * Which of these keys exist and belong to somebody other than `ownerId`.
 *
 * 🔴 NO `deleted_at IS NULL` HERE, AND THAT IS THE ONE DELIBERATE EXCEPTION IN
 * THIS FILE. Every other read of this table filters soft-deleted rows out.
 * This one must not, because the unique index on `key` is GLOBAL and does NOT
 * exclude soft-deleted rows — CC_0468 left it alone on purpose. So another
 * owner's soft-deleted row still occupies the key.
 *
 * Drop the filter in here "for consistency" and this is what happens: the key
 * looks free, the upsert runs, it conflicts on the index against that other
 * owner's dead row, its `WHERE inform.compass_user_lenses.owner_id = $1`
 * predicate is false, and ON CONFLICT DO UPDATE with a false predicate updates
 * nothing AND inserts nothing AND raises nothing. The caller gets HTTP 200 and a
 * lens list quietly short one lens — which is exactly the shape of the data-loss
 * bug this whole branch exists to close, arriving through a different door.
 *
 * Guarded by: "still sees ANOTHER owner's soft-deleted key as taken", which
 * asserts this query does not mention `deleted_at` at all.
 *
 * The owner's OWN soft-deleted key is a different question and is not asked
 * here: re-creating a key you deleted is a resurrection, handled by
 * `deleted_at = NULL` in the upsert's SET.
 */
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
 * Write the owner's lens set: upsert everything in `lenses`, soft-delete exactly
 * the keys in `deleteKeys`, and leave everything else alone — including, now,
 * leaving an unchanged lens genuinely untouched.
 *
 * Whole-set upsert, not per-lens CRUD, because that is how the client holds them:
 * a guest builds lenses in local storage with no server round-trip, and sign-in
 * promotes the whole collection at once. Per-lens endpoints would make that
 * promotion an N-request loop that can half-fail.
 *
 * 🔴 AN OMISSION IS NOT A DELETION. THAT IS THE WHOLE POINT OF `deleteKeys`.
 * This function used to delete the complement of the payload —
 * `DELETE ... WHERE NOT (key = ANY($2))` — so a caller that sent a short list
 * destroyed the rest, permanently, at HTTP 200, with no history table. Measured
 * against production on 2026-11-22: three lenses in, a one-lens PUT, one left.
 *
 * It took one transient failure to produce that payload. `apiFetch` returns null
 * on a blip, the client rendered that as an empty set, and the next ordinary save
 * posted a list missing everything the client had forgotten. Nobody deleted
 * anything. See the CompassV2 half of this fix for the client's share of it.
 *
 * Now a deletion must be named, and the deleting statement itself can only ever
 * touch named keys — the guard below explains the refusal, but the `key = ANY`
 * is what makes an unnamed lens unreachable even if the guard were wrong.
 *
 * ⚠ AND SINCE CC_0468, A NAMED DELETION IS REVERSIBLE TOO. The guard answers
 * "the caller never asked for this"; it cannot answer "the caller asked for the
 * wrong key". So the delete stamps `deleted_at` instead of removing the row, the
 * history trigger keeps the before-image, and re-saving the key resurrects it
 * with its `created_at` intact. Two different failures, two different answers.
 *
 * Runs in one transaction so a failed promotion leaves the previous set intact
 * rather than a partially-written one. `created_at` is preserved across a rewrite
 * of an existing key — the lens is the same lens, so its age should not reset
 * every time the user renames it or reorders a topic.
 */
export async function replaceUserLenses(
  ownerId: string,
  lenses: UserLensInput[],
  deleteKeys: string[] = []
): Promise<UserLens[]> {
  // 🔴 CHECKED BEFORE THE UPSERT, BECAUSE THE UPSERT CANNOT COMPLAIN. Keys are
  // globally unique, so a key can already belong to somebody else. The conflict
  // target's `WHERE owner_id = $1` correctly refuses to overwrite their row —
  // verified against prod — but ON CONFLICT DO UPDATE whose predicate fails
  // updates nothing AND inserts nothing, with no error and row_count = 0. Left
  // to that, the caller gets 200 and a lens list quietly missing a lens, which
  // reads as data loss. Collisions are vanishingly unlikely by construction and
  // that is exactly why this must be explicit rather than swallowed.
  //
  // ⚠ AND SINCE CC_0468, `row_count = 0` MEANS TWO THINGS, SO IT IS WORTH EVEN
  // LESS AS A SIGNAL THAN IT WAS. The upsert's conflict predicate now also
  // carries an IS DISTINCT FROM conjunct, so an unchanged lens is skipped on
  // purpose and reports zero rows too. "Not yours" and "nothing to change" are
  // now indistinguishable from the row count. Do not reintroduce a check on it
  // as a substitute for this pre-flight read: it would reject every no-op save.
  const takenKeys = await findKeysOwnedByOthers(ownerId, lenses.map(l => l.key));
  if (takenKeys.length > 0) {
    throw new LensKeyConflictError(takenKeys);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // What the owner actually holds RIGHT NOW — live rows only — locked for the
    // life of the transaction.
    //
    // `deleted_at IS NULL` is required, not cosmetic. This set is what the
    // unacknowledged-deletion guard below compares the payload against, so
    // without the filter a lens the owner deleted last week would come back as
    // "stored but neither kept nor named" and every subsequent save would be
    // refused — a 409 the user cannot clear, because naming a key in
    // `delete_keys` that is already soft-deleted changes nothing. They would be
    // locked out of their own lens list by a deletion that worked.
    //
    // ⚠ WHAT THE LOCK NOW COVERS, AND WHAT IT DOES NOT. FOR UPDATE still holds
    // the owner's live rows for the whole transaction, so a concurrent PUT
    // cannot modify or delete one between this read and the writes below. It no
    // longer touches the owner's soft-deleted rows, so a concurrent
    // RESURRECTION of a soft-deleted key — a second PUT re-creating it, which
    // the upsert does with `deleted_at = NULL` — is NOT serialised against this
    // read. Nor was a fresh INSERT of a brand-new key ever serialised by it;
    // row locks cannot lock rows that do not exist yet. In both cases the newly
    // live lens simply is not in `storedRows`, so the guard does not see it and
    // does not refuse the save. That is the benign direction: the concurrent
    // write's own lens survives, and nothing of the caller's is destroyed —
    // every destructive statement below is restricted to keys the caller named.
    const { rows: storedRows } = await client.query<{ key: string }>(
      `SELECT key FROM inform.compass_user_lenses
        WHERE owner_id = $1 AND deleted_at IS NULL
        FOR UPDATE`,
      [ownerId]
    );

    const keeping = new Set(lenses.map(l => l.key));
    const named = new Set(deleteKeys);
    const unacknowledged = storedRows
      .map(r => r.key)
      .filter(key => !keeping.has(key) && !named.has(key));

    if (unacknowledged.length > 0) {
      // Nothing is written. The caller is holding a view of this account's
      // lenses that disagrees with the account, and the right move is to go and
      // re-read it — not to let the disagreement decide what survives.
      throw new UnacknowledgedLensDeletionError(unacknowledged);
    }

    // 🔴 A DELETION IS A STAMP, NOT A DESTRUCTION. This was `DELETE FROM` until
    // CC_0468. The guard above already made an omission harmless, but a NAMED
    // deletion was still final: a user who meant to remove one lens and named
    // the wrong key had no way back, and neither did we. Now the row stays, the
    // trigger records a `soft_delete` with the full before-image, and
    // `restoreUserLens` is a possible thing to build on top of it.
    //
    // `AND deleted_at IS NULL` keeps the statement idempotent: naming a key that
    // is already deleted matches nothing, so it does not re-stamp `deleted_at`
    // to a later time and — because the trigger's WHEN clause watches
    // `deleted_at` — it writes no second history row either. A retried PUT does
    // not move the deletion's timestamp.
    //
    // Only what was named. An empty deleteKeys asks nothing of the database
    // rather than issuing a no-op ANY for a guaranteed zero rows.
    if (deleteKeys.length > 0) {
      await client.query(
        `UPDATE inform.compass_user_lenses
            SET deleted_at = now()
          WHERE owner_id = $1 AND key = ANY($2::text[]) AND deleted_at IS NULL`,
        [ownerId, deleteKeys]
      );
    }

    for (const lens of lenses) {
      await client.query(
        `INSERT INTO inform.compass_user_lenses
           (owner_id, key, name, topic_ids, visibility)
         VALUES ($1, $2, $3, $4::uuid[], $5)
         ON CONFLICT (key) DO UPDATE
           SET name       = EXCLUDED.name,
               topic_ids  = EXCLUDED.topic_ids,
               visibility = EXCLUDED.visibility,
               -- Saving a key the owner previously deleted RESURRECTS it rather
               -- than failing on the unique index, and keeps its original
               -- created_at: it is the same lens, and its age should not reset
               -- because it spent a week deleted. The trigger reads this
               -- NOT NULL -> NULL transition as a 'restore'.
               deleted_at = NULL,
               updated_at = now()
           -- Ownership is re-asserted in the conflict target, not assumed. Keys are
           -- globally unique so another user's key CAN collide here; without this
           -- predicate the upsert would hand them someone else's row.
           WHERE inform.compass_user_lenses.owner_id = $1
             -- ⚠ AND NOTHING IS WRITTEN WHEN NOTHING CHANGED. The client PUTs
             -- the WHOLE set on every save, so renaming one lens used to issue a
             -- real row update for every other lens the user owns — each one a
             -- new row version, index churn, and (since CC_0468) a history row
             -- carrying two full copies of an untouched lens.
             --
             -- 🔴 TWO GUARDS AT TWO LAYERS, DELIBERATELY, AND NEITHER MAKES THE
             -- OTHER REDUNDANT. The trigger's WHEN clause stops a no-op from
             -- being RECORDED, whatever write path produced it — it watches the
             -- material columns (owner_id, key, name, topic_ids, visibility,
             -- deleted_at) and not the whole row, precisely so that
             -- an updated_at = now() cannot defeat it. This predicate stops a
             -- no-op from being WRITTEN AT ALL: no row version, no index churn,
             -- no updated_at movement that would make an untouched lens look
             -- edited.
             --
             -- ⚠ SO updated_at NO LONGER MOVES ON A SAVE THAT CHANGED NOTHING.
             -- That is the point, and it is the more honest reading of the
             -- field: it now means "when this lens last actually changed".
             -- Anything that wants "when the user last pressed save" must not
             -- read it.
             --
             -- deleted_at is in the tuple so that a resurrection still counts
             -- as a change when every other column is identical — otherwise
             -- re-creating a deleted lens unchanged would be skipped and the
             -- lens would stay deleted at HTTP 200.
             AND (inform.compass_user_lenses.name,
                  inform.compass_user_lenses.topic_ids,
                  inform.compass_user_lenses.visibility,
                  inform.compass_user_lenses.deleted_at)
                 IS DISTINCT FROM
                 (EXCLUDED.name, EXCLUDED.topic_ids, EXCLUDED.visibility, NULL::timestamptz)`,
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
  answered_text: string | null;
  effective_text: string | null;
}

/**
 * Which of the owner's answers need recalibrating, and what to do with each
 * stored value.
 *
 * 🔴 THE RULE IS CC_0061, NOT THIS FUNCTION. All it does is read
 * `inform.compass_answer_dispositions` and translate its four words into the
 * wire contract. It used to derive the rule itself, in `compareRungs`, and that
 * is deleted: two implementations of one editorial rule is how the suppression
 * path and the prompt path come to disagree about the same answer, and the
 * disagreement would be a person's stated view vanishing without explanation.
 *
 * ⚠ ONE QUERY, ONE TRANSLATION, AND A FILTER THAT IS EITHER THERE OR NOT.
 * `topicIds === null` means every answer the user holds. The scoped and
 * unscoped reads share this body precisely so they cannot drift — the same
 * argument as above, one level down.
 *
 * Only topics the user has actually ANSWERED can be flagged: the view is built
 * on `compass_responses_current`, so an unanswered topic simply is not in the
 * result. An unanswered topic is a gap to fill, not a stale calibration, and the
 * two must not be confused in the UI.
 */
async function queryRecalibrationFlags(
  ownerId: string,
  topicIds: string[] | null
): Promise<RecalibrationFlag[]> {
  // The view already resolves the effective revision through the open season's
  // pins (ADR 0006 Option Y) and already excludes soft-deleted answers. What it
  // does not carry is the two versions and editorial's note, so they are joined
  // back on here — a LEFT JOIN on each side, because a topic the open season
  // dropped has no effective revision at all and must survive as NULL rather
  // than disappearing from the flags.
  // The predicate is named rather than inlined so the template literal holds no
  // escapes: an escaped newline in here is how this shipped broken once.
  const topicFilter = topicIds === null ? '' : ' AND d.topic_id = ANY($2::uuid[])';

  const { rows } = await pool.query<DispositionRow>(
    `SELECT d.topic_id::text             AS topic_id,
            d.value                      AS value,
            d.disposition                AS disposition,
            d.answered_revision_id::text AS answered_revision_id,
            d.effective_revision_id::text AS effective_revision_id,
            ar.version                   AS answered_version,
            eff.version                  AS effective_version,
            eff.public_note              AS public_note,
            ans.text                     AS answered_text,
            eft.text                     AS effective_text
       FROM inform.compass_answer_dispositions d
       LEFT JOIN inform.compass_topic_revisions ar  ON ar.id  = d.answered_revision_id
       LEFT JOIN inform.compass_topic_revisions eff ON eff.id = d.effective_revision_id
       -- The option sitting at the user's value in each revision. Joined on the
       -- VALUE, which is how a stored answer addresses an option at all; a
       -- write-in between rungs matches neither side and stays null.
       LEFT JOIN inform.compass_stance_revisions ans
              ON ans.topic_revision_id = d.answered_revision_id AND ans.value = d.value
       LEFT JOIN inform.compass_stance_revisions eft
              ON eft.topic_revision_id = d.effective_revision_id AND eft.value = d.value
      WHERE d.user_id = $1${topicFilter}`,
    topicIds === null ? [ownerId] : [ownerId, topicIds]
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
        // Nothing is being served, so no journal entry may claim to explain this.
        effectiveRevisionId: null,
        answeredText: row.answered_text,
        // No revision is being served, so there is no current wording to show.
        effectiveText: null,
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
      effectiveRevisionId: row.effective_revision_id,
      answeredText: row.answered_text,
      effectiveText: row.effective_text,
    });
  }

  return flags;
}

/**
 * The flags for a specific set of topics — a lens's topics, in practice.
 *
 * An empty set asks nothing of the database: a lens with no topics has no
 * staleness question, and `ANY('{}')` would be a round trip for a guaranteed
 * empty result.
 */
export async function getRecalibrationFlags(
  ownerId: string,
  topicIds: string[]
): Promise<RecalibrationFlag[]> {
  if (topicIds.length === 0) return [];

  return queryRecalibrationFlags(ownerId, [...new Set(topicIds)]);
}

/**
 * The flags for EVERY answer the owner holds.
 *
 * 🔴 WHY THE UNSCOPED READ EXISTS. Scoping the compass's flags to the SELECTED
 * topics covered only 12 of the 96 non-fresh answers at the changeover —
 * `invalidated` 0 of 1, `moved` 2 of 6, `reworded` 10 of 89. The remaining 84
 * sit on topics the user answered but does not currently show, and an answer set
 * aside off-screen is still an answer set aside: it is missing from
 * `compass_responses_effective` for scoring and for every other reader, and the
 * user would find out only by happening to put that topic back on their compass.
 *
 * The caller decides how loudly each one speaks — see `disposition`.
 */
export async function getAllRecalibrationFlags(
  ownerId: string
): Promise<RecalibrationFlag[]> {
  return queryRecalibrationFlags(ownerId, null);
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
