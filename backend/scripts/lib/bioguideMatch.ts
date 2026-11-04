/**
 * Match our sitting members of Congress to congress.gov's current-member list, by SEAT, never by surname.
 * The surname only confirms a seat match; a seat whose official holder has another surname is "unclear".
 * Pure: the caller loads both sides (scripts/federal-bioguide-backfill.ts).
 */

export interface OfficialMember {
  bioguideId: string;
  name: string; // congress.gov prints "Last, First Middle"
  state: string; // full state name
  district: number | null; // House only; null or 0 = at-large / delegate
  chamber: 'House' | 'Senate';
}

export interface OurHolder {
  politician_id: string;
  full_name: string;
  last_name: string | null;
  bioguide_id: string | null;
  chamber: 'House' | 'Senate';
  seat: string; // House: 4-digit geo_id (state FIPS + district); Senate: state FIPS
}

export type MatchClass =
  | 'clean' // one official member on the seat, surname agrees, id not used by anyone else: safe to set
  | 'already-set' // our row already carries this exact id
  | 'id-differs' // our row carries a DIFFERENT id than the seat's official member
  | 'name-differs' // the seat's official member has another surname: unclear, a person must look
  | 'no-official' // no current official member on that seat (vacancy, or our seat is stale)
  | 'id-taken'; // the official id already sits on another of our politician rows (likely a duplicate person)

export interface Match { cls: MatchClass; holder: OurHolder; official: OfficialMember | null; note: string }

const SUFFIX = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);

/** Lower-case, accents and punctuation off, so "Sánchez" = "Sanchez" and "O'Neill" = "ONeill". */
export function normName(s: string): string {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z\s-]/g, '').replace(/\s+/g, ' ').trim();
}

/** The surname from congress.gov's "Last, First" form. */
export const officialSurname = (name: string): string => normName(name.split(',')[0]);

/** Does our person carry this surname? Last-name field first, else any word of the full name (suffixes skipped). */
export function surnameAgrees(holder: Pick<OurHolder, 'full_name' | 'last_name'>, surname: string): boolean {
  const want = surname.replace(/-/g, ' ').split(' ').filter(Boolean);
  const ours = normName(`${holder.last_name ?? ''} ${holder.full_name}`).replace(/-/g, ' ').split(' ').filter((w) => w && !SUFFIX.has(w));
  return want.length > 0 && want.every((w) => ours.includes(w));
}

/** House seat key: state FIPS + 2-digit district; at-large is "00". */
export function houseSeat(fips: string, district: number | null): string {
  return fips + String(district ?? 0).padStart(2, '0');
}

/** DC and the five territories send a non-voting delegate; our districts key that seat "<FIPS>98" (Census CD 98). */
export const DELEGATE_FIPS = new Set(['11', '60', '66', '69', '72', '78']);

export function matchHolders(
  holders: OurHolder[],
  officials: OfficialMember[],
  stateFips: (stateName: string) => string | undefined,
  idOwners: Map<string, string[]>, // bioguide id -> politician ids that carry it now
): { matches: Match[]; officialsWithoutSeat: OfficialMember[] } {
  const bySeat = new Map<string, OfficialMember[]>();
  for (const m of officials) {
    const f = stateFips(m.state);
    if (!f) continue;
    const seat = m.chamber === 'House' ? (DELEGATE_FIPS.has(f) ? `${f}98` : houseSeat(f, m.district)) : f;
    const key = `${m.chamber}:${seat}`;
    bySeat.set(key, [...(bySeat.get(key) ?? []), m]);
  }
  const used = new Set<string>();
  const matches: Match[] = holders.map((h) => {
    const cands = bySeat.get(`${h.chamber}:${h.seat}`) ?? [];
    // A Senate seat key is a state, with two members: the surname picks one. A House seat has one.
    const named = cands.filter((m) => surnameAgrees(h, officialSurname(m.name)));
    if (cands.length === 0) return { cls: 'no-official' as const, holder: h, official: null, note: `no current ${h.chamber} member on seat ${h.seat}` };
    if (named.length !== 1) {
      return { cls: 'name-differs' as const, holder: h, official: cands.length === 1 ? cands[0] : null, note: `seat ${h.seat}: official ${cands.map((m) => m.name).join(' / ')}` };
    }
    const m = named[0];
    used.add(m.bioguideId);
    if (h.bioguide_id && h.bioguide_id === m.bioguideId) return { cls: 'already-set' as const, holder: h, official: m, note: '' };
    if (h.bioguide_id) return { cls: 'id-differs' as const, holder: h, official: m, note: `ours ${h.bioguide_id}, official ${m.bioguideId}` };
    const owners = (idOwners.get(m.bioguideId) ?? []).filter((p) => p !== h.politician_id);
    if (owners.length) return { cls: 'id-taken' as const, holder: h, official: m, note: `${m.bioguideId} already on ${owners.join(', ')}` };
    return { cls: 'clean' as const, holder: h, official: m, note: '' };
  });
  return { matches, officialsWithoutSeat: officials.filter((m) => !used.has(m.bioguideId)) };
}
