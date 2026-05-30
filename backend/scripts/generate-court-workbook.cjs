#!/usr/bin/env node
// generate-court-workbook.js
// Reads court-research-input.json and produces:
//   1. court-research-workbook.txt  — human-readable research guide
//   2. court-research-results.json  — stub file with PENDING entries

const fs = require('fs');
const path = require('path');

const INPUT_PATH  = path.join(__dirname, 'court-research-input.json');
const WORKBOOK_PATH = path.join(__dirname, 'court-research-workbook.txt');
const RESULTS_PATH  = path.join(__dirname, 'court-research-results.json');

const CIVIL_URL    = 'https://www.lacourt.org/paos/v2public/CivilIndex/';
const CRIMINAL_URL = 'https://www.lacourt.org/paos/v2public/CriminalIndex/';
const SUMMARY_URL  = 'https://www.lacourt.ca.gov/casesummary/v2web3/';

// Entries that should be skipped (not private law firms appearing in court)
const SKIP_FIRMS = new Set([
  'city of los angeles',
  'self',
  'self employed',
  'self-employed',
]);

function formatDollars(n) {
  return '$' + Number(n).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function separator(char = '-', len = 80) {
  return char.repeat(len);
}

const input = JSON.parse(fs.readFileSync(INPUT_PATH, 'utf8'));

// ──────────────────────────────────────────────────────────────────────────────
// BUILD WORKBOOK
// ──────────────────────────────────────────────────────────────────────────────

const lines = [];

lines.push(separator('='));
lines.push('DONOR-COURT CONFLICT MAP — RESEARCH WORKBOOK');
lines.push('Generated: ' + new Date().toISOString().slice(0,19) + ' UTC');
lines.push(separator('='));
lines.push('');
lines.push('PURPOSE');
lines.push('-------');
lines.push('For each law firm that donated to a City Attorney candidate, search lacourt.org');
lines.push('to find whether that firm appears as a party in LA Superior Court cases.');
lines.push('A City Attorney is the City\'s lawyer — firms that appear in those cases could');
lines.push('create a recusal-worthy conflict if the CA is elected.');
lines.push('');
lines.push('SEARCH SITES');
lines.push('------------');
lines.push('Civil party search:    ' + CIVIL_URL);
lines.push('Criminal defendant:    ' + CRIMINAL_URL);
lines.push('Case summary (by #):   ' + SUMMARY_URL);
lines.push('Pricing: $1.00/search (registered) | $4.75 flat (guest)');
lines.push('');
lines.push('GENERAL INSTRUCTIONS');
lines.push('--------------------');
lines.push('1. Search the raw_firm_name column (shown in CAPS) as a PARTY NAME.');
lines.push('2. Focus on cases filed 2021–present (5-year look-back).');
lines.push('3. Record up to 10 case numbers; if more exist set court_appearances_capped=true.');
lines.push('4. For each case note case type (Civil/Criminal) and appearance dates.');
lines.push('5. Update court-research-results.json — replace "PENDING" researcher_notes with');
lines.push('   a plain note: "Searched \'<raw_name>\' as party; N civil cases 2021–2024."');
lines.push('6. PENDING entries are acceptable — Plan 03 loads them as zero appearances.');
lines.push('');
lines.push('SKIP RULES (do NOT search these)');
lines.push('---------------------------------');
lines.push('  city of los angeles  — incumbent office colleagues donating to their boss;');
lines.push('                         NOT a private law firm active in courts.');
lines.push('  self / self employed — solo attorney donors; no firm to search.');
lines.push('  non-law employers    — e.g. Disney, tech companies, government offices.');
lines.push('                         Mark court_appearances_found=0 and note "SKIPPED: not a law firm".');
lines.push('');

// Per-candidate sections
for (const candidate of input) {
  const firms = candidate.firms || [];
  if (!candidate.is_city_attorney) continue; // only CA candidates have firms

  lines.push('');
  lines.push(separator('='));
  lines.push(`CANDIDATE: ${candidate.candidate_name}`);
  lines.push(`  is_city_attorney : true`);
  lines.push(`  politician_id    : ${candidate.politician_id}`);
  lines.push(`  grand_total      : ${formatDollars(candidate.grand_total)}`);
  lines.push(`  threshold_cutoff : ${formatDollars(candidate.threshold_cutoff)} (top 15% cumulative)`);
  lines.push(`  firms to research: ${firms.length}`);

  if (candidate.candidate_name === 'Hydee Feldstein Soto') {
    lines.push('');
    lines.push('  *** NOTE: 212 firms is a very large list. Consider starting with the top 50');
    lines.push('  *** by total_donated (sorted descending, already in that order below).');
    lines.push('  *** "City of Los Angeles" (top entry) is SKIPPED — see SKIP RULES above.');
  }

  lines.push(separator('-'));
  lines.push('');

  if (firms.length === 0) {
    lines.push('  (no firms above threshold — skip this candidate)');
    lines.push('');
    continue;
  }

  // Table header
  const COL = {
    num:      4,
    firm:     40,
    raw:      45,
    donated:  14,
    donors:   8,
  };

  lines.push(
    '  #'.padEnd(COL.num) +
    'NORMALIZED FIRM'.padEnd(COL.firm) +
    'RAW NAME (search this)'.padEnd(COL.raw) +
    'DONATED'.padStart(COL.donated) +
    'DONORS'.padStart(COL.donors)
  );
  lines.push('  ' + separator('-', COL.num + COL.firm + COL.raw + COL.donated + COL.donors - 2));

  firms.forEach((f, i) => {
    const num     = String(i + 1).padEnd(COL.num - 2);
    const firm    = f.firm_name.slice(0,COL.firm-2).padEnd(COL.firm);
    const raw     = f.raw_firm_name.slice(0,COL.raw-2).padEnd(COL.raw);
    const donated = formatDollars(f.total_donated).padStart(COL.donated);
    const donors  = String(f.donor_count).padStart(COL.donors);

    lines.push(`  ${num}  ${firm}${raw}${donated}${donors}`);

    // Special flags
    const normLower = f.firm_name.toLowerCase().trim();
    if (SKIP_FIRMS.has(normLower) || normLower === 'city of los angeles') {
      lines.push(`       *** SKIP: incumbent colleagues donating to incumbent CA — not a private law firm active in courts ***`);
    } else if (f.needs_review) {
      lines.push(`       *** NEEDS REVIEW: fuzzy dedup matched similar names — confirm this is ONE firm before searching ***`);
    }

    if (f.occupations_seen && f.occupations_seen.length > 0) {
      lines.push(`       occupations: ${f.occupations_seen.slice(0,3).join(' | ')}${f.occupations_seen.length > 3 ? ' ...' : ''}`);
    }
  });

  lines.push('');
  lines.push(`  Search URL: ${CIVIL_URL}`);
  lines.push(`  Also check: ${CRIMINAL_URL}`);
  lines.push('');
}

// Non-CA section — just a note
lines.push(separator('='));
lines.push('JUDGE CHALLENGERS (28 candidates) — SKIPPED');
lines.push(separator('-'));
lines.push('No LA Ethics Commission contribution data ingested for judicial races.');
lines.push('These candidates have no firms in court-research-input.json.');
lines.push('All 28 will appear in court-research-results.json with empty firm lists.');
lines.push('');
lines.push(separator('='));
lines.push('END OF WORKBOOK');
lines.push(separator('='));

fs.writeFileSync(WORKBOOK_PATH, lines.join('\n'), 'utf8');
console.log(`Workbook written: ${WORKBOOK_PATH}`);
console.log(`  Lines: ${lines.length}`);

// ──────────────────────────────────────────────────────────────────────────────
// BUILD STUB RESULTS JSON
// ──────────────────────────────────────────────────────────────────────────────

const results = [];

for (const candidate of input) {
  const firms = candidate.firms || [];

  if (firms.length === 0) {
    // Still emit one row per candidate (with no firm) so Plan 03 knows they were processed
    results.push({
      politician_id: candidate.politician_id,
      candidate_name: candidate.candidate_name,
      is_city_attorney: candidate.is_city_attorney,
      firm_name: null,
      raw_firm_name: null,
      total_donated: null,
      court_appearances_found: 0,
      court_appearances_capped: false,
      case_types: [],
      first_appearance_date: null,
      last_appearance_date: null,
      source_urls: [],
      recusal_found: false,
      conflict_note: null,
      researcher_notes: 'PENDING — no firms above threshold for this candidate',
    });
  } else {
    for (const f of firms) {
      const normLower = f.firm_name.toLowerCase().trim();
      const isSkip = SKIP_FIRMS.has(normLower);

      results.push({
        politician_id: candidate.politician_id,
        candidate_name: candidate.candidate_name,
        is_city_attorney: candidate.is_city_attorney,
        firm_name: f.firm_name,
        raw_firm_name: f.raw_firm_name,
        total_donated: f.total_donated,
        court_appearances_found: 0,
        court_appearances_capped: false,
        case_types: [],
        first_appearance_date: null,
        last_appearance_date: null,
        source_urls: [],
        recusal_found: false,
        conflict_note: null,
        researcher_notes: isSkip
          ? 'SKIP — incumbent colleagues / non-court firm; not a private law firm active in courts'
          : 'PENDING',
      });
    }
  }
}

fs.writeFileSync(RESULTS_PATH, JSON.stringify(results, null, 2), 'utf8');
console.log(`Results stub written: ${RESULTS_PATH}`);
console.log(`  Total entries: ${results.length}`);
console.log(`  Breakdown:`);
for (const candidate of input) {
  const count = results.filter(r => r.politician_id === candidate.politician_id).length;
  console.log(`    ${candidate.candidate_name}: ${count} entries`);
}
