/**
 * Honest single-gradient color for the completeness coverage map.
 *
 * Input is the composite completeness score (0..100) for a state or county —
 * empty units already drag it down, so the color reflects how complete the WHOLE
 * jurisdiction is. A gamma curve expands the low end so 4% vs 13% vs 30% are
 * distinguishable sage shades; only ~100% reaches yellow. Untracked geographies
 * (no coverage YAML → null score) render neutral grey, painted by the caller.
 *
 * Antipartisan — sage → purple → yellow, deliberately no red/blue. Tunable.
 */
export const NOT_STARTED = '#e5e7eb'; // gray-200 — untracked / no coverage file
export const GAMMA = 0.55;            // expands the crowded low end
export const KNEE = 0.6;              // t at which the ramp reaches purple

const SAGE = [0xcf, 0xe3, 0xc4];   // low
const PURPLE = [0x7d, 0x5b, 0xa6]; // mid-high (at the knee)
const YELLOW = [0xfe, 0xd1, 0x2e]; // 100% (EV Inform token)

const lerp = (a: number, b: number, t: number) => Math.round(a + (b - a) * t);
const rgb = (c: number[]) => `rgb(${c[0]}, ${c[1]}, ${c[2]})`;

/** score 0..100 → sage→purple→yellow hex; null/undefined → not-started grey. */
export function completenessColor(score: number | null | undefined): string {
  if (score == null) return NOT_STARTED;
  const t = Math.pow(Math.min(1, Math.max(0, score) / 100), GAMMA);
  if (t <= KNEE) {
    const u = t / KNEE;
    return rgb([lerp(SAGE[0], PURPLE[0], u), lerp(SAGE[1], PURPLE[1], u), lerp(SAGE[2], PURPLE[2], u)]);
  }
  const u = (t - KNEE) / (1 - KNEE);
  return rgb([lerp(PURPLE[0], YELLOW[0], u), lerp(PURPLE[1], YELLOW[1], u), lerp(PURPLE[2], YELLOW[2], u)]);
}
