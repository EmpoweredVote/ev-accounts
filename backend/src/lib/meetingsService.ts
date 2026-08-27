/**
 * meetingsService — city council meeting data for the meetings schema.
 *
 * WHY THIS FILE EXISTS:
 * The meetings schema is NOT in the PostgREST exposed schema list.
 * ALL reads AND writes must use pool.query() (direct postgres).
 *
 * The on-the-record pipeline (CouncilScribe) is the sole writer. This service
 * is read-only — all write paths are in the pipeline's publish.py.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 *
 * Bigint/numeric note: pg driver returns bigint and numeric as JavaScript
 * strings. Always call Number() on: segment_index, segment_count,
 * speaker_count, start_time, end_time, duration_seconds, confidence.
 */

import { pool } from './db.js';
import { toIsoStringOrNull } from './pgIso.js';
import type { EventKind } from './eventKinds.js';
import type { EventEntityState } from './eventEntityRules.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface Meeting {
  id: string;
  title: string | null;
  eventKind: EventKind;
  city: string | null;
  state: string | null;
  date: string;
  meetingType: string;
  durationSeconds: number | null;
  videoUrl: string | null;
  audioSource: string | null;
  status: string;
  segmentCount: number | null;
  speakerCount: number | null;
  createdAt: string | null;
  updatedAt: string | null;
  // on-the-record fields
  chamberId: string | null;
  raceIds: string[];
  sourceUrl: string | null;
  playbackKind: string | null;
  clipStartSeconds: number | null;
  clipEndSeconds: number | null;
  slug: string | null;
  summary: unknown | null;
  processingMetadata: unknown | null;
  summaryPreview: string | null;
  thumbnailUrl: string | null;
  startsAt: string | null;
  timezone: string | null;
}

/**
 * List payload shape. Omits the full `summary` JSONB (all sections, content,
 * key_decisions) so the meetings list endpoint only ships the short
 * `summaryPreview`. The full `summary` rides the detail endpoint only.
 */
export type MeetingListItem = Omit<Meeting, 'summary'>;

export interface Speaker {
  id: string;
  meetingId: string;
  label: string;
  displayName: string | null;
  confidence: number | null;
  idMethod: string | null;
  politicianId: string | null;
  politicianSlug: string | null;
  createdAt: string | null;
  localSlug: string | null;
  localName: string | null;
  localRole: string | null;
}

export interface Segment {
  id: string;
  meetingId: string;
  speakerId: string;
  segmentIndex: number;
  startTime: number;
  endTime: number;
  text: string;
  speakerLabel: string | null;
  speakerName: string | null;
  politicianSlug: string | null;
  confidence: number | null;
}

export interface MeetingSummary {
  id: string;
  meetingId: string;
  summaryType: string;
  model: string | null;
  createdAt: string | null;
  executiveSummary: string;
  keyDecisions: string[];
  sections: SummarySection[];
}

export interface SummarySection {
  id: string;
  summaryId: string;
  sectionType: string;
  title: string;
  content: string;
  startTime: number | null;
  endTime: number | null;
  sortOrder: number;
  topics: { key: string; title: string | null; status: string }[];
}

export interface Vote {
  id: string;
  meetingId: string;
  resolution: string | null;
  description: string | null;
  result: string;
  voteType: string | null;
  timestamp: number | null;
  createdAt: string | null;
  records: VoteRecord[];
}

export interface VoteRecord {
  id: string;
  voteId: string;
  speakerId: string;
  position: string;
}

// ---------------------------------------------------------------------------
// Row type helpers (pg query result shapes)
// ---------------------------------------------------------------------------

interface MeetingRow {
  id: string;
  title: string | null;
  event_kind: EventKind;
  city: string | null;
  state: string | null;
  date: string;
  meeting_type: string;
  duration_seconds: string | null;
  video_url: string | null;
  audio_source: string | null;
  status: string;
  segment_count: string | null;
  speaker_count: string | null;
  created_at: string | null;
  updated_at: string | null;
  chamber_id: string | null;
  race_ids: string[] | null;
  source_url: string | null;
  playback_kind: string | null;
  clip_start_seconds: string | null;
  clip_end_seconds: string | null;
  slug: string | null;
  summary: unknown | null;
  processing_metadata: unknown | null;
  thumbnail_url: string | null;
  starts_at: string | Date | null; // pg returns timestamptz as Date
  timezone: string | null;
}

interface SpeakerRow {
  id: string;
  meeting_id: string;
  label: string;
  display_name: string | null;
  confidence: string | null;
  id_method: string | null;
  politician_id: string | null;
  politician_slug: string | null;
  created_at: string | null;
  local_slug: string | null;
  local_name: string | null;
  local_role: string | null;
}

interface SegmentRow {
  id: string;
  meeting_id: string;
  speaker_id: string;
  segment_index: string;
  start_time: string;
  end_time: string;
  text: string;
  speaker_label: string | null;
  speaker_name: string | null;
  politician_slug: string | null;
  confidence: string | null;
}

interface VoteRow {
  id: string;
  meeting_id: string;
  resolution: string | null;
  description: string | null;
  result: string;
  vote_type: string | null;
  timestamp: string | null;
  created_at: string | null;
}

interface VoteRecordRow {
  id: string;
  vote_id: string;
  speaker_id: string;
  position: string;
}

// ---------------------------------------------------------------------------
// Mappers (explicit camelCase — NEVER spread rows)
// ---------------------------------------------------------------------------

/**
 * First sentence of `text` — everything up to and including the first `.`/`!`/`?`
 * that is followed by whitespace or end-of-string. Trimmed. Returns null for
 * empty/missing input; returns the whole trimmed string when there is no
 * terminator. No length cap: the meeting list shows the full first sentence.
 */
export function firstSentence(text: string | null | undefined): string | null {
  if (!text) return null;
  const trimmed = text.trim();
  if (!trimmed) return null;
  const match = /^.*?[.!?](?=\s|$)/s.exec(trimmed);
  return match ? match[0] : trimmed;
}

function mapMeeting(row: MeetingRow): Meeting {
  return {
    id: row.id,
    title: row.title,
    eventKind: row.event_kind,
    city: row.city,
    state: row.state,
    date: row.date,
    meetingType: row.meeting_type,
    durationSeconds: row.duration_seconds !== null ? Number(row.duration_seconds) : null,
    videoUrl: row.video_url,
    audioSource: row.audio_source,
    status: row.status,
    segmentCount: row.segment_count !== null ? Number(row.segment_count) : null,
    speakerCount: row.speaker_count !== null ? Number(row.speaker_count) : null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    chamberId: row.chamber_id,
    raceIds: row.race_ids ?? [],
    sourceUrl: row.source_url,
    playbackKind: row.playback_kind,
    clipStartSeconds: row.clip_start_seconds !== null ? Number(row.clip_start_seconds) : null,
    clipEndSeconds: row.clip_end_seconds !== null ? Number(row.clip_end_seconds) : null,
    slug: row.slug,
    summary: row.summary,
    processingMetadata: row.processing_metadata,
    summaryPreview: firstSentence(
      (row.summary as { executive_summary?: string } | null)?.executive_summary,
    ),
    thumbnailUrl: row.thumbnail_url ?? null,
    startsAt: toIsoStringOrNull(row.starts_at),
    timezone: row.timezone ?? null,
  };
}

// List mapper: drops the full `summary` JSONB so only `summaryPreview` rides
// the list payload. Detail paths use mapMeeting() to keep the full summary.
function mapMeetingListItem(row: MeetingRow): MeetingListItem {
  const { summary: _summary, ...rest } = mapMeeting(row);
  return rest;
}

function mapSpeaker(row: SpeakerRow): Speaker {
  return {
    id: row.id,
    meetingId: row.meeting_id,
    label: row.label,
    displayName: row.display_name,
    confidence: row.confidence !== null ? Number(row.confidence) : null,
    idMethod: row.id_method,
    politicianId: row.politician_id,
    politicianSlug: row.politician_slug,
    createdAt: row.created_at,
    localSlug: row.local_slug,
    localName: row.local_name,
    localRole: row.local_role,
  };
}

function mapSegment(row: SegmentRow): Segment {
  return {
    id: row.id,
    meetingId: row.meeting_id,
    speakerId: row.speaker_id,
    segmentIndex: Number(row.segment_index),
    startTime: Number(row.start_time),
    endTime: Number(row.end_time),
    text: row.text,
    speakerLabel: row.speaker_label,
    speakerName: row.speaker_name,
    politicianSlug: row.politician_slug,
    confidence: row.confidence !== null ? Number(row.confidence) : null,
  };
}

function mapVote(row: VoteRow): Vote {
  return {
    id: row.id,
    meetingId: row.meeting_id,
    resolution: row.resolution,
    description: row.description,
    result: row.result,
    voteType: row.vote_type,
    timestamp: row.timestamp !== null ? Number(row.timestamp) : null,
    createdAt: row.created_at,
    records: [],
  };
}

function mapVoteRecord(row: VoteRecordRow): VoteRecord {
  return {
    id: row.id,
    voteId: row.vote_id,
    speakerId: row.speaker_id,
    position: row.position,
  };
}

// ---------------------------------------------------------------------------
// Public read functions
// ---------------------------------------------------------------------------

const MEETING_COLS = `
  id, title, event_kind, city, state, date::text AS date, meeting_type,
  duration_seconds, video_url, audio_source,
  status, segment_count, speaker_count, created_at, updated_at,
  chamber_id,
  COALESCE(
    (SELECT array_agg(er.race_id) FROM meetings.event_races er
     WHERE er.meeting_id = meetings.meetings.id),
    ARRAY[]::uuid[]
  ) AS race_ids,
  source_url, playback_kind, clip_start_seconds, clip_end_seconds, slug, summary, processing_metadata,
  thumbnail_url, starts_at, timezone
`;

export async function getMeetings(
  filters?: { city?: string; state?: string; status?: string; raceId?: string }
): Promise<MeetingListItem[]> {
  const params: string[] = [];
  const conditions: string[] = [];

  if (filters?.city !== undefined) {
    params.push(filters.city);
    conditions.push(`city = $${params.length}`);
  }
  if (filters?.state !== undefined) {
    params.push(filters.state);
    conditions.push(`state = $${params.length}`);
  }
  if (filters?.status !== undefined) {
    params.push(filters.status);
    conditions.push(`status = $${params.length}`);
  } else {
    // Scheduled (agenda-only) meetings must not leak into the default list;
    // every consumer of the unfiltered list predates their existence.
    conditions.push(`status = 'published'`);
  }
  if (filters?.raceId !== undefined) {
    params.push(filters.raceId);
    conditions.push(
      `EXISTS (SELECT 1 FROM meetings.event_races er
               WHERE er.meeting_id = meetings.meetings.id
                 AND er.race_id = $${params.length}::uuid)`
    );
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await pool.query<MeetingRow>(
    `SELECT ${MEETING_COLS}
     FROM meetings.meetings
     ${whereClause}
     ORDER BY date DESC`,
    params
  );

  return rows.map(mapMeetingListItem);
}

/** Scheduled (agenda-published) meetings from today forward, soonest first. */
// `date >= CURRENT_DATE` evaluates in the DB session zone (UTC) — an acceptable
// soft edge for an upcoming list: rows linger slightly past meeting-local
// midnight for US zones (they flip to published after processing anyway).
export async function getUpcomingMeetings(): Promise<MeetingListItem[]> {
  const { rows } = await pool.query<MeetingRow>(
    `SELECT ${MEETING_COLS}
     FROM meetings.meetings
     WHERE status = 'scheduled' AND date >= CURRENT_DATE
     ORDER BY date ASC, starts_at ASC NULLS LAST`
  );
  return rows.map(mapMeetingListItem);
}

export async function getMeetingById(
  id: string
): Promise<(Meeting & { speakers: Speaker[] }) | null> {
  const { rows: meetingRows } = await pool.query<MeetingRow>(
    `SELECT ${MEETING_COLS} FROM meetings.meetings WHERE id = $1`,
    [id]
  );

  if (meetingRows.length === 0) return null;

  const meeting = mapMeeting(meetingRows[0]);

  const { rows: speakerRows } = await pool.query<SpeakerRow>(
    `SELECT sp.id, sp.meeting_id, sp.label, sp.display_name, sp.confidence, sp.id_method,
            sp.politician_id, sp.politician_slug, sp.local_slug, sp.created_at,
            lp.name AS local_name, lp.role AS local_role
     FROM meetings.speakers sp
     LEFT JOIN meetings.local_people lp ON lp.slug = sp.local_slug
     WHERE sp.meeting_id = $1
     ORDER BY sp.label`,
    [id]
  );

  return { ...meeting, speakers: speakerRows.map(mapSpeaker) };
}

export async function getTranscriptByMeetingId(
  meetingId: string,
  page: number
): Promise<{ segments: Segment[]; page: number; totalCount: number }> {
  const limit = 200;
  const offset = (page - 1) * limit;

  const [{ rows: segmentRows }, { rows: countRows }] = await Promise.all([
    pool.query<SegmentRow>(
      // JOIN speakers so speaker_label is available without a second query
      `SELECT s.id, s.meeting_id, s.speaker_id, s.segment_index,
              s.start_time, s.end_time, s.text,
              s.speaker_name, s.politician_slug, s.confidence,
              sp.label AS speaker_label
       FROM meetings.segments s
       LEFT JOIN meetings.speakers sp ON sp.id = s.speaker_id
       WHERE s.meeting_id = $1
       ORDER BY s.segment_index
       LIMIT ${limit} OFFSET $2`,
      [meetingId, offset]
    ),
    pool.query<{ count: string }>(
      `SELECT COUNT(*) AS count FROM meetings.segments WHERE meeting_id = $1`,
      [meetingId]
    ),
  ]);

  return {
    segments: segmentRows.map(mapSegment),
    page,
    totalCount: Number(countRows[0].count),
  };
}

export async function getSummaryByMeetingId(
  meetingId: string
): Promise<MeetingSummary | null> {
  const { rows } = await pool.query<{ summary: unknown | null }>(
    `SELECT summary FROM meetings.meetings WHERE id = $1`,
    [meetingId]
  );
  if (rows.length === 0 || !rows[0].summary) return null;

  // summary JSONB shape (written by publish.py): { executive_summary,
  // key_decisions[], sections[], model, generated_at }
  const s = rows[0].summary as {
    executive_summary?: string;
    key_decisions?: string[];
    sections?: Array<{
      section_type: string; title: string; content: string;
      start_time?: number; end_time?: number;
      start_segment?: number; end_segment?: number;
    }>;
    model?: string;
    generated_at?: string;
  };

  // Attach topic tags by section_index (meeting_topics is the source of truth).
  const { rows: topicRows } = await pool.query<{
    section_index: string; topic_key: string; status: string; title: string | null;
  }>(
    `SELECT mt.section_index, mt.topic_key, mt.status, ctc.short_title AS title
     FROM meetings.meeting_topics mt
     LEFT JOIN inform.compass_topics ct
       ON ct.topic_key = mt.topic_key AND ct.is_live = true
     -- TEXT ONLY (ADR 0004). ct keeps the match and the is_live gate; ctc carries
     -- the current revision's wording. CA_0012 froze ct's own text columns.
     LEFT JOIN inform.compass_topics_current ctc ON ctc.id = ct.id
     WHERE mt.meeting_id = $1`,
    [meetingId]
  );
  const topicsByIndex = new Map<number, { key: string; title: string | null; status: string }[]>();
  for (const r of topicRows) {
    const idx = Number(r.section_index);
    const list = topicsByIndex.get(idx) ?? [];
    list.push({ key: r.topic_key, title: r.title, status: r.status });
    topicsByIndex.set(idx, list);
  }

  const sections: SummarySection[] = (s.sections ?? []).map((sec, i) => ({
    id: `${meetingId}:${i}`,
    summaryId: meetingId,
    sectionType: sec.section_type,
    title: sec.title,
    content: sec.content,
    startTime: sec.start_time != null ? Number(sec.start_time) : null,
    endTime: sec.end_time != null ? Number(sec.end_time) : null,
    sortOrder: i,
    topics: topicsByIndex.get(i) ?? [],
  }));

  return {
    id: meetingId,
    meetingId,
    summaryType: 'meeting',
    model: s.model ?? null,
    createdAt: s.generated_at ?? null,
    executiveSummary: s.executive_summary ?? '',
    keyDecisions: s.key_decisions ?? [],
    sections,
  };
}

export async function getVotesByMeetingId(meetingId: string): Promise<Vote[]> {
  const { rows: voteRows } = await pool.query<VoteRow>(
    `SELECT id, meeting_id, resolution, description, result, vote_type, timestamp, created_at
     FROM meetings.votes
     WHERE meeting_id = $1
     ORDER BY timestamp`,
    [meetingId]
  );

  if (voteRows.length === 0) return [];

  const voteIds = voteRows.map((r) => r.id);

  const { rows: recordRows } = await pool.query<VoteRecordRow>(
    `SELECT id, vote_id, speaker_id, position
     FROM meetings.vote_records
     WHERE vote_id = ANY($1)`,
    [voteIds]
  );

  const recordsByVoteId = new Map<string, VoteRecord[]>();
  for (const record of recordRows) {
    const mapped = mapVoteRecord(record);
    const existing = recordsByVoteId.get(record.vote_id);
    if (existing) existing.push(mapped);
    else recordsByVoteId.set(record.vote_id, [mapped]);
  }

  return voteRows.map((row) => {
    const vote = mapVote(row);
    vote.records = recordsByVoteId.get(row.id) ?? [];
    return vote;
  });
}

// ---------------------------------------------------------------------------
// Admin write functions (kept for completeness; pipeline writes via psycopg2)
// ---------------------------------------------------------------------------

export async function createMeeting(data: {
  city?: string | null;
  state: string;
  date: string;
  meetingType: string;
  title?: string | null;
  eventKind?: EventKind;
  chamberId?: string | null;
  durationSeconds?: number | null;
  videoUrl?: string | null;
  audioSource?: string | null;
  status?: string;
}): Promise<Meeting> {
  const { rows } = await pool.query<MeetingRow>(
    `INSERT INTO meetings.meetings
       (city, state, date, meeting_type, duration_seconds, video_url,
        audio_source, status, title, event_kind, chamber_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING ${MEETING_COLS}`,
    [
      data.city ?? null,
      data.state,
      data.date,
      data.meetingType,
      data.durationSeconds ?? null,
      data.videoUrl ?? null,
      data.audioSource ?? null,
      data.status ?? 'processing',
      data.title ?? null,
      data.eventKind ?? 'council',
      data.chamberId ?? null,
    ]
  );
  return mapMeeting(rows[0]);
}

export async function updateMeeting(
  id: string,
  data: Partial<{
    city: string | null;
    title: string | null;
    eventKind: EventKind;
    chamberId: string | null;
    state: string;
    date: string;
    meetingType: string;
    durationSeconds: number | null;
    videoUrl: string | null;
    audioSource: string | null;
    status: string;
  }>
): Promise<Meeting | null> {
  const setClauses: string[] = [];
  const params: unknown[] = [];

  if (data.title !== undefined) { params.push(data.title); setClauses.push(`title = $${params.length}`); }
  if (data.eventKind !== undefined) { params.push(data.eventKind); setClauses.push(`event_kind = $${params.length}`); }
  if (data.chamberId !== undefined) { params.push(data.chamberId); setClauses.push(`chamber_id = $${params.length}`); }
  if (data.city !== undefined) { params.push(data.city); setClauses.push(`city = $${params.length}`); }
  if (data.state !== undefined) { params.push(data.state); setClauses.push(`state = $${params.length}`); }
  if (data.date !== undefined) { params.push(data.date); setClauses.push(`date = $${params.length}`); }
  if (data.meetingType !== undefined) { params.push(data.meetingType); setClauses.push(`meeting_type = $${params.length}`); }
  if (data.durationSeconds !== undefined) { params.push(data.durationSeconds); setClauses.push(`duration_seconds = $${params.length}`); }
  if (data.videoUrl !== undefined) { params.push(data.videoUrl); setClauses.push(`video_url = $${params.length}`); }
  if (data.audioSource !== undefined) { params.push(data.audioSource); setClauses.push(`audio_source = $${params.length}`); }
  if (data.status !== undefined) { params.push(data.status); setClauses.push(`status = $${params.length}`); }

  if (setClauses.length === 0) {
    return getMeetingById(id).then((r) => (r ? { ...r } : null));
  }

  setClauses.push(`updated_at = NOW()`);
  params.push(id);

  const { rows } = await pool.query<MeetingRow>(
    `UPDATE meetings.meetings
     SET ${setClauses.join(', ')}
     WHERE id = $${params.length}
     RETURNING ${MEETING_COLS}`,
    params
  );

  return rows.length > 0 ? mapMeeting(rows[0]) : null;
}

export async function getMeetingEntityState(
  id: string
): Promise<EventEntityState | null> {
  const { rows } = await pool.query<{
    event_kind: EventKind;
    chamber_id: string | null;
  }>(
    `SELECT event_kind, chamber_id
     FROM meetings.meetings
     WHERE id = $1`,
    [id]
  );

  if (rows.length === 0) return null;

  return {
    eventKind: rows[0].event_kind,
    chamberId: rows[0].chamber_id,
  };
}

export async function deleteMeeting(id: string): Promise<boolean> {
  await pool.query(
    `DELETE FROM meetings.vote_records
     WHERE vote_id IN (SELECT id FROM meetings.votes WHERE meeting_id = $1)`,
    [id]
  );
  await pool.query(`DELETE FROM meetings.votes WHERE meeting_id = $1`, [id]);
  // The summary is a JSONB column on meetings.meetings (removed with the row
  // below); the meeting_summaries/summary_sections tables never existed. Topic
  // tags clean up via ON DELETE CASCADE on meeting_topics.meeting_id.
  await pool.query(`DELETE FROM meetings.segments WHERE meeting_id = $1`, [id]);
  await pool.query(`DELETE FROM meetings.speakers WHERE meeting_id = $1`, [id]);

  const { rows } = await pool.query<{ id: string }>(
    `DELETE FROM meetings.meetings WHERE id = $1 RETURNING id`,
    [id]
  );

  return rows.length > 0;
}
