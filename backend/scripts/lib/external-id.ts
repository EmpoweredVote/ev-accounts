// Phase 133 / D-07 — deterministic external_id with idempotent-by-identity assignment.
// Range: -300001..-399999 (99,999 slots).
// Seed includes ':ut-v1' discriminator so future regenerations don't collide with current.
//
// IDEMPOTENT contract (D-08):
//   Re-running a loader with the same (dataSource, fullName) MUST return the
//   same external_id so ON CONFLICT (external_id) DO UPDATE upserts in place.
//
// COLLISION-SAFE contract:
//   When the candidate slot is already occupied by a DIFFERENT politician
//   (different dataSource/fullName), walk down to the next free slot rather
//   than silently overwrite.
//
// Algorithm:
//   1. If (dataSource, fullName) already has an external_id in range → reuse it.
//   2. Compute candidate hash. If unoccupied → use it.
//   3. If occupied by SAME (dataSource, fullName) → reuse the candidate.
//   4. Otherwise (occupied by different politician) → walk down to next free.
import crypto from 'node:crypto';
import type { Pool } from 'pg';

const SEED = ':ut-v1';
const BASE = -300001;
const SLOT_COUNT = 99999;

export function computeExternalId(geoId: string, role: string): number {
  const h = crypto.createHash('sha1').update(`${geoId}:${role}${SEED}`).digest();
  const u32 = h.readUInt32BE(0);
  return BASE - (u32 % SLOT_COUNT);
}

export async function assignExternalId(
  pool: Pool,
  geoId: string,
  role: string,
  identity?: { dataSource: string; fullName: string },
): Promise<{ external_id: number; collided: boolean }> {
  // Step 1: reuse if already imported under same identity.
  if (identity) {
    const { rows } = await pool.query<{ external_id: number }>(
      `SELECT external_id FROM essentials.politicians
        WHERE data_source = $1 AND full_name = $2
          AND external_id BETWEEN -399999 AND -300001
        LIMIT 1`,
      [identity.dataSource, identity.fullName],
    );
    if (rows.length > 0) {
      return { external_id: rows[0].external_id, collided: false };
    }
  }

  const candidate = computeExternalId(geoId, role);

  // Step 2-3: check candidate slot.
  const { rows: existing } = await pool.query<{ data_source: string | null; full_name: string | null }>(
    `SELECT data_source, full_name FROM essentials.politicians WHERE external_id = $1`,
    [candidate],
  );
  if (existing.length === 0) {
    return { external_id: candidate, collided: false };
  }
  // Same identity at candidate? Use it.
  if (
    identity &&
    existing[0].data_source === identity.dataSource &&
    existing[0].full_name === identity.fullName
  ) {
    return { external_id: candidate, collided: false };
  }

  // Step 4: walk down to next free slot, logging the collision.
  let id = candidate;
  while (id >= -399999) {
    id--;
    const { rowCount } = await pool.query(
      `SELECT 1 FROM essentials.politicians WHERE external_id = $1`,
      [id],
    );
    if (rowCount === 0) {
      console.warn(
        `[ext-id] COLLISION ${candidate} taken by "${existing[0].full_name ?? '<null>'}" (${existing[0].data_source ?? '<null>'}) -> using ${id} for ${identity?.dataSource ?? geoId}/${identity?.fullName ?? role}`,
      );
      return { external_id: id, collided: true };
    }
  }
  throw new Error(
    `No free external_id slot in -300001..-399999 when assigning ${identity?.dataSource ?? geoId}/${identity?.fullName ?? role}`,
  );
}
