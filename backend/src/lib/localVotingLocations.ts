import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Local voting locations — a hand-checked fallback for counties where Google's
// Voting Information Project (VIP) data has holes. Tables: CA_0320.
//
// WHY. Monroe County, Indiana assigns each voter one Election Day polling place
// by precinct. Measured 2026-10-22 on 186 real county addresses: every polling
// place Google returned matched the county's official list, but about a third of
// lookups returned none — and the same address flipped between an answer and no
// answer on retries. So Google stays first; this fills in only what it left empty.
//
// SAFETY CONTRACT. The worst failure here is sending a voter to the wrong place,
// so this module prefers showing nothing:
//   - A set is used only through its election day. After that it is ignored.
//   - An address must fall inside exactly one precinct of the set.
//   - If any OTHER precinct with a DIFFERENT Election Day site lies within
//     BOUNDARY_GUARD_DEGREES of the point, the Election Day site is withheld
//     (`nearBoundary`). The geocoder places a house by interpolating along its
//     street, and precinct lines often run down the middle of a street, so a
//     point near a line can sit on the wrong side of it.
//   - The early-voting sites are open to every voter in the county, so they are
//     safe to show for any address inside the set, near a line or not.
//
// ⚠ ev-cto decision 0006: every predicate here pins SRID 4326 and avoids
// ST_Transform and ::geography (both read public.spatial_ref_sys). That is why the
// guard distance is in DEGREES, not meters.
// ---------------------------------------------------------------------------

/**
 * 0.0009° is about 100 m north–south and about 78 m east–west at Monroe County's
 * latitude (39° N). Measured against the plan's "about 75 meters".
 */
export const BOUNDARY_GUARD_DEGREES = 0.0009;

export interface LocalVotingSite {
  id: number;
  kind: 'election_day' | 'early_vote';
  name: string;
  address: string;
  lat: number | null;
  lng: number | null;
  hours: string | null;
  startDate: string | null; // ISO date
  endDate: string | null;   // ISO date
  precinctCodes: string[];
}

export interface LocalVotingSet {
  id: number;
  countyName: string;
  electionName: string;
  electionDate: string; // ISO date
  sourceLabel: string;
  sourceUrl: string;
  lastChecked: string;  // ISO date
  lookupUrl: string | null;
}

export interface LocalVotingLocations {
  set: LocalVotingSet;
  precinctCode: string;
  /** The voter's assigned Election Day site, or null when withheld or unknown. */
  electionDaySite: LocalVotingSite | null;
  /** True when the Election Day site was withheld because a precinct line is close. */
  nearBoundary: boolean;
  earlyVoteSites: LocalVotingSite[];
}

/**
 * The decision, kept free of the database so it can be tested on its own.
 *
 * `coveringCodes` are the precincts whose polygon covers the point; `nearbyCodes`
 * are the precincts within the guard distance (which includes the covering one).
 */
export function resolveLocalLocations(
  set: LocalVotingSet,
  coveringCodes: string[],
  nearbyCodes: string[],
  sites: LocalVotingSite[],
  today: string,
): LocalVotingLocations | null {
  // Zero precincts: the address is outside the county. Two or more: overlapping
  // polygons, and we cannot say which one is right. Either way, no answer.
  if (coveringCodes.length !== 1) return null;
  const precinctCode = coveringCodes[0];

  const electionDay = sites.filter((s) => s.kind === 'election_day');
  const siteFor = (code: string) => electionDay.filter((s) => s.precinctCodes.includes(code));

  const own = siteFor(precinctCode);
  // A precinct listed at two sites (or at none) is a data error. Do not guess.
  const assigned = own.length === 1 ? own[0] : null;
  const nearBoundary =
    assigned !== null &&
    nearbyCodes.some((code) => {
      if (code === precinctCode) return false;
      const theirs = siteFor(code);
      return theirs.length !== 1 || theirs[0].id !== assigned.id;
    });

  const earlyVoteSites = sites.filter(
    (s) => s.kind === 'early_vote' && (s.endDate === null || s.endDate >= today),
  );

  return {
    set,
    precinctCode,
    electionDaySite: assigned && !nearBoundary ? assigned : null,
    nearBoundary,
    earlyVoteSites,
  };
}

/** Today's date where the county votes. Every set so far is in Indiana's Eastern time. */
export function localToday(now: Date = new Date(), timeZone = 'America/Indiana/Indianapolis'): string {
  // en-CA formats as YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
}

const isoDate = (d: Date | string | null): string | null =>
  d === null ? null : typeof d === 'string' ? d.slice(0, 10) : d.toISOString().slice(0, 10);

/**
 * Look up the hand-checked locations for a point. Null when no current set
 * covers it. Throws only on a database error; the caller treats that as "no
 * fallback", never as a failed request.
 */
export async function lookupLocalVotingLocations(
  origin: { lat: number; lng: number },
  today: string = localToday(),
): Promise<LocalVotingLocations | null> {
  // $1 = lng, $2 = lat — ST_MakePoint takes (x, y).
  const covering = await pool.query<{ set_id: number; code: string }>(
    `SELECT p.set_id, p.code
       FROM essentials.voting_precincts p
       JOIN essentials.voting_location_sets s ON s.id = p.set_id
      WHERE s.election_date >= $3::date
        AND ST_Covers(p.geometry, ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326))
      ORDER BY s.election_date`,
    [origin.lng, origin.lat, today],
  );
  if (covering.rows.length === 0) return null;

  // The soonest election wins if two sets ever cover the same place.
  const setId = covering.rows[0].set_id;
  const coveringCodes = covering.rows.filter((r) => r.set_id === setId).map((r) => r.code);

  const [setRes, nearbyRes, sitesRes] = await Promise.all([
    pool.query(
      `SELECT id, county_name, election_name, election_date, source_label, source_url, last_checked, lookup_url
         FROM essentials.voting_location_sets WHERE id = $1`,
      [setId],
    ),
    pool.query<{ code: string }>(
      `SELECT code FROM essentials.voting_precincts
        WHERE set_id = $1
          AND ST_DWithin(geometry, ST_SetSRID(ST_MakePoint($2::float8, $3::float8), 4326), $4::float8)`,
      [setId, origin.lng, origin.lat, BOUNDARY_GUARD_DEGREES],
    ),
    pool.query(
      `SELECT id, kind, name, address, lat, lng, hours, start_date, end_date, precinct_codes
         FROM essentials.voting_sites WHERE set_id = $1 ORDER BY id`,
      [setId],
    ),
  ]);

  const s = setRes.rows[0];
  const set: LocalVotingSet = {
    id: s.id,
    countyName: s.county_name,
    electionName: s.election_name,
    electionDate: isoDate(s.election_date)!,
    sourceLabel: s.source_label,
    sourceUrl: s.source_url,
    lastChecked: isoDate(s.last_checked)!,
    lookupUrl: s.lookup_url,
  };
  const sites: LocalVotingSite[] = sitesRes.rows.map((r) => ({
    id: r.id,
    kind: r.kind,
    name: r.name,
    address: r.address,
    lat: r.lat,
    lng: r.lng,
    hours: r.hours,
    startDate: isoDate(r.start_date),
    endDate: isoDate(r.end_date),
    precinctCodes: r.precinct_codes ?? [],
  }));

  return resolveLocalLocations(set, coveringCodes, nearbyRes.rows.map((r) => r.code), sites, today);
}
