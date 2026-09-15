#!/usr/bin/env -S npx tsx
/**
 * load-mn-county-commissioner-boundaries.ts
 *
 * Fetches the St. Louis and Ramsey county commissioner-district boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='st-louis-mn-commissioner-district-1'..'-7', mtfcc='X0054'
 *   essentials.geofence_boundaries  geo_id='ramsey-mn-commissioner-district-1'..'-7',   mtfcc='X0055'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0111 creates the districts and their offices
 * and REFUSES TO RUN if these fourteen boundaries are absent -- an office on a district with no
 * polygon is unreachable by any address, and nothing errors.
 *
 * Wave MN-4 of the Knight Foundation cities program.
 * Sources: backend/data/seed-mn-counties-2026/SOURCES.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 *   npx tsx scripts/load-mn-county-commissioner-boundaries.ts --control
 *   npx tsx scripts/load-mn-county-commissioner-boundaries.ts --dry-run
 *   npx tsx scripts/load-mn-county-commissioner-boundaries.ts
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 A SINGLE PERCENTAGE IS NOT A GATE, AND MN-3's NUMBER WOULD REFUSE A CORRECT MAP.
 *
 * MN-3 gated Duluth and Saint Paul at `minCoverPct: 99.9`, which is what caught Duluth's
 * superseded 2012 map at 89.176%. Copying that number here would make this loader REFUSE
 * St. Louis County, whose layer is right:
 *
 *   Ramsey      170.013 / 170.013 sq mi   100.000%   its seven districts tile the county exactly
 *   St. Louis  6738.734 / 6860.543 sq mi    98.220%   and it is CORRECT
 *
 * A fresh session reusing MN-3's template without measuring first would most likely have
 * concluded it had the wrong map, which is the opposite of the truth. What separates 98.220%
 * from Duluth's 89.176% is not the number. It is WHERE THE GAP IS:
 *
 *   924 pieces, 122.149 sq mi      912 of them under 0.01 sq mi -- two agencies' line work
 *   largest piece 120.593 sq mi    98.7% of the whole gap, interior point (-91.8825, 46.8566)
 *                                  no incorporated place contains that point; nearest is Duluth,
 *                                  3.98 km away; it is 6.60 km inside the county's lake boundary
 *   second piece    1.159 sq mi    at (-92.4281, 48.3010), on the northern water boundary
 *
 * So the gap is an EDGE WEDGE OF LAKE SUPERIOR plus slivers, not an interior hole, and no
 * inhabited land is uncovered. ⚠ Minnesota's own legislative districts DO cover that water --
 * the point falls inside SD-8 and HD-8B. Two agencies disagree about how far to draw into the
 * lake. That is a fact about line work, not evidence the county layer is stale.
 *
 * ▶ So St. Louis gets the FORT WAYNE gate -- bound the gap and explain it -- and Ramsey, which
 *   genuinely tiles, keeps the strict one. They are different gates on purpose.
 *
 * 🔴 AND THE GATE THAT ACTUALLY ANSWERS THE QUESTION IS NEITHER OF THEM. GATE 3P asks the
 * reachability question directly: every incorporated place inside the county must have its
 * interior point in EXACTLY ONE commissioner district. 27 places in St. Louis, 15 in Ramsey,
 * 42 assertions, and it is immune to the water overhang that makes the area ratios argue.
 *
 * ⚠ AREA RATIOS MISLEAD HERE IN BOTH DIRECTIONS, WHICH IS WHY THEY ARE NOT THE MAIN GATE.
 * Duluth's place polygon is only 96.077% covered by these districts -- because Duluth's own
 * polygon overhangs Lake Superior. White Bear Lake is 99.118% covered by Ramsey's -- because
 * the city straddles the Washington County line. Both are correct. Neither is a defect.
 *
 * 🟢 BOTH LAYERS CARRY A POPULATED ROSTER FIELD, so the MN-3 vintage test is available for both.
 * Fort Wayne's FW_Council_Rep was empty and the test was unavailable there.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. The roster that reaches the database comes from
 * each county's board page and its 19 individual officer pages, per data/mn-counties-roster.json.
 * GATE 2 uses the layer's names only as a VINTAGE TEST.
 *
 * ⚠ RAMSEY'S BOARD PAGE WRITES "Rafael E. Ortega" AND ITS GIS LAYER WRITES "Rafael Ortega", so
 * GATE 2 compares with single-letter tokens dropped. That tolerance is itself controlled: a
 * DIFFERENT middle name is not a middle initial, and the control proves the gate still refuses it.
 *
 * ⚠ RAMSEY'S GIS HOST MOVED. MN-1 recorded an `OpenData/OpenData` MapServer but not its host;
 * `gis.ramseycounty.us` no longer resolves. The 404 that found this was about the PATH, not the
 * host -- this server publishes under /server/rest/services, not /arcgis/rest/services. The layer
 * index is 25, not 0, and a request for /0 returns an empty object rather than an error.
 */
import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'mn-counties-roster.json');
const DRY = process.argv.includes('--dry-run');

/** Bound-and-explain, for a county whose polygon includes its share of a Great Lake. */
type BoundedCoverage = {
  mode: 'bounded';
  /** Backstop only. The decomposition below is what decides it. */
  minPct: number;
  /** Below this, a gap piece is two agencies' line work, not a hole. */
  sliverSqMi: number;
  /** How many pieces may exceed that, each of which must then be explained. */
  maxMajorPieces: number;
  /** The whole gap, as a share of the county. */
  maxGapPct: number;
};
/** For a county whose districts genuinely tile it. */
type StrictCoverage = { mode: 'strict'; minPct: number };

type County = {
  key: string;
  county: string;
  mtfcc: string;
  countyGeoId: string;
  expected: number;
  slug: (n: number) => string;
  label: (n: number) => string;
  url: string;
  numberField: string;
  nameField: string;
  coverage: BoundedCoverage | StrictCoverage;
  /** How many incorporated places sit inside this county. GATE 3P is blind if this is 0. */
  expectedPlaces: number;
  /**
   * 🔴 GATE 4's tolerance is MEASURED PER COUNTY, not copied. Two agencies' line work leaves
   * sliver overlaps along a shared boundary exactly as it leaves sliver gaps, and a county 40x
   * the area has 40x the boundary to leave them on. MN-3's flat 0.001 sq mi refuses St. Louis's
   * correct layer. A genuine double-assignment is orders of magnitude bigger than either number.
   */
  maxOverlapSqMi: number;
  maxOverlapPairSqMi: number;
  /** The place whose interior point the --control removes, to prove GATE 3/3P discriminate. */
  controlPlace: { name: string; district: number };
};

const COUNTIES: County[] = [
  {
    key: 'st-louis',
    county: 'St. Louis',
    mtfcc: 'X0054',
    countyGeoId: '27137',
    expected: 7,
    slug: (n) => `st-louis-mn-commissioner-district-${n}`,
    label: (n) => `St. Louis County Commissioner District ${n}`,
    url:
      'https://gis.stlouiscountymn.gov/server2/rest/services/GeneralUse/Open_Data/MapServer/21/query' +
      '?where=1%3D1&outFields=DISTRICTID,REPNAME1&returnGeometry=true&outSR=4326&f=geojson',
    numberField: 'DISTRICTID',
    nameField: 'REPNAME1',
    // 🔴 NOT 99.9. See the header: 98.220% is correct here, and the decomposition is the gate.
    coverage: { mode: 'bounded', minPct: 97.0, sliverSqMi: 0.5, maxMajorPieces: 2, maxGapPct: 2.5 },
    expectedPlaces: 27,
    // Measured: 11 overlapping pairs totalling 0.022855 sq mi, the largest D4xD6 at 0.018929 --
    // 0.0003% of a 6,860 sq mi county, along boundaries that run for tens of miles.
    maxOverlapSqMi: 0.05,
    maxOverlapPairSqMi: 0.03,
    // ⚠ DULUTH IS IN DISTRICT 3, NOT DISTRICT 1. The first draft of this control removed
    //   district 1 because Duluth is the county's largest city and district 1 reads like the
    //   first one -- and GATE 3P passed, because Duluth's interior point was still covered.
    //   The control proved nothing until the district was MEASURED.
    controlPlace: { name: 'Duluth city', district: 3 },
  },
  {
    key: 'ramsey',
    county: 'Ramsey',
    mtfcc: 'X0055',
    countyGeoId: '27123',
    expected: 7,
    slug: (n) => `ramsey-mn-commissioner-district-${n}`,
    label: (n) => `Ramsey County Commissioner District ${n}`,
    url:
      'https://gis.ramseycountymn.gov/server/rest/services/Boundary/' +
      'BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25/query' +
      '?where=1%3D1&outFields=District,Name&returnGeometry=true&outSR=4326&f=geojson',
    numberField: 'District',
    nameField: 'Name',
    coverage: { mode: 'strict', minPct: 99.9 },
    expectedPlaces: 15,
    // Measured: ZERO overlapping pairs. Ramsey's districts tile the county, so MN-3's strict
    // number is the right one here -- the same number is right for one county and wrong for the other.
    maxOverlapSqMi: 0.001,
    maxOverlapPairSqMi: 0.001,
    // ⚠ SAINT PAUL IS IN DISTRICT 5. District 4 lies wholly inside the city and holds no place
    //   interior point at all, so removing it leaves GATE 3P silent -- correctly.
    controlPlace: { name: 'St. Paul city', district: 5 },
  },
];

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36';

const SOURCE_NOTE: Record<string, string> = {
  'st-louis':
    'St. Louis County GIS, GeneralUse/Open_Data/MapServer/21 "County Commissioner Districts", read 2026-09-15 (MN-4, X0054)',
  ramsey:
    'Ramsey County GIS, Boundary/BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25, read 2026-09-15 (MN-4, X0055)',
};

const SQMI = '/2589988.11';

function fail(msg: string): never {
  console.error(`\n✗ ${msg}`);
  process.exit(1);
}

/**
 * ⚠ Single-letter tokens are dropped so "Rafael E. Ortega" and "Rafael Ortega" compare equal.
 * That is a MIDDLE-INITIAL tolerance and nothing wider: a different given name, surname or
 * spelled-out middle name still differs, and --control proves it.
 */
const normName = (s: unknown) =>
  String(s ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z\- ]/g, '')
    .split(/\s+/)
    .filter((t) => t.length > 1)
    .join(' ')
    .trim();

type Feat = { properties: Record<string, any>; geometry: unknown };

/** 🔴 A CLEAN HTTP 200 CAN CARRY A TRUNCATED OR ERROR BODY. Only a full decode catches it. */
async function fetchFeatures(c: Pick<County, 'county' | 'url'>): Promise<Feat[]> {
  const r = await fetch(c.url, { headers: { 'User-Agent': UA } });
  const raw = await r.text();
  if (r.status !== 200) fail(`${c.county}: HTTP ${r.status} from the district service`);
  let gj: any;
  try {
    gj = JSON.parse(raw);
  } catch {
    fail(`${c.county}: HTTP 200 but the body is not JSON (${raw.length} bytes). ${raw.slice(0, 160)}`);
  }
  if (gj.error) fail(`${c.county}: service returned an error object: ${JSON.stringify(gj.error).slice(0, 200)}`);
  if (!Array.isArray(gj.features)) fail(`${c.county}: HTTP 200 and valid JSON with no features array`);
  return gj.features as Feat[];
}

type Q = (sql: string, params?: unknown[]) => Promise<any[]>;

/** Loads a feature set into a TEMP table `t`. Caller owns the transaction. */
async function loadTemp(q: Q, table: string, feats: Feat[], numberField: string) {
  await q(`CREATE TEMP TABLE ${table}(num int, geom geometry) ON COMMIT DROP`);
  for (const f of feats) {
    await q(
      `INSERT INTO ${table}(num, geom) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326)))`,
      [Number(f.properties[numberField]), JSON.stringify(f.geometry)],
    );
  }
}

// ─── The gates, each a pure predicate over a loaded TEMP table ─────────────────────────────

function gate1(c: County, feats: Feat[]): string | null {
  if (feats.length !== c.expected) return `GATE 1: ${feats.length} features, expected ${c.expected}`;
  const nums = feats.map((f) => Number(f.properties[c.numberField]));
  if (nums.some((n) => !Number.isInteger(n))) return `GATE 1: a district number is not an integer: ${nums}`;
  const wanted = Array.from({ length: c.expected }, (_, i) => i + 1);
  const missing = wanted.filter((n) => !nums.includes(n));
  if (missing.length) return `GATE 1: district(s) ${missing.join(', ')} are missing`;
  if (new Set(nums).size !== c.expected) return `GATE 1: duplicate district numbers in ${nums}`;
  return null;
}

function gate2(c: County, feats: Feat[], roster: Array<Record<string, any>>): string | null {
  const byNum = new Map<number, string>();
  for (const f of feats) byNum.set(Number(f.properties[c.numberField]), String(f.properties[c.nameField] ?? ''));

  const empties = [...byNum.entries()].filter(([, v]) => !v.trim());
  if (empties.length) {
    return (
      `GATE 2: the layer's ${c.nameField} field is EMPTY for district(s) ${empties.map(([k]) => k).join(', ')}. ` +
      `Fort Wayne's FW_Council_Rep was empty too, and a field that looks like a source and holds nothing ` +
      `invites the sentence "the county confirms the roster". It does not. Decide what this means before loading.`
    );
  }
  for (const [n, layerName] of byNum) {
    const want = roster.find((x) => x.county === c.county && x.district_number === n);
    if (!want) return `GATE 2: roster has no ${c.county} district ${n}`;
    if (normName(layerName) !== normName(want.full_name)) {
      return (
        `GATE 2: ${c.county} district ${n} -- layer says "${layerName}", roster says "${want.full_name}". ` +
        `Either the polygons are the wrong vintage or the roster is stale. Settle it before loading.`
      );
    }
  }
  // A field holding ONE value everywhere would agree with anything.
  const distinct = new Set([...byNum.values()].map(normName)).size;
  if (distinct !== c.expected) {
    return `GATE 2: the ${c.nameField} field holds ${distinct} distinct value(s) across ${c.expected} districts -- it does not discriminate`;
  }
  return null;
}

type Cov = { pct: number; gapSqMi: number; countySqMi: number; major: Array<{ sqMi: number; lon: number; lat: number; places: number; which: string | null }>; pieces: number };

async function measureCoverage(q: Q, table: string, c: County): Promise<Cov> {
  const sliver = c.coverage.mode === 'bounded' ? c.coverage.sliverSqMi : 0.5;
  const [a] = await q(
    `WITH u AS (SELECT ST_Union(geom) g FROM ${table}),
          co AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4020')
     SELECT round((100*ST_Area(ST_Intersection(co.g,u.g)::geography)/ST_Area(co.g::geography))::numeric,3) AS pct,
            round((ST_Area(ST_Difference(co.g,u.g)::geography)${SQMI})::numeric,3) AS gap_sq_mi,
            round((ST_Area(co.g::geography)${SQMI})::numeric,3) AS county_sq_mi
       FROM u, co`,
    [c.countyGeoId],
  );
  if (!a) fail(`${c.county}: county polygon ${c.countyGeoId}/G4020 is missing`);

  const [n] = await q(
    `WITH u AS (SELECT ST_Union(geom) g FROM ${table}),
          co AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4020'),
          gap AS (SELECT (ST_Dump(ST_Difference(co.g,u.g))).geom AS g FROM u,co)
     SELECT count(*) AS pieces FROM gap`,
    [c.countyGeoId],
  );

  const major = await q(
    `WITH u AS (SELECT ST_Union(geom) g FROM ${table}),
          co AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4020'),
          gap AS (SELECT (ST_Dump(ST_Difference(co.g,u.g))).geom AS g FROM u,co),
          big AS (SELECT g, ST_Area(g::geography)${SQMI} AS sq_mi FROM gap WHERE ST_Area(g::geography)${SQMI} > $2)
     SELECT round(sq_mi::numeric,3) AS sq_mi,
            round(ST_X(ST_PointOnSurface(g))::numeric,4) AS lon,
            round(ST_Y(ST_PointOnSurface(g))::numeric,4) AS lat,
            -- ⚠ CONTAINS THE PLACE'S INTERIOR POINT, not ST_Intersects. Duluth's own polygon
            --   overhangs Lake Superior, so it INTERSECTS the wedge while sitting on land.
            (SELECT count(*) FROM essentials.geofence_boundaries pl
              WHERE pl.mtfcc='G4110' AND pl.state='27'
                AND ST_Contains(big.g, ST_PointOnSurface(ST_MakeValid(pl.geometry)))) AS places,
            (SELECT string_agg(pl.name, ', ') FROM essentials.geofence_boundaries pl
              WHERE pl.mtfcc='G4110' AND pl.state='27'
                AND ST_Contains(big.g, ST_PointOnSurface(ST_MakeValid(pl.geometry)))) AS which
       FROM big ORDER BY sq_mi DESC`,
    [c.countyGeoId, sliver],
  );

  return {
    pct: Number(a.pct),
    gapSqMi: Number(a.gap_sq_mi),
    countySqMi: Number(a.county_sq_mi),
    pieces: Number(n.pieces),
    major: major.map((m) => ({ sqMi: Number(m.sq_mi), lon: Number(m.lon), lat: Number(m.lat), places: Number(m.places), which: m.which })),
  };
}

function gate3(c: County, cov: Cov): string | null {
  const cv = c.coverage;
  if (cv.mode === 'strict') {
    if (cov.pct < cv.minPct) {
      return (
        `GATE 3 (strict): the districts cover only ${cov.pct}% of ${c.county} County, below ${cv.minPct}%, ` +
        `leaving ${cov.gapSqMi} sq mi with no commissioner. ${c.county}'s districts tile the county, so ` +
        `anything short of that is a defect, not a lake.`
      );
    }
    return null;
  }
  // bounded: the percentage is a backstop; the decomposition decides.
  if (cov.pct < cv.minPct) {
    return `GATE 3 (bounded): coverage ${cov.pct}% is below even the backstop ${cv.minPct}% -- this is not an edge wedge`;
  }
  const gapPct = (100 * cov.gapSqMi) / cov.countySqMi;
  if (gapPct > cv.maxGapPct) {
    return `GATE 3 (bounded): the gap is ${gapPct.toFixed(3)}% of the county, above ${cv.maxGapPct}%`;
  }
  if (cov.major.length > cv.maxMajorPieces) {
    return (
      `GATE 3 (bounded): the gap breaks into ${cov.major.length} piece(s) over ${cv.sliverSqMi} sq mi, ` +
      `above the ${cv.maxMajorPieces} this county is allowed. An edge wedge is one piece; several pieces ` +
      `are holes. Largest: ${cov.major.slice(0, 4).map((m) => `${m.sqMi} sq mi at (${m.lon}, ${m.lat})`).join(' · ')}`
    );
  }
  const inhabited = cov.major.filter((m) => m.places > 0);
  if (inhabited.length) {
    return (
      `GATE 3 (bounded): a major gap piece CONTAINS an incorporated place -- ` +
      inhabited.map((m) => `${m.sqMi} sq mi holds ${m.which}`).join(' · ') +
      `. An address there would return no commissioner and nothing would error.`
    );
  }
  return null;
}

/**
 * 🔴 THE GATE THAT ANSWERS THE ACTUAL QUESTION. Immune to water overhang and to a city that
 * straddles the county line, because it tests a point rather than an area ratio.
 * Carries its own positive control: a place set of the wrong size means the detector is blind.
 */
async function gate3p(q: Q, table: string, c: County): Promise<string | null> {
  const rows = await q(
    `WITH co AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4020'),
          pl AS (SELECT b.name, ST_PointOnSurface(ST_MakeValid(b.geometry)) pt
                   FROM essentials.geofence_boundaries b, co
                  WHERE b.mtfcc='G4110' AND b.state='27'
                    AND ST_Contains(co.g, ST_PointOnSurface(ST_MakeValid(b.geometry))))
     SELECT pl.name, (SELECT count(*) FROM ${table} d WHERE ST_Contains(d.geom, pl.pt)) AS n
       FROM pl ORDER BY n, pl.name`,
    [c.countyGeoId],
  );
  if (rows.length !== c.expectedPlaces) {
    return (
      `GATE 3P is BLIND or the place layer moved: ${rows.length} incorporated place(s) found inside ` +
      `${c.county} County, expected ${c.expectedPlaces}. A zero here would pass every district trivially. ` +
      `TIGERweb layer 0 is "Estates" and returns count:0 for Minnesota -- a true answer to the wrong question.`
    );
  }
  const bad = rows.filter((r) => Number(r.n) !== 1);
  if (bad.length) {
    return (
      `GATE 3P: ${bad.length} of ${rows.length} incorporated place(s) in ${c.county} County do NOT sit in ` +
      `exactly one commissioner district: ` +
      bad.slice(0, 8).map((b) => `${b.name}=${b.n}`).join(', ')
    );
  }
  return null;
}

/** The measurement is kept alongside the verdict: "no overlapping pairs" and "11 pairs of
 *  line-work noise, under tolerance" are different facts and only one of them is true here. */
let lastOverlap = { pairs: 0, sqMi: 0, worst: 0 };

async function gate4(q: Q, table: string, c: County): Promise<string | null> {
  const [ov] = await q(
    `SELECT count(*) AS pairs,
            round((COALESCE(sum(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)${SQMI})::numeric,6) AS sq_mi,
            round((COALESCE(max(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)${SQMI})::numeric,6) AS worst_sq_mi
       FROM ${table} a JOIN ${table} b ON b.num > a.num AND ST_Overlaps(a.geom,b.geom)`,
  );
  lastOverlap = { pairs: Number(ov.pairs), sqMi: Number(ov.sq_mi), worst: Number(ov.worst_sq_mi) };
  // A district pair claiming real ground is one big overlap, not many tiny ones. Both are tested.
  if (Number(ov.worst_sq_mi) > c.maxOverlapPairSqMi) {
    return (
      `GATE 4: a single ${c.county} district pair overlaps by ${ov.worst_sq_mi} sq mi, above ${c.maxOverlapPairSqMi}. ` +
      `That is ground two commissioners both claim, not line-work noise.`
    );
  }
  if (Number(ov.sq_mi) > c.maxOverlapSqMi) {
    return (
      `GATE 4: ${ov.pairs} overlapping ${c.county} district pair(s) covering ${ov.sq_mi} sq mi in total, ` +
      `above ${c.maxOverlapSqMi}`
    );
  }
  return null;
}

// ─── Controls ──────────────────────────────────────────────────────────────────────────────

/**
 * 🔴 A GATE THAT HAS NEVER BEEN SEEN TO FAIL IS NOT A GATE, and MN-3 learned the sharper half:
 * A CONTROL THAT ABORTS FOR THE WRONG REASON PROVES NOTHING. Two of MN-3's controls planted
 * something other than what they claimed and both looked like passes. So every control below
 * ASSERTS WHAT IT PLANTED before the gate is allowed to judge it.
 */
async function controls() {
  const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster as Array<Record<string, any>>;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q: Q = async (sql, params = []) => (await pool.query(sql, params)).rows;

  let planted = 0;
  let passed = 0;
  let failed = 0;

  const plant = (what: string, ok: boolean, detail: string) => {
    planted++;
    if (!ok) {
      console.log(`  ✗ PLANT  ${what.padEnd(46)} ${detail}`);
      fail(`the control did not plant what it claims (${what}); its verdict would prove nothing`);
    }
    console.log(`  plant    ${what.padEnd(46)} ${detail}`);
  };
  const expectRefusal = (what: string, verdict: string | null) => {
    if (verdict) {
      passed++;
      console.log(`  ✓ REFUSED ${what.padEnd(45)} ${verdict.slice(0, 150)}`);
    } else {
      failed++;
      console.log(`  ✗ PASSED  ${what.padEnd(45)} the gate did not refuse a deliberately wrong input`);
    }
  };
  const expectPass = (what: string, verdict: string | null) => {
    if (!verdict) {
      passed++;
      console.log(`  ✓ PASSED  ${what.padEnd(45)} as it must`);
    } else {
      failed++;
      console.log(`  ✗ REFUSED ${what.padEnd(45)} ${verdict.slice(0, 150)}`);
    }
  };

  const slc = COUNTIES[0];
  const ram = COUNTIES[1];
  const slcFeats = await fetchFeatures(slc);
  const ramFeats = await fetchFeatures(ram);
  const clone = (f: Feat[]) => JSON.parse(JSON.stringify(f)) as Feat[];

  console.log('\n══ GATE 1 ═══════════════════════════════════════════════════════════════════');
  {
    const short = clone(slcFeats).slice(1);
    plant('a district removed', short.length === slcFeats.length - 1, `${slcFeats.length} -> ${short.length} features`);
    expectRefusal('GATE 1 on a short district set', gate1(slc, short));
  }
  {
    const dup = clone(slcFeats);
    dup[1].properties[slc.numberField] = dup[0].properties[slc.numberField];
    plant('two districts share a number', dup[1].properties[slc.numberField] === dup[0].properties[slc.numberField],
      `district ${dup[1].properties[slc.numberField]} appears twice`);
    expectRefusal('GATE 1 on a duplicate number', gate1(slc, dup));
  }
  expectPass('GATE 1 on the live St. Louis layer', gate1(slc, slcFeats));
  expectPass('GATE 1 on the live Ramsey layer', gate1(ram, ramFeats));

  console.log('\n══ GATE 2 ═══════════════════════════════════════════════════════════════════');
  {
    const renamed = clone(slcFeats);
    const was = String(renamed[0].properties[slc.nameField]);
    renamed[0].properties[slc.nameField] = 'Zzz Control';
    plant('a commissioner renamed', renamed[0].properties[slc.nameField] === 'Zzz Control' && was !== 'Zzz Control',
      `"${was}" -> "Zzz Control" on district ${renamed[0].properties[slc.numberField]}`);
    expectRefusal('GATE 2 on a renamed commissioner', gate2(slc, renamed, roster));
  }
  {
    const uniform = clone(slcFeats);
    for (const f of uniform) f.properties[slc.nameField] = 'Same Person';
    const distinct = new Set(uniform.map((f) => f.properties[slc.nameField])).size;
    plant('one name on every district', distinct === 1, `${distinct} distinct value across ${uniform.length} districts`);
    expectRefusal('GATE 2 when the field discriminates nothing', gate2(slc, uniform, roster));
  }
  {
    const blank = clone(ramFeats);
    blank[2].properties[ram.nameField] = '';
    plant('a roster field emptied', blank[2].properties[ram.nameField] === '', `district ${blank[2].properties[ram.numberField]} now blank`);
    expectRefusal('GATE 2 on an empty roster field', gate2(ram, blank, roster));
  }
  {
    // 🟢 The middle-initial tolerance must be a tolerance and not a blanket pass.
    const ortega = ramFeats.find((f) => normName(f.properties[ram.nameField]).endsWith('ortega'));
    plant('Ramsey ships a middle-initial variance', !!ortega && String(ortega.properties[ram.nameField]) === 'Rafael Ortega',
      `layer "Rafael Ortega" vs roster "Rafael E. Ortega"`);
    expectPass('GATE 2 tolerates a dropped middle initial', gate2(ram, ramFeats, roster));

    const wrongMiddle = clone(ramFeats);
    const i = wrongMiddle.findIndex((f) => normName(f.properties[ram.nameField]).endsWith('ortega'));
    wrongMiddle[i].properties[ram.nameField] = 'Rafael Quentin Ortego';
    plant('a DIFFERENT name, not an initial', wrongMiddle[i].properties[ram.nameField] === 'Rafael Quentin Ortego',
      `"Rafael Ortega" -> "Rafael Quentin Ortego"`);
    expectRefusal('GATE 2 still refuses a spelled-out change', gate2(ram, wrongMiddle, roster));
  }
  expectPass('GATE 2 on the live St. Louis layer', gate2(slc, slcFeats, roster));

  console.log('\n══ GATE 3 / 3P / 4 ══════════════════════════════════════════════════════════');
  {
    // 🔴🔴 THE ONE THAT MATTERS. Remove the district holding the county's largest city: the gap
    //     gains a major piece that CONTAINS an incorporated place, which is the shape a stale map
    //     has. ⚠ THE FIRST DRAFT REMOVED DISTRICT 1 AND BOTH GATES PASSED -- Duluth is in
    //     DISTRICT 3. The control asserts the place is really orphaned before it judges anything.
    await q('BEGIN');
    await q(`SET LOCAL statement_timeout = '300s'`);
    const cp = slc.controlPlace;
    const holed = clone(slcFeats).filter((f) => Number(f.properties[slc.numberField]) !== cp.district);
    await loadTemp(q, 'ctl_holed', holed, slc.numberField);
    const [orphan] = await q(
      `SELECT (SELECT count(*) FROM ctl_holed d WHERE ST_Contains(d.geom, ST_PointOnSurface(ST_MakeValid(pl.geometry)))) AS n
         FROM essentials.geofence_boundaries pl WHERE pl.mtfcc='G4110' AND pl.state='27' AND pl.name=$1`,
      [cp.name],
    );
    plant(`St. Louis district ${cp.district} removed, orphaning ${cp.name}`,
      holed.length === slcFeats.length - 1 && Number(orphan.n) === 0,
      `${slcFeats.length} -> ${holed.length} districts; ${cp.name} now in ${orphan.n} district(s)`);
    const covHoled = await measureCoverage(q, 'ctl_holed', slc);
    console.log(`           holed coverage ${covHoled.pct}%, gap ${covHoled.gapSqMi} sq mi in ${covHoled.pieces} piece(s), ${covHoled.major.length} major`);
    expectRefusal(`GATE 3 (bounded) on a hole over ${cp.name}`, gate3(slc, covHoled));
    expectRefusal(`GATE 3P on a hole over ${cp.name}`, await gate3p(q, 'ctl_holed', slc));
    await q('ROLLBACK');
  }
  {
    // Ramsey's districts against St. Louis County: coverage collapses.
    await q('BEGIN');
    await q(`SET LOCAL statement_timeout = '300s'`);
    await loadTemp(q, 'ctl_wrong', ramFeats, ram.numberField);
    const [chk] = await q(`SELECT count(*) n FROM ctl_wrong`);
    plant("Ramsey's polygons against St. Louis County", Number(chk.n) === ram.expected, `${chk.n} Ramsey districts loaded`);
    const covWrong = await measureCoverage(q, 'ctl_wrong', slc);
    console.log(`           wrong-county coverage ${covWrong.pct}%`);
    expectRefusal('GATE 3 (bounded) on the wrong county', gate3(slc, covWrong));
    expectRefusal('GATE 3P on the wrong county', await gate3p(q, 'ctl_wrong', slc));
    await q('ROLLBACK');
  }
  {
    // Ramsey tiles, so its STRICT gate must refuse what St. Louis's bounded one tolerates.
    await q('BEGIN');
    await q(`SET LOCAL statement_timeout = '300s'`);
    // ⚠ DISTRICT 5, not 4. District 4 lies wholly inside Saint Paul and holds no place interior
    //   point, so removing it leaves GATE 3P correctly silent -- and a control that plants
    //   nothing GATE 3P can see proves nothing about GATE 3P.
    const rcp = ram.controlPlace;
    const short = clone(ramFeats).filter((f) => Number(f.properties[ram.numberField]) !== rcp.district);
    await loadTemp(q, 'ctl_ram', short, ram.numberField);
    const [rOrphan] = await q(
      `SELECT (SELECT count(*) FROM ctl_ram d WHERE ST_Contains(d.geom, ST_PointOnSurface(ST_MakeValid(pl.geometry)))) AS n
         FROM essentials.geofence_boundaries pl WHERE pl.mtfcc='G4110' AND pl.state='27' AND pl.name=$1`,
      [rcp.name],
    );
    plant(`Ramsey district ${rcp.district} removed, orphaning ${rcp.name}`,
      short.length === ram.expected - 1 && Number(rOrphan.n) === 0,
      `${ram.expected} -> ${short.length} districts; ${rcp.name} now in ${rOrphan.n} district(s)`);
    const covRam = await measureCoverage(q, 'ctl_ram', ram);
    console.log(`           Ramsey holed coverage ${covRam.pct}%`);
    expectRefusal('GATE 3 (strict) on a holed Ramsey', gate3(ram, covRam));
    expectRefusal('GATE 3P on a holed Ramsey', await gate3p(q, 'ctl_ram', ram));
    await q('ROLLBACK');
  }
  {
    // GATE 4 for BOTH counties. 🔴 St. Louis's tolerance is 50x Ramsey's because its layer
    // genuinely self-overlaps by 0.0229 sq mi of line-work slivers, so the looser number has to
    // be shown still refusing ground two commissioners both claim.
    for (const [c, feats] of [[slc, slcFeats], [ram, ramFeats]] as Array<[County, Feat[]]>) {
      await q('BEGIN');
      await q(`SET LOCAL statement_timeout = '300s'`);
      await loadTemp(q, 'ctl_ov', feats, c.numberField);
      const [before] = await q(
        `SELECT count(*) AS pairs, round((COALESCE(max(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)${SQMI})::numeric,6) AS worst
           FROM ctl_ov a JOIN ctl_ov b ON b.num > a.num AND ST_Overlaps(a.geom,b.geom)`);
      await q(`UPDATE ctl_ov SET geom = (SELECT ST_Buffer(geom, 0.01) FROM ctl_ov WHERE num = 1) WHERE num = 7`);
      const [after] = await q(
        `SELECT count(*) AS pairs, round((COALESCE(max(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)${SQMI})::numeric,6) AS worst
           FROM ctl_ov a JOIN ctl_ov b ON b.num > a.num AND ST_Overlaps(a.geom,b.geom)`);
      plant(`${c.county}: district 7 made to overlap district 1`,
        Number(after.worst) > Number(before.worst) && Number(after.worst) > c.maxOverlapPairSqMi,
        `worst pair ${before.worst} -> ${after.worst} sq mi (threshold ${c.maxOverlapPairSqMi})`);
      expectRefusal(`GATE 4 on overlapping ${c.county} districts`, await gate4(q, 'ctl_ov', c));
      await q('ROLLBACK');
    }
  }
  {
    // 🟢 THE POSITIVE HALF. Both live layers must pass every gate they are judged by.
    for (const [c, feats] of [[slc, slcFeats], [ram, ramFeats]] as Array<[County, Feat[]]>) {
      await q('BEGIN');
      await q(`SET LOCAL statement_timeout = '300s'`);
      await loadTemp(q, 'ctl_live', feats, c.numberField);
      const cov = await measureCoverage(q, 'ctl_live', c);
      console.log(`  live     ${c.county.padEnd(46)} ${cov.pct}% covered, gap ${cov.gapSqMi} sq mi in ${cov.pieces} piece(s), ${cov.major.length} major`);
      for (const m of cov.major) console.log(`             major piece ${m.sqMi} sq mi at (${m.lon}, ${m.lat}), ${m.places} incorporated place(s) inside`);
      expectPass(`GATE 3 on the live ${c.county} layer`, gate3(c, cov));
      expectPass(`GATE 3P on the live ${c.county} layer`, await gate3p(q, 'ctl_live', c));
      expectPass(`GATE 4 on the live ${c.county} layer`, await gate4(q, 'ctl_live', c));
      await q('ROLLBACK');
    }
  }

  console.log(`\n${planted} control(s) planted and asserted · ${passed} gate verdict(s) correct · ${failed} wrong`);
  await pool.end();
  if (failed) fail(`${failed} gate(s) did not behave as required`);
}

// ─── Main ──────────────────────────────────────────────────────────────────────────────────

async function main() {
  const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster as Array<Record<string, any>>;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q: Q = async (sql, params = []) => (await pool.query(sql, params)).rows;

  for (const c of COUNTIES) {
    console.log(`\n=== ${c.county} County (${c.mtfcc}) ===`);
    const feats = await fetchFeatures(c);

    const g1 = gate1(c, feats);
    if (g1) fail(`${c.county} ${g1}`);
    console.log(`  GATE 1 ✓ ${c.expected} districts, numbered 1..${c.expected}`);

    const g2 = gate2(c, feats, roster);
    if (g2) fail(`${c.county} ${g2}`);
    console.log(`  GATE 2 ✓ all ${c.expected} layer names match the verified roster, all distinct`);

    await q('BEGIN');
    await q(`SET LOCAL statement_timeout = '300s'`);
    await loadTemp(q, 'mn_geom', feats, c.numberField);

    const cov = await measureCoverage(q, 'mn_geom', c);
    console.log(
      `  GATE 3   ${cov.pct}% of the county covered, gap ${cov.gapSqMi} sq mi in ${cov.pieces} piece(s) ` +
        `(${c.coverage.mode} gate)`,
    );
    for (const m of cov.major) {
      console.log(`             major piece ${m.sqMi} sq mi at (${m.lon}, ${m.lat}) -- ${m.places} incorporated place(s) inside${m.which ? `: ${m.which}` : ''}`);
    }
    const g3 = gate3(c, cov);
    if (g3) {
      await q('ROLLBACK');
      fail(`${c.county} ${g3}`);
    }
    console.log(`  GATE 3 ✓`);

    const g3p = await gate3p(q, 'mn_geom', c);
    if (g3p) {
      await q('ROLLBACK');
      fail(`${c.county} ${g3p}`);
    }
    console.log(`  GATE 3P ✓ all ${c.expectedPlaces} incorporated places sit in exactly one district`);

    const g4 = await gate4(q, 'mn_geom', c);
    if (g4) {
      await q('ROLLBACK');
      fail(`${c.county} ${g4}`);
    }
    console.log(
      `  GATE 4 ✓ ${lastOverlap.pairs} overlapping pair(s), ${lastOverlap.sqMi} sq mi total, ` +
        `worst ${lastOverlap.worst} (tolerance ${c.maxOverlapPairSqMi} per pair / ${c.maxOverlapSqMi} total)`,
    );

    if (DRY) {
      await q('ROLLBACK');
      console.log(`  --dry-run: ${feats.length} feature(s) gated, no write`);
      continue;
    }

    // ⚠ Written one row at a time from c.slug()/c.label(), so the geo_id CC_0111 joins on is the
    //   one this file spells rather than one a SQL expression reconstructs.
    let insertedN = 0;
    for (const f of feats) {
      const n = Number(f.properties[c.numberField]);
      const rows = await q(
        `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
         SELECT $1, $2, '27', $3, geom, $4, now() FROM mn_geom WHERE num = $5
         ON CONFLICT (geo_id, mtfcc) DO NOTHING
         RETURNING geo_id`,
        [c.slug(n), c.label(n), c.mtfcc, SOURCE_NOTE[c.key], n],
      );
      insertedN += rows.length;
    }
    console.log(`  inserted ${insertedN} boundary row(s)`);

    const [after] = await q(`SELECT count(*) AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [c.mtfcc]);
    if (Number(after.n) !== c.expected) {
      await q('ROLLBACK');
      fail(`${c.county} post-write: ${c.mtfcc} holds ${after.n} rows, expected ${c.expected}`);
    }
    // The slugs must be the ones CC_0111 joins on, letter for letter.
    const [slugs] = await q(
      `SELECT count(*) AS n FROM essentials.geofence_boundaries
        WHERE mtfcc=$1 AND geo_id = ANY($2::text[])`,
      [c.mtfcc, Array.from({ length: c.expected }, (_, i) => c.slug(i + 1))],
    );
    if (Number(slugs.n) !== c.expected) {
      await q('ROLLBACK');
      fail(`${c.county} post-write: only ${slugs.n} of ${c.expected} rows carry the geo_id CC_0111 joins on`);
    }
    await q('COMMIT');
    console.log(`  ✓ ${c.mtfcc} holds ${after.n} boundaries, all on the expected geo_ids`);
  }

  await pool.end();
  console.log(DRY ? '\n--dry-run complete, nothing written.' : '\nDone.');
}

const entry = process.argv.includes('--control') ? controls : main;
entry().catch((e) => fail(e instanceof Error ? e.message : String(e)));
