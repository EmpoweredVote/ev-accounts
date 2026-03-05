# Phase 63: Headshot Research Sprint - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Manually research and source headshot URLs for all ~300 LA County local officials in the research manifest. Produce a structured CSV mapping every politician to either a sourced image URL or a "not found" status. This phase covers research only — uploading to Supabase CDN and updating the database are Phase 64.

</domain>

<decisions>
## Implementation Decisions

### Research Approach
- Claude browses city council pages using Playwright MCP to find headshot image URLs
- Research order: largest gaps first (cities with the most missing headshots processed first — manifest already sorts this way)
- Batch by city clusters: 10-15 cities per plan session, natural checkpoints for incremental review
- Batch verification at end of each cluster — user spot-checks rather than per-city approval
- For cities with no photos on the main council page: deep-dive 3-4 alternative pages (About, individual member pages, city directory) before marking not_found

### Output Format
- Extend the existing headshot_research_manifest.csv with new columns:
  - `politician_id` — database ID for direct Phase 64 upload (no fuzzy name matching needed)
  - `found_url` — direct image URL (.jpg/.png)
  - `source_page_url` — the page where the image was found (for re-verification and licensing)
  - `research_status` — one of: `pending`, `found`, `not_found`, `blocked`
  - `research_date` — when this row was researched
- The CSV itself is the checkpoint — rows with existing research_status are skipped on resume
- Regenerate manifest with `--include-blocked` flag to include Cloudflare-blocked cities (Burbank)
- `generate_headshot_manifest.py` needs update to add politician_id column and new research columns

### Image Standards
- Official city pages preferred as primary source; fallback to official city/county websites and government directories; news/LinkedIn only as last resort
- Minimum quality: recognizable face at any size (even ~100px thumbnails acceptable — displayed at card size)
- Individual headshots/portraits only — skip group photos (no cropping step)
- Record both the direct image URL and the source page URL for attribution

### Not-Findable Handling
- Mark `research_status='not_found'` and move on — initials avatar covers these in the UI
- Four distinct statuses: `pending` (not yet researched), `found` (URL recorded), `not_found` (researched, no photo), `blocked` (couldn't access page)
- Phase 63 success = every politician researched, not a coverage percentage
- The 80%+ coverage target is Phase 64's metric after upload

### Claude's Discretion
- Exact Playwright navigation strategy per city
- How many alternative pages to try before marking not_found (up to 3-4)
- Batch size within the 10-15 city guideline
- CSV column ordering and any additional metadata columns

</decisions>

<specifics>
## Specific Ideas

- `generate_headshot_manifest.py` already queries LOCAL/LOCAL_EXEC CA politicians without Supabase headshots — extend rather than replace
- city_sources.json tracks 89 cities: 76 scraped, 12 failed (duplicate_url_detected etc.), 1 blocked (Burbank)
- The 12 "failed" cities likely have photos on sub-pages — the batch scraper's duplicate URL detection was too aggressive
- Current coverage: ~21.5% (84/391) — significant room for improvement through manual browsing

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `generate_headshot_manifest.py`: Generates research checklist CSV from DB query. Needs extending with politician_id and research columns.
- `scrape_city_headshots.py` (1,247 lines): Full pipeline — Playwright browser, Cloudflare detection, Supabase upload, DB upsert. Reference for Phase 64 upload, not directly used in Phase 63.
- `coverage_report.py`: 3-check validation (CDN health, contact websites, zero hotlinks). Will be used in Phase 64 to confirm 80%+ target.
- `city_sources.json` (4,664 lines): 89 cities with roster arrays, council URLs, headshot_status. Primary source for research targets.

### Established Patterns
- Python scripts in `EV-Backend/scripts/` with `--dry-run`, `--verbose`, `--include-blocked` CLI flags
- `.env.local` for DATABASE_URL
- psycopg2 direct connections with urlparse for special-character passwords
- city_sources.json as the canonical roster + status tracking file

### Integration Points
- headshot_research_manifest.csv — input to Phase 64 upload pipeline
- essentials.politicians table — source of politician_id for manifest
- essentials.politician_images table — Phase 64 destination (not written in Phase 63)
- Supabase Storage CDN — Phase 64 upload target (not used in Phase 63)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 63-headshot-research-sprint*
*Context gathered: 2026-03-05*
