#!/usr/bin/env node
/**
 * CI tripwire: a season's corpus may grow, but it must never SHRINK.
 *
 * ⚠️ SEASON 1 IS CLOSED AGAIN AND SEASON 2 IS OPEN — corrected 2026-09-04, prose only.
 * Season 2 opened at 14:31Z and season 1 closed in the same transaction, which ends the
 * reopened-season-1 window the next paragraph describes. Season 1's floors are untouched by
 * that; what changes is that season 1 no longer takes writes, so its counts should now HOLD
 * rather than rise, and season 2 is the season whose numbers move. Season 2 has its own FLOORS
 * entry as of this change — before it, its 2,685 answers were measured by nothing.
 *
 * ⚠️ SEASON 1 IS OPEN AGAIN — corrected 2026-08-27, prose only, floors untouched.
 * (Superseded by the 2026-09-04 note above; kept because the paragraph below is written in its
 * voice and reads as current otherwise.)
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
 * use --floor-answers-s<season> / --floor-context-s<season>. Raising is the ordinary case — a
 * season opens and takes answers — but the two directions do NOT share a schedule: see the two
 * ▶ paragraphs below, which are a matched pair and disagree about when the floor moves relative
 * to the migration. Lowering a floor to make this gate pass is the exact event the gate exists
 * to report. If rows are genuinely gone, find out why first.
 *
 * ⚠ THE OVERRIDE FLAGS NAME THEIR SEASON AS OF 2026-09-04, AND THE OLD BARE FORM NOW REFUSES.
 * `--floor-answers=N` was unambiguous while season 1 was the only floored season. With two, a
 * bare flag moves BOTH — so adjusting season 2 by hand would have dropped season 1's floor to
 * the same number and blinded the gate to a loss in the older corpus. Any script, runbook or
 * habit still passing the bare form gets a hard error naming the replacement, not a silent
 * change of meaning.
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
 *                                     Verify the pairs, then lower the ANSWER floor.
 *     answers AND context fall by the SAME amount, and named pairs account for it exactly
 *                                  →  a WITHDRAWAL. Deliberate.
 *                                     Verify the pairs, then lower BOTH floors.
 *     answers AND context fall, UNACCOUNTED  →  rows are being destroyed. STOP.
 *     answers fall, context RISES            →  also destruction, with a rewrite on top. STOP.
 *
 * 🔴 THE WITHDRAWAL BRANCH WAS MISSING UNTIL 2026-09-02, AND ITS ABSENCE MADE CORRECT WORK
 * READ AS DATA LOSS. This table used to say, flatly, "answers AND context fall together →
 * rows are being destroyed. STOP." CLAUDE.md's answer-delete rule has always had TWO
 * dispositions and they are opposites: rewrite the context as a documented blank when the
 * topic genuinely applies, or DELETE the context when it does not. The second one takes both
 * rows down together, by construction — and it had no branch here, exactly as this file once
 * said floors move "only upward" and left no branch for the first one.
 *
 * `CC_0037` is the worked example. Twelve of Jeff Gonzalez's seatings were evidenced against
 * a DIFFERENT PERSON, so both the answer and the context were removed: the context was the
 * thing that was wrong, and a documented blank would have asserted something about Gonzalez
 * that nobody had tested. −12 / −12 is what a correct withdrawal looks like.
 *
 * ⚠ THE BRANCH IS NOT "THEY FELL BY THE SAME NUMBER". Equal deltas are the CHEAP HALF of the
 * test, and a coincidence can produce them. The branch is only taken once NAMED pairs account
 * for the shortfall exactly, each verified to hold zero answers AND zero context. Without
 * that, equal deltas are just as consistent with destruction.
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
 * ▶ RAISING THE FLOOR IS THE APPLYING SESSION'S JOB, AND ITS ORDER IS THE OPPOSITE ONE.
 * "Raising is the ordinary case" said nothing about WHEN, and read as though the two directions
 * shared a rule. They do not, and the asymmetry follows from the same fact — migrations here are
 * applied ad hoc and never replayed by a deploy (CLAUDE.md):
 *
 *     LOWERING  the rows are gone the moment the migration is APPLIED, and the file may merge
 *               long after. Drop the floor in the migration's own PR, or the nightly reddens
 *               against master with nobody left who can derive the number.
 *     RAISING   the rows do not exist until the migration is APPLIED, and the file usually
 *               merges FIRST. Raise the floor after applying — never in the merging PR.
 *
 * Get that backwards and the gate fails for the mirror-image reason: a floor of 2,689 committed
 * against a corpus that still holds 2,685 reports "4 MISSING" every night until someone applies
 * the migration, and the message says rows were LOST when in fact they were never written. That
 * is the worst possible false positive for this particular check, because its whole job is to be
 * believed when it says that.
 *
 * `CC_0074` is the worked example, and it carries the same note in its own header: it inserts
 * four answers and four context rows, its post-verify asserts the totals the floors must become,
 * and it is explicit that the raise waits for the apply.
 *
 * ⚠ SO A RAISE IS NOT URGENT AND A DROP IS. An unraised floor after an apply leaves the new rows
 * merely unprotected — the gate still guards everything that came before, and still passes. An
 * undropped floor after a blanking apply is a red gate. When in doubt about ordering, that is the
 * asymmetry to reason from.
 *
 * NO DATABASE_URL IS A FAILURE, NOT A SKIP. The database is the whole check — there is no
 * static half that still means something. A gate that quietly passes when it never ran reads
 * "healthy" while measuring nothing, which is how a source that never runs looks fine
 * forever. Pass --allow-skip for a deliberate local run without credentials.
 *
 * RUN: npm run check:season-floor --prefix backend
 *      npm run check:season-floor:verbose --prefix backend
 *
 * CI:  ⚠ THE NIGHTLY CRON AND MANUAL DISPATCH ONLY — NOT master-push, NOT pull requests. This
 *      line said "master-push and daily cron" until 2026-09-04 and that was never true of the
 *      job: `season-corpus-floor` in ci.yml carries
 *
 *          if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
 *
 *      deliberately, on a cost argument written beside it — a commit cannot cause what this
 *      measures, so billing it per push watches for something pushes do not do.
 *
 *      🔴 THE STALE LINE POINTED THE WRONG WAY AT THE ONE MOMENT IT IS READ. Someone changing a
 *      floor reads this to learn how the change gets checked, concludes that merging to master
 *      runs it, sees a green master, and is wrong — the number is not measured until 13:00 UTC.
 *      That is the same shape as the paragraph above, which already warns that a blanking PR
 *      merges green and fails hours later; this line quietly denied it.
 *
 *      TO VERIFY A FLOOR CHANGE NOW, do one of these — do not wait for the cron and do not read
 *      a green PR as evidence:
 *        · run it locally against prod (the floors are prod numbers; the run above needs only
 *          DATABASE_URL), or
 *        · `gh workflow run ci.yml --ref master`, which is what workflow_dispatch is for.
 *
 *      It needs DATABASE_URL either way — use the session pooler string, which is IPv4; the
 *      direct host is IPv6-only.
 */

import 'dotenv/config';
import pg from 'pg';

const VERBOSE = process.argv.includes('--verbose');
const ALLOW_SKIP = process.argv.includes('--allow-skip');

/**
 * Read a `--<name>-s<season>=N` override, or fall back to the committed baseline.
 *
 * 🔴 THE OVERRIDE NAMES ITS SEASON, AND THE BARE FORM IS REFUSED. While season 1 was the only
 * floored season, `--floor-answers=N` was unambiguous and this function took no season at all.
 * With season 2 floored it is no longer safe: ONE bare flag would move EVERY season's floor at
 * once, so an operator adjusting season 2 by hand would silently drop season 1's floor to the
 * same number — blinding the gate to a real loss in the corpus it was built to protect, in the
 * exact motion of someone who thought they were touching the other season.
 *
 * Refusing the bare form is deliberate. Defaulting it to season 1, or to "all seasons", both
 * fail the same way this file's other defaults would: quietly, and in the direction of a
 * green run that measured less than the reader thinks.
 */
function flagInt(name, season, fallback) {
  if (process.argv.some((a) => a.startsWith(`--${name}=`))) {
    console.error(
      `check-season-corpus-floor: --${name} must name the season it moves — use ` +
        `--${name}-s<number>=N (e.g. --${name}-s${season}=N). A bare --${name} would move ` +
        `every season's floor at once, which is how an override meant for one season blinds ` +
        `this gate to another season's loss.`
    );
    process.exit(1);
  }
  const flag = `--${name}-s${season}`;
  const hit = process.argv.find((a) => a.startsWith(`${flag}=`));
  if (!hit) return fallback;
  const n = Number.parseInt(hit.split('=')[1], 10);
  if (!Number.isInteger(n) || n < 0) {
    console.error(`check-season-corpus-floor: ${flag} needs a non-negative integer.`);
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
    // and once for a WITHDRAWAL, which is the other disposition and takes the CONTEXT floor
    // down with it — the first time this floor pair has moved together:
    //
    //   −12 / −12 on 2026-09-02: CC_0037 (12 answers AND 12 context rows), PR #320
    //
    // NOT taken from "what prod reads today" — reading it off prod is what would absorb a real
    // loss silently. Each retirement count comes from the migration's own post-verify gate, and
    // no migration in either window INSERTs answers, so the net cannot hide extra deletions
    // behind additions. The context floor did not move across either window, which is the
    // signature of deliberate blanking rather than destruction.
    // 33,164 − 32 − 94 − 4 − 12 = 33,022, which is the number below, derived rather than observed.
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
    answers: flagInt('floor-answers', 1, 33022),
    // 33,818 when measured, and it held across all three documented-blank windows — a blank
    // REWRITES its context, so those never moved it, and that it held is what proved each of
    // those answer losses deliberate.
    //
    // 🔴 CC_0037 IS THE FIRST THING TO MOVE IT, AND THAT IS CORRECT, NOT A BREACH. A
    //    withdrawal deletes the context because the context is the thing that is wrong.
    //    33,818 − 12 = 33,806, derived the same way as the answer floor.
    context: flagInt('floor-context', 1, 33806),
    questions: flagInt('floor-questions', 1, 44),
    measured: '2026-08-27',
    adjusted: '2026-09-02',
  },
  2: {
    // Season 2 opened 2026-09-04 14:31Z with 60 questions, and took no answers of its own at
    // the open: every row below was written by ONE re-research batch on 2026-09-03 20:16Z,
    // while season 2 was still `draft` and season 1 still held the open slot.
    //
    //   Affordable Housing    1,785 answers / 1,785 context
    //   Same-Sex Marriage       900 answers /   872 context
    //   -------------------------------------------------
    //                         2,685 answers / 2,657 context
    //
    // These are not counted off prod. They are `CC_0058`'s OWN post-verify constants — the
    // migration raises unless it wrote exactly 2,685 answers and 2,657 context rows, and its
    // closing NOTICE prints both. That is the strongest provenance a floor can have: the number
    // the writing migration refused to finish without.
    //
    // ⚠ THE 28-ROW DIFFERENCE IS THE BLANKS, AND IT IS REQUIRED — NOT A GAP TO INVESTIGATE.
    //    An earlier version of this comment called it "not yet explained" and read the 28 as
    //    unsourced rows at a forbidden value. That was wrong in both halves, and wrong in the
    //    direction that costs the most: it invited someone to "fix" a ruling by re-researching
    //    or deleting rows that are correct.
    //
    //    `CC_0057` widened the CHECK to `value IN (0,1,2,3,4,5)` so the schema could say
    //    "researched, and no rung states what they hold" — a fact distinct from an absent row
    //    (never researched) and from a deleted one (which, under seasons, blanks nobody: the
    //    read falls back to season 1). The season 2 Same-Sex Marriage ladder (`CA_0074`) retires
    //    old rung 3, "let each state decide"; its rung_map marks that rung `invalidated`. The 28
    //    politicians who sat there have nowhere to go on the new ladder, and Chris ruled on
    //    2026-09-02: blank them, and keep season 1's rung-3 answer as the historical record.
    //
    //    Their having NO season 2 context is likewise deliberate and enforced. Their season 1
    //    reasoning argues federalism — a position the season 2 row no longer records — so
    //    carrying it would put prose arguing a stance under a spoke that shows none.
    //    `CC_0058` §3f RAISES if any blanked answer carries season 2 reasoning, and again if any
    //    non-blank reaches season 2 without it. The 28-row difference between these two floors
    //    is that invariant, expressed in row counts.
    //
    //    So: 2,685 − 2,657 = 28 is the CORRECT relationship between these numbers, and a future
    //    reader who finds them equal should ask what happened to the blanks. Season 1 leaning
    //    the other way — 784 MORE context than answers — is the older blank idiom (context, no
    //    answer) and does not apply here; season 2's blank is a row that says 0.
    //
    //    A cleanup that deletes them would be a REGRESSION, not a retirement. If some future
    //    season gives that federalism position a rung again, the 28 get re-seated by a migration
    //    that raises this floor, and the movement is visible here either way.
    //   +4 / +4 on 2026-09-04: CC_0074, applied. The Senate research pilot's first
    //   four answers — Padilla and Schiff on gun-policy and minimum-wage — each with
    //   its context row, so both floors move together by the same amount. That is the
    //   signature of ordinary research landing, and it is the first time either of
    //   these numbers has moved for a reason other than the season opening.
    //
    //   Derived from CC_0074's own post-verify, which RAISES unless the totals read
    //   exactly 2,689 and 2,661 — and raised only AFTER the apply, per the ordering
    //   rule above. Committing 2,689 while prod still held 2,685 would have reported
    //   "4 MISSING" nightly until somebody applied it.
    //
    //   +55 / +55 on 2026-09-08, to 2,744 / 2,716. Two batches, not one:
    //     · CC_0078 (+45 / +45), applied — the Senate gun-policy pass, 42 senators at
    //       chair 2 off an Assault Weapons Ban and 3 at chair 3 off the Background Check
    //       Expansion Act, each with its context row. Raised to the totals its closing
    //       NOTICE printed, after the apply, per the ordering rule above.
    //     · the Miami-Dade stance pass (PR #401, +10 / +10), which had landed between
    //       CC_0074 and this and never moved the floor. A floor may sit below the live
    //       corpus, so that was safe, not a bug — but a raise measured against prod on
    //       apply picks the stragglers up, which is why 2,689 + 45 reaches 2,744 rather
    //       than 2,734. Confirmed against prod 2026-09-08: season 2 holds 2,744 / 2,716.
    //   2,744 − 2,716 = 28, still the blanks invariant above.
    //
    //   +51 / +51 on 2026-09-08, to 2,795 / 2,767. Also two components, and the second
    //   is the same straggler effect as the entry above:
    //     · CC_0079 (+49 / +49), applied — the Senate gun-policy rung 4 batch. 49
    //       senators who sponsor or cosponsor the Constitutional Concealed Carry
    //       Reciprocity Act, 47 off S. 65 and 2 off S. 214, each with its context row.
    //       They were seatable only because CA_0104 reworded rung 4 EARLIER THE SAME
    //       DAY; under the old wording no rung described them and CC_0078 deliberately
    //       wrote no row for any of them.
    //     · +2 / +2 of local-tier research that had landed above the floor since the
    //       raise above. Prod read 2,746 / 2,718 immediately before this apply against
    //       a floor of 2,744 / 2,716, which is why 2,744 + 49 reaches 2,795 and not
    //       2,793. A floor sitting below the live corpus is safe, not a bug.
    //
    //   Derived from CC_0079's closing NOTICE, after the apply, per the ordering rule
    //   above. That NOTICE prints the LIVE totals precisely because the file asserts
    //   its own DELTA rather than a total — CC_0078 shipped absolute totals and they
    //   went stale before a human had finished reviewing its chairs, which is the
    //   failure this pair of numbers should never depend on again.
    //   2,795 − 2,767 = 28, still the blanks invariant above.
    answers: flagInt('floor-answers', 2, 2795),
    context: flagInt('floor-context', 2, 2767),
    // 60 questions: 43 carried from season 1, 17 new, 1 dropped (Immigration and Treatment of
    // Immigrants). A season's question set is fixed once it opens, so this floor should hold.
    questions: flagInt('floor-questions', 2, 60),
    measured: '2026-09-08',
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

  // A season with no committed floor is a gap in the gate, not a pass.
  //
  // 🔴 IT USED TO ONLY WARN, AND THAT IS HOW SEASON 2 WENT A FULL DAY UNMEASURED. The batch of
  // 2026-09-03 wrote 2,685 answers into season 2; the season opened the next morning; the
  // nightly gate printed one line saying they were unprotected and exited GREEN. Nothing was
  // wrong with the rows — but had they been destroyed that night, this check, the layer that
  // exists precisely because a deleted row leaves no trace, would have reported healthy.
  //
  // So the warning now has a floor of its own: a season that is PAST DRAFT and holds answers
  // must be floored. Draft seasons and empty ones still only warn, which keeps the original
  // reading intact — a season being scaffolded genuinely has nothing to protect yet. The
  // effect is that the PR which opens a season is the PR that must commit its floor, the same
  // rule the blanking case learned three times over.
  const unprotected = unfloored.filter((s) => s.status !== 'draft' && s.answers > 0);

  for (const s of unfloored) {
    console.warn(
      `season corpus floor: season ${s.number} ("${s.name}", ${s.status}) has NO committed ` +
        `floor — ${s.answers.toLocaleString()} answers and ${s.context.toLocaleString()} ` +
        `context rows are currently UNPROTECTED. Add an entry to FLOORS once it takes answers.`
    );
  }

  if (unprotected.length > 0) {
    console.error('\nseason corpus floor FAILED — a live season is holding answers no floor covers:\n');
    for (const s of unprotected) {
      console.error(
        `    · season ${s.number} ("${s.name}", ${s.status}): ${s.answers.toLocaleString()} ` +
          `answers, ${s.context.toLocaleString()} context, ${s.questions} questions — NO FLOOR`
      );
    }
    console.error(
      '\n  This is not a claim that rows were lost. It is that a loss here could not be seen:\n' +
        '  an unfloored season is compared against nothing, so it reads green whatever happens\n' +
        '  to it.\n' +
        '  Add an entry to FLOORS keyed by the season number. DERIVE the numbers from the\n' +
        '  batches that wrote the rows — a floor copied from `SELECT count(*)` silently\n' +
        '  absorbs anything already gone, which is the one failure this gate cannot recover\n' +
        '  from. See the season 2 entry for the shape, and WHEN A FLOOR SHOULD MOVE above.\n'
    );
    process.exit(1);
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
      '\n  Do NOT lower the floor to make this pass. Account for the rows first.\n' +
        '  READ THE SIGNATURE: answers falling while context HOLDS is a documented-blank ' +
        'retirement; answers and context falling by the SAME amount is a withdrawal ' +
        '(@context-decision: deleted-with-context). Both are deliberate — and both are ' +
        'confirmed only once NAMED pairs account for the shortfall exactly, each verified to ' +
        'hold zero answers and zero context.\n' +
        '  Anything else — unequal falls, context rising, or no migration that owns it — is ' +
        'destruction. Check: (1) a REPLACE-ALL RPC reached from a partial payload, the defect ' +
        'CC_0001 fixed; (2) an ad-hoc psql DELETE; (3) a migration that deleted answers ' +
        'without deciding what happened to the matching context rows.\n' +
        '  DATING: `updated_at` is real and is the diagnostic that works. `created_at` is a ' +
        'BACKFILL CONSTANT — every row carries 2026-08-26 03:46:19 — so it cannot say when a ' +
        'row was written, and a query filtered on it returns 0 for reasons that have nothing ' +
        'to do with the question. A DELETED row leaves neither.\n' +
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
