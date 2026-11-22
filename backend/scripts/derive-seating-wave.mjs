#!/usr/bin/env node
/**
 * Derive one seating wave's pin block, and name whatever is blocking the body.
 *
 *   node scripts/derive-seating-wave.mjs --state wi --type STATE_LOWER --type STATE_UPPER \
 *                                        --type STATE_EXEC [--election 2026-11-03] [--slot CC_0461]
 *   node scripts/derive-seating-wave.mjs --type NATIONAL_UPPER --type NATIONAL_LOWER   # every state
 *
 * Logic and the digest contract: scripts/lib/seating-wave.mjs (pure, tested).
 * Control: the JS digest is compared against SELECTION_DIGEST_SQL run in Postgres over the same
 * selection — see the plan's Task 1 step 8. A test cannot prove two engines agree.
 *
 * 🔴 THIS REPORTS. IT NEVER REFUSES AND IT NEVER WRITES. Exit 0 whatever it finds, so a blocked
 *    body shows ALL of its blockers in one run rather than one per round trip. The migration is
 *    what refuses, and the four numbers printed here are what it refuses without.
 *
 * 🔴 NO DATABASE_URL -> SKIP, exit 0, and SAY SO, the same way check-seating-invariants.mjs does.
 *    A script that skips silently is the shape of a detector that has quietly stopped working.
 */
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import pg from 'pg';
import dotenv from 'dotenv';
import { WAVE_SELECTION_SQL, classifyWave, pinBlockSql } from './lib/seating-wave.mjs';

dotenv.config({ path: path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '.env') });
dotenv.config();

const DEFAULT_ELECTION = '2026-11-03';

/** `--type` repeats; `--state` may be omitted for a nationwide district type. */
export function parseArgs(argv) {
  const out = { state: null, types: [], election: DEFAULT_ELECTION, slot: null, json: false };
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (a === '--json') out.json = true;
    else if (a === '--state') out.state = String(argv[++i]).toLowerCase();
    else if (a === '--type') out.types.push(String(argv[++i]).toUpperCase());
    else if (a === '--election') out.election = String(argv[++i]);
    else if (a === '--slot') out.slot = String(argv[++i]);
    else throw new Error(`unknown argument ${a}`);
  }
  if (out.types.length === 0) {
    throw new Error('at least one --type is required (e.g. --type STATE_LOWER)');
  }
  return out;
}

export async function deriveWave(client, { state, types, election }) {
  const { rows } = await client.query(WAVE_SELECTION_SQL, [state, types, election]);
  return { rows, summary: classifyWave(rows) };
}

function report(args, rows, s) {
  const where = `${args.state ? args.state.toUpperCase() : 'every state'} · ${args.types.join(', ')}`;
  console.log(`\n${where} · election ${args.election}\n`);
  console.log(`  winner rows        ${s.rows}`);
  console.log(`  offices            ${new Set(rows.map((r) => r.office_id)).size}`);
  console.log(`  re-elections       ${s.reelections}`);
  console.log(`  new holders        ${s.newHolders}`);
  console.log(`  term start         ${s.termStart ?? '— (no single date; see blockers)'}`);
  console.log(`  called / certified ${s.called} / ${s.certified}`);
  console.log(`  digest             ${s.digest}`);

  if (s.blockers.length === 0) {
    console.log('\n  blockers           none — this body is ready to seat.\n');
  } else {
    const byKind = new Map();
    for (const b of s.blockers) byKind.set(b.kind, [...(byKind.get(b.kind) ?? []), b]);
    console.log(`\n  blockers           ${s.blockers.length} across ${byKind.size} kind(s)\n`);
    for (const [kind, list] of byKind) {
      console.log(`  ── ${kind} (${list.length})`);
      for (const b of list.slice(0, 12)) console.log(`     ${b.detail}`);
      if (list.length > 12) console.log(`     … and ${list.length - 12} more`);
      console.log('');
    }
  }

  if (s.termStart) {
    console.log('  Pin block — paste into the migration, with the date you captured it:\n');
    console.log(
      pinBlockSql(args.slot ?? 'CC_XXXX', s)
        .split('\n')
        .map((l) => `    ${l}`)
        .join('\n'),
    );
    console.log('');
  }
}

const invokedDirectly = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (invokedDirectly) {
  const args = parseArgs(process.argv.slice(2));

  if (!process.env.DATABASE_URL) {
    console.log(
      'SKIPPED: DATABASE_URL is not set, so no wave could be derived. Forks get no secrets; ' +
        'this is a deliberate green skip, not an empty wave.',
    );
    process.exit(0);
  }

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  try {
    await client.connect();
    const { rows, summary } = await deriveWave(client, args);
    if (args.json) console.log(JSON.stringify({ args, summary }, null, 2));
    else report(args, rows, summary);
  } finally {
    await client.end();
  }
}
