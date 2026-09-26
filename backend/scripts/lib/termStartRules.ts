/**
 * termStartRules — dates the start of a legislator's tenure in a seat, for the term-date roster pass
 * (IN + CA pilot, 2026-09-25). Pure.
 *
 * Candidate dates come from the OpenStates `people` dataset. A candidate earns `day` precision only
 * when it equals the day the state's own law fixes for a term to begin; anything else (a special
 * election, an appointment) is stored as the year alone and flagged for a person — never a guessed
 * day (CLAUDE.md "Don't invent dates").
 *
 *   Indiana     — "the day after the general election" (IN Const. art. 4 §3).
 *   California  — "the first Monday in December next following their election" (CA Const. art. IV §2(a)).
 *
 * An `essentials.office_terms` row is a TENURE in one seat (a re-election adds no row), so the start is
 * the day the person first took THIS seat: contiguous roles in the same chamber and district are joined,
 * and a role in another district (redistricting) is a different seat.
 */

export type Chamber = 'upper' | 'lower';
export interface OsRole { start_date?: string; end_date?: string; type: string; district: string }

const iso = (d: Date) => d.toISOString().slice(0, 10);
const utc = (y: number, m: number, day: number) => new Date(Date.UTC(y, m, day));

/** The Tuesday after the first Monday in November. */
export function generalElectionDay(year: number): string {
  const nov1 = utc(year, 10, 1);
  const firstMonday = 1 + ((8 - nov1.getUTCDay()) % 7);
  return iso(utc(year, 10, firstMonday + 1));
}

function firstMondayOfDecember(year: number): string {
  const dec1 = utc(year, 11, 1);
  return iso(utc(year, 11, 1 + ((8 - dec1.getUTCDay()) % 7)));
}

export function legalTermStart(state: string, _chamber: Chamber, electionYear: number): string {
  switch (state) {
    case 'IN': {
      const d = new Date(`${generalElectionDay(electionYear)}T00:00:00Z`);
      d.setUTCDate(d.getUTCDate() + 1);
      return iso(d);
    }
    case 'CA':
      return firstMondayOfDecember(electionYear);
    default:
      throw new Error(`no term-start rule for state ${state}`);
  }
}

/** The start of the unbroken tenure in (chamber, district) that is current (no end date), or null. */
export function tenureStartInSeat(roles: OsRole[], chamber: Chamber, district: string): string | null {
  const inSeat = roles.filter((r) => r.type === chamber && String(r.district) === district && r.start_date);
  const current = inSeat.find((r) => !r.end_date);
  if (!current) return null;
  let start = current.start_date!;
  for (;;) {
    const prev = inSeat.find((r) => r.end_date === start);
    if (!prev) return start;
    start = prev.start_date!;
  }
}

export interface ClassifiedStart { term_start: string; start_precision: 'day' | 'year'; flag: string | null }

export function classifyStart(state: string, chamber: Chamber, date: string): ClassifiedStart {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`start date ${date} not YYYY-MM-DD`);
  const year = Number(date.slice(0, 4));
  if (legalTermStart(state, chamber, year) === date) return { term_start: date, start_precision: 'day', flag: null };
  return { term_start: `${year}-01-01`, start_precision: 'year', flag: `off-rule-date ${date}` };
}

/** "Indiana State Senate - District 040" → "40"; no district number → null. */
export function districtNumber(label: string): string | null {
  const m = /district\s+0*(\d+)\b/i.exec(label);
  return m ? m[1] : null;
}

const fold = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();

/** Does the family name appear as whole tokens in the full name (accent- and case-insensitive)? */
export function surnameMatches(fullName: string, familyName: string): boolean {
  const tokens = fold(fullName).split(/\s+/);
  const fam = fold(familyName).split(/\s+/);
  for (let i = 0; i + fam.length <= tokens.length; i++) {
    if (fam.every((f, j) => tokens[i + j].replace(/[.,]/g, '') === f)) return true;
  }
  return false;
}

/** The last surname token of an official roster name, without honorifics/suffixes ("Steven S. Choi Ph.D." → "Choi"). */
export function officialSurname(name: string): string {
  const tokens = name.trim().split(/\s+/).filter((t) => !/^(jr|sr|ii|iii|iv|ph\.?d|m\.?d|dr)\.?$/i.test(t.replace(/,$/, '')));
  return tokens[tokens.length - 1] ?? '';
}
