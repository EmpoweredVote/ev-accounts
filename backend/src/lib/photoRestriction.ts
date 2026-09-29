/**
 * photoRestriction.ts — the single definition of "a portrait of this person exists and its
 * publisher has reserved it, so we do not show one".
 *
 * WHY THIS IS NOT A PHOTO URL
 *
 * The obvious implementation of "show a placeholder" is to park a placeholder asset in
 * `photo_custom_url`. That is wrong, and the reason is in `photoCoverage.ts`: a non-empty
 * `photo_custom_url` IS the definition of coverage. Filling it would report every restricted
 * person as having a portrait, drop them out of the headshot backlog because they look done,
 * and inflate every coverage rollup — the same defect that already leaves 86 politicians
 * rendering a roster PAGE URL as their face.
 *
 * So the placeholder is drawn by the render layer, and the database carries only the FACT:
 *
 *     photo, no restriction    -> covered. Renders the portrait.
 *     no photo, no restriction -> TO DO. Renders initials. Stays in the headshot backlog.
 *     no photo + restriction   -> BLOCKED. Renders the placeholder and the publisher's notice.
 *                                Not covered, and not a backlog item: looking again cannot help,
 *                                because the portrait was found and may not be used.
 *
 * ⚠ RESTRICTED IS NOT COVERED. `HAS_RENDERABLE_PHOTO_SQL` still reports these people as having
 * no portrait, because they have none. Only the BACKLOG changes. Do not "fix" a coverage number
 * by counting restricted people — that would report a portrait to a funder that no voter sees.
 *
 * WHY A CORRELATED SUB-SELECT AND NOT A JOIN
 *
 * Ten queries across four services build the politician payload, each with its own FROM/JOIN
 * shape and its own aliases. A LEFT JOIN would have to be threaded into all ten by hand, and an
 * alias collision in any one of them is a silent wrong answer. This sub-select is correlated on
 * `p` alone, so it is identical in every site and cannot collide. `photo_restrictions` holds one
 * row per publisher — the planner reads it once.
 *
 * `p` must be the alias bound to essentials.politicians. Yields NULL when the person is
 * unrestricted, which is the overwhelming majority.
 */
export const PHOTO_RESTRICTION_SELECT_SQL = `(
    SELECT jsonb_build_object(
             'code',      pr.code,
             'authority', pr.authority,
             'label',     pr.card_label,
             'headline',  pr.notice_headline,
             'body',      pr.notice_body
           )
      FROM essentials.photo_restrictions pr
     WHERE pr.code = p.photo_restriction_code
  ) AS photo_restriction`;

/**
 * The backlog predicate. A person with no portrait is work TO DO only when nothing blocks them.
 *
 * 🔴 This is the ONLY thing the restriction removes. Pair it with `HAS_RENDERABLE_PHOTO_SQL`,
 * never in place of it: "has no photo" and "is worth searching for" stopped being the same
 * question the moment a publisher said no.
 */
export const PHOTO_SEARCH_IS_BLOCKED_SQL = `(p.photo_restriction_code IS NOT NULL)`;

/** The shape the API serves for a restricted person. Null for everyone else. */
export interface PhotoRestriction {
  /** Stable key of the publisher, e.g. 'sd-legislature-2026'. */
  code: string;
  /** Who reserved the portraits, e.g. 'South Dakota Legislative Research Council'. */
  authority: string;
  /** One line, for a result card. The card has room for one and no more. */
  label: string;
  /** Heading of the notice shown above the affected body. */
  headline: string;
  /** Voter-facing explanation. Paragraphs separated by a blank line. */
  body: string;
}

/** The same rule in TypeScript, for callers holding rows rather than composing SQL. */
export function isPhotoRestricted(row: {
  photo_restriction?: PhotoRestriction | null;
  photo_restriction_code?: string | null;
}): boolean {
  return !!row.photo_restriction || !!row.photo_restriction_code;
}
