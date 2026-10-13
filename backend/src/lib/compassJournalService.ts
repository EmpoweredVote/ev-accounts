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
