# Phase 37: Politician Gap-Fill — City Councils and School Boards - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate city council members for all 87 incorporated LA County cities (excluding LA City, covered in Phase 36) and school board members for all LA County school districts (unified, elementary, high school, and community college districts). All records must link to district rows whose geo_ids match geofence_boundaries imported in Phase 34. Extends the reusable scraper framework built in Phase 36 to handle high-volume multi-entity scraping.

</domain>

<decisions>
## Implementation Decisions

### Source Strategy for 87 Cities
- Claude's discretion on whether to use aggregator sources (League of CA Cities, SCAG, LA County data portals) vs per-city scraping — evaluate during research and pick the best approach per city
- Use Playwright headless browser scraping for JavaScript-heavy or hard-to-scrape city sites before marking as failed — try harder before giving up
- Python for all scrapers, consistent with Phase 34/35/36 scripts (requests + BeautifulSoup for static, Playwright for JS-heavy)
- Single consolidated config file mapping all 87 cities to their scraper configs (similar to arcgis_sources.json pattern from Phase 34)

### School Board Sourcing
- Scope: ALL LA County school districts — unified, elementary, high school, and community college districts (not just USDs)
- Claude's discretion on bulk source approach — research CDE directory, LACOE, and individual district sites to find the best strategy
- Import missing school district boundaries as part of this phase if they weren't covered in Phase 34 — every board member needs a geofence
- Where trustee areas exist, create separate sub-district records so an address returns the specific trustee representative; fall back to shared district for at-large elections

### Coverage and Prioritization
- Target: 90%+ coverage acceptable — cover as many cities and districts as automated scraping handles, log gaps for follow-up
- Phase is complete if 90%+ of cities and 90%+ of school districts have records
- Claude's discretion on batching strategy (all at once vs waves) and coverage tracking approach
- Cities/districts that fail scraping are logged with failure reason for manual follow-up

### Data Quality Thresholds
- Minimum viable record: name + seat only — a record with just the person's name and which seat they hold is acceptable
- Grab everything available from sources — photos, bios, contacts, committee assignments, term dates. More data is better even if inconsistent across cities
- School board members stored with party = 'Nonpartisan' explicitly (not null) since most school board races are nonpartisan
- Incomplete records treated the same in the frontend — show what we have, hide what we don't. No special 'incomplete' indicator. Missing photos use placeholder avatar.

### Claude's Discretion
- Aggregator vs per-city scraping decisions per entity
- Batching/wave strategy for processing 87+ entities
- Coverage tracking mechanism (report script vs config status field)
- School board bulk source selection (CDE vs LACOE vs per-district)
- Playwright integration approach for JS-heavy sites
- Trustee area boundary sourcing for school districts with sub-district elections

</decisions>

<specifics>
## Specific Ideas

- Extend the Phase 36 scraper framework — same config-driven pattern, same Python script directory (EV-Backend/scripts/)
- Consolidated config file should be human-reviewable, similar to arcgis_sources.json
- Follow Phase 36 patterns for deduplication (ocd_id + office title for seat, fuzzy name for person), is_active/inactive handling, and data_source provenance tracking
- Reuse Phase 36 schema additions (is_active, data_source fields) — no new schema changes expected beyond what Phase 36 establishes

</specifics>

<deferred>
## Deferred Ideas

- Automated scraper scheduling/refresh cycles — future phase
- Community college board coverage if not included in "all school districts" boundary data — evaluate during research
- Handling mid-term vacancies and special elections for covered cities — future phase

</deferred>

---

*Phase: 37-politician-gap-fill-city-councils-and-school-boards*
*Context gathered: 2026-02-24*
