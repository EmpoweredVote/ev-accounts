/**
 * candidateService — public candidate profile lookups, ZIP-based discovery,
 * and per-topic answer retrieval with inversion support.
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. Public candidate endpoints require supabaseAdmin
 * for two reasons:
 *
 * 1. GET /api/candidates/:slug must return INACTIVE candidates (demoted civic
 *    leaders whose pages display a demotion notice). The "public read active"
 *    RLS policy on empower.empowered_profiles hides inactive rows from
 *    non-owners. Only supabaseAdmin (service role) can bypass that policy.
 *
 * 2. Compass answers are stored in inform.compass_responses, which has no
 *    public SELECT policy — reads are only permitted via the service role.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses. Sensitive internal fields must never appear in any return value.
 */

import { supabaseAdmin } from './supabase.js';
import { cache } from './cache.js';
import { getSelectedTopics } from './compassService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CandidateProfile {
  candidate_page_slug: string;
  first_name: string;
  last_name: string;
  active: boolean;
  demoted_at: string | null;
  empowered_at: string;
  // NOTE: representing_city, district columns, government_name, chamber_name are planned
  // for a future empowered_profiles schema migration. Not yet in the live DB schema.
  images: Array<{ type: string; url: string | null }>;
  featured_stances: Array<{ topic_id: string; value: number; write_in_text?: string }>;
}

export interface EssentialsCandidate {
  candidate_page_slug: string;
  first_name: string;
  last_name: string;
  // NOTE: representing_city, district_type, government_name, chamber_name are planned
  // for a future empowered_profiles schema migration. Not yet in the live DB schema.
  images: Array<{ type: string; url: string | null }>;
}

export interface CandidateAnswer {
  topic_id: string;
  value: number;
  write_in_text?: string;
}

// ---------------------------------------------------------------------------
// splitLegalName (exported for use in route serialization)
// ---------------------------------------------------------------------------

/**
 * Split a stored legal_name into first_name and last_name.
 *
 * Rules:
 * - Trim whitespace before splitting
 * - Split on the first space only — multi-word last names preserved in last_name
 * - Single-word name: first_name = full input, last_name = ''
 *
 * Examples:
 *   "Maria Garcia"        → { first_name: 'Maria', last_name: 'Garcia' }
 *   "Mary Jo Van Pelt"    → { first_name: 'Mary', last_name: 'Jo Van Pelt' }
 *   "Cher"                → { first_name: 'Cher', last_name: '' }
 */
export function splitLegalName(legalName: string): { first_name: string; last_name: string } {
  const trimmed = legalName.trim();
  const spaceIndex = trimmed.indexOf(' ');
  if (spaceIndex === -1) {
    return { first_name: trimmed, last_name: '' };
  }
  return {
    first_name: trimmed.slice(0, spaceIndex),
    last_name: trimmed.slice(spaceIndex + 1),
  };
}

// ---------------------------------------------------------------------------
// getCandidateBySlug
// ---------------------------------------------------------------------------

/**
 * Fetch a candidate profile by slug, including both active and inactive rows.
 *
 * Uses supabaseAdmin to bypass RLS — the "public read active" policy would hide
 * inactive (demoted) candidates, but slug pages must still render with a
 * demotion notice.
 *
 * Returns null if:
 * - No row exists for the slug
 * - Row exists but deleted_at IS NOT NULL (soft-deleted account)
 *
 * Cache TTL: 900s (15 min). Route handlers should invalidate on demotion.
 */
export async function getCandidateBySlug(slug: string): Promise<CandidateProfile | null> {
  const cacheKey = `candidate:slug:${slug}`;

  // Cache check
  const cached = await cache.get<CandidateProfile>(cacheKey);
  if (cached !== null) return cached;

  // Fetch empowered_profiles row — explicit column list, NEVER *
  // NOTE: representing_city, district columns, government_name, chamber_name are not
  // yet in the live empowered_profiles schema — excluded until migration is applied.
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select('user_id, legal_name, candidate_page_slug, is_active, empowered_at, demoted_at')
    .eq('candidate_page_slug', slug)
    .is('deleted_at', null)
    .maybeSingle();

  if (error) throw new Error(error.message);
  if (!data) return null;

  // The compass lives on inform.inform_profiles as of migration 1850, not on the
  // Connected-tier profile. Reading the old column here would silently return []
  // for any Inform-tier candidate — and for everyone else once it is dropped.
  const selectedTopicIds: string[] = await getSelectedTopics(data.user_id);

  // Fetch public compass answers for selected topics
  let featuredStances: Array<{ topic_id: string; value: number; write_in_text?: string }> = [];

  if (selectedTopicIds.length > 0) {
    const { data: answersData } = await supabaseAdmin
      .schema('inform')
      .from('compass_responses')
      .select('topic_id, value, write_in_text')
      .eq('user_id', data.user_id)
      .in('topic_id', selectedTopicIds)
      .eq('visibility', 'public');

    if (answersData && answersData.length > 0) {
      featuredStances = answersData.map((row) => {
        const stance: { topic_id: string; value: number; write_in_text?: string } = {
          topic_id: row.topic_id as string,
          value: row.value as number,
        };
        if (row.write_in_text != null) {
          stance.write_in_text = row.write_in_text as string;
        }
        return stance;
      });
    }
  }

  // Build response from explicit whitelist — NEVER spread data
  const names = splitLegalName(data.legal_name as string);

  const profile: CandidateProfile = {
    candidate_page_slug: data.candidate_page_slug as string,
    first_name: names.first_name,
    last_name: names.last_name,
    active: data.is_active as boolean,
    demoted_at: (data.demoted_at as string | null) ?? null,
    empowered_at: data.empowered_at as string,
    images: [],
    featured_stances: featuredStances,
  };

  await cache.set(cacheKey, profile, 900);
  return profile;
}

// ---------------------------------------------------------------------------
// getCandidateAnswers
// ---------------------------------------------------------------------------

/**
 * Fetch a candidate's public compass answers for a given set of topic IDs,
 * applying caller-specified inversion.
 *
 * NOT cached — the invertedTopicIds parameter is caller-specific and would
 * require per-caller cache keys, negating the cache benefit.
 *
 * Inversion formula: invertedValue = 6 - value (maps 1<>5, 2<>4, 3=3).
 * Applied only when the topic_id is in the invertedTopicIds set.
 *
 * Returns null if no candidate with that slug exists (or is soft-deleted).
 * Returns [] if the candidate exists but has no matching public answers.
 */
export async function getCandidateAnswers(
  slug: string,
  topicIds: string[],
  invertedTopicIds: Set<string>
): Promise<CandidateAnswer[] | null> {
  // Look up user_id by slug (supabaseAdmin bypasses RLS for inactive rows)
  const { data: profileData, error: profileError } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select('user_id')
    .eq('candidate_page_slug', slug)
    .is('deleted_at', null)
    .maybeSingle();

  if (profileError) throw new Error(profileError.message);
  if (!profileData) return null;

  const userId = profileData.user_id as string;

  // Fetch public compass answers for the requested topic IDs
  const { data: answersData, error: answersError } = await supabaseAdmin
    .schema('inform')
    .from('compass_responses')
    .select('topic_id, value, write_in_text')
    .eq('user_id', userId)
    .in('topic_id', topicIds)
    .eq('visibility', 'public');

  if (answersError) throw new Error(answersError.message);
  if (!answersData || answersData.length === 0) return [];

  // Build answer objects with inversion applied — explicit whitelist
  return answersData.map((row) => {
    const topicId = row.topic_id as string;
    let value = row.value as number;

    // Apply inversion: 6 - value (1<>5, 2<>4, 3=3)
    if (invertedTopicIds.has(topicId)) {
      value = 6 - value;
    }

    const answer: CandidateAnswer = { topic_id: topicId, value };
    if (row.write_in_text != null) {
      answer.write_in_text = row.write_in_text as string;
    }
    return answer;
  });
}

