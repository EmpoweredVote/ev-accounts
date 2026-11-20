/**
 * export-member-ids.ts — write the member ids we hold for a roster's people to a TSV, for file-only tools.
 *
 *   npx tsx scripts/member-ids/export-member-ids.ts --roster <roster.tsv> --out <member-ids.tsv>
 *
 * Stage 5's Python tools never open the database. link_check.py --from-db runs this, then reads the file.
 * Reads essentials.legislative_politician_id_map inside a READ ONLY transaction for every politician_id in the
 * roster's `politician_id` column. Output columns: politician_id, id_type, id_value, match_method.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag, loadBackendEnv } from '../lib/cliEnv.js';

loadBackendEnv(resolve(dirname(fileURLToPath(import.meta.url)), '..', '..'));

async function main(): Promise<number> {
  const roster = flag(process.argv, '--roster');
  const out = flag(process.argv, '--out');
  if (!roster || !out) throw new Error('usage: export-member-ids.ts --roster <roster.tsv> --out <member-ids.tsv>');
  const [head, ...lines] = readFileSync(roster, 'utf8').split(/\r?\n/).filter(Boolean);
  const col = head.split('\t').indexOf('politician_id');
  if (col < 0) throw new Error(`${roster} has no politician_id column`);
  const ids = [...new Set(lines.map((l) => l.split('\t')[col]?.trim()).filter((s) => /^[0-9a-f-]{36}$/i.test(s ?? '')))];
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const client = await pool.connect();
  try {
    await client.query('BEGIN READ ONLY');
    const { rows } = await client.query(
      `SELECT politician_id::text AS pid, id_type, id_value, match_method
         FROM essentials.legislative_politician_id_map WHERE politician_id::text = ANY($1::text[])
        ORDER BY 1, 2, 3`, [ids]);
    await client.query('ROLLBACK');
    writeFileSync(out, ['politician_id\tid_type\tid_value\tmatch_method',
      ...rows.map((r) => [r.pid, r.id_type, r.id_value, r.match_method].join('\t'))].join('\n') + '\n');
    console.log(`export-member-ids: ${rows.length} id(s) for ${ids.length} roster people -> ${out}`);
    return 0;
  } finally {
    client.release();
    await pool.end();
  }
}

main().then((c) => process.exit(c), (e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
