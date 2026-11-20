/**
 * Locating a photograph that carries no coordinates.
 *
 * 🔴 WHY THIS EXISTS AT ALL. Geometry is the only trustworthy membership key and this module
 * does not pretend otherwise. But measured on Delaware 2026-11-19, 151 of 231 swept files —
 * 65% — carry no coordinates. Treating those as "not here" tells the operator a county is
 * empty when most of its photographs were simply never geotagged. The spec's answer is three
 * legs, and ALL THREE are required:
 *   1. a published caption naming the place,
 *   2. confirmed against a SECOND INDEPENDENT source,
 *   3. and the operator's own sight of it.
 * Leg 3 is not here. It is enforced in countyBannerReviewService.recordDecision, because it is
 * a fact about the decision and not about the file.
 *
 * 🔴 A CAPTION WITHOUT A STATE IS NOT EVIDENCE. There is a Dawson County in six states and a
 * Lexington in dozens. A bare place name is the put-a-Colorado-photograph-on-a-Nebraska-county
 * failure wearing a caption instead of a category.
 *
 * 🔴 OUR OWN PLACE LIST IS MISSING FOR 20 STATES. Measured on prod 2026-11-20: 52 states have
 * G4020 county polygons; only 32 have G4110 place polygons. Nebraska and Delaware — the two
 * states this programme has actually swept — have none. A rule that silently required a match
 * against that list would have returned "no caption evidence" for 20 states and looked like a
 * finding. So `placeListAvailable` travels with every result and reaches the operator on the
 * row, and where it is false the file's own Commons category leaf is accepted as the place
 * name — weaker, declared, and never counted as geometry.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import type { CandidateFile } from './types.js';

export interface PlaceNames {
  county: string;
  state: string;
  stateUsps: string;
  places: string[];
  placeListAvailable: boolean;
  /** The file's own Commons category leaf, used only where we hold no place list. */
  categoryLeaf?: string;
}

export interface CaptionResult {
  located: boolean;
  reason: string;
  matchedPlace?: string;
  captionText?: string;
  captionSourceUrl?: string;
  confirmingSourceUrl?: string;
  /** The host that confirmed it, so the operator can judge the source rather than trust it. */
  confirmingDomain?: string;
  placeListAvailable?: boolean;
}

export interface CaptionDeps {
  /** Fetch a page's text. Used only to CONFIRM a name we already hold. */
  fetchText: (url: string) => Promise<string>;
}

function fold(s: string): string {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
}

/** Whole-word containment, so 'Cozad' does not match 'Cozadium'. */
function names(haystack: string, needle: string): boolean {
  if (!needle) return false;
  const h = fold(haystack);
  const n = fold(needle).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`(^|[^\\p{L}\\p{N}])${n}($|[^\\p{L}\\p{N}])`, 'u').test(h);
}

/**
 * Does this caption name the state?
 *
 * 🔴 THE POSTAL ABBREVIATION IS AN ORDINARY WORD IN TWO LANGUAGES, AND MATCHING IT CASE-BLIND
 * REBUILDS THE WRONG-COUNTY FAILURE THIS WHOLE MODULE EXISTS TO PREVENT. Found in review,
 * reproduced against this function:
 *     Indiana  (IN): "The courthouse in Marion, Ohio, photographed in 1912" -> matched Marion
 *     Delaware (DE): "Vista de Dover, acantilados de Inglaterra"            -> matched Dover
 *     Oregon   (OR): "Eugene Delacroix, oil or canvas"                      -> matched Eugene
 *     Maine    (ME): "Rockland Harbor; photo given to me by the author"     -> matched Rockland
 * The first is the spec's named anti-goal exactly: a photograph of Marion, OHIO, offered as a
 * candidate for Marion County, INDIANA. Commons descriptions are often not in English, which
 * puts DE, LA, AL, PA, MA, SC and MS in the same trap.
 *
 * So the abbreviation is matched ONLY in postal shape: uppercase, in the UNFOLDED caption,
 * and preceded by a comma or whitespace. Folding lowercases, which destroys the one signal
 * that separates `IN` from `in` — so this check runs BEFORE fold(), which is why it cannot
 * live inside names().
 *
 * The full state name is matched case-insensitively as before; "indiana" is never a stray word.
 */
function namesState(caption: string, p: PlaceNames): boolean {
  if (names(caption, p.state)) return true;
  const u = p.stateUsps.toUpperCase();
  if (!u) return false;
  // ⚠ `\\s` and `\\p`, not `\s` and `\p`: inside a TEMPLATE LITERAL an unrecognised escape
  // loses its backslash, so `\s` would reach the RegExp as a bare `s` and this would match
  // "Marion, IN" only when preceded by a literal 's'. Caught by the postal-shape test.
  return new RegExp(`(^|[,\\s(])${u}($|[^\\p{L}\\p{N}])`, 'u').test(caption);
}

/**
 * The place this caption names, or null.
 *
 * Requires BOTH a place and the state. The place may be the county itself, one of our own
 * place polygons, or — only where we hold no place list for the state — the file's Commons
 * category leaf.
 */
export function captionNamesPlace(caption: string, p: PlaceNames): string | null {
  if (!caption) return null;
  if (!namesState(caption, p)) return null;

  const countyShort = p.county.replace(/\s+(County|Parish|Borough|Census Area|Municipality)$/i, '');
  const candidates = [
    p.county,
    countyShort,
    ...p.places,
    ...(p.placeListAvailable ? [] : (p.categoryLeaf ? [p.categoryLeaf] : [])),
  ];
  for (const c of candidates) {
    if (names(caption, c)) return c;
  }
  return null;
}

/** The last two labels of a URL's host, as a cheap eTLD+1. `null` when it is not a URL. */
export function registrableDomain(url: string): string | null {
  try {
    const host = new URL(url).hostname.toLowerCase();
    const parts = host.split('.').filter(Boolean);
    if (parts.length < 2) return host || null;
    const base = parts.slice(-2).join('.');
    // 🔴 THE WIKIMEDIA FAMILY IS ONE SOURCE. wikipedia.org and wikimedia.org are different
    // strings and the same organisation, and Wikipedia articles and Commons files routinely
    // copy each other's captions — so a Wikipedia URL 'confirming' a Commons caption is one
    // assertion cited twice. Found in review: the control that was watched failing used
    // upload.wikimedia.org, the one WMF host a bare string comparison happens to catch.
    if (WMF_DOMAINS.has(base)) return 'wikimedia-family';
    return base;
  } catch {
    return null;
  }
}

const WMF_DOMAINS = new Set([
  'wikimedia.org', 'wikipedia.org', 'wikidata.org', 'wikisource.org', 'wikivoyage.org',
  'wikibooks.org', 'wikiquote.org', 'wikinews.org', 'wiktionary.org', 'wikiversity.org',
  'mediawiki.org', 'wikimediafoundation.org',
]);

const COMMONS_FILE_BASE = 'https://commons.wikimedia.org/wiki/';

/** The page the caption was read from — the same page the licence was read from. */
function captionSource(title: string): string {
  return `${COMMONS_FILE_BASE}${encodeURI(title).replace(/#/g, '%23')}`;
}

/**
 * Apply legs 1 and 2 of the rule. Never throws: a network failure is a RESULT with a reason,
 * because a thrown error in the middle of a state would read as "this county has nothing".
 */
export async function confirmByCaption(
  f: CandidateFile & { caption?: string | null; creditUrl?: string | null },
  p: PlaceNames,
  deps: CaptionDeps,
): Promise<CaptionResult> {
  const caption = (f.caption ?? '').trim();
  if (!caption) return { located: false, reason: 'no caption published on the file page' };

  const matched = captionNamesPlace(caption, p);
  if (!matched) {
    return { located: false, reason: `the caption does not name a place in ${p.county}, ${p.state}` };
  }

  const confirming = (f.creditUrl ?? '').trim();
  if (!confirming) {
    return { located: false, reason: 'no second source published to confirm the caption', matchedPlace: matched };
  }
  const captionHost = registrableDomain(captionSource(f.title));
  const confirmHost = registrableDomain(confirming);
  if (!confirmHost || confirmHost === captionHost) {
    // Commons citing Commons is one source twice, not two sources.
    return {
      located: false,
      reason: 'the second source is not independent of the caption',
      matchedPlace: matched,
    };
  }

  let text: string;
  try {
    text = await deps.fetchText(confirming);
  } catch (e) {
    return {
      located: false,
      reason: `could not read the second source: ${(e as Error).message}`,
      matchedPlace: matched,
    };
  }

  if (!names(text, matched)) {
    return {
      located: false,
      reason: `the second source does not name ${matched}`,
      matchedPlace: matched,
    };
  }

  return {
    located: true,
    reason: `caption names ${matched}, confirmed independently at ${confirmHost}`,
    matchedPlace: matched,
    captionText: caption,
    captionSourceUrl: captionSource(f.title),
    confirmingSourceUrl: confirming,
    confirmingDomain: confirmHost,
    placeListAvailable: p.placeListAvailable,
  };
}
