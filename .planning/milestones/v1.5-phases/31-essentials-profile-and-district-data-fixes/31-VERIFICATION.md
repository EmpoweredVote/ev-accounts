---
phase: 31-essentials-profile-and-district-data-fixes
verified: 2026-02-22T00:00:00Z
status: human_needed
score: 10/11 must-haves verified
human_verification:
  - test: "Confirm Bloomington city council district boundaries exist in geofence_boundaries table"
    expected: "SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc = 'X0001' returns 6"
    why_human: "Database-only change; cannot query Supabase from codebase inspection"
  - test: "Confirm Bloomington address search returns council district members"
    expected: "Searching a Bloomington, IN address shows city council district members with correct district in subtitle"
    why_human: "Requires live API call with geofence point-in-polygon evaluation"
---

# Phase 31: Essentials Profile and District Data Fixes — Verification Report

**Phase Goal:** Fix essentials profile display issues and district data visibility
**Verified:** 2026-02-22
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | API responses include `district_id` field for all politicians | VERIFIED | `DistrictID string json:"district_id,omitempty"` in OfficialOut at handlers.go:123; `COALESCE(d.district_id, '') AS district_id_text` in all 3 GORM Scan paths (lines 1117, 1409, 1968) and manual Scan in geofence_lookup.go:157 |
| 2 | X0001 MTFCC code mapped to LOCAL district type | VERIFIED | `"X0001": {"LOCAL"}` at geofence_lookup.go:30; comment: "City council sub-districts (BallotReady custom MTFCC)" |
| 3 | PoliticianProfile shows chamber + district subtitle | VERIFIED | `buildSubtitle(pol)` function at PoliticianProfile.jsx:22-39; rendered at line 261-263 with `styles.subtitle` |
| 4 | PoliticianProfile term dates use labeled format | VERIFIED | `getTermLine()` returns `"First elected: ${start} \u2014 Term ends: ${end}"` at PoliticianProfile.jsx:19 |
| 5 | PoliticianProfile years in office appear below term dates | VERIFIED | `total_years_in_office` rendered at line 291-294, after termDate block at line 286-288 |
| 6 | PoliticianProfile shows office_description as italic; no bio_text | VERIFIED | Italic office_description at line 279-283; no `bio_text`, no `normalizeNotes`, no bio variable anywhere in file |
| 7 | PoliticianProfile missing image shows circular initials avatar | VERIFIED | `placeholder` style has `borderRadius: '50%'`, `background: colors.evTeal`; initials from `pol.first_name[0] + pol.last_name[0]` at lines 215-218, 250 |
| 8 | PoliticianCard accepts subtitle prop and renders 3rd line | VERIFIED | `subtitle` in prop signature at PoliticianCard.jsx:24; `{subtitle && <p style={styles.subtitle}>{subtitle}</p>}` at line 236-238 |
| 9 | PoliticianCard missing image shows initials avatar | VERIFIED | `getInitials(name)` function at lines 182-188; `imagePlaceholder` style with `evTeal` background and `borderRadius: isHorizontal ? '50%' : 0` at lines 70-82 |
| 10 | No party affiliation rendered anywhere | VERIFIED | grep for `party` in PoliticianProfile.jsx, PoliticianCard.jsx, Results.jsx, Profile.jsx — zero matches in JSX output |
| 11 | Bloomington city council district boundaries in geofence table | HUMAN NEEDED | Database-only change; SUMMARY claims 6 rows inserted with mtfcc='X0001' and point-in-polygon verified, but cannot confirm from codebase |

**Score:** 10/11 truths verified (1 requires human/database confirmation)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/internal/essentials/handlers.go` | `district_id` in OfficialOut and all 4 query functions | VERIFIED | OfficialOut.DistrictID at line 123; district_id_text alias in fetchOfficialsFromDB (1117), fetchFederalAndStateFromDBFiltered (1409), GetPoliticianByID (1968); assembly at lines 1300, 1568, 2068 |
| `EV-Backend/internal/essentials/geofence_lookup.go` | X0001 mapping + district_id in FindPoliticiansByGeoMatches | VERIFIED | X0001 at line 30; SELECT alias at line 157; Scan at line 216 |
| `ev-ui/src/PoliticianProfile.jsx` | `buildSubtitle`, labeled terms, circular placeholder, no bio | VERIFIED | buildSubtitle function present; getTermLine uses "First elected" format; placeholder has borderRadius 50% + evTeal; no bio_text anywhere |
| `ev-ui/src/PoliticianCard.jsx` | subtitle prop, initials avatar | VERIFIED | subtitle in props at line 24; getInitials function at lines 182-188; imagePlaceholder with evTeal background |
| `ev-ui/package.json` | Version 0.1.27 | VERIFIED | `"version": "0.1.27"` confirmed |
| `essentials/src/pages/Results.jsx` | subtitle computation + PoliticianCard subtitle prop | VERIFIED | subtitle IIFE at lines 71-88 with LOCAL edge case; `subtitle={subtitle}` at line 97 |
| `essentials/src/pages/Profile.jsx` | No Issues section, no compass imports | VERIFIED | File is 84 lines; no RadarChartCore, IssueTags, fetchTopics, useIsMobile, or compass state present |
| `essentials/package.json` | ev-ui dependency at ^0.1.27 | VERIFIED | `"@chrisandrewsedu/ev-ui": "^0.1.27"` confirmed |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| handlers.go OfficialOut | fetchOfficialsFromDB SQL | `d.district_id` in SELECT + DistrictIDText row struct + Scan + assembly | WIRED | COALESCE(d.district_id,'') AS district_id_text at line 1117; DistrictIDText in row struct at line 1079; DistrictID assembled at line 1300 |
| handlers.go OfficialOut | fetchFederalAndStateFromDBFiltered | Same alias pattern | WIRED | Line 1409 (SELECT), 1373 (struct), 1568 (assembly) |
| handlers.go OfficialOut | GetPoliticianByID | Same alias pattern | WIRED | Line 1968 (SELECT), 1925 (struct), 2068 (assembly) |
| geofence_lookup.go FindPoliticiansByGeoMatches | OfficialOut.DistrictID | Manual Scan with &off.DistrictID | WIRED | SELECT alias at line 157; Scan at line 216 |
| geofence_lookup.go mtfccToDistrictTypes | FindPoliticiansByGeoMatches WHERE clause | Map lookup for X0001 | WIRED | Map at line 30; lookup at line 82 |
| PoliticianProfile.jsx buildSubtitle | pol.chamber_name + pol.district_id | Prop access on politician object | WIRED | `pol.district_id` at line 24; rendered at lines 261-263 |
| PoliticianCard.jsx subtitle prop | styles.subtitle | Conditional rendering | WIRED | `subtitle && <p style={styles.subtitle}>{subtitle}</p>` at line 236-238 |
| Results.jsx renderPoliticianCard | PoliticianCard subtitle prop | `subtitle={subtitle}` (undefined fallback) | WIRED | Lines 71-88 build subtitle; line 97 passes it |
| Profile.jsx PoliticianProfile | No Issues children | Empty render — no children passed | WIRED | PoliticianProfile at lines 69-77 with no children |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PROF-01 | 31-01, 31-02 | Chamber + district subtitle below office title | SATISFIED | buildSubtitle in PoliticianProfile.jsx + district_id from backend |
| PROF-02 | 31-02 | Labeled term date format | SATISFIED | getTermLine returns "First elected: X — Term ends: Y" at line 19 |
| PROF-03 | 31-02 | Years in office below term dates | SATISFIED | total_years_in_office rendered after termDate block |
| PROF-04 | 31-02 | Initials avatar circle for missing images | SATISFIED | placeholder style with borderRadius 50%, evTeal background, initials |
| PROF-05 | 31-02 | Office description italic; no bio_text | SATISFIED | Italic office_description at line 279; zero bio references |
| PROF-06 | 31-03 | Issues and Prioritization section removed | SATISFIED | Profile.jsx has no Issues section, no compass imports |
| CARD-01 | 31-01, 31-02, 31-03 | Cards show 3 lines with subtitle | SATISFIED | PoliticianCard subtitle prop + Results.jsx subtitle computation |
| CARD-02 | 31-02, 31-03 | 2-line fallback when no chamber/district | SATISFIED | `subtitle && <p>` conditional; subtitle returns undefined when no chamber |
| CARD-03 | 31-02, 31-03 | No party affiliation on cards or profiles | SATISFIED | No party field referenced in JSX output of any modified component |
| DIST-01 | 31-03 | Bloomington council members appear in address search | HUMAN NEEDED | Requires live DB + API verification; SUMMARY self-check passed but unverifiable from code |
| DIST-02 | 31-01 | X0001 MTFCC mapped to LOCAL | SATISFIED | `"X0001": {"LOCAL"}` in mtfccToDistrictTypes at geofence_lookup.go:30 |

**Orphaned requirements:** None. All 11 requirements are claimed across Plans 01, 02, and 03.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No TODOs, FIXMEs, placeholder returns, or stub implementations found in any modified file. The two `return []OfficialOut{}, nil` patterns in handlers.go are legitimate early-exit guards for empty result sets, not stubs.

---

## Human Verification Required

### 1. Bloomington Geofence Boundaries — Database Confirmation

**Test:** Connect to the Supabase project and run:
```sql
SELECT geo_id, name, mtfcc, ST_IsValid(geometry), ST_Area(geometry::geography)
FROM essentials.geofence_boundaries
WHERE mtfcc = 'X0001';
```
**Expected:** 6 rows returned (Districts 1-6), each with `ST_IsValid = true` and non-zero area.

**Why human:** This is a database-only change with no code artifact. Cannot query the Supabase instance from static codebase inspection.

### 2. Bloomington Address Search — Live API Confirmation

**Test:** Search a Bloomington, IN address (e.g., "401 N Morton St, Bloomington, IN 47404") in the essentials app.
**Expected:** Results include Bloomington City Common Council member(s) with a district subtitle (e.g., a district label or "City Common Council, District 6"). Council members should appear in the Local section.

**Why human:** Requires the geofence point-in-polygon query to execute against the live database with real coordinate input, then the frontend to render the subtitle with the district data from the API.

---

## Build Verification

- `go build -o /dev/null .` in EV-Backend: PASSED (no output, exit 0)
- ev-ui commits b32a1bf, 6d0be45, 9c89beb: all exist in git history
- essentials commit 4f212d0: exists in git history
- EV-Backend commits 3b8a574, d32a463: exist in git history

---

## Gaps Summary

No blocking gaps identified. All 10 automatically verifiable must-haves pass at all three levels (exists, substantive, wired). The single unverified item (DIST-01, Bloomington geofence DB rows) is a database-only change documented in the SUMMARY with a passing self-check — it cannot be confirmed through static code inspection and requires human or live-database verification.

---

_Verified: 2026-02-22_
_Verifier: Claude (gsd-verifier)_
