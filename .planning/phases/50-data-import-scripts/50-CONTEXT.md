# Phase 50: Data Import Scripts - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Build import scripts that load the stance research CSV (~455 rows, 23 politicians, 21 topics) into compass.answers and the quote collection CSV (~61 rows) into a new essentials.quotes table, with validation. Update Read & Rank to fetch quotes from the API instead of hardcoded mockData.

</domain>

<decisions>
## Implementation Decisions

### Script format & invocation
- Go CLI subcommands on the existing server binary: `./server import-stances` and `./server import-quotes`
- Upsert semantics — safe to re-run; existing rows updated, new rows inserted
- Default file paths (`data/stance_research.csv`, `data/quote_collection.csv`) with positional argument override
- Output: summary stats on success (rows processed, inserted, updated, skipped, errors)

### Quote storage target
- New `essentials.quotes` database table — quotes live in the essentials schema alongside politician data
- New API endpoint to serve quotes (e.g., GET /essentials/quotes or similar)
- Update Read & Rank frontend to fetch from the API instead of hardcoded `mockData.ts`
- Quote fields map from CSV: full_name, topic_key, quote_text, source_url, source_name

### Validation & error handling
- Skip invalid rows and continue processing; print all errors at the end with row numbers
- Stance values validated: must be 1-5, reject otherwise
- Topic keys validated: must match existing compass.topics, reject unknown keys
- Missing politicians: skip row, warn loudly in error report
- No URL validation — source URLs imported as-is (curated during research phases)

### Politician ID resolution
- Primary: exact full_name match against essentials.politicians
- Secondary: if external_id present in CSV, use as fallback lookup
- Ambiguous matches (multiple politicians with same name): skip and warn
- Source URLs from stance CSV stored in database alongside stance values (not just audit trail)
- Topic keys matched against compass.topics for foreign key integrity

### Claude's Discretion
- Dry-run mode implementation (whether to include --dry-run flag)
- Exact quotes table schema design
- API endpoint URL structure for quotes
- How to handle the Read & Rank candidate/issue mapping when switching from mock to API data

</decisions>

<specifics>
## Specific Ideas

- User wants quotes in the essentials schema because they're tied to politician data
- Read & Rank currently uses a `Quote` interface: `{ id, text, candidateId, issue, sourceUrl, sourceName }` — API response should be compatible
- Read & Rank also uses `mockCandidates` and `allIssues` arrays from mockData.ts — these may also need API equivalents
- The import is end-to-end: CSV into DB, DB served via API, Read & Rank consumes API

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 50-data-import-scripts*
*Context gathered: 2026-02-26*
