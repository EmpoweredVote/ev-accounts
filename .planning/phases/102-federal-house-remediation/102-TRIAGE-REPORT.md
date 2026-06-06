# Phase 102 — House Triage Report

Generated: 2026-06-06 02:15:17 UTC

---

## Executive Summary

### NATIONAL_LOWER (US House Representatives)

| Metric | Value |
|--------|-------|
| total_politicians | 122 |
| total_stances | 830 |
| unsourced_stance_count | 0 |
| weak_stance_count | 0 |
| Representatives flagged | 0 |
| — unsourced_only | 0 |
| — weak_only | 0 |
| — both | 0 |

### NATIONAL_UPPER_DEFERRED (2026 Senate Candidates — deferred from Phase 101)

| Metric | Value |
|--------|-------|
| total_politicians | 43 |
| total_stances | 719 |
| unsourced_stance_count | 0 |
| weak_stance_count | 19 |
| Candidates flagged | 3 |
| — unsourced_only | 0 |
| — weak_only | 3 |
| — both | 0 |

---

## Methodology

**Sourced definition (locked Phase 100 — D-01):**
A stance counts as sourced when ALL of the following are true:
1. A row exists in `inform.politician_context` with the same `(politician_id, topic_id)` composite key.
2. `sources` is NOT NULL.
3. `array_length(sources, 1)` is NOT NULL (Postgres returns NULL for empty arrays).
4. At least one element of `sources` passes `url IS NOT NULL AND trim(url) <> ''`.

**Weak-source detection:**
A sourced row is classified as "weak" when every non-blank URL matches the homepage-only pattern:
`^https?://[^/]+/?$`
(domain root with no path, e.g. `https://www.senator.gov`).
Applied via Postgres `~` operator against every non-blank element of `inform.politician_context.sources`.

**Dual scope:**
- `NATIONAL_LOWER`: `essentials.offices JOIN essentials.districts WHERE district_type = 'NATIONAL_LOWER'`
  with `DISTINCT ON (politician_id)` to prevent multi-office Cartesian inflation.
  Active politicians only (`p.is_active = true`). No `is_incumbent` filter (all active NATIONAL_LOWER are incumbents per live DB state).
- `NATIONAL_UPPER_DEFERRED`: `district_type = 'NATIONAL_UPPER' AND p.is_incumbent = false`
  — captures the 3 Senate candidates (Dooley, Shoffner, Alme) deferred from Phase 101.
  Their `is_vacant = false` office records caused them to appear in Phase 101 NATIONAL_UPPER queries;
  their homepage-only sources drove V2 = 19 in 101-VERIFICATION.md.

---

## NATIONAL_LOWER — Unsourced Stances

_No NATIONAL_LOWER representatives with unsourced stances found._


---

## NATIONAL_LOWER — Weak-Sourced Stances

_No NATIONAL_LOWER representatives with weak-sourced stances found._


---

## Deferred Candidates (NATIONAL_UPPER non-incumbent) — Unsourced Stances

_No deferred candidates with unsourced stances found._


---

## Deferred Candidates (NATIONAL_UPPER non-incumbent) — Weak-Sourced Stances

### Hallie Shoffner (AR, Democratic)

- **politician_id:** a7307f34-90ca-4d29-8698-4898ed3de05c
- **weak_count:** 5
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| campaign-finance | 2.0 | https://www.hallieshoffner.com |
| climate-change | 2.0 | https://www.hallieshoffner.com |
| economic-development | 2.0 | https://www.hallieshoffner.com |
| housing | 2.0 | https://www.hallieshoffner.com |
| taxes | 2.0 | https://www.hallieshoffner.com |

### Derek Dooley (GA, Republican)

- **politician_id:** b841a475-41b4-4f19-9ad1-13769b1f4eef
- **weak_count:** 6
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| abortion | 4.0 | https://dooleyforgeorgia.com/ |
| civil-rights | 4.0 | https://dooleyforgeorgia.com/ |
| climate-change | 4.0 | https://dooleyforgeorgia.com/ |
| healthcare | 4.0 | https://dooleyforgeorgia.com/ |
| immigration | 4.0 | https://dooleyforgeorgia.com/ |
| voting-rights | 4.0 | https://dooleyforgeorgia.com/ |

### Kurt Alme (MT, Republican)

- **politician_id:** 0f8bb5ea-8d89-4cfb-9291-04b54c128b82
- **weak_count:** 8
- **Affected topics (homepage-only source URL):**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| abortion | 5.0 | https://almeforsenate.com/ |
| fossil-fuels | 5.0 | https://almeforsenate.com/ |
| religious-freedom | 5.0 | https://almeforsenate.com/ |
| same-sex-marriage | 5.0 | https://almeforsenate.com/ |
| social-security | 4.0 | https://almeforsenate.com/ |
| tariffs | 4.0 | https://almeforsenate.com/ |
| trans-athletes | 4.0 | https://almeforsenate.com/ |
| voting-rights | 4.0 | https://almeforsenate.com/ |



---

## Combined Target List

| full_name | politician_id | scope | state | party | total_stances | unsourced_count | weak_count | classification | affected_topic_keys |
|-----------|---------------|-------|-------|-------|---------------|-----------------|------------|----------------|--------------------|
| Hallie Shoffner | a7307f34-90ca-4d29-8698-4898ed3de05c | NATIONAL_UPPER_DEFERRED | AR | Democratic | 11 | 0 | 5 | weak_only | campaign-finance, climate-change, economic-development, housing, taxes |
| Derek Dooley | b841a475-41b4-4f19-9ad1-13769b1f4eef | NATIONAL_UPPER_DEFERRED | GA | Republican | 12 | 0 | 6 | weak_only | abortion, civil-rights, climate-change, healthcare, immigration, voting-rights |
| Kurt Alme | 0f8bb5ea-8d89-4cfb-9291-04b54c128b82 | NATIONAL_UPPER_DEFERRED | MT | Republican | 13 | 0 | 8 | weak_only | abortion, fossil-fuels, religious-freedom, same-sex-marriage, social-security, tariffs, trans-athletes, voting-rights |


---

## Plan 02 Scoping

**NATIONAL_LOWER flagged (FEDX-02 V1):** 0 — FEDX-02 V1 trivially passes (0 unsourced/weak House stances)
**Deferred candidates flagged (NATIONAL_UPPER_DEFERRED):** 3 candidates, 19 total weak stances


**Recommended batching: 1 research plan** (3 deferred candidates ≤ 10 threshold — per 102-RESEARCH.md Phase Plan Structure)
- 1 research plan covers all 3 deferred candidates (one research-stances agent dispatch per candidate)
- Dispatch order: Dooley (GA, 6 weak topics), Shoffner (AR, 5 weak topics), Alme (MT, 8 weak topics)

Machine-readable target list: `102-HOUSE-TARGETS.csv`
