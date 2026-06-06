# Phase 103 — CA State Source Triage Report

Generated: 2026-06-06 06:42:48 UTC

---

## Pre-flight discoveries (Plan 01 Task 1)

### A. CA district_type values present in essentials.districts
[{"district_type":"COUNTY"},{"district_type":"JUDICIAL"},{"district_type":"LOCAL"},{"district_type":"LOCAL_EXEC"},{"district_type":"NATIONAL_LOWER"},{"district_type":"NATIONAL_UPPER"},{"district_type":"SCHOOL"},{"district_type":"STATE_EXEC"},{"district_type":"STATE_LOWER"},{"district_type":"STATE_UPPER"}]

State-tier types present: STATE_EXEC, STATE_LOWER, STATE_UPPER
Non-state types present (excluded): COUNTY, JUDICIAL, LOCAL, LOCAL_EXEC, NATIONAL_LOWER, NATIONAL_UPPER, SCHOOL

### B. Available state-column on essentials.districts
[{"column_name":"state"}]

Column name confirmed: `state` (not `state_code` or `state_abbr`). Task 2 uses `d.state = 'CA'`.

### C. Per-district_type CA active politician counts
[{"district_type":"COUNTY","politician_count":"3"},{"district_type":"LOCAL","politician_count":"375"},{"district_type":"LOCAL_EXEC","politician_count":"97"},{"district_type":"NATIONAL_LOWER","politician_count":"52"},{"district_type":"NATIONAL_UPPER","politician_count":"2"},{"district_type":"SCHOOL","politician_count":"383"},{"district_type":"STATE_EXEC","politician_count":"18"},{"district_type":"STATE_LOWER","politician_count":"80"},{"district_type":"STATE_UPPER","politician_count":"40"}]

State-tier breakdown:
- STATE_LOWER (CA Assembly): 80 politicians — all 80 Assembly seats present
- STATE_UPPER (CA Senate): 40 politicians — all 40 Senate seats present
- STATE_EXEC (CA statewide executives): 18 politicians — includes Governor, Lt. Governor, AG, etc.
Total CA state-tier politicians: 138

### D. Gavin Newsom district_type confirmation
[{"full_name":"Gavin Newsom","district_type":"STATE_EXEC","state":"CA"}]

Gavin Newsom's district_type is `STATE_EXEC`. This confirms that `STATE_EXEC` MUST be included in the Task 2 IN() list per CONTEXT.md D-02. Pitfall 1 (CA District Type Coverage) is averted.

### E. Final district_type IN() list for Task 2 CTE
'STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC'

Rationale:
- `STATE_LOWER`: CA Assembly (80 politicians) — required, non-negotiable
- `STATE_UPPER`: CA Senate (40 politicians) — required, non-negotiable
- `STATE_EXEC`: CA statewide executives (18 politicians, includes Gavin Newsom) — required per CONTEXT.md D-02

Excluded:
- `STATE_BOARD`: Not present in CA district records in the live DB — excluded (no rows match)
- `COUNTY`, `JUDICIAL`, `LOCAL`, `LOCAL_EXEC`, `NATIONAL_LOWER`, `NATIONAL_UPPER`, `SCHOOL`: Not state-tier — excluded per plan scope

Total CA state politicians in scope: 80 + 40 + 18 = 138

---

## Executive Summary

| Metric | Value |
|--------|-------|
| total_politicians | 137 |
| total_stances | 2184 |
| unsourced_stance_count | 6 |
| weak_stance_count | 12 |
| Politicians flagged | 11 |
| — unsourced_only | 3 |
| — weak_only | 8 |
| — both | 0 |

---

## Methodology

**Sourced definition (locked Phase 100 — D-01):**
A stance counts as sourced when ALL of the following are true:
1. A row exists in `inform.politician_context` with the same `(politician_id, topic_id)` composite key.
2. `sources` is NOT NULL.
3. `array_length(sources, 1)` is NOT NULL (Postgres returns NULL for empty arrays).
4. At least one element of `sources` passes `url IS NOT NULL AND trim(url) <> ''`.

**Weak-source detection (Phase 101 D-01):**
A sourced row is classified as "weak" when every non-blank URL matches the homepage-only pattern:
`^https?://[^/]+/?$`
(domain root with no path, e.g. `https://www.senator.gov` or `https://sd07.senate.ca.gov/`).
Applied via Postgres `~` operator against every non-blank element of `inform.politician_context.sources`.

**CA dual-detection scope (CONTEXT.md D-01):**
This triage captures both:
- (1) Politicians with unsourced stances (missing context row, empty sources array, blank URLs)
- (2) Politicians with weak-source stances (ALL non-blank URLs are homepage-only)

HAVING clause: `SUM(unsourced_case) > 0 OR COUNT(weak_case) > 0` — includes both categories.

**CA politician scope (CONTEXT.md D-02):**
`essentials.offices JOIN essentials.districts WHERE d.state = 'CA' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')`
with `DISTINCT ON (politician_id)` to prevent multi-office Cartesian inflation.
Active politicians only (`p.is_active = true`).

---

## CA — Unsourced Stances

### Gavin Newsom (STATE_EXEC, Democratic)

- **politician_id:** f26309c8-2525-49b2-bdaf-62980cbb1853
- **unsourced_count:** 4
- **Affected topics:**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| medicare/aid | 2.0 | _(none)_ |
| redistricting | 1.0 | _(none)_ |
| religious-freedom | 2.0 | _(none)_ |
| same-sex-marriage | 1.0 | _(none)_ |

### Juan Carrillo (STATE_LOWER, Democratic)

- **politician_id:** b959d608-5674-467e-a1c8-3572c76a729b
- **unsourced_count:** 1
- **Affected topics:**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| childcare | 3.0 | _(none)_ |

### Lisa Calderon (STATE_LOWER, Democratic)

- **politician_id:** 0afa998d-94e9-4af4-ba00-256c38869398
- **unsourced_count:** 1
- **Affected topics:**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| campaign-finance | 3.0 | _(none)_ |


---

## CA — Weak-Sourced Stances (homepage-only)

### Akilah Weber Pierson (STATE_UPPER, Democratic)

- **politician_id:** e5470008-3c0d-4970-a485-053621d8f0a6
- **weak_count:** 1
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| fossil-fuels | 3.0 | https://sd39.senate.ca.gov |

### Caroline Menjivar (STATE_UPPER, Democratic)

- **politician_id:** 4baa73c2-d38b-4d07-894f-1577d5ba43a3
- **weak_count:** 1
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| homelessness | 2.0 | https://sd20.senate.ca.gov/ |

### Catherine Stefani (STATE_LOWER, Democratic)

- **politician_id:** 0649630c-bd6d-40fe-8f66-e026e6f6c83e
- **weak_count:** 1
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| immigration | 2.0 | https://sd22.senate.ca.gov/ |

### Eloise Gómez Reyes (STATE_UPPER, Democratic)

- **politician_id:** 1571da4a-b832-4792-917c-184c155b1700
- **weak_count:** 3
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| campaign-finance | 3.0 | https://sd29.senate.ca.gov |
| religious-freedom | 3.0 | https://sd29.senate.ca.gov |
| ukraine-support | 2.0 | https://sd29.senate.ca.gov |

### Gregg Hart (STATE_LOWER, Democratic)

- **politician_id:** 21940b7c-2424-47e9-a649-077b0f827c2c
- **weak_count:** 1
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| homelessness | 3.0 | https://gregghart.org/ |

### Henry Stern (STATE_UPPER, Democratic)

- **politician_id:** f3671de4-514f-441c-8ad4-4a9ab7c65ae6
- **weak_count:** 3
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| religious-freedom | 3.0 | https://sd27.senate.ca.gov |
| social-security | 2.0 | https://sd27.senate.ca.gov |
| ukraine-support | 2.0 | https://sd27.senate.ca.gov |

### Natasha Johnson (STATE_LOWER, Republican)

- **politician_id:** 3f200d93-74aa-4191-a275-77b64ff5b219
- **weak_count:** 1
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| school-vouchers | 5.0 | https://natashajohnsonforassembly.com |

### Rob Bonta (STATE_EXEC, Democratic)

- **politician_id:** 8b183a30-3afb-4d9e-aa40-aa2ad2c674aa
- **weak_count:** 1
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| ukraine-support | 2.0 | https://oag.ca.gov |


---

## Combined Target List

| full_name | district_type | party | unsourced_count | weak_count | classification | affected_topic_keys |
|-----------|---------------|-------|-----------------|------------|----------------|--------------------|
| Gavin Newsom | STATE_EXEC | Democratic | 4 | 0 | unsourced_only | medicare/aid|redistricting|religious-freedom|same-sex-marriage |
| Juan Carrillo | STATE_LOWER | Democratic | 1 | 0 | unsourced_only | childcare |
| Lisa Calderon | STATE_LOWER | Democratic | 1 | 0 | unsourced_only | campaign-finance |
| Akilah Weber Pierson | STATE_UPPER | Democratic | 0 | 1 | weak_only | fossil-fuels |
| Caroline Menjivar | STATE_UPPER | Democratic | 0 | 1 | weak_only | homelessness |
| Catherine Stefani | STATE_LOWER | Democratic | 0 | 1 | weak_only | immigration |
| Eloise Gómez Reyes | STATE_UPPER | Democratic | 0 | 3 | weak_only | campaign-finance|religious-freedom|ukraine-support |
| Gregg Hart | STATE_LOWER | Democratic | 0 | 1 | weak_only | homelessness |
| Henry Stern | STATE_UPPER | Democratic | 0 | 3 | weak_only | religious-freedom|social-security|ukraine-support |
| Natasha Johnson | STATE_LOWER | Republican | 0 | 1 | weak_only | school-vouchers |
| Rob Bonta | STATE_EXEC | Democratic | 0 | 1 | weak_only | ukraine-support |


---

## Plan 02 Scoping

**Total CA politicians flagged:** 11
- unsourced_only: 3
- weak_only: 8
- both: 0

**Recommended batching: 2 research plans (11–25 threshold — split alphabetically or by district_type)**

Machine-readable target list: `.planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv`
