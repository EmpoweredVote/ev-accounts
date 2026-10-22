/**
 * ladderLint.ts — the pilot T6 lint on rung text (season topic prep).
 *
 * Copied from the pilot's t6_lint.py (.planning/research/s3-pilot-equity-programs/stage3/): degree
 * words, "and", "at most", "without", "only", "while", and every/any/all, as whole words, case
 * insensitive. Raw hits are reported. Some are fine — an "and" inside one object list, an "every" that
 * is itself the object — and the runner accepts those with a reason written beside them, as the pilots
 * did. Pure.
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
