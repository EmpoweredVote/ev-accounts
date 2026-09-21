/**
 * The OCD-ID suffix for a state legislative district, derived from its TIGER district code.
 *
 * This exists because the rule has exactly one correct definition and it was previously inline
 * in `scripts/load-state-tiger-boundaries.ts` as `parseInt(districtNum, 10)` — which is right for
 * a state whose district codes are plain numbers and silently wrong for one whose codes carry a
 * letter. It lives in `src/lib/` rather than `scripts/lib/` on purpose: `backend/tsconfig.json`
 * sets `include: ['src*']` and lint is `eslint src`, so nothing under `scripts/` is typechecked
 * or linted at all. A rule this easy to get wrong belongs where CI can see it.
 *
 * ── THE DEFECT THIS REPLACES ─────────────────────────────────────────────────────────────────
 *
 * 🔴 `parseInt('08A', 10)` is `8`. Minnesota's TIGER SLDLST codes are '01A'..'67B', so 08A and
 *    08B both produced `ocd-division/country:us/state:mn/sldl:8`. Measured against the real
 *    TIGER 2024 FIPS 27 file on 2026-09-12: **134 House districts collapse to 67 distinct
 *    OCD-IDs — every one of the 67 A/B pairs colliding.**
 *
 * 🔴 NOTHING CAUGHT IT, AND NOTHING WOULD HAVE. `essentials.districts` carries no unique
 *    constraint on `ocd_id` (only `id` and `external_id`), so duplicates write silently. Address
 *    search resolves on `geo_id`, never `ocd_id` — `ocd_id` ROLLS UP, `geo_id` LOOKS UP — so
 *    `check:reachability` and every identity anchor stay green either way. `geo_id` itself was
 *    never affected: it comes from the raw TIGER `GEOID` ('2708A'), which keeps the letter.
 *    What it does break is `coverageMapService.ts`, which keys its aggregation on `ocd_id`, so a
 *    collided pair reports as one district with both halves' stats merged.
 *
 * 🔴 IT IS ALREADY IN PRODUCTION. Maryland's delegate districts are 1A/1B/1C: 71 `sldl` rows,
 *    47 distinct `ocd_id`s, 24 sharing one. North Dakota and South Dakota have the same shape
 *    and are not loaded yet. ✅ **Maryland was repaired on 2026-09-16 by
 *    `migrations/CC_0113_md_ocd_suffix_repair.sql`** — and the real scope was **84 rows across TWO
 *    tables**: 42 in `essentials.districts` and 42 in `essentials.geofence_boundaries`, which this
 *    note never mentioned. 24 is `rows − distinct` in one table, a count of the collapse rather
 *    than of the rows carrying it.
 *
 * ── WHY THIS IS SAFE FOR EVERY STATE ALREADY LOADED ──────────────────────────────────────────
 *
 * ⚠ Measured 2026-09-12 across production: all **2,400** existing STATE_UPPER/STATE_LOWER
 *   `ocd_id`s in 18 states have a plain-digit suffix, and **40** Massachusetts rows have the
 *   literal suffix `'NaN'` (its Senate districts are named — "First Essex" — not numbered).
 *   Both groups come out byte-identical here: the numeric path is the same leading-zero strip
 *   `parseInt` performed, and a non-numeric code still returns the string `'NaN'`.
 *
 * ⚠ THE 'NaN' RESULT IS PRESERVED DELIBERATELY, NOT ENDORSED. `…/sldu:NaN` is a bad OCD-ID and
 *   Massachusetts has 40 of them. Changing it here would silently re-key 40 live rows as a side
 *   effect of a Minnesota fix. It is its own decision, with its own migration.
 *
 * @param districtNum the raw TIGER district code — SLDUST or SLDLST, e.g. '043', '008', '08A'
 * @returns the OCD-ID suffix: leading zeros stripped, any alpha suffix kept and uppercased
 */
export function ocdDistrictSuffix(districtNum: string | null | undefined): string {
  const raw = (districtNum ?? '').trim();
  if (raw === '') return '0';

  // Leading zeros stripped, trailing letters kept. The letter is what parseInt threw away.
  const m = /^0*(\d+)([A-Za-z]*)$/.exec(raw);
  if (m) {
    const digits = m[1] === '' ? '0' : m[1];
    return `${digits}${m[2].toUpperCase()}`;
  }

  // Not a district code at all. Fall through to exactly what the old rule produced, so no
  // existing row changes — see the 'NaN' note above.
  return String(parseInt(raw, 10));
}
