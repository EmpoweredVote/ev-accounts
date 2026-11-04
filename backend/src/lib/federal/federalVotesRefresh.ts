/**
 * federalVotesRefresh.ts — weekly refresh of House and Senate roll-call votes for the Congress in
 * session, from LegiScan's US dataset.
 *
 *   node dist/jobs/run.js federal-votes
 *
 * Environment overrides, for manual runs:
 *   FEDERAL_CONGRESS=119        only this Congress (default: the one in session today)
 *   FEDERAL_VOTES_DRY_RUN=1     read and count the votes that would be added, write nothing
 *   FEDERAL_VOTES_FORCE=1       ignore the "dataset unchanged" skip (use after more politicians get a
 *                               bioguide id, so their older votes are picked up)
 *
 * It adds only (member, roll call) pairs that are not stored yet, so it is safe to run any time and
 * as often as you like. It never deletes or rewrites a stored vote. About 3 LegiScan queries a run
 * (dataset list, dataset, people) from the shared monthly budget, and none when nothing changed.
 *
 * A vote is stored only for a member who matches one of our politicians (by bioguide id, else by a
 * LegiScan id in legislative_politician_id_map). Nobody is created. The bill link comes from the
 * LegiScan bill number matched to legislative_bills.external_id (<congress>-<TYPE>-<n>), so run
 * federal-bills first; a roll call with no matching bill (nominations, procedure) keeps a null bill.
 *
 * Antipartisan rule: LegiScan's party fields are never read.
 */
import { pool } from '../db.js';
import { legiscanDatasetZip, legiscanQuery, readQueriesThisMonth, MONTHLY_QUERY_CAP } from '../legiscan/client.js';
import { normalizeVoteCast, parseIsoDate, type DatasetListEntry } from '../legiscan/helpers.js';
import { VoteBuffer, isUnchanged, markImported } from '../legiscan/importer.js';
import { currentCongress, ordinal } from './billStatus.js';
import { ensureSession, loadBioguideMap } from './federalBillsRefresh.js';
import { LightZip } from './lightZip.js';

/* eslint-disable @typescript-eslint/no-explicit-any */
const log = (msg: string) => console.info(`[federal-votes] ${msg}`);
const truthy = (v: string | undefined) => !!v && !['0', 'false', 'no', ''].includes(v.toLowerCase());

/** LegiScan bill-number prefix -> congress.gov bill type. */
export const LEGISCAN_TYPE: Record<string, string> = {
  HB: 'HR', HR: 'HRES', HJR: 'HJRES', HCR: 'HCONRES', SB: 'S', SR: 'SRES', SJR: 'SJRES', SCR: 'SCONRES',
};

/** "HB1347" in the 119th -> "119-HR-1347"; null for anything that is not a bill or resolution. */
export function billKeyFor(congress: number, legiscanNumber: string | undefined): string | null {
  const m = /^([A-Z]+)(\d+)$/.exec((legiscanNumber ?? '').trim());
  const type = m ? LEGISCAN_TYPE[m[1]] : undefined;
  return m && type ? `${congress}-${type}-${m[2]}` : null;
}

/** The US dataset entry for one Congress, from a getDatasetList answer. */
export function pickCongressDataset(list: any, congress: number): (DatasetListEntry & { session_name?: string }) | null {
  let datasets: any[] = list?.datasetlist ?? [];
  if (!Array.isArray(datasets)) datasets = Object.values(datasets);
  return datasets.find((d) => {
    const m = /^(\d+)\w+ Congress/.exec(d?.session_name ?? '');
    return m && Number(m[1]) === congress && (d.special ?? 0) === 0;
  }) ?? null;
}

export interface FederalVotesOptions {
  congress?: number;
  dryRun?: boolean;
  force?: boolean;
}

export interface FederalVotesResult {
  congress: number;
  skippedUnchanged: boolean;
  rollCalls: number;
  members: number;
  alreadyStored: number;
  newVotes: number;
  noBill: number;
}

/** LegiScan people_id -> politician id: bioguide id first, then a LegiScan id we already hold. */
async function memberMap(sessionId: number, apiKey: string): Promise<Map<number, string>> {
  const bioguides = await loadBioguideMap();
  const lg = await pool.query(
    `SELECT id_value, (array_agg(DISTINCT politician_id))[1] AS pid FROM essentials.legislative_politician_id_map
     WHERE id_type = 'legiscan' GROUP BY id_value HAVING count(DISTINCT politician_id) = 1`,
  );
  const byLegiscan = new Map<string, string>(lg.rows.map((r) => [r.id_value as string, r.pid as string]));
  const people: any[] = (await legiscanQuery(apiKey, 'getSessionPeople', { id: String(sessionId) }))?.sessionpeople?.people ?? [];
  const out = new Map<number, string>();
  for (const p of people) {
    const pid = (p.bioguide_id && bioguides.get(p.bioguide_id)) || byLegiscan.get(String(p.people_id));
    if (pid) out.set(p.people_id, pid);
  }
  return out;
}

export async function refreshFederalVotes(apiKey: string, opts: FederalVotesOptions = {}): Promise<FederalVotesResult> {
  const congress = opts.congress ?? currentCongress();
  const dryRun = !!opts.dryRun;
  const res: FederalVotesResult = {
    congress, skippedUnchanged: false, rollCalls: 0, members: 0, alreadyStored: 0, newVotes: 0, noBill: 0,
  };

  const ds = pickCongressDataset(await legiscanQuery(apiKey, 'getDatasetList', { state: 'US' }), congress);
  if (!ds) { log(`no LegiScan dataset for the ${ordinal(congress)} Congress yet; nothing to do`); return res; }
  log(`${ordinal(congress)} Congress: session ${ds.session_id}, hash ${ds.dataset_hash.slice(0, 10)}${dryRun ? ' (dry run)' : ''}`);

  if (!opts.force && (await isUnchanged(ds.session_id, ds.dataset_hash))) {
    log('dataset unchanged since the last good run; skipped');
    res.skippedUnchanged = true;
    return res;
  }

  const sessionId = await ensureSession(congress, dryRun);
  if (!sessionId) { log('no session row yet (dry run); run federal-bills first'); return res; }

  // Streamed download (the JSON is never held, only the zip), read with LightZip: adm-zip's per-file
  // objects cost ~200 MiB for this archive's 21k files and crashed a 512 MiB job.
  const zip = new LightZip(await legiscanDatasetZip(apiKey, ds.session_id, ds.access_key));
  const billFiles = zip.names.filter((n) => /\/bill\/[^/]+\.json$/.test(n));
  const voteFiles = zip.names.filter((n) => /\/vote\/[^/]+\.json$/.test(n));
  log(`dataset read: ${zip.size} files, ${billFiles.length} bills, ${voteFiles.length} roll calls`);
  const members = await memberMap(ds.session_id, apiKey);
  res.members = new Set(members.values()).size;

  // LegiScan bill id -> our bill key. Each bill file is read and dropped.
  const keyOfBill = new Map<number, string>();
  for (let i = 0; i < billFiles.length; i++) {
    if (i > 0 && i % 500 === 0) await new Promise((r) => setImmediate(r));
    const j = zip.readJson(billFiles[i]);
    const bill = j?.bill ?? j;
    const key = bill?.bill_id ? billKeyFor(congress, bill.bill_number ?? bill.number) : null;
    if (key) keyOfBill.set(bill.bill_id, key);
  }
  const bills = new Map<string, string>(
    (await pool.query(
      `SELECT external_id, id FROM essentials.legislative_bills WHERE jurisdiction = 'federal' AND session_id = $1`,
      [sessionId],
    )).rows.map((r) => [r.external_id as string, r.id as string]),
  );
  const stored = new Set<string>(
    (await pool.query(
      `SELECT politician_id, external_vote_id FROM essentials.legislative_votes
       WHERE source = 'legiscan' AND session_id = $1`,
      [sessionId],
    )).rows.map((r) => `${r.politician_id}|${r.external_vote_id}`),
  );
  log(`${members.size} linkable members, ${bills.size} bills, ${stored.size} votes already stored, ${voteFiles.length} roll calls`);

  const buffer = new VoteBuffer(5000);
  for (let i = 0; i < voteFiles.length; i++) {
    if (i > 0 && i % 100 === 0) await new Promise((r) => setImmediate(r));
    const j = zip.readJson(voteFiles[i]);
    const rc = j?.roll_call ?? j;
    if (!rc?.roll_call_id) continue;
    const xid = `legiscan-${rc.roll_call_id}`;
    const billId = bills.get(keyOfBill.get(rc.bill_id) ?? '') ?? null;
    const date = parseIsoDate(rc.date);
    const result = rc.passed === 1 ? 'passed' : 'failed';
    let added = 0;
    for (const mv of rc.votes ?? []) {
      const pol = members.get(mv.people_id);
      if (!pol) continue;
      if (stored.has(`${pol}|${xid}`)) { res.alreadyStored++; continue; }
      added++;
      if (!dryRun) {
        buffer.add([[pol, billId, sessionId, xid, rc.desc ?? 'Vote', normalizeVoteCast(mv.vote_text), date, result, rc.yea ?? 0, rc.nay ?? 0]]);
        if (buffer.full) await buffer.flush();
      }
    }
    if (added) { res.rollCalls++; res.newVotes += added; if (!billId) res.noBill += added; }
  }
  if (!dryRun) {
    await buffer.flush();
    await markImported(ds.session_id, 'federal', ds.dataset_hash, members.size, billFiles.length);
  }

  log(
    `done: ${res.newVotes} ${dryRun ? 'votes would be added' : 'votes added'} across ${res.rollCalls} roll calls ` +
    `(${res.noBill} with no bill link), ${res.alreadyStored} already stored. ` +
    `Queries this month: ${await readQueriesThisMonth()}/${MONTHLY_QUERY_CAP}`,
  );
  return res;
}

/** The job entry point. */
export async function runFederalVotesRefresh(): Promise<FederalVotesResult> {
  const apiKey = process.env.LEGISCAN_API_KEY;
  if (!apiKey) throw new Error('LEGISCAN_API_KEY is not set');
  return refreshFederalVotes(apiKey, {
    congress: process.env.FEDERAL_CONGRESS ? Number(process.env.FEDERAL_CONGRESS) : undefined,
    dryRun: truthy(process.env.FEDERAL_VOTES_DRY_RUN),
    force: truthy(process.env.FEDERAL_VOTES_FORCE),
  });
}
