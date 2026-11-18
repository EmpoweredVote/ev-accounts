/**
 * pacCareerJob — keeps the PAC-career tables (CA_0390–CA_0394) current from FEC's free bulk files, and rebuilds
 * the per-person verdicts (fec_pac_career). The rules live in pacCareer.ts; this file only moves rows.
 *
 * Disk IO (ev-cto decision 0038): nothing here reads transparent_motivations.contributions or any other big
 * table. The heavy reading — FEC's daily e-filing zips (up to ~1 GB on a deadline day) and committee master
 * files — happens in this process, streamed; the database receives a few hundred rows a night. The verdict
 * rebuild reads fec_pac_gifts (~60–80 MB at full size) and runs only when something changed.
 *
 *   nightly (end of ev-jobs-fec-burst): syncLinkedIds -> ccl (current cycle) -> daily e-filing zips ->
 *                                        committee codes -> rebuild verdicts if anything changed
 *   weekly:                              FEC per-cycle candidate totals for every id, stalest first -> rebuild
 *
 * Design: "PAC money over a whole career, from our own database" (approved by Chris Andrews 2026-11-18).
 */

import { Readable } from 'node:stream';
import readline from 'node:readline';
import unzipper from 'unzipper';
import { pool } from './db.js';
import { fecGetJson } from './fecGetJson.js';
import { currentFecCycle } from './fecCycle.js';
import {
  computeCareer, filingForm, normName, parseFiling, reconciles, reportKeyOf, round2, sumByGiver, apiReportKey, COMMITTEE_ID_RE,
  type CareerResult, type CmCodes, type GiftInput, type IdInput, type KindsByCommittee, type ParsedFiling,
  type PersonInput, type ReportInput, type TotalsInput, type Verdict,
} from './pacCareer.js';

type Queryable = { query: typeof pool.query };
const TM = 'transparent_motivations';
const BULK = 'https://www.fec.gov/files/bulk-downloads';
export const FIRST_CYCLE = 1980;

const yy = (cycle: number) => String(cycle).slice(2);
export const cyclesFrom = (from: number, to: number): number[] => {
  const out: number[] = [];
  for (let c = from; c <= to; c += 2) out.push(c);
  return out;
};

// ---------------------------------------------------------------------------------------------------------------
// FEC bulk files
// ---------------------------------------------------------------------------------------------------------------

/** Every '|'-separated line of the one text file in a remote FEC bulk zip. Streamed; constant memory. */
export async function* bulkZipLines(url: string): AsyncGenerator<string[]> {
  const res = await fetch(url);
  if (!res.ok || !res.body) throw new Error(`FEC bulk download failed: HTTP ${res.status} for ${url}`);
  const ctype = res.headers.get('content-type') ?? '';
  // A 200 can be an HTML error page: assert on the content type, never on the status alone.
  if (!/zip|octet-stream/.test(ctype)) throw new Error(`FEC bulk ${url} returned ${ctype}, not a zip`);
  const entry = Readable.fromWeb(res.body as Parameters<typeof Readable.fromWeb>[0]).pipe(unzipper.ParseOne());
  const rl = readline.createInterface({ input: entry.setEncoding('latin1'), crlfDelay: Infinity });
  for await (const line of rl) if (line) yield line.split('|');
}

// ---------------------------------------------------------------------------------------------------------------
// Ids and committees
// ---------------------------------------------------------------------------------------------------------------

/** Mirrors confirmed FEC links in politician_sources into fec_candidate_ids (found_by = 'linked'). */
export async function syncLinkedIds(db: Queryable = pool): Promise<{ added: number; removed: number }> {
  const add = await db.query(
    `INSERT INTO ${TM}.fec_candidate_ids (politician_id, fec_candidate_id, found_by, status, evidence)
     SELECT DISTINCT ps.essentials_politician_id, upper(trim(ps.external_id)), 'linked', 'confirmed',
            'politician_sources ' || ps.source_system
       FROM ${TM}.politician_sources ps
      WHERE ps.source_system LIKE 'fec%' AND ps.research_status = 'confirmed'
        AND upper(trim(ps.external_id)) ~ '^[HSP][0-9A-Z]{8}$'
     ON CONFLICT (politician_id, fec_candidate_id) DO UPDATE
        SET found_by = 'linked', status = 'confirmed', updated_at = now()
      WHERE ${TM}.fec_candidate_ids.found_by <> 'linked' OR ${TM}.fec_candidate_ids.status <> 'confirmed'`,
  );
  const del = await db.query(
    `DELETE FROM ${TM}.fec_candidate_ids f
      WHERE f.found_by = 'linked'
        AND NOT EXISTS (SELECT 1 FROM ${TM}.politician_sources ps
                         WHERE ps.essentials_politician_id = f.politician_id
                           AND upper(trim(ps.external_id)) = f.fec_candidate_id
                           AND ps.source_system LIKE 'fec%' AND ps.research_status = 'confirmed')`,
  );
  return { added: add.rowCount ?? 0, removed: del.rowCount ?? 0 };
}

/** FEC ids the job follows: every id that is not rejected. */
export async function trackedIds(db: Queryable = pool): Promise<Set<string>> {
  const r = await db.query<{ id: string }>(
    `SELECT DISTINCT fec_candidate_id AS id FROM ${TM}.fec_candidate_ids WHERE status <> 'rejected'`);
  return new Set(r.rows.map((x) => x.id));
}

/** Loads candidate -> committee links (designation P and A) for `cycles` from FEC's ccl files. */
export async function loadCandidateCommittees(cycles: number[], ids: Set<string>, db: Queryable = pool): Promise<number> {
  let n = 0;
  for (const cycle of cycles) {
    // ccl lists one (candidate, committee) pair several times (one row per linkage); keep one, P over A.
    const byKey = new Map<string, [string, number, string, string]>();
    // ccl: CAND_ID | CAND_ELECTION_YR | FEC_ELECTION_YR | CMTE_ID | CMTE_TP | CMTE_DSGN | LINKAGE_ID
    for await (const f of bulkZipLines(`${BULK}/${cycle}/ccl${yy(cycle)}.zip`)) {
      const cand = (f[0] ?? '').trim().toUpperCase();
      const dsgn = (f[5] ?? '').trim().toUpperCase();
      const cmte = (f[3] ?? '').trim().toUpperCase();
      if (!ids.has(cand) || (dsgn !== 'P' && dsgn !== 'A') || !COMMITTEE_ID_RE.test(cmte)) continue;
      const k = `${cand}|${cmte}`;
      if (byKey.get(k)?.[3] !== 'P') byKey.set(k, [cand, cycle, cmte, dsgn]);
    }
    const rows = [...byKey.values()];
    for (let i = 0; i < rows.length; i += 500) {
      const chunk = rows.slice(i, i + 500);
      await db.query(
        `INSERT INTO ${TM}.fec_candidate_committees (fec_candidate_id, cycle, committee_id, designation)
         SELECT * FROM unnest($1::text[], $2::smallint[], $3::text[], $4::text[])
         ON CONFLICT (fec_candidate_id, cycle, committee_id) DO UPDATE SET designation = EXCLUDED.designation`,
        [chunk.map((r) => r[0]), chunk.map((r) => r[1]), chunk.map((r) => r[2]), chunk.map((r) => r[3])]);
    }
    n += rows.length;
  }
  return n;
}

export async function upsertCommittees(rows: { id: string; cycle: number; committeeId: string; designation: string }[], db: Queryable = pool): Promise<void> {
  for (let i = 0; i < rows.length; i += 500) {
    const c = rows.slice(i, i + 500);
    await db.query(
      `INSERT INTO ${TM}.fec_candidate_committees (fec_candidate_id, cycle, committee_id, designation)
       SELECT * FROM unnest($1::text[], $2::smallint[], $3::text[], $4::text[])
       ON CONFLICT (fec_candidate_id, cycle, committee_id) DO NOTHING`,
      [c.map((r) => r.id), c.map((r) => r.cycle), c.map((r) => r.committeeId), c.map((r) => r.designation)]);
  }
}

/** Campaign committees the job follows: every committee linked to a tracked id, any cycle. */
export async function trackedCommittees(db: Queryable = pool): Promise<Set<string>> {
  const r = await db.query<{ c: string }>(
    `SELECT DISTINCT cc.committee_id AS c
       FROM ${TM}.fec_candidate_committees cc
       JOIN ${TM}.fec_candidate_ids f ON f.fec_candidate_id = cc.fec_candidate_id AND f.status <> 'rejected'`);
  return new Set(r.rows.map((x) => x.c));
}

// ---------------------------------------------------------------------------------------------------------------
// Committee codes (cm files)
// ---------------------------------------------------------------------------------------------------------------

export type NameIndex = Map<number, Map<string, Set<string>>>; // cycle -> normalised name -> committee ids

/**
 * Reads cm{YY} for `cycles` and stores codes for `wanted` committees. Returns a name index over EVERY committee
 * in those files (used to give an id to a gift whose filing named the committee but gave no id).
 */
export async function loadCommitteeKinds(cycles: number[], wanted: Set<string>, db: Queryable = pool): Promise<{ rows: number; names: NameIndex }> {
  const names: NameIndex = new Map();
  let total = 0;
  for (const cycle of cycles) {
    const idx = new Map<string, Set<string>>();
    names.set(cycle, idx);
    const rows: { id: string; name: string; tp: string; dsgn: string; org: string }[] = [];
    // cm: CMTE_ID|CMTE_NM|TRES_NM|ST1|ST2|CITY|ST|ZIP|CMTE_DSGN|CMTE_TP|CMTE_PTY|CMTE_FILING_FREQ|ORG_TP|CONNECTED_ORG_NM|CAND_ID
    for await (const f of bulkZipLines(`${BULK}/${cycle}/cm${yy(cycle)}.zip`)) {
      const id = (f[0] ?? '').trim().toUpperCase();
      if (!COMMITTEE_ID_RE.test(id)) continue;
      const k = normName(f[1]);
      if (k) (idx.get(k) ?? idx.set(k, new Set()).get(k)!).add(id);
      if (wanted.has(id)) rows.push({ id, name: (f[1] ?? '').trim(), dsgn: (f[8] ?? '').trim(), tp: (f[9] ?? '').trim(), org: (f[12] ?? '').trim() });
    }
    for (let i = 0; i < rows.length; i += 500) {
      const c = rows.slice(i, i + 500);
      await db.query(
        `INSERT INTO ${TM}.fec_committee_kinds (committee_id, cycle, name, cmte_tp, cmte_dsgn, org_tp)
         SELECT a, $2::smallint, b, c, d, e FROM unnest($1::text[], $3::text[], $4::text[], $5::text[], $6::text[]) AS t(a, b, c, d, e)
         ON CONFLICT (committee_id, cycle) DO UPDATE
            SET name = EXCLUDED.name, cmte_tp = EXCLUDED.cmte_tp, cmte_dsgn = EXCLUDED.cmte_dsgn,
                org_tp = EXCLUDED.org_tp, loaded_at = now()
          WHERE (${TM}.fec_committee_kinds.cmte_tp, ${TM}.fec_committee_kinds.cmte_dsgn, ${TM}.fec_committee_kinds.org_tp,
                 ${TM}.fec_committee_kinds.name) IS DISTINCT FROM (EXCLUDED.cmte_tp, EXCLUDED.cmte_dsgn, EXCLUDED.org_tp, EXCLUDED.name)`,
        [c.map((r) => r.id), cycle, c.map((r) => r.name), c.map((r) => r.tp), c.map((r) => r.dsgn), c.map((r) => r.org)]);
    }
    total += rows.length;
  }
  return { rows: total, names };
}

/** The committee id a giver's name belongs to in `cycle`, only when exactly one committee carries that name. */
export function idByName(names: NameIndex | undefined, cycle: number, name: string | null | undefined): string | null {
  const ids = names?.get(cycle)?.get(normName(name));
  return ids && ids.size === 1 ? [...ids][0]! : null;
}

// ---------------------------------------------------------------------------------------------------------------
// Reports and gifts
// ---------------------------------------------------------------------------------------------------------------

export interface ItemRow { refund: boolean; amt: number; id: string | null; name: string | null }

/** Sums rows per giver, first giving a no-id row the id its name uniquely carries in that cycle. */
function giftsOf(rows: ItemRow[], cycle: number, names?: NameIndex) {
  const fromFiling = new Set<string>();
  const resolved = rows.map((r) => {
    const id = (r.id ?? '').trim().toUpperCase();
    if (COMMITTEE_ID_RE.test(id)) { fromFiling.add(id); return { ...r, id }; }
    return { ...r, id: idByName(names, cycle, r.name) };
  });
  return sumByGiver(resolved).map((g) => ({ ...g, idFrom: g.giverId ? (fromFiling.has(g.giverId) ? 'filing' : 'name_match') : null }));
}

async function insertReport(db: Queryable, r: {
  committeeId: string; reportKey: string; cycle: number; source: 'efiling' | 'api'; fileNumber: number | null;
  form: string | null; reportType: string | null; coverageStart: string | null; coverageEnd: string | null;
  line11cTotal: number | null; line20cTotal: number | null; rows: ItemRow[]; names?: NameIndex;
}): Promise<{ itemized11c: number; itemized20c: number; reconciled: boolean | null; givers: number }> {
  const itemized11c = round2(r.rows.filter((x) => !x.refund).reduce((s, x) => s + x.amt, 0));
  const itemized20c = round2(r.rows.filter((x) => x.refund).reduce((s, x) => s + x.amt, 0));
  const reconciled = r.line11cTotal === null || r.line20cTotal === null ? null
    : reconciles(itemized11c, r.line11cTotal) && reconciles(itemized20c, r.line20cTotal);
  await db.query(
    `INSERT INTO ${TM}.fec_pac_reports (committee_id, report_key, cycle, source, file_number, form, report_type,
        coverage_start, coverage_end, line11c_total, line20c_total, line11c_itemized, line20c_itemized, reconciled)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
    [r.committeeId, r.reportKey, r.cycle, r.source, r.fileNumber, r.form, r.reportType, r.coverageStart || null,
     r.coverageEnd || null, r.line11cTotal, r.line20cTotal, itemized11c, itemized20c, reconciled]);
  const g = giftsOf(r.rows, r.cycle, r.names);
  for (let i = 0; i < g.length; i += 500) {
    const c = g.slice(i, i + 500);
    await db.query(
      `INSERT INTO ${TM}.fec_pac_gifts (committee_id, report_key, giver_key, giver_id, giver_id_from, giver_name, received, refunded, n_gifts)
       SELECT $1, $2, * FROM unnest($3::text[], $4::text[], $5::text[], $6::text[], $7::numeric[], $8::numeric[], $9::int[])`,
      [r.committeeId, r.reportKey, c.map((x) => x.giverKey), c.map((x) => x.giverId), c.map((x) => x.idFrom),
       c.map((x) => x.giverName || null), c.map((x) => x.received), c.map((x) => x.refunded), c.map((x) => x.n)]);
  }
  return { itemized11c, itemized20c, reconciled, givers: g.length };
}

export type StoreOutcome = 'stored' | 'older' | 'empty' | 'removed';

/**
 * Stores one campaign report from its raw filing, replacing any earlier version of the same report. An
 * amendment that moves the coverage dates also replaces the earlier report of the same type that it overlaps.
 * A report with no PAC money stores nothing (and removes an earlier version that had some).
 */
export async function storeFiling(p: ParsedFiling, fileNumber: number, names?: NameIndex): Promise<StoreOutcome> {
  const key = reportKeyOf(p);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // The nightly run and a backfill can reach the same report at once; FOR UPDATE cannot lock a row that does
    // not exist yet, so serialise on the committee instead (amendments may touch its other reports too).
    await client.query(`SELECT pg_advisory_xact_lock(hashtext('fec_pac_reports:' || $1))`, [p.committeeId]);
    const prev = await client.query<{ file_number: string | null }>(
      `SELECT file_number FROM ${TM}.fec_pac_reports WHERE committee_id = $1 AND report_key = $2`, [p.committeeId, key]);
    const prevFile = prev.rows[0]?.file_number == null ? null : Number(prev.rows[0].file_number);
    if (prevFile !== null && prevFile > fileNumber) { await client.query('ROLLBACK'); return 'older'; }
    await client.query(
      `DELETE FROM ${TM}.fec_pac_reports
        WHERE committee_id = $1 AND source = 'efiling' AND report_type = $2 AND report_key <> $3
          AND coverage_start <= $5::date AND coverage_end >= $4::date AND coalesce(file_number, 0) < $6`,
      [p.committeeId, p.reportType, key, p.coverageStart, p.coverageEnd, fileNumber]);
    const del = await client.query(`DELETE FROM ${TM}.fec_pac_reports WHERE committee_id = $1 AND report_key = $2`, [p.committeeId, key]);
    const empty = p.rows.length === 0 && p.line11cTotal === 0 && p.line20cTotal === 0;
    if (!empty) {
      await insertReport(client, {
        committeeId: p.committeeId, reportKey: key, cycle: p.cycle, source: 'efiling', fileNumber, form: p.form,
        reportType: p.reportType, coverageStart: p.coverageStart, coverageEnd: p.coverageEnd,
        line11cTotal: p.line11cTotal, line20cTotal: p.line20cTotal,
        rows: p.rows.map((x) => ({ refund: x.line === 'SB20C', amt: x.amt, id: x.id || null, name: x.name })), names,
      });
    }
    await client.query('COMMIT');
    return empty ? ((del.rowCount ?? 0) > 0 ? 'removed' : 'empty') : 'stored';
  } catch (e) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    client.release();
  }
}

/** Stores FEC's processed 11C/20C rows for a whole committee-cycle (used where no electronic filing exists). */
export async function storeApiCycle(committeeId: string, cycle: number, rows: ItemRow[], names?: NameIndex): Promise<void> {
  const key = apiReportKey(cycle);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`SELECT pg_advisory_xact_lock(hashtext('fec_pac_reports:' || $1))`, [committeeId]);
    await client.query(`DELETE FROM ${TM}.fec_pac_reports WHERE committee_id = $1 AND report_key = $2`, [committeeId, key]);
    if (rows.length) {
      await insertReport(client, { committeeId, reportKey: key, cycle, source: 'api', fileNumber: null, form: null, reportType: null,
        coverageStart: null, coverageEnd: null, line11cTotal: null, line20cTotal: null, rows, names });
    }
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------------------------------------------
// Daily e-filing zips
// ---------------------------------------------------------------------------------------------------------------

const HEAD_BYTES = 64 * 1024;

export interface DayResult { day: string; zipBytes: number | null; filings: number; campaignF3: number; kept: number; outcomes: Record<StoreOutcome | 'unparsed', number> }

/**
 * Reads one day's zip of every electronic filing FEC received. Keeps only campaign reports (F3N/F3A/F3T) whose
 * filer is in `committees`; every other entry is drained without being held. A deadline day is ~1 GB, streamed.
 */
export async function readEfilingDay(day: string, committees: Set<string>, names?: NameIndex): Promise<DayResult | null> {
  const url = `${BULK}/electronic/${day.replace(/-/g, '')}.zip`;
  const res = await fetch(url);
  if (res.status === 404 || res.status === 403) return null; // not posted yet (S3 answers 403 for a missing key)
  if (!res.ok || !res.body) throw new Error(`FEC e-filing zip ${day}: HTTP ${res.status}`);
  const ctype = res.headers.get('content-type') ?? '';
  if (!/zip|octet-stream/.test(ctype)) throw new Error(`FEC e-filing zip ${day} returned ${ctype}, not a zip`);
  const zipBytes = Number(res.headers.get('content-length') ?? '') || null;
  const out: DayResult = { day, zipBytes, filings: 0, campaignF3: 0, kept: 0, outcomes: { stored: 0, older: 0, empty: 0, removed: 0, unparsed: 0 } };

  const parser = Readable.fromWeb(res.body as Parameters<typeof Readable.fromWeb>[0]).pipe(unzipper.Parse({ forceStream: true }));
  for await (const entry of parser as AsyncIterable<unzipper.Entry>) {
    if (entry.type !== 'File' || !/\.fec$/i.test(entry.path)) { entry.autodrain(); continue; }
    out.filings++;
    const fileNumber = Number(entry.path.replace(/^.*?(\d+)\.fec$/i, '$1'));
    // Read just enough to see the form and the filer, then decide whether to keep the rest.
    const chunks: Buffer[] = [];
    let size = 0;
    let decided: boolean | null = null;
    for await (const chunk of entry as AsyncIterable<Buffer>) {
      if (decided === false) continue; // drain
      chunks.push(chunk);
      size += chunk.length;
      if (decided === null) {
        const head = Buffer.concat(chunks).toString('latin1', 0, Math.min(size, HEAD_BYTES));
        const lines = head.split(/\r?\n/);
        if (lines.length < 3 && size < HEAD_BYTES) continue;
        const form = filingForm(head);
        const filer = (lines[1] ?? '').split('\x1c')[1]?.trim().toUpperCase() ?? '';
        decided = !!form && /^F3[NAT]$/.test(form) && committees.has(filer);
        if (form && /^F3[NAT]$/.test(form)) out.campaignF3++;
        if (!decided) { chunks.length = 0; }
      }
    }
    if (!decided) continue;
    const parsed = parseFiling(Buffer.concat(chunks).toString('latin1'));
    if (!parsed || !(fileNumber > 0)) { out.outcomes.unparsed++; continue; }
    const o = await storeFiling(parsed, fileNumber, names);
    out.outcomes[o]++;
    if (o === 'stored' || o === 'removed') out.kept++;
  }
  await pool.query(
    `INSERT INTO ${TM}.fec_pac_efiling_days (day, zip_bytes, filings, kept) VALUES ($1, $2, $3, $4)
     ON CONFLICT (day) DO UPDATE SET zip_bytes = EXCLUDED.zip_bytes, filings = EXCLUDED.filings, kept = EXCLUDED.kept, loaded_at = now()`,
    [day, zipBytes, out.filings, out.kept]);
  return out;
}

const isoDay = (d: Date) => d.toISOString().slice(0, 10);

/** Days still to read: after the latest day read, up to yesterday, at most `maxDays`. */
export async function pendingEfilingDays(maxDays: number, startIfEmpty: string, today = new Date()): Promise<string[]> {
  const r = await pool.query<{ d: string | null }>(`SELECT max(day)::text AS d FROM ${TM}.fec_pac_efiling_days`);
  const last = r.rows[0]?.d;
  const start = new Date(`${last ?? startIfEmpty}T00:00:00Z`);
  if (last) start.setUTCDate(start.getUTCDate() + 1);
  const yesterday = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate() - 1));
  const days: string[] = [];
  for (const d = start; d <= yesterday && days.length < maxDays; d.setUTCDate(d.getUTCDate() + 1)) days.push(isoDay(d));
  return days;
}

// ---------------------------------------------------------------------------------------------------------------
// FEC per-cycle candidate totals (weekly)
// ---------------------------------------------------------------------------------------------------------------

interface FecTotals {
  cycle?: number; receipts?: number | null; coverage_end_date?: string | null;
  individual_itemized_contributions?: number | null; individual_unitemized_contributions?: number | null;
  other_political_committee_contributions?: number | null; refunded_other_political_committee_contributions?: number | null;
  political_party_committee_contributions?: number | null; candidate_contribution?: number | null; loans_made_by_candidate?: number | null;
}

/** Writes one id's per-cycle totals (two-year cycles, the table's existing meaning) and stamps totals_fetched_at. */
export async function storeTotals(id: string, results: FecTotals[], db: Queryable = pool): Promise<number> {
  let n = 0;
  for (const t of results) {
    if (typeof t.cycle !== 'number') continue;
    await db.query(
      `INSERT INTO ${TM}.fec_candidate_totals (external_id, cycle, receipts, individual_itemized, individual_unitemized,
          pac_contributions, party_contributions, candidate_self, candidate_loans, pac_refunds, coverage_end_date, fetched_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11, now())
       ON CONFLICT (external_id, cycle) DO UPDATE SET
         receipts = EXCLUDED.receipts, individual_itemized = EXCLUDED.individual_itemized,
         individual_unitemized = EXCLUDED.individual_unitemized, pac_contributions = EXCLUDED.pac_contributions,
         party_contributions = EXCLUDED.party_contributions, candidate_self = EXCLUDED.candidate_self,
         candidate_loans = EXCLUDED.candidate_loans, pac_refunds = EXCLUDED.pac_refunds,
         coverage_end_date = EXCLUDED.coverage_end_date, fetched_at = now()`,
      [id, String(t.cycle), t.receipts ?? null, t.individual_itemized_contributions ?? null, t.individual_unitemized_contributions ?? null,
       t.other_political_committee_contributions ?? null, t.political_party_committee_contributions ?? null,
       t.candidate_contribution ?? null, t.loans_made_by_candidate ?? null, t.refunded_other_political_committee_contributions ?? null,
       (t.coverage_end_date ?? '').slice(0, 10) || null]);
    n++;
  }
  await db.query(`UPDATE ${TM}.fec_candidate_ids SET totals_fetched_at = now() WHERE fec_candidate_id = $1`, [id]);
  return n;
}

export const totalsPath = (id: string) => `/candidate/${encodeURIComponent(id)}/totals/`;

/** Refreshes FEC totals for ids not fetched in `staleDays`, never-fetched first, at most `maxIds`. */
export async function refreshTotals(opts: { maxIds: number; staleDays: number }): Promise<{ ids: number; rows: number; failed: number }> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY is not set');
  const r = await pool.query<{ id: string }>(
    `SELECT fec_candidate_id AS id FROM ${TM}.fec_candidate_ids
      WHERE status <> 'rejected'
      GROUP BY fec_candidate_id
     HAVING max(totals_fetched_at) IS NULL OR max(totals_fetched_at) < now() - make_interval(days => $1)
      ORDER BY max(totals_fetched_at) NULLS FIRST
      LIMIT $2`, [opts.staleDays, opts.maxIds]);
  let rows = 0; let failed = 0;
  for (const { id } of r.rows) {
    try {
      const d = await fecGetJson<{ results?: FecTotals[] }>(
        `https://api.open.fec.gov/v1${totalsPath(id)}?election_full=false&per_page=100&api_key=${apiKey}`, `totals ${id}`);
      rows += await storeTotals(id, d.results ?? []);
    } catch (e) {
      failed++;
      console.error(`[pac-career] totals ${id} failed: ${(e as Error).message}`);
    }
  }
  return { ids: r.rows.length, rows, failed };
}

// ---------------------------------------------------------------------------------------------------------------
// Verdicts
// ---------------------------------------------------------------------------------------------------------------

/** Reads everything the verdicts need, once, and computes every person. Reads ~60–80 MB at full size. */
export async function computeAllCareers(db: Queryable = pool): Promise<CareerResult[]> {
  const ids = (await db.query<{ politician_id: string; id: string; status: 'confirmed' | 'needs_review'; fetched: boolean }>(
    `SELECT politician_id, fec_candidate_id AS id, status, totals_fetched_at IS NOT NULL AS fetched
       FROM ${TM}.fec_candidate_ids WHERE status <> 'rejected'`)).rows;
  const owners = new Map<string, Set<string>>();
  for (const r of ids) (owners.get(r.id) ?? owners.set(r.id, new Set()).get(r.id)!).add(r.politician_id);

  const totals = (await db.query<{ id: string; cycle: string; receipts: string | null; pac: string | null; refunds: string | null; through: string | null }>(
    `SELECT t.external_id AS id, t.cycle, t.receipts, t.pac_contributions AS pac, t.pac_refunds AS refunds, t.coverage_end_date::text AS through
       FROM ${TM}.fec_candidate_totals t
      WHERE t.external_id IN (SELECT fec_candidate_id FROM ${TM}.fec_candidate_ids WHERE status <> 'rejected')
        AND t.cycle ~ '^[0-9]{4}$'`)).rows;
  const committees = (await db.query<{ id: string; cycle: number; committee_id: string }>(
    `SELECT fec_candidate_id AS id, cycle, committee_id FROM ${TM}.fec_candidate_committees`)).rows;
  const reports = (await db.query<{ committee_id: string; report_key: string; cycle: number; source: 'efiling' | 'api'; i11: string; i20: string }>(
    `SELECT committee_id, report_key, cycle, source, line11c_itemized AS i11, line20c_itemized AS i20 FROM ${TM}.fec_pac_reports`)).rows;
  const gifts = (await db.query<{ committee_id: string; report_key: string; giver_key: string; giver_id: string | null; giver_name: string | null; received: string; refunded: string }>(
    `SELECT committee_id, report_key, giver_key, giver_id, giver_name, received, refunded FROM ${TM}.fec_pac_gifts`)).rows;
  const kindRows = (await db.query<{ committee_id: string; cycle: number; cmte_tp: string | null; cmte_dsgn: string | null; org_tp: string | null }>(
    `SELECT committee_id, cycle, cmte_tp, cmte_dsgn, org_tp FROM ${TM}.fec_committee_kinds`)).rows;

  const kinds: KindsByCommittee = new Map();
  for (const k of kindRows) {
    const m = kinds.get(k.committee_id) ?? kinds.set(k.committee_id, new Map<number, CmCodes>()).get(k.committee_id)!;
    m.set(Number(k.cycle), { tp: k.cmte_tp, dsgn: k.cmte_dsgn, org: k.org_tp });
  }
  const num = (s: string | null) => (s == null ? null : Number(s));
  const totalsById = group(totals, (t) => t.id);
  const cmtesById = group(committees, (c) => c.id);
  const reportsByCmte = group(reports, (r) => r.committee_id);
  const giftsByCmte = group(gifts, (g) => g.committee_id);

  const people = group(ids, (r) => r.politician_id);
  const out: CareerResult[] = [];
  for (const [pid, rows] of people) {
    const idInputs: IdInput[] = rows.map((r) => ({ id: r.id, status: r.status, shared: (owners.get(r.id)?.size ?? 0) > 1, totalsFetched: r.fetched }));
    const myIds = new Set(rows.map((r) => r.id));
    const tIn: TotalsInput[] = [...myIds].flatMap((id) => (totalsById.get(id) ?? []).map((t) => ({
      id, cycle: Number(t.cycle), receipts: num(t.receipts), pac: num(t.pac), pacRefunds: num(t.refunds), coverageEnd: t.through })));
    const cIn = [...myIds].flatMap((id) => (cmtesById.get(id) ?? []).map((c) => ({ id, cycle: Number(c.cycle), committeeId: c.committee_id })));
    const myCmtes = new Set(cIn.map((c) => c.committeeId));
    const rIn: ReportInput[] = [...myCmtes].flatMap((c) => (reportsByCmte.get(c) ?? []).map((r) => ({
      committeeId: c, reportKey: r.report_key, cycle: Number(r.cycle), source: r.source, itemized11c: Number(r.i11), itemized20c: Number(r.i20) })));
    const gIn: GiftInput[] = [...myCmtes].flatMap((c) => (giftsByCmte.get(c) ?? []).map((g) => ({
      committeeId: c, reportKey: g.report_key, giverKey: g.giver_key, giverId: g.giver_id, giverName: g.giver_name,
      received: Number(g.received), refunded: Number(g.refunded) })));
    const input: PersonInput = { politicianId: pid, ids: idInputs, totals: tIn, committees: cIn, reports: rIn, gifts: gIn };
    out.push(computeCareer(input, kinds));
  }
  return out;
}

function group<T>(rows: T[], key: (r: T) => string): Map<string, T[]> {
  const m = new Map<string, T[]>();
  for (const r of rows) { const k = key(r); (m.get(k) ?? m.set(k, []).get(k)!).push(r); }
  return m;
}

/** Writes every verdict and removes rows for people no longer tracked. Returns the tally by verdict. */
export async function rebuildCareers(): Promise<Record<Verdict, number>> {
  const results = await computeAllCareers();
  const tally: Record<Verdict, number> = { no_receipts: 0, takes_corporate: 0, unverified: 0, no_corporate_pac: 0, no_pac: 0 };
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (let i = 0; i < results.length; i += 200) {
      const c = results.slice(i, i + 200);
      await client.query(
        `INSERT INTO ${TM}.fec_pac_career (politician_id, verdict, why_unverified, kept_corporate, kept_trade, kept_coop,
            kept_other_pac, kept_candidate, kept_party, kept_unknown, last_corporate_cycle, career_receipts, first_cycle,
            last_cycle, through, cycles_checked, cycles_unreconciled, fec_candidate_ids, computed_at)
         SELECT (x->>'pid')::uuid, x->>'verdict', ARRAY(SELECT jsonb_array_elements_text(x->'why')),
                (x->>'corporate')::numeric, (x->>'trade')::numeric, (x->>'coop')::numeric, (x->>'other_pac')::numeric,
                (x->>'candidate')::numeric, (x->>'party')::numeric, (x->>'unknown')::numeric,
                (x->>'last_corp')::smallint, (x->>'receipts')::numeric, (x->>'first')::smallint, (x->>'last')::smallint,
                (x->>'through')::date, (x->>'checked')::int,
                ARRAY(SELECT jsonb_array_elements_text(x->'unrec'))::smallint[],
                ARRAY(SELECT jsonb_array_elements_text(x->'ids')), now()
           FROM jsonb_array_elements($1::jsonb) x
         ON CONFLICT (politician_id) DO UPDATE SET
           verdict = EXCLUDED.verdict, why_unverified = EXCLUDED.why_unverified, kept_corporate = EXCLUDED.kept_corporate,
           kept_trade = EXCLUDED.kept_trade, kept_coop = EXCLUDED.kept_coop, kept_other_pac = EXCLUDED.kept_other_pac,
           kept_candidate = EXCLUDED.kept_candidate, kept_party = EXCLUDED.kept_party, kept_unknown = EXCLUDED.kept_unknown,
           last_corporate_cycle = EXCLUDED.last_corporate_cycle, career_receipts = EXCLUDED.career_receipts,
           first_cycle = EXCLUDED.first_cycle, last_cycle = EXCLUDED.last_cycle, through = EXCLUDED.through,
           cycles_checked = EXCLUDED.cycles_checked, cycles_unreconciled = EXCLUDED.cycles_unreconciled,
           fec_candidate_ids = EXCLUDED.fec_candidate_ids, computed_at = now()`,
        [JSON.stringify(c.map((r) => ({
          pid: r.politicianId, verdict: r.verdict, why: r.why, corporate: r.kept.corporate, trade: r.kept.trade, coop: r.kept.coop,
          other_pac: r.kept.other_pac, candidate: r.kept.candidate, party: r.kept.party, unknown: r.kept.unknown,
          last_corp: r.lastCorporateCycle, receipts: r.careerReceipts, first: r.firstCycle, last: r.lastCycle, through: r.through,
          checked: r.cycles.length, unrec: r.cycles.filter((x) => !x.reconciled).map((x) => x.cycle), ids: r.fecIds,
        })))]);
    }
    await client.query(
      `DELETE FROM ${TM}.fec_pac_career c WHERE NOT (c.politician_id = ANY($1::uuid[]))`, [results.map((r) => r.politicianId)]);
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    client.release();
  }
  for (const r of results) tally[r.verdict]++;
  return tally;
}

// ---------------------------------------------------------------------------------------------------------------
// Job entry points
// ---------------------------------------------------------------------------------------------------------------

/** Giving committees that appear in the gifts but have no stored codes yet. */
async function giversWithoutKinds(): Promise<Set<string>> {
  const r = await pool.query<{ id: string }>(
    `SELECT DISTINCT g.giver_id AS id FROM ${TM}.fec_pac_gifts g
      WHERE g.giver_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM ${TM}.fec_committee_kinds k WHERE k.committee_id = g.giver_id)`);
  return new Set(r.rows.map((x) => x.id));
}
async function allGivers(): Promise<Set<string>> {
  const r = await pool.query<{ id: string }>(`SELECT DISTINCT giver_id AS id FROM ${TM}.fec_pac_gifts WHERE giver_id IS NOT NULL`);
  return new Set(r.rows.map((x) => x.id));
}

/**
 * Nightly. Env: PAC_EFILING_MAX_DAYS (default 7 per run), PAC_EFILING_START (first day when nothing has been
 * read yet; default 7 days ago). Prints every count, including the ones that are zero.
 */
export async function runPacCareerNightly(): Promise<void> {
  const t0 = Date.now();
  const cycle = Number(currentFecCycle());
  const linked = await syncLinkedIds();
  const ids = await trackedIds();
  const ccl = await loadCandidateCommittees([cycle], ids);
  const committees = await trackedCommittees();
  // Current-cycle codes for every giver we hold (codes change as committees re-register), plus the name index
  // that gives an id to a no-id gift.
  const { rows: kindRows, names } = await loadCommitteeKinds([cycle], await allGivers());
  console.log(`[pac-career] ids=${ids.size} (+${linked.added}/-${linked.removed} linked) committees=${committees.size} ccl rows=${ccl} current-cycle codes=${kindRows}`);

  const maxDays = Number(process.env.PAC_EFILING_MAX_DAYS ?? 7);
  const start = process.env.PAC_EFILING_START ?? isoDay(new Date(Date.now() - 7 * 86_400_000));
  const days = await pendingEfilingDays(maxDays, start);
  let changed = linked.added + linked.removed > 0;
  for (const day of days) {
    const r = await readEfilingDay(day, committees, names);
    if (!r) { console.log(`[pac-career] ${day}: zip not posted yet — stopping here`); break; }
    console.log(`[pac-career] ${day}: ${r.filings} filings, ${r.campaignF3} campaign reports, kept ${r.kept} ` +
      `(stored ${r.outcomes.stored}, removed ${r.outcomes.removed}, older ${r.outcomes.older}, no PAC money ${r.outcomes.empty}, unparsed ${r.outcomes.unparsed})` +
      (r.zipBytes ? `, ${(r.zipBytes / 1e6).toFixed(1)} MB` : ''));
    if (r.kept > 0) changed = true;
  }

  const newGivers = await giversWithoutKinds();
  if (newGivers.size) {
    const k = await loadCommitteeKinds(cyclesFrom(FIRST_CYCLE, cycle), newGivers);
    console.log(`[pac-career] codes for ${newGivers.size} new giver(s): ${k.rows} rows`);
    changed = true;
  }
  if (changed || kindRows > 0) {
    const tally = await rebuildCareers();
    console.log(`[pac-career] verdicts: ${JSON.stringify(tally)}`);
  } else {
    console.log('[pac-career] nothing changed — verdicts not rebuilt');
  }
  console.log(`[pac-career] nightly done in ${Math.round((Date.now() - t0) / 1000)}s`);
}

/** Weekly. Env: PAC_TOTALS_MAX_IDS (default 2500), PAC_TOTALS_STALE_DAYS (default 6). */
export async function runPacCareerWeekly(): Promise<void> {
  await syncLinkedIds();
  const r = await refreshTotals({ maxIds: Number(process.env.PAC_TOTALS_MAX_IDS ?? 2500), staleDays: Number(process.env.PAC_TOTALS_STALE_DAYS ?? 6) });
  console.log(`[pac-career] totals: ${r.ids} id(s), ${r.rows} cycle row(s), ${r.failed} failed`);
  const tally = await rebuildCareers();
  console.log(`[pac-career] verdicts: ${JSON.stringify(tally)}`);
  if (r.failed > 0) throw new Error(`${r.failed} FEC totals request(s) failed`);
}
