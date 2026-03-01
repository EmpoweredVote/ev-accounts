# Domain Pitfalls: Legislative Profile Data

**Domain:** Adding legislative activity data (committees, votes, bills, leadership) to an existing civic engagement platform
**Researched:** 2026-03-01
**Confidence:** HIGH (Congress.gov API mechanics — verified against official GitHub repo + Library of Congress docs), HIGH (data source ID linking — verified against unitedstates/congress-legislators README + OCD-ID standard documentation), MEDIUM (Open States/LegiScan coverage gaps — verified against official docs + community discussion; specifics change with scraper maintenance cycles), MEDIUM (Legistar API access — verified against Granicus docs + LA County portal inspection), LOW (Bloomington Common Council data structure — based on city website inspection, not tested programmatically)

---

## Critical Pitfalls

Mistakes that cause rewrites, dead data, or architectural dead ends.

---

### Pitfall 1: Building a Universal Legislative Schema That Most Jurisdictions Can Never Fill

**What goes wrong:**
The natural instinct when designing a "full data model" for jurisdictions, governing bodies, sessions, committees, bills, and votes is to design it for the most complex case — the U.S. Congress — and expect all lower tiers to conform. This produces a schema with mandatory or near-mandatory fields (session start/end dates, bill number format, roll call vote IDs, committee jurisdiction descriptions) that federal data populates correctly but that will be NULL for 80-90% of the Bloomington Common Council records indefinitely.

The problem compounds when the frontend starts checking for these fields: a committee assignment card shows "Chair of [committee] — 118th Congress (Jan 2023 – Jan 2025)" for a senator but "Member of [committee]" with no session dates for a Bloomington council member — even though the Bloomington council doesn't track legislative sessions in any machine-readable format. The schema has the session fields; the data never arrives.

For a 2-3 dev nonprofit team, the bigger danger is the build time: a universal schema takes 2-4x longer to implement correctly (foreign key chains across 6+ tables, migration ordering, composite unique constraints) and the payoff is data that only exists for federal officials until local scraping is built.

**Why it happens:**
Schema design starts from the data model spec, not from available data inventory. The milestone goal says "full data model (jurisdictions, governing bodies, seats, legislative sessions, committees, legislation, votes)" — this is a correct target, but the order of operations matters. Building all 6 table tiers before validating what Bloomington actually exports from its OnBoard system leads to weeks of infrastructure for data that may take months to populate.

**Consequences:**
- Empty tables in production that the frontend must defensively code around from day one
- Schema migrations that must be run on Supabase in strict dependency order (jurisdictions → bodies → sessions → committees → legislation → votes) — any error cascades
- GORM AutoMigrate handles column additions but not foreign key additions to existing tables without manual migration scripts
- Frontend defensive code ("if no votes, hide votes section") written for 5 cases before a single vote is imported

**Prevention:**
Invert the build order: data inventory first, schema second. Before writing a single GORM model, answer these questions for each jurisdiction:

| Question | Federal (Congress.gov) | Indiana (Open States/LegiScan) | Bloomington (OnBoard) | LA County (Legistar) |
|----------|----------------------|-------------------------------|----------------------|---------------------|
| Are legislative sessions machine-readable? | YES — congress number | YES — session years | NO — PDF minutes only | PARTIAL — Legistar has matter dates |
| Are committee assignments available via API? | YES — Congress.gov /member/{id}/committee-assignments | PARTIAL — Open States has some | NO | PARTIAL — Legistar has body assignments |
| Are individual votes available? | YES — /vote/{congress}/{chamber}/{rollCallNumber} | PARTIAL — not all states | NO | NO — Board of Supervisors votes not in Legistar API |
| Is bill sponsorship available? | YES | YES — Open States | NO | PARTIAL |

Build only the layers that have data to fill them within this milestone. Add session-level tables when session data is actually available — not in anticipation of it.

**Detection:**
After initial data import, run: `SELECT table_name, n_live_tup FROM pg_stat_user_tables WHERE schemaname = 'legislative' ORDER BY n_live_tup ASC LIMIT 10` — any table with 0 rows that was part of the "full model" is infrastructure without data. More than 2 such tables signals over-engineering.

**Phase to address:**
Data inventory phase (before any schema design). The output of this phase is a jurisdiction capability matrix — which data sources provide what, at what fidelity. Schema design follows directly from this matrix.

---

### Pitfall 2: Congress.gov API Pagination Silently Truncates Results at 250 Per Request

**What goes wrong:**
The Congress.gov API returns a maximum of 250 results per request, regardless of what you pass as `limit`. If you request `limit=500`, you get 250 with no error — just a silent truncation. A 119th Congress has 535 members; fetching all committee assignments in a single request will appear to succeed (HTTP 200, result count looks reasonable) but will be missing assignments for whoever fell past position 250 in the sort order.

For bills and votes the volume is much higher: the 118th Congress introduced ~26,000 bills. A naive pagination implementation that fetches page 1, checks that `count < limit`, and stops will import only the first 250 bills and consider the job done. The `total` field was removed from the API response (it now only returns `count` — the number of items in the current response), making it harder to know how many total items exist without implementing proper exhaustive pagination from the start.

**Why it happens:**
Developers test against a single Congress member's record (small result set, fits in one page) or a recent bill search (small date range, few results). The test succeeds, pagination code is skipped as "good enough," and the production import misses thousands of records.

The `fromDateTime` / `toDateTime` date filter parameters are essential for incremental imports but are easy to get wrong: the API uses UTC ISO 8601 format (`2023-01-01T00:00:00Z`), and dates must be precise to the second. An off-by-one on the date range (e.g., using `toDateTime` of a past import run but the API uses `updateDate` not `introduced_date`) causes gaps in incremental imports.

**Consequences:**
- Vote records are incomplete — roll calls before a certain offset are never imported
- Committee assignments missing for members alphabetically late (if sort is by member name)
- Incremental imports create gaps when `fromDateTime` is mis-set, causing votes to silently disappear from the profile

**Prevention:**
Implement exhaustive pagination from the first import:

```go
func fetchAllPages(endpoint string, params url.Values) ([]json.RawMessage, error) {
    var all []json.RawMessage
    offset := 0
    limit := 250

    for {
        params.Set("limit", strconv.Itoa(limit))
        params.Set("offset", strconv.Itoa(offset))

        resp, err := callCongressAPI(endpoint, params)
        if err != nil {
            return nil, err
        }

        all = append(all, resp.Items...)

        if len(resp.Items) < limit {
            break // last page
        }
        offset += limit
    }
    return all, nil
}
```

Always use `len(items) < limit` as the stop condition — never trust a `total` count (it was removed from the API). For incremental imports, store the `lastImportedAt` timestamp in the database and use it as `fromDateTime` on the next run, with a 5-minute lookback buffer to catch updates that arrived near the boundary.

Rate limit: 5,000 requests/hour. For the initial full import (26,000 bills × multiple sub-endpoints each), plan for a multi-hour background job, not a web request handler.

**Detection:**
After importing a session, run: `SELECT COUNT(*) FROM legislative.votes WHERE congress_session = 118` — compare against the known count from Congress.gov website (118th Congress had ~1,400 roll call votes in the House alone). Any import less than 80% of the known count indicates pagination failure.

**Phase to address:**
Congress.gov API client implementation phase — pagination must be in the first version of the client, not added as a "fixup" after the import appears to succeed.

---

### Pitfall 3: Legislator Identity Matching Across Sources Breaks Without a Canonical ID Layer

**What goes wrong:**
The platform already stores federal officials via BallotReady (now decommissioned) and geofence data, with `bioguide_id` in the `essentials.politicians` table. The legislative data sources all use different identifiers:

- Congress.gov: `bioguide_id` (e.g., "S000033")
- unitedstates/congress-legislators YAML: `bioguide`, `thomas`, `govtrack`, `fec`, `opensecrets`, `votesmart`, `ballotpedia` IDs
- Open States: `ocd_id` (Open Civic Data standard — e.g., "ocd-person/123abc...")
- LegiScan: `people_id` (LegiScan-specific integer)
- Legistar (LA County): `PersonId` (Granicus internal integer)
- Bloomington OnBoard: No stable ID — human-readable names only in PDF minutes

The failure mode: you import a senator's committee assignments from Congress.gov using their `bioguide_id`, then try to link them to the politician record in `essentials.politicians`. If `bioguide_id` was never populated (it's nullable in the current schema), the JOIN fails silently — the assignments are imported but orphaned, associated with no politician.

For state legislators: Open States uses OCD-IDs. The existing codebase uses OCD-IDs for geofence matching but does NOT store them on politician records. Matching an Indiana state senator from LegiScan (`people_id: 12345`, name "Jane Smith") to the existing politician record (full_name: "Jane Smith", district: "Indiana Senate District 40") requires either a reliable external ID or a fuzzy name + district match — which breaks for common names, name variants (Jane vs. Janet), and mid-term replacements.

**Why it happens:**
Each data source uses its own ID system. The `essentials.politicians` table was built around `external_id` from BallotReady, which is now decommissioned. The `bioguide_id` field exists but was populated only for federal officials during the BallotReady era, and some records may have NULL even for current federal officials.

**Consequences:**
- Legislative data imported but orphaned — committee assignments, votes, and bills exist in the legislative schema but cannot be joined to politician profiles
- Duplicate politician records created: the import creates a new `essentials.politicians` row for a senator who already exists under a different external ID
- State legislator matching requires manual disambiguation table that grows over time

**Prevention:**
Build an ID bridge table before importing any legislative data:

```sql
CREATE TABLE legislative.politician_id_map (
    politician_id    UUID NOT NULL REFERENCES essentials.politicians(id),
    id_type          TEXT NOT NULL,  -- 'bioguide', 'ocd_person', 'legiscan', 'legistar', 'openstates'
    id_value         TEXT NOT NULL,
    verified_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE (id_type, id_value)
);
```

Populate this table for federal officials first: download `unitedstates/congress-legislators` YAML (updated daily), cross-reference `bioguide_id` in the YAML against `bioguide_id` in `essentials.politicians`. For each match, insert a row for `bioguide`, `govtrack`, and `opensecrets` IDs. This gives you a verified mapping for all current and recent federal officials before the first Congress.gov API import.

For state officials: use the OCD-ID standard. Open States provides OCD-IDs; the existing geofence schema already uses `ocd_id` on districts. Insert politician-level OCD-IDs from Open States into the bridge table.

For local officials with no stable ID: match by `(full_name, governing_body, is_active=true)` but treat this as LOW confidence — log the match reasoning and require human verification before using it in production.

**Detection:**
After import, check orphan rate: `SELECT COUNT(*) FROM legislative.committee_assignments WHERE politician_id IS NULL`. Any non-zero count indicates the ID bridge is incomplete.

**Phase to address:**
First phase of legislative data — before any API import. Populating the ID bridge table is a prerequisite, not an afterthought.

---

### Pitfall 4: Vote Data Volume Makes Lazy-Fetch Impractical for Federal Officials

**What goes wrong:**
The milestone proposes "hybrid data fetching: import for static data (committees, leadership), lazy-fetch for dynamic data (votes, bills)." This is reasonable in principle but the volumes break the lazy-fetch pattern for federal officials.

A two-term U.S. senator has voted on ~8,000-12,000 roll calls. A lazy-fetch triggered on first profile view would need to:
1. Call Congress.gov `/member/{bioguide_id}/votes` with exhaustive pagination (40-48 requests at 250/page)
2. Wait for all responses (rate limited at 5,000/hour → minimum 30+ seconds for the first profile view)
3. Import and upsert thousands of vote records
4. Return the profile page

This turns a profile page load into a multi-minute operation. Even with caching (fetch once, serve from DB forever), the first user to view a senator's profile triggers a 2+ minute server-side job during their request. The existing BallotReady lazy-fetch in the essentials module worked because a single API call returned all data for a profile — legislative votes require dozens of paginated calls.

**Why it happens:**
The lazy-fetch pattern was validated on BallotReady's candidacy endpoint (one call per politician, small response). Vote history is structurally different: it is a paginated collection with thousands of items, not a single profile document.

**Consequences:**
- First profile view for a federal official times out (Go's default HTTP timeout, or Render's 30-second request timeout)
- Rate limit exhausted quickly if multiple users hit different senator profiles simultaneously (5,000 requests/hour shared across all profile views)
- Background goroutine approach (fire-and-forget import) results in users seeing empty vote sections for minutes after first visit

**Prevention:**
Use import-at-session-boundary for federal votes, not lazy-fetch. The 119th Congress started January 2025; run a background import job (CLI command, not request-triggered) that fetches all votes for the current session. Schedule it to run weekly via a cron-style mechanism (Render cron jobs, or a simple CLI invocation from a scheduled task).

```go
// CLI: go run . import-legislative --source congress --data-type votes --congress 119
// Not triggered by HTTP requests
```

For the profile page, show only the most recent N votes (e.g., last 50) fetched from the pre-imported table — this is a fast DB query, not an API call. Add a "View full voting history" link that paginates from the DB, not from the API.

Reserve lazy-fetch for lower-volume data: committee assignments (one call per member, small response), leadership roles, and sponsored bills (reasonably bounded).

**Detection:**
Measure time from profile page request to response for a federal senator. Any response > 5 seconds indicates a lazy-fetch is happening that should be pre-imported. Monitor Congress.gov API request counts per hour — spikes during business hours indicate lazy-fetch calls triggered by user traffic.

**Phase to address:**
Import architecture design phase — the vote import strategy must be decided before writing any profile-serving code. Do not start with lazy-fetch and "optimize later"; the rewrite cost is high.

---

### Pitfall 5: Open States Coverage Is Uneven — Indiana and California Have Different Gap Profiles

**What goes wrong:**
Open States (now operated by Plural Policy) provides standardized state legislative data, but coverage varies significantly by state. Indiana and California have different known patterns:

**Indiana:** Open States historically treated Indiana as part of the second-tier rollout. Indiana has a biennial legislative session (only meets in odd-numbered years for full sessions, even years for short sessions), which means vote data has natural gaps. Committee assignment data quality is lower than bill/vote data. The Indiana General Assembly website provides data, but committee membership updates are less frequently scraped than bill status.

**California:** California provides MySQL database dumps rather than a structured API — Open States must stand up a local MySQL instance to process this data. This introduces a scraper maintenance burden unique to California. When California's legislature updates its database schema (which it does), the Open States scraper breaks until someone fixes it. During a scraper outage, the last-good data is served — potentially weeks old during an active session.

**LegiScan alternative:** LegiScan covers both Indiana and California with a 30,000 request/month free tier. LegiScan's data for Indiana and California is sourced directly from the state, not from Open States. The tradeoff: LegiScan provides more consistent coverage but uses its own `people_id` (not OCD-IDs), requiring a separate ID bridge entry.

**Why it happens:**
Civic data platforms assume "Open States covers 50 states" means uniform coverage. It means consistent schema, not consistent data quality or freshness.

**Consequences:**
- Indiana committee assignments imported with gaps — some legislators show no committee data when they do serve on committees
- California data may be weeks stale during session if the MySQL dump scraper is broken
- Relying on Open States as sole state source creates a single point of failure with no visibility into scraper health

**Prevention:**
Use LegiScan as the primary state data source for Indiana and California, with Open States as verification/cross-check. LegiScan's 30,000 request/month free tier is sufficient for importing two states' current session data plus incremental updates.

For monitoring scraper health: check Open States' `/states/` endpoint for each state's `last_bill_update` timestamp. If it's more than 7 days old during a session, the scraper is likely broken — fall back to LegiScan.

Do not depend on Open States for committee assignment data without verification — compare Open States committee assignments against the state legislature's own website for a sample of 5 legislators before treating the data as authoritative.

**Detection:**
After importing Indiana state legislative data, manually verify committee assignments for 3 known Indiana senators against the Indiana General Assembly website (iga.in.gov). Any mismatch indicates a coverage gap. Run this verification after each import cycle, not just once.

**Phase to address:**
State data source selection phase — choose LegiScan as primary before writing any Indiana/California import code. Document the Open States monitoring check as a recurring maintenance task, not a one-time setup.

---

### Pitfall 6: Local Government Data Does Not Exist in Any Machine-Readable Form — Bloomington Is Better Than Most, LA Is Mixed

**What goes wrong:**
The milestone includes "local data via scraping (Bloomington Common Council, LA County bodies)." The reality is a spectrum:

**Bloomington Common Council (better end of the spectrum):**
- Meeting minutes published as PDFs via OnBoard system (bloomington.in.gov/onboard)
- Agendas published as PDFs before each meeting
- No structured vote data export — individual votes must be extracted from meeting minutes PDFs
- No committee assignment API or structured list — committees listed on the city website as static HTML
- Civic Webcast video available but not machine-readable
- Vote counts in minutes format: "Motion passed 8-1" — no individual member vote attribution unless minutes are structured (many aren't)

**LA County Board of Supervisors (Legistar, partially structured):**
- LA County uses Legistar (lacounty.legistar.com) — Granicus provides a web API at `webapi.legistar.com/v1/{client}/matters`
- Board items (matters) have structured data including sponsors, dates, and status
- Individual board member votes are NOT available in the Legistar API — vote counts are in agenda documents
- Some clients require an API token from Granicus; LA County's token availability is not publicly documented

**LA City Council (separate from LA County — different system):**
- City of Los Angeles uses a separate Legistar instance (cityclerk.lacity.org)
- Council file management system is searchable but vote records require scraping
- This is a different entity than the LA County Board of Supervisors — do not conflate them

**Why it happens:**
The milestone description says "local scraping" as if it's a tractable category. It is not — it is a heterogeneous collection of one-off data access problems specific to each body. What works for LA County Board of Supervisors won't work for Bloomington Common Council and won't work for LA City Council.

**Consequences:**
- Weeks of scraping work yields committee assignments (static HTML extraction) but zero individual vote records for Bloomington
- LA County Legistar API gives structured matter data but no member votes — the profile "voting record" section is empty despite significant engineering effort
- LA City Council data scraping is scoped as "LA County bodies" but is a distinct engineering task

**Prevention:**
Scope local legislative data explicitly, not aspirationally. For this milestone:

| Body | What Is Achievable | What Is Not Achievable |
|------|-------------------|----------------------|
| Bloomington Common Council | Committee assignments (HTML scrape), leadership roles (HTML scrape) | Individual vote records (PDF extraction required, high effort) |
| LA County Board of Supervisors | Matter/legislation tracking via Legistar API | Member-level vote attribution |
| LA City Council | Matter/legislation tracking (different Legistar instance) | Member-level vote attribution |
| Indiana General Assembly | Bills, votes, committee assignments via LegiScan | Floor debate context |
| California Legislature | Bills, votes, committee assignments via LegiScan | Floor debate context |

Build only what is achievable. "Voting record" section on local profiles should either be omitted or show a "Not available for this jurisdiction" message — not be built as empty infrastructure waiting for data that requires a separate milestone.

**Detection:**
Before writing any scraper, manually inspect the data source for each body. Open the Legistar API (`webapi.legistar.com/v1/LACounty/VoteRecords`) and check whether it returns individual member votes or just matter-level outcomes. If the response is empty or error, the feature cannot be built from this source.

**Phase to address:**
Local data feasibility phase — before any scraper implementation. Each body requires a 2-4 hour feasibility check (manual inspection of available data) before committing to implementing a scraper. The feasibility check output is a decision: "build," "defer," or "not possible for this milestone."

---

### Pitfall 7: Bill Status "Normalization" Hides State-Specific Complexity That Users Need to See

**What goes wrong:**
Federal and state legislatures use different status systems. Congress uses a status progression (Introduced → Committee → Floor → Passed/Failed → Signed/Vetoed). Indiana uses a different set of status codes. California uses its own. A unified `bill_status` field that maps all of these to a common set (e.g., "Active", "Passed", "Failed") loses information users need: a bill that "passed the House" is meaningfully different from a bill that "was signed into law" — both might map to "Passed" in an over-normalized schema.

The deeper problem: "Introduced" status is the most common status by far (~70% of bills in any session never advance past introduction). A profile showing 200 "introduced" bills for a senator tells the user almost nothing useful. The meaningful filter is "what did this person actually do" — bills they sponsored that passed committee, votes where they were on the minority side, bills they sponsored that became law.

**Why it happens:**
Data normalization is a natural engineering instinct. Building a status enum with 5 values seems cleaner than storing 15+ state-specific status strings. But civic data users (and press) understand "referred to committee" and "signed by governor" — they do not understand "Active."

**Consequences:**
- Status normalization implemented, then immediately needs to be reverted when frontend team realizes "Active" is not useful
- Over-normalized status causes a second-pass migration to add raw status strings
- Profile pages show 200 "introduced" bills that users ignore — the section looks broken even though the data is correct

**Prevention:**
Store both the raw status string from the source (`raw_status: "REFERRED_COMMITTEE"`) and a human-readable normalized label (`status_label: "In Committee"`). Do not build an enum — use a lookup/translation table per data source. This preserves the source data while enabling display normalization.

For the profile display, implement a significance filter from day one: show only bills where `status_label NOT IN ('Introduced', 'Referred to Committee')` by default, with an "expand to see all sponsored bills" option. A senator who sponsored 180 bills that were introduced and died, and 12 bills that passed, should show 12 bills by default.

**Detection:**
After importing a session's bill data, check: `SELECT status_label, COUNT(*) FROM legislative.legislation GROUP BY status_label ORDER BY COUNT(*) DESC` — if "Introduced" or its equivalent is >50% of rows, the display layer needs a significance filter or users will see a wall of stalled bills.

**Phase to address:**
Bill data display design phase — define the significance filter before building the frontend components. The schema should store raw + normalized status from the start.

---

### Pitfall 8: Congress.gov API Requires Separate Calls for Each Sub-Resource — N+1 Requests for Profile Pages

**What goes wrong:**
Congress.gov API does not have a single endpoint that returns a member's profile with all legislative activity included. A complete legislator profile requires separate API calls for:

1. `GET /member/{bioguideId}` — basic member info
2. `GET /member/{bioguideId}/sponsored-legislation` — sponsored bills (paginated)
3. `GET /member/{bioguideId}/cosponsored-legislation` — cosponsored bills (paginated)
4. `GET /member/{bioguideId}/committee-assignments` — current committees
5. For each committee: `GET /committee/{committeeCode}` — committee details

A senator serving on 5 committees requires 5 + 1 + paginated legislation calls — easily 10-20 API requests per member. With 535 current members and 5,000 requests/hour rate limit, a full import takes 2-3 hours even with optimal parallelism.

The gotcha: sub-resource endpoints (sponsored-legislation, cosponsored-legislation) use different pagination than the member list endpoint. The `count` vs `total` removal (documented in the changelog) means you cannot pre-calculate how many pages to fetch — you must fetch until `len(items) < limit`.

**Why it happens:**
Developers look at the member endpoint and assume "I get all the data for a member in one call." The Congress.gov API is designed as a resource-oriented REST API where each sub-collection is a separate endpoint. This is correct API design but creates N+1 patterns if the client is written naively.

**Consequences:**
- Full import takes significantly longer than estimated — planning around "500 requests should be fast" fails to account for sub-resource pagination
- Rate limit is hit mid-import, causing partial imports that look complete (no error) but are missing data
- Each import run re-fetches all sub-resources even for members who have not had legislative activity since last import

**Prevention:**
Use `updateDate` filtering for incremental imports: `GET /member/{bioguideId}/sponsored-legislation?fromDateTime={lastImportAt}` fetches only bills updated since last run. This dramatically reduces request volume for recurring imports.

For the initial full import: use the `fromDateTime` / `toDateTime` parameters on collection endpoints to batch by date range rather than by member. Fetch all legislation updated in a given month, extract the sponsors, then update the database — rather than iterating member-by-member.

Respect the rate limit: implement a token bucket in the Go API client that enforces 5,000 requests/hour with a small safety margin (use 4,500/hour to avoid throttling on burst):

```go
type CongressClient struct {
    limiter *rate.Limiter // golang.org/x/time/rate
}

// 4,500 per hour = 1.25 per second
func NewCongressClient(apiKey string) *CongressClient {
    return &CongressClient{
        limiter: rate.NewLimiter(rate.Limit(1.25), 5),
    }
}

func (c *CongressClient) Get(ctx context.Context, path string) (*http.Response, error) {
    if err := c.limiter.Wait(ctx); err != nil {
        return nil, err
    }
    return c.doGet(path)
}
```

**Detection:**
Log each API request with its timestamp during import. After a full run, check whether any 429 responses were received. If rate limiting occurred, the import is incomplete even if no error was surfaced — 429 from Congress.gov returns an error message but the import code may not handle it correctly.

**Phase to address:**
Congress.gov API client implementation phase — rate limiting and incremental update logic must be in the first version, not added after the first failed import.

---

## Moderate Pitfalls

Issues that create significant rework but not rewrites.

---

### Pitfall 9: Name Matching as Fallback Breaks for Common Names, Name Variants, and Replacements

**What goes wrong:**
When the ID bridge table (see Pitfall 3) cannot match a legislator by external ID, the fallback is name matching. Name matching fails in predictable patterns:

- **Name variants:** "Patrick" vs "Pat", "Elizabeth" vs "Liz", "Jr." included in some sources but not others
- **Common names:** "John Smith" — multiple legislators with identical names exist (there have been multiple representatives named "John Young" and "Jim Smith" serving in different Congresses)
- **Mid-term replacements:** A legislator dies or resigns, a replacement is appointed with a similar district — name matching creates a new politician record instead of using the replacement's record
- **Hyphenated/compound last names:** "Smith-Jones" in one source, "Smith Jones" in another

For state legislators with no stable cross-source ID (Bloomington council members), name matching is the ONLY option — the risk is high.

**Prevention:**
Implement tiered matching confidence:
1. External ID match (HIGH confidence — use directly)
2. Name + district + chamber match (MEDIUM confidence — log and use, flag for periodic review)
3. Name-only match (LOW confidence — do NOT auto-link; create a staging record for manual review)

Build a `legislative.unmatched_legislators` table where LOW confidence matches are queued. A periodic admin review of this table (monthly) resolves ambiguous matches without blocking imports.

**Phase to address:**
ID bridge and matching logic phase — define confidence tiers before writing any matching code.

---

### Pitfall 10: Legistar API Requires Client-Specific Token and Is Not Self-Service

**What goes wrong:**
The Legistar Web API (webapi.legistar.com) is documented as publicly accessible, but some clients require an API token from Granicus. LA County's Legistar instance is at `lacounty.legistar.com`. The API client name for the LA County Board of Supervisors is `"LACounty"`. Attempting to access `webapi.legistar.com/v1/LACounty/matters` without checking whether a token is required will result in HTTP 401 or empty responses — not a clear error.

Additionally, the Legistar Web API exposes legislative matters (agenda items) but does NOT expose roll call votes for individual board members in most configurations. The LA County Board of Supervisors votes are recorded in agenda minutes PDFs, not the Legistar database. This means the Legistar API provides what was proposed and its outcome (passed/failed) — not who voted which way.

**Prevention:**
Before writing any Legistar integration code: manually test `webapi.legistar.com/v1/LACounty/matters` and `webapi.legistar.com/v1/LACounty/VoteRecords` from a browser or curl. Verify the response format and whether authentication is required. If VoteRecords is empty or unauthorized, accept that member-level vote attribution is not available from this source and scope the feature to matter/legislation tracking only.

**Phase to address:**
Local data feasibility phase — a 1-hour manual inspection resolves this question before any implementation begins.

---

### Pitfall 11: Congressional Session Boundary Creates Discontinuities in Committee Data

**What goes wrong:**
Committee assignments change with each new Congress (every 2 years). A senator who chaired the Judiciary Committee in the 118th Congress may no longer chair it in the 119th — or may no longer be in the Senate at all. The `legislative.committee_assignments` table needs to track the Congress number (session) to distinguish historical from current assignments.

Without session tracking, an import of 119th Congress committees will either overwrite 118th Congress assignments (losing historical data) or create duplicates (same senator, same committee, two rows with no way to tell which is current).

The related gotcha: the 119th Congress began January 2025. The platform's existing data (from BallotReady, now decommissioned) may include federal officials who served in the 118th Congress but did not win re-election in November 2024. Their committee assignments should be marked historical, not displayed as current.

**Prevention:**
Include `congress_number` (or `session_id` referencing a sessions table) on every committee assignment record. Index on `(politician_id, committee_id, congress_number)` with a UNIQUE constraint. On each import, upsert with the congress number — do not delete and recreate, which loses history.

For display: add a `is_current` boolean derived from `congress_number = {current_congress}` — this controls whether the assignment appears in the "current committees" section vs. the "past committees" section on the profile.

**Phase to address:**
Committee data schema design phase — add session/congress tracking before the first import.

---

## Minor Pitfalls

Issues manageable with care but that have bitten civic tech projects before.

---

### Pitfall 12: Bill Summary Text Is Not Available in Congress.gov API for All Bills

**What goes wrong:**
The milestone goal includes "plain-language bill summaries." The Congress.gov API has a `/bill/{congress}/{billType}/{billNumber}/summaries` endpoint, but CRS (Congressional Research Service) summaries are only written for a subset of bills — approximately 30-40% of introduced legislation receives a CRS summary. For bills without a CRS summary, the only text available is the bill's formal title (often highly technical: "To amend the Internal Revenue Code of 1986 to...") and the full bill text (potentially hundreds of pages).

For state bills via LegiScan: full bill text is available as PDF or HTML, but no plain-language summaries exist — the summary must be generated or sourced from press releases.

**Prevention:**
Display available summaries when they exist; fall back gracefully to the short title when no summary is available. Do not block the bill display on summary availability. Plan for a "generate summary" feature (LLM-based, using the bill's official summary or digest) as a future enhancement, not a prerequisite for launch.

**Phase to address:**
Bill display component design — implement the fallback from day one.

---

### Pitfall 13: Parallel Imports of Votes and Bills Can Violate Foreign Key Constraints

**What goes wrong:**
The legislative schema has foreign key chains: a vote record references a bill, which references a committee, which references a governing body. If vote import runs in parallel with bill import (both triggered as background goroutines), a vote for a bill that has not yet been inserted will fail the foreign key constraint.

This is a particularly insidious failure: the goroutines may succeed individually, but the vote rows that arrive before the bill rows are silently dropped (if using `ON CONFLICT DO NOTHING`) or cause import errors that are swallowed.

**Prevention:**
Import in dependency order: governing bodies → sessions → committees → legislation → votes. Use a sequenced import CLI command that enforces this order, not concurrent goroutines. Each step logs completion before the next begins.

**Phase to address:**
Import pipeline implementation — enforce dependency order in the CLI command structure.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Data model design | Over-engineering for jurisdictions that have no data | Build only what data inventory confirms is available; add tables when data arrives |
| Congress.gov client | Pagination truncation at 250 | Exhaustive pagination from day one; `len(items) < limit` stop condition |
| Congress.gov client | Rate limit exceeded mid-import | Token bucket at 1.25 req/sec (4,500/hour); CLI import not HTTP-request-triggered |
| Legislator ID matching | Orphaned legislative data | ID bridge table populated before any import; tiered confidence matching |
| Federal vote import | Profile page timeout from lazy-fetch | Batch import at session boundary; DB-served vote history on profile |
| State data (IN/CA) | Open States coverage gaps or scraper outage | LegiScan as primary source; Open States as verification layer |
| Local data (Bloomington) | No machine-readable votes in minutes PDFs | Scope to committee assignments only; defer vote extraction to a future milestone |
| Local data (LA County) | Legistar API has matters but not member votes | Scope to matter tracking; document that vote attribution is not achievable from this source |
| Bill status display | "Introduced" bills dominate the display | Significance filter from day one: default to bills that progressed past introduction |
| Parallel imports | FK constraint violations | Sequential import order enforced by CLI; governing bodies → sessions → committees → bills → votes |
| Committee assignment history | Current session overwrites historical | `congress_number` on every assignment row; UNIQUE on `(politician_id, committee_id, congress_number)` |

---

## Sources

- Congress.gov API GitHub repository (official): [LibraryOfCongress/api.congress.gov](https://github.com/LibraryOfCongress/api.congress.gov) — rate limits (5,000/hour), pagination (max 250/request), `total` field removal, `fromDateTime`/`toDateTime` parameters, known bugs in changelog
- Congress.gov API changelog: [ChangeLog.md](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/ChangeLog.md) — documented pagination bugs in bill and amendment endpoints, sorting issues, law endpoint errors
- Library of Congress rate limits: [Working Within Limits](https://www.loc.gov/apis/json-and-yaml/working-within-limits/) — 5,000 requests/hour confirmed; deep paging 100,000 item limit
- unitedstates/congress-legislators: [README](https://github.com/unitedstates/congress-legislators/blob/main/README.md) — bioguide, govtrack, fec, opensecrets, thomas IDs for all members; daily updates; stable bioguide ID across sessions
- Bioguide ID system: [Congress.gov Member IDs](https://www.congress.gov/help/field-values/member-bioguide-ids) — BioGuide IDs as stable cross-session identifiers
- Open Civic Data Identifiers: [Cicero Data explainer on OCD-IDs](https://medium.com/cicero-data/how-to-use-open-civic-data-identifiers-to-organize-political-data-c27755702509) — OCD-IDs designed to not change over time; cross-source matching standard
- Open States documentation: [Understanding the Data](https://docs.openstates.org/data/) — scraper-based; coverage varies by state; California requires MySQL dump processing
- Ballotpedia: [Open States Legislative Data Report Card](https://ballotpedia.org/Open_States%27_Legislative_Data_Report_Card) — historical quality grades per state; Massachusetts F grade due to missing vote data; criteria include completeness, timeliness, machine readability
- LegiScan API: [legiscan.com/legiscan](https://legiscan.com/legiscan) — 30,000 queries/month free tier; covers all 50 states + Congress; Indiana and California datasets available
- LegiScan API User Manual: [v1.91 PDF](https://api.legiscan.com/dl/LegiScan_API_User_Manual.pdf) — people_id as primary legislator identifier; bill, vote, and sponsor data structure
- Legistar Web API: [webapi.legistar.com](https://webapi.legistar.com/) — matters endpoint structure; OData v3 URL conventions; client-specific token requirements
- LA County Legistar: [lacounty.legistar.com](https://lacounty.legistar.com/MainBody.aspx) — Board of Supervisors data; separate from LA City Council
- Bloomington Common Council: [bloomington.in.gov/council](https://bloomington.in.gov/council) — OnBoard meeting minutes system; PDF minutes; Civic Webcast video archives; no structured vote API
- Bloomington Open Data: [data.bloomington.in.gov](https://data.bloomington.in.gov/) — city datasets portal; city council district boundaries available (used in v1.5); no legislative vote data

---

*Pitfalls research for: v2026.3 Legislative Profile Data — committees, votes, bills, leadership across federal/state/local*
*Researched: 2026-03-01*
