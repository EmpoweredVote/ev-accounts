/**
 * In-process replacements for the two HTTP calls the standalone slice-assignment service
 * made back to the accounts engine (engine consolidation — ev-cto decision 0018):
 *
 *   GET  /api/account/me        -> getAccountMe(accessToken, userId)   (lib/accountMeService)
 *   POST /api/roles/check {...}  -> getCachedUserRoles + checkRole      (lib/roleService)
 *
 * The engine already owns both. Folding removes a network hop, a duplicated dual-issuer
 * verifier, and the "both verifiers must have WorkOS registered" failure mode — there is now
 * one verifier (requireAuth) and one role cache.
 */
import { getAccountMe } from '../../lib/accountMeService.js';
import { getCachedUserRoles, checkRole } from '../../lib/roleService.js';

export interface AccountData {
  id: string;
  display_name: string;
  tier: 'inform' | 'connected' | 'empowered';
  account_standing: 'active' | 'suspended';
  // Every field is nullable in practice, whatever the API's own docs imply. A point can sit
  // outside a layer we hold: a Buncombe County, NC address on 2026-09-01 resolved a county, a
  // congressional district and a senate district but NO school district, because no
  // school-district boundary covers it. Typing these as non-null hid that until it reached a
  // NOT NULL column at runtime.
  jurisdiction: {
    congressional_district: string | null;
    state_senate_district: string | null;
    state_house_district: string | null;
    county: string | null;
    school_district: string | null;
    // 🔴 The geoid keys, and NOT the `state` / `city` keys that sit beside them in the same
    // object. Those two carry the geocoded USPS code and place NAME — 'NC' and 'ASHEVILLE' —
    // not Census FIPS. Both are truthy strings, so reading the wrong pair would sail past the
    // null guard in assignUserToSlices and key a slice on 'NC'. They are deliberately not
    // declared here: a key this module must never read is better absent than available.
    city_geoid: string | null;
    state_geoid: string | null;
    nation_geoid: string | null;
  } | null;
}

/**
 * The account composite the assigner reads. getAccountMe returns the identical shape the old
 * GET /api/account/me route served (it is the shared builder that route calls), so this is a
 * cast, not a re-map — the same trust model the standalone had for the HTTP JSON.
 */
export async function fetchAccountData(accessToken: string, userId: string): Promise<AccountData> {
  const me = await getAccountMe(accessToken, userId);
  return me as unknown as AccountData;
}

/**
 * Whether the user holds the platform-scope volunteer role.
 *
 * Reproduces exactly what the standalone sent — POST /api/roles/check with
 * { feature_scope: 'volunteer', jurisdiction_geoid: null } — including the null. In the roles
 * route, a body `jurisdiction_geoid: null` becomes `scope.geoid = null` (because null !==
 * undefined), and checkRole with geoid=null matches ONLY grants whose jurisdiction_geoid is
 * null (an unrestricted, platform-scope grant). Passing `{}` (geoid undefined) would instead
 * match a volunteer grant scoped to ANY geoid — a different, wider rule. The null is
 * load-bearing; keep it.
 *
 * Uses getCachedUserRoles so revocation still lags by at most the 90s role cache, identical to
 * the HTTP path. This is what makes the "removed from the volunteer slice on revocation" path
 * behave as before.
 */
export async function checkVolunteerRole(userId: string): Promise<boolean> {
  const grants = await getCachedUserRoles(userId);
  // checkRole's scope type is { geoid?: string }; null is the faithful value (see above).
  return checkRole(grants, 'volunteer', { geoid: null as unknown as string });
}
