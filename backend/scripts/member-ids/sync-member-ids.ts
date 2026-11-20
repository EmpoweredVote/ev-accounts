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
 * Runs weekly as the `member-ids` job (first step of the Render cron ev-jobs-legiscan); the logic is in
 * src/lib/memberIdSync.ts.
 *
 * Exit 0: done (problems and conflicts are listed, never written).
 * Exit 2: no verdict (a state's Open States file is missing or empty).
 */
import { writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag, hasFlag, loadBackendEnv } from '../lib/cliEnv.js';
import { syncMemberIds } from '../../src/lib/memberIdSync.js';

loadBackendEnv(resolve(dirname(fileURLToPath(import.meta.url)), '..', '..'));

async function main(): Promise<number> {
  const apply = hasFlag(process.argv, '--apply');
  const states = flag(process.argv, '--states')?.split(',').map((s) => s.trim()).filter(Boolean);
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  try {
    const r = await syncMemberIds(pool, { apply, states });
    const tsv = flag(process.argv, '--tsv');
    if (tsv) writeFileSync(tsv, ['state\tpolitician_id\tid_type\tid_value\tmatch_method\tsource_name',
      ...r.fresh.map((x) => [x.state, x.politicianId, x.idType, x.idValue, x.matchMethod, x.sourceName].join('\t'))].join('\n') + '\n');
    return r.blind.length ? 2 : 0;
  } finally {
    await pool.end();
  }
}

main().then((c) => process.exit(c), (e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
