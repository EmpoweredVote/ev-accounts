/**
 * identityMatch — tie each name printed on a roll call to one roster politician, or refuse to.
 *
 * Why: the season-topic-prep skill's Stage 0 census counts how many of a topic's politicians cast a
 * recorded vote on an instrument. Roll calls print a surname ("Taylor"), sometimes with initials
 * ("Smith, J.") or a state ("Smith (TX)"). Linking that by surname alone once credited a vote by a
 * past member to a different person with the same surname on today's roster (voting-rights census,
 * 2026-10-20, caught only by an audit). A false link is worse than no link: it seats a politician on a
 * vote they never cast.
 *
 * So the chain is strict, and every step must land on exactly one person:
 *   state roll call: printed name -> exactly one member on that chamber's official member list for the
 *   session of the vote (surname, narrowed by first initial when one is printed) -> that member's full
 *   name -> exactly one roster person in the same state with the same surname AND an agreeing first
 *   name (first three letters, or a quoted nickname on either side).
 *   federal roll call: surname (plus the printed state, when given) -> exactly one roster member of that
 *   chamber of Congress, confirmed only when their current term began on or before the vote.
 * Never surname alone. Never "the first name appears somewhere in the string". A name that fits two
 * people stays unlinked ('ambiguous'), and `politician_id` is set only on a 'confirmed' result.
 *
 * Grades: confirmed | not-in-roster (fits a session member, but no roster person: usually a past
 * member) | ambiguous | no-session-list (no member list for that year) | unmatched (printed name fits
 * no session member) | prior-service (federal: the roster person's term began after the vote, or the
 * start is unknown, so the roster cannot show they cast it).
 *
 * Ported from the voting-rights Stage 0 research script (identity.py), with its loose matches
 * (surname anywhere in a name's words) removed. Pure module: no file or database access.
 */

export type Chamber = 'house' | 'senate';

export interface SessionList {
  /** USPS code, upper-case. */
  state: string;
  chamber: Chamber;
  /** Free text that names the session's years, e.g. "82nd (2011)" or "2021-2022". */
  session: string;
  source_url: string;
  members: Array<{ full_name: string }>;
}

export interface RosterPerson {
  id: string;
  full_name: string;
  first_name?: string;
  last_name?: string;
  /** USPS code, upper-case. */
  state: string;
  level: 'state' | 'federal';
  chamber?: Chamber;
  /** ISO date the person's current term began. */
  term_start?: string;
}

export interface RollCall {
  instrument_id: string;
  /** USPS code, or 'US' for a federal roll call. */
  state: string;
  chamber: Chamber;
  /** ISO date of the vote. */
  date: string;
  motion: string;
  yea_names: string[];
  nay_names: string[];
  other_names: string[];
}

export type Grade = 'confirmed' | 'not-in-roster' | 'ambiguous' | 'no-session-list' | 'unmatched' | 'prior-service';
export type Vote = 'yea' | 'nay' | 'other';

export interface IdentityResult {
  grade: Grade;
  /** Set only when grade is 'confirmed'. */
  politician_id?: string;
  roster_name?: string;
  session_name?: string;
  session_list?: string;
  session_candidates?: string[];
  roster_candidates?: string[];
  term_start?: string;
  note?: string;
}

export interface MemberResult extends IdentityResult {
  printed: string;
  vote: Vote;
}

export interface RollCallResult {
  instrument_id: string;
  state: string;
  chamber: Chamber;
  date: string;
  motion: string;
  members: MemberResult[];
  /** Counts by grade; confirmed is split by vote ('confirmed:yea', 'confirmed:nay', 'confirmed:other'). */
  tally: Record<string, number>;
}

// ---- names -------------------------------------------------------------------------------------

const SUFFIX = /\b(jr|sr|ii|iii|iv|md|phd|dr)\b/g;
const ROLE = /\((chair|chairman|chairwoman|speaker|president|presiding)[^)]*\)/gi;

/** Lower-case ASCII letters and single spaces; accents dropped, hyphens and punctuation to spaces. */
export function normName(s: string | null | undefined): string {
  return (s ?? '')
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function nicknames(full: string | null | undefined): string[] {
  return [...(full ?? '').matchAll(/["“”]([^"“”]+)["“”]/g)].map((m) => normName(m[1])).filter(Boolean);
}

/**
 * First and last name of a full name. "Todd A. Hunter Jr." and "Hunter, Todd" both give
 * {first: 'todd', last: 'hunter'}. Drops parentheticals, quoted nicknames, suffixes and single-letter
 * middle initials; `words` is what is left, in order.
 */
export function splitFull(full: string | null | undefined): { first: string; last: string; words: string[] } {
  let f = (full ?? '').replace(/\([^)]*\)/g, ' ').replace(/["“”][^"“”]*["“”]/g, ' ');
  // "Smith, Jr., John" and "John Smith, Jr." — take the suffix out before reading a comma as "Last, First".
  f = f.replace(/,\s*(jr|sr|ii|iii|iv)\.?(?=,|\s|$)/gi, ' ');
  const comma = f.indexOf(',');
  if (comma !== -1) f = `${f.slice(comma + 1)} ${f.slice(0, comma)}`;
  const words = normName(f).replace(SUFFIX, ' ').split(' ').filter((w) => w.length > 1);
  return { first: words[0] ?? '', last: words[words.length - 1] ?? '', words };
}

/**
 * Read a printed roll-call name. "Smith, J." -> surname smith, initials [j]; "J. R. Smith" -> same with
 * [j, r]; "Smith (TX)" -> stateHint TX; "Martinez Fischer" -> surname "martinez fischer" (leading words
 * count as initials only when they are single letters). Role notes like "(Chair)" are dropped.
 */
export function parsePrinted(printed: string): { surname: string; initials: string[]; stateHint: string | null } {
  let p = (printed ?? '').replace(ROLE, ' ').trim();
  let stateHint: string | null = null;
  const m = p.match(/\(([A-Z]{2})\)/);
  if (m) {
    stateHint = m[1];
    p = p.replace(m[0], ' ').trim();
  }
  let sur: string;
  let initials: string[] = [];
  const comma = p.indexOf(',');
  if (comma !== -1) {
    sur = p.slice(0, comma);
    initials = (p.slice(comma + 1).match(/[A-Za-z]+/g) ?? [])
      .filter((w) => !/^(jr|sr|ii|iii|iv)$/i.test(w))
      .map((w) => w[0].toLowerCase());
  } else {
    const parts = p.split(/\s+/).filter(Boolean);
    let i = 0;
    while (i < parts.length - 1 && /^[A-Za-z]\.?$/.test(parts[i])) i++;
    initials = parts.slice(0, i).map((w) => w[0].toLowerCase());
    sur = parts.slice(i).join(' ');
  }
  const surname = normName(sur).replace(SUFFIX, ' ').replace(/\s+/g, ' ').trim();
  return { surname, initials, stateHint };
}

/** 'house' for House / Assembly / House of Delegates, 'senate' for Senate; null otherwise. */
export function normChamber(s: string | null | undefined): Chamber | null {
  if (/house|assembly|delegates/i.test(s ?? '')) return 'house';
  if (/senate/i.test(s ?? '')) return 'senate';
  return null;
}

// ---- session lists -----------------------------------------------------------------------------

function yearsOf(L: SessionList): number[] {
  return [...`${L.session} ${L.source_url ?? ''}`.matchAll(/(?:19|20)\d\d/g)].map((x) => Number(x[0]));
}

/**
 * The member list for this state and chamber whose session years contain the vote's year; failing
 * that, the nearest one within a year; failing that, null. A list that names no year is never picked.
 */
export function pickSessionList(lists: SessionList[], state: string, chamber: Chamber, date: string): SessionList | null {
  const y = /^\d{4}/.test(date ?? '') ? Number(date.slice(0, 4)) : NaN;
  if (Number.isNaN(y)) return null;
  let best: SessionList | null = null;
  let bestD = Infinity;
  for (const L of lists) {
    if (L.state.toUpperCase() !== state.toUpperCase() || L.chamber !== chamber) continue;
    const ys = yearsOf(L);
    if (!ys.length) continue;
    const d = Math.min(...ys) <= y && y <= Math.max(...ys) ? 0 : Math.min(...ys.map((v) => Math.abs(y - v)));
    if (d < bestD) { best = L; bestD = d; }
  }
  return bestD <= 1 ? best : null;
}

// ---- roster ------------------------------------------------------------------------------------

interface Indexed { p: RosterPerson; first: string; last: string; nicks: string[] }

const INDEX = new WeakMap<RosterPerson[], Indexed[]>();
function indexed(roster: RosterPerson[]): Indexed[] {
  let ix = INDEX.get(roster);
  if (!ix) {
    ix = roster.map((p) => {
      const s = splitFull(p.full_name);
      return { p, first: normName(p.first_name) || s.first, last: normName(p.last_name) || s.last, nicks: nicknames(p.full_name) };
    });
    INDEX.set(roster, ix);
  }
  return ix;
}

/** Surname equality, allowing the roster's compound surname to end with the one we hold. */
function surnameFits(rosterLast: string, last: string): boolean {
  return !!last && (rosterLast === last || rosterLast.endsWith(` ${last}`));
}

const p3 = (s: string) => s.slice(0, 3);
function firstFits(r: Indexed, first: string, nicks: string[]): boolean {
  if (!first || !r.first) return false;
  return p3(r.first) === p3(first) || nicks.some((n) => p3(n) === p3(r.first)) || r.nicks.some((n) => p3(n) === p3(first));
}

/** Roster people in `state` (any level) whose surname and first name both agree with `full`. */
export function rosterFor(roster: RosterPerson[], state: string, full: string): RosterPerson[] {
  const { first, last } = splitFull(full);
  const nicks = nicknames(full);
  const st = state.toUpperCase();
  return indexed(roster)
    .filter((r) => r.p.state.toUpperCase() === st && surnameFits(r.last, last) && firstFits(r, first, nicks))
    .map((r) => r.p);
}

// ---- identify ----------------------------------------------------------------------------------

/** Does the session member's name carry this printed surname? Exact last word, or the trailing words. */
function memberHasSurname(full: string, last: string, sur: string): boolean {
  if (!sur) return false;
  if (last === sur) return true;
  if (!sur.includes(' ')) return false;
  const n = splitFull(full).words.join(' ');
  return n === sur || n.endsWith(` ${sur}`);
}

function initialFits(full: string, first: string, initial: string): boolean {
  return first[0] === initial || nicknames(full).some((n) => n[0] === initial);
}

/** A state roll-call name, through the session's official member list, to one roster person. */
export function identifyState(printed: string, list: SessionList | null, roster: RosterPerson[]): IdentityResult {
  if (!list) return { grade: 'no-session-list' };
  const { surname, initials } = parsePrinted(printed);
  let mem = list.members
    .map((m) => ({ m, ...splitFull(m.full_name) }))
    .filter((x) => memberHasSurname(x.m.full_name, x.last, surname));
  const bySurname = mem.map((x) => x.m.full_name);
  if (initials.length) mem = mem.filter((x) => initialFits(x.m.full_name, x.first, initials[0]));
  if (mem.length !== 1) {
    return {
      grade: mem.length > 1 ? 'ambiguous' : 'unmatched',
      session_list: list.source_url,
      session_candidates: mem.length > 1 ? mem.map((x) => x.m.full_name) : bySurname,
      ...(mem.length === 0 && bySurname.length ? { note: 'printed initial fits no session member with that surname' } : {}),
    };
  }
  const full = mem[0].m.full_name;
  const hits = rosterFor(roster, list.state, full);
  if (hits.length === 1) {
    return { grade: 'confirmed', politician_id: hits[0].id, roster_name: hits[0].full_name, session_name: full, session_list: list.source_url };
  }
  return {
    grade: hits.length ? 'ambiguous' : 'not-in-roster',
    session_name: full,
    session_list: list.source_url,
    roster_candidates: hits.map((h) => h.full_name),
  };
}

/** A federal roll-call name to one roster member of that chamber; confirmed only if seated by the vote. */
export function identifyFederal(printed: string, chamber: Chamber, date: string, roster: RosterPerson[]): IdentityResult {
  const { surname, initials, stateHint } = parsePrinted(printed);
  let c = indexed(roster).filter((r) => {
    if (r.p.level !== 'federal' || r.p.chamber !== chamber) return false;
    if (surnameFits(r.last, surname)) return true;
    return surname.includes(' ') && splitFull(r.p.full_name).words.join(' ').endsWith(` ${surname}`);
  });
  if (stateHint) c = c.filter((r) => r.p.state.toUpperCase() === stateHint);
  if (c.length > 1 && initials.length) c = c.filter((r) => r.first[0] === initials[0] || r.nicks.some((n) => n[0] === initials[0]));
  if (c.length !== 1) return { grade: c.length ? 'ambiguous' : 'not-in-roster', roster_candidates: c.map((r) => r.p.full_name) };
  const r = c[0].p;
  if (r.term_start && date && r.term_start.slice(0, 10) <= date.slice(0, 10)) {
    return { grade: 'confirmed', politician_id: r.id, roster_name: r.full_name, session_list: 'roster term_start on or before the vote date' };
  }
  return {
    grade: 'prior-service',
    roster_name: r.full_name,
    term_start: r.term_start,
    note: r.term_start ? 'current term began after the vote' : 'term_start unknown, so the roster cannot place this person in the seat on the vote date',
  };
}

/** Identify every printed name on every roll call, with a per-roll-call tally. */
export function identifyRollCalls(rollCalls: RollCall[], lists: SessionList[], roster: RosterPerson[]): RollCallResult[] {
  return rollCalls.map((rc) => {
    const federal = rc.state.toUpperCase() === 'US';
    const list = federal ? null : pickSessionList(lists, rc.state, rc.chamber, rc.date);
    const named: Array<[string, Vote]> = [
      ...(rc.yea_names ?? []).map((n): [string, Vote] => [n, 'yea']),
      ...(rc.nay_names ?? []).map((n): [string, Vote] => [n, 'nay']),
      ...(rc.other_names ?? []).map((n): [string, Vote] => [n, 'other']),
    ];
    const tally: Record<string, number> = {};
    const members = named.map(([printed, vote]): MemberResult => {
      const r = federal ? identifyFederal(printed, rc.chamber, rc.date, roster) : identifyState(printed, list, roster);
      const key = r.grade === 'confirmed' ? `confirmed:${vote}` : r.grade;
      tally[key] = (tally[key] ?? 0) + 1;
      return { printed, vote, ...r };
    });
    return { instrument_id: rc.instrument_id, state: rc.state, chamber: rc.chamber, date: rc.date, motion: rc.motion, members, tally };
  });
}

// ---- roster TSV --------------------------------------------------------------------------------

export const ROSTER_COLUMNS = ['id', 'full_name', 'first_name', 'last_name', 'state', 'level', 'chamber', 'term_start'] as const;
const REQUIRED = ['id', 'full_name', 'state', 'level'];

/** Parse a roster TSV whose header names its columns (any order; extra columns ignored). */
export function parseRosterTsv(text: string, file: string): RosterPerson[] {
  const lines = text.split(/\r?\n/);
  const header = (lines[0] ?? '').split('\t').map((h) => h.trim());
  const missing = REQUIRED.filter((c) => !header.includes(c));
  if (missing.length) throw new Error(`${file}: header is missing column(s) ${missing.join(', ')}; expected ${ROSTER_COLUMNS.join(', ')}`);
  const col = (cells: string[], name: string) => {
    const i = header.indexOf(name);
    return i === -1 ? '' : (cells[i] ?? '').trim();
  };
  const out: RosterPerson[] = [];
  lines.slice(1).forEach((line, k) => {
    if (!line.trim()) return;
    const cells = line.split('\t');
    const at = `${file}: line ${k + 2}`;
    const level = col(cells, 'level');
    if (level !== 'state' && level !== 'federal') throw new Error(`${at}: level must be state or federal, got ${JSON.stringify(level)}`);
    const state = col(cells, 'state').toUpperCase();
    if (!/^[A-Z]{2}$/.test(state)) throw new Error(`${at}: state must be a two-letter USPS code, got ${JSON.stringify(state)}`);
    const chamberText = col(cells, 'chamber');
    const chamber = chamberText ? normChamber(chamberText) : null;
    if (chamberText && !chamber) throw new Error(`${at}: chamber must be house or senate, got ${JSON.stringify(chamberText)}`);
    const p: RosterPerson = { id: col(cells, 'id'), full_name: col(cells, 'full_name'), state, level };
    if (!p.id || !p.full_name) throw new Error(`${at}: id and full_name are required`);
    const first = col(cells, 'first_name');
    const last = col(cells, 'last_name');
    const ts = col(cells, 'term_start');
    if (first) p.first_name = first;
    if (last) p.last_name = last;
    if (chamber) p.chamber = chamber;
    if (ts) p.term_start = ts;
    out.push(p);
  });
  return out;
}
