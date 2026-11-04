/**
 * federalBillsRefresh.ts — weekly refresh of federal bills (and their cosponsors) for the
 * Congress in session, from govinfo's BILLSTATUS bulk files.
 *
 *   node dist/jobs/run.js federal-bills
 *
 * Environment overrides, for manual runs:
 *   FEDERAL_CONGRESS=119     only this Congress (default: the one in session today)
 *   FEDERAL_BILL_TYPES=HR,S  only these bill types (default: all eight)
 *   FEDERAL_DRY_RUN=1        run everything, then roll it back: exact counts, nothing saved
 *
 * Why this exists: until 2026-10-31 nothing loaded federal bills on a schedule, so the data was a
 * one-time snapshot. This job adds new bills, updates changed ones (status, summary, subjects,
 * sponsor, cosponsors) and creates the session row when a new Congress starts (January 3).
 * Rows that did not change are not written. Past Congresses are not touched.
 *
 * Source: https://www.govinfo.gov/bulkdata/BILLSTATUS/<congress>/<type>/BILLSTATUS-<congress>-<type>.zip
 * (public, no key; about 60 MB a week for a whole Congress). A Congress with no files yet (the days
 * after January 3) is skipped, not an error.
 *
 * Antipartisan rule: party and names are never read. A sponsor or cosponsor is linked to one of our
 * politicians only by bioguide id, and only when that id belongs to exactly one politician.
 * Members we do not hold stay unlinked; this job never creates people.
 */
import type { PoolClient } from 'pg';
import { pool } from '../db.js';
import {
  FEDERAL_BILL_TYPES, congressEnd, congressStart, currentCongress, ordinal, parseBillStatus,
  type FederalBill, type FederalBillType,
} from './billStatus.js';
import { LightZip } from './lightZip.js';

const log = (msg: string) => console.info(`[federal-bills] ${msg}`);
const truthy = (v: string | undefined) => !!v && !['0', 'false', 'no', ''].includes(v.toLowerCase());

/** Bills written per transaction. Keeps one statement small and a failure local. */
const BATCH = 500;
/** Files parsed between yields, so the event loop (and GC) can breathe on a big archive. */
const YIELD_EVERY = 200;

export interface FederalBillsOptions {
  congress?: number;
  types?: FederalBillType[];
  dryRun?: boolean;
  fetchImpl?: typeof fetch;
}

export interface FederalBillsResult {
  congress: number;
  files: number;
  parsed: number;
  inserted: number;
  updated: number;
  unchanged: number;
  cosponsorsAdded: number;
  cosponsorsRemoved: number;
  typesSkipped: string[];
  errors: string[];
}

export const zipUrl = (congress: number, type: FederalBillType) =>
  `https://www.govinfo.gov/bulkdata/BILLSTATUS/${congress}/${type.toLowerCase()}/BILLSTATUS-${congress}-${type.toLowerCase()}.zip`;

/** bioguide id -> politician id, only where the id belongs to exactly one politician. */
export async function loadBioguideMap(): Promise<Map<string, string>> {
  const { rows } = await pool.query(
    `SELECT bioguide, (array_agg(DISTINCT pid))[1] AS pid FROM (
       SELECT bioguide_id AS bioguide, id AS pid FROM essentials.politicians
         WHERE bioguide_id IS NOT NULL AND bioguide_id <> ''
       UNION
       SELECT id_value, politician_id FROM essentials.legislative_politician_id_map WHERE id_type = 'bioguide'
     ) x GROUP BY bioguide HAVING count(DISTINCT pid) = 1`,
  );
  return new Map(rows.map((r) => [r.bioguide as string, r.pid as string]));
}

/** The federal session row for a Congress; created when missing (a new Congress). */
export async function ensureSession(congress: number, dryRun: boolean): Promise<string | null> {
  const found = await pool.query(
    `SELECT id FROM essentials.legislative_sessions WHERE jurisdiction = 'federal' AND external_id = $1`,
    [String(congress)],
  );
  if (found.rows.length) return found.rows[0].id;
  log(`no session row for the ${ordinal(congress)} Congress; ${dryRun ? 'would create' : 'creating'} it`);
  if (dryRun) return null;
  const ins = await pool.query(
    `INSERT INTO essentials.legislative_sessions
       (id, jurisdiction, name, start_date, end_date, is_current, external_id, source)
     VALUES (gen_random_uuid(), 'federal', $1, $2, $3, $4, $5, 'congress') RETURNING id`,
    [`${ordinal(congress)} Congress`, congressStart(congress), congressEnd(congress),
      congress === currentCongress(), String(congress)],
  );
  return ins.rows[0].id;
}

const UPSERT_BILLS = `
  INSERT INTO essentials.legislative_bills AS b
    (id, session_id, external_id, jurisdiction, number, title, summary, raw_status, status_label,
     sponsor_id, introduced_at, passed_at, signed_at, topic_tags, url, source)
  SELECT gen_random_uuid(), $2::uuid, r.external_id, 'federal', r.number, r.title, r.summary, r.raw_status,
         r.status_label, r.sponsor_id, r.introduced_at, r.passed_at, r.signed_at,
         CASE WHEN jsonb_typeof(r.topic_tags) = 'array' AND jsonb_array_length(r.topic_tags) > 0
              THEN ARRAY(SELECT jsonb_array_elements_text(r.topic_tags)) END, r.url, 'congress'
  FROM jsonb_to_recordset($1::jsonb) AS r(
         external_id text, number text, title text, summary text, raw_status text, status_label text,
         sponsor_id uuid, introduced_at date, passed_at date, signed_at date, topic_tags jsonb, url text)
  ON CONFLICT (external_id, jurisdiction) DO UPDATE SET
    session_id = EXCLUDED.session_id, number = EXCLUDED.number, title = EXCLUDED.title,
    summary = EXCLUDED.summary, raw_status = EXCLUDED.raw_status, status_label = EXCLUDED.status_label,
    sponsor_id = COALESCE(EXCLUDED.sponsor_id, b.sponsor_id), introduced_at = EXCLUDED.introduced_at,
    passed_at = EXCLUDED.passed_at, signed_at = EXCLUDED.signed_at, topic_tags = EXCLUDED.topic_tags,
    url = EXCLUDED.url
  WHERE (b.session_id, b.number, b.title, b.summary, b.raw_status, b.status_label, b.sponsor_id,
         b.introduced_at, b.passed_at, b.signed_at, b.topic_tags, b.url)
        IS DISTINCT FROM
        (EXCLUDED.session_id, EXCLUDED.number, EXCLUDED.title, EXCLUDED.summary, EXCLUDED.raw_status,
         EXCLUDED.status_label, COALESCE(EXCLUDED.sponsor_id, b.sponsor_id), EXCLUDED.introduced_at,
         EXCLUDED.passed_at, EXCLUDED.signed_at, EXCLUDED.topic_tags, EXCLUDED.url)
  RETURNING (xmax = 0) AS inserted`;

const SYNC_COSPONSORS = `
  WITH want AS (
    SELECT (x->>'bill_id')::uuid AS bill_id, (x->>'pol')::uuid AS pol FROM jsonb_array_elements($1::jsonb) x
  ), del AS (
    DELETE FROM essentials.legislative_bill_cosponsors c
    WHERE c.bill_id = ANY($2::uuid[])
      AND NOT EXISTS (SELECT 1 FROM want w WHERE w.bill_id = c.bill_id AND w.pol = c.politician_id)
    RETURNING 1
  ), ins AS (
    INSERT INTO essentials.legislative_bill_cosponsors (id, bill_id, politician_id)
    SELECT gen_random_uuid(), bill_id, pol FROM want
    ON CONFLICT DO NOTHING
    RETURNING 1
  )
  SELECT (SELECT count(*) FROM del)::int AS removed, (SELECT count(*) FROM ins)::int AS added`;

/** Empty text is stored as NULL, as in the 2026-10-30 load, so an unchanged bill compares equal. */
const toRow = (b: FederalBill, bioguides: Map<string, string>) => ({
  external_id: b.externalId, number: b.number, title: b.title || null, summary: b.summary || null,
  raw_status: b.rawStatus || null,
  status_label: b.statusLabel, sponsor_id: bioguides.get(b.sponsorBioguide) ?? null,
  introduced_at: b.introducedAt, passed_at: b.passedAt, signed_at: b.signedAt, topic_tags: b.topicTags, url: b.url,
});

async function inTransaction<T>(fn: (c: PoolClient) => Promise<T>, rollback = false): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const out = await fn(client);
    await client.query(rollback ? 'ROLLBACK' : 'COMMIT');
    return out;
  } catch (err) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Write one batch of bills and bring their cosponsor lists in line, in one transaction.
 * `rollback` (dry run) does all of it and then undoes it, so the counts are exact.
 */
export async function writeBatch(
  batch: FederalBill[], sessionId: string, bioguides: Map<string, string>, res: FederalBillsResult,
  rollback = false,
): Promise<void> {
  await inTransaction(async (client) => {
    const up = await client.query(UPSERT_BILLS, [JSON.stringify(batch.map((b) => toRow(b, bioguides))), sessionId]);
    const inserted = up.rows.filter((r) => r.inserted).length;
    res.inserted += inserted;
    res.updated += up.rows.length - inserted;
    res.unchanged += batch.length - up.rows.length;

    const ids = await client.query(
      `SELECT id, external_id FROM essentials.legislative_bills
       WHERE jurisdiction = 'federal' AND external_id = ANY($1::text[])`,
      [batch.map((b) => b.externalId)],
    );
    const idOf = new Map<string, string>(ids.rows.map((r) => [r.external_id as string, r.id as string]));
    const want: Array<{ bill_id: string; pol: string }> = [];
    for (const b of batch) {
      const billId = idOf.get(b.externalId);
      if (!billId) continue;
      for (const g of b.cosponsorBioguides) {
        const pol = bioguides.get(g);
        if (pol) want.push({ bill_id: billId, pol });
      }
    }
    const sync = await client.query(SYNC_COSPONSORS, [JSON.stringify(want), [...idOf.values()]]);
    res.cosponsorsAdded += sync.rows[0].added;
    res.cosponsorsRemoved += sync.rows[0].removed;
  }, rollback);
}

/** Dry run for a Congress with no session row yet: nothing can be inserted, so only count new ids. */
async function previewBatch(batch: FederalBill[], res: FederalBillsResult): Promise<void> {
  const { rows } = await pool.query(
    `SELECT external_id FROM essentials.legislative_bills WHERE jurisdiction = 'federal' AND external_id = ANY($1::text[])`,
    [batch.map((b) => b.externalId)],
  );
  res.inserted += batch.length - rows.length;
  res.unchanged += rows.length;
}

async function download(type: FederalBillType, congress: number, fetchImpl: typeof fetch): Promise<Buffer | null> {
  const res = await fetchImpl(zipUrl(congress, type), { signal: AbortSignal.timeout(10 * 60_000) });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`govinfo ${type} HTTP ${res.status}`);
  return Buffer.from(await res.arrayBuffer());
}

export async function refreshFederalBills(opts: FederalBillsOptions = {}): Promise<FederalBillsResult> {
  const congress = opts.congress ?? currentCongress();
  const types = opts.types ?? FEDERAL_BILL_TYPES;
  const dryRun = !!opts.dryRun;
  const fetchImpl = opts.fetchImpl ?? fetch;
  const res: FederalBillsResult = {
    congress, files: 0, parsed: 0, inserted: 0, updated: 0, unchanged: 0,
    cosponsorsAdded: 0, cosponsorsRemoved: 0, typesSkipped: [], errors: [],
  };

  const sessionId = await ensureSession(congress, dryRun);
  const bioguides = await loadBioguideMap();
  log(`${ordinal(congress)} Congress${dryRun ? ' (dry run)' : ''}: ${types.join(' ')}; ${bioguides.size} linkable members`);

  for (const type of types) {
    let zipBuffer: Buffer | null;
    try {
      zipBuffer = await download(type, congress, fetchImpl);
    } catch (err) {
      res.errors.push(`${type}: ${(err as Error).message}`);
      continue;
    }
    if (!zipBuffer) { res.typesSkipped.push(type); log(`${type}: no file yet, skipped`); continue; }

    const zip = new LightZip(zipBuffer);
    const entries = zip.names.filter((n) => n.endsWith('.xml'));
    log(`${type}: ${entries.length} bills in the archive (${(zipBuffer.length / 1_048_576).toFixed(1)} MiB)`);
    let batch: FederalBill[] = [];
    const flush = async () => {
      if (!batch.length) return;
      try {
        if (!sessionId) await previewBatch(batch, res);
        else await writeBatch(batch, sessionId, bioguides, res, dryRun);
      } catch (err) {
        res.errors.push(`${type} batch: ${(err as Error).message}`);
      }
      batch = [];
    };

    for (let i = 0; i < entries.length; i++) {
      if (i > 0 && i % YIELD_EVERY === 0) await new Promise((r) => setImmediate(r));
      const name = entries[i];
      res.files++;
      const m = /BILLSTATUS-(\d+)([a-z]+?)(\d+)\.xml$/i.exec(name);
      if (!m) continue;
      try {
        const bill = parseBillStatus(zip.read(name)!.toString('utf8'), { congress, type, number: m[3] });
        if (!bill) continue;
        res.parsed++;
        batch.push(bill);
        if (batch.length >= BATCH) await flush();
      } catch (err) {
        res.errors.push(`${name}: ${(err as Error).message}`);
      }
      if (res.errors.length > 20) break;
    }
    await flush();
    if (res.errors.length > 20) { res.errors.push('too many errors, stopping'); break; }
  }

  log(
    `done: ${res.parsed} bills read, ${res.inserted} ${dryRun ? 'would be new' : 'new'}, ${res.updated} updated, ` +
    `${res.unchanged} unchanged, cosponsors +${res.cosponsorsAdded} -${res.cosponsorsRemoved}, ` +
    `types skipped: ${res.typesSkipped.length ? res.typesSkipped.join(' ') : 'none'}, errors: ${res.errors.length}`,
  );
  return res;
}

/** The job entry point: environment overrides, then fail loudly if anything went wrong. */
export async function runFederalBillsRefresh(): Promise<FederalBillsResult> {
  const types = process.env.FEDERAL_BILL_TYPES
    ? (process.env.FEDERAL_BILL_TYPES.split(',').map((s) => s.trim().toUpperCase()).filter(Boolean) as FederalBillType[])
    : undefined;
  const bad = (types ?? []).filter((t) => !FEDERAL_BILL_TYPES.includes(t));
  if (bad.length) throw new Error(`unknown bill types: ${bad.join(', ')}`);
  const res = await refreshFederalBills({
    congress: process.env.FEDERAL_CONGRESS ? Number(process.env.FEDERAL_CONGRESS) : undefined,
    types,
    dryRun: truthy(process.env.FEDERAL_DRY_RUN),
  });
  if (res.errors.length) {
    console.error(`[federal-bills] first errors: ${res.errors.slice(0, 3).join(' | ')}`);
    throw new Error(`federal bills refresh had ${res.errors.length} errors`);
  }
  return res;
}
