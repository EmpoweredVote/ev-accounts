/**
 * Which office levels a compass topic applies to, and which level an office sits at.
 *
 * One source of truth for the rule compassService applies at the API boundary and the
 * stance-research gate applies before a batch is written. CLAUDE.md: "a ladder is only
 * valid at a level where its rungs are things an officeholder there can actually do."
 * Extracted from compassService.getCompassTopics with behaviour unchanged.
 */
export type Level = 'federal' | 'state' | 'local' | 'judicial';

export interface TopicRoleRow { role_scope: string }

export interface TopicApplicability {
  applies_federal: boolean;
  applies_state: boolean;
  applies_local: boolean;
  applies_judicial: boolean;
}

/** A topic with no role rows is cross-cutting for federal/state/local — but NEVER judicial. */
export function appliesFromRoles(roles: TopicRoleRow[]): TopicApplicability {
  const has = roles.length > 0;
  const any = (scope: string) => roles.some((r) => r.role_scope === scope);
  return {
    applies_federal: has ? any('federal') : true,
    applies_state: has ? any('state') : true,
    applies_local: has ? any('local') : true,
    // CRITICAL: fallback is false — cross-cutting topics must not appear on judicial profiles.
    applies_judicial: has ? any('judicial') : false,
  };
}

export function appliesToLevel(t: TopicApplicability, level: Level): boolean {
  if (level === 'federal') return t.applies_federal;
  if (level === 'state') return t.applies_state;
  if (level === 'local') return t.applies_local;
  return t.applies_judicial;
}

const LOCAL_TYPES = new Set(['COUNTY', 'LOCAL', 'LOCAL_EXEC', 'SCHOOL', 'CITY', 'TOWNSHIP']);

/** Office level from the office's district. null for an unseen type — never a guess. */
export function levelForDistrict(districtType: string | null, isJudicial: boolean | null): Level | null {
  if (isJudicial || districtType === 'JUDICIAL') return 'judicial';
  if (!districtType) return null;
  if (districtType.startsWith('NATIONAL_')) return 'federal';
  if (districtType.startsWith('STATE_')) return 'state';
  if (LOCAL_TYPES.has(districtType)) return 'local';
  return null;
}
