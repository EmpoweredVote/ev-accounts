/**
 * load-state-tiger-boundaries.ts
 *
 * Generalized state-parameterized TIGER loader. Subsumes load-ca-state-boundaries.ts,
 * load-tx-state-boundaries.ts, load-us-congressional-boundaries.ts (deleted in
 * Phase 130 Commit C). See .planning/phases/130-tiger-generalization-ca-tx-regression-gate/.
 *
 * This file is the SKELETON delivered in 130-03. Per-layer record handling
 * (cd, sldu, sldl, unsd, place, county, cousub, cd119) is wired in 130-04.
 *
 * Usage (after 130-04):
 *   npx tsx scripts/load-state-tiger-boundaries.ts --state CA --fips 06 --layers cd,sldu
 *   npx tsx scripts/load-state-tiger-boundaries.ts --state TX --fips 48 --layers sldu,sldl,county --dry-run
 *
 * Today (130-03): CLI parsing + allowlist enforcement + helpers exist; layer
 * dispatch throws "processLayer dispatch not yet wired — see 130-04".
 */

import { Client } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';
import * as dotenv from 'dotenv';
dotenv.config();

// ─── Per-state TIGER layer allowlist (D-04 — copy VERBATIM) ──────────────────
//
// Inline as code (NOT loaded from JSON, NOT configurable). Adding a new state
// is a code change, on purpose: it forces an explicit review of which layers
// are safe for that state.
//
const STATE_LAYER_ALLOWLIST: Record<string, Set<string>> = {
  CA: new Set(['cd', 'sldu', 'sldl', 'unsd', 'place', 'county', 'cousub']),
  TX: new Set(['cd', 'sldu', 'sldl', 'county', 'place']),
  UT: new Set(['cd119', 'sldu', 'sldl', 'unsd', 'place', 'county', 'aiannh']),
  IN: new Set(['cd', 'sldu', 'sldl', 'unsd', 'place', 'cousub']),
  MA: new Set(['cd', 'sldu', 'sldl', 'place', 'county', 'cousub']),
  ME: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
};

// UT_TRIBE_NAMELSAD_ALLOWLIST (Phase 132 GEO-07 / D-05 hybrid path)
//
// Pitfall 2 (132-RESEARCH §"Pitfall 2: Navajo Nation Cross-State Polygon"):
// the TIGER aiannh national layer's STATEFP field designates the *primary*
// state, not all touching states. A naive `STATEFP='49'` filter would EXCLUDE
// Navajo Nation (whose primary state is AZ) entirely. Filter by NAMELSAD
// allowlist instead. Verify exact strings on dry-run if the count drifts;
// loader prints distinct NAMELSAD touching the allowlist when --dry-run.
// Exact NAMELSAD strings from TIGER 2024 (verified 2026-05-09 via dry-run probe
// against tl_2024_us_aiannh.dbf). Covers all UT-touching tribal entities:
//   - 6 reservations (G2101, LSAD=86 "Reservation")
//   - 4 off-reservation trust lands (G2102, LSAD=OT) for tribes with scattered
//     parcels held in federal trust outside the main reservation
// Ute Mountain's primary state is CO/NM but its land touches SE Utah; included
// so addresses in that corner correctly resolve on_reservation:true.
const UT_TRIBE_NAMELSAD_ALLOWLIST: Set<string> = new Set([
  // Reservations
  'Navajo Nation Reservation',
  'Uintah and Ouray Reservation',
  'Goshute Reservation',
  'Skull Valley Reservation',
  'Northwestern Shoshone Reservation',
  'Paiute (UT) Reservation',
  'Ute Mountain Reservation',
  // Off-Reservation Trust Lands
  'Navajo Nation Off-Reservation Trust Land',
  'Uintah and Ouray Off-Reservation Trust Land',
  'Ute Mountain Off-Reservation Trust Land',
]);

// STATE_CITY_ASSERTIONS: place-layer vintage gate (Phase 131 D-03..D-06)
// Fires for any state listed here when processing the 'place' layer.
// Each string is a case-insensitive substring to match against NAMELSAD.
// Adding a new state is a code change, on purpose.
const STATE_CITY_ASSERTIONS: Record<string, string[]> = {
  UT: ['Magna', 'Kearns', 'Copperton', 'Emigration Canyon', 'White City'],
  TX: ['Longview city', 'Houston city', 'Dallas city', 'Austin city'],
  MA: ['Cambridge city'],
  ME: ['Portland city'],
};

// STATE_RUN_MAKEVALID: per-state ST_MakeValid layer set (Phase 131 D-07..D-09)
// When a state is absent, the fallback `layer === 'place'` rule applies (preserving
// CA byte-equivalence). When present, every layer in the Set receives ST_MakeValid.
const STATE_RUN_MAKEVALID: Record<string, Set<string>> = {
  CA: new Set(['place', 'county', 'cousub']),
  UT: new Set(['cd119', 'sldu', 'sldl', 'unsd', 'place', 'county', 'aiannh']),
  TX: new Set(['place', 'county']),
  MA: new Set(['cd', 'sldu', 'sldl', 'place', 'county', 'cousub']),
  ME: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
};

// Globally hard-rejected layers (D-05). PLSS township/range polygons collapsed
// the UT geofence_boundaries table previously — see PITFALLS.md UT-2.
const UNSAFE_LAYERS = new Set(['plss']);

// ─── FIPS → state abbreviation map (D-01, D-02) ──────────────────────────────
//
// Copied from load-us-congressional-boundaries.ts; that file is deleted in
// 130-06 (Commit C).
//
const FIPS_TO_STATE: Record<string, string> = {
  '01': 'al', '02': 'ak', '04': 'az', '05': 'ar', '06': 'ca',
  '08': 'co', '09': 'ct', '10': 'de', '11': 'dc', '12': 'fl',
  '13': 'ga', '15': 'hi', '16': 'id', '17': 'il', '18': 'in',
  '19': 'ia', '20': 'ks', '21': 'ky', '22': 'la', '23': 'me',
  '24': 'md', '25': 'ma', '26': 'mi', '27': 'mn', '28': 'ms',
  '29': 'mo', '30': 'mt', '31': 'ne', '32': 'nv', '33': 'nh',
  '34': 'nj', '35': 'nm', '36': 'ny', '37': 'nc', '38': 'nd',
  '39': 'oh', '40': 'ok', '41': 'or', '42': 'pa', '44': 'ri',
  '45': 'sc', '46': 'sd', '47': 'tn', '48': 'tx', '49': 'ut',
  '50': 'vt', '51': 'va', '53': 'wa', '54': 'wv', '55': 'wi',
  '56': 'wy',
};

// ─── buildOcdId helper (D-09 / GEN-2) ────────────────────────────────────────

/**
 * Build an OCD-ID for a TIGER-derived district.
 *
 * Per PITFALLS.md GEN-2, this is the ONLY place where the OCD division template
 * literal is constructed in this file. Every such ID must be emitted via this
 * helper — see acceptance grep in 130-03 PLAN for enforcement.
 *
 * @param stateAbbrev e.g. "CA", "TX", "UT" (lowercased internally)
 * @param ocdKey e.g. "sldu", "sldl", "congressional_district", "county", "place", "school_district"
 * @param districtNum e.g. "12", "37", or for unsd/place a slug derived from NAMELSAD
 */
function buildOcdId(stateAbbrev: string, ocdKey: string, districtNum: string): string {
  return `ocd-division/country:us/state:${stateAbbrev.toLowerCase()}/${ocdKey}:${districtNum}`;
}

// ─── Case-insensitive column resolver (D-08 / GEN-1) ─────────────────────────

/**
 * Resolve a logical column name (e.g. "NAMELSAD", "GEOID") to whichever physical
 * dbf field is present. TIGER vintages drift: NAMELSAD20, NAMELSAD10, NAMELSAD_1
 * have all been seen. Hard-fail if no candidate matches.
 */
function resolveColumn(record: Record<string, unknown>, candidates: string[]): string {
  for (const c of candidates) {
    if (c in record) return c;
  }
  throw new Error(
    `Column resolution failed: none of [${candidates.join(', ')}] present in record. ` +
    `Available: [${Object.keys(record).join(', ')}]. ` +
    `This is the GEN-1 (NAMELSAD column drift) failure mode — add the new variant to the candidate list.`
  );
}

const NAMELSAD_CANDIDATES = ['NAMELSAD', 'NAMELSAD20', 'NAMELSAD10', 'NAMELSAD_1'];
const GEOID_CANDIDATES = ['GEOID', 'GEOID20', 'GEOID10'];

// ─── Layer dispatch table (ARCHITECTURE.md §2.1 + D-07) ──────────────────────
//
// Single source of truth for per-layer config. 130-04 will extend this with
// skipRecord / fpField / writeDistricts / runMakeValid columns and wire the
// real per-layer record handler. For 130-03 the table is structural only.
//
// D-07: place uses NAMELSAD as geo_id (per audit at PYTHON-AUDIT §place); all
// other layers use GEOID. NB: PYTHON-AUDIT actually flags `place → GEOID` as a
// byte-equivalence requirement; the geoIdSource value here marks the LOGICAL
// column to read NAMELSAD from for the `name`/slug, not necessarily the
// `geo_id` column. The per-layer handler in 130-04 is responsible for the
// final mapping (see 130-04 plan + PYTHON-AUDIT §"Open questions" §1).
//
type LayerDef = {
  mtfcc: string;
  district_type: string;
  ocdKey: string;
  geoIdSource: 'GEOID' | 'NAMELSAD';
  urlTemplate: (vintage: string, fips: string, congress: string) => string;

  // Added in 130-04:
  /** dbf field name(s) holding the district number / suffix used in OCD-IDs.
   *  null for place / unsd / county (county derives from NAME, place/unsd from GEOID/NAMELSAD). */
  districtNumField: string[] | null;
  /** true => filter records to those whose STATEFP matches --fips. False for state-scoped files. */
  filterByStatefp: boolean;
  /** Records whose districtNumField value is in this set are skipped (ZZZ placeholder, 000 at-large, etc.) */
  skipDistrictCodes: Set<string>;
  /** Whether to also write a row to essentials.districts. LITERAL constant — sourced from
   *  130-01-PYTHON-AUDIT.md "Open questions / discrepancies" §4 "Operational-parity"
   *  recommendation per layer. NOT a runtime conditional. The 130-05 snapshot test only
   *  hashes essentials.geofence_boundaries, so this answer is locked at plan time.
   *  Field type below uses `true | false` (not `boolean`) so the literal-only grep
   *  in 130-04 acceptance criteria stays clean. */
  writeDistrictRow: true | false;
  /** Phase 132 D-05/D-09 hybrid aiannh path. Per-row NAMELSAD allowlist filter
   *  (Pitfall 2: Navajo cross-state can't use STATEFP). When set, layers ignore
   *  STATEFP and admit only records whose NAMELSAD is in the Set. */
  namelsadAllowlist?: Set<string>;
  /** Phase 132 D-05 hybrid source string override; replaces 'census_tiger_2024'
   *  in upsertGeofence for layers (e.g. aiannh) sourced from a TIGER+UGRC composite. */
  sourceString?: string;
};

// LA City Mayor risk callout: gap_fill_geo_ids.py:141 hardcodes
//   UPDATE essentials.districts SET geo_id = '0644000' for the LA City LOCAL_EXEC row.
// That literal '0644000' is a 7-char GEOID = STATEFP(06) + PLACEFP(44000). Per the
// 130-01 audit, import_ca_place_boundaries.py:123 writes 'geo_id': row['GEOID']
// (NAMELSAD is the NAME column, not the geo_id). The CONTEXT.md D-07 note saying
// "place → NAMELSAD" is mistaken on the geo_id row; the byte-equivalence baseline
// reflects GEOID. Therefore the place handler in processLayer reads GEOID for the
// geo_id and uses NAMELSAD only for the name column — preserving the 0644000 chain
// AND CA byte-equivalence. The geoIdSource: 'NAMELSAD' marker on the dispatch entry
// retains the D-07 reference but the per-layer handler is authoritative.

const LAYER_DISPATCH: Record<string, LayerDef> = {
  cd: {
    mtfcc: 'G5200', district_type: 'NATIONAL_LOWER', ocdKey: 'congressional_district',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, c) => `https://www2.census.gov/geo/tiger/TIGER${v}/CD/tl_${v}_${f}_cd${c}.zip`,
    districtNumField: ['CD119FP', 'CDFP', 'CD118FP'],
    filterByStatefp: true,
    skipDistrictCodes: new Set(['ZZ', 'ZZZ', '00', '000']),
    writeDistrictRow: true /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (Operational-parity recommendation, line "cd: writeDistricts=true (per existing TS)") */,
  },
  cd119: {
    mtfcc: 'G5200', district_type: 'NATIONAL_LOWER', ocdKey: 'congressional_district',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, c) => `https://www2.census.gov/geo/tiger/TIGER${v}/CD/tl_${v}_${f}_cd${c}.zip`,
    districtNumField: ['CD119FP', 'CDFP', 'CD118FP'],
    filterByStatefp: true,
    skipDistrictCodes: new Set(['ZZ', 'ZZZ', '00', '000']),
    writeDistrictRow: true /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (cd119 shares cd's TS-loader path; Operational-parity recommendation) */,
  },
  sldu: {
    mtfcc: 'G5210', district_type: 'STATE_UPPER', ocdKey: 'sldu',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/SLDU/tl_${v}_${f}_sldu.zip`,
    districtNumField: ['SLDUST'],
    filterByStatefp: false,
    skipDistrictCodes: new Set(['ZZZ', '000']),
    writeDistrictRow: true /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (Operational-parity recommendation, line "sldu: writeDistricts=true (per existing TS)") */,
  },
  sldl: {
    mtfcc: 'G5220', district_type: 'STATE_LOWER', ocdKey: 'sldl',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/SLDL/tl_${v}_${f}_sldl.zip`,
    districtNumField: ['SLDLST'],
    filterByStatefp: false,
    skipDistrictCodes: new Set(['ZZZ', '000']),
    writeDistrictRow: true /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (Operational-parity recommendation, line "sldl: writeDistricts=true (per existing TS)") */,
  },
  unsd: {
    mtfcc: 'G5420', district_type: 'SCHOOL', ocdKey: 'school_district',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/UNSD/tl_${v}_${f}_unsd.zip`,
    districtNumField: null,
    filterByStatefp: false,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: false /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (Operational-parity recommendation, line "unsd: writeDistricts=false (Python sets the precedent; school-board ingestion creates SCHOOL districts rows separately)") */,
  },
  place: {
    mtfcc: 'G4110', district_type: 'LOCAL', ocdKey: 'place',
    // Sentinel value retained per CONTEXT.md D-07; the per-layer handler in
    // processLayer reads GEOID for the actual geo_id (per 130-01 audit). See
    // the LA City Mayor 0644000 risk callout above the LAYER_DISPATCH block.
    geoIdSource: 'NAMELSAD',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/PLACE/tl_${v}_${f}_place.zip`,
    districtNumField: null,
    filterByStatefp: false,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: false /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (Operational-parity recommendation, line "place: writeDistricts=false (Python sets precedent; no essentials.districts row in production today)"); also §"place layer" "districts table write: NO" */,
  },
  county: {
    mtfcc: 'G4020', district_type: 'COUNTY', ocdKey: 'county',
    geoIdSource: 'GEOID',
    urlTemplate: (v, _f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/COUNTY/tl_${v}_us_county.zip`,
    districtNumField: ['COUNTYFP'],
    filterByStatefp: true,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: true /* ARCHITECTURE.md §2.2 default (county not in 130-01 audit's CA-only Python scope; existing load-collin-county-boundary.ts:216 writes the districts row); Operational-parity recommendation extended to county per ARCHITECTURE.md §2.2 */,
  },
  cousub: {
    mtfcc: 'G4040', district_type: 'LOCAL', ocdKey: 'cousub',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/COUSUB/tl_${v}_${f}_cousub.zip`,
    districtNumField: null,
    filterByStatefp: false,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: false,
  },
  aiannh: {
    // Phase 132 GEO-07 / D-05 hybrid path: TIGER aiannh national layer for the
    // polygon, UGRC tribal-lands FeatureServer for metadata enrichment.
    // D-10: stored under synthetic mtfcc='X0004' (not TIGER native G2100).
    // D-11: tribal does NOT join essentials.districts; surfaces via tribal_land
    // response field instead.
    mtfcc: 'X0004',
    district_type: 'TRIBAL',
    ocdKey: 'tribe',
    geoIdSource: 'NAMELSAD',
    urlTemplate: (v, _f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/AIANNH/tl_${v}_us_aiannh.zip`,
    districtNumField: null,
    filterByStatefp: false /* Pitfall 2: Navajo cross-state */,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: false,
    namelsadAllowlist: UT_TRIBE_NAMELSAD_ALLOWLIST,
    sourceString: 'tiger_2024_aiannh+ugrc_sgid_tribal_metadata',
  },
};

// ─── Shared infrastructure helpers ───────────────────────────────────────────

/**
 * Download `url` to `destPath`. Cache: if the file already exists, no-op.
 * Follows 301/302 redirects. Pattern copied verbatim from
 * load-tx-state-boundaries.ts:88.
 */
function downloadWithRedirects(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (fs.existsSync(destPath)) {
      return resolve();
    }
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        return downloadWithRedirects(response.headers.location!, destPath).then(resolve).catch(reject);
      }
      if (response.statusCode !== 200) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
      reject(err);
    });
  });
}

/**
 * Extract `zipPath` to `destDir`. Returns a `cleanup()` that deletes destDir
 * only if it didn't pre-exist (so re-runs don't blow away a hand-extracted
 * shapefile cache).
 */
function extractZip(zipPath: string, destDir: string): { cleanup: () => void } {
  const dirExistedBefore = fs.existsSync(destDir);
  fs.mkdirSync(destDir, { recursive: true });
  const zip = new AdmZip(zipPath);
  zip.extractAllTo(destDir, true);
  return {
    cleanup: () => {
      if (!dirExistedBefore && fs.existsSync(destDir)) {
        fs.rmSync(destDir, { recursive: true, force: true });
      }
    },
  };
}

/**
 * Stream a shapefile, calling `onRecord` for every feature. Opens with
 * utf-8 encoding (TIGER shapefiles ship UTF-8, not the dbf default).
 */
async function streamShapefile(
  shpPath: string,
  dbfPath: string,
  onRecord: (geom: unknown, props: Record<string, unknown>) => Promise<void>,
): Promise<void> {
  const source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });
  let result = await source.read();
  while (!result.done) {
    const feature = result.value;
    await onRecord(feature.geometry, feature.properties as Record<string, unknown>);
    result = await source.read();
  }
}

/**
 * Insert a row into essentials.geofence_boundaries with ON CONFLICT skip.
 *
 * D-01: the `state` named key on this helper receives the FIPS code per D-01
 * (e.g. '06', '48', '49').
 */
async function upsertGeofence(client: Client, params: {
  geo_id: string;
  ocd_id: string | null;
  name: string;
  state: string; // state: FIPS code per D-01
  mtfcc: string;
  geometryGeoJson: unknown;
  /** Wrap the loaded geometry in ST_MakeValid before insert. PLACE-only per
   *  130-01-PYTHON-AUDIT.md §"place layer" "Geometry transform" — Python
   *  import_ca_place_boundaries.py:110-113 calls gdf.geometry.make_valid() on
   *  invalid PLACE rows; the legislative + multi-layer scripts do NOT.
   *  Setting this on for non-place layers would alter geometries that the
   *  Python pipeline left alone and break byte-equivalence. */
  runMakeValid?: boolean;
  /** Phase 132 D-05 hybrid: composite source override (e.g. for aiannh).
   *  Defaults to 'census_tiger_2024' when omitted. */
  sourceString?: string;
}): Promise<{ inserted: boolean }> {
  const geomExpr = params.runMakeValid
    ? `ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($6)), 4326))`
    : `ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($6)), 4326)`;
  const result = await client.query(
    `
    INSERT INTO essentials.geofence_boundaries
      (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
    VALUES ($1, $2, $3, $4, $5,
      ${geomExpr},
      $7, now())
    ON CONFLICT (geo_id, mtfcc) DO NOTHING
    `,
    [
      params.geo_id,
      params.ocd_id,
      params.name,
      params.state,
      params.mtfcc,
      JSON.stringify(params.geometryGeoJson),
      params.sourceString ?? 'census_tiger_2024',
    ],
  );
  return { inserted: (result.rowCount ?? 0) > 0 };
}

/**
 * Insert a row into essentials.districts iff one doesn't already exist for the
 * (geo_id, district_type) pair.
 *
 * D-02: the `state` named key on this helper receives the abbreviation per
 * D-02 (e.g. 'CA', 'TX').
 */
async function insertDistrictIfMissing(client: Client, params: {
  geo_id: string;
  ocd_id: string;
  name: string;
  state: string; // state: ABBREV per D-02
  district_type: string;
  mtfcc: string;
}): Promise<{ inserted: boolean }> {
  const result = await client.query(
    `
    INSERT INTO essentials.districts
      (geo_id, ocd_id, label, district_type, state, mtfcc)
    SELECT $1, $2, $3, $4, $5, $6
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.districts
      WHERE geo_id = $1 AND district_type = $4
    )
    `,
    [
      params.geo_id,
      params.ocd_id,
      params.name,
      params.district_type,
      params.state,
      params.mtfcc,
    ],
  );
  return { inserted: (result.rowCount ?? 0) > 0 };
}

// ─── Per-layer dispatch (stub — wired in 130-04) ─────────────────────────────

interface LayerTotals {
  inserted_boundary: number;
  inserted_district: number;
  already_exists: number;
  skipped: number;
  errors: number;
}

/**
 * Slugify a NAME for OCD-ID suffix (county, place layers).
 *
 *   "Collin County" → "collin"
 *   "Los Angeles County" → "los_angeles"
 *   "Los Angeles city" → "los_angeles"
 *
 * For COUNTY: matches load-collin-county-boundary.ts:202 ("county:collin"). The
 * "County" / "city" / "town" trailing token is stripped, remaining tokens are
 * lowercased and joined with underscore.
 *
 * For PLACE: ocd_id is NULL per 130-01-PYTHON-AUDIT.md §"place layer" — see the
 * place-handler branch in processLayer.
 */
function slugifyName(name: string): string {
  // Strip common trailing classification tokens (case-insensitive).
  const stripTokens = /\s+(county|city|town|village|borough|township|cdp)\b\.?\s*$/i;
  const stripped = name.replace(stripTokens, '').trim();
  return stripped
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

async function processLayer(
  client: Client,
  layer: string,
  fips: string,
  layerDef: LayerDef,
  vintage: string,
  congress: string,
  dryRun: boolean,
): Promise<LayerTotals> {
  // Two named-local variables for the call sites (D-01 / D-02 grep-verifiable).
  const fipsArg = fips;                       // FIPS code, e.g. '06' — passed to upsertGeofence per D-01
  const abbrev = FIPS_TO_STATE[fips];         // state abbreviation (lowercased), e.g. 'ca' — passed to insertDistrictIfMissing per D-02
  const abbrevUpper = (abbrev ?? fips).toUpperCase(); // 'CA' — what the existing TS loaders write to essentials.districts.state

  const totals: LayerTotals = {
    inserted_boundary: 0,
    inserted_district: 0,
    already_exists: 0,
    skipped: 0,
    errors: 0,
  };

  const url = layerDef.urlTemplate(vintage, fips, congress);

  // ── Dry run short-circuit BEFORE any I/O or DB call ─────────────────────────
  if (dryRun) {
    console.log(`  [dry-run] ${layer} (${layerDef.mtfcc} → ${layerDef.district_type})`);
    console.log(`  [dry-run] URL: ${url}`);
    console.log(`  [dry-run] writeDistrictRow=${layerDef.writeDistrictRow}, filterByStatefp=${layerDef.filterByStatefp}`);
    console.log(`  [dry-run] would write rows for layer ${layer} (skip rules: ${Array.from(layerDef.skipDistrictCodes).join(',') || 'none'}).`);

    // Phase 132 GEO-07 dry-run safeguard: when scanning aiannh, download
    // the layer (cached) and print distinct NAMELSAD values that pass the
    // allowlist + a sample of the rest, so the operator can verify the
    // allowlist matches actual TIGER vintage NAMELSAD strings. This guards
    // against threat T-132-05-01 (NAMELSAD drift between TIGER vintages).
    if (layer === 'aiannh' && layerDef.namelsadAllowlist) {
      try {
        const tmpRoot = path.join(process.cwd(), `.tmp-tiger-${vintage}-${fips}`);
        fs.mkdirSync(tmpRoot, { recursive: true });
        const baseName = path.basename(url, '.zip');
        const zipPath = path.join(tmpRoot, `${baseName}.zip`);
        const destDir = path.join(tmpRoot, baseName);
        await downloadWithRedirects(url, zipPath);
        extractZip(zipPath, destDir);
        const entries = fs.readdirSync(destDir);
        const shpFile = entries.find((e) => e.toLowerCase().endsWith('.shp'));
        const dbfFile = entries.find((e) => e.toLowerCase().endsWith('.dbf'));
        if (shpFile && dbfFile) {
          const seenAllowed = new Set<string>();
          const seenOther = new Set<string>();
          await streamShapefile(
            path.join(destDir, shpFile),
            path.join(destDir, dbfFile),
            async (_g, props) => {
              const namelsadKey = resolveColumn(props as Record<string, unknown>, NAMELSAD_CANDIDATES);
              const v = String(props[namelsadKey] ?? '');
              if (!v) return;
              if (layerDef.namelsadAllowlist!.has(v)) seenAllowed.add(v);
              else if (seenOther.size < 20) seenOther.add(v);
            },
          );
          console.log(`  [dry-run] aiannh NAMELSAD allowlist hits (${seenAllowed.size}):`);
          for (const v of Array.from(seenAllowed).sort()) console.log(`    ✓ ${v}`);
          const missing = Array.from(layerDef.namelsadAllowlist).filter((v) => !seenAllowed.has(v));
          if (missing.length > 0) {
            console.log(`  [dry-run] MISSING from allowlist (drift?): ${missing.join(' | ')}`);
          }
          console.log(`  [dry-run] sample of other NAMELSAD (first 20): ${Array.from(seenOther).slice(0, 20).join(' | ')}`);
        }
      } catch (err) {
        console.warn(`  [dry-run] aiannh scan failed: ${(err as Error).message}`);
      }
    }
    return totals;
  }

  // ── Resolve paths under per-run temp dir ────────────────────────────────────
  const tmpRoot = path.join(process.cwd(), `.tmp-tiger-${vintage}-${fips}`);
  fs.mkdirSync(tmpRoot, { recursive: true });
  const baseName = path.basename(url, '.zip'); // e.g. tl_2024_06_sldu / tl_2024_us_cd119
  const zipPath = path.join(tmpRoot, `${baseName}.zip`);
  const destDir = path.join(tmpRoot, baseName);

  // ── Download (cached) ────────────────────────────────────────────────────────
  console.log(`  [${layer}] downloading ${url}`);
  await downloadWithRedirects(url, zipPath);

  // ── Extract ──────────────────────────────────────────────────────────────────
  console.log(`  [${layer}] extracting ${path.basename(zipPath)}`);
  extractZip(zipPath, destDir);

  // Find .shp and .dbf inside destDir
  const entries = fs.readdirSync(destDir);
  const shpFile = entries.find((e) => e.toLowerCase().endsWith('.shp'));
  const dbfFile = entries.find((e) => e.toLowerCase().endsWith('.dbf'));
  if (!shpFile || !dbfFile) {
    throw new Error(`[${layer}] could not locate .shp/.dbf in ${destDir} (entries: ${entries.join(', ')})`);
  }
  const shpPath = path.join(destDir, shpFile);
  const dbfPath = path.join(destDir, dbfFile);

  console.log(`  [${layer}] streaming ${shpFile}`);

  // ── STATE_CITY_ASSERTIONS pre-write gate (Phase 131 D-04, D-05, D-06) ───────
  // Two-pass approach: re-read the (already extracted) shapefile to collect NAMELSAD
  // values into seenNamelsad, assert all required cities present, THEN proceed to
  // the existing upsert pass. Fires only when state has assertions defined.
  if (layer === 'place' && STATE_CITY_ASSERTIONS[abbrevUpper]) {
    const seenNamelsad = new Set<string>();
    await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
      // Apply the same MTFCC filter the upsert pass uses (G4110 only).
      const mtfccRaw = (props['MTFCC'] ?? props['mtfcc'] ?? '') as string;
      if (mtfccRaw && mtfccRaw !== 'G4110') return;
      const namelsadCol = resolveColumn(props as Record<string, unknown>, NAMELSAD_CANDIDATES);
      const v = props[namelsadCol];
      if (typeof v === 'string' && v.length > 0) {
        seenNamelsad.add(v);
      }
    });

    const required = STATE_CITY_ASSERTIONS[abbrevUpper];
    const missing = required.filter(
      (city) => !Array.from(seenNamelsad).some(
        (n) => n.toLowerCase().includes(city.toLowerCase())
      )
    );
    if (missing.length > 0) {
      process.stderr.write(
        `[place] STATE_CITY_ASSERTIONS gate FAILED for ${abbrevUpper}.\n` +
        `Missing cities: ${JSON.stringify(missing)}\n` +
        `Seen NAMELSAD values (sample): ${Array.from(seenNamelsad).slice(0, 10).join(', ')}\n` +
        `Escalate to user per CONTEXT.md D-06. No rows written.\n`
      );
      process.exit(1);
    }
    console.log(`  [${layer}] STATE_CITY_ASSERTIONS gate PASSED for ${abbrevUpper} (${required.length} cities verified).`);
  }

  // ── MA MTFCC pre-flight assertion (Phase 38) ────────────────────────────────
  // For MA (state='25'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  if (fipsArg === '25') {
    const EXPECTED_MA_MTFCC: Record<string, number> = {
      cd:    9,    // 9 MA congressional districts
      sldu: 40,    // 40 MA Senate districts
      sldl: 160,   // 160 MA House districts
      place: 58,   // 58 MA G4110 incorporated cities (towns are G4040 COUSUB, not loaded in Phase 38)
      county: 14,  // 14 MA counties
      cousub: 293,  // 293 active MA towns (FUNCSTAT='A'); 64 FUNCSTAT='F' placeholders skipped
    };
    if (layer in EXPECTED_MA_MTFCC) {
      const expected = EXPECTED_MA_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        // Apply the same filter logic as the upsert pass below.
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
        }
        if (layer === 'place') {
          const mtfccRaw = (props['MTFCC'] ?? props['mtfcc'] ?? '') as string;
          if (mtfccRaw && mtfccRaw !== 'G4110') return;
        }
        if (layer === 'cousub') {
          const funcstatVal = String(props['FUNCSTAT'] ?? props['funcstat'] ?? '');
          if (funcstatVal !== 'A') return;
        }
        if (layerDef.districtNumField) {
          const fpKey = resolveColumn(props, layerDef.districtNumField);
          const fpVal = String(props[fpKey] ?? '');
          if (layerDef.skipDistrictCodes.has(fpVal)) return;
        }
        actualCount++;
      });
      if (actualCount !== expected) {
        const err = new Error(
          `[MA MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 25 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] MA MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── ME MTFCC pre-flight assertion (Phase 49) ────────────────────────────────
  // For ME (state='23'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  if (fipsArg === '23') {
    const EXPECTED_ME_MTFCC: Record<string, number> = {
      cd119: 2,   // 2 ME congressional districts
      sldu:  35,  // 35 ME Senate districts
      sldl:  151, // 151 ME House districts
      place: 23,  // 23 ME G4110 incorporated cities
      county: 16, // 16 ME counties
    };
    if (layer in EXPECTED_ME_MTFCC) {
      const expected = EXPECTED_ME_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        // Apply the same filter logic as the upsert pass below.
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
        }
        if (layer === 'place') {
          const mtfccRaw = (props['MTFCC'] ?? props['mtfcc'] ?? '') as string;
          if (mtfccRaw && mtfccRaw !== 'G4110') return;
        }
        if (layerDef.districtNumField) {
          const fpKey = resolveColumn(props, layerDef.districtNumField);
          const fpVal = String(props[fpKey] ?? '');
          if (layerDef.skipDistrictCodes.has(fpVal)) return;
        }
        actualCount++;
      });
      if (actualCount !== expected) {
        const err = new Error(
          `[ME MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 23 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] ME MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── TX MTFCC pre-flight assertion (Phase TX-place) ───────────────────────────
  // For TX (state='48'), count G4110 incorporated places before any DB write.
  // TX TIGER 2024: 1,228 G4110 records (0 G4150 CDPs, 635 G4210 consolidated cities filtered).
  if (fipsArg === '48') {
    const EXPECTED_TX_MTFCC: Record<string, number> = {
      place: 1228,
      county: 254,
    };
    if (layer in EXPECTED_TX_MTFCC) {
      const expected = EXPECTED_TX_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
        }
        if (layer === 'place') {
          const mtfccRaw = (props['MTFCC'] ?? props['mtfcc'] ?? '') as string;
          if (mtfccRaw && mtfccRaw !== 'G4110') return;
        }
        if (layerDef.districtNumField) {
          const fpKey = resolveColumn(props, layerDef.districtNumField);
          const fpVal = String(props[fpKey] ?? '');
          if (layerDef.skipDistrictCodes.has(fpVal)) return;
        }
        actualCount++;
      });
      if (actualCount !== expected) {
        const err = new Error(
          `[TX MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 48 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] TX MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── CA MTFCC pre-flight assertion (Phase 57) ────────────────────────────────
  // For CA (state='06'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  // CA cousub are CCDs (FUNCSTAT='S') — NO FUNCSTAT filter applied here.
  if (fipsArg === '06') {
    const EXPECTED_CA_MTFCC: Record<string, number> = {
      county: 58,   // 58 California counties
      cousub: 404,  // 404 CA Census County Divisions in TIGER 2024 (CCDs, FUNCSTAT='S')
                    // NOTE: TIGERweb BAS25 dataset shows 1,057 but TIGER 2024 file has 404.
                    // Verified 2026-05-21: all 404 records are FUNCSTAT='S' (statistical CCDs).
    };
    if (layer in EXPECTED_CA_MTFCC) {
      const expected = EXPECTED_CA_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
        }
        // NO FUNCSTAT filter: CA cousub are CCDs with FUNCSTAT='S' (statistical).
        if (layerDef.districtNumField) {
          const fpKey = resolveColumn(props, layerDef.districtNumField);
          const fpVal = String(props[fpKey] ?? '');
          if (layerDef.skipDistrictCodes.has(fpVal)) return;
        }
        actualCount++;
      });
      if (actualCount !== expected) {
        const err = new Error(
          `[CA MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 06 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] CA MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── Stream records ──────────────────────────────────────────────────────────
  await streamShapefile(shpPath, dbfPath, async (geom, props) => {
    try {
      // STATEFP filter (US-wide files only)
      if (layerDef.filterByStatefp) {
        const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
        const statefp = String(props[statefpKey] ?? '');
        if (statefp !== fips) {
          totals.skipped++;
          return;
        }
      }

      // NAMELSAD allowlist filter — Phase 132 GEO-07 / D-05 (aiannh hybrid).
      // Pitfall 2: STATEFP filter would drop Navajo Nation (its primary STATEFP is AZ),
      // so aiannh ignores filterByStatefp and gates on NAMELSAD instead.
      if (layerDef.namelsadAllowlist) {
        const namelsadKey = resolveColumn(props, NAMELSAD_CANDIDATES);
        const namelsad = String(props[namelsadKey] ?? '');
        if (!layerDef.namelsadAllowlist.has(namelsad)) {
          totals.skipped++;
          return;
        }
      }

      // PLACE layer: hard-filter MTFCC === 'G4110' per 130-01 audit
      // §"place layer" "Skip rules" (excludes G4150 CDP, G4210, etc.).
      if (layer === 'place') {
        const mtfccRaw = (props['MTFCC'] ?? props['mtfcc'] ?? '') as string;
        if (mtfccRaw && mtfccRaw !== 'G4110') {
          totals.skipped++;
          return;
        }
      }

      // COUSUB layer: FUNCSTAT filter is state-conditional.
      // MA county subdivisions are MCDs (Minor Civil Divisions, active governments, FUNCSTAT='A').
      // CA county subdivisions are CCDs (Census County Divisions, statistical, FUNCSTAT='S').
      // Filtering CCDs to FUNCSTAT='A' would skip ALL CA records (see Phase 57 RESEARCH).
      // Add a state to this set ONLY if its TIGER COUSUB shapefile contains active MCDs.
      const COUSUB_FUNCSTAT_STATES = new Set(['MA']);
      if (layer === 'cousub' && COUSUB_FUNCSTAT_STATES.has(abbrevUpper)) {
        const funcstatVal = String(props['FUNCSTAT'] ?? props['funcstat'] ?? '');
        if (funcstatVal !== 'A') {
          totals.skipped++;
          return;
        }
      }

      // District-code skip (ZZZ / 000)
      let districtNum: string | null = null;
      if (layerDef.districtNumField) {
        const fpKey = resolveColumn(props, layerDef.districtNumField);
        const fpVal = String(props[fpKey] ?? '');
        if (layerDef.skipDistrictCodes.has(fpVal)) {
          totals.skipped++;
          return;
        }
        districtNum = fpVal;
      }

      // Resolve geo_id.
      // PLACE OVERRIDE: per 130-01-PYTHON-AUDIT.md §"place layer" "geo_id source"
      // (verbatim at import_ca_place_boundaries.py:123 — `'geo_id': row['GEOID']`),
      // place uses GEOID as geo_id. The dispatch entry's `geoIdSource: 'NAMELSAD'`
      // is a sentinel for D-07 reference — the per-layer handler is authoritative.
      // This preserves the LA City Mayor 0644000 chain (gap_fill_geo_ids.py:141).
      let geo_id: string;
      if (layer === 'place') {
        const geoidKey = resolveColumn(props, GEOID_CANDIDATES);
        geo_id = String(props[geoidKey] ?? '');
      } else if (layer === 'aiannh') {
        // Phase 132 GEO-07 / D-09: tribal geo_id is OCD-format
        // `ocd-division/country:us/state:ut/tribe:{slug}` derived from NAMELSAD,
        // NOT raw TIGER GEOID. Predictable for the Phase 133 politician join.
        const namelsadKey = resolveColumn(props, NAMELSAD_CANDIDATES);
        const slug = slugifyName(String(props[namelsadKey] ?? ''));
        geo_id = buildOcdId('UT', 'tribe', slug);
      } else if (layerDef.geoIdSource === 'NAMELSAD') {
        const namelsadKey = resolveColumn(props, NAMELSAD_CANDIDATES);
        geo_id = String(props[namelsadKey] ?? '');
      } else {
        const geoidKey = resolveColumn(props, GEOID_CANDIDATES);
        geo_id = String(props[geoidKey] ?? '');
      }

      // Resolve name.
      let name: string;
      try {
        const namelsadKey = resolveColumn(props, NAMELSAD_CANDIDATES);
        name = String(props[namelsadKey] ?? '');
      } catch {
        // unsd ships only NAME, not NAMELSAD (per 130-01 audit §"unsd layer")
        const nameKey = resolveColumn(props, ['NAME', 'NAME20', 'NAME10']);
        name = String(props[nameKey] ?? '');
      }

      // Derive ocd_id per layer.
      let ocd_id: string | null = null;
      switch (layer) {
        case 'cd':
        case 'cd119': {
          // int() strips leading zeros — '043' → 43 — per 130-01 audit
          // §"Behaviors that MUST be preserved" #4.
          const dn = parseInt(districtNum ?? '0', 10);
          ocd_id = dn === 0
            ? buildOcdId(abbrevUpper, layerDef.ocdKey, 'at-large')
            : buildOcdId(abbrevUpper, layerDef.ocdKey, String(dn));
          break;
        }
        case 'sldu':
        case 'sldl': {
          const dn = parseInt(districtNum ?? '0', 10);
          ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, String(dn));
          break;
        }
        case 'county': {
          // ocdSuffix = lowercased NAME slug (matches load-collin-county-boundary.ts:202
          // "county:collin" — strip "County" suffix, lowercase remainder).
          ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, slugifyName(name));
          break;
        }
        case 'place':
          // ocd_id IS NULL per 130-01-PYTHON-AUDIT.md §"Behaviors that MUST be
          // preserved" #5 (`import_ca_place_boundaries.py:130` comment + audit
          // §"place layer" "districts table write: NO"). DO NOT synthesize an
          // OCD-ID for place — that would diverge from the byte-equivalence
          // baseline's NULL ocd_id column for every CA G4110 row.
          ocd_id = null;
          break;
        case 'unsd':
          // ocd_id IS NULL per 130-01-PYTHON-AUDIT.md §"unsd layer" — the
          // import_shapefiles.py column-rename map at lines 108-114 has no
          // ocd_id key, so unsd baseline rows have ocd_id NULL.
          ocd_id = null;
          break;
        case 'aiannh':
          // Phase 132 GEO-07 / D-09: ocd_id mirrors geo_id (both are the
          // OCD-format `ocd-division/country:us/state:ut/tribe:{slug}` string).
          ocd_id = geo_id;
          break;
        default:
          ocd_id = null;
      }

      // Insert into geofence_boundaries.
      // The state: fipsArg named-key form (kept on a single line) makes the
      // 130-04 D-01 grep-verifiable: `upsertGeofence(client, { ... state: fipsArg ... })`.
      // D-09 single resolution point: registry lookup with place-only fallback (CA byte-equivalence preserved).
      const runMakeValid = STATE_RUN_MAKEVALID[abbrevUpper]?.has(layer) ?? (layer === 'place');
      // eslint-disable-next-line max-len
      const upsertResult = await upsertGeofence(client, { geo_id, ocd_id, name, state: fipsArg, mtfcc: layerDef.mtfcc, geometryGeoJson: geom, runMakeValid, sourceString: layerDef.sourceString });
      if (upsertResult.inserted) {
        totals.inserted_boundary++;
      } else {
        totals.already_exists++;
      }

      // Insert into districts iff dispatch says so.
      // The state: abbrev named-key form (kept on a single line) makes the
      // 130-04 D-02 grep-verifiable: `insertDistrictIfMissing(client, { ... state: abbrev ... })`.
      if (layerDef.writeDistrictRow && ocd_id !== null) {
        // eslint-disable-next-line max-len
        const districtResult = await insertDistrictIfMissing(client, { geo_id, ocd_id, name, state: abbrev, district_type: layerDef.district_type, mtfcc: layerDef.mtfcc });
        if (districtResult.inserted) {
          totals.inserted_district++;
        }
      }
    } catch (err) {
      console.error(`  [${layer}] record error: ${(err as Error).message}`);
      totals.errors++;
    }
  });

  return totals;
}

// ─── CLI parsing (D-05, D-06) ────────────────────────────────────────────────

interface CliArgs {
  state: string;
  fips: string;
  layers: string[];
  dryRun: boolean;
  vintage: string;
  congress: string;
}

function parseArgs(argv: string[]): CliArgs {
  const args: Record<string, string | boolean> = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') {
      args.dryRun = true;
      continue;
    }
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next !== undefined && !next.startsWith('--')) {
        args[key] = next;
        i++;
      } else {
        args[key] = true;
      }
    }
  }

  const state = typeof args.state === 'string' ? args.state.toUpperCase() : '';
  const fips = typeof args.fips === 'string' ? args.fips : '';
  const layersRaw = typeof args.layers === 'string' ? args.layers : '';
  const dryRun = args.dryRun === true;
  const vintage = typeof args.vintage === 'string' ? args.vintage : '2024';
  const congress = typeof args.congress === 'string' ? args.congress : '119';

  if (!state) {
    process.stderr.write('--state required (e.g. CA, TX, UT, IN)\n');
    process.exit(1);
  }
  if (!fips) {
    process.stderr.write('--fips required (e.g. 06, 48, 49, 18)\n');
    process.exit(1);
  }
  if (!(state in STATE_LAYER_ALLOWLIST)) {
    process.stderr.write(
      `unknown state: ${state}. Known: ${Object.keys(STATE_LAYER_ALLOWLIST).join(', ')}\n`,
    );
    process.exit(1);
  }
  // D-06 — exact error string
  if (!layersRaw) {
    process.stderr.write(
      `--layers required: specify a comma-separated subset of ${state}'s allowlist\n`,
    );
    process.exit(1);
  }

  const layers = layersRaw.split(',').map((s) => s.trim()).filter(Boolean);
  if (layers.length === 0) {
    process.stderr.write(
      `--layers required: specify a comma-separated subset of ${state}'s allowlist\n`,
    );
    process.exit(1);
  }

  const allowed = STATE_LAYER_ALLOWLIST[state];
  for (const layer of layers) {
    // D-05: hard-reject unsafe layers GLOBALLY before allowlist check
    if (UNSAFE_LAYERS.has(layer)) {
      process.stderr.write(
        `layer '${layer}' is in UNSAFE_LAYERS and is hard-rejected (PITFALLS.md UT-2). Aborting.\n`,
      );
      process.exit(1);
    }
    if (!allowed.has(layer)) {
      process.stderr.write(
        `layer '${layer}' not in allowlist for ${state}. Allowed: ${Array.from(allowed).join(', ')}\n`,
      );
      process.exit(1);
    }
    if (!(layer in LAYER_DISPATCH)) {
      process.stderr.write(
        `layer '${layer}' has no LAYER_DISPATCH entry (this is a code bug — add it to LAYER_DISPATCH).\n`,
      );
      process.exit(1);
    }
  }

  return { state, fips, layers, dryRun, vintage, congress };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  // Sanity: confirm FIPS_TO_STATE round-trips. Catches typos like --state CA --fips 48.
  const expectedAbbrev = (FIPS_TO_STATE[args.fips] ?? '').toUpperCase();
  if (expectedAbbrev && expectedAbbrev !== args.state) {
    process.stderr.write(
      `--state ${args.state} does not match --fips ${args.fips} (FIPS_TO_STATE says ${expectedAbbrev})\n`,
    );
    process.exit(1);
  }

  console.log(`[load-state-tiger] Mode: ${args.dryRun ? 'DRY-RUN (no DB writes)' : 'LIVE'}`);
  console.log(`[load-state-tiger] State: ${args.state} (FIPS ${args.fips})`);
  console.log(`[load-state-tiger] Layers: ${args.layers.join(', ')}`);
  console.log(`[load-state-tiger] Vintage: ${args.vintage}, Congress: ${args.congress}`);

  // Dry-run short-circuits BEFORE opening any DB client. Each per-layer
  // processLayer() call further short-circuits before any I/O happens (per
  // 130-04 plan: "DRY RUN: would write {N} rows for layer {layer}" without
  // connecting to the DB).
  if (args.dryRun) {
    console.log('\n[dry-run] Would process layers:');
    // Pass `null as unknown as Client` so processLayer's signature stays honest;
    // the dry-run branch returns BEFORE any client method is invoked.
    const dryClient = null as unknown as Client;
    for (const layer of args.layers) {
      const def = LAYER_DISPATCH[layer];
      console.log(`  ${layer} (mtfcc=${def.mtfcc}, ocdKey=${def.ocdKey}) — ${def.urlTemplate(args.vintage, args.fips, args.congress)}`);
      await processLayer(dryClient, layer, args.fips, def, args.vintage, args.congress, true);
    }
    console.log('\nDRY-RUN complete — no database writes made.');
    process.exit(0);
  }

  if (!process.env.DATABASE_URL) {
    process.stderr.write('ERROR: DATABASE_URL is not set\n');
    process.exit(1);
  }

  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();

  const grandTotals: LayerTotals = {
    inserted_boundary: 0,
    inserted_district: 0,
    already_exists: 0,
    skipped: 0,
    errors: 0,
  };
  const perLayer: Array<{ layer: string; totals: LayerTotals }> = [];

  try {
    for (const layer of args.layers) {
      console.log(`\n── ${layer} (${LAYER_DISPATCH[layer].mtfcc} → ${LAYER_DISPATCH[layer].district_type}) ──`);
      try {
        const totals = await processLayer(
          client,
          layer,
          args.fips,
          LAYER_DISPATCH[layer],
          args.vintage,
          args.congress,
          args.dryRun,
        );
        perLayer.push({ layer, totals });
        grandTotals.inserted_boundary += totals.inserted_boundary;
        grandTotals.inserted_district += totals.inserted_district;
        grandTotals.already_exists += totals.already_exists;
        grandTotals.skipped += totals.skipped;
        grandTotals.errors += totals.errors;
      } catch (err) {
        console.error(`\n[load-state-tiger] FAILED on layer '${layer}': ${(err as Error).message}`);
        throw err;
      }
    }
  } finally {
    await client.end();
  }

  console.log('\n=== Per-shapefile Summary ===');
  for (const { layer, totals } of perLayer) {
    const def = LAYER_DISPATCH[layer];
    console.log(`\n  ${layer} (${def.mtfcc} → ${def.district_type}):`);
    console.log(`    Inserted (boundaries): ${totals.inserted_boundary}`);
    console.log(`    Inserted (districts):  ${totals.inserted_district}`);
    console.log(`    Already existed:       ${totals.already_exists}`);
    console.log(`    Skipped (placeholder): ${totals.skipped}`);
    console.log(`    Errors:                ${totals.errors}`);
  }

  console.log('\n=== Grand Total ===');
  console.log(`  Inserted (boundaries): ${grandTotals.inserted_boundary}`);
  console.log(`  Inserted (districts):  ${grandTotals.inserted_district}`);
  console.log(`  Already existed:       ${grandTotals.already_exists}`);
  console.log(`  Skipped (placeholder): ${grandTotals.skipped}`);
  console.log(`  Errors:                ${grandTotals.errors}`);

  console.log('\nLoad complete.');
  console.log('Verify with:');
  console.log(
    `  SELECT mtfcc, COUNT(*) FROM essentials.geofence_boundaries\n   WHERE state = '${args.fips}' GROUP BY mtfcc ORDER BY mtfcc;`,
  );
}

main().catch((err) => {
  console.error('[load-state-tiger] Fatal error:', err);
  process.exit(1);
});

// ─── Exports for testing (no-op at runtime) ──────────────────────────────────
export {
  STATE_LAYER_ALLOWLIST,
  STATE_CITY_ASSERTIONS,
  STATE_RUN_MAKEVALID,
  UT_TRIBE_NAMELSAD_ALLOWLIST,
  UNSAFE_LAYERS,
  FIPS_TO_STATE,
  LAYER_DISPATCH,
  NAMELSAD_CANDIDATES,
  GEOID_CANDIDATES,
  buildOcdId,
  resolveColumn,
  slugifyName,
  processLayer,
  downloadWithRedirects,
  extractZip,
  streamShapefile,
  upsertGeofence,
  insertDistrictIfMissing,
  parseArgs,
};
