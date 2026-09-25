/**
 * reliability — Krippendorff's alpha (nominal, missing data allowed), the Wilson lower bound, the
 * severe-error rule and the stratum certification rule for the stance coders.
 * Spec: docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md §3.
 *
 * Nominal, not ordinal: the five chairs are distinct stances, not a scale (CLAUDE.md), and BLANK is
 * a sixth category. Pure. 🔴 reliability.test.ts reproduces Krippendorff's published examples — do
 * not trust any stratum figure while that test is red.
 */
export type Category = string;
/** One unit (one row) = the value each coder gave it; null = no valid value from that coder. */
export type Unit = ReadonlyArray<Category | null>;

export interface AlphaResult {
  /** null = undefined: fewer than 2 pairable values, or no expected disagreement (one category). */
  alpha: number | null;
  pairableValues: number;
  units: number;
}

const SEP = '\u0000';

export function alphaNominal(units: ReadonlyArray<Unit>): AlphaResult {
  const o = new Map<string, number>(); // coincidence matrix o_ck, keyed `${c}${SEP}${k}`
  let n = 0;
  let used = 0;
  for (const u of units) {
    const vals = u.filter((v): v is Category => v !== null);
    const m = vals.length;
    if (m < 2) continue;
    used++;
    n += m;
    const cnt = new Map<Category, number>();
    for (const v of vals) cnt.set(v, (cnt.get(v) ?? 0) + 1);
    for (const [c, nc] of cnt) {
      for (const [k, nk] of cnt) {
        const pairs = nc * (c === k ? nk - 1 : nk);
        if (pairs === 0) continue;
        const key = `${c}${SEP}${k}`;
        o.set(key, (o.get(key) ?? 0) + pairs / (m - 1));
      }
    }
  }
  if (n < 2) return { alpha: null, pairableValues: n, units: used };
  const marg = new Map<Category, number>();
  let dO = 0;
  for (const [key, v] of o) {
    const [c, k] = key.split(SEP);
    marg.set(c, (marg.get(c) ?? 0) + v);
    if (c !== k) dO += v;
  }
  let dE = 0;
  for (const [c, a] of marg) for (const [k, b] of marg) if (c !== k) dE += a * b;
  dE /= n - 1;
  if (dE === 0) return { alpha: null, pairableValues: n, units: used };
  return { alpha: 1 - dO / dE, pairableValues: n, units: used };
}

export const Z95 = 1.959963984540054;

export function wilsonLowerBound(successes: number, n: number, z = Z95): number {
  if (n <= 0) return 0;
  const p = successes / n;
  const z2 = z * z;
  return (p + z2 / (2 * n) - z * Math.sqrt((p * (1 - p)) / n + z2 / (4 * n * n))) / (1 + z2 / n);
}

/**
 * Spec §3.1 M4. Severe = a seated chair where gold is BLANK, or a chair on the other side of the
 * ladder (1–2 vs 4–5; rung 3 is on neither side). On an off-axis topic "side" means nothing, so
 * every wrong chair is severe. A machine BLANK never publishes, so it is never severe.
 */
export function isSevereError(machine: number | null, gold: number | null, offAxis: boolean): boolean {
  if (machine === gold) return false;
  if (machine === null) return false;
  if (gold === null) return true;
  if (offAxis) return true;
  const side = (v: number) => (v <= 2 ? -1 : v >= 4 ? 1 : 0);
  return side(machine) !== 0 && side(gold) !== 0 && side(machine) !== side(gold);
}

export const CERT = { MIN_GOLD: 50, MIN_ALPHA: 0.8, MIN_WILSON_LOW: 0.9 } as const;

export interface StratumMeasures {
  /** Blind/audit gold items in the stratum, excluding codebook examples. */
  goldN: number;
  /** M1: α among the three coders. */
  m1: number | null;
  /** M2: α between coder consensus and blind gold. */
  m2: number | null;
  /** M3 inputs: unanimous rows whose chair equals gold, out of unanimous rows with gold. */
  unanimousCorrect: number;
  unanimousTotal: number;
  /** M4: severe errors among unanimous rows. */
  severe: number;
}

export function certify(m: StratumMeasures): { certified: boolean; m3WilsonLow: number; reasons: string[] } {
  const reasons: string[] = [];
  const m3 = wilsonLowerBound(m.unanimousCorrect, m.unanimousTotal);
  if (m.goldN < CERT.MIN_GOLD) reasons.push(`gold-n ${m.goldN} < ${CERT.MIN_GOLD}`);
  if (m.m1 === null) reasons.push('m1 undefined');
  else if (m.m1 < CERT.MIN_ALPHA) reasons.push(`m1 ${m.m1.toFixed(3)} < ${CERT.MIN_ALPHA.toFixed(2)}`);
  if (m.m2 === null) reasons.push('m2 undefined');
  else if (m.m2 < CERT.MIN_ALPHA) reasons.push(`m2 ${m.m2.toFixed(3)} < ${CERT.MIN_ALPHA.toFixed(2)}`);
  if (m3 < CERT.MIN_WILSON_LOW) reasons.push(`m3 wilson-low ${m3.toFixed(3)} < ${CERT.MIN_WILSON_LOW.toFixed(2)}`);
  if (m.severe > 0) reasons.push(`m4 severe ${m.severe} > 0`);
  return { certified: reasons.length === 0, m3WilsonLow: m3, reasons };
}

export const chairCategory = (value: number | null): Category => (value === null ? 'BLANK' : String(value));
