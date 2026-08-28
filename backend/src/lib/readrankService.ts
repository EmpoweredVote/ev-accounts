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

/**
 * Readable heading for a topic that has no live Compass row to name it.
 *
 * A Read & Rank question does not require a matching inform.compass_topics row
 * (a salient local question — Israel aid in a Michigan Senate race — may have no
 * Compass topic at all), so ct.short_title arrives NULL. This derives a heading
 * from the topic key instead: 'israel-aid' -> 'Israel Aid'.
 *
 * Deliberately in TypeScript rather than a SQL COALESCE: pool.query is mocked in
 * the tests, so SQL-side behaviour is untestable in-process while this is not.
 * A real short_title always wins — callers only reach for this on NULL.
 */
export function topicTitleFromKey(topicKey: string | null | undefined): string {
  if (!topicKey) return '';
  return topicKey
    .split(/[-_\s]+/)
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(' ');
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
  /** Distinct questions with a served quote. @deprecated misnamed — reads
   *  `questionCount`. Kept because the game client reads it. */
  topicCount: number;
  /** Distinct questions this race serves — one evaluation card each. */
  questionCount: number;
  isLocal: boolean;
  quoteCount: number;
  /** @deprecated misnamed — reads `rankableQuestionCount`. Kept because the game
   *  client reads `rankableTopicCount ?? topicCount` to size race progress. */
  rankableTopicCount: number;
  /** Questions with >= 2 live candidates answering — a real head-to-head. */
  rankableQuestionCount: number;
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
  /** The card this quote belongs to — matches RaceTopicCard.key. Present because
   *  the client resolves a verdict's card FROM THE QUOTE; with two cards sharing a
   *  topicKey, topicKey alone routes the verdict to the wrong one. Names the
   *  question, never the speaker, so it carries no attribution. */
  cardKey: string;
}

/**
 * One evaluation card: a single ranking question and the blind answers to it.
 *
 * The QUESTION is the unit of comparison (migration 1377), NOT the topic — one
 * topic legitimately hosts several questions (LA Mayor's economic-development
 * topic hosts a film/TV question and a downtown question). So `topicKey` is
 * deliberately NOT unique across cards, and a consumer keying a map or a
 * progress record by it silently drops a card. Group by `key`.
 */
export interface RaceTopicCard {
  /** Stable card identity: the question id, or `topic:<topic_key>` for a
   *  compass-era quote that predates question_id. Unique within a payload. */
  key: string;
  /** The real Compass topic this question sits under. NOT unique across cards. */
  topicKey: string;
  /** NULL for compass-era quotes, which are still grouped by topic. */
  questionId: string | null;
  title: string;
  question: string;
  quotes: BlindQuote[];
}

export interface RacePayload {
  raceId: string;
  positionName: string;
  /** Cards, one per question. Named `topics` for wire compatibility with the
   *  game client; the elements have been per-question since this fix. */
  topics: RaceTopicCard[];
}

/**
 * Card identity for every question-keyed grouping in the player path.
 *
 * Mirrors the SQL-side key `COALESCE(question_id::text, 'topic:' || lower(topic_key))`
 * used by getPlayableRaces' counts. Keep the two in step — if they diverge, the
 * race list advertises a card count the payload does not deliver.
 */
export function questionCardKey(questionId: string | null | undefined, topicKey: string | null | undefined): string {
  return questionId ?? `topic:${(topicKey ?? '').toLowerCase()}`;
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
  evidence: {
    agreementCount: number;
    firstPlaceCount: number;
    /** Distinct QUESTIONS with at least one agreement. Named for the wire. */
    topicsWithAgreement: number;
  };
  /** One section per question, NOT per topic — two questions in one topic are two
   *  sections sharing a topicKey. Named `perTopic` for wire compatibility. */
  perTopic: Array<{
    /** Matches RaceTopicCard.key from the evaluation payload. Group by this. */
    key: string;
    topicKey: string;
    questionId: string | null;
    title: string;
    /** The ranking question. Two sections of one topic share `title`, so this is
     *  what tells them apart in the reveal. */
    question: string;
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
    candidate_count: string; question_count: string; quote_count: string; rankable_question_count: string;
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
           -- The QUESTION is the unit of comparison (1377), so a topic hosting two
           -- questions contributes two cards. The 'topic:' fallback keeps compass-era
           -- quotes (question_id IS NULL) grouped by topic. Must stay in step with
           -- questionCardKey() in TypeScript.
           COUNT(DISTINCT COALESCE(q.question_id::text, 'topic:' || lower(q.topic_key))) AS question_count,
           COUNT(q.id)                        AS quote_count,
           (
             SELECT COUNT(*) FROM (
               SELECT COALESCE(q2.question_id::text, 'topic:' || lower(q2.topic_key)) AS qk
               FROM essentials.race_candidates rc2
               JOIN essentials.quotes q2
                 ON q2.politician_id = rc2.politician_id
                AND q2.deidentified_text IS NOT NULL AND q2.readrank_selected = true
               LEFT JOIN inform.compass_topics ct2
                 ON ct2.topic_key = lower(q2.topic_key)
               WHERE rc2.race_id = r.id
                 AND essentials.is_live_candidate(rc2.candidate_status, rc2.result)
                 -- A topic with no Compass row is allowed through; one that HAS a
                 -- Compass row must have it live. Keeping is_live in the LEFT JOIN's
                 -- ON clause would invert the kill switch: a retired topic would fail
                 -- to match, yield ct2 IS NULL, and survive as an "unknown" topic.
                 AND (ct2.topic_key IS NULL OR ct2.is_live = true)
               -- Per QUESTION, not per topic. Grouping by lower(topic_key) counted a
               -- split topic as one rankable unit whenever its two questions had one
               -- answering candidate each — a pairing no single question satisfies.
               GROUP BY COALESCE(q2.question_id::text, 'topic:' || lower(q2.topic_key))
               HAVING COUNT(DISTINCT rc2.politician_id) >= 2
             ) rankable
           )                                  AS rankable_question_count,
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
    LEFT JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key)
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
    -- Topic spine, in WHERE not ON: a quote whose topic has no Compass row is kept,
    -- but a quote on a RETIRED (is_live = false) Compass topic is still dropped.
    -- In the ON clause this predicate would silently disable that kill switch.
    WHERE (ct.topic_key IS NULL OR ct.is_live = true)
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
      questionCount: Number(r.question_count),
      rankableQuestionCount: Number(r.rankable_question_count),
      // Deprecated aliases, same numbers. The game client reads these; dropping them
      // would zero every race card's topic count and progress denominator.
      topicCount: Number(r.question_count),
      quoteCount: Number(r.quote_count),
      rankableTopicCount: Number(r.rankable_question_count),
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
  let counties: Record<string, string>;
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
    // NULL for compass-era quotes, which predate migration 1377's question_id.
    question_id: string | null;
    // topic_title / topic_question are NULL for a topic with no Compass row.
    topic_title: string | null; topic_question: string | null; position_name: string;
  }>(`
    SELECT q.id AS quote_id, q.deidentified_text, lower(q.topic_key) AS topic_key,
           q.politician_id, q.question_id,
           ctc.short_title AS topic_title,
           -- Question resolves: the quote's own question -> per-race topic override
           -- -> Compass. A non-Compass topic has only the first source, so this
           -- COALESCE (not the title) has to stay in SQL: three tables, three joins.
           COALESCE(rq.question_text, rtq.question_text, ctc.question_text) AS topic_question,
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
    LEFT JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key)
    -- TEXT ONLY (ADR 0004). ct stays the matcher and the is_live kill switch;
    -- ctc supplies title and question_text from the CURRENT revision. Splitting
    -- them is what makes publishing a revision reach this surface: CA_0012 froze
    -- compass_topics' own text columns, so reading ct.short_title here would show
    -- the 2026-08-21 wording forever. Cannot fan out — one current revision per
    -- topic, by the compass_topic_revisions_one_current partial unique index.
    LEFT JOIN inform.compass_topics_current ctc ON ctc.id = ct.id
    LEFT JOIN essentials.readrank_questions rq
      ON rq.id = q.question_id
    LEFT JOIN essentials.readrank_race_topic_questions rtq
      ON rtq.race_id = r.id AND rtq.topic_key = lower(q.topic_key)
    WHERE r.id = $1
      -- See getPlayableRaces: the is_live kill switch lives here, not in the ON
      -- clause, so a retired Compass topic still disappears from the evaluation.
      -- 🔴 It reads ct, NOT ctc. Promotion state is not in the content view, and
      -- moving this onto ctc would silently delete the kill switch.
      AND (ct.topic_key IS NULL OR ct.is_live = true)
    -- Non-Compass topics have no short_title; order them by key so a race with
    -- several of them still comes back in a stable order rather than by chance.
    -- The trailing two keys order CARDS WITHIN a topic: ordering by topic title
    -- alone left the row order of a multi-question topic unspecified, which is
    -- how the merged card used to pick its question text by chance.
    ORDER BY COALESCE(ctc.short_title, lower(q.topic_key)),
             COALESCE(rq.question_text, rtq.question_text, ctc.question_text),
             q.question_id NULLS FIRST
  `, [raceId]);

  if (rows.length === 0) return null;

  const positionName = rows[0].position_name;
  const cardOrder: string[] = [];
  const byCard = new Map<string, RaceTopicCard>();

  for (const row of rows) {
    // Keyed by QUESTION, not topic: two questions in one topic are two cards, each
    // carrying its own question text. Keying by topic_key here merged them and
    // printed one nondeterministically-chosen question over both sets of answers.
    const key = questionCardKey(row.question_id, row.topic_key);
    let card = byCard.get(key);
    if (!card) {
      card = {
        key,
        topicKey: row.topic_key,
        questionId: row.question_id,
        title: row.topic_title ?? topicTitleFromKey(row.topic_key),
        question: row.topic_question ?? '',
        quotes: [],
      };
      byCard.set(key, card);
      cardOrder.push(key);
    }
    card.quotes.push({
      id: row.quote_id,
      text: row.deidentified_text, // NEVER quote_text
      candidateToken: candidateToken(raceId, row.politician_id),
      topicKey: row.topic_key,
      cardKey: key,
    });
  }

  return { raceId, positionName, topics: cardOrder.map((k) => byCard.get(k)!) };
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
    quote_id: string; politician_id: string; topic_key: string; question_id: string | null;
    deidentified_text: string;
    source_name: string | null; source_url: string | null; full_name: string;
    photo: string | null; office_title: string | null; topic_title: string | null;
    topic_question: string | null; position_name: string;
  }>(`
    SELECT q.id AS quote_id, q.politician_id, lower(q.topic_key) AS topic_key,
           q.question_id,
           q.deidentified_text, q.source_name, q.source_url,
           p.full_name, p.photo_origin_url AS photo,
           o.title AS office_title, ctc.short_title AS topic_title,
           -- Same three-source resolution as getRaceBlindQuotes. The reveal needs it
           -- because two sections of one topic share the topic short_title and are
           -- otherwise indistinguishable to the reader.
           COALESCE(rq.question_text, rtq.question_text, ctc.question_text) AS topic_question,
           r.position_name
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
    LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key)
    -- TEXT ONLY — see getRaceBlindQuotes. ct matches and gates; ctc supplies the
    -- current revision's wording. The reveal and the blind payload must resolve
    -- text the same way, or a quote's topic renames itself between the two.
    LEFT JOIN inform.compass_topics_current ctc ON ctc.id = ct.id
    LEFT JOIN essentials.readrank_questions rq
      ON rq.id = q.question_id
    LEFT JOIN essentials.readrank_race_topic_questions rtq
      ON rtq.race_id = r.id AND rtq.topic_key = lower(q.topic_key)
    WHERE r.id = $1 AND q.id = ANY($2::uuid[])
      -- Kill switch in WHERE, not ON — see getPlayableRaces. The reveal must not
      -- resurrect a retired topic the evaluation payload already refused to show.
      -- 🔴 ct, not ctc — the content view carries no is_live.
      AND (ct.topic_key IS NULL OR ct.is_live = true)
  `, [raceId, quoteIds]);

  if (rows.length === 0) return { raceId, positionName: '', ballot: [] };

  const positionName = rows[0].position_name;
  const verdictByQuote = new Map(verdicts.map((v) => [v.quote_id, v]));

  interface Agg {
    politicianId: string; name: string; photo: string; office: string;
    agreementCount: number; firstPlaceCount: number; score: number;
    /** Card keys, not topic keys — see questionCardKey. */
    topicsWithAgreement: Set<string>;
    perTopic: Map<string, BallotEntry['perTopic'][number]>;
  }
  const aggs = new Map<string, Agg>();
  /** Best rank per CARD. Keyed by topic, one rank-1 was shared across every
   *  question in the topic, so only the first candidate seen could ever win. */
  const cardBest: Record<string, { pid: string; rank: number }> = {};

  for (const row of rows) {
    const v = verdictByQuote.get(row.quote_id);
    if (!v) continue;
    const cardKey = questionCardKey(row.question_id, row.topic_key);
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
    let pt = a.perTopic.get(cardKey);
    if (!pt) {
      pt = {
        key: cardKey,
        topicKey: row.topic_key,
        questionId: row.question_id,
        title: row.topic_title ?? topicTitleFromKey(row.topic_key),
        question: row.topic_question ?? '',
        userTopWinner: false,
        quotes: [],
      };
      a.perTopic.set(cardKey, pt);
    }
    pt.quotes.push({
      quoteId: row.quote_id, text: row.deidentified_text, supported: v.supported, rank: v.rank,
      sourceName: row.source_name ?? undefined, sourceUrl: row.source_url ?? undefined,
    });
    if (v.supported) {
      a.agreementCount += 1;
      a.score += rankBonus(v.rank);
      a.topicsWithAgreement.add(cardKey);
      if (v.rank === 1) a.firstPlaceCount += 1;
      if (v.rank != null) {
        const best = cardBest[cardKey];
        if (!best || v.rank < best.rank) cardBest[cardKey] = { pid: row.politician_id, rank: v.rank };
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
    for (const pt of a.perTopic.values()) pt.userTopWinner = cardBest[pt.key]?.pid === a.politicianId;
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
