/**
 * repair-legiscan-person.ts — move a LegiScan person id that was matched to the WRONG politician, with
 * everything the importer credited through it: votes, primary sponsorships and cosponsorships.
 *
 *   npx tsx scripts/member-ids/repair-legiscan-person.ts --state CA --ds <dataset root> \
 *       --move <legiscan people_id>=<right politician_id> [--move …] [--apply]
 *
 * WHY. The state importer (src/lib/legiscan/importer.ts) bridges a LegiScan person to us by name, and
 * every vote, sponsorship and cosponsorship of that person follows the bridge. A wrong bridge puts one
 * legislator's record on another's page, and the right person's page shows nothing. Re-running the
 * importer does not undo it: its writes are keyed on our politician_id, so the wrong rows stay. Found
 * 2026-11-20: five California senators' LegiScan ids sat on Assembly members (Susan Rubio's 8,920 votes
 * on Catherine Stefani's page), and Tony Strickland's and Caroline Menjivar's on inactive duplicate rows.
 *
 * HOW. The dataset ZIPs we already hold (`<ds>/<ST>-<session_id>/…/{vote,bill}/*.json`, the Stage 5 cache
 * or an unpacked copy from the `legiscan-datasets` bucket) say exactly which roll calls and bills belong to
 * the id. No LegiScan query is made. For each --move, in ONE transaction:
 *   1. the id's row in essentials.legislative_politician_id_map moves to the right person (match_method
 *      'manual': a person checked the LegiScan record's name, chamber and district);
 *   2. the votes on the id's roll calls move (`legiscan-<roll_call_id>`), from the person who held it;
 *   3. bills whose primary sponsor is the id get the right sponsor_id;
 *   4. cosponsor rows are added for the right person, and the wrong person's row goes only when none of
 *      that person's own LegiScan ids cosponsored the bill.
 * Only sessions we hold (essentials.legislative_sessions.external_id) and only rows the wrong person holds
 * are touched. Without --apply the same writes run and are ROLLED BACK, so the counts printed are exact.
 * Committee memberships are not touched (the importer reads them from a field that is empty in current
 * datasets); check them separately.
 *
 * Exit 0 done; 1 error; 2 no verdict (no dataset folder for the state, or an id the datasets never name).
 */
import { globSync, readFileSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag, flags, hasFlag, loadBackendEnv } from '../lib/cliEnv.js';

loadBackendEnv(resolve(dirname(fileURLToPath(import.meta.url)), '..', '..'));

interface Evidence { votes: Set<string>; sponsor: Set<string>; cosponsor: Set<string>; name: string }

function readDatasets(ds: string, st: string, ids: Set<number>, sessions: Set<string>): Map<number, Evidence> {
  const ev = new Map<number, Evidence>();
  const get = (id: number) => ev.get(id) ?? ev.set(id, { votes: new Set(), sponsor: new Set(), cosponsor: new Set(), name: '' }).get(id)!;
  for (const dir of globSync(join(ds, `${st}-*`))) {
    if (!sessions.has(dir.split('-').pop()!)) continue;
    for (const f of globSync(join(dir, '*', '*', 'people', '*.json'))) {
      const p = JSON.parse(readFileSync(f, 'utf8')).person;
      if (ids.has(p.people_id)) get(p.people_id).name = `${p.name} (${p.role} ${p.district})`;
    }
    for (const f of globSync(join(dir, '*', '*', 'vote', '*.json'))) {
      const rc = JSON.parse(readFileSync(f, 'utf8')).roll_call;
      for (const v of rc.votes ?? []) if (ids.has(v.people_id)) get(v.people_id).votes.add(`legiscan-${rc.roll_call_id}`);
    }
    for (const f of globSync(join(dir, '*', '*', 'bill', '*.json'))) {
      const b = JSON.parse(readFileSync(f, 'utf8')).bill;
      for (const s of b.sponsors ?? []) {
        if (!ids.has(s.people_id)) continue;
        (s.sponsor_order === 1 ? get(s.people_id).sponsor : get(s.people_id).cosponsor).add(`legiscan-${b.bill_id}`);
      }
    }
  }
  return ev;
}

async function main(): Promise<number> {
  const st = flag(process.argv, '--state')?.toUpperCase();
  const ds = flag(process.argv, '--ds');
  const moves = flags(process.argv, '--move').map((m) => {
    const [ls, to] = m.split('=');
    if (!/^\d+$/.test(ls ?? '') || !/^[0-9a-f-]{36}$/i.test(to ?? '')) throw new Error(`--move ${m}: expected <legiscan id>=<politician uuid>`);
    return { ls, to };
  });
  if (!st || !ds || !moves.length) throw new Error('usage: repair-legiscan-person.ts --state XX --ds <root> --move <id>=<uuid> [--move …] [--apply]');
  const apply = hasFlag(process.argv, '--apply');

  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const c = await pool.connect();
  try {
    const { rows: sess } = await c.query(
      `SELECT id::text, external_id FROM essentials.legislative_sessions WHERE source = 'legiscan' OR external_id ~ '^\\d+$'`);
    const sessionIds = new Map(sess.map((r) => [r.external_id as string, r.id as string]));
    const ev = readDatasets(ds, st, new Set(moves.map((m) => Number(m.ls))), new Set(sessionIds.keys()));
    if (!ev.size) { console.log(`NO VERDICT: no dataset under ${ds} names these ids for ${st}`); return 2; }

    await c.query('BEGIN');
    let blind = false;
    for (const { ls, to } of moves) {
      const e = ev.get(Number(ls));
      if (!e) { console.log(`${ls}: NO VERDICT, no ${st} dataset names this id`); blind = true; continue; }
      const { rows: held } = await c.query(
        `SELECT m.id, m.politician_id::text AS pid, p.full_name FROM essentials.legislative_politician_id_map m
           JOIN essentials.politicians p ON p.id = m.politician_id WHERE m.id_type = 'legiscan' AND m.id_value = $1`, [ls]);
      const { rows: [toRow] } = await c.query(`SELECT full_name FROM essentials.politicians WHERE id = $1`, [to]);
      if (!toRow) throw new Error(`${ls}: politician ${to} does not exist`);
      if (held[0]?.pid === to) { console.log(`${ls} ${e.name}: already on ${toRow.full_name}`); continue; }
      const from = held[0]?.pid;
      console.log(`${ls} ${e.name}: ${held[0]?.full_name ?? '(no row)'} -> ${toRow.full_name}`);
      console.log(`   datasets: ${e.votes.size} roll calls, ${e.sponsor.size} primary sponsorships, ${e.cosponsor.size} cosponsorships`);

      if (held.length) {
        await c.query(
          `UPDATE essentials.legislative_politician_id_map
              SET politician_id = $2, match_method = 'manual', verified_at = now(),
                  source = source || '; moved ' || to_char(now(), 'YYYY-MM-DD') || ' by repair-legiscan-person.ts'
            WHERE id = $1`, [held[0].id, to]);
      } else {
        await c.query(
          `INSERT INTO essentials.legislative_politician_id_map (id, politician_id, id_type, id_value, verified_at, source, match_method)
           VALUES (gen_random_uuid(), $1, 'legiscan', $2, now(), 'repair-legiscan-person.ts', 'manual')`, [to, ls]);
      }
      if (!from) continue;

      // The wrong person's own LegiScan ids (after this move): their roll calls and cosponsorships stay with them.
      const { rows: own } = await c.query(
        `SELECT id_value FROM essentials.legislative_politician_id_map WHERE politician_id = $1 AND id_type = 'legiscan'`, [from]);
      const ownIds = new Set(own.map((r) => Number(r.id_value)));
      const ownEv = ownIds.size ? [...readDatasets(ds, st, ownIds, new Set(sessionIds.keys())).values()] : [];
      const ownVotes = new Set(ownEv.flatMap((x) => [...x.votes]));
      const keep = new Set(ownEv.flatMap((x) => [...x.cosponsor]));
      // A roll call both ids voted on holds ONE row for the wrong person (the importer's upsert kept the last):
      // which vote it is cannot be told, so it stays and is reported.
      const shared = [...e.votes].filter((v) => ownVotes.has(v));
      const votes = [...e.votes].filter((v) => !ownVotes.has(v));
      const dup = await c.query(
        `DELETE FROM essentials.legislative_votes f USING essentials.legislative_votes t
          WHERE f.politician_id = $1 AND t.politician_id = $2 AND f.external_vote_id = ANY($3::text[])
            AND t.external_vote_id = f.external_vote_id AND t.bill_id IS NOT DISTINCT FROM f.bill_id AND t.session_id = f.session_id`,
        [from, to, votes]);
      const mv = await c.query(
        `UPDATE essentials.legislative_votes SET politician_id = $2
          WHERE politician_id = $1 AND external_vote_id = ANY($3::text[]) AND session_id = ANY($4::uuid[])`,
        [from, to, votes, [...sessionIds.values()]]);
      const sp = await c.query(
        `UPDATE essentials.legislative_bills SET sponsor_id = $2
          WHERE sponsor_id = $1 AND external_id = ANY($3::text[]) AND session_id = ANY($4::uuid[])`,
        [from, to, [...e.sponsor], [...sessionIds.values()]]);
      const co = [...e.cosponsor];
      const add = await c.query(
        `INSERT INTO essentials.legislative_bill_cosponsors (id, bill_id, politician_id)
         SELECT gen_random_uuid(), x.bill_id, $2 FROM essentials.legislative_bill_cosponsors x
           JOIN essentials.legislative_bills b ON b.id = x.bill_id
          WHERE x.politician_id = $1 AND b.external_id = ANY($3::text[])
         ON CONFLICT (bill_id, politician_id) DO NOTHING`, [from, to, co]);
      // The wrong person keeps a cosponsor row only where one of their own LegiScan ids cosponsored the bill.
      const del = await c.query(
        `DELETE FROM essentials.legislative_bill_cosponsors x USING essentials.legislative_bills b
          WHERE b.id = x.bill_id AND x.politician_id = $1 AND b.external_id = ANY($2::text[])`,
        [from, co.filter((b) => !keep.has(b))]);
      console.log(`   moved: ${mv.rowCount} votes (${dup.rowCount} duplicates dropped), ${sp.rowCount} sponsorships; `
        + `cosponsor rows: ${add.rowCount} added, ${del.rowCount} removed from ${held[0].full_name}`
        + `${shared.length ? `; ${shared.length} roll call(s) both ids voted on LEFT as they are (check by hand)` : ''}`);
    }
    await c.query(apply && !blind ? 'COMMIT' : 'ROLLBACK');
    console.log(apply && !blind ? 'COMMITTED' : `ROLLED BACK${blind ? ' (an id had no verdict)' : ' (dry run: pass --apply)'}`);
    return blind ? 2 : 0;
  } catch (err) {
    await c.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    c.release();
    await pool.end();
  }
}

main().then((code) => process.exit(code), (e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
