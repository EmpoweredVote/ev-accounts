/**
 * partyLabels.ts — one detector for party labels, and the check that a shown quote only brackets them out.
 *
 * Ruling (season-topic-prep RULINGS.md "Party labels never reach a reader", 2026-10-29): a party label is a
 * party's name or colour used for people or places ("Republicans", "the GOP", "Democratic lawmakers", "R-Idaho",
 * "(D-GA)", "red states"); "democratic process" is not one. A quote shown to voters replaces each label with a
 * bracketed neutral word from BRACKET_WORDS; an evidence snippet is never edited (it is dropped instead).
 *
 * Used by the Stage 5 quote check and writer (scripts/lib/stage5QuoteCheck.ts, stage5Write.ts), the evidence
 * writer (researchEvidenceService.accumulateEvidence) and the stance gate (scripts/lib/stanceGate.ts). Pure.
 */

/** Party names in English text, any case. */
const PARTY_RE = /\b(republicans?|democrats?|democratic party|libertarians?|GOP\w*|DNC|RNC|DFL|green party|independent party|independence party|working families( party)?|constitution party|reform party|conservative party|tea party)\b/i;
// Case-sensitive forms: "Democratic" as a name ("Democratic lawmakers") and "Dem"/"Dems", but not "a democratic process".
const PARTY_NAME_CASED = /\b(Democratic|Dems?)\b/;
// Party colours used as labels for people or places ("red states", "a blue district").
const PARTY_COLOUR = /\b(red|blue)[- ](states?|count(y|ies)|districts?|cit(y|ies)|areas?|voters?|wave)\b/i;

// The state part of a "party-state" tag: postal codes, full names, and the older press abbreviations.
const STATE_CODES = 'AL|AK|AZ|AR|CA|CO|CT|DE|DC|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY|PR|GU|VI|AS|MP';
const STATE_NAMES = 'Alabama|Alaska|Arizona|Arkansas|California|Colorado|Connecticut|Delaware|Florida|Georgia|Hawaii|Idaho|Illinois|Indiana|Iowa|Kansas|Kentucky|Louisiana|Maine|Maryland|Massachusetts|Michigan|Minnesota|Mississippi|Missouri|Montana|Nebraska|Nevada|New Hampshire|New Jersey|New Mexico|New York|North Carolina|North Dakota|Ohio|Oklahoma|Oregon|Pennsylvania|Rhode Island|South Carolina|South Dakota|Tennessee|Texas|Utah|Vermont|Virginia|Washington|West Virginia|Wisconsin|Wyoming|Puerto Rico|Guam';
const STATE_ABBREVS = String.raw`Ala|Ariz|Ark|Calif|Colo|Conn|Del|Fla|Ga|Ill|Ind|Kan|Kans|Ky|La|Md|Mass|Mich|Minn|Miss|Mo|Mont|Neb|Nebr|Nev|Okla|Ore|Pa|Penn|Tenn|Tex|Va|Vt|Wash|Wis|Wisc|Wyo|[NSW]\.\s?[A-Z]\.?|N\.\s?[HJMY]\.?`;
// "R-Idaho", "(D-GA)", "D-N.Y.", "R-Ill.", "R–Texas". The state list keeps "D-Day" and "R-rated" out.
const PARTY_STATE_TAG = new RegExp(String.raw`\b[RD]\s?[-–—]\s?(?:(?:${STATE_CODES})\b|(?:${STATE_NAMES})\b|(?:${STATE_ABBREVS})(?:\.|\b))`);
// "Smith (R)", "Jones (D)", "(R.)".
const PARTY_LETTER = /\((?:R|D)\.?\)/;
// State-press "party-town" and "party-district" tags (Michigan, 2026-10-30): "(D-Grand Rapids)", "Lindsey, R-Allen",
// "R-Brighton Township", "(D-Tucson)", "(R-79)". A capital after the dash; "D-Day" is kept out by name, "R-rated"
// and "Section D-1" by the capital and the brackets.
const PARTY_TOWN_TAG = /\b[RD]\s?[-–—]\s?(?!Day\b)[A-Z][a-z]+(?:\s[A-Z][a-z]+){0,2}\b/;
const PARTY_DISTRICT_TAG = /\((?:R|D)\s?[-–—]\s?\d{1,3}\)/;

const PATTERNS = [PARTY_RE, PARTY_NAME_CASED, PARTY_COLOUR, PARTY_STATE_TAG, PARTY_LETTER, PARTY_TOWN_TAG, PARTY_DISTRICT_TAG];

/**
 * Party tags and colours only ("R-Idaho", "(D-GA)", "(D-Warren)", "Smith (R)", "red states"), without the party names. For the
 * stance gate, which reads party names with its own rules (stanceGate.ts PARTY_NAMES / PARTY_NOUNS_ANY_CASE).
 */
export function namesPartyTagOrColour(text: string): boolean {
  return PARTY_STATE_TAG.test(text) || PARTY_LETTER.test(text) || PARTY_COLOUR.test(text)
    || PARTY_TOWN_TAG.test(text) || PARTY_DISTRICT_TAG.test(text);
}

/** True when the text carries a party label. Fails safe: a false hit costs one quote or snippet. */
export function namesParty(text: string): boolean {
  return PATTERNS.some((re) => re.test(text));
}

/**
 * The only words a shown quote may put in brackets in place of a party label (ruled 2026-10-29: a fixed list,
 * so no slanted word can be slipped in; it grows only by ruling). A bracket may start with a capital at the
 * start of a sentence, and "..." counts as "…".
 */
export const BRACKET_WORDS = ['…', 'some lawmakers', 'some officials', 'some voters', 'some states', 'others'] as const;

/** The longest original stretch one bracket may stand in for, so a bracket cannot swallow a clause. */
export const MAX_BRACKETED_CHARS = 40;

function bracketWord(inner: string): boolean {
  const w = inner === '...' ? '…' : inner;
  return BRACKET_WORDS.some((b) => b === w || (b !== '…' && b[0].toUpperCase() + b.slice(1) === w));
}

/** Collapse whitespace; curly → straight quotes; en/em dash → hyphen. The same changes passageOnPage allows. */
function norm(s: string): string {
  return s.replace(/[“”„‟″«»]/g, '"').replace(/[‘’‚‛′]/g, "'").replace(/[–—]/g, '-').replace(/\s+/g, ' ').trim();
}

// Words that may go out with a label inside one bracket ("Democratic lawmakers", "my Republican colleagues",
// "Republican-led states"). Anything else in the cut is the speaker's point and must stay visible.
const LABEL_COMPANIONS = new Set([
  'the', 'my', 'our', 'their', 'his', 'her', 'your', 'some', 'many', 'most', 'all', 'other', 'fellow', 'and', 'of',
  'in', 'on', 'a', 'an', 'lawmakers', 'legislators', 'members', 'member', 'leaders', 'leader', 'leadership',
  'colleagues', 'colleague', 'friends', 'senators', 'senator', 'sen', 'representatives', 'representative', 'rep',
  'reps', 'officials', 'governors', 'governor', 'voters', 'states', 'state', 'majority', 'minority', 'caucus',
  'party', 'parties', 'led', 'controlled', 'run', 'side', 'house', 'senate', 'congress', 'legislature',
  'counties', 'county', 'districts', 'district', 'cities', 'city', 'areas', 'area', 'wave',
]);

/** The words left in a cut once every party label is taken out, lower case. */
function residueWords(cut: string): string[] {
  let rest = cut;
  for (const re of PATTERNS) rest = rest.replace(new RegExp(re.source, re.flags.includes('g') ? re.flags : `${re.flags}g`), ' ');
  return rest.toLowerCase().split(/[^a-z]+/).filter(Boolean);
}

const escapeRe =(s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * Check that `shown` is `original` with only party labels replaced by brackets from BRACKET_WORDS.
 * Returns null when it is, or the reason it is not. Brackets not on the list are read as the speaker's own
 * (e.g. "[sic]") and must match the original word for word. Whitespace, quote marks and dashes are compared
 * as passageOnPage compares them.
 */
export function bracketEditProblem(original: string, shown: string): string | null {
  const o = norm(original);
  const s = norm(shown);
  if (s === o) return 'the shown text is the same as the original; store no shown text';
  const parts = s.split(/(\[[^\]]*\])/);
  let ours = 0;
  const pattern = parts.map((p) => {
    const m = /^\[([^\]]*)\]$/.exec(p);
    if (m && bracketWord(m[1])) { ours += 1; return `(.{1,${MAX_BRACKETED_CHARS}}?)`; }
    return escapeRe(p);
  }).join('');
  if (ours === 0) return `no bracket from the list (${BRACKET_WORDS.map((b) => `[${b}]`).join(', ')})`;
  const hit = new RegExp(`^${pattern}$`, 's').exec(o);
  if (!hit) return 'the shown text changes more than party labels (outside the brackets it must match the original word for word)';
  for (const cut of hit.slice(1)) {
    if (!namesParty(cut)) return `a bracket replaces "${cut}", which is not a party label`;
    const extra = residueWords(cut).filter((w) => !LABEL_COMPANIONS.has(w));
    if (extra.length) return `a bracket replaces "${cut}", which says more than a party label ("${extra.join(' ')}")`;
  }
  if (namesParty(s)) return 'a party label is still in the shown text';
  return null;
}
