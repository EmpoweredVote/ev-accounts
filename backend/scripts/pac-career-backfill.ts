/**
 * pac-career-backfill.ts — one-time load of past cycles into the PAC-career tables (CA_0390–CA_0394).
 *
 * Reads through the cache PR #1532's scripts/pac-career/pac-career.ts built (PAC_CAREER_DIR, default
 * ~/Documents/GitHub/.fec-pac-career): its API replies are keyed the same way here, so a cached request costs
 * nothing. An uncached one goes through the shared FEC limiter (acquireFecSlot) at whatever pace the key allows.
 * Resumable: a committee-cycle already stored is skipped.
 *
 * Per person (every id that is not rejected), per cycle FEC's totals show PAC money or refunds in:
 *   1. FEC's processed Schedule A line 11C and Schedule B line 20C for each serving committee -> 'api' report.
 *   2. If those do not add up to FEC's totals for the cycle, or the cycle is the current one: the campaign's raw
 *      .fec reports from docquery -> 'efiling' reports. Stored only when every PAC-carrying report of the
 *      committee-cycle is readable, so a half-read cycle can never pass for a whole one.
 * Then: FEC committee codes for every giver, every cycle; and the verdicts.
 *
 * usage (from backend/):
 *   npx tsx scripts/pac-career-backfill.ts inferred            # add PR #1532's name+state matches as needs_review
 *   npx tsx scripts/pac-career-backfill.ts load [--route verify|ruled_out_corporate|all] [--limit N] [--only <politician_id>]
 *   npx tsx scripts/pac-career-backfill.ts kinds               # committee codes for every giver, 1980 on
 *   npx tsx scripts/pac-career-backfill.ts verdicts            # rebuild fec_pac_career
 *   npx tsx scripts/pac-career-backfill.ts compare             # every verdict against PR #1532's verify.json
 */
import 'dotenv/config';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import { fecGetJson } from '../src/lib/fecGetJson.js';
import { currentFecCycle } from '../src/lib/fecCycle.js';
import { parseFiling, reconciles } from '../src/lib/pacCareer.js';
import {
  computeAllCareers, cyclesFrom, FIRST_CYCLE, loadCommitteeKinds, rebuildCareers, storeApiCycle, storeFiling,
  storeTotals, syncLinkedIds, totalsPath, upsertCommittees, type ItemRow,
} from '../src/lib/pacCareerJob.js';

const WORK = process.env.PAC_CAREER_DIR ?? join(homedir(), 'Documents/GitHub/.fec-pac-career');
const API_CACHE = join(WORK, 'api');
const FILINGS = join(WORK, 'filings');
const TM = 'transparent_motivations';
const args = process.argv.slice(3);
const flag = (name: string) => { const i = args.indexOf(`--${name}`); return i >= 0 ? args[i + 1] : undefined; };
const CURRENT = Number(currentFecCycle());

let apiHits = 0; let apiCalls = 0; let filingHits = 0; let filingFetches = 0;

/** GET through PR #1532's cache: same key (sha1 of path + query in this exact order), same files. */
async function fecGet<T>(path: string, params: Record<string, string | string[]>): Promise<T> {
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) for (const x of [v].flat()) qs.append(k, x);
  const keyed = `${path}?${qs}`;
  const file = join(API_CACHE, createHash('sha1').update(keyed).digest('hex') + '.json');
  if (existsSync(file)) { apiHits++; return JSON.parse(readFileSync(file, 'utf8')) as T; }
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY is not set');
  apiCalls++;
  const body = await fecGetJson<T>(`https://api.open.fec.gov/v1${keyed}&api_key=${apiKey}`, path);
  mkdirSync(API_CACHE, { recursive: true });
  writeFileSync(file, JSON.stringify(body));
  return body;
}

interface Page<T> { results: T[]; pagination: { count?: number; last_indexes?: Record<string, string> | null } }
async function allRows<T>(path: string, params: Record<string, string>): Promise<T[]> {
  const rows: T[] = [];
  let extra: Record<string, string> = {};
  for (let i = 0; i < 500; i++) {
    const page = await fecGet<Page<T>>(path, { ...params, per_page: '100', ...extra });
    rows.push(...page.results);
    const li = page.pagination.last_indexes;
    if (!li || page.results.length < 100) break;
    extra = Object.fromEntries(Object.entries(li).map(([k, v]) => [k, String(v)]));
  }
  return rows;
}

/** A raw .fec filing's text, or null when FEC has no electronic file for it (paper or pre-2001). */
function filingText(fileNumber: number): string | null {
  if (!(fileNumber > 0)) return null;
  const cached = join(FILINGS, `${fileNumber}.fec`);
  if (existsSync(cached)) { filingHits++; return readFileSync(cached, 'latin1'); }
  // Not kept: the disk is nearly full, and a campaign's report can be tens of MB.
  const tmp = join(tmpdir(), `pac-career-${fileNumber}.fec`);
  filingFetches++;
  // curl, not fetch: docquery sits behind a WAF that scores Node's TLS fingerprint.
  const status = execFileSync('curl', ['-sS', '--max-time', '300', '-A', 'Mozilla/5.0', '-o', tmp, '-w', '%{http_code}',
    `https://docquery.fec.gov/dcdev/posted/${fileNumber}.fec`], { encoding: 'utf8' }).trim();
  try {
    if (status === '404') return null;
    if (status !== '200') throw new Error(`filing ${fileNumber} -> HTTP ${status}`);
    const text = readFileSync(tmp, 'latin1');
    return text.startsWith('HDR') ? text : null;
  } finally {
    if (existsSync(tmp)) unlinkSync(tmp);
  }
}

// ---------------------------------------------------------------------------------------------------------------
async function inferred(): Promise<void> {
  const screen = JSON.parse(readFileSync(join(WORK, 'screen.json'), 'utf8')) as {
    people: { pid: string; inferred_ids: { id: string; fec_name: string; office: string; state: string }[] }[] };
  let n = 0;
  for (const p of screen.people) {
    for (const x of p.inferred_ids) {
      const r = await pool.query(
        `INSERT INTO ${TM}.fec_candidate_ids (politician_id, fec_candidate_id, found_by, status, evidence)
         SELECT $1::uuid, $2, 'name_state_match', 'needs_review', $3
          WHERE EXISTS (SELECT 1 FROM essentials.politicians WHERE id = $1::uuid)
         ON CONFLICT (politician_id, fec_candidate_id) DO NOTHING`,
        [p.pid, x.id, `FEC candidate master: ${x.fec_name}, office ${x.office}, ${x.state} (PR #1532 screen, name + state)`]);
      n += r.rowCount ?? 0;
    }
  }
  console.log(`[backfill] inferred: ${n} needs_review id(s) added`);
}

interface TotalsRow { cycle: number; receipts: number | null; other_political_committee_contributions: number | null; refunded_other_political_committee_contributions: number | null; coverage_end_date: string | null }

async function loadPerson(pid: string, ids: string[]): Promise<{ cycles: number; api: number; efiling: number; unreadable: number }> {
  const stat = { cycles: 0, api: 0, efiling: 0, unreadable: 0 };
  const totals = new Map<number, { pac: number; refunds: number }>();
  const seen = new Set<string>();
  const committees = new Map<string, Set<number>>();
  for (const id of ids) {
    const t = await fecGet<Page<TotalsRow>>(totalsPath(id), { election_full: 'false', per_page: '100' });
    await storeTotals(id, t.results as never);
    for (const r of t.results) {
      if (typeof r.cycle !== 'number') continue;
      const sig = [r.cycle, r.receipts, r.other_political_committee_contributions, r.refunded_other_political_committee_contributions, r.coverage_end_date].join('|');
      if (seen.has(sig)) continue;
      seen.add(sig);
      const cur = totals.get(r.cycle) ?? { pac: 0, refunds: 0 };
      cur.pac += r.other_political_committee_contributions ?? 0;
      cur.refunds += r.refunded_other_political_committee_contributions ?? 0;
      totals.set(r.cycle, cur);
    }
    if (![...totals.values()].some((x) => x.pac !== 0 || x.refunds !== 0)) continue;
    const cm = await fecGet<Page<{ committee_id: string; designation: string; cycles: number[] }>>(
      `/candidate/${id}/committees/`, { designation: ['P', 'A'], per_page: '100' });
    const rows: { id: string; cycle: number; committeeId: string; designation: string }[] = [];
    for (const c of cm.results) {
      const s = committees.get(c.committee_id) ?? new Set<number>();
      for (const cy of c.cycles ?? []) { s.add(cy); if (cy % 2 === 0) rows.push({ id, cycle: cy, committeeId: c.committee_id, designation: c.designation === 'A' ? 'A' : 'P' }); }
      committees.set(c.committee_id, s);
    }
    await upsertCommittees(rows);
  }

  for (const [cycle, t] of [...totals].sort((a, b) => a[0] - b[0])) {
    if (t.pac === 0 && t.refunds === 0) continue;
    stat.cycles++;
    const cmtes = [...committees].filter(([, cys]) => !cys.size || cys.has(cycle)).map(([c]) => c);
    const stored = await pool.query<{ committee_id: string; source: string; i11: string; i20: string }>(
      `SELECT committee_id, source, line11c_itemized AS i11, line20c_itemized AS i20 FROM ${TM}.fec_pac_reports
        WHERE committee_id = ANY($1) AND cycle = $2`, [cmtes, cycle]);
    let api11 = 0; let api20 = 0;
    for (const cmte of cmtes) {
      const have = stored.rows.filter((r) => r.committee_id === cmte && r.source === 'api');
      if (have.length) { for (const r of have) { api11 += Number(r.i11); api20 += Number(r.i20); } continue; }
      const items: ItemRow[] = [];
      const a = await allRows<{ contribution_receipt_amount: number; memo_code: string | null; contributor_id: string | null; contributor_name: string | null }>(
        '/schedules/schedule_a/', { committee_id: cmte, two_year_transaction_period: String(cycle), line_number: 'F3-11C' });
      for (const r of a) if (r.memo_code !== 'X') items.push({ refund: false, amt: r.contribution_receipt_amount ?? 0, id: r.contributor_id, name: r.contributor_name });
      const b = await allRows<{ disbursement_amount: number; memo_code: string | null; recipient_committee_id: string | null; recipient_name: string | null }>(
        '/schedules/schedule_b/', { committee_id: cmte, two_year_transaction_period: String(cycle), line_number: 'F3-20C' });
      for (const r of b) if (r.memo_code !== 'X') items.push({ refund: true, amt: r.disbursement_amount ?? 0, id: r.recipient_committee_id, name: r.recipient_name });
      await storeApiCycle(cmte, cycle, items);
      if (items.length) stat.api++;
      api11 += items.filter((x) => !x.refund).reduce((s, x) => s + x.amt, 0);
      api20 += items.filter((x) => x.refund).reduce((s, x) => s + x.amt, 0);
    }
    const apiOk = reconciles(api11, t.pac) && reconciles(api20, t.refunds);
    if (apiOk && cycle !== CURRENT) continue;

    for (const cmte of cmtes) {
      if (cycle !== CURRENT && stored.rows.some((r) => r.committee_id === cmte && r.source === 'efiling')) continue;
      const reports = await allRows<{ file_number: number; most_recent: boolean; other_political_committee_contributions_period: number | null; refunded_other_political_committee_contributions_period: number | null }>(
        `/committee/${cmte}/reports/`, { cycle: String(cycle), most_recent: 'true' });
      const parsed = [];
      let readable = true;
      for (const r of reports) {
        if (!r.most_recent) continue;
        if (!r.other_political_committee_contributions_period && !r.refunded_other_political_committee_contributions_period) continue;
        const text = filingText(r.file_number);
        const p = text === null ? null : parseFiling(text);
        if (!p || p.committeeId !== cmte) { readable = false; break; }
        parsed.push({ p, file: r.file_number });
      }
      if (!readable) { stat.unreadable++; continue; }
      for (const { p, file } of parsed) { await storeFiling(p, file); stat.efiling++; }
    }
  }
  return stat;
}

async function load(): Promise<void> {
  const route = flag('route') ?? 'all';
  const only = flag('only');
  const limit = Number(flag('limit') ?? Infinity);
  const linked = await syncLinkedIds();
  console.log(`[backfill] linked ids synced (+${linked.added}/-${linked.removed})`);
  const ids = (await pool.query<{ pid: string; id: string }>(
    `SELECT politician_id::text AS pid, fec_candidate_id AS id FROM ${TM}.fec_candidate_ids WHERE status <> 'rejected' ORDER BY 1, 2`)).rows;
  const people = new Map<string, string[]>();
  for (const r of ids) people.set(r.pid, [...(people.get(r.pid) ?? []), r.id]);
  // Order: the people PR #1532 already verified first (their API replies are cached), then the rest.
  const screenPath = join(WORK, 'screen.json');
  const routeOf = new Map<string, string>();
  if (existsSync(screenPath)) for (const p of (JSON.parse(readFileSync(screenPath, 'utf8')) as { people: { pid: string; route: string }[] }).people) routeOf.set(p.pid, p.route);
  // Progress lives beside the cache: a person is done only once every cycle of theirs has been stored.
  const donePath = join(WORK, 'backfill-done.json');
  const done = new Set<string>(existsSync(donePath) ? JSON.parse(readFileSync(donePath, 'utf8')) as string[] : []);
  const queue = [...people].filter(([pid]) => (only ? pid === only : route === 'all' || (routeOf.get(pid) ?? 'verify') === route))
    .sort(([a], [b]) => (routeOf.get(a) === 'verify' ? 0 : 1) - (routeOf.get(b) === 'verify' ? 0 : 1));
  console.log(`[backfill] ${queue.length} people queued (route=${route}); ${done.size} already done`);
  let n = 0;
  const t0 = Date.now();
  for (const [pid, pids] of queue) {
    if (n >= limit) break;
    if (!only && done.has(pid) && !args.includes('--redo')) continue;
    try {
      const s = await loadPerson(pid, pids);
      n++;
      done.add(pid);
      writeFileSync(donePath, JSON.stringify([...done]));
      console.log(`[backfill] ${n} ${pid} ids=${pids.join(',')} pac-cycles=${s.cycles} api=${s.api} efiling=${s.efiling} unreadable=${s.unreadable} ` +
        `| api cached ${apiHits} new ${apiCalls}, filings cached ${filingHits} fetched ${filingFetches}, ${Math.round((Date.now() - t0) / 1000)}s`);
    } catch (e) {
      console.error(`[backfill] ${pid} FAILED: ${(e as Error).message}`);
    }
  }
}

async function kinds(): Promise<void> {
  const givers = new Set((await pool.query<{ id: string }>(`SELECT DISTINCT giver_id AS id FROM ${TM}.fec_pac_gifts WHERE giver_id IS NOT NULL`)).rows.map((r) => r.id));
  const { rows, names } = await loadCommitteeKinds(cyclesFrom(FIRST_CYCLE, CURRENT), givers);
  console.log(`[backfill] codes: ${givers.size} givers, ${rows} (committee, cycle) rows`);
  // Give an id to each no-id gift whose name exactly one committee carries in that cycle.
  const nameless = (await pool.query<{ committee_id: string; report_key: string; giver_key: string; giver_name: string | null; cycle: number; received: string; refunded: string; n_gifts: number }>(
    `SELECT g.committee_id, g.report_key, g.giver_key, g.giver_name, r.cycle, g.received, g.refunded, g.n_gifts
       FROM ${TM}.fec_pac_gifts g JOIN ${TM}.fec_pac_reports r USING (committee_id, report_key)
      WHERE g.giver_id IS NULL`)).rows;
  let resolved = 0;
  const newIds = new Set<string>();
  for (const g of nameless) {
    const ids = names.get(Number(g.cycle))?.get((g.giver_key).slice(5));
    if (!ids || ids.size !== 1) continue;
    const id = [...ids][0]!;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`DELETE FROM ${TM}.fec_pac_gifts WHERE committee_id = $1 AND report_key = $2 AND giver_key = $3`, [g.committee_id, g.report_key, g.giver_key]);
      await client.query(
        `INSERT INTO ${TM}.fec_pac_gifts (committee_id, report_key, giver_key, giver_id, giver_id_from, giver_name, received, refunded, n_gifts)
         VALUES ($1, $2, $3, $3, 'name_match', $4, $5, $6, $7)
         ON CONFLICT (committee_id, report_key, giver_key) DO UPDATE SET
           received = ${TM}.fec_pac_gifts.received + EXCLUDED.received, refunded = ${TM}.fec_pac_gifts.refunded + EXCLUDED.refunded,
           n_gifts = ${TM}.fec_pac_gifts.n_gifts + EXCLUDED.n_gifts`,
        [g.committee_id, g.report_key, id, g.giver_name, g.received, g.refunded, g.n_gifts]);
      await client.query('COMMIT');
    } catch (e) { await client.query('ROLLBACK'); throw e; } finally { client.release(); }
    resolved++;
    if (!givers.has(id)) newIds.add(id);
  }
  if (newIds.size) await loadCommitteeKinds(cyclesFrom(FIRST_CYCLE, CURRENT), newIds);
  console.log(`[backfill] no-id gifts: ${nameless.length}, given an id by exact name: ${resolved} (${newIds.size} new giver(s) coded)`);
}

async function verdicts(): Promise<void> {
  console.log(`[backfill] verdicts: ${JSON.stringify(await rebuildCareers())}`);
}

/**
 * Every verdict against PR #1532's verify.json. Its corporate bucket is C and W only;
 * its verify.json already keeps trade (T) and coop (V) apart, so both sides are read under the 2026-11-18 rules.
 */
async function compare(): Promise<void> {
  const ver = JSON.parse(readFileSync(join(WORK, 'verify.json'), 'utf8')) as Record<string, {
    kept?: Record<string, number>; unreconciled?: number[]; career?: { receipts: number }; error?: string }>;
  const ours = new Map((await computeAllCareers()).map((r) => [r.politicianId, r]));
  const old = (v: (typeof ver)[string]) => {
    if (v.error) return 'unverified';
    if ((v.career?.receipts ?? 0) <= 0) return 'no_receipts';
    if ((v.kept?.corporate ?? 0) > 0) return 'takes_corporate';
    if ((v.unreconciled?.length ?? 0) > 0 || (v.kept?.unknown ?? 0) > 0) return 'unverified';
    const pac = (v.kept?.other_pac ?? 0) + (v.kept?.trade ?? 0) + (v.kept?.coop ?? 0);
    return pac > 0 ? 'no_corporate_pac' : 'no_pac';
  };
  // verify.json already keeps trade and coop apart from corporate, so both sides use the 2026-11-18 rules as they are.
  const mine = (r: NonNullable<ReturnType<typeof ours.get>>) => r.verdict;
  const tally = new Map<string, number>();
  const diffs: string[] = [];
  for (const [pid, v] of Object.entries(ver)) {
    const r = ours.get(pid);
    const a = old(v);
    const b = r ? mine(r) : 'missing';
    const k = a === b ? 'same' : `${a} -> ${b}`;
    tally.set(k, (tally.get(k) ?? 0) + 1);
    if (a !== b) diffs.push(`${pid} ${k} why=${r?.why.join(',') ?? ''} oldKept=${JSON.stringify(v.kept ?? {})} newKept=${JSON.stringify(r?.kept ?? {})}`);
  }
  for (const [k, n] of [...tally].sort((x, y) => y[1] - x[1])) console.log(`  ${k}: ${n}`);
  const out = join(WORK, 'compare-db.txt');
  writeFileSync(out, diffs.join('\n') + '\n');
  console.log(`[compare] ${diffs.length} difference(s) written to ${out}`);
}

const cmd = process.argv[2];
const run: Record<string, () => Promise<void>> = { inferred, load, kinds, verdicts, compare };
if (!cmd || !run[cmd]) { console.error(`usage: pac-career-backfill.ts ${Object.keys(run).join('|')}`); process.exit(2); }
run[cmd]!().then(async () => {
  console.log(`[backfill] api: ${apiHits} cached, ${apiCalls} new; filings: ${filingHits} cached, ${filingFetches} fetched`);
  await pool.end(); process.exit(0);
}, async (e) => { console.error(e); await pool.end().catch(() => undefined); process.exit(1); });

