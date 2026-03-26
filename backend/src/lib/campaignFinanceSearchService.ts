/**
 * campaignFinanceSearchService — politician name search using pg_trgm word_similarity.
 *
 * WHY THIS FILE EXISTS:
 * Exposes a public searchPoliticians() function that queries essentials.politicians
 * with trigram-based fuzzy matching and accent folding via public.f_unaccent().
 *
 * Index used: idx_politicians_full_name_trgm (GIN, created in Plan 12-01).
 *
 * Threshold calibration (query length determines tolerance):
 *   2-4 chars: 0.15 (short query, wider net)
 *   5-7 chars: 0.25 (medium query)
 *   8+ chars:  0.30 (long query, tighter match)
 *
 * All response objects are built from explicit field whitelists.
 * politician_source_id is NEVER exposed.
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Public interfaces
// ---------------------------------------------------------------------------

export interface SearchResult {
  uuid: string;
  name: string;
  office_title: string | null;
  jurisdiction: string | null;
  district: string | null;
  headshot_url: string | null;
}

export interface SearchResponse {
  results: SearchResult[];
  count: number;
  query: string;
  truncated: boolean;
}

// ---------------------------------------------------------------------------
// DB row interface (internal — never exposed directly)
// ---------------------------------------------------------------------------

interface SearchRow {
  uuid: string;
  name: string;
  office_title: string | null;
  jurisdiction: string | null;
  district: string | null;
  headshot_url: string | null;
  sim: string; // pg returns numeric as string
  jurisdiction_tier: string; // pg returns integer as string
}

// ---------------------------------------------------------------------------
// searchPoliticians
// ---------------------------------------------------------------------------

/**
 * Search politicians by name using trigram word_similarity with accent folding.
 *
 * @param query     - The search string (must be >= 2 chars — caller enforces)
 * @param limit     - Max results to return (1–50)
 * @param offset    - Pagination offset
 * @returns         SearchResponse envelope with results, count, query, truncated flag
 */
export async function searchPoliticians(
  query: string,
  limit: number,
  offset: number
): Promise<SearchResponse> {
  // Calibrate similarity threshold based on query length.
  // Shorter queries need a lower threshold (more tolerant) because
  // word_similarity on 2-3 char strings naturally produces lower scores.
  const threshold = query.length <= 4 ? 0.15 : query.length <= 7 ? 0.25 : 0.30;

  // Fetch limit+1 rows to detect truncation without a separate COUNT query.
  const fetchLimit = limit + 1;

  // NOTE: threshold is interpolated (not parameterized) because it is computed
  // entirely from query.length — derived from code logic, not user input.
  // This is safe from SQL injection. Only $1 (query string), $2 (limit), $3 (offset)
  // come from external input and are parameterized.
  //
  // DISTINCT ON (p.id) deduplicates politicians who hold multiple offices.
  // The inner query orders by p.id (required by DISTINCT ON) then prefers
  // non-vacant offices (o.is_vacant ASC NULLS LAST).
  //
  // The outer query re-sorts globally by similarity DESC, then jurisdiction tier
  // ASC (local first = most relevant for civic use), then name ASC as tiebreaker.
  const sql = `
    WITH matches AS (
      SELECT DISTINCT ON (p.id)
        p.id                                                                   AS uuid,
        p.full_name                                                            AS name,
        o.title                                                                AS office_title,
        g.name                                                                 AS jurisdiction,
        d.label                                                                AS district,
        COALESCE(NULLIF(p.photo_custom_url, ''), NULLIF(p.photo_origin_url, '')) AS headshot_url,
        word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(p.full_name))) AS sim,
        CASE
          WHEN d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY', 'SCHOOL')                              THEN 1
          WHEN d.district_type IN ('STATE_UPPER', 'STATE_LOWER', 'STATE_EXEC', 'JUDICIAL')                 THEN 2
          WHEN d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER', 'NATIONAL_EXEC', 'NATIONAL_JUDICIAL') THEN 3
          ELSE 4
        END                                                                    AS jurisdiction_tier
      FROM essentials.politicians p
      LEFT JOIN essentials.offices o
        ON  o.politician_id = p.id
        AND o.is_vacant = false
      LEFT JOIN essentials.districts d
        ON  d.id = o.district_id
      LEFT JOIN essentials.chambers ch
        ON  ch.id = o.chamber_id
      LEFT JOIN essentials.governments g
        ON  g.id = ch.government_id
      WHERE p.is_active = true
        AND word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(p.full_name))) >= ${threshold}
      ORDER BY p.id, o.is_vacant ASC NULLS LAST
    )
    SELECT uuid, name, office_title, jurisdiction, district, headshot_url, sim, jurisdiction_tier
    FROM matches
    ORDER BY sim DESC, jurisdiction_tier ASC, name ASC
    LIMIT  $2
    OFFSET $3
  `;

  const { rows } = await pool.query<SearchRow>(sql, [query, fetchLimit, offset]);

  // Detect truncation: if we got more than limit rows, there are more results.
  const truncated = rows.length > limit;
  const resultRows = truncated ? rows.slice(0, limit) : rows;

  // Map to SearchResult using explicit field whitelist (never object spread).
  const results: SearchResult[] = resultRows.map((row) => ({
    uuid:         row.uuid,
    name:         row.name,
    office_title: row.office_title,
    jurisdiction: row.jurisdiction,
    district:     row.district,
    headshot_url: row.headshot_url,
  }));

  return {
    results,
    count:     results.length,
    query,
    truncated,
  };
}
