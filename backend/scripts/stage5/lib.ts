/** Pure helpers for the Stage 5 batch tools (scripts/stage5/README.md). */
import { namesParty } from '../../src/lib/partyLabels.js';

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
