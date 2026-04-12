# Phase 112: Data Completeness Audit - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Measure the actual gap between what is in the DB and what is on the May 5 Monroe County ballot. Produce a verified full ballot baseline from authoritative sources, run structured audit scripts against the production DB, and smoke-test geofence resolution with multiple Monroe County addresses. All output is read-only — no schema changes, no data imports, no frontend changes.

</domain>

<decisions>
## Implementation Decisions

### Audit Script Structure
- **D-01:** Multiple focused scripts — one per audit dimension (races, candidates, stances, quotes, headshots, profile completeness). Not a single composite script.
- **D-02:** Both CSV and markdown output — CSV for machine-readable data, markdown for human-readable report summaries.
- **D-03:** *Claude's Discretion:* Whether each script writes its own files directly or outputs CSV to stdout with a separate assembler script that builds the unified markdown report.

### Ballot Baseline Sourcing
- **D-04:** *Claude's Discretion:* How deep to go on external source verification — at minimum Indiana SoS + Monroe County Clerk; local press cross-referencing is optional based on Claude's judgment of what's needed for a reliable baseline.
- **D-05:** *Claude's Discretion:* How to handle ambiguous races — confidence flags, confirmed-only, or hybrid approach.

### Geofence Smoke Test
- **D-06:** Multiple test addresses across Monroe County — not a single-address test.
- **D-07:** 5-6 strategically chosen addresses covering distinct district combinations (Bloomington city center, bordering townships, rural area, near IU campus, etc.).

### Coverage Metrics Granularity
- **D-08:** Profile completeness reported as individual fields (bio: Y/N, contacts count, degrees count, experiences count) — not a rolled-up percentage score.
- **D-09:** Stance and quote coverage reported as ratios (e.g., 3/21 topics, 2 quotes) — not binary has-any/has-none.

### Claude's Discretion
- D-03: Script output architecture (self-writing vs assembler pattern)
- D-04: Source verification depth for ballot baseline
- D-05: Ambiguity handling strategy for contested/unclear races

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Audit Scripts (pattern templates)
- `ev-accounts/backend/scripts/auditHeadshots.ts` — Established audit script pattern: CSV to stdout, progress to stderr, pg.Pool direct queries
- `ev-accounts/backend/scripts/audit-is-appointed.ts` — Second audit script example for pattern confirmation

### Database Schema
- `ev-accounts/backend/src/types/database.types.ts` — TypeScript types for all essentials.* tables
- `ev-accounts/backend/src/lib/essentialsService.ts` — Geofence resolution logic (ST_Intersects queries)

### Monroe County Data
- `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` — Existing Monroe County geofence linkage SQL
- `ev-accounts/backend/scripts/importElectionData.ts` — Election data import tooling (reference for schema understanding)

### Project Research
- `.planning/research/SUMMARY.md` — Domain research with ballot size estimates (30-40+ races), stack recommendations, and risk analysis
- `.planning/REQUIREMENTS.md` — AUDIT-01 through AUDIT-08 requirement definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `auditHeadshots.ts`: Proven audit script pattern — dotenv + pg.Pool + CSV stdout + stderr progress. Direct template for new scripts.
- `essentialsService.ts`: Contains the geofence resolution logic (ST_Intersects) that the smoke test will exercise via API or direct query.
- `xlsx` package (already in deps): Can parse Indiana SoS `.xlsx` candidate filing lists for baseline building.

### Established Patterns
- Audit scripts use `pg.Pool` with `DATABASE_URL` — direct DB queries, no ORM
- Scripts live in `ev-accounts/backend/scripts/` and run via `npx tsx scripts/<name>.ts`
- CSV output to stdout, progress/errors to stderr — composable with shell pipes
- `--dry-run` flag convention for safe preview runs

### Integration Points
- Geofence smoke test will call the same resolution path as `essentialsService.ts` (either via API endpoint or direct ST_Intersects query)
- Audit queries span: `essentials.politicians`, `essentials.offices`, `essentials.chambers`, `essentials.districts`, `essentials.geofences`, `essentials.politician_images`, `essentials.politician_contacts`, `essentials.degrees`, `essentials.experiences`, plus compass stance tables and Read & Rank quote tables

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches within the decisions above.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 112-data-completeness-audit*
*Context gathered: 2026-04-12*
