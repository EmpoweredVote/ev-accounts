// ev-accounts/backend/src/lib/sourceVerificationService.ts
/**
 * sourceVerificationService — CRUD for public.source_verifications.
 * Shared by the verify-sources skill (via pool queries) and the admin routes.
 */

import { pool } from './db.js';

export type SourceVerificationStatus = 'unverified' | 'verified' | 'needs_review';
export type SourceVerificationEntityType = 'compass_stance' | 'readrank_quote';

export interface SourceVerification {
  id: string;
  entity_type: SourceVerificationEntityType;
  politician_id: string;
  topic_id: string | null;
  quote_id: string | null;
  url_index: number;
  url: string;
  status: SourceVerificationStatus;
  verified_at: string | null;
  verified_by: string | null;
  notes: string | null;
  replacement_url: string | null;
  original_url: string | null;
  http_status: number | null;
  unfixable: boolean;
  created_at: string;
  updated_at: string;
}

export interface ListParams {
  status?: SourceVerificationStatus;
  entity_type?: SourceVerificationEntityType;
  limit?: number;
  offset?: number;
  include_unfixable?: boolean;
}

export async function listSourceVerifications(
  params: ListParams
): Promise<{ rows: SourceVerification[]; total: number }> {
  const status = params.status ?? null;
  const entity_type = params.entity_type ?? null;
  const limit = Math.min(params.limit ?? 50, 200);
  const offset = params.offset ?? 0;
  const include_unfixable = params.include_unfixable ?? false;

  const { rows } = await pool.query<SourceVerification>(
    `
    SELECT * FROM public.source_verifications
    WHERE ($1::text IS NULL OR status = $1)
      AND ($2::text IS NULL OR entity_type = $2)
      AND ($3::boolean OR unfixable = false)
    ORDER BY created_at ASC
    LIMIT $4 OFFSET $5
    `,
    [status, entity_type, include_unfixable, limit, offset]
  );

  const { rows: countRows } = await pool.query<{ count: string }>(
    `
    SELECT COUNT(*)::text AS count FROM public.source_verifications
    WHERE ($1::text IS NULL OR status = $1)
      AND ($2::text IS NULL OR entity_type = $2)
      AND ($3::boolean OR unfixable = false)
    `,
    [status, entity_type, include_unfixable]
  );

  return { rows, total: parseInt(countRows[0]?.count ?? '0', 10) };
}

export async function getSourceVerification(id: string): Promise<SourceVerification | null> {
  const { rows } = await pool.query<SourceVerification>(
    'SELECT * FROM public.source_verifications WHERE id = $1',
    [id]
  );
  return rows[0] ?? null;
}

export interface SkillUpdate {
  status: SourceVerificationStatus;
  notes?: string | null;
  http_status?: number | null;
  replacement_url?: string | null;
  verified_by?: string; // defaults to 'auto'
}

/**
 * Called by the verify-sources skill. Never mutates the underlying compass/readrank
 * source URL — only updates verification status. URL replacement requires human
 * approval via approveSourceVerification().
 */
export async function applySkillResult(
  id: string,
  update: SkillUpdate
): Promise<SourceVerification> {
  const { rows } = await pool.query<SourceVerification>(
    `
    UPDATE public.source_verifications
    SET status = $2,
        notes = $3,
        http_status = $4,
        replacement_url = $5,
        verified_by = COALESCE($6, 'auto'),
        verified_at = CASE WHEN $2 = 'unverified' THEN NULL ELSE now() END
    WHERE id = $1
    RETURNING *
    `,
    [
      id,
      update.status,
      update.notes ?? null,
      update.http_status ?? null,
      update.replacement_url ?? null,
      update.verified_by ?? 'auto',
    ]
  );
  if (!rows[0]) throw new Error(`source_verification ${id} not found`);
  return rows[0];
}

/**
 * Approve current URL (no replacement) or approve a replacement URL.
 * If a new URL is supplied AND differs from current, swap it into the underlying
 * compass sources[] array or essentials.quotes.source_url, preserving original_url.
 */
export async function approveSourceVerification(
  id: string,
  actorUserId: string,
  newUrl?: string
): Promise<SourceVerification> {
  const existing = await getSourceVerification(id);
  if (!existing) throw new Error(`source_verification ${id} not found`);

  const shouldReplace = !!newUrl && newUrl !== existing.url;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (shouldReplace) {
      if (existing.entity_type === 'compass_stance') {
        // Replace sources[url_index] in inform.politician_context, in the NEWEST
        // season whose array actually holds that URL at that index.
        //
        // Two guards, both load-bearing:
        //   · season_id is named, so the patch cannot spray across every season.
        //     Array POSITIONS differ per season, so an unconstrained UPDATE would
        //     overwrite an unrelated citation at the same index elsewhere.
        //   · sources[...] = $5 requires the slot to still contain the URL being
        //     replaced. If an editor changed it since verification, this patches
        //     nothing rather than clobbering their edit.
        //
        // With one season this is exactly the old behaviour. ⚠ OPEN QUESTION for
        // a human: should correcting a dead or fabricated URL reach a CLOSED
        // season at all? It edits a citation inside a sealed record. Left
        // reachable here because a wrong source is a factual error and the
        // repo's stance-source policy repoints rather than retires — but that is
        // an editorial call, not one this function should be making silently.
        await client.query(
          `
          UPDATE inform.politician_context c
          SET sources[$3::int + 1] = $4, updated_at = now()
          WHERE c.politician_id = $1 AND c.topic_id = $2
            AND c.sources[$3::int + 1] = $5
            AND c.season_id = (
              SELECT c2.season_id
                FROM inform.politician_context c2
                JOIN inform.seasons s2 ON s2.id = c2.season_id
               WHERE c2.politician_id = $1 AND c2.topic_id = $2
                 AND c2.sources[$3::int + 1] = $5
               ORDER BY s2.number DESC
               LIMIT 1
            )
          `,
          [existing.politician_id, existing.topic_id, existing.url_index, newUrl, existing.url]
        );
      } else {
        // readrank_quote — single source_url column
        await client.query(
          `UPDATE essentials.quotes SET source_url = $2 WHERE id = $1`,
          [existing.quote_id, newUrl]
        );
      }
    }

    const { rows } = await client.query<SourceVerification>(
      `
      UPDATE public.source_verifications
      SET status = 'verified',
          verified_at = now(),
          verified_by = $2,
          url = COALESCE($3, url),
          original_url = CASE WHEN $3 IS NOT NULL AND $3 <> url THEN url ELSE original_url END,
          replacement_url = NULL,
          unfixable = false
      WHERE id = $1
      RETURNING *
      `,
      [id, actorUserId, shouldReplace ? newUrl : null]
    );

    await client.query('COMMIT');
    return rows[0]!;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

export async function markUnfixable(
  id: string,
  actorUserId: string,
  note?: string
): Promise<SourceVerification> {
  const { rows } = await pool.query<SourceVerification>(
    `
    UPDATE public.source_verifications
    SET unfixable = true,
        verified_by = $2,
        notes = COALESCE($3, notes)
    WHERE id = $1
    RETURNING *
    `,
    [id, actorUserId, note ?? null]
  );
  if (!rows[0]) throw new Error(`source_verification ${id} not found`);
  return rows[0];
}

/**
 * Trusted-domain guardrail for the skill. Returns true if at least one URL
 * from the same host has already reached status='verified'.
 */
export async function isDomainTrusted(url: string): Promise<boolean> {
  let host: string;
  try {
    host = new URL(url).host.toLowerCase();
  } catch {
    return false;
  }
  const { rows } = await pool.query<{ count: string }>(
    `
    SELECT COUNT(*)::text AS count
    FROM public.source_verifications
    WHERE status = 'verified'
      AND lower(split_part(regexp_replace(url, '^https?://', ''), '/', 1)) = $1
    LIMIT 1
    `,
    [host]
  );
  return parseInt(rows[0]?.count ?? '0', 10) > 0;
}
