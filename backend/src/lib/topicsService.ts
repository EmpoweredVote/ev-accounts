/**
 * topicsService — cross-meeting topic aggregation.
 *
 * meetings.meeting_topics holds AI-predicted Compass-issue tags on meeting
 * sections. Topic titles resolve from the live inform.compass_topics row by
 * topic_key. pool.query only; explicit mappers; Number() on counts/times.
 */

import { pool } from './db.js';
import type { EventKind } from './eventKinds.js';
import {
  publicMeetingStatusClause,
  publicMeetingExistsClause,
} from './meetingVisibility.js';
import { topicAskedByPublishedSeason } from './seasonService.js';

export interface TopicListEntry {
  topicKey: string;
  title: string | null;
  itemCount: number;
  meetingCount: number;
}

export interface TopicItem {
  meetingId: string;
  title: string | null;
  eventKind: EventKind;
  eventOrgs: string[];
  sourceTitle: string | null;
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
            ctc.short_title AS title,
            COUNT(*) AS item_count,
            COUNT(DISTINCT mt.meeting_id) AS meeting_count
     FROM meetings.meeting_topics mt
     LEFT JOIN inform.compass_topics ct
       ON ct.topic_key = mt.topic_key AND ${topicAskedByPublishedSeason('ct.id')}
     -- TEXT ONLY (ADR 0004). ct keeps the match and the retired-topic gate; ctc
     -- carries the current revision's wording. CA_0012 froze ct's own text columns.
     -- The gate is "a published season asks this topic", not is_live — 17 Season 2
     -- topics are is_live = false; see topicAskedByPublishedSeason.
     LEFT JOIN inform.compass_topics_current ctc ON ctc.id = ct.id
     -- Public status gate (ev-cto decision 0017): count tags only on publicly
     -- visible meetings, so a draft meeting's topic tags never inflate a count.
     WHERE ${publicMeetingExistsClause('mt.meeting_id')}
     GROUP BY mt.topic_key, ctc.short_title
     ORDER BY item_count DESC, mt.topic_key`
  );

  // Uncategorized = substantive summary sections with no topic tag. Counting
  // them precisely means comparing each meeting's summary JSONB sections against
  // its meeting_topics rows, which isn't worth a cross-JSONB query here; the web
  // omits the row when this is 0. A precise count is deferred to the curation phase.
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
    // TEXT ONLY (ADR 0004): ct gates on a published season asking the topic
    // (not is_live — see topicAskedByPublishedSeason), ctc supplies the current
    // revision's wording. CA_0012 froze ct.short_title, so reading it here would
    // pin this page to the 2026-08-21 text.
    `SELECT ctc.short_title AS title
       FROM inform.compass_topics ct
       JOIN inform.compass_topics_current ctc ON ctc.id = ct.id
      WHERE ct.topic_key = $1 AND ${topicAskedByPublishedSeason('ct.id')} LIMIT 1`,
    [topicKey]
  );

  const { rows } = await pool.query<{
    meeting_id: string; title: string | null; event_kind: EventKind;
    event_orgs: string[] | null; source_title: string | null;
    city: string; meeting_type: string; date: string;
    playback_kind: string | null; section_index: string; section_title: string | null;
    section_type: string | null; start_time: string | null; status: string;
  }>(
    `SELECT mt.meeting_id, m.title, m.event_kind,
            m.processing_metadata->>'source_title' AS source_title,
            (SELECT COALESCE(array_agg(eo.org_name ORDER BY eo.created_at), ARRAY[]::text[])
             FROM meetings.event_orgs eo WHERE eo.meeting_id = m.slug) AS event_orgs,
            m.city, m.meeting_type, m.date::text AS date,
            m.playback_kind, mt.section_index, mt.section_title, mt.section_type,
            mt.start_time, mt.status
     FROM meetings.meeting_topics mt
     JOIN meetings.meetings m ON m.id = mt.meeting_id
     -- Public status gate (ev-cto decision 0017): a draft meeting's tagged
     -- sections must not appear in a topic's public item list.
     WHERE mt.topic_key = $1 AND ${publicMeetingStatusClause('m.status')}
     ORDER BY m.date DESC, mt.meeting_id, mt.section_index`,
    [topicKey]
  );

  if (titleRows.length === 0 && rows.length === 0) return null;

  return {
    topicKey,
    title: titleRows[0]?.title ?? null,
    items: rows.map((r) => ({
      meetingId: r.meeting_id,
      title: r.title,
      eventKind: r.event_kind,
      eventOrgs: r.event_orgs ?? [],
      sourceTitle: r.source_title,
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
