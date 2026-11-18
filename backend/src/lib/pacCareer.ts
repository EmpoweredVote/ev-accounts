/**
 * pacCareer — pure rules for "which politicians took no PAC money, or no corporate PAC money, over their whole
 * federal career". No database, no network: the job (pacCareerJob.ts) and the backfill feed it rows.
 *
 * Moved from scripts/pac-career/pac-career.ts (PR #1532), with the 2026-11-18 rulings (Chris Andrews):
 *   corporate  = company PACs only: FEC organization types C (corporation) and W (corporation without capital
 *                stock). Trade groups (T) and co-ops (V) are their own kinds, shown separately.
 *   candidate  = another candidate's own campaign committee. Shown apart; not PAC money.
 *   party      = party committees. Not PAC money.
 *   kept       = received minus refunded.
 *   A gift's kind is read for its own cycle, overruled only when the cycles on both sides agree with each other
 *   (the NEA Fund is labor in 2022 and 2026 but corporation in 2024).
 *
 * Source of record: the campaign's OWN reports — Schedule A line 11C (gifts from committees) and Schedule B
 * line 20C (refunds to committees) — never the giving PAC's report (bulk file pas2), which matched FEC's own
 * totals within 5% for only half of candidates (PR #1532, 2024).
 */

export type Bucket = 'corporate' | 'trade' | 'coop' | 'other_pac' | 'candidate' | 'party' | 'unknown';
export const BUCKETS: readonly Bucket[] = ['corporate', 'trade', 'coop', 'other_pac', 'candidate', 'party', 'unknown'];
/** Kinds that count as PAC money. candidate, party and unknown do not (unknown blocks a "none" claim instead). */
export const PAC_BUCKETS: readonly Bucket[] = ['corporate', 'trade', 'coop', 'other_pac'];

/** FEC committee master codes (cm{YY}): CMTE_TP, CMTE_DSGN, ORG_TP. */
export interface CmCodes { tp?: string | null; dsgn?: string | null; org?: string | null }

/** Classify a committee from its FEC committee type, designation and organization type. */
export function classify(c: CmCodes | undefined | null): Bucket {
  if (!c) return 'unknown';
  const tp = (c.tp ?? '').trim().toUpperCase();
  const dsgn = (c.dsgn ?? '').trim().toUpperCase();
  const org = (c.org ?? '').trim().toUpperCase();
  if (!tp && !dsgn && !org) return 'unknown';
  if (tp === 'X' || tp === 'Y') return 'party';
  if (tp === 'H' || tp === 'S' || tp === 'P' || dsgn === 'P' || dsgn === 'A') return 'candidate';
  if (org === 'C' || org === 'W') return 'corporate';
  if (org === 'T') return 'trade';
  if (org === 'V') return 'coop';
  return 'other_pac';
}

/** committee id -> cycle -> codes. */
export type KindsByCommittee = Map<string, Map<number, CmCodes>>;

/**
 * The kind of committee `id` was in `cycle`: FEC's code for that cycle, unless the cycles either side agree with
 * each other and not with it — a one-cycle slip. A lasting change is kept (the trial lawyers' PAC: trade group in
 * the 1990s, membership group now). With no code for the cycle, the nearest one, the later on a tie.
 */
export function committeeKindAt(kinds: KindsByCommittee, id: string, cycle: number): Bucket | undefined {
  const byCycle = kinds.get(id);
  if (!byCycle || byCycle.size === 0) return undefined;
  const at = (c: number) => { const r = byCycle.get(c); return r ? classify(r) : undefined; };
  const own = at(cycle);
  if (own) {
    const before = at(cycle - 2);
    const after = at(cycle + 2);
    return before && before === after && before !== own ? before : own;
  }
  const near = [...byCycle.keys()].sort((x, y) => Math.abs(x - cycle) - Math.abs(y - cycle) || y - x)[0];
  return near === undefined ? undefined : at(near);
}

/**
 * A giver FEC gives no codes for (an unregistered local committee) is a party committee when its name says so
 * ("SOUTHBURY DEMOCRATS", "DEMOCRATIC TOWN COMMITTEE OF AVON"). Everything else without codes stays 'unknown'.
 */
export function partyByName(name: string | null | undefined): boolean {
  const n = (name ?? '').toUpperCase();
  if (!/\b(DEMOCRAT|DEMOCRATS|DEMOCRATIC|REPUBLICAN|REPUBLICANS|GOP|DFL|LIBERTARIAN|GREEN PARTY)\b/.test(n)) return false;
  return /\b(COMMITTEE|COMMITEE|PARTY|DEMOCRATS|REPUBLICANS|CLUB|CAUCUS)\b/.test(n);
}

/** Upper-case, punctuation to spaces, single spaces: "Ibew PAC, Inc." -> "IBEW PAC INC". */
export const normName = (n: string | null | undefined): string =>
  (n ?? '').toUpperCase().replace(/[^A-Z0-9]+/g, ' ').trim();

export const COMMITTEE_ID_RE = /^C[0-9]{8}$/;

/** A gift row's giver key: the FEC committee id, or 'NAME:<normalised name>' when the filing gave none. */
export function giverKeyOf(id: string | null | undefined, name: string | null | undefined): string {
  const cid = (id ?? '').trim().toUpperCase();
  return COMMITTEE_ID_RE.test(cid) ? cid : `NAME:${normName(name) || '?'}`;
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

/** A sum reconciles with FEC's figure within $1 or 0.5%, whichever is larger (PR #1532's rule). */
export function reconciles(a: number, b: number): boolean {
  return Math.abs(a - b) <= Math.max(1, 0.005 * Math.max(Math.abs(a), Math.abs(b)));
}

/** The FEC cycle a date (YYYYMMDD or YYYY-MM-DD) falls in. */
export function cycleOfDate(d: string): number | null {
  const m = /^(\d{4})-?\d{2}-?\d{2}$/.exec(d.trim());
  if (!m) return null;
  const y = Number(m[1]);
  return y % 2 === 0 ? y : y + 1;
}

// ---------------------------------------------------------------------------------------------------------------
// Raw .fec filings (FEC format v8, 2011 on)
// ---------------------------------------------------------------------------------------------------------------

const FS = '\x1c';
/** v8 field positions: [amount, committee id, name, memo code] per itemized line type. */
export const FILED_FIELDS = { SA11C: { amt: 20, id: 25, name: 6, memo: 42 }, SB20C: { amt: 20, id: 24, name: 6, memo: 41 } } as const;
/**
 * v8 F3 summary record positions. 11C and 20C "this period" are fields 36 and 53; verified 2026-11-18 on 397
 * cached filings, where field 36 equalled the itemized 11C sum on 385 of them.
 */
export const F3_FIELDS = { committee: 1, reportType: 11, coverageFrom: 15, coverageThrough: 16, line11c: 36, line20c: 53 } as const;

export interface FiledRow { line: 'SA11C' | 'SB20C'; amt: number; id: string; name: string }
export interface ParsedFiling {
  committeeId: string;
  form: string;             // F3N, F3A, F3T
  reportType: string;       // Q1, Q2, Q3, YE, 12G, 30G, TER, ...
  coverageStart: string;    // YYYY-MM-DD
  coverageEnd: string;
  cycle: number;
  line11cTotal: number;
  line20cTotal: number;
  rows: FiledRow[];
}

const isoDate = (s: string | undefined) => {
  const m = /^(\d{4})(\d{2})(\d{2})$/.exec((s ?? '').trim());
  return m ? `${m[1]}-${m[2]}-${m[3]}` : '';
};

/** First line of a .fec file -> its format version, e.g. '8.3'. */
export function filingVersion(text: string): string | null {
  const nl = text.indexOf('\n');
  const hdr = (nl < 0 ? text : text.slice(0, nl)).split(FS);
  return hdr[0] === 'HDR' ? (hdr[2] ?? '').trim() : null;
}

/** The form of a filing's first report record ('F3N', 'F3XA', 'F99', ...), from its second line. Cheap. */
export function filingForm(text: string): string | null {
  const a = text.indexOf('\n');
  if (a < 0) return null;
  const b = text.indexOf('\n', a + 1);
  const line = text.slice(a + 1, b < 0 ? undefined : b);
  const f = line.split(FS, 2)[0]?.trim().toUpperCase();
  return f || null;
}

/**
 * Parses a campaign's report (Form 3, v8): its summary-page 11C/20C totals and every non-memo 11C gift and 20C
 * refund. Returns null for any other form or an older format — the caller falls back to FEC's processed data.
 */
export function parseFiling(text: string): ParsedFiling | null {
  const v = filingVersion(text);
  if (!v || !v.startsWith('8')) return null;
  const lines = text.split(/\r?\n/);
  let f3: string[] | undefined;
  const rows: FiledRow[] = [];
  for (const l of lines) {
    const f = l.split(FS);
    const t = (f[0] ?? '').trim().toUpperCase();
    if (!f3 && /^F3[NAT]$/.test(t)) { f3 = f; continue; }
    if (t !== 'SA11C' && t !== 'SB20C') continue;
    const pos = FILED_FIELDS[t];
    if ((f[pos.memo] ?? '').trim().toUpperCase() === 'X') continue;
    rows.push({ line: t, amt: Number(f[pos.amt]) || 0, id: (f[pos.id] ?? '').trim().toUpperCase(), name: (f[pos.name] ?? '').trim() });
  }
  if (!f3) return null;
  const coverageEnd = isoDate(f3[F3_FIELDS.coverageThrough]);
  const cycle = cycleOfDate(coverageEnd);
  if (!cycle) return null;
  return {
    committeeId: (f3[F3_FIELDS.committee] ?? '').trim().toUpperCase(),
    form: (f3[0] ?? '').trim().toUpperCase(),
    reportType: (f3[F3_FIELDS.reportType] ?? '').trim().toUpperCase(),
    coverageStart: isoDate(f3[F3_FIELDS.coverageFrom]),
    coverageEnd,
    cycle,
    line11cTotal: Number(f3[F3_FIELDS.line11c]) || 0,
    line20cTotal: Number(f3[F3_FIELDS.line20c]) || 0,
    rows,
  };
}

/** One report replaces another of the same type and period; an amendment shares its original's key. */
export const reportKeyOf = (p: Pick<ParsedFiling, 'reportType' | 'coverageStart' | 'coverageEnd'>): string =>
  `${p.reportType}|${p.coverageStart}|${p.coverageEnd}`;
export const apiReportKey = (cycle: number): string => `api:${cycle}`;

export interface GiftSum { giverKey: string; giverId: string | null; giverName: string; received: number; refunded: number; n: number }

/** Sums itemized rows per giver. Refund rows (20C) add to `refunded`; a negative 11C row reduces `received`. */
export function sumByGiver(rows: { refund: boolean; amt: number; id: string | null; name: string | null }[]): GiftSum[] {
  const m = new Map<string, GiftSum>();
  for (const r of rows) {
    const key = giverKeyOf(r.id, r.name);
    const g = m.get(key) ?? { giverKey: key, giverId: key.startsWith('NAME:') ? null : key, giverName: (r.name ?? '').trim(), received: 0, refunded: 0, n: 0 };
    if (r.refund) g.refunded += r.amt; else g.received += r.amt;
    g.n += 1;
    if (!g.giverName && r.name) g.giverName = r.name.trim();
    m.set(key, g);
  }
  return [...m.values()].map((g) => ({ ...g, received: round2(g.received), refunded: round2(g.refunded) }));
}

export const round2 = (x: number): number => Math.round(x * 100) / 100;

// ---------------------------------------------------------------------------------------------------------------
// One person's career
// ---------------------------------------------------------------------------------------------------------------

export interface IdInput { id: string; status: 'confirmed' | 'needs_review'; shared: boolean; totalsFetched: boolean }
export interface TotalsInput { id: string; cycle: number; receipts: number | null; pac: number | null; pacRefunds: number | null; coverageEnd: string | null }
export interface ReportInput { committeeId: string; reportKey: string; cycle: number; source: 'efiling' | 'api'; itemized11c: number; itemized20c: number }
export interface GiftInput { committeeId: string; reportKey: string; giverKey: string; giverId: string | null; giverName: string | null; received: number; refunded: number }

export interface PersonInput {
  politicianId: string;
  ids: IdInput[];
  totals: TotalsInput[];
  /** (FEC id, cycle) -> campaign committee, from ccl. */
  committees: { id: string; cycle: number; committeeId: string }[];
  /** Reports of those committees, any cycle. */
  reports: ReportInput[];
  /** Gifts of those reports. */
  gifts: GiftInput[];
}

export type Verdict = 'no_receipts' | 'takes_corporate' | 'unverified' | 'no_corporate_pac' | 'no_pac';
export type WhyUnverified = 'id_needs_review' | 'shared_id' | 'totals_not_fetched' | 'cycle_unreconciled' | 'unknown_giver' | 'no_totals_for_cycle';

export interface CycleCheck { cycle: number; fecPac: number | null; fecRefunds: number | null; itemizedPac: number; itemizedRefunds: number; source: 'efiling' | 'api' | 'mixed' | 'none'; reconciled: boolean }
export interface CareerResult {
  politicianId: string;
  verdict: Verdict;
  why: WhyUnverified[];
  kept: Record<Bucket, number>;
  received: Record<Bucket, number>;
  refunded: Record<Bucket, number>;
  lastCorporateCycle: number | null;
  careerReceipts: number;
  firstCycle: number | null;
  lastCycle: number | null;
  through: string | null;
  cycles: CycleCheck[];
  fecIds: string[];
}

const zero = (): Record<Bucket, number> => ({ corporate: 0, trade: 0, coop: 0, other_pac: 0, candidate: 0, party: 0, unknown: 0 });

/**
 * Computes one person's career from stored rows. Only confirmed, unshared ids are counted; a needs_review or
 * shared id blocks a "none" claim but never invents money.
 *
 * Each cycle is read from whichever of the two sources reconciles with FEC's own totals: the e-filed reports
 * first (they are current), then FEC's processed per-cycle data (which covers paper filings). When neither
 * reconciles the cycle is unreconciled and the e-filed reading is kept.
 */
export function computeCareer(p: PersonInput, kinds: KindsByCommittee): CareerResult {
  const why = new Set<WhyUnverified>();
  const counted = p.ids.filter((i) => i.status === 'confirmed' && !i.shared);
  for (const i of p.ids) {
    if (i.status === 'needs_review') why.add('id_needs_review');
    if (i.shared) why.add('shared_id');
  }
  for (const i of counted) if (!i.totalsFetched) why.add('totals_not_fetched');
  const ids = new Set(counted.map((i) => i.id));

  // FEC totals per cycle. Two ids can share one committee; FEC then reports identical totals under both, and
  // summing them doubles the cycle. Count an identical totals row once.
  const totals = new Map<number, { pac: number; refunds: number }>();
  const seen = new Set<string>();
  let careerReceipts = 0;
  let firstCycle: number | null = null;
  let lastCycle: number | null = null;
  let through: string | null = null;
  for (const t of p.totals) {
    if (!ids.has(t.id)) continue;
    const sig = [t.cycle, t.receipts, t.pac, t.pacRefunds, t.coverageEnd].join('|');
    if (seen.has(sig)) continue;
    seen.add(sig);
    careerReceipts += t.receipts ?? 0;
    firstCycle = Math.min(firstCycle ?? t.cycle, t.cycle);
    lastCycle = Math.max(lastCycle ?? t.cycle, t.cycle);
    if (t.coverageEnd && (!through || t.coverageEnd > through)) through = t.coverageEnd;
    const cur = totals.get(t.cycle) ?? { pac: 0, refunds: 0 };
    cur.pac += t.pac ?? 0;
    cur.refunds += t.pacRefunds ?? 0;
    totals.set(t.cycle, cur);
  }

  // Committees serving the counted ids, per cycle.
  const cmtesByCycle = new Map<number, Set<string>>();
  for (const c of p.committees) {
    if (!ids.has(c.id)) continue;
    (cmtesByCycle.get(c.cycle) ?? cmtesByCycle.set(c.cycle, new Set()).get(c.cycle)!).add(c.committeeId);
  }
  const reportsBy = new Map<string, ReportInput[]>(); // committee|cycle
  for (const r of p.reports) {
    const k = `${r.committeeId}|${r.cycle}`;
    (reportsBy.get(k) ?? reportsBy.set(k, []).get(k)!).push(r);
  }
  const giftsBy = new Map<string, GiftInput[]>(); // committee|reportKey
  for (const g of p.gifts) {
    const k = `${g.committeeId}|${g.reportKey}`;
    (giftsBy.get(k) ?? giftsBy.set(k, []).get(k)!).push(g);
  }

  const cycles = new Set<number>([...totals].filter(([, t]) => t.pac !== 0 || t.refunds !== 0).map(([c]) => c));
  for (const [cycle, cmtes] of cmtesByCycle) {
    for (const c of cmtes) if ((reportsBy.get(`${c}|${cycle}`) ?? []).length) cycles.add(cycle);
  }

  const kept = zero(); const received = zero(); const refunded = zero();
  const corpEvents = new Map<string, { cycle: number; amt: number }[]>();
  const checks: CycleCheck[] = [];

  for (const cycle of [...cycles].sort((a, b) => a - b)) {
    const cmtes = [...(cmtesByCycle.get(cycle) ?? [])];
    const pick = (prefer: 'efiling' | 'api') => {
      const chosen: ReportInput[] = [];
      const used = new Set<string>();
      for (const c of cmtes) {
        const rs = reportsBy.get(`${c}|${cycle}`) ?? [];
        const ef = rs.filter((r) => r.source === 'efiling');
        const api = rs.filter((r) => r.source === 'api');
        const take = prefer === 'efiling' ? (ef.length ? ef : api) : (api.length ? api : ef);
        chosen.push(...take);
        for (const r of take) used.add(r.source);
      }
      const pac = chosen.reduce((s, r) => s + r.itemized11c, 0);
      const refunds = chosen.reduce((s, r) => s + r.itemized20c, 0);
      const source: CycleCheck['source'] = used.size === 0 ? 'none' : used.size > 1 ? 'mixed' : ([...used][0] as 'efiling' | 'api');
      return { chosen, pac, refunds, source };
    };
    const t = totals.get(cycle);
    const ok = (x: { pac: number; refunds: number }) => !!t && reconciles(x.pac, t.pac) && reconciles(x.refunds, t.refunds);
    const ef = pick('efiling');
    const api = pick('api');
    const use = ok(ef) ? ef : ok(api) ? api : ef;
    const reconciled = ok(use);
    if (!t) why.add('no_totals_for_cycle');
    else if (!reconciled) why.add('cycle_unreconciled');
    checks.push({ cycle, fecPac: t?.pac ?? null, fecRefunds: t?.refunds ?? null, itemizedPac: round2(use.pac), itemizedRefunds: round2(use.refunds), source: use.source, reconciled });

    for (const r of use.chosen) {
      for (const g of giftsBy.get(`${r.committeeId}|${r.reportKey}`) ?? []) {
        let b: Bucket = (g.giverId ? committeeKindAt(kinds, g.giverId, cycle) : undefined) ?? 'unknown';
        if (b === 'unknown' && partyByName(g.giverName)) b = 'party';
        received[b] += g.received;
        refunded[b] += g.refunded;
        kept[b] += g.received - g.refunded;
        if (b === 'corporate') {
          const ev = corpEvents.get(g.giverKey) ?? [];
          if (g.received) ev.push({ cycle, amt: g.received });
          if (g.refunded) ev.push({ cycle, amt: -g.refunded });
          corpEvents.set(g.giverKey, ev);
        }
      }
    }
  }
  for (const b of BUCKETS) { kept[b] = round2(kept[b]); received[b] = round2(received[b]); refunded[b] = round2(refunded[b]); }
  if (kept.unknown > 0.005) why.add('unknown_giver');

  const blocksAll = why.has('totals_not_fetched') || why.has('shared_id') || why.has('id_needs_review');
  let verdict: Verdict;
  if (kept.corporate > 0.005) verdict = 'takes_corporate';
  else if (careerReceipts <= 0 && !blocksAll) verdict = 'no_receipts';
  else if (why.size > 0) verdict = 'unverified';
  else if (kept.trade + kept.coop + kept.other_pac > 0.005) verdict = 'no_corporate_pac';
  else verdict = 'no_pac';

  return {
    politicianId: p.politicianId, verdict, why: [...why].sort(), kept, received, refunded,
    lastCorporateCycle: lastKeptCycle(corpEvents), careerReceipts: round2(careerReceipts), firstCycle, lastCycle, through,
    cycles: checks, fecIds: [...ids].sort(),
  };
}
