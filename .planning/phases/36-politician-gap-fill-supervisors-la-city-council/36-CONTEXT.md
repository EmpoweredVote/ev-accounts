# Phase 36: Politician Gap-Fill — Supervisors and LA City Council - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Create/verify 5 LA County supervisor records, 15 LA City council member records, and 1 LA City mayor record in the database with district geo_ids that join to the Phase 35 geofences. Enables point-in-polygon lookups to return the correct local officials for LA County addresses. Phase 37 covers the 87 other incorporated cities and school boards.

</domain>

<decisions>
## Implementation Decisions

### Data Sourcing
- Most of these politicians already exist in the database from BallotReady cache — check existing records first, only gap-fill what's missing
- We have moved away from BallotReady API — scraping is the path forward for new/missing data
- Scrape from official government websites: LA County Board of Supervisors site and LA City Clerk/Council site
- Build a reusable scraper framework that Phase 37 can extend with new source configs for other cities
- When scraped data is fresher than existing BallotReady-cached fields, overwrite with the scraped data

### District Linking
- Reuse existing district rows by matching on ocd_id — do not create duplicate district records
- Supervisors use district_type=LOCAL with X0001 geofences (consistent with existing BallotReady convention from Phase 35)
- LA City mayor maps to the G4110 Incorporated Place boundary with district_type=LOCAL_EXEC (same pattern as other mayors in the system)
- Auto-update district geo_ids when they're missing or mismatched — this is the core purpose of gap-fill

### Deduplication
- Primary matching: identify the *seat* by ocd_id + office title, then identify the *person* within that seat using fuzzy name matching (Levenshtein distance to catch "Robert Smith" vs "Bob Smith")
- When the person in a seat has changed (post-election): mark the old officeholder as inactive (add is_active/end_date field), insert the new person — both records persist in the database
- A "duplicate" is defined as the same person appearing in the same seat with both records marked active — the verification query checks for this
- Never delete historical records — inactive officeholders are preserved for historical reference

### Data Completeness
- Scrape everything available from official sites: name, party, photo, bio, contact info, committee assignments, etc.
- Store contacts in existing essentials.politician_contacts table with source attribution (e.g., source='scraped:lacounty.gov')
- Download and re-host politician photos (don't just store external URLs) — prevents broken links when government sites redesign
- Track data provenance: add a data_source/last_updated_by field so records indicate where their data came from (BallotReady vs scraped)

### Claude's Discretion
- Exact fuzzy matching threshold for name deduplication
- Photo storage location (S3, Supabase Storage, or local)
- Scraper architecture details (Python script pattern, retry logic, rate limiting)
- Schema changes for is_active field and data_source tracking (column additions vs new table)
- Inactive officeholder detection logic

</decisions>

<specifics>
## Specific Ideas

- Follow the existing import script pattern from Phase 34/35 (Python scripts in EV-Backend/scripts/) for consistency
- The reusable scraper framework should have a config-driven approach similar to arcgis_sources.json — a human-reviewable mapping of source URLs to scraper configs
- Provenance tracking is important for debugging refresh cycles and knowing which data to trust when sources conflict
- The is_active/inactive pattern supports future election cycles where officeholders change without losing historical data

</specifics>

<deferred>
## Deferred Ideas

- Full officeholder lifecycle management (term tracking, election date triggers) — future phase
- Automated scraper scheduling/refresh cycles — future phase
- Handling mid-term vacancies and appointments — note for later

</deferred>

---

*Phase: 36-politician-gap-fill-supervisors-la-city-council*
*Context gathered: 2026-02-24*
