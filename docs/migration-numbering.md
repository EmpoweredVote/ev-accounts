# Migration Numbering — Team Note (duplicate numbers + going-forward convention)

**Status:** informational / decision needed · **Authored:** 2026-06-18 · **Owner:** TBD

## TL;DR

`backend/migrations/` has **29 duplicate migration numbers** in committed history — different
`.sql` files sharing the same numeric prefix (e.g. `365_meeting_topics.sql` **and**
`365_warren_stances.sql`). This is **not a production problem today**, but it makes the numeric
prefix unreliable as an ordering/identity key and it will keep happening unless we change how
numbers are assigned.

- **No prod impact.** Migration numbers are **not tracked in the database** — there is no
  `schema_migrations` table and no number-ordered runner. Each migration is applied once, ad hoc,
  via a one-shot script (`backend/scripts/_apply-migration-NNN.ts`) that just reads the `.sql` and
  runs `pool.query(sql)`. The number is a *filename label for humans*, nothing more. So duplicate
  numbers cannot double-apply or corrupt anything.
- **Why it matters anyway.** "Apply migrations in number order" is ambiguous when two files share
  a number; tooling/scripts that key off the number can grab the wrong file; and it's confusing in
  review and `git log`.
- **Do NOT retroactively renumber the 29 below.** They're already applied to prod and committed to
  shared history; renaming them churns history for zero functional gain. Leave them.
- **New migrations start at `797`.** Current high-water mark is `796`.

## Root cause

The duplicates are almost entirely **one schema/feature migration + one data migration at the same
number**. Two parallel work streams — the platform/schema stream and the stance-research/data stream
— each independently picked "the next free number" off `main` at a time when the other stream's file
of that number wasn't yet committed (or lived only on a local branch / uncommitted working tree).
The recent v2.5–v2.15 stance backlog (committed 2026-06-18) surfaced and resolved 18 of these against
infrastructure migrations; the 29 below are the ones that remain *within* already-committed history.

## The 29 duplicate numbers

(Each row = files that share a numeric prefix. Pattern: usually a schema migration + a data/stance migration.)

| # | Files sharing this number |
|---|---|
| `047` | 047_add_city_council_district_columns.sql, 047_category_actual_amount.sql, 047_role_scope_migration.sql |
| `049` | 049_compass_contributor_schema.sql, 049_fix_marte_candidate.sql |
| `059` | 059_current_level_default.sql, 059_topic_scoping_foundation.sql |
| `060` | 060_chambers_slug.sql, 060_drop_home_address.sql |
| `063` | 063_abortion_local_tier_flag.sql, 063_fix_resolve_user_jurisdiction_city_council_ordering.sql |
| `070` | 070_discovery_tables.sql, 070_quotes_deidentified_text.sql |
| `116` | 116_district_type_state_board.sql, 116_la_county_durazo_stances.sql |
| `152` | 152_ma_state_house_officials.sql, 152_politician_accent_aliases_and_stub_cleanup.sql |
| `162` | 162_ma_2026_elections_foundation.sql, 162_ma_pending_stances.sql |
| `163` | 163_cambridge_council_topoff.sql, 163_ma_2026_key_races.sql |
| `167` | 167_cambridge_offices_district_id.sql, 167_la_council_votes.sql |
| `178` | 178_council_file_details.sql, 178_portland_council_incumbents.sql |
| `190` | 190_ca_state_executives.sql, 190_politician_sources_source_type.sql |
| `191` | 191_essentials_politicians_external_id_unique.sql, 191_politician_sources_source_type.sql |
| `192` | 192_ca_exec_dedup.sql, 192_essentials_politicians_is_manual_override.sql |
| `193` | 193_ca_federal_officials.sql, 193_compass_topic_roles_missing_scopes.sql |
| `194` | 194_ca_state_senators.sql, 194_population_year.sql, 194_treasury_municipalities_geo_id.sql |
| `207` | 207_sd_government_structure.sql, 207_us_senate_candidate_stances_batch3.sql |
| `210` | 210_appointed_senator_gapfill_stances.sql, 210_fremont_government_structure.sql |
| `211` | 211_fremont_officials.sql, 211_politicians_created_at.sql |
| `219` | 219_fremont_officials_stances.sql, 219_sacramento_government_structure.sql, 219_sj_headshots.sql |
| `230` | 230_portland_government_structure.sql, 230_source_verifications.sql |
| `231` | 231_portland_officials.sql, 231_stance_research_verification.sql |
| `244` | 244_multnomah_county_government.sql, 244_sd_stances.sql |
| `253` | 253_drop_int_overload_upsert_compass_answer.sql, 253_fix_ca_legislature_orphan_context_rows.sql |
| `267` | 267_allen_mayor_office_fix.sql, 267_ut_2026_primary.sql |
| `276` | 276_readrank_deid_index.sql, 276_stmarys_county_government.sql |
| `293` | 293_la_wave1_gap_fill_preflight.sql, 293_readrank_selected_quotes.sql |
| `365` | 365_meeting_topics.sql, 365_warren_stances.sql |

28 are below `#322` (older history); `365` is from phase 111. None are in the freshly-backfilled
v2.5–v2.15 range — that range was de-collided on commit (renumbered to `778`–`796`).

## Recommendation

Two options; **Option A is recommended.**

### Option A — switch new migrations to timestamp prefixes (robust)
Numbers collide because two branches pick the same "next integer." Timestamps don't:
`20260618_1430_warren_stances.sql`. Collision-free by construction across parallel branches, no
coordination needed. Keep the existing integer-numbered files as-is (history); apply the new scheme
to everything from here. One-line note in `backend/migrations/README` documenting the cutover.

### Option B — keep integers, add a "reserve the number" discipline (lighter, fragile)
Before authoring a migration, run a quick check against `main` and **commit a stub immediately** to
claim the number. Works, but depends on everyone fetching first and still races across unpushed
branches — exactly how we got here.

### Either way
- **Start new migrations at `797`** (high-water mark is `796`).
- A real **migration runner with a tracking table** (applied-migrations ledger) would also fix the
  "what order / what's applied" ambiguity, but that's a larger change — separate proposal.

## Quick checks

```bash
# Highest number currently in use (ignore year-in-name false hits):
git ls-files backend/migrations | sed -E 's#.*/([0-9]+)_.*#\1#' | grep -E '^[0-9]+$' | awk '$1<1000' | sort -n | tail -1

# List any duplicate numbers:
git ls-files backend/migrations | grep -oE '/[0-9]+_' | tr -d '/_' | sort | uniq -d
```
