# Phase 39: Schema and Infrastructure Preparation - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add database schema additions (building_photos table, photo_license column, term_date_precision column) and Supabase Storage infrastructure (bucket, upload utilities) that all enrichment phases 40-44 depend on. Includes Python utils with reusable Supabase Storage upload function and config-driven pipeline foundation for regional expansion.

</domain>

<decisions>
## Implementation Decisions

### Regional Expansion Config
- Adding a new region (e.g., Orange County) must require **config-only changes** — no Python code modifications needed
- Existing scraping scripts must work with a new config file for a new region
- Config file format, geographic granularity (county vs state hierarchy), and source definition approach are at Claude's discretion

### Storage Organization
- Photos should be **overwritten on re-scrape** — same CDN URL is reused, no versioning
- Folder structure within the Supabase bucket, file naming convention, and whether to store multiple sizes are at Claude's discretion

### License Categories
- **Track but don't block** — record license type for every photo, but don't prevent storing photos without a clear license (most government headshots have no explicit license)
- License attribution is **internal only for now** — tracked in the database for legal compliance, not displayed on the frontend in v1.7
- Specific license category values (beyond the roadmap examples of cc_by_sa, press_use, scraped_no_license) and Wikimedia CC variant restrictions are at Claude's discretion

### Script Structure
- Scripts connect **directly to Supabase** using the Python client for both database writes and storage uploads — no Go API admin endpoints needed
- Script directory organization, credential management, and logging approach are at Claude's discretion

### Claude's Discretion
- Supabase bucket folder structure and file naming conventions
- Config file format (YAML vs JSON) and geographic granularity
- Whether scraping sources are defined in config per-city or discovered at runtime
- Python script organization (flat files vs package)
- Credential management approach (.env location)
- Logging strategy (console only vs file logging)
- Photo size handling (original only vs multiple sizes)
- License category enum values beyond the three examples
- Wikimedia license variant restrictions

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. The user's primary concern is that the pipeline be extensible: new regions should be a config change, not a code change.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 39-schema-and-infrastructure-preparation*
*Context gathered: 2026-02-24*
