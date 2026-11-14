/**
 * record-script.ts — Stage 5 record-only pass by rule, with an Opus lane and a standing check
 * (round three, adjustment 1; lib/stage5RecordRule.ts holds the rule and its replay numbers).
 *
 *   npx tsx scripts/stage5/record-script.ts plan --config <stage5>/coder-config.json --rulings <stage5>/coder-rulings.md \
 *     --roster <tsv> --ids <ids file> --unit state:xx --bill-table <stage5>/bill-table-xx.json --sides 1,2,3/4,5 \
 *     --name xx-rec --out <stage5>/record-briefs-xx [--check 10] [--skip-rungs 5,2] [--seed <text>] [--store <dir>]
 *   npx tsx scripts/stage5/record-script.ts adopt --out <stage5>/record-briefs-xx --name xx-rec --codes <stage5>/record-codes
 *
 * plan   Decides each person with a record. A PLAIN case gets a script-made code in <out>/script-codes/ (a holding
 *        folder: nothing downstream reads it). Everyone else is listed for Opus with the reason:
 *          <name>-lanes.tsv        every person: script or opus, and why
 *          <name>-opus-ids.txt     the Opus lane
 *          <name>-check-ids.txt    the standing check: a seeded random --check (default 10) of the script's people,
 *                                  half of them seats at --skip-rungs (the seats the pilot rule never searches)
 *          <name>-coder-ids.txt    both lists together: run coder-inputs.ts --record-only --bill-table on THIS file,
 *                                  one wave, as usual. The coders are not told which people are the check.
 *          <name>-script.findings.json   what the script read, for `search_list.py recode`
 *          <name>-script-summary.json    counts for the measures table
 *        Every script-made code passes the same `checkAtIngest` as a coder's (bills named, quotes found in the
 *        bill's text, no labels) plus the party sweep. A code that fails is not fixed: the person goes to Opus.
 * adopt  The standing check. Compares each check person's Opus code in --codes with the script's code. Any
 *        difference in outcome or rung: exit 4, both codes printed, NOTHING released; show the runner. All agree:
 *        every other script code is stamped `script_check` and copied into --codes, never over an existing file.
 *        The check people keep their Opus code. Exit 3 while a check person has no Opus code yet.
 *
 * What the script may decide: a seat at the furthest rung when every counted Yes act sits on one side of the
 * ladder, and a No-votes-only blank. What it never decides is in LANE_WORDS (lib/stage5RecordRule.ts).
 * `checkCode` refuses a script-made code with no `script_check`, at ingest, in the report and at write time.
 */
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { collapseBatch, collapsedRoundTripProblems, expandCollapsed, onTopic, type RosterRow } from '../lib/stage5CoderInputs.js';
import { NEEDS_STANDING_CHECK, SCRIPT_CODER, type Stage5Code } from '../lib/stage5Code.js';
import { checkAtIngest, finalizeCode, rungTextsFromLadder } from '../lib/stage5Ingest.js';
import { LANE_WORDS, decideRecord, namedInRulings, rulingsNameText, seededSample, standingCheckDifferences, unitSections, wordsFor, type Lane, type RuleBill, type RuleBillRow } from '../lib/stage5RecordRule.js';
import type { PersonFindings } from '../lib/sourceStore.js';
import { STORE, instrumentIndex, instrumentTexts, parseArgs, readConfig, readPersonFindings, readRosters } from './coder-io.js';
import { sweepHit } from './lib.js';

const USAGE = 'record-script.ts plan --config <json> --rulings <md> --roster <tsv> --ids <file> --unit state:xx --bill-table <json> --sides 1,2,3/4,5 --name <prefix> --out <dir> [--check 10] [--skip-rungs 5,2] [--seed <text>] [--store <dir>]\n'
  + '       record-script.ts adopt --out <dir> --name <prefix> --codes <dir>';

interface Summary {
  unit: string; name: string; people: number; no_record: number; script: number; opus: number;
  script_seats: Record<string, number>; script_blanks: number; lanes: Record<string, number>;
  text_refused: number; check_ids: string[]; seed: string; planned_at: string;
  check?: { compared: number; agreed: number; passed: boolean; at: string; differences: string[] };
}

function plan(flags: Map<string, string[]>): number {
  const one = (k: string, dflt?: string) => {
    const v = flags.get(k)?.[0] ?? dflt;
    if (v === undefined) throw new Error(`--${k} is required\n${USAGE}`);
    return v;
  };
  const config = readConfig(one('config'));
  const unit = one('unit'); const name = one('name'); const out = one('out'); const store = one('store', STORE);
  const sides = one('sides').split('/').map((s) => s.split(',').map(Number)) as [number[], number[]];
  if (sides.length !== 2 || sides.flat().some((n) => !Number.isInteger(n))) throw new Error('--sides is two rung lists, e.g. 1,2,3/4,5');
  const nCheck = Number(one('check', '10'));
  const skipRungs = new Set(one('skip-rungs', '').split(',').filter(Boolean).map(Number));
  const rosters = readRosters((flags.get('roster') ?? []).flatMap((r) => r.split(',')));
  const listed = readFileSync(one('ids'), 'utf8').split(/\s+/).filter(Boolean);
  const off = listed.filter((p) => !rosters.has(p));
  if (off.length) throw new Error(`not on any roster: ${off.join(', ')}`);
  const table = (JSON.parse(readFileSync(one('bill-table'), 'utf8')) as { bills: Record<string, RuleBillRow> }).bills;
  const prefix = unit === 'federal' ? 'US-' : `${unit.replace(/^state:/, '').toUpperCase()}-`;
  const section = rulingsNameText(unitSections(readFileSync(one('rulings'), 'utf8'), unit), table, prefix);
  const seed = one('seed', `${name}|${config.topic_key}|${config.season}`);
  const index = instrumentIndex(store);
  const billCache = new Map<string, RuleBill | undefined>();
  const bill = (id: string): RuleBill | undefined => {
    if (!billCache.has(id)) {
      const rel = index.get(id);
      if (!rel) billCache.set(id, undefined);
      else {
        const j = JSON.parse(readFileSync(join(store, 'instruments', rel), 'utf8')) as { votes?: { yes: number; no: number }[]; single_subject?: { season: number; verdict: string }[] };
        billCache.set(id, {
          inStore: true,
          multi: (j.single_subject ?? []).some((s) => s.season === config.season && s.verdict === 'multi'),
          tallies: (j.votes ?? []).map((v) => ({ yes: v.yes, no: v.no })),
        });
      }
    }
    return billCache.get(id);
  };
  const rungTexts = rungTextsFromLadder(config.ladder_text);
  const rungText = (r: number) => new RegExp(`^\\s*${r}\\.\\s+(.+?)\\s*$`, 'm').exec(config.ladder_text)?.[1];
  const kinds = new Set(['record'] as const);

  const holding = join(out, 'script-codes');
  mkdirSync(out, { recursive: true });
  rmSync(holding, { recursive: true, force: true });
  mkdirSync(holding, { recursive: true });
  const rows: { pid: string; name: string; by: 'script' | 'opus' | 'none'; result: string; why: string }[] = [];
  const scriptPeople: { row: RosterRow; pf: PersonFindings | undefined }[] = [];
  const seats = new Map<string, number>();
  const laneCount: Record<string, number> = {};
  let textRefused = 0;
  const now = new Date();
  for (const pid of listed) {
    const row = rosters.get(pid)!;
    const pf = readPersonFindings(store, pid);
    if (!onTopic(pf, config.topic_key, kinds).length) { rows.push({ pid, name: row.full_name, by: 'none', result: '', why: LANE_WORDS['no-record'] }); continue; }
    const person = [{ row, pf }];
    const c = collapseBatch(person, config.topic_key, config.season, (id) => index.get(id), table, kinds);
    const problems = collapsedRoundTripProblems(person, c, config.topic_key, config.season, kinds);
    if (problems.length) throw new Error(`${row.full_name}: the record does not rebuild from its lines (${problems[0]})`);
    const plainIds = new Set(c.people[0].record.flatMap((l) => l.on.map((r) => r[0])));
    const findings = expandCollapsed(c).get(pid)!.findings;
    const res = decideRecord({ findings, plainIds, table, bill, sides, billPrefix: prefix, office: row.office ?? '', named: namedInRulings(row.full_name, section) });
    const toOpus = (lanes: (Lane | 'text-check')[], detail = '') => {
      for (const l of lanes) laneCount[l] = (laneCount[l] ?? 0) + 1;
      rows.push({ pid, name: row.full_name, by: 'opus', result: '', why: lanes.map((l) => (l === 'text-check' ? `the script's text did not pass the coding checks${detail}` : LANE_WORDS[l])).join('; ') });
    };
    if (res.lanes.length || !res.decision) { toOpus(res.lanes); continue; }
    // The same checks a coder's code passes. The one problem allowed here is the standing check itself, still to come.
    const ctx = { instruments: instrumentTexts(store, index, pf!.findings.flatMap((f) => (f.instrument_id ? [f.instrument_id] : []))), rungTexts };
    let code: Stage5Code | undefined; let lastProblems: string[] = [];
    for (const withWhy of [true, false]) {
      const w = wordsFor(res.decision, table, rungText, withWhy);
      if (!w) { lastProblems = ['the deciding bill cannot be named or quoted']; break; }
      const entry = { politician_id: pid, outcome: res.decision.outcome, ...(res.decision.value !== undefined ? { value: res.decision.value } : {}), ...w };
      const cand = finalizeCode(entry, { ...config, coded_by: SCRIPT_CODER }, pf, now);
      lastProblems = checkAtIngest(cand, pf!, ctx).filter((p) => p !== NEEDS_STANDING_CHECK);
      if (sweepHit(`${cand.reasoning} ${cand.open_note ?? ''}`)) lastProblems.push('the text names a party');
      if (!lastProblems.length) { code = cand; break; }
    }
    if (!code) { textRefused++; toOpus(['text-check'], `: ${lastProblems[0]}`); continue; }
    writeFileSync(join(holding, `${pid}.json`), JSON.stringify(code, null, 2) + '\n');
    scriptPeople.push({ row, pf });
    if (code.outcome === 'seated') seats.set(pid, code.value!);
    rows.push({ pid, name: row.full_name, by: 'script', result: code.outcome === 'seated' ? `seated ${code.value}` : 'doesnt-fit nay-only', why: 'plain case' });
  }
  const script = rows.filter((r) => r.by === 'script').map((r) => r.pid);
  const opus = rows.filter((r) => r.by === 'opus').map((r) => r.pid);
  const check = seededSample(script, Math.min(nCheck, script.length), seed, new Set(script.filter((p) => skipRungs.has(seats.get(p) ?? -1))));
  const p = (f: string) => join(out, `${name}-${f}`);
  writeFileSync(p('lanes.tsv'), ['politician_id\tfull_name\tcoded_by\tscript_result\twhy', ...rows.map((r) => `${r.pid}\t${r.name}\t${r.by}\t${r.result}\t${r.why}`)].join('\n') + '\n');
  writeFileSync(p('opus-ids.txt'), opus.join('\n') + (opus.length ? '\n' : ''));
  writeFileSync(p('check-ids.txt'), check.join('\n') + (check.length ? '\n' : ''));
  writeFileSync(p('coder-ids.txt'), [...opus, ...check].sort().join('\n') + '\n');
  // What the script read, in the collapsed layout: `search_list.py recode` asks which findings each record-only code saw.
  const shown = scriptPeople.length ? collapseBatch(scriptPeople, config.topic_key, config.season, (id) => index.get(id), table, kinds) : undefined;
  writeFileSync(p('script.findings.json'), JSON.stringify(shown ?? { people: [] }) + '\n');
  const bySeat: Record<string, number> = {};
  for (const v of seats.values()) bySeat[String(v)] = (bySeat[String(v)] ?? 0) + 1;
  const summary: Summary = {
    unit, name, people: listed.length, no_record: rows.filter((r) => r.by === 'none').length, script: script.length, opus: opus.length,
    script_seats: bySeat, script_blanks: script.length - seats.size, lanes: laneCount, text_refused: textRefused, check_ids: check, seed, planned_at: now.toISOString(),
  };
  writeFileSync(p('script-summary.json'), JSON.stringify(summary, null, 1) + '\n');
  const withRecord = script.length + opus.length;
  console.log(`${unit}: ${listed.length} people, ${summary.no_record} with no record (search list, as before)`);
  console.log(`record pass: ${withRecord} people -> script ${script.length} (${withRecord ? Math.round((100 * script.length) / withRecord) : 0}%), Opus ${opus.length}`);
  console.log(`  script seats by rung: ${JSON.stringify(bySeat)}; No-votes-only blanks: ${summary.script_blanks}`);
  for (const [l, n] of Object.entries(laneCount).sort((a, b) => b[1] - a[1])) console.log(`  to Opus, ${n}: ${l === 'text-check' ? "the script's text did not pass the coding checks" : LANE_WORDS[l as Lane]}`);
  console.log(`standing check: ${check.length} of the script's people, seed "${seed}" (${p('check-ids.txt')})`);
  console.log(`next: coder-inputs.ts --record-only --bill-table … --ids ${p('coder-ids.txt')} (Opus lane ${opus.length} + check ${check.length}), split-codes.ts, then record-script.ts adopt`);
  if (script.length && !check.length) { console.error('no standing check is possible (--check 0): nothing can be adopted'); return 1; }
  return 0;
}

function adopt(flags: Map<string, string[]>): number {
  const one = (k: string) => { const v = flags.get(k)?.[0]; if (v === undefined) throw new Error(`--${k} is required\n${USAGE}`); return v; };
  const out = one('out'); const name = one('name'); const codes = one('codes');
  const sumPath = join(out, `${name}-script-summary.json`);
  const summary = JSON.parse(readFileSync(sumPath, 'utf8')) as Summary;
  const holding = join(out, 'script-codes');
  const read = (f: string) => JSON.parse(readFileSync(f, 'utf8')) as Stage5Code;
  const scriptIds = readdirSync(holding).filter((f) => f.endsWith('.json')).map((f) => f.slice(0, -5));
  if (!summary.check_ids.length) { console.error('the plan drew no standing check: nothing can be adopted'); return 1; }
  const waiting = summary.check_ids.filter((p) => !existsSync(join(codes, `${p}.json`)));
  if (waiting.length) { console.log(`${waiting.length} check person(s) have no Opus code in ${codes} yet, e.g. ${waiting[0]}: code them first`); return 3; }
  const differences = standingCheckDifferences(summary.check_ids,
    (pid) => (existsSync(join(holding, `${pid}.json`)) ? read(join(holding, `${pid}.json`)) : undefined), (pid) => read(join(codes, `${pid}.json`)));
  for (const d of differences) {
    const pid = d.split(':')[0];
    console.log(`\nDISAGREE ${d}`);
    if (existsSync(join(holding, `${pid}.json`))) console.log(`  script: ${read(join(holding, `${pid}.json`)).reasoning}\n  Opus:   ${read(join(codes, `${pid}.json`)).reasoning}`);
  }
  const at = new Date().toISOString();
  summary.check = { compared: summary.check_ids.length, agreed: summary.check_ids.length - differences.length, passed: !differences.length, at, differences };
  writeFileSync(sumPath, JSON.stringify(summary, null, 1) + '\n');
  if (differences.length) {
    console.log(`\nstanding check FAILED: ${differences.length} of ${summary.check_ids.length} differ. No script code was released.`);
    console.log('STOP and show the runner. Until the runner rules, code every script person with Opus (coder-inputs.ts --record-only on the lanes.tsv script ids).');
    return 4;
  }
  const stamp = `standing check passed ${at.slice(0, 10)}: ${summary.check_ids.length} of ${summary.check_ids.length} blind Opus codes agree (seed "${summary.seed}")`;
  mkdirSync(codes, { recursive: true });
  let done = 0; let left = 0;
  for (const pid of scriptIds) {
    if (summary.check_ids.includes(pid)) continue;
    const target = join(codes, `${pid}.json`);
    if (existsSync(target)) { left++; continue; }
    writeFileSync(target, JSON.stringify({ ...read(join(holding, `${pid}.json`)), script_check: stamp }, null, 2) + '\n');
    done++;
  }
  console.log(`standing check passed: ${summary.check_ids.length} of ${summary.check_ids.length} agree.`);
  console.log(`released ${done} script code(s) into ${codes}; ${left} already had a code and were left alone; the ${summary.check_ids.length} check people keep their Opus code`);
  return 0;
}

function main(): number {
  const { pos, flags } = parseArgs(process.argv.slice(2));
  if (pos[0] === 'plan') return plan(flags);
  if (pos[0] === 'adopt') return adopt(flags);
  console.error(USAGE);
  return 1;
}

process.exit(main());
