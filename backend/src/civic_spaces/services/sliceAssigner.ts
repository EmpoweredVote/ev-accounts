import { pool } from '../config/database.js'
import { AccountData } from './accountsApi.js'

// Data layer for slice assignment. Folded from civic-spaces services/slice-assignment
// (ev-cto decision 0018). The standalone reached the DB through @supabase/supabase-js and a
// broad per-service key; this runs the same operations as parametric SQL through a dedicated
// least-privilege pool (config/database.ts, role civic_spaces_app) so the module cannot touch
// identity or any schema but civic_spaces (PRIVACY-ARCHITECTURE property A).
//
// The behaviour is deliberately unchanged. Every recorded-bug fix the standalone carried is
// preserved here: the geoid-not-district mapping, the null-geoid skip, the slice_full retry,
// the 23505 race re-query, and the volunteer removal path.

const UNIFIED_GEOID = 'UNIFIED'
const VOLUNTEER_GEOID = 'VOLUNTEER'

/** Postgres error code, if this is a pg error. */
function pgErrorCode(err: unknown): string | undefined {
  if (err && typeof err === 'object' && 'code' in err) {
    const code = (err as { code?: unknown }).code
    return typeof code === 'string' ? code : undefined
  }
  return undefined
}

function pgErrorMessage(err: unknown): string {
  return err instanceof Error ? err.message : String(err)
}

/**
 * A slice is a government a member lives under, not a constituency they vote in.
 *
 * Congressional and legislative districts are deliberately absent. They still decide
 * WHICH representative a member sees — that filtering lives in the frontend's
 * TAB_DISTRICT_TYPES — but they no longer fragment the conversation. Keying `federal`
 * on a congressional district meant two neighbours on opposite sides of a district line
 * could not talk to each other about the country they both live in.
 *
 * Exported for the test suite. The defect above was invisible for as long as it was
 * partly because this table had nothing asserting anything about it.
 *
 * See civic-spaces .planning/research/SLICE-TAXONOMY.md.
 */
export const SLICE_ASSIGNMENTS: Array<{
  sliceType: string
  geoid: (j: NonNullable<AccountData['jurisdiction']>) => string | null
}> = [
  { sliceType: 'city', geoid: (j) => j.city_geoid },
  { sliceType: 'county', geoid: (j) => j.county },
  { sliceType: 'state', geoid: (j) => j.state_geoid },
  { sliceType: 'federal', geoid: (j) => j.nation_geoid },
]

/**
 * Members per slice. A member's five spaces — unified, federal, state, county, city —
 * sum to ~30,000, which is the human-scale figure the feature spec argues for; it is
 * the size of a member's whole civic world, not of one room.
 *
 * MUST equal the threshold in civic_spaces.enforce_slice_cap(), verified 2026-09-12 as
 * `IF v_count >= 6000`. If this is higher, the service hands out a slice whose insert the
 * database then rejects with `slice_full` — recoverable, but only via the retry path in
 * upsertSliceMember, and only three times.
 */
export const SLICE_CAPACITY = 6000

async function findOrCreateSiblingSlice(sliceType: string, geoid: string): Promise<string> {
  // Find max sibling_index for this (geoid, slice_type)
  const { rows: existing } = await pool.query<{ sibling_index: number }>(
    `SELECT sibling_index FROM slices
      WHERE slice_type = $1 AND geoid = $2
      ORDER BY sibling_index DESC
      LIMIT 1`,
    [sliceType, geoid]
  )

  const maxSiblingIndex = existing.length > 0 ? existing[0].sibling_index : 0
  const newSiblingIndex = maxSiblingIndex + 1

  try {
    const { rows } = await pool.query<{ id: string }>(
      `INSERT INTO slices (slice_type, geoid, sibling_index)
       VALUES ($1, $2, $3)
       RETURNING id`,
      [sliceType, geoid, newSiblingIndex]
    )
    if (!rows[0]) throw new Error('Slice insert returned no data')
    return rows[0].id
  } catch (err) {
    // On unique conflict (race condition), re-query and return the existing sibling
    if (pgErrorCode(err) === '23505') {
      const { rows } = await pool.query<{ id: string }>(
        `SELECT id FROM slices
          WHERE slice_type = $1 AND geoid = $2 AND sibling_index = $3`,
        [sliceType, geoid, newSiblingIndex]
      )
      if (!rows[0]) throw new Error('Race condition re-query returned no result', { cause: err })
      return rows[0].id
    }
    throw err
  }
}

async function findActiveSliceForGeoid(sliceType: string, geoid: string): Promise<string> {
  const { rows: available } = await pool.query<{ id: string }>(
    `SELECT id FROM slices
      WHERE slice_type = $1 AND geoid = $2 AND current_member_count < $3
      ORDER BY sibling_index ASC
      LIMIT 1`,
    [sliceType, geoid, SLICE_CAPACITY]
  )

  if (available[0]) return available[0].id

  // No available slice — check if any slice exists at all
  const { rows: anySlice } = await pool.query<{ id: string }>(
    `SELECT id FROM slices WHERE slice_type = $1 AND geoid = $2 LIMIT 1`,
    [sliceType, geoid]
  )

  if (anySlice.length === 0) {
    // No slice exists at all — create the initial one
    try {
      const { rows } = await pool.query<{ id: string }>(
        `INSERT INTO slices (slice_type, geoid, sibling_index)
         VALUES ($1, $2, 1)
         RETURNING id`,
        [sliceType, geoid]
      )
      if (!rows[0]) throw new Error('Initial slice insert returned no data')
      return rows[0].id
    } catch (err) {
      // Race condition on initial creation
      if (pgErrorCode(err) === '23505') {
        const { rows } = await pool.query<{ id: string }>(
          `SELECT id FROM slices
            WHERE slice_type = $1 AND geoid = $2 AND sibling_index = 1`,
          [sliceType, geoid]
        )
        if (!rows[0]) throw new Error('Initial race condition re-query returned no result', { cause: err })
        return rows[0].id
      }
      throw err
    }
  }

  // All slices are full — create a sibling
  return findOrCreateSiblingSlice(sliceType, geoid)
}

async function upsertSliceMember(userId: string, sliceId: string, retries = 3): Promise<void> {
  try {
    await pool.query(
      `INSERT INTO slice_members (user_id, slice_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, slice_id) DO NOTHING`,
      [userId, sliceId]
    )
  } catch (err) {
    const code = pgErrorCode(err)
    const msg = pgErrorMessage(err)
    // enforce_slice_cap() raises P0001 'slice_full: ...' when the target slice filled up
    // between findActiveSliceForGeoid and this insert. Find/create a sibling and retry.
    if (msg.includes('slice_full') || code === 'P0001') {
      if (retries <= 0) {
        throw new Error('Max retries exceeded for slice_full condition', { cause: err })
      }
      // Find the slice's type and geoid to locate/create a sibling
      const { rows } = await pool.query<{ slice_type: string; geoid: string }>(
        `SELECT slice_type, geoid FROM slices WHERE id = $1`,
        [sliceId]
      )
      if (!rows[0]) {
        throw new Error(`Failed to query slice for retry: ${msg}`, { cause: err })
      }
      const siblingId = await findOrCreateSiblingSlice(rows[0].slice_type, rows[0].geoid)
      return upsertSliceMember(userId, siblingId, retries - 1)
    }
    throw err
  }
}

async function upsertConnectedProfile(
  userId: string,
  displayName: string,
  accountStanding: string
): Promise<void> {
  // updated_at is maintained by the trg_connected_profiles_updated_at BEFORE UPDATE trigger,
  // so it is deliberately not set here (matches the standalone's supabase upsert).
  await pool.query(
    `INSERT INTO connected_profiles (user_id, display_name, account_standing)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE
       SET display_name = EXCLUDED.display_name,
           account_standing = EXCLUDED.account_standing`,
    [userId, displayName, accountStanding]
  )
}

async function removeStaleGeoMemberships(
  userId: string,
  sliceType: string,
  newGeoid: string
): Promise<void> {
  // Drop this user's memberships in slices of this type that key on a DIFFERENT geoid — the
  // member moved. decrement_slice_count fires automatically per deleted row.
  await pool.query(
    `DELETE FROM slice_members
      WHERE user_id = $1
        AND slice_id IN (
          SELECT id FROM slices WHERE slice_type = $2 AND geoid <> $3
        )`,
    [userId, sliceType, newGeoid]
  )
}

export async function assignUserToSlices(
  userId: string,
  jurisdiction: NonNullable<AccountData['jurisdiction']>
): Promise<{ assigned: string[]; skipped: string[] }> {
  const assigned: string[] = []
  const skipped: string[] = []

  for (const { sliceType, geoid: geoidFn } of SLICE_ASSIGNMENTS) {
    const geoid = geoidFn(jurisdiction)

    // A jurisdiction can legitimately lack a level. An unincorporated address has no
    // city: no G4110 place boundary covers Arden, NC, so `city` has no geoid. Three
    // of the ten production profiles are in that position.
    //
    // Without this guard that null reached findOrCreateSiblingSlice and violated
    // civic_spaces.slices.geoid NOT NULL, which threw and abandoned the request —
    // AFTER federal, state and county had already been written. The member ended up
    // with slices in the database and a 500 telling the client assignment failed.
    // Skip the level instead: living outside a city is not a broken account.
    if (!geoid) {
      skipped.push(sliceType)
      continue
    }

    await removeStaleGeoMemberships(userId, sliceType, geoid)
    const sliceId = await findActiveSliceForGeoid(sliceType, geoid)
    await upsertSliceMember(userId, sliceId)
    assigned.push(sliceId)
  }

  return { assigned, skipped }
}

async function isAlreadyAssignedToType(
  userId: string,
  sliceType: string,
  geoid: string
): Promise<string | null> {
  // Returns the existing slice_id if already assigned, or null
  const { rows } = await pool.query<{ slice_id: string }>(
    `SELECT sm.slice_id
       FROM slice_members sm
       JOIN slices s ON s.id = sm.slice_id
      WHERE sm.user_id = $1 AND s.slice_type = $2 AND s.geoid = $3
      LIMIT 1`,
    [userId, sliceType, geoid]
  )
  return rows[0] ? rows[0].slice_id : null
}

async function removeMembershipByType(
  userId: string,
  sliceType: string,
  geoid: string
): Promise<void> {
  // decrement_slice_count fires automatically on DELETE
  await pool.query(
    `DELETE FROM slice_members
      WHERE user_id = $1
        AND slice_id IN (
          SELECT id FROM slices WHERE slice_type = $2 AND geoid = $3
        )`,
    [userId, sliceType, geoid]
  )
}

export async function assignUnifiedIfNotAssigned(userId: string): Promise<string | null> {
  const existing = await isAlreadyAssignedToType(userId, 'unified', UNIFIED_GEOID)
  if (existing) return existing

  const sliceId = await findActiveSliceForGeoid('unified', UNIFIED_GEOID)
  await upsertSliceMember(userId, sliceId)
  return sliceId
}

export async function assignVolunteerIfEligible(
  userId: string,
  isVolunteer: boolean
): Promise<string | null> {
  if (!isVolunteer) {
    // Role revocation: remove from volunteer slice if previously assigned
    await removeMembershipByType(userId, 'volunteer', VOLUNTEER_GEOID)
    return null
  }

  // Assign if not already assigned (same check-before-insert pattern as unified)
  const existing = await isAlreadyAssignedToType(userId, 'volunteer', VOLUNTEER_GEOID)
  if (existing) return existing

  const sliceId = await findActiveSliceForGeoid('volunteer', VOLUNTEER_GEOID)
  await upsertSliceMember(userId, sliceId)
  return sliceId
}

export { upsertConnectedProfile }
