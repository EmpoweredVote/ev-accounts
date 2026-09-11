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
import type { EventKind } from './eventKinds.js';
import { publicMeetingStatusClause } from './meetingVisibility.js';

export const SEARCH_PAGE_SIZE = 25;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface SearchResult {
  meetingId: string;
  title: string | null;
  eventKind: EventKind;
  eventOrgs: string[];
  sourceTitle: string | null;
  city: string;
  meetingType: string;
  date: string;
  segmentIndex: number;
  startTime: number;
  endTime: number;
  speakerName: string | null;
  politicianId: string | null;
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
  title: string | null;
  event_kind: EventKind;
  event_orgs: string[] | null;
  source_title: string | null;
  city: string;
  meeting_type: string;
  date: string;
  segment_index: string;
  start_time: string;
  end_time: string;
  speaker_name: string | null;
  politician_id: string | null;
  snippet: string;
}

// ---------------------------------------------------------------------------
// Mapper (explicit camelCase — NEVER spread rows)
// ---------------------------------------------------------------------------

function mapResult(row: SearchRow): SearchResult {
  return {
    meetingId: row.meeting_id,
    title: row.title,
    eventKind: row.event_kind,
    eventOrgs: row.event_orgs ?? [],
    sourceTitle: row.source_title,
    city: row.city,
    meetingType: row.meeting_type,
    date: row.date,
    segmentIndex: Number(row.segment_index),
    startTime: Number(row.start_time),
    endTime: Number(row.end_time),
    speakerName: row.speaker_name,
    politicianId: row.politician_id,
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

  // Public status gate (ev-cto decision 0017): the "pipeline only inserts
  // segments for published meetings" invariant NO LONGER HOLDS — the House-floor
  // weekly automation writes draft meetings WITH transcript segments for human
  // review. Full-text search is the highest-risk leak (a draft's transcript text
  // would be searchable), so gate every hit on the parent meeting's status. The
  // gate is joined below via `meetings.meetings m`.
  const conditions: string[] = [
    `s.tsv @@ websearch_to_tsquery('english', $1)`,
    publicMeetingStatusClause('m.status'),
  ];
  const params: unknown[] = [q];
  if (speaker !== undefined) {
    params.push(speaker);
    conditions.push(`sp.politician_id = $${params.length}`);
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
                s.speaker_name, sp.politician_id, s.text,
                ts_rank(s.tsv, websearch_to_tsquery('english', $1)) AS rank,
                m.city, m.meeting_type, m.date::text AS date,
                m.title, m.event_kind,
                m.processing_metadata->>'source_title' AS source_title,
                (SELECT COALESCE(array_agg(eo.org_name ORDER BY eo.created_at), ARRAY[]::text[])
                 FROM meetings.event_orgs eo WHERE eo.meeting_id = m.slug) AS event_orgs
         FROM meetings.segments s
         JOIN meetings.meetings m ON m.id = s.meeting_id
         LEFT JOIN meetings.speakers sp ON sp.id = s.speaker_id
         WHERE ${where}
         ORDER BY rank DESC, m.date DESC, s.meeting_id, s.segment_index
         LIMIT $${limitParam} OFFSET $${offsetParam}
       )
       SELECT meeting_id, title, event_kind, event_orgs, source_title,
              city, meeting_type, date, segment_index,
              start_time, end_time, speaker_name, politician_id,
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
       LEFT JOIN meetings.speakers sp ON sp.id = s.speaker_id
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
