#!/usr/bin/env node
/**
 * check-nightly-freshness.mjs — is the nightly still firing at all?
 *
 * 🔴 WHY THIS EXISTS. The scheduled run is where every live-DB tripwire lives:
 * `lens durability`, `duplicate people`, `coverage honesty`, `rls coverage` and
 * a dozen more run ONLY on the schedule. If the schedule stops, all of them stop
 * reporting, and not one of them goes red — they simply never run again. Nothing
 * in this repository would say so. A tripwire that stops firing reads exactly
 * like a tripwire with nothing to report.
 *
 * ⚠ AND THE SCHEDULE IS VISIBLY DEGRADING. Measured 2026-11-25 over the 117
 * scheduled runs since 2026-07-31, lateness against the 13:00 UTC due time:
 * August averaged +2.2h, September +4.4h, October +5.3h, November +7.7h — about
 * +1.5h a month, with no run in the last 60 landing within an hour of due. The
 * cadence itself is still perfect (117 days, 117 covered, none missed, none
 * doubled), so this is not a response to a failure. It is the detector for the
 * failure that trend is heading toward.
 *
 * 🔴 IT CANNOT LIVE IN THE NIGHTLY, WHICH IS THE WHOLE POINT. A freshness check
 * that runs on the schedule dies with the thing it is watching: the morning the
 * schedule stops, the check stops too and the last thing it ever said was
 * "fine". So it runs on push and pull_request, in `static guards`, on a cadence
 * the schedule cannot take down with it. Measured 2026-11-25: 60 pushes to
 * master in six days, median gap 1.0h, worst 18.9h, none over 40h.
 *
 * 💰 AND IT COSTS NOTHING. `static guards` already runs on every push and PR and
 * finishes inside the one-minute minimum it already pays, so a fifth
 * dependency-free guard adds no billed minutes. A heartbeat job of its own would
 * have cost ~300 a month, which is the trade that job comment already refuses
 * for `lens durability` ("charging it per push would bill ~494 minutes a month").
 * It uses `fetch` and nothing else — no `npm ci`, no pg, no third-party action —
 * because that is the entry price for being in that job.
 *
 * ⚠ WHAT IT DOES NOT COVER, stated rather than discovered:
 *
 *   - It is gated behind `needs.changes`, so a stretch of docs-only pushes
 *     pauses the heartbeat. Harmless at a 40h threshold and a 1.0h median, and
 *     worth knowing before you conclude from silence.
 *   - It degrades GREEN when the API cannot be reached or returns nothing
 *     useful, following `migration reservations`' precedent for forks, which get
 *     no secrets. So an outage plus a stopped schedule reads green. That is the
 *     same trade this repo already makes, not a new one.
 *   - It says nothing about whether the nightly PASSED. A run that fires and
 *     fails is fresh. Freshness and verdict are different questions and this
 *     answers exactly one.
 *
 * THRESHOLD — 40 hours, from the measurement and not from taste. The gap between
 * consecutive scheduled runs over those 117 runs: median 24.0h, minimum 18.1h,
 * worst 32.9h, exactly one over 30h and none over 36h. 40h clears the worst
 * observed gap by ~7h, so ordinary drift cannot redden it, and still fires well
 * inside the 48h that a genuinely missed day would produce. A check that is red
 * on ordinary use is a check that gets muted.
 *
 * RUN:
 *   npm run check:nightly-freshness            # needs GITHUB_TOKEN + GITHUB_REPOSITORY
 *   node scripts/check-nightly-freshness.mjs --allow-skip   # local, no token
 */

const argv = process.argv.slice(2);
const ALLOW_SKIP = argv.includes('--allow-skip');

/** Hours since the last scheduled run before this goes red. See the header. */
export const MAX_AGE_HOURS = 40;

/** The workflow whose schedule is being watched. One file, named not guessed. */
const WORKFLOW_FILE = 'ci.yml';

/* ------------------------------------------------------------- the judgement ---- */
/* Pure and exported so "does 41 hours fire" is answerable without a network. */

/**
 * @param {string|null} lastRunAt ISO timestamp of the most recent scheduled run,
 *   or null when the API returned no scheduled run at all.
 * @param {Date} now
 * @returns {{red: boolean, ageHours: number|null, reason: string}}
 *
 * 🔴 NO SCHEDULED RUN AT ALL IS RED, NOT GREEN. An empty list is the most
 * complete version of the failure this exists to catch — the schedule has never
 * fired, or has aged out of the API's retention entirely. Reading "no runs" as
 * "nothing to complain about" would make the check silent in precisely its worst
 * case. The one benign cause, a brand-new repository, cannot apply here: this
 * one has 117 scheduled runs behind it.
 */
export function judgeFreshness(lastRunAt, now = new Date()) {
  if (!lastRunAt) {
    return { red: true, ageHours: null, reason: 'the API returned no scheduled run for this workflow at all' };
  }
  const ageHours = (now.getTime() - new Date(lastRunAt).getTime()) / 3_600_000;
  if (!Number.isFinite(ageHours)) {
    return { red: true, ageHours: null, reason: `could not read a timestamp from ${JSON.stringify(lastRunAt)}` };
  }
  // ⚠ A FUTURE TIMESTAMP IS NOT RED. Clock skew between the runner and GitHub
  // makes a slightly negative age possible, and "the nightly ran in the future"
  // is not a failure anybody can act on. Fresh is fresh.
  if (ageHours > MAX_AGE_HOURS) {
    return {
      red: true,
      ageHours,
      reason: `the last scheduled run was ${ageHours.toFixed(1)}h ago, over the ${MAX_AGE_HOURS}h limit`,
    };
  }
  return { red: false, ageHours, reason: `last scheduled run was ${ageHours.toFixed(1)}h ago` };
}

/* ------------------------------------------------------------------ the live half ---- */

/**
 * The most recent `schedule`-triggered run of this workflow.
 *
 * ⚠ `run_started_at` IS PREFERRED OVER `created_at`, and for scheduled runs they
 * are the same instant — measured across all 117, GitHub creates the run and
 * starts it in the same moment, which is itself how we know the lateness is in
 * GitHub's scheduler and not in a queue. `created_at` is the fallback only
 * because it is the field guaranteed to be present.
 */
async function readLastScheduledRun(repo, token) {
  const url = `https://api.github.com/repos/${repo}/actions/workflows/${WORKFLOW_FILE}/runs` +
    '?event=schedule&per_page=1';
  const res = await fetch(url, {
    headers: {
      accept: 'application/vnd.github+json',
      authorization: `Bearer ${token}`,
      'x-github-api-version': '2022-11-28',
      // A generic client name on purpose: this is an outbound request and the
      // repo or the operator is nobody's business but ours.
      'user-agent': 'ev-accounts-ci-freshness-check',
    },
  });
  if (!res.ok) {
    throw new Error(`GitHub API ${res.status} ${res.statusText}`);
  }
  const body = await res.json();
  const run = body?.workflow_runs?.[0];
  if (!run) return null;
  return { at: run.run_started_at || run.created_at, id: run.id, conclusion: run.conclusion };
}

async function main() {
  const repo = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;

  if (!repo || !token) {
    const missing = [!repo && 'GITHUB_REPOSITORY', !token && 'GITHUB_TOKEN'].filter(Boolean).join(' and ');
    if (ALLOW_SKIP) {
      console.log(`nightly freshness SKIPPED — no ${missing}. NOTHING WAS MEASURED.`);
      return 0;
    }
    // Degrades green, per the header. Said loudly, because a silent skip is the
    // shape of failure this whole script exists to prevent.
    console.log(`nightly freshness: no ${missing}, so nothing could be measured — treating as green.`);
    console.log('   (forks get no secrets; see the header. This is NOT a statement that the nightly is alive.)');
    return 0;
  }

  let last;
  try {
    last = await readLastScheduledRun(repo, token);
  } catch (err) {
    console.log(`nightly freshness: could not reach the GitHub API (${err.message}) — treating as green.`);
    console.log('   (This is NOT a statement that the nightly is alive.)');
    return 0;
  }

  const verdict = judgeFreshness(last?.at ?? null);

  if (verdict.red) {
    console.error(`\n🔴 nightly freshness FAILED — ${verdict.reason}.`);
    console.error('   The scheduled run is the ONLY trigger for every live-DB tripwire in this');
    console.error('   workflow: lens durability, duplicate people, coverage honesty, rls coverage');
    console.error('   and the rest. If it has stopped, none of them are red — they are not running,');
    console.error('   and nothing else in this repo would say so.');
    console.error('\n   First three things to check:');
    console.error('     1. Actions → the workflow → is the schedule disabled? GitHub disables');
    console.error('        schedules in repositories with 60 days of no activity.');
    console.error(`     2. gh run list --event schedule --limit 5   (does GitHub agree it stopped?)`);
    console.error('     3. The drift table in ci.yml: if runs are now >24h late they are colliding,');
    console.error('        which is the degradation this threshold was set to catch.');
    if (last) console.error(`\n   Last scheduled run: ${last.at}  (id ${last.id}, ${last.conclusion ?? 'no conclusion'})`);
    return 1;
  }

  console.log(`✅ nightly freshness — ${verdict.reason} (limit ${MAX_AGE_HOURS}h)`);
  return 0;
}

// Only run when invoked directly, so the test can import the judgement.
//
// 🔴 `process.exitCode`, NEVER `process.exit()`. Measured on Windows 2026-11-25:
// calling process.exit() straight after a fetch aborts the process while
// undici's sockets are still closing — `Assertion failed: !(handle->flags &
// UV_HANDLE_CLOSING), file src\win\async.c` — and node exits 127 AFTER printing
// a correct green verdict. A check whose exit code contradicts its own output is
// worse than no check: this one would have read red in CI on a healthy nightly.
// Setting exitCode lets the loop drain and exit on its own.
if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith('check-nightly-freshness.mjs')) {
  main()
    .then((code) => {
      process.exitCode = code;
    })
    .catch((err) => {
      console.error('nightly freshness: unexpected error', err);
      process.exitCode = 1;
    });
}
