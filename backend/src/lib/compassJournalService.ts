import { pool } from './db.js';
import { resolveByline, type JournalAttribution } from './journalAttribution.js';

export interface JournalEntry {
  id: string;
  topicId: string;
  kind: 'watching' | 'changed';
  title: string | null;
  body: string;
  season: { number: number; name: string };
  revisionId: string | null;
  answersId: string | null;
  author: { label: string };
  publishedAt: string;
}

interface JournalRow {
  id: string;
  topic_id: string;
  kind: 'watching' | 'changed';
  title: string | null;
  body: string;
  season_number: number;
  season_name: string;
  revision_id: string | null;
  answers_id: string | null;
  published_at: string;
  attribution: JournalAttribution;
  display_name: string | null;
  legal_name: string | null;
  is_empowered: boolean;
}

/**
 * The SELECT every public read shares.
 *
 * 🔴 `status = 'published'` IS NOT OPTIONAL AND IS NOT THE CALLER'S JOB. A draft
 * entry is the team thinking out loud about a question it has not changed yet.
 *
 * 🔴 TIER COMES FROM A ROW'S EXISTENCE. `empower.empowered_profiles` with
 * is_active — there is no tier column in this database, and a query that
 * invented one would return undefined and quietly clamp every Empowered author.
 *
 * 🔴 THE LEGAL NAME COMES FROM `empower.empowered_profiles`, NEVER FROM
 * `connect.connected_profiles`. The Connect one is the VAULTED identity name
 * (ev-cto 0022): adminService.ts deletes it from an admin-only response —
 * "readable only via offline break-glass, never by the app or any admin" — and
 * says in the same comment that the Empowered one is public. An earlier draft
 * of this query selected the Connect column and would have published it on this
 * anonymous endpoint, which is the exact de-anonymisation the attribution rule
 * exists to prevent, arriving through the SQL that feeds it.
 *
 * It also hid itself: post-vault members have a NULL Connect legal_name, so an
 * Empowered author asking for `real` just rendered their handle and the wrong
 * source looked like the documented fallback.
 *
 * ⚠ THE deleted_at FILTERS SIT IN THE JOIN CONDITIONS, NOT IN WHERE. In WHERE
 * they would drop the ENTRY. A deleted account costs its author their byline —
 * the joins yield NULL and resolveByline falls through to the team byline — and
 * costs the public nothing: the entry stays published.
 */
const SELECT = `
  SELECT j.id::text, j.topic_id::text, j.kind, j.title, j.body,
         s.number AS season_number, s.name AS season_name,
         j.revision_id::text, j.answers_id::text,
         j.published_at, j.attribution,
         u.display_name,
         ep.legal_name,
         (ep.user_id IS NOT NULL AND ep.is_active) AS is_empowered
    FROM inform.compass_topic_journal j
    JOIN inform.seasons s ON s.id = j.season_id
    LEFT JOIN public.users u
           ON u.id = j.author_id AND u.deleted_at IS NULL
    LEFT JOIN empower.empowered_profiles ep
           ON ep.user_id = j.author_id AND ep.deleted_at IS NULL
   WHERE j.status = 'published'`;

const toEntry = (r: JournalRow): JournalEntry => ({
  id: r.id,
  topicId: r.topic_id,
  kind: r.kind,
  title: r.title,
  body: r.body,
  season: { number: r.season_number, name: r.season_name },
  revisionId: r.revision_id,
  answersId: r.answers_id,
  // Resolved here and nowhere else. The identity fields never leave this file.
  author: {
    label: resolveByline(r.attribution, {
      displayName: r.display_name,
      legalName: r.legal_name,
      isEmpowered: Boolean(r.is_empowered),
    }),
  },
  publishedAt: r.published_at,
});

export async function listTopicJournal(topicId: string): Promise<JournalEntry[]> {
  const { rows } = await pool.query<JournalRow>(
    `${SELECT} AND j.topic_id = $1 ORDER BY j.published_at DESC`,
    [topicId],
  );
  return rows.map(toEntry);
}

export async function listSeasonJournal(seasonNumber: number): Promise<JournalEntry[]> {
  const { rows } = await pool.query<JournalRow>(
    `${SELECT} AND s.number = $1 ORDER BY j.published_at DESC`,
    [seasonNumber],
  );
  return rows.map(toEntry);
}

export interface CreateEntryInput {
  topicId: string;
  seasonId: string;
  kind: 'watching' | 'changed';
  title: string | null;
  body: string;
  revisionId: string | null;
  answersId: string | null;
  attribution: JournalAttribution;
}

/**
 * The season an entry belongs to when the caller did not name one: the open
 * season, or the one being prepared when none is open.
 *
 * 🔴 THROWS RATHER THAN GUESSING. A closed season is never the answer — stamping
 * one backdates the entry into a season it was not written for, and nothing
 * downstream could tell.
 */
export async function resolveDefaultSeasonId(): Promise<string> {
  const { rows } = await pool.query<{ id: string }>(
    `SELECT id::text FROM inform.seasons
      WHERE status IN ('open', 'draft')
      ORDER BY CASE status WHEN 'open' THEN 0 ELSE 1 END, number DESC
      LIMIT 1`,
  );
  if (rows.length === 0) {
    throw new Error('NO_SEASON: no open or draft season to attach a journal entry to');
  }
  return rows[0].id;
}

/**
 * ⚠ BOTH LINKS MUST STAY ON THIS TOPIC. A reader who follows either one and
 * lands on a different question has been misled, and neither rule is expressible
 * as a CHECK because both span two rows. They live here, in the one place an
 * entry is created.
 *
 * `revision_id` matters as much as `answers_id` and was missed at first: spec §7
 * marks the `changed` entry whose revision matches a reader's outstanding flag
 * as the cause of their change, so a Childcare revision pasted onto an Abortion
 * entry tells someone an Abortion entry explains their Childcare flag.
 *
 * 🔴 AND answers_id IS ONE HOP, WHICH HAS TO BE ENFORCED AND NOT MERELY SAID.
 * The no-forum guard asserts this SERVICE never walks the link; it cannot stop
 * the DATA becoming a chain. Without the check below, A <- B <- C all insert
 * cleanly and Focused Communities — which adopts this table as-is — renders a
 * thread. That is the §1 decision lost without a reply column ever appearing,
 * which is the shape the guard was written to catch and the one it misses.
 */
export async function createEntry(
  input: CreateEntryInput,
  authorId: string,
): Promise<{ id: string }> {
  if (input.answersId) {
    const { rows } = await pool.query<{ topic_id: string; answers_id: string | null }>(
      `SELECT topic_id::text, answers_id::text
         FROM inform.compass_topic_journal WHERE id = $1`,
      [input.answersId],
    );
    if (rows.length === 0 || rows[0].topic_id !== input.topicId) {
      throw new Error('ANSWERS_WRONG_TOPIC: an entry may only answer one on the same topic');
    }
    if (rows[0].answers_id !== null) {
      throw new Error(
        'ANSWERS_IS_A_CHAIN: that entry already answers another. One hop only — ' +
        'a chain of entries answering each other is a thread.',
      );
    }
  }

  if (input.revisionId) {
    const { rows } = await pool.query<{ topic_id: string }>(
      `SELECT topic_id::text FROM inform.compass_topic_revisions WHERE id = $1`,
      [input.revisionId],
    );
    if (rows.length === 0 || rows[0].topic_id !== input.topicId) {
      throw new Error('REVISION_WRONG_TOPIC: an entry may only cite a revision of its own topic');
    }
  }

  const { rows } = await pool.query<{ id: string }>(
    `INSERT INTO inform.compass_topic_journal
       (topic_id, season_id, kind, title, body, revision_id, answers_id, author_id, attribution)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING id::text`,
    [input.topicId, input.seasonId, input.kind, input.title, input.body,
     input.revisionId, input.answersId, authorId, input.attribution],
  );
  return { id: rows[0].id };
}

/**
 * The season an explicit `seasonId` is allowed to name.
 *
 * 🔴 SAME HARM AS resolveDefaultSeasonId, DIFFERENT DOOR. That function refuses
 * to stamp a closed season onto an entry, with the reasoning in its own comment
 * — but a caller who PASSED a seasonId skipped it entirely, since the route only
 * checked the value was a uuid. A closed season backdates the entry into a
 * season it was not written for, and nothing downstream could tell.
 */
export async function assertSeasonWritable(seasonId: string): Promise<void> {
  const { rows } = await pool.query<{ status: string }>(
    `SELECT status::text FROM inform.seasons WHERE id = $1`,
    [seasonId],
  );
  if (rows.length === 0 || rows[0].status === 'closed') {
    throw new Error(
      'SEASON_CLOSED: a journal entry may only be attached to an open or draft season',
    );
  }
}

/**
 * ⚠ THE SET LIST IS BUILT FROM THE KEYS ACTUALLY PRESENT, and that is the whole
 * point. The previous version used `COALESCE($2, title)`, which cannot tell
 * "clear this" from "leave this alone": PATCH {"title": null} answered
 * 200 {ok:true} and changed nothing, so a title could never be cleared and the
 * API reported success for work it had not done.
 *
 * An empty patch issues no UPDATE at all — it must not bump updated_at for a
 * no-op — but still answers honestly whether the entry exists.
 */
export async function updateEntry(
  id: string,
  patch: { title?: string | null; body?: string; attribution?: JournalAttribution },
): Promise<boolean> {
  const sets: string[] = [];
  const values: unknown[] = [id];

  const set = (column: string, value: unknown): void => {
    values.push(value);
    sets.push(`${column} = $${values.length}`);
  };

  // `in` rather than a truthiness check: an explicit null is a clear.
  if ('title' in patch) set('title', patch.title ?? null);
  if (patch.body !== undefined) set('body', patch.body);
  if (patch.attribution !== undefined) set('attribution', patch.attribution);

  if (sets.length === 0) {
    const { rows } = await pool.query(
      `SELECT id FROM inform.compass_topic_journal WHERE id = $1`,
      [id],
    );
    return rows.length > 0;
  }

  const { rowCount } = await pool.query(
    `UPDATE inform.compass_topic_journal
        SET ${sets.join(', ')}, updated_at = now()
      WHERE id = $1`,
    values,
  );
  return (rowCount ?? 0) > 0;
}

/** Idempotent: re-publishing an already-published entry does not move its date. */
export async function publishEntry(id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE inform.compass_topic_journal
        SET status = 'published',
            published_at = COALESCE(published_at, now()),
            updated_at = now()
      WHERE id = $1`,
    [id],
  );
  return (rowCount ?? 0) > 0;
}

/** Drafts only. A published entry is corrected, not withdrawn. */
export async function deleteDraft(id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    `DELETE FROM inform.compass_topic_journal WHERE id = $1 AND status = 'draft'`,
    [id],
  );
  return (rowCount ?? 0) > 0;
}
