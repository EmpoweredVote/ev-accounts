/**
 * discover-netfile-filers.ts — Read-only discovery script for LA County Netfile Filer_IDs.
 *
 * Downloads the Netfile Excel bulk export for one or more years using the same
 * ASP.NET WebForms postback pattern as netfileAdapter.ts, then fuzzy-matches
 * all Filer_ID + Filer_NamL pairs against 8 target LA County officeholders.
 *
 * Prints ALL matches per politician so the operator can decide which Filer_IDs
 * are correct (candidates often have multiple committees across election cycles).
 *
 * Usage:
 *   npx tsx scripts/discover-netfile-filers.ts --year 2024
 *   npx tsx scripts/discover-netfile-filers.ts --all-years         # downloads 2020, 2022, 2024
 *   npx tsx scripts/discover-netfile-filers.ts --all-years --years 2018,2020,2022,2024
 *
 * IMPORTANT: This script is strictly READ-ONLY. It NEVER writes to the database.
 */

import 'dotenv/config';
import * as XLSX from 'xlsx';

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);

const yearArgIdx = args.indexOf('--year');
const allYears = args.includes('--all-years');
const customYearsArgIdx = args.indexOf('--years');

let yearsToDownload: number[] = [];

if (allYears) {
  if (customYearsArgIdx !== -1 && args[customYearsArgIdx + 1]) {
    // Custom years list: --years 2018,2020,2022,2024
    yearsToDownload = args[customYearsArgIdx + 1]
      .split(',')
      .map((y) => parseInt(y.trim(), 10))
      .filter((y) => !isNaN(y));
  } else {
    yearsToDownload = [2020, 2022, 2024];
  }
} else if (yearArgIdx !== -1 && args[yearArgIdx + 1]) {
  const parsed = parseInt(args[yearArgIdx + 1], 10);
  if (isNaN(parsed)) {
    console.error(`ERROR: --year value is not a valid number: "${args[yearArgIdx + 1]}"`);
    process.exit(1);
  }
  yearsToDownload = [parsed];
} else {
  console.error('ERROR: Specify --year YYYY or --all-years');
  console.error('  npx tsx scripts/discover-netfile-filers.ts --year 2024');
  console.error('  npx tsx scripts/discover-netfile-filers.ts --all-years');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Target officeholders — the 8 LA County politicians we need Filer_IDs for
// ---------------------------------------------------------------------------

interface TargetOfficial {
  displayName: string;   // Human-readable label
  officeTitle: string;   // For output context
  searchTerm: string;    // Lowercase last name to fuzzy-match against Filer_NamL
}

const TARGET_OFFICIALS: TargetOfficial[] = [
  { displayName: 'Hilda L. Solis',      officeTitle: 'Supervisor D1',    searchTerm: 'solis'    },
  { displayName: 'Holly J. Mitchell',   officeTitle: 'Supervisor D2',    searchTerm: 'mitchell' },
  { displayName: 'Lindsey P. Horvath',  officeTitle: 'Supervisor D3',    searchTerm: 'horvath'  },
  { displayName: 'Janice Hahn',         officeTitle: 'Supervisor D4',    searchTerm: 'hahn'     },
  { displayName: 'Kathryn Barger',      officeTitle: 'Supervisor D5',    searchTerm: 'barger'   },
  { displayName: 'Nathan Hochman',      officeTitle: 'District Attorney', searchTerm: 'hochman'  },
  { displayName: 'Robert Luna',         officeTitle: 'Sheriff',          searchTerm: 'luna'     },
  { displayName: 'Jeffrey Prang',       officeTitle: 'Assessor',         searchTerm: 'prang'    },
];

// ---------------------------------------------------------------------------
// Netfile WebForms postback — copied from netfileAdapter.ts
// ---------------------------------------------------------------------------

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const NETFILE_AGENCY = 'LACO';
const SCHEDULE_A_SHEET = 'A-Contributions';
const FORM_TYPE_A = 'A';

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function extractHiddenField(html: string, fieldName: string): string {
  const patterns = [
    new RegExp(`id="${escapeRegex(fieldName)}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`name="${escapeRegex(fieldName)}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*id="${escapeRegex(fieldName)}"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*name="${escapeRegex(fieldName)}"`, 'i'),
  ];

  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match) return match[1] ?? '';
  }

  const viewstatePattern = new RegExp(
    `<input[^>]+id="${escapeRegex(fieldName)}"[^>]*value="([^"]*)"`,
    'i'
  );
  const vsMatch = html.match(viewstatePattern);
  if (vsMatch) return vsMatch[1] ?? '';

  return '';
}

function extractCookies(response: Response): string {
  const setCookieHeader = response.headers.get('set-cookie');
  if (!setCookieHeader) return '';
  return setCookieHeader
    .split(/,(?=[^;]+=[^;]+;|[^;]+=)/)
    .map((cookie) => cookie.trim().split(';')[0]?.trim() ?? '')
    .filter(Boolean)
    .join('; ');
}

async function downloadNetfileExcel(year: number): Promise<Buffer | null> {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;

  console.log(`\n[netfile] GET ${pageUrl} (extracting VIEWSTATE for year=${year})...`);

  const getResp = await fetch(pageUrl, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    },
  });

  if (!getResp.ok) {
    console.error(`[netfile] ERROR: GET page failed: HTTP ${getResp.status}`);
    return null;
  }

  const html = await getResp.text();
  const cookies = extractCookies(getResp);

  const viewState = extractHiddenField(html, '__VIEWSTATE');
  const viewStateGenerator = extractHiddenField(html, '__VIEWSTATEGENERATOR');
  const eventValidation = extractHiddenField(html, '__EVENTVALIDATION');

  if (!viewState) {
    console.warn(`[netfile] WARNING: __VIEWSTATE not found for year=${year} — postback may fail`);
  }

  const formBody = new URLSearchParams({
    __EVENTTARGET: 'ctl00$phBody$GetExcelAmend',
    __EVENTARGUMENT: '',
    __VIEWSTATE: viewState,
    __VIEWSTATEGENERATOR: viewStateGenerator,
    __EVENTVALIDATION: eventValidation,
    'ctl00$phBody$ddlYear': String(year),
  });

  const postHeaders: Record<string, string> = {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
    'Content-Type': 'application/x-www-form-urlencoded',
    Referer: pageUrl,
    Accept:
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,*/*;q=0.8',
  };

  if (cookies) {
    postHeaders['Cookie'] = cookies;
  }

  console.log(`[netfile] POST ${pageUrl} requesting year=${year} Excel export...`);

  const postResp = await fetch(pageUrl, {
    method: 'POST',
    headers: postHeaders,
    body: formBody.toString(),
  });

  if (!postResp.ok) {
    console.error(`[netfile] ERROR: POST failed for year=${year}: HTTP ${postResp.status}`);
    return null;
  }

  const contentType = postResp.headers.get('content-type') ?? '';
  if (contentType.includes('text/html')) {
    console.error(
      `[netfile] ERROR: POST returned HTML instead of Excel for year=${year}. ` +
        `Content-Type: ${contentType}. ` +
        'Possible causes: year not available in Netfile, VIEWSTATE extraction failed, site changed.'
    );
    return null;
  }

  const arrayBuffer = await postResp.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  console.log(`[netfile] Downloaded year=${year} Excel (${(buffer.length / 1024).toFixed(0)} KB)`);
  return buffer;
}

// ---------------------------------------------------------------------------
// Row aggregation types
// ---------------------------------------------------------------------------

interface FilerSummary {
  filerId: string;
  filerNamL: string;
  filingCount: number;
  years: Set<number>;
}

// ---------------------------------------------------------------------------
// Parse Excel and extract unique Filer_ID + Filer_NamL entries
// ---------------------------------------------------------------------------

function extractFilerSummaries(
  buffer: Buffer,
  year: number
): Map<string, FilerSummary> {
  const workbook = XLSX.read(buffer, { type: 'buffer', cellDates: true });

  const ws = workbook.Sheets[SCHEDULE_A_SHEET];
  if (!ws) {
    const available = workbook.SheetNames.join(', ');
    console.error(
      `[netfile] ERROR: Sheet "${SCHEDULE_A_SHEET}" not found in year=${year} workbook. ` +
        `Available: ${available}`
    );
    return new Map();
  }

  const allRows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });

  // Filter to Schedule A, non-memo rows
  const scheduleARows = allRows.filter(
    (row) =>
      row['Form_Type'] === FORM_TYPE_A &&
      (!row['Memo_Code'] || String(row['Memo_Code']).trim() === '')
  );

  console.log(
    `[netfile] year=${year}: total_rows=${allRows.length} schedule_a_non_memo=${scheduleARows.length}`
  );

  // Build Filer_ID summary map
  const summaryMap = new Map<string, FilerSummary>();

  for (const row of scheduleARows) {
    const filerId = String(row['Filer_ID'] ?? '').trim();
    const filerNamL = String(row['Filer_NamL'] ?? '').trim();

    if (!filerId) continue;

    const existing = summaryMap.get(filerId);
    if (existing) {
      existing.filingCount++;
      existing.years.add(year);
      // Use longest/most recent Filer_NamL
      if (filerNamL.length > existing.filerNamL.length) {
        existing.filerNamL = filerNamL;
      }
    } else {
      summaryMap.set(filerId, {
        filerId,
        filerNamL,
        filingCount: 1,
        years: new Set([year]),
      });
    }
  }

  return summaryMap;
}

// ---------------------------------------------------------------------------
// Merge multiple year summaries into one deduplicated map
// ---------------------------------------------------------------------------

function mergeSummaries(
  yearMaps: Array<{ year: number; map: Map<string, FilerSummary> }>
): Map<string, FilerSummary> {
  const merged = new Map<string, FilerSummary>();

  for (const { map } of yearMaps) {
    for (const [filerId, summary] of map.entries()) {
      const existing = merged.get(filerId);
      if (existing) {
        existing.filingCount += summary.filingCount;
        for (const y of summary.years) {
          existing.years.add(y);
        }
        // Prefer longer committee name (usually more descriptive)
        if (summary.filerNamL.length > existing.filerNamL.length) {
          existing.filerNamL = summary.filerNamL;
        }
      } else {
        merged.set(filerId, {
          filerId: summary.filerId,
          filerNamL: summary.filerNamL,
          filingCount: summary.filingCount,
          years: new Set(summary.years),
        });
      }
    }
  }

  return merged;
}

// ---------------------------------------------------------------------------
// Normalize helper — lowercase + remove accents
// ---------------------------------------------------------------------------

function normalizeStr(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

// ---------------------------------------------------------------------------
// Match logic: check if searchTerm appears as a word boundary in filerNamL
// ---------------------------------------------------------------------------

function matchesTerm(filerNamL: string, searchTerm: string): boolean {
  const normalizedNamL = normalizeStr(filerNamL);
  const normalizedTerm = normalizeStr(searchTerm);
  // Word-boundary check: term must appear as a standalone word in the committee name
  // (surrounded by start/end or non-word characters)
  const wordPattern = new RegExp(`(?:^|[^a-z])${escapeRegex(normalizedTerm)}(?:[^a-z]|$)`);
  return wordPattern.test(normalizedNamL);
}

// ---------------------------------------------------------------------------
// Match and print results
// ---------------------------------------------------------------------------

interface MatchResult {
  official: TargetOfficial;
  matches: FilerSummary[];
}

function matchAndPrint(
  officials: TargetOfficial[],
  mergedMap: Map<string, FilerSummary>,
  yearsDownloaded: number[]
): MatchResult[] {
  const yearsLabel = yearsDownloaded.sort((a, b) => a - b).join(', ');
  console.log(`\n${'='.repeat(70)}`);
  console.log(`NETFILE FILER_ID DISCOVERY — YEARS: ${yearsLabel}`);
  console.log(`Total unique Filer_IDs found: ${mergedMap.size}`);
  console.log('='.repeat(70));

  const results: MatchResult[] = [];

  for (const official of officials) {
    const matches: FilerSummary[] = [];

    for (const [, summary] of mergedMap.entries()) {
      if (matchesTerm(summary.filerNamL, official.searchTerm)) {
        matches.push(summary);
      }
    }

    // Sort by filing count descending (highest activity first)
    matches.sort((a, b) => b.filingCount - a.filingCount);

    console.log(`\nTARGET: ${official.displayName} (${official.officeTitle})`);
    if (matches.length === 0) {
      console.log(
        `  NO MATCH: no filer names containing "${official.searchTerm}" found`
      );
    } else {
      for (const m of matches) {
        const yearsStr =
          [...m.years].sort((a, b) => a - b).join(',');
        console.log(
          `  MATCH: Filer_ID=${m.filerId} Filer_NamL="${m.filerNamL}" filingCount=${m.filingCount} years=${yearsStr}`
        );
      }
    }

    results.push({ official, matches });
  }

  console.log(`\n${'='.repeat(70)}`);
  console.log('SUMMARY');
  console.log('='.repeat(70));

  let matchedCount = 0;
  let noMatchCount = 0;
  let multiMatchCount = 0;

  for (const r of results) {
    if (r.matches.length === 0) {
      noMatchCount++;
      console.log(`  NO MATCH:     ${r.official.displayName} (${r.official.officeTitle})`);
    } else if (r.matches.length === 1) {
      matchedCount++;
      console.log(
        `  SINGLE MATCH: ${r.official.displayName} → Filer_ID=${r.matches[0].filerId}`
      );
    } else {
      multiMatchCount++;
      const ids = r.matches.map((m) => m.filerId).join(', ');
      console.log(
        `  MULTI MATCH:  ${r.official.displayName} → ${r.matches.length} matches: ${ids}`
      );
    }
  }

  console.log(`\n  Matched (single):   ${matchedCount}`);
  console.log(`  Multiple matches:   ${multiMatchCount}`);
  console.log(`  No match:           ${noMatchCount}`);
  console.log('='.repeat(70));

  return results;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log('[discover-netfile-filers] Starting Netfile Filer_ID discovery');
  console.log(`[discover-netfile-filers] Years to download: ${yearsToDownload.join(', ')}`);
  console.log('[discover-netfile-filers] READ-ONLY — no database writes');

  const yearMaps: Array<{ year: number; map: Map<string, FilerSummary> }> = [];
  const successfulYears: number[] = [];

  for (const year of yearsToDownload) {
    try {
      const buffer = await downloadNetfileExcel(year);
      if (!buffer) {
        console.warn(`[discover-netfile-filers] Skipping year=${year} (download failed)`);
        continue;
      }

      const summaryMap = extractFilerSummaries(buffer, year);
      console.log(`[discover-netfile-filers] year=${year}: extracted ${summaryMap.size} unique Filer_IDs`);

      yearMaps.push({ year, map: summaryMap });
      successfulYears.push(year);
    } catch (err) {
      console.error(
        `[discover-netfile-filers] ERROR processing year=${year}: ${
          err instanceof Error ? err.message : String(err)
        }`
      );
    }
  }

  if (yearMaps.length === 0) {
    console.error('[discover-netfile-filers] ERROR: No years downloaded successfully. Aborting.');
    process.exit(1);
  }

  const mergedMap = mergeSummaries(yearMaps);
  console.log(
    `\n[discover-netfile-filers] Merged ${yearMaps.length} year(s) → ${mergedMap.size} unique Filer_IDs`
  );

  matchAndPrint(TARGET_OFFICIALS, mergedMap, successfulYears);

  const durationMs = Date.now() - startMs;
  console.log(`\n[discover-netfile-filers] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main().catch((err) => {
  console.error('[discover-netfile-filers] Fatal error:', err);
  process.exit(1);
});
