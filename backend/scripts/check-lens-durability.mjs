#!/usr/bin/env node
/**
 * check-lens-durability.mjs — did anybody's custom lenses go missing, and does
 * anyone know about it yet?
 *
 * 🔴 WHY THIS EXISTS. On 2026-11-22 a short `PUT /api/compass/my-lenses` payload
 * was measured destroying the lenses it did not mention. Three lenses stored,
 * the request named one, HTTP 200 came back, two lenses were gone, and there was
 * no record anywhere that they had ever existed — not in the response, not in a
 * log, not in the table. The only reason anybody found out is that somebody went
 * looking for something else.
 *
 * ev-accounts#1584 closed that path: one PUT may now delete at most one lens, a
 * deletion is a soft delete, and every change to inform.compass_user_lenses is
 * written to inform.compass_user_lens_history by a trigger that application code
 * cannot bypass. That is the fix. This is the thing that notices the NEXT one.
 *
 * ⚠ IT WATCHES THE OUTCOME, NOT THE ROUTE, AND THAT IS THE WHOLE DESIGN. A guard
 * on the PUT handler can only defend against the destruction we already found.
 * A nightly that reads the history table sees lenses disappearing by routes
 * nobody has written yet — a new endpoint, a hand-run UPDATE, a migration with a
 * bad WHERE, an ORM doing something clever. It does not need to know what the
 * next hole is.
 *
 * 🔴 BUT ITS REACH IS EXACTLY THE TRIGGER'S REACH, AND GREEN IS NOT A PROOF OF
 * INTEGRITY. Every row this reads was written by CC_0468's trigger on
 * inform.compass_user_lenses. Anything that removes lenses WITHOUT firing that
 * trigger is invisible here and leaves the check green:
 *
 *   - ALTER TABLE ... DISABLE TRIGGER, or a session with session_replication_role
 *     set to replica;
 *   - dropping and recreating the table, which takes the trigger with it;
 *   - a restore from backup, which rewrites the table underneath the history.
 *
 * TRUNCATE is NOT on that list: CC_0468 installs a TRUNCATE refusal trigger on
 * the table, so that path is closed rather than merely unwatched. The three above
 * are open, are all operator actions rather than application paths, and are
 * written down here because this header is what the next reader sees.
 *
 * WHAT IS CHECKED — two conditions, both failures, no baseline:
 *
 *   1. MULTI-DELETE. One owner removed MORE THAN ONE DISTINCT lens inside the
 *      window. One person deleting one lens is somebody tidying up. One person
 *      losing two is the 2026-11-22 shape, and that is the shape the whole
 *      incident had. THE CI ACCOUNT IS EXCLUDED FROM THIS ONE ONLY — see
 *      CI_OWNER_ID for why, and for the hole it opens.
 *
 *   2. ORPHAN HARD DELETE. A row left inform.compass_user_lenses outright while
 *      its owner's account still exists. The ONLY sanctioned hard delete is the
 *      account-deletion cascade; the sanctioned user-facing deletion is a SOFT
 *      delete, which is recoverable. A hard delete under a live account means
 *      something reached the table by a path that is not the application's.
 *
 * ⚠ A THIRD CONDITION WAS DESIGNED AND DROPPED: "an owner's live lens count fell
 * to zero". It was dropped because it cannot be told apart from ordinary use.
 * MEASURED 2026-11-22 against production: 3 live lenses across 3 owners, each
 * owner holding exactly one. Under that data, every single deletion any current
 * owner could make would take them to zero — so the condition would be red on
 * the first ordinary tidy-up, and a check that is red on ordinary use is a check
 * that gets muted. Condition 1 is the same instinct written so that it only
 * fires on the shape that is actually suspicious.
 *
 * ⚠ THE JOIN ON `public.users` IS DELIBERATE AND IS NOT A SECOND SOURCE OF
 * TRUTH. History is the source of EVENTS. Whether the account still exists is a
 * fact only public.users holds, and both conditions turn on it: condition 2 IS
 * that question, and condition 1 has to exclude account deletions because an
 * account deletion legitimately removes every lens at once. What this check must
 * never do is read a committed baseline file — a baseline is a record of what we
 * expected, and the thing being watched for is precisely that reality stopped
 * matching what we expected.
 *
 * 🔴 NO DATABASE_URL IS A FAILURE HERE, NOT A SKIP, AND THAT IS ON PURPOSE. The
 * design doc said skip-and-exit-0 "matching check-migration-reservations". This
 * follows check-lens-freshness instead. Two reasons. The job is schedule-only,
 * so a fork with no secrets never runs it and there is nobody to be kind to. And
 * a green skip is exactly the design's own anti-goal — a check "satisfied
 * without being true". A tripwire that never ran reads healthy forever, and the
 * morning it matters is the morning nobody looks. `--allow-skip` exists for
 * local work and says in so many words that nothing was measured.
 *
 * 🔴 THE DEPLOY WINDOW: EXPECT CONDITION 2 TO FIRE, AND DO NOT "FIX" THE CHECK.
 * CC_0468 went live in production BEFORE the backend that uses soft delete was
 * deployed. Between those two moments the OLD service is still running and still
 * issues a plain DELETE FROM inform.compass_user_lenses. The trigger now records
 * every such DELETE as op='hard_delete' under a LIVE owner, which is condition 2's
 * exact alarm ("Something reached the table outside the application"). CompassV2's
 * smoke suite calls clearServerLenses against production on every PR run, so
 * ordinary CI traffic will produce these rows. (Measured when this was written:
 * history was still empty, so the window was open but nothing had landed in it.)
 *
 * The condition is correct and is deliberately NOT weakened: during the window a
 * hard_delete under a live owner genuinely IS the sanctioned path being bypassed,
 * because the sanctioned path has not shipped yet. The right response is to ACK
 * those rows with a note naming the window, not to edit the check.
 *
 * ⚠ THE PART THAT WILL ACTUALLY BITE: --selftest ABORTS AGAINST A RED BASELINE.
 * The operator's first instinct, running the selftest to see whether the check is
 * healthy, will not work until those rows are acked. Ack first, then selftest.
 *
 * RUN:
 *   npm run check:lens-durability                 # the nightly
 *   npm run check:lens-durability:selftest        # plant removals, watch it go red, ROLLBACK
 *   npm run check:lens-durability:ack -- <history-id>... --note "why"
 *   node scripts/check-lens-durability.mjs --allow-skip    # local, no DATABASE_URL
 */
import 'dotenv/config';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const argv = process.argv.slice(2);
const ALLOW_SKIP = argv.includes('--allow-skip');
const SELFTEST = argv.includes('--selftest');
const ACK = argv.includes('--ack');

/**
 * How far back an UNACKNOWLEDGED removal keeps this red.
 *
 * 🔴 SEVEN DAYS, NOT TWENTY-FOUR, AND THE DIFFERENCE IS THE POINT. PITR is off;
 * the floor is daily backups with 7-day retention. A 24h query window would let
 * a destruction age out of the alarm while it was still recoverable — which is
 * the self-healing window the design doc rejected, rebuilt as a WHERE clause.
 * Seven days is exactly as long as being red is actionable.
 */
const ALERT_WINDOW_DAYS = 7;

/**
 * The CI account, whose multi-lens deletions are the test suite doing its job.
 *
 * 🔴 WHY AN EXCLUSION EXISTS AT ALL, GIVEN THIS FILE REFUSES BASELINES.
 * CompassV2's smoke suite runs `clearServerLenses` against PRODUCTION on every
 * PR run, deleting each lens it created by name. That is several distinct lenses
 * removed by one owner inside the window — condition 1's exact shape, produced on
 * purpose, several times a week. MEASURED 2026-11-25: of all removal events in
 * the window, 9 rows across 4 distinct keys, EVERY ONE of them this account's,
 * and no other owner had removed anything at all.
 *
 * A baseline is a record of what we expected reality to look like, and this file
 * rejects one because the thing being watched for is reality diverging from it.
 * This is a different object: the identity of a robot that generates sanctioned
 * deletions as its purpose. It does not say "we expect N removals"; it says
 * "these removals were commanded by our own test suite".
 *
 * ⚠ THE HOLE THIS OPENS, STATED PLAINLY. Destruction confined to this account is
 * now invisible to condition 1. That is accepted: the account holds no real
 * lenses, it is already documented as the throwaway that gets destroyed on
 * purpose, and the alternative — acking its rows by hand every few days — is how
 * a tripwire becomes something nobody reads. Condition 2 still covers it (below).
 *
 * ⚠ IT FAILS OPEN. If the account is recreated the id changes, nothing matches,
 * and the nightly goes RED with this account named — noisy, not silent. The
 * correct repair is to update this constant, which is also the only way a reader
 * finds out the account moved.
 *
 * ⚠ WHY THE ID AND NOT THE EMAIL OR THE DISPLAY NAME. The nightly's role cannot
 * read the `auth` schema at all — measured: `permission denied for schema auth` —
 * so the email is unavailable at runtime. `public.users.display_name` is readable
 * and was rejected: it is editable, so any account could take the name and quietly
 * leave condition 1's reach. A tripwire that can be stepped around by renaming
 * yourself is not one.
 */
const CI_OWNER_ID = '1f73d209-e6c3-47ea-9187-cb10f5c9c6e7'; // compass-smoke@empowered.vote

/**
 * EVERY removal event in the window, acknowledged or not, each carrying whether
 * it has been acknowledged.
 *
 * 🔴 THE ACK IS A FLAG ON THE ROW, NOT A `WHERE` CLAUSE, AND THAT DISTINCTION IS
 * A REAL DEFECT THIS QUERY ONCE HAD. Filtering acked rows out here shrinks the
 * GROUPING set and not just the ALERTING set, and condition 1 is a grouping
 * condition. The case it loses: an owner holds two lenses and deletes one on
 * Monday; an operator acks it as ordinary tidying. On Thursday a bug soft-deletes
 * the second. With acked rows filtered out, Thursday's run sees ONE row with ONE
 * distinct key and reports GREEN — while that owner lost both lenses inside the
 * same seven days. That is precisely the shape condition 1 exists to catch.
 *
 * The design doc is unambiguous once you read the two sentences together:
 * condition 1 fires when "any single owner had more than one lens removed", and
 * the check "ignores acknowledged ones and fails on the rest". Acknowledgement
 * governs what FAILS. It never governs what is COUNTED.
 *
 * ⚠ The LEFT JOIN to the acks table cannot fan rows out: `history_id` is its
 * PRIMARY KEY, so there is at most one ack per history row by construction.
 *
 * ⚠ The interval is built from a parameter rather than interpolated, so the
 * window constant above is the only place the number lives.
 */
const REMOVALS_SQL = `
  SELECT h.id::text, h.owner_id::text, h.lens_key, h.op, h.created_at,
         (u.id IS NOT NULL) AS owner_exists,
         (h.owner_id = $2::uuid) AS owner_is_ci,
         (a.history_id IS NOT NULL) AS acked
    FROM inform.compass_user_lens_history h
    LEFT JOIN public.users u ON u.id = h.owner_id
    LEFT JOIN inform.compass_lens_alert_acks a ON a.history_id = h.id
   WHERE h.op IN ('soft_delete', 'hard_delete')
     AND h.created_at >= now() - ($1 || ' days')::interval
   ORDER BY h.owner_id, h.created_at`;

/* ------------------------------------------------------------- the judgement ---- */
/* Pure, exported, and unit-tested in check-lens-durability.test.ts. The SQL above
 * is exercised by --selftest. Keeping the decision out of the query is what makes
 * "does this fire on the 2026-11-22 shape" answerable without a database.        */

/*
 * ⚠ TWO KNOWN LIMITS OF CONDITION 1, WRITTEN DOWN SO THEY ARE NOT DISCOVERED.
 *
 * (a) A RESTORED KEY STILL COUNTS. Only soft_delete and hard_delete rows are
 * selected, so an owner who deletes lens A, re-creates it (a restore row, which
 * is not selected), then deletes lens B reads as having lost two lenses. That is
 * a deliberate choice, not an oversight: both lenses DID leave, the case is rare,
 * and the alternative is netting restores out of the grouping, which is a second
 * change to grouping semantics, made late, whose own bugs would be silent in
 * exactly the way this check exists to prevent. Rare noise is acked with a note.
 *
 * (b) A BUG PLUS AN ACCOUNT DELETION IS INVISIBLE. If something soft-deletes three
 * lenses on Monday and the user deletes their account on Tuesday, owner_exists is
 * false: condition 1 drops the whole group and condition 2 treats the cascade as
 * sanctioned. That is correct per the rules, since an account deletion legitimately
 * removes everything, but it means Monday's damage is unreportable once the
 * account is gone. A limit of the check, stated here rather than discovered.
 */
/**
 * Condition 1. Owners who removed MORE THAN ONE DISTINCT lens in the window.
 *
 * 🔴 DISTINCT `lens_key`, NOT ROW COUNT. A soft delete that is later purged
 * writes TWO history rows for ONE lens. Counting rows would make every ordinary
 * purge look like a destruction event, and this check only survives if it is
 * silent when nothing is wrong.
 *
 * ⚠ Owners whose account is gone are dropped here, not reported. An account
 * deletion removes every lens the account held, all at once, by design — that is
 * condition 2's territory, and only when the account is still there.
 *
 * 🔴 ACKNOWLEDGED ROWS ARE GROUPED, NOT DROPPED. The group is built from every
 * removal in the window and is then discarded only if EVERY row in it has been
 * acknowledged. The obvious reading of "acked" is "gone from the report", and
 * that reading is wrong here on purpose — see the block above REMOVALS_SQL for
 * the Monday/Thursday case it would lose.
 *
 * `ids` carries EVERY removal row for the owner — the already-acked ones, and the
 * purge half of a soft-then-hard pair. When this fires, the operator wants the
 * Monday deletion in front of them too, because that is the context that makes
 * Thursday alarming.
 *
 * `unackedIds` is what the printed ack command uses, and it is a SUBSET of `ids`
 * rather than the same list. `--ack` refuses an id that is already acked, so a
 * command line built from `ids` would be rejected the moment the group contains
 * one — a failure that would look like the ack path being broken.
 */
export function findMultiDeleteOwners(rows) {
  const byOwner = new Map();
  for (const r of rows) {
    if (!r.owner_exists) continue;
    // 🔴 THE CI ACCOUNT NEVER FORMS A GROUP. Its deletions are commanded by the
    // smoke suite on every PR run — see CI_OWNER_ID. Dropping these rows is safe
    // in a way that dropping ACKED rows was not: grouping is per owner_id, so
    // these can only ever have grouped with each other, never with a real
    // owner's. Nothing a person lost is hidden by this line.
    if (r.owner_is_ci) continue;
    let g = byOwner.get(r.owner_id);
    if (!g) {
      g = {
        ownerId: r.owner_id,
        keys: [],
        ids: [],
        unackedIds: [],
        firstAt: r.created_at,
        lastAt: r.created_at,
      };
      byOwner.set(r.owner_id, g);
    }
    if (!g.keys.includes(r.lens_key)) g.keys.push(r.lens_key);
    g.ids.push(r.id);
    if (!r.acked) g.unackedIds.push(r.id);
    // The query orders by created_at, but the finder must not depend on it: a
    // caller feeding it rows from anywhere else still gets a true span.
    if (r.created_at < g.firstAt) g.firstAt = r.created_at;
    if (r.created_at > g.lastAt) g.lastAt = r.created_at;
  }
  return [...byOwner.values()].filter((g) => g.keys.length > 1 && g.unackedIds.length > 0);
}

/**
 * Condition 2. Hard deletes under an account that still exists.
 *
 * 🔴 THE ONLY LEGITIMATE HARD DELETE IS THE ACCOUNT-DELETION CASCADE. Everything
 * the application does is a soft delete, which is recoverable. A row that left
 * the table while its owner is still here left it some other way, and "some
 * other way" is the entire subject of this script.
 *
 * ⚠ Unlike condition 1, an acked row is simply gone from this one, and that is
 * correct rather than inconsistent: there is no GROUP here, so there is no
 * context to preserve. One row, one judgement, and a human has made it.
 *
 * 🔴 THE CI ACCOUNT IS NOT EXCLUDED HERE, AND THAT IS THE WHOLE POINT OF SPLITTING
 * THE EXCLUSION. The smoke suite deletes through the API, which SOFT deletes. A
 * hard delete under that account is therefore not the suite: it is something
 * reaching the table by a path the application does not use, which is exactly
 * what this condition exists to catch, whoever the row belongs to. MEASURED
 * 2026-11-25: zero hard_delete rows in the window, so keeping it in scope costs
 * no noise today and keeps the signal that mattered during the CC_0468 deploy
 * window. Excluding the account wholesale would have thrown that away.
 */
export function findOrphanHardDeletes(rows) {
  return rows.filter((r) => r.op === 'hard_delete' && r.owner_exists && !r.acked);
}

/* ------------------------------------------------------------------ the live half ---- */

/**
 * ⚠ `created_at` is normalised to an ISO string at this boundary and nowhere
 * else. pg hands back Date objects; the finders compare timestamps and print
 * them, and a mixed bag of Dates and strings compares in two different ways.
 * One conversion, here, where the rows enter.
 */
async function readRemovals(client) {
  const { rows } = await client.query(REMOVALS_SQL, [String(ALERT_WINDOW_DAYS), CI_OWNER_ID]);
  return rows.map((r) => ({
    id: r.id,
    owner_id: r.owner_id,
    lens_key: r.lens_key,
    op: r.op,
    created_at: r.created_at instanceof Date ? r.created_at.toISOString() : String(r.created_at),
    owner_exists: r.owner_exists === true,
    owner_is_ci: r.owner_is_ci === true,
    acked: r.acked === true,
  }));
}

/**
 * Read the window and apply both conditions. `red` is the whole verdict.
 *
 * `unacked` is kept separate from `rows` because they answer different questions:
 * `rows` is what the conditions are computed over, `unacked` is what `--ack` is
 * allowed to act on and what the summary line counts.
 */
async function evaluate(client) {
  const rows = await readRemovals(client);
  const unacked = rows.filter((r) => !r.acked);
  const multi = findMultiDeleteOwners(rows);
  const orphans = findOrphanHardDeletes(rows);
  // Counted and printed rather than dropped quietly: an exclusion nobody can see
  // in the output is one nobody re-examines when it stops being appropriate.
  const ciRows = rows.filter((r) => r.owner_is_ci);
  return { rows, unacked, ciRows, multi, orphans, red: multi.length > 0 || orphans.length > 0 };
}

/**
 * ⚠ A uuid PREFIX, for anything the selftest prints. Borrowing a real owner id is
 * correct and necessary (see selftest step 2), but echoing it whole to stdout is
 * avoidable — and selftest output gets pasted into commit messages, which is
 * forever. Eight hex characters prove the id was real and concrete without
 * putting a production user id in git.
 *
 * Real findings print the id in full, deliberately: the operator has to act on it.
 */
const shortId = (id) => String(id).slice(0, 8) + '…';

/** The verbatim line an operator runs to clear a finding. Printed, never guessed at. */
function ackLine(ids) {
  return 'npm run check:lens-durability:ack --prefix backend -- ' +
    ids.join(' ') + ' --note "what happened"';
}

/**
 * 🔴 EVERY FAILURE NAMES THE OWNER, THE KEYS, THE TIMES AND THE IDS TO ACK.
 * "What did we lose, and whose was it" has to be answered BY the failure
 * message. The morning this fires, the person reading it has a backup with
 * seven days of retention and a decision to make; sending them off to write
 * their own query first is how a day gets lost.
 */
function report(found) {
  const { rows, unacked, ciRows, multi, orphans } = found;

  console.log(
    'lens durability — ' + rows.length + ' removal event(s) in the last ' + ALERT_WINDOW_DAYS +
      ' days, ' + unacked.length + ' unacknowledged',
  );

  if (ciRows.length) {
    console.log(
      '   ' + ciRows.length + ' of those are the CI account (' + shortId(CI_OWNER_ID) +
        '), excluded from the multi-delete condition but NOT from the hard-delete one',
    );
  }

  if (multi.length) {
    console.error('\n🔴 FAIL ' + multi.length + ' owner(s) lost MORE THAN ONE lens inside the window:');
    for (const g of multi) {
      const alreadyAcked = g.ids.length - g.unackedIds.length;
      console.error('     owner ' + g.ownerId);
      console.error('       lenses: ' + g.keys.join(', '));
      console.error('       between ' + g.firstAt + ' and ' + g.lastAt);
      console.error('       history ids: ' + g.ids.join(' ') +
        (alreadyAcked ? '   (' + alreadyAcked + ' already acknowledged, shown as context)' : ''));
      console.error('       recover from: SELECT before FROM inform.compass_user_lens_history WHERE id IN (' +
        g.ids.map((i) => "'" + i + "'").join(', ') + ');');
      console.error('       ack when reviewed: ' + ackLine(g.unackedIds));
    }
    console.error('     One person deleting one lens is tidying up. One person losing two is the');
    console.error('     2026-11-22 shape. Check the `before` snapshots BEFORE the backup ages out.');
    console.error('     An already-acknowledged removal still COUNTS toward the group and is listed');
    console.error('     above: a deletion somebody waved through last week is the context that makes');
    console.error('     this week\'s look alarming. Only the unacked ids are on the ack line.');
  } else {
    console.log('✅ no owner lost more than one lens in the window');
  }

  if (orphans.length) {
    console.error('\n🔴 FAIL ' + orphans.length + ' lens row(s) were HARD deleted while the owner still exists:');
    for (const r of orphans) {
      console.error('     owner ' + r.owner_id + ' lens ' + r.lens_key + ' at ' + r.created_at);
      console.error('       history id: ' + r.id);
    }
    console.error('     The only sanctioned hard delete is the account-deletion cascade, and these');
    console.error('     accounts are still here. Something reached the table outside the application.');
    console.error('     ack when reviewed: ' + ackLine(orphans.map((r) => r.id)));
  } else {
    console.log('✅ no hard deletes under a live account');
  }
}

/* ----------------------------------------------------------------------- --ack ---- */

/**
 * Split the argv tail after `--ack` into ids and a note. Pure and exported so the
 * unit tests can prove the note SURVIVES, which is the one thing that matters.
 *
 * 🔴 BOTH SPELLINGS OF --note, AND AN UNRECOGNISED FLAG STOPS THE COMMAND. An
 * earlier version matched only the space-separated form. `--note=why` fell
 * through a generic "skip anything starting with --" branch, the ack was still
 * written, and the operator was told "acked 1" with no hint that the reason they
 * had typed was gone. The entire value of an acknowledgement is the name and the
 * reason attached to it, so losing the reason silently is not a cosmetic bug —
 * and a flag this does not understand now refuses the whole command rather than
 * being quietly dropped the same way.
 */
export function parseAckArgs(tail) {
  const ids = [];
  let note = null;
  for (let k = 0; k < tail.length; k++) {
    const a = tail[k];
    if (a === '--note') {
      // 🔴 A TRAILING --note, OR --note FOLLOWED BY ANOTHER FLAG, IS THE --note=
      // BUG IN FURTHER SPELLINGS. A bare trailing --note left note null and the
      // ack was written with no reason; `--note --force` swallowed the next flag
      // as the note text. Both lose the reason silently.
      const v = tail[k + 1];
      if (v === undefined || v.startsWith('--')) {
        return { ids: [], note: null, error: '--note was given with no text.' };
      }
      note = v;
      k++;
      continue;
    }
    if (a.startsWith('--note=')) { note = a.slice('--note='.length); continue; }
    if (a.startsWith('--')) {
      return {
        ids: [],
        note: null,
        error: 'unrecognised flag ' + a + '. The only flag --ack takes is --note "<why>" (or --note=<why>).',
      };
    }
    ids.push(a);
  }
  if (note !== null && note.trim() === '') {
    return { ids: [], note: null, error: '--note was given with no text.' };
  }
  return { ids, note, error: null };
}

/**
 * Acknowledge removal rows so they stop holding the check red.
 *
 * ⚠ AN ALERT THAT CANNOT BE ACKNOWLEDGED BECOMES AN ALERT THAT IS IGNORED, which
 * is why this path exists at all. Without it, one ordinary deletion keeps the
 * nightly red for seven mornings, and by the third nobody reads it.
 *
 * 🔴 AN ID THAT IS NOT AN UNACKED REMOVAL IN THE WINDOW IS REFUSED, NOT INSERTED.
 * A typo'd uuid that quietly becomes a row would acknowledge nothing while
 * looking exactly like acknowledging something — the operator walks away
 * satisfied and the check stays red for reasons they now believe they handled.
 */
async function ack(client) {
  const parsed = parseAckArgs(argv.slice(argv.indexOf('--ack') + 1));
  const { note, error } = parsed;
  // De-duplicated: ON CONFLICT DO NOTHING absorbs a repeated id, so counting the
  // raw list reported "acked 1 of 2" and printed the same row twice.
  const ids = [...new Set(parsed.ids)];
  if (error) {
    console.error('🔴 refusing to ack: ' + error);
    console.error('   Nothing was written. No ids were acked.');
    return 1;
  }
  if (!ids.length) {
    console.error('🔴 --ack needs at least one history id. ' + ackLine(['<history-id>']));
    return 1;
  }

  // acked_by is the git identity, not an env var and not a flag: an ack is a
  // person saying "I looked at this", and it is worth nothing without a name on it.
  let who;
  try {
    who = execFileSync('git', ['config', 'user.email'], { encoding: 'utf8' }).trim();
  } catch {
    who = '';
  }
  if (!who) {
    console.error('🔴 refusing to ack: `git config user.email` is empty.');
    console.error('   An acknowledgement with nobody attached records that somebody looked,');
    console.error('   which is the one thing it exists to prove. Set it and run this again.');
    return 1;
  }

  // ⚠ `unacked`, not `rows`. Since the query started returning acked rows too,
  // validating against `rows` would quietly accept a re-ack of something already
  // acknowledged — an ON CONFLICT no-op reported as a successful ack.
  const found = await evaluate(client);
  const live = new Set(found.unacked.map((r) => r.id));
  const bogus = ids.filter((id) => !live.has(id));
  if (bogus.length) {
    console.error('🔴 refusing to ack ' + bogus.length + ' id(s) that are not unacknowledged removals in the window:');
    for (const id of bogus) console.error('     ' + id);
    console.error('   Either the id is wrong, it is already acked, or it has aged past ' +
      ALERT_WINDOW_DAYS + ' days.');
    console.error('   Nothing was written. No ids were acked.');
    return 1;
  }

  const { rowCount } = await client.query(
    'INSERT INTO inform.compass_lens_alert_acks (history_id, acked_by, note) ' +
      'SELECT id, $2, $3 FROM unnest($1::uuid[]) AS t(id) ' +
      'ON CONFLICT (history_id) DO NOTHING',
    [ids, who, note],
  );

  console.log('acked ' + rowCount + ' of ' + ids.length + ' removal event(s) as ' + who +
    (note ? ' — ' + note : ''));
  for (const id of ids) {
    const r = found.unacked.find((x) => x.id === id);
    console.log('     ' + id + '  ' + r.op + '  owner ' + r.owner_id + '  lens ' + r.lens_key +
      '  ' + r.created_at);
  }
  console.log('These no longer hold the nightly red. The history rows themselves are untouched.');
  return 0;
}

/* ------------------------------------------------------------------- --selftest ---- */

/**
 * Plant removals, watch the check go red, ack them, watch it go green, ROLLBACK,
 * and prove the rollback took.
 *
 * 🔴 THE ANTI-GOAL IN THE DESIGN DOC IS A TRIPWIRE THAT GOES GREEN WHILE LENSES
 * VANISH. Observing this check green proves nothing on its own — a check with a
 * typo'd table name is green too, forever, and reassuringly. The only evidence
 * that it is watching anything is watching it go red on demand.
 *
 * 🔴🔴 THIS RUNS AGAINST PRODUCTION AND IT MUST NEVER TOUCH
 * `inform.compass_user_lenses`. That table carries a live SECURITY DEFINER
 * trigger: inserting or deleting a lens there writes real history rows and
 * changes a real person's data. So the plants go DIRECTLY into
 * inform.compass_user_lens_history, which is safe to write for exactly the
 * reason the migration gives for its shape — owner_id has no FK, so nothing is
 * referenced, nothing cascades, and the planted rows are inert.
 *
 * ⚠ Everything is inside ONE explicit transaction that ends in ROLLBACK, and the
 * rollback is ASSERTED afterwards rather than assumed. A rollback that silently
 * did not happen would leave fabricated destruction records in the one table
 * whose entire job is to be believed.
 *
 * ⚠ The live-lens count is read before and after as a belt-and-braces: if this
 * ever starts touching real lenses, that number moves and the selftest says so.
 */
/**
 * The selftest's own ack writer: a direct INSERT, deliberately NOT a call into
 * the `--ack` CLI path. Routing the selftest through argv parsing couples two
 * things that fail independently, and then neither failure is legible.
 */
async function ackRows(client, ids) {
  const { rowCount } = await client.query(
    'INSERT INTO inform.compass_lens_alert_acks (history_id, acked_by, note) ' +
      "SELECT id, 'selftest', 'planted by --selftest, rolled back' FROM unnest($1::uuid[]) AS t(id) " +
      'ON CONFLICT (history_id) DO NOTHING',
    [ids],
  );
  return rowCount;
}

async function selftest(pool) {
  const client = await pool.connect();
  const results = [];
  const plantedIds = [];
  try {
    // ── 1. The baseline must be GREEN. ──────────────────────────────────────
    // A tamper proves nothing against an already-red baseline: the check would
    // report red afterwards whether or not the plant did anything at all.
    const baseline = await evaluate(client);
    if (baseline.red) {
      console.error('🔴 SELFTEST ABORTED — the live check is ALREADY RED.');
      console.error('   A tamper against a red baseline proves nothing: the "after" reading would');
      console.error('   be red either way. Deal with the real finding first, then run this again.');
      report(baseline);
      return 1;
    }
    console.log('baseline: GREEN (' + baseline.rows.length + ' removal(s) in the window, ' +
      baseline.unacked.length + ' unacknowledged)');

    const lensesBefore = Number(
      (await client.query('SELECT count(*)::int AS n FROM inform.compass_user_lenses')).rows[0].n,
    );

    // ── 2. One real owner id, read-only. ────────────────────────────────────
    // A real id, not a made-up uuid, because condition 1 and condition 2 BOTH
    // turn on the join to public.users finding the owner. A fabricated owner_id
    // would be filtered out as "account gone" and both tampers would read green
    // for the wrong reason — the exact false negative this is here to rule out.
    const owner = (await client.query('SELECT id::text FROM public.users ORDER BY id LIMIT 1')).rows[0];
    if (!owner) throw new Error('SELFTEST: public.users is empty; there is no owner to plant against.');

    await client.query('BEGIN');

    // ── 3. Tamper one: two soft deletes, two different keys, one owner. ─────
    const soft = await client.query(
      'INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before) ' +
        "VALUES ($1, 'zz-selftest-throwaway-a', 'soft_delete', '{\"selftest\":true}'::jsonb), " +
        "       ($1, 'zz-selftest-throwaway-b', 'soft_delete', '{\"selftest\":true}'::jsonb) " +
        'RETURNING id::text',
      [owner.id],
    );
    if (soft.rowCount !== 2) throw new Error('SELFTEST: the soft_delete plant did not apply.');
    plantedIds.push(...soft.rows.map((r) => r.id));

    const afterSoft = await evaluate(client);
    const multiHit = afterSoft.multi.find((g) => g.ownerId === owner.id);
    results.push({
      condition: 'MULTI_DELETE',
      tamper: 'two soft_delete rows, two keys, owner ' + shortId(owner.id),
      red: Boolean(multiHit && multiHit.keys.length === 2),
    });

    // ── 4. Tamper two: a hard delete under an owner who is still here. ──────
    const hard = await client.query(
      'INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before) ' +
        "VALUES ($1, 'zz-selftest-throwaway-c', 'hard_delete', '{\"selftest\":true}'::jsonb) " +
        'RETURNING id::text',
      [owner.id],
    );
    if (hard.rowCount !== 1) throw new Error('SELFTEST: the hard_delete plant did not apply.');
    plantedIds.push(hard.rows[0].id);

    const afterHard = await evaluate(client);
    results.push({
      condition: 'ORPHAN_HARD_DELETE',
      tamper: 'one hard_delete row under a live account, owner ' + shortId(owner.id),
      red: afterHard.orphans.some((r) => r.id === hard.rows[0].id),
    });

    // ── 5. And the composed check, which is what CI actually reads. ─────────
    results.push({
      condition: 'THE CHECK ITSELF',
      tamper: 'all three planted rows present',
      red: afterHard.red,
    });

    // ── 6a. PARTIAL ack: condition 1 must STILL fire. ──────────────────────
    // 🔴 THIS IS THE INTERESTING CASE, NOT AN INCIDENTAL ONE, AND IT IS BUILT TO
    // BE THE MONDAY/THURSDAY SHAPE EXACTLY. Acknowledgement governs what ALERTS,
    // never what is COUNTED. Every planted row but ONE is acknowledged here, so
    // under the earlier version of the query — which filtered acked rows out —
    // the finder would have been handed a single row with a single distinct key
    // and would have reported GREEN, while this owner lost three lenses inside
    // the window. It must stay RED on one unacked row out of three.
    //
    // It also demonstrates the deliberate asymmetry between the two conditions:
    // the acked hard_delete DOES drop out of condition 2, because a lone row
    // carries no group and so no context worth preserving.
    const plantedSoftIds = soft.rows.map((r) => r.id);
    const leftUnacked = plantedSoftIds[1];
    const ackedEarly = plantedIds.filter((id) => id !== leftUnacked);
    if (ackedEarly.length !== 2) throw new Error('SELFTEST: expected 2 ids to pre-ack.');
    await ackRows(client, ackedEarly);

    const afterPartial = await evaluate(client);
    const partialHit = afterPartial.multi.find((g) => g.ownerId === owner.id);
    results.push({
      condition: 'MULTI_DELETE survives a PARTIAL ack',
      tamper: '2 of the 3 planted removals acknowledged, 1 left unacked',
      red: Boolean(
        partialHit &&
          // All three keys still named, all three ids still listed as context...
          partialHit.keys.length === 3 &&
          partialHit.ids.length === 3 &&
          // ...but only the one unacked id is offered to the ack command.
          partialHit.unackedIds.length === 1 &&
          partialHit.unackedIds[0] === leftUnacked &&
          // And the acked hard_delete is gone from condition 2.
          afterPartial.orphans.length === 0,
      ),
    });

    // ── 6b. FULL ack: now, and only now, it goes green. ────────────────────
    // A direct INSERT, deliberately NOT a call into the --ack CLI path: routing
    // the selftest through argv parsing couples two things that fail
    // independently, and then neither failure is legible.
    const stillUnacked = [leftUnacked];
    const acked = await ackRows(client, stillUnacked);
    if (acked !== stillUnacked.length) {
      throw new Error('SELFTEST: expected to ack ' + stillUnacked.length + ' rows, acked ' + acked + '.');
    }
    const afterAck = await evaluate(client);
    const ackWorked = !afterAck.red;

    // ── 7. ROLLBACK, then PROVE it. ─────────────────────────────────────────
    await client.query('ROLLBACK');

    const survivors = await client.query(
      'SELECT count(*)::int AS n FROM inform.compass_user_lens_history WHERE id = ANY($1::uuid[])',
      [plantedIds],
    );
    const ackSurvivors = await client.query(
      'SELECT count(*)::int AS n FROM inform.compass_lens_alert_acks WHERE history_id = ANY($1::uuid[])',
      [plantedIds],
    );
    if (Number(survivors.rows[0].n) !== 0 || Number(ackSurvivors.rows[0].n) !== 0) {
      console.error('🔴🔴 SELFTEST: ROLLBACK DID NOT REVERT THE PLANTED ROWS.');
      console.error('   ' + survivors.rows[0].n + ' history row(s) and ' + ackSurvivors.rows[0].n +
        ' ack row(s) survived, in PRODUCTION. These are fabricated destruction records in the');
      console.error('   one table whose job is to be believed. Delete them by id and investigate:');
      for (const id of plantedIds) console.error('     ' + id);
      return 1;
    }

    const lensesAfter = Number(
      (await client.query('SELECT count(*)::int AS n FROM inform.compass_user_lenses')).rows[0].n,
    );
    if (lensesAfter !== lensesBefore) {
      console.error('🔴🔴 SELFTEST: the live lens count moved from ' + lensesBefore + ' to ' + lensesAfter + '.');
      console.error('   This selftest must never touch inform.compass_user_lenses. Investigate now.');
      return 1;
    }

    // ── report ──────────────────────────────────────────────────────────────
    console.log('\nSELFTEST — rows planted in inform.compass_user_lens_history only, then rolled back:\n');
    for (const r of results) {
      console.log('  ' + (r.red ? 'RED (correct)   ' : 'GREEN (BROKEN)  ') + r.condition + ': ' + r.tamper);
    }
    console.log('  ' + (ackWorked ? 'GREEN (correct) ' : 'RED (BROKEN)    ') +
      'ACK: green only once EVERY planted id is acknowledged');
    console.log('\n  ROLLBACK verified: 0 of ' + plantedIds.length +
      ' planted history rows and 0 ack rows survived.');
    console.log('  inform.compass_user_lenses untouched: ' + lensesBefore + ' row(s) before and after.');

    const blind = results.filter((r) => !r.red);
    if (blind.length || !ackWorked) {
      console.error('\n🔴 FAIL: the check is not watching what it claims to watch.');
      if (blind.length) {
        console.error('   ' + blind.length + ' condition(s) stayed GREEN against planted removals.');
      }
      if (!ackWorked) console.error('   The ack path did not clear the finding.');
      return 1;
    }
    console.log('\nEvery condition went red against planted removals, green again once acked,');
    console.log('and the rollback left production exactly as it was found.');
    return 0;
  } catch (err) {
    // ⚠ Never leave the transaction open on an unexpected throw. The planted rows
    // are fabricated destruction records; they must not outlive this function.
    try { await client.query('ROLLBACK'); } catch { /* already rolled back or dead */ }
    throw err;
  } finally {
    client.release();
  }
}

/* ------------------------------------------------------------------------ main ---- */

async function main() {
  if (!process.env.DATABASE_URL) {
    if (ALLOW_SKIP) {
      console.log('lens durability SKIPPED — no DATABASE_URL, and --allow-skip was passed. NOTHING WAS MEASURED. This is not a pass.');
      return 0;
    }
    console.error('🔴 lens durability FAILED — no DATABASE_URL. A tripwire that never runs reads healthy forever. Use --allow-skip locally.');
    return 1;
  }

  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  try {
    if (SELFTEST) return await selftest(pool);

    const client = await pool.connect();
    try {
      if (ACK) return await ack(client);

      const found = await evaluate(client);
      report(found);
      if (found.red) {
        console.error('\n🔴 lens durability FAILED. Somebody lost lenses and nobody has said they looked.');
        console.error('   Backups are daily with 7-day retention and PITR is off, so the `before`');
        console.error('   snapshots above and the backup are the whole recovery surface. Act today.');
        return 1;
      }
      console.log('\nlens durability OK');
      return 0;
    } finally {
      client.release();
    }
  } finally {
    await pool.end();
  }
}

// ⚠ ONLY WHEN RUN AS A SCRIPT. The two finders above are imported by
// check-lens-durability.test.ts, and a bare `process.exit(await main())` fires on
// that import — which means the unit tests, whose whole claim is that they need no
// database, open a connection to production and then kill the test runner.
const invokedDirectly =
  process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedDirectly) {
  main()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
