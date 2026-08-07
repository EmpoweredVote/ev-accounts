import crypto from 'node:crypto';
import { pool } from './db.js';
import { env } from './env.js';
import { getBoundaryBatch, getDistrictCountyGeoIds, getStateCountyGeoIds, getCountyNames } from './informBoundaryService.js';
import type { JurisdictionGeoIds } from './essentialsService.js';
import { USPS_TO_FIPS } from './usStateCodes.js';

/**
 * Read & Rank — blind candidate-match election tool.
 *
 * Hard rules enforced here:
 *  - Blind payloads NEVER expose quote_text, politician_id, source, or photo.
 *    Only deidentified_text + an opaque candidateToken leave the server.
 *  - The API NEVER falls back to raw quote_text. A quote with no
 *    deidentified_text is simply not served (the blind premise must hold).
 *  - Identities are de-masked ONLY by the reveal (computeRaceMatch).
 */

const ESSENTIALS_BASE = 'https://essentials.empowered.vote';
const TOKEN_SECRET = process.env.READRANK_TOKEN_SECRET || env.SUPABASE_SERVICE_ROLE_KEY;

/** Opaque, deterministic per-candidate token, scoped to a race. Not reversible client-side. */
function candidateToken(raceId: string, politicianId: string): string {
  return crypto
    .createHmac('sha256', TOKEN_SECRET)
    .update(`${raceId}:${politicianId}`)
    .digest('hex')
    .slice(0, 16);
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface BoundaryRef {
  layer: string;
  geoid: string;
  bbox?: [number, number, number, number];
  geojson?: { type: 'Polygon' | 'MultiPolygon'; coordinates: unknown };
}

export interface RaceSummary {
  raceId: string;
  office: string;
  seat: string | null;
  electionName: string;
  electionDate: string | null;
  state: string | null;
  jurisdictionLevel: string | null;
  candidateCount: number;
  topicCount: number;
  isLocal: boolean;
  quoteCount: number;
  rankableTopicCount: number;
  tier: 'federal' | 'state' | 'local';
  scope: 'statewide' | 'district' | 'county' | 'citywide';
  boundaryRef: BoundaryRef | null;
  frameRef: BoundaryRef | null;
  /** GEOIDs of the counties this race belongs to (set, since state-leg districts cross
   *  county lines). [] for statewide / federal / unframed races. */
  countyGeoIds: string[];
}

export interface BlindQuote {
  id: string;
  text: string;
  candidateToken: string;
  topicKey: string;
}

export interface RacePayload {
  raceId: string;
  positionName: string;
  topics: Array<{ topicKey: string; title: string; question: string; quotes: BlindQuote[] }>;
}

export interface VerdictInput {
  quote_id: string;
  supported: boolean;
  rank: number | null;
}

export interface BallotEntry {
  /** 1-based rank, or null when the user judged this candidate but never agreed
   *  with any of their quotes. Ranking is something a candidate has, not the
   *  price of appearing on the reveal. */
  rank: number | null;
  candidateId: string;
  party: string;
  name: string;
  office: string;
  photo: string;
  essentialsUrl: string;
  evidence: { agreementCount: number; firstPlaceCount: number; topicsWithAgreement: number };
  perTopic: Array<{
    topicKey: string;
    title: string;
    userTopWinner: boolean;
    quotes: Array<{ quoteId: string; text: string; supported: boolean; rank: number | null; sourceName?: string; sourceUrl?: string }>;
  }>;
  score?: number;
}

export interface RevealResult {
  raceId: string;
  positionName: string;
  ballot: BallotEntry[];
}

// ---------------------------------------------------------------------------
// 1. Playable races
// ---------------------------------------------------------------------------

type Tier = 'federal' | 'state' | 'local';
type Scope = 'statewide' | 'district' | 'county' | 'citywide';

const MTFCC_SCOPE: Record<string, Scope> = {
  G4000: 'statewide', // whole state
  G4020: 'county',
  G4040: 'district',  // county subdivision / township
  G4110: 'citywide',  // incorporated place
  G5200: 'district',  // congressional
  G5210: 'district',  // state senate
  G5220: 'district',  // state house / assembly / ward
  G5400: 'district',  // elementary school district
  G5410: 'district',  // secondary school district
  G5420: 'district',  // unified school district
};

/** Sub-state layers whose overlapping counties (ST_Intersects, via getDistrictCountyGeoIds)
 *  drive the read-rank county relevance tier (countyGeoIds): state-leg districts, school
 *  districts, townships, AND congressional districts (G5200). These districts all frame
 *  visually against the state outline (the frame geometry is lazy-loaded client-side). */
const COUNTY_OVERLAP_LAYERS = new Set(['G5200', 'G5210', 'G5220', 'G5400', 'G5410', 'G5420', 'G4040']);

/** USPS → full state name, for stripping a redundant state prefix off statewide-exec offices. */
const USPS_TO_NAME: Record<string, string> = {
  AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas', CA: 'California',
  CO: 'Colorado', CT: 'Connecticut', DE: 'Delaware', FL: 'Florida', GA: 'Georgia',
  HI: 'Hawaii', ID: 'Idaho', IL: 'Illinois', IN: 'Indiana', IA: 'Iowa',
  KS: 'Kansas', KY: 'Kentucky', LA: 'Louisiana', ME: 'Maine', MD: 'Maryland',
  MA: 'Massachusetts', MI: 'Michigan', MN: 'Minnesota', MS: 'Mississippi', MO: 'Missouri',
  MT: 'Montana', NE: 'Nebraska', NV: 'Nevada', NH: 'New Hampshire', NJ: 'New Jersey',
  NM: 'New Mexico', NY: 'New York', NC: 'North Carolina', ND: 'North Dakota', OH: 'Ohio',
  OK: 'Oklahoma', OR: 'Oregon', PA: 'Pennsylvania', RI: 'Rhode Island', SC: 'South Carolina',
  SD: 'South Dakota', TN: 'Tennessee', TX: 'Texas', UT: 'Utah', VT: 'Vermont',
  VA: 'Virginia', WA: 'Washington', WV: 'West Virginia', WI: 'Wisconsin', WY: 'Wyoming',
  DC: 'District of Columbia',
};

/** Chamber-neutral office title for each legislative district_type (ADR-0001). */
const LEGISLATIVE_OFFICE: Record<string, string> = {
  STATE_LOWER: 'State Representative',
  STATE_UPPER: 'State Senator',
  NATIONAL_LOWER: 'US Representative',
  NATIONAL_UPPER: 'US Senator',
};

/** Maps a race's district_type to the JurisdictionGeoIds field carrying the user's
 *  resolved GEOID for that same district type. Statewide/federal-statewide types
 *  (NATIONAL_UPPER, NATIONAL_EXEC, STATE_EXEC, etc.) intentionally have no entry —
 *  those races have no district geoid to geo-match and rely on the roster fallback. */
const DISTRICT_TYPE_TO_JURISDICTION_FIELD: Record<string, keyof JurisdictionGeoIds> = {
  NATIONAL_LOWER: 'congressional',
  STATE_UPPER: 'state_senate',
  STATE_LOWER: 'state_house',
  COUNTY: 'county',
  JUDICIAL: 'county',
  SCHOOL: 'school_district',
};

/** Resolve the user's jurisdiction GEOID for a race's district_type, or null when
 *  the jurisdiction is unresolved, the district_type doesn't map to a jurisdiction
 *  field, or the user's jurisdiction has no value for that field. */
function userGeoIdForType(
  jurisdiction: JurisdictionGeoIds | undefined,
  districtType: string | null,
): string | null {
  if (!jurisdiction || !districtType) return null;
  const field = DISTRICT_TYPE_TO_JURISDICTION_FIELD[districtType];
  if (!field) return null;
  return jurisdiction[field];
}

const WORD_TO_NUM: Record<string, number> = {
  first: 1, second: 2, third: 3, fourth: 4, fifth: 5, sixth: 6, seventh: 7, eighth: 8,
  ninth: 9, tenth: 10, eleventh: 11, twelfth: 12, thirteenth: 13, fourteenth: 14,
  fifteenth: 15, sixteenth: 16, seventeenth: 17, eighteenth: 18, nineteenth: 19, twentieth: 20,
};

/** Normalize a district/seat phrase to its canonical seat token, or null.
 *  "State House District 21" -> "District 21"; "Ninth District" -> "District 9";
 *  "District 060" -> "District 60"; "At Large" -> "At-Large"; "" / null -> null. */
export function normalizeSeat(raw: string | null): string | null {
  if (!raw) return null;
  let s = raw.trim();
  if (!s) return null;
  s = s.replace(
    /\b(first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|eleventh|twelfth|thirteenth|fourteenth|fifteenth|sixteenth|seventeenth|eighteenth|nineteenth|twentieth)\s+district\b/i,
    (_m, w: string) => `District ${WORD_TO_NUM[w.toLowerCase()]}`,
  );
  s = s.replace(/\bdistrict\s+0*(\d+)/i, 'District $1');
  s = s.replace(/\bat[\s-]?large\b/i, 'At-Large');
  const m = s.match(/\b(District\s+\d+|At-Large|Ward\s+\d+|Division\s+\d+|Seat\s+\d+)\b/i);
  return m ? m[1].replace(/\s+/g, ' ') : s;
}

/** Derive a clean office + seat for a race tile (ADR-0001). */
export function deriveOfficeSeat(input: {
  positionName: string;
  districtLabel: string | null;
  districtType: string | null;
  state: string | null;
}): { office: string; seat: string | null } {
  const dt = (input.districtType ?? '').toUpperCase();

  if (LEGISLATIVE_OFFICE[dt]) {
    // normalizeSeat extracts the canonical token; confirm it's a real seat type
    // before using it, otherwise fall back to deriving the seat from positionName.
    const fromLabel = normalizeSeat(input.districtLabel);
    const seat = fromLabel && /^(District|At-Large|Ward|Division|Seat)/i.test(fromLabel)
      ? fromLabel
      : normalizeSeat(input.positionName);
    return { office: LEGISLATIVE_OFFICE[dt], seat };
  }

  // Executive / local / unknown: keep the place-qualified name, split any trailing
  // comma district, and drop a redundant statewide state prefix.
  let office = (input.positionName ?? '').trim()
    .replace(/United States Representative/gi, 'US Representative')
    .replace(/United States Senator/gi, 'US Senator');

  let seat: string | null = null;
  const sepRe = /\s*(?:,|[-–—])\s+/g;
  let sepMatch: RegExpExecArray | null;
  while ((sepMatch = sepRe.exec(office)) !== null) {
    const norm = normalizeSeat(office.slice(sepMatch.index + sepMatch[0].length));
    if (norm && /^(District|At-Large|Ward|Division|Seat)/i.test(norm)) {
      seat = norm;
      office = office.slice(0, sepMatch.index);
      break;
    }
  }

  if (input.state) {
    const esc = (v: string) => v.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const full = USPS_TO_NAME[input.state.toUpperCase()];
    const alt = full ? `|${esc(full)}` : '';
    office = office.replace(new RegExp(`^(${esc(input.state)}${alt})\\s+`, 'i'), '');
  }

  return { office: office.trim(), seat: seat ?? normalizeSeat(input.districtLabel) };
}

/** Tier from jurisdiction_level; scope prefers the mtfcc geometry class, else position name. */
export function deriveTierScope(input: {
  jurisdiction_level: string | null;
  position_name: string;
  mtfcc: string | null;
}): { tier: Tier; scope: Scope } {
  const jl = (input.jurisdiction_level ?? '').toLowerCase();
  const tier: Tier = /fed|congress|national/.test(jl)
    ? 'federal'
    : jl === 'state'
      ? 'state'
      : 'local';

  let scope: Scope | undefined = input.mtfcc ? MTFCC_SCOPE[input.mtfcc] : undefined;
  if (input.mtfcc && input.mtfcc.startsWith('X')) scope = 'district'; // custom council/ward layers
  if (!scope) {
    const n = input.position_name.toLowerCase();
    if (/county commission|board of supervisors|county council|sheriff|\bcounty\b/.test(n)) scope = 'county';
    else if (/mayor|city of /.test(n)) scope = 'citywide';
    else if (/council|ward|\bdistrict\b|house|assembly|representative|senate district/.test(n)) scope = 'district';
    else scope = tier === 'local' ? 'citywide' : 'statewide';
  }
  return { tier, scope };
}

export async function getPlayableRaces(
  politicianIds?: string[],
  jurisdiction?: JurisdictionGeoIds,
  embedRaceIds?: string[],
  embedLocal?: boolean,
): Promise<{ races: RaceSummary[]; counties: Record<string, string> }> {
  const { rows } = await pool.query<{
    race_id: string; position_name: string; district_label: string | null; district_type: string | null;
    election_id: string; election_name: string;
    election_date: Date | null; jurisdiction_level: string | null; state: string | null;
    boundary_layer: string | null; boundary_geoid: string | null;
    frame_layer: string | null; frame_geoid: string | null;
    candidate_count: string; topic_count: string; quote_count: string; rankable_topic_count: string;
    politician_ids: string[];
  }>(`
    SELECT r.id AS race_id,
           r.position_name,
           d.label AS district_label,
           d.district_type,
           e.id AS election_id, e.name AS election_name, e.election_date,
           e.jurisdiction_level, e.state,
           d.mtfcc AS boundary_layer,
           COALESCE(d.geo_id, d.tiger_geoid) AS boundary_geoid,
           frame.frame_layer, frame.frame_geoid,
           COUNT(DISTINCT rc.politician_id)   AS candidate_count,
           COUNT(DISTINCT lower(q.topic_key)) AS topic_count,
           COUNT(q.id)                        AS quote_count,
           (
             SELECT COUNT(*) FROM (
               SELECT lower(q2.topic_key) AS tk
               FROM essentials.race_candidates rc2
               JOIN essentials.quotes q2
                 ON q2.politician_id = rc2.politician_id
                AND q2.deidentified_text IS NOT NULL AND q2.readrank_selected = true
               JOIN inform.compass_topics ct2
                 ON ct2.topic_key = lower(q2.topic_key) AND ct2.is_live = true
               WHERE rc2.race_id = r.id
                 AND essentials.is_live_candidate(rc2.candidate_status, rc2.result)
               GROUP BY lower(q2.topic_key)
               HAVING COUNT(DISTINCT rc2.politician_id) >= 2
             ) rankable
           )                                  AS rankable_topic_count,
           array_agg(DISTINCT rc.politician_id) AS politician_ids
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND essentials.is_live_candidate(rc.candidate_status, rc.result)
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    LEFT JOIN essentials.offices o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.geofence_boundaries cb
      ON (d.mtfcc = 'G4110' OR d.mtfcc LIKE 'X%')
     AND cb.mtfcc = d.mtfcc AND cb.geo_id = COALESCE(d.geo_id, d.tiger_geoid)
    LEFT JOIN LATERAL (
      SELECT fp.mtfcc AS frame_layer, fp.geo_id AS frame_geoid
      FROM essentials.geofence_boundaries fp
      WHERE fp.mtfcc = CASE
              WHEN d.mtfcc = 'G4110' THEN 'G4020'                              -- city  → county
              WHEN d.mtfcc LIKE 'X%' AND d.district_type = 'COUNTY' THEN 'G4020' -- county council → county
              WHEN d.mtfcc LIKE 'X%' THEN 'G4110'                             -- city ward → city
            END
        AND ST_Contains(fp.geometry, ST_PointOnSurface(cb.geometry))
      ORDER BY ST_Area(fp.geometry) ASC
      LIMIT 1
    ) frame ON (d.mtfcc = 'G4110' OR d.mtfcc LIKE 'X%')
    GROUP BY r.id, r.position_name, e.id, e.name, e.election_date, e.jurisdiction_level, e.state,
             d.mtfcc, d.label, d.district_type, COALESCE(d.geo_id, d.tiger_geoid), frame.frame_layer, frame.frame_geoid
    HAVING COUNT(DISTINCT rc.politician_id) >= 2
    ORDER BY e.election_date ASC NULLS LAST
  `);

  // Boundary geometry is NOT embedded here — the races list returns boundaryRef/frameRef
  // as {layer, geoid} only, and the client lazy-loads each rendered card's geometry via
  // /api/inform/boundary. This keeps the list payload small and off the query's hot path.

  // Sub-state districts (state-leg / school / township / congressional) still need the
  // set of counties they overlap, which drives the county relevance tier (countyGeoIds).
  const overlapRefs: Array<{ layer: string; geoid: string }> = [];
  for (const r of rows) {
    if (r.boundary_layer && COUNTY_OVERLAP_LAYERS.has(r.boundary_layer) && r.boundary_geoid) {
      overlapRefs.push({ layer: r.boundary_layer, geoid: r.boundary_geoid });
    }
  }

  // Statewide races cover the whole state → every county, so they surface in
  // each county view (not just the state-outline browse level).
  const statewideStates = [...new Set(
    rows
      .filter((r) => deriveTierScope({
        jurisdiction_level: r.jurisdiction_level, position_name: r.position_name, mtfcc: r.boundary_layer,
      }).scope === 'statewide' && r.state)
      .map((r) => r.state as string),
  )];

  // Both lookups derive their inputs solely from `rows` and are independent, so run
  // them concurrently. Each degrades to an empty default so a failure in one can't
  // affect the other (or the whole list) — the county tier just falls back to [].
  const [districtCountyMap, stateCountyMap] = await Promise.all([
    getDistrictCountyGeoIds(overlapRefs).catch(() => new Map<string, string[]>()),
    getStateCountyGeoIds(statewideStates).catch(() => new Map<string, string[]>()),
  ]);

  const localSet = new Set(politicianIds ?? []);
  const races = rows.map((r) => {
    const { office, seat } = deriveOfficeSeat({
      positionName: r.position_name,
      districtLabel: r.district_label,
      districtType: r.district_type,
      state: r.state,
    });
    const { tier, scope } = deriveTierScope({
      jurisdiction_level: r.jurisdiction_level,
      position_name: r.position_name,
      mtfcc: r.boundary_layer,
    });
    const fips = r.state ? USPS_TO_FIPS[r.state] : undefined;
    const stateRef = fips ? { layer: 'G4000', geoid: fips } : null;
    const childLayer = r.boundary_layer ?? '';

    // Child boundary: the office's specific district, or the whole-state outline
    // for statewide offices. Federal offices are overridden below to the state.
    let boundaryRef: BoundaryRef | null = r.boundary_layer && r.boundary_geoid
      ? { layer: r.boundary_layer, geoid: r.boundary_geoid }
      : (scope === 'statewide' ? stateRef : null);

    // Frame (parent to nest the child inside). Geometry is lazy-loaded client-side,
    // so a frame must be an individually addressable boundary (real layer + geoid) —
    // the synthetic county-union (G4020U) isn't, so sub-state districts frame against
    // the state outline instead. (Congressional districts already did.)
    let frameRef: BoundaryRef | null;
    if (tier === 'federal') {
      boundaryRef = stateRef;                          // model B: federal child = home state
      frameRef = { layer: 'G4000', geoid: 'US' };
    } else if (scope === 'statewide') {
      frameRef = null;                                 // Governor: state alone
    } else if (childLayer === 'G4110' || childLayer.startsWith('X')) {
      frameRef = r.frame_layer && r.frame_geoid        // city→county / county-council→county / ward→city
        ? { layer: r.frame_layer, geoid: r.frame_geoid }
        : null;
    } else {
      frameRef = stateRef;                             // county / state-leg / school / township → state outline
    }

    // County set for the relevance tier. county/city/ward-council come from the
    // single G4020 boundary or frame; state-leg, school, township, and congressional
    // districts use the overlapping-county set; everything else → [].
    let countyGeoIds: string[] = [];
    if (scope === 'county' && childLayer === 'G4020' && r.boundary_geoid) {
      countyGeoIds = [r.boundary_geoid];
    } else if (
      (childLayer === 'G4110' || childLayer.startsWith('X')) &&
      r.frame_layer === 'G4020' && r.frame_geoid
    ) {
      countyGeoIds = [r.frame_geoid];
    } else if (COUNTY_OVERLAP_LAYERS.has(childLayer)) {
      countyGeoIds = (r.boundary_geoid ? districtCountyMap.get(`${childLayer}:${r.boundary_geoid}`) : undefined) ?? [];
    }

    // Statewide races cover the whole state → every county, so they surface in each county view.
    if (scope === 'statewide' && r.state) {
      countyGeoIds = stateCountyMap.get(r.state) ?? [];
    }

    // isLocal = geographic district match (primary) OR candidate-roster match (fallback).
    // Geographic: the user's resolved jurisdiction GEOID for this race's district_type
    // equals the race's own boundary_geoid. Statewide/federal-statewide races have no
    // district geoid to match and rely entirely on the roster fallback.
    const userGeoId = userGeoIdForType(jurisdiction, r.district_type);
    const geoMatch = userGeoId != null && userGeoId === r.boundary_geoid;
    const rosterMatch = localSet.size > 0 && (r.politician_ids ?? []).some((id) => localSet.has(id));

    return {
      raceId: r.race_id,
      office,
      seat,
      electionName: r.election_name,
      electionDate: r.election_date ? new Date(r.election_date).toISOString().slice(0, 10) : null,
      state: r.state,
      jurisdictionLevel: r.jurisdiction_level,
      candidateCount: Number(r.candidate_count),
      topicCount: Number(r.topic_count),
      quoteCount: Number(r.quote_count),
      rankableTopicCount: Number(r.rankable_topic_count),
      tier,
      scope,
      boundaryRef,
      frameRef,
      countyGeoIds,
      isLocal: geoMatch || rosterMatch,
    };
  });

  // Embed boundary geometry for specific races the caller will render immediately
  // (e.g. the frontend's featured landing card, or the located ballot's own "Your
  // races" via embedLocal) so their motif paints with no lazy-load flash. Everything
  // else stays geometry-free and lazy-loads client-side.
  const embedSet = new Set(embedRaceIds ?? []);
  if (embedLocal) for (const r of races) if (r.isLocal) embedSet.add(r.raceId);
  if (embedSet.size) {
    const refs = races
      .filter((r) => embedSet.has(r.raceId))
      .flatMap((r) => [r.boundaryRef, r.frameRef])
      .filter((ref): ref is NonNullable<typeof ref> => ref != null);
    if (refs.length) {
      const geo = await getBoundaryBatch(refs).catch(() => new Map());
      for (const r of races) {
        if (!embedSet.has(r.raceId)) continue;
        const cg = r.boundaryRef ? geo.get(`${r.boundaryRef.layer}:${r.boundaryRef.geoid}`) : undefined;
        if (cg) r.boundaryRef = { ...r.boundaryRef!, bbox: cg.bbox, geojson: cg.geojson };
        const fg = r.frameRef ? geo.get(`${r.frameRef.layer}:${r.frameRef.geoid}`) : undefined;
        if (fg) r.frameRef = { ...r.frameRef!, bbox: fg.bbox, geojson: fg.geojson };
      }
    }
  }

  const allCountyGeoIds = [...new Set(races.flatMap((r) => r.countyGeoIds))];
  let counties: Record<string, string> = {};
  try {
    counties = await getCountyNames(allCountyGeoIds);
  } catch {
    counties = {};
  }
  return { races, counties };
}

// ---------------------------------------------------------------------------
// 2. Blind, topic-grouped quotes for a race
// ---------------------------------------------------------------------------

export async function getRaceBlindQuotes(raceId: string): Promise<RacePayload | null> {
  const { rows } = await pool.query<{
    quote_id: string; deidentified_text: string; topic_key: string; politician_id: string;
    topic_title: string; topic_question: string; position_name: string;
  }>(`
    SELECT q.id AS quote_id, q.deidentified_text, lower(q.topic_key) AS topic_key,
           q.politician_id,
           ct.short_title AS topic_title,
           COALESCE(rtq.question_text, ct.question_text) AS topic_question,
           r.position_name
    FROM essentials.races r
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND essentials.is_live_candidate(rc.candidate_status, rc.result)
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    LEFT JOIN essentials.readrank_race_topic_questions rtq
      ON rtq.race_id = r.id AND rtq.topic_key = lower(q.topic_key)
    WHERE r.id = $1
    ORDER BY ct.short_title
  `, [raceId]);

  if (rows.length === 0) return null;

  const positionName = rows[0].position_name;
  const topicOrder: string[] = [];
  const byTopic = new Map<string, RacePayload['topics'][number]>();

  for (const row of rows) {
    let topic = byTopic.get(row.topic_key);
    if (!topic) {
      topic = { topicKey: row.topic_key, title: row.topic_title ?? '', question: row.topic_question ?? '', quotes: [] };
      byTopic.set(row.topic_key, topic);
      topicOrder.push(row.topic_key);
    }
    topic.quotes.push({
      id: row.quote_id,
      text: row.deidentified_text, // NEVER quote_text
      candidateToken: candidateToken(raceId, row.politician_id),
      topicKey: row.topic_key,
    });
  }

  return { raceId, positionName, topics: topicOrder.map((k) => byTopic.get(k)!) };
}

// ---------------------------------------------------------------------------
// 3. Verdict + rank candidate match (the reveal) — de-masks identities
// ---------------------------------------------------------------------------

const rankBonus = (rank: number | null) => (rank === 1 ? 3 : rank === 2 ? 2 : rank === 3 ? 1 : 0.5);

export async function computeRaceMatch(
  raceId: string,
  verdicts: VerdictInput[],
  exposeScore = false
): Promise<RevealResult | null> {
  const quoteIds = verdicts.map((v) => v.quote_id);
  if (quoteIds.length === 0) return { raceId, positionName: '', ballot: [] };

  const { rows } = await pool.query<{
    quote_id: string; politician_id: string; topic_key: string; deidentified_text: string;
    source_name: string | null; source_url: string | null; full_name: string;
    photo: string | null; office_title: string | null; topic_title: string; position_name: string;
  }>(`
    SELECT q.id AS quote_id, q.politician_id, lower(q.topic_key) AS topic_key,
           q.deidentified_text, q.source_name, q.source_url,
           p.full_name, p.photo_origin_url AS photo,
           o.title AS office_title, ct.short_title AS topic_title, r.position_name
    FROM essentials.races r
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id IS NOT NULL
    JOIN essentials.quotes q ON q.politician_id = rc.politician_id AND q.deidentified_text IS NOT NULL AND q.readrank_selected = true
    JOIN essentials.politicians p ON p.id = q.politician_id
    LEFT JOIN LATERAL (
      -- ADR 0002 phase 5: offices.politician_id is gone; occupancy resolves via current_office_holders.
      SELECT o.title
      FROM essentials.current_office_holders coh
      JOIN essentials.offices o ON o.id = coh.office_id
      WHERE coh.politician_id = p.id
      ORDER BY o.id DESC
      LIMIT 1
    ) o ON true
    JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    WHERE r.id = $1 AND q.id = ANY($2::uuid[])
  `, [raceId, quoteIds]);

  if (rows.length === 0) return { raceId, positionName: '', ballot: [] };

  const positionName = rows[0].position_name;
  const verdictByQuote = new Map(verdicts.map((v) => [v.quote_id, v]));

  interface Agg {
    politicianId: string; name: string; photo: string; office: string;
    agreementCount: number; firstPlaceCount: number; score: number;
    topicsWithAgreement: Set<string>;
    perTopic: Map<string, BallotEntry['perTopic'][number]>;
  }
  const aggs = new Map<string, Agg>();
  const topicBest: Record<string, { pid: string; rank: number }> = {};

  for (const row of rows) {
    const v = verdictByQuote.get(row.quote_id);
    if (!v) continue;
    let a = aggs.get(row.politician_id);
    if (!a) {
      a = {
        politicianId: row.politician_id, name: row.full_name, photo: row.photo ?? '',
        office: row.office_title || 'Candidate',
        agreementCount: 0, firstPlaceCount: 0, score: 0,
        topicsWithAgreement: new Set(), perTopic: new Map(),
      };
      aggs.set(row.politician_id, a);
    }
    let pt = a.perTopic.get(row.topic_key);
    if (!pt) {
      pt = { topicKey: row.topic_key, title: row.topic_title ?? '', userTopWinner: false, quotes: [] };
      a.perTopic.set(row.topic_key, pt);
    }
    pt.quotes.push({
      quoteId: row.quote_id, text: row.deidentified_text, supported: v.supported, rank: v.rank,
      sourceName: row.source_name ?? undefined, sourceUrl: row.source_url ?? undefined,
    });
    if (v.supported) {
      a.agreementCount += 1;
      a.score += rankBonus(v.rank);
      a.topicsWithAgreement.add(row.topic_key);
      if (v.rank === 1) a.firstPlaceCount += 1;
      if (v.rank != null) {
        const best = topicBest[row.topic_key];
        if (!best || v.rank < best.rank) topicBest[row.topic_key] = { pid: row.politician_id, rank: v.rank };
      }
    }
  }

  // Every candidate the user judged appears, whether or not they ranked them.
  // Agreements still decide rank and order; a candidate you only disagreed with
  // comes back unranked rather than vanishing from the reveal entirely.
  const all = [...aggs.values()];
  const ranked = all
    .filter((a) => a.agreementCount > 0)
    .sort((x, y) => y.score - x.score || y.agreementCount - x.agreementCount || y.firstPlaceCount - x.firstPlaceCount || x.name.localeCompare(y.name));
  // Sorted by name rather than left in query order: the SELECT above has no
  // ORDER BY, so insertion order isn't stable across identical requests, and an
  // unstable tail would reshuffle the reveal cascade on a retry.
  const unranked = all
    .filter((a) => a.agreementCount === 0)
    .sort((x, y) => x.name.localeCompare(y.name));

  const toEntry = (a: Agg, rank: number | null): BallotEntry => {
    for (const pt of a.perTopic.values()) pt.userTopWinner = topicBest[pt.topicKey]?.pid === a.politicianId;
    const entry: BallotEntry = {
      rank,
      candidateId: a.politicianId,
      party: '', // antipartisan — party intentionally not transmitted
      name: a.name,
      office: a.office,
      photo: a.photo,
      essentialsUrl: `${ESSENTIALS_BASE}/politician/${a.politicianId}`,
      evidence: {
        agreementCount: a.agreementCount,
        firstPlaceCount: a.firstPlaceCount,
        topicsWithAgreement: a.topicsWithAgreement.size,
      },
      perTopic: [...a.perTopic.values()],
    };
    if (exposeScore) entry.score = a.score;
    return entry;
  };

  const ballot: BallotEntry[] = [
    ...ranked.map((a, i) => toEntry(a, i + 1)),
    ...unranked.map((a) => toEntry(a, null)),
  ];

  return { raceId, positionName, ballot };
}
