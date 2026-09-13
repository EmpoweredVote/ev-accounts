import { pool } from './db.js';

export interface SpeakerLinkCounts {
  named: number;
  linked: number;
}

/**
 * For each meeting id, count speaker rows that carry a display_name (named) and
 * a politician_id (linked). Used by the admin review queue to show, e.g.,
 * "48 speakers · 33 named · 32 linked" without loading every speaker row.
 */
export async function getSpeakerCountsByMeeting(
  meetingIds: string[]
): Promise<Record<string, SpeakerLinkCounts>> {
  if (meetingIds.length === 0) return {};
  const { rows } = await pool.query<{ meeting_id: string; named: string; linked: string }>(
    `SELECT meeting_id,
            COUNT(*) FILTER (WHERE display_name IS NOT NULL) AS named,
            COUNT(*) FILTER (WHERE politician_id IS NOT NULL) AS linked
       FROM meetings.speakers
      WHERE meeting_id = ANY($1::uuid[])
      GROUP BY meeting_id`,
    [meetingIds]
  );
  const out: Record<string, SpeakerLinkCounts> = {};
  for (const r of rows) {
    out[r.meeting_id] = { named: Number(r.named), linked: Number(r.linked) };
  }
  return out;
}
