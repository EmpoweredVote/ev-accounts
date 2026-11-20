/**
 * Every decision the county banner review page makes, as pure functions.
 *
 * The page itself stays thin: it renders what these return. That follows this app's own
 * pattern — researchReviewGrouping.ts, researchReviewApproval.ts, coverageGridCell.ts — and it
 * is why the behaviour below can be pinned by tests in an app whose vitest environment is
 * 'node' and which has no component-rendering setup.
 *
 * 🔴 TWO OF THESE EXIST BECAUSE OF SPECIFIC PAST FAILURES.
 *   - `emptyKind` — a county with no options must say WHICH kind of zero it is. Never swept,
 *     swept with categories lost to errors, a category title that matched nothing, and
 *     genuinely no usable photograph are four different findings, and only one of them means
 *     "this county has nothing". Flattening them publishes "I looked and there was nothing"
 *     over a hole in the search.
 *   - `saveStampText` — on 2026-11-19 a crop editor's saves failed in silence and the page
 *     looked correct the whole time. "Saving..." must never read as "Saved", and a failure
 *     must carry its reason.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */

export interface CandidateRow {
  commonsTitle: string;
  rankPosition: number;
  frameUrl: string;
  sourcePageUrl: string;
  width: number;
  height: number;
  licence: string;
  author: string;
  locatedBy: 'geometry' | 'caption';
  captionText: string | null;
  captionSourceUrl: string | null;
  confirmingSourceUrl: string | null;
  placeListAvailable: boolean | null;
}

export interface CountyReviewRow {
  geoid: string;
  stateUsps: string;
  countyName: string;
  status: 'pending' | 'keep' | 'needs_another_look';
  chosenTitle: string | null;
  verticalAnchor: number | null;
  focus: string | null;
  captionSighted: boolean;
  swept: boolean;
  filesSwept: number;
  categoriesFound: number;
  categoryErrors: number;
  geometryCandidates: number;
  captionCandidates: number;
  rejected: Record<string, number>;
  decidedAt: string | null;
  decidedBy: string | null;
  candidates: CandidateRow[];
}

export type EmptyKind =
  | 'not_swept' | 'sweep_failed' | 'no_categories' | 'no_usable_photograph';

const REJECT_LABELS: Record<string, string> = {
  too_small: 'too small',
  licence_absent: 'no licence published',
  licence_non_free: 'a licence we may not use',
  licence_unreadable: 'a licence we could not classify',
  author_absent: 'no author to credit',
};

/** Why this county shows no options — or null when it shows some. */
export function emptyKind(row: CountyReviewRow): { kind: EmptyKind; text: string } | null {
  if (row.candidates.length > 0) return null;

  if (row.categoryErrors > 0) {
    const n = row.categoryErrors;
    return {
      kind: 'sweep_failed',
      text: `The sweep lost ${n} categor${n === 1 ? 'y' : 'ies'} to errors, so this county has NOT been fully searched. Sweep it again before reading anything into the result.`,
    };
  }
  if (!row.swept) {
    return {
      kind: 'not_swept',
      text: 'This county has not been swept yet. Nobody has looked.',
    };
  }
  if (row.categoriesFound === 0) {
    return {
      kind: 'no_categories',
      text: 'The sweep found no Commons category for this county at all, which usually means the category is named differently rather than that nothing exists.',
    };
  }

  const worst = Object.entries(row.rejected).sort((a, b) => b[1] - a[1])[0];
  const because = worst && worst[1] > 0
    ? ` Most were rejected as ${REJECT_LABELS[worst[0]] ?? worst[0]}.`
    : '';
  return {
    kind: 'no_usable_photograph',
    text: `Swept ${row.filesSwept} file${row.filesSwept === 1 ? '' : 's'} and none is usable as a banner.${because}`,
  };
}

/**
 * Why a keep cannot be recorded yet, or null when it can.
 *
 * These mirror the service's refusals so the operator learns before clicking rather than
 * after. The service still checks: the page is not the only caller, and a disabled button is
 * a convenience, never a gate.
 */
export function keepBlocker(
  row: CountyReviewRow, selectedTitle: string | null, captionSighted: boolean,
): string | null {
  if (!selectedTitle) return 'Choose one of the options first.';
  const chosen = row.candidates.find((c) => c.commonsTitle === selectedTitle);
  if (!chosen) return 'That is not an option for this county any more. Reload the state.';
  if (row.focus === null || row.verticalAnchor === null) {
    return 'Set the crop first — move both sliders, or accept the defaults by nudging them.';
  }
  if (chosen.locatedBy === 'caption' && !captionSighted) {
    return 'This option was placed by its caption, not by coordinates. Look at it and confirm it is the place.';
  }
  return null;
}

/** The page-level line, shown from load. `null` means the probe has not answered yet. */
export function savingLineText(health: { writable: boolean } | null): string {
  if (health === null) return 'Checking whether saving is switched on…';
  return health.writable
    ? 'Saving is on. Every decision is written to the database as you make it.'
    : '🔴 SAVING IS OFF — decisions you make here will NOT be saved. Stop and fix this before reviewing anything.';
}

export type SaveState =
  | { kind: 'none' }
  | { kind: 'saving' }
  | { kind: 'saved'; decidedAt: string }
  | { kind: 'failed'; reason: string };

/** The per-county stamp: saved with a time, not saved with a reason, or neither. */
export function saveStampText(state: SaveState): string {
  switch (state.kind) {
    case 'saved':
      return `Saved ${state.decidedAt.replace('T', ' ').replace(/\.\d+Z$/, 'Z')}`;
    case 'failed':
      return `🔴 NOT SAVED — ${state.reason}`;
    case 'saving':
      return 'Saving…';
    default:
      return 'Not decided yet';
  }
}

/** 'ok' | 'missing' (the importer stored none) | 'broken' (the browser could not load it). */
export function frameStatus(c: CandidateRow, failed: Set<string>): 'ok' | 'missing' | 'broken' {
  if (!c.frameUrl) return 'missing';
  return failed.has(c.frameUrl) ? 'broken' : 'ok';
}

/**
 * The credit as a person can read it.
 *
 * 🔴 Commons' `Artist` field is HTML, and plan 1 stores it verbatim — correctly, because the
 * stored value is the evidence. Measured 2026-11-20 on Kent County's top option, the stored
 * author is:
 *     <div class="fn value">\n<a rel="nofollow" class="external text" href="...">Charles Skip Martin<
 * — tags, and truncated mid-anchor. Plan 1 deferred this as a credit-line concern for plan 3;
 * it stopped being deferrable the moment a review page displayed the field to a person.
 *
 * This strips tags FOR DISPLAY only. The stored value is untouched: plan 3 owns what the
 * published credit line says, and it must build that from the evidence, not from this.
 */
export function creditLine(author: string): string {
  const text = author
    .replace(/<[^>]*>/g, ' ')   // whole tags
    .replace(/<[^>]*$/, ' ')    // a tag the field was truncated inside
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim();
  return text || 'author unreadable — do not ship this one';
}
