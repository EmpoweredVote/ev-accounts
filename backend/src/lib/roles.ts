/**
 * FEATURE_SCOPES — single source of truth for role scope types.
 *
 * The same three values are hardcoded in the CHECK constraint on
 * public.user_roles.feature_scope (migration 047). Adding a new scope
 * requires editing this constant AND writing a new migration to ALTER
 * the CHECK constraint.
 */
export const FEATURE_SCOPES = ['platform', 'jurisdiction', 'resource'] as const;
export type FeatureScope = typeof FEATURE_SCOPES[number];
