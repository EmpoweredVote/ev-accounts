# is_appointed Data Quality Audit

**Run date:** 2026-03-29T19:43:54.464Z
**Database:** Production (kxsdzaojfaibhuzmclfq)
**Audit script:** `ev-accounts/backend/scripts/audit-is-appointed.ts`
**Methodology:** READ-ONLY — no data modifications per D-09 (report-then-fix approach)

---

## Summary

| Metric | Count | Notes |
|--------|-------|-------|
| Total active politicians | 78,879 | Includes campaign finance records (see data quality note below) |
| Offices with NULL is_appointed_position | 77,099 | 97.6% of all offices — these **default to "elected"** via COALESCE |
| Offices classified as appointed (true) | 50 | Bloomington city officials + manual entries |
| Offices classified as elected (false) | 1,733 | LA County, Bloomington, CA SoS imports |
| Well-classified active politicians | 1,277 | Only 1.6% of "active" total |
| Direct politician/office mismatches | 1 | Courtney Daily (Bloomington interim appointment) |
| Politicians affected by NULL office | 77,603 | Includes campaign finance records |

### Critical Data Quality Discovery

**The 78,879 "active politicians" figure is misleading.** Approximately 77,626 records with `data_source = NULL` and `full_name` values like "ZUNIGA FOR CITY COUNCIL 2018" or "COMMITTEE TO ELECT..." are **BallotReady campaign finance records** imported during v1.5. These are political action committees and campaign committees — not actual officeholders. They have `is_active = true` but no office FK, no government/chamber linkage, and no `is_appointed_position`.

This means the **real active officials** are approximately:
- 1,277 well-classified officials (LA County + Bloomington BallotReady imports)
- 503 manual-source officials (LA County judges + city officials added in v1.6)
- ~3,304 NULL-office officials with real titles (City Council Member, Mayor, Judge, etc.)

**Total real officials (estimate): ~5,084**

The Phase 100 filter UI must use `getRepresentativesByAddress` (which joins via PostGIS geofences), not a direct politicians table query. The geofence join naturally excludes campaign finance records since they have no office/chamber/geofence linkage. This **partially mitigates** the Phase 100 risk.

---

## Tier 1: Office-Level Findings

### Overview

Of the 1,783 classified offices (50 appointed + 1,733 elected), the classification is correct and was set during BallotReady import or manual data entry.

Of the 77,099 offices with NULL `is_appointed_position`:
- **73,795** belong to BallotReady campaign finance records (no office title, no government linkage) — these are NOT real officeholders and will not appear in geofence-based address searches
- **3,304** belong to real officials with office titles but NULL classification — **these are the actionable findings**

### Real Officials with NULL Classification (the actual concern)

| Office Title | Count | District Type | Assessment |
|-------------|-------|---------------|------------|
| City Council Member | 1,402 | LOCAL/LOCAL_EXEC | Elected — safe default |
| Indiana Elected Official | 672 | Various | Elected — safe default (name says "Elected") |
| Assembly Member | 292 | STATE_LOWER | Elected — safe default |
| Supervisor | 215 | COUNTY/LOCAL | Mix — LA County supervisors are elected; some county supervisors elsewhere may be appointed |
| School Board Member | 183 | SCHOOL | Elected — safe default |
| Mayor | 157 | LOCAL_EXEC | Elected — safe default |
| Judge | 141 | JUDICIAL | **NEEDS REVIEW** — some judges are appointed, some elected |
| U.S. Representative | 84 | NATIONAL_LOWER | Elected — safe default |
| State Senator | 72 | STATE_UPPER | Elected — safe default |
| Sheriff | 43 | COUNTY | Elected — safe default |
| Superior Court Judge | 29 | JUDICIAL | **NEEDS REVIEW** — CA superior court judges are elected or appointed by governor |
| Councilmember | 29 | LOCAL | Elected — safe default |
| Treasurer | 24 | Various | Mix — depends on jurisdiction |
| Council - At Large | 23 | LOCAL | Elected — safe default |
| District Attorney | 20 | COUNTY | Elected — safe default |

### Recommended Fixes for Tier 1

**Safe to bulk-set `is_appointed_position = false` (elected):**
- All `title IN ('City Council Member', 'Indiana Elected Official', 'Assembly Member', 'School Board Member', 'Mayor', 'U.S. Representative', 'State Senator', 'Sheriff', 'Councilmember', 'Council - At Large', 'District Attorney', 'Council Member', 'Representative', 'Senator')` where `is_appointed_position IS NULL`

**Must investigate before setting:**
- `Judge` — need to check government_name to distinguish IN Supreme Court/Appeals/Tax Court (appointed) vs circuit/superior (elected in IN)
- `Superior Court Judge` — CA superior court: judges are elected, but vacancies are appointed by Governor; currently serving appointed judges should have `is_appointed = true`
- `Treasurer`, `City Attorney`, `City Clerk` — some are appointed positions in certain cities

**Existing Bloomington data (the 9 manually-entered appointed officials):**
- Correctly classified as `is_appointed_position = true` — these are the city officials added to demonstrate the filter
- Include: City Clerk, City Attorney, Director of Public Works, Chief of Police, City Controller, City Engineer, Building Commissioner, Corporation Counsel, Director of Utilities

---

## Tier 2: Politician-Level Findings

### Direct Mismatches

There is **1 direct mismatch** between `politicians.is_appointed` and `offices.is_appointed_position`:

| Politician | ID | politician.is_appointed | office.is_appointed_position | Office | Government |
|-----------|-----|------------------------|------------------------------|--------|------------|
| Courtney Daily | `43fd01ea-c039-4b26-87aa-49cddcb54835` | `true` | `false` | City Common Council - District 5 | City of Bloomington, Indiana, US |

**Analysis:** Courtney Daily was sworn in March 2024 as an **interim appointee** to the Bloomington Common Council District 5 seat (per her bio_text), following Shruti Rana's relocation. The office is a normally-elected position (`is_appointed_position = false`), but Daily was appointed to fill the vacancy. This is a legitimate edge case — interim appointment to an elected seat.

**Recommended Fix:** Keep `offices.is_appointed_position = false` (the seat is elected by nature). Keep `politicians.is_appointed = true` (Daily was individually appointed, not elected). The Phase 100 filter UI should display her under "Appointed" due to her personal appointment status. This requires the filter to use `politicians.is_appointed` for individual display, not just `offices.is_appointed_position`.

### Politicians with NULL Office Classification

77,603 active politicians have `office.is_appointed_position IS NULL`. As analyzed in Tier 1, the vast majority (77,098) are BallotReady campaign finance records that will never appear in address-based searches. The remaining 503–505 are real officials (manual-source LA officials and 1 inform-migration entry for Nanette Barragan).

**Nanette Barragan** (inform-migration): US Representative from CA-44, no office FK. Her record is correct — she was migrated from the inform tier and doesn't have a linked office record. Not an actionable issue for Phase 100 since she appears via geofence, where `is_appointed_position` defaults via COALESCE to `false` (elected), which is correct.

---

## Backfill Plan

### Priority 1 — Block Phase 100 (Must fix before filter UI ships)

**P1-A: Fix Courtney Daily mismatch**
The filter logic must handle the interim-appointment-to-elected-seat case:
- The filter should check `politicians.is_appointed` first; if NULL, fall back to `offices.is_appointed_position`
- This is a **code fix** in the filter service, not a data fix
- Affected: 1 politician (Courtney Daily, `43fd01ea-c039-4b26-87aa-49cddcb54835`)
- Fix location: Phase 100 filter service implementation

**P1-B: Classify Judge offices**
141 offices with title "Judge" have NULL `is_appointed_position`. In Indiana and California:
- IN Supreme Court, Court of Appeals, Tax Court judges: `is_appointed_position = true` (and `faces_retention_vote = true` when that column is added)
- IN Circuit and Superior Court judges: `is_appointed_position = false` (elected in partisan elections)
- CA Superior Court judges: `is_appointed_position = false` (elected), but vacancies appointed by Governor
- The specific judges need identification by government_name before bulk update

**P1-C: Classify Superior Court Judge offices**
29 offices with title "Superior Court Judge" have NULL `is_appointed_position`. These are likely CA Superior Court judges (elected) — should be `is_appointed_position = false`.

### Priority 2 — Should Fix (before Phase 100 wide rollout)

**P2-A: Bulk set elected positions**
The following titles are safe to bulk-set `is_appointed_position = false` where currently NULL:
```sql
-- Safe bulk update (verify governments first with a SELECT count)
UPDATE essentials.offices o
SET is_appointed_position = false
WHERE o.is_appointed_position IS NULL
  AND o.title IN (
    'City Council Member', 'Indiana Elected Official', 'Assembly Member',
    'School Board Member', 'Mayor', 'U.S. Representative', 'State Senator',
    'Sheriff', 'Councilmember', 'Council - At Large', 'District Attorney',
    'Council Member', 'Representative', 'Senator', 'State Representative',
    'City Council', 'Assembly Member', 'State Assembly Member'
  )
  -- Only target records with real government linkage (not campaign finance records)
  AND EXISTS (
    SELECT 1 FROM essentials.chambers ch
    WHERE ch.id = o.chamber_id
  );
```
**Estimated count:** ~3,000–3,200 offices (safe to fix without manual review)

**P2-B: Address BallotReady campaign finance records**
77,098+ politicians with `data_source IS NULL` and no office linkage are campaign finance records (PACs, ballot measure committees) incorrectly flagged `is_active = true`. Phase 100 filter must not include these. They are naturally excluded from `getRepresentativesByAddress` due to missing geofence linkage, but `is_active` cleanup would improve data hygiene.

**Recommendation:** Add `WHERE p.office_id IS NOT NULL` or `WHERE ch.id IS NOT NULL` to any new filter queries to explicitly exclude orphaned records.

### Priority 3 — Investigate (manual research required)

**P3-A: Treasurer and City Attorney offices**
Some cities appoint these roles, others elect them. Requires per-government review to classify correctly.

**P3-B: IN Supreme Court / Court of Appeals / Tax Court offices**
These need `is_appointed_position = true` AND `faces_retention_vote = true` (once that column is added in Phase 97 plan 03). Requires identifying the specific office IDs for these courts by querying by government_name.

**P3-C: Manual-source officials with no office FK**
503 manual-source politicians have `is_appointed_position IS NULL` on their offices. The majority appear to have names matching the format of LA County judges (e.g., "Alexander C.D. Giza", "Alfred A. Coletta"). These officials have office records but without government linkage (NULL government_name in the audit). They need manual review to determine correct classification.

---

## Phase 100 Readiness

### Filter Implementation Notes

The elected/appointed filter in Phase 100 must:

1. **Use `getRepresentativesByAddress` as the base query** — this naturally excludes campaign finance records via geofence join
2. **Check `politicians.is_appointed` first** for individual cases (interim appointments like Courtney Daily)
3. **Fall back to `offices.is_appointed_position`** for office-level classification
4. **Handle `faces_retention_vote`** once added in Plan 03 — retention judges appear under both Elected and Appointed

Suggested filter logic:
```typescript
// In filter service
const effectiveIsAppointed =
  politician.is_appointed !== null
    ? politician.is_appointed                    // individual override (interim appointment)
    : office.is_appointed_position !== null
    ? office.is_appointed_position               // office-level classification
    : false;                                     // NULL defaults to elected (COALESCE behavior)
```

### Readiness Checklist

- [ ] All Priority 1 fixes applied (P1-A code fix + P1-B/C judge classification)
- [ ] Priority 2 bulk update applied for safe elected-position titles
- [ ] Filter service implements politician.is_appointed-first logic
- [ ] Filter tested with Courtney Daily (should appear under Appointed despite elected office)
- [ ] Filter tested with Bloomington city council (elected) and city clerk/attorney (appointed)

**Estimated backfill effort:** Medium
- P1-A (code fix): 2-4 hours
- P1-B/C (judge classification): 4-8 hours (need to identify IN and CA judge office IDs)
- P2-A (bulk elected update): 1-2 hours (write + verify SELECT, then UPDATE)
- P2-B (campaign finance cleanup): separate data hygiene task, not blocking Phase 100

### Overall Assessment

The Phase 100 filter UI is **not blocked** by the is_appointed data issues, provided:
1. The filter uses geofence-based search (natural campaign finance exclusion)
2. The filter logic uses politician-first appointment checking
3. Judge offices are classified before wide rollout

The Bloomington demo use case is well-covered: 1,277 well-classified officials include all the Bloomington city officials that the filter UI will be demonstrated with.
