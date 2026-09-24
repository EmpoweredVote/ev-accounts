/**
 * seed-la-county-netfile.ts — Discovery + seeding of CTL candidate committees
 * from 2024 LA County Netfile LACO bulk export.
 *
 * UPDATED (2026-04-15): Changed from 8-official targeted approach to CTL-filtered
 * candidate discovery. County supervisors (Solis, Mitchell, Horvath, Hahn, Barger,
 * Hochman, Luna, Prang) are NOT in 2024 Netfile LACO data — they file via Cal-Access
 * at the state level and will be added in a separate Cal-Access pass.
 *
 * Approach:
 *   1. Download 2024 Netfile LACO Excel bulk export (same ASP.NET postback as netfileAdapter)
 *   2. Filter Schedule A rows to Committee_Type = 'CTL' only (excludes PACs, ballot measures)
 *   3. For each unique CTL filer: parse candidate name + office from committee name
 *   4. Seed essentials.politicians (if not exists) + politician_sources (confirmed)
 *
 * Result: ~176 LA County local candidates (school board, water board, college board, etc.)
 *
 * Usage:
 *   npx tsx scripts/seed-la-county-netfile.ts --dry-run    # preview, no DB writes
 *   npx tsx scripts/seed-la-county-netfile.ts              # write to DB
 *   npx tsx scripts/seed-la-county-netfile.ts --limit 10  # seed first N filers (testing)
 */

import 'dotenv/config';
import * as XLSX from 'xlsx';
import AdmZip from 'adm-zip';
import { Pool } from 'pg';

// ---------------------------------------------------------------------------
// Env + args
// ---------------------------------------------------------------------------

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const isDryRun = process.argv.includes('--dry-run');
const limitIdx = process.argv.indexOf('--limit');
const limit = limitIdx !== -1 ? parseInt(process.argv[limitIdx + 1] ?? '999', 10) : Infinity;

// ---------------------------------------------------------------------------
// DB pool
// ---------------------------------------------------------------------------

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Netfile download — same WebForms postback as netfileAdapter.ts
// ---------------------------------------------------------------------------

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const NETFILE_AGENCY = 'LACO';
const YEAR = 2024;

function extractHiddenField(html: string, fieldName: string): string {
  const patterns = [
    new RegExp(`id="${fieldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`name="${fieldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*name="${fieldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}"`, 'i'),
  ];
  for (const p of patterns) {
    const m = html.match(p);
    if (m) return m[1] ?? '';
  }
  return '';
}

function extractCookies(response: Response): string {
  const h = response.headers.get('set-cookie');
  if (!h) return '';
  return h
    .split(/,(?=[^;]+=[^;]+;|[^;]+=)/)
    .map((c) => c.trim().split(';')[0]?.trim() ?? '')
    .filter(Boolean)
    .join('; ');
}

async function downloadNetfileExcel(): Promise<Buffer> {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;
  console.log(`[netfile] Fetching ${pageUrl} for year=${YEAR}...`);

  const getResp = await fetch(pageUrl, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0' },
  });
  if (!getResp.ok) throw new Error(`GET page failed: HTTP ${getResp.status}`);

  const html = await getResp.text();
  const cookies = extractCookies(getResp);

  const formBody = new URLSearchParams({
    __EVENTTARGET: 'ctl00$phBody$GetExcel', // Export All (includes non-amended)
    __EVENTARGUMENT: '',
    __VIEWSTATE: extractHiddenField(html, '__VIEWSTATE'),
    __VIEWSTATEGENERATOR: extractHiddenField(html, '__VIEWSTATEGENERATOR'),
    __EVENTVALIDATION: extractHiddenField(html, '__EVENTVALIDATION'),
    'ctl00$phBody$DateSelect': String(YEAR),
  });

  const postResp = await fetch(pageUrl, {
    method: 'POST',
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0',
      'Content-Type': 'application/x-www-form-urlencoded',
      Referer: pageUrl,
      Cookie: cookies,
    },
    body: formBody.toString(),
  });

  if (!postResp.ok) throw new Error(`POST failed: HTTP ${postResp.status}`);
  const ct = postResp.headers.get('content-type') ?? '';
  if (ct.includes('text/html')) throw new Error(`POST returned HTML — ViewState extraction may have failed`);

  const raw = Buffer.from(await postResp.arrayBuffer());
  console.log(`[netfile] Downloaded ${(raw.length / 1024 / 1024).toFixed(1)} MB (${ct})`);

  // Netfile returns a ZIP containing the XLSX
  if (ct.includes('zip') || (raw[0] === 0x50 && raw[1] === 0x4b)) {
    const zip = new AdmZip(raw);
    const entry = zip.getEntries().find((e) => e.entryName.toLowerCase().endsWith('.xlsx'));
    if (!entry) throw new Error(`ZIP contains no .xlsx entry`);
    const xlsxBuf = entry.getData();
    console.log(`[netfile] Extracted ${entry.entryName} (${(xlsxBuf.length / 1024 / 1024).toFixed(1)} MB) from ZIP`);
    return xlsxBuf;
  }

  return raw;
}

// ---------------------------------------------------------------------------
// Parse CTL filers from Excel
// ---------------------------------------------------------------------------

interface FilerRecord {
  filerId: string;
  committeeName: string;  // raw Filer_NamL
  candNamL: string;       // Cand_NamL (candidate last name, often empty)
  candNamF: string;       // Cand_NamF (candidate first name, often empty)
  rowCount: number;
}

function extractCtlFilers(xlsxBuf: Buffer): FilerRecord[] {
  const wb = XLSX.read(xlsxBuf, { type: 'buffer', cellDates: true });
  const ws = wb.Sheets['A-Contributions'];
  if (!ws) throw new Error(`Sheet "A-Contributions" not found. Sheets: ${wb.SheetNames.join(', ')}`);

  const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });
  const schedA = rows.filter((r) => r['Form_Type'] === 'A' && r['Committee_Type'] === 'CTL');

  console.log(`[parse] Total rows: ${rows.length}, Schedule A CTL rows: ${schedA.length}`);

  const filerMap = new Map<string, FilerRecord>();

  for (const row of schedA) {
    const filerId = String(row['Filer_ID'] ?? '').trim();
    if (!filerId || filerId.toLowerCase() === 'pending') continue;

    const existing = filerMap.get(filerId);
    if (existing) {
      existing.rowCount++;
      // Prefer non-empty candidate name fields
      if (!existing.candNamL && row['Cand_NamL']) existing.candNamL = String(row['Cand_NamL']).trim();
      if (!existing.candNamF && row['Cand_NamF']) existing.candNamF = String(row['Cand_NamF']).trim();
    } else {
      filerMap.set(filerId, {
        filerId,
        committeeName: String(row['Filer_NamL'] ?? '').trim(),
        candNamL: String(row['Cand_NamL'] ?? '').trim(),
        candNamF: String(row['Cand_NamF'] ?? '').trim(),
        rowCount: 1,
      });
    }
  }

  return [...filerMap.values()].sort((a, b) => b.rowCount - a.rowCount);
}

// ---------------------------------------------------------------------------
// Committee name parsing
// ---------------------------------------------------------------------------

function toTitleCase(str: string): string {
  return str
    .toLowerCase()
    .replace(/\b\w/g, (c: string) => c.toUpperCase())
    .trim();
}

interface ParsedCandidate {
  fullName: string;
  firstName: string;
  lastName: string;
  officeTitle: string;
  rawCommitteeName: string;
}

function parseCommitteeName(filer: FilerRecord): ParsedCandidate {
  // If CA-460 Cand_NamL/F are populated, use them directly
  if (filer.candNamL && filer.candNamF) {
    const fullName = toTitleCase(`${filer.candNamF} ${filer.candNamL}`);
    return {
      fullName,
      firstName: toTitleCase(filer.candNamF),
      lastName: toTitleCase(filer.candNamL),
      officeTitle: extractOfficeFromCommittee(filer.committeeName),
      rawCommitteeName: filer.committeeName,
    };
  }
  if (filer.candNamL && !filer.candNamF) {
    const fullName = toTitleCase(filer.candNamL);
    return {
      fullName,
      firstName: '',
      lastName: fullName,
      officeTitle: extractOfficeFromCommittee(filer.committeeName),
      rawCommitteeName: filer.committeeName,
    };
  }

  // Parse from committee name
  let name = filer.committeeName;

  // Handle "Last, First" format (e.g., "Mercado - Fortine, Gloria")
  const commaMatch = name.match(/^([^,]+),\s*(.+)$/);
  if (commaMatch) {
    const lastName = commaMatch[1].trim();
    const firstName = commaMatch[2].trim();
    const full = toTitleCase(`${firstName} ${lastName}`);
    return {
      fullName: full,
      firstName: toTitleCase(firstName),
      lastName: toTitleCase(lastName),
      officeTitle: 'Local Official',
      rawCommitteeName: filer.committeeName,
    };
  }

  // Strip year suffix (4-digit number at end, with optional comma/space)
  name = name.replace(/[,\s]+\d{4}\s*$/, '').trim();

  // Strip common prefixes
  const prefixes = [
    /^Committee\s+to\s+Re-?Elect\s+/i,
    /^Committee\s+to\s+Elect\s+/i,
    /^Committee\s+to\s+Support\s+/i,
    /^Campaign\s+to\s+Elect\s+/i,
    /^Committee\s+for\s+/i,
    /^Re-?Elect\s+/i,
    /^Elect\s+/i,
    /^Friends\s+(?:to\s+|of\s+)/i,
  ];
  for (const prefix of prefixes) {
    name = name.replace(prefix, '');
  }

  // Split on " for " or " 4 " to separate candidate name from office
  const forMatch = name.match(/^(.+?)\s+(?:for|4)\s+(.+)$/i);
  if (forMatch) {
    const candidatePart = forMatch[1].trim();
    const officePart = forMatch[2].trim();

    const fullName = toTitleCase(candidatePart);
    const parts = fullName.split(/\s+/);
    const firstName = parts.length > 1 ? parts.slice(0, -1).join(' ') : '';
    const lastName = parts[parts.length - 1] ?? fullName;

    return {
      fullName,
      firstName,
      lastName,
      officeTitle: toTitleCase(officePart),
      rawCommitteeName: filer.committeeName,
    };
  }

  // No "for" separator — treat entire thing as candidate name
  const fullName = toTitleCase(name);
  const parts = fullName.split(/\s+/);
  const firstName = parts.length > 1 ? parts.slice(0, -1).join(' ') : '';
  const lastName = parts[parts.length - 1] ?? fullName;

  return {
    fullName,
    firstName,
    lastName,
    officeTitle: 'Local Official',
    rawCommitteeName: filer.committeeName,
  };
}

function extractOfficeFromCommittee(committeeName: string): string {
  let name = committeeName.replace(/[,\s]+\d{4}\s*$/, '').trim();
  const prefixes = [
    /^Committee\s+to\s+Re-?Elect\s+/i,
    /^Committee\s+to\s+Elect\s+/i,
    /^Re-?Elect\s+/i,
    /^Elect\s+/i,
  ];
  for (const prefix of prefixes) name = name.replace(prefix, '');
  const forMatch = name.match(/^.+?\s+(?:for|4)\s+(.+)$/i);
  if (forMatch) return toTitleCase(forMatch[1].trim());
  return 'Local Official';
}

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

async function findPoliticianByName(fullName: string): Promise<string | null> {
  const res = await pool.query<{ id: string }>(
    `SELECT id FROM essentials.politicians WHERE full_name = $1 LIMIT 1`,
    [fullName]
  );
  return res.rows[0]?.id ?? null;
}

async function upsertPolitician(parsed: ParsedCandidate): Promise<{ id: string; inserted: boolean }> {
  // Check existing first
  const existing = await findPoliticianByName(parsed.fullName);
  if (existing) return { id: existing, inserted: false };

  // Insert new
  const res = await pool.query<{ id: string }>(
    `INSERT INTO essentials.politicians
       (full_name, first_name, last_name, source, is_active, is_vacant, is_incumbent, is_appointed, is_off_cycle)
     VALUES ($1, $2, $3, 'netfile_laco_2024', true, false, false, false, false)
     ON CONFLICT DO NOTHING
     RETURNING id`,
    [parsed.fullName, parsed.firstName || null, parsed.lastName || null]
  );

  if ((res.rowCount ?? 0) > 0 && res.rows[0]) {
    return { id: res.rows[0].id, inserted: true };
  }

  // ON CONFLICT hit (race condition) — fetch
  const after = await findPoliticianByName(parsed.fullName);
  if (after) return { id: after, inserted: false };
  throw new Error(`Failed to insert or find politician: ${parsed.fullName}`);
}

async function upsertPoliticianSource(
  politicianId: string,
  filerId: string,
  parsed: ParsedCandidate
): Promise<'inserted' | 'exists'> {
  const notes = JSON.stringify({
    committee: parsed.rawCommitteeName,
    office: parsed.officeTitle,
    source: 'LA County Netfile FPPC CA-460',
    year: YEAR,
    seeded_by: 'seed-la-county-netfile.ts',
  });

  const res = await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes, netfile_agency)
     VALUES ($1, 'la_county_netfile', $2, 'confirmed', $3, 'LACO')
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
    [politicianId, filerId, notes]
  );

  return (res.rowCount ?? 0) > 0 ? 'inserted' : 'exists';
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const startMs = Date.now();
  console.log(`[seed-la-county-netfile] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE'}`);
  if (limit < Infinity) console.log(`[seed-la-county-netfile] Limit: first ${limit} CTL filers`);

  // Step 1: Download and parse
  const xlsxBuf = await downloadNetfileExcel();
  const filers = extractCtlFilers(xlsxBuf);
  console.log(`[parse] Found ${filers.length} unique CTL filer(s)`);

  const toProcess = filers.slice(0, limit === Infinity ? filers.length : limit);

  // Step 2: Process each filer
  let politiciansInserted = 0;
  let sourcesInserted = 0;
  let sourcesExisting = 0;
  let skipped = 0;

  const rows: Array<{ filerId: string; fullName: string; office: string; pStatus: string; sStatus: string }> = [];

  for (let i = 0; i < toProcess.length; i++) {
    const filer = toProcess[i];
    const parsed = parseCommitteeName(filer);

    if (!parsed.fullName || parsed.fullName.length < 2) {
      console.warn(`  [SKIP] Filer_ID=${filer.filerId} — could not parse name from "${filer.committeeName}"`);
      skipped++;
      rows.push({ filerId: filer.filerId, fullName: '(parse failed)', office: '', pStatus: 'SKIP', sStatus: '-' });
      continue;
    }

    if (isDryRun) {
      const exists = await findPoliticianByName(parsed.fullName);
      rows.push({
        filerId: filer.filerId,
        fullName: parsed.fullName,
        office: parsed.officeTitle,
        pStatus: exists ? 'exists' : 'would-insert',
        sStatus: 'dry-run',
      });
      continue;
    }

    try {
      const { id: politicianId, inserted: pInserted } = await upsertPolitician(parsed);
      if (pInserted) politiciansInserted++;

      const sResult = await upsertPoliticianSource(politicianId, filer.filerId, parsed);
      if (sResult === 'inserted') sourcesInserted++;
      else sourcesExisting++;

      rows.push({
        filerId: filer.filerId,
        fullName: parsed.fullName,
        office: parsed.officeTitle,
        pStatus: pInserted ? 'inserted' : 'exists',
        sStatus: sResult,
      });
    } catch (err) {
      console.error(`  [ERROR] Filer_ID=${filer.filerId} "${parsed.fullName}": ${err instanceof Error ? err.message : String(err)}`);
      skipped++;
      rows.push({ filerId: filer.filerId, fullName: parsed.fullName, office: parsed.officeTitle, pStatus: 'error', sStatus: 'error' });
    }
  }

  // Step 3: Print results table
  console.log(`\n${'='.repeat(90)}`);
  console.log(`LA COUNTY NETFILE CTL CANDIDATE SEEDING${isDryRun ? ' (DRY-RUN)' : ''} — Year ${YEAR}`);
  console.log('='.repeat(90));
  console.log(
    ' ' +
    'FILER_ID'.padEnd(12) +
    '| ' +
    'FULL NAME'.padEnd(32) +
    '| ' +
    'OFFICE'.padEnd(30) +
    '| POLITICIAN | SOURCE'
  );
  console.log('-'.repeat(90));
  for (const r of rows) {
    console.log(
      ' ' +
      r.filerId.padEnd(12) +
      '| ' +
      r.fullName.substring(0, 30).padEnd(32) +
      '| ' +
      r.office.substring(0, 28).padEnd(30) +
      '| ' +
      r.pStatus.padEnd(11) +
      '| ' +
      r.sStatus
    );
  }
  console.log('-'.repeat(90));

  if (!isDryRun) {
    console.log(`\nPoliticians inserted:       ${politiciansInserted}`);
    console.log(`Politician sources inserted: ${sourcesInserted}`);
    console.log(`Sources already existed:    ${sourcesExisting}`);
    console.log(`Skipped/errors:             ${skipped}`);
  } else {
    const wouldInsert = rows.filter((r) => r.pStatus === 'would-insert').length;
    const wouldExist = rows.filter((r) => r.pStatus === 'exists').length;
    console.log(`\nWould insert new politicians:  ${wouldInsert}`);
    console.log(`Already exist in DB:           ${wouldExist}`);
    console.log(`Would seed sources:            ${rows.filter((r) => r.sStatus === 'dry-run').length}`);
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[seed-la-county-netfile] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async (err) => {
    console.error('[seed-la-county-netfile] Fatal error:', err instanceof Error ? err.message : String(err));
    await pool.end();
    process.exit(1);
  });
