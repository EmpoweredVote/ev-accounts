# Phase 154: Field Resolution + Stance-Gap Diagnostic - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

A **read-only, write-free diagnostic** that gates all Wave-2 seeding. It produces, for the v2.21 states:

1. A per-district **Nov-3 general-ballot field table** — every ballot-qualified candidate per district.
2. An **incumbent-not-nominee flag** on every district where the 2024 incumbent is not the 2026 nominee (lost-primary / retirement / open-seat / vacancy / deceased / redistricted).
3. An **incumbent → existing `politician_id` map** (mapped by `(NATIONAL_LOWER, geo_id)`, never computed external_id) plus current stance count per incumbent.
4. A **per-state / per-district new-record + stance-gap enumeration** — the authoritative input each seeding phase consumes so no phase creates a duplicate incumbent or surfaces a non-candidate.

Analog of Wave-1's Phase 148. Writes NO production rows; output is diagnostic artifacts + a write-free `154-verify.sql` gate.

**Scope split (see D-01):** Phase 154 **fully resolves the 6 decided states** (PA/IL/OH/GA/NC/NJ = 89 districts) and builds the incumbent `politician_id` map for **all 8 states incl. MI and VA**. It does **not** resolve MI's or VA's 2026 *nominees* — both congressional primaries are Aug 4, 2026, so nominee resolution for both is deferred to the date-gated Phase 159 (MI+VA). MI and VA districts appear in the field table tagged `pending-primary (Aug-4)`.

> **CORRECTION (applied at planning, 2026-06-30):** This CONTEXT originally listed VA among the "7 decided states (100 districts)." That is **wrong** — Virginia moved its 2026 congressional primary from June to **August 4, 2026** (verified against the VA Dept. of Elections + Ballotpedia in `154-RESEARCH.md`). VA is therefore `pending-primary (Aug-4)`, identical to MI, and is folded into the date-gated Phase 159. Decided scope is **6 states / 89 districts**; deferred is **MI 13 + VA 11 = 24**; total still 113. All D-01 references below are read with VA == MI treatment.

</domain>

<decisions>
## Implementation Decisions

### MI primary timing (Aug 4, 2026 — after the build window)
- **D-01:** MI **and VA** are handled as a **date-gated final phase**, NOT provisional-seeded. Build the 6 decided states now (89 districts: PA/IL/OH/GA/NC/NJ); a separate **date-gated Phase 159 (≥ 2026-08-04)** seeds MI's *and VA's* *real* nominees. No provisional MI/VA records, no two-path prune. This keeps the committed 113-district scope and avoids the FL/Wave-1 prune churn (both have near-term Aug-4 primaries, so waiting for real results is cheaper than provisional + prune).
- **D-01a:** Phase 154 still produces the **MI and VA incumbent `politician_id` map + stance-gap** now (their incumbents are already seeded v2.15–v2.17 and don't depend on the primary). Only the MI/VA *nominee/challenger field* is deferred. MI and VA districts appear in the field table tagged `pending-primary (Aug-4)`. (Exception: VA-11's current member Walkinshaw was special-seated Sep 2025, post-v2.17 — he is a new-record need, not a mappable incumbent; see D-04a.)
- **D-01b:** **Roadmap restructuring APPLIED at planning (2026-06-30):** Phase 157 = **NJ-only (12 districts)**; the Phase 158 gate covers the **89 decided-state districts (PA/IL/OH/GA/NC/NJ)**; Phase 159 = **date-gated MI+VA (24 districts, ≥ Aug 4)** that seeds MI+VA nominees + verifies (MI+VA mini-gate). The milestone closes after Phase 159. (Updated from the original split which placed VA in Phase 157 as "decided" — see the CORRECTION banner above.)

### Partial-incumbent stance top-up
- **D-02:** **Report only, no top-up.** The diagnostic surfaces incumbents below the federal-24 threshold for visibility, but Wave-2 stance research covers only **genuinely-new candidates + zero-stance incumbents**. Partial-stance incumbents (already partially covered in v2.16/v2.17) are left untouched. Inherits Wave-1 policy (NY partials were explicitly untouched). USHC2-05 only covers candidates *lacking* stances.

### Candidate inclusion bar (field table)
- **D-03:** Include **every candidate officially on the Nov-3 general ballot** — major-party nominees + ballot-qualified independents/third-party + officially-certified write-ins. The bar is *ballot-qualified for the Nov-3 general* — exclude primary-only also-rans and uncertified write-ins. No-record minor candidates become **whole-record honest-skips** downstream (pipeline handles this, gate-pinned by id).

### Vacancy / special seats (NJ-11, VA-11, GA-13)
- **D-04:** Resolve the **current officeholder AND the 2026 nominee from an official/results source** — never from 2024 incumbency. Known cases to verify at plan time: **VA-11** (Connolly died/retired 2025 — a 2025 special likely seated a new member), **NJ-11** (Sherrill vacated after winning the NJ governorship), **GA-13** (flagged open/vacancy).
- **D-04a:** Any **current member seated by a post-v2.17 special election** (so not yet in our DB) is enumerated as a **new-record need** for the seeding phase, exactly like a challenger — NOT mapped to a stale incumbent. Tag each such race via the nominee-status taxonomy (`vacancy` / `special-seated` / `open-seat`). **No ghost incumbent records.**

### Claude's Discretion
- Field-resolution source per state (state SoS/board-of-elections results vs Ballotpedia vs Wikipedia/raw-wikitext), diagnostic artifact format/location (scratch CSV layout, query structure), and the exact `154-verify.sql` assertion set — researcher/planner decide, following the inherited Wave-1 conventions (`148-verify.sql` is the template). Primary-source rigor preferred (official state results over aggregators where reachable).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & methodology (locked)
- `.planning/REQUIREMENTS.md` — v2.21 requirements (USHC2-01 owns this phase); "Method (settled)" section.
- `.planning/ROADMAP.md` §"v2.21 … Phases 154–158" — full carry-forward execution methodology (production ref `kxsdzaojfaibhuzmclfq`; `race_candidates` shape; external_id scheme `-(state_fips*10000+cd*100+seq)` with per-state FIPS; stance pipeline; fetch-walls; VA/NJ special notes). **NOTE:** the roadmap's "all 8 states decided" claim is superseded by D-01 (MI is Aug-4 provisional → date-gated).
- `.planning/STATE.md` §"v2.20 Execution Methodology" + Decisions log — the proven Wave-1 patterns this phase inherits.

### Wave-1 analog (the template to mirror)
- `.planning/milestones/v2.20-ROADMAP.md` §"Phase 148: Field Resolution + Stance-Gap Diagnostic" — the diagnostic this phase mirrors.
- `backend/scripts/148-verify.sql` — write-free field-resolution gate; `154-verify.sql` follows its shape.
- Phase 148 decisions (in STATE.md): incumbent map by `(NATIONAL_LOWER, geo_id)` not computed external_id; 7-value nominee-status taxonomy (renominated / retired / redistricted / lost-primary / vacancy / deceased / incumbent-redistricted); `races.office_id → offices.district_id → districts.geo_id` join (races has no direct geo_id).

### Stance scale (for the gap diagnostic's threshold)
- `_TOPIC_SCALE_FULL.txt` (federal 24-topic set; built/used in v2.20) — defines the "federal-24" denominator for the stance-gap report. (Confirm current vs live DB at plan time.)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/148-verify.sql` — write-free gate template; clone its `DO $$ … RAISE EXCEPTION` assertion style for `154-verify.sql`.
- `backend/src/lib/db.js` `pool` + `import 'dotenv/config'` — canonical diagnostic-query path when MCP Supabase tokens expire (~1h). Scripts must live inside `backend/` to resolve `node_modules`.
- Incumbent-map query pattern: join `essentials.politicians → offices → districts` filtered `district_type='NATIONAL_LOWER'`, keyed by `geo_id`.

### Established Patterns
- Incumbent identity is resolved by `(district_type, geo_id)`, never `-(fips*1000+cd)` (mis-keys CA/TX — and by extension any state; verified in Phase 148).
- Diagnostic phases are READ-ONLY: no migrations, no INSERTs. Output = artifacts + verify SQL that asserts read-only facts.
- Stance-gap filter: `LEFT JOIN inform.politician_answers` counting per `politician_id` (the v2.18 stance-gap diagnostic pattern).

### Integration Points
- Output feeds Phases 155 (PA+IL), 156 (OH+GA+NC), 157 (NJ+VA per D-01b), and the new date-gated MI phase — each consumes the per-state new-record list + incumbent `politician_id` map.

</code_context>

<specifics>
## Specific Ideas

- MI 2026 congressional primary confirmed **Aug 4, 2026** (Michigan SoS election-dates PDF; Congress Countdown) — the basis for D-01.
- **VA 2026 congressional primary is ALSO Aug 4, 2026** (VA moved it from June to August; verified VA Dept. of Elections + Ballotpedia "August 4 primary" district pages, `154-RESEARCH.md`). The earlier "VA decided" note here was wrong — superseded by the CORRECTION banner above.
- Per-state primary status (verified 2026-06-30): PA, IL, OH, GA, NC, NJ primaries held by the build window (`decided`); **MI and VA are both undecided** (Aug-4 primaries).
- Field table must mark **MI (13) and VA (11)** rows `pending-primary (Aug-4)` and the **6 others (PA/IL/OH/GA/NC/NJ = 89)** `decided`.

</specifics>

<deferred>
## Deferred Ideas

- **MI nominee seeding** — the date-gated MI phase (≥ 2026-08-04), per D-01. Not Phase 154.
- **Roadmap edit (D-01b)** — split 157 → NJ+VA; 158 gate scopes to 100 decided-state districts; add the date-gated MI phase. Apply via `/gsd-phase` before/at planning, or have the planner account for it. (Distinct from the v2.20 FL Phase-153 carry-forward, which remains separate.)
- **Partial-incumbent top-up** — surfaced but explicitly out of scope (D-02); a candidate for a future data-quality pass, not this milestone.
- **Challenger FEC `finance_summary`** — out of scope for v2.21 (Wave 3+), per REQUIREMENTS.md.

</deferred>

---

*Phase: 154-field-resolution-stance-gap-diagnostic*
*Context gathered: 2026-06-30*
