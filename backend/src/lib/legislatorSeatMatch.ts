/**
 * Every state's sitting legislators ↔ their Open States person id (and, for a few states, the legislature's
 * own member id), matched by SEAT. Used by scripts/member-ids/sync-member-ids.ts.
 *
 * WHY OPEN STATES IS THE COMMON KEY. No body issues one id for all state legislators. Each legislature has its
 * own, and many are not stable (measured from Open States' own links, 2026-11-19):
 *   - new id every session:             AZ (legislator=N), SD (Profile/N), WI (legislators/…/N)
 *   - new id on a move between chambers: VA (H331 → S130), KS (rep_… → sen_…), MA, MD (brooks01 → brooks02)
 *   - one id per person:                GA, ID, PA, SC (and MN's LRL id, mnMemberIds.ts)
 * The Open States person id ("ocd-person/<uuid>") follows the person across sessions and chambers, and is
 * public domain. So every legislator gets an `openstates` row, and a state's own id is stored only where it
 * is one-per-person (STATE_MEMBER_IDS). A person may hold several ids of a type; one id names one person.
 *
 * MATCHING. Our seat = (chamber, district) from essentials.districts; Open States' = (current_chamber,
 * current_district). District spellings differ by state, so each side is folded (seatKey) and, per state, our
 * ocd_id tail or our label is used — whichever lines up with more Open States seats (MA names its districts:
 * "1st Barnstable"). A single-member seat pairs its one holder with Open States' one member, and the family
 * name must agree. A multi-member seat (AZ, MD, ND, SD, WA; ID's A/B seats) pairs each holder with the one
 * member of that seat sharing their family name; a family name shared within the seat is a problem, never a
 * guess. Nothing is ever matched across seats or by name alone.
 */

export type Chamber = 'upper' | 'lower';

export interface Holder {
  politicianId: string;
  state: string; // lower-case postal code
  chamber: Chamber;
  ocdTail: string; // "61A", "1", "nan", ""
  label: string; // "1st Barnstable District", "State House District 1"
  fullName: string;
}

export interface OsPerson { ocdId: string; chamber: Chamber; district: string; name: string; links: string }

export interface IdRow {
  politicianId: string;
  idType: string;
  idValue: string;
  matchMethod: 'seat' | 'id_crosswalk';
  sourceName: string;
}

/** A state legislature's own member id, read from the Open States record's links (Open States scraped them
 * from the legislature's site). Only states whose id is one per person, across sessions and chambers. */
export const STATE_MEMBER_IDS: Record<string, { idType: string; re: RegExp; note: string }> = {
  ga: { idType: 'ga-member', re: /legis\.ga\.gov\/members\/(?:house|senate)\/(\d+)/g, note: 'legis.ga.gov/members/<chamber>/<id>' },
  id: { idType: 'id-member', re: /legislature\.idaho\.gov\/legislators\/membership\/\d{4}\/id(\d+)/g, note: 'legislature.idaho.gov/legislators/membership/<year>/id<id>' },
  pa: { idType: 'pa-member', re: /(?:palegis\.us\/(?:house|senate)\/members\/bio\/|(?:House|Senate)_bio\.cfm\?id=)(\d+)/g, note: 'palegis.us/<chamber>/members/bio/<id>' },
  sc: { idType: 'sc-member', re: /scstatehouse\.gov\/member\.php\?code=(\d+)/g, note: 'scstatehouse.gov/member.php?code=<id>' },
};

const fold = (s: string): string =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/** "State House District 007" → "7"; "1st Barnstable District" → "1stbarnstable"; "At-Large" → "atlarge". */
export function seatKey(s: string): string {
  const t = fold(s)
    .replace(/\b(state|house|senate|assembly|district|tx|representative|of|the|and)\b/g, ' ')
    .replace(/[^a-z0-9]+/g, '');
  return t.replace(/^0+(?=\d)/, '');
}

/** Words after a name that are not part of it: "Jr.", "V", "MD", "Ph.D.". */
const NOT_A_NAME = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v', 'md', 'phd', 'dds', 'esq', 'dvm', 'rn', 'do']);
const nameWords = (s: string): string[] =>
  fold(s).replace(/\bph\.?\s*d\b/g, 'phd').replace(/[^a-z ]+/g, ' ').split(/\s+/).filter((w) => w && !NOT_A_NAME.has(w));

/**
 * True when our record's family name appears in theirs. The seat is the evidence; this only guards against
 * pairing the seat with someone else. Our last name word counts, and for a name of three or more words the
 * one before it too ("Sylvia Wayfer Baker" ~ "Sylvia Wayfer"); spaces inside a family name are ignored
 * ("Van Schoiack" ~ "VanSchoiack").
 */
export function familyAgrees(ourFullName: string, theirName: string): boolean {
  const ours = nameWords(ourFullName);
  const theirWords = nameWords(theirName);
  if (!ours.length || !theirWords.length) return false;
  const theirs = new Set(theirWords);
  const glued = theirWords.join('');
  // A middle initial ("Mark T. Johnson") is never a family name.
  const fam = [ours[ours.length - 1], ...(ours.length >= 3 && ours[ours.length - 2].length > 2 ? [ours[ours.length - 2]] : [])];
  if (fam.some((w) => theirs.has(w))) return true;
  // "Van Schoiack" ~ "VanSchoiack", and the reverse.
  const ourGlued = ours.slice(1).join('');
  return (ours.length >= 3 && theirs.has(ours.slice(-2).join(''))) || (ourGlued.length > 4 && glued.endsWith(ourGlued));
}

export function parseOpenStatesCsv(rows: Record<string, string>[]): OsPerson[] {
  return rows
    .filter((r) => r.current_chamber === 'upper' || r.current_chamber === 'lower')
    .map((r) => ({
      ocdId: r.id, chamber: r.current_chamber as Chamber, district: r.current_district ?? '',
      name: r.name ?? '', links: `${r.links ?? ''};${r.sources ?? ''}`,
    }));
}

export interface StateResult { rows: IdRow[]; problems: string[]; matched: number; holders: number }

export function matchState(state: string, holders: Holder[], people: OsPerson[]): StateResult {
  const problems: string[] = [];
  const rows: IdRow[] = [];
  const osKeys = new Set(people.map((p) => `${p.chamber}|${seatKey(p.district)}`));

  // Per state: our ocd_id tail or our label, whichever names more Open States seats.
  const hits = (f: (h: Holder) => string) => holders.filter((h) => osKeys.has(`${h.chamber}|${seatKey(f(h))}`)).length;
  const useLabel = hits((h) => h.label) > hits((h) => h.ocdTail);
  const ourKey = (h: Holder) => `${h.chamber}|${seatKey(useLabel ? h.label : h.ocdTail)}`;
  const ourKeys = new Set(holders.map(ourKey));
  // Idaho: Open States says "16B" where our seat is "16" with two holders.
  const osKey = (p: OsPerson) => {
    const k = `${p.chamber}|${seatKey(p.district)}`;
    const bare = k.replace(/(\d)[a-z]$/, '$1');
    return !ourKeys.has(k) && ourKeys.has(bare) ? bare : k;
  };

  const group = <T>(xs: T[], k: (x: T) => string) => {
    const m = new Map<string, T[]>();
    for (const x of xs) m.set(k(x), [...(m.get(k(x)) ?? []), x]);
    return m;
  };
  const oursBySeat = group(holders, ourKey);
  const osBySeat = group(people, osKey);
  const stateIds = STATE_MEMBER_IDS[state];

  let matched = 0;
  for (const [seat, hs] of oursBySeat) {
    const os = osBySeat.get(seat) ?? [];
    if (!os.length) { for (const h of hs) problems.push(`${h.fullName} (${seat}): Open States has no member at this seat`); continue; }
    for (const h of hs) {
      const cands = os.filter((p) => familyAgrees(h.fullName, p.name));
      const rivals = hs.filter((o) => o !== h && cands.some((p) => familyAgrees(o.fullName, p.name)));
      if (cands.length !== 1 || rivals.length) {
        problems.push(`${h.fullName} (${seat}): ${cands.length} Open States member(s) of this seat share the family name`
          + `${rivals.length ? `, as do ${rivals.length} other holder(s)` : ''} [${os.map((p) => p.name).join('; ')}]`);
        continue;
      }
      const p = cands[0];
      matched++;
      rows.push({ politicianId: h.politicianId, idType: 'openstates', idValue: p.ocdId, matchMethod: 'seat', sourceName: p.name });
      if (stateIds) {
        const ids = new Set([...p.links.matchAll(stateIds.re)].map((m) => m[1]));
        if (ids.size === 1) rows.push({ politicianId: h.politicianId, idType: stateIds.idType, idValue: [...ids][0], matchMethod: 'id_crosswalk', sourceName: p.name });
        else problems.push(`${h.fullName} (${seat}): Open States record carries ${ids.size} ${stateIds.idType} ids${ids.size ? ` (${[...ids].join(', ')})` : ''}`);
      }
    }
  }
  for (const [seat, os] of osBySeat) if (!oursBySeat.has(seat)) problems.push(`${seat}: Open States lists ${os.map((p) => p.name).join('; ')}; we have no current holder`);

  for (const [k, rs] of group(rows, (r) => `${r.idType}|${r.idValue}`)) {
    if (new Set(rs.map((r) => r.politicianId)).size > 1) problems.push(`id ${k} matched ${rs.length} people — none of them written`);
  }
  const bad = new Set([...group(rows, (r) => `${r.idType}|${r.idValue}`)].filter(([, rs]) => new Set(rs.map((r) => r.politicianId)).size > 1).map(([k]) => k));
  return { rows: rows.filter((r) => !bad.has(`${r.idType}|${r.idValue}`)), problems, matched, holders: holders.length };
}
