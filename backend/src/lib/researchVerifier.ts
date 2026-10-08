/**
 * researchVerifier — deterministic verification of stance-research evidence.
 *
 * Pipeline: parsed CSVs → fetch each source URL → for each snippet, check it
 * appears verbatim on the page (after normalization) and the politician's
 * name appears within 500 characters of the match. No LLM involved.
 *
 * See docs/superpowers/specs/2026-04-30-stance-research-verification-design.md
 */

import { HTML_ENTITIES, decodeNumericEntities, decodeEntities } from './htmlEntities.js';

/**
 * Decode a page's character references for DISPLAY, and nothing else. See
 * {@link decodeEntities} — this is the name the stance pipeline uses for it.
 */
export const decodeForDisplay = decodeEntities;



export function normalizeText(input: string): string {
  // Numeric entities first (see decodeNumericEntities) — decoding `&#8217;` before anything else
  // runs turns it into the same curly apostrophe a named &rsquo; would have produced, so the
  // curly-quote normalization below catches both.
  let out = decodeNumericEntities(input);
  // HTML entities next (before quote normalization, since &quot; → ")
  for (const [entity, replacement] of Object.entries(HTML_ENTITIES)) {
    out = out.split(entity).join(replacement);
  }
  // Curly quotes → straight quotes
  out = out
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'");
  // Em / en dashes → hyphen
  out = out.replace(/[—–]/g, '-');
  // Lowercase
  out = out.toLowerCase();
  // 🔴 Fold diacritics. A name is the same name whether the source prints it
  // "Reneé" or "Renee", but without this fold `checkNameProximity` returns
  // `name_not_present` for every politician whose STORED name carries an accent
  // the source drops — the snippet matches, the person is plainly named, and the
  // row still fails. Measured on Charlotte 2026-10-02: WFAE writes "Renee
  // Johnson" and `essentials.politicians` holds "Reneé Johnson", and the row
  // verified under the unaccented spelling and failed under the stored one.
  out = out.normalize('NFD').replace(/[̀-ͯ]/g, '');
  // Collapse all whitespace runs to single space
  out = out.replace(/\s+/g, ' ');
  // Trim
  return out.trim();
}

// Default minimum snippet length (words). Stances want a bit of context, so 25;
// callers like read-rank (concise verbatim quotes) can pass a lower minWords.
export const MIN_SNIPPET_WORDS = 25;
// Verbatim n-gram size used to test whether the snippet's content appears on the
// page. 6 consecutive words is distinctive enough that a paraphrase won't match.
export const SHINGLE_WORDS = 6;
// Fraction of the snippet's shingles that must appear on the page WITHIN one
// bounded passage for the snippet to count as grounded.
export const MIN_SHINGLE_COVERAGE = 0.6;

export interface MatchOptions {
  /** Minimum snippet length in words (default MIN_SNIPPET_WORDS = 25). */
  minWords?: number;
  /** Fraction of shingles that must cluster in one passage (default MIN_SHINGLE_COVERAGE). */
  minCoverage?: number;
}

export type SnippetVerdict =
  | { verdict: 'verified'; matchOffset: number }
  | { verdict: 'snippet_not_found' }
  | { verdict: 'snippet_too_short' }
  | { verdict: 'name_not_present' }
  | { verdict: 'url_broken'; reason: string }
  // The site's robots.txt disallows our bot and no archived snapshot exists.
  // Distinct from url_broken so a policy "no" is counted separately from a
  // genuinely broken link. See verificationFetch.RobotsDisallowedError.
  | { verdict: 'robots_disallowed'; reason: string }
  // I6 (ruling 2026-09-24): the snippet passed matchSnippet, but its longest run of words that
  // appears CONTIGUOUSLY on the page is shorter than minWords — so there is no publishable span.
  | { verdict: 'span_too_short'; spanWords: number }
  // I1 (2026-09-24): this evidence URL is not one of the row's research.csv sources, so it is
  // not verified or published whatever its snippets say.
  | { verdict: 'url_not_cited' };

/**
 * Verify a snippet is genuinely drawn from ONE passage of the page.
 *
 * The snippet does NOT have to be a single contiguous copy — agents legitimately
 * drop a few words, keep an ellipsis, or wrap a real quote in light framing. But
 * it must not be paraphrased, and it must not stitch together comments from
 * far-apart parts of the article. So we require that a large fraction of the
 * snippet's 6-word verbatim shingles appear on the page packed into a single
 * bounded window (one passage) — not scattered across it.
 *
 * - Paraphrase  → few exact shingles match            → snippet_not_found
 * - Stitched far-apart comments → shingles match but don't cluster → snippet_not_found
 * - Real excerpt (± minor framing / dropped words)    → shingles cluster → verified
 */
export function matchSnippet(
  snippet: string,
  pageText: string,
  opts: MatchOptions = {},
): SnippetVerdict {
  const minWords = opts.minWords ?? MIN_SNIPPET_WORDS;
  const minCoverage = opts.minCoverage ?? MIN_SHINGLE_COVERAGE;

  const normalizedSnippet = normalizeText(snippet);
  const words = normalizedSnippet.split(' ').filter(Boolean);
  if (words.length < minWords) {
    return { verdict: 'snippet_too_short' };
  }
  const normalizedPage = normalizeText(pageText);

  // Fast path: the whole snippet appears verbatim on the page.
  const full = normalizedPage.indexOf(normalizedSnippet);
  if (full !== -1) {
    return { verdict: 'verified', matchOffset: full };
  }

  // (a) A single contiguous verbatim run of >= minWords words. Strong, distinctive
  // grounding; tolerates light framing around a real quote, and cannot be forged
  // by stitching two far-apart comments (the stitch point breaks contiguity).
  for (let i = 0; i + minWords <= words.length; i++) {
    const off = normalizedPage.indexOf(words.slice(i, i + minWords).join(' '));
    if (off !== -1) {
      return { verdict: 'verified', matchOffset: off };
    }
  }

  // (b) Otherwise, accept a real excerpt that isn't perfectly contiguous (a few
  // words dropped mid-passage) by requiring most of its 6-word shingles to appear
  // CLUSTERED in one bounded passage. A paraphrase shares too few exact shingles;
  // a snippet stitched from far-apart comments fails the span window.
  const k = Math.min(SHINGLE_WORDS, words.length);
  const total = words.length - k + 1;
  if (total <= 0) {
    return { verdict: 'snippet_not_found' };
  }
  const hits: number[] = [];
  for (let i = 0; i < total; i++) {
    const off = normalizedPage.indexOf(words.slice(i, i + k).join(' '));
    if (off !== -1) hits.push(off);
  }
  if (hits.length === 0) {
    return { verdict: 'snippet_not_found' };
  }

  const maxSpan = Math.min(4000, Math.max(600, normalizedSnippet.length * 2));
  hits.sort((a, b) => a - b);
  let best = 0;
  let bestStart = hits[0];
  let lo = 0;
  for (let hi = 0; hi < hits.length; hi++) {
    while (hits[hi] - hits[lo] > maxSpan) lo++;
    const count = hi - lo + 1;
    if (count > best) {
      best = count;
      bestStart = hits[lo];
    }
  }

  if (best / total >= minCoverage) {
    return { verdict: 'verified', matchOffset: bestStart };
  }
  return { verdict: 'snippet_not_found' };
}

/**
 * THE PUBLISHABLE SPAN of a snippet (I6, ruling 2026-09-24).
 *
 * matchSnippet keeps its 60% shingle rule for deciding WHETHER a snippet is grounded. But a
 * snippet that verifies on 60% coverage can carry up to 40% words that are not on the page, and a
 * snippet is published as a public citation. So only this span is ever stored or published:
 *
 *   the LONGEST run of consecutive snippet words whose normalized text appears CONTIGUOUSLY on the
 *   normalized page (normalizeText on both sides).
 *
 * It is real page text, a continuous run, and it contains none of the snippet's unmatched words.
 * `text` is the snippet's own words for that run (its original casing and punctuation), so
 * normalizeText(text) is a substring of normalizeText(page) — checked, not assumed. `offset` is
 * where it starts in the normalized page, for the name-proximity check.
 *
 * null when the snippet has no word on the page at all. The caller enforces the minimum length:
 * a span under MIN_SNIPPET_WORDS does not count as verified.
 *
 * Linear in snippet length: if words[i..j] is on the page, so is words[i+1..j], so a sliding
 * window finds the longest run with O(n) page searches.
 */
export function matchedSpan(
  snippet: string, pageText: string,
): { text: string; words: number; offset: number } | null {
  const rawTokens = snippet.trim().split(/\s+/).filter(Boolean);
  const normTokens = rawTokens.map((t) => normalizeText(t));
  // A token that normalizes to nothing or to two words (an entity like &nbsp; inside it) breaks the
  // one-to-one map from raw to normalized words; fall back to normalized words for the text.
  const aligned = normTokens.every((t) => t.length > 0 && !t.includes(' '));
  const words = aligned ? normTokens : normalizeText(snippet).split(' ').filter(Boolean);
  const source = aligned ? rawTokens : words;
  if (words.length === 0) return null;
  // Padded with spaces on both sides so a run matches WHOLE page words only: without it, a span
  // ending in "end" would match a page reading "endless" and publish a clipped word.
  const page = ` ${normalizeText(pageText)} `;
  // The index of " run " in the padded page is the run's own index in the unpadded normalized page.
  const find = (from: number, to: number) => page.indexOf(` ${words.slice(from, to + 1).join(' ')} `);
  let best: { i: number; j: number; offset: number } | null = null;
  let i = 0;
  for (let j = 0; j < words.length; j++) {
    // Extend the window to j; shrink from the left until words[i..j] is on the page.
    let off = find(i, j);
    while (off === -1 && i < j) {
      i++;
      off = find(i, j);
    }
    if (off === -1) { i = j + 1; continue; }
    if (!best || j - i > best.j - best.i) best = { i, j, offset: off };
  }
  if (!best) return null;
  const text = source.slice(best.i, best.j + 1).join(' ');
  // Belt and braces: the published text must normalize to whole-word page text.
  if (!page.includes(` ${normalizeText(text)} `)) return null;
  return { text, words: best.j - best.i + 1, offset: best.offset };
}

export const NAME_PROXIMITY_CHARS = 500;

// Last names common enough that a bare match is too coincidence-prone — require
// a title qualifier (Sen./Rep./Mayor/Gov./Pres./Councilor/etc.) nearby.
export const COMMON_LAST_NAMES: ReadonlySet<string> = new Set([
  'smith', 'johnson', 'williams', 'brown', 'jones', 'garcia', 'miller',
  'davis', 'rodriguez', 'martinez', 'hernandez', 'lopez', 'gonzalez',
  'wilson', 'anderson', 'thomas', 'taylor', 'moore', 'jackson', 'martin',
  'lee', 'thompson', 'white', 'harris', 'clark', 'lewis', 'robinson',
  'walker', 'young', 'allen', 'king', 'wright', 'scott', 'green', 'baker',
  'adams', 'nelson', 'hill', 'campbell', 'mitchell', 'roberts', 'carter',
  'phillips', 'evans', 'turner', 'parker', 'edwards', 'collins',
]);

// ⚠ The municipal and county titles matter as much as the legislative ones for
// this programme: a city commission (Miami, Tallahassee), a county commission,
// a board of supervisors and a school board of trustees all style their members
// with words this pattern did not carry. Miami seats a Christine King and
// Bradenton a Lisa Gonzalez Moore — `king`, `moore`, `brown` and `gonzalez` are
// all COMMON_LAST_NAMES, so without the title the guard cannot fire for them.
// ⚠ `council member` and `city council member` are the two-word renderings most
// newspapers use; the closed-up `councilmember` is mostly an official-site
// spelling. Without the spaced forms the common-surname fallback cannot fire for
// a city councillor, which is the whole municipal cohort — "Council member Renee
// Johnson" failed this test while "Councilmember" would have passed.
const TITLE_PATTERN = /\b(sen|sen\.|senator|rep|rep\.|representative|gov|gov\.|governor|pres|pres\.|president|mayor|councilor|councilman|councilwoman|councilmember|council member|city council member|commissioner|county commissioner|alderman|alderwoman|alderperson|supervisor|trustee|selectman|delegate|asm|asm\.|assemblymember|judge|justice|chief|sheriff|hon|hon\.|honorable)\b/;

/** How many alternate names one politician may contribute. A bound, not a judgement: the list is
 * scanned once per snippet, so a row carrying a hundred names must not slow every check. */
export const MAX_ALIASES = 8;

/**
 * The usable alternate names on a politician row (`essentials.politicians.alternate_names`).
 *
 * A source routinely prints the name a person put on the ballot while our record holds their legal
 * one. Measured on Duvall WA 2026-10-06: the Snoqualmie Valley Record, the King County voters'
 * pamphlet and the election results all write "Jenn Hernandez" where the record says "Jennifer
 * Hernandez". Neither name test fired — the full name is absent from the page, and `hernandez` is
 * on {@link COMMON_LAST_NAMES}, which demands a title no article has reason to give a candidate —
 * so a real, read, chair-level answer could not be cited.
 *
 * 🔴 ONE-TOKEN NAMES ARE DROPPED, and that is the whole safety property. An alias is accepted as a
 * FULL name, which is precisely the path that bypasses the common-surname rule; a bare "Jenn" would
 * hand that bypass to every page carrying a common first name. Two tokens keeps an alias at least
 * as specific as the full name it stands in for.
 */
export function aliasesFrom(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const out: string[] = [];
  const seen = new Set<string>();
  for (const raw of value) {
    if (typeof raw !== 'string') continue;
    const collapsed = raw.trim().replace(/\s+/g, ' ');
    if (collapsed.split(' ').filter(Boolean).length < 2) continue;
    const key = normalizeText(collapsed);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(collapsed);
    if (out.length >= MAX_ALIASES) break;
  }
  return out;
}

export function checkNameProximity(args: {
  fullName: string;
  lastName: string;
  /** Other full names this person is published under. {@link aliasesFrom} is re-applied here, so a
   * caller that hands over the raw column cannot widen the test by accident. */
  aliases?: string[];
  pageText: string;
  matchOffsetInNormalized: number;
}): SnippetVerdict {
  const { fullName, lastName, aliases, pageText, matchOffsetInNormalized } = args;
  if (matchOffsetInNormalized < 0) {
    return { verdict: 'snippet_not_found' };
  }
  const normalizedPage = normalizeText(pageText);
  const fullNameLower = normalizeText(fullName);
  const lastNameLower = normalizeText(lastName);

  // Window: 500 chars before snippet start to 500 chars after snippet start.
  const windowStart = Math.max(0, matchOffsetInNormalized - NAME_PROXIMITY_CHARS);
  const windowEnd = Math.min(
    normalizedPage.length,
    matchOffsetInNormalized + NAME_PROXIMITY_CHARS,
  );
  const window = normalizedPage.slice(windowStart, windowEnd);

  // Full name in window → verified.
  if (window.includes(fullNameLower)) {
    return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
  }

  // An alternate full name counts the same, and for the same reason: it identifies the person as
  // precisely as the record's own spelling. It is checked BEFORE the surname path so that a page
  // printing the ballot name never falls through to the common-surname rule.
  for (const alias of aliasesFrom(aliases)) {
    if (window.includes(normalizeText(alias))) {
      return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
    }
  }

  // Last name in window?
  if (window.includes(lastNameLower)) {
    const isCommon = COMMON_LAST_NAMES.has(lastNameLower);
    if (!isCommon) {
      return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
    }
    // Common last name — require title qualifier within 30 chars before each
    // occurrence of the last name in the window.
    let idx = window.indexOf(lastNameLower);
    while (idx !== -1) {
      const lookbehind = window.slice(Math.max(0, idx - 30), idx);
      if (TITLE_PATTERN.test(lookbehind)) {
        return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
      }
      idx = window.indexOf(lastNameLower, idx + 1);
    }
  }

  return { verdict: 'name_not_present' };
}

export type PageFetchResult =
  | { ok: true; text: string }
  // `robotsDisallowed` distinguishes a policy block from a broken URL; the two
  // are surfaced as different verdicts and counted separately.
  | { ok: false; reason: string; robotsDisallowed?: boolean };

export type PageFetcher = (url: string) => Promise<PageFetchResult>;

/**
 * createPageFetcher — wraps an underlying fetch fn with per-URL caching for
 * the lifetime of one verifier batch. Failures are cached too so we don't
 * retry obviously-broken URLs across multiple snippets in the same batch.
 */
export function createPageFetcher(
  rawFetch: (url: string) => Promise<string>,
): PageFetcher {
  const cache = new Map<string, PageFetchResult>();
  return async (url: string) => {
    const cached = cache.get(url);
    if (cached) return cached;
    let result: PageFetchResult;
    try {
      const text = await rawFetch(url);
      result = { ok: true, text };
    } catch (err: any) {
      // Detect the robots-disallowed signal by its stable `code`, so we don't
      // import verificationFetch here (keeps this module fetcher-agnostic).
      const robotsDisallowed = err?.code === 'robots_disallowed';
      result = robotsDisallowed
        ? { ok: false, reason: 'robots_disallowed', robotsDisallowed: true }
        : { ok: false, reason: err?.message ?? String(err) };
    }
    cache.set(url, result);
    return result;
  };
}

export interface StanceRow {
  full_name: string;
  politician_id: string;
  topic_key: string;
  value: number | null;
  reasoning: string;
  /**
   * I1: the row's research.csv sources (source_url_1..3), carried by stance-gate into stances.csv.
   * verifyEvidence verifies ONLY evidence on these URLs. Undefined = no restriction (a caller that
   * has no row sources, e.g. a unit test); verify-stance-research.ts refuses a stances.csv without
   * the column, so the pipeline always passes it.
   */
  source_urls?: string[];
  /** record | statement | blank, from research.csv (stored on the review row). */
  evidence_type?: string;
  /** Codebook V6 blank reason when value is 0 (a Season 2 blank); null/absent for a chair. */
  blank_reason?: string | null;
}

export interface EvidenceRow {
  full_name: string;
  topic_key: string;
  source_url: string;
  snippet: string;
  snippet_index: number;
}

export interface VerifiedSnippet {
  snippet: string;
  snippet_index: number;
  verdict: SnippetVerdict;
  /** I6: the publishable span (matchedSpan) — set exactly when verdict is 'verified'. */
  matchedSpan?: string;
}

export interface VerifiedSource {
  url: string;
  snippets: VerifiedSnippet[];
  /**
   * A person-saved copy of this own-site page exists (src/lib/humanSavedCopy.ts). Reviewer
   * information only: it never changes a verdict and never counts toward the source threshold.
   */
  humanSaved?: { sha256: string; snippets_found: number[]; snippets_total: number };
}

export interface VerifiedRow {
  stance: StanceRow;
  verifiedSources: VerifiedSource[];
  failedSources: VerifiedSource[];
}

export interface VerifyResult {
  pushable: VerifiedRow[];
  needsReResearch: VerifiedRow[];
  reviewQueue: VerifiedRow[];
}

export interface PoliticianNames {
  [fullName: string]: { fullName: string; lastName: string; aliases?: string[] };
}

/**
 * THE one name/topic normalizer for a research batch. stance-gate (stanceGate.ts) and
 * verify-stance-research (this module's verifyEvidence, and the script's gate-findings join) all
 * key rows through these, so a spelling difference that one of them tolerates cannot be a
 * mismatch to another. Before this, the gate joined evidence case-insensitively while the
 * verifier joined exactly — so a `jane doe` evidence row passed the gate and then silently
 * verified nothing.
 */
export const normName = (s: string): string => s.trim().replace(/\s+/g, ' ').toLowerCase();
export const normTopic = (s: string): string => s.trim().toLowerCase();
export const stanceKey = (name: string, topic: string): string => `${normName(name)}\u0000${normTopic(topic)}`;

export async function verifyEvidence(args: {
  stanceRows: StanceRow[];
  evidenceRows: EvidenceRow[];
  fetcher: PageFetcher;
  threshold: number;
  politicianNames: PoliticianNames;
  /** Snippet match tuning. Defaults: minWords 25, minCoverage 0.6. */
  match?: MatchOptions;
  /**
   * URLs the batch declares as the person's OWN site (sources.json source_kind 'own-site'; ruling
   * 2026-10-08, Chris Andrews). Attribution there is by ownership, not by the surname sitting near the
   * quote: a first-person issue page says "we need…" and prints the name once, in the header. The
   * snippet must still be found on the page; only the name-proximity test is waived.
   */
  ownSiteUrls?: ReadonlySet<string>;
}): Promise<VerifyResult> {
  const { stanceRows, evidenceRows, fetcher, threshold, politicianNames, match, ownSiteUrls } = args;

  const grouped = new Map<string, Map<string, EvidenceRow[]>>();
  for (const ev of evidenceRows) {
    const key = stanceKey(ev.full_name, ev.topic_key);
    if (!grouped.has(key)) grouped.set(key, new Map());
    const bySource = grouped.get(key)!;
    if (!bySource.has(ev.source_url)) bySource.set(ev.source_url, []);
    bySource.get(ev.source_url)!.push(ev);
  }

  const pushable: VerifiedRow[] = [];
  const needsReResearch: VerifiedRow[] = [];

  for (const stance of stanceRows) {
    const key = stanceKey(stance.full_name, stance.topic_key);
    const bySource = grouped.get(key) ?? new Map<string, EvidenceRow[]>();
    const names = politicianNames[stance.full_name];
    if (!names) {
      needsReResearch.push({ stance, verifiedSources: [], failedSources: [] });
      continue;
    }

    const verifiedSources: VerifiedSource[] = [];
    const failedSources: VerifiedSource[] = [];

    // I1: an evidence URL the row does not cite is never fetched, verified or published. The rule is
    // exact string equality after trim — the same comparison stance-gate's source-without-snippet
    // and evidence-url-not-cited checks use — so the gate and the verifier cannot disagree.
    const cited = stance.source_urls ? new Set(stance.source_urls.map((u) => u.trim())) : null;
    for (const [url, snippets] of bySource.entries()) {
      const judged: VerifiedSnippet[] = [];
      if (cited && !cited.has(url.trim())) {
        for (const ev of snippets) judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: { verdict: 'url_not_cited' } });
        failedSources.push({ url, snippets: judged });
        continue;
      }
      const fetched = await fetcher(url);
      if (!fetched.ok) {
        for (const ev of snippets) {
          judged.push({
            snippet: ev.snippet,
            snippet_index: ev.snippet_index,
            verdict: fetched.robotsDisallowed
              ? { verdict: 'robots_disallowed', reason: fetched.reason }
              : { verdict: 'url_broken', reason: fetched.reason },
          });
        }
      } else {
        for (const ev of snippets) {
          const matchVerdict = matchSnippet(ev.snippet, fetched.text, match);
          if (matchVerdict.verdict !== 'verified') {
            judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: matchVerdict });
            continue;
          }
          // I6: only the matched span may be published, and it must itself meet the minimum length.
          const span = matchedSpan(ev.snippet, fetched.text);
          const minWords = match?.minWords ?? MIN_SNIPPET_WORDS;
          if (!span || span.words < minWords) {
            judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index,
              verdict: { verdict: 'span_too_short', spanWords: span?.words ?? 0 } });
            continue;
          }
          // Name proximity is measured from the SPAN — the text that will be published.
          const proxVerdict: SnippetVerdict = ownSiteUrls?.has(url)
            ? { verdict: 'verified', matchOffset: span.offset }
            : checkNameProximity({
              fullName: names.fullName,
              lastName: names.lastName,
              aliases: names.aliases,
              pageText: fetched.text,
              matchOffsetInNormalized: span.offset,
            });
          judged.push({
            snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: proxVerdict,
            // I6 + display: the span is what a voter reads, so it is stored decoded. The snippet beside it
            // keeps the researcher's copy of the page; both fold through normalizeText, so
            // validStoredSpan still pairs them at approval.
            ...(proxVerdict.verdict === 'verified' ? { matchedSpan: decodeForDisplay(span.text) } : {}),
          });
        }
      }
      const anyVerified = judged.some((s) => s.verdict.verdict === 'verified');
      if (anyVerified) verifiedSources.push({ url, snippets: judged });
      else failedSources.push({ url, snippets: judged });
    }

    const row: VerifiedRow = { stance, verifiedSources, failedSources };
    if (verifiedSources.length >= threshold) pushable.push(row);
    else needsReResearch.push(row);
  }

  return { pushable, needsReResearch, reviewQueue: [] };
}
