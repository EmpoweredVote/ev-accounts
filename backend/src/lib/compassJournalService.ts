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
 * The handle comes from public.users (universal coverage) and the legal name
 * from connect.connected_profiles (present on 9 of 12 rows, hence the fallback
 * chain in resolveByline).
 */
const SELECT = `
  SELECT j.id::text, j.topic_id::text, j.kind, j.title, j.body,
         s.number AS season_number, s.name AS season_name,
         j.revision_id::text, j.answers_id::text,
         j.published_at, j.attribution,
         u.display_name,
         cp.legal_name,
         (ep.user_id IS NOT NULL AND ep.is_active) AS is_empowered
    FROM inform.compass_topic_journal j
    JOIN inform.seasons s ON s.id = j.season_id
    LEFT JOIN public.users u  ON u.id  = j.author_id
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = j.author_id
    LEFT JOIN empower.empowered_profiles ep ON ep.user_id = j.author_id
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
 * ⚠ `answers_id` MUST POINT AT AN ENTRY ON THE SAME TOPIC. Without this the two
 * topics' threads splice together and a reader following the link lands on a
 * different question. The CHECK constraint cannot express it (it spans rows), so
 * it lives here, in the one place entries are created.
 */
export async function createEntry(
  input: CreateEntryInput,
  authorId: string,
): Promise<{ id: string }> {
  if (input.answersId) {
    const { rows } = await pool.query<{ topic_id: string }>(
      `SELECT topic_id::text FROM inform.compass_topic_journal WHERE id = $1`,
      [input.answersId],
    );
    if (rows.length === 0 || rows[0].topic_id !== input.topicId) {
      throw new Error('ANSWERS_WRONG_TOPIC: an entry may only answer one on the same topic');
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

export async function updateEntry(
  id: string,
  patch: { title?: string | null; body?: string; attribution?: JournalAttribution },
): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE inform.compass_topic_journal
        SET title       = COALESCE($2, title),
            body        = COALESCE($3, body),
            attribution = COALESCE($4, attribution),
            updated_at  = now()
      WHERE id = $1`,
    [id, patch.title ?? null, patch.body ?? null, patch.attribution ?? null],
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
