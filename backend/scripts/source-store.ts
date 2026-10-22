/**
 * source-store.ts — CLI for the season-topic-prep source store.
 *
 * Usage:
 *   npx tsx scripts/source-store.ts validate [--root <dir>]
 *   npx tsx scripts/source-store.ts merge --from <abs staging dir> [--root <dir>]
 *   npx tsx scripts/source-store.ts topic-list-hash --season open|draft|<uuid>
 *
 * `validate` checks every file in the store against its schema. Exits 1 and prints each problem if any
 * file is broken, so a bad hand edit is caught before it is committed.
 * `merge` folds a staging store (written with `--root` by a run that could not commit) into the repo
 * store by the usual merge rules. It validates the staging store first and refuses a broken one.
 * `topic-list-hash` prints the `topic_list_hash` for a season's served topic list (read-only; it opens
 * its own pg Pool from DATABASE_URL, loaded by lib/cliEnv.ts, and never prints it).
 */
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag, loadBackendEnv } from './lib/cliEnv.js';
import { resolveSeasonTarget, seasonSpecFromArgv } from './lib/seasonTarget.js';
import { mergeStore, topicListHash, validateStore } from './lib/sourceStore.js';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const cmd = argv[0];
const USAGE = 'Usage: source-store.ts validate [--root <dir>] | merge --from <abs dir> [--root <dir>] | topic-list-hash --season open|draft|<uuid>';
let rootArg: string | undefined;
let fromArg: string | undefined;
try {
  rootArg = flag(argv, '--root');
  fromArg = flag(argv, '--from');
} catch (e) {
  console.error(`ERROR: ${(e as Error).message}`);
  process.exit(2);
}
const root = rootArg ? resolve(rootArg) : join(here, '..', 'data', 'source-store');

function report(problems: { file: string; error: string }[], where: string): boolean {
  for (const p of problems) console.error(`${p.file}: ${p.error}`);
  if (problems.length) console.error(`${problems.length} problem(s) in ${where}`);
  return problems.length === 0;
}

async function main(): Promise<number> {
  if (cmd === 'validate') {
    if (!report(validateStore(root), root)) return 1;
    console.log(`source store OK (${root})`);
    return 0;
  }
  if (cmd === 'merge') {
    if (!fromArg || !isAbsolute(fromArg)) {
      console.error('merge needs --from <absolute staging dir> (npm runs this from backend/)');
      return 2;
    }
    if (!report(validateStore(fromArg), fromArg)) return 1;
    const n = mergeStore(fromArg, root);
    console.log(`merged ${n.instruments} instrument(s), ${n.people} person file(s), ${n.jurisdictions} jurisdiction(s), ${n.deadEnds} new dead end(s) into ${root}`);
    return report(validateStore(root), root) ? 0 : 1;
  }
  if (cmd === 'topic-list-hash') {
    loadBackendEnv(join(here, '..'));
    if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');
    const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
    const q = (sql: string, params?: unknown[]) => pool.query(sql, params as any[]);
    try {
      const season = await resolveSeasonTarget(seasonSpecFromArgv(process.argv), q);
      const { rows } = await q(
        `SELECT t.topic_key FROM inform.season_questions sq JOIN inform.compass_topics t ON t.id = sq.topic_id
          WHERE sq.season_id = $1`,
        [season.id],
      );
      console.log(`${topicListHash(rows.map((r: { topic_key: string }) => r.topic_key))}  season ${season.number} (${season.status}), ${rows.length} topics`);
      return 0;
    } finally {
      await pool.end();
    }
  }
  console.error(USAGE);
  return 2;
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(`ERROR: ${(e as Error).message}`);
    process.exitCode = 1;
  });
