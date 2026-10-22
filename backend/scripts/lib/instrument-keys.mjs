/**
 * Jurisdiction-scoped instrument keys, and which way the member went on them.
 *
 * WHY THIS EXISTS. Nothing in the corpus compares two rows that cite the SAME instrument. Sampling
 * the repaired rows on 2026-10-21 found 15 (instrument, topic) pairs seating MORE THAN ONE rung
 * across 167 rows — the Fair Share Amendment seating tax rungs 2, 3 and 4; the ROE Act seating
 * abortion rungs 1, 2 and 4. At most one mapping in each pair can be right, and no check looked.
 * data/stance-research/2026-10-21-repaired-rest-sample/MEASUREMENT.md has the measurement.
 *
 * ⚠ THE NAMED-ACT EXTRACTOR IS NOT REIMPLEMENTED HERE. `md-instruments.mjs` already does it and its
 * header records two rounds of manufacturing FAKE findings while being "improved". This module
 * COMPOSES with it and adds the numeric forms it does not cover; it never edits it.
 *
 * 🔴 A KEY IS ONLY EMITTED WHEN THE JURISDICTION IS KNOWN. "SB 13" in Texas and "SB 13" in
 * Massachusetts are different bills, and merging them would MANUFACTURE a contradiction out of two
 * correct rows. The jurisdiction comes from the cited HOST, which is an observation, not an
 * inference. A row whose host says nothing yields no numeric key and is simply not compared.
 *
 * 🔴 DIRECTION IS SCORED ON THE CLAUSE GOVERNING THE INSTRUMENT, never the whole row. That is
 * md-instruments' own lesson from migration 1694, where a 90-character window crossed into a second
 * clause and manufactured 8 fake contradictions. A row that votes FOR one bill and AGAINST another
 * in the same paragraph must not have both directions smeared across both bills.
 */
import { extractInstruments } from './md-instruments.mjs';

/** Cited host -> jurisdiction. Each one observed in the corpus, none assumed. */
const HOSTS = [
  [/capitol\.texas\.gov|journals\.house\.texas\.gov|journals\.senate\.texas\.gov/i, 'TX'],
  [/malegislature\.gov/i, 'MA'],
  [/lis\.virginia\.gov|legacylis\.virginia\.gov|law\.lis\.virginia\.gov/i, 'VA'],
  [/clerk\.house\.gov|congress\.gov|govtrack\.us|senate\.gov\/legislative/i, 'US'],
  [/mgaleg\.maryland\.gov/i, 'MD'],
  [/leginfo\.legislature\.ca\.gov/i, 'CA'],
  [/legislature\.maine\.gov/i, 'ME'],
  [/azleg\.gov/i, 'AZ'],
  [/ilga\.gov/i, 'IL'],
  [/nyassembly\.gov|nysenate\.gov/i, 'NY'],
];

/**
 * The jurisdiction a row's citations place it in, or null when they do not agree or do not say.
 * Two different legislatures in one row's sources means we cannot tell which one a bare "SB 13"
 * belongs to, so we decline rather than guess.
 */
export function jurisdictionOf(sources = []) {
  const found = new Set();
  for (const u of sources) for (const [re, j] of HOSTS) if (re.test(String(u))) found.add(j);
  return found.size === 1 ? [...found][0] : null;
}

const pad = (n) => String(n).replace(/^0+(?=\d)/, '').padStart(4, '0');

/**
 * Numeric instrument tokens, with the character offset where each was found so the caller can
 * score the governing clause. Returns [{ token, at }].
 */
function numericTokens(text) {
  const out = [];
  const add = (token, at) => out.push({ token, at });
  for (const m of text.matchAll(/\b([SH]B)\s*0*(\d{1,4})\b/gi)) add(`${m[1].toUpperCase()}${pad(m[2])}`, m.index);
  for (const m of text.matchAll(/\bH\.?\s?R\.?\s*0*(\d{1,5})\b/gi)) add(`HR${pad(m[1])}`, m.index);
  for (const m of text.matchAll(/\b(HJR|SJR|HCR|SCR)\s*0*(\d{1,4})\b/gi)) add(`${m[1].toUpperCase()}${pad(m[2])}`, m.index);
  for (const m of text.matchAll(/\b([HS])\.\s?(\d{3,4})\b/g)) add(`${m[1].toUpperCase()}${pad(m[2])}`, m.index);
  // Massachusetts rows cite a bill as <court>/<chamber><number>; the court is part of the identity
  // because the same act is refiled under a NEW number each court.
  for (const m of text.matchAll(/\b(\d{3})\/([HS])(\d{3,5})\b/g)) add(`${m[2].toUpperCase()}${pad(m[3])}`, m.index);
  return out;
}

/**
 * Every instrument this row can be compared on, as { key, at }.
 * Numeric keys are jurisdiction-scoped ("TX:SB0013"); named acts are not, because an act's name is
 * already unique enough to compare on and is often cited with no legislature host at all.
 */
export function extractInstrumentKeys(text, sources = []) {
  if (!text) return [];
  const juris = jurisdictionOf(sources);
  const out = new Map();
  if (juris) {
    for (const { token, at } of numericTokens(text)) {
      const key = `${juris}:${token}`;
      if (!out.has(key)) out.set(key, at);
    }
  }
  for (const name of extractInstruments(text)) {
    // 🔴 `extractInstruments` ALSO returns bare bill tokens ("SB0013"). Those must not become
    // unscoped ACT keys: that would merge Texas SB 13 with Massachusetts SB 13 and manufacture a
    // contradiction out of two correct rows about two different bills. The numeric forms are
    // handled above, WITH a jurisdiction. Keep only the named acts here.
    if (/^[SH]B\d+$/i.test(name)) continue;
    const at = text.indexOf(name);
    const key = `ACT:${name.toLowerCase().replace(/\s+/g, ' ').trim()}`;
    if (!out.has(key)) out.set(key, at < 0 ? 0 : at);
  }
  return [...out].map(([key, at]) => ({ key, at }));
}

/** The sentence containing `at`. The clause boundary is the whole point — see the header. */
export function clauseAt(text, at) {
  if (at == null || at < 0) return text;
  const start = Math.max(
    text.lastIndexOf('.', at), text.lastIndexOf(';', at), text.lastIndexOf('--', at),
  ) + 1;
  let end = text.length;
  for (const p of ['.', ';']) {
    const i = text.indexOf(p, at);
    if (i > -1 && i < end) end = i;
  }
  return text.slice(start < 0 ? 0 : start, end);
}

/**
 * Which way the member went ON THIS INSTRUMENT: 'FOR' | 'AGAINST' | 'SPONSOR' | null.
 *
 * ⚠ SPONSOR is kept SEPARATE from FOR on purpose. Sponsoring and voting are different acts, and
 * migration 1690's rule is that a sponsor list cannot settle a floor vote. Comparing a sponsor
 * against a yes-voter would be comparing two different claims.
 * ⚠ A clause carrying BOTH directions ("voted for X but opposed Y") yields null rather than a
 * guess: an ambiguous direction must not be allowed to create a contradiction.
 */
/**
 * How many DISTINCT instruments a clause names. A verb in a clause naming two instruments cannot
 * be attributed to either with confidence.
 */
function instrumentCount(clause) {
  const n = new Set();
  for (const m of clause.matchAll(/\b([sh]b|hr|hjr|sjr|hcr|scr)\s*\.?\s*0*(\d{1,5})\b/gi)) n.add(m[1].toLowerCase() + m[2].replace(/^0+/, ''));
  for (const m of clause.matchAll(/\b([hs])\.\s?0*(\d{3,4})\b/gi)) n.add(m[1].toLowerCase() + m[2].replace(/^0+/, ''));
  // "Bill" and "Amendment" count too: the clause that caused this rule names the One Big Beautiful
  // BILL and the Inflation Reduction ACT, and only counting acts would see just one of them.
  const named = /\b([a-z][a-z’']*(?:\s+(?:of|the|for|and|[a-z][a-z’']*)){0,6}\s+(?:act|bill|amendment))\b/gi;
  for (const m of clause.matchAll(named)) n.add(m[1].toLowerCase().replace(/\s+/g, ' '));
  return n.size;
}

export function directionFor(text, at) {
  const c = clauseAt(String(text), at).toLowerCase();

  // 🔴 ONE INSTRUMENT ACTING ON ANOTHER INVERTS THE SIDE.
  // "voted for the One Big Beautiful Bill WHICH SCALES BACK Inflation Reduction Act clean energy
  // incentives" names the IRA and would file the member as voting FOR it. He voted for the bill
  // that gutted it.
  // ⚠ The test is TWO instruments joined by a RELATIVE CLAUSE or an acts-upon verb, not merely two
  // instruments. A blunter "more than one instrument" rule was tried first and over-declined:
  // "Co-authored HB3, the Texas Education Savings Account bill" names one instrument twice, and
  // "Co-authored both HB3 and SB2" is one verb genuinely governing both. Those must still read.
  const ACTS_UPON = /\b(?:which|that)\b|\b(?:scales? back|guts?|eliminat\w+|terminat\w+|amend\w+|replac\w+|supersed\w+|defund\w+|rolls? back)\b/;
  if (instrumentCount(c) > 1 && ACTS_UPON.test(c)) return null;

  // 🔴 AN INVERSION MAKES THE SENTENCE UNREADABLE BY THIS METHOD, SO DECLINE IT.
  // "opposed efforts to REPEAL the Respect for Marriage Act" means he is FOR the act. Reading the
  // nearest verb gives exactly the wrong answer. Detect the shape and refuse rather than invert.
  if (/\b(?:repeal|overturn|rescind|strike|undo|roll back|weaken|gut)\w*\b/.test(c)) return null;

  const MARKERS = [
    [/\bvot(?:ed|e|es)\s+(?:nay|no|against)\b|\bvoting\s+nay\b|\bnay\b|\bopposed\b|\bvoted against\b/g, 'AGAINST'],
    [/\bvot(?:ed|e|es)\s+(?:yea|aye|yes|for|in favou?r)\b|\bvoting\s+(?:yea|aye)\b|\byea\b|\bsupported\b|\bbacked\b|\bendorsed\b/g, 'FOR'],
    [/\b(?:co-?sponsor(?:ed|s|ship)?|co-?author(?:ed|s)?|sponsored|authored|introduced|filed|carried)\b/g, 'SPONSOR'],
  ];

  // 🔴 A NEGATED CLAIM IS THE OPPOSITE CLAIM, AND IT IS EVERYWHERE IN THIS CORPUS.
  // "Canales did not co-author HB 3", "Geren is NOT listed as a co-author of HB 3". Read without
  // this guard, every non-co-sponsorship row files as a SPONSOR of the bill it declined to sign,
  // and the anti-voucher members land in the same group as the bill's authors — the largest false
  // group in the first live run, 101 Texas rows on HB 3.
  //
  // ⚠ THE GUARD IS DELIBERATELY BLUNT: ANY negator in the clause and we decline. A window around
  // the verb was tried and defeated three different ways in one afternoon:
  //   "Did not co-author HB3 … co-authored by 71 Republicans"  the second verb is about OTHER PEOPLE
  //   "Not listed as co-sponsor of SB 2 or co-author of HB 3"  the negator is too far from the verb
  //   "never voted for HB 3"                                    a different negator word
  // Each fix invited the next. Declining the whole clause costs coverage — which is printed on
  // every run — and cannot invent a side. That is the correct direction to be wrong in.
  const NEGATOR = /\b(?:no|not|n't|never|nor|without|declined|refused|failed|absent|lacks?)\b/;
  if (NEGATOR.test(c)) return null;

  const seen = new Set();
  for (const [re, kind] of MARKERS) {
    re.lastIndex = 0;
    if (re.test(c)) seen.add(kind);
  }

  // 🔴 MORE THAN ONE KIND OF CLAIM IN ONE SENTENCE IS NOT RESOLVABLE BY PROXIMITY, SO DECLINE.
  // "Matsui co-sponsored the Respect for Marriage Act …, voted NO on a constitutional amendment"
  // carries a SPONSOR and an AGAINST about two different instruments, and the comma splice means
  // no clause boundary separates them. Picking the nearer verb reads her as opposing the act she
  // sponsored. This costs coverage and that is the right trade: a missed row is a missed row, an
  // invented direction is an invented CONTRADICTION. (md-instruments, migration 1694, same lesson.)
  if (seen.size !== 1) return null;
  return [...seen][0];
}
