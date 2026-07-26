/**
 * stanceService — jurisdiction resolution and stance audit helpers for
 * compass_stance_editor and campaign_manager contributors.
 *
 * WHY THIS FILE EXISTS:
 * Plans 02 and 03 (stance editor routes, campaign manager endpoints) need a
 * shared layer for:
 *   1. Looking up a politician's home jurisdiction from essentials.politicians
 *   2. Finding the matching role grant for a given politician + jurisdiction
 *   3. Listing the politicians a contributor is authorized to edit
 *   4. Writing stance audit log entries inside an open transaction
 *
 * All queries use pool.query() — essentials and inform schemas are not exposed
 * via PostgREST. This mirrors the pattern in compassService.ts.
 *
 * JURISDICTION SEMANTICS:
 * - NULL home_jurisdiction_geoid on a politician = unassigned jurisdiction.
 *   In Alpha we fail-open: any compass_stance_editor can edit (logged as warning).
 * - NULL jurisdiction_geoid on a grant = unrestricted — editor covers all jurisdictions.
 * - Exact string equality otherwise.
 *
 * AUDIT LOG:
 * - action = 'stance_write', target_type = 'politician_answer'
 * - fields_changed: text[] of field names that changed (e.g. ['value', 'write_in_text'])
 * - snapshot_after: jsonb with { topic_id, old_value, new_value, write_in_text_changed }
 * - role_grant_id: the user_roles.id UUID of the matching grant row
 */

import { PoolClient } from 'pg';
import { pool } from './db.js';
import type { UserRoleGrant } from './roleService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ContributorPolitician {
  id: string;
  first_name: string | null;
  last_name: string | null;
  full_name: string | null;
  office_title: string;
  photo_url: string;
  home_jurisdiction_geoid: string | null;
}

export interface StanceAuditParams {
  actorId: string;
  targetUserId: string;
  roleGrantId: string;
  featureScope: string;
  jurisdictionGeoid: string | null;
  resourceId: string | null;
  topicId: string;
  oldValue: number | null;
  newValue: number | null;
  writeInTextChanged: boolean;
}

export interface EssentialsAuditParams {
  actorId: string;
  roleGrantId: string;
  featureScope: string;
  jurisdictionGeoid: string | null;
  resourceId: string | null;
  politicianId: string;
  fieldsChanged: string[];           // e.g. ['bio', 'preferred_name']
  changes: Record<string, { old: unknown; new: unknown }>;
}

// ---------------------------------------------------------------------------
// getDistrictGeoidForPolitician
// ---------------------------------------------------------------------------

/**
 * Return the geo_id of the district a politician holds office in, or null
 * if no office/district record is found.
 *
 * Uses the offices→districts join instead of reading home_jurisdiction_geoid
 * directly from essentials.politicians, which is NULL on all rows (never
 * backfilled). This is the canonical jurisdiction lookup for authorization.
 */
export async function getDistrictGeoidForPolitician(
  politicianId: string
): Promise<string | null> {
  const { rows } = await pool.query<{ geo_id: string }>(
    `SELECT d.geo_id
     FROM essentials.politicians p
     -- ADR 0002 phase 5: offices is a SEAT; occupancy lives in office_terms and resolves
     -- at query time via office_current_holder (exactly one row per office, so no fan-out).
     JOIN essentials.office_current_holder och ON och.politician_id = p.id
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE p.id = $1
     LIMIT 1`,
    [politicianId]
  );

  if (rows.length === 0) return null;
  return rows[0].geo_id ?? null;
}

// ---------------------------------------------------------------------------
// getPoliticianJurisdiction (thin wrapper — preserved for backward compat)
// ---------------------------------------------------------------------------

/**
 * Thin wrapper around getDistrictGeoidForPolitician.
 *
 * Existing callers in compassContributor.ts use this name. Delegates to the
 * new district-join helper so all jurisdiction lookups are consistent.
 *
 * @deprecated Prefer getDistrictGeoidForPolitician for new callers.
 */
export async function getPoliticianJurisdiction(
  politicianId: string
): Promise<string | null> {
  return getDistrictGeoidForPolitician(politicianId);
}

// ---------------------------------------------------------------------------
// getMatchingGrant
// ---------------------------------------------------------------------------

/**
 * Pure function — find the first grant that authorizes editing the given politician.
 *
 * campaign_manager: exact match on resource_id === politicianId
 * compass_stance_editor: jurisdiction match (NULL-safe, fail-open if politician
 *   has no home_jurisdiction_geoid assigned).
 *
 * Returns null if no grant matches.
 */
export function getMatchingGrant(
  grants: UserRoleGrant[],
  politicianId: string,
  politicianGeoid: string | null
): UserRoleGrant | null {
  for (const grant of grants) {
    if (grant.slug === 'campaign_manager') {
      if (grant.resource_id === politicianId) return grant;
      continue;
    }

    if (grant.slug === 'compass_stance_editor') {
      // Politician has no home jurisdiction assigned — fail-open for Alpha
      if (politicianGeoid === null) {
        console.warn(
          // TODO: remove fail-open once all politicians have home_jurisdiction_geoid assigned
          `[stanceService] getMatchingGrant: politician ${politicianId} has no home_jurisdiction_geoid — ` +
          `failing open for grant ${grant.id}`
        );
        return grant;
      }

      // Unrestricted grant — covers all jurisdictions
      if (grant.jurisdiction_geoid === null) return grant;

      // Exact jurisdiction match
      if (grant.jurisdiction_geoid === politicianGeoid) return grant;
      continue;
    }
  }

  return null;
}

// ---------------------------------------------------------------------------
// getContributorPoliticians
// ---------------------------------------------------------------------------

/**
 * Return the list of politicians a contributor is authorized to edit,
 * derived from their active role grants.
 *
 * campaign_manager grants: single politician matching grant.resource_id
 * compass_stance_editor grants:
 *   - null jurisdiction_geoid → ALL active politicians (unrestricted editor)
 *   - non-null jurisdiction_geoid → politicians whose office district matches geo_id
 *     (via offices→districts join; NOT home_jurisdiction_geoid which is unbackfilled)
 * essentials_data_editor grants: same jurisdiction logic as compass_stance_editor
 *
 * Uses pool.query() against essentials.politicians (same pattern as
 * getCompassPoliticians in compassService.ts). Deduplicates by politician ID
 * in case multiple grants overlap.
 */
export async function getContributorPoliticians(
  grants: UserRoleGrant[]
): Promise<ContributorPolitician[]> {
  const seen = new Set<string>();
  const result: ContributorPolitician[] = [];

  // ---------------------------------------------------------------------------
  // Shared query strings (reused by compass_stance_editor and essentials_data_editor)
  // ---------------------------------------------------------------------------

  // Returns ALL active politicians — used when jurisdiction_geoid is null (unrestricted)
  const UNRESTRICTED_SQL = `
    SELECT DISTINCT ON (p.id)
           p.id, p.first_name, p.last_name, p.full_name,
           COALESCE(o.title, '') AS office_title,
           COALESCE(p.photo_custom_url, CASE WHEN p.photo_origin_url LIKE 'http%' THEN p.photo_origin_url END, pi.url, '') AS photo_url,
           p.home_jurisdiction_geoid
    FROM essentials.politicians p
    -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = p.id AND type = 'default' LIMIT 1
    ) pi ON true
    WHERE p.is_active = true
    ORDER BY p.id`;

  // Returns politicians whose office district geo_id matches $1 — district-join scoped query
  const SCOPED_SQL = `
    SELECT DISTINCT ON (p.id)
           p.id, p.first_name, p.last_name, p.full_name,
           COALESCE(o.title, '') AS office_title,
           COALESCE(p.photo_custom_url, CASE WHEN p.photo_origin_url LIKE 'http%' THEN p.photo_origin_url END, pi.url, '') AS photo_url,
           p.home_jurisdiction_geoid
    FROM essentials.politicians p
    -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = p.id AND type = 'default' LIMIT 1
    ) pi ON true
    WHERE p.is_active = true AND d.geo_id = $1
    ORDER BY p.id`;

  type PoliticianRow = {
    id: string;
    first_name: string | null;
    last_name: string | null;
    full_name: string | null;
    office_title: string;
    photo_url: string;
    home_jurisdiction_geoid: string | null;
  };

  for (const grant of grants) {
    if (grant.slug === 'campaign_manager') {
      if (!grant.resource_id) continue;
      if (seen.has(grant.resource_id)) continue;

      const { rows } = await pool.query<PoliticianRow>(
        `SELECT p.id, p.first_name, p.last_name, p.full_name,
                COALESCE(o.title, '') AS office_title,
                COALESCE(p.photo_custom_url, CASE WHEN p.photo_origin_url LIKE 'http%' THEN p.photo_origin_url END, pi.url, '') AS photo_url,
                p.home_jurisdiction_geoid
         FROM essentials.politicians p
         -- ADR 0002 phase 5: occupancy resolves via office_current_holder.
         LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
         LEFT JOIN essentials.offices o ON o.id = och.office_id
         LEFT JOIN LATERAL (
           SELECT url FROM essentials.politician_images
           WHERE politician_id = p.id AND type = 'default' LIMIT 1
         ) pi ON true
         WHERE p.id = $1 AND p.is_active = true
         LIMIT 1`,
        [grant.resource_id]
      );

      for (const row of rows) {
        if (!seen.has(row.id)) {
          seen.add(row.id);
          result.push(row);
        }
      }
      continue;
    }

    if (
      grant.slug === 'compass_stance_editor' ||
      grant.slug === 'essentials_data_editor'
    ) {
      if (grant.jurisdiction_geoid === null) {
        // Unrestricted — return ALL active politicians
        const { rows } = await pool.query<PoliticianRow>(UNRESTRICTED_SQL);

        for (const row of rows) {
          if (!seen.has(row.id)) {
            seen.add(row.id);
            result.push(row);
          }
        }
      } else {
        // Scoped to district — join through offices→districts instead of home_jurisdiction_geoid
        const { rows } = await pool.query<PoliticianRow>(
          SCOPED_SQL,
          [grant.jurisdiction_geoid]
        );

        for (const row of rows) {
          if (!seen.has(row.id)) {
            seen.add(row.id);
            result.push(row);
          }
        }
      }
      continue;
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// writeStanceAuditLog
// ---------------------------------------------------------------------------

/**
 * Insert a stance_write audit log entry inside an open transaction.
 *
 * fields_changed: text[] of the field names that changed.
 *   Examples: ['value', 'write_in_text'], ['value'], ['write_in_text']
 *
 * snapshot_after: jsonb with structured change data.
 *   { topic_id, old_value, new_value, write_in_text_changed: boolean }
 *
 * role_grant_id: the user_roles.id UUID of the grant that authorized the write.
 *   This is matchingGrant.id (the grant row UUID), NOT matchingGrant.role_id
 *   (the roles definition UUID).
 *
 * Caller is responsible for BEGIN/COMMIT — this function only inserts.
 */
export async function writeStanceAuditLog(
  client: PoolClient,
  params: StanceAuditParams
): Promise<void> {
  const {
    actorId,
    targetUserId,
    roleGrantId,
    featureScope,
    jurisdictionGeoid,
    resourceId,
    topicId,
    oldValue,
    newValue,
    writeInTextChanged,
  } = params;

  const valueChanged = oldValue !== newValue;

  const fieldsChanged: string[] = [];
  if (valueChanged) fieldsChanged.push('value');
  if (writeInTextChanged) fieldsChanged.push('write_in_text');

  const snapshotAfter = {
    topic_id: topicId,
    old_value: oldValue,
    new_value: newValue,
    write_in_text_changed: writeInTextChanged,
  };

  await client.query(
    `INSERT INTO public.role_audit_log
       (actor_id, target_user_id, feature_scope, jurisdiction_geoid, resource_id,
        action, target_type, target_id, fields_changed, snapshot_after, role_grant_id)
     VALUES ($1, $2, $3, $4, $5, 'stance_write', 'politician_answer', $6, $7, $8, $9)`,
    [
      actorId,
      targetUserId,
      featureScope,
      jurisdictionGeoid,
      resourceId,
      topicId,
      fieldsChanged,
      JSON.stringify(snapshotAfter),
      roleGrantId,
    ]
  );
}

// ---------------------------------------------------------------------------
// getEditorMatchingGrant
// ---------------------------------------------------------------------------

/**
 * Pure function — find the first essentials_data_editor grant that authorizes
 * editing the given politician.
 *
 * JURISDICTION SEMANTICS (fail-CLOSED — intentionally different from getMatchingGrant):
 * - grant.jurisdiction_geoid === null → unrestricted, return grant (global access)
 * - politicianGeoid === null → fail-CLOSED (cannot authorize if politician has no
 *   assigned jurisdiction). No console.warn — this is a hard security boundary.
 * - grant.jurisdiction_geoid === politicianGeoid → exact match, return grant
 * - Otherwise continue to next grant.
 *
 * Returns null if no grant matches.
 */
export function getEditorMatchingGrant(
  grants: UserRoleGrant[],
  politicianGeoid: string | null
): UserRoleGrant | null {
  for (const grant of grants) {
    if (grant.slug !== 'essentials_data_editor') continue;

    // Unrestricted grant — covers all jurisdictions
    if (grant.jurisdiction_geoid === null) return grant;

    // Politician has no home jurisdiction — fail-CLOSED (unlike compass_stance_editor fail-open)
    if (politicianGeoid === null) continue;

    // Exact jurisdiction match
    if (grant.jurisdiction_geoid === politicianGeoid) return grant;
  }

  return null;
}

// ---------------------------------------------------------------------------
// writeEssentialsAuditLog
// ---------------------------------------------------------------------------

/**
 * Insert a bio_edit audit log entry inside an open transaction.
 *
 * Intentionally separate from writeStanceAuditLog — the audit shape differs:
 * arbitrary bio field diffs vs topic value changes.
 *
 * action = 'bio_edit', target_type = 'politician'
 * actor_id = target_user_id = actorId (editor is the actor, no separate target user)
 * snapshot_after = JSON of changes map: { field: { old, new }, ... }
 * role_grant_id = the user_roles.id UUID of the matching grant row
 *
 * Caller is responsible for BEGIN/COMMIT — this function only inserts.
 */
export async function writeEssentialsAuditLog(
  client: PoolClient,
  params: EssentialsAuditParams
): Promise<void> {
  const {
    actorId,
    roleGrantId,
    featureScope,
    jurisdictionGeoid,
    resourceId,
    politicianId,
    fieldsChanged,
    changes,
  } = params;

  await client.query(
    `INSERT INTO public.role_audit_log
       (actor_id, target_user_id, feature_scope, jurisdiction_geoid, resource_id,
        action, target_type, target_id, fields_changed, snapshot_after, role_grant_id)
     VALUES ($1, $2, $3, $4, $5, 'bio_edit', 'politician', $6, $7, $8, $9)`,
    [
      actorId,
      actorId,          // target_user_id = actorId (editor is the actor)
      featureScope,
      jurisdictionGeoid,
      resourceId,
      politicianId,
      fieldsChanged,
      JSON.stringify(changes),
      roleGrantId,
    ]
  );
}
