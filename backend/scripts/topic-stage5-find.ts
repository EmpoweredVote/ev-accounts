/**
 * topic-stage5-find.ts — Stage 5 step 3: the search pass (no writes to the database).
 *
 *   npm run topic:stage5-find --prefix backend -- next --topic <key> --season draft --unit federal|state:xx|local:xx
 *        --size N --roster <abs roster.tsv> --out <abs batch.tsv> [--store <abs store root>]
 *   npm run topic:stage5-find --prefix backend -- import --topic <key> --season draft --dir <abs stage5/raw/find>
 *        --roster <abs roster.tsv> [--by <collector name>] [--store <abs store root>]
 *
 * `next` writes the next batch of people owed a search (roster.tsv columns) for collectors briefed with
 * templates/BRIEF-stage5-find.md. `import` reads every `<politician_id>.json` in `--dir`, validates it (the id inside
 * must match the file name and be on the roster), and
 * merges it into the store's findings; a file's modification time is its search time, so importing the same
 * file twice adds nothing. Both refuse any season but a draft one: Stage 5 never researches the open season.
 * The season is read (read-only) only to learn its number.
 */
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { CliFlagError, flag as readFlag, loadBackendEnv } from './lib/cliEnv.js';
import { resolveSeasonTarget, seasonSpecFromArgv, SeasonTargetError } from './lib/seasonTarget.js';
import { upsertFindings } from './lib/sourceStore.js';
import { formatRosterTsv, parseRosterTsv } from './lib/stage5Roster.js';
import { importFindFile, nextBatch, parseUnit } from './lib/stage5Find.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
loadBackendEnv(backendDir);
const argv = process.argv;
const flag = (name: string) => readFlag(argv, name);
const abs = (name: string, p: string | undefined) => {
  if (!p) throw new Error(`${name} is required`);
  if (!isAbsolute(p)) throw new Error(`${name} must be an absolute path (npm runs this from backend/): ${p}`);
  return p;
};

async function draftSeasonNumber(): Promise<number> {
  const spec = seasonSpecFromArgv(argv);
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  try {
    const s = await resolveSeasonTarget(spec, (sql, params) => pool.query(sql, params as any[]));
    if (s.status !== 'draft') throw new SeasonTargetError(`Stage 5 researches the draft season only; ${spec} is season ${s.number} (${s.status})`);
    return s.number;
  } finally {
    await pool.end();
  }
}

async function main(): Promise<number> {
  const cmd = argv[2];
  const topic = flag('--topic');
  if (!topic || (cmd !== 'next' && cmd !== 'import')) {
    throw new Error('usage: topic-stage5-find next|import --topic <key> --season draft … (see the file header)');
  }
  const store = flag('--store') ? abs('--store', flag('--store')) : join(backendDir, 'data', 'source-store');
  const season = await draftSeasonNumber();

  if (cmd === 'next') {
    const unit = parseUnit(flag('--unit') ?? '');
    const size = Number(flag('--size') ?? '20');
    if (!Number.isInteger(size) || size < 1) throw new Error('--size must be a positive whole number');
    const roster = parseRosterTsv(readFileSync(abs('--roster', flag('--roster')), 'utf8'));
    const out = abs('--out', flag('--out'));
    if (existsSync(out)) throw new Error(`${out} already exists; refusing to overwrite it`);
    const batch = nextBatch(roster, store, topic, season, unit, size);
    const owed = nextBatch(roster, store, topic, season, unit, Number.MAX_SAFE_INTEGER).length;
    writeFileSync(out, formatRosterTsv(batch), { flag: 'wx' });
    console.log(`season ${season}, ${flag('--unit')}: ${batch.length} in this batch, ${owed} still owed a search (wrote ${out})`);
    return 0;
  }

  const dir = abs('--dir', flag('--dir'));
  const onRoster = new Set(parseRosterTsv(readFileSync(abs('--roster', flag('--roster')), 'utf8')).map((r) => r.politician_id));
  const by = flag('--by') ?? 'source-collector';
  let people = 0;
  let found = 0;
  const problems: string[] = [];
  for (const name of readdirSync(dir).filter((n) => n.endsWith('.json')).sort()) {
    const file = join(dir, name);
    try {
      const pf = importFindFile(JSON.parse(readFileSync(file, 'utf8')), topic, season, { by, at: statSync(file).mtime.toISOString() },
        { fileId: name.replace(/\.json$/, ''), onRoster });
      upsertFindings(store, pf);
      people++;
      found += pf.findings.length;
    } catch (e) {
      problems.push(`${name}: ${(e as Error).message}`);
    }
  }
  for (const p of problems) console.error(p);
  console.log(`season ${season}: imported ${people} search(es) with ${found} finding(s); ${problems.length} file(s) refused`);
  return problems.length ? 1 : 0;
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof SeasonTargetError || e instanceof CliFlagError ? e.message : e);
    process.exitCode = 1;
  });
