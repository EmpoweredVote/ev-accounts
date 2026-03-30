/**
 * districtStalenessService — weekly district geo_id re-verification job.
 *
 * Queries all Connected users who have stored coordinates, re-resolves their
 * jurisdiction via the resolve_user_jurisdiction RPC, and updates geo_id columns
 * only when values have actually changed (no churn).
 *
 * Always stamps districts_last_verified_at on each processed row, whether or
 * not geo_ids changed, so we have a reliable audit trail.
 *
 * Purpose: District boundaries change over time (redistricting, annexations).
 * This ensures users' district assignments stay current without manual intervention.
 *
 * Per-user errors are non-fatal — failures are logged and counted but do not
 * abort the job or affect other users.
 */

import { adminRpc } from './supabase.js';
import { pool } from './db.js';

// ---------------------------------------------------------------------------
// runDistrictStalenessCheck
// ---------------------------------------------------------------------------

export async function runDistrictStalenessCheck(): Promise<void> {
  const jobStart = Date.now();
  let total = 0;
  let updated = 0;
  let unchanged = 0;
  let failed = 0;

  // Fetch all connected profiles with stored coordinates
  const { rows: users } = await pool.query<{
    user_id: string;
    congressional_geo_id: string | null;
    state_senate_geo_id: string | null;
    state_house_geo_id: string | null;
    county_geo_id: string | null;
    school_district_geo_id: string | null;
  }>(
    `SELECT user_id, congressional_geo_id, state_senate_geo_id, state_house_geo_id,
            county_geo_id, school_district_geo_id
     FROM connect.connected_profiles
     WHERE encrypted_lat IS NOT NULL`
  );

  total = users.length;

  for (const user of users) {
    try {
      const { data: jurisdictionData, error: jurisdictionError } = await adminRpc(
        'resolve_user_jurisdiction',
        { p_user_id: user.user_id },
        'connect'
      );

      if (jurisdictionError) {
        console.error(
          `[cron/district-staleness] resolve_user_jurisdiction failed for ${user.user_id}:`,
          jurisdictionError.message
        );
        failed++;
        continue;
      }

      const jData = (jurisdictionData ?? {}) as Record<string, string | null>;

      // Compare the 5 geo_id fields returned by the RPC against stored values.
      // RPC returns keys without _geo_id suffix: congressional, state_senate, etc.
      const geoChanged =
        (jData.congressional ?? null) !== user.congressional_geo_id ||
        (jData.state_senate ?? null) !== user.state_senate_geo_id ||
        (jData.state_house ?? null) !== user.state_house_geo_id ||
        (jData.county ?? null) !== user.county_geo_id ||
        (jData.school_district ?? null) !== user.school_district_geo_id;

      if (geoChanged) {
        // Update all geo_id + name columns AND stamp the verified timestamp.
        // Does NOT touch jurisdiction_state or jurisdiction_city — those come
        // from geocoding (set-location), not from jurisdiction resolution.
        await pool.query(
          `UPDATE connect.connected_profiles
           SET congressional_geo_id = $2,
               congressional_district_name = $3,
               state_senate_geo_id = $4,
               state_senate_district_name = $5,
               state_house_geo_id = $6,
               state_house_district_name = $7,
               county_geo_id = $8,
               county_name = $9,
               school_district_geo_id = $10,
               school_district_name = $11,
               districts_last_verified_at = now(),
               updated_at = now()
           WHERE user_id = $1`,
          [
            user.user_id,
            jData.congressional ?? null,
            jData.congressional_name ?? null,
            jData.state_senate ?? null,
            jData.state_senate_name ?? null,
            jData.state_house ?? null,
            jData.state_house_name ?? null,
            jData.county ?? null,
            jData.county_name ?? null,
            jData.school_district ?? null,
            jData.school_district_name ?? null,
          ]
        );
        updated++;
      } else {
        // No geo_ids changed — only stamp the verified timestamp (no column churn).
        await pool.query(
          `UPDATE connect.connected_profiles
           SET districts_last_verified_at = now()
           WHERE user_id = $1`,
          [user.user_id]
        );
        unchanged++;
      }
    } catch (err) {
      console.error(`[cron/district-staleness] Failed to process user ${user.user_id}:`, err);
      failed++;
    }
  }

  console.log(
    JSON.stringify({
      level: 'info',
      job: 'district-staleness',
      users_checked: total,
      users_updated: updated,
      users_unchanged: unchanged,
      users_failed: failed,
      duration_ms: Date.now() - jobStart,
    })
  );
}
