/**
 * federalCoverage.ts — federal + state-government coverage, for EVERY state.
 *
 * The completeness map (coverageMapService) deliberately rolls up only LOCAL
 * government (county / place / school district). That made the Coverage page
 * blind to a whole tier we do cover everywhere: every state's U.S. senators and
 * representatives are loaded (plus governors, statewide execs and, in tracked
 * states, the legislature) — yet untracked states painted "not started" and
 * tracked states' scores ignored those officials entirely.
 *
 * This module answers "how well do we cover a state's federal + state offices?"
 * for all 56 states/territories, live from the DB (no YAML involved):
 *
 *   senate   — bare-state district + title 'Senator' / 'U.S. Senate%'.
 *              State senators can't collide: they sit at /sldu: districts.
 *   house    — /cd: districts. Includes the non-voting delegates (DC + the five
 *              territories, ADR 0003) — that IS the state's House delegation.
 *              DC's shadow senators also sit at cd:98 but hold no seat in
 *              Congress, so they're classified 'statewide', not 'house'.
 *   governor — bare-state district + role_canonical/title 'Governor'.
 *   statewide— every other bare-state officeholder (AG, SoS, treasurer, courts…).
 *   stateleg — /sldu: + /sldl: districts (only tracked states have these loaded).
 *   candidate— offices titled 'Candidate for …' (2026 Senate challengers seated
 *              by the migration-1459 backfill). They are TRACKED PEOPLE, not
 *              officeholders — counted separately and never as a filled seat.
 *
 * Denominators are honest: Senate = 2 for the 50 states (0 for DC/territories),
 * House = the state's /cd: district count in essentials.districts, legislature =
 * loaded /sldu:+/sldl: district count (0 ⇒ unknown ⇒ axis dropped). We never
 * invent a universe we haven't loaded.
 */

import { pool } from './db.js';
import { HAS_RENDERABLE_PHOTO_SQL } from './photoCoverage.js';
import { HAS_ANY_CONTRIBUTION_SQL } from './donorCoverage.js';

/** All 56 postal jurisdictions: 50 states + DC + the five territories. */
export interface StateMeta {
  code: string; // 2-letter lowercase
  fips: string; // 2-digit
  name: string;
  senateSeats: 0 | 2; // voting U.S. Senate seats
  governorSeats: 0 | 1; // 0 only for DC (mayor, tracked as a statewide exec)
}

export const ALL_STATES: StateMeta[] = [
  { code: 'al', fips: '01', name: 'Alabama', senateSeats: 2, governorSeats: 1 },
  { code: 'ak', fips: '02', name: 'Alaska', senateSeats: 2, governorSeats: 1 },
  { code: 'az', fips: '04', name: 'Arizona', senateSeats: 2, governorSeats: 1 },
  { code: 'ar', fips: '05', name: 'Arkansas', senateSeats: 2, governorSeats: 1 },
  { code: 'ca', fips: '06', name: 'California', senateSeats: 2, governorSeats: 1 },
  { code: 'co', fips: '08', name: 'Colorado', senateSeats: 2, governorSeats: 1 },
  { code: 'ct', fips: '09', name: 'Connecticut', senateSeats: 2, governorSeats: 1 },
  { code: 'de', fips: '10', name: 'Delaware', senateSeats: 2, governorSeats: 1 },
  { code: 'dc', fips: '11', name: 'District of Columbia', senateSeats: 0, governorSeats: 0 },
  { code: 'fl', fips: '12', name: 'Florida', senateSeats: 2, governorSeats: 1 },
  { code: 'ga', fips: '13', name: 'Georgia', senateSeats: 2, governorSeats: 1 },
  { code: 'hi', fips: '15', name: 'Hawaii', senateSeats: 2, governorSeats: 1 },
  { code: 'id', fips: '16', name: 'Idaho', senateSeats: 2, governorSeats: 1 },
  { code: 'il', fips: '17', name: 'Illinois', senateSeats: 2, governorSeats: 1 },
  { code: 'in', fips: '18', name: 'Indiana', senateSeats: 2, governorSeats: 1 },
  { code: 'ia', fips: '19', name: 'Iowa', senateSeats: 2, governorSeats: 1 },
  { code: 'ks', fips: '20', name: 'Kansas', senateSeats: 2, governorSeats: 1 },
  { code: 'ky', fips: '21', name: 'Kentucky', senateSeats: 2, governorSeats: 1 },
  { code: 'la', fips: '22', name: 'Louisiana', senateSeats: 2, governorSeats: 1 },
  { code: 'me', fips: '23', name: 'Maine', senateSeats: 2, governorSeats: 1 },
  { code: 'md', fips: '24', name: 'Maryland', senateSeats: 2, governorSeats: 1 },
  { code: 'ma', fips: '25', name: 'Massachusetts', senateSeats: 2, governorSeats: 1 },
  { code: 'mi', fips: '26', name: 'Michigan', senateSeats: 2, governorSeats: 1 },
  { code: 'mn', fips: '27', name: 'Minnesota', senateSeats: 2, governorSeats: 1 },
  { code: 'ms', fips: '28', name: 'Mississippi', senateSeats: 2, governorSeats: 1 },
  { code: 'mo', fips: '29', name: 'Missouri', senateSeats: 2, governorSeats: 1 },
  { code: 'mt', fips: '30', name: 'Montana', senateSeats: 2, governorSeats: 1 },
  { code: 'ne', fips: '31', name: 'Nebraska', senateSeats: 2, governorSeats: 1 },
  { code: 'nv', fips: '32', name: 'Nevada', senateSeats: 2, governorSeats: 1 },
  { code: 'nh', fips: '33', name: 'New Hampshire', senateSeats: 2, governorSeats: 1 },
  { code: 'nj', fips: '34', name: 'New Jersey', senateSeats: 2, governorSeats: 1 },
  { code: 'nm', fips: '35', name: 'New Mexico', senateSeats: 2, governorSeats: 1 },
  { code: 'ny', fips: '36', name: 'New York', senateSeats: 2, governorSeats: 1 },
  { code: 'nc', fips: '37', name: 'North Carolina', senateSeats: 2, governorSeats: 1 },
  { code: 'nd', fips: '38', name: 'North Dakota', senateSeats: 2, governorSeats: 1 },
  { code: 'oh', fips: '39', name: 'Ohio', senateSeats: 2, governorSeats: 1 },
  { code: 'ok', fips: '40', name: 'Oklahoma', senateSeats: 2, governorSeats: 1 },
  { code: 'or', fips: '41', name: 'Oregon', senateSeats: 2, governorSeats: 1 },
  { code: 'pa', fips: '42', name: 'Pennsylvania', senateSeats: 2, governorSeats: 1 },
  { code: 'ri', fips: '44', name: 'Rhode Island', senateSeats: 2, governorSeats: 1 },
  { code: 'sc', fips: '45', name: 'South Carolina', senateSeats: 2, governorSeats: 1 },
  { code: 'sd', fips: '46', name: 'South Dakota', senateSeats: 2, governorSeats: 1 },
  { code: 'tn', fips: '47', name: 'Tennessee', senateSeats: 2, governorSeats: 1 },
  { code: 'tx', fips: '48', name: 'Texas', senateSeats: 2, governorSeats: 1 },
  { code: 'ut', fips: '49', name: 'Utah', senateSeats: 2, governorSeats: 1 },
  { code: 'vt', fips: '50', name: 'Vermont', senateSeats: 2, governorSeats: 1 },
  { code: 'va', fips: '51', name: 'Virginia', senateSeats: 2, governorSeats: 1 },
  { code: 'wa', fips: '53', name: 'Washington', senateSeats: 2, governorSeats: 1 },
  { code: 'wv', fips: '54', name: 'West Virginia', senateSeats: 2, governorSeats: 1 },
  { code: 'wi', fips: '55', name: 'Wisconsin', senateSeats: 2, governorSeats: 1 },
  { code: 'wy', fips: '56', name: 'Wyoming', senateSeats: 2, governorSeats: 1 },
  { code: 'as', fips: '60', name: 'American Samoa', senateSeats: 0, governorSeats: 1 },
  { code: 'gu', fips: '66', name: 'Guam', senateSeats: 0, governorSeats: 1 },
  { code: 'mp', fips: '69', name: 'Northern Mariana Islands', senateSeats: 0, governorSeats: 1 },
  { code: 'pr', fips: '72', name: 'Puerto Rico', senateSeats: 0, governorSeats: 1 },
  { code: 'vi', fips: '78', name: 'U.S. Virgin Islands', senateSeats: 0, governorSeats: 1 },
];

export type FederalTier = 'senate' | 'house' | 'governor' | 'statewide' | 'stateleg' | 'candidate';

/**
 * The tier classifier, shared verbatim by the rollup and the per-member list so
 * the two can never disagree. Requires aliases: o = offices, d = districts.
 * Order matters — 'candidate' must win over everything (challengers sit at the
 * same districts as the seats they contest), and shadow senators must be caught
 * before the generic /cd: house branch.
 *
 * ⚠ THERE IS A SIBLING: `scripts/lib/office-tiers.mjs` maps the same people to
 * the COMPASS vocabulary (federal | state | local | judicial) that
 * compass_topic_roles uses, because a research batch asks "does this topic
 * display for this person", not "how covered is this state". It is derived from
 * the rules below rather than being a second opinion — in particular it carries
 * the same two sitting-senator title formats. **Change both together.** It goes
 * further in three places this module has no reason to: President and Vice
 * President (bare country division, NULL here), district/territory divisions,
 * and a judicial branch.
 */
export const TIER_CASE_SQL = `CASE
    WHEN o.title ILIKE 'candidate for%' THEN 'candidate'
    WHEN d.ocd_id ~ '^ocd-division/country:us/state:[a-z]{2}$'
         AND (o.title = 'Senator' OR o.title ILIKE 'u.s. senate%') THEN 'senate'
    WHEN d.ocd_id ~ '/cd:' AND o.title ILIKE '%shadow senator%' THEN 'statewide'
    WHEN d.ocd_id ~ '/cd:' THEN 'house'
    WHEN d.ocd_id ~ '^ocd-division/country:us/state:[a-z]{2}$'
         AND (o.role_canonical = 'governor' OR o.title = 'Governor') THEN 'governor'
    WHEN d.ocd_id ~ '^ocd-division/country:us/state:[a-z]{2}$' THEN 'statewide'
    WHEN d.ocd_id ~ '/sldu:' OR d.ocd_id ~ '/sldl:' THEN 'stateleg'
    ELSE NULL
  END`;

export interface TierCounts {
  total: number;
  withPhoto: number;
  researched: number;
  withDonors: number;
  districtsCovered: number; // distinct districts with ≥1 holder (house / stateleg)
}

export interface FederalStateStats {
  code: string;
  fips: string;
  name: string;
  senate: { filled: number; expected: number; withPhoto: number; researched: number };
  house: {
    filled: number; // politicians (can exceed districts on data errors — do not use as roster)
    districtsCovered: number;
    expected: number; // /cd: district count for this state
    withPhoto: number;
    researched: number;
  };
  governor: { filled: number; expected: number };
  statewideExecs: number; // other bare-state officeholders (AG, SoS, courts…)
  stateLeg: {
    members: number;
    districtsCovered: number;
    districtsTotal: number; // 0 = legislative districts not loaded → unknown universe
    researched: number;
  };
  candidatesTracked: number;
  /** Composite 0..100 — see federalStateScore. */
  score: number;
}

const EMPTY_TIER: TierCounts = { total: 0, withPhoto: 0, researched: 0, withDonors: 0, districtsCovered: 0 };

/**
 * Pure composite over the federal + state tiers, 0..100. Same renormalising
 * axis model as coverageMapService.compositeScore: an axis with no denominator
 * (DC has no Senate seats; most states have no legislative districts loaded)
 * is DROPPED and the remaining weights renormalise — a state is scored on the
 * offices it can actually have, never punished for a universe we haven't loaded.
 */
export function federalStateScore(s: {
  senateFilled: number; senateExpected: number;
  houseCovered: number; houseExpected: number;
  governorFilled: number; governorExpected: number;
  delegationResearched: number; delegationTotal: number;
  delegationWithPhoto: number;
  stateLegCovered: number; stateLegTotal: number;
}): number {
  const axes: { weight: number; value: number }[] = [];
  if (s.senateExpected > 0) axes.push({ weight: 0.2, value: Math.min(1, s.senateFilled / s.senateExpected) });
  if (s.houseExpected > 0) axes.push({ weight: 0.3, value: Math.min(1, s.houseCovered / s.houseExpected) });
  if (s.governorExpected > 0) axes.push({ weight: 0.1, value: s.governorFilled > 0 ? 1 : 0 });
  if (s.delegationTotal > 0) {
    axes.push({ weight: 0.2, value: s.delegationResearched / s.delegationTotal });
    axes.push({ weight: 0.1, value: s.delegationWithPhoto / s.delegationTotal });
  }
  if (s.stateLegTotal > 0) axes.push({ weight: 0.1, value: Math.min(1, s.stateLegCovered / s.stateLegTotal) });
  const wsum = axes.reduce((sum, a) => sum + a.weight, 0);
  if (wsum === 0) return 0;
  const score = axes.reduce((sum, a) => sum + a.weight * a.value, 0) / wsum;
  return Math.round(score * 1000) / 10;
}

/**
 * One aggregate per (state, tier) over active politicians. Cheap (~5.8k active
 * politicians, no PostGIS), so unlike buildJurisdictions this runs in ONE query
 * for all 56 states.
 */
async function tierStatsByState(): Promise<Map<string, Map<FederalTier, TierCounts>>> {
  const { rows } = await pool.query<{
    state: string | null;
    tier: FederalTier | null;
    total: string;
    with_photos: string;
    researched: string;
    with_donors: string;
    districts_covered: string;
  }>(
    `SELECT
       (regexp_match(d.ocd_id, '^ocd-division/country:us/state:([a-z]{2})'))[1] AS state,
       ${TIER_CASE_SQL} AS tier,
       COUNT(DISTINCT p.id)                                              AS total,
       COUNT(DISTINCT p.id) FILTER (WHERE ${HAS_RENDERABLE_PHOTO_SQL})   AS with_photos,
       COUNT(DISTINCT p.id) FILTER (WHERE ans.politician_id IS NOT NULL) AS researched,
       COUNT(DISTINCT p.id) FILTER (WHERE ${HAS_ANY_CONTRIBUTION_SQL})   AS with_donors,
       COUNT(DISTINCT d.ocd_id)                                          AS districts_covered
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
       AND d.ocd_id LIKE 'ocd-division/country:us/state:%'
     GROUP BY 1, 2`,
  );
  const out = new Map<string, Map<FederalTier, TierCounts>>();
  for (const r of rows) {
    if (!r.state || !r.tier) continue;
    const tiers = out.get(r.state) ?? new Map<FederalTier, TierCounts>();
    tiers.set(r.tier, {
      total: Number(r.total),
      withPhoto: Number(r.with_photos),
      researched: Number(r.researched),
      withDonors: Number(r.with_donors),
      districtsCovered: Number(r.districts_covered),
    });
    out.set(r.state, tiers);
  }
  return out;
}

/** /cd: and /sldu:+/sldl: district counts per state — the seat denominators. */
async function districtTotalsByState(): Promise<Map<string, { cd: number; sld: number }>> {
  const { rows } = await pool.query<{ state: string | null; cd: string; sld: string }>(
    `SELECT
       (regexp_match(ocd_id, '^ocd-division/country:us/state:([a-z]{2})'))[1] AS state,
       COUNT(DISTINCT ocd_id) FILTER (WHERE ocd_id ~ '/cd:')     AS cd,
       COUNT(DISTINCT ocd_id) FILTER (WHERE ocd_id ~ '/sld[ul]:') AS sld
     FROM essentials.districts
     WHERE ocd_id LIKE 'ocd-division/country:us/state:%'
     GROUP BY 1`,
  );
  const out = new Map<string, { cd: number; sld: number }>();
  for (const r of rows) {
    if (r.state) out.set(r.state, { cd: Number(r.cd), sld: Number(r.sld) });
  }
  return out;
}

/**
 * Federal + state coverage for every state/territory, keyed by 2-letter code.
 * Uncached here — coverageMapService caches the combined state payload.
 */
export async function getFederalStateStats(): Promise<Map<string, FederalStateStats>> {
  const [tiers, districts] = await Promise.all([tierStatsByState(), districtTotalsByState()]);
  const out = new Map<string, FederalStateStats>();
  for (const meta of ALL_STATES) {
    const t = tiers.get(meta.code);
    const senate = t?.get('senate') ?? EMPTY_TIER;
    const house = t?.get('house') ?? EMPTY_TIER;
    const governor = t?.get('governor') ?? EMPTY_TIER;
    const statewide = t?.get('statewide') ?? EMPTY_TIER;
    const stateleg = t?.get('stateleg') ?? EMPTY_TIER;
    const candidate = t?.get('candidate') ?? EMPTY_TIER;
    const d = districts.get(meta.code) ?? { cd: 0, sld: 0 };

    const delegationTotal = senate.total + house.total + governor.total;
    const score = federalStateScore({
      senateFilled: senate.total,
      senateExpected: meta.senateSeats,
      houseCovered: house.districtsCovered,
      houseExpected: d.cd,
      governorFilled: governor.total,
      governorExpected: meta.governorSeats,
      delegationResearched: senate.researched + house.researched + governor.researched,
      delegationTotal,
      delegationWithPhoto: senate.withPhoto + house.withPhoto + governor.withPhoto,
      stateLegCovered: stateleg.districtsCovered,
      stateLegTotal: d.sld,
    });

    out.set(meta.code, {
      code: meta.code,
      fips: meta.fips,
      name: meta.name,
      senate: {
        filled: senate.total,
        expected: meta.senateSeats,
        withPhoto: senate.withPhoto,
        researched: senate.researched,
      },
      house: {
        filled: house.total,
        districtsCovered: house.districtsCovered,
        expected: d.cd,
        withPhoto: house.withPhoto,
        researched: house.researched,
      },
      governor: { filled: governor.total, expected: meta.governorSeats },
      statewideExecs: statewide.total,
      stateLeg: {
        members: stateleg.total,
        districtsCovered: stateleg.districtsCovered,
        districtsTotal: d.sld,
        researched: stateleg.researched,
      },
      candidatesTracked: candidate.total,
      score,
    });
  }
  return out;
}

// ── Per-member delegation list (drill-down panel) ───────────────────────────

export interface FederalMember {
  politician_id: string;
  full_name: string;
  title: string | null;
  tier: FederalTier;
  district_ocd: string;
  has_photo: boolean;
  researched: boolean;
  has_donors: boolean;
  voting_powers: 'full' | 'committee_only' | 'non_voting';
  /** ADR 0003: REQUIRED whenever voting_powers ≠ 'full' — render it or don't render the seat. */
  representation_note: string | null;
}

const TIER_ORDER: Record<FederalTier, number> = {
  senate: 0, house: 1, governor: 2, statewide: 3, stateleg: 4, candidate: 5,
};

/**
 * Every federal/state-tier officeholder (and tracked candidate) for one state,
 * ordered senate → house → governor → statewide → legislature → candidates.
 */
export async function getFederalDelegation(stateCode: string): Promise<FederalMember[]> {
  const code = stateCode.toLowerCase();
  // The code is interpolated into a regex pattern (as a bind param, so no SQL
  // injection — but regex metacharacters would still change the match).
  if (!/^[a-z]{2}$/.test(code) || !ALL_STATES.some((s) => s.code === code)) return [];
  const { rows } = await pool.query<{
    politician_id: string;
    full_name: string;
    title: string | null;
    tier: FederalTier | null;
    district_ocd: string;
    has_photo: boolean;
    researched: boolean;
    has_donors: boolean;
    voting_powers: FederalMember['voting_powers'];
    representation_note: string | null;
  }>(
    `SELECT DISTINCT
       p.id AS politician_id,
       p.full_name,
       o.title,
       ${TIER_CASE_SQL} AS tier,
       d.ocd_id AS district_ocd,
       ${HAS_RENDERABLE_PHOTO_SQL} AS has_photo,
       (ans.politician_id IS NOT NULL) AS researched,
       ${HAS_ANY_CONTRIBUTION_SQL} AS has_donors,
       o.voting_powers,
       o.representation_note
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
       AND d.ocd_id ~ ('^ocd-division/country:us/state:' || $1 || '(/|$)')`,
    [code],
  );
  return rows
    .filter((r): r is typeof r & { tier: FederalTier } => r.tier != null)
    .map((r) => ({ ...r, title: r.title ?? null, representation_note: r.representation_note ?? null }))
    .sort(
      (a, b) =>
        TIER_ORDER[a.tier] - TIER_ORDER[b.tier] ||
        a.district_ocd.localeCompare(b.district_ocd, undefined, { numeric: true }) ||
        a.full_name.localeCompare(b.full_name),
    );
}
