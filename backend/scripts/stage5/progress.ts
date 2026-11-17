/**
 * progress — which states a topic's Stage 5 has written, and which are left. Read-only.
 *
 *   npx tsx --env-file=.env scripts/stage5/progress.ts --topic <key> --roster <stage5>/roster.tsv
 *       [--batches <stage5>/batches] [--ds <stage5>/legiscan/ds] [--out <progress.md>] [--level state]
 *
 * Why: the only record of "which state is done" was a person's memory and a folder of hand-offs. The answer is in
 * the database: `inform.topic_research_outcomes` holds one row per person the topic's Stage 5 wrote in the draft
 * season. This counts those rows against the topic's own roster, state by state.
 *
 * Per state it prints the roster's sitting people at --level (scope `sitting` or `both`; a candidate-only row is not
 * counted), how many of them have an outcome, the outcomes by kind, review rows still pending, and a status:
 *   done         the state was run and nothing waits: with --batches, at least 9 in 10 ids of `<xx>-ids.txt` (the run's own scope)
 *                have an outcome (the table shows the rest: people held or left out); without it, at least 2 in 3 of the sitting people do. No review row is pending.
 *   to approve   as done, but review rows are still pending (written, not yet approved)
 *   part         some are written, fewer than that (a batch was held or split, or people joined the scope)
 *   not started  none is written
 *   no roster    fewer than 20 sitting people on the roster: the legislature is not on it, so there is nothing to run yet
 * 🔴 "done" is a count, not a judgment: a run drops people who lost or are leaving, and may hold some. Read the numbers.
 * The run's scope is the better measure, which is why --batches is worth passing: a roster keeps everyone who sat.
 * It also says what the next run would read: a legislature profile on file (`data/legislatures/xx.json`), and with
 * --ds whether bill data is on disk and where it came from (LegiScan, or Open States by its `.openstates.json`).
 *
 * Blind check: no roster row at --level, or a topic with no outcome at all in the draft season, gives no verdict
 * (exit 2): a list of 50 states all "not started" is what a wrong topic key or a wrong season looks like.
 */
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../../src/lib/db.js';
import { draftSeasonId, flag, topicId } from './batch-db.js';
import { statusOf, type StateCount, type Status } from '../lib/stage5Progress.js';

const BACKEND = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

let rosterPath = '', level = 'state', ds = '', out = '', batches = '', topic = '';

function readRoster(path: string) {
  const [head, ...lines] = readFileSync(path, 'utf8').split('\n').filter((l) => l.trim());
  const cols = head.split('\t');
  const at = (name: string) => { const i = cols.indexOf(name); if (i < 0) throw new Error(`${path}: no ${name} column`); return i; };
  const [id, lv, st, sc] = [at('politician_id'), at('level'), at('state'), at('scope')];
  return lines.map((l) => l.split('\t')).map((r) => ({ id: r[id], level: r[lv], state: (r[st] || '').toUpperCase(), scope: r[sc] || 'sitting' }));
}

function dataOnDisk(st: string): string {
  if (!ds || !existsSync(ds)) return '';
  const dirs = readdirSync(ds).filter((d) => d.startsWith(`${st}-`));
  if (!dirs.length) return 'none';
  return dirs.some((d) => existsSync(join(ds, d, '.openstates.json'))) ? `Open States (${dirs.length})` : `LegiScan (${dirs.length})`;
}

async function main() {
  const usage = 'progress.ts --topic <key> --roster <roster.tsv> [--batches <dir>] [--ds <legiscan ds dir>] [--out <progress.md>] [--level state]';
  topic = flag('--topic', usage); rosterPath = flag('--roster', usage); level = flag('--level', usage, 'state');
  ds = flag('--ds', usage, ''); out = flag('--out', usage, ''); batches = flag('--batches', usage, '');
  const rows = readRoster(rosterPath).filter((r) => r.level === level && r.scope !== 'candidate');
  if (!rows.length) { console.error(`progress: NO VERDICT. ${rosterPath} has no sitting row at level ${level}.`); return 2; }
  const tid = await topicId(topic);
  const sid = await draftSeasonId();
  const written = await pool.query<{ politician_id: string; outcome: string }>(
    'SELECT politician_id, outcome FROM inform.topic_research_outcomes WHERE topic_id = $1 AND season_id = $2', [tid, sid]);
  if (!written.rows.length) { console.error(`progress: NO VERDICT. No outcome for "${topic}" in the draft season: a wrong topic key, or a season that is no longer the draft.`); return 2; }
  const pending = await pool.query<{ politician_id: string }>(
    "SELECT DISTINCT politician_id FROM inform.stance_research_review WHERE topic_key = $1 AND season_id = $2 AND status = 'pending'", [topic, sid]);
  const outcome = new Map(written.rows.map((r) => [r.politician_id, r.outcome]));
  const wait = new Set(pending.rows.map((r) => r.politician_id));
  const by = new Map<string, StateCount>();
  for (const r of rows) {
    const c = by.get(r.state) ?? { state: r.state, sitting: 0, written: 0, outcomes: {}, pending: 0 };
    c.sitting++;
    const o = outcome.get(r.id);
    if (o) { c.written++; c.outcomes[o] = (c.outcomes[o] ?? 0) + 1; }
    if (wait.has(r.id)) c.pending++;
    by.set(r.state, c);
  }
  if (batches) {
    for (const c of by.values()) {
      const f = join(batches, `${c.state.toLowerCase()}-ids.txt`);
      if (!existsSync(f)) continue;
      const ids = readFileSync(f, 'utf8').split(/\s+/).filter(Boolean);
      c.scope = ids.length; c.scopeWritten = ids.filter((p) => outcome.has(p)).length;
    }
  }
  const onRoster = new Set(rows.map((r) => r.id));
  const offRoster = written.rows.filter((r) => !onRoster.has(r.politician_id)).length;
  const order: Status[] = ['to approve', 'part', 'not started', 'done', 'no roster'];
  const all = [...by.values()].sort((a, b) => order.indexOf(statusOf(a)) - order.indexOf(statusOf(b)) || b.sitting - a.sitting);
  const n = (s: Status) => all.filter((c) => statusOf(c) === s).length;
  const L = [`# ${topic}: Stage 5 progress by ${level}`, '',
    `Read ${new Date().toISOString().slice(0, 16)}Z from the draft season and \`${rosterPath}\`. Read-only.`, '',
    `**${n('done')} done, ${n('to approve')} to approve, ${n('part')} part, ${n('not started')} not started, ${n('no roster')} with no legislature on the roster** (of ${all.length}). ` +
    `${written.rows.length} people written in all; ${offRoster} of them are not sitting ${level}-level people on this roster (another level, or candidates).`, '',
    `| ${level} | status | run scope: written of listed | sitting on roster | written | seated | doesn't fit | no stance | review pending | profile | bill data on disk |`, '|---|---|---|---|---|---|---|---|---|---|---|'];
  for (const c of all) {
    const xx = c.state.toLowerCase();
    L.push(`| ${c.state || '?'} | ${statusOf(c)} | ${c.scope === undefined ? '' : `${c.scopeWritten} of ${c.scope}${c.scopeWritten! < c.scope ? ` (${c.scope - c.scopeWritten!} not written)` : ''}`} | ${c.sitting} | ${c.written} | ${c.outcomes.seated ?? 0} | ${c.outcomes['doesnt-fit'] ?? 0} | ${c.outcomes['no-stance'] ?? 0} | ${c.pending} | ` +
      `${existsSync(join(BACKEND, 'data', 'legislatures', `${xx}.json`)) ? 'yes' : 'no'} | ${dataOnDisk(c.state)} |`);
  }
  L.push('', '"done" is a count: at least 9 in 10 of the people the run listed have an outcome (or, where no run list is on file, 2 in 3 of the roster\'s sitting people) and no review row is pending. A run drops people who lost or are leaving, and may hold some. "no roster": fewer than 20 sitting people, so the legislature is not on the roster yet.');
  const text = L.join('\n') + '\n';
  if (out) writeFileSync(out, text);
  console.log(text + (out ? `written to ${out}\n` : ''));
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().then(async (code) => { await pool.end(); process.exit(code); }).catch(async (e) => { console.error(e); await pool.end(); process.exit(1); });
}
