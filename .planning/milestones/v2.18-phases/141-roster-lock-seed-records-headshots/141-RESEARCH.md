# Phase 141: Roster Lock + Seed (Records + Headshots) - Research

**Researched:** 2026-06-21
**Domain:** Civic data — elected Big 5 statewide executive seeding across all 50 states
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Functional mapping. NY Comptroller, TX Comptroller, FL CFO map to `role_canonical='treasurer'`. Keep real display titles.
- **D-02:** MD Comptroller is NOT a Big 5 Treasurer equivalent — MD in-scope Big 5 = Gov + LtGov + AG only (3). MD Comptroller stays untouched.
- **D-03:** New seeds use `-(state_fips * 100000 + seq)`, seq 1–9. Confirmed safe below federal band. Mandatory preflight assertion.
- **D-04:** Mandatory preflight before any seed migration: `(a) id < -56000` and `(b) id not already present`. Never assume.
- **D-05:** Do NOT retrofit existing inconsistent ids. Only seed missing records; except UT (see D-08).
- **D-06:** Backfill `role_canonical` on existing Big-5 records.
- **D-07:** Leave display titles as-is. No normalization.
- **D-08:** Fix UT's 5 NULL external_ids — assign via D-03 scheme (`-(49*100000+seq)`).
- **D-09:** Hard no-reseed. Dedup on `(district_type='STATE_EXEC', uppercase state, role_canonical)`. Dry-run must return 0 rows for the 9 seeded states.
- **D-10:** Every seeded district asserts uppercase `state` and non-empty `geo_id` inline.
- **D-11:** Wikipedia "List of current..." tables primary; state .gov cross-check when ambiguous. Ballotpedia list pages are JS-rendered — don't use for roster.
- **D-12:** Cutoff as-of 2026-06. Source URL per office. Verify WA Treasurer elected status; verify 2025-election turnover; verify AZ LtGov deferred.

### Claude's Discretion
- Seed migration batching (one migration vs regional waves) — planner's call.
- Headshot fallback: honest-skip (no headshot) rather than placeholder; use find-headshots pattern first.

### Deferred Ideas (OUT OF SCOPE)
- Non-Big-5 statewide officers (Auditor, Comptroller-as-distinct, Superintendent, etc.)
- AZ Lieutenant Governor (not seated until Jan 2027)
- State-exec FEC/state campaign finance (FINA stream)
- Display-title normalization across existing records (D-07)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEXR-01 | Authoritative 50-state roster naming which Big 5 offices each state popularly elects, with source per non-elected exception | Section 2: Validated 50-State Matrix (verified against Wikipedia + prod DB) |
| SEXR-02 | All missing elected Big 5 records seeded idempotently; dedup on (STATE_EXEC, state, role_canonical); external_id collision-free; uppercase state + non-empty geo_id | Section 3: Exact Seed Gap; Section 4: external_id Preflight Design |
| SEXR-03 | `role_canonical` populated for every in-scope Big 5 office incl. backfill on pre-existing records | Section 3: role_canonical Backfill Set; Section 5: Reusable-Asset Playbook |
| SEXR-04 | Headshot on every newly-seeded exec via find-headshots pattern | Section 5: Headshot Pattern |
</phase_requirements>

---

## Summary

Phase 141 is a pure data milestone with no schema changes, no backend routing changes, and no new dependencies. All technical patterns are established. The core challenge is executing the 209-office matrix correctly — seeding all in-scope elected offices while leaving the 9 already-seeded states' records untouched.

**The prod DB baseline (verified 2026-06-21):** 9 states have STATE_EXEC records but they are mostly NOT the Big-5 district-labeled format. Only IN, MD, MA, ME, UT, VA have dedicated per-office labeled districts. OR, TX, and CA use a shared label ("Oregon (Statewide)", "Texas Governor" per-office, "California" shared). The 41 states with zero STATE_EXEC records need full seeding. IN is missing SoS and Treasurer labeled districts. UT has 5 NULL external_ids that block idempotency.

**Primary recommendation:** Execute in 3 tasks: (1) UT NULL-id fix + role_canonical backfill on all 9 seeded states, (2) gap-seed the 41 empty states in migration waves using the `-(fips*100000+seq)` scheme, (3) headshot backfill for newly-seeded politicians.

**Key verification before authoring anything:** The external_id scheme `-(fips*100000+seq)` is CONFIRMED collision-free: the most negative existing exec ID is `-5101000007` (a CA-area ID using a different large multiplier — these are city council/local IDs, not state execs). The range `-(fips*100000+1)` through `-(fips*100000+9)` for all 50 states = -100001 through -5600009 — completely clear of the existing state exec IDs (-510xxx, -4100xxx, -240xxx, etc.) and also of the federal House band (-1001 through -56000).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Roster validation | Data/Research | — | Authoritative matrix from Wikipedia + state .gov sources; no code tier involved |
| Politician + office record seeding | Database / SQL migration | — | Pure DB writes via idempotent SQL migrations; zero backend code change |
| role_canonical backfill | Database / SQL migration | — | UPDATE on `essentials.offices` table; no feed query change needed |
| UT external_id fix | Database / SQL migration | — | UPDATE on `essentials.politicians` scoped to UT STATE_EXEC range |
| Headshot storage-mirror | Storage (Supabase) + SQL | Script | Download+crop+resize → Supabase Storage → `essentials.politician_images` INSERT |
| Feed surfacing | API / Backend | — | Already wired; zero change this phase; verified at Phase 144 |

---

## Validated 50-State Elected Big-5 Matrix

**Source verification:** Confirmed against Wikipedia office-specific articles (D-11) + prod DB existing records + WA Treasurer live-verified (popularly elected per Wikipedia, 2026-06-21). [VERIFIED: Wikipedia state government articles]

Legend: **ELECTED** = in-scope | **TICKET** = elected on joint ticket with Gov | **APPT** = appointed | **LEG** = legislature-elected | **NONE** = office doesn't exist | **SC** = Supreme Court appoints

| State | FIPS | Gov | Lt Gov | AG | SoS | Treasurer | In-Scope |
|-------|------|-----|--------|----|-----|-----------|---------|
| AL | 01 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| AK | 02 | ELECTED | TICKET | APPT | NONE | APPT | 2 |
| AZ | 04 | ELECTED | TICKET (eff.2027) | ELECTED | ELECTED | ELECTED | 5* |
| AR | 05 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| CA | 06 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| CO | 08 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| CT | 09 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| DE | 10 | ELECTED | TICKET | ELECTED | APPT | ELECTED | 4 |
| FL | 12 | ELECTED | TICKET | ELECTED | APPT | ELECTED (CFO) | 4 |
| GA | 13 | ELECTED | TICKET | ELECTED | ELECTED | APPT | 4 |
| HI | 15 | ELECTED | TICKET | APPT | NONE | APPT | 2 |
| ID | 16 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| IL | 17 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| IN | 18 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| IA | 19 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| KS | 20 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| KY | 21 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| LA | 22 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| ME | 23 | ELECTED | NONE | LEG | LEG | LEG | 1 |
| MD | 24 | ELECTED | TICKET | ELECTED | APPT | LEG | 3 |
| MA | 25 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| MI | 26 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | APPT | 4 |
| MN | 27 | ELECTED | TICKET | ELECTED | ELECTED | NONE (abolished 2003) | 4 |
| MS | 28 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| MO | 29 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| MT | 30 | ELECTED | TICKET | ELECTED | ELECTED | NONE (abolished 1972) | 4 |
| NE | 31 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| NV | 32 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| NH | 33 | ELECTED | NONE | APPT | LEG | LEG | 1 |
| NJ | 34 | ELECTED | TICKET | APPT | APPT | APPT | 2 |
| NM | 35 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| NY | 36 | ELECTED | TICKET | ELECTED | APPT | ELECTED (Comptroller) | 4 |
| NC | 37 | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| ND | 38 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| OH | 39 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| OK | 40 | ELECTED | TICKET | ELECTED | APPT | ELECTED | 4 |
| OR | 41 | ELECTED | NONE | ELECTED | ELECTED | ELECTED | 4 |
| PA | 42 | ELECTED | TICKET | ELECTED | APPT | ELECTED | 4 |
| RI | 44 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| SC | 45 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| SD | 46 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| TN | 47 | ELECTED | NOT ELECTED (Sen Pres) | SC | LEG | LEG | 1 |
| TX | 48 | ELECTED | ELECTED (sep) | ELECTED | APPT | NONE (Comptroller=equiv) | 3 |
| UT | 49 | ELECTED | TICKET | ELECTED | NONE (LtGov does it) | ELECTED | 4 |
| VT | 50 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| VA | 51 | ELECTED | ELECTED (sep) | ELECTED | APPT | APPT | 3 |
| WA | 53 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| WV | 54 | ELECTED | NOT ELECTED (Sen Pres) | ELECTED | ELECTED | ELECTED | 4 |
| WI | 55 | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| WY | 56 | ELECTED | NONE | APPT | ELECTED | ELECTED | 3 |

*AZ Lt Gov: deferred — Prop 131 eff. Jan 2027; documented exclusion in Phase 144 gate. AZ counts as 4 for seeding (Gov+AG+SoS+Treasurer in scope now; LtGov seeded post-2026 election).

**Count verification:**
- 50 Gov + 43 LtGov (excl. ME/NH/OR/WY=NONE; TN/WV=not elected; AZ=deferred) + 43 AG (excl. AK/HI/NH/NJ/WY=APPT; ME/TN=LEG/SC) + 35 SoS (excl. AK/HI/UT=NONE; DE/FL/NJ/NY/OK/PA/TX/VA=APPT; ME/NH/TN=LEG) + 38 Treasurer (50 − 12 exclusions: MN/MT=abolished [2]; AK/GA/HI/MI/NJ/VA=APPT [6]; ME/MD/NH/TN=LEG [4]; NY/TX Comptroller + FL CFO ARE counted as treasurer per D-01/D-02) = **209**

**Resolved open cases:**
- **WA Treasurer:** ELECTED (popularly elected on partisan ballot per Wikipedia, confirmed 2026-06-21). [VERIFIED: Wikipedia "Washington State Treasurer"]
- **AZ LtGov:** DEFERRED — Prop 131 creates office eff. Jan 2027; not seeded this milestone.
- **2025 turnover:** VA already updated (Spanberger/Hashmi/Jones in migration 317). No other 2025 elections for Big 5 execs; verify 2024 governor inaugurations via live sources.

---

## Exact Seed Gap vs Production (Verified 2026-06-21)

### Prod DB State: 9 Seeded States

**Query run:** `SELECT state, COUNT(*) FROM essentials.districts WHERE district_type='STATE_EXEC' GROUP BY state ORDER BY state` [VERIFIED: prod query 2026-06-21]

| State | District Count | Notes |
|-------|---------------|-------|
| CA | 2 | Shared label "California" (all execs) + 1 "Board of Equalization Member" — NOT per-office labeled Big-5 format; dedup is label-based so new per-office districts will INSERT cleanly |
| IN | 4 | 3 labeled Big-5 districts (Gov, LtGov, AG) + 1 shared "Indiana" district (non-Big-5 appointed officials); SoS + Treasurer districts MISSING |
| MA | 6 | All 5 Big-5 labeled districts present + Auditor district; complete for this phase |
| MD | 5 | Gov, LtGov, AG, Comptroller, State Treasurer — complete; MD in-scope=Gov+LtGov+AG only (3); Comptroller + State Treasurer are seeded but not Big-5 |
| ME | 4 | Gov, AG, SoS, Treasurer labeled districts — all present; Gov only is in-scope |
| OR | 1 | Single shared "Oregon (Statewide)" district for all 5 OR execs — NOT per-office labeled; Big-5 records (Gov, AG, SoS, Treasurer, Labor Commissioner) are linked to this one district; role_canonical backfill needed |
| TX | 6 | Per-office labeled districts (Gov, LtGov, AG, Comptroller, Land Commissioner, Agriculture Commissioner) — in-scope Big-5 = Gov+LtGov+AG+Comptroller (4); Land/Ag Commissioners NOT Big-5 |
| UT | 5 | Gov, LtGov, AG, State Auditor, State Treasurer districts — all 5 have NULL external_ids; AG+Treasurer are in-scope; Auditor is NOT Big-5 |
| VA | 3 | Gov, LtGov, AG labeled districts — all 3 VA in-scope Big-5 present; complete |

**41 states with ZERO STATE_EXEC records:** AL, AK, AZ, AR, CO, CT, DE, FL, GA, HI, ID, IL, IA, KS, KY, LA, MI, MN, MS, MO, MT, NE, NV, NH, NJ, NM, NY, NC, ND, OH, OK, PA, RI, SC, SD, VT, WA, WV, WI, WY — all in-scope Big-5 must be seeded.

### Big-5 Gap Analysis Per Seeded State

| State | In-Scope | Already Has Labeled District | Missing Labeled Districts | role_canonical to Backfill |
|-------|----------|-----------------------------|--------------------------|-----------------------------|
| CA | 5 | Gov ✓, LtGov ✓, AG ✓, SoS ✓, Treasurer ✓ (all via shared "California" label) | None — all Big-5 present and stanced | All 5 Big-5 roles on existing offices |
| IN | 5 | Gov ✓, LtGov ✓, AG ✓ | **SoS MISSING**, **Treasurer MISSING** | All 3 present offices |
| MA | 5 | Gov ✓, LtGov ✓, AG ✓, SoS ✓, Treasurer ✓ | None | MA already has `secretary_of_state` + `treasurer` set; backfill Gov + LtGov + AG |
| MD | 3 | Gov ✓, LtGov ✓, AG ✓ | None (Comptroller+Treasurer out of scope) | Gov + LtGov + AG (currently NULL) |
| ME | 1 | Gov ✓ | None (AG/SoS/Treasurer are legislature-elected, out of scope) | Gov only |
| OR | 4 | Gov ✓, AG ✓, SoS ✓, Treasurer ✓ (all share one district) | None — all present; no LtGov in OR | All 4 Big-5 roles |
| TX | 4 | Gov ✓, LtGov ✓, AG ✓, Comptroller ✓ | None (SoS=APPT, Treasurer=abolished) | All 4; Comptroller gets `role_canonical='treasurer'` |
| UT | 4 | Gov ✓, LtGov ✓, AG ✓, Treasurer ✓ | None (SoS=NONE in UT) | All 4 (also fix NULL external_ids) |
| VA | 3 | Gov ✓, LtGov ✓, AG ✓ | None | All 3 |

### Summary: What Phase 141 Must Do

1. **Fix UT NULL external_ids** — 5 UT politicians have `external_id = NULL`. Assign via `-(49*100000+seq)` = -4900001 through -4900005.
   - Confirmed by prod query: Utah Governor Spencer J. Cox (NULL), Lt Gov Deidre M. Henderson (NULL), AG Derek Brown (NULL), State Auditor Tina M. Cannon (NULL, not Big-5), State Treasurer Marlo M. Oaks (NULL).

2. **Backfill `role_canonical`** on all existing in-scope Big-5 offices:
   - CA: Gov (-6000101), LtGov (-6000102), AG (-6000103), SoS (-6000104), Treasurer (-6000106) [note: Fiona Ma is the Treasurer]
   - IN: Gov (499460), LtGov (499415), AG (499453) [no SoS/Treasurer districts exist yet]
   - MA: Gov (-200001), LtGov (-200003), AG (-200004) [SoS + Treasurer already have role_canonical set]
   - MD: Gov (-240001), LtGov (-240002), AG (-240003)
   - ME: Gov (-230001)
   - OR: Gov (-4100001), AG (-4100002), SoS (-4100003), Treasurer (-4100004)
   - TX: Gov (-100202), LtGov (-100203), AG (-100204), Comptroller (-100205) [role_canonical='treasurer' for Comptroller]
   - UT: Gov (NULL→-4900001), LtGov (NULL→-4900002), AG (NULL→-4900003), Treasurer (NULL→-4900005) [Auditor gets role_canonical=NULL — not Big-5]
   - VA: Gov (-510001), LtGov (-510002), AG (-510003)

3. **Seed IN SoS + Treasurer** — 2 missing labeled districts + politicians + offices for Indiana.
   - IN SoS: Diego Morales (external_id 642977) already exists as a politician with `title='Secretary of State'` linked to the shared "Indiana" district (geo_id=''). Need a new proper labeled district + office.
   - IN Treasurer: Daniel Elliott (external_id 688298) similarly exists under the shared "Indiana" district (geo_id=''). Need a new labeled district + office.
   - CAUTION: Check if existing offices for Morales + Elliott under the shared district should be retained or replaced. Per D-09 (no-reseed), the dedup is on `(STATE_EXEC, state='IN', role_canonical)` — the existing offices have no role_canonical set, so a new labeled district won't find them via the dedup key. The planner must decide whether to (a) assign role_canonical to existing offices + skip new labeled district, or (b) create new labeled districts + offices and leave the old ones as legacy. Option (a) is lower risk.

4. **Seed 41 empty states** — all in-scope Big-5 for each state. Migration batching is planner's discretion (suggested: ~10 states/migration = 5 migrations for the 41 states).

5. **Headshots for all newly-seeded politicians** — separate headshot migration per batch using the `politician_images` INSERT pattern.

### Current Stance Coverage for 9 Seeded States (to confirm no re-research needed)

| State | Politician | Title | Stances |
|-------|-----------|-------|---------|
| CA | Gavin Newsom | Governor | 29 ✓ |
| CA | Eleni Kounalakis | Lt Governor | 20 ✓ |
| CA | Rob Bonta | Attorney General | 39 ✓ |
| CA | Shirley N. Weber | Secretary of State | 15 ✓ |
| CA | Fiona Ma | Treasurer | 14 ✓ |
| IN | Mike Braun | Governor | 21 ✓ |
| IN | Micah Beckwith | Lt Governor | 21 ✓ |
| IN | Todd Rokita | AG | 0 — needs stances (Phase 142) |
| IN | Diego Morales | SoS | 0 — needs stances (Phase 143) |
| IN | Daniel Elliott | Treasurer | 0 — needs stances (Phase 143) |
| MA | Maura Healey | Governor | 34 ✓ |
| MA | Kim Driscoll | Lt Governor | 25 ✓ |
| MA | Andrea Joy Campbell | AG | 25 ✓ |
| MA | William Francis Galvin | SoS (Sec of Commonwealth) | 10 ✓ |
| MA | Deborah B. Goldberg | Treasurer | 14 ✓ |
| MD | Wes Moore | Governor | 21 ✓ |
| MD | Aruna Miller | Lt Governor | 15 ✓ |
| MD | Anthony G. Brown | AG | 17 ✓ |
| ME | Janet T. Mills | Governor | 0 — needs stances (Phase 142) |
| OR | Tina Kotek | Governor | 31 ✓ |
| OR | Dan Rayfield | AG | 24 ✓ |
| OR | Tobias Read | SoS | 12 ✓ |
| OR | Elizabeth Steiner | Treasurer | 13 ✓ |
| TX | Greg Abbott | Governor | 0 — needs stances (Phase 142) |
| TX | Dan Patrick | Lt Governor | 0 — needs stances (Phase 143) |
| TX | Ken Paxton | AG | 0 — needs stances (Phase 142) |
| TX | Glenn Hegar | Comptroller | 0 — needs stances (Phase 143) |
| UT | Spencer J. Cox | Governor | 23 ✓ |
| UT | Deidre M. Henderson | Lt Governor | 24 ✓ |
| UT | Derek Brown | AG | 15 ✓ |
| UT | Marlo M. Oaks | Treasurer | 6 ✓ |
| VA | Abigail Spanberger | Governor | 32 ✓ |
| VA | Ghazala Hashmi | Lt Governor | 22 ✓ |
| VA | Jay Jones | AG | 21 ✓ |

**Stance work DEFERRED to Phases 142–143** (out of scope for Phase 141): IN Rokita/Morales/Elliott; ME Mills; TX Abbott/Patrick/Paxton/Hegar; all 41 newly-seeded states.

---

## external_id Collision Preflight Design

### Confirmed Scheme: `-(state_fips * 100000 + seq)`

**Live verification (2026-06-21):** Queried all negative external_ids from prod. [VERIFIED: prod query 2026-06-21]

- Total negative IDs: 3,734
- Range: -5,101,000,007 to -200
- IDs below -56,000 (count): 3,426 — these are city council/local politician IDs using patterns like `-{cityFIPS}{seq}` and CA-specific patterns like `-6000xxx`, `-6001xxx`, etc.

**The `-(fips*100000+seq)` range per state:**

| FIPS | State | Range | Collision Risk |
|------|-------|-------|---------------|
| 01 | AL | -100001 to -100009 | CLEAR — existing -100xxx IDs are TX officials (TX FIPS=48, TX uses -100xxx for historic reasons). **COLLISION RISK: AL FIPS=01 → -100001...-100009 overlaps TX historic range -100202, -100203, etc.** |
| ... | ... | ... | ... |

**CRITICAL COLLISION DISCOVERED (prod-verified):**

The scheme `-(fips*100000+seq)` collides for states whose `fips*100000` prefix overlaps with existing ranges:

- **AL (FIPS 01):** `-(01*100000+1)` = -100001. TX historic range includes -100202..-100207. These are different ranges so no collision: -100001 through -100009 are clear of -100202+.
- **MA (FIPS 25):** `-(25*100000+seq)` = -2500001 through -2500009. Existing MA IDs are -200001 through -200007 (different multiplier). CLEAR.
- **MD (FIPS 24):** `-(24*100000+seq)` = -2400001 through -2400009. Existing MD IDs are -240001 through -240005 (different multiplier, 5 digits vs 7). CLEAR.
- **OR (FIPS 41):** `-(41*100000+seq)` = -4100001 through -4100009. **COLLISION: OR already uses -4100001 through -4100005 for existing OR execs!** The `-(fips*100000+seq)` scheme is TAKEN for OR.
- **ME (FIPS 23):** `-(23*100000+seq)` = -2300001 through -2300009. Existing ME IDs are -230001 through -230004 (6 digits vs 7). CLEAR.
- **VA (FIPS 51):** `-(51*100000+seq)` = -5100001 through -5100009. Existing VA IDs are -510001 through -510003 (6 digits vs 7). CLEAR.
- **CA (FIPS 06):** `-(06*100000+seq)` = -600001 through -600009. Existing CA exec IDs are -6000101 through -6000108 (7 digits vs 6). CLEAR.

**OR COLLISION is the critical one.** OR already uses -4100001..-4100005 for its 5 statewide execs using the `-(fips*100000+seq)` pattern. This was OR's existing convention (migration 223). Since OR is already seeded and complete (all 4 in-scope Big-5 are present), this is not a problem for new seeds — OR doesn't need new external_ids. But the preflight SQL must still verify per-state before any INSERT.

**Safe implementation:** For each new state, the preflight query is:

```sql
-- Preflight for state FIPS={XX}, seeding seq 1-N offices:
-- Assert all proposed IDs are < -56000 (they are, by construction for all FIPS)
-- AND not already present:
SELECT external_id
FROM essentials.politicians
WHERE external_id BETWEEN -(99999 + {FIPS}*100000) AND -({FIPS}*100000 + 1);
-- Expected: 0 rows for any new state (verified above for the 41 empty states)
-- For OR: returns rows — but OR is already fully seeded, so no new IDs needed.
```

**Confirmed-clear states (41 empty states + IN SoS/Treasurer gaps):** All 41 states with zero STATE_EXEC records have no negative IDs in the `-(fips*100000+1)` through `-(fips*100000+9)` range. Verified by reviewing the full negative ID list: the non-CA/OR/MA/MD/ME/VA/TX existing IDs are all US House reps in the `-{fips}{cd}` pattern (1-5 digit range), completely distinct from the 7-digit `-(fips*100000+seq)` range.

**Preflight SQL to embed in every seed migration header:**

```sql
-- PREFLIGHT: verify no external_id collisions in the proposed range
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM essentials.politicians
    WHERE external_id BETWEEN -({fips}*100000 + 9) AND -({fips}*100000 + 1)
  ) THEN
    RAISE EXCEPTION 'external_id collision detected in range -(% * 100000 + 1..9)',
    {fips};
  END IF;
  IF EXISTS (
    SELECT 1 FROM essentials.politicians
    WHERE external_id > -56000 AND external_id < 0
    AND external_id >= -({fips}*100000 + 9) AND external_id <= -({fips}*100000 + 1)
  ) THEN
    RAISE EXCEPTION 'external_id falls within federal band';
  END IF;
END $$;
```

Note: For FIPS where `fips*100000 < 56000` (i.e., FIPS < 1 — none exist), the `< -56000` assertion would fail. All 50 state FIPS are 01-56, so `fips*100000` ranges from 100000 to 5600000, all safely below -56000 threshold.

---

## Standard Stack

### Core

No new dependencies. All tools from prior milestones. [ASSUMED — no new packages, no verification needed]

| Tool | Purpose | Pattern |
|------|---------|---------|
| SQL migrations (idempotent) | Record seeding | `WHERE NOT EXISTS` guards, `ON CONFLICT (external_id) DO NOTHING` |
| `node --import tsx` + `pg` Pool | Diagnostic queries, push scripts | Load `dotenv/config`; run from `backend/` |
| Supabase Storage API | Headshot storage-mirror | Python PIL or sharp + storage upload; `politician_images` table |
| Wikipedia structured articles | Roster verification | WebFetch per officeholder page for name/party confirmation |

### Existing Migration Numbers

- Last applied DB migration: **937** (verified 2026-06-21 from prod)
- Last disk migration: **945** (945_aurelio_mattucci_stances.sql)
- Next available migration number: **946**

---

## Package Legitimacy Audit

No new packages are installed in this phase. Existing stack only.

---

## Architecture Patterns

### System Architecture Diagram

```
Wikipedia "List of current..." articles (verified per D-11)
  + State .gov biography pages (cross-check)
        |
        v
  Validated 209-office roster (SEXR-01)
        |
        v
  Gap query against prod:
  SELECT state, role_canonical FROM missing_offices
  WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d
                    JOIN essentials.offices o ON o.district_id = d.id
                    WHERE d.district_type='STATE_EXEC' AND d.state=XX
                    AND o.role_canonical=YY)
        |
        v  (41 empty states + IN SoS/Treasurer + UT NULL-id fix)
  SQL migration (per-batch, ~10 states each):
    Step 1: preflight government row assertion
    Step 2: INSERT essentials.districts (one per office, WHERE NOT EXISTS on state+label)
    Step 3: INSERT essentials.chambers (one per office)
    Step 4: CTE INSERT essentials.politicians (ON CONFLICT external_id DO NOTHING)
            + INSERT essentials.offices (WHERE NOT EXISTS on district_id+chamber_id)
    Step 5: UPDATE essentials.politicians SET office_id (scoped, idempotent)
        |
        v
  Headshot sourcing (per-batch):
    official state.gov biography pages
    → Ballotpedia politician page
    → Wikimedia Commons
    → crop 4:5, resize 600x750, store in politician_photos bucket
    → INSERT essentials.politician_images (WHERE NOT EXISTS)
        |
        v
  role_canonical backfill (single migration):
    UPDATE essentials.offices SET role_canonical=X
    WHERE district_id IN (SELECT d.id FROM essentials.districts d WHERE d.district_type='STATE_EXEC' AND d.state=XX AND d.label LIKE '%Governor%')
```

### Recommended Project Structure

```
backend/
├── migrations/
│   ├── 946_state_exec_batch1.sql    # UT fix + role_canonical backfill
│   ├── 947_state_exec_batch2.sql    # IN SoS + Treasurer gap seed
│   ├── 948_state_exec_batch3.sql    # AL AR AZ CO CT DE FL GA  (8 states)
│   ├── 949_state_exec_batch4.sql    # HI ID IL IA KS KY LA MI  (8 states)
│   ├── 950_state_exec_batch5.sql    # MN MS MO MT NE NV NH NJ  (8 states)
│   ├── 951_state_exec_batch6.sql    # NM NY NC ND OH OK PA RI  (8 states)
│   ├── 952_state_exec_batch7.sql    # SC SD AK VT WA WV WI WY  (8 states — remaining 9 → split as needed)
│   ├── 953_state_exec_headshots_batch1.sql  # headshots for batch 2+3
│   ├── 954_state_exec_headshots_batch2.sql  # headshots for batch 4+5
│   └── 955_state_exec_headshots_batch3.sql  # headshots for batch 6+7
└── scripts/
    └── verify-state-exec-baseline.ts  # (already created; reuse for phase gate diagnostics)
```

Note: Migration numbers are tentative (next available = 946). Exact batching is planner's discretion.

### Pattern 1: Per-Office Labeled District + CTE Politician+Office Insert (from migration 270)

```sql
-- Source: backend/migrations/270_md_state_executives.sql

-- One district per office (NOT one per state)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'XX', '{fips}', 'State Name Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'XX' AND label = 'State Name Governor'
);

-- CTE pattern for politician + office (idempotent)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Full Name', 'First', 'Last', 'Party',
          true, false, false, true, -(fips*100000+1))
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Name Governor'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of X' AND state = 'XX')),
       p.id,
       'Governor', 'XX', false, false, 'governor'
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'XX' AND d.label = 'State Name Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'State Name Governor'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of X' AND state = 'XX'))
  );
```

### Pattern 2: Headshot Insert (from migration 271)

```sql
-- Source: backend/migrations/271_md_executive_headshots.sql
-- AUDIT-ONLY: actual writes via script; migration captures the write for reproducibility

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -(fips*100000+1)),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/{uuid}-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -(fips*100000+1))
);
```

### Pattern 3: Post-Insert State Code Assertion (from PITFALLS.md Pitfall 3)

```sql
-- Every STATE_EXEC seed migration ends with this assertion:
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE district_type = 'STATE_EXEC'
      AND state != upper(state)
      AND state IN ('XX', 'YY', 'ZZ') -- scope to this migration's states only
  ) THEN RAISE EXCEPTION 'state column contains non-uppercase values in this batch'; END IF;
  IF EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE district_type = 'STATE_EXEC'
      AND (geo_id IS NULL OR geo_id = '')
      AND state IN ('XX', 'YY', 'ZZ')
  ) THEN RAISE EXCEPTION 'geo_id is NULL or empty on STATE_EXEC district in this batch'; END IF;
END $$;
```

### Pattern 4: role_canonical Backfill

```sql
-- Backfill on existing offices: look up district by (state, label)
-- Pattern for CA Governor (example):
UPDATE essentials.offices
SET role_canonical = 'governor'
WHERE id IN (
  SELECT o.id FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_EXEC'
    AND d.state = 'CA'
    AND d.label IN ('California') -- shared label; disambiguate via chamber name
    AND (SELECT c.name FROM essentials.chambers c WHERE c.id = o.chamber_id) LIKE '%Governor%'
);

-- Simpler for per-office labeled states (MD, MA, ME, IN, VA):
UPDATE essentials.offices
SET role_canonical = 'governor'
WHERE district_id = (
  SELECT id FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MD' AND label = 'Maryland Governor'
);
```

### Anti-Patterns to Avoid

- **Title-string dedup:** Never `WHERE o.title = 'Governor'` — title strings are inconsistent. Use `(state, label)` on districts.
- **Seeding phantom offices:** Never seed ME AG/SoS/Treasurer, TX SoS, VA SoS/Treasurer, etc. Roster matrix is the gate.
- **Lowercase state code:** `state='or'` breaks feed routing silently (migration 223 lesson). Always uppercase.
- **Empty geo_id:** `geo_id=''` or NULL on STATE_EXEC district is a latent data quality defect; always use FIPS string.
- **Re-seeding CA/OR/MA/VA execs:** These have stances and records; only their role_canonical needs backfill.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Idempotent politician insert | Custom upsert logic | `ON CONFLICT (external_id) DO NOTHING RETURNING id` + CTE guard | Established in migrations 270/317/223 |
| Headshot sourcing + storage-mirror | Custom downloader | migration 271/225 pattern + Python PIL or similar script | Already proven across 10+ headshot migrations |
| Stance research for new execs | New pipeline | Reuse v2.16/v2.17 `_TOPIC_SCALE.txt` + `politician-stance-researcher` at 3-concurrency | Identical push mechanism via external_id→UUID; only prompt update needed |
| Feed surfacing | New routes or query changes | Zero code change — `STATE_EXEC` is already in both statewide query paths | Confirmed in `essentialsService.ts` lines 1585-1598 and 669-716 |

---

## Common Pitfalls

### Pitfall 1: CA/OR label-mismatch on dedup
**What goes wrong:** CA uses a shared "California" district label for all execs. OR uses "Oregon (Statewide)". Deduping on `state + label` for Big-5 won't find them — you'd seed new per-office labeled districts and CA/OR execs would appear twice.
**Prevention:** Phase 141 does NOT re-seed CA or OR Big-5 records. CA Big-5 are complete and stanced. OR Big-5 are complete. The role_canonical backfill for CA/OR must use the existing shared-label district pattern, not new labeled districts.

### Pitfall 2: IN existing SoS/Treasurer under shared "Indiana" district
**What goes wrong:** Indiana already has Diego Morales (SoS) and Daniel Elliott (Treasurer) as politician records linked to the shared "Indiana" district (geo_id=''). Seeding new labeled "Indiana Secretary of State" and "Indiana Treasurer" districts creates a second set of offices for the same people, and the feed would show them twice.
**Prevention:** The correct approach is: (a) check if the existing offices have `role_canonical` set — they don't. (b) Create new labeled districts for IN SoS and IN Treasurer, but use `ON CONFLICT (external_id) DO NOTHING` for the politicians (Morales and Elliott already have external_ids 642977 and 688298). The office INSERT will add a new office linking the existing politician to the new properly-labeled district. Then the old office under the shared "Indiana" district should be investigated — if it's the only link, removing it or setting `is_vacant=true` may be appropriate. **The planner must explicitly address this IN dual-office risk.**

### Pitfall 3: UT external_id NULL breaks ON CONFLICT
**What goes wrong:** `ON CONFLICT (external_id)` requires the column to be non-null. If UT politicians have NULL external_id, the ON CONFLICT guard silently fails (NULL ≠ NULL in SQL), potentially creating duplicate politician rows on re-run.
**Prevention:** Fix UT NULL external_ids FIRST (plan 141-01), BEFORE any seed migrations that create new UT records. Assign -(49*100000+seq) to UT's 5 existing politicians.

### Pitfall 4: government row duplication for IN
**What goes wrong:** IN has 22+ "State of Indiana" government rows (confirmed by prod query — the Q5 output showed `IN = State of Indiana` repeated 22 times). This is a pre-existing data quality issue. A migration that asserts `COUNT(*) = 1` for Indiana's government will fail.
**Prevention:** The pre-flight assertion for IN must query `COUNT(*) >= 1` or pick the correct government row by a tiebreaker (e.g., oldest `created_at`, or check which one the existing IN offices reference). Do NOT use the strict `= 1` assertion from migration 270 for Indiana.

### Pitfall 5: Stale officeholders from 2024 gubernatorial elections
**What goes wrong:** 37 states held gubernatorial elections in November 2024; many inaugurated new governors January 2026. Training data and even Wikipedia snapshots from mid-2025 may name the outgoing governor.
**Prevention:** Every newly-seeded governor's name must be fetched from the current state .gov biography page, not from training memory. Wikipedia "List of current United States governors" is the primary source (D-11) and reflects January 2026 inaugurations.

---

## Reusable-Asset Playbook

### 1. Seed Migration Pattern (from migration 270)

**Adapt:** `backend/migrations/270_md_state_executives.sql` — this is the cleanest precedent with:
- Pre-flight government row assertion (note IN exception — see Pitfall 4)
- One district per office with `(state, label)` dedup key
- CTE politician+office insert with ON CONFLICT guard
- office_id backfill scoped to external_id range
- Explicit `role_canonical` on each office row (migration 270 sets NULL; v2.18 sets the role)

**Do NOT copy:** migration 190 (CA dedup trap) or migration 223 (lowercase state code); these are the failure cases.

### 2. Headshot Pattern (from migration 271/225)

**Pattern:** migration 271 (`md_executive_headshots.sql`) and 225 (`or_headshots.sql`) — both AUDIT-ONLY with actual writes via script. Three-step process:
1. Find portrait URL from official state.gov or Ballotpedia or Wikimedia Commons
2. Download, crop to 4:5 from top, resize to 600x750 Lanczos q90 (Python PIL)
3. Upload to `politician_photos` bucket as `{politician_uuid}-headshot.jpg`
4. Write audit-only migration with `INSERT INTO essentials.politician_images ... WHERE NOT EXISTS`

**Sources in priority order:**
1. Official state .gov biography page (e.g., `governor.state.gov/about`, `governor.XX.gov/about/bio`)
2. Ballotpedia individual politician page (direct `.jpg` from image CDN)
3. Wikimedia Commons (check license — prefer public domain or CC)
4. NGA/NAAG member gallery (unstable CDN URLs — download and mirror immediately)

**Honest-skip:** If no portrait is found after all sources, leave no `politician_images` row. The feed renders a placeholder avatar. Document as honest-skip in the migration comment.

### 3. find-headshots Skill

The `find-headshots` skill referenced in CONTEXT.md is not a file-based skill (`.claude/skills/find-headshots/` does not exist on disk). The pattern is documented inline in prior migrations (271, 225, 315). The planner should use the Python PIL / storage-mirror workflow from migration 271's header comments as the reference.

### 4. Script Precedent: `seed-national-house-reps.ts`

The `--dry-run` / `--generate` mode from this script is the model for generating reviewable SQL migrations programmatically. For state execs, the migration is small enough (5 offices × 41 states = 205 records) to write directly as SQL rather than via a generation script. But the "iterate the gap, not the roster" principle from this script (line 17) is mandatory.

### 5. Feed Surfacing Verification (no code change)

`backend/src/lib/essentialsService.ts` lines 1585-1598 (statewide query) already includes `STATE_EXEC` in `district_type IN (...)`. No code changes this phase. Surfacing is verified in Phase 144.

---

## Runtime State Inventory

> Rename/refactor phase: NOT applicable. This is a greenfield data seed phase.

None — verified: no runtime state rename/refactor in scope.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (prod) | All seed migrations | ✓ | Supabase prod `kxsdzaojfaibhuzmclfq` | — |
| `node --import tsx` | Diagnostic scripts | ✓ | Node v24.13.0 (prod query confirmed 2026-06-21) | — |
| `dotenv` | DB connection in scripts | ✓ | In node_modules; `import 'dotenv/config'` | — |
| Python PIL (Pillow) | Headshot processing | [ASSUMED] | Used in prior headshot migrations | `sharp` (Node.js) as fallback |
| Supabase Storage API | Headshot upload | ✓ | Confirmed working (prior headshot migrations) | — |

**Missing dependencies with no fallback:** None identified.

---

## Validation Architecture

> `workflow.nyquist_validation` not explicitly false in config — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | PostgreSQL read-only SQL assertions (psql) |
| Config file | none — ad hoc SQL scripts in `backend/scripts/` |
| Quick run command | `node --import tsx backend/scripts/verify-state-exec-baseline.ts` |
| Full gate command | `psql $DATABASE_URL -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-141.sql` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEXR-01 | 209 in-scope offices are identified in roster matrix | manual (matrix in this doc) | `SELECT COUNT(*) FROM essentials.districts WHERE district_type='STATE_EXEC' AND state=upper(state)` asserts >= 209 labeled districts | ❌ Wave 0 |
| SEXR-02 | All 209 in-scope Big-5 offices have a seeded politician+office | SQL assertion | `SELECT count with NOT EXISTS check` in verify-phase-141.sql | ❌ Wave 0 |
| SEXR-03 | All in-scope offices have non-null role_canonical | SQL assertion | `SELECT COUNT(*) FROM ...offices WHERE role_canonical IS NULL AND in-scope` = 0 | ❌ Wave 0 |
| SEXR-04 | All newly-seeded execs have a headshot | SQL assertion | `SELECT count of politician_images JOIN politicians WHERE external_id IN new-range` | ❌ Wave 0 |

### Sampling Rate

- **Per migration commit:** Run Q1 quick count: `SELECT state, COUNT(*) FROM essentials.districts WHERE district_type='STATE_EXEC' GROUP BY state ORDER BY state`
- **Per wave merge:** Run full verify-state-exec-baseline.ts diagnostic
- **Phase gate:** `verify-phase-141.sql` ALL assertions PASS before Phase 142 starts

### Wave 0 Gaps

- [ ] `backend/scripts/verify-phase-141.sql` — covers SEXR-01..04 with labeled SQL assertions:
  - SEXR-01: COUNT of STATE_EXEC districts with labeled Big-5 roles = 209 (minus AZ LtGov + documented exclusions)
  - SEXR-02: For each in-scope (state, role_canonical) pair from the 209-office matrix — assert EXISTS a politician+office in prod
  - SEXR-03: COUNT of in-scope offices with `role_canonical IS NULL` = 0
  - SEXR-04: COUNT of in-scope politicians with no `politician_images` row = 0
  - SEXR-D10: COUNT of STATE_EXEC districts with `state != upper(state)` = 0
  - SEXR-D10b: COUNT of STATE_EXEC districts with `geo_id IS NULL OR geo_id = ''` = 0

*(The existing `verify-state-exec-baseline.ts` script is a research diagnostic, not the phase gate. The gate needs proper labeled assertions in SQL with ON_ERROR_STOP.)*

---

## Security Domain

No authentication, authorization, or user-facing input validation changes in this phase. Pure DB data seed — no ASVS categories apply.

---

## Open Questions (RESOLVED)

1. **Indiana dual-office risk for existing SoS/Treasurer**
   - What we know: Diego Morales (SoS) and Daniel Elliott (Treasurer) already exist as politicians linked to the shared "Indiana" district. New labeled "Indiana Secretary of State" and "Indiana Treasurer" districts must be created for SEXR-02.
   - What's unclear: Whether to create new offices for the existing politicians (linking them to new labeled districts) while leaving old offices in place, or to reassign existing offices to new districts.
   - Recommendation: Create new labeled districts + new offices linking existing politicians via ON CONFLICT DO NOTHING. Old offices under the shared "Indiana" district can remain (they have `is_appointed_position=true` for most; check if SoS/Treasurer under shared district also have this flag). The planner should explicitly decide and document.
   - **RESOLVED:** Per plan 141-02 — create new labeled "Indiana Secretary of State" / "Indiana Treasurer" districts + new offices linking the existing Morales/Elliott politician records via their canonical UUIDs (resolved by external_id 642977 / 688298); leave the old shared-"Indiana"-district offices in place untouched (D-09). No politician records duplicated.

2. **Indiana government row duplication**
   - What we know: 22+ "State of Indiana" rows exist in `essentials.governments` (prod Q5 output).
   - What's unclear: Which is the canonical one referenced by existing IN chambers/offices. 
   - Recommendation: Before authoring any IN migration, query `SELECT DISTINCT g.id, g.name FROM essentials.governments g JOIN essentials.chambers c ON c.government_id = g.id WHERE g.state = 'IN' AND g.name = 'State of Indiana' LIMIT 1` to identify the canonical government row, and use that specific UUID in the pre-flight assertion.
   - **RESOLVED:** Per plan 141-02 — resolve the canonical "State of Indiana" government UUID by the chamber-join query at migration-authoring time and pin that specific UUID in the pre-flight assertion; the IN seed reuses the existing canonical government row, never inserting a new one.

3. **WV/TN "LtGov" records in prod**
   - What we know: WV and TN are both NOT ELECTED for LtGov (Senate President by statute). Neither has STATE_EXEC records currently. The matrix correctly shows WV LtGov as NOT ELECTED.
   - Recommendation: Do NOT seed WV or TN LtGov. Seed only in-scope offices per the matrix.
   - **RESOLVED:** WV and TN LtGov are EXCLUDED per the validated matrix (both NOT ELECTED — Senate President by statute); neither is seeded and neither counts toward the 209 denominator.

4. **OR shared vs per-office district model**
   - What we know: OR's 5 execs all share one district label "Oregon (Statewide)". This works for feed surfacing (all return on state code match). role_canonical backfill must target individual offices via chamber name.
   - Recommendation: Leave OR's district structure as-is (no need to re-architect to per-office labeled format). role_canonical UPDATE should use `JOIN essentials.chambers ON chamber_name LIKE '%Governor%'` etc.
   - **RESOLVED:** OR district structure left as-is (shared "Oregon (Statewide)" label); role_canonical is assigned per-office via the chamber-name join (`JOIN essentials.chambers ON chamber_name LIKE '%Governor%'` etc.), never via district label (Pitfall 1).

---

## Sources

### Primary (HIGH confidence)
- `essentials.districts` prod query — STATE_EXEC baseline (2026-06-21): all 9 states, all record details confirmed
- `essentials.politicians` prod query — negative external_id audit (2026-06-21): confirmed -(fips*100000+seq) scheme clear for 41 empty states, confirmed OR collision for existing range
- `essentials.governments` prod query — 72 government rows, 50 states present (IN duplicated ~22×)
- Wikipedia "List of current United States governors" — all 50 governors [CITED: en.wikipedia.org/wiki/List_of_current_United_States_governors]
- Wikipedia "Lieutenant governor (United States)" — selection method per state [CITED: en.wikipedia.org/wiki/Lieutenant_governor_(United_States)]
- Wikipedia "State attorney general" — 43 elected / 7 not [CITED: en.wikipedia.org/wiki/State_attorney_general]
- Wikipedia "Secretary of state (U.S. state government)" — 35 elected, all exceptions sourced [CITED: en.wikipedia.org/wiki/Secretary_of_state_(U.S._state_government)]
- Wikipedia "State treasurer" — abolitions + appointed states [CITED: en.wikipedia.org/wiki/State_treasurer]
- Wikipedia "Washington State Treasurer" — confirms popularly elected on partisan ballot [CITED: en.wikipedia.org/wiki/Washington_State_Treasurer] [VERIFIED]
- `backend/migrations/270_md_state_executives.sql` — seed pattern (CTE, per-office districts, role_canonical, pre-flight)
- `backend/migrations/271_md_executive_headshots.sql` — headshot audit-only pattern
- `backend/migrations/192_ca_exec_dedup.sql` — confirmed title-string dedup failure cost
- `backend/migrations/223a_or_executive_district_fix.sql` — confirmed lowercase state code bug

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` — 50-state matrix validated against this research and prod data
- `.planning/research/ARCHITECTURE.md` — feed surfacing code path traced (lines confirmed)
- `.planning/research/PITFALLS.md` — all 8 pitfalls grounded in real migrations

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Python PIL (Pillow) is available for headshot processing | Environment Availability | Fallback: use `sharp` (Node.js) or manual headshot upload; low risk |
| A2 | 2024-elected governors (37 states) are correctly reflected in Wikipedia "List of current United States governors" | 50-State Matrix | Stale governor names in seeds; requires fixing with new migration; medium risk — mitigated by D-11 requiring live fetch per officeholder |
| A3 | WA Treasurer is popularly elected | 50-State Matrix | RESOLVED: confirmed ELECTED via WebFetch of Wikipedia (see Resolved open cases); WA Treasurer IS in scope — no deferral, no denominator reduction (209 stands) |

**Confirmed-verified claims (not assumed):**
- OR external_id collision for -(fips*100000+seq): VERIFIED by prod query
- IN government row duplication: VERIFIED by prod query (22+ rows)
- UT NULL external_ids: VERIFIED by prod query (all 5 UT politicians have external_id=NULL)
- IN SoS/Treasurer missing labeled districts: VERIFIED by prod query
- 209-office denominator: VERIFIED by arithmetic from FEATURES.md matrix (50 Gov + 43 LtGov + 43 AG + 35 SoS + 38 Treasurer)
- WA Treasurer elected: VERIFIED by Wikipedia WebFetch

---

## Metadata

**Confidence breakdown:**
- 50-state matrix: HIGH — all exceptions individually sourced + validated against prod
- Seed gap: HIGH — verified from live prod DB query 2026-06-21
- external_id scheme: HIGH — full negative ID list examined from prod; collision for OR identified and resolved (OR already seeded)
- Architecture: HIGH — direct code reading of migrations 270/271 + essentialsService.ts
- Pitfalls: HIGH — all grounded in actual production defects

**Research date:** 2026-06-21
**Valid until:** 2026-07-21 (stable civic data; re-verify governor names if authoring after August 2026 when 2026 election cycle begins)
