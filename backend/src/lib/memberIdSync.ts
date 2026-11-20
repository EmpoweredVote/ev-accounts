/**
 * memberIdSync — the seat match that gives every sitting state legislator their Open States person id (and, for
 * GA, ID, PA, SC, the legislature's own member id). src/lib/legislatorSeatMatch.ts explains the match.
 *
 * Run by scripts/member-ids/sync-member-ids.ts (by hand, dry run by default) and by the weekly `member-ids` job
 * (src/jobs/registry.ts, first step of the Render cron ev-jobs-legiscan), which applies.
 *
 * Without apply it only reads (a READ ONLY transaction) and logs, per state: holders, matched, new rows,
 * problems. With apply, in ONE transaction, it inserts the new rows and marks an existing name-matched row
 * that the seat match confirms (same person, same id) with the stronger match_method. An id already held by a
 * different person is a CONFLICT: listed and skipped, never moved (one id names one person). It never deletes.
 * `essentials.legislator_member_id_gaps` (CA_0402) lists every sitting legislator with no trusted Open States id.
 */
import type { PoolClient } from 'pg';
import { parseCsv } from './mnMemberIds.js';
import { matchState, parseOpenStatesCsv, type Holder, type IdRow } from './legislatorSeatMatch.js';

export const osUrl = (st: string) => `https://data.openstates.org/people/current/${st}.csv`;

async function fetchText(url: string): Promise<string> {
  const res = await fetch(url, { headers: { 'user-agent': 'EmpoweredVoteBot (+https://empowered.vote)' }, signal: AbortSignal.timeout(60_000) });
  if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
  return res.text();
}

export interface MemberIdSyncOptions { apply: boolean; states?: string[]; log?: (line: string) => void }
export interface MemberIdSyncResult {
  fresh: (IdRow & { state: string })[];
  confirmed: number;
  conflicts: string[];
  /** States whose Open States file could not be read: no verdict for them. */
  blind: string[];
  written: boolean;
}

export async function syncMemberIds(
  pool: { connect(): Promise<PoolClient> }, opts: MemberIdSyncOptions,
): Promise<MemberIdSyncResult> {
  const { apply } = opts;
  const only = opts.states?.map((s) => s.toLowerCase());
  const log = opts.log ?? ((l: string) => console.log(l));
  const today = new Date().toISOString().slice(0, 10);
  const client = await pool.connect();
  try {
    await client.query('BEGIN READ ONLY');
    const { rows: hr } = await client.query(
      `SELECT DISTINCT p.id::text AS pid, lower(d.state) AS st,
              CASE d.district_type WHEN 'STATE_UPPER' THEN 'upper' ELSE 'lower' END AS ch,
              coalesce(substring(d.ocd_id from '[^:]+$'), '') AS tail, coalesce(d.label, '') AS label, p.full_name
         FROM essentials.office_current_holder och
         JOIN essentials.offices o ON o.id = och.office_id
         JOIN essentials.districts d ON d.id = o.district_id
         JOIN essentials.politicians p ON p.id = och.politician_id
        WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER')`);
    const { rows: ex } = await client.query(
      `SELECT politician_id::text AS pid, id_type, id_value, match_method FROM essentials.legislative_politician_id_map`);
    await client.query('ROLLBACK');

    const holders = new Map<string, Holder[]>();
    for (const r of hr) {
      if (only && !only.includes(r.st)) continue;
      holders.set(r.st, [...(holders.get(r.st) ?? []), {
        politicianId: r.pid, state: r.st, chamber: r.ch, ocdTail: r.tail, label: r.label, fullName: r.full_name,
      }]);
    }
    const have = new Map(ex.map((r) => [`${r.pid}|${r.id_type}|${r.id_value}`, r.match_method as string]));
    const owner = new Map(ex.map((r) => [`${r.id_type}|${r.id_value}`, r.pid as string]));

    const fresh: (IdRow & { state: string })[] = [];
    const upgrades: (IdRow & { state: string })[] = []; // same row, made by name before; the seat match confirms it
    const conflicts: string[] = [];
    const blind: string[] = [];
    log('state  holders  matched  new  problems');
    for (const st of [...holders.keys()].sort()) {
      let people;
      try { people = parseOpenStatesCsv(parseCsv(await fetchText(osUrl(st)))); } catch (e) {
        log(`${st.padEnd(5)}  NO VERDICT: ${(e as Error).message}`); blind.push(st); continue;
      }
      if (!people.length) { log(`${st.padEnd(5)}  NO VERDICT: Open States file is empty`); blind.push(st); continue; }
      const res = matchState(st, holders.get(st)!, people);
      const add = res.rows.filter((r) => !have.has(`${r.politicianId}|${r.idType}|${r.idValue}`));
      for (const r of res.rows) if (have.get(`${r.politicianId}|${r.idType}|${r.idValue}`) === 'name') upgrades.push({ ...r, state: st });
      for (const r of add) {
        const o = owner.get(`${r.idType}|${r.idValue}`);
        if (o && o !== r.politicianId) conflicts.push(`${st}: ${r.idType} ${r.idValue} (${r.sourceName}) is already held by politician ${o}, not ${r.politicianId}`);
        else fresh.push({ ...r, state: st });
      }
      log(`${st.padEnd(5)}  ${String(res.holders).padStart(7)}  ${String(res.matched).padStart(7)}  ${String(add.length).padStart(4)}  ${res.problems.length}`);
      for (const p of res.problems) log(`         - ${p}`);
    }
    // A conflict is never written: the id stays with its current holder until a person fixes it (usually a
    // duplicate person record to merge, or an old name-matched row to remove).
    for (const c of conflicts) log(`CONFLICT (skipped): ${c}`);
    if (upgrades.length) log(`confirmed by seat: ${upgrades.length} existing name-matched row(s) → match_method '${upgrades[0].matchMethod}'`);
    log(`new rows: ${fresh.length}${apply ? '' : ' (dry run: nothing written)'}`);
    const result = { fresh, confirmed: upgrades.length, conflicts, blind, written: false };
    if (!apply || (!fresh.length && !upgrades.length)) return result;

    await client.query('BEGIN');
    for (const r of upgrades) {
      await client.query(
        `UPDATE essentials.legislative_politician_id_map SET match_method = $4, verified_at = now()
          WHERE politician_id = $1::uuid AND id_type = $2 AND id_value = $3 AND match_method = 'name'`,
        [r.politicianId, r.idType, r.idValue, r.matchMethod]);
    }
    const chunk = 500;
    for (let i = 0; i < fresh.length; i += chunk) {
      const part = fresh.slice(i, i + chunk);
      await client.query(
        `INSERT INTO essentials.legislative_politician_id_map (politician_id, id_type, id_value, match_method, source, verified_at)
         SELECT u.pid::uuid, u.t, u.v, u.m, u.src, now()
           FROM unnest($1::text[], $2::text[], $3::text[], $4::text[], $5::text[]) AS u(pid, t, v, m, src)`,
        [part.map((r) => r.politicianId), part.map((r) => r.idType), part.map((r) => r.idValue),
          part.map((r) => r.matchMethod), part.map((r) => `${osUrl(r.state)} (read ${today}; sync-member-ids)`)]);
    }
    await client.query('COMMIT');
    log(`WROTE ${fresh.length} rows; confirmed ${upgrades.length}.`);
    return { ...result, written: true };
  } catch (e) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    client.release();
  }
}

