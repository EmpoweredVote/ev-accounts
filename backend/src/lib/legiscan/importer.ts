/**
 * importer.ts — loads LegiScan weekly datasets into essentials.legislative_*.
 *
 * Flow per state (about 1 query when nothing changed, 3 per changed session):
 *   getDatasetList -> per session: skip if dataset_hash unchanged -> getDataset (ZIP)
 *   -> getSessionPeople -> match legislators -> bills, sponsors, committees, roll calls.
 * Everything after the downloads is local work on the ZIP contents (zero queries).
 * ev-cto decision 0031. Ported from backend/scripts/legiscan/import_state_legislative.py.
 *
 * Antipartisan rule: party fields in LegiScan's people records are never read or stored.
 */
import AdmZip from 'adm-zip';
import { pool } from '../db.js';
import { legiscanQuery } from './client.js';
import {
  STATE_NAMES,
  committeeChamber,
  getNameVariants,
  jurisdictionFor,
  normalizeBillStatus,
  normalizeVoteCast,
  parseIsoDate,
  pickSessionDatasets,
  sessionName,
  type DatasetListEntry,
  type SessionLabel,
} from './helpers.js';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Json = any;

export interface ImportOptions {
  dryRun?: boolean;
  force?: boolean;
  sessions?: SessionLabel[];
}

export interface ImportResult {
  bridgeRows: number;
  bills: number;
  votes: number;
  cosponsors: number;
  committees: number;
  memberships: number;
  sessionsSkipped: number;
  errors: string[];
}

const emptyResult = (): ImportResult => ({
  bridgeRows: 0, bills: 0, votes: 0, cosponsors: 0, committees: 0, memberships: 0,
  sessionsSkipped: 0, errors: [],
});

const log = (msg: string) => console.info(`[legiscan] ${msg}`);

const TRANSIENT = /Connection terminated|ECONNRESET|ETIMEDOUT|ENOTFOUND|EAI_AGAIN|timeout|57P01|08006/i;

/**
 * pool.query with retries for dropped connections and short network outages (a long load
 * must survive a blip). Waits 5s, 15s, 45s, 2min, 5min between tries, then gives up.
 */
async function query(text: string, params?: unknown[]): Promise<{ rows: any[] }> {
  const waits = [5_000, 15_000, 45_000, 120_000, 300_000];
  for (let attempt = 0; ; attempt++) {
    try {
      // A fresh copy per attempt: the driver can consume the array it is given.
      return await pool.query(text, params ? [...params] : undefined);
    } catch (err) {
      const msg = (err as Error).message ?? '';
      if (attempt >= waits.length || !TRANSIENT.test(msg)) throw err;
      log(`database error (${msg.slice(0, 80)}); retry ${attempt + 1} in ${waits[attempt] / 1000}s`);
      await new Promise((r) => setTimeout(r, waits[attempt]));
    }
  }
}

// ---------------------------------------------------------------------------
// Dataset download
// ---------------------------------------------------------------------------

export async function downloadDataset(
  apiKey: string,
  ds: DatasetListEntry,
): Promise<{ bills: Map<number, Json>; rollCalls: Map<number, Json> }> {
  const data = await legiscanQuery(apiKey, 'getDataset', {
    id: String(ds.session_id),
    access_key: ds.access_key,
  });
  const zipB64: string = data?.dataset?.zip ?? '';
  if (!zipB64) throw new Error(`Empty ZIP in dataset response for session ${ds.session_id}`);
  const zip = new AdmZip(Buffer.from(zipB64, 'base64'));

  const bills = new Map<number, Json>();
  const rollCalls = new Map<number, Json>();
  for (const entry of zip.getEntries()) {
    if (entry.isDirectory || !entry.entryName.endsWith('.json')) continue;
    let parsed: Json;
    try {
      parsed = JSON.parse(entry.getData().toString('utf8'));
    } catch {
      continue;
    }
    const path = entry.entryName.toLowerCase();
    if (path.includes('/bill/')) {
      const bill = parsed.bill ?? parsed;
      if (bill?.bill_id) bills.set(bill.bill_id, bill);
    } else if (path.includes('/vote/') || path.includes('/rollcall/')) {
      const rc = parsed.roll_call ?? parsed;
      if (rc?.roll_call_id) rollCalls.set(rc.roll_call_id, rc);
    }
  }
  log(`dataset ${ds.session_id} extracted: ${bills.size} bills, ${rollCalls.size} roll calls`);
  return { bills, rollCalls };
}

// ---------------------------------------------------------------------------
// Session + state bookkeeping
// ---------------------------------------------------------------------------

async function getOrCreateSession(
  jurisdiction: string, name: string, externalId: number, isCurrent: boolean,
): Promise<string> {
  const found = await query(
    'SELECT id FROM essentials.legislative_sessions WHERE jurisdiction = $1 AND external_id = $2',
    [jurisdiction, String(externalId)],
  );
  if (found.rows.length) return found.rows[0].id;
  const ins = await query(
    `INSERT INTO essentials.legislative_sessions (id, jurisdiction, name, external_id, is_current, source)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, 'legiscan') RETURNING id`,
    [jurisdiction, name, String(externalId), isCurrent],
  );
  return ins.rows[0].id;
}

async function isUnchanged(sessionId: number, hash: string): Promise<boolean> {
  const { rows } = await query(
    'SELECT dataset_hash, bills FROM essentials.legiscan_dataset_state WHERE legiscan_session_id = $1',
    [sessionId],
  );
  return rows.length > 0 && rows[0].dataset_hash === hash && Number(rows[0].bills) > 0;
}

async function markImported(
  sessionId: number, jurisdiction: string, hash: string, bridgeCount: number, bills: number,
): Promise<void> {
  await query(
    `INSERT INTO essentials.legiscan_dataset_state
       (legiscan_session_id, jurisdiction, dataset_hash, bridge_count, bills, imported_at)
     VALUES ($1, $2, $3, $4, $5, now())
     ON CONFLICT (legiscan_session_id) DO UPDATE SET
       jurisdiction = EXCLUDED.jurisdiction, dataset_hash = EXCLUDED.dataset_hash,
       bridge_count = EXCLUDED.bridge_count, bills = EXCLUDED.bills, imported_at = now()`,
    [sessionId, jurisdiction, hash, bridgeCount, bills],
  );
}

// ---------------------------------------------------------------------------
// Legislator bridge: LegiScan people_id -> essentials.politicians.id
// ---------------------------------------------------------------------------

export async function buildLegislatorBridge(
  apiKey: string, legiscanSessionId: number, stateCode: string, dryRun: boolean,
): Promise<{ bridge: Map<number, string>; people: Json[] }> {
  const data = await legiscanQuery(apiKey, 'getSessionPeople', { id: String(legiscanSessionId) });
  const people: Json[] = data?.sessionpeople?.people ?? [];
  const bridge = new Map<number, string>();

  // One query for every bridge that already exists.
  const existing = await query(
    `SELECT id_value, politician_id FROM essentials.legislative_politician_id_map
     WHERE id_type = 'legiscan' AND id_value = ANY($1::text[])`,
    [people.map((p) => String(p.people_id))],
  );
  const known = new Map<string, string>(existing.rows.map((r) => [r.id_value, r.politician_id]));

  let matched = 0, alreadyBridged = 0, noMatch = 0, ambiguous = 0;
  for (const person of people) {
    const first = String(person.first_name ?? '').trim();
    const last = String(person.last_name ?? '').trim();
    if (!first || !last) { noMatch++; continue; }

    const prior = known.get(String(person.people_id));
    if (prior) { bridge.set(person.people_id, prior); alreadyBridged++; continue; }

    // Same state only: a name shared with a legislator elsewhere must not match.
    const { rows } = await query(
      `SELECT DISTINCT p.id FROM essentials.politicians p
       JOIN essentials.office_terms ot ON ot.politician_id = p.id
       JOIN essentials.offices o ON o.id = ot.office_id
       JOIN essentials.districts d ON o.district_id = d.id
       WHERE LOWER(p.last_name) = LOWER($1)
         AND LOWER(p.first_name) = ANY($2::text[])
         AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER', 'STATE_EXEC')
         AND UPPER(d.state) = $3`,
      [last, getNameVariants(first), stateCode.toUpperCase()],
    );
    if (rows.length === 1) {
      bridge.set(person.people_id, rows[0].id);
      matched++;
      if (!dryRun) {
        await query(
          `INSERT INTO essentials.legislative_politician_id_map
             (id, politician_id, id_type, id_value, verified_at, source)
           VALUES (gen_random_uuid(), $1, 'legiscan', $2, NOW(), 'legiscan-state-people')
           ON CONFLICT DO NOTHING`,
          [rows[0].id, String(person.people_id)],
        );
      }
    } else if (rows.length === 0) {
      noMatch++;
    } else {
      ambiguous++;
      log(`ambiguous: ${first} ${last} (${stateCode}) has ${rows.length} candidates, skipped`);
    }
  }
  log(`bridge ${stateCode}: ${matched} new, ${alreadyBridged} existing, ${noMatch} no match, ${ambiguous} ambiguous`);
  return { bridge, people };
}

// ---------------------------------------------------------------------------
// Committees, sponsors
// ---------------------------------------------------------------------------

async function upsertCommittee(
  c: Json, jurisdiction: string, sessionId: string, dryRun: boolean,
): Promise<string | null> {
  const ext = String(c?.committee_id ?? '');
  if (!ext || ext === '0' || dryRun) return null;
  const { rows } = await query(
    `INSERT INTO essentials.legislative_committees
       (id, session_id, external_id, jurisdiction, name, type, chamber, is_current, source)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, 'committee', $5, true, 'legiscan')
     ON CONFLICT (external_id, jurisdiction) DO UPDATE SET
       name = EXCLUDED.name, chamber = EXCLUDED.chamber, session_id = EXCLUDED.session_id
     RETURNING id`,
    [sessionId, ext, jurisdiction, c.name ?? 'Unknown Committee', committeeChamber(c.chamber)],
  );
  return rows[0]?.id ?? null;
}

async function upsertMemberships(
  people: Json[], bridge: Map<number, string>, sessionId: string,
  committees: Map<number, string>, dryRun: boolean,
): Promise<number> {
  let n = 0;
  for (const p of people) {
    const dbCommittee = p.committee_id ? committees.get(p.committee_id) : undefined;
    const politicianId = bridge.get(p.people_id);
    if (!dbCommittee || !politicianId) continue;
    n++;
    if (dryRun) continue;
    // congress_number 0 = state level (unique index on committee, politician, congress_number).
    await query(
      `INSERT INTO essentials.legislative_committee_memberships
         (id, committee_id, politician_id, congress_number, role, is_current, session_id)
       VALUES (gen_random_uuid(), $1, $2, 0, $3, true, $4)
       ON CONFLICT (committee_id, politician_id, congress_number) DO UPDATE SET
         role = EXCLUDED.role, is_current = EXCLUDED.is_current, session_id = EXCLUDED.session_id`,
      [dbCommittee, politicianId, p.committee_sponsor ? 'chair' : 'member', sessionId],
    );
  }
  return n;
}

// ---------------------------------------------------------------------------
// Votes: queued, written in batches
// ---------------------------------------------------------------------------

type VoteRow = [
  politicianId: string, billId: string | null, sessionId: string, externalVoteId: string,
  question: string, position: string, voteDate: string | null, result: string,
  yea: number, nay: number,
];

/** 5,000 rows x 10 values = 50,000, safely under the 65,535-value limit of one statement. */
export const MAX_ROWS_PER_STATEMENT = 5000;

export class VoteBuffer {
  private rows = new Map<string, VoteRow>();
  written = 0;
  constructor(private batchSize = 1000) {}

  add(rows: VoteRow[]): void {
    for (const r of rows) this.rows.set(`${r[0]}|${r[1]}|${r[2]}|${r[3]}`, r);
  }
  get full(): boolean { return this.rows.size >= this.batchSize; }

  async flush(): Promise<void> {
    if (!this.rows.size) return;
    const all = [...this.rows.values()];
    this.rows = new Map();
    const COLS = 10;
    // One statement carries at most 65,535 values (a 16-bit count in the protocol), and the
    // buffer can hold far more rows than that after a group of new bills. Write in slices.
    for (let start = 0; start < all.length; start += MAX_ROWS_PER_STATEMENT) {
      const batch = all.slice(start, start + MAX_ROWS_PER_STATEMENT);
      const params: unknown[] = [];
      const tuples = batch.map((r, i) => {
        params.push(...r);
        const o = i * COLS;
        const ph = Array.from({ length: COLS }, (_, k) => `$${o + k + 1}`).join(', ');
        return `(gen_random_uuid(), ${ph}, 'legiscan')`;
      });
      await query(
        `INSERT INTO essentials.legislative_votes
           (id, politician_id, bill_id, session_id, external_vote_id, vote_question, position,
            vote_date, result, yea_count, nay_count, source)
         VALUES ${tuples.join(', ')}
         ON CONFLICT (politician_id, bill_id, session_id, external_vote_id) DO UPDATE SET
           position = EXCLUDED.position, vote_question = EXCLUDED.vote_question, result = EXCLUDED.result`,
        params,
      );
      this.written += batch.length;
    }
  }
}

/** Queue the vote rows of one roll call for our legislators. Returns how many rows. */
export function queueRollCall(
  rc: Json, billDbId: string, sessionId: string, bridge: Map<number, string>, buffer: VoteBuffer,
  dryRun: boolean,
): number {
  const voteDate = parseIsoDate(rc.date) ?? new Date().toISOString().slice(0, 10);
  const result = rc.passed === 1 ? 'passed' : 'failed';
  const rows: VoteRow[] = [];
  for (const mv of rc.votes ?? []) {
    const politicianId = bridge.get(mv.people_id);
    if (!politicianId) continue;
    rows.push([
      politicianId, billDbId, sessionId, `legiscan-${rc.roll_call_id}`,
      rc.desc ?? 'Vote', normalizeVoteCast(mv.vote_text), voteDate, result,
      rc.yea ?? 0, rc.nay ?? 0,
    ]);
  }
  if (!dryRun) buffer.add(rows);
  return rows.length;
}

// ---------------------------------------------------------------------------
// Bills (new ones in full; existing ones refreshed: status and roll calls)
// ---------------------------------------------------------------------------

const BILL_CHUNK = 400;

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

/** Multi-row VALUES placeholders: ($1,$2,..),($n,..) for rows of `width` columns. */
function placeholders(rows: number, width: number, startAt = 1): string {
  return Array.from({ length: rows }, (_, r) =>
    `(${Array.from({ length: width }, (_, c) => `$${startAt + r * width + c}`).join(', ')})`).join(', ');
}

async function importBills(
  bills: Map<number, Json>, rollCalls: Map<number, Json>, sessionId: string, jurisdiction: string,
  bridge: Map<number, string>, dryRun: boolean,
): Promise<{ bills: number; votes: number; cosponsors: number; committees: Map<number, string>; errors: string[] }> {
  const existingRows = await query(
    `SELECT external_id, id, raw_status FROM essentials.legislative_bills
     WHERE jurisdiction = $1 AND session_id = $2`,
    [jurisdiction, sessionId],
  );
  const existing = new Map<string, { id: string; rawStatus: string }>(
    existingRows.rows.map((r) => [r.external_id, { id: r.id, rawStatus: r.raw_status }]),
  );
  log(`${bills.size} bills in dataset, ${existing.size} already in the database`);

  const buffer = new VoteBuffer();
  const statusUpdates: Array<[string, string, string]> = [];
  const committees = new Map<number, string>();
  const errors: string[] = [];
  let votes = 0, cosponsors = 0, count = 0;

  const sorted = [...bills.entries()].sort((a, b) => a[0] - b[0]);
  const fresh = sorted.filter(([id]) => !existing.has(`legiscan-${id}`));
  const known = sorted.filter(([id]) => existing.has(`legiscan-${id}`));

  const queueVotes = (bill: Json, billDbId: string) => {
    for (const stub of bill.votes ?? []) {
      const rc = stub.roll_call_id ? rollCalls.get(stub.roll_call_id) : undefined;
      if (rc) votes += queueRollCall(rc, billDbId, sessionId, bridge, buffer, dryRun);
    }
  };

  // --- Existing bills: refresh status, queue roll calls.
  for (const [billId, bill] of known) {
    const prior = existing.get(`legiscan-${billId}`)!;
    const status = bill.status ?? 1;
    if (String(status) !== String(prior.rawStatus)) {
      statusUpdates.push([prior.id, String(status), normalizeBillStatus(status, bill.status_desc ?? '')]);
    }
    queueVotes(bill, prior.id);
    count++;
    if (!dryRun && buffer.full) await buffer.flush();
  }

  // --- New bills: committees once, then bills / sponsors / cosponsors in batches.
  const uniqueCommittees = new Map<number, Json>();
  for (const [, bill] of fresh) {
    if (bill.committee?.committee_id) uniqueCommittees.set(bill.committee.committee_id, bill.committee);
    for (const ref of bill.referrals ?? []) {
      if (ref.committee_id && !uniqueCommittees.has(ref.committee_id)) uniqueCommittees.set(ref.committee_id, ref);
    }
  }
  for (const [cid, c] of uniqueCommittees) {
    const id = await upsertCommittee(c, jurisdiction, sessionId, dryRun);
    if (id) committees.set(cid, id);
  }

  if (dryRun) {
    for (const [, bill] of fresh) { queueVotes(bill, 'dry-run'); count++; }
  } else {
    for (const group of chunk(fresh, BILL_CHUNK)) {
      try {
        const params: unknown[] = [];
        for (const [billId, bill] of group) {
          const status = bill.status ?? 1;
          params.push(
            sessionId, `legiscan-${billId}`, jurisdiction, bill.bill_number ?? bill.number ?? '',
            bill.title ?? '', String(status), normalizeBillStatus(status, bill.status_desc ?? ''),
            parseIsoDate(bill.history?.[0]?.date), bill.url ?? '',
          );
        }
        const ins = await query(
          `INSERT INTO essentials.legislative_bills
             (id, session_id, external_id, jurisdiction, number, title, summary,
              raw_status, status_label, introduced_at, url, source)
           SELECT gen_random_uuid(), v.* FROM (VALUES ${
             Array.from({ length: group.length }, (_, r) => {
               const o = r * 9;
               return `($${o + 1}::uuid, $${o + 2}, $${o + 3}, $${o + 4}, $${o + 5}, ''::text, $${o + 6}, $${o + 7}, $${o + 8}::date, $${o + 9}, 'legiscan'::text)`;
             }).join(', ')
           }) AS v(session_id, external_id, jurisdiction, number, title, summary,
                   raw_status, status_label, introduced_at, url, source)
           ON CONFLICT (external_id, jurisdiction) DO UPDATE SET
             title = EXCLUDED.title, raw_status = EXCLUDED.raw_status,
             status_label = EXCLUDED.status_label, url = EXCLUDED.url
           RETURNING external_id, id`,
          params,
        );
        const ids = new Map<string, string>(ins.rows.map((r) => [r.external_id, r.id]));

        const cosponsorRows: Array<[string, string]> = [];
        const sponsorRows: Array<[string, string]> = [];
        for (const [billId, bill] of group) {
          const billDbId = ids.get(`legiscan-${billId}`);
          if (!billDbId) continue;
          for (const sp of bill.sponsors ?? []) {
            const pol = bridge.get(sp.people_id);
            if (!pol) continue;
            if ((sp.sponsor_order ?? 99) === 1) sponsorRows.push([billDbId, pol]);
            else cosponsorRows.push([billDbId, pol]);
          }
          queueVotes(bill, billDbId);
          count++;
        }
        for (const part of chunk(cosponsorRows, 1000)) {
          await query(
            `INSERT INTO essentials.legislative_bill_cosponsors (id, bill_id, politician_id)
             SELECT gen_random_uuid(), v.bill_id::uuid, v.politician_id::uuid
             FROM (VALUES ${placeholders(part.length, 2)}) AS v(bill_id, politician_id)
             ON CONFLICT (bill_id, politician_id) DO NOTHING`,
            part.flat(),
          );
          cosponsors += part.length;
        }
        for (const part of chunk(sponsorRows, 1000)) {
          await query(
            `UPDATE essentials.legislative_bills b SET sponsor_id = v.sponsor_id::uuid
             FROM (VALUES ${placeholders(part.length, 2)}) AS v(id, sponsor_id)
             WHERE b.id = v.id::uuid`,
            part.flat(),
          );
        }
        if (buffer.full) await buffer.flush();
      } catch (err) {
        errors.push(`bill batch: ${(err as Error).message}`);
        if (errors.length > 20) { errors.push('too many errors, aborting bill import'); break; }
      }
    }
  }

  if (!dryRun) {
    try {
      await buffer.flush();
      for (const part of chunk(statusUpdates, 1000)) {
        await query(
          `UPDATE essentials.legislative_bills b
           SET raw_status = v.raw_status, status_label = v.status_label
           FROM (VALUES ${placeholders(part.length, 3)}) AS v(id, raw_status, status_label)
           WHERE b.id = v.id::uuid`,
          part.flat(),
        );
      }
    } catch (err) {
      errors.push(`final flush: ${(err as Error).message}`);
    }
  }
  log(`bills processed ${count} (${statusUpdates.length} status changes), ${votes} vote rows, ${errors.length} errors`);
  return { bills: count, votes, cosponsors, committees, errors };
}

// ---------------------------------------------------------------------------
// One state
// ---------------------------------------------------------------------------

export async function importState(
  apiKey: string, stateCode: string, opts: ImportOptions = {},
): Promise<ImportResult> {
  const dryRun = !!opts.dryRun;
  const result = emptyResult();
  const stateName = STATE_NAMES[stateCode];
  const jurisdiction = jurisdictionFor(stateCode);

  const list = await legiscanQuery(apiKey, 'getDatasetList', { state: stateCode });
  let datasets: DatasetListEntry[] = list?.datasetlist ?? [];
  if (!Array.isArray(datasets)) datasets = Object.values(datasets);

  const picks = pickSessionDatasets(datasets, opts.sessions);
  if (!picks.length) {
    result.errors.push(`no regular-session datasets found for ${stateCode}`);
    return result;
  }

  const allCommittees = new Map<number, string>();
  for (const { label, dataset: ds } of picks) {
    log(`${stateCode} ${label}: session ${ds.session_id} (${ds.year_start}), hash ${ds.dataset_hash.slice(0, 10)}`);

    // Unchanged since the last good import: stop before spending any more queries.
    // A grown legislator roster is not noticed here; use force after roster changes.
    if (!dryRun && !opts.force && (await isUnchanged(ds.session_id, ds.dataset_hash))) {
      log(`${stateCode} ${label}: unchanged, skipped`);
      result.sessionsSkipped++;
      continue;
    }

    const { bills, rollCalls } = await downloadDataset(apiKey, ds);
    const sessionId = await getOrCreateSession(
      jurisdiction, sessionName(stateName, ds), ds.session_id, label === 'current',
    );
    const { bridge, people } = await buildLegislatorBridge(apiKey, ds.session_id, stateCode, dryRun);
    result.bridgeRows += bridge.size;
    if (!bridge.size) {
      log(`${stateCode} ${label}: no legislators matched, skipping bills and votes`);
      continue;
    }

    const r = await importBills(bills, rollCalls, sessionId, jurisdiction, bridge, dryRun);
    for (const [k, v] of r.committees) allCommittees.set(k, v);
    result.bills += r.bills;
    result.votes += r.votes;
    result.cosponsors += r.cosponsors;
    result.committees += r.committees.size;
    result.errors.push(...r.errors);
    result.memberships += await upsertMemberships(people, bridge, sessionId, allCommittees, dryRun);

    if (!dryRun && r.bills > 0 && r.errors.length === 0) {
      await markImported(ds.session_id, jurisdiction, ds.dataset_hash, bridge.size, r.bills);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Every state with a sitting state legislator
// ---------------------------------------------------------------------------

export async function statesWithLegislators(): Promise<string[]> {
  const { rows } = await query(
    `SELECT DISTINCT UPPER(d.state) AS state
     FROM essentials.office_terms ot
     JOIN essentials.offices o ON o.id = ot.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type IN ('STATE_UPPER', 'STATE_LOWER') AND ot.term_end IS NULL`,
  );
  return rows.map((r) => r.state as string).filter((s) => STATE_NAMES[s]).sort();
}

export { emptyResult };
