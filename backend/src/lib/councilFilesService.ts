/**
 * councilFilesService — LA City Council file enrichment and DB operations.
 *
 * WHY THIS FILE EXISTS:
 * Every vote row in the VotingRecordSection has a council_file_number. Clicking it
 * must show a title, sponsors, plain-English summary, PDF links, video link, and the
 * full vote roster for that bill. This service provides all of that data.
 *
 * Data sources:
 *   - CFMS (cityclerk.lacity.org/lacityclerkconnect) — title, movers, dates, PDF links
 *   - Granicus RSS (lacity.granicus.com) — video clip IDs keyed by meeting date
 *   - Anthropic claude-haiku-4-5 — plain-English 2-sentence summaries
 *   - meetings.council_file_details — cached enriched rows
 *   - meetings.la_council_votes + essentials.politicians — vote roster
 *
 * Pitfalls honored (from RESEARCH.md):
 *   1. Mover field: split on \s{2,} after tag stripping — multiple co-movers collapse to multi-space
 *   2. Skip enrichment if CFN is null; treat suffixes (S3, A2, T1) as part of the key
 *   3. 200 + empty pairs is still a successful fetch — store enriched_at to avoid re-scraping
 *   4. Use view_id=129 for Granicus RSS (view_id=2 is 60-day only)
 *   5. Skip AI summary for commendations/certificates/recognitions
 */

import { pool } from './db.js';
import Anthropic from '@anthropic-ai/sdk';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type CfmsData = {
  title: string | null;
  introducedDate: string | null;  // YYYY-MM-DD
  lastChangedDate: string | null; // YYYY-MM-DD
  movers: string[];
  second: string | null;
  pdfLinks: string[];
  cfmsUrl: string;
};

export type CouncilFileDetail = {
  council_file_number: string;
  title: string | null;
  movers: string[];
  second: string | null;
  introduced_date: string | null;
  last_changed_date: string | null;
  pdf_links: string[];
  cfms_url: string | null;
  granicus_clip_id: number | null;
  ai_summary: string | null;
  enriched_at: string | null;
  ai_summary_at: string | null;
  video_url: string | null; // derived: not stored in DB, constructed from granicus_clip_id
};

export type VoteRosterEntry = {
  name: string;
  vote: string;
  politician_id: string;
};

// ---------------------------------------------------------------------------
// Module-level singletons and cache
// ---------------------------------------------------------------------------

// Anthropic client — initialized once at module scope
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// Granicus clip map cache — 1-hour TTL
let clipMapCache: Map<string, number> | null = null;
let clipMapCachedAt = 0;
const CLIP_MAP_TTL_MS = 60 * 60 * 1000; // 1 hour

// Rate limiting for CFMS fetches — enforce ≥1 second between requests
let lastFetchAt = 0;

// CFN validation
const CFN_REGEX = /^\d{2}-\d{4}(-[A-Z0-9]+)?$/;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Strip HTML tags from a string, collapse whitespace. */
function stripTags(html: string): string {
  return html.replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&nbsp;/g, ' ').replace(/&#\d+;/g, ' ').trim();
}

/**
 * Parse a date string in either MM/DD/YYYY or YYYY-MM-DD format to YYYY-MM-DD.
 * Returns null on parse failure.
 */
function parseDate(raw: string): string | null {
  if (!raw || !raw.trim()) return null;
  const slashMatch = raw.trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (slashMatch) {
    const [, m, d, y] = slashMatch;
    return `${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
  }
  const isoMatch = raw.trim().match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (isoMatch) {
    return raw.trim();
  }
  return null;
}

// ---------------------------------------------------------------------------
// 1. scrapeCouncilFile
// ---------------------------------------------------------------------------

/**
 * Fetch and parse a council file's metadata from CFMS.
 *
 * Returns null ONLY on non-200 HTTP response (network error or 4xx/5xx).
 * A 200 with empty or unrecognized HTML returns a CfmsData with all-null fields
 * (Pitfall 3 — store enriched_at to avoid re-scraping a legitimately empty page).
 *
 * @param cfn Council file number, e.g. "22-0158" or "21-0042-S3"
 */
export async function scrapeCouncilFile(cfn: string): Promise<CfmsData | null> {
  const cfmsUrl = `https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=${encodeURIComponent(cfn)}`;

  // Enforce ≥1 second delay between CFMS requests (rate limiting)
  const now = Date.now();
  const elapsed = now - lastFetchAt;
  if (elapsed < 1000) {
    await new Promise(resolve => setTimeout(resolve, 1000 - elapsed));
  }

  let html: string;
  try {
    lastFetchAt = Date.now();
    const res = await fetch(cfmsUrl, {
      headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120' },
    });

    if (!res.ok) {
      // Exponential backoff: wait 2s and retry once
      console.warn(`[scrapeCouncilFile] ${cfn} got ${res.status} — waiting 2s then retrying`);
      await new Promise(resolve => setTimeout(resolve, 2000));
      lastFetchAt = Date.now();
      const retry = await fetch(cfmsUrl, {
        headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120' },
      });
      if (!retry.ok) {
        console.error(`[scrapeCouncilFile] ${cfn} retry also failed: ${retry.status}`);
        return null;
      }
      html = await retry.text();
    } else {
      html = await res.text();
    }
  } catch (err) {
    console.error(`[scrapeCouncilFile] ${cfn} fetch error:`, err);
    return null;
  }

  // Parse label→value pairs from CFMS HTML
  const re = /class="reclabel">(.*?)<\/div>\s*<div[^>]*class="rectext">(.*?)<\/div>/gis;
  const pairs: Record<string, string> = {};
  let match: RegExpExecArray | null;
  while ((match = re.exec(html)) !== null) {
    const label = stripTags(match[1]).replace(/:$/, '').trim();
    const value = stripTags(match[2]).trim();
    if (label) {
      pairs[label] = value;
    }
  }

  // Extract PDF links
  const pdfRe = /href="(https:\/\/cityclerk\.lacity\.org\/onlinedocs\/[^"]+\.pdf[^"]*)"/gi;
  const pdfLinks: string[] = [];
  let pdfMatch: RegExpExecArray | null;
  while ((pdfMatch = pdfRe.exec(html)) !== null) {
    const url = pdfMatch[1];
    if (!pdfLinks.includes(url)) {
      pdfLinks.push(url);
    }
  }

  // Extract movers — Pitfall 1: split on 2+ whitespace after tag stripping
  const rawMover = pairs['Mover'] ?? pairs['Motion by'] ?? '';
  const movers = rawMover
    ? rawMover.split(/\s{2,}/).map(s => s.trim()).filter(Boolean)
    : [];

  // Find second field (case-insensitive key search)
  const secondKey = Object.keys(pairs).find(k => /second/i.test(k));
  const second = secondKey ? pairs[secondKey] || null : null;

  // Find title (various CFMS label names)
  const titleKey = Object.keys(pairs).find(k => /title|subject/i.test(k));
  const title = titleKey ? pairs[titleKey] || null : null;

  // Find dates
  const introKey = Object.keys(pairs).find(k => /received|introduced/i.test(k));
  const changedKey = Object.keys(pairs).find(k => /last.*changed|changed/i.test(k));

  return {
    title,
    introducedDate: introKey ? parseDate(pairs[introKey] ?? '') : null,
    lastChangedDate: changedKey ? parseDate(pairs[changedKey] ?? '') : null,
    movers,
    second,
    pdfLinks,
    cfmsUrl,
  };
}

// ---------------------------------------------------------------------------
// 2. buildDateToClipMap
// ---------------------------------------------------------------------------

/**
 * Fetch the Granicus RSS feed for LA City Council meetings and build a
 * map of { YYYY-MM-DD → clip_id }.
 *
 * Uses view_id=129 (full history — Pitfall 4: view_id=2 is 60-day only).
 * Cached at module scope with a 1-hour TTL to avoid re-fetching on every enrichment.
 */
export async function buildDateToClipMap(): Promise<Map<string, number>> {
  const now = Date.now();
  if (clipMapCache && now - clipMapCachedAt < CLIP_MAP_TTL_MS) {
    return clipMapCache;
  }

  const rssUrl = 'https://lacity.granicus.com/ViewPublisherRSS.php?view_id=129&mode=agendas';
  let xml: string;
  try {
    const res = await fetch(rssUrl, {
      headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120' },
    });
    if (!res.ok) {
      console.warn(`[buildDateToClipMap] Granicus RSS returned ${res.status}`);
      return clipMapCache ?? new Map();
    }
    xml = await res.text();
  } catch (err) {
    console.error('[buildDateToClipMap] fetch error:', err);
    return clipMapCache ?? new Map();
  }

  const itemRe = /<item>.*?<pubDate>(.*?)<\/pubDate>.*?clip_id=(\d+).*?<\/item>/gis;
  const map = new Map<string, number>();
  let match: RegExpExecArray | null;
  while ((match = itemRe.exec(xml)) !== null) {
    const rawDate = match[1].trim();
    const clipId = parseInt(match[2], 10);
    // Convert pubDate (RFC 2822) to YYYY-MM-DD UTC
    const dt = new Date(rawDate);
    if (!isNaN(dt.getTime())) {
      const iso = dt.toISOString().slice(0, 10); // YYYY-MM-DD
      map.set(iso, clipId);
    }
  }

  clipMapCache = map;
  clipMapCachedAt = now;
  return map;
}

// ---------------------------------------------------------------------------
// 3. summarizeBill
// ---------------------------------------------------------------------------

/**
 * Generate a plain-English 2-sentence summary of a council bill using
 * Anthropic claude-haiku-4-5.
 *
 * Returns null for commendations, certificates, congratulatory items,
 * and recognitions (Pitfall 5 — no substantive policy content).
 * Returns null on API error to avoid crashing enrichment.
 *
 * @param title    Bill title from CFMS
 * @param description  Optional description/context (may be empty string)
 * @param cfn      Council file number (included in prompt for context)
 */
export async function summarizeBill(
  title: string,
  description: string,
  cfn: string
): Promise<string | null> {
  // Skip AI summary for commendations/recognitions (Pitfall 5)
  if (/commendation|certificate|congratulat|recognit/i.test(title)) {
    return null;
  }

  try {
    const message = await anthropic.messages.create({
      model: 'claude-haiku-4-5',
      max_tokens: 150,
      system:
        'You summarize LA City Council legislation for ordinary residents. Write in plain English at a 6th-grade reading level. Be specific about what the bill does, not just its topic area.',
      messages: [
        {
          role: 'user',
          content: `Summarize this council file in 2 sentences for a resident who wants to know what it does:\nTitle: ${title}\nDescription: ${description}\nCouncil File: ${cfn}`,
        },
      ],
    });

    const block = message.content[0];
    return block.type === 'text' ? block.text.trim() : null;
  } catch (err) {
    console.error('[summarizeBill] Anthropic API error:', err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// 4. enrichCouncilFile
// ---------------------------------------------------------------------------

/**
 * Orchestrate full enrichment for a council file:
 *   1. Scrape CFMS for title, movers, dates, PDF links
 *   2. Look up Granicus clip ID from meeting date
 *   3. Generate AI summary via claude-haiku-4-5
 *   4. UPSERT into meetings.council_file_details
 *
 * Always sets enriched_at — even on partial failure — so we don't retry
 * every request. Sets ai_summary_at only when a summary was actually generated.
 *
 * Rate limiting: ≥1 second delay between CFMS fetches (enforced in scrapeCouncilFile).
 *
 * @param cfn  Council file number. Must match /^\d{2}-\d{4}(-[A-Z0-9]+)?$/
 * @param opts Optional extra context (description text for AI summary)
 */
export async function enrichCouncilFile(
  cfn: string,
  opts?: { description?: string }
): Promise<void> {
  if (!CFN_REGEX.test(cfn)) {
    console.warn(`[enrichCouncilFile] invalid CFN format: ${cfn}`);
    return;
  }

  const now = new Date().toISOString();
  let cfmsData: CfmsData | null = null;

  try {
    cfmsData = await scrapeCouncilFile(cfn);
  } catch (err) {
    console.error(`[enrichCouncilFile] scrapeCouncilFile error for ${cfn}:`, err);
  }

  if (!cfmsData) {
    // HTTP failure — store enriched_at so we don't retry immediately (Pitfall 3)
    await pool.query(
      `INSERT INTO meetings.council_file_details (council_file_number, enriched_at)
       VALUES ($1, $2)
       ON CONFLICT (council_file_number) DO UPDATE SET enriched_at = EXCLUDED.enriched_at`,
      [cfn, now]
    );
    return;
  }

  // Look up Granicus clip ID using introduced_date
  let granicusClipId: number | null = null;
  if (cfmsData.introducedDate) {
    try {
      const clipMap = await buildDateToClipMap();
      granicusClipId = clipMap.get(cfmsData.introducedDate) ?? null;
    } catch (err) {
      console.warn(`[enrichCouncilFile] buildDateToClipMap error for ${cfn}:`, err);
    }
  }

  // Generate AI summary if title is available
  let aiSummary: string | null = null;
  let aiSummaryAt: string | null = null;
  if (cfmsData.title) {
    try {
      aiSummary = await summarizeBill(cfmsData.title, opts?.description ?? '', cfn);
      if (aiSummary !== null) {
        aiSummaryAt = new Date().toISOString();
      }
    } catch (err) {
      console.warn(`[enrichCouncilFile] summarizeBill error for ${cfn}:`, err);
    }
  }

  // UPSERT into meetings.council_file_details
  await pool.query(
    `INSERT INTO meetings.council_file_details (
       council_file_number, title, movers, second,
       introduced_date, last_changed_date, pdf_links, cfms_url,
       granicus_clip_id, ai_summary, enriched_at, ai_summary_at
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
     ON CONFLICT (council_file_number) DO UPDATE SET
       title            = EXCLUDED.title,
       movers           = EXCLUDED.movers,
       second           = EXCLUDED.second,
       introduced_date  = EXCLUDED.introduced_date,
       last_changed_date = EXCLUDED.last_changed_date,
       pdf_links        = EXCLUDED.pdf_links,
       cfms_url         = EXCLUDED.cfms_url,
       granicus_clip_id = EXCLUDED.granicus_clip_id,
       ai_summary       = EXCLUDED.ai_summary,
       enriched_at      = EXCLUDED.enriched_at,
       ai_summary_at    = EXCLUDED.ai_summary_at`,
    [
      cfn,
      cfmsData.title,
      cfmsData.movers,
      cfmsData.second,
      cfmsData.introducedDate,
      cfmsData.lastChangedDate,
      cfmsData.pdfLinks,
      cfmsData.cfmsUrl,
      granicusClipId,
      aiSummary,
      new Date().toISOString(),
      aiSummaryAt,
    ]
  );
}

// ---------------------------------------------------------------------------
// 5. getCouncilFileDetail
// ---------------------------------------------------------------------------

/**
 * Fetch a cached council file detail row from the DB.
 *
 * Returns null if no row exists (caller should trigger enrichCouncilFile).
 * Adds derived `video_url` field constructed from granicus_clip_id (not stored in DB).
 */
export async function getCouncilFileDetail(cfn: string): Promise<CouncilFileDetail | null> {
  const result = await pool.query(
    'SELECT * FROM meetings.council_file_details WHERE council_file_number = $1',
    [cfn]
  );

  if (result.rows.length === 0) return null;

  const row = result.rows[0];
  const clipId: number | null = row.granicus_clip_id ?? null;

  return {
    council_file_number: row.council_file_number,
    title: row.title ?? null,
    movers: row.movers ?? [],
    second: row.second ?? null,
    introduced_date: row.introduced_date ? new Date(row.introduced_date).toISOString().slice(0, 10) : null,
    last_changed_date: row.last_changed_date ? new Date(row.last_changed_date).toISOString().slice(0, 10) : null,
    pdf_links: row.pdf_links ?? [],
    cfms_url: row.cfms_url ?? null,
    granicus_clip_id: clipId,
    ai_summary: row.ai_summary ?? null,
    enriched_at: row.enriched_at ? new Date(row.enriched_at).toISOString() : null,
    ai_summary_at: row.ai_summary_at ? new Date(row.ai_summary_at).toISOString() : null,
    video_url: clipId
      ? `https://lacity.granicus.com/MediaPlayer.php?view_id=129&clip_id=${clipId}`
      : null,
  };
}

// ---------------------------------------------------------------------------
// 6. getVoteRoster
// ---------------------------------------------------------------------------

/**
 * Return the full vote roster for a council file — every council member and
 * how they voted, joined from la_council_votes and essentials.politicians.
 *
 * Ordered by vote outcome first, then by last name.
 */
export async function getVoteRoster(cfn: string): Promise<VoteRosterEntry[]> {
  const result = await pool.query(
    `SELECT p.first_name || ' ' || p.last_name AS name, v.vote, p.id AS politician_id
     FROM meetings.la_council_votes v
     JOIN essentials.politicians p ON p.id = v.politician_id
     WHERE v.council_file_number = $1
     ORDER BY v.vote, p.last_name`,
    [cfn]
  );

  return result.rows.map((r) => ({
    name: r.name as string,
    vote: r.vote as string,
    politician_id: r.politician_id as string,
  }));
}
