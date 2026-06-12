/**
 * peopleService — people who speak in published meetings.
 *
 * Roster source: DISTINCT politician_slug from meetings.speakers, enriched
 * from essentials.politicians via the shared slug. Speakers without a
 * politician_slug (unidentified) are not listed.
 *
 * Same architecture rules as meetingsService:
 *   - meetings.* and essentials.* are NOT PostgREST-exposed; pool.query() only
 *   - explicit field whitelists, never spread rows
 *   - Number() on bigint/numeric: meeting_count, segment_index, start/end_time
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface Person {
  slug: string;
  politicianId: string | null;
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
  slug: string;
  politician_id: string | null;
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
    slug: row.slug,
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

// Shared SELECT for roster and profile. GROUP BY (slug, p.id) is valid:
// p.id is essentials.politicians' PK, so p.* columns are functionally
// dependent; the lateral office columns must be grouped explicitly.
const PERSON_SELECT = `
  SELECT
    sp.politician_slug                                                       AS slug,
    p.id                                                                     AS politician_id,
    COALESCE(p.full_name, MAX(sp.display_name), sp.politician_slug)          AS name,
    COALESCE(NULLIF(p.photo_custom_url, ''), NULLIF(p.photo_origin_url, '')) AS headshot_url,
    p.party                                                                  AS party,
    p.bio_text                                                               AS bio_text,
    off.office_title,
    off.district,
    off.jurisdiction,
    COUNT(DISTINCT sp.meeting_id)                                            AS meeting_count,
    ARRAY_AGG(DISTINCT m.city)                                               AS cities,
    MAX(m.date)::text                                                        AS last_spoke_date
  FROM meetings.speakers sp
  JOIN meetings.meetings m ON m.id = sp.meeting_id
  LEFT JOIN essentials.politicians p ON p.slug = sp.politician_slug
  LEFT JOIN LATERAL (
    SELECT o.title AS office_title, d.label AS district, g.name AS jurisdiction
    FROM essentials.offices o
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE o.politician_id = p.id AND o.is_vacant = false
    ORDER BY o.id
    LIMIT 1
  ) off ON true
`;

const PERSON_GROUP_BY = `
  GROUP BY sp.politician_slug, p.id, off.office_title, off.district, off.jurisdiction
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
     WHERE sp.politician_slug IS NOT NULL
     ${cityClause}
     ${PERSON_GROUP_BY}
     ORDER BY name`,
    params
  );

  return rows.map(mapPerson);
}

export async function getPersonBySlug(slug: string): Promise<PersonDetail | null> {
  const { rows } = await pool.query<PersonRow>(
    `${PERSON_SELECT}
     WHERE sp.politician_slug = $1
     ${PERSON_GROUP_BY}`,
    [slug]
  );

  return rows.length > 0 ? mapPersonDetail(rows[0]) : null;
}

export async function getAppearancesBySlug(slug: string): Promise<Appearance[]> {
  const { rows } = await pool.query<AppearanceRow>(
    `SELECT s.meeting_id, s.segment_index, s.start_time, s.end_time, s.text,
            m.city, m.meeting_type, m.date::text AS date, m.playback_kind
     FROM meetings.segments s
     JOIN meetings.meetings m ON m.id = s.meeting_id
     WHERE s.politician_slug = $1
     ORDER BY m.date DESC, s.meeting_id, s.segment_index`,
    [slug]
  );

  const byMeeting = new Map<string, Appearance>();
  for (const row of rows) {
    let appearance = byMeeting.get(row.meeting_id);
    if (!appearance) {
      appearance = {
        meetingId: row.meeting_id,
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
