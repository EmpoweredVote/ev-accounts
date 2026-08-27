/**
 * coverageService.ts — data coverage tracker.
 *
 * Source of truth is a per-state YAML file at data/coverage/<state>.yaml
 * (version-controlled). This service:
 *   • parses that YAML (manual columns + jurisdiction rules), and
 *   • recomputes the "auto" columns (populated / headshots / stances /
 *     last_researched) LIVE from the database, so the admin page is always
 *     fresh regardless of when coverage-sync.ts last ran.
 *
 * The same computeLocationStats() helper is reused by scripts/coverage-sync.ts
 * to snapshot those auto columns back into the YAML.
 *
 * Politician → jurisdiction join (see scripts/load-ut-city-rosters.ts):
 *   essentials.politicians → offices.district_id → districts.ocd_id
 * matched as a subtree: ocd_id = $1 OR ocd_id LIKE $1 || '/%'.
 */

import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';
import { pool } from './db.js';
import { HAS_RENDERABLE_PHOTO_SQL } from './photoCoverage.js';

const FRESHNESS_DAYS = 180;

export type Tristate = 'none' | 'partial' | 'full';
export type CoverageLevel = 'federal' | 'state' | 'county' | 'local' | 'school';
export type CoverageStatus = 'active' | 'in_progress' | 'deferred';
/**
 * How a row's politicians are matched against districts.ocd_id:
 *  - subtree: ocd_id = X or under X/  (a specific jurisdiction; counties/cities/schools)
 *  - exact:   ocd_id = X exactly      (statewide offices at the bare state OCD)
 *  - kind:    all districts of ocd_kind in the state (chamber aggregates: cd/sldu/sldl)
 */
export type CoverageMatch = 'subtree' | 'exact' | 'kind' | 'title';

export interface SkipTopicRule {
  topic_key: string;
  reason: string;
  source?: string;
  applies_to: CoverageLevel[];
}

export interface CoverageRules {
  skip_topics: SkipTopicRule[];
  notes: string[];
}

/** A location row as authored in the YAML (auto fields may be stale on disk). */
export interface CoverageLocationFile {
  ocd_id: string;
  ocd_kind?: string | null; // for match: 'kind' — the OCD segment to aggregate (cd | sldu | sldl)
  match?: CoverageMatch; // default 'subtree'
  office_title_like?: string | null; // for match: 'title' — ILIKE pattern on offices.title (e.g. 'U.S. Senate%')
  exclude_title_like?: string | null; // for match: 'exact' — drop offices whose title ILIKE this (e.g. de-dupe senators out of the statewide bucket)
  name: string;
  level: CoverageLevel;
  status: CoverageStatus;
  expected_seats: number | null; // full-roster target; null = unknown (can't confirm "complete")
  geofenced: boolean;
  donors: Tristate;
  candidates: Tristate;
  treasury: Tristate;
  populated: boolean;
  headshots: Tristate;
  stances: { researched: number; total: number };
  last_researched: string | null;
}

export interface CoverageUniverseConfig {
  state_fips?: string;
  tribes?: string[];
}

export interface CoverageFile {
  state: string;
  state_name: string;
  synced_at: string | null;
  universe?: CoverageUniverseConfig;
  rules: CoverageRules;
  locations: CoverageLocationFile[];
}

/** Progress of one jurisdiction category toward covering the whole state. */
export type UniverseLevel = 'county' | 'local' | 'school' | 'tribe';
export interface UniverseCategory {
  level: UniverseLevel;
  label: string;
  total: number; // full universe of jurisdictions in this category (TIGER geofence count)
  complete: number; // full roster loaded (actual ≥ expected_seats)
  started: number; // ≥1 active politician (includes complete)
  remaining: string[]; // jurisdiction names with no active politician yet
  reliable: boolean; // false when geofence universe looks incomplete (started > total)
}

/** Live-computed coverage stats for one jurisdiction subtree. */
export interface LocationStats {
  populated: boolean;
  headshots: Tristate;
  stances: { researched: number; total: number };
  last_researched: string | null;
}

/** A location row enriched with live stats + a freshness flag, for the API. */
export interface CoverageLocationResolved extends CoverageLocationFile {
  stale: boolean;
  roster_actual: number; // active politicians currently loaded
  roster_complete: boolean; // expected_seats known AND actual ≥ expected
}

/** A budget-bearing municipality with no matching coverage row (money data, no people data). */
export interface TreasuryOrphan {
  name: string;
  level: CoverageLevel;
}

export interface CoverageResponse {
  state: string;
  state_name: string;
  synced_at: string | null;
  freshness_days: number;
  universe: UniverseCategory[];
  rules: CoverageRules;
  locations: CoverageLocationResolved[];
  treasury_orphans: TreasuryOrphan[];
}

function coverageDir(): string {
  return path.join(process.cwd(), 'data', 'coverage');
}

export function coverageFilePath(state: string): string {
  return path.join(coverageDir(), `${state.toLowerCase()}.yaml`);
}

/** List the state codes that have a coverage file (e.g. ['ut']). */
export function listCoverageStates(): string[] {
  const dir = coverageDir();
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.yaml'))
    .map((f) => f.replace(/\.yaml$/, ''))
    .sort();
}

/**
 * Normalize a YAML date value to a 'YYYY-MM-DD' string. js-yaml's default
 * schema parses bare ISO dates (e.g. 2026-05-30) into JS Date objects, so coerce
 * them back to plain date strings for stable typing, diffing and JSON output.
 */
function toDateStr(v: unknown): string | null {
  if (v == null) return null;
  if (v instanceof Date) return v.toISOString().slice(0, 10);
  return String(v);
}

/** Read + parse a coverage YAML file. Throws if the file is missing. */
export function readCoverageFile(state: string): CoverageFile {
  const file = coverageFilePath(state);
  if (!fs.existsSync(file)) {
    throw new Error(`No coverage file for state "${state}" (${file})`);
  }
  const parsed = yaml.load(fs.readFileSync(file, 'utf8')) as CoverageFile;
  if (!parsed || !Array.isArray(parsed.locations)) {
    throw new Error(`Malformed coverage file: ${file}`);
  }
  parsed.rules ??= { skip_topics: [], notes: [] };
  parsed.rules.skip_topics ??= [];
  parsed.rules.notes ??= [];
  parsed.synced_at = toDateStr(parsed.synced_at);
  for (const loc of parsed.locations) {
    loc.last_researched = toDateStr(loc.last_researched);
    loc.expected_seats = loc.expected_seats == null ? null : Number(loc.expected_seats);
  }
  return parsed;
}

function tristate(part: number, total: number): Tristate {
  if (total === 0 || part === 0) return 'none';
  return part >= total ? 'full' : 'partial';
}

/** Minimal shape needed to compute stats for a coverage row. */
export interface LocationStatSpec {
  ocd_id: string;
  ocd_kind?: string | null;
  match?: CoverageMatch;
  office_title_like?: string | null;
  exclude_title_like?: string | null;
}

/**
 * Compute live coverage stats for a coverage row.
 * Reused by the admin API (live) and coverage-sync.ts (snapshot).
 */
export async function computeLocationStats(spec: LocationStatSpec): Promise<LocationStats> {
  const match = spec.match ?? 'subtree';
  let where: string;
  let params: (string | null)[];
  if (match === 'exact') {
    where = 'd.ocd_id = $1';
    params = [spec.ocd_id];
    // Optionally drop offices by title — e.g. exclude U.S. Senators from the
    // statewide bucket once they have their own 'title'-matched row.
    if (spec.exclude_title_like) {
      where += ' AND o.title NOT ILIKE $2';
      params.push(spec.exclude_title_like);
    }
  } else if (match === 'kind') {
    // all districts of a kind under the state prefix, e.g. .../state:tx/sldl:NN
    where = `d.ocd_id LIKE $1 || '/%' AND d.ocd_id ~ ('/' || $2 || ':')`;
    params = [spec.ocd_id, spec.ocd_kind ?? ''];
  } else if (match === 'title') {
    // statewide-elected officials with no distinct district (e.g. U.S. Senators
    // share the bare .../state:<code> OCD with the governor) — filter by office title.
    where = 'd.ocd_id = $1 AND o.title ILIKE $2';
    params = [spec.ocd_id, spec.office_title_like ?? ''];
  } else {
    where = `(d.ocd_id = $1 OR d.ocd_id LIKE $1 || '/%')`;
    params = [spec.ocd_id];
  }
  const { rows } = await pool.query<{
    total: string;
    with_photos: string;
    researched: string;
    last_researched: string | null;
  }>(
    `SELECT
       COUNT(DISTINCT p.id)                                                    AS total,
       COUNT(DISTINCT p.id) FILTER (WHERE ${HAS_RENDERABLE_PHOTO_SQL})         AS with_photos,
       -- "researched" = politician has ≥1 compass answer (the real data), NOT the
       -- last_stances_researched_at timestamp, which is unstamped for bulk-loaded
       -- states (CA/OR show 0 stamped despite hundreds with answers). The date
       -- column below still comes from the timestamp, so it stays blank when the
       -- true research date is unknown rather than fabricating one.
       COUNT(DISTINCT p.id) FILTER (WHERE ans.politician_id IS NOT NULL)       AS researched,
       to_char(MAX(p.last_stances_researched_at), 'YYYY-MM-DD')                AS last_researched
     FROM essentials.politicians p
     -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
     JOIN essentials.office_current_holder och ON och.politician_id = p.id
     JOIN essentials.offices   o ON o.id = och.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
     -- @season-scope: all-seasons — coverage answers "has this person EVER been
     --   researched". Narrowing it to the open season would report a loss of data
     --   that did not happen: a stance from season 1 is still a stance we hold.
     --   DISTINCT politician_id collapses the per-season rows, so this cannot fan
     --   out when a second season exists.
     LEFT JOIN (SELECT DISTINCT politician_id FROM inform.politician_answers) ans
            ON ans.politician_id = p.id
     WHERE p.is_active = true
       AND ${where}`,
    params,
  );
  const r = rows[0];
  const total = Number(r?.total ?? 0);
  const withPhotos = Number(r?.with_photos ?? 0);
  const researched = Number(r?.researched ?? 0);
  return {
    populated: total > 0,
    headshots: tristate(withPhotos, total),
    stances: { researched, total },
    last_researched: r?.last_researched ?? null,
  };
}

// ── Universe (full-state progress) ──────────────────────────────────────────
// TIGER MTFCC → jurisdiction category. Names are cleaned to OCD-style slugs so
// they can be diffed against districts.ocd_id (which is what populated jurisdictions key on).
const UNIVERSE_LAYERS: {
  level: Exclude<UniverseLevel, 'tribe'>;
  label: string;
  mtfcc: string;
  ocdKind: string;
  strip: RegExp;
}[] = [
  // These strips MUST mirror scripts/backfill-district-ocd.ts, which synthesizes the ocd_id slugs
  // this matches against. Where they diverged, the universe card contradicted itself: Oregon showed
  // "12 of 12 started" while listing 11 as remaining, because the backfill strips a trailing
  // state-assigned district number ("Beaverton School District 48J" -> beaverton) and this did not.
  // Change the two together.
  { level: 'county', label: 'Counties', mtfcc: 'G4020', ocdKind: 'county', strip: / county$/i },
  // `village|borough|CDP` for the same reason: the backfill strips them (WI place names read
  // "Elmwood Park village"), so without them a WI village never matches its own populated slug.
  { level: 'local', label: 'Cities & Towns', mtfcc: 'G4110', ocdKind: 'place', strip: / (city|town|village|borough|CDP)$/i },
  { level: 'school', label: 'School Districts', mtfcc: 'G5420', ocdKind: 'school_district', strip: / school district( \d+[a-z]?)?$| \d+[a-z]?$/i },
];

// `name` is typed nullable because geofence_boundaries.name IS nullable and IS null in practice.
// Callers filter nulls out before matching; this guard only keeps a future caller from crashing.
function toSlug(name: string | null, strip: RegExp): string {
  if (!name) return '';
  return name
    .replace(strip, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

/** Set of jurisdiction slugs (for one OCD kind) that have ≥1 active politician. */
async function populatedSlugs(stateCode: string, ocdKind: string): Promise<Set<string>> {
  const { rows } = await pool.query<{ slug: string }>(
    `SELECT DISTINCT regexp_replace(d.ocd_id, $1, $2) AS slug
       FROM essentials.districts d
       JOIN essentials.offices o ON o.district_id = d.id
       -- ADR 0002 phase 5: occupancy resolves via office_current_holder.
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active = true
      WHERE d.ocd_id LIKE $3 AND d.ocd_id ~ $4`,
    [`^.*/${ocdKind}:([^/]+).*$`, '\\1', `ocd-division/country:us/state:${stateCode}/%`, `/${ocdKind}:`],
  );
  return new Set(rows.map((r) => r.slug));
}

/**
 * Progress toward covering the ENTIRE state: per category, how many of the full
 * universe of jurisdictions have politicians yet, and which remain. Universe
 * totals come from TIGER geofences; tribes are a static list (no geofences yet).
 */
export async function computeUniverse(
  file: CoverageFile,
  resolved: CoverageLocationResolved[],
): Promise<UniverseCategory[]> {
  const stateCode = file.state.toLowerCase();
  const fips = file.universe?.state_fips;
  const out: UniverseCategory[] = [];

  if (fips) {
    for (const layer of UNIVERSE_LAYERS) {
      const { rows: allRows } = await pool.query<{ name: string | null }>(
        `SELECT name FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = $2 ORDER BY name`,
        [fips, layer.mtfcc],
      );
      if (allRows.length === 0) continue; // no geofence denominator for this category in this state
      // geofence_boundaries.name is NULLABLE and null in practice (MA 5 school districts, VA 1).
      // toSlug(null) threw here, and one null 500'd getCoverage for the WHOLE state — the admin
      // coverage page has been dead for MA and VA. This is the same nullable-name defect that was
      // fixed in coverage-init.ts and missed here; see data/coverage/README.md.
      const rows = allRows.filter((r) => r.name !== null);
      const nameless = allRows.length - rows.length;
      // started/complete come from the tracked rows (kept internally consistent: complete ⊆ started);
      // geofences provide only the total denominator and the "remaining" name list.
      const levelLocs = resolved.filter((l) => l.level === layer.level);
      const started = levelLocs.filter((l) => l.roster_actual > 0).length;
      const complete = levelLocs.filter((l) => l.roster_complete).length;
      const pop = await populatedSlugs(stateCode, layer.ocdKind);
      // Matching is by name, so a nameless geofence can never match a populated slug. It still
      // COUNTS toward `total` (the jurisdiction is real), but it cannot be listed in `remaining`
      // without asserting it is unstarted — which for MA's school districts would be false, since
      // Boston/Lynn/Medford/Newton/Somerville are covered. So flag the card unreliable instead:
      // the same "universe size unknown" escape the started > total case already uses.
      const remaining = rows.filter((r) => !pop.has(toSlug(r.name, layer.strip))).map((r) => r.name!);
      out.push({
        level: layer.level,
        label: layer.label,
        total: allRows.length,
        complete,
        started,
        remaining,
        reliable: allRows.length >= started && nameless === 0,
      });
    }
  }

  const tribes = file.universe?.tribes ?? [];
  if (tribes.length > 0) {
    out.push({ level: 'tribe', label: 'Tribal Nations', total: tribes.length, complete: 0, started: 0, remaining: tribes, reliable: true });
  }
  return out;
}

function isStale(lastResearched: string | null): boolean {
  if (!lastResearched) return false;
  const then = Date.parse(lastResearched);
  if (Number.isNaN(then)) return false;
  return Date.now() - then > FRESHNESS_DAYS * 24 * 60 * 60 * 1000;
}

// ── Treasury (budget-data coverage) ─────────────────────────────────────────
// READ-ONLY against the treasury schema (treasury.municipalities / budgets).
// treasury.municipalities now carries a TIGER `geo_id` (migration 194, populated by
// scripts/backfill-treasury-geo-id.ts and the budget importers). We PREFER an exact
// geo_id join (treasury.geo_id ↔ the coverage location's district geo_id) and fall
// back to the legacy name+state slug only for rows whose geo_id is still NULL
// (townships / special districts / un-backfilled imports).
const TREASURY_ENTITY_TO_LEVEL: Record<string, CoverageLevel> = {
  city: 'local',
  town: 'local',
  municipality: 'local',
  county: 'county',
  school_district: 'school',
};

function treasurySlug(name: string, entityType: string): string {
  const cleaned = entityType === 'county' ? name.replace(/ county$/i, '') : name;
  return cleaned.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

/** The OCD slug + level for a location, if it's a place/county/school row. */
function locationSlug(loc: { ocd_id: string; level: CoverageLevel }): string | null {
  const kind = loc.level === 'local' ? 'place' : loc.level === 'county' ? 'county' : loc.level === 'school' ? 'school_district' : null;
  if (!kind) return null;
  return loc.ocd_id.match(new RegExp(`/${kind}:([a-z0-9_]+)`))?.[1] ?? null;
}

interface TreasuryEntry {
  name: string;
  level: CoverageLevel;
  status: Tristate; // full = has budgets, partial = municipality exists but no budgets
  geoId: string | null; // TIGER geo_id (null for townships/special districts/un-backfilled)
}

export interface TreasuryForState {
  byKey: Map<string, Tristate>; // `${level}|${slug}` → status (legacy name fallback)
  byGeoId: Map<string, Tristate>; // TIGER geo_id → status (preferred exact join)
  entries: Map<string, TreasuryEntry>; // for orphan computation
}

/**
 * Treasury status for a state: a geo_id-keyed map (preferred), a name-slug-keyed map
 * (fallback), and the raw entries (to compute orphans). Read-only; never mutates
 * treasury data.
 */
export async function computeTreasuryForState(state: string): Promise<TreasuryForState> {
  const byKey = new Map<string, Tristate>();
  const byGeoId = new Map<string, Tristate>();
  const entries = new Map<string, TreasuryEntry>();
  const { rows } = await pool.query<{ name: string; entity_type: string; geo_id: string | null; budgets: number }>(
    `SELECT m.name, m.entity_type, m.geo_id, COUNT(b.id)::int AS budgets
       FROM treasury.municipalities m
       LEFT JOIN treasury.budgets b ON b.municipality_id = m.id
      WHERE lower(m.state) = $1
      GROUP BY m.id, m.name, m.entity_type, m.geo_id`,
    [state.toLowerCase()],
  );
  for (const r of rows) {
    const level = TREASURY_ENTITY_TO_LEVEL[r.entity_type];
    if (!level) continue; // townships / libraries / special districts aren't coverage jurisdictions
    const key = `${level}|${treasurySlug(r.name, r.entity_type)}`;
    const status: Tristate = r.budgets > 0 ? 'full' : 'partial';
    if (byKey.get(key) !== 'full') byKey.set(key, status); // prefer 'full' on collision
    if (r.geo_id && byGeoId.get(r.geo_id) !== 'full') byGeoId.set(r.geo_id, status);
    if (!entries.has(key) || status === 'full') entries.set(key, { name: r.name, level, status, geoId: r.geo_id });
  }
  return { byKey, byGeoId, entries };
}

/**
 * Resolve each coverage location's TIGER geo_id via its district (exact ocd_id match).
 * This is the key the treasury geo_id join hangs on: treasury.geo_id ↔ district.geo_id.
 * Locations with no matching district geo_id simply fall back to the name slug.
 */
export async function resolveLocationGeoIds(
  locations: { ocd_id: string }[],
): Promise<Map<string, string>> {
  const ocds = [...new Set(locations.map((l) => l.ocd_id))];
  const map = new Map<string, string>();
  if (ocds.length === 0) return map;
  const { rows } = await pool.query<{ ocd_id: string; geo_id: string }>(
    `SELECT DISTINCT ON (ocd_id) ocd_id, geo_id
       FROM essentials.districts
      WHERE geo_id IS NOT NULL AND ocd_id = ANY($1)
      ORDER BY ocd_id, geo_id`,
    [ocds],
  );
  for (const r of rows) map.set(r.ocd_id, r.geo_id);
  return map;
}

/**
 * Treasury status for one coverage location (auto column). Prefers an exact geo_id
 * match; falls back to the legacy name+level slug when the location has no resolved
 * geo_id or no geo_id-keyed treasury row.
 */
export function locationTreasury(
  loc: { ocd_id: string; level: CoverageLevel },
  treasury: Pick<TreasuryForState, 'byKey' | 'byGeoId'>,
  locGeoId?: string | null,
): Tristate {
  if (locGeoId) {
    const byGeo = treasury.byGeoId.get(locGeoId);
    if (byGeo) return byGeo;
  }
  const slug = locationSlug(loc);
  if (!slug) return 'none';
  return treasury.byKey.get(`${loc.level}|${slug}`) ?? 'none';
}

/**
 * Read the coverage file for a state and overlay live DB stats onto each row.
 * This is what GET /api/admin/coverage returns.
 */
/**
 * Run an async mapper over items with BOUNDED concurrency. The pg pool is small
 * (max 5), so a plain Promise.all over a large YAML (e.g. CA has ~181 tracked
 * locations) would request far more connections than exist and every query past
 * the 5th would time out waiting to connect → 500. A handful of workers draining
 * a shared cursor keeps in-flight queries ≤ limit.
 */
async function mapWithConcurrency<T, R>(items: T[], limit: number, fn: (item: T) => Promise<R>): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;
  const worker = async (): Promise<void> => {
    while (next < items.length) {
      const i = next++;
      results[i] = await fn(items[i]);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

export async function getCoverage(state: string): Promise<CoverageResponse> {
  const file = readCoverageFile(state);
  const treasury = await computeTreasuryForState(state);
  const geoIdByOcd = await resolveLocationGeoIds(file.locations);
  const locations: CoverageLocationResolved[] = await mapWithConcurrency(
    file.locations,
    4, // ≤ pool max (5), leaving headroom
    async (loc) => {
      const stats = await computeLocationStats(loc);
      const rosterComplete =
        loc.expected_seats != null && stats.stances.total > 0 && stats.stances.total >= loc.expected_seats;
      return {
        ...loc,
        populated: stats.populated,
        headshots: stats.headshots,
        stances: stats.stances,
        last_researched: stats.last_researched,
        treasury: locationTreasury(loc, treasury, geoIdByOcd.get(loc.ocd_id)), // auto column (overrides YAML)
        stale: isStale(stats.last_researched),
        roster_actual: stats.stances.total,
        roster_complete: rosterComplete,
      };
    },
  );
  const universe = await computeUniverse(file, locations);

  // Orphans: budget-bearing municipalities with no matching coverage row. A treasury
  // entry counts as covered if its geo_id matches a covered location's geo_id (exact)
  // OR its name+level slug matches a covered location (legacy fallback).
  const covKeys = new Set(file.locations.map((l) => `${l.level}|${locationSlug(l) ?? ''}`));
  const covGeoIds = new Set([...geoIdByOcd.values()]);
  const treasury_orphans: TreasuryOrphan[] = [...treasury.entries.entries()]
    .filter(([key, e]) => e.status === 'full' && !(e.geoId && covGeoIds.has(e.geoId)) && !covKeys.has(key))
    .map(([, e]) => ({ name: e.name, level: e.level }))
    .sort((a, b) => a.name.localeCompare(b.name));

  return {
    state: file.state,
    state_name: file.state_name,
    synced_at: file.synced_at ?? null,
    freshness_days: FRESHNESS_DAYS,
    universe,
    rules: file.rules,
    treasury_orphans,
    locations,
  };
}

/**
 * Skip-topic rules that apply to a given office level — used by the
 * research-stances skill (and exposable via the API) to exclude inapplicable
 * topics before dispatching researcher agents.
 */
export function skipTopicsForLevel(state: string, level: CoverageLevel): SkipTopicRule[] {
  const file = readCoverageFile(state);
  return file.rules.skip_topics.filter((r) => r.applies_to.includes(level));
}
