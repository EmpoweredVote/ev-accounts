/**
 * peopleService — people who speak in published meetings.
 *
 * Roster source: DISTINCT politician_id from meetings.speakers, enriched
 * from essentials.politicians via the shared id. Speakers without a
 * politician_id (unidentified) are not listed.
 *
 * Same architecture rules as meetingsService:
 *   - meetings.* and essentials.* are NOT PostgREST-exposed; pool.query() only
 *   - explicit field whitelists, never spread rows
 *   - Number() on bigint/numeric: meeting_count, segment_index, start/end_time
 */

import { pool } from './db.js';
import type { EventKind } from './eventKinds.js';
import { publicMeetingStatusClause } from './meetingVisibility.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface Person {
  politicianId: string;
  name: string;
  headshotUrl: string | null;
  party: string | null;
  officeTitle: string | null;
  district: string | null;
  jurisdiction: string | null;
  meetingCount: number;
  cities: string[];
  lastSpokeDate: string | null;
}

export interface PersonDetail extends Person {
  bioText: string | null;
}

export interface AppearanceSegment {
  segmentIndex: number;
  startTime: number;
  endTime: number;
  text: string;
}

export interface Appearance {
  meetingId: string;
  title: string | null;
  eventKind: EventKind;
  eventOrgs: string[];
  sourceTitle: string | null;
  city: string;
  meetingType: string;
  date: string;
  playbackKind: string | null;
  segments: AppearanceSegment[];
}

// ---------------------------------------------------------------------------
// Row types
// ---------------------------------------------------------------------------

interface PersonRow {
  politician_id: string;
  name: string;
  headshot_url: string | null;
  party: string | null;
  bio_text: string | null;
  office_title: string | null;
  district: string | null;
  jurisdiction: string | null;
  meeting_count: string;
  cities: string[];
  last_spoke_date: string | null;
}

interface AppearanceRow {
  meeting_id: string;
  segment_index: string;
  start_time: string;
  end_time: string;
  text: string;
  title: string | null;
  event_kind: EventKind;
  event_orgs: string[] | null;
  source_title: string | null;
  city: string;
  meeting_type: string;
  date: string;
  playback_kind: string | null;
}

// ---------------------------------------------------------------------------
// Mappers (explicit camelCase — NEVER spread rows)
// ---------------------------------------------------------------------------

function mapPerson(row: PersonRow): Person {
  return {
    politicianId: row.politician_id,
    name: row.name,
    headshotUrl: row.headshot_url,
    party: row.party,
    officeTitle: row.office_title,
    district: row.district,
    jurisdiction: row.jurisdiction,
    meetingCount: Number(row.meeting_count),
    cities: row.cities,
    lastSpokeDate: row.last_spoke_date,
  };
}

function mapPersonDetail(row: PersonRow): PersonDetail {
  return { ...mapPerson(row), bioText: row.bio_text };
}

// ---------------------------------------------------------------------------
// Queries
// ---------------------------------------------------------------------------

// Shared SELECT for roster and profile. Keyed on essentials.politicians.id
// (politician_slug is NULL for ~99.4% of rows, incl. candidates). GROUP BY p.id
// is valid: it is the PK, so p.* columns are functionally dependent; the lateral
// office columns must be grouped explicitly.
const PERSON_SELECT = `
  SELECT
    p.id                                                                     AS politician_id,
    COALESCE(p.full_name, MAX(sp.display_name))                              AS name,
    COALESCE(NULLIF(p.photo_custom_url, ''), pi.url)                         AS headshot_url,
    p.party                                                                  AS party,
    p.bio_text                                                               AS bio_text,
    off.office_title,
    off.district,
    off.jurisdiction,
    COUNT(DISTINCT sp.meeting_id)                                            AS meeting_count,
    ARRAY_AGG(DISTINCT m.city)                                               AS cities,
    MAX(m.date)::text                                                        AS last_spoke_date
  FROM meetings.speakers sp
  -- Public status gate (ev-cto decision 0017): the roster and its aggregates
  -- (meeting_count, last_spoke_date, cities) count only publicly-visible
  -- meetings, so a draft floor meeting's speakers never inflate a live profile.
  JOIN meetings.meetings m ON m.id = sp.meeting_id AND ${publicMeetingStatusClause('m.status')}
  JOIN essentials.politicians p ON p.id = sp.politician_id
  LEFT JOIN LATERAL (
    SELECT o.title AS office_title, d.label AS district, g.name AS jurisdiction
    FROM essentials.offices o
    -- ADR 0002 phase 3: resolve via essentials.office_current_holder so a future-dated term
    -- takes effect on its own date.
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE och.politician_id = p.id AND o.is_vacant = false
    ORDER BY o.id
    LIMIT 1
  ) off ON true
  -- Actual portrait image from Supabase Storage. photo_origin_url is a
  -- source/citation page (Wikipedia, Ballotpedia, voter guide), NOT an image,
  -- so headshot_url uses the custom override then this default image only.
  LEFT JOIN LATERAL (
    SELECT url FROM essentials.politician_images
    WHERE politician_id = p.id AND type = 'default'
    LIMIT 1
  ) pi ON true
`;

const PERSON_GROUP_BY = `
  GROUP BY p.id, off.office_title, off.district, off.jurisdiction, pi.url
`;

export async function getPeople(filters?: { city?: string }): Promise<Person[]> {
  const params: string[] = [];
  let cityClause = '';
  if (filters?.city !== undefined) {
    params.push(filters.city);
    cityClause = `AND m.city = $${params.length}`;
  }

  const { rows } = await pool.query<PersonRow>(
    `${PERSON_SELECT}
     WHERE sp.politician_id IS NOT NULL
     ${cityClause}
     ${PERSON_GROUP_BY}
     ORDER BY name`,
    params
  );

  return rows.map(mapPerson);
}

export async function getPersonById(politicianId: string): Promise<PersonDetail | null> {
  const { rows } = await pool.query<PersonRow>(
    `${PERSON_SELECT}
     WHERE sp.politician_id = $1
     ${PERSON_GROUP_BY}`,
    [politicianId]
  );

  return rows.length > 0 ? mapPersonDetail(rows[0]) : null;
}

export async function getAppearancesById(politicianId: string): Promise<Appearance[]> {
  const { rows } = await pool.query<AppearanceRow>(
    `SELECT s.meeting_id, s.segment_index, s.start_time, s.end_time, s.text,
            m.city, m.meeting_type, m.date::text AS date, m.playback_kind,
            m.title, m.event_kind,
            m.processing_metadata->>'source_title' AS source_title,
            (SELECT COALESCE(array_agg(eo.org_name ORDER BY eo.created_at), ARRAY[]::text[])
             FROM meetings.event_orgs eo WHERE eo.meeting_id = m.slug) AS event_orgs
     FROM meetings.segments s
     JOIN meetings.speakers sp ON sp.id = s.speaker_id
     JOIN meetings.meetings m ON m.id = s.meeting_id
     -- Public status gate (ev-cto decision 0017): a draft floor meeting's
     -- transcript segments must not surface as appearances on a live people page.
     WHERE sp.politician_id = $1 AND ${publicMeetingStatusClause('m.status')}
     ORDER BY m.date DESC, s.meeting_id, s.segment_index`,
    [politicianId]
  );

  const byMeeting = new Map<string, Appearance>();
  for (const row of rows) {
    let appearance = byMeeting.get(row.meeting_id);
    if (!appearance) {
      appearance = {
        meetingId: row.meeting_id,
        title: row.title,
        eventKind: row.event_kind,
        eventOrgs: row.event_orgs ?? [],
        sourceTitle: row.source_title,
        city: row.city,
        meetingType: row.meeting_type,
        date: row.date,
        playbackKind: row.playback_kind,
        segments: [],
      };
      byMeeting.set(row.meeting_id, appearance);
    }
    appearance.segments.push({
      segmentIndex: Number(row.segment_index),
      startTime: Number(row.start_time),
      endTime: Number(row.end_time),
      text: row.text,
    });
  }
  return [...byMeeting.values()];
}
