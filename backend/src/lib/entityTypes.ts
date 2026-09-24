/**
 * Entity types the treasury schema's CHECK constraint permits, and the
 * validator for `?entity_type=`.
 *
 * ⚠⚠ INVARIANT: this set must mirror `municipalities_entity_type_check` in TT
 * migration `20260903000000_pa_borough_entity_type.sql` EXACTLY — not which
 * values happen to have rows today. `special_district`, `school_district`,
 * `conservancy` and `library` are legal in the constraint with zero rows right
 * now; the moment a loader writes one, this set must already accept it or
 * every CSV containing it (e.g. TT's `CITY_TIER_TYPES`) 422s as a whole and a
 * county's children panel goes blank — the PA-borough failure mode (1,202
 * entities silently invisible) reproduced across repos. Add a type here WHEN
 * THAT CONSTRAINT GAINS ONE, not after a loader needs it.
 *
 * ⭐ THAT INVARIANT IS NOW WATCHED, not just written down: `npm run
 * check:entity-types` reads `pg_get_constraintdef` nightly and fails on any
 * difference in either direction. It reads the literal below out of THIS FILE
 * by source, so reshaping the declaration means teaching that reader the new
 * shape (it errors rather than passing when it cannot find it).
 *
 * ⚠ This is a VALIDATION whitelist, not a classification. It says which values
 * are legal shape, never which of them count as a city — that judgement stays
 * in the caller (see CityFilters).
 *
 * ⚠ It lives in its own module, apart from treasuryService, because it is PURE:
 * treasuryService reaches `./db.js`, which `process.exit(1)`s at module load
 * when there is no DATABASE_URL (i.e. in CI). Anything importing the service to
 * get at this whitelist therefore had to mock it and hand-copy the list back in
 * — which is how a third copy of these fourteen values came to exist. A guard
 * with its own copy of the list cannot catch the list being wrong (TT PR #150).
 */
export const KNOWN_ENTITY_TYPES: ReadonlySet<string> = new Set([
  'city', 'county', 'township', 'village', 'borough',
  'nonprofit', 'state', 'municipality', 'special_district',
  'school_district', 'conservancy', 'library', 'town', 'federal',
]);

export function parseEntityTypes(raw: unknown): { values: string[] } | { invalid: string } {
  if (typeof raw !== 'string' || raw.trim() === '') return { values: [] };
  const values = raw.split(',').map((s) => s.trim()).filter((s) => s !== '');
  const invalid = values.find((v) => !KNOWN_ENTITY_TYPES.has(v));
  if (invalid !== undefined) return { invalid };
  return { values };
}
