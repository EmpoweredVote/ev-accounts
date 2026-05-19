/**
 * scrape-cvvs-la-council.ts — Scrape LA City Council vote records from CVVS
 * (cityclerk.lacity.org/cvvs/) and store them in meetings.la_council_votes.
 *
 * Strategy: Search CVVS by date range to get vote IDs, then fetch
 * votedetails.cfm for each vote ID to get all 15 members' individual
 * YES/NO/ABSENT votes in one request. Stores all members' votes together.
 *
 * Date granularity: 2-week windows to stay under CVVS's 500-record limit.
 * Each 2-week window typically returns ~150-200 vote records.
 *
 * Usage:
 *   npx tsx scripts/scrape-cvvs-la-council.ts
 *
 * Note: Uses Playwright for form submission (raw fetch is blocked by CF).
 * Requires DISPLAY or headless Chromium.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { chromium, type Browser, type BrowserContext } from 'playwright';

// ─── DB pool ──────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// ─── Council member map (essentials politician ID → CVVS display name) ───────

const MEMBER_NAME_TO_ID: Record<string, string> = {
  'BOB BLUMENFIELD':        '0379cbef-05d8-4fd7-ba51-92b7661a4bbc',
  'MARQUEECE HARRIS-DAWSON':'ece32bfa-26de-4177-9bb3-cea506870747',
  'EUNISSES HERNANDEZ':     '317698c6-2ae7-4f7f-ab39-bb3811ed50f3',
  'HEATHER HUTT':           '29a8c85b-2572-463c-8034-8986615d7717',
  'YSABEL JURADO':          '04d12540-8075-4263-894a-6575f7c9bd14',
  'JOHN LEE':               'c3155cf3-9a97-43d1-a076-dd6ef6aa46e9',
  'TIM MCOSKER':            '5cf02835-9024-4a00-80f7-bc2dcc3165df',
  'ADRIN NAZARIAN':         'e30ddde5-a722-477b-837b-056fdc7e2d6b',
  'IMELDA PADILLA':         'd82a3080-0a11-4d73-bacb-a936e51c9fb3',
  'TRACI PARK':             'd0977350-df68-4cfe-822e-816ba13f9213',
  'CURREN D. PRICE':        '725d4081-e820-4064-83dc-3f8470bd7c2b',
  'NITHYA RAMAN':           '26dbe16a-9dff-42c0-939f-5b5e529063ca',
  'MONICA RODRIGUEZ':       '7c0d3bdd-a363-4d97-93a9-67034c6a0ead',
  'HUGO SOTO-MARTINEZ':     '6c795b3b-d59d-4667-b79e-8a2e27e0c283',
  'KATY YAROSLAVSKY':       '10678016-146d-4543-941c-00414b4c4ad2',
};

// ─── Constants ────────────────────────────────────────────────────────────────

const CVVS_BASE = 'https://cityclerk.lacity.org/cvvs/search';
const SCRAPE_START = new Date('2025-01-01');
const SCRAPE_END   = new Date('2026-05-19');
const WINDOW_DAYS  = 14;  // 2-week chunks to stay under 500-record limit
const DELAY_MS     = 800; // polite delay between requests

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatDate(d: Date): string {
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${mm}/${dd}/${yyyy}`;
}

function addDays(d: Date, n: number): Date {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function sleep(ms: number): Promise<void> {
  return new Promise(r => setTimeout(r, ms));
}

function normalizeVote(raw: string): string | null {
  const v = raw.trim().toUpperCase();
  const map: Record<string, string> = {
    'YES': 'YES', 'AYE': 'YES',
    'NO': 'NO', 'NAY': 'NO',
    'ABSENT': 'ABSENT',
    'ABSTAIN': 'ABSTAIN', 'ABSTAINED': 'ABSTAIN',
    'RECUSE': 'RECUSE', 'RECUSED': 'RECUSE',
    'PRESENT': 'PRESENT',
  };
  return map[v] ?? null;
}

// ─── Fetch vote IDs from CVVS search for a date window ───────────────────────

async function fetchVoteIds(
  context: BrowserContext,
  startDate: string,
  endDate: string
): Promise<number[]> {
  const page = await context.newPage();
  const seen = new Set<number>();
  const allVoteIds: number[] = [];

  function extractFromHtml(html: string): void {
    for (const m of html.matchAll(/votedetails\.cfm\?voteid=(\d+)/g)) {
      const id = parseInt(m[1], 10);
      if (!seen.has(id)) { seen.add(id); allVoteIds.push(id); }
    }
  }

  async function safeContent(): Promise<string> {
    try {
      return await page.content();
    } catch {
      await sleep(1000);
      return await page.content();
    }
  }

  try {
    await page.goto(`${CVVS_BASE}/search.cfm`);
    await page.evaluate((dates: [string, string]) => {
      (document.querySelector('input[name="startdate"]') as HTMLInputElement).value = dates[0];
      (document.querySelector('input[name="enddate"]') as HTMLInputElement).value = dates[1];
      (document.querySelector('form[name="form"]') as HTMLFormElement).submit();
    }, [startDate, endDate] as [string, string]);
    await page.waitForLoadState('load');
    await sleep(500);

    let html = await safeContent();

    if (html.includes('over 500 records')) {
      console.warn(`  [cvvs] ${startDate}–${endDate}: over 500 records — reduce window`);
      return [];
    }
    if (html.includes('No records were found') || html.includes('no records found')) {
      return [];
    }

    extractFromHtml(html);

    // Follow all pagination pages
    const pageMatch = html.match(/page \d+ of (\d+)/i);
    const totalPages = pageMatch ? parseInt(pageMatch[1], 10) : 1;

    for (let p = 2; p <= totalPages; p++) {
      // pagejump(n) on the results page sets CurrentPage and submits the form.
      // JS is disabled for page scripts, so we replicate it via CDP eval.
      const submitted: boolean = await page.evaluate((n: number) => {
        const form = document.querySelector('form[name="form"]') as HTMLFormElement | null;
        if (!form) return false;
        let pageInput = form.querySelector('input[name="CurrentPage"]') as HTMLInputElement | null;
        if (!pageInput) {
          pageInput = document.createElement('input') as HTMLInputElement;
          pageInput.type = 'hidden';
          pageInput.name = 'CurrentPage';
          form.appendChild(pageInput);
        }
        pageInput.value = String(n);
        form.submit();
        return true;
      }, p);

      if (!submitted) {
        console.warn(`  [cvvs] ${startDate}–${endDate}: form not found for page ${p}`);
        break;
      }

      await page.waitForLoadState('load');
      await sleep(400);
      html = await safeContent();
      extractFromHtml(html);
    }

    if (totalPages > 1) {
      console.log(`  [cvvs] ${startDate}–${endDate}: ${totalPages} pages → ${allVoteIds.length} vote IDs`);
    }

    return allVoteIds;
  } finally {
    await page.close();
  }
}

// ─── Fetch vote details for a single vote ID ─────────────────────────────────

interface MemberVote {
  memberName: string;
  politicianId: string | null;
  vote: string;
}

interface VoteDetail {
  voteId: number;
  meetingDate: string;  // YYYY-MM-DD
  meetingType: string;
  itemNumber: string;
  councilFileNumber: string;
  description: string;
  memberVotes: MemberVote[];
}

async function fetchVoteDetail(context: BrowserContext, voteId: number): Promise<VoteDetail | null> {
  const page = await context.newPage();
  try {
    await page.goto(`${CVVS_BASE}/votedetails.cfm?voteid=${voteId}`);
    await page.waitForLoadState('load');

    const text = await page.evaluate(() => document.body.innerText);

    if (!text.includes('Meeting Date:')) return null;

    // Parse meeting date (e.g., "TUESDAY JANUARY 07, 2025" → strip day name → "JANUARY 07, 2025")
    const dateMatch = text.match(/Meeting Date:\s*(?:[A-Z]+\s+)?([A-Z]+ \d{1,2}, \d{4})/i);
    let meetingDate = '';
    if (dateMatch) {
      const parsed = new Date(dateMatch[1]);
      if (!isNaN(parsed.getTime())) {
        // Use UTC year/month/day to avoid timezone shift
        const y = parsed.getUTCFullYear();
        const m = String(parsed.getUTCMonth() + 1).padStart(2, '0');
        const d = String(parsed.getUTCDate()).padStart(2, '0');
        meetingDate = `${y}-${m}-${d}`;
      }
    }

    const meetingTypeMatch = text.match(/Meeting Type:\s*(\S+)/i);
    const meetingType = meetingTypeMatch?.[1] ?? '';

    const itemMatch = text.match(/Agenda Item Number:\s*(\S+)/i);
    const itemNumber = itemMatch?.[1] ?? '';

    const cfnMatch = text.match(/Council File Number:\s*(\S+)/i);
    const councilFileNumber = cfnMatch?.[1] ?? '';

    const descMatch = text.match(/Item Description:\s*([\s\S]*?)(?=Pertinent Council Districts:|Member Name)/i);
    const description = descMatch?.[1]?.trim().replace(/\s+/g, ' ') ?? '';

    // Parse member votes from the table
    const memberVotes: MemberVote[] = [];
    const lines = text.split('\n').map(l => l.trim()).filter(Boolean);

    // Find the header line then parse rows
    let inVoteSection = false;
    for (const line of lines) {
      if (line.includes('Member Name')) {
        inVoteSection = true;
        continue;
      }
      // Skip sub-header lines and vote totals line
      if (line.includes('Vote Given') || line.match(/^\(\d+ - \d+ - \d+\)/)) continue;
      if (!inVoteSection) continue;

      // Lines look like: "BOB BLUMENFIELD   3   YES" or "BOB BLUMENFIELD\t3\tYES"
      // The last token is the vote, the second-to-last is CD number, rest is name
      const tokens = line.split(/\s{2,}|\t/).map(t => t.trim()).filter(Boolean);
      if (tokens.length < 3) continue;

      const vote = normalizeVote(tokens[tokens.length - 1]);
      if (!vote) continue;

      // Name is everything before the last two tokens.
      // CVVS uses non-breaking spaces (U+00A0) in names — normalize to regular space.
      const nameParts = tokens.slice(0, -2);
      const memberName = nameParts.join(' ').replace(/ /g, ' ').toUpperCase().trim();
      if (!memberName) continue;

      const politicianId = MEMBER_NAME_TO_ID[memberName] ?? null;
      memberVotes.push({ memberName, politicianId, vote });
    }

    return { voteId, meetingDate, meetingType, itemNumber, councilFileNumber, description, memberVotes };
  } catch (err: any) {
    console.error(`  [cvvs] votedetails ${voteId}: error — ${err.message}`);
    return null;
  } finally {
    await page.close();
  }
}

// ─── Upsert vote detail into DB ───────────────────────────────────────────────

async function upsertVoteDetail(detail: VoteDetail): Promise<{ inserted: number; skipped: number }> {
  let inserted = 0;
  let skipped = 0;

  const cfn = detail.councilFileNumber || null;

  // Upsert agenda item
  let agendaItemId: string | null = null;
  if (cfn) {
    await pool.query(
      `INSERT INTO meetings.la_council_agenda_items (council_file_number, title)
       VALUES ($1, $2)
       ON CONFLICT ON CONSTRAINT la_council_agenda_items_cfn_unique DO NOTHING`,
      [cfn, detail.description || null]
    );
    const res = await pool.query(
      `SELECT id FROM meetings.la_council_agenda_items WHERE council_file_number = $1`,
      [cfn]
    );
    agendaItemId = res.rows[0]?.id ?? null;
  }

  // Upsert each member's vote
  for (const mv of detail.memberVotes) {
    if (!mv.politicianId) {
      // Skip if we don't have this member mapped (e.g., historical members)
      continue;
    }
    const result = await pool.query(
      `INSERT INTO meetings.la_council_votes
         (politician_id, council_file_number, agenda_item_id, vote_date, vote,
          agenda_description, meeting_type, item_number)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT ON CONSTRAINT la_council_votes_unique DO NOTHING`,
      [
        mv.politicianId,
        cfn,
        agendaItemId,
        detail.meetingDate || null,
        mv.vote,
        detail.description || null,
        detail.meetingType || null,
        detail.itemNumber || null,
      ]
    );
    if ((result.rowCount ?? 0) > 0) inserted++;
    else skipped++;
  }

  return { inserted, skipped };
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[cvvs] Starting LA City Council vote scraper (Playwright-based)');
  console.log(`[cvvs] Scraping ${formatDate(SCRAPE_START)} – ${formatDate(SCRAPE_END)} in ${WINDOW_DAYS}-day windows`);

  const browser: Browser = await chromium.launch({ headless: true });
  const context: BrowserContext = await browser.newContext({ javaScriptEnabled: false });

  let totalVoteIds = 0;
  let totalInserted = 0;
  let totalSkipped = 0;
  let totalErrors = 0;

  try {
    let windowStart = new Date(SCRAPE_START);

    while (windowStart < SCRAPE_END) {
      const windowEnd = addDays(windowStart, WINDOW_DAYS - 1);
      const effectiveEnd = windowEnd < SCRAPE_END ? windowEnd : new Date(SCRAPE_END);

      const startStr = formatDate(windowStart);
      const endStr = formatDate(effectiveEnd);
      console.log(`\n[cvvs] Window ${startStr} – ${endStr}`);

      const voteIds = await fetchVoteIds(context, startStr, endStr);
      console.log(`  [cvvs] Found ${voteIds.length} vote IDs`);
      totalVoteIds += voteIds.length;

      for (const voteId of voteIds) {
        try {
          const detail = await fetchVoteDetail(context, voteId);
          // DEBUG: log detail summary to diagnose 0-insertion issue
          if (!detail || !detail.meetingDate) {
            totalErrors++;
            continue;
          }

          const { inserted, skipped } = await upsertVoteDetail(detail);
          totalInserted += inserted;
          totalSkipped += skipped;

          if (inserted > 0) {
            console.log(`  [cvvs] vote ${voteId} (${detail.councilFileNumber}): +${inserted} member votes`);
          }

          await sleep(DELAY_MS);
        } catch (err: any) {
          console.error(`  [cvvs] vote ${voteId}: ERROR — ${err.message}`);
          totalErrors++;
        }
      }

      windowStart = addDays(effectiveEnd, 1);
    }

  } finally {
    await browser.close();
  }

  console.log('\n[cvvs] ─── SUMMARY ───────────────────────────────────');
  console.log(`  Total vote IDs found:   ${totalVoteIds}`);
  console.log(`  Member vote rows inserted: ${totalInserted}`);
  console.log(`  Skipped (already existed): ${totalSkipped}`);
  console.log(`  Errors: ${totalErrors}`);
  console.log('[cvvs] Done.');

  await pool.end();
}

main().catch((err) => {
  console.error('[cvvs] Fatal error:', err);
  pool.end().finally(() => process.exit(1));
});
