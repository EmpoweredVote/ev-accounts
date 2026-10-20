/**
 * topic-ladder-lint.ts — lint the served rung text of one compass topic (read-only).
 *
 *   npm run topic:ladder-lint --prefix backend -- --topic <key> [--season open|draft|<uuid>]
 *
 * Reads the revision the season serves (`inform.season_questions.topic_revision_id`) and its rungs
 * (`inform.compass_stance_revisions`), then prints the raw T6 hits. Exit 2 on an unknown topic key.
 * Never writes. Opens its own pg Pool from DATABASE_URL (backend/.env, or the main checkout's .env in
 * a worktree); it does not import db.js, which demands every server variable at import time.
 */
import { existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import dotenv from 'dotenv';
import pg from 'pg';
import { resolveSeasonTarget, seasonSpecFromArgv, SeasonTargetError } from './lib/seasonTarget.js';
import { lintRungs } from './lib/ladderLint.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
dotenv.config({ path: join(backendDir, '.env'), quiet: true });
if (!process.env.DATABASE_URL) {
  try {
    const common = execFileSync('git', ['rev-parse', '--path-format=absolute', '--git-common-dir'],
      { cwd: backendDir, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    const mainEnv = join(dirname(common), 'backend', '.env');
    if (existsSync(mainEnv)) dotenv.config({ path: mainEnv, quiet: true });
  } catch { /* no git: fall through to the missing-variable message */ }
}

function flag(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  if (i === -1) return undefined;
  const v = process.argv[i + 1];
  if (!v || v.startsWith('--')) throw new Error(`${name} needs a value`);
  return v;
}

async function main(): Promise<number> {
  const topic = flag('--topic');
  if (!topic) throw new Error('usage: topic-ladder-lint --topic <key> [--season open|draft|<uuid>]');
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const q = (sql: string, params?: unknown[]) => pool.query(sql, params as any[]);
  try {
    const t = await q('SELECT id FROM inform.compass_topics WHERE topic_key = $1', [topic]);
    if (!t.rows.length) { console.error(`unknown topic: ${topic}`); return 2; }
    const season = await resolveSeasonTarget(seasonSpecFromArgv(process.argv), q);
    const { rows } = await q(
      `SELECT sr.value, sr.text
         FROM inform.season_questions sq
         JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = sq.topic_revision_id
        WHERE sq.topic_id = $1 AND sq.season_id = $2
        ORDER BY sr.value`,
      [t.rows[0].id, season.id],
    );
    if (!rows.length) { console.error(`topic ${topic} serves no rungs in season ${season.number}`); return 1; }
    const rungs = rows.filter((r: any) => r.value > 0).map((r: any) => r.text as string);
    const hits = lintRungs(rungs);
    console.log(`topic ${topic} — season ${season.number} (${season.status}); ${rungs.length} rungs, ${hits.length} raw hits`);
    for (const h of hits) console.log(`  rung ${h.rung}  ${h.check}: "${h.match}"`);
    return 0;
  } finally {
    await pool.end();
  }
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof SeasonTargetError ? e.message : e);
    process.exitCode = 1;
  });
