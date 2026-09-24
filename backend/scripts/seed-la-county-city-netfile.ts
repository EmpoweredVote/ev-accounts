/**
 * seed-la-county-city-netfile.ts
 *
 * Phase 109 Wave 2 — LAFI-02
 *
 * Probes Netfile QuickNameSearch for each of the 26 non-LA-City LA County
 * municipalities seeded in Phase 108. For each city, tests agency code LACO
 * (and any city-specific code guess) against a well-known official. If the
 * probe returns committees, discovers all Phase 108 officials in that city and
 * seeds confirmed la_county_netfile politician_sources rows. Zero-hit cities
 * are documented as "no-data" gaps.
 *
 * After seeding, triggers runAdapterForAll('la_county_netfile') to ingest
 * contributions from Netfile into transparent_motivations.contributions.
 *
 * Run (dry-run, no DB writes):
 *   cd C:/EV-Accounts/backend && npx tsx scripts/seed-la-county-city-netfile.ts --dry-run
 *
 * Run (live):
 *   cd C:/EV-Accounts/backend && npx tsx scripts/seed-la-county-city-netfile.ts
 *
 * NEVER uses the WebForms bulk Excel approach (broken as of 2026-04-15).
 * Only uses the REST QuickNameSearch endpoint.
 * NEVER triggers ingest via HTTP POST — uses runAdapterForAll() directly.
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------

const isDryRun = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Committee {
  filerId: string;      // 'TBD-...' means resolve via QuickNameSearch
  label: string;        // Used for notes + name matching
  searchQuery?: string; // Query for QuickNameSearch if filerId is TBD
  agencyCode?: string;  // Per-city agency code override (default: 'LACO')
}

interface Official {
  name: string;          // Matches essentials.politicians.full_name
  district: string;      // Human-readable location for notes
  committees: Committee[];
  skipFinance?: boolean;  // For appointed officials with no campaign committee
  skipReason?: string;
}

interface CityConfig {
  name: string;                    // Matches essentials.governments.name
  fips: string;                    // FIPS geo_id for reference
  preferredAgencyCodes: string[];  // Agency codes to try in order
}

// ---------------------------------------------------------------------------
// 26 non-LA-City LA County municipalities (from verify-la-county-108.sql)
// ---------------------------------------------------------------------------

const CITIES: CityConfig[] = [
  // Cities with ", California, US" suffix in essentials.governments.name
  { name: 'City of Long Beach, California, US',    fips: '0643000', preferredAgencyCodes: ['LACO', 'LONGBCH', 'LB'] },
  { name: 'City of Glendale, California, US',      fips: '0630000', preferredAgencyCodes: ['LACO', 'GLNDL', 'GLENDALE'] },
  { name: 'City of Burbank, California, US',       fips: '0608954', preferredAgencyCodes: ['LACO', 'BURBK', 'BURBANK'] },
  { name: 'City of Downey, California, US',        fips: '0619766', preferredAgencyCodes: ['LACO', 'DOWNEY'] },
  { name: 'City of El Monte, California, US',      fips: '0622230', preferredAgencyCodes: ['LACO', 'ELMNTE', 'ELMONTE'] },
  { name: 'City of Inglewood, California, US',     fips: '0636546', preferredAgencyCodes: ['LACO', 'INGLWD', 'INGLEWOOD'] },
  { name: 'City of Lancaster, California, US',     fips: '0640130', preferredAgencyCodes: ['LACO', 'LNCSTR', 'LANCASTER'] },
  { name: 'City of Norwalk, California, US',       fips: '0652526', preferredAgencyCodes: ['LACO', 'NORWLK', 'NORWALK'] },
  { name: 'City of Palmdale, California, US',      fips: '0655156', preferredAgencyCodes: ['LACO', 'PLMDL', 'PALMDALE'] },
  { name: 'City of Pasadena, California, US',      fips: '0656000', preferredAgencyCodes: ['LACO', 'PASDN', 'PASADENA'] },
  { name: 'City of Pomona, California, US',        fips: '0658072', preferredAgencyCodes: ['LACO', 'POMONA'] },
  { name: 'City of Santa Clarita, California, US', fips: '0669088', preferredAgencyCodes: ['LACO', 'SCLAR', 'SANTACLARITA'] },
  { name: 'City of Torrance, California, US',      fips: '0680000', preferredAgencyCodes: ['LACO', 'TORR', 'TORRANCE'] },
  { name: 'City of West Covina, California, US',   fips: '0684200', preferredAgencyCodes: ['LACO', 'WSTCOV', 'WESTCOVINA'] },
  { name: 'City of Beverly Hills, California, US', fips: '0606308', preferredAgencyCodes: ['LACO', 'BHILLS', 'BVRLHLS'] },
  { name: 'City of Santa Monica, California, US',  fips: '0670000', preferredAgencyCodes: ['LACO', 'SMONICA', 'SANTAMONICA', 'SM'] },
  // Cities without suffix in essentials.governments.name
  { name: 'City of South Gate',    fips: '0673080', preferredAgencyCodes: ['LACO', 'SGATE', 'SOUTHGATE'] },
  { name: 'City of Compton',       fips: '0615044', preferredAgencyCodes: ['LACO', 'COMPTON'] },
  { name: 'City of Carson',        fips: '0611530', preferredAgencyCodes: ['LACO', 'CARSON'] },
  { name: 'City of Hawthorne',     fips: '0632548', preferredAgencyCodes: ['LACO', 'HAWTH', 'HAWTHORNE'] },
  { name: 'City of Whittier',      fips: '0685292', preferredAgencyCodes: ['LACO', 'WHITT', 'WHITTIER'] },
  { name: 'City of Alhambra',      fips: '0600884', preferredAgencyCodes: ['LACO', 'ALHMBR', 'ALHAMBRA'] },
  { name: 'City of Gardena',       fips: '0628168', preferredAgencyCodes: ['LACO', 'GARDN', 'GARDENA'] },
  { name: 'City of Culver City',   fips: '0617568', preferredAgencyCodes: ['LACO', 'CULVER', 'CULVERCITY'] },
  { name: 'City of West Hollywood',fips: '0684410', preferredAgencyCodes: ['LACO', 'WESTHWD', 'WESTHOLLYWOOD', 'WEHO'] },
  { name: 'City of El Segundo',    fips: '0622412', preferredAgencyCodes: ['LACO', 'ELSEG', 'ELSEGUNDO'] },
];

// ---------------------------------------------------------------------------
// Netfile QuickNameSearch types
// ---------------------------------------------------------------------------

interface QuickNameCommittee {
  id: string;
  name: string;
}

interface QuickNameResponse {
  committees: QuickNameCommittee[];
}

// ---------------------------------------------------------------------------
// probeAgencyCode — test whether agency code has committees for a search name
// ---------------------------------------------------------------------------

async function probeAgencyCode(agencyCode: string, searchName: string): Promise<boolean> {
  const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=${agencyCode}&query=${encodeURIComponent(searchName)}`;

  let resp: Response;
  try {
    resp = await fetch(url, {
      headers: {
        Accept: 'application/json',
        'User-Agent': 'EV-CampaignFinance/1.0 (+https://empowered.vote)',
      },
    });
  } catch (err) {
    console.warn(`[seed] probeAgencyCode: network error (aid=${agencyCode} query="${searchName}"): ${err instanceof Error ? err.message : String(err)}`);
    return false;
  }

  if (!resp.ok) {
    console.warn(`[seed] probeAgencyCode: HTTP ${resp.status} (aid=${agencyCode} query="${searchName}")`);
    return false;
  }

  const data = (await resp.json()) as QuickNameResponse;
  return (data.committees?.length ?? 0) > 0;
}

// ---------------------------------------------------------------------------
// resolveFilerId — QuickNameSearch for a specific official, with agency code param
// ---------------------------------------------------------------------------

async function resolveFilerId(
  label: string,
  searchQuery: string,
  agencyCode: string = 'LACO'
): Promise<string | null> {
  const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=${agencyCode}&query=${encodeURIComponent(searchQuery)}`;

  console.log(`[seed] QuickNameSearch: aid=${agencyCode} query="${searchQuery}" for label="${label}"`);

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

  if (committees.length === 0) {
    console.log(`[seed] QuickNameSearch: no results for aid=${agencyCode} query="${searchQuery}"`);
    return null;
  }

  // First try: exact substring match
  const labelLower = label.toLowerCase();
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
    // Third try: check if search query words appear in any committee name
    const queryWords = searchQuery.toLowerCase().replace(/[^a-z0-9\s]/g, '').split(/\s+/).filter((w) => w.length > 3);
    match = committees.find((c) => {
      const nameLower = c.name.toLowerCase();
      return queryWords.some((w) => nameLower.includes(w));
    });
  }

  if (!match) {
    console.warn(
      `[seed] No Netfile committee matched label="${label}" from ${committees.length} results: ` +
      committees.slice(0, 5).map((c) => `"${c.name}"`).join(', ')
    );
    return null;
  }

  console.log(`[seed] Resolved: label="${label}" → filerId=${match.id} name="${match.name}"`);
  return match.id;
}

// ---------------------------------------------------------------------------
// lookupPoliticianId — case-insensitive full_name match
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
    console.warn(`[seed] Multiple politicians match "${fullName}": ${ids} — skipping (requires disambiguation)`);
    return null;
  }

  return result.rows[0].id;
}

// ---------------------------------------------------------------------------
// upsertSource — insert or update confirmed la_county_netfile source row
// ---------------------------------------------------------------------------

async function upsertSource(
  politicianId: string,
  filerId: string,
  notes: string,
  agencyCode: string
): Promise<string | null> {
  // netfile_agency is what the adapter reads (CA_0224). The "agency=" in notes is for humans:
  // the 2026-06-09 run wrote only that, and the adapter read the WEHO links under LACO.
  const result = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes, netfile_agency, created_at, updated_at)
     VALUES ($1, 'la_county_netfile', $2, 'confirmed', $3, $4, NOW(), NOW())
     ON CONFLICT (essentials_politician_id, source_system, external_id)
       DO UPDATE SET
         research_status = 'confirmed',
         notes           = EXCLUDED.notes,
         netfile_agency  = EXCLUDED.netfile_agency,
         updated_at      = NOW()
     RETURNING id`,
    [politicianId, filerId, notes, agencyCode]
  );

  return result.rows[0]?.id ?? null;
}

// ---------------------------------------------------------------------------
// getPhase108OfficialsByCity — query officials seeded in Phase 108 for a city
// ---------------------------------------------------------------------------

interface CityOfficial {
  id: string;
  full_name: string;
  office_title: string;
}

async function getPhase108OfficialsByCity(governmentName: string): Promise<CityOfficial[]> {
  const result = await pool.query<CityOfficial>(
    `SELECT p.id, p.full_name, o.title AS office_title
     FROM essentials.politicians p
     JOIN essentials.offices o ON o.id = p.office_id
     JOIN essentials.chambers ch ON ch.id = o.chamber_id
     JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.name = $1
       AND g.state = 'CA'
       AND p.is_active = true
     ORDER BY p.full_name`,
    [governmentName]
  );
  return result.rows;
}

// ---------------------------------------------------------------------------
// Per-city result tracking
// ---------------------------------------------------------------------------

interface CityResult {
  city: string;
  agencyCode: string | null;
  probeResult: 'hits' | 'no-data';
  officialsFound: number;
  officialsProbed: number;
  officialsSeeded: number;
  gapReason?: string;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('[seed-la-county-city-netfile] Starting...');
  console.log(`[seed-la-county-city-netfile] Mode: ${isDryRun ? 'DRY-RUN (no DB writes, no ingest)' : 'LIVE'}\n`);

  const cityResults: CityResult[] = [];
  let totalSeeded = 0;

  for (const city of CITIES) {
    console.log(`\n[seed] ═══ ${city.name} ═══`);

    // Step 1: Get officials for this city
    const officials = await getPhase108OfficialsByCity(city.name);
    console.log(`[seed] Found ${officials.length} Phase 108 officials in ${city.name}`);

    if (officials.length === 0) {
      console.warn(`[seed] No officials found for "${city.name}" — skipping probe`);
      cityResults.push({
        city: city.name,
        agencyCode: null,
        probeResult: 'no-data',
        officialsFound: 0,
        officialsProbed: 0,
        officialsSeeded: 0,
        gapReason: 'No officials found in DB for this city',
      });
      continue;
    }

    // Step 2: Probe agency codes using the first official's last name as search query
    const probeOfficial = officials[0];
    const probeName = probeOfficial.full_name.split(' ').slice(-1)[0] ?? probeOfficial.full_name;

    let usableAgencyCode: string | null = null;
    for (const code of city.preferredAgencyCodes) {
      console.log(`[seed] Probing agency code "${code}" for ${city.name} using query="${probeName}"...`);
      const hasHits = await probeAgencyCode(code, probeName);
      if (hasHits) {
        usableAgencyCode = code;
        console.log(`[seed] Agency code "${code}" has results for ${city.name}`);
        break;
      } else {
        console.log(`[seed] Agency code "${code}": no results for query="${probeName}"`);
      }
    }

    if (!usableAgencyCode) {
      console.log(`[seed] ${city.name}: no accessible Netfile agency code found — documenting as gap`);
      cityResults.push({
        city: city.name,
        agencyCode: null,
        probeResult: 'no-data',
        officialsFound: officials.length,
        officialsProbed: 0,
        officialsSeeded: 0,
        gapReason: 'No matching committees found under LACO or any city-specific agency code',
      });
      continue;
    }

    // Step 3: For each official, resolve filer ID and seed source row
    let probed = 0;
    let seeded = 0;

    for (const official of officials) {
      probed++;
      console.log(`\n[seed] --- ${official.full_name} (${official.office_title}) ---`);

      if (isDryRun) {
        console.log(`[seed] [DRY-RUN] Would probe QuickNameSearch for "${official.full_name}" with aid=${usableAgencyCode}`);
        continue;
      }

      // Resolve filer ID via QuickNameSearch
      const filerId = await resolveFilerId(
        official.full_name,
        official.full_name,
        usableAgencyCode
      );

      if (!filerId) {
        console.log(`[seed] No committee found for "${official.full_name}" in ${city.name} — skipping`);
        continue;
      }

      // Look up politician UUID
      const politicianId = await lookupPoliticianId(official.full_name);
      if (!politicianId) continue;

      // Upsert politician_sources row
      const notes = `${city.name} — ${official.office_title} — agency=${usableAgencyCode}`;
      const psId = await upsertSource(politicianId, filerId, notes, usableAgencyCode);

      if (psId) {
        console.log(`[seed] ${official.full_name} → filerId=${filerId} ps_id=${psId}`);
        seeded++;
        totalSeeded++;
      } else {
        console.warn(`[seed] Upsert returned no ID for ${official.full_name} filerId=${filerId}`);
      }
    }

    cityResults.push({
      city: city.name,
      agencyCode: usableAgencyCode,
      probeResult: 'hits',
      officialsFound: officials.length,
      officialsProbed: probed,
      officialsSeeded: isDryRun ? 0 : seeded,
      gapReason: undefined,
    });
  }

  // Step 4: Trigger adapter ingest (skip in dry-run)
  if (!isDryRun && totalSeeded > 0) {
    console.log(`\n[seed] ═══ Triggering runAdapterForAll('la_county_netfile')... ═══`);
    await runAdapterForAll('la_county_netfile');
    console.log('[seed] runAdapterForAll complete.');
  } else if (isDryRun) {
    console.log('\n[seed] [DRY-RUN] Would call runAdapterForAll("la_county_netfile") after seeding');
  } else {
    console.log('\n[seed] No new sources seeded — skipping runAdapterForAll (no-op would produce no new contributions)');
  }

  // Step 5: Print closing summary table
  console.log('\n[seed] ══════════════════════════════════════════════════════════════════════════');
  console.log('[seed] COVERAGE REPORT — Per-city Netfile assessment');
  console.log('[seed] ══════════════════════════════════════════════════════════════════════════');
  console.log('[seed] City                      | Agency Code | Probe    | Found | Seeded | Gap Reason');
  console.log('[seed] ─────────────────────────────────────────────────────────────────────────');

  for (const r of cityResults) {
    const city = r.city.replace('City of ', '').replace(', California, US', '').padEnd(26);
    const code = (r.agencyCode ?? 'none').padEnd(11);
    const probe = r.probeResult.padEnd(8);
    const found = String(r.officialsFound).padEnd(5);
    const seeded = String(r.officialsSeeded).padEnd(6);
    const gap = r.gapReason ?? '';
    console.log(`[seed] ${city} | ${code} | ${probe} | ${found} | ${seeded} | ${gap}`);
  }

  console.log('[seed] ══════════════════════════════════════════════════════════════════════════');

  const citiesWithHits = cityResults.filter((r) => r.probeResult === 'hits').length;
  const citiesWithGaps = cityResults.filter((r) => r.probeResult === 'no-data').length;
  const citiesWithSeeds = cityResults.filter((r) => r.officialsSeeded > 0).length;

  console.log(`\n[seed] Summary:`);
  console.log(`[seed]   Cities with accessible Netfile data: ${citiesWithHits}`);
  console.log(`[seed]   Cities with no accessible data (gaps): ${citiesWithGaps}`);
  console.log(`[seed]   Cities with seeded sources: ${citiesWithSeeds}`);
  console.log(`[seed]   Total source rows seeded this run: ${totalSeeded}`);
  console.log(`\n[seed] Done.`);
}

main()
  .catch((err) => {
    console.error('[seed-la-county-city-netfile] FATAL:', err instanceof Error ? err.message : String(err));
    process.exitCode = 1;
  })
  .finally(() => pool.end());
