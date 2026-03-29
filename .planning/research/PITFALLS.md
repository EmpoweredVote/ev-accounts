# Domain Pitfalls

**Domain:** Adding Election Central page and elected/appointed filter to existing Essentials civic platform
**Researched:** 2026-03-29
**Scope:** v2026.3.8 Essentials Election Central milestone
**Overall confidence:** HIGH — derived from direct codebase inspection of `.planning/PROJECT.md`, `CLAUDE.md`, existing milestone history, and web research into election data freshness, judicial classification, civic API ecosystems, and antipartisan UX design.

---

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

---

### Pitfall 1: Stale `is_appointed` Flag on Officials Scraped After v1.5

**What goes wrong:** BallotReady was the original authoritative source for `is_appointed` classifications, but it was decommissioned as of v1.5 (all cache warmers removed, API key deleted). All officials imported since v1.5 via the LA County ArcGIS gap-fill pipeline (791 officials, v1.6) and any subsequent scraping lack a verified `is_appointed` value. The field may be `NULL`, defaulted to `false`, or inherited from a stale cache row. Displaying an elected/appointed toggle filter against this data produces incorrect groupings — appointed commissioners appear as elected, appointed board members appear as elected, and the filter looks broken to anyone who knows the actual status of local officials.

**Why it happens:** The v1.5 decommission removed the data pipeline that populated `is_appointed` without introducing a replacement. The v1.6 gap-fill imported officials to fill geographic coverage gaps, not to maintain classification metadata. It is easy to assume the column has valid data because it exists and has no NULLs if it was defaulted to `false`.

**How to avoid:** Before building any filter UI, run a data audit:
1. Query `SELECT COUNT(*), is_appointed FROM essentials.politicians GROUP BY is_appointed` — if 97%+ are `false`, the data is likely defaulted, not researched.
2. Cross-reference a sample of known-appointed officials (LA County supervisors, Monroe County commissioners) against their `is_appointed` value.
3. Budget a manual classification pass for all officials in coverage scope (Bloomington/Monroe County IN + LA County CA) before building the filter toggle. This is a data task, not a code task, and it must precede Phase 1.

**Warning signs:** `is_appointed = false` for LA County supervisors (who are elected) is fine; `is_appointed = false` for LA County Arts Commission members (who are appointed) is a red flag. Any official with a role description containing "commission," "board," "authority," or "appointed" that shows `is_appointed = false` should be manually verified.

**Phase to address:** Phase 1 (data audit and classification backfill) — must be resolved before the filter toggle is built. Do not build the UI against unverified classification data.

---

### Pitfall 2: Retention Judges Must Appear in BOTH Filter States

**What goes wrong:** Judicial retention elections are a hybrid: judges are initially appointed (by the governor or a judicial nominating commission), then periodically face a public retention vote — a yes/no ballot question with no opponent. In Indiana, Supreme Court and Court of Appeals judges use this system. In California, appellate justices face retention elections after initial gubernatorial appointment. If the elected/appointed filter is implemented as a binary — `is_appointed ? show in Appointed : show in Elected` — retention judges appear in Appointed only and are invisible in the Elected filter. Users researching "who is on my ballot" will not find them under Elected because there is a retention race on the ballot.

**Why it happens:** Binary boolean classification (`is_appointed: true/false`) cannot represent the hybrid status. Developers who model `is_appointed` as a simple flag make this mistake because the column encourages binary thinking.

**How to avoid:** The data model needs to distinguish `selection_method` from `faces_retention_vote`. Two approaches, in order of preference:
- Add a `faces_retention_vote: boolean` column to `essentials.politicians` (separate from `is_appointed`). Retention judges get `is_appointed = true` AND `faces_retention_vote = true`. The filter logic: show in Appointed if `is_appointed = true`; show in Elected if `is_appointed = false` OR `faces_retention_vote = true`.
- Alternatively, add `is_appointed_with_retention: boolean` as a third state alongside `is_appointed` and `is_elected`.

**Warning signs:** If a judge who appears on the Indiana retention ballot (Indiana Supreme Court, Court of Appeals) does not show up under the Elected filter, this pitfall has occurred. Cross-check by looking at the 2026 Monroe County ballot on Ballotpedia.

**Phase to address:** Phase 1 (data model design) — the schema decision must be made before any classification data is entered. Retrofitting a boolean to a three-state system after data entry requires a migration and re-audit of all judicial records.

---

### Pitfall 3: Election Data Has No Native Pipeline — Manual Entry Will Rot

**What goes wrong:** There is currently no election data pipeline. BallotReady was decommissioned. The platform has no mechanism to ingest candidate filings, election dates, or race definitions. If Election Central is built with manually-entered candidate records (inserted directly into the DB by hand), the data will become stale immediately after launch: candidates drop out, new candidates file, special elections are called, election dates change. Within 60 days of launch the page will display wrong candidates, wrong dates, and potentially candidates who have already won or lost.

**Why it happens:** Manual data entry is the path of least resistance. It unblocks the frontend build quickly. The decay problem is invisible until it causes user-visible errors. Special elections in particular are called with minimal advance notice (Congress special elections are called within days).

**How to avoid:** Before writing a single candidate record by hand, decide on a data source strategy and build at least a partial refresh mechanism:
- **Democracy Works Elections API** (data.democracy.works) — nonprofit-friendly, covers federal/state/local across all 50 states including Monroe County and LA County. Published data for 3,462 elections in 2025. Has a free-access tier for civic engagement orgs. This is the highest-confidence option for election dates and race definitions.
- **Ballotpedia API** — comprehensive local candidate data (top 100 cities by population). LA is covered; Bloomington (population ~90K) may be in scope. Paid tier, but has a nonprofit contact channel (data@ballotpedia.org). Covers candidate names, incumbency, party, filing status.
- **Manual entry with a structured refresh date** — if APIs are cost-prohibitive, build a `last_verified_at` timestamp on every candidate record and surface stale records (>30 days old) in the admin panel as a forcing function for re-verification.

At minimum, implement a `last_verified_at` timestamp and a `candidate_status` enum (`filed`, `qualified`, `withdrawn`, `elected`, `defeated`) regardless of which data source is used. Never display a candidate whose status is `withdrawn`.

**Warning signs:** No `last_verified_at` or `candidate_status` field in the schema. Any schema that only records that a candidate filed but has no mechanism to record that they withdrew. Missing a withdrawal deadline column — in many jurisdictions a candidate who missed the withdrawal deadline remains on the ballot even if they publicly quit the race.

**Phase to address:** Phase 1 (data source research and schema design) — this is the foundational decision the entire milestone rests on. Do not build the Election Central page UI until the data source and refresh strategy is settled.

---

### Pitfall 4: Antipartisan Principle Violated by Incumbent Display Logic

**What goes wrong:** Incumbents in a race are, by definition, known politicians already in the Essentials database. It is tempting to link incumbent candidate cards directly to their existing profile page, displaying their party affiliation, compass alignment, and all available data. But the platform's antipartisan principle (documented in MEMORY.md: "Never show political parties or use partisan color associations") applies equally to candidates as to current officials. The violation is subtle — party affiliation is not explicitly displayed, but when an incumbent's full profile is surfaced inline in the Election Central race view, and the profile includes their legislative voting history on partisan bills or their compass alignment, the partisan inference is trivially available. More obviously: any candidate data sourced from Ballotpedia or Democracy Works includes party affiliation fields. If those fields are stored in the candidate schema, they will leak into API responses, and frontend developers will use them.

**Why it happens:** Party affiliation is the single most commonly available data point for candidates. Every data source includes it. Filtering it out requires intentional, ongoing effort. Incumbent-to-profile linking bypasses the filter because the official profile pages were never designed for an election context where party inference is problematic.

**How to avoid:**
1. Do not store `party_affiliation` in the candidates table. Explicitly exclude it when consuming data from Democracy Works, Ballotpedia, or any other source. Document this exclusion in the import scripts with a comment explaining the antipartisan rationale.
2. When displaying an incumbent's Essentials profile card within an Election Central race, audit which data surfaces. Compass alignment comparison should be opt-in (same pattern as the Compare page), not displayed by default on the race listing.
3. The Elected/Appointed filter toggle itself is not partisan — this is safe. But adding "party" as a secondary filter or sort option is explicitly prohibited.

**Warning signs:** Any `party` or `party_affiliation` column in `essentials.candidates` or any JOIN query that surfaces `essentials.politicians.party` in election-related API responses (if such a column exists or is later added). Any filter or sort option that groups candidates by party.

**Phase to address:** Phase 2 (candidate data schema and import) — enforce the exclusion at the data ingestion layer, not in the frontend. Blocking party data from entering the DB is far easier than scrubbing it from API responses after the fact.

---

### Pitfall 5: Candidates and Officials in the Same Schema Collision

**What goes wrong:** The existing `essentials.politicians` table is designed for current officeholders: it has `total_years_in_office`, `election_frequency`, links to geofences/districts, and a profile page rendering pipeline. Candidates are not current officials. If candidates are inserted into the `politicians` table using a flag like `is_candidate: true`, the shared schema causes cascading problems:
- The address-based search (`ST_Intersects` geofence matching) returns candidates mixed with current officials if they happen to be associated with a district geofence.
- The legislative data pipeline (committees, bills, votes) will try to fetch data for candidates who have no legislative history.
- Challenger candidates (non-incumbents) have no `bioguide_id`, no `slug`, no photos in CDN, and no geofence association — all the fields that assume an existing official.
- Incumbent candidates ARE in the table already, so linking them is correct; but challenger candidates inserted here create orphaned records that pollute the officials dataset permanently.

**Why it happens:** Sharing a table avoids a JOIN for incumbent display and seems to simplify the data model. The differences are invisible until the edge cases surface during testing.

**How to avoid:** Create a separate `essentials.candidates` table that references `essentials.politicians` via `politician_id` (nullable — NULL for challengers) and `essentials.offices` via `office_id`. Separate concerns:
- `essentials.elections` — one row per race (election date, jurisdiction, office, district)
- `essentials.candidates` — one row per candidate-race pairing (politician_id nullable, name, is_incumbent, candidate_status, last_verified_at, filing_date, withdrawal_date)
- Incumbent profile pages link back to the existing `politicians` record. Challenger profile pages render from `candidates` data only.

This schema prevents geofence queries from returning candidates, keeps the legislative pipeline isolated, and allows challenger records to be deleted after the election without corrupting the officials dataset.

**Warning signs:** Any proposal to add `is_candidate`, `race_id`, or `election_date` columns to `essentials.politicians`. Any migration that adds candidate data to the existing politicians table.

**Phase to address:** Phase 1 (schema design) — the separate table boundary must be established before any candidate data is imported.

---

### Pitfall 6: Election Central Shows Stale "Upcoming" Races After Election Day

**What goes wrong:** The Election Central page is designed around showing "the next upcoming election." If the frontend filters races by `election_date > NOW()`, races disappear from the page the moment election day passes — which is correct. But if the filter is `election_date >= [hardcoded date]` or if `election_date` is stored as a date string without timezone, races in LA (Pacific time) may disappear 3 hours before they should for Indiana users, or persist 3 hours too long. More seriously: if the upcoming election filter has no refresh mechanism, the page goes blank after the election and there is nothing to show until the next election's data is entered.

**Why it happens:** Election dates feel stable and far away when first entered. Post-election state management is deprioritized until the election is over and the page breaks.

**How to avoid:**
1. Store `election_date` as a UTC timestamp (not a date-only string) in the database. Election day in Indiana is Eastern Time; in California it is Pacific Time — the cutoff for "upcoming" is not midnight UTC.
2. Implement an `election_status` enum: `upcoming`, `in_progress`, `results_pending`, `completed`. The frontend filter uses `election_status IN ('upcoming', 'in_progress')`.
3. Design the empty state for Election Central explicitly: when no upcoming elections exist, show the most recently completed election with results (if available) rather than a blank page.

**Warning signs:** `election_date` stored as `DATE` (not `TIMESTAMPTZ`). No `election_status` or equivalent field. No empty state design for Election Central when no upcoming elections are scheduled.

**Phase to address:** Phase 2 (Election Central page and election data schema).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Insert candidates into `essentials.politicians` with `is_candidate` flag | No new table, no JOIN needed for incumbents | Search queries return candidates mixed with officials; legislative pipeline runs on non-officials; challenger records pollute officials dataset post-election | Never — separate schema required |
| Store `party_affiliation` in candidates table "just in case" | Easier to display data from upstream sources | Violates antipartisan principle; will leak into API responses; very difficult to remove after downstream code depends on it | Never — exclude at ingestion |
| Manually enter all candidate data without a `last_verified_at` timestamp | Faster initial build | Data goes stale within weeks; no forcing function for re-verification; page misleads users about who is actually in a race | Never — timestamp is mandatory |
| Binary `is_appointed` boolean for the filter | Simpler query | Cannot represent retention judges (appointed + faces election); requires schema migration to fix | Never for jurisdictions with retention elections (Indiana, California) |
| Skip Democracy Works API integration and use Ballotpedia scraping instead | Avoids API cost | Ballotpedia terms of service prohibit scraping; ToS violation could result in IP block or legal exposure | Never — use API or manual entry |
| Hardcode election dates as string literals in code | Simple, visible | Election dates change (moved by legislation, special election called); requires code deploy to fix | Never — always from database |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Democracy Works Elections API | Assume free tier covers candidate-level data (names, incumbency, bio) | Free tier covers election dates and jurisdictions; full candidate data requires a paid plan or partnership agreement. Contact them as a nonprofit civic org for access terms. |
| Ballotpedia API | Assume local races (Bloomington, Monroe County) are covered in standard tier | Coverage is top 100 cities + 475 school districts. Bloomington (~90K pop) may fall just outside; verify before signing up. Monroe County races may require manual entry regardless. |
| Democracy Works Elections Calendar (free) | Use as the sole source of candidate names | Elections Calendar provides dates and jurisdiction data; it does NOT provide individual candidate filings. Candidate data needs a separate source. |
| BallotReady (now CivicEngine) | Attempt to re-integrate as election data source | BallotReady was decommissioned from this platform in v1.5 for cost reasons. Their API has had major enhancements since (OCD-ID support, 2025 updates) but requires a paid organizational plan. Only re-evaluate if budget is available. |
| Ballotpedia scraping | Scrape ballotpedia.org directly for candidate data | Ballotpedia ToS prohibits scraping. Use their API (paid) or contact data@ballotpedia.org for nonprofit data access. |
| Open States API | Assume Open States covers municipal/local candidates | Open States covers state legislators only (bills, votes, committees). It has "limited support" for municipal governments and does NOT provide candidate election data for city/county races. |
| Indiana Election Division | Expect structured API for candidate filings | Indiana does not expose a public API for candidate filings. The Monroe County Election Board website (`monroecountyvoters.us`) has a candidate portal but no machine-readable export. Manual verification required. |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading all races + all candidates in a single Election Central query | Fine for 2 upcoming elections; slow for full election history | Paginate: load only the next upcoming election by default; lazy-load historical elections | Breaks when 10+ elections with 50+ candidates each are stored |
| Linking candidate profiles to full politician profile rendering pipeline | First incumbent profile load is fast; subsequent renders trigger legislative data fetch | Add `is_candidate_view` flag to profile context to skip legislative fetch for challenger candidates who have no legislative data | Breaks immediately for any challenger candidate |
| Running `ST_Intersects` address match including candidates table | Address search returns candidates mixed with officials if candidates are improperly associated with geofences | Separate candidates from the geofence query entirely — candidates are discovered via Election Central, not via address search | Breaks as soon as any candidate record has a district association |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing `party_affiliation` in any API response | Enables partisan inference in what is intentionally a nonpartisan platform; also violates the documented antipartisan principle | Audit all election-related API endpoints before launch to confirm no party field is returned in any response payload |
| Displaying candidate home addresses | Candidates often provide home addresses on filing documents; including them in profile data is a safety risk | Do not store or display residential addresses for candidates — city/county of residence only |
| Admin election data entry with no access control | Malicious actor could insert fake candidates or modify election dates | All election admin endpoints must be behind existing `requireAuth` + admin role check |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing the elected/appointed toggle when `is_appointed` data is unverified | Users trust the filter; appointed officials appear as elected; trust is lost when discrepancy is noticed | Audit and verify `is_appointed` for all in-scope officials before shipping the toggle |
| Displaying "No upcoming elections" when an election exists but has no candidate data yet | User thinks the page is broken or coverage is missing | Show the election date and office list even if no candidates have been entered yet; indicate "Candidates will be listed as they file" |
| Presenting challenger and incumbent candidate profiles identically | Users cannot tell who currently holds the seat | Always label incumbents explicitly ("Incumbent" badge on the card); challenger cards should not have the legislative history section (it would be empty and confusing) |
| Linking Election Central only from the main nav (not from official profile pages) | Users who land on an official's profile have no path to see "is this person on the ballot?" | Add an "Upcoming election" callout on the official's profile page if they are a candidate in a registered race |
| Using red/blue color coding for "Elected" vs "Appointed" filter pills | Red/blue has partisan connotation in US civic context | Use neutral EV design tokens: `ev-coral` and `ev-muted-blue` are acceptable only if they are not consistently mapped to the same "side" as election results displays |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Elected/Appointed filter:** Verify retention judges appear under BOTH filter states, not only Appointed. Test with actual Indiana appellate judges from the 2026 ballot.
- [ ] **`is_appointed` data quality:** Run the audit query (`SELECT COUNT(*), is_appointed FROM essentials.politicians GROUP BY is_appointed`) and confirm the distribution is plausible before shipping the filter. All-false or all-true signals a defaulted field, not researched data.
- [ ] **Candidate schema separation:** Confirm no `is_candidate` flag was added to `essentials.politicians`. Confirm `essentials.candidates` exists as a separate table with a nullable `politician_id` FK for incumbents.
- [ ] **Antipartisan data exclusion:** Verify the candidates table schema has no `party`, `party_affiliation`, or `party_id` column. Check the import scripts for any field that is excluded with a comment explaining why.
- [ ] **Election data freshness:** Verify every candidate record has `last_verified_at` and `candidate_status` fields. Verify no candidate with `candidate_status = 'withdrawn'` is visible in the UI.
- [ ] **Post-election empty state:** After the next election passes, verify Election Central does not show a blank page — it should show the completed election results state or the "next upcoming election" state.
- [ ] **Challenger profile pages:** Navigate to a challenger candidate's profile. Confirm the legislative history section is absent (not visible, not an empty loading state, not an error).
- [ ] **UTC timestamp for election dates:** Confirm `election_date` is stored as `TIMESTAMPTZ`, not `DATE` or a string. Verify the "upcoming" filter uses server-side UTC comparison, not a client-side date string comparison.

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| `is_appointed` data found to be defaulted (all false) after filter ships | HIGH | Suspend the filter toggle UI, audit all officials in coverage scope, manually classify, re-enable toggle. Budget 1-2 days of classification work for ~800 officials. |
| Candidates accidentally inserted into `essentials.politicians` | HIGH | Requires: remove candidate-specific columns from politicians table via migration, create separate candidates table, migrate candidate rows, update all API endpoints and frontend references. Estimate 2-3 days of work. |
| Party affiliation data found in candidates table after launch | MEDIUM | `ALTER TABLE essentials.candidates DROP COLUMN party_affiliation`, redeploy API, purge any cached API responses. Fast technically but requires security review if data was ever served. |
| Retention judge appears under only Appointed (not Elected) | LOW | Add `faces_retention_vote` column (migration), update classification for retention judges, update filter query. 2-4 hours. |
| Election Central goes blank after election day | LOW | Implement `election_status` enum update (either scheduled job or manual admin toggle), update frontend empty state. 4-8 hours. |
| Stale candidate data (withdrawn candidate still showing) | MEDIUM | Requires a data verification pass and a process for ongoing maintenance. Technical fix is a `candidate_status` update + cache invalidation. Process fix is the harder part — must establish who owns ongoing data freshness. |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Stale `is_appointed` data from scraping pipeline | Phase 1: Data audit and classification backfill | Audit query shows plausible appointed/elected distribution; sample of known-appointed officials verified |
| Retention judges need dual filter appearance | Phase 1: Schema design | `faces_retention_vote` column exists; filter query includes `OR faces_retention_vote = true` in Elected result set |
| No election data pipeline → data rot | Phase 1: Data source selection | Data source decision documented; `last_verified_at` and `candidate_status` in schema before any data entered |
| Antipartisan principle violated by party storage | Phase 2: Candidate schema and import | `DESCRIBE essentials.candidates` shows no party column; import scripts have explicit exclusion comments |
| Candidates mixed into officials schema | Phase 1: Schema design | Separate `essentials.candidates` and `essentials.elections` tables exist with correct FK structure |
| Election Central blank after election day | Phase 2: Election page | `election_status` enum implemented; empty state designed and tested |
| UTC timestamp missing from election dates | Phase 1: Schema design | `election_date` column is `TIMESTAMPTZ`; verified before any data entry |
| Challenger profiles triggering legislative fetch | Phase 3: Candidate profile pages | Challenger profile page renders without legislative section; no API call to legislative endpoints on challenger load |

---

## Sources

- Direct inspection: `/Users/chrisandrews/Documents/GitHub/.planning/PROJECT.md` — v1.5 BallotReady decommission, v1.6 gap-fill pipeline, v2026.3.8 milestone target features
- Direct inspection: `CLAUDE.md` — antipartisan principle, district types, essentials schema documentation
- User memory (MEMORY.md): "NEVER show political parties or use partisan color associations" — antipartisan principle confirmed as absolute constraint
- [Indiana Judicial Branch: Indiana's Judicial Retention System](https://www.in.gov/courts/about/retention/) — appellate judges appointed then face retention vote; confirmed hybrid classification
- [Retention election — Ballotpedia](https://ballotpedia.org/Retention_election) — retention elections are not an initial selection method; combined with appointment; creates dual classification need
- [Indiana Judicial Branch: 2026 Judicial Retention](https://www.in.gov/courts/selection/marion/2026-retention/) — 2026 retention elections confirmed active for Indiana appellate judges
- [Monroe County, Indiana, elections, 2026 — Ballotpedia](https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026) — Monroe County trial court judges compete in partisan elections (not retention); state appellate judges use retention system
- [Democracy Works Elections API](https://data.democracy.works/ballot-info) — nonprofit-friendly, 3,462 elections in 2025, covers local races; free calendar access for civic orgs; candidate data requires partnership
- [Democracy Works: We Powered Democracy in 2025](https://www.democracy.works/news/we-powered-democracy-in-2025) — nonprofit coverage and mission confirmed
- [Ballotpedia: Buy Political Data](https://ballotpedia.org/Ballotpedia:Buy_Political_Data) — paid API; top 100 cities + 475 school districts; contact data@ballotpedia.org for nonprofit access
- [Ballotpedia API documentation](https://developer.ballotpedia.org) — candidate fields include party affiliation; must be excluded at ingestion for antipartisan compliance
- [Candidate withdrawal — Ballotpedia](https://ballotpedia.org/Candidate_withdrawal) — candidate withdrawal defined; withdrawal deadline critical (missed deadline = name stays on ballot)
- [Open States API v3 Overview](https://docs.openstates.org/api-v3/) — confirmed state legislative data only; limited municipal support; no candidate election data for city/county races
- [BallotReady for Organizations](https://organizations.ballotready.org) — API still active as of 2025 with OCD-ID enhancements; paid organizational plan required
- [American local government elections database — Scientific Data](https://www.nature.com/articles/s41597-023-02792-x) — confirms persistent challenge of decentralized local election data; lack of centralized sources well-documented
- [Notice of Turndown of the Representatives API — Google Groups](https://groups.google.com/g/google-civicinfo-api/c/9fwFn-dhktA) — Google Civic Information API deprecating representative data; ecosystem shifting to BallotReady/Ballotpedia/Cicero
- [Judicial Selection: A Glossary — Brennan Center](https://www.brennancenter.org/our-work/research-reports/judicial-selection-glossary-terms) — confirmed no single classification for states using combined appointment + retention selection
- [Voter guides: Using color effectively — Center for Civic Design](https://civicdesign.org/voter-guides-using-color-effectively/) — color in civic election contexts carries partisan associations; use deliberately

---
*Pitfalls research for: Election Central page and elected/appointed filter added to existing Essentials civic platform*
*Researched: 2026-03-29*
