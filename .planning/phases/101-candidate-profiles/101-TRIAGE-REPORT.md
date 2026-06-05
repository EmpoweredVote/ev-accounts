# Phase 101 — Senator Triage Report

Generated: 2026-06-05 22:45:00 UTC

---

## Executive Summary

| Metric | Value |
|--------|-------|
| total_senators | 100 |
| total_stances | 2321 |
| unsourced_stance_count | 1 |
| weak_stance_count | 0 |
| Senators flagged | 1 |
| — unsourced_only | 1 |
| — weak_only | 0 |
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

**Senate scope:**
`essentials.offices JOIN essentials.districts WHERE district_type = 'NATIONAL_UPPER'`
with `DISTINCT ON (politician_id)` to prevent multi-office Cartesian inflation.
Active politicians only (`p.is_active = true`).

---

## Unsourced Senator Stances

### Deb Fischer (NE, Republican)

- **politician_id:** 3149d855-8d85-4080-b0d6-fb83be500533
- **unsourced_count:** 1
- **Affected topics:**

| topic_key | current_value | current_sources |
|-----------|---------------|----------------|
| ai-regulation | 3.0 | _(none)_ |



---

## Weak-Sourced Senator Stances

_No senators with weak-sourced stances found._


---

## Combined Target List

| full_name | politician_id | state | party | total_stances | unsourced_count | weak_count | classification | affected_topic_keys |
|-----------|---------------|-------|-------|---------------|-----------------|------------|----------------|--------------------|
| Deb Fischer | 3149d855-8d85-4080-b0d6-fb83be500533 | NE | Republican | 20 | 1 | 0 | unsourced_only | ai-regulation |


---

## Plan 02 Scoping Note

**Senators flagged (requiring research):** 1
- unsourced_only: 1
- weak_only: 0
- both (unsourced + weak): 0

**Recommended batching:** 1 plan (≤10 senators) (per D-03 thresholds: ≤10 = 1 plan, 11–25 = 2 plans, 26+ = 3 plans)

Machine-readable target list: `101-SENATOR-TARGETS.csv`
