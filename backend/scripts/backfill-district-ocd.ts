#!/usr/bin/env -S npx tsx
/**
 * backfill-district-ocd.ts — synthesize a usable ocd_id for districts that have
 * a geo_id but no ocd_id, so the ~444 real officeholders they carry (US Senate,
 * governors, CA/ME/MA/OR locals, …) become visible to the coverage tracker.
 *
 *   npx tsx scripts/backfill-district-ocd.ts                 # dry run — ALL types
 *   npx tsx scripts/backfill-district-ocd.ts --type national_upper
 *   npx tsx scripts/backfill-district-ocd.ts --type local --state wi        # scope to one state
 *   npx tsx scripts/backfill-district-ocd.ts --type national_upper --write   # apply
 *
 * SAFE: address search joins geofence_boundaries.geo_id = districts.geo_id (+ mtfcc)
 * and NEVER reads ocd_id (verified). ocd_id is read only by coverageService. So this
 * changes coverage visibility only — not who appears when a voter searches an address.
 *
 * Only touches rows where ocd_id IS NULL/'' (never overwrites a valid ocd_id).
 * Dry run by default; --write applies and prints every (district_id, old → new).
 *
 * Synthesis rules by district_type:
 *   NATIONAL_UPPER, STATE_EXEC        -> ocd-division/country:us/state:<xx>            (statewide / exact)
 *   LOCAL, LOCAL_EXEC                 -> .../state:<xx>/place:<slug>                    (G4110 place geofence)
 *                                     -> .../state:<xx>/place:<slug>/ward:<n>           (council/supervisor ward layer)
 *   SCHOOL                            -> .../state:<xx>/school_district:<slug>          (parent LEA; board-subdistricts roll up)
 *   COUNTY                            -> .../state:<xx>/county:<slug>                   (FIPS-5 → county name; districts roll up)
 *   NATIONAL_JUDICIAL, JUDICIAL, ...  -> SKIP (no OCD geography)
 *
 * Deferred-tier resolution (added 2026-05-30):
 *   - LOCAL councils that point at a custom X-layer geofence (not G4110) are ward-aware:
 *     place comes from the geo_id slug prefix (sf/sd/sj aliased) or the X-layer geofence
 *     name ("<City> City Common Council District N"); ward from the trailing number.
 *   - SCHOOL board-subdistricts (LAUSD "Board District N", IPS sub-geos with no own
 *     geofence) roll up to the PARENT school district slug, not a per-seat division.
 *   - COUNTY 10-digit geo_ids (state2+county3+seq5) resolve via FIPS-5 → county name
 *     (G4020 geofence first, then IN_COUNTY_FIPS table); seats roll up to the county.
 */
import 'dotenv/config';
import { mkdirSync, writeFileSync } from 'node:fs';
import { pool } from '../src/lib/db.js';

const WRITE = process.argv.includes('--write');
const TYPE_FILTER = (() => {
  const i = process.argv.indexOf('--type');
  return i >= 0 ? (process.argv[i + 1] ?? '').toUpperCase() : null;
})();
// --state scopes the run to one state. Without it, `--type LOCAL --write` would touch every
// state at once (142 districts), which is rarely what a caller scoping to one wave wants.
// districts.state is MIXED CASE, so always compare lowered.
const STATE_FILTER = (() => {
  const i = process.argv.indexOf('--state');
  return i >= 0 ? (process.argv[i + 1] ?? '').toLowerCase() : null;
})();

const FIPS_TO_ABBR: Record<string, string> = {
  '01': 'al', '02': 'ak', '04': 'az', '05': 'ar', '06': 'ca', '08': 'co', '09': 'ct',
  '10': 'de', '11': 'dc', '12': 'fl', '13': 'ga', '15': 'hi', '16': 'id', '17': 'il',
  '18': 'in', '19': 'ia', '20': 'ks', '21': 'ky', '22': 'la', '23': 'me', '24': 'md',
  '25': 'ma', '26': 'mi', '27': 'mn', '28': 'ms', '29': 'mo', '30': 'mt', '31': 'ne',
  '32': 'nv', '33': 'nh', '34': 'nj', '35': 'nm', '36': 'ny', '37': 'nc', '38': 'nd',
  '39': 'oh', '40': 'ok', '41': 'or', '42': 'pa', '44': 'ri', '45': 'sc', '46': 'sd',
  '47': 'tn', '48': 'tx', '49': 'ut', '50': 'vt', '51': 'va', '53': 'wa', '54': 'wv',
  '55': 'wi', '56': 'wy',
};

const STATEWIDE_TYPES = new Set(['NATIONAL_UPPER', 'STATE_EXEC']);
const SKIP_TYPES = new Set(['NATIONAL_JUDICIAL', 'JUDICIAL', 'NATIONAL_LOWER']);

// geo_id slug prefixes that abbreviate a city → canonical place slug (ward-layer councils).
const CITY_ALIAS: Record<string, string> = {
  sf: 'san_francisco', sd: 'san_diego', sj: 'san_jose', 'portland-or': 'portland',
};
// geo_id slug prefixes for school-board sub-districts whose own geofence name is generic
// ("Board District N") → parent LEA slug.
const SCHOOL_ALIAS: Record<string, string> = {
  lausd: 'los_angeles_unified',
};
// County FIPS-5 → county name for states where geofence_boundaries has no G4020 row.
// geofence_boundaries G4020 is consulted first; this backstops it (IN counties absent there).
const COUNTY_FIPS_NAME: Record<string, string> = {
  '18055': 'Greene', '18071': 'Jackson', '18093': 'Lawrence',
  '18097': 'Marion', '18105': 'Monroe', '18109': 'Morgan',
};

function abbrOf(state: string | null, reprState: string | null, geoId: string | null): string | null {
  for (const v of [state, reprState]) {
    if (v && /^[A-Za-z]{2}$/.test(v)) return v.toLowerCase();
    if (v && /^\d{1,2}$/.test(v)) return FIPS_TO_ABBR[v.padStart(2, '0')] ?? null;
  }
  if (geoId && /^\d/.test(geoId)) return FIPS_TO_ABBR[geoId.slice(0, 2)] ?? null;
  return null;
}
function slugify(name: string, strip: RegExp): string {
  return name.replace(strip, '').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}
function plainSlug(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

// LOCAL council/supervisor ward layer → { place, ward }.
// Place from the geo_id slug prefix (sf/sd/sj aliased) or the X-layer geofence name.
function resolveWard(geoId: string, xName: string | undefined, abbr?: string | null): { place: string; ward: string } | null {
  const m = geoId.match(/^([a-z][a-z0-9-]*?)-(?:council|supervisor)-district-(\d+)$/i);
  if (m) {
    let token = m[1].toLowerCase();
    // Some geo_id slugs disambiguate with a trailing state code ("boston-ma-council-district-5"),
    // which would produce place:boston_ma — not how any of the ~296 already-populated rows look,
    // and not a real OCD place slug. CITY_ALIAS already special-cased 'portland-or' for exactly
    // this; strip it generally instead. Guarded on an exact match with THIS district's state, so
    // it can only ever remove a real state code, never a meaningful final word.
    if (abbr && token.endsWith(`-${abbr}`)) token = token.slice(0, -(abbr.length + 1));
    return { place: CITY_ALIAS[token] ?? token.replace(/-/g, '_'), ward: m[2] };
  }
  if (xName) {
    const wm = xName.match(/district\s+(\d+)\s*$/i);
    const placePart = xName.replace(/\s+(?:city\s+)?(?:common\s+)?council\s+district\s+\d+\s*$/i, '');
    if (wm && placePart && placePart !== xName) return { place: plainSlug(placePart), ward: wm[1] };
  }
  return null;
}

// SCHOOL → parent LEA slug. Board-subdistricts roll up to the parent district, never a
// per-seat division: generic "Board District N" names use SCHOOL_ALIAS; "MCCSC N" drops
// the seat number; sub-geos with no own geofence look up the 7-digit parent geo_id.
// A trailing state-assigned district number, which is NOT part of the district's name.
// `\d+[A-Za-z]?` not `\d+`: Oregon's numbers carry a joint-district suffix ("Hillsboro School
// District 1J", "Beaverton ... 48J", "Tigard-Tualatin ... 23J"). With digits only, the letter
// blocked BOTH strips — the number failed to match, which left the name ending in "1J" so the
// " school district" strip could not match either, yielding school_district:hillsboro_school_
// district_1j. Of the 125 school slugs already in prod, NOT ONE contains "school_district_" or a
// district number, and Oregon's own numberless siblings resolve clean (reynolds, parkrose,
// david_douglas) — so this was the `village` defect again: a descriptor that only fails to strip
// in one state's naming style, invisible everywhere else.
const TRAILING_DISTRICT_NO = /\s+\d+[A-Za-z]?$/;
// Bare seat descriptors. A SCHOOL district whose geofence name is missing falls back to its label,
// and IN's consolidated sub-districts show what that must never produce: labels like "District 4"
// and "At-Large" would slug to school_district:district_4. Reject them and skip instead.
const BARE_SEAT_LABEL = /^(?:board\s+)?(?:district|zone|seat|area|position|ward)\s*\d*[A-Za-z]?$|^at[-\s]?large$/i;

function stripSchoolName(name: string): string | null {
  const parent = name.replace(TRAILING_DISTRICT_NO, '').replace(/\s+school district$/i, '');
  return plainSlug(parent) || null;
}

function resolveSchoolSlug(
  geoId: string,
  nameByKey: Map<string, string>,
  label?: string | null,
): string | null {
  const ownName = nameByKey.get(`${geoId}|G5420`);
  if (ownName) {
    if (/^board district\s+\d+$/i.test(ownName.trim())) {
      const am = geoId.match(/^([a-z]+)-board-district/i);
      return (am ? SCHOOL_ALIAS[am[1].toLowerCase()] : undefined) ?? null;
    }
    return stripSchoolName(ownName);
  }
  if (/^\d{12}$/.test(geoId)) {
    const baseName = nameByKey.get(`${geoId.slice(0, 7)}|G5420`);
    if (baseName) return plainSlug(baseName.replace(/\s+school district$/i, '')) || null;
  }
  // Last resort: the district's own label. MA and VA city school departments are keyed to the
  // CITY place GEOID, and their G5420 row exists with a NULL `name` (the same nullable-name defect
  // that killed coverage-init: MA 5, VA 1) — or, for Cambridge, there is no G5420 at all. TIGER
  // therefore offers no district name, and the label ("Boston Public Schools", "Cambridge School
  // District") is the only source. Guarded on the label being a real district name, never a seat.
  if (label && !BARE_SEAT_LABEL.test(label.trim())) return stripSchoolName(label);
  return null;
}

// COUNTY → county slug. 10-digit geo_id is state2+county3+seq5; resolve the FIPS-5 county
// name from a G4020 geofence first, then the COUNTY_FIPS_NAME table. Seats roll up to the county.
function resolveCountySlug(geoId: string, nameByKey: Map<string, string>): string | null {
  const fips5 = /^\d{10}$/.test(geoId) ? geoId.slice(0, 5) : /^\d{5}$/.test(geoId) ? geoId : null;
  if (!fips5) return null;
  const name = nameByKey.get(`${fips5}|G4020`) ?? COUNTY_FIPS_NAME[fips5] ?? null;
  return name ? plainSlug(name.replace(/\s+county$/i, '')) || null : null;
}

interface DistrictRow {
  id: string;
  district_type: string;
  state: string | null;
  geo_id: string | null;
  label: string | null;
  old_ocd_id: string | null;
  repr_state: string | null;
  pols: number;
}

async function main(): Promise<void> {
  // Distinct backfill districts (have a politician, no usable ocd_id, have a geo_id).
  const { rows: districts } = await pool.query<DistrictRow>(
    `SELECT d.id, d.district_type, d.state, d.geo_id, d.label, d.ocd_id AS old_ocd_id,
            MAX(o.representing_state) AS repr_state,
            COUNT(DISTINCT p.id)::int AS pols
       FROM essentials.districts d
       JOIN essentials.offices o ON o.district_id = d.id
       -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id
       -- (dropped in migration 1463). Exactly one row per office, so it cannot fan the count out.
       -- This script was missed by the port, same as coverage-init.ts — which is why the whole
       -- coverage-visibility toolchain has been unusable and the ~353 NULL-ocd_id local districts
       -- it was written to fix were never fixed.
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active = true
      WHERE (d.ocd_id IS NULL OR d.ocd_id NOT LIKE 'ocd-division/%')
        AND d.geo_id IS NOT NULL AND d.geo_id <> ''
        AND ($1::text IS NULL OR lower(d.state) = $1::text)
      GROUP BY d.id, d.district_type, d.state, d.geo_id, d.label, d.ocd_id`,
    [STATE_FILTER],
  );

  // Geofence rows for every involved geo_id, plus the FIPS-5 county prefixes (county
  // districts carry a 10-digit geo_id whose G4020 lives under the 5-digit prefix).
  const geoIds = [...new Set(districts.map((d) => d.geo_id).filter(Boolean))] as string[];
  const countyFips = [
    ...new Set(
      districts
        .filter((d) => d.district_type === 'COUNTY' && d.geo_id && /^\d{10}$/.test(d.geo_id))
        .map((d) => d.geo_id!.slice(0, 5)),
    ),
  ];
  const lookupIds = [...new Set([...geoIds, ...countyFips])];
  const nameByKey = new Map<string, string>(); // `geo_id|mtfcc` -> name
  const xNameByGeo = new Map<string, string>(); // geo_id -> first custom X-layer geofence name
  if (lookupIds.length) {
    const { rows } = await pool.query<{ geo_id: string; mtfcc: string; name: string }>(
      `SELECT geo_id, mtfcc, name FROM essentials.geofence_boundaries WHERE geo_id = ANY($1)`,
      [lookupIds],
    );
    for (const r of rows) {
      nameByKey.set(`${r.geo_id}|${r.mtfcc}`, r.name);
      if (/^X/i.test(r.mtfcc) && !xNameByGeo.has(r.geo_id)) xNameByGeo.set(r.geo_id, r.name);
    }
  }

  type Plan = { district_type: string; resolved: { d: DistrictRow; ocd: string }[]; skipped: { d: DistrictRow; reason: string }[] };
  const plans = new Map<string, Plan>();
  const planFor = (t: string) => {
    if (!plans.has(t)) plans.set(t, { district_type: t, resolved: [], skipped: [] });
    return plans.get(t)!;
  };

  for (const d of districts) {
    if (TYPE_FILTER && d.district_type !== TYPE_FILTER) continue;
    const p = planFor(d.district_type);
    if (SKIP_TYPES.has(d.district_type)) { p.skipped.push({ d, reason: 'no OCD geography (judiciary/federal)' }); continue; }
    const abbr = abbrOf(d.state, d.repr_state, d.geo_id);
    if (!abbr) { p.skipped.push({ d, reason: `cannot resolve state (state=${d.state} repr=${d.repr_state} geo=${d.geo_id})` }); continue; }

    if (STATEWIDE_TYPES.has(d.district_type)) {
      p.resolved.push({ d, ocd: `ocd-division/country:us/state:${abbr}` });
      continue;
    }
    const geoId = d.geo_id ?? '';

    // LOCAL / LOCAL_EXEC: G4110 place geofence → bare place; else council/supervisor ward layer.
    if (d.district_type === 'LOCAL' || d.district_type === 'LOCAL_EXEC') {
      const placeName = nameByKey.get(`${geoId}|G4110`);
      if (placeName) {
        // Strip TIGER's trailing legal/statistical descriptor. `village` was missing, which is
        // invisible in states whose TIGER place names omit it but wrong in Wisconsin, where the
        // G4110 names read "Madison city" / "Elmwood Park village" / "Yorkville village". Without
        // it the 11 WI villages would have become place:elmwood_park_village — inconsistent with
        // all ~296 already-populated rows, which are clean (place:holladay, place:san_diego).
        // Only the TRAILING descriptor goes: "Boulder City city" -> boulder_city and
        // "Wood Village city" -> wood_village are correct, because those really are the names.
        const slug = slugify(placeName, / (city|town|village|borough|CDP)$/i);
        if (!slug) { p.skipped.push({ d, reason: `empty slug from "${placeName}"` }); continue; }
        p.resolved.push({ d, ocd: `ocd-division/country:us/state:${abbr}/place:${slug}` });
        continue;
      }
      const ward = resolveWard(geoId, xNameByGeo.get(geoId), abbr);
      if (!ward) { p.skipped.push({ d, reason: `no G4110 place + unparseable ward layer for geo_id=${geoId}` }); continue; }
      // A COUNTY board typed as LOCAL is not a place. resolveWard matches "council|supervisor",
      // and "supervisor" is county-board terminology, so "Pima County Supervisor District 1"
      // (geo_id pima-az-supervisor-district-1) resolved to place:pima — but Pima is a county.
      // Emit the county form instead, matching the county precedent already in the data
      // (county:los_angeles/council_district:1, county:salt_lake/council_district:2).
      // Keyed on the LABEL naming a county, which correctly excludes San Francisco: its board of
      // supervisors IS the city council of a consolidated city-county, its labels are bare
      // ("District 1"), and place:san_francisco is right for it.
      const countyName = (d.label ?? '').match(/^(.+?)\s+County\b/i)?.[1];
      if (countyName) {
        p.resolved.push({
          d,
          ocd: `ocd-division/country:us/state:${abbr}/county:${plainSlug(countyName)}/council_district:${ward.ward}`,
        });
        continue;
      }
      p.resolved.push({ d, ocd: `ocd-division/country:us/state:${abbr}/place:${ward.place}/ward:${ward.ward}` });
      continue;
    }

    // SCHOOL: parent LEA slug (board-subdistricts roll up).
    if (d.district_type === 'SCHOOL') {
      const slug = resolveSchoolSlug(geoId, nameByKey, d.label);
      if (!slug) { p.skipped.push({ d, reason: `no parent school district for geo_id=${geoId}` }); continue; }
      p.resolved.push({ d, ocd: `ocd-division/country:us/state:${abbr}/school_district:${slug}` });
      continue;
    }

    // COUNTY: FIPS-5 → county slug (seats roll up to the county).
    if (d.district_type === 'COUNTY') {
      const slug = resolveCountySlug(geoId, nameByKey);
      if (!slug) { p.skipped.push({ d, reason: `cannot resolve county name for geo_id=${geoId}` }); continue; }
      p.resolved.push({ d, ocd: `ocd-division/country:us/state:${abbr}/county:${slug}` });
      continue;
    }

    p.skipped.push({ d, reason: `unhandled district_type` });
  }

  // Report.
  let totalResolved = 0, totalSkipped = 0;
  console.log(`\n${WRITE ? '*** WRITE MODE ***' : 'DRY RUN'} — districts with no usable ocd_id but a geo_id\n`);
  for (const t of [...plans.keys()].sort()) {
    const p = plans.get(t)!;
    totalResolved += p.resolved.length; totalSkipped += p.skipped.length;
    console.log(`■ ${t}: ${p.resolved.length} resolvable, ${p.skipped.length} skipped (${p.resolved.reduce((a, r) => a + r.d.pols, 0)} politicians)`);
    const showAll = WRITE || process.argv.includes('--all');
    for (const r of p.resolved.slice(0, showAll ? p.resolved.length : 4)) {
      console.log(`    ${r.d.id.slice(0, 8)}  [${r.d.pols}p]  ${r.d.label ?? ''}  NULL → ${r.ocd}`);
    }
    if (!showAll && p.resolved.length > 4) console.log(`    … +${p.resolved.length - 4} more`);
    const reasons = new Map<string, number>();
    for (const s of p.skipped) reasons.set(s.reason.replace(/geo_id=\S+/, 'geo_id=…').replace(/state=\S+ repr=\S+ geo=\S+/, 'unresolved state'), (reasons.get(s.reason.replace(/geo_id=\S+/, 'geo_id=…').replace(/state=\S+ repr=\S+ geo=\S+/, 'unresolved state')) ?? 0) + 1);
    for (const [reason, n] of reasons) console.log(`      skip ${n}: ${reason}`);
  }
  console.log(`\nTotal: ${totalResolved} districts resolvable, ${totalSkipped} skipped.`);

  if (!WRITE) {
    console.log('\n(dry run — no changes. Re-run with --write [--type X] to apply.)');
    await pool.end();
    return;
  }

  // Snapshot a revert log BEFORE writing (mirror of backfill-log-2026-05-30.json).
  // Revert = set ocd_id NULL for the captured ids. Filename reflects --type when scoped.
  const snapshot = [...plans.values()].flatMap((p) =>
    p.resolved.map((r) => ({
      id: r.d.id,
      district_type: r.d.district_type,
      state: r.d.state,
      geo_id: r.d.geo_id,
      old_ocd_id: r.d.old_ocd_id,
      new_ocd_id: r.ocd,
    })),
  );
  const suffix = [TYPE_FILTER ? TYPE_FILTER.toLowerCase() : 'deferred-tiers', STATE_FILTER]
    .filter(Boolean)
    .join('-');
  // The date is the ACTUAL run date. It used to be hardcoded '2026-05-30' in both the filename
  // and the payload, so any later run produced a revert log that lied about when it was captured —
  // the worst possible property for the file you reach for when reverting.
  const runDate = new Date().toISOString().slice(0, 10);
  // Path was '../../.planning/...', one level too many: from backend/ that resolves OUTSIDE the
  // repo (C:\.planning). Combined with the directory not existing, --write would throw ENOENT
  // here — before any UPDATE, so it failed safe, but it never actually worked.
  const logDir = '../.planning/coverage';
  mkdirSync(logDir, { recursive: true });
  const logPath = `${logDir}/backfill-log-${suffix}-${runDate}.json`;
  writeFileSync(
    logPath,
    JSON.stringify(
      {
        captured: runDate,
        tier: TYPE_FILTER ?? 'deferred (LOCAL/SCHOOL/COUNTY)',
        state: STATE_FILTER ?? 'all',
        count: snapshot.length,
        districts: snapshot,
      },
      null,
      2,
    ),
  );
  console.log(`[backfill] Revert log → ${logPath} (${snapshot.length} districts)`);

  // Apply: only update rows still NULL/'' (defensive), one statement per district.
  let updated = 0;
  for (const p of plans.values()) {
    for (const r of p.resolved) {
      const res = await pool.query(
        `UPDATE essentials.districts SET ocd_id = $1
          WHERE id = $2 AND (ocd_id IS NULL OR ocd_id NOT LIKE 'ocd-division/%')`,
        [r.ocd, r.d.id],
      );
      updated += res.rowCount ?? 0;
    }
  }
  console.log(`\n[backfill] Updated ${updated} districts. Re-run coverage-init/sync for affected states.`);
  await pool.end();
}

main().catch((e) => { console.error('[backfill] FATAL', e); process.exit(1); });
