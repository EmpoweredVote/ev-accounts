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
  const found = await pool.query(
    'SELECT id FROM essentials.legislative_sessions WHERE jurisdiction = $1 AND external_id = $2',
    [jurisdiction, String(externalId)],
  );
  if (found.rows.length) return found.rows[0].id;
  const ins = await pool.query(
    `INSERT INTO essentials.legislative_sessions (id, jurisdiction, name, external_id, is_current, source)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, 'legiscan') RETURNING id`,
    [jurisdiction, name, String(externalId), isCurrent],
  );
  return ins.rows[0].id;
}

async function isUnchanged(sessionId: number, hash: string): Promise<boolean> {
  const { rows } = await pool.query(
    'SELECT dataset_hash, bills FROM essentials.legiscan_dataset_state WHERE legiscan_session_id = $1',
    [sessionId],
  );
  return rows.length > 0 && rows[0].dataset_hash === hash && Number(rows[0].bills) > 0;
}

async function markImported(
  sessionId: number, jurisdiction: string, hash: string, bridgeCount: number, bills: number,
): Promise<void> {
  await pool.query(
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
  const existing = await pool.query(
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
    const { rows } = await pool.query(
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
        await pool.query(
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
  const { rows } = await pool.query(
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

async function extractCommittees(
  bill: Json, jurisdiction: string, sessionId: string, dryRun: boolean,
): Promise<Map<number, string>> {
  const map = new Map<number, string>();
  const main = bill.committee;
  if (main?.committee_id) {
    const id = await upsertCommittee(main, jurisdiction, sessionId, dryRun);
    if (id) map.set(main.committee_id, id);
  }
  for (const ref of bill.referrals ?? []) {
    if (ref.committee_id && !map.has(ref.committee_id)) {
      const id = await upsertCommittee(ref, jurisdiction, sessionId, dryRun);
      if (id) map.set(ref.committee_id, id);
    }
  }
  return map;
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
    await pool.query(
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

async function linkSponsors(
  sponsors: Json[], bridge: Map<number, string>, billDbId: string, dryRun: boolean,
): Promise<{ primary: string | null; cosponsors: number }> {
  let primary: string | null = null;
  let cosponsors = 0;
  for (const s of sponsors) {
    const politicianId = bridge.get(s.people_id);
    if (!politicianId) continue;
    if ((s.sponsor_order ?? 99) === 1) {
      primary = politicianId;
    } else if (!dryRun) {
      await pool.query(
        `INSERT INTO essentials.legislative_bill_cosponsors (id, bill_id, politician_id)
         VALUES (gen_random_uuid(), $1, $2) ON CONFLICT (bill_id, politician_id) DO NOTHING`,
        [billDbId, politicianId],
      );
      cosponsors++;
    }
  }
  return { primary, cosponsors };
}

// ---------------------------------------------------------------------------
// Votes: queued, written in batches
// ---------------------------------------------------------------------------

type VoteRow = [
  politicianId: string, billId: string | null, sessionId: string, externalVoteId: string,
  question: string, position: string, voteDate: string | null, result: string,
  yea: number, nay: number,
];

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
    const batch = [...this.rows.values()];
    this.rows = new Map();
    const COLS = 10;
    const params: unknown[] = [];
    const tuples = batch.map((r, i) => {
      params.push(...r);
      const o = i * COLS;
      const ph = Array.from({ length: COLS }, (_, k) => `$${o + k + 1}`).join(', ');
      return `(gen_random_uuid(), ${ph}, 'legiscan')`;
    });
    await pool.query(
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

async function importBills(
  bills: Map<number, Json>, rollCalls: Map<number, Json>, sessionId: string, jurisdiction: string,
  bridge: Map<number, string>, dryRun: boolean,
): Promise<{ bills: number; votes: number; cosponsors: number; committees: Map<number, string>; errors: string[] }> {
  const existingRows = await pool.query(
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

  for (const [billId, bill] of [...bills.entries()].sort((a, b) => a[0] - b[0])) {
    try {
      const externalId = `legiscan-${billId}`;
      const prior = existing.get(externalId);
      let billDbId: string;

      if (prior) {
        billDbId = prior.id;
        const status = bill.status ?? 1;
        if (String(status) !== String(prior.rawStatus)) {
          statusUpdates.push([prior.id, String(status), normalizeBillStatus(status, bill.status_desc ?? '')]);
        }
      } else {
        for (const [k, v] of await extractCommittees(bill, jurisdiction, sessionId, dryRun)) committees.set(k, v);
        if (dryRun) {
          // Count this bill's votes too, so a dry run reports the true size of the load.
          for (const stub of bill.votes ?? []) {
            const rc = stub.roll_call_id ? rollCalls.get(stub.roll_call_id) : undefined;
            if (rc) votes += queueRollCall(rc, 'dry-run', sessionId, bridge, buffer, true);
          }
          count++;
          continue;
        }
        const status = bill.status ?? 1;
        const introduced = parseIsoDate(bill.history?.[0]?.date);
        const ins = await pool.query(
          `INSERT INTO essentials.legislative_bills
             (id, session_id, external_id, jurisdiction, number, title, summary,
              raw_status, status_label, introduced_at, url, source)
           VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, '', $6, $7, $8, $9, 'legiscan')
           ON CONFLICT (external_id, jurisdiction) DO UPDATE SET
             title = EXCLUDED.title, raw_status = EXCLUDED.raw_status,
             status_label = EXCLUDED.status_label, url = EXCLUDED.url
           RETURNING id`,
          [sessionId, externalId, jurisdiction, bill.bill_number ?? bill.number ?? '', bill.title ?? '',
           String(status), normalizeBillStatus(status, bill.status_desc ?? ''), introduced, bill.url ?? ''],
        );
        billDbId = ins.rows[0].id;
        const { primary, cosponsors: n } = await linkSponsors(bill.sponsors ?? [], bridge, billDbId, dryRun);
        cosponsors += n;
        if (primary) {
          await pool.query('UPDATE essentials.legislative_bills SET sponsor_id = $1 WHERE id = $2', [primary, billDbId]);
        }
      }

      for (const stub of bill.votes ?? []) {
        const rc = stub.roll_call_id ? rollCalls.get(stub.roll_call_id) : undefined;
        if (rc) votes += queueRollCall(rc, billDbId, sessionId, bridge, buffer, dryRun);
      }
      count++;
      if (!dryRun && buffer.full) await buffer.flush();
    } catch (err) {
      errors.push(`bill ${billId}: ${(err as Error).message}`);
      if (errors.length > 50) { errors.push('too many errors, aborting bill import'); break; }
    }
  }

  if (!dryRun) {
    try {
      await buffer.flush();
      if (statusUpdates.length) {
        const params: unknown[] = [];
        const tuples = statusUpdates.map((u, i) => {
          params.push(...u);
          return `($${i * 3 + 1}, $${i * 3 + 2}, $${i * 3 + 3})`;
        });
        await pool.query(
          `UPDATE essentials.legislative_bills b
           SET raw_status = v.raw_status, status_label = v.status_label
           FROM (VALUES ${tuples.join(', ')}) AS v(id, raw_status, status_label)
           WHERE b.id = v.id::uuid`,
          params,
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
  const { rows } = await pool.query(
    `SELECT DISTINCT UPPER(d.state) AS state
     FROM essentials.office_terms ot
     JOIN essentials.offices o ON o.id = ot.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type IN ('STATE_UPPER', 'STATE_LOWER') AND ot.term_end IS NULL`,
  );
  return rows.map((r) => r.state as string).filter((s) => STATE_NAMES[s]).sort();
}

export { emptyResult };
