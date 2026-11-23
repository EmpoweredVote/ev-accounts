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
 * A nightly that reads the history table sees lenses disappearing however they
 * disappear — a new endpoint, a hand-run UPDATE, a migration with a bad WHERE,
 * an ORM doing something clever. It does not need to know what the next hole is.
 *
 * WHAT IS CHECKED — two conditions, both failures, no baseline:
 *
 *   1. MULTI-DELETE. One owner removed MORE THAN ONE DISTINCT lens inside the
 *      window. One person deleting one lens is somebody tidying up. One person
 *      losing two is the 2026-11-22 shape, and that is the shape the whole
 *      incident had.
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
 * One row per removal event in the window that nobody has acknowledged.
 *
 * ⚠ The ack is a NOT EXISTS and not a LEFT JOIN with an IS NULL: same answer,
 * and it cannot be accidentally weakened later by a join that fans rows out and
 * turns one deletion into two.
 *
 * ⚠ The interval is built from a parameter rather than interpolated, so the
 * window constant above is the only place the number lives.
 */
const REMOVALS_SQL = `
  SELECT h.id::text, h.owner_id::text, h.lens_key, h.op, h.created_at,
         (u.id IS NOT NULL) AS owner_exists
    FROM inform.compass_user_lens_history h
    LEFT JOIN public.users u ON u.id = h.owner_id
   WHERE h.op IN ('soft_delete', 'hard_delete')
     AND h.created_at >= now() - ($1 || ' days')::interval
     AND NOT EXISTS (
       SELECT 1 FROM inform.compass_lens_alert_acks a WHERE a.history_id = h.id)
   ORDER BY h.owner_id, h.created_at`;

/* ------------------------------------------------------------- the judgement ---- */
/* Pure, exported, and unit-tested in check-lens-durability.test.ts. The SQL above
 * is exercised by --selftest. Keeping the decision out of the query is what makes
 * "does this fire on the 2026-11-22 shape" answerable without a database.        */

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
 * `ids` carries EVERY removal row for the owner, including the purge half of a
 * soft-then-hard pair, because those are the ids an operator has to ack to clear
 * the alert. Acking only the distinct keys would leave the check red.
 */
export function findMultiDeleteOwners(rows) {
  const byOwner = new Map();
  for (const r of rows) {
    if (!r.owner_exists) continue;
    let g = byOwner.get(r.owner_id);
    if (!g) {
      g = { ownerId: r.owner_id, keys: [], ids: [], firstAt: r.created_at, lastAt: r.created_at };
      byOwner.set(r.owner_id, g);
    }
    if (!g.keys.includes(r.lens_key)) g.keys.push(r.lens_key);
    g.ids.push(r.id);
    // The query orders by created_at, but the finder must not depend on it: a
    // caller feeding it rows from anywhere else still gets a true span.
    if (r.created_at < g.firstAt) g.firstAt = r.created_at;
    if (r.created_at > g.lastAt) g.lastAt = r.created_at;
  }
  return [...byOwner.values()].filter((g) => g.keys.length > 1);
}

/**
 * Condition 2. Hard deletes under an account that still exists.
 *
 * 🔴 THE ONLY LEGITIMATE HARD DELETE IS THE ACCOUNT-DELETION CASCADE. Everything
 * the application does is a soft delete, which is recoverable. A row that left
 * the table while its owner is still here left it some other way, and "some
 * other way" is the entire subject of this script.
 */
export function findOrphanHardDeletes(rows) {
  return rows.filter((r) => r.op === 'hard_delete' && r.owner_exists);
}

/* ------------------------------------------------------------------ the live half ---- */

/**
 * ⚠ `created_at` is normalised to an ISO string at this boundary and nowhere
 * else. pg hands back Date objects; the finders compare timestamps and print
 * them, and a mixed bag of Dates and strings compares in two different ways.
 * One conversion, here, where the rows enter.
 */
async function readRemovals(client) {
  const { rows } = await client.query(REMOVALS_SQL, [String(ALERT_WINDOW_DAYS)]);
  return rows.map((r) => ({
    id: r.id,
    owner_id: r.owner_id,
    lens_key: r.lens_key,
    op: r.op,
    created_at: r.created_at instanceof Date ? r.created_at.toISOString() : String(r.created_at),
    owner_exists: r.owner_exists === true,
  }));
}

/** Read the window and apply both conditions. `red` is the whole verdict. */
async function evaluate(client) {
  const rows = await readRemovals(client);
  const multi = findMultiDeleteOwners(rows);
  const orphans = findOrphanHardDeletes(rows);
  return { rows, multi, orphans, red: multi.length > 0 || orphans.length > 0 };
}

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
  const { rows, multi, orphans } = found;

  console.log(
    'lens durability — ' + rows.length + ' unacknowledged removal event(s) in the last ' +
      ALERT_WINDOW_DAYS + ' days',
  );

  if (multi.length) {
    console.error('\n🔴 FAIL ' + multi.length + ' owner(s) lost MORE THAN ONE lens inside the window:');
    for (const g of multi) {
      console.error('     owner ' + g.ownerId);
      console.error('       lenses: ' + g.keys.join(', '));
      console.error('       between ' + g.firstAt + ' and ' + g.lastAt);
      console.error('       history ids: ' + g.ids.join(' '));
      console.error('       recover from: SELECT before FROM inform.compass_user_lens_history WHERE id IN (' +
        g.ids.map((i) => "'" + i + "'").join(', ') + ');');
      console.error('       ack when reviewed: ' + ackLine(g.ids));
    }
    console.error('     One person deleting one lens is tidying up. One person losing two is the');
    console.error('     2026-11-22 shape. Check the `before` snapshots BEFORE the backup ages out.');
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
  const i = argv.indexOf('--ack');
  const noteIdx = argv.indexOf('--note');
  const tail = argv.slice(i + 1);
  const ids = [];
  for (let k = 0; k < tail.length; k++) {
    const a = tail[k];
    if (a === '--note') { k++; continue; }
    if (a.startsWith('--')) continue;
    ids.push(a);
  }
  const note = noteIdx >= 0 ? argv[noteIdx + 1] ?? null : null;

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

  const found = await evaluate(client);
  const live = new Set(found.rows.map((r) => r.id));
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
    const r = found.rows.find((x) => x.id === id);
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
    console.log('baseline: GREEN (' + baseline.rows.length + ' unacked removal(s) in the window)');

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
      tamper: 'two soft_delete rows, two keys, owner ' + owner.id,
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
      tamper: 'one hard_delete row under a live account, owner ' + owner.id,
      red: afterHard.orphans.some((r) => r.id === hard.rows[0].id),
    });

    // ── 5. And the composed check, which is what CI actually reads. ─────────
    results.push({
      condition: 'THE CHECK ITSELF',
      tamper: 'all three planted rows present',
      red: afterHard.red,
    });

    // ── 6. The ack path. This is its ONLY proof. ────────────────────────────
    // A direct INSERT, deliberately NOT a call into the --ack CLI path: routing
    // the selftest through argv parsing couples two things that fail
    // independently, and then neither failure is legible.
    const acked = await client.query(
      'INSERT INTO inform.compass_lens_alert_acks (history_id, acked_by, note) ' +
        "SELECT id, 'selftest', 'planted by --selftest, rolled back' FROM unnest($1::uuid[]) AS t(id) " +
        'ON CONFLICT (history_id) DO NOTHING',
      [plantedIds],
    );
    if (acked.rowCount !== plantedIds.length) {
      throw new Error('SELFTEST: expected to ack ' + plantedIds.length + ' rows, acked ' + acked.rowCount + '.');
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
      'ACK: all three planted ids acknowledged');
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
