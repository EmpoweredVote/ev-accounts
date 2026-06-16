/**
 * seed-national-house-reps.ts
 *
 * Seeds the currently-UNSEEDED US House representatives into
 *   essentials.politicians + essentials.offices
 * FK-linked to existing essentials.districts (district_type='NATIONAL_LOWER')
 * rows via tiger_geoid. Geofencing is already complete (Phase 116): every
 * NATIONAL_LOWER district has a tiger_geoid; only ~137/435 have a linked rep.
 *
 * Source: unitedstates/congress-legislators legislators-current.yaml
 *
 * Strategy: iterate the GAP (unseeded districts), not the roster. For each
 * NATIONAL_LOWER district with no linked office, look up the current House rep
 * for that district from the YAML by tiger_geoid. This auto-handles:
 *   - DC (already 3/3 seeded → no unseeded districts → skipped)
 *   - territories PR/GU/VI/AS/MP (no NATIONAL_LOWER district rows → never queried)
 *   - genuine vacancies (unseeded district with no current YAML rep → reported, not inserted)
 *
 * This script NEVER writes to the DB. It only SELECTs, then either prints a
 * coverage report (--dry-run, default) or generates a reviewable SQL migration
 * (--generate). Applying the migration is plan 125-02.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/seed-national-house-reps.ts --dry-run
 *   npx tsx scripts/seed-national-house-reps.ts --generate
 *
 * Insert pattern: migration 311 (VA federal officials).
 * Shared US House chamber UUID: c2facc31-7b13-428c-b7b9-32d0d3b95f76
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as yaml from 'js-yaml';

// ─── Constants ──────────────────────────────────────────────────────────────

const YAML_URL =
  'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml';
const US_HOUSE_CHAMBER = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76';
const MIGRATIONS_DIR = path.join(process.cwd(), 'migrations');
const TMP_YAML = path.join(process.cwd(), '.tmp-legislators-current.yaml');

const MODE_GENERATE = process.argv.includes('--generate');
// default is dry-run

// USPS → 2-digit state FIPS (50 states + DC).
const USPS_TO_FIPS: Record<string, string> = {
  AL: '01', AK: '02', AZ: '04', AR: '05', CA: '06', CO: '08', CT: '09',
  DE: '10', DC: '11', FL: '12', GA: '13', HI: '15', ID: '16', IL: '17',
  IN: '18', IA: '19', KS: '20', KY: '21', LA: '22', ME: '23', MD: '24',
  MA: '25', MI: '26', MN: '27', MS: '28', MO: '29', MT: '30', NE: '31',
  NV: '32', NH: '33', NJ: '34', NM: '35', NY: '36', NC: '37', ND: '38',
  OH: '39', OK: '40', OR: '41', PA: '42', RI: '44', SC: '45', SD: '46',
  TN: '47', TX: '48', UT: '49', VT: '50', VA: '51', WA: '53', WV: '54',
  WI: '55', WY: '56',
};

// ─── DB Pool ──────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Helpers ────────────────────────────────────────────────────────────────

function downloadWithRedirects(url: string, destPath: string, depth = 0): Promise<void> {
  return new Promise((resolve, reject) => {
    if (depth > 5) return reject(new Error(`Too many redirects (>5) for ${url}`));
    if (fs.existsSync(destPath) && fs.statSync(destPath).size > 0) return resolve();
    if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        const loc = response.headers.location;
        if (!loc) return reject(new Error(`Redirect missing Location for ${url}`));
        return downloadWithRedirects(loc, destPath, depth + 1).then(resolve).catch(reject);
      }
      if (response.statusCode !== 200) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
      reject(err);
    });
  });
}

const sqlStr = (s: string) => s.replace(/'/g, "''");

function normalizeParty(p: string): string {
  if (p === 'Democrat') return 'Democratic';
  return p; // Republican, Independent pass through
}

// ─── Roster types ─────────────────────────────────────────────────────────────

interface Rep {
  bioguide: string;
  fullName: string;
  firstName: string;
  lastName: string;
  party: string;       // normalized
  usps: string;        // 2-letter
  district: number;    // 0 = at-large
  tigerGeoid: string;  // FIPS + zero-padded CD
  externalId: number;  // -(fips*1000 + cd)
}

function buildRoster(legislators: any[]): { byGeoid: Map<string, Rep>; skipped: string[] } {
  const byGeoid = new Map<string, Rep>();
  const skipped: string[] = [];
  for (const leg of legislators) {
    const terms = leg.terms;
    if (!Array.isArray(terms) || terms.length === 0) continue;
    const term = terms[terms.length - 1]; // current term = last entry
    if (term.type !== 'rep') continue;     // House (and delegates)
    const usps: string = term.state;
    const fips = USPS_TO_FIPS[usps];
    if (!fips) { skipped.push(`${leg.id?.bioguide ?? '?'} (${usps}) — territory/no FIPS`); continue; }
    const district = typeof term.district === 'number' ? term.district : 0;
    if (district < 0) { skipped.push(`${leg.id?.bioguide} (${usps}) — district=${district} (unknown)`); continue; }
    const tigerGeoid = `${fips}${String(district).padStart(2, '0')}`;
    const name = leg.name ?? {};
    const fullName = (name.official_full && String(name.official_full).trim())
      || `${name.first ?? ''} ${name.last ?? ''}`.trim();
    const rep: Rep = {
      bioguide: leg.id?.bioguide ?? '',
      fullName,
      firstName: name.first ?? '',
      lastName: name.last ?? '',
      party: normalizeParty(term.party ?? ''),
      usps,
      district,
      tigerGeoid,
      externalId: -(parseInt(fips, 10) * 1000 + district),
    };
    byGeoid.set(tigerGeoid, rep);
  }
  return { byGeoid, skipped };
}

// ─── Migration generation ──────────────────────────────────────────────────────

function renderInsertBlock(rep: Rep): string {
  return `
-- ----- ${rep.usps}-${rep.district === 0 ? 'AL' : rep.district}: ${rep.fullName} (${rep.party}) — bioguide ${rep.bioguide}, tiger_geoid '${rep.tigerGeoid}', external_id ${rep.externalId} -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '${sqlStr(rep.fullName)}', '${sqlStr(rep.firstName)}', '${sqlStr(rep.lastName)}', '${sqlStr(rep.party)}',
          true, false, false, true, ${rep.externalId})
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, '${US_HOUSE_CHAMBER}', p.id,
       'U.S. Representative', '${rep.usps}', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.tiger_geoid = '${rep.tigerGeoid}' AND d.district_type = 'NATIONAL_LOWER'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '${US_HOUSE_CHAMBER}'
  );
`;
}

function renderMigration(matched: { rep: Rep }[], migrationNum: number): string {
  const minExt = Math.min(...matched.map((m) => m.rep.externalId));
  const maxExt = Math.max(...matched.map((m) => m.rep.externalId));
  const blocks = matched.map((m) => renderInsertBlock(m.rep)).join('\n');
  return `-- Migration ${migrationNum}: National US House Representatives (Tier 1 seeding)
--
-- Seeds ${matched.length} currently-unseeded US House reps (politician + office records),
-- FK-linked to existing essentials.districts NATIONAL_LOWER rows via tiger_geoid.
-- Source: unitedstates/congress-legislators legislators-current.yaml
-- Generated by backend/scripts/seed-national-house-reps.ts
--
-- MATCHED reps only — genuine vacancies are intentionally excluded (no current member).
-- party normalized Democrat->Democratic (v2.6 SACC-03). external_id = -(state_fips*1000 + cd).
-- external_id range in this batch: ${minExt}..${maxExt}.
-- Shared US House chamber UUID: ${US_HOUSE_CHAMBER}
-- Idempotent: ON CONFLICT (external_id) DO NOTHING + NOT EXISTS (district_id, chamber_id) guard.

BEGIN;

-- Pre-flight assertions
DO $$
DECLARE
  v_chamber INT;
  v_unseeded INT;
BEGIN
  SELECT COUNT(*) INTO v_chamber FROM essentials.chambers
   WHERE id = '${US_HOUSE_CHAMBER}' AND name = 'U.S. House of Representatives';
  IF v_chamber != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: US House chamber ${US_HOUSE_CHAMBER} not found exactly once (got %)', v_chamber;
  END IF;

  SELECT COUNT(*) INTO v_unseeded
  FROM essentials.districts d
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type = 'NATIONAL_LOWER' AND o.politician_id IS NULL;
  IF v_unseeded < ${matched.length} THEN
    RAISE EXCEPTION 'Pre-flight FAILED: only % unseeded NATIONAL_LOWER districts, need >= ${matched.length}', v_unseeded;
  END IF;

  RAISE NOTICE 'Pre-flight passed: chamber=%, unseeded districts=%', v_chamber, v_unseeded;
END $$;

${blocks}

-- office_id backfill (scoped to this batch's external_id range)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -56999 AND -1000
  AND p.office_id IS NULL;

COMMIT;
`;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[seed-national-house-reps] mode:', MODE_GENERATE ? 'GENERATE' : 'DRY-RUN');

  // 1. Fetch + parse YAML
  console.log('  Downloading legislators-current.yaml ...');
  await downloadWithRedirects(YAML_URL, TMP_YAML);
  const legislators = yaml.load(fs.readFileSync(TMP_YAML, 'utf-8')) as any[];
  console.log(`  Parsed ${legislators.length} current legislators`);

  // 2. Build roster (current House terms, keyed by tiger_geoid)
  const { byGeoid, skipped } = buildRoster(legislators);
  console.log(`  House roster (50 states + DC): ${byGeoid.size} reps; ${skipped.length} skipped (territories/unknown)`);

  // 3. Query unseeded NATIONAL_LOWER districts
  const res = await pool.query(`
    SELECT d.id, d.tiger_geoid
    FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.district_type = 'NATIONAL_LOWER' AND o.politician_id IS NULL
    ORDER BY d.tiger_geoid
  `);
  const unseeded = res.rows as { id: string; tiger_geoid: string }[];
  console.log(`  Unseeded NATIONAL_LOWER districts: ${unseeded.length}`);

  // 4. Match
  const matched: { rep: Rep }[] = [];
  const vacancies: string[] = [];
  const matchedGeoids = new Set<string>();
  for (const d of unseeded) {
    const rep = byGeoid.get(d.tiger_geoid);
    if (rep) { matched.push({ rep }); matchedGeoids.add(d.tiger_geoid); }
    else vacancies.push(d.tiger_geoid);
  }
  // YAML reps whose district was NOT in the unseeded set = already seeded (or DC/territory)
  const alreadySeeded: string[] = [];
  for (const [geoid, rep] of byGeoid) {
    if (!matchedGeoids.has(geoid)) alreadySeeded.push(`${rep.usps}-${rep.district === 0 ? 'AL' : rep.district} (${geoid})`);
  }

  // 5. Report
  console.log('\n=== Coverage Report ===');
  console.log(`  MATCHED (insert generated):   ${matched.length}`);
  console.log(`  VACANCY (no current member):  ${vacancies.length}`);
  console.log(`  ALREADY-SEEDED (not in gap):  ${alreadySeeded.length}`);
  if (vacancies.length) {
    console.log('\n  Vacancy districts (unseeded, no current YAML rep):');
    vacancies.forEach((g) => console.log(`    ${g}`));
  }
  if (skipped.length) {
    console.log('\n  Skipped roster entries (territories/unknown district):');
    skipped.forEach((s) => console.log(`    ${s}`));
  }

  // Per-state matched breakdown
  const byState = new Map<string, number>();
  matched.forEach((m) => byState.set(m.rep.usps, (byState.get(m.rep.usps) ?? 0) + 1));
  console.log('\n  Matched by state:');
  [...byState.entries()].sort().forEach(([s, n]) => process.stdout.write(`    ${s}:${n}`));
  console.log('');

  if (!MODE_GENERATE) {
    console.log('\nDRY-RUN complete — no file written, no DB rows changed.');
    await pool.end();
    return;
  }

  // 6. Generate migration
  // Pre-flight migration number: disk max + 1, cross-checked against schema_migrations.
  const diskNums = fs.readdirSync(MIGRATIONS_DIR)
    .map((f) => parseInt(f.match(/^(\d+)/)?.[1] ?? '0', 10))
    .filter((n) => !Number.isNaN(n));
  const diskMax = Math.max(0, ...diskNums);
  let dbMax = 0;
  try {
    const mres = await pool.query(`SELECT MAX(version::int) AS m FROM supabase_migrations.schema_migrations WHERE version ~ '^[0-9]+$'`);
    dbMax = mres.rows[0]?.m ?? 0;
  } catch { /* schema_migrations may not track psql applies; disk wins */ }
  const migrationNum = Math.max(diskMax, dbMax) + 1;
  const outFile = path.join(MIGRATIONS_DIR, `${migrationNum}_national_house_reps.sql`);
  fs.writeFileSync(outFile, renderMigration(matched, migrationNum), 'utf-8');
  console.log(`\nGENERATED: ${outFile}`);
  console.log(`  ${matched.length} insert blocks; review then apply in plan 125-02.`);
  await pool.end();
}

main().catch((err) => {
  console.error('[seed-national-house-reps] Fatal error:', err);
  process.exit(1);
});
