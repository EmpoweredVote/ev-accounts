---
phase: 77-city-infrastructure-official-records
plan: "02"
subsystem: essentials-data
tags: [verification, city-officials, san-jose, san-diego, berkeley, fremont, data-audit]
dependency_graph:
  requires: [77-01]
  provides: [city-01-08-verification, phase-78-go-no-go]
  affects: []
tech_stack:
  added: []
  patterns: [read-only-verification, psql-direct-queries]
key_files:
  created:
    - .planning/phases/77-city-infrastructure-official-records/77-02-SUMMARY.md
  modified: []
decisions:
  - "CITY-02 uses district_type IN ('LOCAL', 'LOCAL_EXEC') not 'CITY_COUNCIL' — enum value does not exist in schema (RESEARCH.md Pitfall 1)"
  - "SJ external_id range is -640001 to -640019 (not -660001 as originally planned in RESEARCH.md) — confirmed from live DB and 77-01-SUMMARY"
  - "Sacramento officials (-660001 to -660017) incidentally fall inside the BETWEEN -680017 AND -640001 catch-all range — excluded from per-city counts via explicit CASE WHEN buckets"
  - "All 4 cities pass all 8 requirements — Phase 77 is closeable, Phase 78 is GREEN"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-28"
  tasks_completed: 1
  files_changed: 1
---

# Phase 77 Plan 02: City Infrastructure Verification Report

Executed: 2026-05-28

Read-only verification pass. All 8 CITY-01 through CITY-08 requirements verified against the live DB across San Jose, San Diego, Berkeley, and Fremont.

## Result Summary

| Requirement | Description | San Jose | San Diego | Berkeley | Fremont | Status |
|-------------|-------------|----------|-----------|----------|---------|--------|
| CITY-01 | Government row exists | PASS | PASS | PASS | PASS | **PASS** |
| CITY-02 | LOCAL districts (per-seat) | 10 | 9 | 8 | 6 | **PASS** |
| CITY-02 | LOCAL_EXEC district (citywide) | 1 | 1 | 1 | 1 | **PASS** |
| CITY-03 | Politician records — SJ | 11 | — | — | — | **PASS** |
| CITY-04 | Politician records — SD | — | 11 | — | — | **PASS** |
| CITY-05 | Politician records — Berkeley | — | — | 10 | — | **PASS** |
| CITY-06 | Politician records — Fremont | — | — | — | 7 | **PASS** |
| CITY-07 | Offices linked to valid district | 0 orphans | 0 orphans | 0 orphans | 0 orphans | **PASS** |
| CITY-07 | Every politician has >= 1 office | 0 missing | 0 missing | 0 missing | 0 missing | **PASS** |
| CITY-07 | office_id back-fill complete | 0 NULL | 0 NULL | 0 NULL | 0 NULL | **PASS** |
| CITY-08 | photo_origin_url populated | 0 missing | 0 missing | 0 missing | 0 missing | **PASS** |
| CITY-08 | politician_images row exists | 0 missing | 0 missing | 0 missing | 0 missing | **PASS** |

All 8 requirements: **PASS**

---

## Detailed Query Results

### CITY-01: Government Stubs

```sql
SELECT name, state, geo_id, type
FROM essentials.governments
WHERE name IN ('City of San Jose', 'City of San Diego', 'City of Berkeley', 'City of Fremont')
ORDER BY name;
```

| name | state | geo_id | type |
|------|-------|--------|------|
| City of Berkeley | CA | 0606000 | LOCAL |
| City of Fremont | CA | 0626000 | LOCAL |
| City of San Diego | CA | 0666000 | LOCAL |
| City of San Jose | CA | 0668000 | LOCAL |

**Row count: 4. Expected: 4. PASS.**

---

### CITY-02: City Council District Records

**LOCAL (per-seat) districts:**

```sql
SELECT
  CASE
    WHEN geo_id LIKE 'sj-%' THEN 'San Jose'
    WHEN geo_id LIKE 'sd-%' THEN 'San Diego'
    WHEN geo_id LIKE 'berkeley-%' THEN 'Berkeley'
    WHEN geo_id LIKE 'fremont-%' THEN 'Fremont'
    ELSE 'other'
  END AS city,
  COUNT(*) AS local_seats
FROM essentials.districts
WHERE district_type = 'LOCAL'
  AND state = 'CA'
  AND (geo_id LIKE 'sj-%' OR geo_id LIKE 'sd-%' OR geo_id LIKE 'berkeley-%' OR geo_id LIKE 'fremont-%')
GROUP BY 1
ORDER BY 1;
```

| city | local_seats |
|------|-------------|
| Berkeley | 8 |
| Fremont | 6 |
| San Diego | 9 |
| San Jose | 10 |

Expected: {SJ:10, SD:9, Berkeley:8, Fremont:6}. **PASS.**

**LOCAL_EXEC (citywide) districts:**

```sql
SELECT geo_id, label
FROM essentials.districts
WHERE district_type = 'LOCAL_EXEC'
  AND state = 'CA'
  AND geo_id IN ('0668000', '0666000', '0606000', '0626000')
ORDER BY geo_id;
```

| geo_id | label |
|--------|-------|
| 0606000 | Berkeley (Citywide) |
| 0626000 | Fremont (Citywide) |
| 0666000 | San Diego (Citywide) |
| 0668000 | San Jose (Citywide) |

**Row count: 4. Expected: 4. PASS.**

---

### CITY-03 / CITY-04 / CITY-05 / CITY-06: Politician Records Per City

```sql
SELECT
  CASE
    WHEN external_id BETWEEN -640019 AND -640001 THEN 'San Jose'
    WHEN external_id BETWEEN -650018 AND -650001 THEN 'San Diego'
    WHEN external_id BETWEEN -680017 AND -680001 THEN 'Berkeley'
    WHEN external_id BETWEEN -670015 AND -670001 THEN 'Fremont'
  END AS city,
  COUNT(*) AS politicians
FROM essentials.politicians
WHERE external_id BETWEEN -680017 AND -640001
GROUP BY 1
ORDER BY 1;
```

| city | politicians |
|------|-------------|
| Berkeley | 10 |
| Fremont | 7 |
| San Diego | 11 |
| San Jose | 11 |
| (NULL — Sacramento) | 9 |

**Note:** The catch-all range `BETWEEN -680017 AND -640001` picks up 9 Sacramento city officials who use external_id range -660001 to -660017. These are NOT one of the 4 target cities and are counted in the NULL bucket. Per-city counts for SJ/SD/Berkeley/Fremont are unaffected. The 4-city total is SJ 11 + SD 11 + Berkeley 10 + Fremont 7 = **39**. Expected: 39. **PASS.**

---

### CITY-07: Office Records Linked to Correct District

**Orphan offices (NULL district FK):**

```sql
SELECT COUNT(*) AS orphan_offices
FROM essentials.offices o
LEFT JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE p.external_id BETWEEN -680017 AND -640001
  AND d.id IS NULL;
```

**Result: 0. Expected: 0. PASS.**

**Politicians without any office:**

```sql
SELECT COUNT(*) AS politicians_without_office
FROM essentials.politicians p
WHERE p.external_id BETWEEN -680017 AND -640001
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id);
```

**Result: 0. Expected: 0. PASS.**

**office_id back-fill status (per city):**

```sql
SELECT
  CASE
    WHEN external_id BETWEEN -640019 AND -640001 THEN 'San Jose'
    WHEN external_id BETWEEN -650018 AND -650001 THEN 'San Diego'
    WHEN external_id BETWEEN -680017 AND -680001 THEN 'Berkeley'
    WHEN external_id BETWEEN -670015 AND -670001 THEN 'Fremont'
  END AS city,
  COUNT(*) FILTER (WHERE office_id IS NULL) AS missing_office_id,
  COUNT(*) AS total
FROM essentials.politicians
WHERE (
    external_id BETWEEN -640019 AND -640001
    OR external_id BETWEEN -650018 AND -650001
    OR external_id BETWEEN -680017 AND -680001
    OR external_id BETWEEN -670015 AND -670001
  )
GROUP BY 1
ORDER BY 1;
```

| city | missing_office_id | total |
|------|-------------------|-------|
| Berkeley | 0 | 10 |
| Fremont | 0 | 7 |
| San Diego | 0 | 11 |
| San Jose | 0 | 11 |

**All 0. Expected: 0. PASS.**

---

### CITY-08: photo_origin_url Populated

```sql
SELECT
  CASE
    WHEN external_id BETWEEN -640019 AND -640001 THEN 'San Jose'
    WHEN external_id BETWEEN -650018 AND -650001 THEN 'San Diego'
    WHEN external_id BETWEEN -680017 AND -680001 THEN 'Berkeley'
    WHEN external_id BETWEEN -670015 AND -670001 THEN 'Fremont'
  END AS city,
  COUNT(*) FILTER (WHERE photo_origin_url IS NULL OR photo_origin_url = '') AS missing_photo,
  COUNT(*) AS total
FROM essentials.politicians
WHERE (
    external_id BETWEEN -640019 AND -640001
    OR external_id BETWEEN -650018 AND -650001
    OR external_id BETWEEN -680017 AND -680001
    OR external_id BETWEEN -670015 AND -670001
  )
GROUP BY 1
ORDER BY 1;
```

| city | missing_photo | total |
|------|---------------|-------|
| Berkeley | 0 | 10 |
| Fremont | 0 | 7 |
| San Diego | 0 | 11 |
| San Jose | 0 | 11 |

**All 0 missing. Expected: 0. PASS.**

**Cross-check: politician_images row exists for every official with photo_origin_url:**

```sql
SELECT COUNT(*) AS missing_image_row
FROM essentials.politicians p
WHERE (
    p.external_id BETWEEN -640019 AND -640001
    OR p.external_id BETWEEN -650018 AND -650001
    OR p.external_id BETWEEN -680017 AND -680001
    OR p.external_id BETWEEN -670015 AND -670001
  )
  AND p.photo_origin_url IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);
```

**Result: 0. Expected: 0. PASS.**

---

## Anomalies and Exceptions

### 1. San Jose external_id range differs from RESEARCH.md recommendation

RESEARCH.md recommended -660001 to -660020 for San Jose. The actual migration 218 used -640001 to -640019. The -660xxx range was already occupied by Sacramento city officials (9 officials: Kevin McCarty, Lisa Kaplan, Roger Dickinson, Karina Talamantes, Phil Pluckebaum, Caity Maple, Eric Guerra, Rick Jennings II, Mai Vang). The migration author correctly avoided the collision. No data integrity issue — this is an informational note for future ID range planning.

### 2. Sacramento officials in catch-all range

The plan's CITY-03–06 query uses `BETWEEN -680017 AND -640001` which inadvertently includes 9 Sacramento officials (-660001 to -660017). The plan's query was designed before the SJ range was known. This does not affect correctness: the explicit CASE WHEN city buckets correctly assign all 39 target-city politicians, and Sacramento officials fall in the NULL bucket. The orphan/no-office queries for the range are also clean: Sacramento officials have valid offices, so the aggregate counts are still correct.

### 3. Photo notes from 77-01

Per 77-01-SUMMARY.md, the `photo_origin_url` field was populated via direct psql UPDATE after the headshots script (commit 502b21b) had created `politician_images` rows without back-filling `photo_origin_url`. Both fields are now confirmed clean across all 4 cities.

---

## Phase 78 Go/No-Go

**GREEN — Phase 78 (City Stance Research) may begin.**

All 8 CITY requirements pass:

- 4 government rows confirmed (CITY-01)
- 33 LOCAL + 4 LOCAL_EXEC district rows confirmed (CITY-02)
- 39 total new city politicians (SJ 11 + SD 11 + Berkeley 10 + Fremont 7) confirmed (CITY-03–06)
- Zero orphan offices, zero politicians without offices, zero office_id NULLs (CITY-07)
- Zero missing photo_origin_url, zero missing politician_images rows (CITY-08)

The data foundation for all 4 cities is complete and consistent. Stance research agents for Phase 78 can begin targeting all 39 officials across 43 topics.

---

## Deviations from Plan

None. This was a read-only verification plan. All queries executed as specified. The Sacramento range overlap (anomaly 2 above) is an informational finding, not a defect — the data is correct.

---

## Known Stubs

None — all 39 officials have government, district, office, photo_origin_url, and politician_images data in the live DB.

---

## Threat Flags

None — read-only verification, no new network endpoints or auth paths introduced.

---

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| 77-02-SUMMARY.md exists | FOUND |
| CITY-01 pass: 4 government rows | CONFIRMED |
| CITY-02 pass: 33 LOCAL + 4 LOCAL_EXEC | CONFIRMED |
| CITY-03–06 pass: 39 politicians | CONFIRMED |
| CITY-07 pass: 0 orphan offices | CONFIRMED |
| CITY-08 pass: 0 missing photos | CONFIRMED |
| Phase 78 go/no-go explicit | GREEN |
