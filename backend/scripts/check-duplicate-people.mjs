#!/usr/bin/env node
/**
 * Gate: one person split across two ACTIVE essentials.politicians rows.
 *
 * WHY THIS EXISTS. A load that inserts a person without looking for the existing row makes a second
 * row, and nothing errors. The damage is silent and it compounds: the seat lands on one row, the
 * compass answers, quotes, FEC link and race rows on the other. Compass reads answers by
 * politician_id, so whichever row is later deactivated takes its data off the person's profile.
 * Every pair so far was found by accident: CA_0180, CA_0182, CA_0184, CA_0204, CA_0226, CA_0227,
 * CA_0229, CA_0234, CA_0261, CA_0270. This gate exists so the next one is found on the day it is made.
 *
 * WHAT IT PROPOSES (it never merges and never decides):
 *   NAME_STATE  two active rows whose name keys meet (scripts/lib/person-key.mjs: initials, suffixes,
 *               accents and nicknames folded) and whose state is the same. A row's state is its seat's
 *               state, else the state of its newest active race row. A row with no state at all is
 *               paired on name alone — it has nowhere else to be compared.
 *   SHARED_FEC  two active rows holding politician_sources links with one (source_system, external_id).
 *               An FEC candidate ID is one person, so this is the strongest signal; a name need not match.
 *
 * THE BASELINE IS A LIST OF REVIEWED PAIRS, NOT A COUNT. "Two different Mike Rogers" is a permanent fact,
 * and a count would let a new real pair hide behind a resolved one. Each pair in
 * data/duplicate-people-baseline.json carries a verdict:
 *   unreviewed       seen, not yet ruled on (the backlog — should only shrink)
 *   different_people ruled distinct; stays quiet for ever
 *   same_person      ruled one person; waiting for a merge migration
 * The gate FAILS on any pair not in the file. A pair in the file that no longer appears is reported as
 * resolved; --update-baseline drops it and keeps every other verdict and note untouched.
 *
 * 🔴 POSITIVE CONTROL. Before reporting, the run plants a synthetic pair shaped like the real Klein pair
 * (nickname + initial in last_name + same state) and one sharing an FEC id, and refuses to give a
 * verdict unless both are found. A detector that came back blind would otherwise print "0 new pairs".
 *
 * WHAT IT CANNOT SEE: a surname spelled two ways ("Barragán" / "Baragán"), a married-name change, a
 * pair where one row has no state and a different given name. It reads active rows only: two inactive
 * rows cannot hide anyone.
 *
 * Needs a live DB, so like check:stance-sources it runs on master pushes and on a schedule, and skips
 * itself when DATABASE_URL is absent.
 *
 * Usage (from backend/):
 *   node scripts/check-duplicate-people.mjs
 *   node scripts/check-duplicate-people.mjs --verbose          # list every pair, reviewed ones too
 *   node scripts/check-duplicate-people.mjs --update-baseline  # add new pairs as unreviewed, drop resolved
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';
import { findPairs, isSplit } from './lib/person-key.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const BASELINE = path.join(HERE, '..', 'data', 'duplicate-people-baseline.json');

const argv = process.argv.slice(2);
const VERBOSE = argv.includes('--verbose');
const UPDATE = argv.includes('--update-baseline');
const VERDICTS = new Set(['unreviewed', 'different_people', 'same_person']);

const QUERY = `
  SELECT p.id::text, p.full_name, p.first_name, p.last_name, p.preferred_name, p.alternate_names,
         lower(coalesce(seat.st, cand.st, '')) AS st,
         seat.st IS NOT NULL                   AS seated,
         (SELECT count(*)::int FROM inform.politician_answers a WHERE a.politician_id = p.id) AS answers,
         coalesce((SELECT array_agg(ps.source_system || ':' || ps.external_id ORDER BY ps.source_system, ps.external_id)
                     FROM transparent_motivations.politician_sources ps
                    WHERE ps.essentials_politician_id = p.id AND ps.source_system LIKE 'fec%'
                      AND coalesce(ps.external_id, '') <> ''), '{}') AS fec
    FROM essentials.politicians p
    -- LIMIT 1 lateral, not a join: one person can hold two seats, and a politician-rooted join on
    -- office_current_holder fans out (CLAUDE.md, "Officeholder occupancy").
    LEFT JOIN LATERAL (
      SELECT coalesce(nullif(d.state, ''), o.representing_state) AS st
        FROM essentials.office_current_holder och
        JOIN essentials.offices o ON o.id = och.office_id
        LEFT JOIN essentials.districts d ON d.id = o.district_id
       WHERE och.politician_id = p.id
       ORDER BY o.title LIMIT 1
    ) seat ON true
    LEFT JOIN LATERAL (
      SELECT e.state::text AS st
        FROM essentials.race_candidates rc
        JOIN essentials.races r ON r.id = rc.race_id
        JOIN essentials.elections e ON e.id = r.election_id
       WHERE rc.politician_id = p.id
       ORDER BY e.election_date DESC LIMIT 1
    ) cand ON true
   WHERE p.is_active`;

/** Plant a Klein-shaped name pair and an FEC-shaped pair; the run is blind unless both come back. */
function positiveControl(rows) {
  const ctl = [
    { id: '~ctl-a', first_name: 'Matthew', last_name: 'Q. Zzcontrol', st: 'zz', fec: [] },
    { id: '~ctl-b', first_name: 'Matt', last_name: 'Zzcontrol', st: 'zz', fec: [] },
    { id: '~ctl-c', first_name: 'Ann', last_name: 'Zzone', st: 'zy', fec: ['fec_house:H0ZZ00000'] },
    { id: '~ctl-d', first_name: 'Bea', last_name: 'Zztwo', st: 'zx', fec: ['fec_house:H0ZZ00000'] },
  ];
  const got = findPairs([...rows, ...ctl]);
  return got.get('~ctl-a|~ctl-b')?.why.has('NAME_STATE') && got.get('~ctl-c|~ctl-d')?.why.has('SHARED_FEC');
}

function describe(p) {
  const side = (r) => `${r.full_name} [${r.seated ? 'seated' : 'no seat'}, ${r.answers} answers${r.fec?.length ? `, ${r.fec.join(' ')}` : ''}]`;
  return `${[...p.why].join('+').padEnd(21)} ${(p.a.st || p.b.st || '-').padEnd(3)} ${side(p.a)}  ~  ${side(p.b)}`;
}

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(QUERY);
  await pool.end();

  if (rows.length < 1000 || !positiveControl(rows)) {
    console.error(`FAIL: the detector is blind (${rows.length} active rows read; planted control pairs not found). No verdict.`);
    process.exit(2);
  }

  const observed = findPairs(rows);

  let baseline = { pairs: {} };
  try {
    baseline = JSON.parse(readFileSync(BASELINE, 'utf8'));
  } catch {
    if (!UPDATE) {
      console.error(`FAIL: no baseline at ${path.relative(process.cwd(), BASELINE)}. Run with --update-baseline once, review it, commit it.`);
      process.exit(2);
    }
  }
  const base = baseline.pairs ?? {};
  for (const [k, v] of Object.entries(base)) {
    if (!VERDICTS.has(v.verdict)) {
      console.error(`FAIL: baseline pair ${k} has verdict "${v.verdict}"; expected one of ${[...VERDICTS].join(', ')}.`);
      process.exit(2);
    }
  }

  const fresh = [...observed.values()].filter((p) => !(p.key in base));
  const resolved = Object.keys(base).filter((k) => !observed.has(k));

  if (UPDATE) {
    const pairs = {};
    for (const p of [...observed.values()].sort((x, y) => x.key.localeCompare(y.key))) {
      const prev = base[p.key];
      pairs[p.key] = {
        names: `${p.a.full_name} ~ ${p.b.full_name}`,
        state: p.a.st || p.b.st || null,
        why: [...p.why].sort(),
        split: isSplit(p),
        verdict: prev?.verdict ?? 'unreviewed',
        ...(prev?.note ? { note: prev.note } : {}),
      };
    }
    const payload = {
      _comment:
        'Reviewed pairs for check-duplicate-people.mjs. The gate fails on any pair NOT listed here. Set verdict ' +
        'to different_people (quiet for ever) or same_person (needs a merge migration) and add a note naming the ' +
        'source you checked. "unreviewed" is the backlog and should only shrink. split = seat on one row, ' +
        'compass answers only on the other (voter-visible harm).',
      _updated: new Date().toISOString().slice(0, 10),
      pairs,
    };
    writeFileSync(BASELINE, `${JSON.stringify(payload, null, 2)}\n`);
    console.log(`baseline written: ${Object.keys(pairs).length} pairs (${fresh.length} added as unreviewed, ${resolved.length} resolved and dropped)`);
    process.exit(0);
  }

  const count = (v) => [...observed.keys()].filter((k) => base[k]?.verdict === v).length;
  const splits = [...observed.values()].filter(isSplit);
  console.log(`duplicate people — ${rows.length} active rows, ${observed.size} candidate pair(s); positive control found`);
  console.log(`  reviewed: ${count('different_people')} different people, ${count('same_person')} same person (merge owed), ${count('unreviewed')} unreviewed`);
  console.log(`  split pairs (seat on one row, answers only on the other): ${splits.length}`);
  if (resolved.length) console.log(`  ${resolved.length} baseline pair(s) no longer appear (merged or renamed) — drop them with --update-baseline`);

  if (VERBOSE) {
    console.log('\nall pairs:');
    for (const p of observed.values()) console.log(`  ${(base[p.key]?.verdict ?? 'NEW').padEnd(16)} ${describe(p)}`);
  }

  if (fresh.length === 0) {
    console.log('\nOK — no new pair of active rows looks like one person.');
    process.exit(0);
  }
  console.error(`\nFAIL — ${fresh.length} new candidate pair(s):\n`);
  for (const p of fresh) console.error(`  ${isSplit(p) ? '🔴 SPLIT ' : ''}${describe(p)}\n      ${p.key}`);
  console.error(
    '\nCheck each pair against an official source (legislature page, FEC, election office).\n' +
    '  Same person  -> merge it (pattern: CA_0227 / CA_0261), or list it as same_person until the merge lands.\n' +
    '  Different    -> run --update-baseline and set its verdict to different_people with a note.\n' +
    'Better still, fix the load that made the second row: look the person up before inserting.',
  );
  process.exit(1);
})();
