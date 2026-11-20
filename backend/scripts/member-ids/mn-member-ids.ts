/**
 * mn-member-ids.ts — Minnesota legislators' own member ids, matched by seat. Read-only.
 *
 *   npx tsx scripts/member-ids/mn-member-ids.ts [--sql <out.sql>] [--tsv <out.tsv>]
 *
 * Reads the sitting Minnesota legislators from essentials.office_current_holder (inside a READ ONLY
 * transaction), fetches the LRL current-member list, the Senate member API and the Open States people
 * file, and pairs them by chamber + district (src/lib/mnMemberIds.ts). Prints a summary and every
 * problem. Exit 1 if there is any problem: nothing may be written from a run that disagrees anywhere.
 *
 * --sql writes the INSERT block for a migration (it never runs it). --tsv writes the pairs for review.
 * Re-run at each session start or after a special election; rows already in the map are left out.
 */
import { writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag, loadBackendEnv } from '../lib/cliEnv.js';
import { fetchRawHtml } from '../../src/lib/mnRevisorAuthors.js';
import {
  matchMinnesota, normDistrict, parseLrlCurrent, parseOpenStatesPeople, parseSenateMembers,
  type MemberIdRow, type SeatHolder,
} from '../../src/lib/mnMemberIds.js';

loadBackendEnv(resolve(dirname(fileURLToPath(import.meta.url)), '..', '..'));

const URLS = {
  lrl: 'https://www.lrl.mn.gov/legdb/current',
  senate: 'https://www.senate.mn/api/members',
  openStates: 'https://data.openstates.org/people/current/mn.csv',
};

const sqlText = (s: string) => `'${s.replace(/'/g, "''")}'`;

async function main(): Promise<number> {
  const today = new Date().toISOString().slice(0, 10);
  const sources = {
    lrl: `${URLS.lrl} (read ${today})`,
    senate: `${URLS.senate} (read ${today})`,
    openStates: `${URLS.openStates} (read ${today})`,
  };
  const [lrlHtml, senateJson, osCsv] = await Promise.all([
    fetchRawHtml(URLS.lrl), fetchRawHtml(URLS.senate), fetchRawHtml(URLS.openStates),
  ]);
  const lrl = parseLrlCurrent(lrlHtml);
  const senate = parseSenateMembers(JSON.parse(senateJson));
  const openStates = parseOpenStatesPeople(osCsv);
  if (lrl.length < 150 || senate.length < 50) {
    console.error(`NO VERDICT: LRL gave ${lrl.length} members, Senate API ${senate.length} — a page changed shape`);
    return 2;
  }

  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const client = await pool.connect();
  let holders: SeatHolder[];
  let existing: Set<string>;
  try {
    await client.query('BEGIN READ ONLY');
    const { rows } = await client.query(
      `SELECT p.id::text AS pid, d.district_type, substring(d.ocd_id from '[^:]+$') AS dist,
              p.full_name, p.photo_origin_url
         FROM essentials.office_current_holder och
         JOIN essentials.offices o ON o.id = och.office_id
         JOIN essentials.districts d ON d.id = o.district_id
         JOIN essentials.politicians p ON p.id = och.politician_id
        WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND upper(d.state) = 'MN'`);
    holders = rows.map((r) => ({
      politicianId: r.pid, chamber: r.district_type === 'STATE_UPPER' ? 'senate' : 'house',
      district: normDistrict(String(r.dist ?? '')), fullName: r.full_name, photoOriginUrl: r.photo_origin_url,
    }));
    const ex = await client.query(
      `SELECT politician_id::text AS pid, id_type, id_value FROM essentials.legislative_politician_id_map
        WHERE id_type IN ('mn-lrl','mn-senate-mem','openstates')`);
    existing = new Set(ex.rows.map((r) => `${r.pid}|${r.id_type}|${r.id_value}`));
    await client.query('ROLLBACK');
  } finally {
    client.release();
    await pool.end();
  }

  const { rows, problems } = matchMinnesota({ holders, lrl, senate, openStates, sources });
  const fresh = rows.filter((r) => !existing.has(`${r.politicianId}|${r.idType}|${r.idValue}`));
  const count = (t: MemberIdRow['idType']) => rows.filter((r) => r.idType === t).length;
  console.log(`sitting MN legislators: ${holders.length}  (LRL ${lrl.length}, Senate API ${senate.length}, Open States ${openStates.length})`);
  console.log(`matched: mn-lrl ${count('mn-lrl')}, mn-senate-mem ${count('mn-senate-mem')}, openstates ${count('openstates')}; new ${fresh.length}`);
  for (const p of problems) console.log(`PROBLEM: ${p}`);

  const tsv = flag(process.argv, '--tsv');
  if (tsv) {
    const byPid = new Map(holders.map((h) => [h.politicianId, h]));
    writeFileSync(tsv, ['politician_id\tchamber\tdistrict\tour_name\tid_type\tid_value\tsource_name',
      ...rows.map((r) => {
        const h = byPid.get(r.politicianId)!;
        return [r.politicianId, h.chamber, h.district, h.fullName, r.idType, r.idValue, r.sourceName].join('\t');
      })].join('\n') + '\n');
  }
  const out = flag(process.argv, '--sql');
  if (out && !problems.length) {
    const values = fresh
      .sort((a, b) => a.idType.localeCompare(b.idType) || a.idValue.localeCompare(b.idValue, 'en', { numeric: true }))
      // The comment goes BEFORE the tuple: after it, the joining comma would be commented out.
      .map((r) => `  -- ${r.sourceName.replace(/[\r\n]/g, ' ')}\n  (${sqlText(r.politicianId)}::uuid, ${sqlText(r.idType)}, ${sqlText(r.idValue)}, ${sqlText(r.matchMethod)}, ${sqlText(r.source)})`);
    writeFileSync(out, `INSERT INTO essentials.legislative_politician_id_map (politician_id, id_type, id_value, match_method, source, verified_at)\nSELECT v.pid, v.t, v.val, v.m, v.src, now() FROM (VALUES\n${values.join(',\n')}\n) AS v(pid, t, val, m, src);\n`);
    console.log(`wrote ${fresh.length} rows to ${out}`);
  }
  return problems.length ? 1 : 0;
}

main().then((c) => process.exit(c), (e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
