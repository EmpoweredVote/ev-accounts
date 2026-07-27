/**
 * 166-coordinate-smoke.ts — Phase 166 read-only coordinate-surfacing smoke (all 38 Wave-3 states).
 *
 * ROADMAP success criterion 1 for Phase 166 is a COORDINATE-PATH proof, not a SQL-only proof.
 * For one contested in-district US House coordinate per Wave-3 state, the live surfacing join
 * (geofence ST_Covers point -> district -> office -> race within that state's surfacing election,
 * NATIONAL_LOWER) must return the resident's House race with the full challenger-inclusive
 * candidate field: >= minActive active candidates AND >= 1 challenger (is_incumbent = false).
 * A gate that only proves the incumbent resolves passes on a half-seeded district — that is the
 * Pitfall-5 two-path guard.
 *
 * Plus one NEGATIVE sample: a coordinate inside a severe MO district must surface ZERO House
 * races on the surfacing MO election, proving the withholding mechanism still holds end-to-end.
 *
 * ENGINE: cloned from 163-coordinate-smoke.ts — the post-164.1 vintage-preference form. The
 * anchor query orders `CASE WHEN gb.mtfcc = 'G5200V26' THEN 0 ELSE 1 END` so a 2026-vintage
 * polygon wins when one exists, and the surfacing query uses a JOIN LATERAL that takes the
 * G5200V26 geometry for a geo_id when present and otherwise falls back to the district-mtfcc
 * branch. This is what the deployed service does. 165's hard `mtfcc` pin is NOT used: a hard pin
 * is correct only for UT, while the LATERAL generalises to TN, AL, LA, UT and every non-dual-map
 * state at once. 164.1-04 recorded that the pre-164.1 plain join double-matches for dual-map
 * states and would spuriously surface two races.
 *
 * FIVE ELECTION NAMES DEVIATE from the `{ABBR} 2026 Statewide General` convention because those
 * elections were PRE-EXISTING and were reused rather than authored: OR ('OR 2026 General',
 * 164-03), MD ('2026 Maryland General Election', 162-08), MA ('2026 Massachusetts General
 * Election', 161), ME ('2026 Maine General Election', 165-01) and NV (name reused, 165-01).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A (ST_Covers).
 * All PostGIS calls use the public. schema prefix.
 *
 * Run:   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *          node --import tsx scripts/166-coordinate-smoke.ts
 * Select: ... node --import tsx scripts/166-coordinate-smoke.ts --select
 *          (live enumeration of every district's active/challenger counts — the authority for
 *           which geo_id each state contributes as its sample)
 */
import { pool } from '../src/lib/db.js';

interface Sample {
  state: string;
  geoId: string;
  minActive: number;
}

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  AZ: { election: 'AZ 2026 Statewide General', geoPrefix: '04' },
  WA: { election: 'WA 2026 Statewide General', geoPrefix: '53' },
  TN: { election: 'TN 2026 Statewide General', geoPrefix: '47' },
  MA: { election: '2026 Massachusetts General Election', geoPrefix: '25' }, // pre-existing name (161)
  IN: { election: 'IN 2026 Statewide General', geoPrefix: '18' },
  MD: { election: '2026 Maryland General Election', geoPrefix: '24' }, // pre-existing name (162-08)
  MN: { election: 'MN 2026 Statewide General', geoPrefix: '27' },
  MO: { election: 'MO 2026 Statewide General', geoPrefix: '29' }, // surfacing election only; 2902-2906 are withheld
  WI: { election: 'WI 2026 Statewide General', geoPrefix: '55' },
  CO: { election: 'CO 2026 Statewide General', geoPrefix: '08' },
  AL: { election: 'AL 2026 Statewide General', geoPrefix: '01' },
  SC: { election: 'SC 2026 Statewide General', geoPrefix: '45' },
  LA: { election: 'LA 2026 Statewide General', geoPrefix: '22' },
  KY: { election: 'KY 2026 Statewide General', geoPrefix: '21' },
  OR: { election: 'OR 2026 General', geoPrefix: '41' }, // pre-existing name (164-03)
  CT: { election: 'CT 2026 Statewide General', geoPrefix: '09' },
  OK: { election: 'OK 2026 Statewide General', geoPrefix: '40' },
  AR: { election: 'AR 2026 Statewide General', geoPrefix: '05' },
  IA: { election: 'IA 2026 Statewide General', geoPrefix: '19' },
  KS: { election: 'KS 2026 Statewide General', geoPrefix: '20' },
  MS: { election: 'MS 2026 Statewide General', geoPrefix: '28' },
  NV: { election: 'NV 2026 Statewide General', geoPrefix: '32' }, // pre-existing races reused (165-01)
  UT: { election: 'UT 2026 Statewide General', geoPrefix: '49' }, // dual-map: G5200V26 wins via the LATERAL
  NM: { election: 'NM 2026 Statewide General', geoPrefix: '35' },
  NE: { election: 'NE 2026 Statewide General', geoPrefix: '31' },
  WV: { election: 'WV 2026 Statewide General', geoPrefix: '54' },
  ID: { election: 'ID 2026 Statewide General', geoPrefix: '16' },
  HI: { election: 'HI 2026 Statewide General', geoPrefix: '15' },
  ME: { election: '2026 Maine General Election', geoPrefix: '23' }, // pre-existing name (165-01)
  NH: { election: 'NH 2026 Statewide General', geoPrefix: '33' },
  RI: { election: 'RI 2026 Statewide General', geoPrefix: '44' },
  MT: { election: 'MT 2026 Statewide General', geoPrefix: '30' },
  AK: { election: 'AK 2026 Statewide General', geoPrefix: '02' },
  DE: { election: 'DE 2026 Statewide General', geoPrefix: '10' },
  ND: { election: 'ND 2026 Statewide General', geoPrefix: '38' },
  SD: { election: 'SD 2026 Statewide General', geoPrefix: '46' },
  VT: { election: 'VT 2026 Statewide General', geoPrefix: '50' },
  WY: { election: 'WY 2026 Statewide General', geoPrefix: '56' },
};

/** The five severity-routed MO districts, deliberately NOT on the surfacing MO election. */
const SEVERE_MO_GEO_IDS = ['2902', '2903', '2904', '2905', '2906'];

// -- === MO POST-2026-08-04 FLIP REGION (see 166-mo-flip-runbook.md) ===
// (The `--` above keeps this delimiter greppable by the same pattern the SQL gates use; this is
//  a .ts file, so the surrounding `//` is what actually makes it a comment.)
//
// MO-5 (2905, the dismantled Cleaver seat) is one of the five severity-routed districts listed
// in 162-mo-correspondence-audit.md. Its races live on the withheld
// 'MO 2026 Congressional Redistricting - Polygon Pending' election, which
// electionService.ts's ELECTION_VISIBILITY_WINDOW never returns — so a resident of a severe MO
// district correctly sees NO House race at all. This block proves that end-to-end.
//
// Plan 164.1-07 resolves the withholding on or after 2026-08-04, and has TWO branches:
//
//   MAP-HOLDS branch — the 2026 map survives. The five severe MO races move onto
//     'MO 2026 Statewide General'. THIS BLOCK MUST THEN CHANGE: the negative sample becomes
//     FIVE POSITIVE samples (2902, 2903, 2904, 2905, 2906) appended to SAMPLES, SEVERE_MO_GEO_IDS
//     empties, MIN_DISTRICTS rises from 38 to 43, and the --select MO exclusion is dropped.
//
//   REFERENDUM-QUALIFIES branch — the referendum makes the ballot and MO stays withheld for this
//     cycle. THIS BLOCK NEEDS NO EDIT. It is already asserting the correct world.
//
// Until 164.1-07 runs, the negative sample below is the correct assertion in both branches.
// ============================================================================================

/** MO-5, the dismantled Cleaver seat — the negative sample. */
const SEVERE_MO_GEO_ID = '2905';

/**
 * One sample per state, chosen from the `--select` run of 2026-07-26: the district with the
 * highest challenger count, preferring an open seat on ties. NOT copied from the 161..165
 * smoke files — those picks were frozen in early July and the fields have changed since.
 * Counts in the comments are as of selection.
 */
const SAMPLES: Sample[] = [
  { state: 'AZ', geoId: '0401', minActive: 2 }, // AZ-1 open, 8 active / 8 challengers — deepest AZ field
  { state: 'WA', geoId: '5304', minActive: 2 }, // WA-4 open, 11/11 — tied with 5305 on challengers, open seat wins
  { state: 'TN', geoId: '4706', minActive: 2 }, // TN-6 open, 11/11 — deepest TN field
  { state: 'MA', geoId: '2506', minActive: 2 }, // MA-6 open, 7/7 — only MA open seat
  { state: 'IN', geoId: '1802', minActive: 2 }, // IN-2, 3/2 — tied with 1807/1809, none open
  { state: 'MD', geoId: '2405', minActive: 2 }, // MD-5 open, 4/4 — Hoyer seat
  { state: 'MN', geoId: '2705', minActive: 2 }, // MN-5, 10/9 — deepest MN field
  { state: 'MO', geoId: '2901', minActive: 2 }, // MO-1, 8/7 — NON-SEVERE (2902-2906 are withheld)
  { state: 'WI', geoId: '5503', minActive: 2 }, // WI-3 open, 2/2 — see WI NOTE below; the general is nearly empty
  { state: 'CO', geoId: '0801', minActive: 2 }, // CO-1 open, 2/2 — only CO open seat
  { state: 'AL', geoId: '0102', minActive: 2 }, // AL-2, 7/6 — un-withheld by 164.1-05 (mig 1248)
  { state: 'SC', geoId: '4501', minActive: 2 }, // SC-1 open, 4/4
  { state: 'LA', geoId: '2205', minActive: 2 }, // LA-5 open jungle, 12/12 — deepest field in the phase
  { state: 'KY', geoId: '2104', minActive: 2 }, // KY-4 open, 4/4 — tied with 2106, both open, first wins
  { state: 'OR', geoId: '4104', minActive: 2 }, // OR-4, 3/2 — deepest OR field
  { state: 'CT', geoId: '0904', minActive: 2 }, // CT-4, 6/5
  { state: 'OK', geoId: '4005', minActive: 2 }, // OK-5, 4/3
  { state: 'AR', geoId: '0501', minActive: 2 }, // AR-1, 3/2 — tied with 0503, none open
  { state: 'IA', geoId: '1902', minActive: 2 }, // IA-2 open, 4/4
  { state: 'KS', geoId: '2004', minActive: 2 }, // KS-4, 11/10 — deepest KS field
  { state: 'MS', geoId: '2801', minActive: 2 }, // MS-1, 3/2 — four-way tie, none open
  { state: 'NV', geoId: '3202', minActive: 2 }, // NV-2 open, 3/3 — tied on challengers, open seat wins (Amodei retired)
  { state: 'UT', geoId: '4903', minActive: 2 }, // UT-3, 6/5 — dual-map state, resolves via G5200V26
  { state: 'NM', geoId: '3501', minActive: 2 }, // NM-1, 2/1 — three-way tie, none open
  { state: 'NE', geoId: '3102', minActive: 2 }, // NE-2 open, 3/3 — Bacon retired
  { state: 'WV', geoId: '5402', minActive: 2 }, // WV-2, 4/3
  { state: 'ID', geoId: '1602', minActive: 2 }, // ID-2, 6/5
  { state: 'HI', geoId: '1501', minActive: 2 }, // HI-1, 8/7
  { state: 'ME', geoId: '2302', minActive: 2 }, // ME-2 open, 2/2
  { state: 'NH', geoId: '3301', minActive: 2 }, // NH-1 open, 14/14
  { state: 'RI', geoId: '4401', minActive: 2 }, // RI-1, 3/2 — tied with 4402, none open
  { state: 'MT', geoId: '3001', minActive: 2 }, // MT-1 open, 3/3 — Zinke retired
  { state: 'AK', geoId: '0200', minActive: 2 }, // AK at-large jungle, 15/14
  { state: 'DE', geoId: '1000', minActive: 2 }, // DE at-large, 2/1
  { state: 'ND', geoId: '3800', minActive: 2 }, // ND at-large, 2/1
  { state: 'SD', geoId: '4600', minActive: 2 }, // SD at-large open, 2/2
  { state: 'VT', geoId: '5000', minActive: 2 }, // VT at-large, 4/3
  { state: 'WY', geoId: '5600', minActive: 2 }, // WY at-large open, 14/14
];

/**
 * WI NOTE (recorded 2026-07-26, see 166-01-SUMMARY.md). WI's sample is thinner than every other
 * state's, and that is a real fact about the data rather than a seeding gap: on 2026-07-25 a
 * party-split 'WI 2026 Partisan Primary' (2026-08-11) was created and WI's field moved onto it.
 * The 'WI 2026 Statewide General' this smoke scopes to now holds 5 active candidates with 4 of
 * its 8 races EMPTY. 5503 and 5506 are the only general races meeting the >= 2 active / >= 1
 * challenger bar. The smoke deliberately still scopes WI to the GENERAL, because that is the
 * election whose surfacing behaviour the other 37 states are being compared against; the
 * primary-election field is covered by 166-verify.sql, whose scope includes it.
 */

const MIN_DISTRICTS = 38;

/** Anchor point: prefer the 2026-vintage polygon when one exists (post-164.1). */
async function anchorPoint(geoId: string): Promise<{ lng: number; lat: number } | null> {
  const pt = await pool.query(
    `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
            public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
     FROM essentials.geofence_boundaries gb
     JOIN essentials.districts d
       ON d.geo_id = gb.geo_id
      AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc OR gb.mtfcc = 'G5200V26')
     WHERE gb.geo_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND gb.geometry IS NOT NULL
     ORDER BY CASE WHEN gb.mtfcc = 'G5200V26' THEN 0 ELSE 1 END
     LIMIT 1`,
    [geoId]
  );
  return pt.rows.length ? { lng: +pt.rows[0].lng, lat: +pt.rows[0].lat } : null;
}

/**
 * Mirror of getElectionsByCoordinate Part A, post-164.1: the vintage-preference LATERAL takes
 * G5200V26 for a geo_id when present, else the district-mtfcc branch.
 */
async function surface(eid: string, geoPrefix: string, lng: number, lat: number) {
  return pool.query(
    `SELECT r.id AS race_id, d.geo_id,
            COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active_cands,
            COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
            COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.politician_id IS NULL) AS null_pid
     FROM essentials.races r
     JOIN essentials.offices o ON o.id = r.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     JOIN LATERAL (
       SELECT geometry FROM essentials.geofence_boundaries gbv
        WHERE gbv.geo_id = d.geo_id AND gbv.mtfcc = 'G5200V26'
          AND d.district_type = 'NATIONAL_LOWER'
       UNION ALL
       SELECT geometry FROM essentials.geofence_boundaries gbo
        WHERE gbo.geo_id = d.geo_id
          AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gbo.mtfcc = d.mtfcc)
          AND NOT EXISTS (
            SELECT 1 FROM essentials.geofence_boundaries x
             WHERE x.geo_id = d.geo_id AND x.mtfcc = 'G5200V26'
          )
       LIMIT 1
     ) gb ON true
     LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE r.election_id = $1
       AND d.district_type = 'NATIONAL_LOWER'
       AND substr(d.geo_id, 1, 2) = $4
       AND gb.geometry IS NOT NULL
       AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))
     GROUP BY r.id, d.geo_id`,
    [eid, lng, lat, geoPrefix]
  );
}

async function resolveElections(): Promise<Record<string, string>> {
  const eids: Record<string, string> = {};
  for (const [st, cfg] of Object.entries(STATE_CONFIG)) {
    const row = (await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [cfg.election])).rows[0];
    if (!row) throw new Error(`FAIL: election not found: ${cfg.election} (${st})`);
    eids[st] = row.id;
  }
  return eids;
}

/**
 * --select: live enumeration. For each state, list every in-scope district with its active and
 * challenger counts, ordered by challenger count descending. This is the ONLY authority for
 * which geo_id each state contributes as its sample — the 161..165 smoke picks were frozen in
 * early July and candidate fields have changed since.
 */
async function selectMode() {
  const eids = await resolveElections();
  for (const [st, cfg] of Object.entries(STATE_CONFIG)) {
    const q = await pool.query(
      `SELECT d.geo_id,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = true) AS incumbents
       FROM essentials.races r
       JOIN essentials.offices o ON o.id = r.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       WHERE r.election_id = $1
         AND d.district_type = 'NATIONAL_LOWER'
         AND substr(d.geo_id, 1, 2) = $2
         AND ($3::text[] IS NULL OR NOT (d.geo_id = ANY($3::text[])))
       GROUP BY d.geo_id
       ORDER BY challengers DESC, active DESC, d.geo_id`,
      [eids[st], cfg.geoPrefix, st === 'MO' ? SEVERE_MO_GEO_IDS : null]
    );
    const cells = q.rows.map(
      (r) => `${r.geo_id}(a=${r.active},c=${r.challengers}${+r.incumbents === 0 ? ',OPEN' : ''})`
    );
    console.log(`SELECT-CANDIDATES ${st}: ${cells.join(' ') || '(no districts)'}`);
  }
  await pool.end();
}

async function smokeMode() {
  const eids = await resolveElections();
  const failures: string[] = [];
  let surfaced = 0;

  for (const s of SAMPLES) {
    const cfg = STATE_CONFIG[s.state];
    const pt = await anchorPoint(s.geoId);
    if (!pt) {
      failures.push(`${s.state} ${s.geoId}: no NATIONAL_LOWER geofence boundary`);
      continue;
    }
    const surf = await surface(eids[s.state], cfg.geoPrefix, pt.lng, pt.lat);

    if (!surf.rows.length) {
      failures.push(
        `${s.state} ${s.geoId}: coordinate (${pt.lat.toFixed(4)},${pt.lng.toFixed(4)}) surfaced NO House race`
      );
      continue;
    }

    const row = surf.rows[0];
    const active = +row.active_cands;
    const chal = +row.challengers;
    const nullpid = +row.null_pid;
    let ok = true;

    if (surf.rows.length > 1) {
      failures.push(`${s.state} ${s.geoId}: matched ${surf.rows.length} House races (expected 1)`);
      ok = false;
    }
    if (active < s.minActive) {
      failures.push(`${s.state} ${s.geoId}: only ${active} active candidate(s) (expected >= ${s.minActive})`);
      ok = false;
    }
    if (chal < 1) {
      failures.push(`${s.state} ${s.geoId}: 0 challengers -- only incumbent surfaced (Pitfall-5)`);
      ok = false;
    }
    if (nullpid > 0) {
      failures.push(`${s.state} ${s.geoId}: ${nullpid} active candidate(s) with NULL politician_id`);
      ok = false;
    }

    if (ok) {
      surfaced++;
      console.log(
        `PASS ${s.state} ${s.geoId}: 1 House race -- ${active} active, ${chal} challenger(s), 0 null pid [contested]`
      );
    }
  }

  // ==========================================================================
  // NEGATIVE sample — see the MO POST-2026-08-04 FLIP REGION comment above.
  // A coordinate inside severe MO-5 must surface ZERO races on the surfacing election.
  // ==========================================================================
  const moPt = await anchorPoint(SEVERE_MO_GEO_ID);
  if (!moPt) {
    failures.push(`MO ${SEVERE_MO_GEO_ID}: no NATIONAL_LOWER geofence boundary for the severe negative sample`);
  } else {
    const moSurf = await surface(eids.MO, STATE_CONFIG.MO.geoPrefix, moPt.lng, moPt.lat);
    if (moSurf.rows.length) {
      failures.push(
        `MO ${SEVERE_MO_GEO_ID}: severe district surfaced ${moSurf.rows.length} House race(s) on ` +
          `'${STATE_CONFIG.MO.election}' (expected 0) — withholding has BROKEN: ` +
          moSurf.rows.map((r) => r.geo_id).join(', ')
      );
    } else {
      console.log(
        `PASS MO ${SEVERE_MO_GEO_ID} (severe negative sample): coordinate ` +
          `(${moPt.lat.toFixed(4)},${moPt.lng.toFixed(4)}) surfaced ZERO House races on ` +
          `${STATE_CONFIG.MO.election} — withholding confirmed end-to-end`
      );
    }
  }

  if (failures.length) {
    console.error('FAIL coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  if (surfaced < MIN_DISTRICTS) {
    console.error(`FAIL: only ${surfaced} of ${MIN_DISTRICTS} states surfaced cleanly (need all ${MIN_DISTRICTS})`);
    process.exit(1);
  }
  console.log(
    `\n166 COORDINATE SMOKE GREEN: ${surfaced}/38 states surface their US House race with full challenger-inclusive field`
  );

  // National coverage arithmetic, stated so the milestone claim is checkable rather than
  // asserted, and naming which gate owns each segment.
  console.log(`
NATIONAL COVERAGE — 178 + 144 + 89 + 24 = 435 US House districts
  178  Wave-3 (v2.22), proven here and by backend/scripts/166-verify.sql
  144  v2.20 CA/TX/FL/NY, owned by backend/scripts/152-verify.sql
   89  v2.21 decided states, owned by backend/scripts/158-verify.sql
  ---
  411  GATE-PROVEN
   24  v2.21 MI and VA — SEEDED BUT GATE-PENDING, owned by plan 159-06,
       date-gated on or after 2026-08-05. These are NOT gate-proven: 158-verify.sql's
       own header states it must not reference MI or VA.
  ---
  435  total US House districts covered`);
  await pool.end();
}

const isSelect = process.argv.includes('--select');
(isSelect ? selectMode() : smokeMode()).catch((e) => {
  console.error(e);
  process.exit(1);
});
