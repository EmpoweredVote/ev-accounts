# Research Summary: v2.18 State Leaders

**Project:** Empowered Accounts -- v2.18 State Leaders
**Domain:** Civic data -- elected Big 5 statewide executives (Governor, Lt. Governor, AG, Secretary of State, Treasurer) across all 50 states
**Researched:** 2026-06-20
**Confidence:** HIGH

---

## Executive Summary

v2.18 is a pure data milestone. No new dependencies, no schema changes, no backend routing changes. The existing stack -- idempotent SQL migrations, the v2.16/v2.17 stance pipeline, and the find-headshots skill -- covers 100% of the work. The core challenge is scoping: the naive 50x5 = 250 grid shrinks to **208 popularly elected offices** once appointed, legislature-elected, abolished, and nonexistent offices are excluded per state. Getting this matrix right before writing any migration is the single highest-leverage action of the entire milestone; every other phase flows directly from it.

The recommended approach is a three-tier execution: (1) roster phase producing the authoritative 208-office matrix with per-office selection-method verification against live sources, (2) seed phase creating politician + office + headshot records for all 41 states that currently have zero STATE_EXEC coverage plus gaps in the 9 existing states, and (3) stance phase reusing the proven v2.16/v2.17 pipeline with one addition -- office-type-specific evidence guidance in the researcher prompt before dispatch. Feed surfacing is already wired: STATE_EXEC is enumerated in the essentialsService.ts statewide query for both GET /representatives/me and the address-search path; adding records for a new state requires only the seed migration, no code change. The milestone closes with a consolidated read-only SQL gate.

The key risks are all data-quality risks, not engineering risks. The top three: (1) seeding appointed officials as if elected (ME AG/SoS/Treasurer, TX SoS, UT SoS, VA SoS -- these must be marked is_appointed_position=true or excluded); (2) stale officeholders from sources that have not yet reflected January 2026 inaugurations (37 gubernatorial races ran in 2024); and (3) stance evidence mismatch by office type -- AGs generate amicus briefs and multistate coalitions, not floor votes, and the researcher prompt must be updated before any agent dispatch. All three risks have established prevention patterns from prior work in this codebase.

---

## Key Findings

### Recommended Stack

No new technology is introduced. Wikipedia structured articles are the primary source for the roster phase (free, structured HTML tables, confirmed parseable via WebFetch, already reflecting January 2026 inaugurations). Official state .gov biography pages are the secondary source for name verification and headshots. Ballotpedia individual politician pages remain the primary stance research source; Ballotpedia category/list pages are JS-rendered and must not be used for bulk roster work. iSideWith.com is below the evidence bar (confirmed v2.17 lesson).

**Data sources by use case:**

- Wikipedia structured tables (five office-specific articles): roster building -- confirmed accessible, party and selection-method data, HIGH confidence
- Official state .gov biography pages: name/incumbency verification and headshot URLs -- authoritative, inconsistently formatted; use for verification not bulk extraction
- Ballotpedia individual pages: stance research -- above-the-bar primary source, confirmed from v2.16/v2.17 pipeline
- Votesmart.org / OnTheIssues: stance research supplemental -- same ranking as v2.17 pipeline
- NGA / NAAG association pages: cross-check only -- image CDN URLs unstable; NASS/NAST directories are login-gated and not useful for bulk seeding

### Expected Features

The 208-office breakdown by office type:

| Office | In-Scope Count | Key Exceptions |
|--------|---------------|----------------|
| Governor | 50 | All 50 states, no exceptions |
| Lt. Governor | 43 | AZ (eff. 2027 -- defer), ME/NH/OR/WY (no office), TN/WV (Senate Speaker -- not elected) |
| Attorney General | 43 | AK/HI/NH/NJ/WY (Gov appoints), ME (legislature), TN (Supreme Court appoints) |
| Secretary of State | 35 | AK/HI/UT (no office), DE/FL/NJ/NY/OK/PA/TX/VA (Gov appoints), ME/NH/TN (legislature) |
| Treasurer | 37 | TX/MN/MT (abolished; TX Comptroller = elected equiv), NY (abolished; NY Comptroller = elected equiv), FL (CFO = elected equiv), AK/GA/HI/MI/NJ/VA (Gov appoints), ME/MD/NH/TN (legislature) |

**Total: 208 in-scope elected offices. This is the milestone denominator -- not 250.**

FL CFO, NY Comptroller, and TX Comptroller are modeled with role_canonical = treasurer as elected equivalents. MD Comptroller is NOT a Big 5 Treasurer equivalent for MD (MD in-scope Big 5 = Gov + Lt Gov + AG only = 3; MD Treasurer is legislature-elected).

**Must have (table stakes):**
- Governor for every state (50 records; most visible statewide official)
- Headshot for every seeded exec (users notice absence)
- Correct office title normalization (MA Secretary of the Commonwealth, NY/TX Comptroller, FL Chief Financial Officer)
- Sourced compass stances for all 208 in-scope officials (real source URL per stance; honest-skip where no evidence)

**Should have (differentiators):**
- Full Big 5 scope where elected -- no other civic platform provides stances for all five offices across all 50 states
- role_canonical populated for all Big 5 offices on new records (enables future cross-state queries)
- Honest is_appointed_position=true for legislature-elected offices already in DB

**Defer to v2.19+:**
- AZ Lieutenant Governor (Prop 131, first election 2026, seats January 2027)
- Non-Big-5 statewide officers (Auditor, Insurance Commissioner, Agriculture Commissioner)

**Do not build:**
- Appointed officials seeded as elected (breaks platform elected-officials focus)
- 50x5 flat grid (creates phantom offices)
- Stances inferred from party affiliation

### Architecture Approach

The feed surfacing code path already handles STATE_EXEC. The statewide query in essentialsService.ts (lines 1585-1598 for getRepresentativesByJurisdiction(), lines 669-716 for getRepresentativesByAddress()) includes d.district_type IN (NATIONAL_UPPER, NATIONAL_EXEC, STATE_EXEC, ...) and filters by d.state = $1 where $1 is the 2-char uppercase postal abbreviation derived from the user NATIONAL_LOWER district. Adding any new state records requires only a seed migration -- zero code changes. Feed surfacing is a smoke-test in the gate, not a build phase.

**Major components:**

1. Authoritative 208-office roster (data verification at plan time) -- per-state table of (state, office, selection_method, officeholder, source_url); gates all downstream phases; the FEATURES.md matrix is the research output but must be confirmed against live state sources at plan authoring time
2. Seed migrations (SQL, new) -- idempotent 5-step pattern: governments + chambers stubs, then districts (one per office, label = State Role, state = uppercase, geo_id = FIPS), then politicians + offices (ON CONFLICT DO NOTHING), then office_id backfill; dedup key is (district_type=STATE_EXEC, state=XX, label=State Role) -- never title string
3. Stance research pipeline (reused from v2.16/v2.17) -- _TOPIC_SCALE.txt (25 topics, unchanged) + politician-stance-researcher at 3-concurrency + per-exec CSV merge and push; office-type-specific evidence guidance added to researcher prompt before dispatch
4. Phase gate SQL (new) -- read-only verify-phase-N.sql asserting all 208 offices filled, 0 unsourced, all STATE_EXEC rows have uppercase state code and non-empty geo_id

### Critical Pitfalls

1. **Seeding phantom appointed offices** -- The naive 50x5 grid includes 42 appointed and 8 legislature-elected offices. ME has an AG, SoS, and Treasurer but all three are legislature-elected; TX appoints its SoS. Always derive seeds from the 208-office matrix. Prevention: roster phase must have an explicit selection_method column with a source URL per row; count of in-scope offices per state must match the known exception map before any migration is written.

2. **Duplicate records via title-string dedup** -- The CA dedup migration 192_ca_exec_dedup.sql exists because existing STATE_EXEC titles are inconsistent (Indiana Governor vs Governor vs Texas Governor). Any seed migration that checks for existing records by title string will silently create duplicates. Prevention: dedup on (district_type=STATE_EXEC, state=XX, label=State Role) on districts; run a dry-run gap query against prod and confirm 0 new rows for the 9 already-seeded states before any INSERT executes.

3. **Lowercase state code silently breaking feed routing** -- Migration 223 shipped state=or (lowercase) and required repair migration 223a. The statewide query filters d.state = $1 where $1 is always uppercase; a lowercase state code is fully invisible in the feed. Prevention: every STATE_EXEC district INSERT must use the uppercase 2-char postal abbreviation; include a post-insert assertion in the migration SQL; gate must check state = upper(state).

4. **Stale officeholders from pre-2026 sources** -- 37 gubernatorial races ran in 2024; many January 2026 inaugurations (VA Spanberger/Hashmi/Jones confirmed in migration 317). Sources cached before January 2026 may name the outgoing governor. Prevention: every officeholder name must be verified from a live fetch of the state .gov page, not training memory. Roster output must include URL fetched and fetch date per row.

5. **Wrong evidence type for exec office stances** -- The v2.16/v2.17 pipeline was calibrated for legislators (floor votes, co-sponsorships). Governors sign/veto bills; AGs file amicus briefs and join multistate coalitions; Treasurers make investment/divestment decisions; SoS officials issue election administration actions. Prevention: researcher prompt must include office-type-specific evidence guidance before any agent is dispatched. AG: multistate coalition membership counts only when coalition has a published position directly on that topic; filed lawsuits and amicus briefs are strongest evidence. Treasurer: investment/divestment decisions (documented fund actions) are strongest evidence. SoS: specific election administration actions -- not SoS administers elections role description. Lt Gov: honest-partial if no independent record; never mirror Governor stances without independent sourcing.

---

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Roster and Seed (Big 5 Records + Headshots)

**Rationale:** The 208-office roster must be locked before any migration is authored -- it is the gate that prevents the highest-severity pitfall (phantom offices). Seed must precede stances because stance push needs politician UUIDs. Headshots belong with seed to avoid a separate backfill pass. The 9 existing states need a gap diagnostic before any seed work touches them.

**Delivers:** Complete politician + office + district + headshot records for all 208 in-scope elected Big 5 offices across all 50 states; all 41 currently-empty states seeded; gaps in IN/ME/OR/TX/UT filled; 0 phantom appointed offices.

**Addresses:** All table-stakes features -- Governors for 50 states, Lt Govs for 43, AGs for 43, SoS for 35, Treasurers for 37; correct title normalization; role_canonical set on all new office records.

**Avoids:** Phantom offices (Pitfall 1), duplicate records via title-string dedup (Pitfall 2), lowercase state codes (Pitfall 3), stale officeholders (Pitfall 4).

**Key execution notes:**
- Start with live prod query: SELECT state, COUNT(*) FROM essentials.districts WHERE district_type=STATE_EXEC GROUP BY state to confirm the 9-state baseline
- Dry-run gap query must return 0 new rows for the 9 already-seeded states before any INSERT executes
- Group states into migration batches (~8-10 states per migration) to keep migration count manageable
- geo_id = FIPS (non-empty string) required on every STATE_EXEC district

### Phase 2: Stance Research (All 208 In-Scope Execs)

**Rationale:** Stances require seeded records (Phase 1 dependency). The v2.16/v2.17 pipeline applies unchanged except for office-type-specific evidence guidance in the researcher prompt. Governors first (richest press release archives), then AGs (amicus briefs are primary sources), then SoS/Treasurer/Lt Gov.

**Delivers:** Sourced compass stances for all 208 in-scope officials, or honest-skip with documented reason. 0 unsourced rows. Every stance backed by a real fetched URL in inform.politician_context.

**Avoids:** Wrong evidence type for exec stances (Pitfall 5), re-researching already-stanced executives (Pitfall 6).

**Key execution notes:**
- Run stance gap diagnostic first: query inform.politician_answers by politician UUID for all STATE_EXEC politicians; dispatch only for stance_count = 0 rows (avoids re-researching CA execs who already have complete coverage)
- Update researcher prompt with office-type evidence guidance before first dispatch (full framework in PITFALLS.md Pitfall 5)
- 3-concurrency cap holds; validate first 3-exec wave before proceeding
- Proxy-row review gate standard: drop overall record alignment, coalition membership without published topical platform, office role description rows before push
- Expected honest-partial rate lower than v2.17 freshman-heavy batches (governors and AGs have richer primary source archives)

### Phase 3: Feed Surfacing Verification + Phase Gate

**Rationale:** Feed surfacing is already wired (zero code change needed), but the gate must confirm it works for newly-seeded states. This is confirmation, not construction.

**Delivers:** Read-only SQL gate (verify-phase-N.sql) asserting: (a) all 208 in-scope offices have a seeded politician, (b) 0 unsourced stance rows for STATE_EXEC politicians, (c) all STATE_EXEC districts have uppercase state code and non-empty geo_id, (d) per-state counts match the 208-office matrix. Feed smoke test confirming at least 3 newly-seeded states return the correct exec in GET /representatives/me.

**Avoids:** Silent lowercase state code breakage (Pitfall 3), missing geo_id (Pitfall 8).

### Phase Ordering Rationale

- Roster must precede all seed work -- the live gap count in the 9 existing states must be queried against prod before authoring any migration
- Seed and headshots are one phase -- separating them creates an unnecessary intermediate state; all existing milestones co-locate these
- Stances are strictly post-seed -- the push script requires politician UUIDs which only exist after seed migrations are applied
- Gate is last -- verifies the full chain end-to-end
- No backend code phase for feed surfacing -- STATE_EXEC is already enumerated in essentialsService.ts; feed surfacing is a smoke test in the gate, not a build step

### Research Flags

Phases with standard patterns (skip research-phase):
- **Phase 1 (Roster + Seed):** Migration pattern established in migrations 154/169/190/270/317/223. 208-office matrix produced in FEATURES.md. Live gap query at plan time confirms current coverage.
- **Phase 3 (Gate):** SQL gate pattern established (verify-phase-127-131.sql, verify-phase-132-140.sql). Standard assertions.

Needs attention during plan authoring (not a full research-phase):
- **Phase 2 (Stances):** Researcher prompt must include office-type-specific evidence guidance. Not a separate research task -- embed the framework from PITFALLS.md Pitfall 5 directly in the plan before first agent dispatch.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new technology; all data sources confirmed accessible; existing pipeline proven across 3 milestones |
| Features | HIGH | 208-office matrix individually verified against Wikipedia and state constitution sources; all exceptions cited with source URLs |
| Architecture | HIGH | All findings from direct code reading of production source; STATE_EXEC enumeration in essentialsService.ts confirmed at lines 1585-1598 and 669-716 |
| Pitfalls | HIGH | All 8 pitfalls grounded in actual production defects (migrations 192, 223/223a, 317) or confirmed patterns from v2.15/v2.16/v2.17 |

**Overall confidence: HIGH**

### Gaps to Address at Plan Time

These are not research gaps -- research is conclusive -- but require live prod queries before migration authoring begins:

- **External ID scheme (must verify before authoring any migration):** STACK.md proposes -(fips * 100 + seq); ARCHITECTURE.md proposes -(fips * 100000 + seq). The conflict is real: -(fips * 100 + seq) produces IDs in the range -101 through -5609, which overlaps with the NATIONAL_LOWER federal rep range starting at -1001 for AL CD1. The safer scheme is -(fips * 100000 + seq) but existing exec records used ad hoc schemes (CA: -(fips*1000000+seq), MA: flat -200xxx, TX: flat -100xxx). Required action before authoring any new state migration: run SELECT external_id FROM essentials.politicians WHERE external_id < 0 ORDER BY external_id against prod, define a non-overlapping range per state, document it in the migration header. Do not treat either proposed scheme as settled until collision-free verification is confirmed against the live database.

- **Gap baseline in the 9 already-seeded states:** IN likely has AG/SoS/Treasurer gaps; ME has 0 stances on all 4 records; TX has 3 in-scope elected offices but some may lack stances. Run the stance count diagnostic from PITFALLS.md Pitfall 6 against prod before authoring any research plans.

- **AZ Lt. Governor (defer):** AZ Prop 131 created the LG position; first election in 2026, seats January 2027. Do not seed until post-election results are confirmed. Gate assertion should note AZ Lt Gov as deferred, not missing.

- **WA Treasurer elected-vs-appointed:** FEATURES.md classifies WA as 5 in-scope offices (Treasurer = elected). Verify against WA state constitution at plan time; if live source contradicts, exclude and adjust the denominator from 208 to 207.

- **MD Comptroller:** Already seeded; NOT a Big 5 Treasurer equivalent for MD (unlike NY/TX Comptrollers which absorbed Treasurer functions). MD in-scope Big 5 = Gov + Lt Gov + AG only. Leave MD Comptroller record untouched.

---

## Sources

### Primary (HIGH confidence)

- en.wikipedia.org/wiki/List_of_current_United_States_governors -- all 50 governors, party, term dates
- en.wikipedia.org/wiki/List_of_current_United_States_lieutenant_governors -- 45 states with LG, 5 without, selection method
- en.wikipedia.org/wiki/State_attorney_general -- 43 elected / 7 not; all 50 current AGs named
- en.wikipedia.org/wiki/Secretary_of_state_(U.S._state_government) -- 35 elected, exceptions individually cited
- en.wikipedia.org/wiki/State_treasurer -- ~36 elected, abolitions confirmed (TX 1996, MN 2003, MT 1972, NY 1926)
- naag.org/attorneys-general/ -- confirms 43 elected / 7 appointed breakdown
- backend/src/lib/essentialsService.ts lines 1574-1598 and 669-716 -- STATE_EXEC feed query confirmed; no code change needed
- backend/migrations/154_ma_state_executives.sql -- role_canonical pattern, label dedup established
- backend/migrations/169_me_state_executives.sql -- legislature-elected modeling with is_appointed_position=true
- backend/migrations/190_ca_state_executives.sql + 192_ca_exec_dedup.sql -- title-string dedup failure proof and recovery cost (confirmed real in production)
- backend/migrations/223_or_executive_officials.sql + 223a_or_executive_district_fix.sql -- lowercase state code defect and repair (confirmed real in production)
- backend/migrations/317_va_state_executives.sql -- Jan 2026 turnover modeling, uppercase state code, pre-flight government assertion

### Secondary (MEDIUM confidence)

- NGA nga.org/governors/ -- visual cross-check for governors; not used as primary (image CDN unstable)
- NAAG naag.org/find-my-ag/ -- headshot gallery for AGs; not used as primary (no party data on main page)

---

*Research completed: 2026-06-20*
*Ready for roadmap: yes*
