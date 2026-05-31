/**
 * coverageMapService.ts — choropleth scores for the coverage map view.
 *
 * Complements coverageService.ts (the tabular tracker). Where that service
 * returns the hand-tracked YAML rows for one state, this one produces a single
 * "composite depth" score per geography so a US → county choropleth can colour
 * each polygon without shipping any politician data to the client.
 *
 * Score model (per JURISDICTION — a county, place, or school district):
 *   composite = weighted mean of five axes, each normalised to 0..1
 *     geofenced  — exists as a TIGER polygon (always 1 inside the universe)
 *     populated  — ≥1 active politician loaded
 *     headshots  — fraction of those politicians with a photo
 *     stances    — fraction with stances researched
 *     roster     — actual / expected_seats   (N/A unless tracked in the YAML)
 *   Axes that are N/A (roster, for untracked jurisdictions) are dropped and the
 *   remaining weights renormalised, so untracked jurisdictions still score on
 *   the four axes they do have.
 *
 * Geography rollup:
 *   county score = mean composite over { county govt + every place / school
 *                  district whose centroid falls inside the county }
 *   state score  = mean composite over the whole state universe
 * Empty / untracked jurisdictions score low, so white space correctly drags a
 * county's colour down — one number blends breadth and depth.
 *
 * Jurisdiction → politician join mirrors coverageService: politicians reach a
 * jurisdiction through offices.district_id → districts.ocd_id, matched as a
 * subtree. Places / school districts have no ocd_id on geofence_boundaries, so
 * (like computeUniverse) we derive their ocd_id from the TIGER name via toSlug.
 *
 * Results are cached in-process for CACHE_TTL_MS (coverage moves slowly); pass
 * ?refresh=1 on the route to bust the cache.
 */

import { pool } from './db.js';
import { listCoverageStates, readCoverageFile, type Tristate } from './coverageService.js';

export interface AxisWeights {
  geofenced: number;
  populated: number;
  headshots: number;
  stances: number;
  roster: number;
  treasury: number;
  donors: number;
}

/**
 * Default weighting — roster + stances dominate; the rest are lighter signals.
 * NOTE: in the map universe every jurisdiction is geofenced (the universe IS the
 * geofence table), so the `geofenced` axis is effectively a constant baseline —
 * it's kept small and surfaced as a visible breakdown column rather than relied
 * on to differentiate jurisdictions. Tune freely.
 */
export const DEFAULT_WEIGHTS: AxisWeights = {
  roster: 0.3,
  stances: 0.25,
  headshots: 0.1,
  populated: 0.1,
  geofenced: 0.1,
  treasury: 0.1,
  donors: 0.05,
};

const TRISTATE_VALUE: Record<Tristate, number> = { none: 0, partial: 0.5, full: 1 };

export type MapLevel = 'county' | 'local' | 'school';

/** Per-jurisdiction summary used both in the rollup and the drill-down panel. */
export interface JurisdictionScore {
  ocd_id: string;
  name: string;
  level: MapLevel;
  county_fips: string | null;
  score: number; // composite 0..100
  populated: boolean;
  roster_actual: number;
  expected_seats: number | null;
  headshots: { withPhoto: number; total: number };
  stances: { researched: number; total: number };
  geofenced: boolean;
  treasury: Tristate;
  donors: Tristate;
}

export interface CountyScore {
  fips: string; // 5-digit county FIPS (matches us-atlas county keys)
  name: string;
  score: number; // 0..100, mean composite over jurisdictions inside
  jurisdiction_count: number;
  populated_count: number;
  jurisdictions: JurisdictionScore[];
}

export interface StateScore {
  fips: string; // 2-digit state FIPS (matches us-atlas state keys)
  code: string; // 2-letter lowercase (e.g. 'ut')
  name: string;
  score: number; // 0..100
  jurisdiction_count: number;
  populated_count: number;
}

const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; data: unknown }>();

function cached<T>(key: string, refresh: boolean, build: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (!refresh && hit && Date.now() - hit.at < CACHE_TTL_MS) {
    return Promise.resolve(hit.data as T);
  }
  return build().then((data) => {
    cache.set(key, { at: Date.now(), data });
    return data;
  });
}

// TIGER name → OCD-style slug. Mirrors coverageService.toSlug (kept local to
// avoid widening that module's export surface; keep the two in sync).
function toSlug(name: string, strip: RegExp): string {
  return name
    .replace(strip, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}
const PLACE_STRIP = / (city|town)$/i;
const SCHOOL_STRIP = / school district$/i;

interface JurisStats {
  total: number;
  withPhoto: number;
  researched: number;
}

/**
 * One query per state: active politicians grouped by their jurisdiction-level
 * OCD key (.../county:x | .../place:y | .../school_district:z). District rows
 * that aren't under one of those kinds (state-exec, legislative) yield a null
 * key and are dropped — they aren't part of the county rollup.
 */
async function statsByJurisdiction(stateCode: string): Promise<Map<string, JurisStats>> {
  const { rows } = await pool.query<{
    juris_ocd: string | null;
    total: string;
    with_photos: string;
    researched: string;
  }>(
    `SELECT
       (regexp_match(d.ocd_id,
         '^(ocd-division/country:us/state:' || $1 || '/(?:county|place|school_district):[^/]+)'))[1] AS juris_ocd,
       COUNT(DISTINCT p.id)                                                         AS total,
       COUNT(DISTINCT p.id) FILTER (
         WHERE img.politician_id IS NOT NULL
            OR p.photo_origin_url IS NOT NULL
            OR p.photo_custom_url IS NOT NULL)                                      AS with_photos,
       COUNT(DISTINCT p.id) FILTER (WHERE p.last_stances_researched_at IS NOT NULL) AS researched
     FROM essentials.politicians p
     JOIN essentials.offices   o ON o.politician_id = p.id
     JOIN essentials.districts d ON d.id = o.district_id
     LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
     WHERE p.is_active = true
       AND d.ocd_id LIKE 'ocd-division/country:us/state:' || $1 || '/%'
     GROUP BY juris_ocd`,
    [stateCode],
  );
  const map = new Map<string, JurisStats>();
  for (const r of rows) {
    if (!r.juris_ocd) continue;
    map.set(r.juris_ocd, {
      total: Number(r.total),
      withPhoto: Number(r.with_photos),
      researched: Number(r.researched),
    });
  }
  return map;
}

/** Manually-tracked fields per jurisdiction ocd_id, from the YAML (if any). */
interface YamlRow {
  expected: number | null;
  donors: Tristate;
  treasury: Tristate;
}
function yamlByOcd(stateCode: string): Map<string, YamlRow> {
  const map = new Map<string, YamlRow>();
  try {
    const file = readCoverageFile(stateCode);
    for (const loc of file.locations) {
      map.set(loc.ocd_id, {
        expected: loc.expected_seats ?? null,
        donors: loc.donors ?? 'none',
        treasury: loc.treasury ?? 'none',
      });
    }
  } catch {
    /* no YAML for this state — fine */
  }
  return map;
}

/** geo_ids in this state with ≥1 loaded budget (treasury-tracker data present). */
async function treasuryGeoIds(stateCode: string): Promise<Set<string>> {
  const { rows } = await pool.query<{ geo_id: string }>(
    `SELECT DISTINCT m.geo_id FROM treasury.municipalities m
       JOIN treasury.budgets b ON b.municipality_id = m.id
      WHERE upper(m.state) = $1 AND m.geo_id IS NOT NULL`,
    [stateCode.toUpperCase()],
  );
  return new Set(rows.map((r) => r.geo_id));
}

function compositeScore(j: {
  populated: boolean;
  withPhoto: number;
  total: number;
  researched: number;
  expected: number | null;
  geofenced: boolean;
  treasury: Tristate;
  donors: Tristate;
}, w: AxisWeights): number {
  const axes: { weight: number; value: number }[] = [
    { weight: w.geofenced, value: j.geofenced ? 1 : 0 },
    { weight: w.populated, value: j.populated ? 1 : 0 },
    { weight: w.headshots, value: j.total > 0 ? j.withPhoto / j.total : 0 },
    { weight: w.stances, value: j.total > 0 ? j.researched / j.total : 0 },
    { weight: w.treasury, value: TRISTATE_VALUE[j.treasury] },
    { weight: w.donors, value: TRISTATE_VALUE[j.donors] },
  ];
  if (j.expected != null && j.expected > 0) {
    axes.push({ weight: w.roster, value: Math.min(1, j.total / j.expected) });
  }
  const wsum = axes.reduce((s, a) => s + a.weight, 0);
  if (wsum === 0) return 0;
  const score = axes.reduce((s, a) => s + a.weight * a.value, 0) / wsum;
  return Math.round(score * 1000) / 10; // 0..100, one decimal
}

/**
 * Build every jurisdiction (county / place / school) in a state with its
 * composite score and the county it sits in. Shared by the county and US
 * endpoints. One spatial query assigns places/schools to a county by centroid.
 */
async function buildJurisdictions(
  stateFips: string,
  stateCode: string,
  weights: AxisWeights,
): Promise<JurisdictionScore[]> {
  const [counties, children, stats, treasurySet] = await Promise.all([
    pool.query<{ geo_id: string; ocd_id: string | null; name: string }>(
      `SELECT geo_id, ocd_id, name FROM essentials.geofence_boundaries
        WHERE state = $1 AND mtfcc = 'G4020'`,
      [stateFips],
    ),
    // Assign each place / school to the county it OVERLAPS MOST, not by centroid.
    // Centroid containment breaks for jurisdictions with offshore parts — e.g.
    // San Francisco's centroid lands in the ocean (Farallon Islands), so it would
    // be dropped from SF County entirely.
    pool.query<{ mtfcc: string; name: string; geo_id: string; county_fips: string | null }>(
      `SELECT child.mtfcc, child.name, child.geo_id,
         (SELECT c.geo_id FROM essentials.geofence_boundaries c
           WHERE c.state = $1 AND c.mtfcc = 'G4020' AND ST_Intersects(c.geometry, child.geometry)
           ORDER BY ST_Area(ST_Intersection(c.geometry, child.geometry)) DESC
           LIMIT 1) AS county_fips
         FROM essentials.geofence_boundaries child
        WHERE child.state = $1 AND child.mtfcc IN ('G4110', 'G5420')`,
      [stateFips],
    ),
    statsByJurisdiction(stateCode),
    treasuryGeoIds(stateCode),
  ]);

  const yaml = yamlByOcd(stateCode);
  const out: JurisdictionScore[] = [];

  const push = (ocd_id: string, name: string, level: MapLevel, county_fips: string | null, geoId: string) => {
    const s = stats.get(ocd_id) ?? { total: 0, withPhoto: 0, researched: 0 };
    const y = yaml.get(ocd_id);
    const exp = y?.expected ?? null;
    // Every jurisdiction here comes from the geofence table, so it's geofenced.
    const geofenced = true;
    // Treasury: live signal (a loaded budget for this geo_id) wins; fall back to
    // the YAML flag for jurisdictions tracked but not yet in the treasury schema.
    const treasury: Tristate = treasurySet.has(geoId) ? 'full' : y?.treasury ?? 'none';
    const donors: Tristate = y?.donors ?? 'none';
    const score = compositeScore(
      {
        populated: s.total > 0,
        withPhoto: s.withPhoto,
        total: s.total,
        researched: s.researched,
        expected: exp,
        geofenced,
        treasury,
        donors,
      },
      weights,
    );
    out.push({
      ocd_id,
      name,
      level,
      county_fips,
      score,
      populated: s.total > 0,
      roster_actual: s.total,
      expected_seats: exp,
      headshots: { withPhoto: s.withPhoto, total: s.total },
      stances: { researched: s.researched, total: s.total },
      geofenced,
      treasury,
      donors,
    });
  };

  for (const c of counties.rows) {
    const ocd = c.ocd_id ?? `ocd-division/country:us/state:${stateCode}/county:${toSlug(c.name, / county$/i)}`;
    push(ocd, c.name, 'county', c.geo_id, c.geo_id);
  }
  for (const ch of children.rows) {
    if (ch.mtfcc === 'G4110') {
      push(`ocd-division/country:us/state:${stateCode}/place:${toSlug(ch.name, PLACE_STRIP)}`, ch.name, 'local', ch.county_fips, ch.geo_id);
    } else {
      push(`ocd-division/country:us/state:${stateCode}/school_district:${toSlug(ch.name, SCHOOL_STRIP)}`, ch.name, 'school', ch.county_fips, ch.geo_id);
    }
  }
  return out;
}

function mean(nums: number[]): number {
  if (nums.length === 0) return 0;
  return Math.round((nums.reduce((s, n) => s + n, 0) / nums.length) * 10) / 10;
}

/** County choropleth + drill-down data for one state. */
export async function getCountyScores(
  stateCode: string,
  opts: { refresh?: boolean; weights?: AxisWeights } = {},
): Promise<{ state: string; state_fips: string; counties: CountyScore[] } | null> {
  const code = stateCode.toLowerCase();
  let stateFips: string | undefined;
  try {
    stateFips = readCoverageFile(code).universe?.state_fips;
  } catch {
    return null; // no YAML → not tracked
  }
  if (!stateFips) return null;
  const weights = opts.weights ?? DEFAULT_WEIGHTS;

  return cached(`county:${code}`, !!opts.refresh, async () => {
    const jur = await buildJurisdictions(stateFips!, code, weights);
    const byCounty = new Map<string, JurisdictionScore[]>();
    for (const j of jur) {
      if (!j.county_fips) continue;
      const arr = byCounty.get(j.county_fips) ?? [];
      arr.push(j);
      byCounty.set(j.county_fips, arr);
    }
    const counties: CountyScore[] = [];
    for (const [fips, list] of byCounty) {
      const county = list.find((l) => l.level === 'county');
      counties.push({
        fips,
        name: county?.name ?? fips,
        score: mean(list.map((l) => l.score)),
        jurisdiction_count: list.length,
        populated_count: list.filter((l) => l.populated).length,
        jurisdictions: list.sort((a, b) => {
          const order = { county: 0, local: 1, school: 2 } as const;
          return order[a.level] - order[b.level] || a.name.localeCompare(b.name);
        }),
      });
    }
    counties.sort((a, b) => a.name.localeCompare(b.name));
    return { state: code, state_fips: stateFips!, counties };
  });
}

/** US choropleth: one score per tracked state. Untracked states are omitted. */
export async function getStateScores(
  opts: { refresh?: boolean; weights?: AxisWeights } = {},
): Promise<StateScore[]> {
  const weights = opts.weights ?? DEFAULT_WEIGHTS;
  return cached('us', !!opts.refresh, async () => {
    const out: StateScore[] = [];
    for (const code of listCoverageStates()) {
      const file = readCoverageFile(code);
      const fips = file.universe?.state_fips;
      if (!fips) continue;
      const jur = await buildJurisdictions(fips, code, weights);
      out.push({
        fips,
        code,
        name: file.state_name,
        score: mean(jur.map((j) => j.score)),
        jurisdiction_count: jur.length,
        populated_count: jur.filter((j) => j.populated).length,
      });
    }
    return out;
  });
}
