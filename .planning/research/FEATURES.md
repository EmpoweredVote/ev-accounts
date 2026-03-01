# Feature Landscape — Legislative Profile Data

**Domain:** Civic engagement — legislative activity enrichment for politician profiles
**Researched:** 2026-03-01
**Confidence:** HIGH for federal patterns (multiple authoritative sources); MEDIUM for state patterns (IGA API confirmed, Open States status changing); LOW for local patterns (city/county web scraping, no structured APIs)

---

## Scope Note

This file covers ONLY the new legislative profile features for milestone v2026.3. The existing infrastructure already built includes:

- Politician profiles with images, bio, education, experience, endorsements, stances, elections, contacts
- Federal/State/Local tier classification with PostGIS geofence matching
- BallotReady candidacy data (endorsements, stances, election history) already fetched
- **Not yet built:** committees, voting records, sponsored legislation, leadership positions

Focus is on what competitive civic platforms display, what users actually expect, and what is feasible across federal (Congress), state (Indiana + California), and local (Bloomington Common Council, LA County Board of Supervisors, LA City Council) levels.

---

## Platform Audit — What Competitors Display

### GovTrack (Federal Congress only)
Comprehensive profile sections: ideology score, leadership score, missed votes percentage, bills sponsored count, bills enacted count, cosponsor statistics, committee memberships with subcommittees, recent votes with positions (Yea/Nay/Not Voting), sponsored bills list with status, party-line voting percentage, bipartisan cosponsor rate. Also computes annual "report card" statistics. Source: [GovTrack.us](https://www.govtrack.us/start)

### VoteSmart (Federal + State)
Six profile domains: background information, issue positions (Political Courage Test), voting records, campaign finances, interest group ratings, speeches and public statements. Voting records are keyed votes on high-profile issues, not full roll-call dumps. Source: [VoteSmart](https://www.votesmart.org/)

### Ballotpedia (Federal + State + some Local)
Profile sections include: committee memberships, leadership positions in legislature, sponsored legislation (via BillTrack50), legislative scorecards from interest groups, campaign finance, key votes by session, election history. Coverage is manually curated — local officials rarely covered. Source: [Ballotpedia](https://ballotpedia.org/Main_Page)

### Open States / Plural Policy (State only)
Data model: legislator basic info, committee memberships, sponsored/cosponsored bills, roll-call vote positions. State data only — no federal, no local. Note: as of 2023 Open States transitioned to Plural/SAI360; primary UI largely disabled for general public, API still active. Source: [Open States](https://open.pluralpolicy.com/)

### LegiScan (Federal + All 50 States)
Rich bill data: full text, sponsors, co-sponsors, committees referred, amendment history, roll call records, bill status, vote positions per legislator. Coverage includes Congress and all 50 states. Free tier available (OneVote). Professional tier starts at $100/year for single state, $3,000/year national. Source: [LegiScan](https://legiscan.com/legiscan)

### ProPublica Congress API (Federal only)
Member endpoints return: committee memberships (full + subcommittee with role), recent votes with positions, bills sponsored, bills cosponsored, missed votes count/percentage, party-line vote percentage, bipartisan cosponsor rate. Bill data available from 1995 forward. Roll-call votes only (not voice votes). Free, requires API key. Source: [ProPublica Congress API](https://projects.propublica.org/api-docs/congress-api/)

### Congress.gov API (Federal only)
Official source: bills, amendments, summaries, members, committee reports, nominations, congressional record. Free with API key. Source: [Congress.gov API](https://www.loc.gov/apis/additional-apis/congress-dot-gov-api/)

---

## Table Stakes

Features that users expect on any politician profile that claims to cover legislative activity. Missing these makes the profile feel like a stub and undermines platform credibility.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Committee memberships list | Every major civic platform shows this; users ask "what does this politician actually work on?" | LOW-MEDIUM | Data: Congress.gov API + ProPublica (federal), IGA API (Indiana), Open States (California), scraping (local). Display: simple list with committee name and role (member/chair/vice-chair). Already in data model vision. |
| Leadership roles | Voters expect to know if someone is a committee chair or speaker; it signals influence | LOW | Often a field on the committee membership record (role = "chair"/"ranking member"/"member"). No separate fetch required if committees captured. |
| Sponsored legislation list | Core civic literacy — "what has this person tried to pass?" | MEDIUM | Show bill number, title, status, introduction date. Current session primary, recent session secondary. Federal: Congress.gov + ProPublica. State: IGA API (IN), Open States (CA). Local: scraping required. |
| Voting record (recent roll calls) | Most-requested feature in civic tech; fundamental accountability data | HIGH | Roll-call votes only (not voice votes). Federal: ProPublica API most convenient. State: LegiScan covers Indiana + California reliably. Local: no structured API — scraping meeting minutes or agendas required. |
| Vote position per vote | For each vote, user expects to see Yea/Nay/Abstain/Not Voting | LOW | Accompanies voting record. Federal data clean. State data varies by state system. Local often requires parsing HTML agendas. |
| Bill status / outcome | Users want to know if a sponsored bill passed, failed, died in committee | LOW | Status field on bill record. All APIs provide this. Display as: Enacted / Passed Chamber / In Committee / Failed / Vetoed. |

---

## Differentiators

Features that make Empowered Vote profiles richer than a bare legislative data dump. Not expected by default but highly valued when present.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Plain-language bill summaries | Raw bill titles are cryptic ("SB 423 relating to ad valorem taxation"). A one-sentence plain English summary dramatically increases usability. | MEDIUM-HIGH | Best approach: use Congress.gov's existing CRS summaries (free) for federal bills. LegiScan sometimes surfaces official summaries. For state/local: no reliable source — would require AI generation (out of scope for this milestone) or manual curation. Start with CRS summaries federal-only; show raw title for state/local. |
| Vote alignment score (party-line %) | "Votes with party X% of the time" is a GovTrack differentiator that users find highly engaging — tells a story without reading every vote | MEDIUM | Derivable from roll-call data if you have the member's party affiliation and the majority party vote position per roll call. Computable server-side. Federal: straightforward. State: possible if legislative party caucus data available. Local: party-line voting rare in nonpartisan bodies (Bloomington is nonpartisan). |
| Bipartisan cosponsor rate | Shows willingness to work across party lines — cited by The Lugar Center Bipartisan Index as meaningful civic signal | MEDIUM | Federal: ProPublica API returns this directly. State: compute from cosponsorship data. Local: not applicable (nonpartisan). |
| Committee chair / leadership badge | Visual indicator on profile distinguishing committee members from committee leaders — communicates influence at a glance | LOW | Purely UI layer once committee data with roles is captured. Badge: "Committee Chair", "Ranking Member", "Whip", etc. |
| Legislation topic tags | Group sponsored bills by policy area (Health, Environment, Criminal Justice) to let users see policy focus quickly | MEDIUM | Federal: Congress.gov provides bill subjects. State: varies — some states tag bills by subject, some do not. Local: no tagging; manual curation only. Start federal-only. |
| Cosponsored legislation | Shows who a politician supports beyond their own bills — reveals coalition behavior | LOW | Separate list from sponsored. Same data source (member's bills endpoint filtered to cosponsored). Display: bill + primary sponsor's name. |
| Session filter | Let users toggle between current session and previous session | LOW | Pure UI filter on already-fetched data. High value for returning visitors tracking incumbents. |
| Vote on notable bills | Curated list of the 5-10 most important votes in a session, with member's position highlighted — like VoteSmart's approach | HIGH | Requires editorial curation of "notable" bills. Not a data problem, a content editorial problem. Appropriate for a future milestone with a content pipeline. Anti-feature risk: curation introduces bias. |

---

## Anti-Features

Features that seem valuable but create more problems than they solve at this scale.

| Anti-Feature | Why Problematic | What to Do Instead |
|--------------|-----------------|-------------------|
| Real-time vote tracking (polling API on a schedule) | ProPublica updates votes every 30 minutes; Congress.gov has webhooks. Keeping DB in sync requires a background sync daemon with retry logic, error handling, and drift detection. This is significant ops complexity for a 2-3 person nonprofit team. | Batch import: fetch voting records once per week or on-demand when profile is viewed. Stale by a few days is acceptable for an accountability platform — users aren't day-trading on votes. |
| Displaying voice votes / division votes | Federal congressional data only tracks roll-call votes. Voice votes have no individual position data. Displaying "voted on this bill" without knowing their position creates a misleading record. | Only display roll-call votes where individual position (Yea/Nay/Not Voting) is available. Clearly label the limitation. |
| Full bill text display | Bills can be hundreds of pages. Hosting full text requires significant storage, search indexing, and rendering infrastructure. | Link out to Congress.gov / state legislature site for full text. Display title, number, summary, status only. |
| Automated interest group ratings scraping | VoteSmart's Political Courage Test ratings are valuable but Terms of Service restrict scraping. Ballotpedia ratings similarly restricted. | Show "see VoteSmart for ratings" as an outbound link. Do not attempt to replicate this data in-house. |
| Historical votes beyond 2 sessions | Complete voting history (10+ years) is rarely consulted by voters and creates DB bloat. Fetching and storing years of roll-call data for hundreds of politicians is expensive. | Scope to current session + previous session only. Most voters care about recent behavior. Provide "view full history" link to GovTrack/ProPublica for power users. |
| Local government vote tallies from all 89 LA County cities | Each city has its own meeting minutes format, agenda system, and HTML structure. Building 89 scrapers is unsustainable. | Scope local voting records to only the bodies where structured data exists: Bloomington Common Council (data.bloomington.in.gov open data portal) and LA County Board of Supervisors (Statement of Proceedings). Skip individual city council voting records — too much scraper maintenance for too little coverage. |
| Bill co-sponsorship network visualization | Showing which politicians co-sponsor each other's bills as a network graph is a GovTrack feature that requires specialized D3 rendering and significant data processing. | Text list of cosponsors per bill is sufficient. Network visualization is a future v2 feature if user demand emerges. |
| Ideology score computation | GovTrack's ideology score requires eigenvector decomposition of a co-sponsorship matrix across all legislators — statistically sophisticated and federally-scoped. Reproducing it for state/local is an original research project. | Link to GovTrack's ideology score for federal members (via bioguide_id, already captured). Do not attempt to compute it independently. |

---

## Feature Dependencies

```
Committee Assignments
    └──requires──> Legislative session data (jurisdictions, governing bodies, sessions)
    └──requires──> Committee table + membership join table in DB
    └──federal data──> Congress.gov API (committee endpoint) OR ProPublica members endpoint
    └──state data (IN)──> IGA Hypermedia API (docs.api.iga.in.gov)
    └──state data (CA)──> Open States / LegiScan CA session data
    └──local data──> Scraping or manual import (Bloomington, LA County BOS)
    └──renders in──> Profile page new "Committees" section

Leadership Roles
    └──derived from──> Committee membership role field (chair/member/ranking)
    └──also requires──> Body-level leadership (speaker, majority leader, whip) — separate lookup
    └──independent fetch──> congressional-legislators YAML (already has leadership fields)
    └──feeds──> Leadership badge UI on profile

Sponsored Legislation
    └──requires──> Bill table (number, title, status, intro date, session)
    └──requires──> Politician → bill sponsorship join table
    └──federal data──> Congress.gov API bills-by-member endpoint
    └──state data──> LegiScan (sponsors field on bill) OR IGA API (IN)
    └──local data──> Bloomington city clerk searchable database; LA County BOS agendas
    └──depends on──> Committee Assignments (session context needed for scoping)

Voting Records
    └──requires──> Vote event table (bill/motion, date, session, description)
    └──requires──> Vote position table (politician → vote event → position)
    └──federal data──> ProPublica votes endpoint (most convenient; 30min freshness)
    └──state data (IN)──> IGA API has roll call data
    └──state data (CA)──> LegiScan CA has roll call data
    └──local data──> Bloomington: data.bloomington.in.gov searchable DB (1945-present); LA County BOS: Statement of Proceedings (HTML scraping)
    └──depends on──> Sponsored Legislation (shared session/bill model)

Party-Line Vote Score
    └──derived from──> Voting Records (positions per roll call)
    └──requires──> Party affiliation per politician (already in DB)
    └──requires──> Majority party position per roll call (aggregate computation)
    └──federal only initially──> ProPublica returns this directly as a field
    └──state: compute──> Requires roll-call data + party caucus position

Plain-Language Bill Summary
    └──federal only──> Congress.gov CRS summaries (official, free)
    └──state/local──> No reliable source; AI generation out of scope for this milestone
    └──display──> Summary if available; raw title if not (graceful degradation)
    └──does not block──> Any other feature; enhancement layer only

Bill Topic Tags
    └──federal only initially──> Congress.gov bill subjects endpoint
    └──state──> Varies by state API; IGA has subject codes for IN
    └──local──> No tags; not applicable
```

---

## Government Level Coverage Matrix

The data availability differs dramatically by level. This matrix is critical for phase planning.

| Feature | Federal (Congress) | State (Indiana IGA) | State (California) | Local (Bloomington) | Local (LA County BOS) | Local (LA City Council) |
|---------|-------------------|--------------------|--------------------|---------------------|----------------------|------------------------|
| Committee memberships | HIGH — Congress.gov + ProPublica | HIGH — IGA API documented | MEDIUM — Open States or LegiScan | MEDIUM — manual import; council assigns committees | MEDIUM — BOS committee structure simple (5 members) | MEDIUM — council committee list public but no API |
| Leadership roles | HIGH — congress-legislators YAML | MEDIUM — IGA API includes leadership | MEDIUM — Open States | LOW — scraping city website | LOW — BOS chair is rotational per year | LOW — council president elected annually |
| Sponsored bills | HIGH — Congress.gov member bills endpoint | HIGH — IGA API bills-by-legislator | HIGH — LegiScan CA | MEDIUM — city clerk DB (1945-present) accessible | LOW — BOS motions not structured as "bills" | LOW — LA City Council ordinances require scraping |
| Voting record (roll calls) | HIGH — ProPublica (30min fresh) | HIGH — IGA API roll calls | HIGH — LegiScan CA | MEDIUM — city clerk DB has vote records | MEDIUM — Statement of Proceedings HTML | LOW — no structured API; minutes scraping only |
| Bill status | HIGH | HIGH | HIGH | MEDIUM | LOW | LOW |
| Bill summaries | HIGH — CRS summaries | LOW — no official summary API | LOW — no official summary API | NONE | NONE | NONE |
| Topic tags | HIGH — Congress.gov subjects | MEDIUM — IGA has subject codes | MEDIUM — varies | NONE | NONE | NONE |

**Implication for phasing:** Federal data is the strongest implementation target. State data is viable via IGA (Indiana) and LegiScan (California). Local data requires scraping with lower reliability. Phase around confidence, not political level.

---

## MVP Recommendation for This Milestone

### Must Have (Milestone Definition of Done)

These are what PROJECT.md lists as the target features. All must ship.

1. **Data model foundation** — jurisdictions, governing_bodies, legislative_sessions, committees, committee_memberships, legislation, votes, vote_positions tables in PostgreSQL. This is the prerequisite for all other features. Define schema first, migrate, then build data fetchers.

2. **Committee assignments with roles** — Display on politician profile for federal members (Congress.gov), Indiana state legislators (IGA API), California state legislators (LegiScan), and locally for Bloomington Common Council and LA County BOS (manual import acceptable for first milestone). Show: committee name, role (member/chair/vice-chair), body name.

3. **Leadership positions** — Chamber leadership (speaker, majority leader, whip) and committee chairships. Federal: congress-legislators YAML. State: IGA API + Open States. Local: manual import.

4. **Voting records (current + previous session)** — Roll-call votes only. Federal: ProPublica API. Indiana state: IGA API. California state: LegiScan. Local Bloomington: city clerk searchable DB. LA County BOS: Statement of Proceedings. Scope: last 2 legislative sessions per jurisdiction. Display: vote title/bill, date, member's position, overall outcome.

5. **Sponsored legislation** — Bills where politician is primary sponsor or cosponsor. Federal: Congress.gov member bills endpoint. State: IGA (IN) + LegiScan (CA). Local: city clerk database (Bloomington). Display: bill number, short title, status, intro date. Current + previous session.

6. **Frontend profile sections** — New collapsible sections on politician profile page in essentials app: "Committees & Leadership", "Sponsored Legislation", "Voting Record". Each section gracefully empty-states when data is unavailable for a given government level.

### Defer to Later Milestone

- Plain-language bill summaries for state/local (no reliable data source; AI generation is a separate project)
- Vote alignment / party-line percentage computation (depends on having full roll-call data first; compute after data is stable)
- Bill topic tags for state/local (federal implementation first; validate that users engage with it before expanding)
- Notable votes / curated key votes (requires editorial workflow; high content labor)
- Historical voting records beyond 2 sessions (DB size concern; start narrow and expand based on demand)
- All LA City Council voting records (no structured API; scraper maintenance burden too high for v1)
- Local government body voting for 87 non-Bloomington Monroe County jurisdictions (out of scope per PROJECT.md)

---

## Feature Prioritization Matrix

| Feature | User Value | Data Availability | Implementation Cost | Priority |
|---------|------------|-------------------|---------------------|----------|
| Data model foundation | CRITICAL — blocks everything else | N/A | MEDIUM | P0 |
| Committee assignments (federal) | HIGH — expected by anyone who knows civics | HIGH | LOW | P1 |
| Committee assignments (state IN + CA) | HIGH | HIGH | LOW-MEDIUM | P1 |
| Leadership roles (federal) | HIGH — signals influence | HIGH | LOW | P1 |
| Sponsored bills (federal) | HIGH — core accountability | HIGH | MEDIUM | P1 |
| Voting record (federal) | HIGH — most requested civic data | HIGH | MEDIUM | P1 |
| Committee assignments (local — manual import) | MEDIUM — limited data | MEDIUM | LOW | P2 |
| Leadership roles (state) | MEDIUM | MEDIUM | MEDIUM | P2 |
| Sponsored bills (state IN + CA) | HIGH | HIGH | MEDIUM | P2 |
| Voting record (state IN — IGA API) | HIGH | HIGH | MEDIUM | P2 |
| Voting record (state CA — LegiScan) | HIGH | MEDIUM-HIGH | MEDIUM | P2 |
| Frontend profile sections (federal) | HIGH — required to be user-visible | N/A | MEDIUM | P1 |
| Frontend profile sections (state + local) | HIGH | N/A | LOW (extends federal pattern) | P2 |
| Voting record (local Bloomington) | MEDIUM | MEDIUM | MEDIUM-HIGH (scraping) | P3 |
| Voting record (LA County BOS) | MEDIUM | MEDIUM | HIGH (HTML scraping) | P3 |
| Plain-language bill summaries (federal CRS) | HIGH — usability win | HIGH | LOW (CRS summaries free) | P2 |
| Vote alignment / party-line % (federal) | MEDIUM-HIGH — engaging metric | HIGH (derivable from ProPublica) | MEDIUM | P3 |
| Bill topic tags (federal) | MEDIUM | HIGH | LOW | P3 |

**Priority key:**
- P0: Prerequisite, no other feature ships without it
- P1: Core milestone deliverable for federal data tier
- P2: Core milestone deliverable for state data tier
- P3: Nice-to-have; ship if P1+P2 complete ahead of schedule

---

## Data Freshness Strategy

| Data Type | Proposed Refresh Cadence | Rationale |
|-----------|--------------------------|-----------|
| Committee memberships | Per-session import (2-year cycle federal; 1-2 year state) | Committees are stable within a session; batch import acceptable |
| Leadership roles | Per-session import | Leadership elected at start of each session |
| Sponsored bills | Weekly batch import | Bills introduced frequently during active sessions; real-time not needed |
| Voting records | Weekly batch import OR lazy-fetch on profile view | Profile view trigger matches existing lazy-fetch pattern (already used for candidacy data). Weekly batch is simpler for large bodies. |
| Bill summaries (CRS) | Per-bill import (fetch when bill record created) | CRS summaries published after bill introduction; one-time fetch sufficient |

**Rationale for batch over real-time:** PROJECT.md already uses a lazy-fetch pattern for candidacy data (fetch on first profile view, background goroutine). Extend same pattern for voting records — fetch for a politician when their profile is first viewed, cache in DB. Weekly scheduled re-sync for frequently updated bodies (Congress, active state sessions). Avoids sync daemon complexity.

---

## Sources

- [GovTrack.us](https://www.govtrack.us/start) — Profile features, scoring methodology
- [GovTrack Wikipedia](https://en.wikipedia.org/wiki/GovTrack) — History, data lineage
- [VoteSmart](https://www.votesmart.org/) — Six-domain profile structure
- [Ballotpedia](https://ballotpedia.org/Main_Page) — Committee, leadership, scorecard display patterns
- [Open States / Plural Policy](https://open.pluralpolicy.com/) — State legislative data model
- [LegiScan API](https://legiscan.com/legiscan) — State + federal bill/vote data; pricing tiers
- [ProPublica Congress API](https://projects.propublica.org/api-docs/congress-api/) — Federal member committees, votes, bills, party-line metrics
- [Congress.gov API](https://www.loc.gov/apis/additional-apis/congress-dot-gov-api/) — Official federal legislative data
- [Indiana General Assembly MyIGA API](http://docs.api.iga.in.gov/detail/bills.html) — IN-specific bill and roll-call data
- [City of Bloomington Open Data](https://data.bloomington.in.gov/) — Local council meeting/vote records
- [Bloomington City Clerk](https://bloomington.in.gov/departments/clerk) — Searchable legislation DB (1945-present)
- [LA County BOS Records](https://bos.lacounty.gov/services/records-of-the-board/) — Statement of Proceedings (1985-present)
- [The Lugar Center Bipartisan Index](https://www.thelugarcenter.org/ourwork-Bipartisan-Index.html) — Bipartisan co-sponsorship scoring methodology

---

*Feature research for: v2026.3 Legislative Profile Data milestone*
*Researched: 2026-03-01*
