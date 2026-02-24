# Phase 38: Validation and Performance - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify that the LA County data pipeline (Phases 34-37) works end-to-end: any LA County address returns the correct representative hierarchy, PostGIS spatial index is active, and the import process is documented as a repeatable runbook for future regions. This phase owns the outcome — if validation reveals gaps, fix them here.

</domain>

<decisions>
## Implementation Decisions

### Test Address Selection
- Claude selects all 3 required test addresses (incorporated city, unincorporated area, boundary edge)
- Incorporated city: pick a mid-size city like Pasadena or Long Beach that exercises multiple tiers
- Unincorporated area: pick a community like East LA, Willowbrook, or Altadena
- Boundary edge: address on a district line — must return a result (no empty/null responses on boundaries)
- All test addresses go in a repeatable validation script (not one-time manual checks)

### Gap Remediation
- Phase 38 fixes all gaps found during validation — the goal is that validation passes, not just that we ran checks
- Fixing can include patching scrapers or re-running importers from previous phases if needed
- Expected gaps are correct behavior: unincorporated areas legitimately have no city council, that's not a failure
- Validation script outputs pass/fail report showing expected vs actual tiers per address, with PASS/FAIL per tier and overall summary

### Pipeline Documentation
- Step-by-step runbook in `.planning/IMPORT-PIPELINE.md`
- Uses LA County as the concrete example throughout, with notes on what varies per region
- Covers: data sources, import order, dependencies between steps
- Includes a verification section that references the validation script from this phase
- Audience: someone repeating this process for a new county/region

### Validation Breadth
- 10-20 sample addresses beyond the 3 required test addresses
- Mix of geographic spread (north/south/east/west LA County) and intentional edge cases (small cities, multi-district overlaps)
- Validation script shows tier-level detail per address: which tiers (federal, state, county, city, school) resolved
- For performance: confirming GiST Index Scan via EXPLAIN ANALYZE is sufficient — no specific query time threshold required

### Claude's Discretion
- Specific address selection for all test cases
- Validation script language/format (SQL file, shell script, etc.)
- VACUUM ANALYZE timing and approach
- How to structure the pass/fail report output

</decisions>

<specifics>
## Specific Ideas

- Validation script should be re-runnable after future imports to verify the same addresses still resolve correctly
- Boundary-edge behavior: PostGIS `ST_Contains` or `ST_Intersects` should always return a result, never leave a real address unresolved
- Runbook should be practical enough that a future developer (or Claude) can follow it step-by-step for a new county

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 38-validation-and-performance*
*Context gathered: 2026-02-24*
