/**
 * stagingService — CRUD, review workflow, locking, and merge for staging entities.
 *
 * WHY THIS FILE EXISTS:
 * The staging schema is NOT in the PostgREST exposed schema list
 * (`public, connect, empower, inform, graphql_public, validation_quests`).
 * `supabaseAnon.schema('staging')` would fail at runtime.
 * ALL staging reads AND writes must use pool.query() (direct postgres).
 *
 * The essentials schema is also NOT in PostgREST — auto-promotion on approve
 * uses pool.query() for the essentials INSERT as well.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 *
 * Bigint note: The pg driver returns bigint columns as JavaScript strings.
 * Always call Number() on: review_count, total_years_in_office.
 * Use `value !== null ? Number(value) : null` for nullable bigints.
 *
 * JSONB note: The pg driver auto-parses JSONB columns into JS objects/arrays.
 * contacts, degrees, experiences, urls, images, addresses pass through as-is.
 */

import { pool } from './db.js';
import { UPSERT_ANSWER_SQL, assertWritten } from './seasonService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface StagingPolitician {
  id: string;
  externalId: string | null;
  fullName: string;
  party: string | null;
  office: string | null;
  officeLevel: string | null;
  state: string | null;
  district: string | null;
  status: string;
  addedBy: string;
  reviewedBy: string | null;
  mergedToId: string | null;
  bioText: string | null;
  photoUrl: string | null;
  contacts: any;
  degrees: any;
  experiences: any;
  urls: any;
  images: any;
  addresses: any;
  reviewCount: number;
  lastReviewedAt: string | null;
  lockedBy: string | null;
  lockedAt: string | null;
  approvedAt: string | null;
  validFrom: string | null;
  validTo: string | null;
  totalYearsInOffice: number | null;
  isAppointed: boolean;
  isVacant: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface PoliticianReviewLog {
  id: string;
  politicianId: string;
  reviewerName: string;
  action: string;
  comment: string | null;
  createdAt: string;
}

export interface CreatePoliticianInput {
  fullName: string;
  party?: string | null;
  office?: string | null;
  officeLevel?: string | null;
  state?: string | null;
  district?: string | null;
  bioText?: string | null;
  photoUrl?: string | null;
  externalId?: string | null;
  contacts?: any;
  degrees?: any;
  experiences?: any;
  urls?: any;
  images?: any;
  addresses?: any;
  validFrom?: string | null;
  validTo?: string | null;
  totalYearsInOffice?: number | null;
  isAppointed?: boolean;
  isVacant?: boolean;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/**
 * Look up a user's display_name from public.users.
 * Falls back to the raw userId string if the user has no display_name set.
 * NEVER trust display names from request body — always derive server-side.
 */
async function getDisplayName(userId: string): Promise<string> {
  const { rows } = await pool.query<{ display_name: string | null }>(
    `SELECT display_name FROM public.users WHERE id = $1`,
    [userId]
  );
  return rows[0]?.display_name ?? userId;
}

/**
 * Enforce the staging state machine — only 'pending' records can be mutated.
 * Throws a 422-shaped error for any other status.
 */
function assertPending(status: string): void {
  if (status !== 'pending') {
    const err = new Error(`Cannot modify a record with status '${status}'`) as any;
    err.httpStatus = 422;
    throw err;
  }
}

// ---------------------------------------------------------------------------
// Row mapper (explicit whitelist — NEVER spread DB rows)
// ---------------------------------------------------------------------------

function mapPoliticianRow(row: any): StagingPolitician {
  return {
    id: row.id,
    externalId: row.external_id,
    fullName: row.full_name,
    party: row.party,
    office: row.office,
    officeLevel: row.office_level,
    state: row.state,
    district: row.district,
    status: row.status,
    addedBy: row.added_by,
    reviewedBy: row.reviewed_by,
    mergedToId: row.merged_to_id,
    bioText: row.bio_text,
    photoUrl: row.photo_url,
    contacts: row.contacts,
    degrees: row.degrees,
    experiences: row.experiences,
    urls: row.urls,
    images: row.images,
    addresses: row.addresses,
    reviewCount: Number(row.review_count),
    lastReviewedAt: row.last_reviewed_at,
    lockedBy: row.locked_by,
    lockedAt: row.locked_at,
    approvedAt: row.approved_at,
    validFrom: row.valid_from,
    validTo: row.valid_to,
    totalYearsInOffice: row.total_years_in_office !== null ? Number(row.total_years_in_office) : null,
    isAppointed: row.is_appointed,
    isVacant: row.is_vacant,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// ---------------------------------------------------------------------------
// Politician CRUD
// ---------------------------------------------------------------------------

/**
 * List all staging politicians, optionally filtered by status.
 * Ordered by created_at DESC (newest first).
 */
export async function getPoliticians(
  filters?: { status?: string }
): Promise<StagingPolitician[]> {
  if (filters?.status) {
    const { rows } = await pool.query(
      `SELECT * FROM staging.politicians
       WHERE status = $1
       ORDER BY created_at DESC`,
      [filters.status]
    );
    return rows.map(mapPoliticianRow);
  }

  const { rows } = await pool.query(
    `SELECT * FROM staging.politicians
     ORDER BY created_at DESC`
  );
  return rows.map(mapPoliticianRow);
}

/**
 * Fetch a single staging politician by UUID.
 * Returns null if not found.
 */
export async function getPoliticianById(id: string): Promise<StagingPolitician | null> {
  const { rows } = await pool.query(
    `SELECT * FROM staging.politicians WHERE id = $1`,
    [id]
  );
  return rows.length > 0 ? mapPoliticianRow(rows[0]) : null;
}

/**
 * Submit a new politician for staging review.
 * Server-derives: added_by (from public.users display_name), status = 'pending'.
 * Client MUST NOT pass added_by — it is always resolved from the authenticated userId.
 */
export async function createPolitician(
  data: CreatePoliticianInput,
  userId: string
): Promise<StagingPolitician> {
  const addedBy = await getDisplayName(userId);

  const { rows } = await pool.query(
    `INSERT INTO staging.politicians
       (full_name, party, office, office_level, state, district, bio_text, photo_url,
        external_id, contacts, degrees, experiences, urls, images, addresses,
        valid_from, valid_to, total_years_in_office, is_appointed, is_vacant,
        added_by, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
             $16, $17, $18, $19, $20, $21, 'pending')
     RETURNING *`,
    [
      data.fullName,
      data.party ?? null,
      data.office ?? null,
      data.officeLevel ?? null,
      data.state ?? null,
      data.district ?? null,
      data.bioText ?? null,
      data.photoUrl ?? null,
      data.externalId ?? null,
      data.contacts ?? null,
      data.degrees ?? null,
      data.experiences ?? null,
      data.urls ?? null,
      data.images ?? null,
      data.addresses ?? null,
      data.validFrom ?? null,
      data.validTo ?? null,
      data.totalYearsInOffice ?? null,
      data.isAppointed ?? false,
      data.isVacant ?? false,
      addedBy,
    ]
  );

  return mapPoliticianRow(rows[0]);
}

/**
 * Update a pending staging politician.
 * Throws 422 if the record is not in 'pending' status.
 * Throws 404 if the record does not exist.
 * Builds a dynamic parameterized SET clause — never uses string interpolation.
 */
export async function updatePolitician(
  id: string,
  data: Partial<CreatePoliticianInput>
): Promise<StagingPolitician> {
  const record = await getPoliticianById(id);
  if (!record) {
    const err = new Error(`Politician not found: ${id}`) as any;
    err.httpStatus = 404;
    throw err;
  }
  assertPending(record.status);

  // Column name mapping: camelCase input -> snake_case DB columns
  const columnMap: Record<string, string> = {
    fullName: 'full_name',
    party: 'party',
    office: 'office',
    officeLevel: 'office_level',
    state: 'state',
    district: 'district',
    bioText: 'bio_text',
    photoUrl: 'photo_url',
    externalId: 'external_id',
    contacts: 'contacts',
    degrees: 'degrees',
    experiences: 'experiences',
    urls: 'urls',
    images: 'images',
    addresses: 'addresses',
    validFrom: 'valid_from',
    validTo: 'valid_to',
    totalYearsInOffice: 'total_years_in_office',
    isAppointed: 'is_appointed',
    isVacant: 'is_vacant',
  };

  const setClauses: string[] = [];
  const values: any[] = [];

  for (const [key, col] of Object.entries(columnMap)) {
    const val = (data as any)[key];
    if (val !== undefined) {
      setClauses.push(`${col} = $${values.length + 1}`);
      values.push(val);
    }
  }

  // Always bump updated_at
  setClauses.push(`updated_at = NOW()`);

  if (setClauses.length === 1) {
    // Only updated_at — nothing actually changed; just return current record
    return record;
  }

  values.push(id); // final param for WHERE clause
  const { rows } = await pool.query(
    `UPDATE staging.politicians
     SET ${setClauses.join(', ')}
     WHERE id = $${values.length}
     RETURNING *`,
    values
  );

  return mapPoliticianRow(rows[0]);
}

// ---------------------------------------------------------------------------
// Review workflow (approve / reject)
// ---------------------------------------------------------------------------

/**
 * Review a staging politician — approve or reject.
 *
 * On approve:
 *   - Auto-promotes the politician to essentials.politicians via pool.query().
 *   - Sets staging status to 'approved'.
 *
 * On reject:
 *   - Sets staging status to 'rejected' (terminal state).
 *
 * Both paths:
 *   - Increment review_count, set last_reviewed_at, write review log.
 *   - reviewer_name is always derived from public.users — never trusted from client.
 *
 * Throws 422 if record is not in 'pending' status.
 */
export async function reviewPolitician(
  id: string,
  action: 'approve' | 'reject',
  userId: string,
  comment?: string
): Promise<StagingPolitician> {
  const record = await getPoliticianById(id);
  if (!record) {
    const err = new Error(`Politician not found: ${id}`) as any;
    err.httpStatus = 404;
    throw err;
  }
  assertPending(record.status);

  const reviewerName = await getDisplayName(userId);

  let updatedRow: any;

  if (action === 'approve') {
    // Auto-promote to essentials.politicians
    await promoteToEssentials(record);

    // Mark staging record as approved
    const { rows } = await pool.query(
      `UPDATE staging.politicians
       SET status = 'approved',
           reviewed_by = $1,
           review_count = review_count + 1,
           last_reviewed_at = NOW(),
           approved_at = NOW(),
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [reviewerName, id]
    );
    updatedRow = rows[0];
  } else {
    // Reject
    const { rows } = await pool.query(
      `UPDATE staging.politicians
       SET status = 'rejected',
           reviewed_by = $1,
           review_count = review_count + 1,
           last_reviewed_at = NOW(),
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [reviewerName, id]
    );
    updatedRow = rows[0];
  }

  // Write review log
  await pool.query(
    `INSERT INTO staging.politician_review_logs (politician_id, reviewer_name, action, comment)
     VALUES ($1, $2, $3, $4)`,
    [id, reviewerName, action, comment ?? null]
  );

  return mapPoliticianRow(updatedRow);
}

/**
 * Auto-promote a staging politician to essentials.politicians.
 *
 * Column mapping (staging -> essentials):
 *   full_name       -> full_name
 *   party           -> party
 *   bio_text        -> bio_text
 *   photo_url       -> photo_origin_url
 *   is_appointed    -> is_appointed
 *   is_vacant       -> is_vacant (NULL -> false; the essentials column is NOT NULL since CA_0195)
 *   valid_from      -> valid_from
 *   valid_to        -> valid_to
 *   total_years_in_office -> total_years_in_office
 *
 * Always sets: is_active = true, is_incumbent = true
 *
 * external_id type mismatch: staging stores text, essentials stores bigint.
 * Attempt Number(external_id) — if NaN or null, use NULL in essentials.
 * Upsert on external_id when numeric; plain INSERT when null.
 *
 * essentials is NOT in PostgREST — pool.query() required.
 */
async function promoteToEssentials(politician: StagingPolitician): Promise<void> {
  const rawExtId = politician.externalId;
  const numericExtId = rawExtId !== null ? Number(rawExtId) : NaN;
  const essentialsExtId = !isNaN(numericExtId) && rawExtId !== null ? numericExtId : null;

  if (essentialsExtId !== null) {
    // Upsert: conflict on external_id (numeric)
    await pool.query(
      `INSERT INTO essentials.politicians
         (full_name, party, bio_text, photo_origin_url, is_appointed, is_vacant,
          valid_from, valid_to, total_years_in_office, is_active, is_incumbent, external_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true, true, $10)
       ON CONFLICT (external_id) DO UPDATE SET
         full_name = EXCLUDED.full_name,
         party = EXCLUDED.party,
         bio_text = EXCLUDED.bio_text,
         photo_origin_url = EXCLUDED.photo_origin_url,
         is_appointed = EXCLUDED.is_appointed,
         is_vacant = EXCLUDED.is_vacant,
         valid_from = EXCLUDED.valid_from,
         valid_to = EXCLUDED.valid_to,
         total_years_in_office = EXCLUDED.total_years_in_office,
         is_active = true,
         is_incumbent = true`,
      [
        politician.fullName,
        politician.party,
        politician.bioText,
        politician.photoUrl,
        politician.isAppointed,
        politician.isVacant ?? false, // staging.politicians.is_vacant is nullable; essentials is NOT NULL (CA_0195)
        politician.validFrom,
        politician.validTo,
        politician.totalYearsInOffice,
        essentialsExtId,
      ]
    );
  } else {
    // New politician — plain INSERT, no conflict key
    await pool.query(
      `INSERT INTO essentials.politicians
         (full_name, party, bio_text, photo_origin_url, is_appointed, is_vacant,
          valid_from, valid_to, total_years_in_office, is_active, is_incumbent)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true, true)`,
      [
        politician.fullName,
        politician.party,
        politician.bioText,
        politician.photoUrl,
        politician.isAppointed,
        politician.isVacant ?? false, // staging.politicians.is_vacant is nullable; essentials is NOT NULL (CA_0195)
        politician.validFrom,
        politician.validTo,
        politician.totalYearsInOffice,
      ]
    );
  }
}

// ---------------------------------------------------------------------------
// Advisory locking
// ---------------------------------------------------------------------------

/**
 * Atomically acquire a review lock on a staging politician.
 *
 * Uses UPDATE ... WHERE locked_by IS NULL to avoid TOCTOU races.
 * If the row was already locked by another reviewer, returns the current
 * lock holder info so the caller can return a 409.
 */
export async function lockPolitician(
  id: string,
  userId: string
): Promise<{ locked: boolean; lockedBy?: string; lockedAt?: string }> {
  const { rows } = await pool.query(
    `UPDATE staging.politicians
     SET locked_by = $1, locked_at = NOW()
     WHERE id = $2 AND locked_by IS NULL
     RETURNING id`,
    [userId, id]
  );

  if (rows.length > 0) {
    return { locked: true };
  }

  // Lock was not acquired — fetch current holder
  const current = await getPoliticianById(id);
  return {
    locked: false,
    lockedBy: current?.lockedBy ?? undefined,
    lockedAt: current?.lockedAt ?? undefined,
  };
}

/**
 * Release the review lock on a staging politician.
 * Any staging_reviewer or admin can release any lock (no ownership check here —
 * ownership enforcement is at the route level per CONTEXT.md decision).
 */
export async function unlockPolitician(id: string): Promise<void> {
  await pool.query(
    `UPDATE staging.politicians
     SET locked_by = NULL, locked_at = NULL
     WHERE id = $1`,
    [id]
  );
}

// ---------------------------------------------------------------------------
// Merge
// ---------------------------------------------------------------------------

/**
 * Merge a source staging politician into a target.
 *
 * Sets merged_to_id = targetId and marks the source as 'rejected' (terminal).
 * Writes a review log with action = 'merged'.
 * reviewer_name is always derived from public.users.
 *
 * Throws 422 if source is not in 'pending' status.
 * Throws 404 if source or target does not exist.
 */
export async function mergePolitician(
  sourceId: string,
  targetId: string,
  userId: string
): Promise<StagingPolitician> {
  const source = await getPoliticianById(sourceId);
  if (!source) {
    const err = new Error(`Source politician not found: ${sourceId}`) as any;
    err.httpStatus = 404;
    throw err;
  }
  assertPending(source.status);

  const target = await getPoliticianById(targetId);
  if (!target) {
    const err = new Error(`Target politician not found: ${targetId}`) as any;
    err.httpStatus = 404;
    throw err;
  }

  const reviewerName = await getDisplayName(userId);

  const { rows } = await pool.query(
    `UPDATE staging.politicians
     SET merged_to_id = $1,
         status = 'rejected',
         reviewed_by = $2,
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [targetId, reviewerName, sourceId]
  );

  // Write review log
  await pool.query(
    `INSERT INTO staging.politician_review_logs (politician_id, reviewer_name, action, comment)
     VALUES ($1, $2, 'merged', $3)`,
    [sourceId, reviewerName, `Merged into ${targetId}`]
  );

  return mapPoliticianRow(rows[0]);
}

// ---------------------------------------------------------------------------
// Stance types
// ---------------------------------------------------------------------------

export interface StagingStance {
  id: string;
  contextKey: string;
  politicianExternalId: string | null;
  politicianName: string;
  topicKey: string;
  topicId: string | null;
  value: number;
  reasoning: string | null;
  sources: string[];
  status: string;
  addedBy: string;
  reviewedBy: string[];
  lastReviewedAt: string | null;
  reviewCount: number;
  lockedBy: string | null;
  lockedAt: string | null;
  approvedToAnswerId: string | null;
  approvedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface StanceReviewLog {
  id: string;
  stanceId: string;
  reviewerName: string;
  action: string;
  previousValue: number | null;
  newValue: number | null;
  comment: string | null;
  createdAt: string;
}

export interface CreateStanceInput {
  contextKey: string;
  politicianExternalId?: string | null;
  politicianName: string;
  topicKey: string;
  topicId?: string | null;
  value: number;
  reasoning?: string | null;
  sources?: string[];
}

function mapStanceRow(row: any): StagingStance {
  return {
    id: row.id,
    contextKey: row.context_key,
    politicianExternalId: row.politician_external_id,
    politicianName: row.politician_name,
    topicKey: row.topic_key,
    topicId: row.topic_id,
    value: Number(row.value),
    reasoning: row.reasoning,
    sources: row.sources ?? [],
    status: row.status,
    addedBy: row.added_by,
    reviewedBy: row.reviewed_by ?? [],
    lastReviewedAt: row.last_reviewed_at,
    reviewCount: Number(row.review_count),
    lockedBy: row.locked_by,
    lockedAt: row.locked_at,
    approvedToAnswerId: row.approved_to_answer_id,
    approvedAt: row.approved_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function getStances(filters?: { status?: string }): Promise<StagingStance[]> {
  if (filters?.status) {
    const { rows } = await pool.query(
      `SELECT * FROM staging.stances WHERE status = $1 ORDER BY created_at DESC`,
      [filters.status]
    );
    return rows.map(mapStanceRow);
  }
  const { rows } = await pool.query(`SELECT * FROM staging.stances ORDER BY created_at DESC`);
  return rows.map(mapStanceRow);
}

export async function getStanceById(id: string): Promise<StagingStance | null> {
  const { rows } = await pool.query(`SELECT * FROM staging.stances WHERE id = $1`, [id]);
  return rows.length > 0 ? mapStanceRow(rows[0]) : null;
}

export async function createStance(data: CreateStanceInput, userId: string): Promise<StagingStance> {
  const addedBy = await getDisplayName(userId);
  const { rows } = await pool.query(
    `INSERT INTO staging.stances
       (context_key, politician_external_id, politician_name, topic_key, topic_id,
        value, reasoning, sources, added_by, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
     RETURNING *`,
    [
      data.contextKey,
      data.politicianExternalId ?? null,
      data.politicianName,
      data.topicKey,
      data.topicId ?? null,
      data.value,
      data.reasoning ?? null,
      data.sources ?? null,
      addedBy,
    ]
  );
  return mapStanceRow(rows[0]);
}

export async function updateStance(id: string, data: Partial<CreateStanceInput>): Promise<StagingStance> {
  const record = await getStanceById(id);
  if (!record) {
    const err = new Error(`Stance not found: ${id}`) as any;
    err.httpStatus = 404;
    throw err;
  }
  assertPending(record.status);

  const columnMap: Record<string, string> = {
    contextKey: 'context_key',
    politicianExternalId: 'politician_external_id',
    politicianName: 'politician_name',
    topicKey: 'topic_key',
    topicId: 'topic_id',
    value: 'value',
    reasoning: 'reasoning',
    sources: 'sources',
  };

  const setClauses: string[] = [];
  const values: any[] = [];

  for (const [key, col] of Object.entries(columnMap)) {
    const val = (data as any)[key];
    if (val !== undefined) {
      setClauses.push(`${col} = $${values.length + 1}`);
      values.push(val);
    }
  }
  setClauses.push(`updated_at = NOW()`);

  if (setClauses.length === 1) return record;

  values.push(id);
  const { rows } = await pool.query(
    `UPDATE staging.stances SET ${setClauses.join(', ')} WHERE id = $${values.length} RETURNING *`,
    values
  );
  return mapStanceRow(rows[0]);
}

export async function reviewStance(
  id: string,
  action: 'approve' | 'reject',
  userId: string,
  comment?: string,
  newValue?: number
): Promise<StagingStance> {
  const record = await getStanceById(id);
  if (!record) {
    const err = new Error(`Stance not found: ${id}`) as any;
    err.httpStatus = 404;
    throw err;
  }
  assertPending(record.status);

  const reviewerName = await getDisplayName(userId);
  const previousValue = record.value;

  let updatedRow: any;

  if (action === 'approve') {
    if (!record.topicId) {
      const err = new Error('Cannot approve stance: topic_id is required for promotion to politician_answers') as any;
      err.httpStatus = 422;
      throw err;
    }

    const extIdNum = record.politicianExternalId !== null ? Number(record.politicianExternalId) : NaN;
    if (isNaN(extIdNum)) {
      const err = new Error(`Cannot approve stance: politician not found in essentials (external_id: ${record.politicianExternalId})`) as any;
      err.httpStatus = 422;
      throw err;
    }

    const { rows: polRows } = await pool.query(
      `SELECT id FROM essentials.politicians WHERE external_id = $1`,
      [extIdNum]
    );
    if (polRows.length === 0) {
      const err = new Error(`Cannot approve stance: politician not found in essentials (external_id: ${record.politicianExternalId})`) as any;
      err.httpStatus = 422;
      throw err;
    }
    const politicianId = polRows[0].id;
    const approvalValue = newValue !== undefined ? newValue : record.value;

    if (newValue !== undefined) {
      await pool.query(
        `UPDATE staging.stances SET value = $1 WHERE id = $2`,
        [newValue, id]
      );
    }

    // Season-aware write; shape defined once in seasonService. Approving a
    // staged stance writes it into the OPEN season, pinned to the ladder
    // revision that season asks — never into a closed one.
    const approved = await pool.query(UPSERT_ANSWER_SQL,
      [politicianId, record.topicId, approvalValue, userId]
    );
    await assertWritten(approved.rowCount ?? 0, record.topicId);

    const { rows } = await pool.query(
      `UPDATE staging.stances
       SET status = 'approved', approved_at = NOW(), review_count = review_count + 1,
           last_reviewed_at = NOW(), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id]
    );
    updatedRow = rows[0];
  } else {
    const { rows } = await pool.query(
      `UPDATE staging.stances
       SET status = 'rejected', review_count = review_count + 1,
           last_reviewed_at = NOW(), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id]
    );
    updatedRow = rows[0];
  }

  await pool.query(
    `INSERT INTO staging.review_logs (stance_id, reviewer_name, action, previous_value, new_value, comment)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [id, reviewerName, action, previousValue, newValue ?? null, comment ?? null]
  );

  return mapStanceRow(updatedRow);
}

export async function lockStance(
  id: string,
  userId: string
): Promise<{ locked: boolean; lockedBy?: string; lockedAt?: string }> {
  const { rows } = await pool.query(
    `UPDATE staging.stances SET locked_by = $1, locked_at = NOW()
     WHERE id = $2 AND locked_by IS NULL RETURNING id`,
    [userId, id]
  );
  if (rows.length > 0) return { locked: true };

  const current = await getStanceById(id);
  return {
    locked: false,
    lockedBy: current?.lockedBy ?? undefined,
    lockedAt: current?.lockedAt ?? undefined,
  };
}

export async function unlockStance(id: string): Promise<void> {
  await pool.query(
    `UPDATE staging.stances SET locked_by = NULL, locked_at = NULL WHERE id = $1`,
    [id]
  );
}

// ---------------------------------------------------------------------------
// Building photo types
// ---------------------------------------------------------------------------

export interface StagingPhoto {
  id: string;
  placeGeoid: string;
  placeName: string;
  state: string | null;
  url: string;
  sourceUrl: string | null;
  license: string;
  attribution: string;
  status: string;
  addedBy: string;
  reviewedBy: string[];
  lastReviewedAt: string | null;
  reviewCount: number;
  approvedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PhotoReviewLog {
  id: string;
  buildingPhotoId: string;
  reviewerName: string;
  action: string;
  comment: string | null;
  createdAt: string;
}

export interface CreatePhotoInput {
  placeGeoid: string;
  placeName: string;
  state?: string | null;
  url: string;
  sourceUrl?: string | null;
  license: string;
  attribution: string;
}

function mapPhotoRow(row: any): StagingPhoto {
  return {
    id: row.id,
    placeGeoid: row.place_geoid,
    placeName: row.place_name,
    state: row.state,
    url: row.url,
    sourceUrl: row.source_url,
    license: row.license,
    attribution: row.attribution,
    status: row.status,
    addedBy: row.added_by,
    reviewedBy: row.reviewed_by ?? [],
    lastReviewedAt: row.last_reviewed_at,
    reviewCount: Number(row.review_count),
    approvedAt: row.approved_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function getPhotos(filters?: { status?: string }): Promise<StagingPhoto[]> {
  if (filters?.status) {
    const { rows } = await pool.query(
      `SELECT * FROM staging.building_photos WHERE status = $1 ORDER BY created_at DESC`,
      [filters.status]
    );
    return rows.map(mapPhotoRow);
  }
  const { rows } = await pool.query(`SELECT * FROM staging.building_photos ORDER BY created_at DESC`);
  return rows.map(mapPhotoRow);
}

export async function getPhotoById(id: string): Promise<StagingPhoto | null> {
  const { rows } = await pool.query(`SELECT * FROM staging.building_photos WHERE id = $1`, [id]);
  return rows.length > 0 ? mapPhotoRow(rows[0]) : null;
}

export async function createPhoto(data: CreatePhotoInput, userId: string): Promise<StagingPhoto> {
  const addedBy = await getDisplayName(userId);
  const { rows } = await pool.query(
    `INSERT INTO staging.building_photos
       (place_geoid, place_name, state, url, source_url, license, attribution, added_by, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending')
     RETURNING *`,
    [
      data.placeGeoid,
      data.placeName,
      data.state ?? null,
      data.url,
      data.sourceUrl ?? null,
      data.license,
      data.attribution,
      addedBy,
    ]
  );
  return mapPhotoRow(rows[0]);
}

export async function reviewPhoto(
  id: string,
  action: 'approve' | 'reject',
  userId: string,
  comment?: string
): Promise<StagingPhoto> {
  const record = await getPhotoById(id);
  if (!record) {
    const err = new Error(`Building photo not found: ${id}`) as any;
    err.httpStatus = 404;
    throw err;
  }
  assertPending(record.status);

  const reviewerName = await getDisplayName(userId);
  let updatedRow: any;

  if (action === 'approve') {
    await pool.query(
      `INSERT INTO essentials.building_photos (place_geoid, url, source_url, license, attribution)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (place_geoid) DO UPDATE SET
         url = EXCLUDED.url,
         source_url = EXCLUDED.source_url,
         license = EXCLUDED.license,
         attribution = EXCLUDED.attribution`,
      [record.placeGeoid, record.url, record.sourceUrl, record.license, record.attribution]
    );
    const { rows } = await pool.query(
      `UPDATE staging.building_photos
       SET status = 'approved', approved_at = NOW(), review_count = review_count + 1,
           last_reviewed_at = NOW(), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id]
    );
    updatedRow = rows[0];
  } else {
    const { rows } = await pool.query(
      `UPDATE staging.building_photos
       SET status = 'rejected', review_count = review_count + 1,
           last_reviewed_at = NOW(), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id]
    );
    updatedRow = rows[0];
  }

  await pool.query(
    `INSERT INTO staging.building_photo_review_logs (building_photo_id, reviewer_name, action, comment)
     VALUES ($1, $2, $3, $4)`,
    [id, reviewerName, action, comment ?? null]
  );

  return mapPhotoRow(updatedRow);
}
