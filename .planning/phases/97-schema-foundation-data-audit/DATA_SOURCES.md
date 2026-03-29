# Election Data Sources - Phase 97 Validation

**Validated:** 2026-03-29
**Schema version:** 042_election_schema.sql

## Data Source Decision (per D-01, D-02)

CivicEngine API: OFF THE TABLE (paid, no access)
Google Civic API: UNAVAILABLE (no longer supported)
Approach: Hybrid — scrape structured public sources + manual staging for gaps

## Indiana Secretary of State (State + Federal Races)

**Source URL (Primary):** https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx
**Source URL (General):** https://www.in.gov/sos/elections/files/General-Candidate-List-February-25,-2026.xlsx
**Format:** Excel (.xlsx), sheet name: `Candidate_List_Abbreviated_2026`
**Confidence:** HIGH — live download confirmed 2026-03-29 (12,289 rows in primary file)
**Coverage:** US House (all 9 IN districts), Indiana State Senate, Indiana State Representative

### Actual Excel File Structure (Confirmed from Live Download)

```
Row 0: ["ALL COUNTIES", "2026 PRIMARY ELECTION - 5/5/2026"]   (metadata header)
Row 1: []                                                       (blank)
Row 2: ["OFFICE", "CANDIDATE NAME", "POLITICAL PARTY", "DISTRICT", "DATE FILED"]  (column headers)
Row 3+: data rows
```

Key observation: The file uses ALL CAPS column names and there is NO separate "Last Name" or "Incumbent" column. The `DISTRICT` column contains the full district description string (e.g., "United States Representative, Eighth District"), not just a district number.

### Column Mapping to Schema

| Source Column | Schema Target | Notes |
|---------------|---------------|-------|
| OFFICE | races.position_name (fallback) | Use DISTRICT description when available |
| CANDIDATE NAME | race_candidates.full_name | Direct map |
| DISTRICT | races.position_name | Full description (e.g. "United States Representative, Eighth District") |
| DATE FILED | race_candidates.source metadata | Provenance only — not a schema column. Stored as Excel serial date (e.g. 46042) |
| POLITICAL PARTY | races.primary_party | Primary elections only — party is a structural property of the race, not the candidate. NULL for general/retention/special elections. Required for closed/semi-closed primary states where voters need to know which primary they can participate in. |
| *(none)* | race_candidates.last_name | Extracted from CANDIDATE NAME — last word |
| *(none)* | race_candidates.is_incumbent | Not in filing data — defaults to false; set at import by politician_id match |

### Sample Records (Live Data, 2026-03-29)

These are actual candidate names from the 2026 Indiana Primary filing list:

```json
{
  "election": { "name": "2026 Indiana Primary", "election_date": "2026-05-05", "election_type": "primary", "jurisdiction_level": "state", "state": "IN" },
  "race": { "position_name": "United States Representative, Eighth District", "primary_party": "Democratic", "seats": 1 },
  "candidate": { "full_name": "Mary Allen", "last_name": "Allen", "first_name": "Mary", "is_incumbent": false, "candidate_status": "active", "source": "sos_excel" }
}
{
  "election": { "name": "2026 Indiana Primary", "election_date": "2026-05-05", "election_type": "primary", "jurisdiction_level": "state", "state": "IN" },
  "race": { "position_name": "United States Representative, Eighth District", "primary_party": "Democratic", "seats": 1 },
  "candidate": { "full_name": "Mario Foradori", "last_name": "Foradori", "first_name": "Mario", "is_incumbent": false, "candidate_status": "active", "source": "sos_excel" }
}
{
  "election": { "name": "2026 Indiana Primary", "election_date": "2026-05-05", "election_type": "primary", "jurisdiction_level": "state", "state": "IN" },
  "race": { "position_name": "United States Representative, Fifth District", "primary_party": "Democratic", "seats": 1 },
  "candidate": { "full_name": "J.D. Ford", "last_name": "Ford", "first_name": "J.D.", "is_incumbent": false, "candidate_status": "active", "source": "sos_excel" }
}
```

### Schema Fit Assessment

**CLEAN FIT** — Indiana SoS data maps to 042 schema without schema changes needed.

All 7 schema validation checks passed on live data:
- full_name: all records populated
- position_name: all records populated (DISTRICT column used directly)
- last_name: extractable from CANDIDATE NAME (last word)
- election_date: ISO format compatible with PostgreSQL `date` type
- candidate_status: all values map to enum (`active` | `withdrawn` | `filed`)
- election_type: maps to enum (`primary` | `general`)
- primary_party: populated on race records for primary elections; absent from candidate records (antipartisan on candidates enforced)

**Discovered discrepancy from RESEARCH.md assumptions:**
RESEARCH.md listed expected columns as: `Office, Candidate Name, Last Name, Political Party, District, Date Filed, Incumbent`. The actual file has NO separate "Last Name" or "Incumbent" columns. This is a schema fit note — no schema changes needed, but the Phase 98 import script must handle last_name extraction from full_name and determine is_incumbent via politician_id matching rather than a source column.

---

## Monroe County Local Races (Bloomington)

**Source URL:** https://www.in.gov/counties/monroe/community2/voter-registration/candidate-filings/
**Format:** HTML page linking to SharePoint folders containing PDF filing documents
**Confidence:** MEDIUM — page exists and confirmed accessible; no structured download
**Coverage:** City council, mayor, county offices, township positions

### Known Coverage Gap

Local Bloomington/Monroe County races are NOT in the Indiana SoS Excel file. The SoS Excel covers state and federal races only. The county clerk's candidate filings page exists but provides only an HTML list of candidate names with SharePoint links to PDF filing documents. No machine-readable structured download.

**Specific races with gap:**
- Bloomington City Council (9 district seats + 3 at-large seats)
- City of Bloomington Mayor
- Monroe County Commissioner (3 seats)
- Monroe County Council (7 seats: 4 district + 3 at-large)
- Monroe County Clerk, Auditor, Treasurer, Recorder
- Township trustee and advisory board positions (Bean Blossom, Benton, Bloomington, Clear Creek, Indian Creek, Madison, Perry, Polk, Salt Creek, Van Buren, Washington)

**Data available from clerk page:** Candidate names (from SharePoint links), filing date
**Data NOT available from clerk page:** Photos, bios, structured position metadata, filing status

### Recommended Approach for Phase 98

Manual entry via existing staging/data-entry tool (`/api/staging/*`) for:
- Candidate names (available from clerk page HTML)
- Position names (known from district structure)
- Incumbent identification (match against existing politicians records)
- Photos and bios (require manual research per candidate — use same headshot scraper pipeline from v1.7)

---

## LA County Elections

**Source URLs:**
- Scheduled elections PDF: https://content.lavote.gov/docs/rrcc/documents/2026-scheduled-elections-10-25-2025-v-2.pdf
- Public Officials Roster: https://apps1.lavote.net/Voter/Public_Officials.cfm
- 2026 Candidate Handbook: https://content.lavote.gov/docs/rrcc/documents/2026-candidate-handbook-and-resource-guide--new-v-5.pdf
**Format:** PDF (scheduled elections + handbook) + HTML web app (officials roster)
**Confidence:** MEDIUM — PDFs confirmed accessible; no free structured API
**Coverage:** LA County supervisor, LA City council, city council for 88 incorporated cities, school board races

### Known Coverage Gaps

No free structured API. Purchasing election information requires calling (800) 815-2666 option 4.

**Specific gaps:**
- Challenger candidates: NOT available via free sources — require manual staging entry
- Ballot qualification status: Only confirmed candidates in PDF; no real-time updates
- School board races for LAUSD and other districts: Available in handbook but not structured

**Data available for free:**
- Election dates: Available from scheduled elections PDF (parse-able)
- Race names: Available from scheduled elections PDF and handbook
- Incumbent data: Available from Public Officials Roster web app (scrapable HTML)
- LA County positions covered: Board of Supervisors (5 districts), LA City Council (15 districts), LA Unified School District Board, Community College District Board

### Recommended Approach for Phase 98

1. Parse scheduled elections PDF for election dates and race names (pdfplumber or pdfjs)
2. Scrape Public Officials Roster for incumbent data (HTML table scraping)
3. Manual staging via `/api/staging/*` for challenger candidates
4. Use existing politician records for incumbents (politician_id FK on race_candidates)

---

## Party Data Handling

ALL sources include party affiliation data. Party is handled differently depending on election type:

**Primary elections:** Party is stored on `races.primary_party` — it's a structural property of the race, not a label on the candidate. In closed/semi-closed primary states (including Indiana), voters need to know which party's primary a race belongs to. Example: "Republican Primary — State Senate District 40" has `primary_party = 'Republican'`.

**General/retention/special elections:** `races.primary_party` is NULL. No party data is displayed or stored.

**Never on candidates:** Party is NEVER stored on `race_candidates`. The antipartisan principle applies to individual candidates — voters should evaluate candidates on positions, not party labels.

Source handling by data source:
- Indiana SoS: `POLITICAL PARTY` column → `races.primary_party` for primary elections, ignored for general elections
- Monroe County clerk: Party listed next to candidate names — stored on race level for primaries only
- LA County: Party affiliation in official records — same treatment

See 042_election_schema.sql antipartisan rationale comment for full explanation.

---

## Phase 98 Import Pipeline Recommendations

| Source | Approach | Automation Level | Est. Effort |
|--------|----------|-----------------|-------------|
| Indiana SoS Excel (state/federal) | Automated xlsx parser | HIGH — script validated | 4-8 hours |
| Monroe County local races | Manual staging via data-entry tool | MANUAL — no structured source | 2-4 hours per election cycle |
| LA County incumbents | Scrape Public Officials Roster | SEMI — HTML table scraping | 8-12 hours |
| LA County challengers | Manual staging via data-entry tool | MANUAL — no free structured API | Per-race research |

**All pipelines must:**
1. Have explicit party column exclusion with logged warnings
2. Set `source = 'sos_excel' | 'county_clerk' | 'manual'` on all race_candidates records
3. Set `last_verified_at` to import date for freshness tracking
4. Default `candidate_status = 'active'` (withdrawn candidates require manual update)
5. Attempt incumbent identification by matching full_name against `essentials.politicians` records; set `is_incumbent = true` and populate `politician_id` FK when match found

**Date note:** Indiana SoS uses Excel serial date format for `DATE FILED` (e.g., 46042 = 2026-01-15). Phase 98 parser must convert via `new Date(Date.UTC(1900, 0, serialDate - 1))`.
