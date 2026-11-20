/**
 * Stage 4 -- RANKING. Narrow to what the operator looks at first.
 *
 * 🔴 THIS IS THE COMPONENT THE NEBRASKA RUN MEASURED WRONG 47% OF THE TIME. Where the
 * operator had a real choice between two or more candidates, they took the top-ranked
 * option in 29 of 55 counties and moved to a lower one in 26. So this ranking is
 * written down, tested and reproducible rather than implicit -- it NARROWS, it does not
 * choose, and the operator overriding it is the normal case, not a failure.
 *
 * 🔴 RANK ONLY ON MEASURABLE PROPERTIES. Not on category name: a category name is not a
 * jurisdiction and it is not a judgement about quality either.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import type { CandidateFile } from './types.js';

/** How many options the operator sees at once. The rest stay retrievable. */
export const PAGE_SIZE = 5;

/** The shipped asset's aspect ratio: 1700 / 540. */
const ASSET_RATIO = 1700 / 540;

/**
 * Vertical slack: how much taller than the asset's crop this source is.
 *
 * 0 means the source is already at or wider than 3.148:1, so cutting a 1700x540 asset
 * from it uses the full height and the operator can move NEITHER crop lever. Slack is
 * what makes a candidate adjustable, so it ranks first.
 */
function slack(f: CandidateFile): number {
  if (f.width <= 0 || f.height <= 0) return 0;
  const neededHeight = f.width / ASSET_RATIO;
  return Math.max(0, (f.height - neededHeight) / f.height);
}

/**
 * Most adjustable first, then largest, then title.
 *
 * The title tiebreak makes this a total order: two runs over the same candidates give
 * the same page, so what the operator saw yesterday is what they see today.
 */
/**
 * Enough slack to move the levers meaningfully. Below this the operator can barely
 * reframe; ABOVE it, more slack is not better -- a 1700x5000 vertical strip has the
 * most slack of anything and makes a poor banner. Slack is a gate, not a score.
 */
export const MIN_SLACK = 0.12;

/** How far a source's shape is from the asset's own 3.148:1. */
function shapeDistance(f: CandidateFile): number {
  if (f.width <= 0 || f.height <= 0) return Number.POSITIVE_INFINITY;
  return Math.abs(Math.log((f.width / f.height) / ASSET_RATIO));
}

export function rankCandidates(files: CandidateFile[]): CandidateFile[] {
  return [...files].sort((a, b) => {
    // 1. Can the operator reframe it at all?
    const adequate = Number(slack(b) >= MIN_SLACK) - Number(slack(a) >= MIN_SLACK);
    if (adequate !== 0) return adequate;
    // 2. Among those, the closest to the banner's own shape -- which puts an ordinary
    //    landscape above an ordinary portrait instead of below it.
    const d = shapeDistance(a) - shapeDistance(b);
    if (Math.abs(d) > 1e-9) return d;
    const size = Math.max(b.width, b.height) - Math.max(a.width, a.height);
    if (size !== 0) return size;
    return a.title.localeCompare(b.title);
  });
}
