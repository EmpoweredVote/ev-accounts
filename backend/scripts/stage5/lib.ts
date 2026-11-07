/** Pure helpers for the Stage 5 batch tools (scripts/stage5/README.md). */
import { namesParty } from '../../src/lib/partyLabels.js';
import {
  NAME_PROXIMITY_CHARS, aliasesFrom, checkNameProximity, lastNameOf, matchSnippet, matchedSpan,
} from '../../src/lib/researchVerifier.js';

/** RFC 4180 CSV reader for the batch files (quoted fields, doubled quotes, embedded newlines). */
export function readCsv(text: string): Record<string, string>[] {
  const recs: string[][] = [];
  let row: string[] = [], cur = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { cur += '"'; i++; } else if (c === '"') quoted = false; else cur += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(cur); cur = ''; }
    else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(cur); cur = ''; recs.push(row); row = [];
    } else cur += c;
  }
  if (cur !== '' || row.length) { row.push(cur); recs.push(row); }
  const [head, ...body] = recs.filter((r) => r.length > 1 || r[0] !== '');
  return (body ?? []).map((r) => Object.fromEntries(head.map((h, k) => [h, r[k] ?? ''])));
}

/**
 * A party marker that namesParty() does not read as a label: roll-call letters ("CLANCY D N", "(R)", "R-Dist", "D-12")
 * and a vote API's party field ("Party":"R", azleg.gov).
 */
const LETTER = /\b[A-Z][A-Z'-]+ [DRI] (?:Y|N|NV|x)\b|\((?:D|R|I)\)|\b[DR]-[A-Z][a-z]|\b[DR]-\d|"Party"\s*:\s*"[A-Z]/;

/** True when text shown to a reader (a snippet, a research-text line) names a party. */
export const sweepHit = (text: string): boolean => namesParty(text) || LETTER.test(text);

export interface WindowNames { fullName: string; lastName?: string; aliases?: string[] }

/**
 * A passage of a saved page that the verifier will accept as a blank's examined source: 25+ words, no party
 * label (sweepHit), found on the page by matchSnippet, with a publishable span (matchedSpan) whose FIRST
 * occurrence lies within NAME_PROXIMITY_CHARS of the person's name (checkNameProximity, common-surname rule
 * included). Asked of the verifier's own functions, so a window kept here is one the verifier verifies.
 *
 * Windows are tried near each occurrence of the full name, then an alias, then the surname, nearest first.
 * A window need not contain the name: on a congress.gov cosponsor list every window holding the name also holds
 * a party label ("Sen. Warner, Mark R. [D-VA]"), but the action line printed beside the list is party-free and
 * still near the name (Warner, S. 2747, 2026-10-31). null when no window passes.
 */
export function verifiableWindow(pageText: string, names: WindowNames, size = 30): string | null {
  const lastName = names.lastName ?? lastNameOf(names.fullName);
  const verdictNames = { fullName: names.fullName, lastName, aliases: names.aliases };
  const tokens: { word: string; at: number }[] = [];
  for (const m of pageText.matchAll(/\S+/g)) tokens.push({ word: m[0], at: m.index ?? 0 });
  if (tokens.length < 25) return null;
  const lower = pageText.toLowerCase();
  const hits: number[] = [];
  for (const n of [names.fullName, ...aliasesFrom(names.aliases), lastName]) {
    const needle = n.toLowerCase();
    if (!needle) continue;
    for (let i = lower.indexOf(needle); i !== -1; i = lower.indexOf(needle, i + 1)) hits.push(i);
  }
  const tried = new Set<number>();
  // The proximity window is measured in normalized characters; stay well inside it in raw ones.
  const reach = Math.floor(NAME_PROXIMITY_CHARS * 0.8);
  for (const hit of hits) {
    const near = tokens.map((t, k) => ({ k, d: Math.abs(t.at - hit) })).filter((x) => x.d <= reach);
    if (!near.length) continue;
    const at = near.reduce((a, b) => (b.d < a.d ? b : a)).k;
    const starts = near.map((x) => x.k).sort((a, b) => Math.abs(a - (at - 6)) - Math.abs(b - (at - 6)));
    for (const a of starts) {
      if (tried.has(a)) continue;
      tried.add(a);
      const w = tokens.slice(a, a + size).map((t) => t.word).join(' ');
      if (w.split(' ').length < 25 || sweepHit(w)) continue;
      if (matchSnippet(w, pageText).verdict !== 'verified') continue;
      const span = matchedSpan(w, pageText);
      if (!span || span.words < 25 || sweepHit(span.text)) continue;
      const v = checkNameProximity({ ...verdictNames, pageText, matchOffsetInNormalized: span.offset });
      if (v.verdict === 'verified') return w;
    }
  }
  return null;
}

/**
 * The review-row note for a blank approved with no verified source (approve-batch.ts --unverifiable-blank): the
 * date, the ruling, and each cited page with the verifier's verdicts on it, so the record says why no source shows.
 */
export function unverifiableNote(
  evidence: { url: string; snippets?: { verdict?: string }[] }[] | null, today = new Date().toISOString().slice(0, 10),
): string {
  const pages = (evidence ?? []).map((e) => {
    const vs = [...new Set((e.snippets ?? []).map((s) => s.verdict ?? 'no verdict'))];
    return `${e.url} (${vs.join(', ') || 'no snippet'})`;
  });
  return `Blank approved with no verified source (${today}, approve-batch --unverifiable-blank; ruling 2026-10-31 `
    + `"Write a blank for all 26"): ${pages.length ? `no cited page verified: ${pages.join('; ')}` : 'no page could be cited'}.`;
}

/**
 * LegiScan sessions a vote of `year` can sit in: every session whose span (year_start..year_end) covers it, plus a
 * session that starts the next year (the old rule, kept). The old rule matched year_start only, so a vote in the
 * second year of a two-year session (Ohio's 2022, 2024, 2026) found no session at all (oh-01, 2026-11-06).
 */
export function sessionsForYear<T extends { year_start: number | string; year_end?: number | string }>(sessions: T[], year: number): T[] {
  return sessions.filter((s) => {
    const a = Number(s.year_start), b = Number(s.year_end ?? s.year_start);
    return (a <= year && year <= b) || a === year + 1;
  });
}

