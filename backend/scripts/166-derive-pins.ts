/**
 * 166-derive-pins.ts — Phase 166 read-only LIVE pin derivation harness.
 *
 * The five per-phase Wave-3 gates froze their pin lists at their own authoring dates
 * (161 + 162 on 2026-07-04/05, 163 on 2026-07-06, 164 + 165 on 2026-07-07). Today is
 * 2026-07-26. Filings, withdrawals, culls and the 164.2-04 FL/CA candidate-field repairs
 * (2026-07-22) have all landed since. A consolidated gate built on those snapshots would
 * be green for the wrong reasons — so every pin the Phase-166 gate carries is re-derived
 * here, live, against production.
 *
 * SELECT-only against essentials/inform. The single write is the local artifact
 * `backend/scripts/166-pins.generated.sql`, consumed verbatim by 166-03 and 166-04.
 *
 * Scope: the SAME 42 elections and 38 two-digit FIPS geo prefixes 166-verify.sql uses.
 * A scope mismatch here would silently produce pins for the wrong universe.
 *
 * Run:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *     node --import tsx scripts/166-derive-pins.ts
 */
import { pool } from '../src/lib/db.js';

const DERIVED_AT = '2026-07-26';

// ---------------------------------------------------------------------------
// The 38 general elections. `districts` is the expected NATIONAL_LOWER district
// count for the state across ALL 42 in-scope elections — MO's 8 is 3 under its
// general plus 5 still held behind the MO Polygon Pending marker election.
// `band` is [lo, hi] with lo the MORE NEGATIVE endpoint (SQL BETWEEN lo AND hi).
// ---------------------------------------------------------------------------
interface StateCfg {
  st: string;
  fips: string;
  election: string;
  districts: number;
  band: [number, number];
  sourceGate: string;
}

const STATES: StateCfg[] = [
  // --- 161 ---------------------------------------------------------------
  { st: 'AZ', fips: '04', election: 'AZ 2026 Statewide General', districts: 9, band: [-40901, -40101], sourceGate: '161' },
  { st: 'WA', fips: '53', election: 'WA 2026 Statewide General', districts: 10, band: [-531005, -530101], sourceGate: '161' },
  { st: 'TN', fips: '47', election: 'TN 2026 Statewide General', districts: 9, band: [-470910, -470101], sourceGate: '161' },
  { st: 'MA', fips: '25', election: '2026 Massachusetts General Election', districts: 9, band: [-250902, -250101], sourceGate: '161' },
  // --- 162 ---------------------------------------------------------------
  { st: 'IN', fips: '18', election: 'IN 2026 Statewide General', districts: 9, band: [-180999, -180101], sourceGate: '162' },
  { st: 'MD', fips: '24', election: '2026 Maryland General Election', districts: 8, band: [-240899, -240101], sourceGate: '162' },
  { st: 'MN', fips: '27', election: 'MN 2026 Statewide General', districts: 8, band: [-270899, -270101], sourceGate: '162' },
  { st: 'MO', fips: '29', election: 'MO 2026 Statewide General', districts: 8, band: [-290899, -290101], sourceGate: '162' },
  // --- 163 ---------------------------------------------------------------
  { st: 'WI', fips: '55', election: 'WI 2026 Statewide General', districts: 8, band: [-550899, -550101], sourceGate: '163' },
  { st: 'CO', fips: '08', election: 'CO 2026 Statewide General', districts: 8, band: [-80899, -80101], sourceGate: '163' },
  { st: 'AL', fips: '01', election: 'AL 2026 Statewide General', districts: 7, band: [-10799, -10101], sourceGate: '163' },
  { st: 'SC', fips: '45', election: 'SC 2026 Statewide General', districts: 7, band: [-450799, -450101], sourceGate: '163' },
  { st: 'LA', fips: '22', election: 'LA 2026 Statewide General', districts: 6, band: [-220699, -220101], sourceGate: '163' },
  // --- 164 ---------------------------------------------------------------
  { st: 'KY', fips: '21', election: 'KY 2026 Statewide General', districts: 6, band: [-210899, -210101], sourceGate: '164' },
  { st: 'OR', fips: '41', election: 'OR 2026 General', districts: 6, band: [-410699, -410101], sourceGate: '164' },
  { st: 'CT', fips: '09', election: 'CT 2026 Statewide General', districts: 5, band: [-90599, -90101], sourceGate: '164' },
  { st: 'OK', fips: '40', election: 'OK 2026 Statewide General', districts: 5, band: [-400599, -400101], sourceGate: '164' },
  { st: 'AR', fips: '05', election: 'AR 2026 Statewide General', districts: 4, band: [-50499, -50101], sourceGate: '164' },
  { st: 'IA', fips: '19', election: 'IA 2026 Statewide General', districts: 4, band: [-190499, -190101], sourceGate: '164' },
  { st: 'KS', fips: '20', election: 'KS 2026 Statewide General', districts: 4, band: [-200499, -200101], sourceGate: '164' },
  { st: 'MS', fips: '28', election: 'MS 2026 Statewide General', districts: 4, band: [-280499, -280101], sourceGate: '164' },
  // --- 165 ---------------------------------------------------------------
  { st: 'NV', fips: '32', election: 'NV 2026 Statewide General', districts: 4, band: [-320499, -320101], sourceGate: '165' },
  { st: 'UT', fips: '49', election: 'UT 2026 Statewide General', districts: 4, band: [-490499, -490101], sourceGate: '165' },
  { st: 'NM', fips: '35', election: 'NM 2026 Statewide General', districts: 3, band: [-350399, -350101], sourceGate: '165' },
  { st: 'NE', fips: '31', election: 'NE 2026 Statewide General', districts: 3, band: [-310399, -310101], sourceGate: '165' },
  { st: 'WV', fips: '54', election: 'WV 2026 Statewide General', districts: 2, band: [-540299, -540101], sourceGate: '165' },
  { st: 'ID', fips: '16', election: 'ID 2026 Statewide General', districts: 2, band: [-160299, -160101], sourceGate: '165' },
  { st: 'HI', fips: '15', election: 'HI 2026 Statewide General', districts: 2, band: [-150299, -150101], sourceGate: '165' },
  { st: 'ME', fips: '23', election: '2026 Maine General Election', districts: 2, band: [-230299, -230101], sourceGate: '165' },
  { st: 'NH', fips: '33', election: 'NH 2026 Statewide General', districts: 2, band: [-330299, -330101], sourceGate: '165' },
  { st: 'RI', fips: '44', election: 'RI 2026 Statewide General', districts: 2, band: [-440299, -440101], sourceGate: '165' },
  { st: 'MT', fips: '30', election: 'MT 2026 Statewide General', districts: 2, band: [-300299, -300101], sourceGate: '165' },
  { st: 'AK', fips: '02', election: 'AK 2026 Statewide General', districts: 1, band: [-20099, -20001], sourceGate: '165' },
  { st: 'DE', fips: '10', election: 'DE 2026 Statewide General', districts: 1, band: [-100099, -100001], sourceGate: '165' },
  { st: 'ND', fips: '38', election: 'ND 2026 Statewide General', districts: 1, band: [-380099, -380001], sourceGate: '165' },
  { st: 'SD', fips: '46', election: 'SD 2026 Statewide General', districts: 1, band: [-460099, -460001], sourceGate: '165' },
  { st: 'VT', fips: '50', election: 'VT 2026 Statewide General', districts: 1, band: [-500099, -500001], sourceGate: '165' },
  { st: 'WY', fips: '56', election: 'WY 2026 Statewide General', districts: 1, band: [-560099, -560001], sourceGate: '165' },
];

// The 4 withheld / Polygon Pending marker elections. Migrations 1247 (TN), 1248 (AL)
// and 1249 (LA) emptied three of them; only MO should still hold races.
const MARKER_ELECTIONS: { st: string; name: string }[] = [
  { st: 'TN', name: 'TN 2026 Congressional Redistricting - Polygon Pending' },
  { st: 'MO', name: 'MO 2026 Congressional Redistricting - Polygon Pending' },
  { st: 'AL', name: 'AL 2026 Congressional Redistricting - Polygon Pending' },
  { st: 'LA', name: 'LA 2026 Congressional Redistricting - Polygon Pending' },
];

const EXPECTED_TOTAL_DISTRICTS = 178;

// FIPS -> state abbreviation. 42 elections make the CASE-on-election_id form used by
// 152 and 162 unmanageable, so the state is derived from substr(geo_id,1,2) instead.
const FIPS_TO_ST: Record<string, string> = Object.fromEntries(STATES.map((s) => [s.fips, s.st]));
const GEO_PREFIXES = STATES.map((s) => s.fips);

interface HouseRow {
  fips: string;
  st: string;
  geo_id: string;
  race_id: string;
  election_id: string;
  description: string | null;
  primary_party: string | null;
  rc_id: string | null;
  politician_id: string | null;
  full_name: string | null;
  candidate_status: string | null;
  is_incumbent: boolean | null;
  external_id: string | null;
}

/** True when `ext` falls inside any of the 38 Phase-166 new-candidate bands. */
function inAnyBand(ext: number): boolean {
  return STATES.some((s) => ext >= s.band[0] && ext <= s.band[1]);
}

/**
 * Which state's band claims `ext`. When this differs from the state the candidate is
 * actually racing in, the id is a CROSS-STATE BAND COLLISION — a legacy record whose
 * external_id happens to fall inside another state's Wave-3 seeding band (CLAUDE.md:
 * "new external_id bands can be POLLUTED -> scope via race_candidates joins, not raw
 * band"). Every id here entered through a race_candidates join, so it is in scope; the
 * label just must not claim it was seeded by the band's owner.
 */
function bandOwner(ext: number): string | null {
  return STATES.find((s) => ext >= s.band[0] && ext <= s.band[1])?.st ?? null;
}

async function resolveElections(): Promise<{ generals: Map<string, string>; markers: Map<string, string> }> {
  const generals = new Map<string, string>();
  const markers = new Map<string, string>();
  const missing: string[] = [];

  for (const s of STATES) {
    const r = await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [s.election]);
    if (!r.rows.length) missing.push(`${s.st} general: ${s.election}`);
    else generals.set(s.st, r.rows[0].id);
  }
  for (const m of MARKER_ELECTIONS) {
    const r = await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [m.name]);
    if (!r.rows.length) missing.push(`${m.st} marker: ${m.name}`);
    else markers.set(m.st, r.rows[0].id);
  }
  if (missing.length) {
    throw new Error(`FAIL setup: ${missing.length} of 42 election name(s) did not resolve:\n  ${missing.join('\n  ')}`);
  }
  return { generals, markers };
}

async function loadHouse(electionIds: string[]): Promise<HouseRow[]> {
  const q = await pool.query(
    `SELECT substr(d.geo_id, 1, 2) AS fips,
            d.geo_id,
            r.id            AS race_id,
            r.election_id   AS election_id,
            r.description,
            r.primary_party,
            rc.id           AS rc_id,
            rc.politician_id,
            rc.full_name,
            rc.candidate_status,
            rc.is_incumbent,
            p.external_id
     FROM essentials.races r
     JOIN essentials.offices   o ON o.id = r.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
     LEFT JOIN essentials.politicians     p  ON p.id = rc.politician_id
     WHERE r.election_id = ANY($1::uuid[])
       AND d.district_type = 'NATIONAL_LOWER'
       AND substr(d.geo_id, 1, 2) = ANY($2::text[])`,
    [electionIds, GEO_PREFIXES]
  );
  return q.rows.map((r) => ({ ...r, st: FIPS_TO_ST[r.fips] })) as HouseRow[];
}

// ---------------------------------------------------------------------------
// Task 1 — scope layer: per-state census + band-filter delta.
// ---------------------------------------------------------------------------
interface Scope {
  house: HouseRow[];
  /** distinct politician_id, banded + active (the SUPERSET filter the gate uses) */
  bandedActive: Map<string, number>;
  /** distinct politician_id, banded + active + is_incumbent=false (165's stricter form) */
  bandedActiveChallengers: Map<string, number>;
  stateOf: Map<string, string>;
}

function deriveScope(house: HouseRow[]): Scope {
  const byState = new Map<string, { races: Set<string>; active: number; banded: Set<string> }>();
  for (const s of STATES) byState.set(s.st, { races: new Set(), active: 0, banded: new Set() });

  const bandedActive = new Map<string, number>();
  const bandedActiveChallengers = new Map<string, number>();
  const stateOf = new Map<string, string>();

  for (const row of house) {
    const bucket = byState.get(row.st);
    if (!bucket) throw new Error(`FAIL scope: geo prefix ${row.fips} (geo_id ${row.geo_id}) maps to no in-scope state`);
    bucket.races.add(row.race_id);
    if (row.candidate_status !== 'active') continue;
    bucket.active++;
    if (row.external_id === null || row.politician_id === null) continue;
    const ext = Number(row.external_id);
    if (!inAnyBand(ext)) continue;
    bucket.banded.add(row.politician_id);
    bandedActive.set(row.politician_id, ext);
    stateOf.set(row.politician_id, row.st);
    if (row.is_incumbent === false) bandedActiveChallengers.set(row.politician_id, ext);
  }

  console.log('=== PER-STATE CENSUS (live, %s) ===', DERIVED_AT);
  console.log('ST  FIPS  races  active  banded-new');
  const mismatches: string[] = [];
  let total = 0;
  for (const s of STATES) {
    const b = byState.get(s.st)!;
    total += b.races.size;
    console.log(
      `${s.st}  ${s.fips}    ${String(b.races.size).padStart(3)}    ${String(b.active).padStart(4)}      ${String(b.banded.size).padStart(4)}`
    );
    if (b.races.size !== s.districts) mismatches.push(`${s.st}: ${b.races.size} races (expected ${s.districts})`);
  }
  if (mismatches.length) {
    throw new Error(`FAIL scope: ${mismatches.length} state(s) with wrong district count:\n  ${mismatches.join('\n  ')}`);
  }
  console.log(`TOTAL DISTRICTS: ${total}`);
  if (total !== EXPECTED_TOTAL_DISTRICTS) {
    throw new Error(`FAIL scope: total districts=${total} (expected ${EXPECTED_TOTAL_DISTRICTS})`);
  }

  // Band-filter delta. The gate uses the SUPERSET `active` form (161/162/163/164) rather
  // than 165's `active AND is_incumbent=false`, because a superset demands an image-or-pin
  // from strictly MORE candidates — the safe direction for a gate. Enumerate the difference
  // so the choice is auditable rather than asserted.
  const diff = [...bandedActive.entries()].filter(([pid]) => !bandedActiveChallengers.has(pid));
  diff.sort((a, b) => b[1] - a[1]);
  console.log(
    `\nBAND FILTER DELTA: active=${bandedActive.size} active+is_incumbent=false=${bandedActiveChallengers.size} difference=${diff.length}`
  );
  let collisions = 0;
  for (const [pid, ext] of diff) {
    const racingIn = stateOf.get(pid)!;
    const owner = bandOwner(ext);
    const collided = owner !== racingIn;
    if (collided) collisions++;
    const nameRow = house.find((h) => h.politician_id === pid && h.candidate_status === 'active');
    console.log(
      `  +${racingIn} ${ext} ${nameRow?.full_name ?? '?'} — active INCUMBENT` +
        (collided
          ? `; CROSS-STATE BAND COLLISION: this id sits inside ${owner}'s band, not ${racingIn}'s (legacy record, entered via the race_candidates join)`
          : `; genuinely inside ${racingIn}'s own band`)
    );
  }
  console.log(
    `BAND FILTER DELTA DETAIL: all ${diff.length} are active incumbents; ${collisions} are cross-state band collisions, ` +
      `${diff.length - collisions} sit inside their own state's band. The gate uses the SUPERSET (active) form, so all ${diff.length} ` +
      `must carry an image-or-pin — strictly more demanding than 165's active+is_incumbent=false form.`
  );

  return { house, bandedActive, bandedActiveChallengers, stateOf };
}

async function main() {
  const { generals, markers } = await resolveElections();
  const allElectionIds = [...generals.values(), ...markers.values()];
  console.log(`Resolved ${allElectionIds.length} of 42 elections (${generals.size} generals + ${markers.size} markers).\n`);

  const house = await loadHouse(allElectionIds);
  deriveScope(house);

  await pool.end();
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
