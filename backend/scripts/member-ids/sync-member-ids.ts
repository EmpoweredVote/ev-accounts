/**
 * sync-member-ids.ts — give every sitting state legislator their Open States person id (and, for GA, ID, PA,
 * SC, the legislature's own member id), matched by seat. src/lib/legislatorSeatMatch.ts explains the match.
 *
 *   npx tsx scripts/member-ids/sync-member-ids.ts [--states ga,pa] [--apply] [--tsv <review.tsv>]
 *
 * Without --apply it only reads (a READ ONLY transaction) and prints, per state: holders, matched, new rows,
 * problems. With --apply, in ONE transaction, it inserts the new rows and marks an existing name-matched row
 * that the seat match confirms (same person, same id) with the stronger match_method. An id already held by a
 * different person is a CONFLICT: listed and skipped, never moved (one id names one person). It never deletes.
 * Exit 1 only on an error.
 *
 * WHEN TO RUN. After any change to who sits in a legislature (a roster refresh, a special election, the
 * January turnover), and before a Stage 5 batch. `essentials.legislator_member_id_gaps` (CA_0402) lists every
 * sitting legislator with no trusted Open States id; it should be empty, or hold only the people this
 * script reports as problems. Minnesota's LRL and Senate ids come from mn-member-ids.ts.
 *
 * Exit 0: done (problems and conflicts are listed, never written).
 * Exit 2: no verdict (a state's Open States file is missing or empty).
 */
import { writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag, hasFlag, loadBackendEnv } from '../lib/cliEnv.js';
import { parseCsv } from '../../src/lib/mnMemberIds.js';
import { matchState, parseOpenStatesCsv, type Holder, type IdRow } from '../../src/lib/legislatorSeatMatch.js';

loadBackendEnv(resolve(dirname(fileURLToPath(import.meta.url)), '..', '..'));
const osUrl = (st: string) => `https://data.openstates.org/people/current/${st}.csv`;

async function fetchText(url: string): Promise<string> {
  const res = await fetch(url, { headers: { 'user-agent': 'EmpoweredVoteBot (+https://empowered.vote)' }, signal: AbortSignal.timeout(60_000) });
  if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
  return res.text();
}

async function main(): Promise<number> {
  const apply = hasFlag(process.argv, '--apply');
  const only = flag(process.argv, '--states')?.toLowerCase().split(',').map((s) => s.trim()).filter(Boolean);
  const today = new Date().toISOString().slice(0, 10);
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
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
    let blind = false;
    console.log('state  holders  matched  new  problems');
    for (const st of [...holders.keys()].sort()) {
      let people;
      try { people = parseOpenStatesCsv(parseCsv(await fetchText(osUrl(st)))); } catch (e) {
        console.log(`${st.padEnd(5)}  NO VERDICT: ${(e as Error).message}`); blind = true; continue;
      }
      if (!people.length) { console.log(`${st.padEnd(5)}  NO VERDICT: Open States file is empty`); blind = true; continue; }
      const res = matchState(st, holders.get(st)!, people);
      const add = res.rows.filter((r) => !have.has(`${r.politicianId}|${r.idType}|${r.idValue}`));
      for (const r of res.rows) if (have.get(`${r.politicianId}|${r.idType}|${r.idValue}`) === 'name') upgrades.push({ ...r, state: st });
      for (const r of add) {
        const o = owner.get(`${r.idType}|${r.idValue}`);
        if (o && o !== r.politicianId) conflicts.push(`${st}: ${r.idType} ${r.idValue} (${r.sourceName}) is already held by politician ${o}, not ${r.politicianId}`);
        else fresh.push({ ...r, state: st });
      }
      console.log(`${st.padEnd(5)}  ${String(res.holders).padStart(7)}  ${String(res.matched).padStart(7)}  ${String(add.length).padStart(4)}  ${res.problems.length}`);
      for (const p of res.problems) console.log(`         - ${p}`);
    }
    // A conflict is never written: the id stays with its current holder until a person fixes it (usually a
    // duplicate person record to merge, or an old name-matched row to remove).
    for (const c of conflicts) console.log(`CONFLICT (skipped): ${c}`);
    if (upgrades.length) console.log(`confirmed by seat: ${upgrades.length} existing name-matched row(s) → match_method '${upgrades[0].matchMethod}'`);
    const tsv = flag(process.argv, '--tsv');
    if (tsv) writeFileSync(tsv, ['state\tpolitician_id\tid_type\tid_value\tmatch_method\tsource_name',
      ...fresh.map((r) => [r.state, r.politicianId, r.idType, r.idValue, r.matchMethod, r.sourceName].join('\t'))].join('\n') + '\n');
    console.log(`new rows: ${fresh.length}${apply ? '' : ' (dry run: nothing written)'}`);
    if (!apply) return blind ? 2 : 0;
    if (!fresh.length && !upgrades.length) return 0;

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
    console.log(`WROTE ${fresh.length} rows; confirmed ${upgrades.length}.`);
    return 0;
  } catch (e) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    client.release();
    await pool.end();
  }
}

main().then((c) => process.exit(c), (e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
