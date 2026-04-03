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
  newValue: number;
  writeInTextChanged: boolean;
}

// ---------------------------------------------------------------------------
// getPoliticianJurisdiction
// ---------------------------------------------------------------------------

/**
 * Return the home_jurisdiction_geoid for a politician, or null if not set.
 *
 * Queries essentials.politicians — the canonical politician table post-Phase 35.
 */
export async function getPoliticianJurisdiction(
  politicianId: string
): Promise<string | null> {
  const { rows } = await pool.query<{ home_jurisdiction_geoid: string | null }>(
    `SELECT home_jurisdiction_geoid
     FROM essentials.politicians
     WHERE id = $1
     LIMIT 1`,
    [politicianId]
  );

  if (rows.length === 0) return null;
  return rows[0].home_jurisdiction_geoid ?? null;
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
 *   - non-null jurisdiction_geoid → politicians WHERE home_jurisdiction_geoid = geoid
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

  for (const grant of grants) {
    if (grant.slug === 'campaign_manager') {
      if (!grant.resource_id) continue;
      if (seen.has(grant.resource_id)) continue;

      const { rows } = await pool.query<{
        id: string;
        first_name: string | null;
        last_name: string | null;
        full_name: string | null;
        office_title: string;
        photo_url: string;
        home_jurisdiction_geoid: string | null;
      }>(
        `SELECT p.id, p.first_name, p.last_name, p.full_name,
                COALESCE(o.title, '') AS office_title,
                COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_url,
                p.home_jurisdiction_geoid
         FROM essentials.politicians p
         LEFT JOIN essentials.offices o ON o.politician_id = p.id
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

    if (grant.slug === 'compass_stance_editor') {
      if (grant.jurisdiction_geoid === null) {
        // Unrestricted — return ALL active politicians
        const { rows } = await pool.query<{
          id: string;
          first_name: string | null;
          last_name: string | null;
          full_name: string | null;
          office_title: string;
          photo_url: string;
          home_jurisdiction_geoid: string | null;
        }>(
          `SELECT DISTINCT ON (p.id)
                  p.id, p.first_name, p.last_name, p.full_name,
                  COALESCE(o.title, '') AS office_title,
                  COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_url,
                  p.home_jurisdiction_geoid
           FROM essentials.politicians p
           LEFT JOIN essentials.offices o ON o.politician_id = p.id
           LEFT JOIN LATERAL (
             SELECT url FROM essentials.politician_images
             WHERE politician_id = p.id AND type = 'default' LIMIT 1
           ) pi ON true
           WHERE p.is_active = true
           ORDER BY p.id`
        );

        for (const row of rows) {
          if (!seen.has(row.id)) {
            seen.add(row.id);
            result.push(row);
          }
        }
      } else {
        // Scoped to jurisdiction
        const { rows } = await pool.query<{
          id: string;
          first_name: string | null;
          last_name: string | null;
          full_name: string | null;
          office_title: string;
          photo_url: string;
          home_jurisdiction_geoid: string | null;
        }>(
          `SELECT DISTINCT ON (p.id)
                  p.id, p.first_name, p.last_name, p.full_name,
                  COALESCE(o.title, '') AS office_title,
                  COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_url,
                  p.home_jurisdiction_geoid
           FROM essentials.politicians p
           LEFT JOIN essentials.offices o ON o.politician_id = p.id
           LEFT JOIN LATERAL (
             SELECT url FROM essentials.politician_images
             WHERE politician_id = p.id AND type = 'default' LIMIT 1
           ) pi ON true
           WHERE p.is_active = true AND p.home_jurisdiction_geoid = $1
           ORDER BY p.id`,
          [grant.jurisdiction_geoid]
        );

        for (const row of rows) {
          if (!seen.has(row.id)) {
            seen.add(row.id);
            result.push(row);
          }
        }
      }
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
