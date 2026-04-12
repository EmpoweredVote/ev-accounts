/**
 * audit-112-assemble.ts — Unified audit assembler for Monroe County May 5, 2026 primary.
 *
 * Runs all 7 audit dimension scripts, captures their CSV stdout output, saves individual
 * CSV files, and builds a single human-readable markdown report at .planning/research/AUDIT-REPORT-112.md.
 *
 * Per D-02: produces both CSV files and markdown summary.
 * Per threat model T-112-07: DATABASE_URL is inherited via process env — never passed as CLI arg.
 *
 * Output:
 *   .planning/research/csv/{name}.csv  — individual CSV files per dimension
 *   .planning/research/AUDIT-REPORT-112.md — unified markdown report
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-assemble.ts             # Full assembly — queries DB and writes files
 *   npx tsx scripts/audit-112-assemble.ts --dry-run   # Runs all sub-scripts in dry-run mode, writes report
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Script registry
// ---------------------------------------------------------------------------

interface ScriptEntry {
  name: string;
  file: string;
  reqId: string;
  sectionTitle: string;
}

const SCRIPTS: ScriptEntry[] = [
  { name: 'races', file: 'audit-112-races.ts', reqId: 'AUDIT-01', sectionTitle: 'Race Coverage' },
  { name: 'candidates', file: 'audit-112-candidates.ts', reqId: 'AUDIT-02', sectionTitle: 'Candidate Linkage' },
  { name: 'stances', file: 'audit-112-stances.ts', reqId: 'AUDIT-03', sectionTitle: 'Stance Coverage' },
  { name: 'quotes', file: 'audit-112-quotes.ts', reqId: 'AUDIT-04', sectionTitle: 'Quote Coverage' },
  { name: 'headshots', file: 'audit-112-headshots.ts', reqId: 'AUDIT-05', sectionTitle: 'Headshot Coverage' },
  { name: 'profile', file: 'audit-112-profile.ts', reqId: 'AUDIT-06', sectionTitle: 'Profile Completeness' },
  { name: 'geofence', file: 'audit-112-geofence.ts', reqId: 'AUDIT-08', sectionTitle: 'Geofence Smoke Test' },
];

// ---------------------------------------------------------------------------
// Paths
// NOTE: __dirname is ev-accounts/backend/scripts/
// Workspace root is 3 levels up: ../../../
// ---------------------------------------------------------------------------

const WORKSPACE_ROOT = path.resolve(__dirname, '..', '..', '..');
const SCRIPTS_DIR = __dirname;
const RESEARCH_DIR = path.join(WORKSPACE_ROOT, '.planning', 'research');
const CSV_DIR = path.join(RESEARCH_DIR, 'csv');
const REPORT_PATH = path.join(RESEARCH_DIR, 'AUDIT-REPORT-112.md');

// ---------------------------------------------------------------------------
// CSV parsing
// ---------------------------------------------------------------------------

interface ParsedCsv {
  headers: string[];
  rows: string[][];
}

function parseCsv(raw: string): ParsedCsv {
  // Handle the geofence script's two-section output (blank line separating sections)
  const lines = raw.split('\n').filter((l) => l.trim().length > 0);
  if (lines.length === 0) return { headers: [], rows: [] };

  const headers = lines[0].split(',').map((h) => h.trim().replace(/^"|"$/g, ''));
  const rows: string[][] = [];

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    // Simple CSV parse — handle quoted fields
    const cells = parsecsvLine(line);
    rows.push(cells);
  }

  return { headers, rows };
}

function parsecsvLine(line: string): string[] {
  const cells: string[] = [];
  let inQuotes = false;
  let current = '';

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === ',' && !inQuotes) {
      cells.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  cells.push(current);
  return cells;
}

// ---------------------------------------------------------------------------
// Markdown table rendering
// ---------------------------------------------------------------------------

function renderMarkdownTable(csv: ParsedCsv): string {
  if (csv.headers.length === 0 || csv.rows.length === 0) {
    return '_No data returned._\n';
  }

  const colWidths = csv.headers.map((h) => h.length);
  for (const row of csv.rows) {
    for (let i = 0; i < row.length; i++) {
      colWidths[i] = Math.max(colWidths[i] ?? 0, (row[i] ?? '').length);
    }
  }

  const pad = (s: string, len: number) => s.padEnd(len, ' ');

  const headerLine = '| ' + csv.headers.map((h, i) => pad(h, colWidths[i] ?? h.length)).join(' | ') + ' |';
  const sepLine = '| ' + colWidths.map((w) => '-'.repeat(Math.max(w, 1))).join(' | ') + ' |';
  const dataLines = csv.rows.map(
    (row) =>
      '| ' +
      csv.headers
        .map((_, i) => pad(row[i] ?? '', colWidths[i] ?? 0))
        .join(' | ') +
      ' |',
  );

  return [headerLine, sepLine, ...dataLines].join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Executive summary extraction helpers
// ---------------------------------------------------------------------------

interface ExecutiveSummary {
  totalRaces: string;
  totalCandidates: string;
  linkedCandidates: string;
  stubCandidates: string;
  stanceCoverage: string;
  quoteCoverage: string;
  headshots: string;
  profileBio: string;
  avgContacts: string;
}

function extractSummary(
  results: Map<string, { csv: ParsedCsv; error?: string }>,
): ExecutiveSummary {
  // From races CSV: count total rows = total race slots
  const racesData = results.get('races');
  const totalRaces = racesData && !racesData.error ? String(racesData.csv.rows.length) : 'N/A';

  // From candidates CSV: aggregate totals
  const candidatesData = results.get('candidates');
  let totalCandidates = 'N/A';
  let linkedCandidates = 'N/A';
  let stubCandidates = 'N/A';
  if (candidatesData && !candidatesData.error) {
    const rows = candidatesData.csv.rows;
    const idx = {
      total: candidatesData.csv.headers.indexOf('total_candidates'),
      linked: candidatesData.csv.headers.indexOf('linked_to_politician'),
      stub: candidatesData.csv.headers.indexOf('stub_candidates'),
    };
    if (idx.total >= 0) {
      const t = rows.reduce((s, r) => s + parseInt(r[idx.total] ?? '0', 10), 0);
      const l = rows.reduce((s, r) => s + parseInt(r[idx.linked] ?? '0', 10), 0);
      const st = rows.reduce((s, r) => s + parseInt(r[idx.stub] ?? '0', 10), 0);
      totalCandidates = String(t);
      linkedCandidates = String(l);
      stubCandidates = String(st);
    }
  }

  // From stances CSV: count how many linked candidates have pct > 0%
  const stancesData = results.get('stances');
  let stanceCoverage = 'N/A';
  if (stancesData && !stancesData.error) {
    const rows = stancesData.csv.rows;
    const pctIdx = stancesData.csv.headers.indexOf('pct');
    const linkedIdx = stancesData.csv.headers.indexOf('is_linked');
    const linkedRows = linkedIdx >= 0 ? rows.filter((r) => r[linkedIdx] === 'linked') : rows;
    const withStances = pctIdx >= 0
      ? linkedRows.filter((r) => r[pctIdx] !== '0.0' && r[pctIdx] !== '0' && r[pctIdx] !== 'N/A' && r[pctIdx] !== '').length
      : 0;
    stanceCoverage = `${withStances}/${linkedRows.length} linked candidates have any stances`;
  }

  // From quotes CSV: count linked candidates with quote_count > 0
  const quotesData = results.get('quotes');
  let quoteCoverage = 'N/A';
  if (quotesData && !quotesData.error) {
    const rows = quotesData.csv.rows;
    const countIdx = quotesData.csv.headers.indexOf('quote_count');
    const linkedIdx = quotesData.csv.headers.indexOf('is_linked');
    const linkedRows = linkedIdx >= 0 ? rows.filter((r) => r[linkedIdx] === 'linked') : rows;
    const withQuotes = countIdx >= 0
      ? linkedRows.filter((r) => parseInt(r[countIdx] ?? '0', 10) > 0).length
      : 0;
    quoteCoverage = `${withQuotes}/${linkedRows.length} linked candidates have any quotes`;
  }

  // From headshots CSV: count cdn, local, none
  const headshotsData = results.get('headshots');
  let headshots = 'N/A';
  if (headshotsData && !headshotsData.error) {
    const rows = headshotsData.csv.rows;
    const srcIdx = headshotsData.csv.headers.indexOf('photo_source');
    if (srcIdx >= 0) {
      const cdn = rows.filter((r) => r[srcIdx] === 'cdn').length;
      const local = rows.filter((r) => r[srcIdx] === 'local').length;
      const none = rows.filter((r) => r[srcIdx] === 'none').length;
      headshots = `${cdn} cdn, ${local} local, ${none} none`;
    }
  }

  // From profile CSV: bio count and avg contacts
  const profileData = results.get('profile');
  let profileBio = 'N/A';
  let avgContacts = 'N/A';
  if (profileData && !profileData.error) {
    const rows = profileData.csv.rows;
    const bioIdx = profileData.csv.headers.indexOf('has_bio');
    const contactIdx = profileData.csv.headers.indexOf('contact_count');
    if (bioIdx >= 0) {
      const withBio = rows.filter((r) => r[bioIdx] === 'Y').length;
      profileBio = `${withBio}/${rows.length} linked candidates have bio`;
    }
    if (contactIdx >= 0) {
      const total = rows.reduce((s, r) => s + parseInt(r[contactIdx] ?? '0', 10), 0);
      const avg = rows.length > 0 ? (total / rows.length).toFixed(1) : '0';
      avgContacts = avg;
    }
  }

  return {
    totalRaces,
    totalCandidates,
    linkedCandidates,
    stubCandidates,
    stanceCoverage,
    quoteCoverage,
    headshots,
    profileBio,
    avgContacts,
  };
}

// ---------------------------------------------------------------------------
// Geofence section rendering (two-section output: main CSV + UNLINKED_RACES)
// ---------------------------------------------------------------------------

function renderGeofenceSection(raw: string): string {
  const lines = raw.split('\n');
  const mainLines: string[] = [];
  const unlinkedLines: string[] = [];
  let inUnlinked = false;

  for (const line of lines) {
    if (line.startsWith('UNLINKED_RACES,')) {
      inUnlinked = true;
    }
    if (inUnlinked) {
      unlinkedLines.push(line);
    } else if (line.trim().length > 0) {
      mainLines.push(line);
    }
  }

  const mainCsv = parseCsv(mainLines.join('\n'));
  const unlinkedCsv = parseCsv(unlinkedLines.join('\n'));

  let out = '### Resolved Races Per Address\n\n';
  out += renderMarkdownTable(mainCsv);
  out += '\n### Unlinked Races (Not Address-Scoped)\n\n';
  if (unlinkedCsv.rows.length === 0) {
    out += '_No unlinked races — all races are geofence-connected._\n';
  } else {
    out += renderMarkdownTable(unlinkedCsv);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Ensure output directories exist
  if (!fs.existsSync(CSV_DIR)) {
    fs.mkdirSync(CSV_DIR, { recursive: true });
    console.error(`Created directory: ${CSV_DIR}`);
  }

  const results = new Map<string, { raw: string; csv: ParsedCsv; error?: string }>();
  const dryRunFlag = DRY_RUN ? ' --dry-run' : '';

  // Run each sub-script, capture stdout CSV
  for (const script of SCRIPTS) {
    console.error(`Running ${script.name} (${script.reqId})...`);
    try {
      const raw = execSync(
        `npx tsx scripts/${script.file}${dryRunFlag}`,
        {
          encoding: 'utf-8',
          cwd: path.join(__dirname, '..'),  // ev-accounts/backend
          // DATABASE_URL is inherited from process.env — never passed as CLI arg (T-112-07)
          env: process.env,
        },
      );
      const csvData = script.name === 'geofence' ? raw : raw; // geofence handled specially below
      const csv = script.name === 'geofence' ? parseCsv(raw.split('\n')[0]) : parseCsv(raw);
      // Save raw CSV to file
      const csvPath = path.join(CSV_DIR, `${script.name}.csv`);
      fs.writeFileSync(csvPath, raw, 'utf-8');
      const rowCount = raw.split('\n').filter((l) => l.trim().length > 0).length - 1;
      console.error(`  done (${rowCount} rows) -> ${csvPath}`);
      results.set(script.name, { raw, csv });
    } catch (err: unknown) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error(`  ERROR running ${script.file}: ${errMsg}`);
      results.set(script.name, { raw: '', csv: { headers: [], rows: [] }, error: errMsg });
    }
  }

  // Build executive summary
  const summary = extractSummary(results);

  // Build unified markdown report
  const generatedAt = new Date().toISOString();

  let report = `# Data Completeness Audit Report — Monroe County IN, May 5, 2026 Primary

**Generated:** ${generatedAt}
**Baseline:** BALLOT-BASELINE-2026-05-05.md (~43 distinct race slots)
**Mode:** ${DRY_RUN ? 'DRY-RUN (no full CSV data)' : 'Full production audit'}

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total DB races | ${summary.totalRaces} (baseline: ~43) |
| Total candidates | ${summary.totalCandidates} (linked: ${summary.linkedCandidates}, stubs: ${summary.stubCandidates}) |
| Stance coverage | ${summary.stanceCoverage} |
| Quote coverage | ${summary.quoteCoverage} |
| Photo coverage | ${summary.headshots} |
| Profile bio | ${summary.profileBio} |
| Avg contacts per linked candidate | ${summary.avgContacts} |

---

`;

  // Add per-dimension sections
  for (const script of SCRIPTS) {
    const result = results.get(script.name);
    report += `## ${script.sectionTitle} (${script.reqId})\n\n`;

    if (!result || result.error) {
      const errDetail = result?.error ?? 'Script did not run';
      report += `**SCRIPT FAILED:** ${errDetail}\n\n`;
      continue;
    }

    if (script.name === 'geofence') {
      // Geofence has two-section output
      report += renderGeofenceSection(result.raw);
    } else {
      if (result.csv.rows.length === 0) {
        report += '_No rows returned._\n\n';
      } else {
        report += renderMarkdownTable(result.csv);
      }
    }

    report += '\n';
  }

  // Methodology section
  report += `## Methodology

- **Scripts:** \`ev-accounts/backend/scripts/audit-112-*.ts\`
- **Database:** Production Supabase (\`essentials.*\` + \`inform.*\` schemas)
- **Baseline:** Official Monroe County Clerk sample ballot PDFs (May 5, 2026 Primary)
- **Geofence:** PostGIS \`ST_Covers\` via \`geofence_boundaries\` table
- **Election filter:** \`election_date = '2026-05-05' AND state = 'IN'\`
- **Stub definition:** \`race_candidates.politician_id IS NULL\` — unlinked entry with no stance/quote/profile data
- **Intentional omissions:** State Convention Delegate races are party organizational elections — excluded from DB and audit scope
- **Generated by:** \`audit-112-assemble.ts\`
`;

  // Write report
  fs.writeFileSync(REPORT_PATH, report, 'utf-8');
  console.error(`\nAudit report written to ${REPORT_PATH}`);
  console.error(`CSV files written to ${CSV_DIR}/`);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
