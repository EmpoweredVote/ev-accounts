# Phase 100 — Source Coverage Audit Report

Generated: 2026-06-05 20:49:04 UTC

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Stances | 13920 |
| Sourced Stances | 13890 |
| Unsourced Stances | 30 |
| % Sourced | 99.8% |

---

## Tier Breakdown

| Tier | Total Stances | Sourced | Unsourced | % Sourced |
|------|--------------|---------|-----------|-----------|
| Federal | 3915 | 3914 | 1 | 100.0% |
| State | 6891 | 6875 | 16 | 99.8% |
| City | 215 | 210 | 5 | 97.7% |
| Local | 2195 | 2187 | 8 | 99.6% |
| Unknown | 704 | 704 | 0 | 100.0% |

---

## Milestone Cohorts

| Cohort | Total Stances | Sourced | Unsourced | % Sourced |
|--------|--------------|---------|-----------|-----------|
| v2.3 — US Senators (100 senators) | 3040 | 3039 | 1 | 100% |
| v2.4 — 2026 Senate Candidates (43 candidates) | 719 | 719 | 0 | 100% |
| v2.5 — City Officials (SF, SJ, SD, Berkeley, Fremont) | 893 | 893 | 0 | 100% |
| Migrations 269–271 — MD Officials (Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis) | 0 | 0 | 0 | 0.0 (0 stances — Phase 103 STAX-02 scope)% |

---

## "Sourced" Definition

A stance in `inform.politician_answers` counts as **sourced** for v2.7 Source Integrity when ALL of the following are true:

1. A row exists in `inform.politician_context` with the same `(politician_id, topic_id)` composite key.
2. `sources` is NOT NULL (defensive; schema default is `'{}'` but early rows cannot be assumed).
3. `array_length(sources, 1)` is NOT NULL — Postgres returns NULL for empty arrays, not 0. This detects the `ARRAY[]::text[]` pattern used in migrations where no evidence was found (confirmed in migration 233: 2 CA Assembly stances).
4. At least one element of `sources` passes `url IS NOT NULL AND trim(url) <> ''` — eliminates blank-string array elements.

Conditions that make a stance **unsourced**:
- Missing context row (orphan answer — no matching row in `politician_context`)
- Context row exists but `sources = ARRAY[]::text[]` (empty array)
- Context row exists but `sources IS NULL`
- Context row exists but all elements are blank strings

**Weak sources** (counted as sourced, noted separately): Context rows where the only non-blank URL is a domain root with no path (e.g., `https://sd07.senate.ca.gov`). These technically pass the four-rule test above but may lack specific evidence. Count: **107** rows. Remediation phases 101–104 should evaluate these under QUAL-01 ("URL links to a primary source").

This definition is locked for all v2.7 remediation phases (101–104). Every phase that sources a stance or deletes one must apply this same standard.

---

## Weak Sources Note

**107** stance(s) have a context row with at least one non-blank URL, but every non-blank URL matches the homepage-only pattern `^https?://[^/]+/?$` (a domain root with no path component, e.g., `https://sd07.senate.ca.gov`).

These rows are counted as **sourced** in all totals above. Phases 101–104 should review these rows against QUAL-01: "every updated or added stance links to a primary source that contains specific evidence of the politician's position." A homepage URL alone does not satisfy QUAL-01.

**Recommendation for remediation phases:** Filter target politicians by checking whether any of their sourced URLs match the homepage pattern. Treat homepage-only rows as low-confidence sources during the Chair methodology re-verification step.

---

## MD Officials (Migrations 269–271)

The following 5 Maryland state executive officials were added in migrations 269 (chambers), 270 (politicians + offices), and 271 (headshots). As of this audit, they have zero stance rows in `inform.politician_answers`. They are **not** included in the TARGET-LIST.csv (which lists politicians with at least one unsourced stance). Their research is scoped to Phase 103, requirement STAX-02.

MD official names in plan references: Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis.
DB full_names (with middle initials where applicable): see table below.

| Full Name (DB) | Politician ID | Stance Count | Expected State | Note |
|----------------|---------------|-------------|----------------|------|
| Wes Moore | 21e534c8-c0c0-42f5-b52b-5eb2f246d632 | 0 | MD | No stances yet — Phase 103 STAX-02 scope |
| Aruna Miller | ea9fc2d6-3b26-469a-978c-e8c846d2d49a | 0 | MD | No stances yet — Phase 103 STAX-02 scope |
| Anthony G. Brown | 60329719-1d5b-4bb4-8295-38ea18f6f378 | 0 | MD | No stances yet — Phase 103 STAX-02 scope |
| Brooke Lierman | b26fb5d2-90eb-4108-8ce5-838df719473d | 0 | MD | No stances yet — Phase 103 STAX-02 scope |
| Dereck E. Davis | 75378a96-8886-46eb-b0c1-37cbe2579265 | 0 | MD | No stances yet — Phase 103 STAX-02 scope |

**Phase 103 action (STAX-02):** Research stances from scratch for all 5 officials using the Chair methodology. Every added stance must have a context row with at least one real primary source URL.

---

## Methodology Notes

- **Database:** Live Supabase production database (connection via `DATABASE_URL` in `backend/.env`)
- **Run date:** 2026-06-05 20:49:04 UTC
- **Query patterns:** See `100-RESEARCH.md` Patterns 1–5 for the SQL templates used here
- **All queries use `pool.query()`** — the `inform` schema is not in the PostgREST exposed schema list; PostgREST calls silently fail for `inform.*`
- **Active politicians only:** All queries filter `WHERE p.is_active = true` to exclude historical/inactive records
- **Tier classification source:** `essentials.districts.district_type` via offices join — never from `essentials.offices.title` (title="Senator" matches both US and State senators)
- **DISTINCT ON in tier subquery:** Prevents multi-office Cartesian product inflation (a politician with multiple office rows produces only one tier assignment, using the highest-priority tier rank)
- **City vs Local distinction in Tier Breakdown:** City = LOCAL/LOCAL_EXEC district where `essentials.governments.name ILIKE 'City of %'` AND `government_id` is NOT NULL. NOTE: CA city officials (SF, SJ, SD, Berkeley, Fremont) do NOT have `government_id` set on their districts — they appear as "Local" in the tier breakdown, not "City". The "City" rows in the tier breakdown reflect TX cities (Plano, McKinney, Frisco, Allen, Richardson, etc.) which do have `government_id` populated.
- **Cohort scoping:**
  - v2.3 senators: `district_type = 'NATIONAL_UPPER'`
  - v2.4 candidates: `external_id BETWEEN -400143 AND -400101`
  - v2.5 city officials: `external_id BETWEEN -689999 AND -630000 EXCEPT -669999 TO -660000` (blocks 63=SF, 64=SJ, 65=SD, 67=Fremont, 68=Berkeley; block 66=Sacramento excluded). CA city districts lack `government_id` so government-name joins fail; external_id ranges are authoritative.
  - MD officials: `external_id BETWEEN -240005 AND -240001`
