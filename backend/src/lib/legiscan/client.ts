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

/** Budget check and call spacing, shared by every LegiScan call. */
async function reserveQuery(): Promise<void> {
  const used = await readQueriesThisMonth();
  if (used >= MONTHLY_QUERY_CAP - BUDGET_MARGIN) {
    throw new Error(`LegiScan budget nearly exhausted: ${used}/${MONTHLY_QUERY_CAP} this month`);
  }

  const wait = MIN_GAP_MS - (Date.now() - lastCallAt);
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  lastCallAt = Date.now();
}

function queryUrl(apiKey: string, op: string, params: Record<string, string>): URL {
  const url = new URL(LEGISCAN_BASE);
  url.searchParams.set('key', apiKey);
  url.searchParams.set('op', op);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  return url;
}

/* eslint-disable @typescript-eslint/no-explicit-any */
export async function legiscanQuery(
  apiKey: string,
  op: string,
  params: Record<string, string> = {},
): Promise<any> {
  await reserveQuery();

  const url = queryUrl(apiKey, op, params);

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

/**
 * Pull the base64 `zip` field out of a getDataset response WITHOUT parsing the JSON.
 *
 * 🔴 WHY: a big dataset is a JSON string of base64 (the US Congress one is 63 MiB of zip, 85 MiB of JSON).
 * `res.json()` holds the text and the parsed copy at once, then Buffer.from holds the zip as well, and
 * peak memory passed a 256 MiB heap. This reads the body chunk by chunk, decodes the base64 as it
 * arrives, and keeps only the zip bytes. The `zip` field comes last in LegiScan's answer. PHP escapes
 * "/" as "\/" inside JSON strings, so that escape is undone here; any other escape is an error.
 * An answer with no `zip` field is an error reply: the first part of it is returned in the message.
 */
export async function zipFromDatasetStream(body: AsyncIterable<Uint8Array>): Promise<Buffer> {
  const MARK = '"zip":"';
  const parts: Buffer[] = [];
  let head = '';
  let first = '';
  let inZip = false;
  let carry = '';
  let done = false;
  for await (const raw of body) {
    let text = Buffer.from(raw.buffer, raw.byteOffset, raw.byteLength).toString('latin1');
    if (!inZip) {
      if (first.length < 400) first += text.slice(0, 400 - first.length);
      head += text;
      const at = head.indexOf(MARK);
      if (at < 0) { head = head.slice(-(MARK.length - 1)); continue; }
      text = head.slice(at + MARK.length);
      head = '';
      inZip = true;
    }
    text = (carry + text).replace(/\\\//g, '/');
    carry = '';
    const quote = text.indexOf('"');
    if (quote >= 0) { text = text.slice(0, quote); done = true; }
    if (!done && text.endsWith('\\')) { carry = '\\'; text = text.slice(0, -1); }
    if (/\\/.test(text)) throw new Error('LegiScan dataset: unexpected escape in the zip data');
    const whole = done ? text.length : text.length - (text.length % 4);
    if (whole) parts.push(Buffer.from(text.slice(0, whole), 'base64'));
    carry = text.slice(whole) + carry;
    if (done) break;
  }
  if (!inZip) {
    throw new Error(`LegiScan dataset reply had no zip: ${first.replace(/key=[^&"\s]+/g, 'key=…').slice(0, 300)}`);
  }
  return Buffer.concat(parts);
}

/**
 * getDataset as a streamed download: counts as one query like any other call, but never holds the JSON.
 * Returns the dataset ZIP.
 */
export async function legiscanDatasetZip(apiKey: string, sessionId: number, accessKey: string): Promise<Buffer> {
  await reserveQuery();
  const url = queryUrl(apiKey, 'getDataset', { id: String(sessionId), access_key: accessKey });
  const res = await fetch(url, { signal: AbortSignal.timeout(10 * 60_000) });
  await countQuery();
  if (!res.ok || !res.body) throw new Error(`LegiScan getDataset HTTP ${res.status}`);
  return zipFromDatasetStream(res.body as unknown as AsyncIterable<Uint8Array>);
}
