#!/usr/bin/env node
/**
 * CI gate: every live query against the answer tables must constrain the season.
 *
 * WHY THIS EXISTS. Task 6 of the compass-seasons plan swaps the primary key of
 * `inform.politician_answers` from `(politician_id, topic_id)` to
 * `(politician_id, topic_id, season_id)`. That is the one irreversible step in
 * the plan, and it changes the meaning of every query that joins on the old
 * pair. Two distinct failures follow, and they fail in opposite directions:
 *
 *   READS FAN OUT, SILENTLY, AND LATER. A join on `(politician_id, topic_id)`
 *   returns one row today because that pair is unique today. It returns one row
 *   per season the moment a second season exists. Nothing errors. Counts
 *   inflate, `array_agg` duplicates, and averages drift — months after the
 *   migration that caused it, with no failing test in between.
 *
 *   WRITES BREAK LOUDLY AND IMMEDIATELY. `ON CONFLICT (politician_id,
 *   topic_id)` needs a unique index on exactly those columns. After the swap
 *   there is none, so Postgres raises 42P10: "there is no unique or exclusion
 *   constraint matching the ON CONFLICT specification". Verified on 2026-08-25
 *   with a scratch-table control: the clause works under the 2-column key,
 *   raises 42P10 under the 3-column key, and works again when it names the
 *   season. This is not a prediction.
 *
 * This gate is the reason neither can reach production. It starts RED and turns
 * green as Task 5 makes each consumer season-aware. Land Tasks 4 and 5 on one
 * branch so master never sees it failing.
 *
 * IT CHECKS TWO PLACES, BECAUSE THE CONSUMERS LIVE IN TWO PLACES.
 *
 *   1. backend/src — TypeScript that builds SQL.
 *   2. The DATABASE — `SECURITY DEFINER` RPCs. This half is not optional
 *      thoroughness. On 2026-08-25 the static half alone would have passed
 *      while THREE `ON CONFLICT (politician_id, topic_id)` clauses sat inside
 *      `public.admin_update_politician_answers` and
 *      `inform.admin_publish_topic_rewrite` — the admin compass write path.
 *      No file under backend/src contains them; they are function bodies. A
 *      gate that only reads the repo would have green-lit the key swap and
 *      broken the admin editor at runtime.
 *
 * THE UNIT OF MATCHING IS THE SQL LITERAL, NOT THE FILE. An earlier draft asked
 * "does this file mention a season anywhere". `lib/compassService.ts` holds 19
 * references to the answer tables across many independent queries, so seasoning
 * one of them would have turned the whole file green with 18 still broken. Each
 * backtick literal is now judged on its own.
 *
 * WHAT THIS CANNOT DO. It reads text, not meaning. A literal that mentions
 * `season_id` in a comment passes. A literal that filters on the WRONG season
 * passes. It proves that every consumer NAMES a season, not that it names the
 * right one — read a green run as "no consumer is still keyed on the bare pair".
 *
 * SCOPE IS backend/src ONLY on the static side. The one-off `apply-*-stances.ts`
 * scripts and `NNN-verify.sql` files are historical records of past batches, not
 * live consumers; rewriting them would change nothing and lose their meaning.
 * `types/database.types.ts` is generated, not hand-written — regenerate it.
 *
 * Usage (from backend/):
 *   node scripts/check-answer-season-consumers.mjs
 *   node scripts/check-answer-season-consumers.mjs --verbose   # show each literal
 */
import 'dotenv/config';
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import pg from 'pg';

const VERBOSE = process.argv.includes('--verbose');

// ---------------------------------------------------------------------------
// Predicates
// ---------------------------------------------------------------------------

/**
 * A reference that is actually SQL against the table — either schema-qualified,
 * or introduced by a clause keyword.
 *
 * The keyword form is what keeps `'update_politician_answers'` (an audit action
 * name in routes/admin.ts) and `'admin_update_politician_answers'` (an RPC name
 * in routes/compassAdmin.ts) out of the results. Both contain the table name as
 * a SUBSTRING; neither queries the table. `\b` cannot match inside
 * `admin_update_politician_answers` because `_` is a word character, so the
 * keyword alternative requires real whitespace and the bare-substring case
 * never fires. An earlier draft listed both files as offenders — they are not.
 */
const SQL_TABLE_REF =
  /\binform\.politician_(?:answers|context)\b|\b(?:from|join|into|update|table)\s+(?:inform\.)?politician_(?:answers|context)\b/i;

/** Any mention of a season. Deliberately generous — see "WHAT THIS CANNOT DO". */
const SEASON_REF = /season_id|seasonId|current_season|currentSeason|season_questions|seasons\b/i;

/** Stale upsert target: the pair that stops being unique after the key swap. */
const STALE_ON_CONFLICT =
  /on\s+conflict\s*\(\s*(?:\w+\.)?politician_id\s*,\s*(?:\w+\.)?topic_id\s*\)/i;

// ---------------------------------------------------------------------------
// Static half — backend/src
// ---------------------------------------------------------------------------

function sourceFiles(root) {
  return readdirSync(root, { recursive: true, encoding: 'utf8' })
    .filter((f) => f.endsWith('.ts'))
    .filter((f) => !f.endsWith('.test.ts'))
    // Generated by `supabase gen types`. Regenerate it; do not hand-edit.
    .filter((f) => f.split(sep).join('/') !== 'types/database.types.ts')
    .map((f) => join(root, f));
}

/** Strip SQL and JS comments so prose about a table is not read as a query. */
function stripComments(text) {
  return text
    .replace(/\/\*[\s\S]*?\*\//g, ' ')   // /* block */
    .replace(/--[^\n]*/g, ' ')            // -- sql line
    .replace(/\/\/[^\n]*/g, ' ');         // // js line
}

/**
 * Every backtick literal in the file, with the line it starts on.
 *
 * A template literal nested inside a `${...}` of another one will be split at
 * the inner backtick. That is conservative in the safe direction: a split piece
 * carrying the table but not the season is reported, so the gate over-reports
 * rather than missing a consumer.
 */
function templateLiterals(text) {
  const out = [];
  const re = /`(?:[^`\\]|\\[\s\S])*`/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    out.push({ body: m[0], line: text.slice(0, m.index).split('\n').length });
  }
  return out;
}

function scanRepo(root) {
  const offenders = [];
  for (const path of sourceFiles(root)) {
    const raw = readFileSync(path, 'utf8');
    const rel = relative(root, path).split(sep).join('/');
    const literals = templateLiterals(raw);

    for (const { body, line } of literals) {
      const sql = stripComments(body);
      if (!SQL_TABLE_REF.test(sql)) continue;
      if (STALE_ON_CONFLICT.test(sql)) {
        offenders.push({ rel, line, why: 'ON CONFLICT (politician_id, topic_id) — breaks with 42P10 after the swap' });
        continue;
      }
      if (!SEASON_REF.test(sql)) {
        offenders.push({ rel, line, why: 'queries the answer tables without naming a season' });
      }
    }

    // SQL held somewhere other than a backtick literal — a quoted string, say.
    // Blank the literals out first so this only sees the residue.
    let residue = raw;
    for (const { body } of literals) residue = residue.replace(body, ' ');
    if (SQL_TABLE_REF.test(stripComments(residue))) {
      offenders.push({ rel, line: 0, why: 'table reference outside any template literal — read it by hand' });
    }
  }
  return offenders;
}

// ---------------------------------------------------------------------------
// Database half — SECURITY DEFINER RPCs
// ---------------------------------------------------------------------------

const FUNC_QUERY = `
  SELECT n.nspname || '.' || p.proname AS fn,
         pg_get_functiondef(p.oid) ~* 'season'            AS names_season,
         pg_get_functiondef(p.oid) ~* $1                  AS stale_on_conflict
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE p.prokind = 'f'
     AND n.nspname NOT IN ('pg_catalog','information_schema','extensions','auth',
                           'storage','realtime','vault','graphql','graphql_public',
                           'pgbouncer','cron','net','pgsodium','pgsodium_masks',
                           'supabase_functions','supabase_migrations')
     AND pg_get_functiondef(p.oid) ~* '\\ypolitician_(answers|context)\\y'
   ORDER BY 1`;

async function scanDatabase() {
  if (!process.env.DATABASE_URL) return null;
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  try {
    const { rows } = await pool.query(FUNC_QUERY, [STALE_ON_CONFLICT.source]);
    return rows
      .filter((r) => r.stale_on_conflict || !r.names_season)
      .map((r) => ({
        fn: r.fn,
        why: r.stale_on_conflict
          ? 'ON CONFLICT (politician_id, topic_id) — breaks with 42P10 after the swap'
          : 'touches the answer tables without naming a season',
      }));
  } finally {
    await pool.end();
  }
}

// ---------------------------------------------------------------------------

async function main() {
  const repo = scanRepo('src');
  const db = await scanDatabase();

  if (VERBOSE) {
    console.log(`scanned ${sourceFiles('src').length} file(s) under src/`);
  }

  const byFile = new Map();
  for (const o of repo) {
    if (!byFile.has(o.rel)) byFile.set(o.rel, []);
    byFile.get(o.rel).push(o);
  }

  let failed = false;

  if (repo.length) {
    failed = true;
    console.error(
      `\nanswer-season consumers — ${repo.length} SQL literal(s) in ${byFile.size} file(s) ` +
      `under backend/src do not constrain the season:`);
    for (const [rel, list] of [...byFile].sort()) {
      console.error(`  ${rel}`);
      for (const o of list.sort((a, b) => a.line - b.line)) {
        console.error(`    · ${rel}:${o.line} — ${o.why}`);
      }
    }
  }

  if (db === null) {
    // House pattern: forks get no secrets, so a green skip beats a red herring.
    // Say plainly what went unchecked — a silent skip reads as coverage.
    console.error(
      '\nSKIP: DATABASE_URL not set — the RPC half did NOT run. ' +
      'SECURITY DEFINER functions were not checked, and that is where the ' +
      'ON CONFLICT (politician_id, topic_id) upserts live. A pass here does ' +
      'not clear the database side.');
  } else if (db.length) {
    failed = true;
    console.error(
      `\nanswer-season consumers — ${db.length} database function(s) do not ` +
      `constrain the season. These are NOT in backend/src; they need a migration:`);
    for (const o of db) console.error(`    · ${o.fn}() — ${o.why}`);
  }

  if (failed) {
    console.error(
      '\nA read joined on (politician_id, topic_id) alone FANS OUT once a second ' +
      'season exists — silently, with nothing to catch it. A write with ' +
      'ON CONFLICT on that pair raises 42P10 the moment the key changes. ' +
      'Make every consumer above season-aware before the key swap lands.\n');
    process.exit(1);
  }

  console.log(
    'answer-season consumers OK — every live consumer names a season' +
    (db === null ? ' (repo only; the RPC half was skipped).' : ', RPCs included.'));
}

main().catch((err) => {
  console.error(`check-answer-season-consumers failed to run: ${err.message}`);
  process.exit(1);
});
