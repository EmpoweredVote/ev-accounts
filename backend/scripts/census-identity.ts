/**
 * census-identity.ts — tie roll-call names to roster politicians for a Stage 0 census (no database).
 *
 *   npm run census:identity --prefix backend -- --rollcalls <abs json> --sessions <abs json> \
 *        --roster <abs tsv> --out <abs json>
 *
 * --rollcalls: an array of roll calls, or {"rollcalls": [...]}, each {instrument_id, state ('US' for
 *   Congress), chamber, date, motion, yea_names, nay_names, other_names}.
 * --sessions: the official member list per chamber and session, an array or {"lists": [...]}, each
 *   {state, chamber, session, source_url, members: [{full_name}]}. Chamber text such as "House of
 *   Delegates" is normalised.
 * --roster: TSV with header id, full_name, first_name, last_name, state, level, chamber, term_start
 *   (from essentials, read-only; only id, full_name, state and level are required).
 * --out: per-member results (lib/identityMatch.ts grades); refuses an existing file.
 * Prints one tally line per roll call. Rules and grades: lib/identityMatch.ts. Paths must be absolute
 * (npm runs this from backend/). A flag with no value is an error.
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { isAbsolute } from 'node:path';
import { CliFlagError, flag as readFlag } from './lib/cliEnv.js';
import { identifyRollCalls, normChamber, parseRosterTsv, type RollCall, type SessionList } from './lib/identityMatch.js';

const flag = (name: string) => readFlag(process.argv, name);
const USAGE = 'usage: census-identity --rollcalls <abs json> --sessions <abs json> --roster <abs tsv> --out <abs json>';

function absolute(name: string): string {
  const v = flag(name);
  if (!v) throw new CliFlagError(USAGE);
  if (!isAbsolute(v)) throw new CliFlagError(`${name} must be an absolute path (npm runs this from backend/): ${v}`);
  return v;
}

function arrayOf<T>(file: string, key: string): T[] {
  const j = JSON.parse(readFileSync(file, 'utf8'));
  const a = Array.isArray(j) ? j : j?.[key];
  if (!Array.isArray(a)) throw new Error(`${file}: expected an array or {"${key}": [...]}`);
  return a as T[];
}

function main(): number {
  const rollcallsFile = absolute('--rollcalls');
  const sessionsFile = absolute('--sessions');
  const rosterFile = absolute('--roster');
  const out = absolute('--out');
  if (existsSync(out)) throw new Error(`--out ${out} already exists; refusing to overwrite it`);

  const rollCalls = arrayOf<RollCall & { chamber: string }>(rollcallsFile, 'rollcalls').map((rc, i) => {
    const chamber = normChamber(rc.chamber);
    if (!chamber) throw new Error(`${rollcallsFile}: roll call ${i + 1} has chamber ${JSON.stringify(rc.chamber)}`);
    return { ...rc, chamber };
  });
  const lists = arrayOf<SessionList & { chamber: string }>(sessionsFile, 'lists').map((L, i) => {
    const chamber = normChamber(L.chamber);
    if (!chamber) throw new Error(`${sessionsFile}: list ${i + 1} has chamber ${JSON.stringify(L.chamber)}`);
    return { ...L, state: L.state.toUpperCase(), chamber };
  });
  const roster = parseRosterTsv(readFileSync(rosterFile, 'utf8'), rosterFile);

  const results = identifyRollCalls(rollCalls, lists, roster);
  writeFileSync(out, JSON.stringify(results, null, 1) + '\n', { flag: 'wx' });
  for (const r of results) console.log(`${r.instrument_id}  ${r.chamber}  ${r.date}  ${r.motion.slice(0, 28)}  ${JSON.stringify(r.tally)}`);
  console.error(`wrote ${results.length} roll call(s) to ${out}`);
  return 0;
}

try {
  process.exitCode = main();
} catch (e) {
  console.error(e instanceof CliFlagError ? e.message : (e as Error).message);
  process.exitCode = 1;
}
