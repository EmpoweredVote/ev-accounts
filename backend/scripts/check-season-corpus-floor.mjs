#!/usr/bin/env node
/**
 * CI tripwire: a CLOSED season's corpus may grow, but it must never SHRINK.
 *
 * WHY THIS EXISTS. On 2026-08-2x a per-topic "Save" in the admin compass editor posted a
 * single-topic payload to a REPLACE-ALL RPC. The RPC did exactly what it was written to do:
 * it deleted every answer not present in the payload. 40 of 41 answers for that politician
 * were destroyed. `CC_0001` fixed the caller/RPC mismatch, and `CC_wip_closed_season_immutable.sql`
 * (written, proven, NOT YET APPLIED — it needs an open season) makes the destructive shape
 * refuse at the database level, including from an ad-hoc `psql` DELETE.
 *
 * This gate is the third layer, and it covers what neither of those can:
 *
 *   A TRIGGER CAN BE DROPPED. A CI CHECK NOTICES.
 *
 * `inform.politician_answers` and `inform.politician_context` carry NO TIMESTAMPS you can
 * use to ask "which batch wrote this row" — so once rows are gone, there is no way to learn
 * from the table when or how they went. The corpus size is therefore the only cheap,
 * continuous evidence that season 1 is intact. This check reads it and refuses a decrease.
 *
 * WHAT IT ASSERTS, and why each is a FLOOR rather than an equality:
 *
 *   answers   >= 33164   Season 1 is closed. Its answers should never be deleted. A floor
 *   context   >= 33818   still permits a documented correction that ADDS a row, which the
 *   questions >= 44      closed-season editorial policy allows, while catching every delete.
 *
 * Measured against production on 2026-08-27: season 1, closed, 44 questions, 33,164 answers,
 * 33,818 context rows. These are the same numbers the compass-seasons plan records, taken
 * independently from the live database, not copied from the document.
 *
 * WHAT THIS CANNOT DO. It counts rows. It cannot tell a deleted answer from a replaced one:
 * a run that destroys 100 answers and writes 100 different ones passes. It proves the corpus
 * did not shrink, never that its CONTENTS are unchanged. Read a green run as "no season-1 row
 * was lost", not as "season 1 is untouched".
 *
 * WHEN A FLOOR SHOULD MOVE. Only upward, and only deliberately: after a season opens and
 * takes answers, raise its floor with --floor-answers / --floor-context and commit the new
 * number with the reason. Lowering a floor to make this gate pass is the exact event the
 * gate exists to report. If rows are genuinely gone, find out why first.
 *
 * NO DATABASE_URL IS A FAILURE, NOT A SKIP. The database is the whole check — there is no
 * static half that still means something. A gate that quietly passes when it never ran reads
 * "healthy" while measuring nothing, which is how a source that never runs looks fine
 * forever. Pass --allow-skip for a deliberate local run without credentials.
 *
 * RUN: npm run check:season-floor --prefix backend
 *      npm run check:season-floor:verbose --prefix backend
 * CI:  master-push and daily cron (it needs DATABASE_URL — use the session pooler string,
 *      which is IPv4; the direct host is IPv6-only).
 */

import 'dotenv/config';
import pg from 'pg';

const VERBOSE = process.argv.includes('--verbose');
const ALLOW_SKIP = process.argv.includes('--allow-skip');

/** Read a --flag=N override, or fall back to the committed baseline. */
function flagInt(name, fallback) {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  if (!hit) return fallback;
  const n = Number.parseInt(hit.split('=')[1], 10);
  if (!Number.isInteger(n) || n < 0) {
    console.error(`check-season-corpus-floor: --${name} needs a non-negative integer.`);
    process.exit(1);
  }
  return n;
}

/**
 * Committed floors, per season number. Measured against production 2026-08-27.
 * Add an entry when a season opens; never lower one.
 */
const FLOORS = {
  1: {
    answers: flagInt('floor-answers', 33164),
    context: flagInt('floor-context', 33818),
    questions: flagInt('floor-questions', 44),
    measured: '2026-08-27',
  },
};

const CORPUS_QUERY = `
  SELECT s.number,
         s.status::text AS status,
         s.name,
         (SELECT count(*) FROM inform.politician_answers a WHERE a.season_id = s.id) AS answers,
         (SELECT count(*) FROM inform.politician_context c WHERE c.season_id = s.id) AS context_rows,
         (SELECT count(*) FROM inform.season_questions q WHERE q.season_id = s.id) AS questions
    FROM inform.seasons s
   ORDER BY s.number`;

async function readCorpus() {
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  try {
    const { rows } = await pool.query(CORPUS_QUERY);
    return rows.map((r) => ({
      number: Number(r.number),
      status: r.status,
      name: r.name,
      answers: Number(r.answers),
      context: Number(r.context_rows),
      questions: Number(r.questions),
    }));
  } finally {
    await pool.end();
  }
}

async function main() {
  if (!process.env.DATABASE_URL) {
    if (ALLOW_SKIP) {
      console.log(
        'season corpus floor SKIPPED — no DATABASE_URL, and --allow-skip was passed. ' +
          'NOTHING WAS MEASURED. This is not a pass.'
      );
      return;
    }
    console.error(
      '\nseason corpus floor CANNOT RUN — DATABASE_URL is not set.\n' +
        '  The database is the entire check; there is no half of it that still means ' +
        'something without a connection. Passing here would report "healthy" while ' +
        'measuring nothing.\n' +
        '  In CI: set DATABASE_URL to the session pooler string (IPv4; the direct host is ' +
        'IPv6-only).\n' +
        '  Locally, on purpose: re-run with --allow-skip.\n'
    );
    process.exit(1);
  }

  const seasons = await readCorpus();

  if (seasons.length === 0) {
    console.error(
      '\nseason corpus floor FAILED — inform.seasons is EMPTY.\n' +
        '  Season 1 holds the entire published compass corpus. No rows here means the ' +
        'season model itself is gone, not that no season exists yet.\n'
    );
    process.exit(1);
  }

  if (VERBOSE) {
    console.log('\nSeason corpus, as measured now:\n');
    for (const s of seasons) {
      console.log(
        `  season ${s.number} (${s.status}, "${s.name}") — ` +
          `${s.answers.toLocaleString()} answers, ` +
          `${s.context.toLocaleString()} context, ${s.questions} questions`
      );
    }
    console.log('');
  }

  const breaches = [];
  const unfloored = [];

  for (const s of seasons) {
    const floor = FLOORS[s.number];
    if (!floor) {
      unfloored.push(s);
      continue;
    }
    for (const [label, actual, min] of [
      ['answers', s.answers, floor.answers],
      ['context rows', s.context, floor.context],
      ['questions', s.questions, floor.questions],
    ]) {
      if (actual < min) {
        breaches.push({ season: s.number, label, actual, min, lost: min - actual });
      }
    }
  }

  // A season with no committed floor is a gap in the gate, not a pass. Report it — but do
  // not fail: a brand-new draft season legitimately has nothing to protect yet.
  for (const s of unfloored) {
    console.warn(
      `season corpus floor: season ${s.number} ("${s.name}", ${s.status}) has NO committed ` +
        `floor — ${s.answers.toLocaleString()} answers and ${s.context.toLocaleString()} ` +
        `context rows are currently UNPROTECTED. Add an entry to FLOORS once it takes answers.`
    );
  }

  if (breaches.length > 0) {
    console.error('\nseason corpus floor FAILED — a closed season LOST rows:\n');
    for (const b of breaches) {
      console.error(
        `    · season ${b.season} ${b.label}: ${b.actual.toLocaleString()} now, ` +
          `floor is ${b.min.toLocaleString()} — ${b.lost.toLocaleString()} MISSING`
      );
    }
    console.error(
      '\n  These tables carry no timestamps, so the rows cannot tell you when or how they ' +
        'went. Do NOT lower the floor to make this pass.\n' +
        '  Check, in this order: (1) a REPLACE-ALL RPC reached from a partial payload — the ' +
        'defect CC_0001 fixed; (2) an ad-hoc psql DELETE; (3) a migration that deleted ' +
        'answers without deciding what happened to the matching context rows.\n' +
        '  If the loss is real, restore from a backup before anything else writes.\n'
    );
    process.exit(1);
  }

  const protectedSeasons = seasons.filter((s) => FLOORS[s.number]);
  console.log(
    `season corpus floor OK — ${protectedSeasons.length} season(s) at or above their floor ` +
      `(${protectedSeasons
        .map((s) => `s${s.number}: ${s.answers.toLocaleString()} answers`)
        .join(', ')}).` +
      (unfloored.length > 0 ? ` ${unfloored.length} season(s) UNPROTECTED — see above.` : '')
  );
}

main().catch((err) => {
  console.error(`check-season-corpus-floor failed to run: ${err.message}`);
  process.exit(1);
});
