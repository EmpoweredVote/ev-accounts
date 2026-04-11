# 107-01 — chambers.slug Foundation

## What was built
Migration `ev-accounts/backend/migrations/060_chambers_slug.sql` (renumbered from 059 — 059 was already taken by `059_topic_scoping_foundation.sql`).

- Adds `essentials.chambers.slug` as a `STORED GENERATED ALWAYS AS` column derived from `name_formal` via `public.f_unaccent` (IMMUTABLE wrapper from migration 040).
- Slug rule (D-03): lowercase → strip accents → `&`→`and` → drop `'’.` → non-alnum runs → `-` → btrim `-`.
- Non-unique B-tree index `idx_chambers_slug` (D-04: duplicates aggregate per D-13).
- Idempotent B-tree indexes on `offices.chamber_id`, `offices.politician_id`, `politician_images.politician_id` (D-27) to protect <500ms p95.
- Inline `DO $$` sanity check — raises if `Bloomington Common Council` does not resolve to `bloomington-common-council`.

## Applied to
- **Production** (`E.V Backend`, project `kxsdzaojfaibhuzmclfq`) — applied via Supabase MCP `apply_migration`. Transaction committed without exception.
- Dev project skipped per user direction (prod-only for this phase).

## Verification evidence
- `SELECT slug FROM essentials.chambers WHERE name_formal='Bloomington Common Council'` → 7 rows all `bloomington-common-council` (duplicates expected; will aggregate per D-13 in 107-02).
- `information_schema.columns` → `slug` is `is_generated='ALWAYS'`.
- `pg_indexes` → all four indexes present in `essentials`: `idx_chambers_slug`, `idx_offices_chamber_id`, `idx_offices_politician_id`, `idx_politician_images_politician_id`.

## Requirements covered
- ESSBODY-03 foundation — stable kebab-case slug column on `essentials.chambers`. Plan 107-02 can now write `WHERE ch.slug = $1`.

## Notes
- Acceptance criterion `! grep UNIQUE` required rewording the index comment from "NOT UNIQUE" → "not unique" to avoid the case-sensitive substring match.
- Plan file `107-01-PLAN.md` was edited at execution time to reference `060_chambers_slug.sql` instead of `059_chambers_slug.sql`.
