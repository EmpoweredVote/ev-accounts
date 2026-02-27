---
status: complete
phase: 50-data-import-scripts
source: 50-01-SUMMARY.md, 50-02-SUMMARY.md, 50-03-SUMMARY.md
started: 2026-02-27T01:00:00Z
updated: 2026-02-27T01:12:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Stance Import Dry Run
expected: Run `./server import-stances --dry-run` — validates CSV rows (topic/politician lookups) and reports results without writing to DB. Exits cleanly with summary.
result: pass

### 2. Stance Import Full Run
expected: Run `./server import-stances` — imports stance rows from CSV into compass.answers and compass.contexts tables. Output shows upserted row count and any skipped/errored rows.
result: pass

### 3. Quote Import Dry Run
expected: Run `./server import-quotes --dry-run` — validates quote_collection.csv rows (politician name resolution, topic_key validation) without writing. Exits with summary.
result: pass

### 4. Quote Import Full Run
expected: Run `./server import-quotes` — imports quote rows into essentials.quotes table. Output shows upserted count. Re-running is idempotent (same count, no duplicates).
result: pass

### 5. Quotes API Endpoint
expected: With server running, GET /essentials/quotes returns JSON with three arrays: `quotes` (each with politician_id, topic_key, quote_text, source_url), `candidates` (deduped politician info with name, party, office), and `issues` (topic keys with total_issues count).
result: pass

### 6. Read & Rank Loads From API
expected: Open Read & Rank app (npm run dev in EV-prototypes/read-rank). IssueHub shows "Loading issues..." briefly, then displays issue cards sourced from the API. Clicking an issue shows quotes from the database, not hardcoded mock data.
result: pass (fixed: created .env.local with VITE_API_URL=http://localhost:5050)

### 7. Read & Rank Fallback to Mock Data
expected: With API server stopped, Read & Rank still loads using mock data fallback. IssueHub displays issues from mockData.ts instead of showing an error.
result: pass

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0

## Gaps

- truth: "Read & Rank IssueHub loads quotes from API when backend is running locally"
  status: resolved
  reason: "Missing .env.local with VITE_API_URL for local dev"
  resolution: "Created EV-prototypes/read-rank/.env.local with VITE_API_URL=http://localhost:5050"
  test: 6
