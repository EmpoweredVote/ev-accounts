/**
 * backfill-indiana-office-titles.ts — One-time backfill for Indiana office titles.
 *
 * Usage:
 *   npx tsx scripts/backfill-indiana-office-titles.ts --dry-run   # preview counts, no DB writes
 *   npx tsx scripts/backfill-indiana-office-titles.ts              # live run, updates essentials.offices
 *
 * What it does:
 *   1. Fetches all Indiana needs_research politician_sources rows.
 *   2. Extracts committee name from politician_sources.notes (already stored from discovery).
 *   3. Parses office title from committee name using [NAME] FOR [OFFICE] pattern.
 *   4. Applies gender-neutral aliases and Title Case normalization.
 *   5. Updates essentials.offices.title from 'Indiana Elected Official' to derived title.
 *
 * Critical constraints:
 *   - Reads from politician_sources.notes — does NOT download Indiana CSVs
 *   - Updates essentials.offices.title ONLY — NOT politician_sources (no office_title column there)
 *   - All writes gated behind if (!isDryRun)
 *   - Uses LEFT JOIN for offices (some politicians may lack an offices row)
 */

import 'dotenv/config';
import { Pool } from 'pg';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');
console.log(`[backfill-indiana-office-titles] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE RUN'}`);

// ─── DB Pool ─────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface SourceRow {
  source_id: string;
  external_id: string;
  notes: string | null;
  full_name: string;
  politician_id: string;
  office_title: string | null;
}

interface UpdateCandidate {
  politicianId: string;
  newTitle: string;
  fullName: string;
  committeeName: string;
}

// ─── Alias map ───────────────────────────────────────────────────────────────
// Keys are UPPERCASE (matched after .toUpperCase()); values are final Title Case output.

const OFFICE_ALIASES: Record<string, string> = {
  // Gender-neutral normalization
  'CITY COUNCILMAN': 'City Council Member',
  'CITY COUNCILWOMAN': 'City Council Member',
  'CITY COUNCIL MAN': 'City Council Member',
  'CITY COUNCIL WOMAN': 'City Council Member',
  'COUNCILMAN': 'Council Member',
  'COUNCILWOMAN': 'Council Member',
  'COUNCILMEMBER': 'Council Member',
  'TOWN COUNCILMAN': 'Town Council Member',
  'TOWN COUNCILWOMAN': 'Town Council Member',
  'TOWN COUNCIL': 'Town Council Member',

  // Common abbreviations / state offices
  'STATE REP': 'State Representative',
  'STATE REP.': 'State Representative',
  'STATE REPRESENTATIVE': 'State Representative',
  'STATE REPRESENATIVE': 'State Representative', // common typo
  'STATE REPRESENTATAIVE': 'State Representative', // common typo
  'REPRESENTATIVE': 'State Representative',
  'STATE SENATOR': 'State Senator',
  'STATE SENATE': 'State Senator',
  'SENATE': 'State Senator',
  'SENATOR': 'State Senator',
  'INDIANA STATE SENATE': 'State Senator',
  'INDIANA SENATE': 'State Senator',
  'INDIANA STATE REPRESENTATIVE': 'State Representative',
  'INDIANA REPRESENTATIVE': 'State Representative',
  'HOUSE OF REPRESENTATIVES': 'State Representative',
  'INDIANA HOUSE OF REPRESENTATIVES': 'State Representative',
  'STATEHOUSE': 'State Representative',

  // Statewide offices
  'ATTORNEY GENERAL': 'Attorney General',
  'LIEUTENANT GOVERNOR': 'Lieutenant Governor',
  'LT. GOVERNOR': 'Lieutenant Governor',
  'LT GOVERNOR': 'Lieutenant Governor',
  'GOVERNOR': 'Governor',
  'SECRETARY OF STATE': 'Secretary of State',
  'STATE TREASURER': 'State Treasurer',
  'STATE AUDITOR': 'State Auditor',

  // City / municipal
  'MAYOR': 'Mayor',
  'CITY COUNCIL': 'City Council Member',
  'CITY CLERK': 'City Clerk',
  'CITY JUDGE': 'City Judge',

  // Township / County
  'TOWNSHIP TRUSTEE': 'Township Trustee',
  'TOWNSHIP BOARD': 'Township Board Member',
  'TOWNSHIP BOARD MEMBER': 'Township Board Member',
  'COUNTY COMMISSIONER': 'County Commissioner',
  'COUNTY COUNCIL': 'County Council Member',
  'COUNTY COUNCILMAN': 'County Council Member',
  'COUNTY COUNCILWOMAN': 'County Council Member',
  'COUNTY AUDITOR': 'County Auditor',
  'COUNTY CLERK': 'County Clerk',
  'COUNTY RECORDER': 'County Recorder',
  'COUNTY TREASURER': 'County Treasurer',
  'COUNTY SHERIFF': 'County Sheriff',
  'COUNTY CORONER': 'County Coroner',
  'COUNTY SURVEYOR': 'County Surveyor',
  'COUNTY ASSESSOR': 'County Assessor',
  'COUNTY PROSECUTOR': 'County Prosecutor',
  'PROSECUTING ATTORNEY': 'Prosecuting Attorney',

  // School boards
  'SCHOOL BOARD': 'School Board Member',
  'SCHOOL BOARD MEMBER': 'School Board Member',
  'SCHOOL TRUSTEE': 'School Board Trustee',

  // Judge normalization
  'JUDGE': 'Judge',
  'CIRCUIT COURT JUDGE': 'Circuit Court Judge',
  'SUPERIOR COURT JUDGE': 'Superior Court Judge',
  'PROBATE COURT JUDGE': 'Probate Court Judge',
  'SMALL CLAIMS COURT JUDGE': 'Small Claims Court Judge',
  'CITY COURT JUDGE': 'City Court Judge',

  // Clerk of courts
  'CLERK OF COURTS': 'Clerk of Courts',
  'CLERK OF THE COURTS': 'Clerk of Courts',
  'CLERK OF COURT': 'Clerk of Courts',

  // Constable / Other
  'CONSTABLE': 'Constable',
  'SUPERINTENDENT': 'Superintendent',
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Convert a string to Title Case (each word capitalized).
 * E.g., "state representative" → "State Representative"
 */
function toTitleCase(str: string): string {
  return str
    .toLowerCase()
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

/**
 * Strip district numbers, trailing noise, and punctuation from an office string (uppercased input).
 */
function stripSuffix(office: string): string {
  let result = office.trim();
  // Strip trailing " COMMITTEE" first (may appear after district number)
  result = result.replace(/\s+COMMITTEE\s*$/i, '').trim();
  // Strip " DISTRICT N" or " DISTRICT NN" at the end (with optional dash/period)
  result = result.replace(/\s+DISTRICT\s+[\d-]+\s*$/i, '').trim();
  // Strip trailing standalone numbers (e.g., "State Rep 29", "Indiana Senate 31")
  result = result.replace(/\s+\d+\s*$/, '').trim();
  // Strip leading "DISTRICT N " or "DISTRICT NN " at the start
  result = result.replace(/^DISTRICT\s+\d+\s+/i, '').trim();
  // Strip leading "IN " (state abbreviation used as prefix, e.g., "IN STATE REPRESENTATIVE")
  result = result.replace(/^IN\s+STATE\s+/i, 'STATE ').trim();
  // Strip trailing " ELECTION" (e.g., "SENATE ELECTION")
  result = result.replace(/\s+ELECTION\s*$/i, '').trim();
  // Strip trailing " -" or " –"
  result = result.replace(/\s+[-–]+\s*$/, '').trim();
  // Strip trailing period (abbreviation artifact, e.g., "State Rep.")
  result = result.replace(/\.$/, '').trim();
  return result;
}

/**
 * Known office keywords used to validate parsed office strings.
 * A parsed string must contain at least one of these to be considered a valid office title.
 * This prevents person names, city names, and state names from being treated as offices.
 */
const OFFICE_KEYWORDS = new Set([
  'REPRESENTATIVE', 'REP', 'SENATOR', 'SENATE', 'MAYOR', 'COUNCIL',
  'COMMISSIONER', 'TRUSTEE', 'TREASURER', 'SHERIFF', 'AUDITOR', 'CLERK',
  'RECORDER', 'JUDGE', 'PROSECUTOR', 'ATTORNEY', 'CONSTABLE', 'SUPERINTENDENT',
  'CORONER', 'SURVEYOR', 'ASSESSOR', 'BOARD', 'STATEHOUSE', 'GOVERNOR',
  'SECRETARY', 'ELECTION',
]);

/**
 * Returns true if the uppercased office string contains a known office keyword.
 */
function looksLikeOffice(upper: string): boolean {
  for (const kw of OFFICE_KEYWORDS) {
    if (upper.includes(kw)) return true;
  }
  return false;
}

/**
 * Parse office title from committee name.
 * Primary: "[NAME] FOR [OFFICE]" — validated against known office keywords.
 * Secondary: "[NAME] COMMITTEE" patterns cannot yield office info — returns null.
 * Returns null if no valid office keyword found in extracted text.
 */
function parseOfficeFromCommittee(committeeName: string): string | null {
  const upper = committeeName.toUpperCase().trim();

  // Primary: look for " FOR " pattern
  const forMatch = upper.match(/\bFOR\s+(.+)$/i);
  if (forMatch) {
    const rawOffice = stripSuffix(forMatch[1].trim());
    if (!rawOffice) return null;
    // Validate: the extracted text must look like an actual office role
    if (!looksLikeOffice(rawOffice)) return null;
    return rawOffice;
  }

  // Special pattern: "[OFFICE] [NAME]" — e.g., "Snow Indiana State Representative"
  // Check if the committee name itself contains an office keyword
  if (looksLikeOffice(upper)) {
    // Find the longest alias key that appears in the committee name
    let bestMatch: string | null = null;
    let bestLen = 0;
    for (const key of Object.keys(OFFICE_ALIASES)) {
      if (upper.includes(key) && key.length > bestLen) {
        bestMatch = key;
        bestLen = key.length;
      }
    }
    if (bestMatch) return bestMatch;
  }

  // "Committee to Elect/Retain [NAME]" — no office info encodable, return null
  // "Friends of [NAME]" — same, no office info
  return null;
}

/**
 * Apply alias normalization. Returns final Title Case title.
 */
function normalizeOffice(rawOfficeUpper: string): string {
  const alias = OFFICE_ALIASES[rawOfficeUpper];
  if (alias) return alias;

  // Check partial alias match (some offices have city/county prefix before known term)
  for (const [key, value] of Object.entries(OFFICE_ALIASES)) {
    if (rawOfficeUpper === key) return value;
  }

  // Fallback: Title Case the raw office string
  return toTitleCase(rawOfficeUpper);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const client = await pool.connect();

  try {
    // ── Fetch all Indiana needs_research rows ──────────────────────────────────
    const { rows } = await client.query<SourceRow>(`
      SELECT ps.id AS source_id, ps.external_id, ps.notes,
             p.full_name, p.id AS politician_id,
             o.title AS office_title
      FROM transparent_motivations.politician_sources ps
      JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
      LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
      WHERE ps.source_system = 'indiana'
        AND ps.research_status = 'needs_research'
      ORDER BY p.full_name
    `);

    console.log(`\nFetched ${rows.length} Indiana needs_research rows`);

    // ── Parse loop ────────────────────────────────────────────────────────────
    let noCommitteeInNotes = 0;
    let noOfficesRow = 0;
    let alreadyCorrected = 0;
    let unparseable = 0;
    const updates: UpdateCandidate[] = [];

    for (const row of rows) {
      // a. Extract committee name from notes
      const committeeMatch = row.notes?.match(/Committee:\s*(.+?)\.\s*Office type/i);
      if (!committeeMatch) {
        noCommitteeInNotes++;
        continue;
      }
      const committeeName = committeeMatch[1].trim();

      // b. Skip if no essentials.offices row
      if (row.office_title === null) {
        noOfficesRow++;
        continue;
      }

      // c. Skip if already corrected (not the placeholder)
      if (row.office_title !== 'Indiana Elected Official') {
        alreadyCorrected++;
        continue;
      }

      // d. Parse office from committee name
      const rawOfficeUpper = parseOfficeFromCommittee(committeeName);
      if (!rawOfficeUpper) {
        unparseable++;
        if (process.env.DEBUG_UNPARSEABLE) {
          console.log(`  [unparseable] ${row.full_name} | ${committeeName}`);
        }
        continue;
      }

      // e. Normalize to final title
      const newTitle = normalizeOffice(rawOfficeUpper);

      updates.push({
        politicianId: row.politician_id,
        newTitle,
        fullName: row.full_name,
        committeeName,
      });
    }

    // ── Print preview ─────────────────────────────────────────────────────────
    if (isDryRun && updates.length > 0) {
      console.log('\nSample updates (first 30):');
      for (const u of updates.slice(0, 30)) {
        console.log(`  ${u.fullName.padEnd(35)} | ${u.committeeName.substring(0, 50).padEnd(50)} → ${u.newTitle}`);
      }
      // Show title distribution
      const titleDist: Record<string, number> = {};
      for (const u of updates) {
        titleDist[u.newTitle] = (titleDist[u.newTitle] ?? 0) + 1;
      }
      console.log('\nTitle distribution:');
      for (const [title, count] of Object.entries(titleDist).sort((a, b) => b[1] - a[1])) {
        console.log(`  ${String(count).padStart(4)}  ${title}`);
      }
    }

    // ── Write ─────────────────────────────────────────────────────────────────
    if (!isDryRun && updates.length > 0) {
      await client.query('BEGIN');
      try {
        for (const u of updates) {
          await client.query(
            `UPDATE essentials.offices
             SET title = $1
             WHERE politician_id = $2
               AND title = 'Indiana Elected Official'`,
            [u.newTitle, u.politicianId]
          );
        }
        await client.query('COMMIT');
        console.log('\nTransaction committed successfully.');
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      }
    }

    // ── Summary ───────────────────────────────────────────────────────────────
    const total = rows.length;
    console.log('\n── Summary ──────────────────────────────────────────');
    if (isDryRun) {
      console.log(`  Would update:                         ${updates.length}`);
    } else {
      console.log(`  Updated:                              ${updates.length}`);
    }
    console.log(`  Left as placeholder (unparseable):    ${unparseable}`);
    console.log(`  No committee in notes:                ${noCommitteeInNotes}`);
    console.log(`  No essentials.offices row:            ${noOfficesRow}`);
    console.log(`  Already corrected:                    ${alreadyCorrected}`);
    console.log(`  ─────────────────────────────────────────────────`);
    console.log(`  Total processed:                      ${total}`);

    const checkTotal = updates.length + unparseable + noCommitteeInNotes + noOfficesRow + alreadyCorrected;
    if (checkTotal !== total) {
      console.warn(`  WARNING: counts don't add up! (${checkTotal} vs ${total})`);
    }

    if (isDryRun) {
      console.log('\nDRY-RUN complete — no database writes made.');
    } else {
      console.log('\nBackfill complete.');
    }

  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
