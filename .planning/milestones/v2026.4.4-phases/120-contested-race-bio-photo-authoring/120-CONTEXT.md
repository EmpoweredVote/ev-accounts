# Phase 120: Contested-Race Bio + Photo Authoring - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Author bios and source headshots for ~5-10 candidates in contested Monroe County May 5 races (D-61 IN House, IN-9 US House, contested county offices). The highest-visibility profiles are complete before primary day. This is a content authoring phase — the data model and import infrastructure already exist from Phase 117.

</domain>

<decisions>
## Implementation Decisions

### Candidate Scope
- **D-01:** Start from the Phase 117 feasibility output (`117-FEASIBILITY.md`) as the primary candidate list for contested Monroe County races.
- **D-02:** Supplement the feasibility doc with a DB audit (run `audit-112-candidates.ts` or similar query) to catch any candidates added since Phase 117 was executed. Cross-reference to ensure complete contested-race coverage.
- **D-03:** No special priority ordering — all contested-race candidates are equal priority. Work through the list in whatever order makes sense for sourcing efficiency.

### Authoring Workflow
- **D-04:** Use a one-shot import script (TypeScript) that reads a prepared data file with candidate bios + photo URLs and inserts/updates the DB directly. Small batch (~5-10) doesn't need the staging review workflow.
- **D-05:** Claude does the research and drafting — researches each candidate online, writes the bio, finds a photo URL, and prepares the import data. User reviews before import runs.
- **D-06:** Review format is a markdown table in a review doc (`.planning/phases/120-*/120-REVIEW-DATA.md` or similar). Columns: name, bio text, photo URL, source citation. User reads and approves/edits before the import script runs.
- **D-07:** Produce a bio authoring methodology doc during this phase. Captures sourcing approach, tone, length, and antipartisan constraints — reusable for Phase 124's 45-candidate batch. (Phase 124 success criteria requires this.)

### Photo Sourcing
- **D-08:** Photo source priority: Official government photos > Campaign website > Social media profiles > News article photos. Most authoritative source preferred.
- **D-09:** Claude downloads photos and uploads to Supabase Storage CDN, following the existing pattern: download from source → upload to politician headshots bucket → store CDN URL in `essentials.politician_images`. No hotlinking.
- **D-10:** For candidates with no findable photo at all, use the existing ev-ui missing-photo fallback. Don't block on photos — proceed with bio authoring and import without a photo.

### Bio Tone + Voice
- **D-11:** Neutral factual tone. Dry, objective facts: role, background, reason for running. No editorial voice. Example: "Monroe County educator and longtime community volunteer seeking County Council District 3 seat."
- **D-12:** Length: ~120-180 characters, one sentence (carries forward from Phase 117 D-14).
- **D-13:** Party affiliation is omitted from bios unless it is part of the candidate's actual professional or service history (e.g., "president of Monroe County Democrats" as a leadership role). Minimize party mentions as much as possible — consistent with antipartisan principle.
- **D-14:** Bios are extracted + lightly compressed from a single named source — never LLM-synthesized across multiple sources (carries forward from Phase 117 D-07). Source URL stored alongside the bio text.
- **D-15:** Fallback for candidates with insufficient info: office-title-only bio ("Candidate for [office title].") as established in Phase 117 D-06.

### Claude's Discretion
- Exact structure of the import data file (JSON vs CSV)
- Import script location and naming
- Whether to batch all candidates in one import run or process individually
- Methodology doc format and location within `.planning/`
- Exact column for source citation storage (existing `bio_source_url` or equivalent)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-defining docs
- `.planning/ROADMAP.md` §Phase 120 — Goal, requirements (CONT-01, CONT-02), success criteria
- `.planning/REQUIREMENTS.md` §Tier 1 Contested-Race Content — CONT-01, CONT-02 definitions
- `.planning/phases/117-candidate-stub-resolution-data-import/117-CONTEXT.md` — Bio sourcing rules (D-07, D-12, D-13, D-14), photo pipeline (D-13), placeholder fallback (D-06, D-12)

### Prior art in codebase
- `ev-accounts/backend/scripts/audit-112-candidates.ts` — Defines "stub" candidates (`race_candidates.politician_id IS NULL`); run to get authoritative stub list
- `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql` — Existing linking script for reference
- `ev-accounts/backend/scripts/discover-indiana-candidates.ts` — Prior discovery pipeline; may contain sourcing utilities

### Data model
- `ev-accounts/backend/src/lib/essentialsService.ts` — Politicians table interface, `bio_text` field, `politician_images` join, `photo_origin_url`
- `ev-accounts/backend/migrations/026_inform_schema_repair_and_candidates.sql` — `is_candidate` column definition

### Photo pipeline
- Supabase Storage: politician headshots bucket (existing CDN pattern)
- `essentials.politician_images` table: `politician_id`, `url`, `type`, `photo_license`, `focal_point`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `audit-112-candidates.ts` — Can be run to produce the current candidate stub list for scoping
- `discover-indiana-candidates.ts` — Prior discovery pipeline with sourcing utilities
- `link-monroe-candidates-to-politicians.sql` — Linking logic for matching imports to existing politician rows
- `importElectionData.ts` — Existing import script pattern; reference for structure

### Established Patterns
- `bio_text` column on `essentials.politicians` — single text field, nullable
- `politician_images` table with CDN URLs — download + re-host pattern established
- `photo_origin_url` on politicians — tracks where the photo came from
- `is_candidate` boolean flag — already filters candidates from address-lookup results

### Integration Points
- Import script updates `essentials.politicians.bio_text` for existing politician rows
- Photo upload goes to Supabase Storage → URL stored in `essentials.politician_images`
- PoliticianProfile component (ev-ui) renders `bio_text` and images automatically — no frontend changes needed

</code_context>

<specifics>
## Specific Ideas

- Phase 117 feasibility doc is the starting point for the candidate list
- Methodology doc produced here is explicitly needed by Phase 124 (success criteria requirement)
- Party mentions in bios: OK only when it's the candidate's actual job/service role (e.g., "president of Monroe County Democrats"), otherwise omit entirely

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 120-contested-race-bio-photo-authoring*
*Context gathered: 2026-04-16*
