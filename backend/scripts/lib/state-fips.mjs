/**
 * USPS code <-> 2-digit state FIPS, in one place.
 *
 * 🔴 THIS MAP IS TYPED OUT BY HAND EVERY TIME IT IS COPIED, AND HAND-TYPING IT HAS ALREADY
 *    DROPPED A JURISDICTION. `census-coverage-report.mts` carries its own copy whose comment
 *    records the failure verbatim: `dc: '11'` was MISSING, so `--state dc` wrote
 *    `state_fips: ""` and silently reported "universe categories: none" for a state that has
 *    G4020 and G5220 geofences. DC is the one FIPS between de:10 and fl:12 — exactly where an
 *    eye skips when reading a list out state by state.
 *
 *    So new readers import this module. The existing copies are NOT retro-refactored here
 *    (they are TypeScript and typechecking their import chain is a separate change), but this
 *    is the definition new code takes.
 *
 * ⚠ TWO DIFFERENT THINGS ARE BOTH CALLED "state" IN THIS REPO, and confusing them is a silent
 *   empty result rather than an error:
 *     * `essentials.geofence_boundaries.state`     -> 2-digit FIPS  ('06')
 *     * `essentials.districts.state`               -> USPS, mixed case  ('CA', 'ca')
 *   See CLAUDE.md. Anything comparing the two must convert deliberately, which is what this is.
 *
 * Includes DC and the five territories, because ADR 0003 seats non-voting delegates from all of
 * them and they hold real offices in this database.
 */

/** USPS (lowercase) -> 2-digit FIPS. */
export const USPS_TO_FIPS = Object.freeze({
  al: "01", ak: "02", az: "04", ar: "05", ca: "06", co: "08", ct: "09", de: "10",
  dc: "11", fl: "12", ga: "13", hi: "15", id: "16", il: "17", in: "18", ia: "19",
  ks: "20", ky: "21", la: "22", me: "23", md: "24", ma: "25", mi: "26", mn: "27",
  ms: "28", mo: "29", mt: "30", ne: "31", nv: "32", nh: "33", nj: "34", nm: "35",
  ny: "36", nc: "37", nd: "38", oh: "39", ok: "40", or: "41", pa: "42", ri: "44",
  sc: "45", sd: "46", tn: "47", tx: "48", ut: "49", vt: "50", va: "51", wa: "53",
  wv: "54", wi: "55", wy: "56",
  // Territories. AS/GU/MP/PR/VI each send a non-voting delegate; see ADR 0003.
  as: "60", gu: "66", mp: "69", pr: "72", vi: "78",
});

/** 2-digit FIPS -> USPS (lowercase). */
export const FIPS_TO_USPS = Object.freeze(
  Object.fromEntries(Object.entries(USPS_TO_FIPS).map(([usps, fips]) => [fips, usps])));

/** FIPS for a USPS code in any case, or null. Never returns "" — an empty FIPS matches nothing. */
export function fipsOf(usps) {
  if (typeof usps !== "string") return null;
  return USPS_TO_FIPS[usps.trim().toLowerCase()] ?? null;
}

/** USPS for a 2-digit FIPS, or null. Accepts a longer geo_id and reads its first two digits. */
export function uspsOf(fips) {
  if (typeof fips !== "string") return null;
  const two = fips.trim().slice(0, 2);
  return FIPS_TO_USPS[two] ?? null;
}
