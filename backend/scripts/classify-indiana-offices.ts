/**
 * classify-indiana-offices.ts — Classify Indiana office titles from generic 'Indiana Elected Official'
 * to specific titles (State Senator, State Representative, Governor, etc.)
 *
 * Usage:
 *   npx tsx scripts/classify-indiana-offices.ts                    # dry-run (default, no DB writes)
 *   npx tsx scripts/classify-indiana-offices.ts --dry-run          # explicit dry-run
 *   npx tsx scripts/classify-indiana-offices.ts --apply            # write to DB
 *   npx tsx scripts/classify-indiana-offices.ts --dry-run --limit 25  # limit to 25 rows
 *   npx tsx scripts/classify-indiana-offices.ts --out /path/report.csv # custom output path
 *
 * Classification strategy:
 *   1. Notes-pattern match (HIGH confidence) — parse committee name from politician_sources.notes
 *      using the same alias patterns as backfill-indiana-office-titles.ts
 *   2. Indiana SoS CandidateSearch fallback (HIGH confidence) — fetch campaign finance portal
 *      and match by candidate name to get office type from official records
 *   3. Unresolved — left as 'Indiana Elected Official', documented in CSV for manual follow-up
 *
 * NOTE: Original plan called for IGA roster scraping, but IGA site is a React SPA (no server-rendered
 * HTML). Indiana SoS CandidateSearch returns structured results with office type — used instead.
 * This provides HIGH confidence matches (official SoS records) vs MEDIUM (roster name match).
 *
 * Safe:
 *   - Dry-run by default (no DB writes unless --apply)
 *   - Only updates rows WHERE title = 'Indiana Elected Official' (idempotent)
 *   - Never inserts or deletes rows
 *   - Only touches Indiana-confirmed scope (WHERE clause guard)
 */

import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { pool } from '../src/lib/db.js';

// ─── Arg parsing ──────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const isApply = args.includes('--apply');
const isDryRun = !isApply;

const limitIdx = args.indexOf('--limit');
const limit: number | null = limitIdx !== -1 ? parseInt(args[limitIdx + 1], 10) : null;

const outIdx = args.indexOf('--out');
const outPath: string = outIdx !== -1 ? args[outIdx + 1] : 'scripts/classify-indiana-offices.report.csv';

console.log(`[classify-indiana-offices] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'APPLY'}`);
if (limit !== null) console.log(`[classify-indiana-offices] Limit: ${limit} rows`);
console.log(`[classify-indiana-offices] Report output: ${outPath}`);

// ─── Types ────────────────────────────────────────────────────────────────────

interface InputRow {
  office_id: string;
  politician_id: string;
  current_title: string;
  full_name: string;
  first_name: string;
  last_name: string;
  notes: string | null;
  source_external_id: string | null;
}

interface ReportRow {
  office_id: string;
  politician_id: string;
  full_name: string;
  current_title: string;
  proposed_title: string;
  source: 'notes' | 'sos_lookup' | 'unresolved';
  confidence: 'high' | 'none';
  evidence: string;
}

// ─── Step 2: Classify by notes / committee name patterns ─────────────────────

// These title aliases mirror backfill-indiana-office-titles.ts
const COMMITTEE_PATTERNS: Array<{ pattern: RegExp; title: string }> = [
  // State-level chambers — must come before generic patterns
  { pattern: /state\s+sen(ator|ate)?\.?|indiana\s+sen(ator|ate)|for\s+state\s+senate|for\s+senate(?!\s+district)/i, title: 'State Senator' },
  { pattern: /state\s+rep(resentative|resentative)?\.?|for\s+state\s+rep|for\s+state\s+representative|state\s+house|indiana\s+house|for\s+(?:the\s+)?house(?!\s+of\s+rep)|house\s+district/i, title: 'State Representative' },
  // Statewide offices
  { pattern: /for\s+governor|for\s+(?:the\s+)?governor/i, title: 'Governor' },
  { pattern: /lt\.?\s*gov|lieutenant\s+gov/i, title: 'Lieutenant Governor' },
  { pattern: /attorney\s+general/i, title: 'Attorney General' },
  { pattern: /secretary\s+of\s+state/i, title: 'Secretary of State' },
  { pattern: /state\s+treasurer|treasurer\s+of\s+state/i, title: 'State Treasurer' },
  { pattern: /state\s+auditor|auditor\s+of\s+state/i, title: 'State Auditor' },
  { pattern: /superintendent\s+of\s+public\s+instruction|state\s+superintendent/i, title: 'Superintendent of Public Instruction' },
  // Congress
  { pattern: /for\s+(?:u\.?s\.?\s+)?congress|for\s+(?:u\.?s\.?\s+)?senate(?!\s+district)|u\.?s\.?\s+representative/i, title: 'U.S. Representative' },
];

function extractCommitteeName(notes: string | null): string | null {
  if (!notes) return null;
  const m = notes.match(/Committee:\s*(.+?)\.\s*Office type/i);
  return m ? m[1].trim() : null;
}

function classifyFromNotes(notes: string | null): { title: string; evidence: string } | null {
  const committee = extractCommitteeName(notes);
  if (!committee) return null;

  for (const { pattern, title } of COMMITTEE_PATTERNS) {
    if (pattern.test(committee)) {
      return { title, evidence: `Committee name: "${committee}"` };
    }
  }
  return null;
}

// ─── Step 3: Indiana SoS CandidateSearch fallback ────────────────────────────

const SOS_URL = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

// Normalize office string from SoS to our standard titles
function normalizeSosOffice(office: string): string | null {
  const o = office.trim().toLowerCase();
  if (o.includes('state representative')) return 'State Representative';
  if (o.includes('state senator') || o.includes('state senate')) return 'State Senator';
  if (o.includes('governor') && !o.includes('lt') && !o.includes('lieutenant')) return 'Governor';
  if (o.includes('lt') || o.includes('lieutenant')) return 'Lieutenant Governor';
  if (o.includes('attorney general')) return 'Attorney General';
  if (o.includes('secretary of state')) return 'Secretary of State';
  if (o.includes('state treasurer') || o.includes('treasurer')) return 'State Treasurer';
  if (o.includes('state auditor') || o.includes('auditor')) return 'State Auditor';
  if (o.includes('superintendent')) return 'Superintendent of Public Instruction';
  if (o.includes('clerk of the supreme')) return 'Clerk of the Supreme Court';
  if (o.includes('congress') || o.includes('u.s. representative') || o.includes('us representative')) return 'U.S. Representative';
  if (o.includes('u.s. senate') || o.includes('us senate')) return 'U.S. Senator';
  if (o.includes('justice of the supreme')) return 'Justice of the Supreme Court';
  if (o.includes('judge of the court of appeals')) return 'Judge of the Court of Appeals';
  if (o.includes('judge of the tax court')) return 'Judge of the Tax Court';
  if (o.length === 0) return null;
  // Return as-is (title-cased) for any other office
  return office.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()).join(' ');
}

// Cache: lastName → Map<normalizedFullName, officeName>
// Each lookup needs a fresh GET (ASP.NET VIEWSTATE is consumed per POST, status=4 breaks things)
const sosCache = new Map<string, Map<string, string>>();
let sosAvailable = true;

// Verify SoS is reachable during startup
async function initSos(): Promise<void> {
  try {
    const res = await fetch(SOS_URL, {
      headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' },
      signal: AbortSignal.timeout(10000),
    });
    const html = await res.text();
    const viewstate = html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
    if (!viewstate) {
      console.warn('[classify-indiana-offices] SoS: could not extract VIEWSTATE — SoS lookup disabled');
      sosAvailable = false;
    } else {
      console.log('[classify-indiana-offices] SoS: reachable (viewstate OK)');
    }
  } catch (e) {
    console.warn('[classify-indiana-offices] SoS: init failed:', (e as Error).message);
    sosAvailable = false;
  }
}

function parseSearchResults(html: string): Map<string, string> {
  // The results grid has format: "Candidate Name | Party | Office | District | Status"
  // We find the dgdSearchResults table and parse rows
  const results = new Map<string, string>(); // normalizedName → office

  const gridStart = html.indexOf('dgdSearchResults');
  if (gridStart === -1) return results;

  const gridHtml = html.slice(gridStart, gridStart + 20000);

  // Extract all <tr> rows from the grid
  const trPattern = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
  let trMatch: RegExpExecArray | null;
  let headerSkipped = false;

  while ((trMatch = trPattern.exec(gridHtml)) !== null) {
    const cells: string[] = [];
    const tdPattern = /<t[dh][^>]*>([\s\S]*?)<\/t[dh]>/gi;
    let tdMatch: RegExpExecArray | null;
    while ((tdMatch = tdPattern.exec(trMatch[1])) !== null) {
      const text = tdMatch[1].replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
      cells.push(text);
    }

    if (cells.length < 3) continue;
    if (!headerSkipped && cells[0].toLowerCase().includes('candidate')) {
      headerSkipped = true;
      continue;
    }
    if (cells.length < 4) continue;

    const candidateName = cells[0]?.trim();
    const officeRaw = cells[2]?.trim();

    if (!candidateName || !officeRaw) continue;
    // Normalize name: last first → first last
    const normalized = candidateName.toLowerCase().replace(/\s+/g, ' ').trim();
    const office = normalizeSosOffice(officeRaw);
    if (office) {
      results.set(normalized, office);
    }
  }

  return results;
}

async function lookupSos(lastName: string): Promise<Map<string, string>> {
  if (!sosAvailable) return new Map();
  if (sosCache.has(lastName.toLowerCase())) return sosCache.get(lastName.toLowerCase())!;

  try {
    // Must do fresh GET per POST — ASP.NET VIEWSTATE is single-use per session
    const getRes = await fetch(SOS_URL, {
      headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' },
      signal: AbortSignal.timeout(10000),
    });
    const getHtml = await getRes.text();
    const cookie = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';
    const viewstate = getHtml.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
    const eventval = getHtml.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';

    const formData = new URLSearchParams({
      '_ctl0_ToolkitScriptManager1_HiddenField': '',
      '__EVENTTARGET': '', '__EVENTARGUMENT': '',
      '__VIEWSTATE': viewstate, '__VIEWSTATEGENERATOR': '4045FD78',
      '__SCROLLPOSITIONX': '0', '__SCROLLPOSITIONY': '0',
      '__EVENTVALIDATION': eventval,
      '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': lastName,
      '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '1',  // contains
      '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': '',
      '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '1',
      '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
      '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
      '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
      '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '2',  // all (exploratory + non-exploratory)
      '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': '2',  // active/disbanded (status=4 breaks server-side)
      '_ctl0:Content:btnSearch': 'Search',
    });

    const res = await fetch(SOS_URL, {
      method: 'POST',
      headers: {
        'User-Agent': 'EmpoweredVote-TM/1.0',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Referer': SOS_URL,
        'Cookie': cookie,
      },
      body: formData.toString(),
      signal: AbortSignal.timeout(15000),
    });

    const html = await res.text();
    const resultMap = parseSearchResults(html);
    sosCache.set(lastName.toLowerCase(), resultMap);
    return resultMap;
  } catch (e) {
    console.warn(`[classify-indiana-offices] SoS lookup failed for "${lastName}":`, (e as Error).message);
    sosCache.set(lastName.toLowerCase(), new Map());
    return new Map();
  }
}

async function classifyFromSos(
  firstName: string,
  lastName: string,
  fullName: string
): Promise<{ title: string; evidence: string } | null> {
  const results = await lookupSos(lastName);
  if (results.size === 0) return null;

  // SoS returns names like "Amy Burke Adams", "C. WOODY BURTON", "KENT J. ADAMS"
  // We match: SoS name must contain BOTH our first name AND our last name (case-insensitive)
  // This handles middle names in SoS, initials, etc.
  const fn = firstName.toLowerCase().trim();
  const ln = lastName.toLowerCase().trim();

  // Try full name match first (exact first+last), then partial
  const matches: Array<{ sosName: string; office: string; score: number }> = [];

  for (const [sosName, office] of results) {
    const sosLower = sosName.toLowerCase();
    const sosWords = sosLower.split(/\s+/);

    const hasLastName = sosWords.some(w => w === ln || w.startsWith(ln));
    const hasFirstName = sosWords.some(w => w === fn || w.startsWith(fn.slice(0, Math.max(3, fn.length))));

    if (!hasLastName || !hasFirstName) continue;

    // Score: higher = better match
    let score = 0;
    if (sosLower === `${fn} ${ln}` || sosLower === `${ln} ${fn}`) score = 100;  // exact
    else if (sosLower.startsWith(fn) && sosLower.endsWith(ln)) score = 90;
    else if (sosWords[0] === fn && sosWords[sosWords.length - 1] === ln) score = 85;
    else score = 50;

    matches.push({ sosName, office, score });
  }

  if (matches.length === 0) return null;

  // Sort by score descending, take best match
  matches.sort((a, b) => b.score - a.score);
  const best = matches[0];

  // If multiple matches with same last name resolve to DIFFERENT offices, log warning
  const offices = [...new Set(matches.map(m => m.office))];
  if (offices.length > 1) {
    // Ambiguous — multiple offices for same last name. Return best match but note ambiguity
    return {
      title: best.office,
      evidence: `IN SoS record: "${best.sosName}" → ${best.office} [WARNING: ${matches.length} name matches, offices: ${offices.join(', ')}]`,
    };
  }

  return { title: best.office, evidence: `IN SoS record: "${best.sosName}" → ${best.office}` };
}

// ─── CSV escaping ─────────────────────────────────────────────────────────────

function csvField(value: string): string {
  if (/[,"\n\r]/.test(value)) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

function buildCsvLine(row: ReportRow): string {
  return [
    csvField(row.office_id),
    csvField(row.politician_id),
    csvField(row.full_name),
    csvField(row.current_title),
    csvField(row.proposed_title),
    csvField(row.source),
    csvField(row.confidence),
    csvField(row.evidence),
  ].join(',');
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  // Step 1: Load affected rows
  console.log('[classify-indiana-offices] Loading affected rows from DB...');
  const { rows: inputRows } = await pool.query<InputRow>(`
    SELECT
      o.id            AS office_id,
      o.politician_id,
      o.title         AS current_title,
      p.full_name,
      p.first_name,
      p.last_name,
      ps.notes,
      ps.external_id  AS source_external_id
    FROM essentials.offices o
    JOIN essentials.politicians p
      ON p.id = o.politician_id
    JOIN transparent_motivations.politician_sources ps
      ON ps.essentials_politician_id = o.politician_id
    WHERE o.title = 'Indiana Elected Official'
      AND ps.source_system = 'indiana'
      AND ps.research_status = 'confirmed'
    ORDER BY p.last_name, p.first_name
  `);

  const allRows = limit !== null ? inputRows.slice(0, limit) : inputRows;
  console.log(`[classify-indiana-offices] Total input rows: ${allRows.length}`);

  // Initialize SoS session
  await initSos();

  // Steps 2-4: Classify each row
  const results: ReportRow[] = [];
  let notesCount = 0;
  let sosCount = 0;
  let unresolvedCount = 0;

  let processed = 0;
  for (const row of allRows) {
    processed++;
    if (processed % 50 === 0) {
      console.log(`[classify-indiana-offices] Progress: ${processed}/${allRows.length} (notes: ${notesCount}, sos: ${sosCount}, unresolved: ${unresolvedCount})`);
    }

    // Try notes pattern first (high confidence)
    const notesResult = classifyFromNotes(row.notes);
    if (notesResult) {
      results.push({
        office_id: row.office_id,
        politician_id: row.politician_id,
        full_name: row.full_name,
        current_title: row.current_title,
        proposed_title: notesResult.title,
        source: 'notes',
        confidence: 'high',
        evidence: notesResult.evidence,
      });
      notesCount++;
      continue;
    }

    // Try Indiana SoS CandidateSearch fallback (high confidence — official records)
    if (sosAvailable) {
      const sosResult = await classifyFromSos(
        row.first_name ?? '',
        row.last_name ?? '',
        row.full_name ?? ''
      );
      if (sosResult) {
        results.push({
          office_id: row.office_id,
          politician_id: row.politician_id,
          full_name: row.full_name,
          current_title: row.current_title,
          proposed_title: sosResult.title,
          source: 'sos_lookup',
          confidence: 'high',
          evidence: sosResult.evidence,
        });
        sosCount++;
        continue;
      }
    }

    // Unresolved
    unresolvedCount++;
    const committee = extractCommitteeName(row.notes);
    results.push({
      office_id: row.office_id,
      politician_id: row.politician_id,
      full_name: row.full_name,
      current_title: row.current_title,
      proposed_title: '(none)',
      source: 'unresolved',
      confidence: 'none',
      evidence: `(committee: ${committee ?? 'null'} | notes head: ${row.notes?.slice(0, 60) ?? 'null'})`,
    });
  }

  console.log(`[classify-indiana-offices] Classification complete.`);

  // Step 5: Write CSV report
  const csvLines = [
    'office_id,politician_id,full_name,current_title,proposed_title,source,confidence,evidence',
    ...results.map(buildCsvLine),
  ];
  writeFileSync(outPath, csvLines.join('\n'), 'utf8');
  console.log(`[classify-indiana-offices] Report written to: ${outPath}`);

  // Step 6: Apply (only if --apply)
  let rowsUpdated = 0;
  if (isApply) {
    const toUpdate = results.filter(r => r.confidence === 'high');
    console.log(`[classify-indiana-offices] Applying ${toUpdate.length} updates...`);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (const r of toUpdate) {
        const res = await client.query(
          'UPDATE essentials.offices SET title = $1, updated_at = NOW() WHERE id = $2 AND title = $3',
          [r.proposed_title, r.office_id, 'Indiana Elected Official']
        );
        rowsUpdated += res.rowCount ?? 0;
      }
      await client.query('COMMIT');
      console.log(`[classify-indiana-offices] Transaction committed.`);
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  // Step 7: Summary log
  console.log('\n── Summary ──────────────────────────────────────────────────────');
  console.log(`  Total input rows:              ${allRows.length}`);
  console.log(`  Classified by notes pattern:   ${notesCount}  (confidence: high)`);
  console.log(`  Classified by IN SoS lookup:   ${sosCount}  (confidence: high)`);
  console.log(`  Unresolved:                    ${unresolvedCount}`);
  if (isApply) {
    console.log(`  Rows updated in DB:            ${rowsUpdated}`);
  } else {
    console.log(`\nDry run — no DB writes. Review CSV at ${outPath} then re-run with --apply.`);
  }
  console.log('─────────────────────────────────────────────────────────────────');

  await pool.end();
}

main().catch((err) => {
  console.error('[classify-indiana-offices] Fatal error:', err);
  process.exit(1);
});
