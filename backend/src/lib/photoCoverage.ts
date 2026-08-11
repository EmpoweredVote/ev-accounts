/**
 * photoCoverage.ts — the single definition of "this politician has a portrait we can render".
 *
 * WHY THIS EXISTS AS ONE CONSTANT
 *
 * Both coverage surfaces (coverageService, coverageMapService) previously carried their own copy
 * of the predicate, and both counted `photo_origin_url IS NOT NULL`. That is wrong twice over:
 *
 *   • `photo_origin_url` doubles as a research scratchpad. 143 rows hold a literal process note —
 *     `searched:no_results` (97), `explored` (48), `searched:circular_crop_only`,
 *     `local:public/images/HollyHarvey_.jfif` — and 82 more hold an empty string, which is
 *     non-NULL and so counted as coverage. None of these can ever paint a portrait.
 *   • For seated officeholders the old predicate reported 4,353 with photos where only 4,072 can
 *     render one. The 281-row gap is also invisible to any headshot-backlog query keyed on
 *     `IS NOT NULL`: those officials look done and have no portrait.
 *
 * WHAT COUNTS, AND WHAT DELIBERATELY STILL COUNTS
 *
 * A hosted image row, a non-empty `photo_custom_url`, or a non-empty `photo_origin_url` that is
 * at least URL-shaped (`http%`). The `http%` test is intentionally the ONLY filter applied to
 * origin URLs. It is tempting to also require an image file extension — do not. Verified
 * counter-examples, same day, same corpus:
 *
 *   https://www.cityofinglewood.org/ImageRepository/Document?documentID=20637  -> 200 image/jpeg
 *   https://dccouncil.gov/councilmembers/                                      -> 200 text/html
 *
 * A CMS image handler and a roster page are indistinguishable by URL shape, so an
 * extension test would silently condemn working portraits. Distinguishing those two requires
 * fetching each row and reading the content type — a per-row verification project, not a
 * predicate. This constant therefore measures "could render", not "is definitely a face".
 *
 * `p` must be the alias bound to essentials.politicians and `img` the alias bound to a
 * LEFT JOIN on essentials.politician_images.
 */
export const HAS_RENDERABLE_PHOTO_SQL = `(
     img.politician_id IS NOT NULL
  OR btrim(coalesce(p.photo_custom_url, '')) <> ''
  OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%')
)`;

/**
 * The same rule in TypeScript, for callers holding rows rather than composing SQL.
 * Kept beside the SQL so the two cannot drift apart unnoticed.
 */
export function hasRenderablePhoto(row: {
  photo_custom_url?: string | null;
  photo_origin_url?: string | null;
  images?: unknown[] | null;
}): boolean {
  if (Array.isArray(row.images) && row.images.length > 0) return true;
  if ((row.photo_custom_url ?? '').trim() !== '') return true;
  const origin = (row.photo_origin_url ?? '').trim();
  return origin !== '' && origin.startsWith('http');
}
