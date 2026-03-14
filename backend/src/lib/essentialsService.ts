/**
 * essentialsService — public politician data lookups for CompassV2 frontend.
 *
 * WHY THIS FILE EXISTS:
 * Route files must not reference the service-role client directly (enforced
 * by architecture.test.ts). This service wraps all DB access for the
 * GET /api/essentials/politicians endpoint using supabaseAnon only.
 *
 * inform.politicians rows are public reference data — no user-owned data,
 * no sensitive fields, no RLS bypass needed. supabaseAnon (anon key, RLS
 * enforced) is the correct client for this table.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 */

import { supabaseAnon } from './supabase.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface PoliticianRecord {
  id: string;
  full_name: string | null;
  office_title: string | null;
  photo_origin_url: string | null;
  is_candidate: boolean;
  // New fields from migration 033
  representing_city: string | null;
  representing_state: string | null;
  district_type: string | null;
  district_label: string | null;
  district_id: string | null;
  chamber_name: string | null;
  chamber_name_formal: string | null;
  government_name: string | null;
  is_vacant: boolean;
}

export interface PoliticianGroup {
  office_title: string | null;
  incumbent: PoliticianRecord | null;
  candidates: PoliticianRecord[];
}

// ---------------------------------------------------------------------------
// getPoliticiansGrouped
// ---------------------------------------------------------------------------

/**
 * Fetch active, non-vacant politicians from inform.politicians and group by office_title.
 *
 * Filters applied:
 *   - is_active = true  (exclude deactivated/removed records)
 *   - is_vacant = false (exclude vacant seats — no elected officeholder)
 *
 * When includeCandidates is false:
 *   - Returns only rows where is_candidate = false (incumbents)
 *   - Each group: { office_title, incumbent: politician, candidates: [] }
 *
 * When includeCandidates is true:
 *   - Returns all active politicians (incumbents + candidates)
 *   - Each group: { office_title, incumbent: first non-candidate, candidates: all candidates }
 *
 * Ordering: non-null office_title groups first (alphabetical), null last.
 *
 * On DB error: throws (NOT a silent empty array).
 */
export async function getPoliticiansGrouped(
  includeCandidates: boolean
): Promise<PoliticianGroup[]> {
  // Build query — explicit column list, never *
  let query = supabaseAnon
    .schema('inform')
    .from('politicians')
    .select('id, full_name, office_title, photo_origin_url, is_candidate, representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, is_vacant')
    .eq('is_active', true)
    .eq('is_vacant', false)
    .order('office_title', { ascending: true, nullsFirst: false })
    .order('full_name', { ascending: true });

  // If not including candidates, filter to incumbents only
  if (!includeCandidates) {
    query = query.eq('is_candidate', false);
  }

  const { data, error } = await query;

  if (error) throw error;

  const rows: Array<{
    id: string;
    full_name: string | null;
    office_title: string | null;
    photo_origin_url: string | null;
    is_candidate: boolean;
    representing_city: string | null;
    representing_state: string | null;
    district_type: string | null;
    district_label: string | null;
    district_id: string | null;
    chamber_name: string | null;
    chamber_name_formal: string | null;
    government_name: string | null;
    is_vacant: boolean;
  }> = data ?? [];

  // Group by office_title
  const groupMap = new Map<string | null, PoliticianGroup>();

  for (const row of rows) {
    const key = row.office_title ?? null;
    const record: PoliticianRecord = {
      id: row.id,
      full_name: row.full_name,
      office_title: row.office_title,
      photo_origin_url: row.photo_origin_url,
      is_candidate: row.is_candidate,
      representing_city: row.representing_city,
      representing_state: row.representing_state,
      district_type: row.district_type,
      district_label: row.district_label,
      district_id: row.district_id,
      chamber_name: row.chamber_name,
      chamber_name_formal: row.chamber_name_formal,
      government_name: row.government_name,
      is_vacant: row.is_vacant,
    };

    if (!groupMap.has(key)) {
      groupMap.set(key, {
        office_title: key,
        incumbent: null,
        candidates: [],
      });
    }

    const group = groupMap.get(key)!;

    if (record.is_candidate) {
      group.candidates.push(record);
    } else {
      // First incumbent seen for this office_title becomes the group incumbent
      if (group.incumbent === null) {
        group.incumbent = record;
      }
    }
  }

  // Sort groups: non-null office_title first (alphabetical), null last
  const groups = Array.from(groupMap.values());
  groups.sort((a, b) => {
    if (a.office_title === null && b.office_title === null) return 0;
    if (a.office_title === null) return 1;
    if (b.office_title === null) return -1;
    return a.office_title.localeCompare(b.office_title);
  });

  return groups;
}
