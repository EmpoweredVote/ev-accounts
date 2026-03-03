---
created: 2026-03-03T20:37:04.646Z
title: Add incremental import logic to federal bills and votes scripts
area: tooling
files:
  - EV-Backend/internal/essentials/import_federal_bills.go
  - EV-Backend/internal/essentials/import_federal_votes.go
---

## Problem

The `import-federal-bills` and `import-federal-votes` CLI commands re-fetch all data from Congress.gov and LegiScan APIs on every run. There is no incremental logic — no tracking of last-imported congress session, no skipping of bills/votes already in the database. This makes re-runs very slow since both scripts hit external rate-limited APIs for the full dataset each time.

Other import scripts (`import-committees`, `import-leadership`, `backfill-legislative-ids`) are fast because they parse local YAML files. The API-dependent scripts are the bottleneck.

## Solution

Add incremental import logic:

1. **`import_federal_bills.go`**: Before fetching a bill from Congress.gov, check if it already exists in `essentials.legislative_bills` by bill number + congress. Skip if present (or only re-fetch if older than N days for updates). Track the last-imported congress session number.

2. **`import_federal_votes.go`**: Before fetching vote records from LegiScan, check if the vote already exists in `essentials.legislative_votes` by roll call number + session. Skip existing votes. Could also add a `--congress N` flag to only import a specific congress session.

3. Consider adding a `--force` flag to override incremental logic when a full re-import is needed.

4. The `import_state_indiana.py` and `import_local_bloomington.py` Python scripts could also benefit from similar logic but are lower priority since they're faster.
