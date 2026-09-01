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
 *
 * 🔴 A point that resolves to NOTHING is not a district change — see UNRESOLVED below.
 */

import { adminRpc } from './supabase.js';
import { pool } from './db.js';
import {
  GEO_FIELDS,
  resolvedDistrictCount,
  droppedDistricts,
} from './jurisdictionPayload.js';

export interface DistrictStalenessResult {
  total: number;
  updated: number;
  unchanged: number;
  /** The RPC succeeded but placed the point in no district at all. Nothing was written. */
  unresolved: number;
  failed: number;
  durationMs: number;
}

// ---------------------------------------------------------------------------
// runDistrictStalenessCheck
// ---------------------------------------------------------------------------

export async function runDistrictStalenessCheck(): Promise<DistrictStalenessResult> {
  const jobStart = Date.now();
  let updated = 0;
  let unchanged = 0;
  let unresolved = 0;
  let failed = 0;

  // Fetch all connected profiles with stored coordinates
  const { rows: users } = await pool.query<{
    user_id: string;
    congressional_geo_id: string | null;
    state_senate_geo_id: string | null;
    state_house_geo_id: string | null;
    county_geo_id: string | null;
    school_district_geo_id: string | null;
    city_geo_id: string | null;
    state_geo_id: string | null;
    nation_geo_id: string | null;
  }>(
    `SELECT user_id, congressional_geo_id, state_senate_geo_id, state_house_geo_id,
            county_geo_id, school_district_geo_id,
            city_geo_id, state_geo_id, nation_geo_id
     FROM connect.connected_profiles
     WHERE encrypted_lat IS NOT NULL
       -- A weekly cron over every row, with no request and therefore no
       -- requireAuth in front of it. Re-resolving jurisdictions for deleted
       -- accounts writes location data back onto a record the user asked us to
       -- delete, and bills the geocoder for it.
       AND deleted_at IS NULL`
  );

  const total = users.length;

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

      // ---------------------------------------------------------------------
      // UNRESOLVED — the guard. Read this before removing it.
      // ---------------------------------------------------------------------
      // resolve_user_jurisdiction builds its payload with aggregates and no GROUP BY,
      // so it returns exactly ONE row even when zero boundaries cover the point: every
      // key NULL, and NO error raised. adminRpc can also hand back `data: null`.
      //
      // Both used to fall through to `?? {}` and read as "all five districts changed to
      // NULL". The job then wrote NULL over all five geo_ids AND their names, and stamped
      // districts_last_verified_at — so a wiped profile looked freshly verified. The
      // trigger is any change that breaks the geo_id / mtfcc / district_type join in the
      // RPC, and essentials.districts has no inbound FKs to make such a change loud.
      //
      // A point in no district is a fact we cannot act on, not a district change. Report
      // it and leave the stored values alone. Removing a district must be a deliberate
      // human action, never a side effect of this job.
      const resolvedCount = resolvedDistrictCount(jData);

      if (resolvedCount === 0) {
        console.warn(
          `[cron/district-staleness] UNRESOLVED — resolve_user_jurisdiction placed user ` +
            `${user.user_id} in no district at all. Stored districts left untouched and ` +
            `districts_last_verified_at NOT stamped.`
        );
        unresolved++;
        continue;
      }

      // A partial drop IS real signal — redistricting can genuinely remove one seat — so
      // it is still written. But it is also the shape a half-broken join takes, so name
      // the dropped fields rather than letting them disappear quietly.
      const dropped = droppedDistricts(user, jData);

      if (dropped.length > 0) {
        console.warn(
          `[cron/district-staleness] partial drop for user ${user.user_id}: ` +
            `${dropped.join(', ')} resolved to NULL while ${resolvedCount} of ` +
            `${GEO_FIELDS.length} still resolved. Writing the removal.`
        );
      }

      // Compare the 5 geo_id fields returned by the RPC against stored values.
      // RPC returns keys without _geo_id suffix: congressional, state_senate, etc.
      const geoChanged =
        (jData.congressional ?? null) !== user.congressional_geo_id ||
        (jData.state_senate ?? null) !== user.state_senate_geo_id ||
        (jData.state_house ?? null) !== user.state_house_geo_id ||
        (jData.county ?? null) !== user.county_geo_id ||
        (jData.school_district ?? null) !== user.school_district_geo_id;

      // Place geoids move for reasons districts do not — annexation puts a point inside
      // city limits without touching a single district line — so they need their own
      // comparison. They are still gated by the resolvedCount check above: this only
      // runs when the districts join proved itself healthy, which is what makes a null
      // city here trustworthy enough to write.
      // Both sides are normalised: a column absent from the row reads as undefined,
      // and `undefined !== null` would report every profile as changed forever.
      const placeChanged =
        (jData.city ?? null) !== (user.city_geo_id ?? null) ||
        (jData.state ?? null) !== (user.state_geo_id ?? null) ||
        (jData.nation ?? null) !== (user.nation_geo_id ?? null);

      if (geoChanged || placeChanged) {
        // Update all geo_id + name columns AND stamp the verified timestamp.
        // Does NOT touch jurisdiction_state or jurisdiction_city — those come
        // from geocoding (set-location), not from jurisdiction resolution. The
        // *_geo_id columns below are the resolved Census FIPS and are a different
        // thing from that geocoded pair despite the similar names.
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
               city_geo_id = $12,
               state_geo_id = $13,
               nation_geo_id = $14,
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
            jData.city ?? null,
            jData.state ?? null,
            jData.nation ?? null,
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
      users_unresolved: unresolved,
      users_failed: failed,
      duration_ms: Date.now() - jobStart,
    })
  );

  return {
    total,
    updated,
    unchanged,
    unresolved,
    failed,
    durationMs: Date.now() - jobStart,
  };
}
