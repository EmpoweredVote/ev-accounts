# Phase 101 — Deferred Items

Discovered during Phase 101 execution but outside Phase 101 scope.

---

## Homepage-Only Sources for 2026 Senate Candidates

**Discovered:** 2026-06-06 (Task 4 — FEDX-01 V2 query returned 19, not 0)

**Issue:** 19 stance context rows for 2026 Senate candidates have homepage-only source URLs that fail the V2 verification query. These politicians appear in the NATIONAL_UPPER query because their `is_vacant = false` office records match the senator subquery.

| Politician | State | Homepage URL | Topics |
|------------|-------|-------------|--------|
| Derek Dooley | GA | https://dooleyforgeorgia.com/ | abortion, civil-rights, climate-change, healthcare, immigration, voting-rights (6) |
| Hallie Shoffner | AR | https://www.hallieshoffner.com | campaign-finance, climate-change, economic-development, housing, taxes (5) |
| Kurt Alme | MT | https://almeforsenate.com/ | abortion, fossil-fuels, religious-freedom, same-sex-marriage, social-security, tariffs, trans-athletes, voting-rights (8) |

**Root cause:** These are 2026 Senate candidates added in Phase 76 (v2.4). Their `essentials.offices.is_vacant = false` causes them to appear alongside current senators in the NATIONAL_UPPER query. Their stance context rows have campaign website homepages as the sole source URL.

**Why not fixed in Phase 101:**
- Phase 101 scope is limited to the 1 target identified by Plan 01 triage (Deb Fischer / ai-regulation / unsourced)
- These 19 rows are from the 107 homepage-only rows documented in Phase 100's audit report
- They were present before this migration — not introduced by migration 268

**Recommended action for Phase 102:**
- Remediate Dooley, Shoffner, and Alme using the research-stances skill (all are 2026 candidates running for Senate seats)
- Or add a `is_candidate` boolean to `essentials.politicians` / `essentials.offices` to distinguish current officeholders from future candidates in the verification query scope
- Coordinate with Phase 102 planning to ensure these three candidates are included in the House/candidate remediation scope
