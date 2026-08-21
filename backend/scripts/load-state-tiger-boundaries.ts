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
import { pathToFileURL } from 'url';
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
  OR: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  MD: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  VA: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  NV: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  AZ: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  // WI. sldu/sldl: the 2024-vintage TIGER set was verified to be the 2023 Wisconsin Act 94
  // remap (enacted 2024-02-19) via identity-anchor probes against TIGERweb: Burlington ->
  // AD 33 / SD 11, downtown Racine -> AD 62 / SD 21, Sturtevant -> AD 66 / SD 22, with the
  // Assembly-into-Senate nesting internally consistent.
  // place/cousub: Wisconsin is a strong-MCD state — its 1,850 towns/villages/cities are ALL
  // elected governments, so cousub carries real bodies here (unlike CA's statistical CCDs)
  // and WI is added to COUSUB_FUNCSTAT_STATES below. Incorporated municipalities appear in
  // BOTH layers (Racine is place 5566000 AND an MCD); towns appear ONLY in cousub.
  // school: all THREE tiers are loaded together on purpose. WI is a union-high-school state,
  // so unsd alone under-covers it — rural Racine County sits in an elementary district AND a
  // union high district, i.e. two separate elected boards. elsd/scsd layer support was added
  // for exactly this.
  WI: new Set(['sldu', 'sldl', 'place', 'cousub', 'unsd', 'elsd', 'scsd']),
  // WA. place: Washington's incorporated cities and towns are elected governments.
  // cousub is deliberately EXCLUDED — WA county subdivisions are statistical CCDs,
  // not elected bodies, same as CA. Do NOT add WA to COUSUB_FUNCSTAT_STATES.
  // sldu/sldl: WA has 49 legislative districts, each electing ONE senator and TWO
  // representatives (Position 1 / Position 2) over the SAME boundary — the same
  // multi-member shape as AZ. TIGER SLDL is therefore 49 polygons covering 98
  // seats, NOT 98 polygons. Counts asserted in the WA pre-flight block below.
  // cd119 (10) and county (39) are already loaded for WA and are not re-run here.
  WA: new Set(['place', 'sldu', 'sldl']),
  // CO. sldu/sldl: Colorado has 35 Senate and 65 House districts as DISTINCT polygons —
  // single-member in both chambers, so the polygon count equals the seat count (unlike
  // AZ/WA, where one SLDL polygon carries two seats). Measured 2026-08-21 against TIGER
  // 2024 FIPS 08: 35 / 65 with NO 'ZZZ' pseudo-district in either file, so the skip rule
  // is a no-op here rather than the -1 it is in WI.
  // VINTAGE IS CORRECT AS PLAIN TIGER 2024: Colorado's independent-commission map has been
  // in effect since 2021 and the state did NOT redistrict mid-decade, so these are the maps
  // governing the 2026 election. This is why CO gets G5210/G5220 and NOT the 'G5200V26'
  // vintage-tagged treatment used by the states that redrew (whose sources read like
  // 'al_sos_2026') — that suffix is a congressional-only convention.
  // place: Colorado's incorporated cities and towns are elected governments. 272 G4110
  // records; the 210 G4210 CDPs in the same file are statistical and are filtered out.
  // cousub is deliberately EXCLUDED — CO county subdivisions are statistical CCDs, not
  // elected bodies, same as CA and WA. Do NOT add CO to COUSUB_FUNCSTAT_STATES.
  // cd/cd119 and county are NOT re-run here: prod already holds 8 G5200 congressional and
  // 64 G4020 county polygons for FIPS 08.
  CO: new Set(['sldu', 'sldl', 'place']),
  DC: new Set(['sldl']),
};

// STATE_LAYER_TYPE_MAP: override layerDef.district_type for the insertDistrictIfMissing
// call when a state uses a non-standard district type for a TIGER layer.
// DC sldl polygons are ward boundaries (CITY_COUNCIL), not STATE_LOWER.
const STATE_LAYER_TYPE_MAP: Record<string, Record<string, string>> = {
  DC: { sldl: 'CITY_COUNCIL' },
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
  OR: ['Portland city'],
  MD: ['Baltimore city'],
  VA: ['Alexandria city'],
  NV: ['Las Vegas city', 'Henderson city', 'North Las Vegas city', 'Boulder City city'],
  AZ: ['Tucson city', 'Oro Valley town', 'Marana town', 'Sahuarita town', 'South Tucson city'],
  // Racine County's incorporated municipalities — verified present in TIGER 2024 FIPS 55
  // place (all G4110, FUNCSTAT='A') before wiring this gate.
  WI: ['Racine city', 'Burlington city', 'Mount Pleasant village', 'Caledonia village',
       'Sturtevant village', 'Union Grove village'],
  // El Paso County's incorporated municipalities plus the Colorado Springs wave's own
  // subject. Every string verified present in TIGER 2024 FIPS 08 place (all G4110,
  // FUNCSTAT='A') by direct probe 2026-08-21 before wiring this gate — Colorado Springs
  // city resolves to GEOID 0816000, which is the geo_id the city district row keys on.
  CO: ['Colorado Springs city', 'Manitou Springs city', 'Fountain city',
       'Monument town', 'Green Mountain Falls town'],
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
  OR: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  MD: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  VA: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  NV: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  AZ: new Set(['cd119', 'sldu', 'sldl', 'place', 'county']),
  WI: new Set(['sldu', 'sldl', 'place', 'cousub', 'unsd', 'elsd', 'scsd']),
  WA: new Set(['place', 'sldu', 'sldl']),
  CO: new Set(['sldu', 'sldl', 'place']),
  DC: new Set(['sldl']),
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
    // '00' is NOT a placeholder — at-large states (AK, DE, MT, ND, SD, VT, WY) use CD119FP='00'
    // for their single voting House member. Only ZZ/ZZZ/000 are TIGER placeholder codes.
    skipDistrictCodes: new Set(['ZZ', 'ZZZ', '000']),
    writeDistrictRow: true /* 130-01-PYTHON-AUDIT.md §"Open questions" #4 (Operational-parity recommendation, line "cd: writeDistricts=true (per existing TS)") */,
  },
  cd119: {
    mtfcc: 'G5200', district_type: 'NATIONAL_LOWER', ocdKey: 'congressional_district',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, c) => `https://www2.census.gov/geo/tiger/TIGER${v}/CD/tl_${v}_${f}_cd${c}.zip`,
    districtNumField: ['CD119FP', 'CDFP', 'CD118FP'],
    filterByStatefp: true,
    // '00' is NOT a placeholder — at-large states use CD119FP='00' for their voting member.
    skipDistrictCodes: new Set(['ZZ', 'ZZZ', '000']),
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
  // elsd/scsd complete the school picture that 'unsd' alone cannot cover.
  // States using the "union high school district" model — WI, CA, AZ, IL — split school
  // governance across TWO overlapping elected boards: an ELEMENTARY district (K-8) and a
  // SECONDARY / union-high district (9-12). A resident sits in BOTH, so loading only unsd
  // silently drops one of a voter's two school boards. Concretely in Racine County, rural
  // addresses fall in e.g. Waterford Joint No. 1 (elementary) AND Waterford Union High
  // (secondary), and NEITHER appears in the unsd layer.
  // Both mirror unsd exactly: same SCHOOL district_type, GEOID as geo_id, no district-number
  // field, and writeDistrictRow=false because school-board ingestion creates the districts
  // rows separately.
  elsd: {
    mtfcc: 'G5400', district_type: 'SCHOOL', ocdKey: 'school_district',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/ELSD/tl_${v}_${f}_elsd.zip`,
    districtNumField: null,
    filterByStatefp: false,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: false,
  },
  scsd: {
    mtfcc: 'G5410', district_type: 'SCHOOL', ocdKey: 'school_district',
    geoIdSource: 'GEOID',
    urlTemplate: (v, f, _c) => `https://www2.census.gov/geo/tiger/TIGER${v}/SCSD/tl_${v}_${f}_scsd.zip`,
    districtNumField: null,
    filterByStatefp: false,
    skipDistrictCodes: new Set<string>(),
    writeDistrictRow: false,
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
function downloadWithRedirects(url: string, destPath: string, redirectDepth = 0): Promise<void> {
  return new Promise((resolve, reject) => {
    if (redirectDepth > 5) {
      return reject(new Error(`Too many redirects (>5) for ${url}`));
    }
    if (fs.existsSync(destPath)) {
      return resolve();
    }
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        const location = response.headers.location;
        if (!location) {
          return reject(new Error(`Redirect response (${response.statusCode}) for ${url} missing Location header`));
        }
        return downloadWithRedirects(location, destPath, redirectDepth + 1).then(resolve).catch(reject);
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
  // `parish` = Louisiana's county-equivalent; `planning region`/`region` =
  // Connecticut's 2022 TIGER re-classification of its former counties (both
  // appear in nationwide county-layer NAMELSAD values — D-XX nationwide mode).
  const stripTokens = /\s+(county|parish|planning region|region|city|town|village|borough|township|cdp)\b\.?\s*$/i;
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
  if (!abbrev) {
    throw new Error(`FIPS ${fips} not found in FIPS_TO_STATE — cannot derive state abbreviation`);
  }
  const abbrevUpper = abbrev.toUpperCase(); // 'CA' — what the existing TS loaders write to essentials.districts.state

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
  extractZip(zipPath, destDir); // cleanup() intentionally not called — extracted dirs cached for re-runs

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

  // ── OR MTFCC pre-flight assertion (Phase 72) ────────────────────────────────
  // For OR (state='41'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  if (fipsArg === '41') {
    const EXPECTED_OR_MTFCC: Record<string, number> = {
      cd119: 6,   // 6 OR congressional districts (post-2022 redistricting)
      sldu:  30,  // 30 OR Senate districts
      sldl:  60,  // 60 OR House districts
      place: 241, // 241 OR G4110 incorporated cities (confirmed via dry-run 2026-05-28)
      county: 36, // 36 OR counties
    };
    if (layer in EXPECTED_OR_MTFCC) {
      const expected = EXPECTED_OR_MTFCC[layer];
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
          `[OR MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 41 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] OR MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── MD MTFCC pre-flight assertion (Phase 91) ────────────────────────────────
  // For MD (state='24'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  // sldl and place values are set to 0 so dry-run MtfccAssertionError reveals actual count.
  // Plan 02 updates these values before the live load.
  if (fipsArg === '24') {
    const EXPECTED_MD_MTFCC: Record<string, number> = {
      cd119:  8,    // 8 MD congressional districts (post-2022 redistricting)
      sldu:  47,    // 47 MD Senate districts (1 senator each)
      sldl:  71,    // confirmed via dry-run 2026-06-05 — 71 MD SLDL sub-district polygons (NOT 141 delegates; NOT 47 senate districts)
      place: 157,   // confirmed via dry-run 2026-06-05 — 157 MD G4110 incorporated places (TIGER 2024 G4110-only; TIGERweb 311 count included G4210 CDPs)
      county: 24,   // 24 MD counties (23 counties + Baltimore City as independent city-county)
    };
    if (layer in EXPECTED_MD_MTFCC) {
      const expected = EXPECTED_MD_MTFCC[layer];
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
          `[MD MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 24 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] MD MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── VA MTFCC pre-flight assertion (Phase 100) ──────────────────────────────
  // For VA (state='51'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  // sldl and place values are set to 0 so dry-run MtfccAssertionError reveals actual count.
  // Plan 02 updates these values before the live load.
  //
  // sldl and sldu TIGER shapefiles are state-scoped (FIPS 51 in filename);
  // filterByStatefp is false for these layers — no STATEFP filter in pre-flight count.
  if (fipsArg === '51') {
    const EXPECTED_VA_MTFCC: Record<string, number> = {
      cd119: 11,   // 11 VA congressional districts (post-2022 redistricting)
      sldu:  40,   // 40 VA Senate districts (1 senator each)
      sldl: 100,   // confirmed via dry-run 2026-06-08 — 100 VA G5220 single-member House of Delegates polygons
      place: 227,  // confirmed via dry-run 2026-06-08 — 227 VA G4110 incorporated places
      county: 133, // 133 VA county-equivalents: 95 counties + 38 independent cities
    };
    if (layer in EXPECTED_VA_MTFCC) {
      const expected = EXPECTED_VA_MTFCC[layer];
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
          `[VA MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 51 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] VA MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── NV MTFCC pre-flight assertion (Phase 158) ───────────────────────────────
  // For NV (state='32'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  // sldl and place values are set to 0 so dry-run MtfccAssertionError reveals actual count.
  // Plan 02 updates these values before the live load.
  //
  // sldl and sldu TIGER shapefiles are state-scoped (FIPS 32 in filename);
  // filterByStatefp is false for these layers — no STATEFP filter in pre-flight count.
  if (fipsArg === '32') {
    const EXPECTED_NV_MTFCC: Record<string, number> = {
      cd119: 4,   // 4 NV congressional districts (post-2022 redistricting)
      sldu:  21,  // 21 NV State Senate districts, single-member
      sldl: 42,   // confirmed via dry-run 2026-06-23 — 42 NV G5220 single-member Assembly polygons
      place: 19,  // confirmed via dry-run 2026-06-23 — 19 NV G4110 incorporated places
      county: 17, // 16 NV counties + Carson City as an independent city-county = 17 county-equivalents
    };
    if (layer in EXPECTED_NV_MTFCC) {
      const expected = EXPECTED_NV_MTFCC[layer];
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
          `[NV MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 32 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] NV MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── AZ MTFCC pre-flight assertion (Phase 190) ───────────────────────────────
  // For AZ (state='04'), count records satisfying the same filters as the upsert
  // pass BEFORE any DB write. Assertion failure is named and fatal.
  // sldl and place values start at 0 so dry-run MtfccAssertionError reveals actual count.
  // Plan 01 Task 3 updates these values with the confirmed dry-run counts.
  //
  // sldl and sldu TIGER shapefiles are state-scoped (FIPS 04 in filename);
  // filterByStatefp is false for these layers — no STATEFP filter in pre-flight count.
  // D-04: AZ has 30 legislative districts, each electing 1 senator + 2 house reps;
  // TIGER SLDL therefore has 30 polygons (one per district, shared by 2 house seats), NOT 60.
  if (fipsArg === '04') {
    const EXPECTED_AZ_MTFCC: Record<string, number> = {
      cd119: 9,   // 9 AZ congressional districts
      sldu:  30,  // 30 AZ legislative districts (single senator each)
      sldl: 30,   // confirmed via read-only shapefile count 2026-07-08 — 30 AZ G5220 legislative-district polygons (2 house seats per district, one polygon; D-04)
      place: 91,  // confirmed via read-only shapefile count 2026-07-08 — 91 AZ G4110 incorporated municipalities
      county: 15, // 15 AZ counties; NO independent cities (unlike VA/NV)
    };
    if (layer in EXPECTED_AZ_MTFCC) {
      const expected = EXPECTED_AZ_MTFCC[layer];
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
          `[AZ MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 04 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] AZ MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── WA MTFCC pre-flight assertion ───────────────────────────────────────────
  // Count records satisfying the same filters as the upsert pass BEFORE any DB
  // write. Assertion failure is named and fatal.
  //
  // WA has the same multi-member shape as AZ: 49 legislative districts, each
  // electing 1 senator + 2 representatives (Position 1 / Position 2) over the
  // SAME boundary. TIGER SLDL is therefore 49 polygons covering 98 seats, NOT 98.
  //
  // NOTE the MTFCC assignment is INVERTED relative to the plain TIGER reading,
  // confirmed by dry-run 2026-08-13: sldu → G5210 (STATE_UPPER),
  // sldl → G5220 (STATE_LOWER). Same as CA/VA/NV/AZ in this loader.
  //
  if (fipsArg === '53') {
    const EXPECTED_WA_MTFCC: Record<string, number> = {
      sldu:   49,  // confirmed via pre-flight assertion 2026-08-13 — 49 WA legislative districts (1 senator each)
      sldl:   49,  // confirmed via pre-flight assertion 2026-08-13 — 49 polygons covering 98 house seats (2 per district), NOT 98
      place: 281,  // confirmed via pre-flight assertion 2026-08-13 — 281 WA G4110 incorporated cities and towns
    };
    if (layer in EXPECTED_WA_MTFCC) {
      const expected = EXPECTED_WA_MTFCC[layer];
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
          `[WA MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 53 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] WA MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── CO MTFCC pre-flight assertion ───────────────────────────────────────────
  // Count records satisfying the same filters as the upsert pass BEFORE any DB
  // write. Assertion failure is named and fatal.
  //
  // Colorado is single-member in BOTH chambers, so unlike AZ/WA the polygon count
  // equals the seat count: 35 Senate, 65 House.
  //
  // ⚠ CO HOUSE DISTRICTS DO NOT NEST INSIDE SENATE DISTRICTS. Measured 2026-08-21
  // against the loaded polygons: only 13 of 65 House districts fall wholly within a
  // single Senate district, and there are 149 HD×SD overlaps above 0.1% of HD area.
  // (HD 18 alone spans SD 9, SD 11 and SD 12.) Wisconsin's 3-Assembly-per-Senate
  // nesting is NOT the general rule and must not be assumed here: a resident's
  // Senate district CANNOT be derived from their House district. Both layers have to
  // be resolved independently by ST_Covers, which is what address search already does.
  //
  // Counts are MEASURED, not assumed — probed directly against TIGER 2024 FIPS 08
  // on 2026-08-21 (sldu 35/35 kept, sldl 65/65 kept, place 482 total → 272 G4110
  // kept and 210 G4210 CDPs filtered). Neither SLD file carries a 'ZZZ'
  // pseudo-district, so skipDistrictCodes removes nothing here.
  //
  if (fipsArg === '08') {
    const EXPECTED_CO_MTFCC: Record<string, number> = {
      sldu:   35,  // 35 CO Senate districts (2021 commission map) — measured 2026-08-21, no 'ZZZ' row
      sldl:   65,  // 65 CO House districts  (2021 commission map) — measured 2026-08-21, no 'ZZZ' row
      place: 272,  // 272 CO G4110 incorporated cities/towns; the file's other 210 records are G4210 CDPs
    };
    if (layer in EXPECTED_CO_MTFCC) {
      const expected = EXPECTED_CO_MTFCC[layer];
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
          `[CO MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 08 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] CO MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // ── WI MTFCC pre-flight assertion ───────────────────────────────────────────
  // Count records satisfying the same filters as the upsert pass BEFORE any DB
  // write. Assertion failure is named and fatal.
  //
  // Unlike AZ (30 districts, 2 house seats sharing one SLDL polygon), Wisconsin
  // has 33 Senate districts and 99 Assembly districts as DISTINCT polygons —
  // each WI Senate district nests exactly 3 Assembly districts, so the counts
  // are 33 and 99, NOT 33 and 33. Expected counts cross-checked against
  // TIGERweb (STATE='55'), which reports 34 SLDU / 100 SLDL features: the extra
  // row in each is TIGER's "not defined" pseudo-district (SLDUST/SLDLST='ZZZ'),
  // removed here by layerDef.skipDistrictCodes.
  if (fipsArg === '55') {
    const EXPECTED_WI_MTFCC: Record<string, number> = {
      sldu:     33,  // 33 WI Senate districts (Act 94 map; TIGERweb 34 minus 1 'ZZZ')
      sldl:     99,  // 99 WI Assembly districts (Act 94 map; TIGERweb 100 minus 1 'ZZZ')
      place:   607,  // 607 WI G4110 incorporated cities/villages, all FUNCSTAT='A'. The 2024
                     //   PLACE file bundles 607 G4110 + 201 G4210 CDPs = 808 records; the
                     //   MTFCC filter drops the CDPs. TIGERweb's current vintage reports 608
                     //   incorporated places, ONE more than 2024: Greenleaf (5531375) was a
                     //   CDP in 2024 and has since incorporated as a village. Brown County,
                     //   so it does not affect Racine; it will appear when the vintage moves.
      cousub: 1243,  // 1243 ACTIVE WI MCDs (towns/villages/cities) out of 1925 records; the
                     //   682 FUNCSTAT='F' placeholders are skipped by the FUNCSTAT='A' filter,
                     //   which is why WI is in COUSUB_FUNCSTAT_STATES. TIGERweb's current
                     //   vintage reports 1242 active, ONE fewer than 2024: Williamstown town
                     //   (5502787225, Dodge County) was active in 2024 and no longer is.
                     //   Dodge County, so it does not affect Racine.
      unsd:    369,  // 369 WI G5420 unified school districts
      elsd:     43,  // 43 WI G5400 ELEMENTARY school districts (K-8)
      scsd:     10,  // 10 WI G5410 SECONDARY / union-high districts (9-12). Small on purpose:
                     //   only union-high states have these at all. Racine County's two are
                     //   Union Grove UHS and Waterford UHS.
    };
    if (layer in EXPECTED_WI_MTFCC) {
      const expected = EXPECTED_WI_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
        }
        // Mirror the upsert pass's filters exactly, or the count means nothing.
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
          `[WI MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify the TIGER 2024 FIPS 55 file ` +
          `is the 2023 Act 94 map (33 Senate / 99 Assembly districts).`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] WI MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }

  // For DC (FIPS '11'): 8 ward polygons in the sldl layer (TIGER 2024).
  if (fipsArg === '11') {
    const EXPECTED_DC_MTFCC: Record<string, number> = {
      sldl: 8,  // 8 DC ward polygons (TIGER 2024 FIPS 11, mtfcc G5220)
    };
    if (layer in EXPECTED_DC_MTFCC) {
      const expected = EXPECTED_DC_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
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
          `[DC MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 11 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] DC MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
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
      // WI is an MCD state like MA: its county subdivisions are towns/villages/cities with
      // real elected boards (FUNCSTAT='A'). Without this filter WI imports 1,925 records
      // instead of 1,242 — 683 inactive placeholders that have no government at all.
      const COUSUB_FUNCSTAT_STATES = new Set(['MA', 'WI']);
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
        const effectiveDistrictType = STATE_LAYER_TYPE_MAP[abbrevUpper]?.[layer] ?? layerDef.district_type;
        // eslint-disable-next-line max-len
        const districtResult = await insertDistrictIfMissing(client, { geo_id, ocd_id, name, state: abbrev, district_type: effectiveDistrictType, mtfcc: layerDef.mtfcc });
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

// ─── Nationwide county mode (county layer ONLY) ──────────────────────────────
//
// Counties are the one TIGER layer sourced from a single national file
// (tl_${vintage}_us_county.zip); every other layer (cd/sldu/sldl/place/etc.)
// is state-scoped and MUST keep going through processLayer's per-state
// --fips filter — this mode is deliberately not offered for them. Nationwide
// mode skips the `filterByStatefp` discard so all county records are
// processed in one download+parse pass instead of once per state.
//
// Two safety properties beyond processLayer's per-state assertions:
//  1. ST_MakeValid runs UNCONDITIONALLY (not gated by STATE_RUN_MAKEVALID) —
//     coastal/AK polygons in the national file otherwise produce invalid
//     geometry that breaks downstream ST_Intersects (getCountyUnionFrames).
//  2. A pre-flight national row-count assertion runs BEFORE any DB write,
//     using a bound (not an exact count, per PYTHON-AUDIT-style pre-flight
//     discipline) because the raw file also carries Puerto Rico + island-area
//     county-equivalents that FIPS_TO_STATE doesn't map (this loader only
//     supports the 50 states + DC); those records are counted separately and
//     skipped rather than inserted, not treated as an error.
//
// STRUCTURAL zero-write guarantee (not just a code trace): the download +
// parse + pre-flight count/validate step below (`countAndValidateNationwideCounties`)
// takes NO `Client` parameter — it is impossible for it to issue a DB write,
// not merely unlikely. `main()` calls this helper directly for `--dry-run` and
// NEVER constructs a `pg.Client` on that path at all. Only after this helper
// resolves successfully (in live mode) does `main()` construct a `Client` and
// hand it to `processNationwideCounty` for the write pass. `processNationwideCounty`
// itself also re-runs the validation before touching `client.query`, so even a
// direct call with `dryRun: true` and a real/fake client can never reach a write.
const NATIONWIDE_COUNTY_COUNT_BOUNDS = { min: 3050, max: 3200 } as const; // ~3,143 for 50 states + DC

interface NationwideCountyTotals extends LayerTotals {
  /** Records parsed with a STATEFP this loader supports (50 states + DC). */
  parsedCount: number;
  /** Records whose STATEFP isn't in FIPS_TO_STATE (PR / island areas) — skipped, not an error. */
  territoryCount: number;
}

interface NationwideCountyValidation {
  parsedCount: number;
  territoryCount: number;
}

/**
 * Source of nationwide county records: streams every feature from the national
 * TIGER county shapefile via `onRecord`. Injectable so tests can supply an
 * in-memory fixture instead of hitting the network/filesystem — see
 * `defaultNationwideCountySource` for the real (download + extract + stream)
 * implementation used in production.
 */
type NationwideCountyRecordSource = (
  layerDef: LayerDef,
  vintage: string,
  onRecord: (geom: unknown, props: Record<string, unknown>) => Promise<void>,
) => Promise<void>;

async function defaultNationwideCountySource(
  layerDef: LayerDef,
  vintage: string,
  onRecord: (geom: unknown, props: Record<string, unknown>) => Promise<void>,
): Promise<void> {
  const url = layerDef.urlTemplate(vintage, 'us', '');
  const tmpRoot = path.join(process.cwd(), `.tmp-tiger-${vintage}-us-county-nationwide`);
  fs.mkdirSync(tmpRoot, { recursive: true });
  const baseName = path.basename(url, '.zip'); // tl_${vintage}_us_county
  const zipPath = path.join(tmpRoot, `${baseName}.zip`);
  const destDir = path.join(tmpRoot, baseName);

  console.log(`  [county:nationwide] downloading ${url}`);
  await downloadWithRedirects(url, zipPath);
  console.log(`  [county:nationwide] extracting ${path.basename(zipPath)}`);
  extractZip(zipPath, destDir); // cleanup() intentionally not called — cached for re-runs, mirrors processLayer

  const entries = fs.readdirSync(destDir);
  const shpFile = entries.find((e) => e.toLowerCase().endsWith('.shp'));
  const dbfFile = entries.find((e) => e.toLowerCase().endsWith('.dbf'));
  if (!shpFile || !dbfFile) {
    throw new Error(`[county:nationwide] could not locate .shp/.dbf in ${destDir} (entries: ${entries.join(', ')})`);
  }
  await streamShapefile(path.join(destDir, shpFile), path.join(destDir, dbfFile), onRecord);
}

/**
 * Download + parse + pre-flight national row-count assertion for the
 * nationwide county load. Takes NO `Client` — this is the structural half of
 * the zero-write guarantee: this function is physically incapable of writing
 * to the database, not merely trusted not to. Throws (named `MtfccAssertionError`)
 * if the parsed count falls outside `NATIONWIDE_COUNTY_COUNT_BOUNDS`, BEFORE
 * any caller has a chance to construct a `Client`.
 */
async function countAndValidateNationwideCounties(
  layerDef: LayerDef,
  vintage: string,
  recordSource: NationwideCountyRecordSource = defaultNationwideCountySource,
): Promise<NationwideCountyValidation> {
  let parsedCount = 0;
  let territoryCount = 0;

  console.log(`  [county:nationwide] streaming for pre-flight count (vintage ${vintage})`);
  await recordSource(layerDef, vintage, async (_geom, props) => {
    const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
    const statefp = String(props[statefpKey] ?? '');
    if (FIPS_TO_STATE[statefp]) parsedCount++;
    else territoryCount++;
  });
  console.log(
    `  [county:nationwide] parsed ${parsedCount} county-equivalent records for supported states ` +
    `(${territoryCount} territory/unmapped-FIPS records excluded, e.g. Puerto Rico).`,
  );

  if (parsedCount < NATIONWIDE_COUNTY_COUNT_BOUNDS.min || parsedCount > NATIONWIDE_COUNTY_COUNT_BOUNDS.max) {
    const err = new Error(
      `[county:nationwide] national row-count assertion FAILED: parsed ${parsedCount} records, ` +
      `expected between ${NATIONWIDE_COUNTY_COUNT_BOUNDS.min} and ${NATIONWIDE_COUNTY_COUNT_BOUNDS.max} ` +
      `(~3,143 county-equivalents for the 50 states + DC). Vintage: ${vintage}. Aborting before any DB write — ` +
      `verify the TIGER ${vintage} national county file is correct.`,
    );
    err.name = 'MtfccAssertionError';
    throw err;
  }
  console.log(`  [county:nationwide] row-count assertion PASSED (bounds ${NATIONWIDE_COUNTY_COUNT_BOUNDS.min}-${NATIONWIDE_COUNTY_COUNT_BOUNDS.max}).`);

  return { parsedCount, territoryCount };
}

async function processNationwideCounty(
  client: Client,
  layerDef: LayerDef,
  vintage: string,
  dryRun: boolean,
  recordSource: NationwideCountyRecordSource = defaultNationwideCountySource,
): Promise<NationwideCountyTotals> {
  const totals: NationwideCountyTotals = {
    inserted_boundary: 0,
    inserted_district: 0,
    already_exists: 0,
    skipped: 0,
    errors: 0,
    parsedCount: 0,
    territoryCount: 0,
  };

  // ── Count + validate FIRST, before any branch that could touch `client` ────
  // This call cannot issue a DB write (see countAndValidateNationwideCounties
  // doc comment) — so even if `dryRun` is wrong or `client` is garbage, nothing
  // is written until this resolves successfully.
  const validation = await countAndValidateNationwideCounties(layerDef, vintage, recordSource);
  totals.parsedCount = validation.parsedCount;
  totals.territoryCount = validation.territoryCount;

  if (dryRun) {
    console.log(
      `  [dry-run] county:nationwide — would write rows for ${totals.parsedCount} records ` +
      `(ST_MakeValid unconditional; ${totals.territoryCount} territory records would be skipped). No DB writes made.`,
    );
    return totals;
  }

  // ── Write pass (only reachable after a passing count/validate) ─────────────
  await recordSource(layerDef, vintage, async (geom, props) => {
    try {
      const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
      const statefp = String(props[statefpKey] ?? '');
      const abbrev = FIPS_TO_STATE[statefp];
      if (!abbrev) {
        totals.skipped++; // territory / unmapped FIPS — not one of the 50 states + DC this loader supports
        return;
      }
      const abbrevUpper = abbrev.toUpperCase();

      const geoidKey = resolveColumn(props, GEOID_CANDIDATES);
      const geo_id = String(props[geoidKey] ?? '');
      const namelsadKey = resolveColumn(props, NAMELSAD_CANDIDATES);
      const name = String(props[namelsadKey] ?? '');
      // ocdSuffix = lowercased NAME slug, mirroring processLayer's 'county' case.
      const ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, slugifyName(name));

      const upsertResult = await upsertGeofence(client, {
        geo_id,
        ocd_id,
        name,
        state: statefp,
        mtfcc: layerDef.mtfcc,
        geometryGeoJson: geom,
        runMakeValid: true, // unconditional in nationwide mode — see module doc above
      });
      if (upsertResult.inserted) totals.inserted_boundary++;
      else totals.already_exists++;

      if (layerDef.writeDistrictRow) {
        const districtResult = await insertDistrictIfMissing(client, {
          geo_id,
          ocd_id,
          name,
          state: abbrev,
          district_type: layerDef.district_type,
          mtfcc: layerDef.mtfcc,
        });
        if (districtResult.inserted) totals.inserted_district++;
      }
    } catch (err) {
      console.error(`  [county:nationwide] record error: ${(err as Error).message}`);
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
  /** county-layer-only nationwide load mode: `--nationwide` or `--fips ALL`. */
  nationwide: boolean;
}

function parseArgs(argv: string[]): CliArgs {
  const args: Record<string, string | boolean> = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') {
      args.dryRun = true;
      continue;
    }
    if (a === '--nationwide') {
      args.nationwide = true;
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

  const stateRaw = typeof args.state === 'string' ? args.state.toUpperCase() : '';
  const fipsRaw = typeof args.fips === 'string' ? args.fips : '';
  const layersRaw = typeof args.layers === 'string' ? args.layers : '';
  const dryRun = args.dryRun === true;
  const vintage = typeof args.vintage === 'string' ? args.vintage : '2024';
  const congress = typeof args.congress === 'string' ? args.congress : '119';

  // Nationwide county mode: `--nationwide` or `--fips ALL` (case-insensitive).
  // County is the ONE layer sourced from a single national TIGER file; every
  // other layer stays state-scoped and must go through the normal --state/--fips path.
  const nationwide = args.nationwide === true || fipsRaw.toUpperCase() === 'ALL';

  if (nationwide) {
    if (!layersRaw) {
      process.stderr.write('--layers required: nationwide mode only supports --layers county\n');
      process.exit(1);
    }
    const nwLayers = layersRaw.split(',').map((s) => s.trim()).filter(Boolean);
    if (nwLayers.length !== 1 || nwLayers[0] !== 'county') {
      process.stderr.write(
        `--nationwide (or --fips ALL) only supports the county layer (got '${layersRaw}'). ` +
        `sldu/sldl/place/cd/etc. are state-scoped and require an explicit --state/--fips.\n`,
      );
      process.exit(1);
    }
    return { state: 'US', fips: 'ALL', layers: nwLayers, dryRun, vintage, congress, nationwide: true };
  }

  const state = stateRaw;
  const fips = fipsRaw;

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

  return { state, fips, layers, dryRun, vintage, congress, nationwide: false };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  // ── Nationwide county mode: separate dispatch path (county layer only) ─────
  if (args.nationwide) {
    console.log(`[load-state-tiger] Mode: ${args.dryRun ? 'DRY-RUN (no DB writes)' : 'LIVE'} — NATIONWIDE county load`);
    console.log(`[load-state-tiger] Vintage: ${args.vintage}`);

    const layerDef = LAYER_DISPATCH.county;

    // Structural zero-write guarantee: the dry-run branch calls ONLY the
    // client-free count/validate helper. There is no `Client` construction
    // anywhere in this branch — not "unused", genuinely absent — so a
    // --dry-run invocation cannot open a DB connection, let alone write.
    if (args.dryRun) {
      const validation = await countAndValidateNationwideCounties(layerDef, args.vintage);
      console.log('\n=== Nationwide County Dry-Run Summary ===');
      console.log(`  Parsed (supported states + DC): ${validation.parsedCount}`);
      console.log(`  Territory/unmapped FIPS (excluded): ${validation.territoryCount}`);
      console.log(
        `  [dry-run] county:nationwide — would write rows for ${validation.parsedCount} records ` +
        `(ST_MakeValid unconditional; ${validation.territoryCount} territory records would be skipped). No DB writes made.`,
      );
      console.log('\nDRY-RUN complete — no database writes made.');
      process.exit(0);
    }

    // Live mode: the count/validate assertion above only ran on the dry-run
    // branch, which just returned. Here we haven't validated yet, so
    // processNationwideCounty (called below with a freshly-constructed
    // Client) re-runs count/validate itself BEFORE issuing any client.query —
    // the Client only becomes reachable for writes after that passes.

    if (!process.env.DATABASE_URL) {
      process.stderr.write('ERROR: DATABASE_URL is not set\n');
      process.exit(1);
    }

    const nwClient = new Client({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });
    await nwClient.connect();

    let totals: NationwideCountyTotals;
    try {
      totals = await processNationwideCounty(nwClient, layerDef, args.vintage, false);
    } finally {
      await nwClient.end();
    }

    console.log('\n=== Nationwide County Summary ===');
    console.log(`  Inserted (boundaries): ${totals.inserted_boundary}`);
    console.log(`  Inserted (districts):  ${totals.inserted_district}`);
    console.log(`  Already existed:       ${totals.already_exists}`);
    console.log(`  Skipped (territory/unmapped FIPS): ${totals.skipped}`);
    console.log(`  Errors:                ${totals.errors}`);
    console.log('\nLoad complete.');
    console.log('Verify with:');
    console.log(
      `  SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc = 'G4020';`,
    );
    return;
  }

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

  // Nothing else in the codebase refreshes essentials.geofence_child_county — it is only READ, by
  // coverageMapService, and only CHECKED, by scripts/check-child-county-mapping.mjs. So inserting
  // boundaries here silently leaves it stale, every affected jurisdiction shows with NO county on
  // the coverage dashboard, and CI goes red on a later, unrelated commit.
  // That is not hypothetical: the 2026-08-14 Washington load added 281 G4110 places and left CI red
  // until it was refreshed by hand. Say so loudly whenever this run actually inserted a boundary.
  if (grandTotals.inserted_boundary > 0) {
    console.log('\n=== ⚠ ACTION REQUIRED: refresh the persisted child→county mapping ===');
    console.log(`  This run inserted ${grandTotals.inserted_boundary} boundary/ies. Until the matview is`);
    console.log('  refreshed they will show with NO county on the coverage dashboard, and');
    console.log('  `npm run check:child-county` (which CI runs on every push) will FAIL.');
    console.log('\n  REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;');
    console.log('\n  ~17 s. CONCURRENTLY cannot run inside a transaction block. Requires ownership of');
    console.log('  the matview, so run it as postgres, not as ev_api. Then confirm with:');
    console.log('    npm run check:child-county   -> expect "stale 0"');
  }
}

// Only auto-run when executed directly (`npx tsx scripts/load-state-tiger-boundaries.ts ...`).
// Guards against side effects (main() calling process.exit) when this module is
// imported for unit testing pure helpers like slugifyName.
const isMainModule = (() => {
  try {
    // Must use pathToFileURL, NOT a `file://${argv[1]}` template. On Windows
    // argv[1] is a backslash drive path (C:\...\x.ts) while import.meta.url is
    // file:///C:/.../x.ts — the template can never match, so main() silently
    // never ran and every invocation exited 0 with no output.
    return import.meta.url === pathToFileURL(process.argv[1]).href;
  } catch {
    return false;
  }
})();
if (isMainModule) {
  main().catch((err) => {
    console.error('[load-state-tiger] Fatal error:', err);
    process.exit(1);
  });
}

// ─── Exports for testing (no-op at runtime) ──────────────────────────────────
export type { NationwideCountyRecordSource, LayerDef };
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
  processNationwideCounty,
  countAndValidateNationwideCounties,
  NATIONWIDE_COUNTY_COUNT_BOUNDS,
  downloadWithRedirects,
  extractZip,
  streamShapefile,
  upsertGeofence,
  insertDistrictIfMissing,
  parseArgs,
};
