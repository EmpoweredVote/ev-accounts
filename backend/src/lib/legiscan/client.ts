/**
 * client.ts — LegiScan API client for the refresh job.
 *
 * Two limits drive the design (LegiScan email, effective 2026-10-01):
 *  - free tier = 10,000 queries a month, so every call is counted in
 *    `essentials.legiscan_query_counter` (the old file counter cannot survive on a Render cron);
 *  - about 2 requests a second, so calls are spaced at least MIN_GAP_MS apart.
 * Only the API key and public bill queries leave our systems. No user data.
 */
import { pool } from '../db.js';

const LEGISCAN_BASE = 'https://api.legiscan.com/';
export const MONTHLY_QUERY_CAP = 10_000;
/** Stop this many queries short of the cap, as a margin. */
export const BUDGET_MARGIN = 100;
const MIN_GAP_MS = 600;

let lastCallAt = 0;

export function currentMonth(now = new Date()): string {
  return now.toISOString().slice(0, 7);
}

export async function readQueriesThisMonth(): Promise<number> {
  const { rows } = await pool.query(
    'SELECT queries FROM essentials.legiscan_query_counter WHERE month = $1',
    [currentMonth()],
  );
  return rows.length ? Number(rows[0].queries) : 0;
}

async function countQuery(): Promise<number> {
  const { rows } = await pool.query(
    `INSERT INTO essentials.legiscan_query_counter (month, queries) VALUES ($1, 1)
     ON CONFLICT (month) DO UPDATE SET queries = essentials.legiscan_query_counter.queries + 1
     RETURNING queries`,
    [currentMonth()],
  );
  return Number(rows[0].queries);
}

/* eslint-disable @typescript-eslint/no-explicit-any */
export async function legiscanQuery(
  apiKey: string,
  op: string,
  params: Record<string, string> = {},
): Promise<any> {
  const used = await readQueriesThisMonth();
  if (used >= MONTHLY_QUERY_CAP - BUDGET_MARGIN) {
    throw new Error(`LegiScan budget nearly exhausted: ${used}/${MONTHLY_QUERY_CAP} this month`);
  }

  const wait = MIN_GAP_MS - (Date.now() - lastCallAt);
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  lastCallAt = Date.now();

  const url = new URL(LEGISCAN_BASE);
  url.searchParams.set('key', apiKey);
  url.searchParams.set('op', op);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);

  const res = await fetch(url, { signal: AbortSignal.timeout(120_000) });
  // Count the call as soon as it was made, whatever the answer was.
  await countQuery();
  if (!res.ok) throw new Error(`LegiScan ${op} HTTP ${res.status}`);
  const data: any = await res.json();
  if (data?.status !== 'OK') {
    // Never echo the request URL: it carries the API key.
    throw new Error(`LegiScan ${op} error: ${JSON.stringify(data?.alert ?? data).slice(0, 300)}`);
  }
  return data;
}
