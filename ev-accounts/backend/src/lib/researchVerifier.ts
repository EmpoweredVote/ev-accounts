/**
 * researchVerifier — deterministic verification of stance-research evidence.
 *
 * Pipeline: parsed CSVs → fetch each source URL → for each snippet, check it
 * appears verbatim on the page (after normalization) and the politician's
 * name appears within 500 characters of the match. No LLM involved.
 *
 * See docs/superpowers/specs/2026-04-30-stance-research-verification-design.md
 */

const HTML_ENTITIES: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&nbsp;': ' ',
  '&#39;': "'",
};

export function normalizeText(input: string): string {
  let out = input;
  // HTML entities first (before quote normalization, since &quot; → ")
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
  // Collapse all whitespace runs to single space
  out = out.replace(/\s+/g, ' ');
  // Trim
  return out.trim();
}

export const MIN_SNIPPET_WORDS = 25;

export type SnippetVerdict =
  | { verdict: 'verified'; matchOffset: number }
  | { verdict: 'snippet_not_found' }
  | { verdict: 'snippet_too_short' }
  | { verdict: 'name_not_present' }
  | { verdict: 'url_broken'; reason: string };

export function matchSnippet(
  snippet: string,
  pageText: string,
): SnippetVerdict {
  const wordCount = snippet.trim().split(/\s+/).filter(Boolean).length;
  if (wordCount < MIN_SNIPPET_WORDS) {
    return { verdict: 'snippet_too_short' };
  }
  const normalizedSnippet = normalizeText(snippet);
  const normalizedPage = normalizeText(pageText);
  const offset = normalizedPage.indexOf(normalizedSnippet);
  if (offset === -1) {
    return { verdict: 'snippet_not_found' };
  }
  return { verdict: 'verified', matchOffset: offset };
}


export const NAME_PROXIMITY_CHARS = 500;

// Last names common enough that a bare match is too coincidence-prone — require
// a title qualifier (Sen./Rep./Mayor/Gov./Pres./Councilor/etc.) nearby.
const COMMON_LAST_NAMES = new Set([
  'smith', 'johnson', 'williams', 'brown', 'jones', 'garcia', 'miller',
  'davis', 'rodriguez', 'martinez', 'hernandez', 'lopez', 'gonzalez',
  'wilson', 'anderson', 'thomas', 'taylor', 'moore', 'jackson', 'martin',
  'lee', 'thompson', 'white', 'harris', 'clark', 'lewis', 'robinson',
  'walker', 'young', 'allen', 'king', 'wright', 'scott', 'green', 'baker',
  'adams', 'nelson', 'hill', 'campbell', 'mitchell', 'roberts', 'carter',
  'phillips', 'evans', 'turner', 'parker', 'edwards', 'collins',
]);

const TITLE_PATTERN = /\b(sen|sen\.|senator|rep|rep\.|representative|gov|gov\.|governor|pres|pres\.|president|mayor|councilor|councilman|councilwoman|councilmember|delegate|asm|asm\.|assemblymember|judge|justice|chief|sheriff|hon|hon\.|honorable)\b/;

export function checkNameProximity(args: {
  fullName: string;
  lastName: string;
  pageText: string;
  matchOffsetInNormalized: number;
}): SnippetVerdict {
  const { fullName, lastName, pageText, matchOffsetInNormalized } = args;
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
  | { ok: false; reason: string };

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
      result = { ok: false, reason: err?.message ?? String(err) };
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
}

export interface VerifiedSource {
  url: string;
  snippets: VerifiedSnippet[];
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
  [fullName: string]: { fullName: string; lastName: string };
}

function rowKey(fullName: string, topicKey: string): string {
  return `${fullName} ${topicKey}`;
}

export async function verifyEvidence(args: {
  stanceRows: StanceRow[];
  evidenceRows: EvidenceRow[];
  fetcher: PageFetcher;
  threshold: number;
  politicianNames: PoliticianNames;
}): Promise<VerifyResult> {
  const { stanceRows, evidenceRows, fetcher, threshold, politicianNames } = args;

  const grouped = new Map<string, Map<string, EvidenceRow[]>>();
  for (const ev of evidenceRows) {
    const key = rowKey(ev.full_name, ev.topic_key);
    if (!grouped.has(key)) grouped.set(key, new Map());
    const bySource = grouped.get(key)!;
    if (!bySource.has(ev.source_url)) bySource.set(ev.source_url, []);
    bySource.get(ev.source_url)!.push(ev);
  }

  const pushable: VerifiedRow[] = [];
  const needsReResearch: VerifiedRow[] = [];

  for (const stance of stanceRows) {
    const key = rowKey(stance.full_name, stance.topic_key);
    const bySource = grouped.get(key) ?? new Map<string, EvidenceRow[]>();
    const names = politicianNames[stance.full_name];
    if (!names) {
      needsReResearch.push({ stance, verifiedSources: [], failedSources: [] });
      continue;
    }

    const verifiedSources: VerifiedSource[] = [];
    const failedSources: VerifiedSource[] = [];

    for (const [url, snippets] of bySource.entries()) {
      const fetched = await fetcher(url);
      const judged: VerifiedSnippet[] = [];
      if (!fetched.ok) {
        for (const ev of snippets) {
          judged.push({
            snippet: ev.snippet,
            snippet_index: ev.snippet_index,
            verdict: { verdict: 'url_broken', reason: fetched.reason },
          });
        }
      } else {
        for (const ev of snippets) {
          const matchVerdict = matchSnippet(ev.snippet, fetched.text);
          if (matchVerdict.verdict !== 'verified') {
            judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: matchVerdict });
            continue;
          }
          const proxVerdict = checkNameProximity({
            fullName: names.fullName,
            lastName: names.lastName,
            pageText: fetched.text,
            matchOffsetInNormalized: matchVerdict.matchOffset,
          });
          judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: proxVerdict });
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
