# Project Research Summary

**Project:** v2026.3.3 — Local Government Organization
**Domain:** Civic tech — government body display, state-specific structure, website links
**Researched:** 2026-03-10
**Confidence:** HIGH

## Executive Summary

This milestone is a targeted display and data-modeling improvement to the existing Essentials app. It does not introduce new frameworks, external services, or infrastructure. The core problem is that section headings in the Results page show generic labels ("County Legislators") instead of specific body names ("Monroe County Council"), and no official website links exist at the body level. Both gaps are solvable within the current stack through one new lookup table, two extended API fields, and minimal changes to `classify.js`, `Results.jsx`, and the ev-ui `CategorySection` component.

The recommended approach is to create a new `essentials.government_bodies` table keyed on a combination of TIGER GEO_ID, state, and classifier body key. This table is populated manually (not via any import pipeline), keeps the data out of Cicero-synced tables that risk overwrite, and allows per-body website URLs and display names to be added for new jurisdictions without code changes. The body metadata is embedded in the existing `OfficialOut` search response via a LEFT JOIN — no new frontend API calls are needed.

The primary risk is the Indiana dual-body county structure: Indiana counties have constitutionally distinct Commissioners (executive) and Council (fiscal) bodies that currently map to a single "County Legislators" section. Before any classification code is written, the actual `chamber_name` and `chamber_name_formal` values in the DB must be inspected. If those fields already differ between commissioners and council members, the frontend split is trivial. If they do not, a data correction precedes the feature work. All other features in this milestone are confirmed data-first, code-second.

## Key Findings

### Recommended Stack

No new technologies are introduced. The existing stack handles everything: Go 1.24.3 / GORM / PostgreSQL for the new table and JOIN, React 19 / Vite / Tailwind CSS 4 for the frontend changes, and ev-ui for the `CategorySection` prop addition. The new `GovernmentBody` model follows the identical pattern as the existing `PositionDescription` enrichment table — a lookup keyed on stable string values, not FK-coupled to import-managed tables.

**Core technologies:**
- Go / GORM: Add `GovernmentBody` model; AutoMigrate creates table; extend `OfficialOut` with two optional fields populated via LEFT JOIN
- PostgreSQL (Supabase): Store `essentials.government_bodies` with composite unique on `(state, geo_id, body_key)`; no changes to existing tables
- React 19 / essentials app: Read `government_body_name` and `government_body_url` from API response; derive section titles per group in `Results.jsx`
- ev-ui 0.1.40 → 0.1.41: Add optional `websiteUrl` (or `titleHref`) prop to `CategorySection`; backward compatible; existing callers unaffected

**Version requirement:** ev-ui must publish 0.1.41 before the essentials frontend can consume the new prop. This is the only cross-repo dependency in the build order.

### Expected Features

**Must have (table stakes):**
- Specific body name in section headings — "Monroe County Council" instead of generic "County Legislators"; data already in API via `chamber_name_formal`, pure frontend change
- Distinct sections for Commissioners vs. Council — Indiana's executive and fiscal county bodies are constitutionally separate; showing them merged is incorrect and misleads users
- County Officials as a consistently distinct section — Sheriff, Assessor, Clerk, Treasurer, Recorder, Coroner, Surveyor are independently elected; classify.js fall-through paths currently misroute some of them
- Official website link per body section — users need the body's site (for meetings, contacts, agendas), not individual politician contact pages
- Township name specificity — covered automatically by the same heading-qualification logic; no extra work

**Should have (competitive):**
- At-large vs. district badge on council member cards — `district_label` already in `OfficialOut`; rendering change only; defer until sections are specific
- Role description under section heading — one-sentence static copy per body type; low effort; ship after heading names are confirmed correct
- State-configurable body config — Indiana-specific rules as named constants now; design interface so CA expansion is a config change, not a code change

**Defer (v2+):**
- Full state-configurable body structure (CA Board of Supervisors vs. Indiana commissioners + council split)
- Meeting/agenda deep links per body
- Automated body website discovery (unacceptably low accuracy for civic use)
- Full organizational chart / hierarchy visualization
- Expansion to all 92 Indiana counties (pipeline is repeatable; website data entry is the manual step per county)

### Architecture Approach

The change is an additive enrichment layer on the existing search response. A new `essentials.government_bodies` table provides per-body display name and URL, keyed by `(state, geo_id, body_key)`. The backend derives `body_key` via a new `classify.go` pure function that mirrors `classify.js` logic, then performs a single batch join after geofence lookup to annotate `OfficialOut` records. The frontend reads the two new optional fields per politician, derives the section title and URL from the first matching politician in each group, and passes them as a new prop to `CategorySection`. The entire change degrades gracefully: jurisdictions without `government_bodies` rows display identically to today.

**Major components:**
1. `essentials.government_bodies` table — stores specific body display names and website URLs; manually curated; keyed by TIGER GEO_ID + body_key; unique constraint `(state, geo_id, body_key)` makes it upsert-safe
2. `classify.go` (new Go file) — pure function mirroring classify.js; produces body_key for the DB lookup; must stay in sync with classify.js; unit-testable
3. `GovernmentBody` GORM model + modified `SearchPoliticians` handler — adds model, AutoMigrate, batch join post-geofence, and two optional fields on `OfficialOut`
4. `Results.jsx` update — reads new fields per group, derives section title and URL from `polList.find(p => p.government_body_name)`, passes to `CategorySection`
5. ev-ui `CategorySection` update — adds optional `websiteUrl` prop with inline external-link SVG icon; one optional prop; no sub-section concepts; minor version bump and publish

### Critical Pitfalls

1. **String-matching classification breaks silently** — `classify.js` uses `includes()` keyword matching. Adding state-specific rules without verifying actual DB strings causes silent politician misrouting (wrong section, no error, no visible failure). Prevention: audit DB for actual `chamber_name` and `chamber_name_formal` values first; add a classification regression test before touching classify.js.

2. **Indiana dual-body structure may not be distinguishable from current data** — Commissioners and Council may share the same `chamber_name_formal` in the DB, making a frontend split impossible without a data migration. Prevention: run `SELECT DISTINCT chamber_name, chamber_name_formal FROM essentials.chambers ... WHERE state = 'IN'` before writing any classification code.

3. **New group keys must be added to three separate structures simultaneously** — Adding a new `classifyCategory()` group key without updating `LOCAL_ORDER`, `CATEGORY_DISPLAY_NAMES`, and `GROUP_SORT_OPTIONS` causes sections to appear in wrong positions or display raw key strings. Prevention: treat these three as an atomic update; never add a group key in isolation.

4. **Website links require data collection that is chronically underestimated** — The schema change is trivial; finding and verifying official body URLs for Monroe County is the real work. Prevention: complete URL research before writing any frontend code; treat data population as a prerequisite that must finish before the schema migration is deployed.

5. **`qualifyLocalTitle()` produces double-prefixed names when applied to section headers** — This existing function is designed for card titles ("County Council" → "Monroe County Council"), not section headers where `government_body_name` already contains the government prefix. Calling it on section headers produces "Monroe County Monroe County Council." Prevention: use `government_body_name` from the new API fields directly for section headers; keep `qualifyLocalTitle()` for card titles only.

## Implications for Roadmap

Based on combined research, the build order is strictly data-first, then backend, then frontend. Dependencies between components make parallelism possible only in specific windows. A 6-phase structure is recommended.

### Phase 1: DB Audit and Data Verification

**Rationale:** Every subsequent decision — whether classify.js needs changes, what body_key values to use, whether the Indiana dual-body split is a code change or a data migration — depends on what is actually in the DB. This is not optional groundwork; it gates Phase 2.
**Delivers:** Confirmed list of Indiana chamber `name_formal` values; known classification gaps for Monroe County officials; verified TIGER GEO_ID for Monroe County (18105); regression test list of known politician-to-expected-group mappings; confirmed whether Commissioners and Council produce distinct group keys from current data.
**Addresses:** Pitfalls 1, 2, and 5 (all three require knowing actual DB values before writing code).
**Avoids:** Writing classifier logic that does not match DB data; discovering the Indiana body split requires a data migration after code is written.

### Phase 2: Backend — GovernmentBody Table and OfficialOut Extension

**Rationale:** The frontend cannot be built until the API delivers the new fields. The table must exist before data can be seeded. This phase establishes the new data layer.
**Delivers:** `essentials.government_bodies` table live in Supabase via AutoMigrate; `GovernmentBody` GORM model in `models.go`; `classify.go` pure function with unit test against Phase 1 data; `OfficialOut` extended with `government_body_name` and `government_body_url`; batch join in `SearchPoliticians` handler; admin CRUD endpoints for curation.
**Uses:** Go / GORM (no new packages); LEFT JOIN in existing raw SQL queries following established pattern.
**Implements:** GovernmentBody model, classify.go, modified SearchPoliticians handler, admin endpoints.
**Avoids:** Pitfall 4 (data layer complexity); Pitfall 2 (Indiana body distinction via body_key, not fragile title keywords).

### Phase 3: Data Seeding — Monroe County and Bloomington Bodies

**Rationale:** Data seeding is the prerequisite for any visible frontend change. The schema exists after Phase 2; this phase populates it. Scoped strictly to covered jurisdictions — Monroe County IN and Bloomington IN.
**Delivers:** Populated rows for Monroe County Commissioners, Monroe County Council, Bloomington City Council, and elected officials page URLs. Verified correct `body_key` values matching `classify.go` output from Phase 2. LA County body names verified as stretch goal (likely auto-correct via heading logic).
**Addresses:** FEATURES.md official website link requirement; confirms that `body_key` strings in seed data exactly match `classify.go` output.
**Avoids:** Pitfall 4 (URL research completed and verified before frontend work; no broken or empty links).

### Phase 4: classify.js Updates (Conditional on Phase 1 Findings)

**Rationale:** Only needed if Phase 1 shows that Monroe County Commissioners and Council members map to the same group key in `classifyCategory()`. If they already produce distinct group keys from `chamber_name_formal`, this phase is a no-op and can be skipped entirely. Gate this work on Phase 1 output.
**Delivers:** Distinct "County Commissioners" and "County Council" group keys (if needed); `LOCAL_ORDER`, `CATEGORY_DISPLAY_NAMES`, and `GROUP_SORT_OPTIONS` updated atomically in the same commit; County Officials fall-through paths audited and cleaned up.
**Addresses:** FEATURES.md commissioners vs. council distinct sections; County Officials consistent routing.
**Avoids:** Pitfall 3 (simultaneous atomic update of all three consumer structures); Pitfall 1 (regression test from Phase 1 run as verification before merge).

### Phase 5: ev-ui CategorySection Update and Publish

**Rationale:** The `websiteUrl` prop addition is a cross-repo dependency. Must be published before the essentials frontend can consume it. This phase is independent of Phases 2-4 and can run in parallel with those phases.
**Delivers:** ev-ui 0.1.41 published to GitHub npm registry; `CategorySection` renders an external-link SVG icon when `websiteUrl` is provided; inline SVG (no icon library import); existing callers unaffected.
**Implements:** Minimal ev-ui change; one optional prop; minor version bump.
**Avoids:** Pitfall 6 equivalent (minimal prop addition only; no sub-section redesign; no ev-ui scope creep; no `target="_self"` links).

### Phase 6: Frontend — Results.jsx Section Titles and Links

**Rationale:** Depends on ev-ui 0.1.41 (Phase 5) and backend fields (Phase 2). This is the user-facing delivery phase.
**Delivers:** Section headings show specific body names for covered jurisdictions, generic fallback for all others; external website link rendered in section header when URL is present; at-large vs. district card subtitles verified working via existing `dashIdx` logic; cross-jurisdiction boundary test confirming graceful fallback when multiple counties appear.
**Addresses:** All P1 features from FEATURES.md prioritization matrix.
**Avoids:** Pitfall 5 (use `government_body_name` from API directly, never pass through `qualifyLocalTitle()`, for section headers); Pitfall 1 (classification verified in Phase 1 before this renders); UX pitfall of same-tab external links (`target="_blank" rel="noopener noreferrer"`).

### Phase Ordering Rationale

- Phase 1 is mandatory before everything else. Both ARCHITECTURE.md and PITFALLS.md explicitly flag "verify actual DB values before writing code" as the make-or-break condition for this milestone.
- Phase 2 before Phase 3: table must exist before data can be inserted.
- Phase 4 is conditional: if Phase 1 shows commissioners and council already produce distinct keys, skip Phase 4 and merge any cleanup into Phase 2.
- Phase 5 can run in parallel with Phases 2-4: ev-ui change has no dependency on backend or data work.
- Phase 6 is last: requires ev-ui 0.1.41 (Phase 5) and populated backend data (Phases 2-3).

### Research Flags

Phases requiring caution during execution:
- **Phase 1:** Not a code phase, but the most consequential one. If `chamber_name_formal` is unpopulated for Indiana chambers, this milestone becomes a data migration milestone before it becomes a display milestone. Plan for both branches.
- **Phase 4:** Conditional and must not start until Phase 1 results are confirmed. If classify.js changes are needed, the regression test list from Phase 1 is mandatory verification before merge.

Phases with standard, well-understood patterns:
- **Phase 2:** Direct pattern match to existing `PositionDescription` table and admin CRUD endpoints. STACK.md documents the exact Go model code. No inference needed.
- **Phase 3:** SQL INSERT via admin API endpoint or direct SQL. Well-understood data entry step.
- **Phase 5:** ev-ui minor version bump following the established publish pattern used for every ev-ui release. One optional prop following the `infoTooltip` precedent already on `CategorySection`.
- **Phase 6:** Pure frontend composition. Data arrives in the search response; rendering logic is additive with graceful fallbacks; no new state management.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct codebase inspection of models.go, handlers.go, classify.js, CategorySection.jsx, package.json files. No inference or third-party source needed — the codebase is the source of truth. |
| Features | HIGH | Confirmed via Monroe County and Bloomington official government sites and Indiana state resources. Existing codebase fields verified present in API response. Industry standard (BallotReady, Google Civic API) confirmed the "specific name at display layer" approach. |
| Architecture | HIGH | Based on direct inspection of all relevant source files. Build order and component responsibilities verified against actual code. ARCHITECTURE.md documents the exact before/after data flow. |
| Pitfalls | HIGH | All six pitfalls derived from actual codebase patterns — classify.js keyword matching logic, LOCAL_ORDER coupling, qualifyLocalTitle double-prefix behavior. Verified from code, not inferred from general patterns. |

**Overall confidence:** HIGH

### Gaps to Address

- **Indiana `chamber_name_formal` population (Phase 1 critical):** The single unresolved unknown. Whether `chambers.name_formal` is populated for Monroe County Commissioners and Monroe County Council is not confirmed from research — it requires a direct DB query. If empty, the key question shifts from "how do we split them in classify.js?" to "how do we populate `name_formal` in the DB?" and a data correction precedes all feature work.

- **Exact body_key strings for government_bodies seeding:** The `body_key` values used in the seeding SQL must exactly match what `classify.go` produces for Indiana officials. Phase 1's DB audit produces the definitive list. Do not guess these strings — a mismatch causes the JOIN to silently return NULL and the feature to appear broken for Indiana officials.

- **LA County body coverage:** Research scoped website link collection to Monroe County / Bloomington. LA County has hundreds of bodies and is not targeted for website links this milestone. Verify that the heading qualification change (using `government_body_name` from the new table where available) does not regress existing LA County rendering — section titles for LA County officials should fall back gracefully to `getDisplayName(category)`.

## Sources

### Primary (HIGH confidence)
- `EV-Backend/internal/essentials/models.go` — GORM model structure; Chamber, Government, and PositionDescription patterns that `GovernmentBody` follows
- `EV-Backend/internal/essentials/handlers.go` — OfficialOut struct, SQL query patterns, LEFT JOIN structure, chamber_name_formal availability in response
- `EV-Backend/internal/essentials/geofence_lookup.go` — geo_id / MTFCC structure, district type mapping, OfficialOut composition
- `essentials/src/lib/classify.js` — full classification logic, LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, group key strings, hasAny() matching behavior
- `essentials/src/pages/Results.jsx` — rendering pipeline, qualifyLocalTitle() implementation, subtitle dashIdx pattern, CategorySection usage
- `ev-ui/src/CategorySection.jsx` — existing component API; infoTooltip prop as established pattern for optional extras on this component
- `ev-ui/package.json` — current version 0.1.40 confirmed
- `essentials/package.json` — ev-ui consumer at ^0.1.40 confirmed

### Secondary (MEDIUM confidence)
- Monroe County official site (co.monroe.in.us) — commissioners and council structure; confirmed separate body pages and URLs
- Bloomington City Council (bloomington.in.gov/council) — 9-member structure; 6 district + 3 at-large confirmed
- Indiana DLGF — county commissioners statutory structure; constitutional basis for dual-body model
- Indiana SBOA — township trustee and advisory board structure; single trustee + 3-member board model

### Tertiary (reference only)
- NACo Indiana County Overview PDF — dual-body county structure context; confirms the structure is statewide across all 92 Indiana counties
- Google Civic Information API reference — industry standard for body name composition at the display layer (officeName + divisionName)
- BallotReady `websiteUrl` per office — confirms industry standard of storing one canonical URL per government body

---
*Research completed: 2026-03-10*
*Ready for roadmap: yes*
