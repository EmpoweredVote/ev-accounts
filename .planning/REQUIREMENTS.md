# Requirements: v2.18 State Leaders

**Milestone goal:** Every US resident sees their state's elected Big 5 executives — Governor, Lt. Governor, Attorney General, Secretary of State, and Treasurer (whichever of the five their state actually *elects*) — in the representatives feed with sourced compass alignment, across all 50 states.

**Approach:** Gap-based and idempotent (the v2.15 "iterate the gap, not the roster" lesson). Pure data milestone — no new stack, no schema changes, no backend routing changes (feed surfacing for `STATE_EXEC` is already wired in `essentialsService.ts`). True denominator is ~**208 popularly elected offices**, not 250 (appointed / legislature-selected / abolished / nonexistent offices excluded per state, each exception sourced).

**Baseline at start (verified vs prod 2026-06-20):** 68 `STATE_EXEC` records across only 9 states (CA, IN, MA, MD, ME, OR, TX, UT, VA); 41 states empty; stance gaps even in present states (IN AG/SoS/Treasurer, all of ME, all of TX). The 68 existing records include non-Big-5 officers (Comptroller, Auditor, Commissioners) that are out of scope and must not be touched.

---

## v2.18 Requirements

### State Executive Records (SEXR)

- [ ] **SEXR-01**: An authoritative 50-state roster names which of the Big 5 offices each state *popularly elects* (vs. appoints, legislature-selects, or does not have), with a source cited for every non-elected exception. The roster defines the ~208 in-scope offices and is the source of truth that prevents seeding phantom offices.
- [ ] **SEXR-02**: All *missing* elected Big 5 records (politician + office) are seeded across all 50 states — idempotently and gap-based. Existing records are detected by `(district_type='STATE_EXEC', uppercase state, role_canonical)`, never by title string; external_id range is verified collision-free against production before authoring; each seed asserts uppercase `state` and non-empty `geo_id`; the 68 existing records and all non-Big-5 officers are left untouched.
- [ ] **SEXR-03**: `role_canonical` is populated for every in-scope Big 5 office (`governor`, `lt_governor`, `attorney_general`, `secretary_of_state`, `treasurer`), including backfill on the pre-existing Big 5 records.
- [ ] **SEXR-04**: Every newly-seeded exec has a headshot (official state .gov / Ballotpedia / Wikimedia portrait, storage-mirrored per the find-headshots pattern).
- [ ] **SEXR-05**: Newly-seeded execs are verified to surface in `GET /representatives/me` by state code for an in-state address (smoke-test on ≥3 newly-seeded states; no backend code change expected since `STATE_EXEC` is already enumerated in the feed query).

### State Executive Stances (SEXS)

- [ ] **SEXS-01**: The stance researcher prompt is extended with office-type evidence guidance before first dispatch — AG (lawsuits / amicus / multistate coalitions), Treasurer (investment / divestment policy), Secretary of State (election administration actions), Lt. Governor (honest-partial when no independent record) — so exec actions map to compass topics without over-reading.
- [ ] **SEXS-02**: Every in-scope elected exec has sourced compass stances — newly-seeded *and* the existing stance gaps (IN AG/SoS/Treasurer, all of ME, all of TX) — with each answer row paired to an `inform.politician_context` row carrying a real fetched source URL. **Zero unsourced rows** at close; honest-skip per topic where no evidence; the proxy-row review gate applies; never inferred from party.
- [ ] **SEXS-03**: A consolidated read-only, labeled-assertion SQL phase gate (mirroring `verify-phase-132-140.sql`) confirms every elected Big 5 office is filled (208 minus documented deferrals), **zero** answer rows lack a paired source-bearing context row, and state-code accessibility holds — all assertions PASS against production.

---

## Future Requirements (deferred)

- [ ] **AZ Lieutenant Governor**: Arizona created the office (Prop 131, 2022) but the first elected Lt. Governor is not seated until January 2027 (after the Nov 2026 election). Deferred to a future milestone; documented in the v2.18 phase gate as a known exclusion, not a miss.
- [ ] **Non-Big-5 statewide officers** (Comptroller where distinct from Treasurer, Auditor, Superintendent of Public Instruction, Insurance/Labor/Agriculture Commissioners, Public Utilities/Railroad Commissioners, Land Commissioners, Boards of Equalization): coverage expansion candidate for a later milestone.
- [ ] **FEC/state campaign finance** for state execs: out of scope here; belongs to the finance (FINA) stream.

## Out of Scope (this milestone)

- **Appointed or legislature-selected Big 5 offices** — a representatives feed surfaces elected officials; appointed AGs/SoS/Treasurers (e.g. AK/HI/NJ/NH/WY AGs; DE/FL/NJ/NY/OK/PA/TX/VA SoS; ME/NH/TN legislature-selected offices) are excluded. *Reason: not on a voter's ballot; not "their" elected representative.*
- **Non-Big-5 statewide officers** already in the DB (CA Controller/Auditor/Insurance Commissioner, OR Labor Commissioner, TX Land/Ag Commissioners, MA Auditor, MD Comptroller, etc.) — left untouched. *Reason: user scoped this milestone to the Big 5 only.*
- **Backend feed/routing code changes** — `STATE_EXEC` is already in the feed query at both sites; seeding data makes execs appear automatically. *Reason: no code change is needed; verification only.*
- **State legislators and local officials** — separate coverage streams.
- **Territories (DC/PR/GU/etc.)** — DC executives covered in v2.8; territorial execs out of scope here.

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEXR-01 | TBD (roadmap) | pending |
| SEXR-02 | TBD (roadmap) | pending |
| SEXR-03 | TBD (roadmap) | pending |
| SEXR-04 | TBD (roadmap) | pending |
| SEXR-05 | TBD (roadmap) | pending |
| SEXS-01 | TBD (roadmap) | pending |
| SEXS-02 | TBD (roadmap) | pending |
| SEXS-03 | TBD (roadmap) | pending |

*Traceability filled by the roadmapper.*
