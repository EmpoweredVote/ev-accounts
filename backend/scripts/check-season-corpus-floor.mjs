#!/usr/bin/env node
/**
 * CI tripwire: a season's corpus may grow, but it must never SHRINK.
 *
 * ⚠️ SEASON 1 IS OPEN AGAIN — corrected 2026-08-27, prose only, floors untouched.
 * This file was written while season 1 was closed and says so in several places
 * below. `CA_0020_reopen_season_one.sql` reopened it, because closing season 1
 * before season 2 could be opened had left every compass write path refusing
 * with NO_OPEN_SEASON since 2026-08-26 — the scaffolding interlock in `CC_0002`
 * means season 2 cannot be opened until those indexes are dropped, so the
 * intended brief handover became an open-ended outage.
 *
 * What that means HERE, and it is narrow: **the check still works and its
 * numbers are still right.** It compares row counts and never reads
 * `seasons.status`, so an open season 1 does not affect what it measures. What
 * changes is the reading of a failure — and one specific misreading is now
 * possible that was not before:
 *
 *   🔴 SEASON 1 NOW TAKES WRITES, SO ITS COUNTS WILL RISE LEGITIMATELY.
 *   A floor is a floor, so growth still passes. But do NOT read the "season 1 is
 *   closed, its answers should never be deleted" framing below as "any change to
 *   season 1 is the data-loss event". New stance research lands in season 1
 *   today. That is normal, and it means season 1's floor is now the kind that
 *   moves upward over time — exactly as WHEN A FLOOR SHOULD MOVE describes, an
 *   instruction written for season 2 that now applies to season 1 first.
 *
 * The floors are deliberately NOT re-measured here. Raising a floor to today's
 * counts would silently absorb any loss that happened before today, which is the
 * one thing this gate exists to refuse.
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
 * A DELETED ROW LEAVES NO TRACE. Once rows are gone there is no way to learn from the table
 * when or how they went, so the corpus size is the only cheap, continuous evidence that
 * season 1 is intact. This check reads it and refuses a decrease.
 *
 * ⚠ CORRECTED 2026-09-01. This paragraph used to say both tables "carry NO TIMESTAMPS you can
 *   use to ask which batch wrote this row". That is false — `politician_answers` and
 *   `politician_context` BOTH carry `created_at` and `updated_at`. The true limitation is
 *   narrower and only applies in one direction: SURVIVING rows can be dated, DELETED ones
 *   cannot. That distinction is not academic — it is how the −4 window below was diagnosed.
 *   Dating the season-1 context rows that have no answer isolated the four retired pairs to a
 *   single batch in minutes, where the overstated claim would have said not to bother looking.
 *
 * WHAT IT ASSERTS, and why each is a FLOOR rather than an equality:
 *
 *   answers   >= 33164   No season's answers should ever be deleted. A floor still permits
 *   context   >= 33818   both a documented correction that ADDS a row and — now that season 1
 *   questions >= 44      is open again — ordinary new research, while catching every delete.
 *
 * Measured against production on 2026-08-27: season 1, 44 questions, 33,164 answers,
 * 33,818 context rows. These are the same numbers the compass-seasons plan records, taken
 * independently from the live database, not copied from the document.
 * (Season 1 read `closed` when these were measured; it was reopened later the same day by
 * `CA_0020`, which moved no rows — verified after applying: 33,164 answers, 33,818 context.)
 *
 * WHAT THIS CANNOT DO. It counts rows. It cannot tell a deleted answer from a replaced one:
 * a run that destroys 100 answers and writes 100 different ones passes. It proves the corpus
 * did not shrink, never that its CONTENTS are unchanged. Read a green run as "no season-1 row
 * was lost", not as "season 1 is untouched".
 *
 * WHEN A FLOOR SHOULD MOVE. Deliberately, and with the reason committed beside the number:
 * use --floor-answers / --floor-context. Raising is the ordinary case — a season opens and
 * takes answers. Lowering a floor to make this gate pass is the exact event the gate exists
 * to report. If rows are genuinely gone, find out why first.
 *
 * 🔴 BUT A DOCUMENTED-BLANK RETIREMENT LOWERS THE ANSWER FLOOR LEGITIMATELY, AND THIS FILE
 * USED TO SAY FLOORS MOVE "ONLY UPWARD", WHICH LEFT NO BRANCH FOR IT. Retiring a seating to
 * a documented blank DELETES the answer on purpose and REWRITES the context. That is the
 * correct disposition under CLAUDE.md's answer-delete rule, and it makes the answer count
 * fall. It is not loss, and the floor must follow it down.
 *
 * 🔴🔴 THE SIGNATURE TELLS THE TWO APART, AND IT IS THE ONE DIAGNOSTIC THIS GATE CAN OFFER:
 *
 *     answers FALL, context HOLDS  →  documented-blank retirement. Deliberate.
 *                                     Verify the pairs, then lower the answer floor.
 *     answers AND context fall together  →  rows are being destroyed. STOP.
 *     answers fall, context RISES        →  also destruction, with a rewrite on top. STOP.
 *
 * To verify rather than assume: extract the (politician_id, topic_id) pairs from the
 * migrations in the window and assert each has ZERO answers and ONE context row. If the
 * count of such pairs equals the shortfall exactly, the reduction is fully accounted for.
 * Confirm too that no migration in the window INSERTs answers — otherwise a net figure can
 * hide extra deletions behind additions.
 *
 * ▶ LOWERING THE FLOOR IS THE BLANKING PR'S OWN JOB, NOT THE NEXT MORNING'S. This check runs
 * on a SCHEDULE, not on pull requests, so a blanking migration merges green and the gate
 * fails hours later against master — where the reduction has to be re-derived by someone who
 * did not write it. If your migration retires N answers to documented blanks, lower the
 * answers floor by N in the SAME pull request and cite the migration slot. Five such
 * migrations landed inside one 24-hour window on 2026-08-29/30 (CA_0032, CA_0033, CA_0035,
 * CA_0038, CA_0039, 32 answers between them) and none moved the floor, which is what made
 * that morning's failure look like data loss. Four more landed on 2026-08-30/31 while this
 * very fix was open (CA_0044, CA_0045, CA_0052, CA_0056, 94 answers between them), so the
 * correction had to be re-derived a second time before it could merge. The rule above is
 * what stops a third round.
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
 * Committed floors, per season number.
 *
 * Add an entry when a season opens. Lower one ONLY for an accounted-for reduction, with the
 * migration slots named here — see WHEN A FLOOR SHOULD MOVE above for what "accounted for"
 * has to mean before you touch a number.
 */
const FLOORS = {
  1: {
    // 33,164 when measured 2026-08-27, lowered three times for documented-blank retirements —
    // each of which deleted a seating on purpose and rewrote its context as a blank:
    //
    //   −32 on 2026-08-30: CA_0032 (1), CA_0033 (9), CA_0035 (13), CA_0038 (7), CA_0039 (2)
    //   −94 on 2026-08-31: CA_0044 (31), CA_0045 (3), CA_0052 (2), CA_0056 (58)
    //   − 4 on 2026-09-01: CA_0097 (4)
    //
    // NOT taken from "what prod reads today" — reading it off prod is what would absorb a real
    // loss silently. Each retirement count comes from the migration's own post-verify gate, and
    // no migration in either window INSERTs answers, so the net cannot hide extra deletions
    // behind additions. The context floor did not move across either window, which is the
    // signature of deliberate blanking rather than destruction.
    // 33,164 − 32 − 94 − 4 = 33,034, which is the number below, derived rather than observed.
    //
    // 🔴 THE −4 WINDOW WAS FOUND BY THIS GATE GOING RED, NOT BY THE PR THAT CAUSED IT — THE
    //    THIRD TIME (32, then 94, now 4). CA_0097 retires four Police Accountability seatings
    //    to documented blanks and is CORRECT work: it carries an @context-decision line, a
    //    guard that refuses any blanked row whose reasoning still asserts a position, and it
    //    INSERTs no answers, so its net cannot hide extra deletions. It simply did not drop
    //    this floor in the same PR, and it is applied to production while PR #292 is still
    //    open — so the drop had to land here on master or the nightly gate stays red.
    //
    //    The four pairs were verified individually before this number moved, which is what
    //    the signature rule above requires: David Chiu, Shawn Robinson, Hydee Feldstein Soto
    //    and Heather Ferbert, all on Police Accountability, all rewritten 2026-09-01 with
    //    reasoning that documents what was read and why no chair is evidenced. Context held
    //    at 33,818 across the window.
    answers: flagInt('floor-answers', 33034),
    // Untouched. A documented blank REWRITES its context, so this count did not move — and
    // that it held at exactly 33,818 is what proved the answer loss was deliberate.
    context: flagInt('floor-context', 33818),
    questions: flagInt('floor-questions', 44),
    measured: '2026-08-27',
    adjusted: '2026-08-31',
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
    // "a season", not "a closed season" — season 1 is open again, and this
    // message is the first thing read during an incident. Naming the wrong
    // precondition sends the reader looking for a write that should have been
    // impossible, when the answer is simply that rows are gone.
    console.error('\nseason corpus floor FAILED — a season LOST rows:\n');
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
