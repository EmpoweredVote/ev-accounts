/**
 * photoCredit.ts — the credit a portrait owes, in the shape a reader can see.
 *
 * WHY THIS EXISTS: THE CREDIT WAS RECORDED AND NEVER DISPLAYED
 *
 * `CC_0326` spent a migration filling in `politicians.photo_origin_url` so that Creative Commons
 * portraits would name the page stating their terms, and `CC_0328`–`CC_0333` corrected or replaced
 * every portrait whose licence could not be supported. None of that reached a voter, because
 * nothing on the read path ever served it.
 *
 * ⚠ AND THE OBVIOUS FIX IS THE WRONG ONE. The API field called `photo_origin_url` is NOT the
 * origin. Thirteen queries across five services select
 *
 *     COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url
 *
 * so the field is "the image to display", with the true origin as a last-resort fallback for
 * people whose photograph was never mirrored. `PoliticianProfile` and both compass cards render it
 * as an `<img src>`. "Un-masking" that alias to expose provenance would blank those portraits.
 * So the credit travels as its OWN field and the alias is left exactly as it is.
 *
 * WHAT A CREDIT CAN HONESTLY SAY
 *
 * `essentials.politician_images` has no author column — only `photo_license` — so we cannot print
 * "Photo by X". What we can do is name the licence and LINK the page that states it and names the
 * author, which is what the Commons file page does. Hence `source_url`, never an invented byline.
 *
 * 🔴 A CDN SELF-REFERENCE IS NOT PROVENANCE. Some rows record our own storage bucket as their
 * origin. Linking that would present our copy as its own source, so those are emitted as ''.
 *
 * ⚠ `photo_license` IS NOT A CONTROLLED VOCABULARY. Most of it is free prose — provenance
 * paragraphs up to 250 words, recording that a publisher states no policy at all. A paragraph is
 * not a caption, so `label` is set only for the recognised short tokens (`CC_0328` fixed their
 * spelling) and is '' otherwise. The raw value still travels in `license` for a reader who wants
 * the whole story; deciding how to surface it is the render layer's business, not this module's.
 *
 * WHY A CORRELATED SUB-SELECT AND NOT A JOIN: the same reason as photoRestriction.ts — it is
 * identical at every call site and cannot collide with a caller's aliases. `p` must be the alias
 * bound to essentials.politicians.
 */

/** The canonical licence tokens, as `CC_0328` normalised them, mapped to a display label. */
const LABELLED_TOKENS: ReadonlyArray<readonly [string, string]> = [
  ['cc0', 'CC0'],
  ['cc_by_2.0', 'CC BY 2.0'],
  ['cc_by_3.0', 'CC BY 3.0'],
  ['cc_by_4.0', 'CC BY 4.0'],
  ['cc_by-sa_2.0', 'CC BY-SA 2.0'],
  ['cc_by-sa_3.0', 'CC BY-SA 3.0'],
  ['cc_by-sa_4.0', 'CC BY-SA 4.0'],
  ['cc_by-sa', 'CC BY-SA (version not recorded)'],
  ['public_domain', 'Public domain'],
  ['us_government_work', 'U.S. Government work'],
  ['press_use', 'Press use'],
  ['candidate_submitted', 'Candidate-submitted'],
];

const LABEL_CASE_SQL = LABELLED_TOKENS
  .map(([token, label]) => `             WHEN pi.photo_license = '${token}' THEN '${label.replace(/'/g, "''")}'`)
  .join('\n');

/**
 * Yields a jsonb credit for the person's default portrait, or NULL when they have no portrait or
 * nothing is recorded about it. Shape: {@link PhotoCredit}.
 */
export const PHOTO_CREDIT_SELECT_SQL = `(
    SELECT jsonb_build_object(
             'license', pi.photo_license,
             'label', CASE
${LABEL_CASE_SQL}
                        ELSE ''
                      END,
             -- 🔴 Our own bucket is not a source. Emitting it would present our copy of a
             --    photograph as the page that licensed it.
             'source_url', CASE
                             WHEN coalesce(p.photo_origin_url, '') = '' THEN ''
                             WHEN p.photo_origin_url ~* 'kxsdzaojfaibhuzmclfq|(^|\\.)supabase\\.co/' THEN ''
                             ELSE p.photo_origin_url
                           END,
             -- Every Creative Commons licence except CC0 requires a credit. CC0 is a public-domain
             -- dedication and requires none, so the token must not match here.
             'attribution_required', (pi.photo_license ~* '^\\s*cc[-_ ]?by')
           )
      FROM essentials.politician_images pi
     WHERE pi.politician_id = p.id
       AND pi.type = 'default'
       AND btrim(coalesce(pi.photo_license, '')) <> ''
     LIMIT 1
  ) AS photo_credit`;

/** The shape the API serves alongside a portrait. Null when there is nothing to credit. */
export interface PhotoCredit {
  /** The stored value, verbatim. A short licence token, or a free-text provenance note. */
  license: string;
  /** Short display label for a recognised token, e.g. 'CC BY-SA 4.0'. '' for free-text notes. */
  label: string;
  /** Page that states the terms and names the author. '' when we hold none worth linking. */
  source_url: string;
  /** True when the licence obliges us to credit. Any CC BY…; never CC0. */
  attribution_required: boolean;
}

/**
 * True when this row owes a credit that we cannot currently give — a CC licence requiring
 * attribution with no source to point at. 43 rows were in this state when the field was added;
 * they are a research backlog, not a render bug, and showing the licence with no link is still
 * more honest than showing nothing.
 */
export function creditIsIncomplete(credit: PhotoCredit | null | undefined): boolean {
  return !!credit && credit.attribution_required && !credit.source_url;
}
