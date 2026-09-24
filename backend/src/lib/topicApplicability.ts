/**
 * Which office levels a compass topic applies to, and which level an office sits at.
 *
 * One source of truth for the rule compassService applies at the API boundary and the
 * stance-research gate applies before a batch is written. CLAUDE.md: "a ladder is only
 * valid at a level where its rungs are things an officeholder there can actually do."
 * Extracted from compassService.getCompassTopics with behaviour unchanged.
 *
 * `school` (CA_0256, rulings 2026-09-23 / 2026-09-24, Chris Andrews): K-12 school boards are
 * their own level, carrying only the topics with an explicit `school` role row — the eight
 * Education Lens topics. Per-rung review: .superpowers/sdd/2026-09-23-stance-program-
 * reconciliation/school-scope-proposal.md.
 */
export type Level = 'federal' | 'state' | 'local' | 'judicial' | 'school';

export interface TopicRoleRow { role_scope: string }

export interface TopicApplicability {
  applies_federal: boolean;
  applies_state: boolean;
  applies_local: boolean;
  applies_judicial: boolean;
  applies_school: boolean;
}

/**
 * A topic with no role rows is cross-cutting for federal/state/local — but NEVER judicial and
 * NEVER school. Both of those levels take only the topics that name them.
 */
export function appliesFromRoles(roles: TopicRoleRow[]): TopicApplicability {
  const has = roles.length > 0;
  const any = (scope: string) => roles.some((r) => r.role_scope === scope);
  return {
    applies_federal: has ? any('federal') : true,
    applies_state: has ? any('state') : true,
    applies_local: has ? any('local') : true,
    // CRITICAL: fallback is false — cross-cutting topics must not appear on judicial profiles.
    applies_judicial: has ? any('judicial') : false,
    // CRITICAL: fallback is false — a school board is asked only what the operator approved
    // rung by rung (ruling 2026-09-24). A new topic with no role rows must not reach it.
    applies_school: has ? any('school') : false,
  };
}

export function appliesToLevel(t: TopicApplicability, level: Level): boolean {
  if (level === 'federal') return t.applies_federal;
  if (level === 'state') return t.applies_state;
  if (level === 'local') return t.applies_local;
  if (level === 'school') return t.applies_school;
  return t.applies_judicial;
}

const LOCAL_TYPES = new Set(['COUNTY', 'LOCAL', 'LOCAL_EXEC', 'CITY', 'TOWNSHIP']);

/**
 * THE COMMUNITY-COLLEGE LABEL RULE — the one place it lives.
 *
 * The `school` level is K-12 only (ruling 2026-09-24). Community-college trustee boards also
 * carry district_type SCHOOL, and NO column tells them apart: subtype is null on all of them,
 * and mtfcc X0002 is shared with 265 K-12 offices (school-scope-proposal.md §5). Only the
 * district label does: all 70 held community-college offices (12 CA boards) have a label
 * matching this, and no K-12 label does (prod, 2026-09-24). Match on essentials.districts.label.
 */
export const COMMUNITY_COLLEGE_LABEL_RE = /\bcommunity college\b/i;

export function isCommunityCollegeBoard(districtLabel: string | null | undefined): boolean {
  return !!districtLabel && COMMUNITY_COLLEGE_LABEL_RE.test(districtLabel);
}

/**
 * THE MISFILED-SCHOOL-BOARD RULE — next to the community-college rule, for the same reason.
 *
 * Some K-12 boards sit on a city district (district_type LOCAL) instead of SCHOOL. On prod
 * (2026-09-24) that is 33 Maine offices, 9 held: Portland ("Board of Public Education"),
 * Augusta and Lewiston ("School Committee"), Westbrook ("School Board"). Left alone they would
 * read as `local` and be researched on city topics. So a local-typed district whose office
 * title or chamber name names a school board, school committee or board of education is level
 * UNKNOWN (null): a person must re-type the district to SCHOOL. The probe that set this matched
 * nothing else on COUNTY/LOCAL/LOCAL_EXEC/CITY/TOWNSHIP ("Trustee" alone is village, library or
 * township, and is deliberately not matched).
 */
export const SCHOOL_BOARD_OFFICE_RE = /\bschool (board|committee)\b|\bboard of (public )?education\b/i;

export function namesSchoolBoard(officeLabels: readonly (string | null | undefined)[]): boolean {
  return officeLabels.some((l) => !!l && SCHOOL_BOARD_OFFICE_RE.test(l));
}

/**
 * Office level from the office's district. null for an unseen type — never a guess.
 *
 * `districtLabel` is essentials.districts.label. It is needed only for SCHOOL, and it is
 * required there: a SCHOOL district with no label cannot be told apart from a community
 * college, so its level is null (unknown), not 'school'. A community-college board is null too:
 * it is outside every level's topic set, and the gate reports it as unknown rather than scoring it.
 *
 * `officeLabels` is the office title and the chamber name(s). It is read only for local-typed
 * districts: a school board filed on a LOCAL district is null, not 'local' (SCHOOL_BOARD_OFFICE_RE).
 */
export function levelForDistrict(
  districtType: string | null, isJudicial: boolean | null, districtLabel: string | null,
  officeLabels: readonly (string | null | undefined)[],
): Level | null {
  if (isJudicial || districtType === 'JUDICIAL') return 'judicial';
  if (!districtType) return null;
  if (districtType.startsWith('NATIONAL_')) return 'federal';
  // STATE_BOARD_EDUCATION stays here, at `state` (ruling 2026-09-24).
  if (districtType.startsWith('STATE_')) return 'state';
  if (districtType === 'SCHOOL') {
    if (!districtLabel || isCommunityCollegeBoard(districtLabel)) return null;
    return 'school';
  }
  if (LOCAL_TYPES.has(districtType)) return namesSchoolBoard(officeLabels) ? null : 'local';
  return null;
}
