// Read-only service for meetings.agenda_items — the citizen-facing agenda-item
// atoms published by the on-the-record pipeline (which is the sole writer).
//
// Same rules as meetingsService.ts:
// - meetings schema is NOT PostgREST-exposed: pool.query() only, schema-qualified.
// - DTOs are explicit whitelists (never spread rows); camelCase out.
// - Number() every numeric — pg returns them as strings.
import { pool } from './db.js';

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
  m_starts_at: string | null;
  m_timezone: string | null;
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
  meetingId: string
): Promise<AgendaItem[]> {
  const { rows } = await pool.query<AgendaItemRow>(
    `SELECT ${ITEM_COLS}
     FROM meetings.agenda_items
     WHERE meeting_id = $1
     ORDER BY position ASC`,
    [meetingId]
  );
  return rows.map(mapAgendaItem);
}

export async function getAgendaItemById(
  id: string
): Promise<AgendaItemDetail | null> {
  const { rows } = await pool.query<AgendaItemDetailRow>(
    `SELECT ${ITEM_COLS_QUALIFIED},
            m.id AS m_id, m.title AS m_title, m.date::text AS m_date,
            m.city AS m_city, m.status AS m_status, m.starts_at AS m_starts_at,
            m.timezone AS m_timezone
     FROM meetings.agenda_items ai
     JOIN meetings.meetings m ON m.id = ai.meeting_id
     WHERE ai.id = $1`,
    [id]
  );
  if (rows.length === 0) return null;
  const row = rows[0];
  return {
    ...mapAgendaItem(row),
    meeting: {
      id: row.m_id,
      title: row.m_title ?? null,
      date: row.m_date,
      city: row.m_city ?? null,
      status: row.m_status,
      // timestamptz passthrough — same convention as meetingsService's
      // created_at/updated_at: pg hands back what JSON.stringify serializes
      // to an ISO instant on the route.
      startsAt: row.m_starts_at ?? null,
      // IANA zone (e.g. 'America/Indiana/Indianapolis'): timestamptz loses the
      // original offset, so the UI needs this to render starts_at meeting-local.
      timezone: row.m_timezone ?? null,
    },
  };
}
