/**
 * pac-career.ts — which federal politicians take no PAC money, or no corporate PAC money, over
 * their WHOLE federal career (every cycle, every FEC candidate id), net of refunds.
 *
 * WHY TWO PASSES. FEC publishes PAC gifts twice:
 *   - by the GIVING PAC (bulk file pas2, every cycle back to 1980, a few MB each), and
 *   - by the RECEIVING campaign (Schedule A line 11C, refunds on Schedule B line 20C), which is
 *     what FEC's own per-candidate totals are built from, but is only reachable through the API
 *     (15 calls/minute here). The bulk "oth" file does NOT carry these receipts.
 * Measured on 2024: the giver-side sum matches FEC's candidate total within 5% for only about
 * half of candidates, and 179 candidates FEC records at $0 have giver-side gifts. So the giver
 * side is a SCREEN, never a verdict:
 *   1. `bulk` + `screen`: the giver-side file rules out everyone who plainly keeps corporate PAC
 *      money (net >= SCREEN_CORPORATE_FLOOR over the career). Cheap, all cycles. A random sample of
 *      those it rules out is verified too (`--sample-ruled-out`), so the screen has a control.
 *   2. `verify`: everyone else is checked against the campaign's OWN filings through the API.
 *      Every cycle's itemized 11C rows must add up to FEC's total for that cycle, or the person
 *      is UNVERIFIED. PAC gifts are always itemized (no $200 floor), so the sum should close.
 * Only `verify` output may be published as "no PAC money" / "no corporate PAC money".
 *
 * DEFINITIONS (ruling 2026-11-18, Chris Andrews):
 *   corporate   = PACs connected to a corporation or a trade association. FEC organization types
 *                 C (corporation), W (corporation without capital stock), T (trade association),
 *                 V (cooperative).
 *   other_pac   = every other non-party committee that is not a candidate's campaign: labor (L),
 *                 membership (M), issue/ideological (nonconnected), leadership PACs (designation D),
 *                 super PACs.
 *   candidate   = another candidate's own campaign committee (types H/S/P, designation P/A).
 *                 Shown separately; it does NOT make someone a PAC-money taker.
 *   party       = party committees (types X/Y). Not PAC money. FEC's PAC total excludes it too.
 *   "kept"      = gifts received minus refunds returned, summed over the career, so a gift taken
 *                 in 2024 and refunded in 2026 nets to zero.
 *
 * Work directory (default ~/Documents/GitHub/.fec-pac-career, outside every repo; override with
 * PAC_CAREER_DIR) holds the downloads, the per-cycle summaries and the API cache. Everything in it
 * is regenerable. The only production read is the roster (politician_sources, a small table).
 *
 * usage (from backend/):
 *   npx tsx scripts/pac-career/pac-career.ts roster
 *   npx tsx scripts/pac-career/pac-career.ts bulk [--from 1980] [--to 2026]
 *   npx tsx scripts/pac-career/pac-career.ts screen
 *   npx tsx scripts/pac-career/pac-career.ts verify [--limit N] [--only <politician_id>] [--sample-ruled-out N]
 *   npx tsx scripts/pac-career/pac-career.ts report [--out <dir>]
 */
import 'dotenv/config';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createWriteStream, existsSync, mkdirSync, readFileSync, statSync, unlinkSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { createInterface } from 'node:readline';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { pathToFileURL } from 'node:url';

const WORK = process.env.PAC_CAREER_DIR ?? join(homedir(), 'Documents/GitHub/.fec-pac-career');
const BULK = join(WORK, 'bulk');
const API_CACHE = join(WORK, 'api');
for (const d of [WORK, BULK, API_CACHE]) mkdirSync(d, { recursive: true });

/**
 * Giver-side corporate money "kept" over a career at or above this rules a person out without the API.
 * Deliberately loose: the giver side OVERSTATES what a campaign kept, because a campaign that never
 * cashes a corporate PAC's check reports nothing while the PAC still reports the gift. Measured on
 * Chris Murphy 2024: giver side $14,000 corporate kept, his own filings $3,000 (refunded in 2026).
 * `verify --sample-ruled-out N` checks a random sample of the people this rules out, as a control.
 */
export const SCREEN_CORPORATE_FLOOR = 50_000;
/** A cycle reconciles when the itemized sum is within this of FEC's total. */
const RECONCILE_ABS = 1;
const RECONCILE_REL = 0.005;

export type Bucket = 'corporate' | 'other_pac' | 'candidate' | 'party' | 'unknown';
export const BUCKETS: Bucket[] = ['corporate', 'other_pac', 'candidate', 'party', 'unknown'];
const CORPORATE_ORG = new Set(['C', 'W', 'T', 'V']);

/** Classify a giving committee from its FEC committee type, designation and organization type. */
export function classify(c: { tp?: string | null; dsgn?: string | null; org?: string | null } | undefined): Bucket {
  if (!c) return 'unknown';
  const tp = (c.tp ?? '').trim().toUpperCase();
  const dsgn = (c.dsgn ?? '').trim().toUpperCase();
  const org = (c.org ?? '').trim().toUpperCase();
  if (!tp && !dsgn && !org) return 'unknown';
  if (tp === 'X' || tp === 'Y') return 'party';
  if (tp === 'H' || tp === 'S' || tp === 'P' || dsgn === 'P' || dsgn === 'A') return 'candidate';
  if (CORPORATE_ORG.has(org)) return 'corporate';
  return 'other_pac';
}

/** Last cycle holding a corporate gift that was not later refunded (refunds cancel newest gifts first). */
export function lastKeptCycle(events: Map<string, { cycle: number; amt: number }[]>): number | null {
  let last: number | null = null;
  for (const ev of events.values()) {
    const gifts = ev.filter((e) => e.amt > 0).map((e) => ({ ...e })).sort((a, b) => b.cycle - a.cycle);
    let refund = ev.filter((e) => e.amt < 0).reduce((t, e) => t - e.amt, 0);
    for (const g of gifts) { const take = Math.min(g.amt, refund); g.amt -= take; refund -= take; }
    for (const g of gifts) if (g.amt > 0.005) last = Math.max(last ?? 0, g.cycle);
  }
  return last;
}

/**
 * A giver FEC gives no type codes for (an unregistered local committee) is a party committee when
 * its name says so ("SOUTHBURY DEMOCRATS", "DEMOCRATIC TOWN COMMITTEE OF AVON"). Everything else
 * without codes stays 'unknown', which keeps the person UNVERIFIED rather than guessed.
 */
export function partyByName(name: string | null | undefined): boolean {
  const n = (name ?? '').toUpperCase();
  if (!/\b(DEMOCRAT|DEMOCRATS|DEMOCRATIC|REPUBLICAN|REPUBLICANS|GOP|DFL|LIBERTARIAN|GREEN PARTY)\b/.test(n)) return false;
  return /\b(COMMITTEE|COMMITEE|PARTY|DEMOCRATS|REPUBLICANS|CLUB|CAUCUS)\b/.test(n);
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const yy = (cycle: number) => String(cycle).slice(2);
const readJson = <T>(p: string): T => JSON.parse(readFileSync(p, 'utf8')) as T;
const writeJson = (p: string, v: unknown) => writeFileSync(p, JSON.stringify(v));
const args = process.argv.slice(3);
const flag = (name: string): string | undefined => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};

// ---------------------------------------------------------------------------------------------
// roster — confirmed FEC candidate ids per politician (production read, small table)
// ---------------------------------------------------------------------------------------------
interface RosterRow { pid: string; name: string; ids: string[] }

async function roster(): Promise<void> {
  // Plain pg, not src/lib/db.js: that module validates the API server's whole environment at import.
  const pg = (await import('pg')).default;
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const { rows } = await pool.query<RosterRow>(`
    SELECT ps.essentials_politician_id::text AS pid, p.full_name AS name,
           array_agg(DISTINCT upper(trim(ps.external_id)) ORDER BY upper(trim(ps.external_id))) AS ids
      FROM transparent_motivations.politician_sources ps
      JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
     WHERE ps.source_system LIKE 'fec%' AND ps.research_status = 'confirmed' AND trim(ps.external_id) <> ''
     GROUP BY 1, 2`);
  await pool.end();
  // An id linked to two politicians cannot be credited to either without a look.
  const owners = new Map<string, string[]>();
  for (const r of rows) for (const id of r.ids) owners.set(id, [...(owners.get(id) ?? []), r.pid]);
  const shared = [...owners].filter(([, o]) => o.length > 1);
  writeJson(join(WORK, 'roster.json'), { fetched_at: new Date().toISOString(), rows, shared_ids: shared });
  console.log(`[roster] ${rows.length} politicians, ${owners.size} FEC ids, ${shared.length} id(s) linked to >1 politician`);
}

// ---------------------------------------------------------------------------------------------
// bulk — download FEC bulk files per cycle and reduce them to a small per-cycle summary
// ---------------------------------------------------------------------------------------------
interface CmRow { tp: string; dsgn: string; org: string; name: string }
type Money = { gross: number; refunds: number };
interface CycleSummary {
  cycle: number;
  files: Record<string, { bytes: number; last_modified: string | null }>;
  weball: Record<string, { rec: number; oth: number; pty: number; cmte_refunds: number; through: string }>;
  cn: Record<string, { name: string; state: string; office: string }>;
  pas2: Record<string, Partial<Record<Bucket, Money>>>;
  pas2_rows: number;
}

async function download(url: string, dest: string): Promise<{ bytes: number; last_modified: string | null }> {
  const head = await fetch(url, { method: 'HEAD', redirect: 'follow' });
  if (!head.ok) throw new Error(`HEAD ${url} -> ${head.status}`);
  const len = Number(head.headers.get('content-length') ?? '0');
  const lm = head.headers.get('last-modified');
  if (existsSync(dest) && len > 0 && statSync(dest).size === len) return { bytes: len, last_modified: lm };
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok || !res.body) throw new Error(`GET ${url} -> ${res.status}`);
  const ctype = res.headers.get('content-type') ?? '';
  if (!ctype.includes('zip')) throw new Error(`GET ${url} returned ${ctype}, not a zip`);
  await pipeline(Readable.fromWeb(res.body as never), createWriteStream(dest));
  const got = statSync(dest).size;
  if (len > 0 && got !== len) throw new Error(`truncated ${url}: ${got} of ${len} bytes`);
  return { bytes: got, last_modified: lm };
}

/** Stream every '|'-separated line of the single text file inside a zip. */
async function* zipLines(zip: string): AsyncGenerator<string[]> {
  const child = spawn('unzip', ['-p', zip], { stdio: ['ignore', 'pipe', 'inherit'] });
  const rl = createInterface({ input: child.stdout.setEncoding('latin1'), crlfDelay: Infinity });
  for await (const line of rl) if (line) yield line.split('|');
  const code: number = await new Promise((r) => child.on('close', r));
  if (code !== 0) throw new Error(`unzip ${zip} exited ${code}`);
}

const num = (s: string | undefined) => (s ? Number(s) || 0 : 0);
const slashDate = (s: string) => {
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(s ?? '');
  return m ? `${m[3]}-${m[1]}-${m[2]}` : '';
};

async function bulkCycle(cycle: number): Promise<void> {
  const out = join(BULK, `cycle-${cycle}.json`);
  if (existsSync(out) && cycle < 2026) { console.log(`[bulk] ${cycle} cached`); return; }
  const base = `https://www.fec.gov/files/bulk-downloads/${cycle}`;
  const files: CycleSummary['files'] = {};
  const get = async (stem: string) => {
    const zip = join(BULK, `${stem}${yy(cycle)}.zip`);
    files[stem] = await download(`${base}/${stem}${yy(cycle)}.zip`, zip);
    return zip;
  };

  const cm = new Map<string, CmRow>();
  for await (const f of zipLines(await get('cm'))) cm.set(f[0]!, { name: f[1]!, dsgn: f[8]!, tp: f[9]!, org: f[12]! });

  const cn: CycleSummary['cn'] = {};
  for await (const f of zipLines(await get('cn'))) cn[f[0]!] = { name: f[1]!, office: f[5]!, state: f[4]! };

  const weball: CycleSummary['weball'] = {};
  for await (const f of zipLines(await get('weball'))) {
    weball[f[0]!] = { rec: num(f[5]), oth: num(f[25]), pty: num(f[26]), through: slashDate(f[27]!), cmte_refunds: num(f[29]) };
  }

  // pas2: CMTE_ID|AMNDT_IND|RPT_TP|TRANSACTION_PGI|IMAGE_NUM|TRANSACTION_TP|ENTITY_TP|NAME|CITY|STATE|
  //       ZIP_CODE|EMPLOYER|OCCUPATION|TRANSACTION_DT|TRANSACTION_AMT|OTHER_ID|CAND_ID|TRAN_ID|FILE_NUM|
  //       MEMO_CD|MEMO_TEXT|SUB_ID. 24K = direct contribution, 24Z = in-kind; 24E/24A are independent
  //       expenditures (spent ABOUT a candidate, never received) and are excluded.
  const pasZip = await get('pas2');
  const pas2: CycleSummary['pas2'] = {};
  let rows = 0;
  for await (const f of zipLines(pasZip)) {
    if (f.length < 22) continue;
    if (f[5] !== '24K' && f[5] !== '24Z') continue;
    if (f[19] === 'X') continue;
    const cand = (f[16] ?? '').trim().toUpperCase();
    if (!cand) continue;
    const b = classify(cm.get(f[0]!));
    const amt = num(f[14]);
    const slot = ((pas2[cand] ??= {})[b] ??= { gross: 0, refunds: 0 });
    if (amt >= 0) slot.gross += amt; else slot.refunds += -amt;
    rows++;
  }
  unlinkSync(pasZip); // ~25 MB a cycle; the summary is all we need, and the HEAD check re-fetches on demand
  writeJson(out, { cycle, files, weball, cn, pas2, pas2_rows: rows } satisfies CycleSummary);
  console.log(`[bulk] ${cycle}: cm=${cm.size} cn=${Object.keys(cn).length} weball=${Object.keys(weball).length} pas2 rows=${rows}`);
}

async function bulk(): Promise<void> {
  const from = Number(flag('from') ?? 1980);
  const to = Number(flag('to') ?? 2026);
  for (let c = from; c <= to; c += 2) await bulkCycle(c);
}

function loadCycles(): CycleSummary[] {
  const out: CycleSummary[] = [];
  for (let c = 1980; c <= 2026; c += 2) {
    const p = join(BULK, `cycle-${c}.json`);
    if (existsSync(p)) out.push(readJson<CycleSummary>(p));
  }
  if (out.length === 0) throw new Error('no bulk cycles on disk — run `bulk` first');
  return out;
}

// ---------------------------------------------------------------------------------------------
// screen — find every FEC id per person, and rule out plain corporate-PAC takers giver-side
// ---------------------------------------------------------------------------------------------
/** "MURPHY, CHRISTOPHER SCOTT MR." -> { last: MURPHY, first: CHRISTOPHER } */
export function nameKey(fecName: string): { last: string; first: string } {
  const [lastRaw = '', restRaw = ''] = fecName.toUpperCase().split(',');
  const strip = (s: string) => s.replace(/[^A-Z ]/g, ' ').replace(/\s+/g, ' ').trim();
  const titles = new Set(['MR', 'MRS', 'MS', 'DR', 'HON', 'JR', 'SR', 'II', 'III', 'IV', 'REV']);
  const first = strip(restRaw).split(' ').filter((t) => t && !titles.has(t))[0] ?? '';
  const last = strip(lastRaw).split(' ').filter((t) => t && !titles.has(t)).join(' ');
  return { last, first };
}

interface PersonScreen {
  pid: string; name: string;
  linked_ids: string[];
  inferred_ids: { id: string; fec_name: string; office: string; state: string }[];
  states: string[];
  giver_side: Record<Bucket, number>; // kept = gross - refunds, career
  giver_last_corporate_cycle: number | null;
  weball_career: { receipts: number; pac: number; cycles: number[]; through: string };
  route: 'ruled_out_corporate' | 'verify';
}

function screen(): void {
  const { rows, shared_ids } = readJson<{ rows: RosterRow[]; shared_ids: [string, string[]][] }>(join(WORK, 'roster.json'));
  const cycles = loadCycles();
  const sharedSet = new Set(shared_ids.map(([id]) => id));
  const linkedAnywhere = new Set(rows.flatMap((r) => r.ids));

  // name index over every cycle's candidate master: "STATE|LAST|FIRST" -> ids
  const byKey = new Map<string, Map<string, { fec_name: string; office: string; state: string }>>();
  const info = new Map<string, { fec_name: string; office: string; state: string }>();
  for (const c of cycles) for (const [id, v] of Object.entries(c.cn)) {
    const k = nameKey(v.name);
    const key = `${v.state}|${k.last}|${k.first}`;
    const rec = { fec_name: v.name, office: v.office, state: v.state };
    (byKey.get(key) ?? byKey.set(key, new Map()).get(key)!).set(id, rec);
    info.set(id, rec);
  }

  const people: PersonScreen[] = [];
  for (const r of rows) {
    const linked = r.ids.filter((id) => !sharedSet.has(id));
    const states = new Set<string>();
    const inferred = new Map<string, { fec_name: string; office: string; state: string }>();
    for (const id of linked) {
      const me = info.get(id);
      if (!me) continue;
      states.add(me.state);
      const k = nameKey(me.fec_name);
      for (const [other, rec] of byKey.get(`${me.state}|${k.last}|${k.first}`) ?? []) {
        if (other === id || linked.includes(other) || linkedAnywhere.has(other)) continue;
        if (rec.office !== 'H' && rec.office !== 'S') continue;
        inferred.set(other, rec);
      }
    }
    const ids = [...linked, ...inferred.keys()];
    const giver: Record<Bucket, number> = { corporate: 0, other_pac: 0, candidate: 0, party: 0, unknown: 0 };
    let lastCorp: number | null = null;
    const wb = { receipts: 0, pac: 0, cycles: [] as number[], through: '' };
    for (const c of cycles) {
      let corpThisCycle = 0;
      for (const id of ids) {
        const p = c.pas2[id];
        if (p) for (const b of BUCKETS) {
          const m = p[b];
          if (!m) continue;
          giver[b] += m.gross - m.refunds;
          if (b === 'corporate') corpThisCycle += m.gross - m.refunds;
        }
        const w = c.weball[id];
        if (w) {
          wb.receipts += w.rec; wb.pac += w.oth;
          if (!wb.cycles.includes(c.cycle)) wb.cycles.push(c.cycle);
          if (w.through > wb.through) wb.through = w.through;
        }
      }
      if (corpThisCycle > 0) lastCorp = c.cycle;
    }
    people.push({
      pid: r.pid, name: r.name, linked_ids: linked,
      inferred_ids: [...inferred].map(([id, v]) => ({ id, ...v })),
      states: [...states], giver_side: giver, giver_last_corporate_cycle: lastCorp, weball_career: wb,
      route: giver.corporate >= SCREEN_CORPORATE_FLOOR ? 'ruled_out_corporate' : 'verify',
    });
  }
  writeJson(join(WORK, 'screen.json'), { built_at: new Date().toISOString(), floor: SCREEN_CORPORATE_FLOOR, people });
  const n = (route: string) => people.filter((p) => p.route === route).length;
  console.log(`[screen] ${people.length} people: ${n('ruled_out_corporate')} ruled out (giver-side corporate >= $${SCREEN_CORPORATE_FLOOR}), ${n('verify')} to verify; ` +
    `${people.filter((p) => p.inferred_ids.length).length} with inferred extra FEC ids; ${shared_ids.length} shared id(s) set aside`);
}

// ---------------------------------------------------------------------------------------------
// verify — the campaign's own filings, via the FEC API, reconciled cycle by cycle
// ---------------------------------------------------------------------------------------------
const FEC = 'https://api.open.fec.gov/v1';

async function fecGet<T>(path: string, params: Record<string, string | string[]>): Promise<T> {
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) for (const x of [v].flat()) qs.append(k, x);
  const keyed = `${path}?${qs}`;
  const cacheFile = join(API_CACHE, createHash('sha1').update(keyed).digest('hex') + '.json');
  if (existsSync(cacheFile)) return readJson<T>(cacheFile);
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY is not set');
  const { acquireFecSlot } = await import('../../src/lib/fecRateLimiter.js');
  let delay = 5_000;
  for (let attempt = 0; attempt < 6; attempt++) {
    await acquireFecSlot();
    const res = await fetch(`${FEC}${keyed}&api_key=${apiKey}`, { signal: AbortSignal.timeout(60_000) }).catch((e: Error) => e);
    if (res instanceof Error || res.status === 429 || res.status >= 500) {
      await sleep(delay); delay = Math.min(delay * 2, 120_000); continue;
    }
    if (!res.ok) throw new Error(`FEC ${path} -> HTTP ${res.status}`);
    const body = await res.text();
    if (!body.startsWith('{')) throw new Error(`FEC ${path} returned non-JSON (${body.slice(0, 80)})`);
    writeFileSync(cacheFile, body);
    return JSON.parse(body) as T;
  }
  throw new Error(`FEC ${path} failed after retries`);
}

interface Page<T> { results: T[]; pagination: { count?: number; pages?: number; last_indexes?: Record<string, string> | null } }
interface CmteRef { committee_type?: string | null; designation?: string | null; organization_type?: string | null }

/** Every row of a keyset-paginated schedule endpoint. */
async function allRows<T>(path: string, params: Record<string, string>): Promise<{ rows: T[]; count: number }> {
  const rows: T[] = [];
  let extra: Record<string, string> = {};
  let count = 0;
  for (let i = 0; i < 500; i++) {
    const page = await fecGet<Page<T>>(path, { ...params, per_page: '100', ...extra });
    count = page.pagination.count ?? count;
    rows.push(...page.results);
    const li = page.pagination.last_indexes;
    if (!li || page.results.length < 100) break;
    extra = Object.fromEntries(Object.entries(li).map(([k, v]) => [k, String(v)]));
  }
  return { rows, count };
}

interface TotalsRow {
  cycle: number; receipts: number | null; coverage_end_date: string | null;
  other_political_committee_contributions: number | null;
  refunded_other_political_committee_contributions: number | null;
}
interface CycleCheck {
  cycle: number; fec_pac_total: number; itemized_pac_total: number; fec_refunds: number; itemized_refunds: number;
  reconciled: boolean; rows: number;
}
interface PersonVerify {
  pid: string; checked_at: string; ids: string[];
  career: { receipts: number; first_cycle: number | null; last_cycle: number | null; through: string };
  kept: Record<Bucket, number>; received: Record<Bucket, number>; refunded: Record<Bucket, number>;
  last_corporate_cycle: number | null;
  unknown_examples: { cycle: number; name: string; contributor_id: string | null; amount: number }[];
  cycles: CycleCheck[];
  unreconciled: number[];
  error?: string;
}

const close = (a: number, b: number) => Math.abs(a - b) <= Math.max(RECONCILE_ABS, RECONCILE_REL * Math.max(Math.abs(a), Math.abs(b)));

async function verifyPerson(p: PersonScreen, cmByCycle: Map<number, Map<string, CmRow>>): Promise<PersonVerify> {
  const ids = [...p.linked_ids, ...p.inferred_ids.map((x) => x.id)];
  const zero = (): Record<Bucket, number> => ({ corporate: 0, other_pac: 0, candidate: 0, party: 0, unknown: 0 });
  const v: PersonVerify = {
    pid: p.pid, checked_at: new Date().toISOString(), ids,
    career: { receipts: 0, first_cycle: null, last_cycle: null, through: '' },
    kept: zero(), received: zero(), refunded: zero(), last_corporate_cycle: null, unknown_examples: [], cycles: [], unreconciled: [],
  };
  // Per giving corporate committee: its gifts and refunds over the career. A refund cancels that
  // committee's MOST RECENT gifts first, so a 2024 gift refunded in 2026 never makes 2024 the last
  // corporate cycle, even when the same PAC's 2018 gift was kept.
  const corpEvents = new Map<string, { cycle: number; amt: number }[]>();
  const ledger = (key: string, cycle: number, amt: number) => {
    corpEvents.set(key, [...(corpEvents.get(key) ?? []), { cycle, amt }]);
  };
  // cycle -> FEC totals summed over this person's ids
  const totals = new Map<number, { pac: number; refunds: number }>();
  const committees = new Map<string, Set<number>>(); // committee id -> cycles it served
  for (const id of ids) {
    const t = await fecGet<Page<TotalsRow>>(`/candidate/${id}/totals/`, { election_full: 'false', per_page: '100' });
    for (const r of t.results) {
      if (typeof r.cycle !== 'number') continue;
      v.career.receipts += r.receipts ?? 0;
      v.career.first_cycle = Math.min(v.career.first_cycle ?? r.cycle, r.cycle);
      v.career.last_cycle = Math.max(v.career.last_cycle ?? r.cycle, r.cycle);
      const end = (r.coverage_end_date ?? '').slice(0, 10);
      if (end > v.career.through) v.career.through = end;
      const cur = totals.get(r.cycle) ?? { pac: 0, refunds: 0 };
      cur.pac += r.other_political_committee_contributions ?? 0;
      cur.refunds += r.refunded_other_political_committee_contributions ?? 0;
      totals.set(r.cycle, cur);
    }
    const anyPac = [...totals.values()].some((x) => x.pac !== 0 || x.refunds !== 0);
    if (!anyPac) continue;
    const cm = await fecGet<Page<{ committee_id: string; designation: string; cycles: number[] }>>(
      `/candidate/${id}/committees/`, { designation: ['P', 'A'], per_page: '100' });
    for (const c of cm.results) {
      const s = committees.get(c.committee_id) ?? new Set<number>();
      for (const cy of c.cycles ?? []) s.add(cy);
      committees.set(c.committee_id, s);
    }
  }

  const bucketOf = (cycle: number, ref: CmteRef | null | undefined, refId: string | null | undefined): Bucket => {
    if (ref && (ref.committee_type || ref.designation || ref.organization_type)) {
      return classify({ tp: ref.committee_type, dsgn: ref.designation, org: ref.organization_type });
    }
    const id = (refId ?? '').trim().toUpperCase();
    if (!id) return 'unknown';
    for (const c of [cycle, cycle + 2, cycle - 2]) {
      const hit = cmByCycle.get(c)?.get(id);
      if (hit) return classify(hit);
    }
    return 'unknown';
  };

  for (const [cycle, t] of [...totals].sort((a, b) => a[0] - b[0])) {
    if (t.pac === 0 && t.refunds === 0) continue;
    const check: CycleCheck = { cycle, fec_pac_total: t.pac, itemized_pac_total: 0, fec_refunds: t.refunds, itemized_refunds: 0, reconciled: false, rows: 0 };
    for (const [cmte, cys] of committees) {
      if (cys.size && !cys.has(cycle)) continue;
      const a = await allRows<{ contribution_receipt_amount: number; memo_code: string | null; contributor_id: string | null; contributor_name: string | null; contributor: CmteRef | null }>(
        '/schedules/schedule_a/', { committee_id: cmte, two_year_transaction_period: String(cycle), line_number: 'F3-11C' });
      for (const r of a.rows) {
        if (r.memo_code === 'X') continue;
        let b = bucketOf(cycle, r.contributor, r.contributor_id);
        if (b === 'unknown' && partyByName(r.contributor_name)) b = 'party';
        const amt = r.contribution_receipt_amount ?? 0;
        check.itemized_pac_total += amt; check.rows++;
        v.received[b] += amt; v.kept[b] += amt;
        if (b === 'corporate') ledger(r.contributor_id || r.contributor_name || '?', cycle, amt);
        if (b === 'unknown' && v.unknown_examples.length < 15) {
          v.unknown_examples.push({ cycle, name: r.contributor_name ?? '', contributor_id: r.contributor_id, amount: amt });
        }
      }
      const b20 = await allRows<{ disbursement_amount: number; memo_code: string | null; recipient_committee_id: string | null; recipient_name: string | null; recipient_committee: CmteRef | null }>(
        '/schedules/schedule_b/', { committee_id: cmte, two_year_transaction_period: String(cycle), line_number: 'F3-20C' });
      for (const r of b20.rows) {
        if (r.memo_code === 'X') continue;
        let b = bucketOf(cycle, r.recipient_committee, r.recipient_committee_id);
        if (b === 'unknown' && partyByName(r.recipient_name)) b = 'party';
        const amt = r.disbursement_amount ?? 0;
        check.itemized_refunds += amt;
        v.refunded[b] += amt; v.kept[b] -= amt;
        if (b === 'corporate') ledger(r.recipient_committee_id || r.recipient_name || '?', cycle, -amt);
      }
    }
    check.reconciled = close(check.itemized_pac_total, check.fec_pac_total) && close(check.itemized_refunds, check.fec_refunds);
    if (!check.reconciled) v.unreconciled.push(cycle);
    v.cycles.push(check);
  }
  v.last_corporate_cycle = lastKeptCycle(corpEvents);
  return v;
}

async function verify(): Promise<void> {
  const { people } = readJson<{ people: PersonScreen[] }>(join(WORK, 'screen.json'));
  const only = flag('only');
  const limit = Number(flag('limit') ?? Infinity);
  // Control on the screen: a random sample of the people it ruled out, checked the same way.
  const sample = Number(flag('sample-ruled-out') ?? 0);
  const ruledOut = people.filter((p) => p.route === 'ruled_out_corporate');
  const sampled = new Set<string>();
  for (const p of [...ruledOut].sort((a, b) => createHash('sha1').update(a.pid).digest('hex').localeCompare(createHash('sha1').update(b.pid).digest('hex')))) {
    if (sampled.size >= sample) break;
    sampled.add(p.pid);
  }
  const queue = people.filter((p) => (only ? p.pid === only : p.route === 'verify' || sampled.has(p.pid)));
  const outPath = join(WORK, 'verify.json');
  const done: Record<string, PersonVerify> = existsSync(outPath) ? readJson(outPath) : {};

  const cmByCycle = new Map<number, Map<string, CmRow>>();
  // committee master per cycle, for gifts whose API row carries no committee details
  for (let c = 1980; c <= 2026; c += 2) {
    const zip = join(BULK, `cm${yy(c)}.zip`);
    if (!existsSync(zip)) continue;
    const m = new Map<string, CmRow>();
    for await (const f of zipLines(zip)) m.set(f[0]!, { name: f[1]!, dsgn: f[8]!, tp: f[9]!, org: f[12]! });
    cmByCycle.set(c, m);
  }

  let n = 0;
  for (const p of queue) {
    if (n >= limit) break;
    if (done[p.pid] && !done[p.pid]!.error && !only) continue;
    try {
      done[p.pid] = await verifyPerson(p, cmByCycle);
    } catch (e) {
      done[p.pid] = { pid: p.pid, checked_at: new Date().toISOString(), ids: [], error: (e as Error).message } as unknown as PersonVerify;
    }
    n++;
    writeJson(outPath, done);
    const r = done[p.pid]!;
    console.log(`[verify] ${n}/${Math.min(queue.length, limit)} ${p.name}: ${r.error ? 'ERROR ' + r.error :
      `corporate kept $${Math.round(r.kept.corporate)}, other PAC kept $${Math.round(r.kept.other_pac)}, ` +
      `${r.cycles.length} PAC cycle(s), ${r.unreconciled.length} unreconciled`}`);
  }
}

// ---------------------------------------------------------------------------------------------
// report
// ---------------------------------------------------------------------------------------------
export type Verdict = 'NO_PAC_MONEY' | 'NO_CORPORATE_PAC_MONEY' | 'TOOK_CORPORATE_PAC_MONEY' | 'UNVERIFIED' | 'NO_RECEIPTS';

export function verdictOf(v: Pick<PersonVerify, 'kept' | 'unreconciled' | 'career' | 'error'>): Verdict {
  if (v.error) return 'UNVERIFIED';
  if (v.career.receipts <= 0) return 'NO_RECEIPTS';
  if (v.kept.corporate > 0) return 'TOOK_CORPORATE_PAC_MONEY';
  // A gift we could not classify, or a cycle whose itemized rows do not add up to FEC's total,
  // could hide corporate money: never claim "none" over it.
  if (v.unreconciled.length > 0 || v.kept.unknown > 0) return 'UNVERIFIED';
  return v.kept.other_pac > 0 ? 'NO_CORPORATE_PAC_MONEY' : 'NO_PAC_MONEY';
}

function report(): void {
  const { people } = readJson<{ people: PersonScreen[] }>(join(WORK, 'screen.json'));
  const ver = existsSync(join(WORK, 'verify.json')) ? readJson<Record<string, PersonVerify>>(join(WORK, 'verify.json')) : {};
  const outDir = flag('out') ?? WORK;
  mkdirSync(outDir, { recursive: true });
  const csvCell = (x: unknown) => { const s = String(x ?? ''); return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; };
  const header = ['politician_id', 'name', 'verdict', 'source', 'fec_ids', 'inferred_fec_ids', 'first_cycle', 'last_cycle', 'data_through',
    'career_receipts', 'corporate_pac_kept', 'other_pac_kept', 'candidate_committees_kept', 'unknown_kept',
    'corporate_pac_received', 'corporate_pac_refunded', 'last_corporate_cycle', 'unreconciled_cycles'];
  const lines = [header.join(',')];
  const tally = new Map<string, number>();
  for (const p of people) {
    const v = ver[p.pid];
    let row: unknown[];
    if (p.route === 'ruled_out_corporate' && !v) {
      row = [p.pid, p.name, 'TOOK_CORPORATE_PAC_MONEY', 'giver-side (PAC reports)', p.linked_ids.join(' '), p.inferred_ids.map((x) => x.id).join(' '),
        p.weball_career.cycles[0] ?? '', p.weball_career.cycles.at(-1) ?? '', p.weball_career.through, Math.round(p.weball_career.receipts),
        Math.round(p.giver_side.corporate), Math.round(p.giver_side.other_pac), Math.round(p.giver_side.candidate), Math.round(p.giver_side.unknown),
        '', '', p.giver_last_corporate_cycle ?? '', ''];
      tally.set('TOOK_CORPORATE_PAC_MONEY', (tally.get('TOOK_CORPORATE_PAC_MONEY') ?? 0) + 1);
    } else if (!v) {
      row = [p.pid, p.name, 'NOT_YET_CHECKED', '', p.linked_ids.join(' '), p.inferred_ids.map((x) => x.id).join(' ')];
      tally.set('NOT_YET_CHECKED', (tally.get('NOT_YET_CHECKED') ?? 0) + 1);
    } else {
      const verdict = verdictOf(v);
      row = [p.pid, p.name, verdict, v.error ? `error: ${v.error}` : 'campaign filings (FEC API)', p.linked_ids.join(' '), p.inferred_ids.map((x) => x.id).join(' '),
        v.career.first_cycle ?? '', v.career.last_cycle ?? '', v.career.through, Math.round(v.career.receipts ?? 0),
        Math.round(v.kept?.corporate ?? 0), Math.round(v.kept?.other_pac ?? 0), Math.round(v.kept?.candidate ?? 0), Math.round(v.kept?.unknown ?? 0),
        Math.round(v.received?.corporate ?? 0), Math.round(v.refunded?.corporate ?? 0), v.last_corporate_cycle ?? '', (v.unreconciled ?? []).join(' ')];
      tally.set(verdict, (tally.get(verdict) ?? 0) + 1);
      if (p.route === 'ruled_out_corporate') {
        const k = verdict === 'TOOK_CORPORATE_PAC_MONEY' ? 'control: screen confirmed' : `control: SCREEN WRONG (${verdict})`;
        tally.set(k, (tally.get(k) ?? 0) + 1);
      }
    }
    lines.push(row.map(csvCell).join(','));
  }
  writeFileSync(join(outDir, 'pac-career.csv'), lines.join('\n') + '\n');
  console.log(`[report] ${people.length} people -> ${join(outDir, 'pac-career.csv')}`);
  for (const [k, n] of [...tally].sort()) console.log(`  ${k}: ${n}`);
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const cmd = process.argv[2];
  const run: Record<string, () => Promise<void> | void> = { roster, bulk, screen, verify, report };
  if (!cmd || !run[cmd]) { console.error(`usage: pac-career.ts ${Object.keys(run).join('|')}`); process.exit(2); }
  Promise.resolve(run[cmd]!()).then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
}
