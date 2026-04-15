# Phase 117: Candidate Stub Resolution + Data Import - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

For contested Monroe County May 5, 2026 primary races, resolve ~30 stub `essentials.race_candidates` rows (where `politician_id IS NULL`) by creating minimum-viable politician records — name, office, photo (or placeholder), 1-line bio — so Essentials profiles render and the Compass politician picker works for those candidates.

Phase is **gated by a pre-code feasibility evaluation** (CAND-01) that must exist before any import scripts are written. If sourcing slips past April 25, scope drops to the highest-impact 5–10 contested-race candidates only.

Phase also closes a prior model-level defect: creating politician rows for non-incumbent candidates currently leaks them into address-lookup results as if they held office. Phase 117 fixes this in the same commit wave by adding an `is_candidate` flag and filtering it out of the resolver.

</domain>

<decisions>
## Implementation Decisions

### Feasibility Gate (CAND-01)

- **D-01:** Feasibility evaluation is delivered as a tiered markdown document (`117-FEASIBILITY.md`) in the phase directory. Groups all stub candidates into **Confirmed-sourceable / Partial / Unsourceable** tiers. Includes a prioritized "scope-down 5-10" list identifying which candidates survive if April 25 forces a scope cut.
- **D-02:** Claude performs **real sourcing** during feasibility — not just availability checks. For each stub, actually attempts to retrieve: clerk filing row, candidate website/social, local press mention. Records source URLs and data found (name / office / photo / bio Y|N) per candidate in the feasibility doc.
- **D-03:** Go/no-go on April 25 is a **planner's-call discussion**, not a hard numeric threshold. Both parties review `117-FEASIBILITY.md` together and decide based on data quality + contested-race coverage, not a percentage cutoff.
- **D-04:** Feasibility evaluation must be committed BEFORE any import script is written or any migration runs. The planner MUST NOT schedule code work in parallel with sourcing.

### Data Sourcing Strategy

- **D-05:** Source priority order: **Monroe County Clerk filings first** (CAN-2 forms are authoritative for name, office, party spelling), then candidate website/social for photo + bio, then local press as fallback. Every imported field records its source URL.
- **D-06:** For candidates with no sourceable photo AND no sourceable bio: import name + office anyway with **reused ev-ui missing-photo fallback** and an office-title-only bio (`Candidate for [office title]`). Profile still loads, Compass picker still works, CAND-03 minimum met.
- **D-07:** Bios are **extracted + lightly compressed** from a single named source — never LLM-synthesized across multiple sources and never augmented with claims not present in the source. Source URL stored alongside the bio text. This is non-negotiable; hallucinated bios before a primary are a reputational risk.

### Candidate-vs-Politician Data Model Fix

- **D-08:** Add `essentials.politicians.is_candidate BOOLEAN NOT NULL DEFAULT false` via migration. Column semantics: `true` means "this row represents an active candidate, not a sitting official."
- **D-09:** Update `essentialsService` (the address-resolver path) to **exclude `is_candidate = true`** from tier-grouped address-lookup results. Candidates still appear in the Compass picker and in race listings — only the "these are your current representatives" surface filters them out.
- **D-10:** **Backfill** `is_candidate = true` for any existing politician row that is linked via `essentials.race_candidates` with `is_incumbent = false`. Closes the broader pre-existing leakage in the same migration pass. Backfill runs in the same migration that adds the column.
- **D-11:** Phase 117's 30 new imports all get `is_candidate = true`. Incumbents linked to contested races are unaffected (they remain `is_candidate = false` because they're sitting officials even while running again).

### Photo + Bio Minimum Bar (CAND-03)

- **D-12:** Photo placeholder = **reuse whatever ev-ui currently renders for missing photos** on PoliticianProfile. Planner verifies the existing fallback is adequate; no new placeholder asset introduced in this phase. Must be party-agnostic (antipartisan principle).
- **D-13:** Sourced photos land in **Supabase Storage CDN** following the existing scraped/re-hosted pattern: download from source → upload to politician headshots bucket → store CDN URL in `essentials.politician_images`. No direct hotlinking to candidate sites (breakage risk before May 5).
- **D-14:** Bio content bar = **one sentence, ~120-180 characters**, naming current profession or reason-for-running. Example: "Monroe County educator running for County Council District 3." Source citation stored alongside the bio (column TBD by planner — `bio_source_url` on politicians, or a separate `politician_sources` join).

### Claude's Discretion

- Exact column name and placement of source-citation field (`bio_source_url` on politicians vs separate audit table).
- Whether to reuse existing staging workflow (`stagingService`) or write a one-shot import script. Planner should evaluate both against the feasibility output.
- Exact migration filename numbering (next in sequence after current max in `ev-accounts/backend/migrations/`).
- Whether the `is_candidate` filter happens in SQL (join clause) or in application code — whichever is cleaner given current `essentialsService` shape.

### Folded Todos

_No todos folded from cross_reference_todos — relevant memory notes (candidates-vs-politicians leak) were surfaced through prior_decisions loading, not todo matching._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-defining docs
- `.planning/ROADMAP.md` §Phase 117 — Goal, requirements, success criteria, feasibility gate language
- `.planning/REQUIREMENTS.md` §Tier 1 Candidate Stubs — CAND-01 through CAND-05 definitions
- `.planning/STATE.md` — Tier 1 deadline (May 1), Phase 117 feasibility-gate decision (April 25 scope-drop trigger)
- `.planning/BACKLOG.md` §Phase 117 — "CRITICAL FEASIBILITY DEPENDENCY" note on lead time and scope-down criteria

### Prior art in codebase
- `ev-accounts/backend/scripts/audit-112-candidates.ts` — Defines what a "stub" is (`race_candidates.politician_id IS NULL`) and produces per-race linked vs stub counts. Run this to get the authoritative stub list for feasibility sourcing.
- `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql` — Existing idempotent linking script (last-name match + first-name disambiguation). Reference for linking logic if new imports should auto-link to any already-existing politician rows.
- `ev-accounts/backend/scripts/discover-indiana-candidates.ts` — Prior discovery pipeline; may contain sourcing utilities worth reusing.

### Data model
- `ev-accounts/backend/src/lib/essentialsService.ts` — Address-resolver path. This is where the `is_candidate = true` filter MUST be applied to prevent the address-leakage bug.
- `ev-accounts/backend/src/lib/stagingService.ts` — Existing volunteer data-entry workflow. Planner evaluates whether to route Phase 117 imports through staging review or a one-shot script.
- `ev-accounts/backend/src/lib/candidateService.ts` — Existing candidate-surface service; inspect for shared helpers before writing new ones.
- `ev-accounts/backend/migrations/` — Next migration number lands `is_candidate` column + backfill.

### Schema context (from CLAUDE.md)
- `essentials.politicians` — Core politician record; Phase 117 adds `is_candidate` column and inserts ~30 new rows with it set to `true`.
- `essentials.race_candidates` — Source of truth for stubs via `politician_id IS NULL`. Phase 117 populates `politician_id` as new rows are created.
- `essentials.politician_images` — Supabase CDN URL storage for re-hosted photos.
- `essentials.offices` / `essentials.chambers` / `essentials.districts` — Scaffolding that must already exist for each contested race. Planner verifies during research before import.

### Memory-derived context
- Memory note `project_candidates_vs_politicians.md` — Documents the address-leakage problem this phase now fixes. Relevant for writing the migration commit message and the `is_candidate` doc comment.
- Memory note `feedback_antipartisan.md` — Placeholder/bio content must not use partisan color associations or party framing.

### Prior phase context
- `.planning/phases/116-quick-correctness-fixes/116-CONTEXT.md` — Establishes the Tier 1 May 1 deadline context and the single-source-of-truth principle for nav (not directly reused here but sets the milestone cadence).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`audit-112-candidates.ts`** — Already produces the stub inventory. Feasibility doc derives its row list from this script's output, not a fresh query.
- **`link-monroe-candidates-to-politicians.sql`** — Idempotent linking via last-name match. Pattern to follow for any "auto-link new import to existing politician if name collides" safety check.
- **`stagingService.ts`** — Full volunteer data-entry workflow with review/approval already exists. Planner should evaluate using it vs a bespoke import script.
- **ev-ui `PoliticianProfile`** — Already renders some missing-photo fallback; reuse rather than introduce a new placeholder asset.
- **Supabase Storage CDN pattern** — Existing scraped/re-hosted photo pipeline per CLAUDE.md. Follow exactly; don't invent a new upload path.

### Established Patterns
- **Stub definition is a FK nullability pattern**, not a "politician with missing fields" pattern. Every decision must respect this.
- **Antipartisan rendering** — No party colors in placeholders, bios, or profile content.
- **Source citation** — All essentials data that was scraped or re-hosted records its origin; bios must follow the same discipline.
- **Migration + backfill in one step** — Existing migrations (e.g., `064_backfill_city_council_geo_id.sql`, `067_backfill_municipality_geo_id.sql`) already combine schema change + backfill in a single file. Follow that pattern for `is_candidate`.

### Integration Points
- **`essentialsService` address resolver** — Single point where `is_candidate` filter must land to close the leak. Changing the SQL/query here propagates to Essentials address lookup automatically.
- **Compass politician picker** — Consumes politician rows via the existing API; gets the new candidates "for free" once they're inserted. Verify nothing in the picker's query excludes `is_candidate = true` — it should NOT filter the same way the address resolver does.
- **`essentials.race_candidates.politician_id`** — Populated as a side effect of each new import. The import script must UPDATE the stub row to point at the new politician id, or the stubs remain stubs.

</code_context>

<specifics>
## Specific Ideas

- **Feasibility doc as a planner's-call artifact, not a gatekeeper script** — The go/no-go on April 25 is a human conversation using the feasibility doc as evidence. Not a CI check, not a numeric threshold.
- **Contested races are the non-negotiable coverage target** — D-61 IN House, IN-9 US House, and contested Monroe County offices. If scope drops, these survive. Uncontested stubs drop first.
- **`is_candidate` fix is scoped INTO this phase deliberately** — The memory note flagged it as a separate concern, but since Phase 117 is the first phase to bulk-insert candidate politicians, it's cheapest to fix here and prevents making the bug worse.
- **Backfill via `is_incumbent = false` from race_candidates** is the cleanest signal available — any existing politician that's already marked as a non-incumbent candidate in the race linkage table is definitionally an active candidate.

</specifics>

<deferred>
## Deferred Ideas

- **Full candidate/politician table split** — Long-term, the right model is a separate `candidacies` table joined to a unified `people` table. Memory note tracks this. Phase 117 uses the `is_candidate` flag as a pragmatic patch; a post-primary phase can do the full restructure without deadline pressure.
- **Candidate Q&A / response tracking** — Benchmark gap noted in `.planning/BACKLOG.md` as deliberately excluded (Vote411/VoteSmart/Ballotpedia feature). v2026.5.x or later.
- **Withdrawn candidate status tracking** — Benchmark gap in same BACKLOG.md exclusion list. New data category, not in scope.
- **Automated candidate discovery pipeline expansion** — `discover-indiana-candidates.ts` exists; expanding it to fully automate future stub detection is Phase 123+ pipeline work, not this phase.
- **Staging workflow vs one-shot script decision** — Flagged as planner discretion (D-decisions under Claude's Discretion). Planner evaluates, doesn't need to come back to discuss-phase.

</deferred>

---

*Phase: 117-candidate-stub-resolution-data-import*
*Context gathered: 2026-04-14*
