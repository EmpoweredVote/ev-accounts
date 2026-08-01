/**
 * Shared claim-matching primitives for the stance citation tools.
 *
 * MOVED HERE VERBATIM from audit-stance-citations.mjs on 2026-07-31, comments intact, when
 * repair-primary-site-paths.mjs needed the same matchers. Every rule below was calibrated against a
 * real wrong verdict -- the six false alarms in the 2026-07-31 post-mortem are all encoded here, and
 * the reasons are in the comments. DO NOT relax one without reading why it is the value it is.
 *
 * The point of a shared module is that the two tools cannot drift apart. If you tune a threshold
 * here, re-run the audit against a committed cohort JSON and diff before committing.
 */

const STATE_NAMES = {
  al: 'Alabama', ak: 'Alaska', az: 'Arizona', ar: 'Arkansas', ca: 'California', co: 'Colorado',
  ct: 'Connecticut', de: 'Delaware', fl: 'Florida', ga: 'Georgia', hi: 'Hawaii', id: 'Idaho',
  il: 'Illinois', in: 'Indiana', ia: 'Iowa', ks: 'Kansas', ky: 'Kentucky', la: 'Louisiana',
  me: 'Maine', md: 'Maryland', ma: 'Massachusetts', mi: 'Michigan', mn: 'Minnesota', ms: 'Mississippi',
  mo: 'Missouri', mt: 'Montana', ne: 'Nebraska', nv: 'Nevada', nh: 'New Hampshire', nj: 'New Jersey',
  nm: 'New Mexico', ny: 'New York', nc: 'North Carolina', nd: 'North Dakota', oh: 'Ohio', ok: 'Oklahoma',
  or: 'Oregon', pa: 'Pennsylvania', ri: 'Rhode Island', sc: 'South Carolina', sd: 'South Dakota',
  tn: 'Tennessee', tx: 'Texas', ut: 'Utah', vt: 'Vermont', va: 'Virginia', wa: 'Washington',
  wv: 'West Virginia', wi: 'Wisconsin', wy: 'Wyoming', dc: 'District of Columbia',
};

// ---------------------------------------------------------------------------- term extraction

const STOP = new Set(('the a an and or but of for to in on at by with from as is are was were be been being that this ' +
  'these those it its his her their our your they he she we you i not no nor so than then there here when where ' +
  'which who whom whose what how why all any both each few more most other some such only own same too very can ' +
  'will just should now also including includes include support supported supports supporting oppose opposed ' +
  'opposes opposing voted vote votes voting backed backs back consistent strong record position measures measure ' +
  'legislation bill bills policy policies during throughout part while against toward towards').split(/\s+/));

const CAP_PHRASE = /\b[A-Z][a-zA-Z']+(?:\s+(?:of|for|and|the|de|van)\s+|\s+)(?:[A-Z][a-zA-Z']+)(?:(?:\s+(?:of|for|and|the)\s+|\s+)[A-Z][a-zA-Z']+)*/g;
const HYPHEN = /\b[a-zA-Z]{2,}(?:-[a-zA-Z]{2,})+\b/g;
const SINGLE_CAP = /\b[A-Z][a-zA-Z']{4,}\b/g;
const BILLREF = /\b(?:H\.?\s?B|S\.?\s?B|HJR|SJR|HCR|SCR|A\.?\s?B|AJR|LD|LB|HF|SF|H\.?\s?R|S\.?\s?R|H\.?\s?Con\.?\s?Res|S\.?\s?J\.?\s?Res|RES|ORD|HJ|SJ)\s*[-.\s]?\s*\d+[A-Za-z]?\b/gi;
const MEASUREREF = /\b(?:Measure|Proposition|Prop|Question|Initiative|Amendment)\s*\.?\s*\d+[A-Za-z]?\b/gi;

/**
 * 🔴 NO ARBITRARY BIGRAMS. The first version of this extractor paired any two adjacent long words,
 * which produced "issue because", "scale closest", "people without", "dentist emphasizes". Those are
 * prose fragments, not claim terms: they are RARE, so the corpus-frequency filter keeps them, and they
 * land in `missing` and push genuinely-supported rows down to PARTIAL_SUPPORT. Calibrated against the
 * A1 audit, whose term lists were tight -- ["cap-and-trade","job-killing","walkout"] for Drazan,
 * ["Corporate Activity Tax","Lane County","anti-tax"] for Harbick. Multi-word phrases come from a
 * curated policy lexicon instead, which is high-precision by construction.
 */
const POLICY_PHRASES = [
  'border security', 'immigration enforcement', 'sanctuary city', 'sanctuary state', 'cap and trade',
  'voter id', 'photo id', 'clean energy', 'public option', 'single payer', 'school choice',
  'right to work', 'minimum wage', 'paid leave', 'family leave', 'gun control', 'assault weapons',
  'background checks', 'red flag', 'medicaid expansion', 'school vouchers', 'charter schools',
  'rent control', 'rent stabilization', 'affordable housing', 'criminal justice', 'police accountability',
  'qualified immunity', 'death penalty', 'campaign finance', 'dark money', 'donor disclosure',
  'term limits', 'ranked choice', 'vote by mail', 'automatic voter registration', 'gender affirming',
  'transgender athletes', 'parental rights', 'critical race theory', 'carbon tax', 'net metering',
  'fossil fuel', 'universal healthcare', 'public transit', 'zoning reform', 'inclusionary zoning',
  'corporate tax', 'income tax', 'sales tax', 'property tax', 'estate tax', 'payroll tax',
  'student debt', 'tuition free', 'universal pre', 'planned parenthood', 'parental notification',
  'heartbeat bill', 'late term', 'conscience protection', 'religious exemption', 'union dues',
  'collective bargaining', 'prevailing wage', 'tort reform', 'eminent domain', 'civil asset forfeiture',
  'bail reform', 'mandatory minimum', 'drug decriminalization', 'harm reduction', 'needle exchange',
  'work requirements', 'block grant', 'balanced budget', 'rainy day', 'kicker rebate',
];

/**
 * Frequent English and civic words that are worthless as claim terms. Single tokens only. The dynamic
 * corpus filter catches most of these when enough pages are read, but it needs ~8+ pages to be
 * reliable, and a small run must not therefore score a row on "Health" or "Participated".
 */
const COMMON_TOKEN = new Set(('republican republicans democrat democrats democratic senate house senator ' +
  'representative assembly legislature legislative congress congressional state states federal government ' +
  'governor mayor council county city district committee chair chairman speaker leader caucus session ' +
  'health healthcare education school schools tax taxes taxation budget spending revenue funding fund ' +
  'program programs bill bills law laws act acts policy policies measure measures legislation vote votes ' +
  'voted voting voter voters election elections campaign campaigns candidate candidates primary general ' +
  'participated supported opposed backed sponsored cosponsored introduced passed failed approved rejected ' +
  'public private community communities family families worker workers business businesses industry ' +
  'industries resident residents people person persons citizen citizens american americans national ' +
  'security social justice rights protection protections access expansion reform regulations regulation ' +
  'environmental economic financial social political conservative progressive liberal moderate ' +
  'platform position positions record records issue issues emphasizes calls scale closest current ' +
  'legal status alternatives controlled individually entitlements guilty aliens undocumented ' +
  'affecting blocking ending mandates approaches').split(/\s+/));

/**
 * Single tokens come from a CURATED lexicon, not a length rule. A generic ">=6 chars and not common"
 * rule leaked "because", "country", "explicit", "exception", "activity", "authorize" -- ordinary prose
 * words that are rare enough to survive a frequency filter and so become fake evidence in either
 * direction. These are the single words that actually carry a policy claim, and the A1 audit's real
 * finds are all here: walkout, quorum, sanctuary, medicaid.
 *
 * Under-extraction is SAFE here and over-extraction is not: a row with no surviving term becomes
 * UNTESTABLE, which this tool reports as a decision to be made rather than a retirement.
 */
const POLICY_TOKENS = new Set(('walkout quorum filibuster gerrymander gerrymandering sanctuary medicaid medicare ' +
  'obamacare vouchers voucher charter fracking pipeline pipelines abortion contraception ' +
  'trans transgender nonbinary immigration deportation daca ice asylum refugee refugees ' +
  'unionize unionization strikes picketing minimum wages tipped ' +
  'firearms firearm handgun handguns suppressors magazines ' +
  'marijuana cannabis psilocybin decriminalize decriminalization ' +
  'redistricting apportionment ballots absentee provisional gerrymandered ' +
  'vaccination vaccine mandate mandates masking lockdown lockdowns ' +
  'tariffs subsidies subsidy privatize privatization nationalize ' +
  'homelessness encampments upzoning downzoning setbacks ' +
  'reparations affirmative desegregation bussing ' +
  'nuclear renewables solar wind geothermal hydropower emissions ' +
  'kicker referendum initiative recall supermajority ' +
  'earmarks pork sequestration deficits surplus ' +
  'euthanasia hospice palliative telehealth ' +
  'homeschool homeschooling tenure creationism ' +
  'annexation zoning easement moratorium ordinance').split(/\s+/));

/**
 * 🔴 QUOTE-BEARING ROWS MUST BE JUDGED ON THE QUOTE, NOT ON DISTINCTIVE TERMS. Discovered on the TX
 * cohort, whose rows are a different breed from Oregon's: they quote campaign websites and Candidate
 * Connection surveys directly ("Resist any attempts to impose a national school voucher scheme") rather
 * than asserting bills. The term test produced FALSE FAILURES on them for three reasons, none of which
 * is evidence about the citation:
 *
 *   - morphology: the row's term was "vouchers", the page says "voucher"
 *   - the row's INTERPRETIVE vocabulary is not the source's: a row may correctly quote "the right to
 *     make their own healthcare decisions" and then reasonably label it abortion access. "abortion"
 *     being absent says something about the label, not about whether the citation checks out
 *   - extractor artifacts: "His Candidate Connection" (a capitalised phrase starting on the row's own
 *     pronoun) and "Paul Ryan's" (possessive that cannot match "Paul Ryan")
 *
 * A quote is a far stronger test than a term: it is long, verbatim and unambiguous. So when a row
 * contains quoted material, the quote verdict governs and the term verdict is reported alongside.
 */
/**
 * 🔴 PAIR THE QUOTE MARKS; DO NOT REGEX ACROSS THEM. And an apostrophe is NOT a quote mark. The first
 * version used /["“”']([^"“”]{25,400}?)["“”']/g and produced pure artifacts on the TX cohort:
 *
 *   - "s tariff authority and lower"   <- started mid-word inside Congress's, because ' was a delimiter
 *   - "a top plank -- citing his career in the Border Patrol"   <- the UNQUOTED prose BETWEEN two real
 *     quotes, because the regex matched from one closing mark to the next opening mark
 *
 * Both look exactly like a missing quote and would have put well-sourced rows on a retirement list.
 * Marks are therefore consumed in order, strictly as open/close pairs.
 *
 * 🔴 AN ELLIPSIS MEANS SPLICED, NON-CONTIGUOUS TEXT. "lower drug costs ... end surprise billing" can
 * never match a page verbatim, so the quote is split on the ellipsis and each fragment tested
 * separately. A quote counts as verified when every fragment long enough to be distinctive is present.
 */
function extractQuotes(reasoning) {
  // 🔴 A SINGLE QUOTE IS SOMETIMES A DELIMITER AND SOMETIMES A POSSESSIVE, AND GETTING THIS BINARY
  // WRONG BREAKS ROWS IN BOTH DIRECTIONS. Treating ' as a mark produced "s tariff authority" out of
  // Congress's; NOT treating it as a mark meant every row quoting with 'single quotes' skipped the quote
  // test entirely and fell through to terms -- which is what put Keith Arnold's three well-quoted rows,
  // Conroy, Gordon and Hildebrand on a retirement list. So it is position-sensitive: an opening mark is
  // preceded by start/space/( and followed by a word character; a closing mark is preceded by a word
  // character and followed by space/punctuation/end. Congress's fails both (letter on each side).
  // Closing single quote may sit after punctuation that belongs INSIDE the quotation
  // ("...renewable energy sources,'"), so the lookbehind must allow it -- but the lookahead still
  // requires whitespace/close-paren/end, which is what keeps Congress's (letter on both sides) out.
  // PREFER DOUBLE QUOTES WHENEVER THE ROW USES THEM, and only fall back to single. Mixing the two
  // delimiter sets mis-pairs the marks: a TRAILING possessive ("Sales' survey emphasizes \"...\"",
  // "Congress' authority") satisfies the closing-single-quote rule, so mark 1 lands on the possessive,
  // pairs with the real quote's opening ", and the actual quotation is lost -- which is what produced
  // Joshua Warren Sales's CITATION_FAILS on a row that quotes its source correctly.
  // 🔴 A DOUBLED APOSTROPHE IS A CLOSING DOUBLE QUOTE, AND NOT FOLDING IT DISCARDS THE QUOTE ENTIRELY.
  // Billy Nord's row reads: lists "ending the health insurance industry'' as a core platform goal.
  // One real double-quote mark plus a '' pair, so hasDouble was FALSE, extraction fell back to
  // single-quote mode, mis-paired on the '' and produced nothing testable -- the row then fell through
  // to the term test and was scored NOT_FOUND. His page says "ending the health insurance industry"
  // verbatim. The quote was never tested, which is a silent false negative rather than a wrong answer.
  reasoning = reasoning.replace(/''/g, '"');
  const dq = /["“”]/g;
  const hasDouble = (reasoning.match(dq) ?? []).length >= 2;
  // 🔴 A CLOSING QUOTE CAN BE FOLLOWED BY PUNCTUATION THAT SITS OUTSIDE THE QUOTATION, and refusing
  // to recognise it does not merely lose that quote -- it BREAKS PARITY for the whole row. In
  // "states under 'Reproductive Rights': 'For Jonathan, ...'" the mark after Rights is followed by a
  // colon, so the old lookahead [\s)] skipped it; the marks then paired up shifted by one and the
  // NEXT "quote" ran from the close of one real quotation to the open of the next, capturing the
  // row's own analytical prose ("This general pro-choice framing without an explicit ... matches
  // stance 2 ..."). That is bug #3 from the post-mortem coming back through a different door: it was
  // fixed by pairing marks in order, and an unrecognised mark defeats ordered pairing entirely.
  // Trailing , . ; : ! ? are therefore all valid after a closing mark.
  const marks = hasDouble ? dq : /(?<=^|[\s(])'(?=\w)|(?<=[\w.,;:!?])'(?=[\s).,;:!?]|$)/g;
  const positions = [];
  for (const m of reasoning.matchAll(marks)) positions.push(m.index);
  const out = [];
  for (let i = 0; i + 1 < positions.length; i += 2) {
    const q = reasoning.slice(positions[i] + 1, positions[i + 1]).trim();
    // >=3 words, not >=4. At >=4, Casey Shepard's quote "compassionate immigration reform" was skipped,
    // the row fell through to the term test, and its only surviving term was the author's own coinage
    // "reform-oriented" -- producing a CITATION_FAILS on a row whose quote was very likely on the page.
    if (q.length >= 20 && /[a-z]/i.test(q) && q.split(/\s+/).length >= 3) out.push(q);
  }
  return out;
}

/**
 * 🔴 A QUOTED COMPASS CHAIR LABEL IS NOT A QUOTATION FROM THE SOURCE, AND TESTING THE PAGE FOR IT
 * MANUFACTURES FAILURES. Rows routinely name the chair they picked in quotation marks -- Greg
 * Guithues's healthcare row ends `matching value 1 ("Make healthcare free and available to everyone,
 * paid for and run by the public sector")`. That string is OUR answer text. No campaign site contains
 * it, so `quotePresent` returns false, the row is scored as having an unverifiable quote, and it lands
 * in NOT_FOUND -- while the page in fact says "I support single payer medical and dental for all
 * Americans", which supports the row completely.
 *
 * Measured on the 113-row NOT_FOUND cohort 2026-08-01: 9 rows, ALL of them in QUOTE_ABSENT, which was
 * 41% of that bucket. This is the same error as the >3-hyphen chair-label rule in `candidateTerms`,
 * one level up: that rule drops chair labels from TERMS and nothing ever dropped them from QUOTES.
 *
 * Matching is containment either way round, because rows quote chairs both verbatim and trimmed.
 */
function isChairLabel(quote, chairTexts) {
  const nq = norm(quote);
  if (nq.length < 20) return false;
  return chairTexts.some((t) => {
    const ns = norm(t);
    return ns.length >= 20 && (ns.includes(nq) || nq.includes(ns));
  });
}

/** Fragments of a quote that are long enough to be distinctive, split on elided spans. */
function quoteFragments(q) {
  return q.split(/\s*(?:\.\.\.|…)\s*/).map((f) => f.trim()).filter((f) => norm(f).length >= 20);
}

/**
 * 🔴 MATCH A SHINGLE, NOT THE WHOLE FRAGMENT. Requiring the full contiguous fragment made long quotes
 * fail on a single differing word, and it produced FALSE ABSENCES on quotes that were plainly there:
 * Suetterlein's "David is pro-life ... taxpayer funding of abortion", Simonds's "We do not need a
 * voucher system", Pillion's "opposed to expanding Obamacare", Warner's tax-cut pledge. All four were
 * confirmed present by hand using shorter sub-phrases. A run of 6 consecutive words reproduced verbatim
 * is already overwhelming evidence the row is quoting this page, and it tolerates one edit elsewhere.
 */
const SHINGLE = 6;

/**
 * Light inflectional stem. Deliberately crude and only applied to words of 5+ characters, so "has"
 * and "ties" are left alone while "increasing" and "increase" both land on "increas".
 */
function stemWord(w) {
  if (w.length < 5) return w;
  return w.replace(/(?:ings?|ing|edly|ed|es|s)$/, '').replace(/e$/, '');
}
const stemLine = (s) => s.split(' ').map(stemWord).join(' ');

/**
 * 🔴 INFLECTION DEFEATED THE EXACT SHINGLE, AND IT IS THE SINGLE BIGGEST SOURCE OF FALSE FAILURES
 * LEFT IN THIS TOOL. Ana Valencia's row quotes "enhance community policing and increase support for
 * emergency services"; her page says "enhancING community policing and increasING support for
 * emergency services". Identical substance, and every 6-word window differs by a suffix, so the exact
 * test reported the quote absent and the row landed on a retirement list. `looseIncludes` has stemmed
 * for terms all along -- quotes simply never got the same treatment.
 *
 * Exact matching is tried FIRST and is unchanged; the stemmed pass only adds recall, and a run of six
 * consecutive words agreeing on their stems is still overwhelming evidence the row is quoting this
 * page. Recorded as a match, not as a lesser one, because "increase" vs "increasing" is not a defect
 * in the citation -- and per the post-mortem's own rule, inexact quotation is not fabrication.
 */
function quotePresent(body, q) {
  const frags = quoteFragments(q);
  if (!frags.length) return null;                     // nothing testable in it
  const hay = norm(body);
  const hayStem = stemLine(hay);
  return frags.every((f) => {
    const w = norm(f).split(' ').filter(Boolean);
    if (w.length < SHINGLE) return hay.includes(norm(f)) || hayStem.includes(stemLine(norm(f)));
    for (let i = 0; i + SHINGLE <= w.length; i++) {
      const run = w.slice(i, i + SHINGLE).join(' ');
      if (hay.includes(run) || hayStem.includes(stemLine(run))) return true;
    }
    return false;
  });
}

/** Normalise for comparison: fold case, curly quotes, bracketed edits and all punctuation/space runs. */
/**
 * 🔴 THE BRACKETED-EDIT STRIP MUST BE LENGTH-BOUNDED, OR ONE STRAY `[` DELETES THE REST OF THE PAGE.
 * `norm` is applied to the HAYSTACK as well as the needle, and the unbounded form -- /\[[^\]]*\]/g --
 * happily spans thousands of characters looking for a closing bracket. Measured on
 * sendnomoney.org 2026-08-01: a `[` at offset 5,517 paired with a `]` at 52,511 and the strip removed
 * 47,177 of 56,732 characters, 83% OF THE PAGE. John Vail's row was then scored NOT_FOUND on two
 * quotes -- "Target luxury of all sorts." and "a percentage wad of the whole taken every year." --
 * that are on that page VERBATIM, and a hand-check recorded it in the backlog as a genuine failure.
 *
 * This is the same shape as the doubled-apostrophe bug and the silent HTTP 202: nothing in the output
 * says text was discarded, so the false negative looks exactly like evidence. A real editorial
 * insertion is a word or two ("advocate[s]", "[sic]"), so the span is capped -- anything longer is
 * page furniture and is left in place, where at worst it fails to match.
 */
function norm(s) {
  return s.toLowerCase()
    .replace(/[‘’“”]/g, "'")
    .replace(/\[[^\][]{0,24}\]/g, '')      // "advocate[s]" -> "advocate"; bounded, see above
    // Drop possessives on BOTH sides before punctuation stripping. Otherwise the page's "Jackson
    // Women's Health" normalises to "jackson women s health" while the term-builder has already
    // removed the 's, giving "jackson women health" -- a guaranteed miss on a real, present phrase.
    .replace(/['’]s\b/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

/** Does `needle` appear in `haystack` allowing a simple plural/singular difference per word? */
function looseIncludes(haystack, needle) {
  const h = norm(haystack);
  const n = norm(needle);
  if (!n) return false;
  if (h.includes(n)) return true;
  const stem = (w) => w.replace(/(?:ies|es|s)$/, '');
  const nStem = n.split(' ').map(stem).join(' ');
  return nStem.length > 3 && h.split(' ').map(stem).join(' ').includes(nStem);
}

/**
 * Cues that mean the row is asserting a term is ABSENT from the source.
 *
 * 🔴 A NEGATED TERM MUST NEVER BE TESTED FOR PRESENCE -- THE ROW ALREADY SAID IT IS NOT THERE. This is
 * the real root of the "chair label" false alarms, and it is worth stating precisely because the first
 * diagnosis was wrong. Those failures were blamed on hyphenated chair names leaking into the term list,
 * and a >3-hyphen-part rule was added to catch them. But every one of the four measured cases is a
 * NEGATION, not a naming convention:
 *
 *   "without an explicit flat-tax or shrink-government-services pledge"          Harding
 *   "absent an explicit automatic-registration/online-voting pledge"             Miller-Watkins
 *   "propose no single-payer or public-option mechanism and no market-only ..."  Milleron
 *   "without an explicit all-stages public-funding statement"                    Nez
 *
 * The hyphen rule could never have fixed these: single-payer and public-option are two parts each and
 * are real policy terms -- they are in POLICY_PHRASES. Nothing about their SHAPE is wrong. What is
 * wrong is testing the page for a term the row explicitly says the candidate did not offer, and then
 * recording its absence as a citation failure. Scope is the rest of the clause, since a negation does
 * not carry across a sentence or a dash.
 */
const NEGATION_CUE = /\b(?:no|not|without|absent|lacks?|lacking|never|neither|nor|rather than|instead of|does not|do not|doesn't|don't|didn't|failed to|declined to|stops? short of|falls? short of|makes? no|offers? no|proposes? no)\b/gi;
/**
 * 🔴 A CONTRASTIVE CONJUNCTION ENDS THE NEGATION, and leaving it out over-drops. Measured on Tina
 * McKinnor's abortion row: "No authored bill directly on abortion found, BUT California Democratic
 * caucus members ... consistently vote for and co-author abortion access legislation." Running the
 * scope to the full stop swallowed the assertion after the "but", dropped abortion / co-author /
 * California Democratic, and pushed a PARTIAL_SUPPORT row down to CITATION_FAILS -- the negation fix
 * manufacturing exactly the kind of false failure it was written to remove.
 */
const CLAUSE_BREAK = /[.;]|--|—|\b(?:but|yet|however|although|though|whereas|while|instead|still)\b/;

/** Character ranges of `text` that sit under a negation, from the cue to the end of its clause. */
function negatedRanges(text) {
  const ranges = [];
  NEGATION_CUE.lastIndex = 0;
  for (const m of text.matchAll(NEGATION_CUE)) {
    const rest = text.slice(m.index);
    const brk = rest.search(CLAUSE_BREAK);
    ranges.push([m.index, m.index + (brk === -1 ? rest.length : brk)]);
  }
  return ranges;
}

function candidateTerms(reasoning) {
  const text = reasoning.replace(/https?:\/\/\S+/g, ' ');
  const lower = text.toLowerCase();
  const negated = negatedRanges(text);
  const isNegated = (i) => negated.some(([a, b]) => i >= a && i < b);
  const seen = new Map();                       // lowercased -> original casing
  const add = (s, at) => {
    if (at != null && isNegated(at)) return;
    // Strip a leading pronoun/determiner the capitalised-phrase regex swept up from the row's own prose
    // ("His Candidate Connection"), and drop possessives that can never match the page ("Paul Ryan's").
    const v = s.trim().replace(/\s+/g, ' ').replace(/[.,;:]$/, '')
      .replace(/^(?:His|Her|Their|Its|The|A|An|He|She|They)\s+/i, '')
      .replace(/['’]s\b/g, '');
    if (v.length < 5) return;
    const k = v.toLowerCase();
    if (STOP.has(k) || COMMON_TOKEN.has(k)) return;
    if (!seen.has(k)) seen.set(k, v);
  };

  for (const re of [BILLREF, MEASUREREF, CAP_PHRASE, HYPHEN]) {
    re.lastIndex = 0;
    for (const m of text.matchAll(re)) {
      // 🔴 DROP SPELLED-OUT COMPASS-CHAIR LABELS. The row author sometimes writes the chair they picked
      // as one hyphenated string -- "gradual-transition-while-investing-in-clean-energy",
      // "help-people-who-cant-afford-care-while-keeping-private-insurance-for-everyone-else". No web
      // page contains those. Real-world hyphenated terms stay: cap-and-trade, market-based, anti-tax
      // and job-killing are all <=3 parts and were load-bearing in Oregon.
      //
      // This rule is NARROWER than it was once believed to be, and the belief cost a wrong diagnosis.
      // It was credited with fixing the TN/WA chair-label failures; it cannot have, because those
      // terms (single-payer, public-option, flat-tax) are two parts each and pass this test. What
      // actually produced them is negation, handled in `add` above.
      if (m[0].split('-').length > 3) continue;
      add(m[0], m.index);
    }
  }
  for (const p of POLICY_PHRASES) {
    const at = lower.indexOf(p);
    if (at > -1) add(p, at);
  }

  // Single tokens from the curated policy lexicon only.
  for (const m of text.matchAll(/\b[a-zA-Z][a-zA-Z']{3,}\b/g)) {
    const k = m[0].toLowerCase();
    if (POLICY_TOKENS.has(k)) add(m[0], m.index);
  }

  // Drop any term wholly contained in a longer kept term ("oregon health" under "Oregon Health Plan",
  // "Security" under "Social Security") -- it is the same evidence counted twice.
  const kept = [...seen.values()];
  return kept.filter((t) => !kept.some((o) => o !== t && o.length > t.length
    && o.toLowerCase().includes(t.toLowerCase())));
}

/**
 * Identity terms: everything a page names because of WHOSE page it is. Built per row from the
 * politician's own name, district, office and state rather than a global list, because "Portland" is
 * identity for a Portland member and a real policy token for nobody else's page.
 */
function identityTerms(row) {
  const bits = [
    row.first_name, row.last_name, row.office_title, row.district_label, row.office_city,
    STATE_NAMES[row.st], row.st?.toUpperCase(),
  ].filter(Boolean);
  const set = new Set();
  for (const b of bits) {
    set.add(String(b).toLowerCase());
    for (const w of String(b).split(/[^A-Za-z]+/)) if (w.length >= 4) set.add(w.toLowerCase());
  }
  for (const generic of ['state house', 'state senate', 'house district', 'senate district', 'city council',
    'majority leader', 'minority leader', 'house majority', 'senate republican', 'senate democrat',
    'republican party', 'democratic party', 'state representative', 'state senator', 'county commission']) set.add(generic);
  return set;
}

export {
  STATE_NAMES, STOP, CAP_PHRASE, HYPHEN, SINGLE_CAP, BILLREF, MEASUREREF,
  POLICY_PHRASES, COMMON_TOKEN, POLICY_TOKENS, SHINGLE,
  extractQuotes, quoteFragments, quotePresent, norm, looseIncludes, candidateTerms, identityTerms,
  isChairLabel,
  // Exported 2026-08-01 for propose-quote-corrections.mjs, which scores how CLOSE a quote is to the
  // page rather than whether it is present. It has to fold inflection the same way `quotePresent`
  // does, or a row this module already treats as a match would score as a near-miss in the proposal.
  stemWord, stemLine,
};
