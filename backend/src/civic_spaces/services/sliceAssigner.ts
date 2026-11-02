import { pool } from '../config/database.js'
import { AccountData } from './accountsApi.js'
import { firstNonBlank, deterministicAutoName } from '../../lib/displayName.js'

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

/** One row of `slices` as the placement query returns it. */
export type OpenSliceCandidate = {
  id: string
  sibling_index: number
  current_member_count: number
}

/**
 * Which slice a new member joins, given every slice a jurisdiction has (design §4.3).
 *
 * 🔴 AT MOST TWO SLICES ARE OPEN: the newest and the second-newest. Everything older is
 * CLOSED — it keeps its members and its conversation and takes no new arrivals. Closed is
 * not a state a slice is put into; it is the absence of candidacy, and it falls out of this
 * one comparison. A stored `is_closed` column would be a second source of truth that has to
 * be written at every split, can disagree with sibling_index, and would need backfilling for
 * every slice that already exists. There is nothing here for it to drift from.
 *
 * 🔴 WITHIN the open pair the order is still ASCENDING, and that is not an oversight left
 * over from the old query. Lowest-first across the two open slices IS "fill the second-newest
 * first": the newest stays mostly empty until its neighbour is full, so there is always a
 * room with space in it when the frontier divides. Sorting DESC instead would fill the newest
 * and starve the second-newest, which is the design exactly inverted.
 *
 * 🔴 PURE, and deliberately not a WHERE clause. This was SQL until Phase 19-01. A mocked
 * pool.query cannot test a WHERE clause — it returns whatever the test handed it — so the
 * placement rule was the one rule in this module with no way to prove it. It is the rule
 * Task 4 exists to make single; it has to be somewhere a test can reach.
 *
 * Returns null when both open slices are full. That is not a failure: it means the frontier
 * must divide before anyone else can be placed, which is the caller's job, not this one's.
 */
export function chooseOpenSlice(slices: OpenSliceCandidate[]): string | null {
  if (slices.length === 0) return null

  const newest = Math.max(...slices.map((s) => s.sibling_index))

  return (
    slices
      .filter((s) => s.sibling_index >= newest - 1)
      .filter((s) => s.current_member_count < SLICE_CAPACITY)
      .sort((a, b) => a.sibling_index - b.sibling_index)[0]?.id ?? null
  )
}

/**
 * The open slice a member should join, or null if both open slices are full.
 *
 * Exported for the test suite. Null is an answer, not an error — see chooseOpenSlice.
 */
export async function findActiveSliceForGeoid(
  sliceType: string,
  geoid: string
): Promise<string | null> {
  // 🔴 Every slice, unfiltered. The window is "the two highest sibling_index values", and
  // that cannot be computed from a set already filtered by current_member_count: the newest
  // slice is usually the full one, and dropping it first slides the window down onto two
  // closed slices without anything looking wrong.
  const { rows: slices } = await pool.query<OpenSliceCandidate>(
    `SELECT id, sibling_index, current_member_count FROM slices
      WHERE slice_type = $1 AND geoid = $2
      ORDER BY sibling_index ASC`,
    [sliceType, geoid]
  )

  if (slices.length === 0) {
    // No slice exists at all — create the initial one.
    try {
      const { rows } = await pool.query<{ id: string }>(
        `INSERT INTO slices (slice_type, geoid, sibling_index)
         VALUES ($1, $2, $3)
         RETURNING id`,
        [sliceType, geoid, 1]
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

  return chooseOpenSlice(slices)
}

/**
 * Opens the next slice for a jurisdiction whose open pair is full, and answers where the
 * member should go once it is open.
 *
 * 🔴 SPLIT, DO NOT CREATE. Until Phase 19-01 this path inserted an empty sibling: a room
 * with six thousand neighbours next door and nobody in it, no conversation, nothing to join.
 * civic_spaces.split_slice moves the most recently joined half of the frontier across and
 * seeds the new slice with a forked window of the parent's threads, so the people who arrive
 * next walk into a town that is already talking.
 *
 * 🔴 THE ENGINE CANNOT DO THE COPY ITSELF, and that is the point of the function existing.
 * This pool connects as `civic_spaces_app`, which holds DML on slices, slice_members and
 * connected_profiles and NOTHING ELSE — it cannot read a post, let alone duplicate one (see
 * config/database.ts, migration CA_0112). Widening the role to make the seed possible would
 * cross a stated privacy boundary for implementation convenience and permanently enlarge what
 * a compromised accounts service can read. So the engine decides a split should happen, and
 * one EXECUTE grant lets it ask.
 *
 * 🔴 It splits THE FRONTIER, not the slice that happened to be full. Only the newest slice
 * divides (design §4.4): a full slice with a newer sibling beside it simply closes, because a
 * split exists to open the NEXT room and that room is already open. Passing the caller's full
 * slice id straight through would ask a closed slice to divide, which split_slice refuses.
 */
async function openNextSliceForGeoid(sliceType: string, geoid: string): Promise<string> {
  // 🔴 Asked, not assumed. The five splittable types are listed in SQL
  // (civic_spaces.is_splittable_slice_type) and in civic-spaces' writeAccess.ts, pinned
  // against each other by check:write-access. A third copy here would be pinned to nothing,
  // and a drifted copy routes a split down the wrong branch in silence. One round trip on a
  // path that fires once per 6000 members buys a single source of truth.
  const { rows: splittable } = await pool.query<{ splittable: boolean }>(
    `SELECT civic_spaces.is_splittable_slice_type($1) AS splittable`,
    [sliceType]
  )

  if (!splittable[0]?.splittable) {
    // `volunteer` is a role, not a place, so it does not divide. The pre-split overflow is
    // still the right answer there: a plain sibling, which fills from empty. Dormant — a
    // volunteer slice reaching 6000 is not expected — but reachable on purpose.
    return findOrCreateSiblingSlice(sliceType, geoid)
  }

  const { rows: frontier } = await pool.query<{ id: string }>(
    `SELECT id FROM slices
      WHERE slice_type = $1 AND geoid = $2
      ORDER BY sibling_index DESC
      LIMIT 1`,
    [sliceType, geoid]
  )
  if (!frontier[0]) throw new Error(`No slice to split for ${sliceType}/${geoid}`)

  try {
    // 🔴 ONCE, INTO A RESULT. split_slice is VOLATILE and it MUTATES, so a call placed in a
    // WHERE clause or a join condition is evaluated per row and divides the jurisdiction
    // repeatedly. That happened while the rehearsal was being written, and the second call's
    // refusal masked it — a function without the frontier guard would have split twice in
    // silence. A bare SELECT is the contract.
    await pool.query(`SELECT civic_spaces.split_slice($1)`, [frontier[0].id])
  } catch (err) {
    // P0001 is split_slice refusing: another request split this jurisdiction first, so the
    // row read above is no longer the frontier. Not an error — the room we wanted opened is
    // open. Any other code is a real failure and is rethrown.
    if (pgErrorCode(err) !== 'P0001') throw err
  }

  // 🔴 Re-place rather than taking split_slice's return value. It returns the NEW slice, and
  // that is not where this member goes: after a split the parent is the SECOND-newest, and
  // the second-newest fills first (§4.3) so the newest keeps its room for the arrivals after.
  // Seating the member in the returned slice would fill the newest first — the design exactly
  // inverted, and invisible, because the answer is still a real slice in the right place.
  const placed = await findActiveSliceForGeoid(sliceType, geoid)
  if (!placed) throw new Error(`No slice open after splitting ${sliceType}/${geoid}`)
  return placed
}

/**
 * Where to put a member: the open slice if there is one, otherwise whatever opening the next
 * one takes.
 *
 * 🔴 findActiveSliceForGeoid no longer opens anything itself; it answers "nowhere open" and
 * openNextSliceForGeoid splits the frontier, which carries people and a conversation across
 * instead of leaving a new room empty.
 */
async function findOrOpenSliceForGeoid(sliceType: string, geoid: string): Promise<string> {
  const open = await findActiveSliceForGeoid(sliceType, geoid)
  if (open) return open

  return openNextSliceForGeoid(sliceType, geoid)
}

export async function upsertSliceMember(userId: string, sliceId: string, retries = 3): Promise<void> {
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
    // between placement and this insert. Re-place, splitting the frontier if nothing is open,
    // and retry. The three-attempt ceiling is what stops a jurisdiction that refuses every
    // insert from dividing once per attempt.
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
      // 🔴 Re-place BEFORE splitting. A member seated in a closed slice by the admin
      // override can hit slice_full there while the open pair is half empty — splitting the
      // frontier then would divide a jurisdiction that had plenty of room, on the strength of
      // a cap reached somewhere else entirely. findOrOpenSliceForGeoid asks placement first
      // and only opens the next slice when there is genuinely nowhere to put anyone.
      const nextId = await findOrOpenSliceForGeoid(rows[0].slice_type, rows[0].geoid)
      return upsertSliceMember(userId, nextId, retries - 1)
    }
    throw err
  }
}

async function upsertConnectedProfile(
  userId: string,
  displayName: string,
  accountStanding: string
): Promise<void> {
  // Second guard behind getAccountMe (watchlist #70): the target column is NOT NULL, so a
  // blank must never reach it even if a caller passes one. getAccountMe already guarantees a
  // non-blank name; this keeps upsertConnectedProfile safe on its own too.
  const safeName = firstNonBlank(displayName) ?? deterministicAutoName(userId)
  // updated_at is maintained by the trg_connected_profiles_updated_at BEFORE UPDATE trigger,
  // so it is deliberately not set here (matches the standalone's supabase upsert).
  await pool.query(
    `INSERT INTO connected_profiles (user_id, display_name, account_standing)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE
       SET display_name = EXCLUDED.display_name,
           account_standing = EXCLUDED.account_standing`,
    [userId, safeName, accountStanding]
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
    const sliceId = await findOrOpenSliceForGeoid(sliceType, geoid)
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

  const sliceId = await findOrOpenSliceForGeoid('unified', UNIFIED_GEOID)
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

  const sliceId = await findOrOpenSliceForGeoid('volunteer', VOLUNTEER_GEOID)
  await upsertSliceMember(userId, sliceId)
  return sliceId
}

export { upsertConnectedProfile }
