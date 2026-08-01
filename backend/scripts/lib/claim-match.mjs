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
  const dq = /["“”]/g;
  const hasDouble = (reasoning.match(dq) ?? []).length >= 2;
  const marks = hasDouble ? dq : /(?<=^|[\s(])'(?=\w)|(?<=[\w.,;:!?])'(?=[\s)]|$)/g;
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
function quotePresent(body, q) {
  const frags = quoteFragments(q);
  if (!frags.length) return null;                     // nothing testable in it
  const hay = norm(body);
  return frags.every((f) => {
    const w = norm(f).split(' ').filter(Boolean);
    if (w.length < SHINGLE) return hay.includes(norm(f));
    for (let i = 0; i + SHINGLE <= w.length; i++) {
      if (hay.includes(w.slice(i, i + SHINGLE).join(' '))) return true;
    }
    return false;
  });
}

/** Normalise for comparison: fold case, curly quotes, bracketed edits and all punctuation/space runs. */
function norm(s) {
  return s.toLowerCase()
    .replace(/[‘’“”]/g, "'")
    .replace(/\[[^\]]*\]/g, '')            // "advocate[s]" -> "advocate"
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

function candidateTerms(reasoning) {
  const text = reasoning.replace(/https?:\/\/\S+/g, ' ');
  const lower = text.toLowerCase();
  const seen = new Map();                       // lowercased -> original casing
  const add = (s) => {
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
      // 🔴 DROP COMPASS-CHAIR LABELS. The row author writes the chair they picked as a hyphenated
      // string -- "gradual-transition-while-investing-in-clean-energy", "public-program-plus-regulated-
      // private-insurance", "stop-issuing-new-drilling-permits". No web page contains those, so they are
      // guaranteed "missing" and they manufactured 15 CITATION_FAILS across TN/WA on rows that quote
      // their source correctly. Real-world hyphenated terms stay: cap-and-trade, market-based, anti-tax
      // and job-killing are all <=3 parts and were load-bearing in Oregon.
      if (m[0].split('-').length > 3) continue;
      add(m[0]);
    }
  }
  for (const p of POLICY_PHRASES) if (lower.includes(p)) add(p);

  // Single tokens from the curated policy lexicon only.
  for (const m of text.matchAll(/\b[a-zA-Z][a-zA-Z']{3,}\b/g)) {
    const k = m[0].toLowerCase();
    if (POLICY_TOKENS.has(k)) add(m[0]);
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
};
