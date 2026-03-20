/**
 * meetingsService — city council meeting data lookups for the meetings schema.
 *
 * WHY THIS FILE EXISTS:
 * The meetings schema is NOT in the PostgREST exposed schema list
 * (`public, connect, empower, inform, graphql_public, validation_quests`).
 * `supabaseAnon.schema('meetings')` would fail at runtime.
 * ALL meetings reads AND writes must use pool.query() (direct postgres).
 *
 * Purpose: Satisfies CONS-09 — Meetings endpoints served by ev-accounts.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 *
 * Bigint/numeric note: The pg driver returns bigint and numeric columns as
 * JavaScript strings. Always call Number() on: segment_index, segment_count,
 * speaker_count, sort_order, start_time, end_time, timestamp, duration_seconds,
 * confidence. Use `value !== null ? Number(value) : null` for nullable columns.
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface Meeting {
  id: string;
  city: string;
  state: string;
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
}

export interface Speaker {
  id: string;
  meetingId: string;
  label: string;
  displayName: string | null;
  confidence: number | null;
  idMethod: string | null;
  politicianId: string | null;
  createdAt: string | null;
}

export interface Segment {
  id: string;
  meetingId: string;
  speakerId: string;
  segmentIndex: number;
  startTime: number;
  endTime: number;
  text: string;
}

export interface MeetingSummary {
  id: string;
  meetingId: string;
  summaryType: string;
  model: string | null;
  createdAt: string | null;
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
  city: string;
  state: string;
  date: string;
  meeting_type: string;
  duration_seconds: string | null; // numeric → string
  video_url: string | null;
  audio_source: string | null;
  status: string;
  segment_count: string | null; // bigint → string
  speaker_count: string | null; // bigint → string
  created_at: string | null;
  updated_at: string | null;
}

interface SpeakerRow {
  id: string;
  meeting_id: string;
  label: string;
  display_name: string | null;
  confidence: string | null; // numeric → string
  id_method: string | null;
  politician_id: string | null;
  created_at: string | null;
}

interface SegmentRow {
  id: string;
  meeting_id: string;
  speaker_id: string;
  segment_index: string; // bigint → string
  start_time: string; // numeric → string
  end_time: string; // numeric → string
  text: string;
}

interface SummaryRow {
  id: string;
  meeting_id: string;
  summary_type: string;
  model: string | null;
  created_at: string | null;
}

interface SummarySectionRow {
  id: string;
  summary_id: string;
  section_type: string;
  title: string;
  content: string;
  start_time: string | null; // numeric → string
  end_time: string | null; // numeric → string
  sort_order: string | null; // bigint → string
}

interface VoteRow {
  id: string;
  meeting_id: string;
  resolution: string | null;
  description: string | null;
  result: string;
  vote_type: string | null;
  timestamp: string | null; // numeric → string
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

function mapMeeting(row: MeetingRow): Meeting {
  return {
    id: row.id,
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
  };
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
    createdAt: row.created_at,
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
  };
}

function mapSummarySection(row: SummarySectionRow): SummarySection {
  return {
    id: row.id,
    summaryId: row.summary_id,
    sectionType: row.section_type,
    title: row.title,
    content: row.content,
    startTime: row.start_time !== null ? Number(row.start_time) : null,
    endTime: row.end_time !== null ? Number(row.end_time) : null,
    sortOrder: row.sort_order !== null ? Number(row.sort_order) : 0,
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

/**
 * Fetch meetings with optional filters. Never uses string interpolation —
 * all filter values are parameterized.
 */
export async function getMeetings(
  filters?: { city?: string; state?: string; status?: string }
): Promise<Meeting[]> {
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
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await pool.query<MeetingRow>(
    `SELECT id, city, state, date, meeting_type, duration_seconds, video_url, audio_source,
            status, segment_count, speaker_count, created_at, updated_at
     FROM meetings.meetings
     ${whereClause}
     ORDER BY date DESC`,
    params
  );

  return rows.map(mapMeeting);
}

/**
 * Fetch a single meeting by UUID with its speakers. Returns null if not found.
 */
export async function getMeetingById(
  id: string
): Promise<(Meeting & { speakers: Speaker[] }) | null> {
  const { rows: meetingRows } = await pool.query<MeetingRow>(
    `SELECT id, city, state, date, meeting_type, duration_seconds, video_url, audio_source,
            status, segment_count, speaker_count, created_at, updated_at
     FROM meetings.meetings
     WHERE id = $1`,
    [id]
  );

  if (meetingRows.length === 0) return null;

  const meeting = mapMeeting(meetingRows[0]);

  const { rows: speakerRows } = await pool.query<SpeakerRow>(
    `SELECT id, meeting_id, label, display_name, confidence, id_method, politician_id, created_at
     FROM meetings.speakers
     WHERE meeting_id = $1
     ORDER BY label`,
    [id]
  );

  return {
    ...meeting,
    speakers: speakerRows.map(mapSpeaker),
  };
}

/**
 * Fetch paginated transcript segments for a meeting.
 * page is 1-indexed, returns 200 segments per page.
 */
export async function getTranscriptByMeetingId(
  meetingId: string,
  page: number
): Promise<{ segments: Segment[]; page: number; totalCount: number }> {
  const limit = 200;
  const offset = (page - 1) * limit;

  const [{ rows: segmentRows }, { rows: countRows }] = await Promise.all([
    pool.query<SegmentRow>(
      `SELECT id, meeting_id, speaker_id, segment_index, start_time, end_time, text
       FROM meetings.segments
       WHERE meeting_id = $1
       ORDER BY segment_index
       LIMIT 200 OFFSET $2`,
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

/**
 * Fetch the summary (with sections) for a meeting. Returns null if none exists.
 */
export async function getSummaryByMeetingId(
  meetingId: string
): Promise<MeetingSummary | null> {
  const { rows: summaryRows } = await pool.query<SummaryRow>(
    `SELECT id, meeting_id, summary_type, model, created_at
     FROM meetings.meeting_summaries
     WHERE meeting_id = $1
     LIMIT 1`,
    [meetingId]
  );

  if (summaryRows.length === 0) return null;

  const summaryRow = summaryRows[0];

  const { rows: sectionRows } = await pool.query<SummarySectionRow>(
    `SELECT id, summary_id, section_type, title, content, start_time, end_time, sort_order
     FROM meetings.summary_sections
     WHERE summary_id = $1
     ORDER BY sort_order`,
    [summaryRow.id]
  );

  return {
    id: summaryRow.id,
    meetingId: summaryRow.meeting_id,
    summaryType: summaryRow.summary_type,
    model: summaryRow.model,
    createdAt: summaryRow.created_at,
    sections: sectionRows.map(mapSummarySection),
  };
}

/**
 * Fetch all votes (with embedded vote records) for a meeting.
 */
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

  // Group records by vote_id
  const recordsByVoteId = new Map<string, VoteRecord[]>();
  for (const record of recordRows) {
    const mapped = mapVoteRecord(record);
    const existing = recordsByVoteId.get(record.vote_id);
    if (existing) {
      existing.push(mapped);
    } else {
      recordsByVoteId.set(record.vote_id, [mapped]);
    }
  }

  return voteRows.map((row) => {
    const vote = mapVote(row);
    vote.records = recordsByVoteId.get(row.id) ?? [];
    return vote;
  });
}

// ---------------------------------------------------------------------------
// Admin write functions
// ---------------------------------------------------------------------------

/**
 * Create a new meeting.
 */
export async function createMeeting(data: {
  city: string;
  state: string;
  date: string;
  meetingType: string;
  durationSeconds?: number | null;
  videoUrl?: string | null;
  audioSource?: string | null;
  status?: string;
}): Promise<Meeting> {
  const { rows } = await pool.query<MeetingRow>(
    `INSERT INTO meetings.meetings
       (city, state, date, meeting_type, duration_seconds, video_url, audio_source, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING id, city, state, date, meeting_type, duration_seconds, video_url, audio_source,
               status, segment_count, speaker_count, created_at, updated_at`,
    [
      data.city,
      data.state,
      data.date,
      data.meetingType,
      data.durationSeconds ?? null,
      data.videoUrl ?? null,
      data.audioSource ?? null,
      data.status ?? 'processing',
    ]
  );
  return mapMeeting(rows[0]);
}

/**
 * Update a meeting by UUID. Only provided fields are changed.
 * Returns null if meeting not found.
 */
export async function updateMeeting(
  id: string,
  data: Partial<{
    city: string;
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

  if (data.city !== undefined) {
    params.push(data.city);
    setClauses.push(`city = $${params.length}`);
  }
  if (data.state !== undefined) {
    params.push(data.state);
    setClauses.push(`state = $${params.length}`);
  }
  if (data.date !== undefined) {
    params.push(data.date);
    setClauses.push(`date = $${params.length}`);
  }
  if (data.meetingType !== undefined) {
    params.push(data.meetingType);
    setClauses.push(`meeting_type = $${params.length}`);
  }
  if (data.durationSeconds !== undefined) {
    params.push(data.durationSeconds);
    setClauses.push(`duration_seconds = $${params.length}`);
  }
  if (data.videoUrl !== undefined) {
    params.push(data.videoUrl);
    setClauses.push(`video_url = $${params.length}`);
  }
  if (data.audioSource !== undefined) {
    params.push(data.audioSource);
    setClauses.push(`audio_source = $${params.length}`);
  }
  if (data.status !== undefined) {
    params.push(data.status);
    setClauses.push(`status = $${params.length}`);
  }

  if (setClauses.length === 0) {
    // Nothing to update — fetch and return current state
    return getMeetingById(id).then((r) => (r ? { ...r } : null));
  }

  setClauses.push(`updated_at = NOW()`);
  params.push(id);
  const idParam = `$${params.length}`;

  const { rows } = await pool.query<MeetingRow>(
    `UPDATE meetings.meetings
     SET ${setClauses.join(', ')}
     WHERE id = ${idParam}
     RETURNING id, city, state, date, meeting_type, duration_seconds, video_url, audio_source,
               status, segment_count, speaker_count, created_at, updated_at`,
    params
  );

  return rows.length > 0 ? mapMeeting(rows[0]) : null;
}

/**
 * Delete a meeting and all its child data (manual cascade).
 * Returns true if deleted, false if not found.
 */
export async function deleteMeeting(id: string): Promise<boolean> {
  // Manual cascade — delete child rows in dependency order
  await pool.query(
    `DELETE FROM meetings.vote_records
     WHERE vote_id IN (SELECT id FROM meetings.votes WHERE meeting_id = $1)`,
    [id]
  );
  await pool.query(`DELETE FROM meetings.votes WHERE meeting_id = $1`, [id]);
  await pool.query(
    `DELETE FROM meetings.summary_sections
     WHERE summary_id IN (SELECT id FROM meetings.meeting_summaries WHERE meeting_id = $1)`,
    [id]
  );
  await pool.query(`DELETE FROM meetings.meeting_summaries WHERE meeting_id = $1`, [id]);
  await pool.query(`DELETE FROM meetings.segments WHERE meeting_id = $1`, [id]);
  await pool.query(`DELETE FROM meetings.speakers WHERE meeting_id = $1`, [id]);

  const { rows } = await pool.query<{ id: string }>(
    `DELETE FROM meetings.meetings WHERE id = $1 RETURNING id`,
    [id]
  );

  return rows.length > 0;
}
