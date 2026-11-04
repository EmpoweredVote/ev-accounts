/**
 * rollCallEvidence — the roll-call lane of the research verifier.
 *
 * A vote seat cannot pass the snippet-plus-name test: the bill text never names a voter, and a
 * House roll call (clerk.house.gov/evs/<year>/roll<NNN>.xml) prints each member by surname only
 * ("Guthrie", or "Jackson (IL)" when two share one), beside a party attribute that must never be
 * published. Found on the Season 3 voting-rights federal batch (2026-10-29): 33 Yea-vote seats on
 * H.R. 22, H.R. 8281 and S. 1383 verified nothing.
 *
 * So a roll-call evidence row carries ONE canonical line built from the XML, which prints no party:
 *
 *   House roll call 345 (2024), H R 8281, On Passage: Guthrie (KY) voted Aye.
 *
 * The verifier fetches the XML again and checks the line field by field: roll number, year (from
 * the URL), bill, question, and a recorded vote with this surname, this state and this vote. The
 * surname must also be the politician's own last name. The checked line is what a voter reads.
 * Who the surname belongs to was settled when the vote was linked (census:identity, by the
 * official member list for that session); this lane re-checks the record, not the identity.
 */
import { normalizeText, type SnippetVerdict } from './researchVerifier.js';

const HOUSE_ROLL_XML = /^https:\/\/clerk\.house\.gov\/evs\/(\d{4})\/roll(\d{1,4})\.xml$/i;
const VOTES = ['Yea', 'Nay', 'Aye', 'No', 'Present', 'Not Voting'] as const;
const LINE = new RegExp(
  `^House roll call (\\d{1,4}) \\((\\d{4})\\), ([^,:]+), ([^:]+): ([^()]+?) \\(([A-Z]{2})\\) voted (${VOTES.join('|')})\\.$`,
);

export interface RollCallLine {
  rollNum: number;
  year: number;
  legisNum: string;
  question: string;
  surname: string;
  state: string;
  vote: (typeof VOTES)[number];
}

export function isRollCallXmlUrl(url: string): boolean {
  return HOUSE_ROLL_XML.test(url.trim());
}

export function formatRollCallLine(l: RollCallLine): string {
  return `House roll call ${l.rollNum} (${l.year}), ${l.legisNum}, ${l.question}: ${l.surname} (${l.state}) voted ${l.vote}.`;
}

export function parseRollCallLine(text: string): RollCallLine | null {
  const m = LINE.exec(text.trim());
  if (!m) return null;
  return {
    rollNum: Number(m[1]), year: Number(m[2]), legisNum: m[3].trim(), question: m[4].trim(),
    surname: m[5].trim(), state: m[6], vote: m[7] as RollCallLine['vote'],
  };
}

const tag = (xml: string, name: string): string | null => {
  const m = new RegExp(`<${name}>\\s*([^<]*?)\\s*</${name}>`).exec(xml);
  return m ? m[1] : null;
};
const decode = (s: string): string =>
  s.replace(/&amp;/g, '&').replace(/&apos;/g, "'").replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
/** "Jackson (IL)" → "Jackson"; accents and case folded, as the verifier folds names. */
const foldName = (s: string): string => normalizeText(decode(s).replace(/\s*\([A-Z]{2}\)\s*$/, ''));

/**
 * Check a canonical line against the roll-call XML at `url`. `lastName` and `fullName` are the
 * politician's own, from the bundle. Returns `verified` with offset 0 when every field matches;
 * otherwise `snippet_not_found` (the record does not say this) or `name_not_present` (it does, for
 * someone whose name is not this politician's).
 */
export function verifyRollCallLine(line: string, url: string, xml: string, lastName: string, fullName?: string): SnippetVerdict {
  const u = HOUSE_ROLL_XML.exec(url.trim());
  const l = parseRollCallLine(line);
  if (!u || !l) return { verdict: 'snippet_not_found' };
  if (Number(u[1]) !== l.year || Number(u[2]) !== l.rollNum) return { verdict: 'snippet_not_found' };
  if (Number(tag(xml, 'rollcall-num')) !== l.rollNum) return { verdict: 'snippet_not_found' };
  if (normalizeText(tag(xml, 'legis-num') ?? '') !== normalizeText(l.legisNum)) return { verdict: 'snippet_not_found' };
  if (normalizeText(decode(tag(xml, 'vote-question') ?? '')) !== normalizeText(l.question)) return { verdict: 'snippet_not_found' };
  const want = foldName(l.surname);
  const rec = /<recorded-vote>\s*<legislator\b([^>]*)>([^<]*)<\/legislator>\s*<vote>([^<]*)<\/vote>\s*<\/recorded-vote>/g;
  let found = false;
  for (let m = rec.exec(xml); m; m = rec.exec(xml)) {
    const state = /\bstate="([A-Z]{2})"/.exec(m[1])?.[1];
    if (foldName(m[2]) === want && state === l.state && m[3].trim() === l.vote) { found = true; break; }
  }
  if (!found) return { verdict: 'snippet_not_found' };
  // The surname on the roll must be this politician's own (folded the same way). When the clerk adds
  // a first name or initial to tell two members apart ("Gonzalez, Vicente", "Gonzalez, V."), it must
  // fit the politician's first name too.
  const [rollSurname, rollGiven] = want.split(',').map((s) => s.trim());
  // A two-word surname the clerk prints whole ("Leger Fernandez") must end the politician's full name.
  const full = foldName(fullName ?? '').replace(/,/g, ' ').replace(/\s+(jr|sr|ii|iii|iv|v)\.?$/, '').trim();
  const compound = rollSurname.includes(' ') && (full === rollSurname || full.endsWith(` ${rollSurname}`));
  if (rollSurname !== foldName(lastName) && !compound) return { verdict: 'name_not_present' };
  if (rollGiven) {
    const first = normalizeText(fullName ?? '').split(' ')[0] ?? '';
    const given = rollGiven.replace(/\.$/, '');
    if (!first || !(first === given || (given.length === 1 && first.startsWith(given)))) return { verdict: 'name_not_present' };
  }
  return { verdict: 'verified', matchOffset: 0 };
}

/**
 * Whether the roll-call XML is the roll call it was fetched to prove: its `legis-num` is `billNumber`
 * (spaces removed from both, so the clerk's "H J RES 44" is the table's "HJRES 44") and its
 * `rollcall-num` is `rollNum`. False when either field is missing.
 */
export function houseRollCallIsFor(xml: string, billNumber: string, rollNum: number): boolean {
  const legisNum = tag(xml, 'legis-num');
  const squash = (s: string) => decode(s).replace(/\s+/g, '').toUpperCase();
  return legisNum !== null && squash(legisNum) !== '' && squash(legisNum) === squash(billNumber)
    && Number(tag(xml, 'rollcall-num')) === rollNum;
}

/**
 * Build the canonical line for one member of a House roll call, chosen by bioguide id (`name-id`).
 * No surname guess is involved. The party attribute is never read. `null` when the member is not
 * on this roll call, when the URL is not a House roll-call XML URL, or when the XML lacks a field.
 */
export function houseRollCallLineFor(xml: string, url: string, bioguideId: string): string | null {
  const u = HOUSE_ROLL_XML.exec(url.trim());
  if (!u) return null;
  const rollNum = Number(tag(xml, 'rollcall-num'));
  const legisNum = tag(xml, 'legis-num');
  const question = tag(xml, 'vote-question');
  if (!rollNum || !legisNum || !question) return null;
  const rec = /<recorded-vote>\s*<legislator\b([^>]*)>([^<]*)<\/legislator>\s*<vote>([^<]*)<\/vote>\s*<\/recorded-vote>/g;
  for (let m = rec.exec(xml); m; m = rec.exec(xml)) {
    if (/\bname-id="([^"]*)"/.exec(m[1])?.[1] !== bioguideId) continue;
    const state = /\bstate="([A-Z]{2})"/.exec(m[1])?.[1];
    const vote = m[3].trim() as RollCallLine['vote'];
    if (!state || !VOTES.includes(vote)) return null;
    const built: RollCallLine = {
      rollNum, year: Number(u[1]), legisNum, question: decode(question),
      surname: decode(m[2]).replace(/\s*\([A-Z]{2}\)\s*$/, '').trim(), state, vote,
    };
    const line = formatRollCallLine(built);
    // Fail closed: a bill number or question the line format cannot carry (a ',' or ':') must not
    // yield a line the verifier would refuse, or one that parses into different fields.
    const back = parseRollCallLine(line);
    return back && JSON.stringify(back) === JSON.stringify(built) ? line : null;
  }
  return null;
}
