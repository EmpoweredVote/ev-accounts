# Phase 97: Schema Foundation & Data Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-29
**Phase:** 97-schema-foundation-data-audit
**Areas discussed:** Data source strategy, Election schema design, is_appointed audit approach, Retention judge modeling

---

## Data Source Strategy

### Q1: CivicEngine API access status

| Option | Description | Selected |
|--------|-------------|----------|
| I have access | OAuth token available — build pipeline around CivicEngine GraphQL | |
| No access yet | Need to request — design schema independent of CivicEngine | |
| Unavailable | CivicEngine off the table — fallback needed | |

**User's choice:** Other — "I think a lot of the data we can pull from other free APIs. We don't want to rely on CivicEngine and the Google Civic API is no longer supported."
**Notes:** Both CivicEngine (paid) and Google Civic API (deprecated) are off the table. Free/open sources only.

### Q2: How to source election/candidate data

| Option | Description | Selected |
|--------|-------------|----------|
| Manual staging | Research manually, enter via data-entry tool | |
| Scrape public sources | Build scrapers for county clerk sites, SoS filings | |
| Hybrid approach | Scrape structured sources, manually fill gaps | ✓ |

**User's choice:** Hybrid approach
**Notes:** None

### Q3: Depth of data source research in Phase 97

| Option | Description | Selected |
|--------|-------------|----------|
| Document sources only | Identify websites/APIs, note data format | |
| Verify with samples | Identify AND pull sample records to validate schema | ✓ |
| You decide | Claude picks depth based on research | |

**User's choice:** Verify with samples
**Notes:** None

---

## Election Schema Design

### Q4: How race_candidates links to existing politicians

| Option | Description | Selected |
|--------|-------------|----------|
| FK to politicians | Optional politician_id FK; incumbents link, challengers NULL | ✓ |
| Always separate | No link; all data self-contained on race_candidates | |
| Merge into politicians | Insert candidates into politicians with flag | |

**User's choice:** FK to politicians (Recommended)
**Notes:** None

### Q5: Candidate status values

| Option | Description | Selected |
|--------|-------------|----------|
| Three statuses | active / withdrawn / filed; only active returned by default | ✓ |
| Two statuses | active / withdrawn; simpler | |
| You decide | Claude designs based on data sources | |

**User's choice:** Three statuses (Recommended)
**Notes:** None

### Q6: Elections table geographic scope

| Option | Description | Selected |
|--------|-------------|----------|
| Flexible with scope field | jurisdiction_level field (federal/state/county/city/district) | ✓ |
| One election per date+type | Single record per (date, type) pair | |
| You decide | Claude picks based on data shape | |

**User's choice:** Flexible with scope field
**Notes:** None

---

## is_appointed Audit Approach

### Q7: Audit thoroughness

| Option | Description | Selected |
|--------|-------------|----------|
| Office-level audit | Audit offices.is_appointed_position; politicians inherit | |
| Politician-level audit | Audit every individual politician record | |
| Both levels | Offices first (batch), then spot-check politicians | ✓ |

**User's choice:** Both levels
**Notes:** None

### Q8: Audit output format

| Option | Description | Selected |
|--------|-------------|----------|
| Report then fix | Generate report for review, then apply fixes after sign-off | ✓ |
| Auto-fix obvious cases | Fix clear-cut cases automatically, report ambiguous | |
| You decide | Claude determines based on audit findings | |

**User's choice:** Report then fix
**Notes:** None

---

## Retention Judge Modeling

### Q9: Where faces_retention_vote lives

| Option | Description | Selected |
|--------|-------------|----------|
| On politicians (per roadmap) | Boolean on essentials.politicians | |
| On offices | Boolean on essentials.offices; normalized, auto-inherits | ✓ |
| Both (denormalized) | On offices as source, mirrored to politicians | |

**User's choice:** On offices
**Notes:** Deviates from roadmap suggestion — offices is more normalized.

### Q10: How to identify retention vote judges

| Option | Description | Selected |
|--------|-------------|----------|
| By district_type + state | All JUDICIAL in Indiana get the flag | |
| By specific office/court | Flag only specific courts | |
| Research during phase | Claude researches Indiana rules and flags correct offices | ✓ |

**User's choice:** Research during phase
**Notes:** None

---

## Claude's Discretion

- Column types, indexes, constraints for new tables
- Migration file structure and sequencing
- Sample data extraction approach
- Audit query design and report format

## Deferred Ideas

None — discussion stayed within phase scope
