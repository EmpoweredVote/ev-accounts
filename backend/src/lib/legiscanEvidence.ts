/**
 * legiscanEvidence — the LegiScan lane of the research verifier.
 *
 * A state seat that rests on a sponsorship or a member vote often cannot pass the snippet-plus-name
 * test. Found on the Season 3 voting-rights Texas batch (tx-01, 2026-10-29): the Legislature's
 * robots.txt blocks /BillLookup/ (authors and history pages), the archived copies list members by
 * surname only, and 12 seats verified nothing. LegiScan holds the same records for every state,
 * with each sponsor and voter as a full name. Its web pages sit behind a bot challenge, so the
 * lane reads the API. The URL on the evidence row is LegiScan's public page; the API address is
 * never stored, because it carries our key.
 *
 * An evidence row carries ONE canonical line built from LegiScan data, which prints no party:
 *
 *   LegiScan TX 89th Legislature Regular Session HB5337: Gary Gates is listed as a cosponsor.
 *   LegiScan TX 89th Legislature Regular Session SB16, roll call 1532789 (Senate, 2025-04-01, "Read 3rd time"): Sarah Eckhardt voted Nay.
 *
 * The verifier re-reads the record and checks the line field by field: state, session, bill, and
 * either the sponsor role or the roll call, chamber, date, motion and vote. The name must be the
 * one LegiScan prints for that sponsor or voter, and it must be the politician's own (first name or
 * a nickname of it, and last name; hyphens, accents and suffixes folded). The checked line is what a
 * voter reads.
 *
 * LegiScan has four sponsor kinds only (sponsor, primary sponsor, cosponsor, joint sponsor), so a
 * line never says "author": Texas authors and joint authors are both LegiScan primary sponsors.
 *
 * 🔴 Antipartisan rule: LegiScan people records carry `party` and `party_id`. The record fetcher
 * drops every party field before anything else reads the record, and nothing here prints one.
 */
import { normalizeText, type PageFetcher, type SnippetVerdict } from './researchVerifier.js';
import { getNameVariants } from './legiscan/helpers.js';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Json = any;

/** One LegiScan API call: (op, params) -> parsed response with status OK, or a thrown error. */
export type LegiscanQuery = (op: string, params: Record<string, string>) => Promise<Json>;

// A bill number: letters then digits ("HB5337", "SB0303"), or a Michigan letter-named joint resolution ("HJRB").
const BILL_NO = String.raw`(?:[A-Z]{1,5}\d+[A-Z]?|[HS]JR[A-Z]{1,2})`;
const BILL_URL = new RegExp(String.raw`^https:\/\/legiscan\.com\/([A-Z]{2})\/bill\/(${BILL_NO})\/(\d{4})(\/[A-Za-z0-9]+)?\/?$`);
const ROLLCALL_URL = new RegExp(String.raw`^https:\/\/legiscan\.com\/([A-Z]{2})\/rollcall\/(${BILL_NO})\/id\/(\d+)\/?$`);

const ROLES = { 0: 'sponsor', 1: 'primary sponsor', 2: 'cosponsor', 3: 'joint sponsor' } as const;
type Role = (typeof ROLES)[keyof typeof ROLES];
const VOTES = ['Yea', 'Nay', 'NV', 'Absent'] as const;
const CHAMBERS: Record<string, string> = { H: 'House', S: 'Senate', A: 'Assembly', J: 'Joint' };

const SPONSOR_LINE = new RegExp(String.raw`^LegiScan ([A-Z]{2}) (.+) (${BILL_NO}): (.+) is listed as an? (primary sponsor|cosponsor|joint sponsor|sponsor)\.$`);
const VOTE_LINE = new RegExp(
  `^LegiScan ([A-Z]{2}) (.+) (${BILL_NO}), roll call (\\d+) \\((\\w+), (\\d{4}-\\d{2}-\\d{2}), "(.*)"\\): (.+) voted (${VOTES.join('|')})\\.$`,
);

export type LegiscanLine =
  | { kind: 'sponsor'; state: string; session: string; bill: string; name: string; role: Role }
  | { kind: 'vote'; state: string; session: string; bill: string; rollCallId: number; chamber: string;
      date: string; motion: string; name: string; vote: (typeof VOTES)[number] };

export function isLegiscanUrl(url: string): boolean {
  const u = url.trim();
  return BILL_URL.test(u) || ROLLCALL_URL.test(u);
}

export function formatLegiscanLine(l: LegiscanLine): string {
  const head = `LegiScan ${l.state} ${l.session} ${l.bill}`;
  if (l.kind === 'sponsor') return `${head}: ${l.name} is listed as ${/^[aeiou]/.test(l.role) ? 'an' : 'a'} ${l.role}.`;
  return `${head}, roll call ${l.rollCallId} (${l.chamber}, ${l.date}, "${l.motion}"): ${l.name} voted ${l.vote}.`;
}

export function parseLegiscanLine(text: string): LegiscanLine | null {
  const t = text.trim();
  const v = VOTE_LINE.exec(t);
  if (v) {
    return { kind: 'vote', state: v[1], session: v[2], bill: v[3], rollCallId: Number(v[4]), chamber: v[5],
      date: v[6], motion: v[7], name: v[8].trim(), vote: v[9] as (typeof VOTES)[number] };
  }
  const s = SPONSOR_LINE.exec(t);
  if (s) return { kind: 'sponsor', state: s[1], session: s[2], bill: s[3], name: s[4].trim(), role: s[5] as Role };
  return null;
}

// ---------------------------------------------------------------------------------------------
// Record fetcher: LegiScan URL -> a party-free JSON record, through the API
// ---------------------------------------------------------------------------------------------

/** Remove every party field, at any depth. */
function dropParty(x: Json): Json {
  if (Array.isArray(x)) return x.map(dropParty);
  if (x && typeof x === 'object') {
    const out: Json = {};
    for (const [k, v] of Object.entries(x)) if (!/party/i.test(k)) out[k] = dropParty(v);
    return out;
  }
  return x;
}

const PERSON_FIELDS = ['people_id', 'name', 'first_name', 'middle_name', 'last_name', 'suffix', 'nickname'] as const;
const personOf = (p: Json) => Object.fromEntries(PERSON_FIELDS.map((f) => [f, p?.[f] ?? '']));

/**
 * Build the URL -> record function the verifier reads. Each record is JSON text:
 *  - bill URL: `{ kind: 'bill', state, bill_number, bills: [{ session_name, sponsors: [...] }] }`: the
 *    ONE bill whose LegiScan page is this URL. A regular session and its special sessions reuse bill
 *    numbers for unrelated bills (Texas 2025 has three SB16s), so a session is a candidate only if it
 *    began in the URL's year and is regular for a URL with no session suffix (special for one with a
 *    suffix), and the bill is kept only if LegiScan's own `url` for it is this URL;
 *  - roll-call URL: `{ kind: 'rollcall', state, bill_number, session_name, roll_call_id, chamber,
 *    date, desc, votes: [{ vote_text, person }] }`.
 * Session lists, master lists and session people are cached for the life of the fetcher, so a
 * batch costs about one query per bill or roll call plus one per state and session.
 */
export function createLegiscanRecordFetcher(query: LegiscanQuery): (url: string) => Promise<string> {
  const memo = new Map<string, Promise<Json>>();
  const once = (op: string, params: Record<string, string>): Promise<Json> => {
    const key = `${op}:${JSON.stringify(params)}`;
    let hit = memo.get(key);
    if (!hit) {
      hit = query(op, params).then(dropParty);
      memo.set(key, hit);
      hit.catch(() => memo.delete(key));
    }
    return hit;
  };

  async function billRecord(url: string, state: string, number: string, year: number, special: boolean): Promise<string> {
    const sessions: Json[] = (await once('getSessionList', { state })).sessions ?? [];
    const bills: Json[] = [];
    for (const s of sessions.filter((x) => Number(x.year_start) === year && Boolean(Number(x.special)) === special)) {
      const list = (await once('getMasterListRaw', { id: String(s.session_id) })).masterlist ?? {};
      const hit = Object.entries(list).find(([k, b]: [string, Json]) => k !== 'session' && b?.number === number);
      if (!hit) continue;
      const bill = (await once('getBill', { id: String((hit[1] as Json).bill_id) })).bill;
      if (bill.url && bill.url.replace(/\/$/, '') !== url.replace(/\/$/, '')) continue;
      bills.push({
        session_name: bill.session?.session_name ?? s.session_name,
        sponsors: (bill.sponsors ?? []).filter((sp: Json) => sp.people_id && !sp.committee_sponsor)
          .map((sp: Json) => ({ ...personOf(sp), sponsor_type_id: sp.sponsor_type_id, sponsor_order: sp.sponsor_order })),
      });
    }
    if (!bills.length) throw new Error(`LegiScan bill ${state} ${number} (${year}) not found`);
    if (bills.length > 1) throw new Error(`LegiScan bill ${state} ${number} (${year}) is ambiguous: ${bills.length} sessions`);
    return JSON.stringify({ kind: 'bill', state, bill_number: number, bills });
  }

  async function rollCallRecord(state: string, number: string, id: string): Promise<string> {
    const rc = (await once('getRollCall', { id })).roll_call;
    const bill = (await once('getBill', { id: String(rc.bill_id) })).bill;
    if (bill.bill_number !== number || bill.state !== state) throw new Error(`LegiScan roll call ${id} is not on ${state} ${number}`);
    const people: Json[] = (await once('getSessionPeople', { id: String(bill.session.session_id) })).sessionpeople?.people ?? [];
    const byId = new Map(people.map((p) => [p.people_id, p]));
    return JSON.stringify({
      kind: 'rollcall', state, bill_number: bill.bill_number, session_name: bill.session.session_name,
      roll_call_id: rc.roll_call_id, chamber: rc.chamber, date: rc.date, desc: rc.desc,
      votes: (rc.votes ?? []).filter((v: Json) => byId.has(v.people_id))
        .map((v: Json) => ({ vote_text: v.vote_text, person: personOf(byId.get(v.people_id)) })),
    });
  }

  return async (url: string) => {
    const u = url.trim();
    const b = BILL_URL.exec(u);
    if (b) return billRecord(u, b[1], b[2], Number(b[3]), Boolean(b[4]));
    const r = ROLLCALL_URL.exec(u);
    if (r) return rollCallRecord(r[1], r[2], r[3]);
    throw new Error(`not a LegiScan bill or roll-call URL: ${u}`);
  };
}

/**
 * Wrap a PageFetcher so LegiScan bill and roll-call URLs resolve to party-free records through the
 * API. Every other URL goes to `base` unchanged. Results are cached per URL, failures included.
 */
export function withLegiscanRecords(base: PageFetcher, records: (url: string) => Promise<string>): PageFetcher {
  const cache = new Map<string, ReturnType<PageFetcher>>();
  return (url) => {
    if (!isLegiscanUrl(url)) return base(url);
    let hit = cache.get(url);
    if (!hit) {
      hit = records(url)
        .then((text) => ({ ok: true as const, text }))
        .catch((err: any) => ({ ok: false as const, reason: err?.message ?? String(err) }));
      cache.set(url, hit);
    }
    return hit;
  };
}

// ---------------------------------------------------------------------------------------------
// Check
// ---------------------------------------------------------------------------------------------

const SUFFIX = /\b(jr|sr|ii|iii|iv|v)\b\.?/g;
/** Accents and case folded as the verifier folds names; hyphens and periods become spaces; suffixes dropped. */
const fold = (s: string): string => normalizeText(s).replace(/[-.,]/g, ' ').replace(SUFFIX, '').replace(/\s+/g, ' ').trim();

/** "J.D." / "J. D." → "JD": two or more dotted initials are one name the person goes by, not two letters. */
const joinInitials = (s: string): string =>
  s.replace(/\b[A-Za-z]\.(?:\s*[A-Za-z]\.)+/g, (m) => m.replace(/[.\s]/g, ''));

/**
 * Surnames LegiScan is known to misspell, each checked by hand against the official record: our spelling →
 * LegiScan's. Exact entries only (never a fuzzy match): the first name must still fit as usual.
 * - GA, 2026-10-31: Timothy Bearden is printed "Timothy Beardon" (SB 86 of 2009 House roll call).
 */
const LEGISCAN_SURNAME_MISSPELLINGS: Readonly<Record<string, readonly string[]>> = { bearden: ['beardon'] };

/** Does LegiScan's person fit the politician's own name? */
function personFits(p: Json, fullName: string, lastName: string): boolean {
  const last = fold(lastName);
  let recLast = fold(p.last_name ?? '');
  if (LEGISCAN_SURNAME_MISSPELLINGS[last]?.includes(recLast)) recLast = last;
  // A two-word last_name the record prints as one ("Capps Balkcom", printed "Jennifer Balkcom") fits
  // the printed surname, and only when that word is one of the two.
  const printedLast = fold(p.name ?? '').split(' ').pop() ?? '';
  if (recLast !== last && !(recLast.split(' ').includes(last) && printedLast === last)) return false;
  // A leading initial ("A. Reece Pyrtle") gives way to the given name the person goes by.
  const words = fold(joinInitials(fullName)).split(' ');
  const wants = [words[0] ?? ''];
  if (wants[0].length === 1 && words[1] && words[1] !== last) wants.push(words[1]);
  const have = [fold(p.first_name ?? '').split(' ')[0], fold(joinInitials(p.nickname ?? ''))].filter(Boolean);
  return have.some((h) => wants.some((want) => h === want || getNameVariants(h).includes(want) || getNameVariants(want).includes(h)));
}

/**
 * Check a canonical line against the record `withLegiscanRecords` fetched for `url`. `fullName`
 * and `lastName` are the politician's own, from the bundle. Returns `verified` with offset 0 when
 * every field matches; `snippet_not_found` when the record does not say this; `name_not_present`
 * when it does, for a person whose name is not this politician's.
 */
export function verifyLegiscanLine(
  line: string, url: string, recordText: string, names: { fullName: string; lastName: string },
): SnippetVerdict {
  const l = parseLegiscanLine(line);
  let rec: Json;
  try { rec = JSON.parse(recordText); } catch { return { verdict: 'snippet_not_found' }; }
  if (!l || !isLegiscanUrl(url) || rec.state !== l.state || rec.bill_number !== l.bill) return { verdict: 'snippet_not_found' };
  const sameName = (p: Json) => fold(p.name ?? '') === fold(l.name);

  let who: Json | undefined;
  if (l.kind === 'sponsor') {
    if (rec.kind !== 'bill') return { verdict: 'snippet_not_found' };
    const bill = (rec.bills ?? []).find((b: Json) => b.session_name === l.session);
    who = bill?.sponsors.find((sp: Json) => sameName(sp) && ROLES[sp.sponsor_type_id as keyof typeof ROLES] === l.role);
  } else {
    if (rec.kind !== 'rollcall' || rec.session_name !== l.session || rec.roll_call_id !== l.rollCallId
      || (CHAMBERS[rec.chamber] ?? rec.chamber) !== l.chamber || rec.date !== l.date
      || normalizeText(rec.desc ?? '') !== normalizeText(l.motion)) return { verdict: 'snippet_not_found' };
    who = (rec.votes ?? []).find((v: Json) => sameName(v.person) && v.vote_text === l.vote)?.person;
  }
  if (!who) return { verdict: 'snippet_not_found' };
  if (!personFits(who, names.fullName, names.lastName)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

/**
 * Every canonical line a record holds for this politician: one per sponsorship on a bill URL (per
 * session), one vote on a roll-call URL. This is how an evidence builder writes the lines, so they
 * are exactly what verifyLegiscanLine accepts.
 */
export function legiscanLinesFor(url: string, recordText: string, names: { fullName: string; lastName: string }): string[] {
  const rec: Json = JSON.parse(recordText);
  const out: LegiscanLine[] = [];
  if (rec.kind === 'bill') {
    for (const b of rec.bills ?? []) {
      for (const sp of b.sponsors ?? []) {
        const role = ROLES[sp.sponsor_type_id as keyof typeof ROLES];
        if (role && personFits(sp, names.fullName, names.lastName)) {
          out.push({ kind: 'sponsor', state: rec.state, session: b.session_name, bill: rec.bill_number, name: sp.name, role });
        }
      }
    }
  } else if (rec.kind === 'rollcall') {
    for (const v of rec.votes ?? []) {
      if (!personFits(v.person, names.fullName, names.lastName)) continue;
      out.push({ kind: 'vote', state: rec.state, session: rec.session_name, bill: rec.bill_number, rollCallId: rec.roll_call_id,
        chamber: CHAMBERS[rec.chamber] ?? rec.chamber, date: rec.date, motion: rec.desc, name: v.person.name, vote: v.vote_text });
    }
  }
  return out.map(formatLegiscanLine).filter((l) => verifyLegiscanLine(l, url, recordText, names).verdict === 'verified');
}
