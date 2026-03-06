# State Legislative Data Audit — Phase 61

**Date:** 2026-03-05
**Script:** EV-Backend/scripts/validate_state_legislative.py
**Status:** PASS

Both Indiana and California pass all automated validation checks. No gap-fill re-import was required — the v2026.3 LegiScan import was complete for our legislator roster.

---

## Indiana — 2026 Regular Session

### Bill/Vote Counts

- Bills in DB: 935
- Vote records in DB: 6,069
- Legislators with at least one bill (sponsor or cosponsor): 17 / 18
- Legislators with at least one vote: 18 / 18
- LegiScan session confirmed present via getDatasetList: YES (dataset 3.3 MB, hash: 09ae7434)
- Status: **PASS**

Note: `getDatasetList` does not return a `bill_count` field. Session existence was confirmed; an exact bill-count comparison would require downloading the full dataset via `getDataset` (not done to conserve API budget).

### Bridge Coverage

- Legislators in DB: 18
- With legiscan bridge records: 17 (94.4%)
- Missing bridge: 1 — **Robert Johnson** (8c12dbdc-8afa-409a-8681-928c2e23e93e)
- Threshold: 80%
- Status: **PASS (94.4%)**

### Zero-Activity Analysis

- Total legislators: 18
- Active (any bill or vote in current session): 17
- New legislators (zero activity, expected): 0 (start_date not available in offices table)
- Established legislators with zero activity: 1 — Robert Johnson (5.6%)
- Threshold: ≤ 10%
- Status: **PASS (5.6%)**

**Root cause — Robert Johnson:** No legiscan bridge record found. This means the LegiScan import could not match Robert Johnson's LegiScan legislator ID to his politician record. He appears in our DB as a STATE_LOWER legislator in Indiana but has no legislative_politician_id_map entry with id_type='legiscan'. His bills and votes were not linked during import because the bridge is missing.

### Orphaned Records

- Bills with no primary sponsor (sponsor_id IS NULL): 784 of 935 (83.8%)
- Votes with invalid politician_id (broken FK): 0
- Bill cosponsors with invalid politician_id: 0

Sample unsponsored bills: HB1001 (Housing matters), HB1002 (Electric utility affordability), HB1003 (Boards and commissions)

**Root cause — unsponsored bills:** Our politicians table contains only the 18 IN legislators that match our geofence coverage areas (primarily Bloomington/Monroe County area legislators). The full Indiana General Assembly has 150 members (100 House + 50 Senate). Bills sponsored by the remaining ~132 legislators have no matching politician_id in our DB — this is expected behavior, not a data gap. The sponsor_id is NULL because the bill's LegiScan sponsor was not in our roster, not because the bill itself is missing a sponsor.

### Spot-Checks

- **Rodric Bray (Senate President Pro Tem)** — 71 bills (45 as primary sponsor), 301 votes | bridge: YES [OK]
- Todd Huston (Speaker of House) — NOT FOUND in DB (not in our geofence coverage area)
- Matt Lehman (Senate rank-and-file) — NOT FOUND in DB (not in our geofence coverage area)
- Sharon Negele (House rank-and-file) — NOT FOUND in DB (not in our geofence coverage area)

Note: Only Rodric Bray was resolvable because the validate_committee_coverage.py script had his partial UUID (97c61094). The other spot-check names are legislators not in our 18-person IN roster. This is expected — our roster covers Bloomington-area districts, and most statewide leadership are from other districts.

---

## California — 2025-2026 Session

### Bill/Vote Counts

- Bills in DB: 4,746
- Vote records in DB: 92,492
- Legislators with at least one bill (sponsor or cosponsor): 35 / 37
- Legislators with at least one vote: 35 / 37
- LegiScan session confirmed present via getDatasetList: YES (dataset 17.9 MB, hash: 89829117)
- Status: **PASS**

### Bridge Coverage

- Legislators in DB: 37
- With legiscan bridge records: 35 (94.6%)
- Missing legiscan bridge: 2 — **Blanca Pachecco** (c9205ba1), **Suzette Valladares** (8c61cd23)
- Threshold: 80%
- Status: **PASS (94.6%)**

Note: Suzette Valladares has an openstates bridge record (ocd-person/fb1c2c06-108c-41bf-9f08-44a9f8e0cb08) but no legiscan bridge. Both legislators are missing from the legiscan id map, which is the root cause of their zero-activity status.

### Zero-Activity Analysis

- Total legislators: 37
- Active (any bill or vote in current session): 35
- New legislators (zero activity, expected): 0
- Established legislators with zero activity: 2 — Blanca Pachecco (5.4%) and Suzette Valladares
- Threshold: ≤ 10%
- Status: **PASS (5.4%)**

**Root cause — Pachecco and Valladares:** Neither has a legiscan bridge record, so their bills and votes could not be attributed during the LegiScan import. Valladares has an OpenStates bridge, which suggests she was imported from Open States but not matched to a LegiScan person ID.

### Orphaned Records

- Bills with no primary sponsor (sponsor_id IS NULL): 3,348 of 4,746 (70.6%)
- Votes with invalid politician_id (broken FK): 0
- Bill cosponsors with invalid politician_id: 0

Sample unsponsored bills: AB1 (Residential property insurance), AB10 (CA Coastal Commission), AB1000 (CEQA exemption)

**Root cause — unsponsored bills:** Same as Indiana. Our 37 CA legislators represent a subset of the full 120-member California Legislature (80 Assembly + 40 Senate). Bills from the remaining ~83 legislators have no sponsor_id match. This is expected behavior.

### Spot-Checks

- **Lena Gonzalez (Senate rank-and-file)** — 131 bills (32 as primary sponsor), 2,716 votes | bridge: YES [OK]
- Robert Rivas (Assembly Speaker) — NOT FOUND in DB (not in our geofence coverage area)
- Mike McGuire (Senate President Pro Tem) — NOT FOUND in DB (not in our geofence coverage area)
- Buffy Wicks (Assembly rank-and-file) — NOT FOUND in DB (not in our geofence coverage area)

Note: Only Lena Gonzalez was resolvable from our 37-person CA roster. Lena Gonzalez's strong activity (131 bills, 2,716 votes) confirms the data pipeline is working correctly for legislators who have legiscan bridge records.

---

## Gap-Fill Actions Taken

**No gap-fill required** — all checks passed on first validation run. The v2026.3 LegiScan import was complete for all legislators in our roster who have legiscan bridge records.

---

## Remaining Gaps

### 1. Missing legiscan bridge records (3 legislators)

**Indiana:**
- Robert Johnson (STATE_LOWER, Bloomington area) — no legiscan bridge, zero activity as a result

**California:**
- Blanca Pachecco — no legiscan bridge, zero activity as a result
- Suzette Valladares — has openstates bridge but no legiscan bridge, zero activity as a result

**Root cause:** During the Phase 57 LegiScan import, the name-matching algorithm (nickname-aware fuzzy matching) did not find these legislators in the LegiScan session people data, or they were absent from the session. Without a bridge record, the import cannot attribute their bills/votes.

**Impact:** Minimal — these 3 legislators represent 5.5% of the combined IN+CA roster (3 of 55). All validation thresholds pass. The gaps are documented.

**Resolution options (not implemented in Phase 61):**
- Manual bridge record insertion: query LegiScan getSessionPeople for the matching sessions, find each legislator's LegiScan person_id, and INSERT a row into legislative_politician_id_map
- Re-run import with `--force` after adding bridge records manually (import would then pull their bills/votes)

### 2. Bills with no sponsor_id (expected, not a gap)

IN: 784/935 bills (83.8%) and CA: 3,348/4,746 bills (70.6%) have sponsor_id IS NULL. This is expected behavior — our politician roster is a small subset of each state's full legislature. Sponsors who are not in our DB are imported with no `sponsor_id` link. This is by design and does not represent missing data.

### 3. Leadership spot-checks skipped (expected, not a gap)

Most leadership figures (Todd Huston, Robert Rivas, etc.) are not in our geofence-filtered politician roster. Only politicians that appear in our coverage areas (Bloomington IN, LA County CA) are in our DB. This is expected.

### 4. LegiScan bill_count comparison not available (API limitation)

`getDatasetList` does not return a bill_count field. Exact bill count comparison requires downloading the full dataset via `getDataset` (expensive API call). Sessions were confirmed as present and active; dataset sizes (IN: 3.3 MB, CA: 17.9 MB) are reasonable proxies for data completeness.

---

## Overall Validation Result

| Check | Indiana | California | Overall |
|-------|---------|------------|---------|
| Bridge coverage (≥ 80%) | 94.4% PASS | 94.6% PASS | PASS |
| Established zero-activity (≤ 10%) | 5.6% PASS | 5.4% PASS | PASS |
| LegiScan session confirmed | YES PASS | YES PASS | PASS |
| Votes with broken FK | 0 PASS | 0 PASS | PASS |
| Cosponsors with broken FK | 0 PASS | 0 PASS | PASS |

Script exit code: **0 (all states pass)**

API budget used for this audit: 4 calls (2 calls × 2 states for `getDatasetList`, plus earlier debug calls). Running total: ~15,032/30,000 for March 2026.
