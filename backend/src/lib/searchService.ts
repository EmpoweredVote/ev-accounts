/**
 * searchService — full-text search across published meeting transcripts.
 *
 * Uses the tsv tsvector column on meetings.segments (GIN-indexed, maintained
 * by trigger — migration 364). websearch_to_tsquery parses user input and
 * never throws on malformed queries.
 *
 * Snippets: ts_headline does NOT HTML-escape, so we never emit HTML. The
 * [[[ / ]]] sentinels are converted to <mark> elements client-side.
 * ts_headline runs in an outer query over only the returned page.
 *
 * Same architecture rules as meetingsService/peopleService:
 *   - meetings.* is NOT PostgREST-exposed; pool.query() only
 *   - explicit field whitelists, never spread rows
 *   - Number() on bigint/numeric: segment_index, start_time, end_time, count
 */

import { pool } from './db.js';

export const SEARCH_PAGE_SIZE = 25;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface SearchResult {
  meetingId: string;
  city: string;
  meetingType: string;
  date: string;
  segmentIndex: number;
  startTime: number;
  endTime: number;
  speakerName: string | null;
  politicianSlug: string | null;
  snippet: string;
}

export interface SearchResponse {
  query: string;
  page: number;
  totalCount: number;
  results: SearchResult[];
}

interface SearchRow {
  meeting_id: string;
  city: string;
  meeting_type: string;
  date: string;
  segment_index: string;
  start_time: string;
  end_time: string;
  speaker_name: string | null;
  politician_slug: string | null;
  snippet: string;
}

// ---------------------------------------------------------------------------
// Mapper (explicit camelCase — NEVER spread rows)
// ---------------------------------------------------------------------------

function mapResult(row: SearchRow): SearchResult {
  return {
    meetingId: row.meeting_id,
    city: row.city,
    meetingType: row.meeting_type,
    date: row.date,
    segmentIndex: Number(row.segment_index),
    startTime: Number(row.start_time),
    endTime: Number(row.end_time),
    speakerName: row.speaker_name,
    politicianSlug: row.politician_slug,
    snippet: row.snippet,
  };
}

// ---------------------------------------------------------------------------
// Query
// ---------------------------------------------------------------------------

export async function searchSegments(opts: {
  q: string;
  city?: string;
  speaker?: string;
  page: number;
}): Promise<SearchResponse> {
  const { q, city, speaker, page } = opts;
  const offset = (page - 1) * SEARCH_PAGE_SIZE;

  // No meeting-status filter: the on-the-record pipeline (sole writer) only
  // inserts segments for meetings it publishes — the same invariant the
  // transcript endpoint relies on. Revisit if another ingest path appears.
  const conditions: string[] = [`s.tsv @@ websearch_to_tsquery('english', $1)`];
  const params: unknown[] = [q];
  if (speaker !== undefined) {
    params.push(speaker);
    conditions.push(`s.politician_slug = $${params.length}`);
  }
  if (city !== undefined) {
    params.push(city);
    conditions.push(`m.city = $${params.length}`);
  }
  const where = conditions.join(' AND ');

  const limitParam = params.length + 1;
  const offsetParam = params.length + 2;

  const [{ rows }, { rows: countRows }] = await Promise.all([
    pool.query<SearchRow>(
      `WITH hits AS (
         SELECT s.meeting_id, s.segment_index, s.start_time, s.end_time,
                s.speaker_name, s.politician_slug, s.text,
                ts_rank(s.tsv, websearch_to_tsquery('english', $1)) AS rank,
                m.city, m.meeting_type, m.date::text AS date
         FROM meetings.segments s
         JOIN meetings.meetings m ON m.id = s.meeting_id
         WHERE ${where}
         ORDER BY rank DESC, m.date DESC, s.meeting_id, s.segment_index
         LIMIT $${limitParam} OFFSET $${offsetParam}
       )
       SELECT meeting_id, city, meeting_type, date, segment_index,
              start_time, end_time, speaker_name, politician_slug,
              ts_headline('english', text, websearch_to_tsquery('english', $1),
                          'StartSel=[[[, StopSel=]]], MaxWords=40, MinWords=20') AS snippet
       FROM hits
       ORDER BY rank DESC, date DESC, meeting_id, segment_index`,
      [...params, SEARCH_PAGE_SIZE, offset]
    ),
    pool.query<{ count: string }>(
      `SELECT COUNT(*) AS count
       FROM meetings.segments s
       JOIN meetings.meetings m ON m.id = s.meeting_id
       WHERE ${where}`,
      params
    ),
  ]);

  return {
    query: q,
    page,
    totalCount: Number(countRows[0].count),
    results: rows.map(mapResult),
  };
}
