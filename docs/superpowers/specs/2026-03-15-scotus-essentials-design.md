# SCOTUS Justices in Essentials — Design Spec

**Date:** 2026-03-15
**Status:** Approved
**Scope:** Add 9 U.S. Supreme Court justices to the Essentials module with a Federal Judiciary foundation that can expand to circuit/district courts later.

---

## Problem

Supreme Court justices are not elected but have significant impact on individuals. They should appear alongside other federal officials when users search by address.

## Approach

Go import command (Approach B) with hardcoded justice data. Idempotent, repeatable, follows existing pipeline patterns. Photos stored in Supabase Storage with original URLs as backup.

---

## 1. Data Model Changes

### New District Type: `NATIONAL_JUDICIAL`

Follows the naming convention of `NATIONAL_EXEC`, `NATIONAL_UPPER`, `NATIONAL_LOWER`. Single district record with `geo_id = "US"`, `is_judicial = true`, no geofence boundary.

### New Table: `essentials.judge_details`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| politician_id | uuid | FK to politicians, unique |
| appointed_by | string | President name, e.g. "Barack Obama" |
| appointing_president_party | string | e.g. "Democratic", "Republican" |
| confirmation_vote | string (nullable) | e.g. "68-31", null for voice votes |
| court_role | string | "Chief Justice" or "Associate Justice" |
| created_at / updated_at | timestamps | Standard GORM fields |

GORM model must include `TableName()` returning `"essentials.judge_details"` (consistent with all other models). Must be added to `AutoMigrate` in `setup.go`.

### Supporting Records (created by import)

- 1 `GovernmentBody` — "U.S. Supreme Court", state: "US", body_key: "Supreme Court of the United States" (must match chamber name_formal for the LEFT JOIN in queries)
- 1 `Chamber` — name: "U.S. Supreme Court", name_formal: "Supreme Court of the United States", election_frequency: "life_tenure"
- 1 `District` — district_type: `NATIONAL_JUDICIAL`, geo_id: "US", state: "US", is_judicial: true

**ExternalID handling:** Chamber, District, and Politician models have `uniqueIndex` on `ExternalID`. The import must assign distinct negative IDs (e.g., -100, -101, ...) to avoid conflicts with data imported from external sources (BallotReady, Cicero) which use positive IDs.
- 9 `Office` records — one per seat, title: "Chief Justice" / "Associate Justice"
- 9 `Politician` records — is_appointed: true, is_incumbent: true, is_active: true, party: "Nonpartisan"
- 9 `JudgeDetail` records
- 9+ `PoliticianImage` records (Supabase CDN primary, supremecourt.gov origin URL as backup)

---

## 2. Backend — Geofence Matching

`NATIONAL_JUDICIAL` is treated identically to `NATIONAL_EXEC` — always included in query results regardless of state or address.

### Query Changes — All `NATIONAL_EXEC` Locations

Every place that special-cases `NATIONAL_EXEC` must also include `NATIONAL_JUDICIAL`:

| Location | File | Action |
|----------|------|--------|
| `fetchOfficialsFromDB` (~line 1241) | handlers.go | Add `OR d.district_type = 'NATIONAL_JUDICIAL'` |
| `fetchFederalAndStateFromDBFiltered` (~line 1571) | handlers.go | Add `OR d.district_type = 'NATIONAL_JUDICIAL'` |
| `FindPoliticiansByGeoMatches` | geofence_lookup.go | Add `NATIONAL_JUDICIAL` condition alongside `NATIONAL_EXEC` |

**Intentionally excluded** — these are candidate/election queries; SCOTUS justices are appointed, not candidates:

| Location | File | Reason excluded |
|----------|------|-----------------|
| `GetCandidatesByZip` (~line 2790) | handlers.go | Candidate search, not applicable to appointed justices |
| `SearchCandidates` (~line 3004) | handlers.go | Candidate search, not applicable to appointed justices |

`fetchStatewideFromDB` inherits the change automatically via `fetchFederalAndStateFromDBFiltered` — no separate change needed.

Example query pattern:

```sql
WHERE (
  d.district_type = 'NATIONAL_EXEC'
  OR d.district_type = 'NATIONAL_JUDICIAL'
  OR (
    d.district_type = ANY(?)
    AND (o.representing_state = ? OR d.state = ?)
  )
)
```

### No Geofence Boundary

No geometry in the `geofences` table. No MTFCC mapping. District record has `geo_id = "US"` as a marker only.

---

## 3. Frontend — Classification & Display

### classify.js

Add `NATIONAL_JUDICIAL` to the Federal tier:

```javascript
if (dt === "NATIONAL_JUDICIAL") {
  return { tier: "Federal", group: "Federal Judiciary" };
}
```

### Display Order

Add `"Federal Judiciary"` to the end of the `FEDERAL_ORDER` array in classify.js so it renders at the bottom of the Federal tier:

```javascript
const FEDERAL_ORDER = [...existing entries..., "Federal Judiciary"];
```

### Category Display Name

Add entry to `CATEGORY_DISPLAY_NAMES`:

```javascript
"Federal Judiciary": "U.S. Supreme Court",
```

More specific and meaningful for users since that's the only federal court for now.

### sorters.js

New sort group for Federal Judiciary:

```javascript
"Federal Judiciary": [
  { id: "court_role", label: "Role", cmp: (dir) => makeComparator(chiefJusticeFirstKey, dir) },
  { id: "seniority", label: "Seniority", cmp: (dir) => makeComparator(appointmentDateKey, dir) },
  { id: "name", label: "Name", cmp: (dir) => makeComparator(lastNameKey, dir) },
]
```

Note: Uses the `(dir) => makeComparator(keyFn, dir)` factory pattern consistent with existing sort group entries.

Chief Justice sorts first, then by seniority (appointment date), then alphabetically by name.

### Profile Page

No changes needed — existing politician profile view handles all stored fields. Display of `judge_details` fields (appointed_by, confirmation_vote) is a follow-up enhancement.

---

## 4. Go Import Command

### File: `EV-Backend/internal/essentials/import_scotus.go`

### Behavior

1. **Ensures prerequisite records exist** (find-or-create):
   - GovernmentBody, Chamber, District (as described in Section 1)
2. **For each of the 9 justices, upserts:**
   - Office record (title based on role)
   - Politician record (is_appointed, is_incumbent, is_active, party: "Nonpartisan")
   - JudgeDetail record (appointed_by, party, vote, role)
   - PoliticianImage record (Supabase CDN URL)
3. **Idempotent** — matches justices by full name, safe to re-run
4. **Triggered by** CLI flag (`--import-scotus`) or admin endpoint (`POST /essentials/admin/import-scotus`)

### Justice Data (as of March 2026)

| Justice | Role | Appointed By | President Party | Vote | Since |
|---------|------|-------------|-----------------|------|-------|
| John G. Roberts Jr. | Chief Justice | George W. Bush | Republican | 78-22 | 2005-09-29 |
| Clarence Thomas | Associate Justice | George H.W. Bush | Republican | 52-48 | 1991-10-23 |
| Samuel A. Alito Jr. | Associate Justice | George W. Bush | Republican | 58-42 | 2006-01-31 |
| Sonia Sotomayor | Associate Justice | Barack Obama | Democratic | 68-31 | 2009-08-08 |
| Elena Kagan | Associate Justice | Barack Obama | Democratic | 63-37 | 2010-08-07 |
| Neil M. Gorsuch | Associate Justice | Donald Trump | Republican | 54-45 | 2017-04-10 |
| Brett M. Kavanaugh | Associate Justice | Donald Trump | Republican | 50-48 | 2018-10-06 |
| Amy Coney Barrett | Associate Justice | Donald Trump | Republican | 52-48 | 2020-10-27 |
| Ketanji Brown Jackson | Associate Justice | Joe Biden | Democratic | 53-47 | 2022-06-30 |

---

## 5. Photo Workflow

1. Download official portraits from supremecourt.gov
2. Upload to Supabase Storage bucket (consistent with existing headshot pattern)
3. Store Supabase CDN URL as primary in `PoliticianImage`
4. Store original supremecourt.gov URL in `photo_origin_url` on the politician record as backup

---

## Out of Scope

- Education and experience data for justices (tables exist, can add later)
- Federal circuit/district court judges (foundation supports it via `NATIONAL_JUDICIAL` type)
- Display of `judge_details` on the Profile page (follow-up frontend enhancement)
- Scraping/automation of justice data updates
