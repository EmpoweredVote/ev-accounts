# Feature Research

**Domain:** Civic tech — Election Central page + elected/appointed filter for Essentials app
**Researched:** 2026-03-29
**Confidence:** MEDIUM (domain patterns well-understood from competitor analysis; some UX guidance indirect)

---

## Context: What Already Exists

This is a subsequent milestone on the existing Essentials app. The following are already shipped and NOT in scope:

- Address search via Google Maps Places + PostGIS geofence matching
- Politicians grouped Federal/State/Local with government_body names and official website links
- Full profile pages with legislative data, compass comparison cards, Read & Rank verdict badges
- `essentials.politicians` schema with `is_incumbent`, `is_appointed`, `is_candidate` booleans
- `essentials.offices` with `is_appointed_position`, `is_vacant`, `is_elected` (derived as NOT is_appointed_position)
- Government body names, district types including JUDICIAL, and official URLs
- Initials avatar fallback for missing photos
- Candidate toggle (show/hide challengers) already exists on the representatives page

The **new features** for v2026.3.8 are:
1. Election Central page — upcoming races grouped by org/position, with election dates and candidate cards
2. Elected/Appointed filter toggle on the main Essentials representatives page
3. Retention judges appearing under both Elected and Appointed filters

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist on any election-oriented civic page. Missing these = product feels incomplete or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Races grouped by government body then position | Ballot-style organization is universal. Voters recognize this hierarchy from official voter guides (VOTE411, Ballotpedia, lavote.gov, sample ballots). Flat lists feel overwhelming. | MEDIUM | Group by organization first (e.g. "Monroe County"), then by specific seat (e.g. "County Clerk"). Mirrors official sample ballot layout and matches how Essentials already organizes the representatives page. |
| Incumbent badge on candidate cards | Users need to identify who currently holds the seat. Universal convention — every voter guide from VOTE411 to Ballotpedia marks incumbents. | LOW | `is_incumbent` column already exists. Add a small badge/pill. Per Center for Civic Design guidance, candidate names should be visually equal — the badge should be informational, not an endorsement. |
| Election date displayed per race | Users arrive asking "when is this?" before "who is running?" | LOW | Show the date alongside the race header. For jurisdictions with primary and general (Monroe County 2026: May primary; LA County 2026: June primary + November general), show the next upcoming date and label it "Primary" or "General." |
| Candidate name, photo, and position sought | Minimum viable candidate card. Photo adds trust. | LOW | Position title must appear on the card. Use initials avatar fallback (already in ev-ui) when photo is unavailable — common for challengers. |
| Incumbent vs. challenger differentiation within a race | Users need to see the full field for each seat. If only one name shows and it's unlabeled, users don't know if a race is contested. | MEDIUM | Show all candidates under their shared position/seat heading. Incumbent labeled. Challengers unlabeled or labeled "Challenger." Vacant seats get explicit "Open Seat" race header. |
| Elected vs. appointed filter on representatives page | Users trust and relate to elected officials differently from appointed ones. This is an expected distinction in civic directories. | LOW | Toggle or segmented control. `is_appointed_position` already in schema derived as `is_elected`. Default to showing all (current behavior), add "Elected" / "Appointed" / "All" options. |
| "No upcoming races found" empty state | If no election data exists for an address, the page must say so clearly. Empty content with no explanation destroys trust. | LOW | Clear message: "No upcoming races found for this address." Add a note about data coverage limitations (Bloomington/Monroe County IN and LA County CA only). |

### Differentiators (Competitive Advantage)

Features that set Empowered Vote's election page apart from generic voter guide lookups.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Candidates link to full Essentials-style profile pages | VOTE411 and Ballotpedia only show basic bio + Q&A responses. EV shows legislative record, compass comparison card, Read & Rank verdict badges. Gives voters real depth on candidates. | MEDIUM | Reuses existing PoliticianProfile component entirely. Requires candidates to exist as `essentials.politicians` records with `is_candidate = true`. The effort is data population, not new frontend code. |
| Compass comparison card on candidate profiles | No civic voter guide offers interactive policy alignment visualization for candidates. Users can see how challengers align with their own positions. | LOW | Already built — just needs candidates in the politicians table with compass stances imported. |
| Read & Rank verdict badges on candidate profiles | No civic voter guide offers per-quote evaluation with user verdicts. Shows candidates' actual words, not just stated positions. | LOW | Already built in StanceAccordion — needs quotes imported for candidates via existing import pipeline. |
| Retention judges appear under both Elected and Appointed filters | Retention elections are hybrid: judge was initially appointed, now faces a public yes/no vote. Most civic apps categorize incorrectly. Getting this right builds trust with informed users. | MEDIUM | District type `JUDICIAL` with `is_appointed_position = true` but also `is_candidate = true` (retention race upcoming). Filter logic: show in both Elected and Appointed tabs. Add "Retention Election" label on the race card to explain the hybrid nature to voters unfamiliar with the system. |
| Primary vs. general election distinction per race | Monroe County 2026 has May primary AND November general. LA County 2026 has June primary + November runoff option. Users need to know which stage they are seeing. | LOW | Store `election_type` (primary/general/retention/runoff) alongside `election_date` in the races/elections data. Display as a pill or subtitle label. |
| Days-until countdown near election date | Adds appropriate urgency and helps users plan. Simple but effective engagement driver for civic participation. | LOW | Calculate from `election_date`. Show "X days away" when under 60 days. Show full date when farther out. Plain text — not an animated timer (would feel gimmicky and undermine trust). |

### Anti-Features (Commonly Requested, Often Problematic)

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Party affiliation display | Users expect to know which party a candidate belongs to on most voter guides | Violates the antipartisan mission documented in project memory. Partisan labels push voters toward confirmation bias rather than policy evaluation — the opposite of EV's purpose. | Show policy positions via compass comparison, legislative votes, and Read & Rank quotes. Let voters derive alignment from evidence. |
| Polling place / "how to vote" logistics | Users naturally want this on any election page | Requires real-time county-level data integration; operational scope is voter research, not logistics. Creates maintenance burden for data EV doesn't own. | Add a prominent external link to the county registrar: "Find your polling place" pointing to lavote.gov or co.monroe.in.us. |
| Real-time election results | Users ask about results night-of | Requires live data feeds, significant operational complexity, and the data is freely and authoritatively available from official county sources. Not core mission. | Link to county election board results page. A static link is sufficient. |
| Endorsement lists | Candidates highlight endorsements; users are familiar with the pattern | Endorsements from advocacy groups, unions, and political figures are partisan signals by nature. Creates a maintenance burden and conflicts with the antipartisan mission. | Show factual legislative record (votes, activity) and sourced quotes instead. |
| Animated countdown timer (seconds/milliseconds) | Visually engaging; some civic sites use it | Creates a "spectacle" feel that undermines the serious, trustworthy tone. Adds visual noise without information value. | Show "X days until [election date]" in plain text near the race header. |
| Candidate self-submitted Q&A responses | VOTE411-style questionnaire where candidates fill in issue answers | High coordination overhead for a small nonprofit with no current candidate relationship infrastructure. Responses are often boilerplate and not factually verifiable. Risk of candidates gaming responses. | Use sourced verbatim quotes (already in Read & Rank pipeline) with verified attribution and source links. |
| Ballot measures / referendums | Part of the ballot; users expect to see them | Different data model, different UX pattern, no existing infrastructure. Referendums are measures, not candidates — require entirely separate sourcing and display approach. | Acknowledge as out of scope. Add a note on Election Central linking to the official county registrar ballot for measures. |

---

## Feature Dependencies

```
Election Central Page
    └──requires──> Election/race data source decision (races, candidates, dates per address)
                       └──requires──> Candidate records in essentials.politicians (is_candidate = true)
                                          └──requires──> Geofence-to-race mapping (which races apply to this address)
                                          └──requires──> essentials.races or similar table with election_date, election_type, office_id

Candidate Profile Pages (full depth)
    └──requires──> Candidate in essentials.politicians (is_candidate = true)
    └──reuses──> Existing PoliticianProfile component — no new frontend code
    └──enhances──> Compass stances (requires candidate answers in compass tables)
    └──enhances──> Read & Rank quotes (requires quotes imported for this candidate)

Elected/Appointed Filter Toggle
    └──requires──> is_appointed_position on essentials.offices (ALREADY EXISTS)
    └──requires──> Frontend toggle UI on Essentials representatives page
    └──edge-case──> Retention judges: is_appointed_position=true AND is_candidate=true → show in BOTH tabs

Incumbent Badge on Candidate Card
    └──requires──> is_incumbent on essentials.politicians (ALREADY EXISTS)

Race grouping by org then position
    └──requires──> government_bodies table with correct org names (ALREADY EXISTS from v2026.3.3)
    └──requires──> races or elections table linking positions to election_date and election_type

Primary vs. General label
    └──requires──> election_type field stored per race (NEW — not in current schema)

Days-until countdown
    └──requires──> election_date stored per race (NEW — not in current schema)
```

### Dependency Notes

- **Election data source is the highest-risk dependency for the entire milestone.** BallotReady/CivicEngine API is the most complete national source (races, candidates, dates at all levels) but requires a paid contract with no confirmed free nonprofit tier. Google Civic Information API is free but has known gaps in local race coverage. Manual data entry via the existing staging tool is the lowest-risk approach for the two target jurisdictions (Monroe County IN has ~25 races in 2026; LA County has ~40 county-level races) — small enough to manage manually. Source decision should be made in Phase 1 before any schema work.
- **Candidate profiles reuse all existing infrastructure.** Once a candidate exists in `essentials.politicians` with `is_candidate = true`, the entire profile pipeline (photos, contacts, legislative data, compass card, Read & Rank) works without modification. The cost is data population, not new code.
- **Retention judges are the only "both-filters" edge case.** All other `is_appointed_position = true` officials (cabinet secretaries, agency heads, appointed commissioners) are purely appointed. Only JUDICIAL district types with an upcoming retention race need dual-filter treatment. Indiana uses merit selection (retention elections) for Court of Appeals and Supreme Court. California uses the same for Supreme Court and Courts of Appeal. Monroe County 2026 Circuit Court judges run in contested elections — those are `is_appointed_position = false` and "Elected" filter only.

---

## MVP Definition

### Launch With (v1 — this milestone)

- [ ] Elected/Appointed filter toggle on main Essentials representatives page — schema already supports it; low frontend effort; high user value
- [ ] Election Central page accessible from Essentials navigation with the same address input
- [ ] Races grouped by government body (org) then by specific position within that body
- [ ] Incumbent designation badge on candidate cards
- [ ] Election date displayed per race with primary/general label
- [ ] Open seat / vacancy label when no incumbent exists for the seat
- [ ] Candidates link to full profile pages using existing PoliticianProfile component
- [ ] Retention judges appear under both Elected and Appointed filter tabs with "Retention Election" label
- [ ] "No upcoming races found for this address" empty state with coverage note
- [ ] Coverage scoped to Monroe County IN and LA County CA only

### Add After Validation (v1.x)

- [ ] Days-until countdown near election date — add once election dates are verified accurate and the page is live; low effort
- [ ] Read & Rank quotes for candidates — StanceAccordion already supports it; add as quote data is researched and imported via existing pipeline
- [ ] Compass stances for candidates — add when candidate stance data is researched; requires admin data entry

### Future Consideration (v2+)

- [ ] Ballot measures / referendums — requires separate data model and UX; different scope from candidate races
- [ ] Multi-jurisdiction election calendar (beyond two supported jurisdictions) — requires scalable data sourcing
- [ ] "Remind me before the election" feature — requires email/SMS infrastructure not currently in place
- [ ] External link to county registrar polling place lookup — low effort, can add when copy and links are ready

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Elected/Appointed filter toggle | HIGH | LOW (schema exists) | P1 |
| Races grouped by org then position | HIGH | MEDIUM | P1 |
| Incumbent badge on candidate card | HIGH | LOW (flag exists) | P1 |
| Election date + primary/general label | HIGH | LOW | P1 |
| Candidate cards linking to profile pages | HIGH | LOW (reuse existing) | P1 |
| Election data source + schema | HIGH | HIGH (data sourcing is the blocker) | P1 — must resolve first |
| Retention judges in both filter tabs | MEDIUM | MEDIUM (logic + label) | P1 — correctness requirement |
| Open seat / vacancy label | MEDIUM | LOW | P1 |
| "No upcoming races" empty state | MEDIUM | LOW | P1 |
| Days-until countdown | LOW-MEDIUM | LOW | P2 |
| Read & Rank quotes for candidates | HIGH | MEDIUM (data entry) | P2 |
| Compass stances for candidates | HIGH | HIGH (research + import) | P2 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | VOTE411 (League of Women Voters) | Ballotpedia | Our Approach |
|---------|----------------------------------|-------------|--------------|
| Race grouping | By ballot section (federal/state/local/judicial), address-filtered | By election date then race type, state-organized | By government body (org) then position — matches Essentials' existing representatives hierarchy for cognitive consistency |
| Incumbent display | "(Incumbent)" inline with candidate name | Incumbent labeled in race entry | "Incumbent" badge/pill on politician card, visually equal to other candidates |
| Candidate depth | Candidate Q&A responses from questionnaire, website link | Bio, campaign website, news links, endorsements | Full profile with legislative record, compass comparison card, Read & Rank verdicts — uniquely deeper |
| Elected vs. appointed filter | Not offered | Not offered (separate encyclopedia pages) | Toggle on main representatives page — differentiating |
| Retention judges | Shown in judicial section, labeled "Retention" | Shown in judicial elections section | Appear in BOTH Elected and Appointed filter tabs with "Retention Election" label — more accurate than single-category |
| Party display | Yes — required for ballot | Yes | No — antipartisan mission; policy evidence instead |
| Election date | Shown per race | Shown per race | Shown per race; primary vs. general explicitly labeled; days-until added when election is approaching |
| Polling place / voting logistics | Yes — full voter services | External link | External link to county registrar only — out of scope for this milestone |
| Ballot measures | Yes | Yes | Out of scope for v1 — link to official ballot |

---

## Key Research Findings by Question

### 1. Race grouping conventions in civic tech

Standard pattern across all major civic voter guides (confirmed via Ballotpedia, lavote.gov, Monroe County 2026, LA County 2026, VOTE411): races are organized by **government type** (county, city, school board, judicial), then by **specific office within that body**. Within a body, ordering follows institutional importance (executive/chair roles before member seats; county-wide before district-specific). Voters recognize this hierarchy because it mirrors the physical sample ballot layout.

For Essentials specifically: since the existing representatives page already uses "government body" as the organizing unit (e.g., "Monroe County Council," "Bloomington City Council"), Election Central should mirror that exact structure. This creates cognitive consistency for users switching between the two pages — the same organizations they see in Representatives also appear in Election Central, just filtered to contested seats.

LA County 2026 example grouping (from Ballotpedia): County elections (Sheriff, Assessor, Board of Supervisors) → City elections by city → School board elections → Judicial elections.
Monroe County 2026 example grouping (from Ballotpedia): County elections (Assessor, Clerk, Commissioner, Sheriff, Council) → Township elections → Judicial elections.

### 2. Incumbent designation conventions

"Incumbent" is the universal label used across every civic voter guide examined. Implementation note from Center for Civic Design field guide: candidate names should be presented with equal visual weight — the incumbent indicator should be a small secondary badge, not larger text or a prominent header treatment that could imply endorsement. When a seat is vacant (`is_vacant = true`), display "Open Seat" on the race header instead of showing an empty incumbent slot.

### 3. Elected vs. appointed filter and the retention judge edge case

The elected/appointed distinction is straightforward for most officials: `is_appointed_position` on `essentials.offices` already correctly captures this.

The genuine edge case is retention judges. Indiana uses merit selection (Missouri Plan) for appellate and supreme court judges: governor appoints initially, then voters face a yes/no retention vote after the initial term. California uses the same system for Supreme Court and Courts of Appeal. At the trial court level (Monroe County Circuit Court judgeships), judges run in contested elections — those are "Elected," not appointed.

Implementation rule for the filter:
- `district_type = 'JUDICIAL'` AND `is_appointed_position = false` → Elected (contested election) → "Elected" tab only
- `district_type = 'JUDICIAL'` AND `is_appointed_position = true` AND `is_candidate = true` → Retention election → BOTH "Elected" and "Appointed" tabs, with "Retention Election" label
- `district_type = 'JUDICIAL'` AND `is_appointed_position = true` AND `is_candidate = false` → Appointed (no current election) → "Appointed" tab only

All non-judicial appointed officials (cabinet secretaries, agency heads, appointed commissioners) stay in "Appointed" only — no dual-filter needed.

### 4. Election date display

Users want a single clear answer to "when do I vote?" Show the **next upcoming** date prominently near the page header or race group header. For jurisdictions with a primary followed by a general, show the primary date first (it is sooner) and label it "Primary Election." After the primary passes, the display automatically shifts to the general date. A days-until countdown adds urgency when the election is close (under 30-60 days); for distant elections the full date is sufficient.

Monroe County 2026 dates: May 5, 2026 Primary. November general date TBD for those races advancing.
LA County 2026 dates: June 2, 2026 Primary. November 3, 2026 General.

### 5. User expectations from election information pages

Based on patterns from Center for Civic Design (2025), VOTE411, Ballotpedia, and Wisconsin's MyVote platform:

- Users scan rather than read — race names and candidate names must be large, clear, and scannable; do not bury important information in dense paragraphs
- Users want their specific ballot, not every race in the county — address-based filtering to relevant races is table stakes (EV's existing model already does this correctly)
- Users trust the platform when it shows the official election date and links to the registrar for logistics (polling places, registration deadlines)
- Empty states must explain themselves — blank sections without context destroy trust faster than missing data does; "no races found" with a reason is better than silence
- Party identification is expected by most voters on partisan sites, but EV's antipartisan stance is a deliberate differentiator — policy alignment tools (compass, Read & Rank) substitute for party labels

---

## Sources

- [Ballotpedia: Monroe County, Indiana, elections, 2026](https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026) — Race grouping patterns, confirmed judicial election types (HIGH confidence)
- [Ballotpedia: Los Angeles County, California, elections, 2026](https://ballotpedia.org/Los_Angeles_County,_California,_elections,_2026) — LA race structure, Board of Supervisors + Sheriff + judicial (HIGH confidence)
- [Ballotpedia: Judicial selection in the states](https://ballotpedia.org/Judicial_selection_in_the_states) — Retention election systems by state; Indiana and California both use merit selection for appellate courts (HIGH confidence)
- [VOTE411 Voter Guide](https://www.vote411.org) — Grouping and display conventions observed; address-filtering confirmed (MEDIUM confidence — interface observed, no direct design doc available)
- [Center for Civic Design: Designing Election Websites (2025)](https://civicdesign.org/wp-content/uploads/2025/03/Designing-Election-Websites-2.pdf) — User scanning behavior, plain language, avoiding visual decoration (MEDIUM confidence — referenced via search result, PDF binary)
- [CivicEngine / BallotReady developer docs](https://developers.civicengine.com/) — Data source option; coverage confirmed as comprehensive; pricing requires direct contact, no confirmed free nonprofit tier (MEDIUM confidence)
- [LA County Registrar: Upcoming Elections](https://www.lavote.gov/home/voting-elections/current-elections/upcoming-elections) — Official election dates confirmed (HIGH confidence)
- [2026 Greater Bloomington Chamber: Election candidates](https://www.chamberbloomington.org/2026-election-candidates.html) — Monroe County races confirmed for 2026 (HIGH confidence)
- [Uchicago Center for Effective Government: Elected vs. Appointed Judges](https://effectivegov.uchicago.edu/primers/elected-vs-appointed-judges) — Retention election mechanics and hybrid nature confirmed (HIGH confidence)
- Codebase: `ev-accounts/backend/src/lib/essentialsService.ts` — Confirmed existing schema flags (`is_appointed_position`, `is_incumbent`, `is_candidate`, `is_elected` derived field, `district_type`) (HIGH confidence)
- Codebase: `ev-accounts/backend/migrations/033_politician_schema.sql` — Column availability confirmed (HIGH confidence)

---

*Feature research for: v2026.3.8 Essentials Election Central + elected/appointed filter*
*Researched: 2026-03-29*
