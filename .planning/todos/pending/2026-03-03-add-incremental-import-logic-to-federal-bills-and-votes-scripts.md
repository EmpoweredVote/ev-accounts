---
created: 2026-03-03T20:37:04.646Z
title: Replace LegiScan API imports with bulk download approach
area: tooling
files:
  - EV-Backend/internal/essentials/import_federal_bills.go
  - EV-Backend/internal/essentials/import_federal_votes.go
---

## Problem

The `import-federal-bills` and `import-federal-votes` CLI commands fetch data one-at-a-time from Congress.gov and LegiScan APIs. This is extremely slow (hours for a full import) and burns through the LegiScan monthly budget (30,000 queries). A single run for Senate bills alone attempted 19,314 `getBill` API calls plus additional `getRollCall` calls per vote. The safety cutoff at 100 remaining budget prevents exhaustion but leaves data incomplete.

The current approach is fundamentally wrong for bulk historical data — live APIs are designed for incremental updates, not initial population.

## Solution

Replace the live API approach with bulk data sources that can be downloaded and parsed locally:

### Bills: GPO Bulk Data
- **Source:** https://www.govinfo.gov/bulkdata/BILLSTATUS
- **Format:** XML, organized by congress number (108-119)
- **Update frequency:** Every 4 hours for current congress, daily for prior
- **Includes:** Bill status, cosponsors, actions, committees, amendments
- **No API key needed, no rate limits**

### Roll Call Votes: unitedstates/congress
- **Source:** https://github.com/unitedstates/congress
- **Tool:** Python CLI (`usc-run votes`) — downloads from Senate/House clerk websites
- **Output:** Structured JSON with individual member votes
- **No API key needed, no rate limits**
- **Public domain (CC0)**

### Implementation approach:
1. Add a download step that fetches GPO bulk XML and `unitedstates/congress` vote JSON to a local cache directory
2. Rewrite `import_federal_bills.go` to parse local XML instead of calling Congress.gov API
3. Rewrite `import_federal_votes.go` to parse local JSON instead of calling LegiScan API
4. Keep upsert logic — just change the data source from API to local files
5. Add `--download` flag to refresh the local cache, `--parse-only` to skip download
6. LegiScan API key becomes optional (only needed if user prefers the old approach)

### What's already imported:
The paused import successfully upserted some House votes and partial Senate data. The bulk approach should upsert on top of this — no data loss.
