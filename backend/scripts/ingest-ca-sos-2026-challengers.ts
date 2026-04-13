/**
 * ingest-ca-sos-2026-challengers.ts — CA 2026 Primary challenger ingestion
 *
 * Usage:
 *   npx tsx scripts/ingest-ca-sos-2026-challengers.ts             # dry-run (default)
 *   npx tsx scripts/ingest-ca-sos-2026-challengers.ts --commit     # write to DB
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * What it does:
 *   1. Looks up the '2026 LA County Primary' election record.
 *   2. For each race in CHALLENGERS, finds the matching race by position_name.
 *   3. Inserts challengers as race_candidates with is_incumbent=false.
 *   4. Idempotent — skips by name collision within the same race.
 *   5. Updates incumbents not seeking re-election to candidate_status='withdrawn'.
 *
 * DATA PROVENANCE — READ BEFORE ADDING CANDIDATES:
 *   Only add candidates to this script from a citable, human-verified source.
 *   Do NOT add candidates based on inference, prior election history, or speculation.
 *   Each section below must reference its source URL/publication and date.
 *
 * Sources used in this script:
 *   - CA SoS Certified List of Candidates (2026 Primary)
 *     http://elections.cdn.sos.ca.gov/statewide-elections/2026-primary/cert-list-candidates.pdf
 *     Published: 2026-03-26. Verified: 2026-04-13.
 *   - Calmatters CA Governor candidate tracker
 *     https://calmatters.org/politics/2026/03/california-governor-candidates/
 *     Published: 2026-03-06. Verified: 2026-04-13.
 *   - LA County Registrar-Recorder Candidate Filing Status
 *     https://www.lavote.gov/Apps/CandidateList/Index?id=4338
 *     Updated: 2026-04-10. Verified: 2026-04-13.
 *
 * CA is a "top-2 jungle primary" state:
 *   - ALL candidates appear on one primary ballot regardless of party
 *   - races.primary_party = NULL for ALL CA race records
 *
 * ANTIPARTISAN POLICY: No party column is stored on race_candidates.
 *   Party affiliation is excluded per EV design (see importElectionData.ts header).
 *
 * DATA QUALITY NOTE — Assembly District 54 vs 55:
 *   The CA SoS Certified List confirms:
 *     - Assembly District 54: Mark Gonzalez (incumbent, UNCONTESTED — no challengers filed)
 *     - Assembly District 55: Isaac G. Bryan (incumbent, 3 challengers)
 *   The DB race record was initially seeded as "CA State Assembly District 54" with Bryan
 *   as incumbent. This was corrected in Quick-017 (2026-04-13):
 *     - Race renamed from "CA State Assembly District 54" → "CA State Assembly District 55"
 *     - office_id updated to AD-55's geofence (ocd-division/country:us/state:ca/sldl:55)
 *   AD-54 (Mark Gonzalez, uncontested) is not tracked in this election — no race record seeded.
 *
 * LAUSD Board D2/D4/D6 NOTE:
 *   LAUSD Board of Education Districts 2, 4, and 6 are NOT on the June 2, 2026 primary
 *   ballot. They do not appear on the CA SoS certified list or lavote.gov candidate filing
 *   list. LAUSD Board elections run on a different cycle. Do NOT add challengers to those
 *   races. The existing incumbent-only records represent the current officeholders for
 *   reference/information purposes only.
 */

import 'dotenv/config';
import path from 'path';
import { fileURLToPath } from 'url';
import { Pool, PoolClient } from 'pg';

// ---------------------------------------------------------------------------
// ESM __dirname shim
// ---------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------------------------------------------------------------------
// Load .env from backend root
// ---------------------------------------------------------------------------
import dotenv from 'dotenv';
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const isDryRun = !isCommit;

// ---------------------------------------------------------------------------
// DB pool
// ---------------------------------------------------------------------------
if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set. Add it to backend/.env');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ChallengerEntry {
  /** Must match races.position_name exactly */
  race_position_name: string;
  full_name: string;
  first_name: string;
  last_name: string;
  /** Source tag stored in race_candidates.source — should match the data's origin */
  source: string;
  /** Stable external ID for idempotency. Format: {source}-{normalized-name} */
  external_id: string;
}

interface IncumbentStatusUpdate {
  /** Must match races.position_name exactly */
  race_position_name: string;
  /** Full name of the incumbent candidate to update */
  full_name: string;
  /** New status — only 'withdrawn' makes sense here */
  new_status: 'withdrawn';
  /** Why this update is needed */
  reason: string;
}

function makeExternalId(source: string, fullName: string): string {
  const normalized = fullName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `${source}-${normalized}`;
}

/**
 * Build a ChallengerEntry with auto-derived external_id.
 */
function c(
  source: string,
  race_position_name: string,
  first_name: string,
  last_name: string,
  full_name_override?: string
): ChallengerEntry {
  const full_name = full_name_override ?? `${first_name} ${last_name}`;
  return {
    race_position_name,
    full_name,
    first_name,
    last_name,
    source,
    external_id: makeExternalId(source, full_name),
  };
}

// ---------------------------------------------------------------------------
// Incumbent status corrections
// These are incumbents who are NOT seeking re-election in this race.
// Sources confirm they either: (a) are term-limited, (b) are running for a
// different office in 2026, or (c) did not file for this race.
// ---------------------------------------------------------------------------
const INCUMBENT_STATUS_UPDATES: IncumbentStatusUpdate[] = [
  {
    race_position_name: 'CA Insurance Commissioner',
    full_name: 'Ricardo Lara',
    new_status: 'withdrawn',
    reason: 'Term-limited — not on CA SoS 2026 primary certified list for this race',
  },
  {
    race_position_name: 'CA Lieutenant Governor',
    full_name: 'Eleni Kounalakis',
    new_status: 'withdrawn',
    reason: 'Running for CA State Treasurer in 2026, not seeking re-election as Lt. Governor',
  },
  {
    race_position_name: 'CA Superintendent of Public Instruction',
    full_name: 'Tony Thurmond',
    new_status: 'withdrawn',
    reason: 'Running for CA Governor in 2026, not seeking re-election as Superintendent',
  },
  {
    race_position_name: 'CA State Treasurer',
    full_name: 'Fiona Ma',
    new_status: 'withdrawn',
    reason: 'Running for CA Lieutenant Governor in 2026, not seeking re-election as Treasurer',
  },
  {
    race_position_name: 'LA County Assessor',
    full_name: 'Jeff Prang',
    new_status: 'withdrawn',
    reason: 'Not on lavote.gov 2026 candidate filing list — only Stephen A. Adamus filed',
  },
];

// ---------------------------------------------------------------------------
// Challenger data
//
// Each section must cite its source. Do not add candidates from inference or
// prior election history — only from a citable human-verified source.
// ---------------------------------------------------------------------------
const CHALLENGERS: ChallengerEntry[] = [

  // =========================================================================
  // CA GOVERNOR — open seat (Newsom term-limited; all candidates are challengers)
  //
  // Source A: Calmatters — https://calmatters.org/politics/2026/03/california-governor-candidates/
  //   Published: 2026-03-06. Verified: 2026-04-13.
  //   Note: Eric Swalwell withdrew 2026-04-11 — already in DB as withdrawn.
  //         Tony Thurmond filed for Governor but is also Superintendent incumbent.
  //
  // Source B: CA SoS Certified List, 2026-03-26 — additional candidates beyond Calmatters.
  //   http://elections.cdn.sos.ca.gov/statewide-elections/2026-primary/cert-list-candidates.pdf
  // =========================================================================

  // --- Calmatters-sourced (already in DB from Quick-016; idempotent re-run) ---
  c('calmatters-2026', 'CA Governor', 'Xavier',   'Becerra'),
  c('calmatters-2026', 'CA Governor', 'Chad',     'Bianco'),
  c('calmatters-2026', 'CA Governor', 'Steve',    'Hilton'),
  c('calmatters-2026', 'CA Governor', 'Matt',     'Mahan'),
  c('calmatters-2026', 'CA Governor', 'Katie',    'Porter'),
  c('calmatters-2026', 'CA Governor', 'Tom',      'Steyer'),
  c('calmatters-2026', 'CA Governor', 'Tony',     'Thurmond'),
  c('calmatters-2026', 'CA Governor', 'Antonio',  'Villaraigosa'),
  c('calmatters-2026', 'CA Governor', 'Betty',    'Yee'),

  // --- CA SoS certified additions (not in Calmatters list) ---
  c('ca-sos-2026', 'CA Governor', 'Akinyemi',    'Agbede'),
  c('ca-sos-2026', 'CA Governor', 'Mohammad',    'Arif'),
  c('ca-sos-2026', 'CA Governor', 'Larry',       'Azevedo'),
  c('ca-sos-2026', 'CA Governor', 'Naomi',       'Bar-Lev'),
  c('ca-sos-2026', 'CA Governor', 'Carolina',    'Buhler'),
  c('ca-sos-2026', 'CA Governor', 'Joseph',      'Cabrera'),
  c('ca-sos-2026', 'CA Governor', 'Elaine',      'Culotti'),
  c('ca-sos-2026', 'CA Governor', 'Louis A.',    'De Barraicua'),
  c('ca-sos-2026', 'CA Governor', 'Patricia',    'De Luca Basualdo'),
  c('ca-sos-2026', 'CA Governor', 'LivingForGod AndCountry', 'DeMott', 'LivingForGod AndCountry DeMott'),
  c('ca-sos-2026', 'CA Governor', 'Randeep S.',  'Dhillon'),
  c('ca-sos-2026', 'CA Governor', 'Sophia',      'Edum-a-Sam'),
  c('ca-sos-2026', 'CA Governor', 'Serge',       'Fiankan'),
  c('ca-sos-2026', 'CA Governor', 'Lukasz Adam', 'Filinski'),
  c('ca-sos-2026', 'CA Governor', 'Max',         'Fomin'),
  c('ca-sos-2026', 'CA Governor', 'Derek',       'Grasty'),
  c('ca-sos-2026', 'CA Governor', 'Don J.',      'Grundmann'),
  c('ca-sos-2026', 'CA Governor', 'Jon',         'Henderson'),
  c('ca-sos-2026', 'CA Governor', 'Rafael M.',   'Hernandez'),
  c('ca-sos-2026', 'CA Governor', 'Lewis',       'Herms'),
  c('ca-sos-2026', 'CA Governor', 'Joel E.',     'Jacob'),
  c('ca-sos-2026', 'CA Governor', 'Dawit',       'Kellel'),
  c('ca-sos-2026', 'CA Governor', 'Gary Howard', 'Kidgell'),
  c('ca-sos-2026', 'CA Governor', 'Anne',        'Komarovsk'),
  c('ca-sos-2026', 'CA Governor', 'Alicia Olivia', 'Lapp'),
  c('ca-sos-2026', 'CA Governor', 'Matthew Chase', 'Levy'),
  c('ca-sos-2026', 'CA Governor', 'Duane Terrence', 'Loynes Jr.'),
  c('ca-sos-2026', 'CA Governor', 'Amanda',      'Martin'),
  c('ca-sos-2026', 'CA Governor', 'Brent',       'Maupin'),
  c('ca-sos-2026', 'CA Governor', 'Daniel',      'Mercuri'),
  c('ca-sos-2026', 'CA Governor', 'Leo',         'Naranjo IV'),
  c('ca-sos-2026', 'CA Governor', 'Tim',         'Nelson'),
  c('ca-sos-2026', 'CA Governor', 'Mauro Alberto', 'Orozco'),
  c('ca-sos-2026', 'CA Governor', 'Thunder',     'Parley'),
  c('ca-sos-2026', 'CA Governor', 'Raji',        'Rab'),
  c('ca-sos-2026', 'CA Governor', 'Satish',      'Rao'),
  c('ca-sos-2026', 'CA Governor', 'Ramsey',      'Robinson'),
  c('ca-sos-2026', 'CA Governor', 'Reza',        'Safarnejad'),
  c('ca-sos-2026', 'CA Governor', 'Sam',         'Sandak'),
  c('ca-sos-2026', 'CA Governor', 'Christine R.', 'Sarmiento'),
  c('ca-sos-2026', 'CA Governor', 'Frederic C.', 'Schultz'),
  c('ca-sos-2026', 'CA Governor', 'Barack D. Obama', 'Shaw', 'Barack D. Obama Shaw'),
  c('ca-sos-2026', 'CA Governor', 'Scott P',     'Shields'),
  c('ca-sos-2026', 'CA Governor', 'Gretha',      'Solorzano'),
  c('ca-sos-2026', 'CA Governor', 'Margaret',    'Trowe'),
  c('ca-sos-2026', 'CA Governor', 'Tom',         'Woodard'),
  c('ca-sos-2026', 'CA Governor', 'Nancy D.',    'Young'),
  c('ca-sos-2026', 'CA Governor', 'Leo Samuel',  'Zacky'),
  c('ca-sos-2026', 'CA Governor', 'Erin',        'Zezulak', 'Erin "Zez" Zezulak'),
  c('ca-sos-2026', 'CA Governor', 'David',       'Zickefoose'),
  c('ca-sos-2026', 'CA Governor', 'James',       'Athans Jr.'),
  c('ca-sos-2026', 'CA Governor', 'James',       'Williamson'),
  c('ca-sos-2026', 'CA Governor', 'James',       'Hanink'),
  c('ca-sos-2026', 'CA Governor', 'Delaine',     'Eastin'),

  // =========================================================================
  // CA LIEUTENANT GOVERNOR — open seat (Kounalakis running for Treasurer)
  // Source: CA SoS Certified List, 2026-03-26
  // Note: Kounalakis was seeded as incumbent but is NOT on the Lt. Gov SoS list.
  //       Her status is updated to 'withdrawn' via INCUMBENT_STATUS_UPDATES above.
  //       Fiona Ma is on the SoS Lt. Gov list (running for Lt. Gov, not re-running
  //       for Treasurer). All listed candidates are challengers for this open seat.
  // =========================================================================
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Josh',        'Fryday'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Janelle',     'Kellman'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Jeyson',      'Lopez'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Fiona',       'Ma'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Oliver',      'Ma'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Tim',         'Myers'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Abdur Rahman', 'Sikder'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Michael',     'Tubbs'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Ebie',        'Lynch'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'David',       'Collenberg'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'David',       'Fennell'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Gloria',      'Romero'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Skip',        'Shelton'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Alice',       'Stek'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Rakesh',      'Christian'),
  c('ca-sos-2026', 'CA Lieutenant Governor', 'Sean',        'Collinson'),

  // =========================================================================
  // CA ATTORNEY GENERAL — Rob Bonta is incumbent
  // Source: CA SoS Certified List, 2026-03-26
  // =========================================================================
  c('ca-sos-2026', 'CA Attorney General', 'Michael E.',  'Gates'),
  c('ca-sos-2026', 'CA Attorney General', 'Marjorie',    'Mikels'),

  // =========================================================================
  // CA SECRETARY OF STATE — Shirley N. Weber is incumbent
  // Source: CA SoS Certified List, 2026-03-26
  // =========================================================================
  c('ca-sos-2026', 'CA Secretary of State', 'Donald P.',   'Wagner'),
  c('ca-sos-2026', 'CA Secretary of State', 'Gary N.',     'Blenner'),
  c('ca-sos-2026', 'CA Secretary of State', 'Michael',     'Feinstein'),

  // =========================================================================
  // CA STATE CONTROLLER — Malia M. Cohen is incumbent
  // Source: CA SoS Certified List, 2026-03-26
  // =========================================================================
  c('ca-sos-2026', 'CA State Controller', 'Herb W',      'Morgan'),
  c('ca-sos-2026', 'CA State Controller', 'Meghann',     'Adams'),

  // =========================================================================
  // CA STATE TREASURER — open seat (Fiona Ma running for Lt. Gov)
  // Source: CA SoS Certified List, 2026-03-26
  // Note: Ma was seeded as Treasurer incumbent but she's on the SoS Lt. Gov list.
  //       Her Treasurer status is updated to 'withdrawn' via INCUMBENT_STATUS_UPDATES.
  //       All listed candidates are challengers for this open seat.
  // =========================================================================
  c('ca-sos-2026', 'CA State Treasurer', 'Anna M.',      'Caballero'),
  c('ca-sos-2026', 'CA State Treasurer', 'Eleni',        'Kounalakis'),
  c('ca-sos-2026', 'CA State Treasurer', 'Tony',         'Vazquez'),
  c('ca-sos-2026', 'CA State Treasurer', 'Jennifer',     'Hawks'),
  c('ca-sos-2026', 'CA State Treasurer', 'David',        'Serpa'),
  c('ca-sos-2026', 'CA State Treasurer', 'Glenn',        'Turner'),

  // =========================================================================
  // CA INSURANCE COMMISSIONER — open seat (Ricardo Lara term-limited)
  // Source: CA SoS Certified List, 2026-03-26
  // Note: Lara was seeded as incumbent but is NOT on SoS list.
  //       His status is updated to 'withdrawn' via INCUMBENT_STATUS_UPDATES above.
  //       All listed candidates are challengers for this open seat.
  // =========================================================================
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Ben',           'Allen'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Steven Craig',  'Bradford'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Jane',          'Kim'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Patrick',       'Wolff'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Eric Thor',     'Aarnio'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Merritt',       'Farren'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Robert P',      'Howell'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Stacy A.',      'Korsgaden'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Sean',          'Lee'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Keith W.',      'Davis'),
  c('ca-sos-2026', 'CA Insurance Commissioner', 'Eduardo',       'Vargas', 'Eduardo "Lalo" Vargas'),

  // =========================================================================
  // CA SUPERINTENDENT OF PUBLIC INSTRUCTION — open seat (Thurmond running for Gov)
  // Source: CA SoS Certified List, 2026-03-26
  // Note: Thurmond was seeded as incumbent but is NOT on SoS Supt. list.
  //       His status is updated to 'withdrawn' via INCUMBENT_STATUS_UPDATES above.
  //       All listed candidates are challengers for this open seat.
  // =========================================================================
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Richard',     'Barrera'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Wendy',       'Castaneda Leal'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Nichelle M.', 'Henderson'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Frank',       'Lara'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Ainye',       'Long'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Gus',         'Mattammal'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Al',          'Muratsuchi'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Josh',        'Newman'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Anthony',     'Rendon'),
  c('ca-sos-2026', 'CA Superintendent of Public Instruction', 'Sonja',       'Shaw'),

  // =========================================================================
  // CA STATE SENATE DISTRICT 26 — open seat (no incumbent marked)
  // Source: CA SoS Certified List, 2026-03-26
  // =========================================================================
  c('ca-sos-2026', 'CA State Senate District 26', 'Paul A.',  'Bowers'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Juan',     'Camacho'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Wendy',    'Carrillo'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Sara',     'Hernandez'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Maebe',    'Pudlo'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Sarah',    'Rascon'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Claudia',  'Agraz'),
  c('ca-sos-2026', 'CA State Senate District 26', 'Sang',     'Masog', 'Sang "Sam Shin" Masog'),

  // =========================================================================
  // U.S. REPRESENTATIVE DISTRICT 34 — Jimmy Gomez is incumbent
  // Source: CA SoS Certified List, 2026-03-26
  // =========================================================================
  c('ca-sos-2026', 'U.S. Representative District 34', 'Arthur',   'Dixon'),
  c('ca-sos-2026', 'U.S. Representative District 34', 'Angela',   'Gonzales-Torres'),
  c('ca-sos-2026', 'U.S. Representative District 34', 'Robert George', 'Lucero Jr.'),
  c('ca-sos-2026', 'U.S. Representative District 34', 'Calvin',   'Lee'),
  c('ca-sos-2026', 'U.S. Representative District 34', 'Loren',    'Colin'),

  // =========================================================================
  // CA STATE ASSEMBLY DISTRICT 55 — Isaac G. Bryan is incumbent
  // Source: CA SoS Certified List, 2026-03-26
  // Note: Race was originally seeded as "CA State Assembly District 54" with Bryan
  //       as incumbent — this was a data error. Quick-017 corrected the race record:
  //         - Renamed to "CA State Assembly District 55"
  //         - office_id updated to AD-55 geofence (ocd-division/country:us/state:ca/sldl:55)
  //       AD-54 (Mark Gonzalez, uncontested) is not tracked in this election.
  // =========================================================================
  c('ca-sos-2026', 'CA State Assembly District 55', 'Ashley M.',   'Brown'),
  c('ca-sos-2026', 'CA State Assembly District 55', 'Keith G.',    'Cascio'),
  c('ca-sos-2026', 'CA State Assembly District 55', 'William',     'Campbell', 'William "Billion" Campbell'),

  // =========================================================================
  // LA COUNTY SHERIFF — Robert Luna is incumbent
  // Source: LA County Registrar-Recorder Candidate Filing Status
  //   https://www.lavote.gov/Apps/CandidateList/Index?id=4338
  //   Updated: 2026-04-10. Verified: 2026-04-13.
  // =========================================================================
  c('lavote-2026', 'LA County Sheriff', 'Mike',    'Bornman'),
  c('lavote-2026', 'LA County Sheriff', 'Karla',   'Carranza'),
  c('lavote-2026', 'LA County Sheriff', 'Brendan', 'Corbett'),

  // =========================================================================
  // LA COUNTY ASSESSOR — open seat (Jeff Prang not seeking re-election)
  // Source: LA County Registrar-Recorder Candidate Filing Status
  //   https://www.lavote.gov/Apps/CandidateList/Index?id=4338
  //   Updated: 2026-04-10. Verified: 2026-04-13.
  // Note: Jeff Prang (incumbent) did NOT file per lavote.gov; only Adamus filed.
  //       Prang's status is updated to 'withdrawn' via INCUMBENT_STATUS_UPDATES above.
  // =========================================================================
  c('lavote-2026', 'LA County Assessor', 'Stephen A.', 'Adamus'),

  // =========================================================================
  // LAUSD BOARD OF EDUCATION D2, D4, D6 — NOT ON JUNE 2026 BALLOT
  // These races do NOT appear on the CA SoS certified list or lavote.gov filing list.
  // LAUSD Board elections run on a different cycle. No challengers to add.
  // The existing incumbent-only records are for reference only.
  // =========================================================================
];

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

async function getElectionId(client: PoolClient): Promise<string> {
  const result = await client.query<{ id: string }>(
    `SELECT id FROM essentials.elections WHERE name = $1`,
    ['2026 LA County Primary']
  );
  if (result.rows.length === 0) {
    throw new Error("Election '2026 LA County Primary' not found in DB. Run seed scripts first.");
  }
  return result.rows[0].id;
}

async function getRaceIdByPosition(
  client: PoolClient,
  electionId: string,
  positionName: string
): Promise<string | null> {
  const result = await client.query<{ id: string }>(
    `SELECT id FROM essentials.races
     WHERE election_id = $1 AND position_name = $2 AND primary_party IS NULL`,
    [electionId, positionName]
  );
  return result.rows[0]?.id ?? null;
}

interface InsertResult {
  action: 'inserted' | 'updated' | 'skipped';
  external_id: string;
}

async function upsertChallenger(
  client: PoolClient,
  raceId: string,
  entry: ChallengerEntry
): Promise<InsertResult> {
  // Check if this candidate already exists for this race by external_id
  const existing = await client.query<{ id: string; is_incumbent: boolean }>(
    `SELECT id, is_incumbent FROM essentials.race_candidates
     WHERE external_id = $1`,
    [entry.external_id]
  );

  if (existing.rows.length > 0) {
    // Already exists — update status/name but preserve politician_id (manual link)
    await client.query(
      `UPDATE essentials.race_candidates
       SET full_name        = $1,
           first_name       = $2,
           last_name        = $3,
           is_incumbent     = false,
           candidate_status = 'active',
           last_verified_at = now()
       WHERE external_id = $4`,
      [entry.full_name, entry.first_name, entry.last_name, entry.external_id]
    );
    return { action: 'updated', external_id: entry.external_id };
  }

  // Check for name collision in same race (handles case where external_id is missing
  // but the person was added via a different pathway)
  const nameCheck = await client.query<{ id: string }>(
    `SELECT id FROM essentials.race_candidates
     WHERE race_id = $1 AND full_name = $2`,
    [raceId, entry.full_name]
  );

  if (nameCheck.rows.length > 0) {
    return { action: 'skipped', external_id: entry.external_id };
  }

  // Insert new challenger
  await client.query(
    `INSERT INTO essentials.race_candidates
       (race_id, full_name, first_name, last_name,
        is_incumbent, candidate_status, source, external_id,
        last_verified_at, politician_id)
     VALUES ($1, $2, $3, $4, false, 'active', $5, $6, now(), NULL)`,
    [raceId, entry.full_name, entry.first_name, entry.last_name, entry.source, entry.external_id]
  );
  return { action: 'inserted', external_id: entry.external_id };
}

async function applyIncumbentStatusUpdate(
  client: PoolClient,
  raceId: string,
  update: IncumbentStatusUpdate
): Promise<{ action: 'updated' | 'not_found' }> {
  const result = await client.query(
    `UPDATE essentials.race_candidates
     SET candidate_status = $1,
         last_verified_at = now()
     WHERE race_id = $2
       AND full_name = $3
       AND is_incumbent = true
       AND candidate_status != $1
     RETURNING id`,
    [update.new_status, raceId, update.full_name]
  );
  return { action: result.rowCount && result.rowCount > 0 ? 'updated' : 'not_found' };
}

// ---------------------------------------------------------------------------
// Dry-run preview
// ---------------------------------------------------------------------------

function printDryRunPreview(
  byRace: Map<string, { raceFound: boolean; raceId: string | null; challengers: ChallengerEntry[] }>
): void {
  console.log('\n=== DRY RUN — pass --commit to write to DB ===\n');

  let totalFound = 0;
  let totalMissing = 0;

  for (const [positionName, info] of byRace) {
    const statusIcon = info.raceFound ? '✓' : '✗ RACE NOT FOUND';
    console.log(`\n[${statusIcon}] ${positionName} (${info.challengers.length} challengers)`);
    if (info.raceFound) {
      totalFound += info.challengers.length;
    } else {
      totalMissing += info.challengers.length;
    }
    for (const ch of info.challengers) {
      console.log(`      ${ch.full_name} [external_id: ${ch.external_id}]`);
    }
  }

  console.log('\n--- Summary ---');
  console.log(`  Races found:        ${[...byRace.values()].filter(v => v.raceFound).length}`);
  console.log(`  Races missing:      ${[...byRace.values()].filter(v => !v.raceFound).length}`);
  console.log(`  Challengers ready:  ${totalFound}`);
  console.log(`  Challengers skipped (race not found): ${totalMissing}`);

  console.log('\n--- Incumbent status updates ---');
  for (const update of INCUMBENT_STATUS_UPDATES) {
    console.log(`  [${update.race_position_name}] ${update.full_name} → ${update.new_status}`);
    console.log(`    Reason: ${update.reason}`);
  }

  console.log('\nRun with --commit to execute inserts.');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const client = await pool.connect();

  try {
    console.log('\n[ingest-ca-sos-2026-challengers] Starting...');
    console.log(`  Mode: ${isDryRun ? 'DRY RUN (preview only)' : 'COMMIT (writing to DB)'}`);

    // 1. Resolve election
    const electionId = await getElectionId(client);
    console.log(`  Election ID: ${electionId}`);

    // 2. Group challengers by race and resolve race IDs
    const byRace = new Map<
      string,
      { raceFound: boolean; raceId: string | null; challengers: ChallengerEntry[] }
    >();

    for (const entry of CHALLENGERS) {
      if (!byRace.has(entry.race_position_name)) {
        const raceId = await getRaceIdByPosition(client, electionId, entry.race_position_name);
        byRace.set(entry.race_position_name, {
          raceFound: raceId !== null,
          raceId,
          challengers: [],
        });
        if (!raceId) {
          console.warn(`  WARN: Race not found: "${entry.race_position_name}"`);
        }
      }
      byRace.get(entry.race_position_name)!.challengers.push(entry);
    }

    // 3. Dry-run: preview and exit
    if (isDryRun) {
      printDryRunPreview(byRace);
      return;
    }

    // 4. Commit mode: insert within transaction
    await client.query('BEGIN');

    let inserted = 0;
    let updated = 0;
    let skipped = 0;
    let raceMissed = 0;

    for (const [positionName, info] of byRace) {
      if (!info.raceFound || !info.raceId) {
        console.warn(`  SKIP (race not found): ${positionName} — ${info.challengers.length} candidates skipped`);
        raceMissed += info.challengers.length;
        continue;
      }

      console.log(`\n  Processing: ${positionName} (race_id: ${info.raceId})`);

      for (const entry of info.challengers) {
        const result = await upsertChallenger(client, info.raceId, entry);
        const icon = result.action === 'inserted' ? '+' : result.action === 'updated' ? '~' : '=';
        console.log(`    [${icon}] ${result.action.padEnd(8)} ${entry.full_name}`);

        if (result.action === 'inserted') inserted++;
        else if (result.action === 'updated') updated++;
        else skipped++;
      }
    }

    // 5. Apply incumbent status corrections
    console.log('\n  Applying incumbent status corrections...');
    let incumbentUpdated = 0;
    let incumbentNotFound = 0;

    for (const update of INCUMBENT_STATUS_UPDATES) {
      const raceId = await getRaceIdByPosition(client, electionId, update.race_position_name);
      if (!raceId) {
        console.warn(`  WARN: Race not found for incumbent update: "${update.race_position_name}"`);
        incumbentNotFound++;
        continue;
      }
      const result = await applyIncumbentStatusUpdate(client, raceId, update);
      const icon = result.action === 'updated' ? '~' : '=';
      console.log(`    [${icon}] ${result.action.padEnd(9)} [${update.race_position_name}] ${update.full_name} → ${update.new_status}`);
      if (result.action === 'updated') incumbentUpdated++;
      else incumbentNotFound++;
    }

    await client.query('COMMIT');

    console.log('\n=== COMMIT COMPLETE ===');
    console.log(`  Challengers inserted: ${inserted}`);
    console.log(`  Challengers updated:  ${updated}`);
    console.log(`  Challengers skipped (name collision): ${skipped}`);
    console.log(`  Challengers skipped (race not found): ${raceMissed}`);
    console.log(`  Total challengers processed: ${CHALLENGERS.length}`);
    console.log(`  Incumbent status corrections applied: ${incumbentUpdated}`);
    console.log(`  Incumbent corrections not needed (already correct or not found): ${incumbentNotFound}`);

  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('\nERROR:', (err as Error).message);
    console.error((err as Error).stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
