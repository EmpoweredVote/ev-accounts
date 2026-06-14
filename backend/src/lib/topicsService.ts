/**
 * topicsService — cross-meeting topic aggregation.
 *
 * meetings.meeting_topics holds AI-predicted Compass-issue tags on meeting
 * sections. Topic titles resolve from the live inform.compass_topics row by
 * topic_key. pool.query only; explicit mappers; Number() on counts/times.
 */

import { pool } from './db.js';

export interface TopicListEntry {
  topicKey: string;
  title: string | null;
  itemCount: number;
  meetingCount: number;
}

export interface TopicItem {
  meetingId: string;
  city: string;
  meetingType: string;
  date: string;
  playbackKind: string | null;
  sectionIndex: number;
  sectionTitle: string | null;
  sectionType: string | null;
  startTime: number | null;
  status: string;
}

export interface TopicDetail {
  topicKey: string;
  title: string | null;
  items: TopicItem[];
}

export async function getTopics(): Promise<{ topics: TopicListEntry[]; uncategorizedCount: number }> {
  const { rows } = await pool.query<{
    topic_key: string; title: string | null; item_count: string; meeting_count: string;
  }>(
    `SELECT mt.topic_key,
            ct.short_title AS title,
            COUNT(*) AS item_count,
            COUNT(DISTINCT mt.meeting_id) AS meeting_count
     FROM meetings.meeting_topics mt
     LEFT JOIN inform.compass_topics ct
       ON ct.topic_key = mt.topic_key AND ct.is_live = true
     GROUP BY mt.topic_key, ct.short_title
     ORDER BY item_count DESC, mt.topic_key`
  );

  // Uncategorized = substantive sections (any meeting) with zero tags.
  // Counted as meetings that have a summary but fewer tagged sections than
  // substantive sections is non-trivial from SQL alone; expose a simple proxy:
  // sections present in summaries with no row in meeting_topics is computed
  // client-rarely, so we return 0 here and let the web omit the row when 0.
  // (A precise count is deferred to the curation phase.)
  const uncategorizedCount = 0;

  return {
    topics: rows.map((r) => ({
      topicKey: r.topic_key,
      title: r.title,
      itemCount: Number(r.item_count),
      meetingCount: Number(r.meeting_count),
    })),
    uncategorizedCount,
  };
}

export async function getTopicByKey(topicKey: string): Promise<TopicDetail | null> {
  const { rows: titleRows } = await pool.query<{ title: string | null }>(
    `SELECT short_title AS title FROM inform.compass_topics
     WHERE topic_key = $1 AND is_live = true LIMIT 1`,
    [topicKey]
  );

  const { rows } = await pool.query<{
    meeting_id: string; city: string; meeting_type: string; date: string;
    playback_kind: string | null; section_index: string; section_title: string | null;
    section_type: string | null; start_time: string | null; status: string;
  }>(
    `SELECT mt.meeting_id, m.city, m.meeting_type, m.date::text AS date,
            m.playback_kind, mt.section_index, mt.section_title, mt.section_type,
            mt.start_time, mt.status
     FROM meetings.meeting_topics mt
     JOIN meetings.meetings m ON m.id = mt.meeting_id
     WHERE mt.topic_key = $1
     ORDER BY m.date DESC, mt.meeting_id, mt.section_index`,
    [topicKey]
  );

  if (titleRows.length === 0 && rows.length === 0) return null;

  return {
    topicKey,
    title: titleRows[0]?.title ?? null,
    items: rows.map((r) => ({
      meetingId: r.meeting_id,
      city: r.city,
      meetingType: r.meeting_type,
      date: r.date,
      playbackKind: r.playback_kind,
      sectionIndex: Number(r.section_index),
      sectionTitle: r.section_title,
      sectionType: r.section_type,
      startTime: r.start_time != null ? Number(r.start_time) : null,
      status: r.status,
    })),
  };
}
