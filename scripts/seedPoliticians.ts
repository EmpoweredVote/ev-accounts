/**
 * seedPoliticians.ts — Legacy seed script for politician data.
 *
 * NOTE: After Phase 35 deduplication, essentials.politicians is the unified
 * source of truth with 1,854 real politicians already seeded from EV-Backend.
 * This script is preserved for reference but should NOT be run against
 * production — it would insert placeholder records into essentials.politicians.
 *
 * Originally populated inform.politicians with known records for Alpha coverage:
 *   - Bloomington, Indiana (congressional, state senate, state house)
 *   - Los Angeles, California (county only — Alpha scope)
 *
 * Prerequisites:
 *   - Phase 35 complete (essentials.politicians is the unified table)
 *   - SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY set in environment
 *
 * Usage (local/dev only — do NOT run against production):
 *   npx tsx scripts/seedPoliticians.ts
 */

import { createClient } from '@supabase/supabase-js';

// ---------------------------------------------------------------------------
// Environment setup — validate required vars before proceeding
// ---------------------------------------------------------------------------

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('[seedPoliticians] ERROR: Missing required environment variables.');
  console.error('  Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// ---------------------------------------------------------------------------
// Seed data — politician district records for known Alpha coverage areas
// ---------------------------------------------------------------------------

/**
 * Each record must have first_name + last_name at minimum.
 * full_name in essentials.politicians is a regular column (NOT GENERATED) —
 * include it explicitly. is_active and is_incumbent are set for all records.
 *
 * Note: essentials.politicians does not have district_type, district_id,
 * office_title, chamber_name, representing_city, etc. — those were inform-
 * specific columns. Essentials uses party, is_incumbent, slug, bio_text.
 */
const seedRecords = [
  // -----------------------------------------------------------------------
  // Bloomington, Indiana — Indiana 9th Congressional District
  // -----------------------------------------------------------------------
  {
    first_name: 'Indiana',
    last_name: '9th Congressional District Rep',
    full_name: 'Indiana 9th Congressional District Rep',
    preferred_name: null as string | null,
    photo_origin_url: null as string | null,
    party: null as string | null,
    party_short_name: null as string | null,
    slug: null as string | null,
    bio_text: null as string | null,
    is_active: true,
    is_vacant: false,
    is_incumbent: true,
  },
  // -----------------------------------------------------------------------
  // Bloomington, Indiana — Indiana Senate District 40
  // -----------------------------------------------------------------------
  {
    first_name: 'Indiana',
    last_name: 'Senate District 40 Senator',
    full_name: 'Indiana Senate District 40 Senator',
    preferred_name: null as string | null,
    photo_origin_url: null as string | null,
    party: null as string | null,
    party_short_name: null as string | null,
    slug: null as string | null,
    bio_text: null as string | null,
    is_active: true,
    is_vacant: false,
    is_incumbent: true,
  },
  // -----------------------------------------------------------------------
  // Bloomington, Indiana — Indiana House District 60
  // -----------------------------------------------------------------------
  {
    first_name: 'Indiana',
    last_name: 'House District 60 Representative',
    full_name: 'Indiana House District 60 Representative',
    preferred_name: null as string | null,
    photo_origin_url: null as string | null,
    party: null as string | null,
    party_short_name: null as string | null,
    slug: null as string | null,
    bio_text: null as string | null,
    is_active: true,
    is_vacant: false,
    is_incumbent: true,
  },
  // -----------------------------------------------------------------------
  // Los Angeles, California — LA County (county-level only per Alpha scope)
  // -----------------------------------------------------------------------
  {
    first_name: 'Los Angeles',
    last_name: 'County Representative',
    full_name: 'Los Angeles County Representative',
    preferred_name: null as string | null,
    photo_origin_url: null as string | null,
    party: null as string | null,
    party_short_name: null as string | null,
    slug: null as string | null,
    bio_text: null as string | null,
    is_active: true,
    is_vacant: false,
    is_incumbent: true,
  },
];

// ---------------------------------------------------------------------------
// Seed execution
// ---------------------------------------------------------------------------

async function main() {
  console.log('[seedPoliticians] Starting politician seed...');
  console.log(`[seedPoliticians] Records to upsert: ${seedRecords.length}`);

  const { data, error } = await supabase
    .schema('essentials')
    .from('politicians')
    .insert(seedRecords)
    .select('id, full_name, party, is_incumbent');

  if (error) {
    console.error('[seedPoliticians] ERROR during insert:', error.message);
    console.error('[seedPoliticians] Details:', error);
    process.exit(1);
  }

  console.log('[seedPoliticians] Insert complete. Records written:');
  for (const row of data ?? []) {
    console.log(
      `  - [${row.party ?? 'no-party'}] ${row.full_name ?? row.id} (incumbent: ${row.is_incumbent})`
    );
  }

  console.log('[seedPoliticians] Done.');
  process.exit(0);
}

main().catch((err: unknown) => {
  console.error('[seedPoliticians] Unexpected error:', err);
  process.exit(1);
});
