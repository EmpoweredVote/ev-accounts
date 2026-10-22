/**
 * ladderLint.ts — the pilot T6 lint on rung text (season topic prep).
 *
 * Copied from the pilot's t6_lint.py (.planning/research/s3-pilot-equity-programs/stage3/): degree
 * words, "and", "at most", "without", "only", "while", and every/any/all, as whole words, case
 * insensitive. Raw hits are reported. Some are fine — an "and" inside one object list, an "every" that
 * is itself the object — and the runner accepts those with a reason written beside them, as the pilots
 * did. Known false-positive classes (finding #9): a "without" that names who a fallback is for ("voters
 * without one"), an "every <object>" that is the object itself, an "and" inside one object list. "but"
 * and the comma clause were added after the voting-rights run (finding #8). Pure.
 */
export interface LintHit {
  rung: number;
  check: string;
  match: string;
}

export const LINT_CHECKS: Array<{ name: string; re: RegExp }> = [
  { name: 'degree word', re: /\b(more|less|some|significant|strong|modest|reasonable|appropriate|limited|broad(ly)?|small|large|minimal|substantial)\b/gi },
  { name: 'and', re: /\band\b/gi },
  { name: 'at most', re: /\bat most\b/gi },
  { name: 'without', re: /\bwithout\b/gi },
  { name: 'only', re: /\bonly\b/gi },
  { name: 'while', re: /\bwhile\b/gi },
  { name: 'every/any/all', re: /\b(every|any|all)\b/gi },
  // Two clauses joined without "and" (voting-rights Stage 0a, finding #8): "…, but let voters …" and
  // "…, verifying voters by …". The gerund must be followed by a word, so a list item ("programs,
  // training, and staff") is not a hit. Both are L6 checks by hand: compare with the annex's clauses.
  { name: 'but', re: /\bbut\b/gi },
  { name: 'comma clause', re: /,\s+[a-z]+ing\s+(?!and\b|or\b)[a-z]+/gi },
];

/** Raw hits for rung texts given in order (rung 1 first); rung numbers are 1-based. */
export function lintRungs(rungs: string[]): LintHit[] {
  const hits: LintHit[] = [];
  rungs.forEach((text, i) => {
    for (const { name, re } of LINT_CHECKS) {
      for (const m of text.matchAll(re)) hits.push({ rung: i + 1, check: name, match: m[0] });
    }
  });
  return hits;
}
