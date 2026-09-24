/**
 * seed-la-county-netfile-officials.ts
 *
 * Idempotent seed of politician_sources rows for the 4 LA County officials
 * confirmed to be in the Netfile LACO database (quick-025/026 discovery).
 *
 * Officials seeded:
 *   - Holly Mitchell (D2): officeholder committee filerId=216787458 (confirmed)
 *   - Lindsey Horvath (D3): campaign committee filerId=216785710 (confirmed)
 *   - Robert Luna (Sheriff): two committees — filerIds resolved via QuickNameSearch
 *   - Jeffrey Prang (Assessor): two committees — filerIds resolved via QuickNameSearch
 *
 * For "TBD" filerIds, hits QuickNameSearch?aid=LACO&query=<name> and matches
 * by committee label substring (case-insensitive). Skips if no match found.
 *
 * Run: cd C:/EV-Accounts/backend && npx tsx scripts/seed-la-county-netfile-officials.ts
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// ---------------------------------------------------------------------------
// Officials list
// ---------------------------------------------------------------------------

interface Committee {
  filerId: string;      // 'TBD-...' means resolve via QuickNameSearch
  label: string;        // Used for notes + name matching
  searchQuery?: string; // Query for QuickNameSearch if filerId is TBD
}

interface Official {
  name: string;       // Matches essentials.politicians.full_name
  district: string;   // Human-readable location for notes
  committees: Committee[];
}

const OFFICIALS: Official[] = [
  {
    // DB full_name is "Holly J. Mitchell"
    name: 'Holly J. Mitchell',
    district: 'LA County Board of Supervisors District 2',
    committees: [
      {
        filerId: '216787458',
        label: 'Supervisor Holly J. Mitchell Officeholder 2020',
      },
    ],
  },
  {
    // DB full_name is "Lindsey P. Horvath"
    name: 'Lindsey P. Horvath',
    district: 'LA County Board of Supervisors District 3',
    committees: [
      {
        filerId: '216785710',
        label: 'Lindsey Horvath for Supervisor 2026',
      },
    ],
  },
  {
    name: 'Robert Luna',
    district: 'LA County Sheriff',
    committees: [
      {
        filerId: 'TBD',
        label: 'Luna for Sheriff 2022',
        searchQuery: 'Luna',
      },
      {
        filerId: 'TBD',
        label: 'Luna for Sheriff 2026',
        searchQuery: 'Luna',
      },
    ],
  },
  {
    // DB full_name is "Jeff Prang"
    name: 'Jeff Prang',
    district: 'LA County Assessor',
    committees: [
      {
        filerId: 'TBD',
        label: 'Jeffrey Prang For Assessor 2022',
        searchQuery: 'Prang',
      },
      {
        filerId: 'TBD',
        label: 'Jeffrey Prang for Assessor 2026',
        searchQuery: 'Prang',
      },
    ],
  },
];

// ---------------------------------------------------------------------------
// Netfile QuickNameSearch
// ---------------------------------------------------------------------------

interface QuickNameCommittee {
  id: string;
  name: string;
}

interface QuickNameResponse {
  committees: QuickNameCommittee[];
}

async function resolveFilerId(label: string, searchQuery: string): Promise<string | null> {
  const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=LACO&query=${encodeURIComponent(searchQuery)}`;

  console.log(`[seed] QuickNameSearch: query="${searchQuery}" for label="${label}"`);

  let resp: Response;
  try {
    resp = await fetch(url, {
      headers: {
        Accept: 'application/json',
        'User-Agent': 'EV-CampaignFinance/1.0 (+https://empowered.vote)',
      },
    });
  } catch (err) {
    console.warn(`[seed] QuickNameSearch network error: ${err instanceof Error ? err.message : String(err)}`);
    return null;
  }

  if (!resp.ok) {
    console.warn(`[seed] QuickNameSearch HTTP ${resp.status} for query="${searchQuery}"`);
    return null;
  }

  const data = (await resp.json()) as QuickNameResponse;
  const committees = data.committees ?? [];

  // Find committee whose name contains the label (case-insensitive substring match).
  // The label may differ slightly from the API name, so use liberal matching:
  // check if label words appear in committee name or vice versa.
  const labelLower = label.toLowerCase();

  // First try: exact substring match
  let match = committees.find((c) => c.name.toLowerCase().includes(labelLower));

  if (!match) {
    // Second try: match key words from the label in the committee name
    const labelWords = labelLower.replace(/[^a-z0-9\s]/g, '').split(/\s+/).filter((w) => w.length > 3);
    match = committees.find((c) => {
      const nameLower = c.name.toLowerCase();
      return labelWords.every((w) => nameLower.includes(w));
    });
  }

  if (!match) {
    console.warn(
      `[seed] No Netfile committee matched label="${label}" from ${committees.length} results: ` +
        committees.map((c) => `"${c.name}"`).join(', ')
    );
    return null;
  }

  console.log(`[seed] Resolved: label="${label}" → filerId=${match.id} name="${match.name}"`);
  return match.id;
}

// ---------------------------------------------------------------------------
// Politician lookup
// ---------------------------------------------------------------------------

async function lookupPoliticianId(fullName: string): Promise<string | null> {
  const result = await pool.query<{ id: string }>(
    `SELECT id FROM essentials.politicians
     WHERE LOWER(full_name) = LOWER($1) AND is_active = true
     LIMIT 2`,
    [fullName]
  );

  if (result.rows.length === 0) {
    console.warn(`[seed] Politician not found: "${fullName}" — skipping`);
    return null;
  }

  if (result.rows.length > 1) {
    const ids = result.rows.map((r) => r.id).join(', ');
    console.warn(`[seed] Multiple politicians match "${fullName}": ${ids} — skipping (requires operator disambiguation)`);
    return null;
  }

  return result.rows[0].id;
}

// ---------------------------------------------------------------------------
// Upsert politician_sources row
// ---------------------------------------------------------------------------

async function upsertSource(
  politicianId: string,
  filerId: string,
  notes: string
): Promise<string | null> {
  // The unique constraint on politician_sources is (essentials_politician_id, source_system, external_id).
  const result = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes, netfile_agency, created_at, updated_at)
     VALUES ($1, 'la_county_netfile', $2, 'confirmed', $3, 'LACO', NOW(), NOW())
     ON CONFLICT (essentials_politician_id, source_system, external_id)
       DO UPDATE SET
         research_status = 'confirmed',
         notes           = EXCLUDED.notes,
         netfile_agency  = EXCLUDED.netfile_agency,
         updated_at      = NOW()
     RETURNING id`,
    [politicianId, filerId, notes]
  );

  return result.rows[0]?.id ?? null;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

interface SeedResult {
  name: string;
  committeesAttempted: number;
  committeesSeeded: number;
  politicianUuid: string;
}

async function main(): Promise<void> {
  console.log('[seed] Starting seed-la-county-netfile-officials...\n');

  const summary: SeedResult[] = [];

  for (const official of OFFICIALS) {
    console.log(`\n[seed] === ${official.name} (${official.district}) ===`);

    // 1. Look up politician UUID
    const politicianId = await lookupPoliticianId(official.name);
    if (!politicianId) {
      summary.push({
        name: official.name,
        committeesAttempted: official.committees.length,
        committeesSeeded: 0,
        politicianUuid: 'NOT FOUND',
      });
      continue;
    }

    console.log(`[seed] Politician UUID: ${politicianId}`);

    let seeded = 0;

    for (const committee of official.committees) {
      // 2. Resolve TBD filerIds via QuickNameSearch
      let filerId = committee.filerId;

      if (filerId.startsWith('TBD') && committee.searchQuery) {
        const resolved = await resolveFilerId(committee.label, committee.searchQuery);
        if (!resolved) {
          console.warn(`[seed] Could not resolve filerId for "${committee.label}" — skipping`);
          continue;
        }
        filerId = resolved;
      }

      // 3. Upsert politician_sources row
      const psId = await upsertSource(
        politicianId,
        filerId,
        `${official.district} — ${committee.label}`
      );

      if (psId) {
        console.log(
          `[seed] ${official.name} → filerId=${filerId} ps_id=${psId} (${committee.label})`
        );
        seeded++;
      } else {
        console.warn(`[seed] Upsert returned no ID for ${official.name} filerId=${filerId}`);
      }
    }

    summary.push({
      name: official.name,
      committeesAttempted: official.committees.length,
      committeesSeeded: seeded,
      politicianUuid: politicianId,
    });
  }

  // Print summary table
  console.log('\n[seed] ══════════════════════════════════════════════════════');
  console.log('[seed] SUMMARY');
  console.log('[seed] ══════════════════════════════════════════════════════');
  console.log(
    '[seed] Name                  | Attempted | Seeded | UUID'
  );
  console.log('[seed] ─────────────────────────────────────────────────────');
  for (const r of summary) {
    const name = r.name.padEnd(22);
    const att = String(r.committeesAttempted).padEnd(9);
    const sed = String(r.committeesSeeded).padEnd(6);
    console.log(`[seed] ${name} | ${att} | ${sed} | ${r.politicianUuid}`);
  }
  console.log('[seed] ══════════════════════════════════════════════════════\n');
}

main()
  .catch((err) => {
    console.error('[seed] FATAL:', err instanceof Error ? err.message : String(err));
    process.exitCode = 1;
  })
  .finally(() => pool.end());
