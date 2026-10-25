/**
 * pilotImport.ts — adapters that turn finished Season 3 pilot folders into source-store records.
 *
 * Why: the pilots (equity programs, homelessness) already found bills, votes, rosters and dead ends.
 * Importing them lets later topics reuse that work instead of searching again. Each adapter knows ONE
 * file shape, maps only fields that exist in the files (nothing is invented) and returns records that
 * already pass the source-store schemas. Free-text notes are not converted (spec section 9 item 4).
 *
 * Pure filesystem helpers: reads the pilot folder, no db.js import, no network, no store writes.
 * Writing into the store is done by scripts/import-pilot-sources.ts.
 *
 * Provenance rule for imported records: `fetched_by` = "pilot-import (<pilot folder name>)",
 * `fetched_at` = the pilot file's recorded fetch date if it has one, else the file's mtime (ISO),
 * `method` from the file if recorded (access note naming curl or a browser), else "webfetch".
 * Saved copies found in the pilot's raw/ folder become `saved_copy` (absolute path + SHA-256).
 *
 * School-district scopes: a district is written as `school:<7-digit geoid>`, using the geoid
 * essentials.districts holds for the SCHOOL district row (state FIPS + 5-digit district code).
 */
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { basename, dirname, join, relative, resolve } from 'node:path';
import {
  DeadEndSchema, InstrumentIdSchema, InstrumentSchema, JurisdictionSchema, PersonSourcesSchema,
  type DeadEnd, type Instrument, type Jurisdiction, type PersonSources, type Provenance, type Vote,
} from './sourceStore.js';

export type PilotOutput = {
  instruments: Instrument[];
  people: PersonSources[];
  jurisdictions: Jurisdiction[];
  deadEnds: DeadEnd[];
};
export type PilotAdapter = {
  name: string;
  matches(dir: string): boolean;
  /** `researchRoot` is the folder holding all pilot folders; saved-copy paths are stored relative to it. */
  read(dir: string, researchRoot?: string): PilotOutput;
};

/** Notes the adapters add to the report (ids built, records skipped). Filled during read(). */
export type ImportNotes = { constructedIds: string[]; skipped: string[]; noRuling: string[]; unknownMotions: string[] };
export const importNotes: ImportNotes = { constructedIds: [], skipped: [], noRuling: [], unknownMotions: [] };
export function resetImportNotes(): void {
  importNotes.constructedIds = [];
  importNotes.skipped = [];
  importNotes.noRuling = [];
  importNotes.unknownMotions = [];
}

// ---------- small helpers ----------

const SEASON = 3;
const CODEBOOK = '0.6';
const TOPIC_LIST_HASH = 'pilot-unrecorded';

const readJson = <T = any>(file: string): T => JSON.parse(readFileSync(file, 'utf8')) as T;
const has = (dir: string, ...names: string[]) => names.every((n) => existsSync(join(dir, n)));
/** `meta.topic` (or `topic`) of a pilot JSON file, so one adapter never reads another topic's folder of the same shape. */
function topicOf(file: string): string | undefined {
  if (!existsSync(file)) return undefined;
  try { const j = readJson(file); return j?.meta?.topic ?? j?.topic; } catch { return undefined; }
}
const mtimeIso = (file: string) => statSync(file).mtime.toISOString();

export function sha256File(file: string): string {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}

/** Tab-separated file with a header row → array of objects. */
export function readTsv(file: string): Record<string, string>[] {
  const lines = readFileSync(file, 'utf8').split('\n').filter((l) => l.trim() !== '');
  const head = lines[0].split('\t');
  return lines.slice(1).map((l) => {
    const cells = l.split('\t');
    return Object.fromEntries(head.map((h, i) => [h, cells[i] ?? '']));
  });
}

const isUuid = (s: unknown): s is string => typeof s === 'string' && PersonSourcesSchema.shape.politician_id.safeParse(s).success;

/** Research root of the current read(); saved-copy paths are written relative to it (the store is shared). */
let ctxRoot = '';
const setRoot = (dir: string, root?: string) => { ctxRoot = resolve(root ?? dirname(dir)); };
/** Another pilot folder's file (the census a pilot was built from), or undefined when it is not there. */
function sibling(folder: string, ...parts: string[]): string | undefined {
  const f = join(ctxRoot, folder, ...parts);
  return existsSync(f) ? f : undefined;
}

/** "browser user agent" is a curl header, not the browser tool. */
const mentionsBrowserTool = (t: string) => /browser/i.test(t.replace(/browser user[- ]agent/gi, ''));

/** The method the pilot recorded in its access note; `unrecorded` when it recorded none. */
function methodFromNote(note: unknown): Provenance['method'] {
  const t = typeof note === 'string' ? note : '';
  if (/curl/i.test(t)) return 'curl';
  if (mentionsBrowserTool(t)) return 'browser';
  if (/webfetch/i.test(t)) return 'webfetch';
  return 'unrecorded';
}

function provenance(label: string, file: string, method: Provenance['method'] = 'unrecorded', savedCopy?: string): Provenance {
  const p: Provenance = { fetched_by: `pilot-import (${label})`, fetched_at: mtimeIso(file), method };
  if (savedCopy && existsSync(savedCopy)) {
    p.saved_copy = { path: relative(ctxRoot, resolve(savedCopy)), sha256: sha256File(savedCopy) };
  }
  return p;
}

const yearOf = (s: unknown): number | undefined => {
  const m = typeof s === 'string' ? s.match(/\b(19|20)\d{2}\b/) : null;
  return m ? Number(m[0]) : undefined;
};

const sanitizeId = (s: string) => s.replace(/[^A-Za-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

/** Use the pilot's own id when it already fits the store's regex; otherwise build `<STATE>-<id>-<YEAR>`. */
export function fitInstrumentId(pilotId: string, state: string, year: number): string {
  if (InstrumentIdSchema.safeParse(pilotId).success) return pilotId;
  const core = sanitizeId(pilotId);
  const prefixed = core.toUpperCase().startsWith(`${state.toUpperCase()}-`) ? core : `${state.toUpperCase()}-${core}`;
  const id = /-\d{4}$/.test(prefixed) ? prefixed : `${prefixed}-${year}`;
  importNotes.constructedIds.push(`${pilotId} -> ${id}`);
  return id;
}

/** State bill id: `WA`, `ESSB 5044`, year → `WA-ESSB-5044-2021`. Always constructed. */
export function stateBillId(state: string, bill: string, year: number): string {
  const m = bill.match(/((?:[A-Z]+\/)*)([A-Z][A-Za-z.]*)\s*(\d+)/);
  if (!m) throw new Error(`cannot build instrument id from "${bill}"`);
  const type = m[2].replace(/\./g, '');
  const id = `${state.toUpperCase()}-${type}-${m[3]}-${year}`;
  importNotes.constructedIds.push(`${state} ${bill} -> ${id}`);
  return id;
}

const NUMBER_WORDS: Record<string, number> = {
  zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10, eleven: 11, twelve: 12,
};

/** Read a vote tally the way the pilots printed it. Returns undefined when it cannot be read. */
export function parseTally(s: unknown): { yes: number; no: number } | undefined {
  if (typeof s !== 'string') return undefined;
  let m = s.match(/^\s*(\d+)\s*[-–]\s*(\d+)/);
  if (m) return { yes: Number(m[1]), no: Number(m[2]) };
  m = s.match(/majority do pass\s+(\d+);\s*minority do not pass\s+(\d+)/i);
  if (m) return { yes: Number(m[1]), no: Number(m[2]) };
  m = s.match(/^\s*(\w+)-to-(\w+)\s*$/i);
  if (m && NUMBER_WORDS[m[1].toLowerCase()] !== undefined && NUMBER_WORDS[m[2].toLowerCase()] !== undefined) {
    return { yes: NUMBER_WORDS[m[1].toLowerCase()], no: NUMBER_WORDS[m[2].toLowerCase()] };
  }
  m = s.match(/(?:ayes?|yeas?|yes|for)\b\W*\(?(\d+)\)?\W+(?:nays?|noes?|no|against)\b\W*\(?(\d+)\)?/i);
  if (m) return { yes: Number(m[1]), no: Number(m[2]) };
  return undefined;
}

const voteKind = (act: string): 'yea' | 'nay' | 'abstain' | 'absent' | 'recused' | undefined => {
  const a = act.toLowerCase();
  if (a === 'yes' || a === 'yea') return 'yea';
  if (a === 'no' || a === 'nay') return 'nay';
  if (a === 'abstain') return 'abstain';
  if (a === 'absent') return 'absent';
  if (a === 'recused') return 'recused';
  return undefined;
};

const usps = (s: string) => s.toLowerCase();

function mergePortals(list: Jurisdiction['portals']): Jurisdiction['portals'] {
  const m = new Map<string, Jurisdiction['portals'][number]>();
  for (const p of list) if (!m.has(p.url)) m.set(p.url, p);
  return [...m.values()];
}

function jurisdictionsFromPortals(byScope: Map<string, Jurisdiction['portals']>): Jurisdiction[] {
  return [...byScope.entries()].map(([scope, portals]) =>
    JurisdictionSchema.parse({ scope, portals: mergePortals(portals), rosters: [], higher_law_duties: [] }),
  );
}

function portalFor(sourceUrl: string, note: unknown, prov: Provenance): Jurisdiction['portals'][number] | undefined {
  let origin: string;
  try { origin = new URL(sourceUrl).origin + '/'; } catch { return undefined; }
  const n = typeof note === 'string' ? note : '';
  const status = mentionsBrowserTool(n) ? 'needs-browser' : 'works';
  const how = n.trim().slice(0, 240);
  return { name: new URL(origin).host, url: origin, status, how: how || undefined, checked_at: prov.fetched_at, provenance: prov };
}

/** Single-subject ruling entry; written only when the pilot's own census ruled the instrument `count`. */
const singleSubject = (ruled: boolean) =>
  ruled ? [{ season: SEASON, codebook: CODEBOOK, topic_list_hash: TOPIC_LIST_HASH, verdict: 'single' as const, other_topics: [] as string[] }] : [];

/** `HB 324`-style key (type + number) used to line up bills across the pilot's files. */
const billKey = (bill: string): string | undefined => {
  const m = bill.match(/((?:[A-Z]+\/)*)([A-Z][A-Za-z.]*)\s*(\d+)/);
  return m ? `${m[2].replace(/\./g, '')}-${m[3]}` : undefined;
};

/** Verdicts the equity supplement census recorded: law key `WA|ESSB-5044` and school key `Virginia|2025-04-08|15.F`. */
function equityVerdicts(file: string | undefined): { law: Map<string, string>; school: Map<string, string> } {
  const law = new Map<string, string>();
  const school = new Map<string, string>();
  if (!file) return { law, school };
  const j = readJson(file);
  for (const l of j.state ?? []) { const k = billKey(String(l.bill)); if (k) law.set(`${l.state}|${k}`, String(l.verdict)); }
  for (const r of j.school ?? []) school.set(`${String(r.body).split(' ')[0]}|${r.date}|${r.item_no}`, String(r.verdict));
  return { law, school };
}


// ---------- equity Stage 1 ----------

const EQUITY_STAGE1 = 's3-pilot-equity-programs/stage1';

/** Operative text in the pilot is a list of {section, quote}, an object with `quotes`, or a string. */
function operativeToString(op: unknown): string | undefined {
  if (typeof op === 'string') return op;
  if (Array.isArray(op)) {
    return op.map((x) => (typeof x === 'string' ? x : x?.section ? `${x.section}: ${x.quote}` : String(x?.quote ?? ''))).filter(Boolean).join('\n');
  }
  if (op && typeof op === 'object' && Array.isArray((op as any).quotes)) return (op as any).quotes.join('\n');
  return undefined;
}

function savedCopyFromNote(dir: string, note: unknown): string | undefined {
  const m = typeof note === 'string' ? note.match(/raw\/[A-Za-z0-9_./-]+\.(?:pdf|html)/) : null;
  return m ? join(dir, m[0]) : undefined;
}

/** Split the pilot's one record for the VA pair into HB 1904 and SB 1196 (the pilot ruled them two records, G6). */
function splitStateInstruments(list: any[]): any[] {
  const out: any[] = [];
  for (const i of list) {
    if (!String(i.id).includes('+')) { out.push(i); continue; }
    const [a, b] = String(i.id).split('+');
    const st = a.split('-')[0];
    out.push({ ...i, id: a, title: i.title, bill_label: a.replace(/-/g, ' ').replace(/^\w\w /, '') });
    const url24 = typeof i.chapter_24_identical === 'string' ? i.chapter_24_identical.match(/https?:\/\/\S+CHAP0024/)?.[0] : undefined;
    out.push({ ...i, id: `${st}-${b}`, bill_label: b.replace(/-/g, ' '), source_url: url24 ?? i.source_url, copy_of: a, access_note: i.access_note?.replace(/ch23\.html/, 'ch24.html') });
  }
  return out;
}

const BOARD_SHORT: Record<string, string> = { VB: 'VBCPS', MCCSC: 'MCCSC' };
/** Districts resolved with a read-only query of essentials.districts (geo_id of the SCHOOL district row). */
const BOARD_SCOPE: Record<string, string> = { VB: 'school:5103840', MCCSC: 'school:1800630' };

const equityStage1: PilotAdapter = {
  name: 'equity-stage1',
  matches: (dir) => has(dir, 'texts-state.json', 'texts-boards.json', 'school-voters.tsv') && topicOf(join(dir, 'test-set-v1.json')) === 'education-equity-programs',
  read(dir, researchRoot) {
    setRoot(dir, researchRoot);
    const verdicts = equityVerdicts(sibling(EQUITY_SUPP, 'stage0-supplement.json'));
    const ruled = (kind: 'law' | 'school', key: string, id: string) => {
      const v = verdicts[kind].get(key);
      if (v === 'count') return true;
      importNotes.noRuling.push(`${id}: census verdict ${v ?? 'not found'} (single_subject left empty)`);
      return false;
    };
    const instruments: Instrument[] = [];
    const portals = new Map<string, Jurisdiction['portals']>();
    const addPortal = (scope: string, p?: Jurisdiction['portals'][number]) => { if (p) portals.set(scope, [...(portals.get(scope) ?? []), p]); };

    // State laws: text, URL, single-subject ruling. Roll calls come from the supplement adapter (full lists).
    const stateFile = join(dir, 'texts-state.json');
    for (const i of splitStateInstruments(readJson(stateFile).instruments)) {
      const state = String(i.state);
      const year = yearOf(i.date_approved) ?? yearOf(i.session)!;
      const label = String(i.bill_label ?? i.id.replace(/^[A-Z]{2}-/, '').replace(/-/g, ' '));
      const id = stateBillId(state, label, year);
      const prov = provenance(EQUITY_STAGE1, stateFile, methodFromNote(i.access_note), savedCopyFromNote(dir, i.access_note));
      instruments.push(InstrumentSchema.parse({
        id, scope: `state:${usps(state)}`, title: String(i.title), urls: i.source_url ? [i.source_url] : [], version: 'enrolled',
        operative_text: operativeToString(i.operative_text), single_subject: singleSubject(ruled('law', `${state}|${billKey(label)}`, id)), votes: [], provenance: prov,
      }));
      addPortal(`state:${usps(state)}`, portalFor(String(i.source_url), i.access_note, prov));
    }

    // School boards: vote lists from school-voters.tsv.
    const boardsFile = join(dir, 'texts-boards.json');
    const voters = readTsv(join(dir, 'school-voters.tsv'));
    for (const b of readJson(boardsFile).instruments) {
      const short = String(b.id).split('-')[0];
      const state = String(b.state);
      const year = yearOf(b.date)!;
      const item = String(b.item ?? '').replace(/\./g, '');
      const isPolicy = /^Policy\s+(\d+)/.exec(String(b.title));
      const mmdd = String(b.date).slice(5).replace('-', '');
      const num = isPolicy ? isPolicy[1] : `${mmdd}-${item}`;
      const id = `${state}-${BOARD_SHORT[short] ?? short}-${num}-${year}`;
      InstrumentIdSchema.parse(id);
      importNotes.constructedIds.push(`${b.id} -> ${id}`);
      const scope = BOARD_SCOPE[short];
      if (!scope) throw new Error(`no scope known for board ${short}`);
      const saved = typeof b.source_url === 'string' ? join(dir, 'raw', 'vb', basename(new URL(b.source_url).pathname)) : undefined;
      const prov = provenance(EQUITY_STAGE1, boardsFile, methodFromNote(b.access_note), short === 'VB' ? saved : undefined);
      const rows = voters.filter((r) => r.instrument === b.id);
      let tally = parseTally(b.tally);
      if (!tally && /(\d+)\s+Yea/i.test(String(b.tally))) tally = { yes: Number(/(\d+)\s+Yea/i.exec(String(b.tally))![1]), no: 0 };
      const votes: Vote[] = [];
      if (tally && rows.length) {
        votes.push({
          date: String(b.date), body: String(b.body).replace(/\s*\(.*\)$/, ''), motion: String(b.title), kind: 'action-item',
          yes: tally.yes, no: tally.no,
          ...(/(\d+)\s+Yea listed/i.test(String(b.tally)) && !parseTally(b.tally)
            ? { note: 'Nay count not printed in the minutes (7 Yea listed; no nays recorded): 0 nays inferred, not stated.' }
            : {}),
          ...(rows.some((r) => r.vote === 'absent') ? { absent: rows.filter((r) => r.vote === 'absent').length } : {}),
          members: rows.map((r) => ({
            name: r.db_person || r.printed_name,
            ...(isUuid(r.politician_id) ? { politician_id: r.politician_id } : {}),
            vote: voteKind(r.vote) ?? 'abstain',
          })),
        });
      } else importNotes.skipped.push(`equity-stage1 ${b.id}: vote not imported (no readable tally or no voter rows)`);
      const passed = /passed|carries/i.test(String(b.tally));
      instruments.push(InstrumentSchema.parse({
        id, scope, title: String(b.title), urls: b.source_url ? [b.source_url] : [], version: passed && !isPolicy ? 'adopted' : 'other',
        operative_text: operativeToString(typeof b.operative_text === 'string' ? b.operative_text : b.operative_text), single_subject: singleSubject(ruled('school', `${String(b.body).split(' ')[0]}|${b.date}|${b.item}`, id)), votes, provenance: prov,
      }));
      addPortal(scope, portalFor(String(b.source_url), b.access_note, prov));
    }
    return { instruments, people: [], jurisdictions: jurisdictionsFromPortals(portals), deadEnds: [] };
  },
};

// ---------- equity census supplement ----------

const EQUITY_SUPP = 's3-census-education-equity-programs-supplement';

const OFFICE_BY_TYPE: Record<string, (st: string) => string> = {
  STATE_UPPER: (st) => `State Senate (${st.toUpperCase()})`,
  STATE_LOWER: (st) => `State House (${st.toUpperCase()})`,
};

function deadEndResult(note: string): DeadEnd['result'] {
  return /\b403\b|refus|not fetchable|not permitted|unable to fetch|blocked|rate-limited/i.test(note) ? 'blocked' : 'nothing';
}

/**
 * Members who did not vote, from a roll call's `other_names`. A label in brackets after a name applies to
 * every unlabelled name before it ("Acevero", "Martinez (not voting)", "Crosby", "Woods (excused/absent)" means
 * Acevero and Martinez are not voting; Crosby and Woods are excused). Counts are checked against the roll
 * call's printed `other` line and a mismatch throws, so a bad reading never reaches the store.
 */
export function parseOtherNames(names: string[], other: string, where: string): { name: string; vote: 'absent' | 'abstain' }[] {
  const out: { name: string; vote: 'absent' | 'abstain' }[] = [];
  let group: string[] = [];
  for (const raw of names) {
    const m = raw.match(/^(.*?)\s*\(([^)]*)\)\s*$/);
    group.push(m ? m[1] : raw);
    if (!m) continue;
    const vote = /not voting|present/i.test(m[2]) ? 'abstain' : /excused|absent/i.test(m[2]) ? 'absent' : undefined;
    if (!vote) throw new Error(`${where}: unknown label "${m[2]}" in other_names`);
    for (const g of group) out.push({ name: g, vote });
    group = [];
  }
  if (group.length) throw new Error(`${where}: names with no group label after them: ${group.join(', ')}`);
  const sum = (res: RegExp[]) => res.reduce((n, re) => n + [...other.matchAll(re)].reduce((k, x) => k + Number(x[1]), 0), 0);
  const expectNotVoting = sum([/not voting[:\s]+(\d+)/gi, /(\d+)\s+not voting/gi]);
  const expectAbsent = sum([/(?:absent|excused)[:\s]+(\d+)/gi, /(\d+)\s+(?:absent|excused)/gi]);
  const gotNotVoting = out.filter((o) => o.vote === 'abstain').length;
  const gotAbsent = out.filter((o) => o.vote === 'absent').length;
  if (gotNotVoting !== expectNotVoting || gotAbsent !== expectAbsent) {
    throw new Error(`${where}: other_names give ${gotNotVoting} not voting / ${gotAbsent} absent but the roll call says "${other}"`);
  }
  return out;
}

const equitySupplement: PilotAdapter = {
  name: 'equity-supplement',
  matches: (dir) => has(dir, 'identity-check.json', 'stage0-supplement.json') && topicOf(join(dir, 'stage0-supplement.json')) === 'education-equity-programs',
  read(dir, researchRoot) {
    setRoot(dir, researchRoot);
    const idFile = join(dir, 'identity-check.json');
    const idRows: any[] = readJson(idFile);
    const prov = (file: string) => provenance(EQUITY_SUPP, file, 'unrecorded');
    const supp = readJson(join(dir, 'stage0-supplement.json'));
    const verdicts = equityVerdicts(join(dir, 'stage0-supplement.json'));

    // Person term rows: seated people (identity-check OK) joined to the roster export's term dates.
    const people: PersonSources[] = [];
    const rosterFile = join(dir, 'raw', 'roster-legislators.tsv');
    if (existsSync(rosterFile)) {
      const roster = new Map<string, Record<string, string>[]>();
      for (const r of readTsv(rosterFile)) roster.set(r.id, [...(roster.get(r.id) ?? []), r]);
      const seen = new Set<string>();
      for (const r of idRows) {
        if (r.verdict !== 'OK' || !isUuid(r.id) || seen.has(r.id)) continue;
        seen.add(r.id);
        const terms = (roster.get(r.id) ?? []).map((t) => {
          const precision = (['day', 'month', 'year'] as const).find((p) => p === t.start_precision) ?? 'unknown';
          return {
            office: (OFFICE_BY_TYPE[t.district_type] ?? (() => t.district_type))(t.st),
            ...(t.term_start ? { start: t.term_start } : {}),
            ...(t.term_end ? { end: t.term_end } : {}),
            precision: t.term_start ? precision : ('unknown' as const),
            source: `essentials roster export (${EQUITY_SUPP}/raw/roster-legislators.tsv)`,
          };
        });
        if (terms.length) people.push(PersonSourcesSchema.parse({ politician_id: r.id, sources: [], terms }));
        else importNotes.skipped.push(`equity-supplement person ${r.id} (${r.db}): no row in roster-legislators.tsv, no term written`);
      }
    }

    // Full roll calls for the seven counted laws, with politician ids from the identity check.
    const instruments: Instrument[] = [];
    const s2File = join(dir, 'raw', 's2-pro-equity.json');
    if (existsSync(s2File)) {
      const key = (state: string, bill: string, chamber: string, date: string, printed: string, side: string) =>
        [state, bill, chamber[0], date, printed, side].join('|');
      const ok = new Map<string, any>();
      for (const r of idRows) if (r.verdict === 'OK') ok.set(key(r.state, r.bill, r.chamber, r.date, r.printed, r.side), r);
      const counted = new Set(idRows.map((r) => `${r.state}|${r.bill}`));
      for (const law of readJson(s2File).laws) {
        if (!counted.has(`${law.state}|${law.bill}`)) continue;
        const year = yearOf(String(law.bill).slice(String(law.bill).indexOf('(')).replace(/Ch\.\s*\d+/g, ''))!;
        const id = stateBillId(law.state, String(law.bill), year);
        const member = (printed: string, chamber: string, date: string, side: string, vote: 'yea' | 'nay' | 'absent' | 'abstain') => {
          const base = printed.replace(/\s*\([^)]*\)\s*$/, '').replace(/\*$/, '');
          const hit = ok.get(key(law.state, law.bill, chamber, date, printed, side)) ?? ok.get(key(law.state, law.bill, chamber, date, base, side));
          return { name: hit?.db ?? base, ...(hit && isUuid(hit.id) ? { politician_id: hit.id } : {}), vote };
        };
        const votes: Vote[] = (law.rollcalls ?? []).map((rc: any) => {
          const where = `${law.state} ${law.bill} ${rc.chamber} ${rc.date}`;
          const others = parseOtherNames(rc.other_names ?? [], String(rc.other ?? ''), where);
          const members = [
            ...(rc.yea_names ?? []).map((n: string) => member(n, rc.chamber, rc.date, 'yea', 'yea')),
            ...(rc.nay_names ?? []).map((n: string) => member(n, rc.chamber, rc.date, 'nay', 'nay')),
            // parseOtherNames keeps the input order, so others[i] belongs to other_names[i]
            ...(rc.other_names ?? []).map((n: string, i: number) => member(n, rc.chamber, rc.date, 'other', others[i].vote)),
          ];
          const absent = members.filter((m) => m.vote === 'absent').length;
          return {
            date: String(rc.date), body: `${law.state} ${rc.chamber}`, motion: String(rc.motion), kind: 'roll-call' as const,
            yes: Number(rc.yeas), no: Number(rc.nays), ...(absent > 0 ? { absent } : {}), members,
          };
        });
        const urls = [...new Set<string>((law.rollcalls ?? []).map((rc: any) => rc.url).filter(Boolean))];
        instruments.push(InstrumentSchema.parse({
          id, scope: `state:${usps(law.state)}`, title: String(law.subject), urls, version: 'enrolled', single_subject: singleSubject(((): boolean => {
            const v = verdicts.law.get(`${law.state}|${billKey(String(law.bill))}`);
            if (v !== 'count') importNotes.noRuling.push(`${id}: census verdict ${v ?? 'not found'} (single_subject left empty)`);
            return v === 'count';
          })()), votes,
          provenance: prov(s2File),
        }));
      }
    }

    // Blocked-portal notes become dead ends (one per note), dated at the pilot's census date.
    const deadEnds: DeadEnd[] = [];
    const at = String(supp.date ?? mtimeIso(join(dir, 'stage0-supplement.json')));
    const rawDir = join(dir, 'raw');
    for (const f of existsSync(rawDir) ? ['c0-carried-boards.json', 'e1-virginia.json', 'e2-oregon.json', 'e3-ca-large.json', 'e4-la-county.json', 'e5-tx-fl-mo-nv.json', 'e6-in-mn-md-ut.json', 'e7-ma-me.json', 'e8-offroster.json'] : []) {
      const file = join(rawDir, f);
      if (!existsSync(file)) continue;
      for (const b of readJson(file).boards ?? []) {
        for (const note of b.blocked ?? []) {
          if (typeof note !== 'string' || !note.trim() || /^none\b/i.test(note)) continue;
          deadEnds.push(DeadEndSchema.parse({
            at, ...(/^[A-Za-z]{2}$/.test(String(b.state ?? '')) ? { scope: `state:${usps(b.state)}` } : {}),
            query_or_url: `${b.body}: ${note}`, result: deadEndResult(note), by: `pilot-import (${EQUITY_SUPP})`,
          }));
        }
      }
    }
    return { instruments, people, jurisdictions: [], deadEnds };
  },
};

// ---------- homelessness Stage 1 ----------

const HOMELESS = 's3-pilot-homelessness-stage1';

/** Local governments resolved with a read-only query of essentials.governments (geo_id column). */
const LOCAL_GOVERNMENTS: Record<string, { state: string; scope: string }> = {
  'City of Atlanta, Georgia, US': { state: 'GA', scope: 'place:1304000' },
  'City of Berkeley': { state: 'CA', scope: 'place:0606000' },
  'City of Bloomington, Indiana, US': { state: 'IN', scope: 'place:1805860' },
  'City of Colorado Springs, Colorado, US': { state: 'CO', scope: 'place:0816000' },
  'Columbus Consolidated Government, Georgia, US': { state: 'GA', scope: 'place:1319000' },
  'DeKalb County, Georgia, US': { state: 'GA', scope: 'county:13089' },
  'City of Duluth, Minnesota, US': { state: 'MN', scope: 'place:2717000' },
  'City of Huntington Beach, California, US': { state: 'CA', scope: 'place:0636000' },
  'Los Angeles, California, US': { state: 'CA', scope: 'place:0644000' },
  'City of Las Vegas, Nevada, US': { state: 'NV', scope: 'place:3240000' },
  'City of Miami, Florida, US': { state: 'FL', scope: 'place:1245000' },
  'Metropolitan Government of Nashville and Davidson County, Tennessee, US': { state: 'TN', scope: 'county:47037' },
  'City of Palm Springs, California, US': { state: 'CA', scope: 'place:0655254' },
  'City of Portland, Oregon, US': { state: 'OR', scope: 'place:4159000' },
  'City of Sacramento': { state: 'CA', scope: 'place:0664000' },
  'City of San Diego': { state: 'CA', scope: 'place:0666000' },
  'City and County of San Francisco': { state: 'CA', scope: 'place:0667000' },
  'City of St. Louis, Missouri, US': { state: 'MO', scope: 'place:2965000' },
};

function homelessInstrumentId(item: any, lastYear: number): { id: string; scope: string } {
  const pilotId = String(item.instrument);
  if (item.level === 'federal') {
    const m = pilotId.match(/^US\s+(H\.R\.|S\.)\s*(\d+)/);
    if (!m) throw new Error(`cannot read federal id ${pilotId}`);
    const id = `US-${m[1].replace(/\./g, '')}-${m[2]}-${lastYear}`;
    importNotes.constructedIds.push(`${pilotId} -> ${id}`);
    return { id, scope: 'federal' };
  }
  if (item.level === 'state') {
    const state = pilotId.slice(0, 2);
    return { id: stateBillId(state, pilotId.slice(3), lastYear), scope: `state:${usps(state)}` };
  }
  const gov = LOCAL_GOVERNMENTS[String(item.gov)];
  if (!gov) throw new Error(`no scope known for government "${item.gov}"`);
  return { id: fitInstrumentId(pilotId, gov.state, lastYear), scope: gov.scope };
}

/** Pilot instrument id → text that identifies its records in the census (the pilot's own INSTR table). */
const CENSUS_LOCAL_KEY: Record<string, string> = {
  'LA-LAMC-41.18-amend-2022': 'LA 41.18 amendment (2022)', 'LA-LAMC-41.18-2021': 'LA LAMC 41.18 (2021)',
  'BERKELEY-RES-37-2024': 'Berkeley City Council 37', 'HUNTINGTON-BEACH-ORD-4273': 'HB Ord 4273',
  'SACRAMENTO-12.74.030-2025': 'Sacramento City Council 2025-01309', 'SAN-DIEGO-O-21674': 'O-21674',
  'SF-LARGE-VEHICLE-2025': 'San Francisco Board of Supervisors', 'COLORADO-SPRINGS-ORD-26-08': '26-08',
  'PORTLAND-ENFORCEMENT-DIRECTIVE-2025': 'Portland enforcement directive', 'LAS-VEGAS-BILL-2024-29': 'LV Bill 2024-29',
  'ATLANTA-CLEARING-MACHINERY-2025': 'Atlanta clearing-machinery', 'DEKALB-2026-0550': 'DeKalb County 2026-0550',
  'COLUMBUS-GA-ORD-25-040': 'Columbus Consolidated Government Ordinance 25-040', 'ST-LOUIS-BB-14-2022': 'St. Louis Board Bill 14',
  'DULUTH-24-030-O': 'Duluth City Council 24-030-O', 'BLOOMINGTON-IN-ORD-21-06': 'Ordinance 21-06',
  'BLOOMINGTON-IN-ORD-23-20': 'Ordinance 23-20', 'PALM-SPRINGS-ORD-2099': 'Palm Springs Ord 2099',
  'NASHVILLE-BL2022-1533': 'Nashville BL2022-1533', 'MIAMI-WARNING-REPEAL-2026': 'City of Miami',
};

/** What the census (stage0-census.json, raw/F1-federal.json) says about one instrument: its `final` values and record URLs. */
function censusFor(group: any[], census: any, federal: any): { finals: Set<string>; urls: string[] } | undefined {
  if (!census) return undefined;
  const first = group[0];
  const finals = new Set<string>();
  const urls: string[] = [];
  const take = (r: any) => { if (r.final) finals.add(String(r.final)); if (typeof r.url === 'string' && r.url.startsWith('http')) urls.push(r.url); };
  if (first.level === 'local') {
    const key = CENSUS_LOCAL_KEY[String(first.instrument)];
    if (!key) return undefined;
    for (const r of census.local ?? []) if (`${r.instrument ?? ''} ${r.body} ${r.item ?? ''}`.includes(key)) take(r);
  } else if (first.level === 'federal') {
    const num = String(first.instrument).slice(3);
    for (const r of census.state ?? []) if (r.state === 'US' && r.bill === num) take(r);
    const b = (federal?.state_bills ?? []).find((x: any) => x.number === num);
    if (b) {
      if (!(b.bundled_funding === true || b.bundled_funding === 'True')) finals.add('count');
      else finals.add('multi');
      if (typeof b.url_text === 'string') urls.push(b.url_text);
    }
  } else {
    const st = String(first.instrument).slice(0, 2);
    const num = String(first.instrument).slice(3);
    for (const r of census.state ?? []) if (r.state === st && r.bill === num) take(r);
  }
  return finals.size ? { finals, urls } : undefined;
}

const NO_MOTION = /^(not retrieved|not obtained|n\/a|none)\b/i;

const homelessness: PilotAdapter = {
  name: 'homelessness-stage1',
  matches: (dir) => has(dir, 'test-set-v1.json', 'local-terms.json', 'excluded.json') && topicOf(join(dir, 'test-set-v1.json')) === 'homelessness',
  read(dir, researchRoot) {
    setRoot(dir, researchRoot);
    const censusFile = sibling('s3-census-homelessness', 'stage0-census.json');
    const census = censusFile ? readJson(censusFile) : undefined;
    const fedFile = sibling('s3-census-homelessness', 'raw', 'F1-federal.json');
    const federal = fedFile ? readJson(fedFile) : undefined;
    const file = join(dir, 'test-set-v1.json');
    const items: any[] = readJson(file).items;
    const suppFile = join(dir, 'test-set-v1-supp-governors.json');
    const all = items.filter((i) => i.kind === 'record' && i.instrument);
    if (existsSync(suppFile)) all.push(...readJson(suppFile).items.filter((i: any) => i.instrument));
    const prov = provenance(HOMELESS, file, 'unrecorded');

    const groups = new Map<string, any[]>();
    for (const i of all) groups.set(`${i.level}|${i.instrument}`, [...(groups.get(`${i.level}|${i.instrument}`) ?? []), i]);

    const instruments: Instrument[] = [];
    for (const [, group] of groups) {
      const first = group.find((g) => g.title) ?? group[0];
      const dates = group.flatMap((g) => (g.acts ?? []).map((a: any) => a.date)).filter(Boolean).sort();
      const year = yearOf(dates[dates.length - 1]) ?? yearOf(first.census_record?.status) ?? yearOf(first.session);
      if (!year) { importNotes.skipped.push(`homelessness ${first.instrument}: no year found, instrument not imported`); continue; }
      const { id, scope } = homelessInstrumentId(first, year);

      const voteMap = new Map<string, Vote>();
      let unreadable = 0;
      for (const it of group) {
        for (const a of it.acts ?? []) {
          const kind = voteKind(String(a.act ?? ''));
          if (!kind || kind === 'absent' || !a.date) continue;
          const tally = parseTally(a.tally);
          if (!tally) { unreadable++; continue; }
          const body = it.level === 'state' ? `${String(it.instrument).slice(0, 2)} ${a.chamber ?? 'Legislature'}`
            : it.level === 'federal' ? String(a.chamber ?? it.body ?? 'U.S. Congress') : String(it.body ?? 'U.S. Congress');
          const quoted = [it.census_record?.motion_quote, ...group.map((g) => g.census_record?.motion_quote)].find((q) => typeof q === 'string' && q.trim() && !NO_MOTION.test(q.trim()));
          const motion = a.motion ? String(a.motion) : quoted ? String(quoted).trim().slice(0, 300) : 'unknown (see pilot)';
          if (motion === 'unknown (see pilot)') importNotes.unknownMotions.push(`${id} ${a.date}: the pilot has no motion text`);
          const k = `${a.date}|${body}|${motion}`;
          let v = voteMap.get(k);
          if (!v) {
            v = { date: String(a.date), body, motion, kind: it.level === 'local' ? 'action-item' : 'roll-call', yes: tally.yes, no: tally.no, ...(it.body_size ? { body_size: Number(it.body_size) } : {}), members: [] };
            voteMap.set(k, v);
          }
          v.members.push({ name: String(it.name), ...(isUuid(it.politician_id) ? { politician_id: it.politician_id } : {}), vote: kind });
        }
      }
      if (unreadable) importNotes.skipped.push(`homelessness ${first.instrument}: ${unreadable} vote act(s) with an unreadable tally not imported`);
      // Official instrument URLs only: the acts' own URLs and the census record URL. Person sources
      // (campaign sites, news stories) stay out.
      const cen = censusFor(group, census, federal);
      const urls = [...new Set<string>([...group.flatMap((g) => (g.acts ?? []).map((a: any) => a.url)), ...(cen?.urls ?? [])].filter((u) => typeof u === 'string' && u.startsWith('http')))];
      const ruledSingle = !!cen && cen.finals.has('count') && !cen.finals.has('duty');
      if (!ruledSingle) importNotes.noRuling.push(`${id}: ${cen ? `census final ${[...cen.finals].join('/')}` : 'no census record found'} (single_subject left empty)`);
      const quote = first.census_record?.operative_quote;
      instruments.push(InstrumentSchema.parse({
        id, scope, title: String(first.title), urls, version: 'other',
        ...(typeof quote === 'string' && quote ? { operative_text: quote } : {}),
        single_subject: singleSubject(ruledSingle), votes: [...voteMap.values()], provenance: prov,
      }));
    }

    // Person term rows for people in the test set, from the Stage 1 read-only term query.
    const people: PersonSources[] = [];
    const termsFile = join(dir, 'local-terms.json');
    const inSet = new Set(all.map((i) => i.politician_id).filter(isUuid));
    const byPid = new Map<string, any[]>();
    for (const t of readJson<any[]>(termsFile)) if (inSet.has(t.pid)) byPid.set(t.pid, [...(byPid.get(t.pid) ?? []), t]);
    for (const [pid, rows] of byPid) {
      people.push(PersonSourcesSchema.parse({
        politician_id: pid, sources: [],
        terms: rows.map((t) => ({
          office: [t.title, t.gov].filter(Boolean).join(', ') || 'unknown office',
          ...(t.ts ? { start: t.ts } : {}), ...(t.te ? { end: t.te } : {}),
          precision: t.ts ? ((['day', 'month', 'year'] as const).find((p) => p === t.start_precision) ?? 'unknown') : 'unknown',
          source: `${HOMELESS}/local-terms.json (read-only essentials query)`,
        })),
      }));
    }
    return { instruments, people, jurisdictions: [], deadEnds: [] };
  },
};

export const ADAPTERS: PilotAdapter[] = [equityStage1, equitySupplement, homelessness];
