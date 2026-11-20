/**
 * Minnesota legislators' member ids, matched by SEAT (chamber + district), never by name.
 *
 * Sources (all public, no sign-in):
 *   - LRL current members  https://www.lrl.mn.gov/legdb/current      → LRL id per (chamber, district)
 *   - Senate member API    https://www.senate.mn/api/members         → Senate mem_id per district
 *   - Open States people   https://data.openstates.org/people/current/mn.csv
 *       its `links` column carries the House profile URL (= LRL id) or the Senate member_bio URL (= mem_id),
 *       so an Open States person id is attached by id, not by name.
 *
 * A name is used only as a cross-check: the record's family name must appear in the source's name for
 * the seat. Any seat that is empty, doubled, or fails a cross-check stops the run (see matchMinnesota).
 */

export type Chamber = 'house' | 'senate';

export interface SeatHolder {
  politicianId: string;
  chamber: Chamber;
  /** "61A" (House) or "35" (Senate), upper-case, no leading zero. */
  district: string;
  fullName: string;
  photoOriginUrl: string | null;
}

export interface LrlMember { lrlId: string; chamber: Chamber; district: string; name: string }
export interface SenateMember { memId: string; district: string; lastName: string; fullName: string }
export interface OpenStatesPerson { ocdId: string; chamber: Chamber; district: string; name: string; links: string }

export interface MemberIdRow {
  politicianId: string;
  idType: 'mn-lrl' | 'mn-senate-mem' | 'openstates';
  idValue: string;
  matchMethod: 'seat' | 'id_crosswalk';
  source: string;
  /** For the reviewer: the name the source prints for this id. */
  sourceName: string;
}

export const normDistrict = (d: string): string => d.trim().toUpperCase().replace(/^0+(?=\d)/, '');

export const fold = (s: string): string =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
    .replace(/[^a-z0-9 ]+/g, ' ').replace(/\s+/g, ' ').trim();

/** The LRL current-members page: one card per member — `Rep.|Sen. Name`, `District: 33A`, `fulldetail?id=N`. */
export function parseLrlCurrent(html: string): LrlMember[] {
  const re = /fulldetail\?id=(\d+)'?"?>\s*<b>\s*(Rep|Sen)\.\s+([^<]+?)\s*<\/b>\s*<\/a>\s*<\/h5>\s*<span[^>]*>\s*District:\s*(\w+)\s*<\/span>/gi;
  const seen = new Set<string>();
  const out: LrlMember[] = [];
  for (let m = re.exec(html); m; m = re.exec(html)) {
    const row: LrlMember = {
      lrlId: m[1], chamber: m[2].toLowerCase() === 'rep' ? 'house' : 'senate',
      district: normDistrict(m[4]), name: m[3].replace(/&quot;/g, '"').replace(/&amp;/g, '&').trim(),
    };
    const key = `${row.lrlId}|${row.chamber}|${row.district}`;
    if (!seen.has(key)) { seen.add(key); out.push(row); }
  }
  return out;
}

export function parseSenateMembers(json: unknown): SenateMember[] {
  const list = (json as { members?: Record<string, unknown>[] })?.members ?? [];
  return list.map((m) => ({
    memId: String(m.mem_id), district: normDistrict(String(m.dist ?? '')),
    lastName: String(m.preferred_last_name ?? ''), fullName: String(m.preferred_full_name ?? ''),
  }));
}

/** Minimal CSV reader (quoted fields, doubled quotes). Enough for the Open States people file. */
export function parseCsv(text: string): Record<string, string>[] {
  const rows: string[][] = [];
  let row: string[] = [], field = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') q = false;
      else field += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(field); field = ''; if (row.some((f) => f !== '')) rows.push(row); row = [];
    } else field += c;
  }
  if (field !== '' || row.length) { row.push(field); rows.push(row); }
  const [head, ...body] = rows;
  return body.map((r) => Object.fromEntries(head.map((h, i) => [h, r[i] ?? ''])));
}

export function parseOpenStatesPeople(csv: string): OpenStatesPerson[] {
  return parseCsv(csv)
    .filter((r) => r.current_chamber === 'lower' || r.current_chamber === 'upper')
    .map((r) => ({
      ocdId: r.id, chamber: r.current_chamber === 'lower' ? 'house' : 'senate',
      district: normDistrict(r.current_district), name: r.name, links: `${r.links};${r.sources}`,
    }));
}

export const houseProfileId = (s: string | null): string | null =>
  /house\.(?:leg\.state\.)?mn(?:\.gov)?\/members\/profile\/(\d+)/i.exec(s ?? '')?.[1] ?? null;
export const senateMemId = (s: string | null): string | null =>
  /(?:senate\.mn|mnsenate\.gov)\/members\/member_bio\.html\?(?:[^;"]*&)?mem_id=(\d+)/i.exec(s ?? '')?.[1] ?? null;

/** True when the record's family name (last word, or a hyphenated/two-word family) appears in the source name. */
export function familyAgrees(ourFullName: string, sourceName: string): boolean {
  const ours = fold(ourFullName).split(' ').filter((w) => !['jr', 'sr', 'ii', 'iii', 'iv'].includes(w));
  const theirs = ` ${fold(sourceName)} `;
  const last = ours[ours.length - 1];
  return !!last && theirs.includes(` ${last} `);
}

export interface MatchResult { rows: MemberIdRow[]; problems: string[] }

/**
 * Pairs each sitting legislator with the LRL id, Senate mem_id and Open States id for their seat.
 * `problems` is non-empty when anything is off; a caller must refuse to write when it is.
 */
export function matchMinnesota(args: {
  holders: SeatHolder[]; lrl: LrlMember[]; senate: SenateMember[]; openStates: OpenStatesPerson[];
  sources: { lrl: string; senate: string; openStates: string };
}): MatchResult {
  const { holders, lrl, senate, openStates, sources } = args;
  const rows: MemberIdRow[] = [];
  const problems: string[] = [];
  const key = (c: Chamber, d: string) => `${c}|${d}`;

  const group = <T>(xs: T[], k: (x: T) => string) => {
    const m = new Map<string, T[]>();
    for (const x of xs) m.set(k(x), [...(m.get(k(x)) ?? []), x]);
    return m;
  };
  const lrlBySeat = group(lrl, (x) => key(x.chamber, x.district));
  const senBySeat = group(senate, (x) => x.district);
  const holdersBySeat = group(holders, (h) => key(h.chamber, h.district));
  const osByLrl = new Map<string, OpenStatesPerson[]>();
  const osByMem = new Map<string, OpenStatesPerson[]>();
  for (const p of openStates) {
    const h = houseProfileId(p.links);
    const s = senateMemId(p.links);
    if (p.chamber === 'house' && h) osByLrl.set(h, [...(osByLrl.get(h) ?? []), p]);
    if (p.chamber === 'senate' && s) osByMem.set(s, [...(osByMem.get(s) ?? []), p]);
  }

  for (const [seat, hs] of holdersBySeat) if (hs.length > 1) problems.push(`seat ${seat}: ${hs.length} current holders in our records`);
  for (const [seat, ls] of lrlBySeat) {
    if (ls.length > 1) problems.push(`seat ${seat}: LRL lists ${ls.length} members`);
    if (!holdersBySeat.has(seat)) problems.push(`seat ${seat}: LRL lists ${ls[0].name} (${ls[0].lrlId}); we have no current holder`);
  }

  for (const h of holders) {
    const seat = key(h.chamber, h.district);
    if ((holdersBySeat.get(seat)?.length ?? 0) > 1) continue;
    const ls = lrlBySeat.get(seat) ?? [];
    if (ls.length !== 1) { if (!ls.length) problems.push(`${h.fullName} (${seat}): no LRL member at this seat`); continue; }
    const l = ls[0];
    if (!familyAgrees(h.fullName, l.name)) { problems.push(`${h.fullName} (${seat}): LRL names ${l.name} (${l.lrlId}) — family name differs`); continue; }
    const photoHouse = houseProfileId(h.photoOriginUrl);
    if (photoHouse && photoHouse !== l.lrlId) { problems.push(`${h.fullName} (${seat}): photo URL has House id ${photoHouse}, LRL id is ${l.lrlId}`); continue; }
    rows.push({ politicianId: h.politicianId, idType: 'mn-lrl', idValue: l.lrlId, matchMethod: 'seat', source: sources.lrl, sourceName: l.name });

    if (h.chamber === 'house') {
      const os = osByLrl.get(l.lrlId) ?? [];
      if (os.length === 1 && os[0].district === h.district) {
        rows.push({ politicianId: h.politicianId, idType: 'openstates', idValue: os[0].ocdId, matchMethod: 'id_crosswalk', source: sources.openStates, sourceName: os[0].name });
      } else problems.push(`${h.fullName} (${seat}): Open States has ${os.length} House record(s) linking LRL id ${l.lrlId}${os[0] ? ` (district ${os[0].district})` : ''}`);
      continue;
    }

    const ss = senBySeat.get(h.district) ?? [];
    if (ss.length !== 1) { problems.push(`${h.fullName} (${seat}): Senate API lists ${ss.length} members for district ${h.district}`); continue; }
    const s = ss[0];
    if (!familyAgrees(h.fullName, s.fullName || s.lastName)) { problems.push(`${h.fullName} (${seat}): Senate API names ${s.fullName} (mem_id ${s.memId}) — family name differs`); continue; }
    const photoMem = senateMemId(h.photoOriginUrl);
    if (photoMem && photoMem !== s.memId) { problems.push(`${h.fullName} (${seat}): photo URL has mem_id ${photoMem}, Senate API has ${s.memId}`); continue; }
    rows.push({ politicianId: h.politicianId, idType: 'mn-senate-mem', idValue: s.memId, matchMethod: 'seat', source: sources.senate, sourceName: s.fullName });
    const os = osByMem.get(s.memId) ?? [];
    if (os.length === 1 && os[0].district === h.district) {
      rows.push({ politicianId: h.politicianId, idType: 'openstates', idValue: os[0].ocdId, matchMethod: 'id_crosswalk', source: sources.openStates, sourceName: os[0].name });
    } else problems.push(`${h.fullName} (${seat}): Open States has ${os.length} Senate record(s) linking mem_id ${s.memId}`);
  }

  const dupes = group(rows, (r) => `${r.idType}|${r.idValue}`);
  for (const [k, rs] of dupes) if (rs.length > 1) problems.push(`id ${k} matched ${rs.length} people`);
  return { rows, problems };
}
