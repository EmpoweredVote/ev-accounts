# Phase 98: Election Data Import - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-29
**Phase:** 98-election-data-import
**Areas discussed:** Import script design, Incumbent matching, LA County approach, Scope & coverage

---

## Import Script Design

| Option | Description | Selected |
|--------|-------------|----------|
| Evolve sample script | Extend sample-indiana-candidates.ts into a real import script — add DB writes, dedup logic, dry-run mode. Preserves validated parsing logic. | ✓ |
| New CLI tool | Build a fresh importElectionData.ts CLI with subcommands per source. Cleaner architecture but rewrites existing parsing. | |
| You decide | Claude picks the approach that fits the codebase best. | |

**User's choice:** Evolve sample script
**Notes:** None

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, dry-run by default | Script runs in preview mode unless --commit flag is passed. Shows parsed records, match results, and warnings before any DB writes. | ✓ |
| No dry-run | Script writes directly to DB every time. Simpler, but mistakes require manual cleanup. | |
| You decide | Claude picks based on what fits the import pattern. | |

**User's choice:** Yes, dry-run by default
**Notes:** None

---

| Option | Description | Selected |
|--------|-------------|----------|
| Upsert by external_id | Use SoS filing ID / external_id as the dedup key. Re-running updates existing records and adds new ones. | ✓ |
| Wipe and reload | Delete all records for that election and re-import fresh. Simple but loses any manual edits. | |
| You decide | Claude picks the dedup strategy. | |

**User's choice:** Upsert by external_id
**Notes:** None

---

## Incumbent Matching

| Option | Description | Selected |
|--------|-------------|----------|
| Office-based match | For each race, look up the essentials.offices record and find the current politician(s) holding that seat. If a filed candidate's name matches the current officeholder, mark as incumbent and set politician_id. | ✓ |
| Name match against all politicians | Fuzzy match candidate full_name against all essentials.politicians records. Wider net but higher false-positive risk. | |
| No auto-matching | Import all as non-incumbent. Manually set is_incumbent and politician_id via staging tool after review. | |

**User's choice:** Office-based match
**Notes:** None

---

| Option | Description | Selected |
|--------|-------------|----------|
| Flag for manual review | Log the near-match in dry-run output as 'POSSIBLE INCUMBENT — needs verification'. Don't auto-link politician_id. | ✓ |
| Auto-link on close match | Use Levenshtein distance or similar — if above threshold, auto-set politician_id. | |
| Strict exact match only | Only link if full_name matches exactly (case-insensitive). Miss some incumbents but zero false positives. | |

**User's choice:** Flag for manual review
**Notes:** None

---

## Cross-Office Filers (User-Raised)

| Option | Description | Selected |
|--------|-------------|----------|
| Link politician_id, not incumbent | Set politician_id (profile data flows through) but is_incumbent = false. Office-based match handles incumbent flag correctly; separate name-match pass catches cross-office filers. | ✓ |
| Only link incumbents | politician_id only set when someone is the incumbent for that specific race. Cross-office filers treated as new challengers. | |
| You decide | Claude picks based on schema design and downstream needs. | |

**User's choice:** Link politician_id, not incumbent
**Notes:** User raised this as an important edge case — e.g., state congressperson running for US congress, or city council member running for county commissioner. Two-pass matching strategy (office-based then name-based) handles this correctly.

---

## LA County Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Incumbents only via scraper | Scrape the Public Officials Roster HTML for current officeholders → create election/race records + auto-link incumbents. Challengers entered manually via staging tool. | ✓ |
| Full PDF + scraper pipeline | Parse the scheduled elections PDF for dates/race names AND scrape the roster for incumbents. More complete but PDF parsing is brittle. | |
| Manual only for LA | No automation for LA County. All candidates entered via staging tool. | |

**User's choice:** Incumbents only via scraper
**Notes:** None

---

| Option | Description | Selected |
|--------|-------------|----------|
| Same CLI, different flag | Add a --source la-roster flag to the import script. Keeps all election import logic in one place. | ✓ |
| Separate script | Create a standalone scrape-la-officials.ts. Clearer separation but fragments the import workflow. | |
| You decide | Claude picks based on codebase patterns. | |

**User's choice:** Same CLI, different flag
**Notes:** None

---

## Scope & Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Filter to coverage areas | Import only races relevant to Bloomington/Monroe County — IN-9, overlapping State Senate and State Rep districts. ~50-100 candidates. | ✓ |
| Import full state file | Import all 12K rows statewide. More data but most won't have geofence coverage. | |
| You decide | Claude picks based on success criteria. | |

**User's choice:** Filter to coverage areas
**Notes:** None

---

| Option | Description | Selected |
|--------|-------------|----------|
| All available from roster | Import everything scrapable from the Public Officials Roster — Supervisors, City Council, school boards, community college boards. | ✓ |
| Board of Supervisors + LA City Council | Import incumbents for 5 Supervisors districts and 15 City Council districts. | |
| Board of Supervisors only | Minimal scope — just 5 districts. | |

**User's choice:** All available from roster
**Notes:** None

---

| Option | Description | Selected |
|--------|-------------|----------|
| Basic query endpoint this phase | Create a minimal GET /api/essentials/elections?lat=X&lng=Y. Just enough to verify data with test addresses. Phase 99 builds the full page on top. | ✓ |
| DB verification only | Verify via direct SQL queries in import script output. No API endpoint until Phase 99. | |
| You decide | Claude interprets the success criteria and decides. | |

**User's choice:** Basic query endpoint this phase
**Notes:** Success criteria say "a test address returns election results from the API"

---

## Claude's Discretion

- Indiana district filtering logic (how to determine which districts overlap Monroe County)
- LA County HTML scraping library choice and parsing approach
- Election query endpoint implementation (geofence-based vs district matching)
- Error handling and logging format in import script output
- Test address selection for verification

## Deferred Ideas

None — discussion stayed within phase scope
