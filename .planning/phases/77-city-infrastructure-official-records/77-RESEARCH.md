# Phase 77: City Infrastructure + Official Records - Research

**Researched:** 2026-05-23
**Domain:** PostgreSQL data seeding — essentials schema (governments, districts, chambers, politicians, offices)
**Confidence:** HIGH

## Summary

Phase 77 is substantially pre-complete. Three of the four target cities (San Diego, Fremont, Berkeley) have already had their government structure, officials, and headshots applied in migrations 207–215 during prior work sessions. San Jose has its government structure in migration 217 (already written, unapplied). Only San Jose's officials migration (politicians + offices + headshots) remains to be authored and applied.

The primary task for Phase 77 is: (1) apply migration 217 (SJ government structure), (2) write and apply migration 218 (SJ officials — 11 politicians + offices), (3) apply headshots for all 11 SJ officials using the find-headshots skill, and (4) verify all four cities' data passes the CITY-01 through CITY-08 success criteria.

**Critical schema discrepancy:** The REQUIREMENTS.md specifies `district_type = 'CITY_COUNCIL'` for CITY-02. The actual existing migrations for SD, Fremont, Berkeley, and SJ all use `district_type = 'LOCAL'` (for per-district seats) and `LOCAL_EXEC` (for citywide seats). The success criteria query in ROADMAP.md uses `CITY_COUNCIL` — this will return 0 rows against the existing data. The planner must resolve whether to (a) accept the existing `LOCAL` type as meeting intent, or (b) add a new `CITY_COUNCIL` type and re-examine the district rows. Given that 3 cities are already live with `LOCAL`, option (a) is strongly preferred — amend the success criteria query to use `LOCAL` instead.

**Primary recommendation:** Write migration 218 for SJ officials (11 politicians) following the exact pattern of migration 211 (Fremont officials), then run headshot skill. All other cities are already done.

## Standard Stack

### Core Pattern (HIGH confidence — verified from migrations 207–215, 217)
| Component | Pattern | Notes |
|-----------|---------|-------|
| Government row | `INSERT ... WHERE NOT EXISTS (name, state)` | No unique constraint on geo_id |
| Chambers | `INSERT ... WHERE NOT EXISTS (name, government_id)` | slug is GENERATED — never include in INSERT |
| Districts (per-seat) | Bulk VALUES insert with NOT EXISTS guard on (geo_id, district_type, state) | `label` column, not `name` |
| Districts (citywide) | Single LOCAL_EXEC row with geo_id = census FIPS code | Shared by mayor + any other citywide offices |
| Politicians | `WITH ins_p AS (INSERT ... ON CONFLICT (external_id) DO NOTHING RETURNING id)` | party = NULL always |
| Offices | `INSERT ... FROM districts CROSS JOIN ins_p WHERE NOT EXISTS (...)` | |
| Back-fill | `UPDATE politicians SET office_id = o.id FROM offices WHERE ... AND office_id IS NULL` | Required for headshot skill compatibility |

### Installation
No packages needed — pure SQL migrations applied via psql to remote Supabase.

## Architecture Patterns

### Migration File Sequence

**Already Applied (confirmed from file system):**
- 207: San Diego government structure (government + 3 chambers + 9 LOCAL districts + 1 LOCAL_EXEC district)
- 208: San Diego officials (9 council members + mayor + city attorney = 11 politicians, external_ids -650001..-650018)
- 209: San Diego headshots (audit-only file — actual writes done live via find-headshots skill)
- 210: Fremont government structure (government + 2 chambers + 6 LOCAL districts + 1 LOCAL_EXEC district)
- 211: Fremont officials (6 council members + mayor = 7 politicians, external_ids -670001..-670015)
- 212: Fremont headshots (audit-only)
- 213: Berkeley government structure (government + 3 chambers + 8 LOCAL districts + 1 LOCAL_EXEC district)
- 214: Berkeley officials (8 council members + mayor + city auditor = 10 politicians, external_ids -680001..-680017)
- 215: Berkeley headshots (audit-only)
- 216: SF officials stances (stance migration — not infrastructure)

**Written, Not Applied:**
- 217: San Jose government structure (government + 2 chambers + 10 LOCAL districts + 1 LOCAL_EXEC district)

**To Be Written:**
- 218: San Jose officials (10 council members + mayor = 11 politicians)
- Headshots for SJ officials (via find-headshots skill, produces audit-only file 219)

### San Jose Officials Composition (current as of May 2026)

San Jose has a strong-mayor form of government. City Attorney and City Auditor are both APPOINTED by the City Council (per the San Jose City Charter, confirmed in migration 217 header). Neither gets a chamber or elected office record.

**Mayor (1, citywide — LOCAL_EXEC district geo_id='0668000'):**
- Matt Mahan — elected 2022, incumbent

**City Council (10, by district — LOCAL districts sj-council-district-1 through 10):**
- District 1: Rosemary Kamei
- District 2: Pam Foley
- District 3: Omar Torres
- District 4: David Cohen
- District 5: Dev Davis
- District 6: Bien Doan
- District 7: Bien Doan (NOTE: verify — D6 and D7 may both be Bien Doan; check official roster)
- District 7: Matthew Mahan (NOT the mayor — different Matthew; verify carefully)
- District 8: Kansen Chu
- District 9: Pam Foley (verify — she may be D2 only)
- District 10: Arjun Batra

**IMPORTANT — Low confidence on council composition (LOW):** The council member names above are from training data and may have changed since the November 2024 election. The planner MUST verify names against the official San Jose city website (sanjoseca.gov/government/city-council) before writing migration 218. This is the primary research gap.

**CONFIDENCE NOTE:** San Diego (11), Fremont (7), and Berkeley (10) compositions are HIGH confidence because their official migrations were already researched and applied by prior sessions with live DB verification.

### External_id Ranges

| City | Range | Notes |
|------|-------|-------|
| SF | -630001 to -630028 | 20 officials |
| San Diego | -650001 to -650018 | 11 officials |
| Fremont | -670001 to -670015 | 7 officials |
| Berkeley | -680001 to -680017 | 10 officials |
| San Jose | **-660001 to -660020** (recommended) | 11 officials; range is unused |
| US Senators | -400001 to -400090 | Do not overlap |
| 2026 Candidates | -400101 to -400143 | Do not overlap |

### Recommended Project Structure
```
backend/migrations/
├── 217_sj_government_structure.sql   (written, apply first)
├── 218_sj_officials.sql              (to write)
└── 219_sj_headshots.sql              (audit-only, produced by find-headshots skill)
```

### Pattern: SJ Officials Migration (modeled on 211_fremont_officials.sql)

Key differences from Fremont:
- 10 council districts (not 6): sj-council-district-1 through 10
- Chamber name: 'City Council' with government = 'City of San Jose' AND state='CA'
- Mayor chamber: 'Mayor' with same government lookup
- geo_id for citywide (mayor): '0668000' — LOCAL_EXEC
- Title for council members: 'Council Member' (two words, no district number in parens — San Jose convention, unlike Berkeley's 'Council Member (District N)')
- external_id range: -660001 (mayor), -660010 through -660019 (10 council members)
- Back-fill range: `BETWEEN -660019 AND -660001`
- NO City Attorney office — appointed position, no chamber created in 217

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Headshot discovery and upload | Custom web scraper | `/find-headshots` skill (existing) | Handles 403 WAF workarounds, image processing, Supabase storage upload |
| District uniqueness enforcement | ON CONFLICT (geo_id, district_type) | WHERE NOT EXISTS guard | No unique constraint exists on that combination |
| Multi-table atomicity | Chained JS awaits | BEGIN/COMMIT in SQL migration | `essentials` schema not accessible via PostgREST |
| Photo URL discovery | Manual search | find-headshots skill with sanjoseca.gov as source | Official portrait pages exist; skill handles download + crop + upload |

## Common Pitfalls

### Pitfall 1: CITY_COUNCIL district_type mismatch
**What goes wrong:** REQUIREMENTS.md CITY-02 and the ROADMAP success criteria specify `district_type = 'CITY_COUNCIL'`. All existing city district rows (SD, Fremont, Berkeley, SJ in 217) use `LOCAL` (per-seat) and `LOCAL_EXEC` (citywide). Running the ROADMAP success criteria query as written will return 0 rows.
**Why it happens:** Requirements were written with a logical name for city council districts; implementation uses the existing enum value `LOCAL` from the pre-existing schema.
**How to avoid:** Amend the success criteria verification query to use `district_type IN ('LOCAL', 'LOCAL_EXEC')` when checking city districts. Do NOT change the actual district_type values in the DB — 3 cities are already live with `LOCAL` and changing them would require migrating existing data.
**Warning signs:** Success criteria query returning 0 rows even after all 4 cities are confirmed live.

### Pitfall 2: slug GENERATED column
**What goes wrong:** Including `slug` in an `INSERT INTO essentials.chambers` statement causes a Postgres error.
**Why it happens:** `slug` is a GENERATED ALWAYS AS column.
**How to avoid:** Never include `slug` in the INSERT column list. Only include `id, name, name_formal, government_id`.

### Pitfall 3: ON CONFLICT guard on districts
**What goes wrong:** Using `ON CONFLICT (geo_id, district_type)` on district inserts fails because no such unique constraint exists.
**Why it happens:** The unique constraint does not exist on `essentials.districts`.
**How to avoid:** Use `WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state)`.

### Pitfall 4: governments table lacks unique constraint on geo_id
**What goes wrong:** Multiple government rows can exist with the same geo_id (Indiana has 22 identical "State of Indiana" rows).
**Why it happens:** `essentials.governments` has no unique constraint on geo_id alone.
**How to avoid:** Always use `WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = '...' AND state = '...')` guards. For SJ: `WHERE name = 'City of San Jose' AND state = 'CA'`.

### Pitfall 5: Missing back-fill of office_id
**What goes wrong:** The `/find-headshots` skill queries politicians JOIN offices ON `o.id = p.office_id`. If the back-fill UPDATE is skipped, the skill finds 0 rows and produces no headshots.
**Why it happens:** `politicians.office_id` is not auto-populated by the office INSERT — it must be explicitly written back.
**How to avoid:** Always include `UPDATE essentials.politicians p SET office_id = o.id FROM essentials.offices o WHERE o.politician_id = p.id AND p.external_id BETWEEN -660019 AND -660001 AND p.office_id IS NULL;` as the final step in the officials migration.

### Pitfall 6: San Jose council composition drift
**What goes wrong:** The November 2024 election changed multiple San Jose council seats. Using pre-2024 roster data produces wrong names.
**Why it happens:** Training data may be stale. San Jose D2 (Pam Foley), D4 (David Cohen), D5 (Dev Davis), and D10 (Arjun Batra) may have changed.
**How to avoid:** Verify the current roster at `https://www.sanjoseca.gov/your-government/elected-officials/city-council` before writing migration 218. Use WebFetch in the planning step.

## Code Examples

### Government + Districts structure (from migration 217 pattern)
```sql
-- Source: 217_sj_government_structure.sql
BEGIN;

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of San Jose', 'LOCAL', 'CA', 'San Jose', '0668000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of San Jose' AND state = 'CA'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of San Jose',
       (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')
);

INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('sj-council-district-1',  'LOCAL', 'District 1',  'CA'),
  -- ... through district 10
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0668000', 'LOCAL_EXEC', 'San Jose (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0668000' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
```

### Official seeding pattern (from migration 211, adapted for SJ)
```sql
-- Source: 211_fremont_officials.sql (pattern)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Mahan', 'Matt', 'Mahan', NULL, true, false, false, true, -660001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Mayor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0668000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual SQL ad-hoc | Templated WITH ins_p pattern | v2.3 (senator migrations) | Idempotent, no-op on re-run |
| phone_origin_url only | politician_images table + photo_origin_url | v2.3 | find-headshots skill handles both |
| Inline headshots in officials migration | Separate headshots audit file | v2.3 (SF pattern) | Clean separation; audit file not applied via ledger |

**Deprecated/outdated:**
- Do not use `ON CONFLICT (geo_id, district_type)` on districts — constraint does not exist
- Do not use `supabaseAdmin.schema('essentials')` — not in PostgREST exposed schema list; use pool.query() direct postgres

## Open Questions

1. **San Jose council member names (current roster)**
   - What we know: Migration 217 (government structure) is already written. Training data gives approximate names but the November 2024 election changed several seats.
   - What's unclear: Exact current names for all 10 district council members as of May 2026.
   - Recommendation: The planner must WebFetch `https://www.sanjoseca.gov/your-government/elected-officials/city-council` to get authoritative current names before writing migration 218. This is a mandatory verification step.

2. **CITY_COUNCIL vs LOCAL district_type**
   - What we know: All existing city districts use `LOCAL` / `LOCAL_EXEC`. Requirements say `CITY_COUNCIL`. These cannot both be correct.
   - What's unclear: Whether the requirements author intended to introduce a new enum value or just used `CITY_COUNCIL` as shorthand for the existing `LOCAL` type.
   - Recommendation: Confirm with Chris that `LOCAL` satisfies CITY-02 (not introducing a new district_type). The success criteria verification query in the plan should be amended to use `LOCAL` instead of `CITY_COUNCIL`.

3. **Migration 217 application status**
   - What we know: The file `217_sj_government_structure.sql` exists in `backend/migrations/`. The SJ officials (218) do not exist yet.
   - What's unclear: Whether migration 217 has actually been applied to the live database.
   - Recommendation: The first task in 77-01 should be to verify whether the SJ government/district rows exist in the live DB (SELECT COUNT(*) from essentials.governments WHERE name = 'City of San Jose') before applying 217. If not applied, apply it first.

4. **San Jose appointed officials scope**
   - What we know: REQUIREMENTS.md CITY-03 mentions "key appointed roles such as City Attorney, City Clerk, City Administrator." Migration 217 explicitly states City Attorney and City Auditor are BOTH APPOINTED (no chambers created for them).
   - What's unclear: Whether to include appointed officials (City Attorney Jennifer Nygaard, City Manager Jennifer Schembri) as politician records with `is_appointed = true`.
   - Recommendation: Follow the SF pattern — include key appointed officials (City Manager + City Attorney) as politician records with `is_appointed_position = true` on their office row. Both are civic officials worth surfacing for stance research. This adds 2 more officials to migration 218 (total ~13 instead of 11).

## Sources

### Primary (HIGH confidence)
- `backend/migrations/207_sd_government_structure.sql` — SD government/district pattern verified
- `backend/migrations/208_sd_officials.sql` — SD officials pattern verified (11 politicians)
- `backend/migrations/210_fremont_government_structure.sql` — Fremont pattern verified
- `backend/migrations/211_fremont_officials.sql` — Fremont officials pattern verified (7 politicians)
- `backend/migrations/213_berkeley_government_structure.sql` — Berkeley pattern verified
- `backend/migrations/214_berkeley_officials.sql` — Berkeley officials pattern verified (10 politicians)
- `backend/migrations/217_sj_government_structure.sql` — SJ government structure (written, unapplied status unknown)
- `backend/migrations/199_sf_officials.sql` — canonical reference for appointed officials pattern

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — v2.5 requirements definition; district_type discrepancy identified
- `.planning/ROADMAP.md` — success criteria queries; uses CITY_COUNCIL (conflicts with actual schema)
- `.planning/STATE.md` — v2.5 infrastructure patterns carry-forward note

### Tertiary (LOW confidence)
- Training data knowledge of San Jose city council composition — must be verified via official city website before authoring migration 218

## Metadata

**Confidence breakdown:**
- SD, Fremont, Berkeley infrastructure: HIGH — migrations already applied, verified at time of application
- SJ government structure: HIGH — migration 217 is written and matches established pattern
- SJ officials composition: LOW — must verify against official roster before writing migration 218
- Migration pattern and schema constraints: HIGH — verified from 6 prior city migrations

**Research date:** 2026-05-23
**Valid until:** 2026-06-23 (city council composition may change; stable otherwise)
