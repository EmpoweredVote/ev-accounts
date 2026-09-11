// Read-only service for meetings.agenda_items — the citizen-facing agenda-item
// atoms published by the on-the-record pipeline (which is the sole writer).
//
// Same rules as meetingsService.ts:
// - meetings schema is NOT PostgREST-exposed: pool.query() only, schema-qualified.
// - DTOs are explicit whitelists (never spread rows); camelCase out.
// - Number() every numeric — pg returns them as strings.
import { pool } from './db.js';
import { toIsoStringOrNull } from './pgIso.js';
import {
  publicMeetingStatusClause,
  publicMeetingExistsClause,
  type MeetingViewerOptions,
} from './meetingVisibility.js';

export interface AgendaItem {
  id: string;
  meetingId: string;
  position: number;
  itemNumber: string;
  titleRaw: string;
  kind: string;
  legislationRef: string | null;
  summaryPlain: string | null;
  decisionPlain: string | null;
  stage: string | null;
  publicComment: boolean;
  publicCommentNote: string | null;
  status: 'upcoming' | 'happened';
  outcome: string | null;
  segmentStartSeconds: number | null;
  segmentEndSeconds: number | null;
  continuedFromItemId: string | null;
  sourceUrl: string;
}

export interface AgendaItemVoteRecord {
  position: string;
  name: string | null;
  politicianId: string | null;
}

export interface AgendaItemVote {
  id: string;
  resolution: string | null;
  description: string | null;
  result: string;
  voteType: string | null;
  timestamp: number | null;
  records: AgendaItemVoteRecord[];
}

export interface AgendaItemSpeaker {
  name: string;
  politicianId: string | null;
  role: string | null;
  firstSpokeSeconds: number;
  segmentCount: number;
}

export interface AgendaItemDetail extends AgendaItem {
  meeting: {
    id: string;
    title: string | null;
    date: string;
    city: string | null;
    status: string;
    startsAt: string | null;
    timezone: string | null;
  };
  // Roll-call votes hung off this item (votes.agenda_item_id — written by the
  // clerk-memo reconciler). Empty until reconciliation runs for the meeting.
  votes: AgendaItemVote[];
  // People who spoke within the item's segment span. Empty until the video
  // pass binds segment bounds (and for items the alignment abstained on).
  speakers: AgendaItemSpeaker[];
  // Minimal pointer to the prior appearance of the same matter
  // (continued_from_item_id — the matter-tracking seed).
  continuedFrom: {
    id: string;
    itemNumber: string;
    meetingDate: string;
  } | null;
}

interface AgendaItemRow {
  id: string;
  meeting_id: string;
  position: string | number;
  item_number: string;
  title_raw: string;
  kind: string;
  legislation_ref: string | null;
  summary_plain: string | null;
  decision_plain: string | null;
  stage: string | null;
  public_comment: boolean;
  public_comment_note: string | null;
  status: 'upcoming' | 'happened';
  outcome: string | null;
  segment_start_seconds: string | number | null;
  segment_end_seconds: string | number | null;
  continued_from_item_id: string | null;
  source_url: string;
}

interface AgendaItemDetailRow extends AgendaItemRow {
  m_id: string;
  m_title: string | null;
  m_date: string;
  m_city: string | null;
  m_status: string;
  m_starts_at: string | Date | null; // pg returns timestamptz as Date
  m_timezone: string | null;
  cf_id: string | null;
  cf_item_number: string | null;
  cf_meeting_date: string | null;
}

interface ItemVoteRow {
  id: string;
  resolution: string | null;
  description: string | null;
  result: string;
  vote_type: string | null;
  timestamp: string | number | null;
}

interface ItemVoteRecordRow {
  vote_id: string;
  position: string;
  name: string | null;
  politician_id: string | null;
}

interface ItemSpeakerRow {
  name: string;
  politician_id: string | null;
  role: string | null;
  first_spoke_seconds: string | number;
  segment_count: string | number;
}

const ITEM_COLS = `id, meeting_id, position, item_number, title_raw, kind,
  legislation_ref, summary_plain, decision_plain, stage,
  public_comment, public_comment_note, status, outcome,
  segment_start_seconds, segment_end_seconds, continued_from_item_id, source_url`;

// Same columns, ai.-qualified for the detail JOIN (trim strips ITEM_COLS'
// newlines/indentation).
const ITEM_COLS_QUALIFIED = ITEM_COLS.split(',')
  .map((c) => `ai.${c.trim()}`)
  .join(', ');

function mapAgendaItem(row: AgendaItemRow): AgendaItem {
  return {
    id: row.id,
    meetingId: row.meeting_id,
    position: Number(row.position),
    itemNumber: row.item_number,
    titleRaw: row.title_raw,
    kind: row.kind,
    legislationRef: row.legislation_ref ?? null,
    summaryPlain: row.summary_plain ?? null,
    decisionPlain: row.decision_plain ?? null,
    stage: row.stage ?? null,
    publicComment: row.public_comment,
    publicCommentNote: row.public_comment_note ?? null,
    status: row.status,
    outcome: row.outcome ?? null,
    segmentStartSeconds:
      row.segment_start_seconds == null ? null : Number(row.segment_start_seconds),
    segmentEndSeconds:
      row.segment_end_seconds == null ? null : Number(row.segment_end_seconds),
    continuedFromItemId: row.continued_from_item_id ?? null,
    sourceUrl: row.source_url,
  };
}

export async function getAgendaItemsByMeetingId(
  meetingId: string,
  opts?: MeetingViewerOptions
): Promise<AgendaItem[]> {
  // Gate on the parent meeting's status so a draft meeting's agenda items stay
  // invisible to public callers.
  const meetingGate = opts?.includeAllStatuses
    ? ''
    : `AND ${publicMeetingExistsClause('$1')}`;
  const { rows } = await pool.query<AgendaItemRow>(
    `SELECT ${ITEM_COLS}
     FROM meetings.agenda_items
     WHERE meeting_id = $1 ${meetingGate}
     ORDER BY position ASC`,
    [meetingId]
  );
  return rows.map(mapAgendaItem);
}

// Roll-call votes attached to the item, each with its per-member records.
// Member names resolve through the meeting's speaker rows (display_name, or
// the local_people roster name); politician_id links members to /people pages.
async function getVotesByAgendaItemId(itemId: string): Promise<AgendaItemVote[]> {
  const { rows: voteRows } = await pool.query<ItemVoteRow>(
    `SELECT id, resolution, description, result, vote_type, timestamp
     FROM meetings.votes
     WHERE agenda_item_id = $1
     ORDER BY timestamp ASC NULLS LAST, created_at ASC`,
    [itemId]
  );
  if (voteRows.length === 0) return [];

  const { rows: recordRows } = await pool.query<ItemVoteRecordRow>(
    `SELECT vr.vote_id, vr.position,
            COALESCE(sp.display_name, lp.name) AS name,
            sp.politician_id
     FROM meetings.vote_records vr
     JOIN meetings.speakers sp ON sp.id = vr.speaker_id
     LEFT JOIN meetings.local_people lp ON lp.slug = sp.local_slug
     WHERE vr.vote_id = ANY($1)
     ORDER BY name ASC NULLS LAST`,
    [voteRows.map((v) => v.id)]
  );

  const recordsByVoteId = new Map<string, AgendaItemVoteRecord[]>();
  for (const r of recordRows) {
    const mapped: AgendaItemVoteRecord = {
      position: r.position,
      name: r.name ?? null,
      politicianId: r.politician_id ?? null,
    };
    const existing = recordsByVoteId.get(r.vote_id);
    if (existing) existing.push(mapped);
    else recordsByVoteId.set(r.vote_id, [mapped]);
  }

  return voteRows.map((v) => ({
    id: v.id,
    resolution: v.resolution ?? null,
    description: v.description ?? null,
    result: v.result,
    voteType: v.vote_type ?? null,
    timestamp: v.timestamp == null ? null : Number(v.timestamp),
    records: recordsByVoteId.get(v.id) ?? [],
  }));
}

// Named people who spoke within [startSeconds, endSeconds) of the item's
// meeting, first-appearance order. Unnamed diarized speakers (no display_name
// and no roster name) are omitted — labels like SPEAKER_07 are pipeline
// internals, not a citizen-facing record.
async function getSpeakersInSpan(
  meetingId: string,
  startSeconds: number,
  endSeconds: number
): Promise<AgendaItemSpeaker[]> {
  const { rows } = await pool.query<ItemSpeakerRow>(
    `SELECT COALESCE(sp.display_name, lp.name) AS name,
            sp.politician_id,
            lp.role AS role,
            MIN(s.start_time) AS first_spoke_seconds,
            COUNT(*) AS segment_count
     FROM meetings.segments s
     JOIN meetings.speakers sp ON sp.id = s.speaker_id
     LEFT JOIN meetings.local_people lp ON lp.slug = sp.local_slug
     WHERE s.meeting_id = $1
       AND s.start_time >= $2
       AND s.start_time < $3
       AND COALESCE(sp.display_name, lp.name) IS NOT NULL
     GROUP BY sp.id, sp.display_name, lp.name, lp.role, sp.politician_id
     ORDER BY first_spoke_seconds ASC`,
    [meetingId, startSeconds, endSeconds]
  );
  return rows.map((r) => ({
    name: r.name,
    politicianId: r.politician_id ?? null,
    role: r.role ?? null,
    firstSpokeSeconds: Number(r.first_spoke_seconds),
    segmentCount: Number(r.segment_count),
  }));
}

export async function getAgendaItemById(
  id: string,
  opts?: MeetingViewerOptions
): Promise<AgendaItemDetail | null> {
  // Public callers only see items whose meeting is allowlisted; a draft meeting's
  // agenda-item permalink resolves to null (404).
  const statusGate = opts?.includeAllStatuses
    ? ''
    : `AND ${publicMeetingStatusClause('m.status')}`;
  const { rows } = await pool.query<AgendaItemDetailRow>(
    `SELECT ${ITEM_COLS_QUALIFIED},
            m.id AS m_id, m.title AS m_title, m.date::text AS m_date,
            m.city AS m_city, m.status AS m_status, m.starts_at AS m_starts_at,
            m.timezone AS m_timezone,
            cf.id AS cf_id, cf.item_number AS cf_item_number,
            cfm.date::text AS cf_meeting_date
     FROM meetings.agenda_items ai
     JOIN meetings.meetings m ON m.id = ai.meeting_id
     LEFT JOIN meetings.agenda_items cf ON cf.id = ai.continued_from_item_id
     LEFT JOIN meetings.meetings cfm ON cfm.id = cf.meeting_id
     WHERE ai.id = $1 ${statusGate}`,
    [id]
  );
  if (rows.length === 0) return null;
  const row = rows[0];
  const item = mapAgendaItem(row);

  // Sequential on purpose: the speaker query needs the item's segment bounds,
  // and a permalink page tolerates two short extra round-trips.
  const votes = await getVotesByAgendaItemId(id);
  const speakers =
    item.segmentStartSeconds != null && item.segmentEndSeconds != null
      ? await getSpeakersInSpan(
          item.meetingId,
          item.segmentStartSeconds,
          item.segmentEndSeconds
        )
      : [];

  return {
    ...item,
    meeting: {
      id: row.m_id,
      title: row.m_title ?? null,
      date: row.m_date,
      city: row.m_city ?? null,
      status: row.m_status,
      // pg returns timestamptz as a JS Date — normalize to an ISO-8601 UTC
      // string at the mapper boundary (same as meetingsService.mapMeeting).
      startsAt: toIsoStringOrNull(row.m_starts_at),
      // IANA zone (e.g. 'America/Indiana/Indianapolis'): timestamptz loses the
      // original offset, so the UI needs this to render starts_at meeting-local.
      timezone: row.m_timezone ?? null,
    },
    votes,
    speakers,
    continuedFrom:
      row.cf_id != null && row.cf_item_number != null && row.cf_meeting_date != null
        ? {
            id: row.cf_id,
            itemNumber: row.cf_item_number,
            meetingDate: row.cf_meeting_date,
          }
        : null,
  };
}
