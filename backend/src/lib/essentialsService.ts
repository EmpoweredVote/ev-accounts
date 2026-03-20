/**
 * essentialsService — public politician data lookups for CompassV2 frontend.
 *
 * WHY THIS FILE EXISTS:
 * Route files must not reference the service-role client directly (enforced
 * by architecture.test.ts). This service wraps all DB access for the
 * GET /api/essentials/politicians endpoint using supabaseAnon only.
 *
 * essentials.politicians rows are public reference data — no user-owned data,
 * no sensitive fields, no RLS bypass needed. supabaseAnon (anon key, RLS
 * enforced) is the correct client for this table.
 *
 * After Phase 35 deduplication, essentials.politicians is the unified source
 * of truth for politician identity. inform-specific columns (office_title,
 * district_type, district_label, etc.) are not present in this table.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface PoliticianRecord {
  id: string;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  preferred_name: string | null;
  photo_origin_url: string | null;
  is_active: boolean;
  is_vacant: boolean | null;
  is_incumbent: boolean;
  party: string | null;
  party_short_name: string | null;
  slug: string | null;
  bio_text: string | null;
}

export interface PoliticianGroup {
  party: string | null;
  incumbent: PoliticianRecord | null;
  candidates: PoliticianRecord[];
}

// ---------------------------------------------------------------------------
// getPoliticiansGrouped
// ---------------------------------------------------------------------------

/**
 * Fetch active politicians from essentials.politicians and group by party.
 *
 * After Phase 35 deduplication, essentials.politicians is the unified source
 * of truth. inform-specific columns (office_title, district_type, is_candidate,
 * etc.) are not present; essentials uses is_incumbent to distinguish incumbents
 * from non-incumbents.
 *
 * Filters applied:
 *   - is_active = true  (exclude deactivated/removed records)
 *
 * When includeCandidates is false:
 *   - Returns only rows where is_incumbent = true
 *   - Each group: { party, incumbent: politician, candidates: [] }
 *
 * When includeCandidates is true:
 *   - Returns all active politicians (incumbents + non-incumbents)
 *   - Each group: { party, incumbent: first incumbent in party, candidates: non-incumbents }
 *
 * Ordering: non-null party groups first (alphabetical), null last.
 *
 * On DB error: throws (NOT a silent empty array).
 */
export async function getPoliticiansGrouped(
  includeCandidates: boolean
): Promise<PoliticianGroup[]> {
  // Uses pool.query() — essentials schema is not exposed via PostgREST.
  // Build parameterized query with optional incumbent filter.
  const baseSelect = `
    SELECT id, full_name, first_name, last_name, preferred_name,
           photo_origin_url, is_active, is_vacant, is_incumbent,
           party, party_short_name, slug, bio_text
    FROM essentials.politicians
    WHERE is_active = true`;

  const queryText = includeCandidates
    ? `${baseSelect} ORDER BY party ASC NULLS LAST, last_name ASC, first_name ASC`
    : `${baseSelect} AND is_incumbent = true ORDER BY party ASC NULLS LAST, last_name ASC, first_name ASC`;

  const { rows } = await pool.query<{
    id: string;
    full_name: string | null;
    first_name: string | null;
    last_name: string | null;
    preferred_name: string | null;
    photo_origin_url: string | null;
    is_active: boolean;
    is_vacant: boolean | null;
    is_incumbent: boolean;
    party: string | null;
    party_short_name: string | null;
    slug: string | null;
    bio_text: string | null;
  }>(queryText);

  // Group by party
  const groupMap = new Map<string | null, PoliticianGroup>();

  for (const row of rows) {
    const key = row.party ?? null;
    const record: PoliticianRecord = {
      id: row.id,
      full_name: row.full_name,
      first_name: row.first_name,
      last_name: row.last_name,
      preferred_name: row.preferred_name,
      photo_origin_url: row.photo_origin_url,
      is_active: row.is_active,
      is_vacant: row.is_vacant,
      is_incumbent: row.is_incumbent,
      party: row.party,
      party_short_name: row.party_short_name,
      slug: row.slug,
      bio_text: row.bio_text,
    };

    if (!groupMap.has(key)) {
      groupMap.set(key, {
        party: key,
        incumbent: null,
        candidates: [],
      });
    }

    const group = groupMap.get(key)!;

    if (record.is_incumbent) {
      // First incumbent seen for this party becomes the group incumbent
      if (group.incumbent === null) {
        group.incumbent = record;
      } else {
        group.candidates.push(record);
      }
    } else {
      group.candidates.push(record);
    }
  }

  // Sort groups: non-null party first (alphabetical), null last
  const groups = Array.from(groupMap.values());
  groups.sort((a, b) => {
    if (a.party === null && b.party === null) return 0;
    if (a.party === null) return 1;
    if (b.party === null) return -1;
    return a.party.localeCompare(b.party);
  });

  return groups;
}
