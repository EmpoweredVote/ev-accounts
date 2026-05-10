/**
 * identify-legal-donors.ts — Top-15% legal-professional donor extractor.
 *
 * Queries transparent_motivations.contributions for LA legal candidates (City Attorney
 * candidates and judge challengers from migration 117). Filters to legal-professional
 * donors by occupation keyword, normalizes and deduplicates firm names, applies a
 * cumulative-dollar 15% threshold, then writes court-research-input.json.
 *
 * Usage:
 *   npx tsx scripts/identify-legal-donors.ts          # full extraction → court-research-input.json
 *   npx tsx scripts/identify-legal-donors.ts --probe  # probe only → per-candidate confirmed contribution counts
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { distance } from 'fastest-levenshtein';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const isProbe = process.argv.includes('--probe');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// =============================================================================
// LEGAL CANDIDATES — sourced from migration 117
// UUIDs verified against live DB (2026-05-09)
// =============================================================================

interface LegalCandidate {
  politician_id: string;
  candidate_name: string;
  is_city_attorney: boolean;
}

const LEGAL_CANDIDATES: LegalCandidate[] = [
  // City Attorney candidates (is_city_attorney = true)
  { politician_id: '3f90952e-7d1b-413d-a0e1-e319fb23fa05', candidate_name: 'Hydee Feldstein Soto', is_city_attorney: true },
  { politician_id: '0f6484bd-2fc1-4071-9648-d7b8a950d29c', candidate_name: 'Aida Ashouri',         is_city_attorney: true },
  { politician_id: '6cd2e87b-7366-429a-a049-990751bd647f', candidate_name: 'John McKinney',        is_city_attorney: true },
  { politician_id: '7157dd95-0f1b-4e05-bd4f-39317345b47c', candidate_name: 'Marissa Roy',          is_city_attorney: true },

  // Incumbent judges (already in DB before migration 117)
  { politician_id: 'fa932212-a2cf-4fa1-97ab-c6619e3db610', candidate_name: 'Robert S. Draper',  is_city_attorney: false },
  { politician_id: '1ce3f260-d267-4569-993b-47f8dd8b0842', candidate_name: 'David B. Walgren',  is_city_attorney: false },
  { politician_id: '53fd1ed7-b8f2-4c0b-a973-3592e4457472', candidate_name: 'Patrick Connolly',  is_city_attorney: false },

  // Office 2 challengers
  { politician_id: '917d6200-f048-4b7b-85f7-3a390abeecf2', candidate_name: 'Tal K. Valbuena',      is_city_attorney: false },

  // Office 14 challengers
  { politician_id: 'd06e70b3-b63a-477e-8b3d-8fb7e656f30e', candidate_name: 'Angie Christides',     is_city_attorney: false },
  { politician_id: 'b5e19b59-9085-48e6-8f14-864b9c94699d', candidate_name: 'Irene Lee',             is_city_attorney: false },

  // Office 64 challengers
  { politician_id: '78cd4ef7-5768-4cbd-bcde-dfefed15f325', candidate_name: 'Francisco Amador',     is_city_attorney: false },
  { politician_id: '861e2613-73ff-41a1-b938-e8f43dda52de', candidate_name: 'Maria Ghobadi',         is_city_attorney: false },
  { politician_id: '5926b32e-56b9-48a5-9de2-a17beb0101a7', candidate_name: 'Rhonda A. Haymon',      is_city_attorney: false },

  // Office 65 challengers
  { politician_id: '92e8db0a-71f7-4195-b092-0b3ae1ca1fe5', candidate_name: 'Justin Allen Clayton',  is_city_attorney: false },
  { politician_id: '17a0332f-38f4-485f-b4ea-9dc8d45e876c', candidate_name: 'Chellei G. Jimenez',    is_city_attorney: false },
  { politician_id: '4405b45a-2829-4cde-9b83-ef3f32e6a50e', candidate_name: 'Samuel Wolloch Krause', is_city_attorney: false },
  { politician_id: '7e3e123e-eaef-4fa1-a24c-8b5ab14f7b40', candidate_name: 'Anna Slotky Reitano',   is_city_attorney: false },

  // Office 66 challengers
  { politician_id: '0e091c54-e251-41e9-a7aa-1a87a69bc79e', candidate_name: 'Ben Forer',             is_city_attorney: false },
  { politician_id: 'fc0b3b3f-fefc-427f-851d-9a2b536d5724', candidate_name: 'Cheryl C. Turner',       is_city_attorney: false },

  // Office 81 challengers
  { politician_id: '51d9e940-a84e-4ce2-a370-7440225bac9b', candidate_name: 'Dan Kapelovitz',         is_city_attorney: false },

  // Office 87 challengers
  { politician_id: '9f40d56d-8e04-4ef9-8d26-bd5f3ca5fbeb', candidate_name: 'Anthony (A.J.) Bayne',  is_city_attorney: false },
  { politician_id: 'b60a7b50-a9e6-4262-834d-2577adc30762', candidate_name: 'David DeJute',           is_city_attorney: false },
  { politician_id: 'a9faefe0-318d-46f8-8ea3-722f24bad35e', candidate_name: 'Sharee Sanders Gordon',  is_city_attorney: false },

  // Office 116 challengers
  { politician_id: '839199d0-669b-45bc-aa8e-2ba63d960b7b', candidate_name: 'Paul A. Thompson',       is_city_attorney: false },

  // Office 131 challengers
  { politician_id: 'fb040054-4099-40e8-ae98-a8e1b6680ab1', candidate_name: 'Carlos Dammeier',        is_city_attorney: false },
  { politician_id: '475d512a-6737-460d-8634-03b86712d594', candidate_name: 'David Ross',              is_city_attorney: false },
  { politician_id: 'e66de256-31e6-45a3-b3a8-a01ade5b79ec', candidate_name: 'Troy W. Slaten',          is_city_attorney: false },
  { politician_id: '7f32a8a4-fac8-44d3-af71-01f40895f5ba', candidate_name: 'Donna Tryfman',           is_city_attorney: false },

  // Office 176 challengers
  { politician_id: '995875ef-93a2-47a6-9522-730420239ffa', candidate_name: 'Gloria Marin',            is_city_attorney: false },
  { politician_id: '47627948-d590-47a4-9c7f-dd135043035f', candidate_name: 'Zachary Smith',           is_city_attorney: false },

  // Office 181 challengers
  { politician_id: '680a9dff-74b4-41de-a0fc-df30d83cbf49', candidate_name: 'Ryan Dibble',             is_city_attorney: false },
  { politician_id: 'fd669a19-1069-4c30-892d-78ff47a70324', candidate_name: 'Thanayi Lindsey',         is_city_attorney: false },
];

// =============================================================================
// LEGAL OCCUPATION KEYWORDS (case-insensitive substring match)
// NOTE: "associate" excluded — too many non-legal collisions in LA Socrata data
// =============================================================================

const LEGAL_OCCUPATION_KEYWORDS = [
  'attorney',
  'lawyer',
  'counsel',
  'partner',
  'esquire',
  'esq',
  'solicitor',
  'litigator',
  'paralegal',
  'public defender',
  'district attorney',
  'prosecutor',
];

// =============================================================================
// FIRM NAME NORMALIZATION
// =============================================================================

function normalizeFirmName(raw: string): string {
  return raw
    .toLowerCase()
    // Strip legal suffixes
    .replace(/\b(llp|lp|llc|inc|corp|pc|apc|pllc|ltd|p\.c\.|a\.p\.c\.)\b\.?/g, '')
    // Replace & and , with space
    .replace(/[&,]/g, ' ')
    // Collapse whitespace and trim
    .replace(/\s+/g, ' ')
    .trim();
}

// =============================================================================
// PROBE MODE — verify confirmed contribution coverage
// =============================================================================

async function runProbe(): Promise<void> {
  console.log('[identify-legal-donors] PROBE MODE\n');
  console.log(`Checking ${LEGAL_CANDIDATES.length} candidates from migration 117...\n`);

  const allIds = LEGAL_CANDIDATES.map(c => c.politician_id);

  const result = await pool.query<{ essentials_politician_id: string; contrib_count: string }>(`
    SELECT ps.essentials_politician_id, COUNT(*) AS contrib_count
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
    WHERE ps.research_status = 'confirmed'
      AND ps.essentials_politician_id = ANY($1::uuid[])
    GROUP BY 1
  `, [allIds]);

  const countMap = new Map<string, number>();
  for (const row of result.rows) {
    countMap.set(row.essentials_politician_id, parseInt(row.contrib_count, 10));
  }

  let withData = 0;
  let skipped = 0;

  for (const candidate of LEGAL_CANDIDATES) {
    const count = countMap.get(candidate.politician_id) ?? 0;
    const type = candidate.is_city_attorney ? '[CA]  ' : '[judge]';
    if (count > 0) {
      console.log(`  ${type} ${candidate.candidate_name.padEnd(30)} contrib_count=${count}`);
      withData++;
    } else {
      console.log(`  ${type} ${candidate.candidate_name.padEnd(30)} skipped: no confirmed contributions`);
      skipped++;
    }
  }

  console.log(`\nSummary: ${withData} with data, ${skipped} skipped.`);
  await pool.end();
}

// =============================================================================
// EXTRACTION HELPERS
// =============================================================================

function isLegalOccupation(occupation: string): boolean {
  const occ = occupation.toLowerCase();
  return LEGAL_OCCUPATION_KEYWORDS.some(kw => occ.includes(kw));
}

interface FirmEntry {
  firm_name: string;
  raw_firm_name: string;
  total_donated: number;
  donor_count: number;
  occupations_seen: string[];
  is_fuzzy_match: boolean;
  needs_review: boolean;
}

interface CandidateOutput {
  politician_id: string;
  candidate_name: string;
  is_city_attorney: boolean;
  grand_total: number;
  threshold_cutoff: number;
  firms: FirmEntry[];
}

// =============================================================================
// MAIN EXTRACTION
// =============================================================================

async function runExtraction(): Promise<void> {
  console.log('[identify-legal-donors] EXTRACTION MODE\n');

  // Step 1: Get candidates with confirmed contribution data
  const allIds = LEGAL_CANDIDATES.map(c => c.politician_id);
  const coverageResult = await pool.query<{ essentials_politician_id: string; contrib_count: string }>(`
    SELECT ps.essentials_politician_id, COUNT(*) AS contrib_count
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
    WHERE ps.research_status = 'confirmed'
      AND ps.essentials_politician_id = ANY($1::uuid[])
    GROUP BY 1
  `, [allIds]);

  const countMap = new Map<string, number>();
  for (const row of coverageResult.rows) {
    countMap.set(row.essentials_politician_id, parseInt(row.contrib_count, 10));
  }

  const activeCandidates = LEGAL_CANDIDATES.filter(c => (countMap.get(c.politician_id) ?? 0) > 0);
  const skipped = LEGAL_CANDIDATES.filter(c => (countMap.get(c.politician_id) ?? 0) === 0);

  console.log(`Candidates with confirmed data: ${activeCandidates.length}`);
  for (const s of skipped) {
    console.log(`  skipped: no confirmed contributions — ${s.candidate_name}`);
  }
  console.log('');

  const output: CandidateOutput[] = [];

  for (const candidate of LEGAL_CANDIDATES) {
    const hasData = (countMap.get(candidate.politician_id) ?? 0) > 0;

    // Step 2: Query grand_total across ALL confirmed contributions
    const grandTotalResult = await pool.query<{ grand_total: string }>(`
      SELECT COALESCE(SUM(c.amount), 0) AS grand_total
      FROM transparent_motivations.contributions c
      JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
      WHERE ps.research_status = 'confirmed'
        AND ps.essentials_politician_id = $1::uuid
    `, [candidate.politician_id]);

    const grand_total = parseFloat(grandTotalResult.rows[0]?.grand_total ?? '0');
    const threshold_cutoff = grand_total * 0.15;

    if (!hasData) {
      // Include with empty firms list (honest output)
      output.push({
        politician_id: candidate.politician_id,
        candidate_name: candidate.candidate_name,
        is_city_attorney: candidate.is_city_attorney,
        grand_total: 0,
        threshold_cutoff: 0,
        firms: [],
      });
      continue;
    }

    // Step 3: Query contributions with legal occupation filter
    const contribResult = await pool.query<{
      donor_name: string;
      employer: string;
      occupation: string;
      amount: string;
    }>(`
      SELECT
        COALESCE(c.raw_record->>'contributor_name', c.raw_record->>'con_name', c.donor_name_normalized) AS donor_name,
        COALESCE(c.raw_record->>'contributor_employer', c.raw_record->>'con_empr', '')                  AS employer,
        COALESCE(c.raw_record->>'contributor_occupation', c.raw_record->>'con_occp', '')                AS occupation,
        c.amount
      FROM transparent_motivations.contributions c
      JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
      WHERE ps.research_status = 'confirmed'
        AND ps.essentials_politician_id = $1::uuid
    `, [candidate.politician_id]);

    // Check for "associate" volume (log but exclude)
    const associateCount = contribResult.rows.filter(r => {
      const occ = (r.occupation ?? '').toLowerCase();
      return occ.includes('associate') && !isLegalOccupation(occ);
    }).length;
    if (associateCount > 0) {
      console.log(`  [associate volume] ${candidate.candidate_name}: ${associateCount} rows with bare "associate" occupation — excluded per spec`);
    }

    // Step 4: Filter to legal professionals
    const legalRows = contribResult.rows.filter(r => isLegalOccupation(r.occupation ?? ''));

    // Step 5: Normalize and group by firm
    const firmMap = new Map<string, {
      raw_firm_name: string;
      total_donated: number;
      donor_names: Set<string>;
      occupations: Set<string>;
    }>();

    for (const row of legalRows) {
      const amount = parseFloat(row.amount ?? '0');
      if (isNaN(amount) || amount <= 0) continue;

      // Determine raw firm name: use employer if present, else donor name
      const rawFirm = (row.employer ?? '').trim() !== '' ? row.employer.trim() : (row.donor_name ?? '').trim();
      if (!rawFirm) continue;

      const normalized = normalizeFirmName(rawFirm);
      if (!normalized) continue;

      const existing = firmMap.get(normalized);
      if (existing) {
        existing.total_donated += amount;
        existing.donor_names.add(row.donor_name ?? '');
        if (row.occupation) existing.occupations.add(row.occupation.toUpperCase());
      } else {
        firmMap.set(normalized, {
          raw_firm_name: rawFirm,
          total_donated: amount,
          donor_names: new Set([row.donor_name ?? '']),
          occupations: new Set(row.occupation ? [row.occupation.toUpperCase()] : []),
        });
      }
    }

    // Step 6: Convert to array for fuzzy dedup
    let firms: FirmEntry[] = Array.from(firmMap.entries()).map(([norm, data]) => ({
      firm_name: norm,
      raw_firm_name: data.raw_firm_name,
      total_donated: data.total_donated,
      donor_count: data.donor_names.size,
      occupations_seen: Array.from(data.occupations).sort(),
      is_fuzzy_match: false,
      needs_review: false,
    }));

    // Step 7: Fuzzy dedup pass using fastest-levenshtein
    // Same-first-letter pairs: distance <= 3 → merge smaller into larger
    // Distance 4-6 → tag both needs_review=true
    const merged = new Set<string>(); // firm_name values that were merged away

    for (let i = 0; i < firms.length; i++) {
      if (merged.has(firms[i].firm_name)) continue;
      for (let j = i + 1; j < firms.length; j++) {
        if (merged.has(firms[j].firm_name)) continue;

        const a = firms[i].firm_name;
        const b = firms[j].firm_name;

        // Only compare same-first-letter pairs
        if (!a || !b || a[0] !== b[0]) continue;

        const dist = distance(a, b);

        if (dist <= 3) {
          // Merge smaller into larger
          if (firms[i].total_donated >= firms[j].total_donated) {
            firms[i].total_donated += firms[j].total_donated;
            firms[i].donor_count += firms[j].donor_count;
            for (const occ of firms[j].occupations_seen) {
              if (!firms[i].occupations_seen.includes(occ)) {
                firms[i].occupations_seen.push(occ);
              }
            }
            firms[i].is_fuzzy_match = true;
            merged.add(firms[j].firm_name);
          } else {
            firms[j].total_donated += firms[i].total_donated;
            firms[j].donor_count += firms[i].donor_count;
            for (const occ of firms[i].occupations_seen) {
              if (!firms[j].occupations_seen.includes(occ)) {
                firms[j].occupations_seen.push(occ);
              }
            }
            firms[j].is_fuzzy_match = true;
            merged.add(firms[i].firm_name);
            break; // firms[i] is gone, move to i+1
          }
        } else if (dist >= 4 && dist <= 6) {
          firms[i].needs_review = true;
          firms[j].needs_review = true;
          console.warn(`  [fuzzy warn] ${candidate.candidate_name}: "${a}" vs "${b}" (distance=${dist}) — both flagged needs_review`);
        }
      }
    }

    // Remove merged entries
    firms = firms.filter(f => !merged.has(f.firm_name));

    // Step 8: Sort deterministically: desc by total_donated, then asc by raw_firm_name
    firms.sort((a, b) => {
      if (b.total_donated !== a.total_donated) return b.total_donated - a.total_donated;
      return a.raw_firm_name.localeCompare(b.raw_firm_name);
    });

    // Step 9: Apply 15% cumulative threshold
    // Include firms until cumulative >= 15% of grand_total
    // A single firm exceeding 15% alone is still included
    const thresholdFirms: FirmEntry[] = [];
    let cumulative = 0;

    for (const firm of firms) {
      if (cumulative >= threshold_cutoff && thresholdFirms.length > 0) break;
      thresholdFirms.push(firm);
      cumulative += firm.total_donated;
    }

    // Sort final list deterministically (already sorted, but re-sort after threshold cut for safety)
    thresholdFirms.sort((a, b) => {
      if (b.total_donated !== a.total_donated) return b.total_donated - a.total_donated;
      return a.raw_firm_name.localeCompare(b.raw_firm_name);
    });

    const needsReviewCount = thresholdFirms.filter(f => f.needs_review).length;

    console.log(`${candidate.candidate_name}:`);
    console.log(`  grand_total=$${grand_total.toFixed(2)}, threshold_cutoff=$${threshold_cutoff.toFixed(2)}`);
    console.log(`  total rows=${contribResult.rows.length}, legal rows=${legalRows.length}, firms after dedup=${firms.length}, in 15%=${thresholdFirms.length}, needs_review=${needsReviewCount}`);
    console.log('');

    output.push({
      politician_id: candidate.politician_id,
      candidate_name: candidate.candidate_name,
      is_city_attorney: candidate.is_city_attorney,
      grand_total,
      threshold_cutoff,
      firms: thresholdFirms,
    });
  }

  // Write output JSON
  const outputPath = path.join(__dirname, 'court-research-input.json');
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2) + '\n', 'utf-8');
  console.log(`\nWrote ${outputPath}`);
  console.log(`Candidates: ${output.length} total (${output.filter(c => c.firms.length > 0).length} with firms, ${output.filter(c => c.firms.length === 0).length} empty)`);

  await pool.end();
}

// =============================================================================
// ENTRY POINT
// =============================================================================

async function main(): Promise<void> {
  if (isProbe) {
    await runProbe();
  } else {
    await runExtraction();
  }
}

main().catch(async err => {
  console.error('[identify-legal-donors] Fatal:', err);
  await pool.end();
  process.exit(1);
});
