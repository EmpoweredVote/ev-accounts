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
import { toSlug, PLACE_STRIP } from './electionsMap.js';
import { aggregateUnits, type Unit } from './coverageBivariate.js';
import { HAS_RENDERABLE_PHOTO_SQL } from './photoCoverage.js';
import { HAS_ANY_CONTRIBUTION_SQL } from './donorCoverage.js';
import { ALL_STATES, getFederalStateStats, type FederalStateStats } from './federalCoverage.js';

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
 * geofence table), so `geofenced` is effectively a constant. It's kept at a TINY
 * weight — a boundary-only county should read as ~empty (near 0%), barely nudged
 * above "not started", and any county with even one official should clearly
 * outrank it. Surfaced as a breakdown column rather than relied on for colour.
 * Tune freely.
 */
export const DEFAULT_WEIGHTS: AxisWeights = {
  roster: 0.35,
  stances: 0.3,
  populated: 0.1,
  headshots: 0.1,
  treasury: 0.1,
  donors: 0.03,
  geofenced: 0.02,
};

/**
 * True number of counties (+ county-equivalents) per state, keyed by 2-digit
 * state FIPS — the denominator for STATE breadth. The geofence table can be an
 * incomplete county universe in prod (e.g. Indiana has only Monroe loaded), so
 * denominating breadth by loaded geofences would overstate coverage. These are
 * the fixed US Census county-equivalent counts (TIGER 2024); states absent here
 * fall back to the loaded-geofence count. Tunable.
 */
export const US_COUNTY_COUNTS: Record<string, number> = {
  '01': 67,  '02': 30,  '04': 15,  '05': 75,  '06': 58,  '08': 64,  '09': 9,   '10': 3,
  '11': 1,   '12': 67,  '13': 159, '15': 5,   '16': 44,  '17': 102, '18': 92,  '19': 99,
  '20': 105, '21': 120, '22': 64,  '23': 16,  '24': 24,  '25': 14,  '26': 83,  '27': 87,
  '28': 82,  '29': 115, '30': 56,  '31': 93,  '32': 17,  '33': 10,  '34': 21,  '35': 33,
  '36': 62,  '37': 100, '38': 53,  '39': 88,  '40': 77,  '41': 36,  '42': 67,  '44': 5,
  '45': 46,  '46': 66,  '47': 95,  '48': 254, '49': 29,  '50': 14,  '51': 133, '53': 39,
  '54': 55,  '55': 72,  '56': 23,
};

const TRISTATE_VALUE: Record<Tristate, number> = { none: 0, partial: 0.5, full: 1 };

/** part/total → tristate (none if 0, full if all, partial otherwise). */
function ratioTristate(part: number, total: number): Tristate {
  if (total === 0 || part === 0) return 'none';
  return part >= total ? 'full' : 'partial';
}

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
  donors_n: { withDonors: number; total: number };
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
  // Bivariate + hover breakdown (completeness mode):
  breadth: number; // 0..1 — populated_count ÷ jurisdiction_count
  depth: number;   // 0..100 — mean composite over populated jurisdictions only
  county_govt_started: boolean;
  cities_started: number;
  cities_total: number;
  schools_started: number;
  schools_total: number;
  roster_pct: number;   // 0..100 over populated jurisdictions
  stances_pct: number;  // 0..100
  photo_pct: number;    // 0..100
  donors_pct: number;   // 0..100 — politicians with ≥1 contribution ÷ total
  treasury: Tristate;   // categorical: any/all populated jurisdictions with a budget
}

export interface StateScore {
  fips: string; // 2-digit state FIPS (matches us-atlas state keys)
  code: string; // 2-letter lowercase (e.g. 'ut')
  name: string;
  /** false = no coverage YAML — local fields are zeros and `score` is null. */
  tracked: boolean;
  /** Local-government composite 0..100; null when the state is untracked. */
  score: number | null;
  /** Federal + state-office coverage — present for EVERY state (live from DB). */
  federal: FederalStateStats;
  jurisdiction_count: number;
  populated_count: number;
  // Bivariate + hover breakdown (completeness mode):
  breadth: number; // 0..1 — counties with ≥1 started unit ÷ total counties
  depth: number;   // 0..100 — mean of started counties' depth
  counties_started: number;
  counties_total: number;
  cities_started: number;
  cities_total: number;
  schools_started: number;
  schools_total: number;
  roster_pct: number;  // 0..100 over started units
  stances_pct: number; // 0..100 over started units
  photo_pct: number;   // 0..100 over started units
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

const SCHOOL_STRIP = / school district$/i;

interface JurisStats {
  total: number;
  withPhoto: number;
  researched: number;
  withDonors: number;
}

/**
 * One query per state: active politicians grouped by their jurisdiction-level
 * OCD key (.../county:x | .../place:y | .../school_district:z). District rows
 * that aren't under one of those kinds (state-exec, legislative) yield a null
 * key and are dropped — they aren't part of the county rollup.
 *
 * Signals (these come from the ACTUAL data, not proxy flags):
 *   researched — politician has ≥1 compass answer in inform.politician_answers.
 *     NOT politicians.last_stances_researched_at: that timestamp is unstamped for
 *     bulk-loaded states (CA/OR have 0 stamped despite 228/108 with answers), so
 *     it badly under-reported stance coverage.
 *   withDonors — politician has ≥1 contribution. The contributions table keys on
 *     politician_source_id, which is NOT an essentials id — it joins through
 *     transparent_motivations.politician_sources.essentials_politician_id.
 */
async function statsByJurisdiction(stateCode: string): Promise<Map<string, JurisStats>> {
  const { rows } = await pool.query<{
    juris_ocd: string | null;
    total: string;
    with_photos: string;
    researched: string;
    with_donors: string;
  }>(
    `SELECT
       (regexp_match(d.ocd_id,
         '^(ocd-division/country:us/state:' || $1 || '/(?:county|place|school_district):[^/]+)'))[1] AS juris_ocd,
       COUNT(DISTINCT p.id)                                                         AS total,
       COUNT(DISTINCT p.id) FILTER (WHERE ${HAS_RENDERABLE_PHOTO_SQL})              AS with_photos,
       COUNT(DISTINCT p.id) FILTER (WHERE ans.politician_id IS NOT NULL)            AS researched,
       COUNT(DISTINCT p.id) FILTER (WHERE ${HAS_ANY_CONTRIBUTION_SQL})              AS with_donors
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
     -- @zero-scope: counts-blanks — a blanked answer (value 0) still counts here,
     --   for the same reason. Blanking means the ladder moved out from under a
     --   position, not that the research was undone: the reading happened, the
     --   sources stand, and there is simply no rung left that states what this
     --   person holds. Excluding blanks would report a coverage loss no editor
     --   caused. Measured 2026-09-02: every politician holding a blank holds at
     --   least 7 other answers, so this count is identical either way today —
     --   the note is here so the next reader does not "fix" it.
     LEFT JOIN (SELECT DISTINCT politician_id FROM inform.politician_answers) ans
            ON ans.politician_id = p.id
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
      withDonors: Number(r.with_donors),
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
        WHERE state = $1 AND mtfcc = 'G4020' AND name IS NOT NULL`,
      [stateFips],
    ),
    // Each place / school is assigned to the county it OVERLAPS MOST, not by centroid — centroid
    // containment breaks for jurisdictions with offshore parts, e.g. San Francisco's centroid lands
    // in the ocean (Farallon Islands), which would drop SF from its own county.
    //
    // That assignment is now PERSISTED in essentials.geofence_child_county (migration 1696) rather
    // than recomputed here. It was the single largest cost in this endpoint — 15.9 s of
    // ST_Area(ST_Intersection(...)) across the 13 tracked states (ca 5.8 s alone) — and it depends
    // only on geometry, so a request never needed to recompute it. Reading it: 282 ms for all 13.
    //
    // 🔴 REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;  -- after ANY
    // boundary load. A child with no mapping row degrades to an unassigned county (never a dropped
    // row) and is reported by essentials.geofence_child_county_stale and the warning below.
    pool.query<{
      mtfcc: string; name: string; geo_id: string;
      county_fips: string | null; mapping_missing: boolean;
    }>(
      `SELECT child.mtfcc, child.name, child.geo_id,
              m.county_geo_id            AS county_fips,
              (m.child_geo_id IS NULL)   AS mapping_missing
         FROM essentials.geofence_boundaries child
         LEFT JOIN essentials.geofence_child_county m
                ON m.child_geo_id = child.geo_id AND m.child_mtfcc = child.mtfcc
        WHERE child.state = $1 AND child.mtfcc IN ('G4110', 'G5420', 'G5400', 'G5410') AND child.name IS NOT NULL`,
      [stateFips],
    ),
    statsByJurisdiction(stateCode),
    treasuryGeoIds(stateCode),
  ]);

  // Say so loudly if the persisted mapping is behind the boundary table. Silence here would mean a
  // jurisdiction quietly losing its county after a boundary load — the failure mode CLAUDE.md warns
  // about for office_terms, in a different table.
  const unmapped = children.rows.filter((r) => r.mapping_missing).length;
  if (unmapped > 0) {
    console.warn(
      `[coverage] ${stateCode}: ${unmapped} of ${children.rows.length} children have no ` +
        `essentials.geofence_child_county row — run ` +
        `REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county; ` +
        `(see essentials.geofence_child_county_stale)`,
    );
  }

  const yaml = yamlByOcd(stateCode);
  const out: JurisdictionScore[] = [];

  const push = (ocd_id: string, name: string, level: MapLevel, county_fips: string | null, geoId: string) => {
    const s = stats.get(ocd_id) ?? { total: 0, withPhoto: 0, researched: 0, withDonors: 0 };
    const y = yaml.get(ocd_id);
    const exp = y?.expected ?? null;
    // Every jurisdiction here comes from the geofence table, so it's geofenced.
    const geofenced = true;
    // Treasury: live signal (a loaded budget for this geo_id) wins; fall back to
    // the YAML flag for jurisdictions tracked but not yet in the treasury schema.
    const treasury: Tristate = treasurySet.has(geoId) ? 'full' : y?.treasury ?? 'none';
    // Donors: live contribution data (transparent_motivations) — fraction of the
    // jurisdiction's politicians with ≥1 contribution. Was YAML-only, which read
    // 'none' everywhere even though e.g. CA has 260 politicians with donor data.
    const donors: Tristate = ratioTristate(s.withDonors, s.total);
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
      donors_n: { withDonors: s.withDonors, total: s.total },
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

/**
 * Roll a county's jurisdiction list into the bivariate + hover breakdown.
 * breadth/depth come from the pure aggregator (started = populated, depth =
 * composite score). Per-axis values are percentages over the POPULATED
 * jurisdictions, so empty white space doesn't drag them to zero. Treasury stays
 * categorical (a budget is loaded per jurisdiction, not a per-politician ratio).
 */
function countyBreakdown(list: JurisdictionScore[]) {
  const units: Unit[] = list.map((j) => ({ started: j.populated, depth: j.score }));
  const { breadth, depth } = aggregateUnits(units);
  const populated = list.filter((j) => j.populated);

  const cities = list.filter((j) => j.level === 'local');
  const schools = list.filter((j) => j.level === 'school');
  const countyGovt = list.find((j) => j.level === 'county');

  const sum = (sel: (j: JurisdictionScore) => number) => populated.reduce((s, j) => s + sel(j), 0);
  const photoPart = sum((j) => j.headshots.withPhoto);
  const photoTotal = sum((j) => j.headshots.total);
  const stancePart = sum((j) => j.stances.researched);
  const stanceTotal = sum((j) => j.stances.total);
  const donorPart = sum((j) => j.donors_n.withDonors);
  const donorTotal = sum((j) => j.donors_n.total);
  const rosterActual = sum((j) => (j.expected_seats != null ? j.roster_actual : 0));
  const rosterExpected = sum((j) => j.expected_seats ?? 0);
  const pct = (part: number, total: number) => (total > 0 ? Math.round((part / total) * 1000) / 10 : 0);

  const treasuryFull = populated.filter((j) => j.treasury === 'full').length;
  const treasuryAny = populated.filter((j) => j.treasury !== 'none').length;
  // 'full' only when every populated jurisdiction has a budget, 'partial' when some do.
  const treasury: Tristate =
    populated.length === 0 || treasuryAny === 0 ? 'none' : treasuryFull >= populated.length ? 'full' : 'partial';

  return {
    breadth,
    depth,
    county_govt_started: !!countyGovt?.populated,
    cities_started: cities.filter((c) => c.populated).length,
    cities_total: cities.length,
    schools_started: schools.filter((s) => s.populated).length,
    schools_total: schools.length,
    roster_pct: pct(Math.min(rosterActual, rosterExpected), rosterExpected),
    stances_pct: pct(stancePart, stanceTotal),
    photo_pct: pct(photoPart, photoTotal),
    donors_pct: pct(donorPart, donorTotal),
    treasury,
  };
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
      const sorted = list.sort((a, b) => {
        const order = { county: 0, local: 1, school: 2 } as const;
        return order[a.level] - order[b.level] || a.name.localeCompare(b.name);
      });
      counties.push({
        fips,
        name: county?.name ?? fips,
        score: mean(list.map((l) => l.score)),
        jurisdiction_count: list.length,
        populated_count: list.filter((l) => l.populated).length,
        jurisdictions: sorted,
        ...countyBreakdown(list),
      });
    }
    counties.sort((a, b) => a.name.localeCompare(b.name));
    return { state: code, state_fips: stateFips!, counties };
  });
}

/**
 * Roll a whole state's flat jurisdiction list into the bivariate + hover
 * breakdown. Breadth/depth are computed over COUNTY rollups (a county is a
 * "unit"; started = any jurisdiction inside it populated; its depth = mean
 * composite over its populated jurisdictions). This is why a state with one
 * built-out county and many empty ones reads low-breadth / high-depth (teal),
 * instead of the old single mean that washed out to near-empty.
 *
 * Note: the breadth rollup groups by county_fips and skips jurisdictions with a
 * null county_fips (the rare case where ST_Intersects found no county). Those
 * rows are still counted in the state-wide cities/schools hover bars (which are
 * intentionally state-wide, not per-county), so a null-county city can show in
 * cities_total without contributing to any county's started flag. This is
 * negligible in practice and only affects the hover counts, not the breadth color.
 */
function stateBreakdown(jur: JurisdictionScore[], stateFips: string) {
  // Group by county for the county-rollup units.
  const byCounty = new Map<string, JurisdictionScore[]>();
  for (const j of jur) {
    if (!j.county_fips) continue;
    const arr = byCounty.get(j.county_fips) ?? [];
    arr.push(j);
    byCounty.set(j.county_fips, arr);
  }
  const countyUnits: Unit[] = [];
  for (const [, list] of byCounty) {
    const populated = list.filter((j) => j.populated);
    const started = populated.length > 0;
    const depth = populated.length > 0 ? populated.reduce((s, j) => s + j.score, 0) / populated.length : 0;
    countyUnits.push({ started, depth });
  }
  // Use aggregateUnits only for depth — breadth is overridden below using the
  // true county count so that states with an incomplete geofence universe (e.g.
  // Indiana with only Monroe County loaded) don't read as fully broad.
  const { depth } = aggregateUnits(countyUnits);
  const countiesStarted = countyUnits.filter((u) => u.started).length;
  const counties = jur.filter((j) => j.level === 'county');
  const countiesTotal = US_COUNTY_COUNTS[stateFips] || counties.length;
  const breadth = countiesTotal > 0 ? Math.min(1, countiesStarted / countiesTotal) : 0;

  const cities = jur.filter((j) => j.level === 'local');
  const schools = jur.filter((j) => j.level === 'school');

  // Depth summary over ALL populated units (state-wide), as percentages.
  const populated = jur.filter((j) => j.populated);
  const sum = (sel: (j: JurisdictionScore) => number) => populated.reduce((s, j) => s + sel(j), 0);
  const photoPart = sum((j) => j.headshots.withPhoto);
  const photoTotal = sum((j) => j.headshots.total);
  const stancePart = sum((j) => j.stances.researched);
  const stanceTotal = sum((j) => j.stances.total);
  const rosterActual = sum((j) => (j.expected_seats != null ? j.roster_actual : 0));
  const rosterExpected = sum((j) => j.expected_seats ?? 0);
  const pct = (part: number, total: number) => (total > 0 ? Math.round((part / total) * 1000) / 10 : 0);

  return {
    breadth,
    depth,
    counties_started: countiesStarted,
    counties_total: countiesTotal,
    cities_started: cities.filter((c) => c.populated).length,
    cities_total: cities.length,
    schools_started: schools.filter((s) => s.populated).length,
    schools_total: schools.length,
    roster_pct: pct(Math.min(rosterActual, rosterExpected), rosterExpected),
    stances_pct: pct(stancePart, stanceTotal),
    photo_pct: pct(photoPart, photoTotal),
  };
}

/**
 * How many states may be built at once by getStateScores.
 *
 * The states are independent, so building them one at a time made the cold load the SUM of every
 * state's cost — 24.7 s for 13 states, which overran the 30 s statement timeout and returned a 500.
 * Nearly all of it is the PostGIS child→county assignment in buildJurisdictions (16.2 s of the 24.7,
 * CA alone 5.8 s); statsByJurisdiction is only 1.5 s across all 13.
 *
 * Deliberately NOT unbounded. `pool` is `max: 10` and shared with every other API request, so
 * fanning out 13 states x 4 queries would saturate the pool and starve live traffic for the whole
 * cold build. 4 keeps the majority of the win — wall clock falls to roughly the slowest single state
 * — while leaving connections free.
 *
 * The faster path would be to stop recomputing the child→county mapping at all (it only changes when
 * boundaries are reloaded), but that needs somewhere to persist it. Rewriting the spatial query was
 * tried and rejected: a DISTINCT ON spatial join is only ~20% faster and CHANGED the county assigned
 * in ca/in/or/ut/wi, because area ties (a child merely touching a neighbouring county intersects it
 * with area 0) resolve differently than the correlated `ORDER BY ... LIMIT 1`. Not worth 20%.
 */
const STATE_BUILD_CONCURRENCY = 4;

/**
 * Map over `items` with at most `limit` concurrent workers, preserving INPUT ORDER in the result.
 * Order matters here: the choropleth list is rendered in listCoverageStates() order.
 */
async function mapWithConcurrency<T, R>(
  items: readonly T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const out = new Array<R>(items.length);
  let next = 0;
  const worker = async (): Promise<void> => {
    for (;;) {
      const i = next++;
      if (i >= items.length) return;
      out[i] = await fn(items[i]!, i);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return out;
}

/**
 * US choropleth: one entry per state/territory — ALL 56, not just the tracked
 * ones. Tracked states (a coverage YAML exists) carry the local-government
 * composite `score`; untracked states carry `score: null` and zeroed local
 * fields. EVERY state carries the live `federal` block, because federal + state
 * offices are covered everywhere regardless of YAML tracking — omitting the
 * untracked states painted them "not started" when e.g. their full congressional
 * delegation is loaded.
 */
export async function getStateScores(
  opts: { refresh?: boolean; weights?: AxisWeights } = {},
): Promise<StateScore[]> {
  const weights = opts.weights ?? DEFAULT_WEIGHTS;
  return cached('us', !!opts.refresh, async () => {
    // Resolve the YAML synchronously first so the concurrent section is pure DB work, and so
    // states without a state_fips are dropped BEFORE the ordered map (keeping index alignment).
    const tracked = listCoverageStates()
      .map((code) => ({ code, file: readCoverageFile(code) }))
      .filter((t): t is { code: string; file: ReturnType<typeof readCoverageFile> & { universe: { state_fips: string } } } =>
        Boolean(t.file.universe?.state_fips));

    const [federalByCode, trackedScores] = await Promise.all([
      getFederalStateStats(),
      mapWithConcurrency(tracked, STATE_BUILD_CONCURRENCY, async ({ code, file }) => {
        const fips = file.universe.state_fips;
        const jur = await buildJurisdictions(fips, code, weights);
        return {
          fips,
          code,
          name: file.state_name,
          score: mean(jur.map((j) => j.score)),
          jurisdiction_count: jur.length,
          populated_count: jur.filter((j) => j.populated).length,
          ...stateBreakdown(jur, fips),
        };
      }),
    ]);

    const trackedByCode = new Map(trackedScores.map((s) => [s.code, s]));
    // ALL_STATES order (FIPS order) — the frontend keys by fips and sorts itself.
    return ALL_STATES.map((meta): StateScore => {
      const federal = federalByCode.get(meta.code)!;
      const t = trackedByCode.get(meta.code);
      if (t) return { ...t, tracked: true, federal };
      return {
        fips: meta.fips,
        code: meta.code,
        name: meta.name,
        tracked: false,
        score: null,
        federal,
        jurisdiction_count: 0,
        populated_count: 0,
        breadth: 0,
        depth: 0,
        counties_started: 0,
        counties_total: US_COUNTY_COUNTS[meta.fips] ?? 0,
        cities_started: 0,
        cities_total: 0,
        schools_started: 0,
        schools_total: 0,
        roster_pct: 0,
        stances_pct: 0,
        photo_pct: 0,
      };
    });
  });
}
