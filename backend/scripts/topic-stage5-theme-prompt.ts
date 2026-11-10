/**
 * topic-stage5-theme-prompt.ts — write the filled Stage 5 theme-pass prompt (read-only on the database).
 *
 *   npm run topic:stage5-theme-prompt --prefix backend -- --topic <key> --notes <abs notes.jsonl> --out <abs prompt.md>
 *        [--season open|draft|<uuid>] [--date YYYY-MM-DD]
 *
 * Fills `.claude/skills/season-topic-prep/templates/stage5-theme-prompt.md`: the topic key, the date, the notes file
 * (made by `topic:stage5-report … --notes-out`) and the ladder — the question and its five rungs as the season
 * SERVES them (seasonService.servedRevisionLateral, the resolver build-stance-topic-bundle uses; a draft season
 * counts its approved, not-yet-published pin). Never the frozen `compass_stances` text (`check:ladder-text`).
 *
 * 🔴 Exit 1, writing nothing, if any `{{…}}` slot would stay unfilled (lib/stage5Template.ts). The 2026-11-05
 * Mississippi theme pass ran on a hand-filled copy with `{{LADDER_TEXT}}` left in, and grouped notes without the
 * ladder. Give the subagent the file this writes, and the notes file, and nothing else.
 *
 * Opens its own pg Pool from DATABASE_URL, loaded by lib/cliEnv.ts (backend/.env, or the main checkout's .env in a
 * worktree). Exit 2 on an unknown topic key.
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { CliFlagError, flag as readFlag, loadBackendEnv } from './lib/cliEnv.js';
import { resolveSeasonTarget, seasonSpecFromArgv, SeasonTargetError } from './lib/seasonTarget.js';
import { fillTemplate, formatLadderText, TemplateFillError } from './lib/stage5Template.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
loadBackendEnv(backendDir);
const flag = (name: string) => readFlag(process.argv, name);
const TEMPLATE = join(backendDir, '..', '.claude', 'skills', 'season-topic-prep', 'templates', 'stage5-theme-prompt.md');

const absFlag = (name: string): string => {
  const p = flag(name);
  if (!p) throw new CliFlagError(`${name} is required (see the file header)`);
  if (!isAbsolute(p)) throw new CliFlagError(`${name} must be an absolute path (npm runs this from backend/): ${p}`);
  return p;
};

async function main(): Promise<number> {
  const topic = flag('--topic');
  if (!topic) throw new CliFlagError('usage: topic-stage5-theme-prompt --topic <key> --notes <abs> --out <abs> [--season …] [--date …]');
  const notes = absFlag('--notes');
  const out = absFlag('--out');
  if (!existsSync(notes)) throw new CliFlagError(`--notes file not found: ${notes} (make it with topic:stage5-report --notes-out)`);
  const date = flag('--date') ?? new Date().toISOString().slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new CliFlagError(`--date must be YYYY-MM-DD: ${date}`);
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');

  // Imported late: seasonService loads src/config (through db.js), which checks the server's whole environment at
  // import time — before loadBackendEnv above has run, if this were a static import. This script uses only
  // servedRevisionLateral (a SQL string) and its own pool, so the one server-only secret a research .env often
  // lacks gets a placeholder here, as federal-bioguide-backfill.ts does on its command line.
  process.env.ADMIN_INGEST_TOKEN ??= 'unused-by-topic-stage5-theme-prompt';
  const { servedRevisionLateral } = await import('../src/lib/seasonService.js');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const q = (sql: string, params?: unknown[]) => pool.query(sql, params as any[]);
  try {
    const t = await q('SELECT id FROM inform.compass_topics WHERE topic_key = $1', [topic]);
    if (!t.rows.length) { console.error(`unknown topic: ${topic}`); return 2; }
    const season = await resolveSeasonTarget(seasonSpecFromArgv(process.argv), q);
    const servedOpts = season.status === 'draft' ? { includeApprovedWhen: 'true' } : {};
    const { rows } = await q(
      `SELECT sq.topic_revision_id::text AS pin_id, eff.id::text AS served_id, eff.question_text, sr.value, sr.text
         FROM inform.season_questions sq
         JOIN ${servedRevisionLateral('sq.topic_revision_id', 'eff', servedOpts)} ON true
         JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id
        WHERE sq.topic_id = $1 AND sq.season_id = $2
        ORDER BY sr.value`,
      [t.rows[0].id, season.id],
    );
    if (!rows.length) { console.error(`topic ${topic} serves no rungs in season ${season.number}`); return 1; }
    const ladder = formatLadderText(rows[0].question_text, rows.map((r: any) => ({ value: r.value, text: r.text })));
    const text = fillTemplate(readFileSync(TEMPLATE, 'utf8'), {
      TOPIC_KEY: topic, DATE: date, NOTES_FILE: notes, LADDER_TEXT: ladder,
    });
    writeFileSync(out, text);
    const noteCount = readFileSync(notes, 'utf8').split('\n').filter((l) => l.trim()).length;
    console.log(`topic ${topic} — season ${season.number} (${season.status}); served revision ${rows[0].served_id} (pin ${rows[0].pin_id})`);
    console.log(ladder);
    console.log(`\nwrote ${out}; ${noteCount} note(s) in ${notes}`);
    return 0;
  } finally {
    await pool.end();
  }
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof SeasonTargetError || e instanceof CliFlagError || e instanceof TemplateFillError ? e.message : e);
    process.exitCode = 1;
  });
