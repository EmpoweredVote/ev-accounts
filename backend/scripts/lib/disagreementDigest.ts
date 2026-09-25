/**
 * disagreementDigest — improvement loop 1 (spec sec10.1). Per codebook variable: how many units the
 * coders split on, alpha, and a few examples. Ranked by split RATE, it tells a person which part of
 * the codebook the coders read differently — the input to a proposed codebook edit, which is then
 * measured by replay before it is adopted (sec10.2). It never edits anything itself.
 * Units: a (row, snapshot) passage for V1-V5; a row for the chair. A missing coder is null.
 */
import { alphaNominal, chairCategory, type Unit } from './reliability.js';
import { rowKey, type CoderRow, type Passage } from './coderLabel.js';

export const DIGEST_VARIABLES = ['v1_attribution', 'v2_relevance', 'v3_class', 'v4_shape', 'v5_time', 'v6_chair'] as const;
export type DigestVariable = typeof DIGEST_VARIABLES[number];
const PASSAGE_VARIABLES = DIGEST_VARIABLES.slice(0, 5) as readonly Exclude<DigestVariable, 'v6_chair'>[];
export const MAX_EXAMPLES = 3;

export interface VariableDigest {
  variable: DigestVariable;
  /** Units at least two coders gave a value for. */
  units: number;
  split_units: number;
  alpha: number | null;
  examples: { unit: string; values: (string | null)[] }[];
}

export function buildDisagreementDigest(
  rowsBySlot: ReadonlyMap<number, readonly CoderRow[]>,
  slots: number[] = [1, 2, 3],
): { variables: VariableDigest[]; ranked: DigestVariable[] } {
  const byVar = new Map<DigestVariable, Map<string, (string | null)[]>>(DIGEST_VARIABLES.map((v) => [v, new Map()]));
  const put = (v: DigestVariable, unit: string, idx: number, value: string) => {
    const m = byVar.get(v)!;
    const vals = m.get(unit) ?? slots.map(() => null);
    vals[idx] = value;
    m.set(unit, vals);
  };
  slots.forEach((slot, idx) => {
    for (const r of rowsBySlot.get(slot) ?? []) {
      const key = rowKey(r);
      put('v6_chair', key, idx, chairCategory(r.v6_value));
      for (const p of r.passages) for (const v of PASSAGE_VARIABLES) put(v, `${key}#${p.snapshot_id}`, idx, String(p[v as keyof Passage]));
    }
  });
  const variables: VariableDigest[] = DIGEST_VARIABLES.map((v) => {
    const entries = [...byVar.get(v)!];
    const coded = entries.filter(([, vals]) => vals.filter((x) => x !== null).length >= 2);
    const split = coded.filter(([, vals]) => new Set(vals.filter((x) => x !== null)).size > 1);
    return {
      variable: v,
      units: coded.length,
      split_units: split.length,
      alpha: alphaNominal(entries.map(([, vals]) => vals) as Unit[]).alpha,
      examples: split.slice(0, MAX_EXAMPLES).map(([unit, values]) => ({ unit, values })),
    };
  });
  const rate = (d: VariableDigest) => (d.units ? d.split_units / d.units : 0);
  const ranked = variables
    .filter((d) => d.split_units > 0)
    .sort((a, b) => rate(b) - rate(a) || a.variable.localeCompare(b.variable))
    .map((d) => d.variable);
  return { variables, ranked };
}
