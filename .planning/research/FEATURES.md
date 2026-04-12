# Feature Landscape

**Domain:** Civic tech — Voter guide, election readiness, Indiana primary 2026
**Researched:** 2026-04-11
**Confidence:** MEDIUM-HIGH (competitor sites verified via search; Monroe County race list verified via multiple local news/official sources; data gaps noted where information was unavailable)

---

## Context: Milestone v2026.4.3

This is a **competitive benchmarking and election readiness audit** milestone, not a feature-build milestone. The output of this research is a tiered gap list: what Empowered Vote is missing compared to competitor voter guide sites, and what a Monroe County IN voter would need to see for the May 5, 2026 primary.

### What Already Exists (not in scope)

- Election Central page — tier-grouped races, candidate cards, primary ballot labels, countdown
- Candidate profile pages — incumbent/challenger branching, CompassCard wiring
- Election data schema — elections, races, race_candidates, antipartisan enforcement
- Indiana + LA County data imported (2 elections, 12 races, 18 candidates as of v2026.3.8)
- Politician profiles — bio, education, experience, legislative activity, stances, quotes
- Compass / Read & Rank — issue positions, quote evaluation, head-to-head matchups
- Address-based lookup — PostGIS geofence matching, federal/state/local tier hierarchy

---

## Competitor Analysis: What Each Site Offers

### BallotReady

**Coverage model:** All 50 states, tiered research depth. Monroe County IN falls in Tier 3-4 (county population ~150K, above the 50K threshold for school board and township coverage). Research team makes phone calls, files FOIA requests, sends faxes to confirm data.

**Per-race data:** Office name, description of what the office does, filing deadline, election date, seat count. Links to official government body. Ballot measure full text where applicable.

**Per-candidate data:**
- Biography: education (high school and above, institution + degree), work/elected/military experience
- Issue stances: candidate's own words from campaign website, displayed in quotation marks, must be specific actionable statements (not "I support veterans")
- Endorsements: issue advocacy groups, business/labor groups, political organizations, newspaper editorial boards (NOT private citizens; tied to candidacy not person)
- Party affiliation (displayed)
- Campaign website link

**UX:** Address entry → personalized ballot → left-side race menu, right-side candidate list → click candidate → profile → "Add to My Ballot" → save choices, print/email ballot

**Strengths:** Most comprehensive local coverage of the three paid-for sites; data quality enforced via strict criteria; saves ballot to print/take to polls.

**Weaknesses:** Information asymmetry — top candidates get more data than lesser-known ones; party affiliation shown (conflicts with EV antipartisan mission if mirrored directly).

**Confidence:** MEDIUM (sourced from BallotReady support docs and organization site, not a live Monroe County spot-check)

---

### VOTE411 (League of Women Voters)

**Coverage model:** Address-based, shows only races on your specific ballot. Local LWV chapters conduct candidate outreach; candidates answer structured Q&A questions in their own words. Covers contested races in cities/counties of 1,000+ people.

**Per-race data:** Office name, description of the office and its responsibilities, election date. LWV-provided questions tailored to the race (local chapter writes questions for local races; national questions updated each federal cycle via polling).

**Per-candidate data:**
- Candidate answers to LWV questions — unedited, in candidate's own words, displayed side-by-side with opponent
- Available in English and Spanish (where provided)
- No editorial framing on answers

**UX:** Address entry → personalized ballot → race-by-race candidate Q&A comparison → printable voter guide PDF ("Keys to the Candidates" — LWV Bloomington-Monroe County produces this locally)

**Strengths:** Side-by-side candidate comparison on issues is uniquely powerful for local races; candidate Q&A is authoritative (candidate submitted); LWV local chapter actively produces a printed guide for Monroe County distributed to senior centers and the public library.

**Weaknesses:** Depends entirely on candidate participation — if candidate doesn't respond, profile is empty. Coverage limited to contested races in populated areas; township-level races often excluded.

**Confidence:** MEDIUM-HIGH (sourced from LWV national site and LWV Bloomington-Monroe County local chapter page)

---

### Ballotpedia

**Coverage model:** Wikipedia-style encyclopedic entries for every race and candidate at federal, state, and major local levels. Does NOT comprehensively cover Monroe County city council, school board, or township races (coverage limited to top 100 US cities by population; Bloomington is not in top 100).

**Per-race data:** Race history, previous election results, office description, district map, links to official sources.

**Per-candidate data:**
- Biography (Wikipedia-quality depth for known candidates)
- Past election results with vote percentages
- Campaign themes (from Candidate Connection survey responses)
- Endorsements (searchable endorsement portal, tracked from public record)
- Party affiliation
- Key policy positions (where researched)
- Campaign finance (links to FEC/state data)

**UX:** Sample ballot lookup by address → race list → click race → encyclopedic article → click candidate → encyclopedic article. Very research-heavy; not optimized for quick ballot decisions.

**Strengths:** Deepest content per candidate for races they cover; historical election data is unmatched; ballot measure analysis.

**Weaknesses:** Monroe County local races (commissioner, council, township, school board) largely NOT covered. Best for federal/state races. Not designed for "take to the polls" use case.

**Confidence:** MEDIUM (sourced from Ballotpedia's own coverage scope documentation and sample ballot FAQ)

---

### VoteSmart (JustFacts.votesmart.org)

**Coverage model:** Federal, state, and gubernatorial candidates primarily. Local races minimally covered. Emphasizes Political Courage Test — structured issue questionnaire answered by candidates.

**Per-candidate data:**
- Background / biography
- Issue positions (Political Courage Test — designed with 200+ political scientists; when candidates refuse, VoteSmart uses public record)
- Voting records (for incumbents)
- Campaign finance data
- Interest group ratings (which organizations rate the candidate positively/negatively)
- Speeches and public statements

**Strengths:** Issue positions via Political Courage Test are the most structured of all four competitors; interest group ratings add third-party context; covers candidates who refuse to answer directly via public record.

**Weaknesses:** Extremely weak local coverage — township trustees, school board, county commissioners in Monroe County are not covered at all. Heavy emphasis on interest group ratings, which EV explicitly avoids (antipartisan mission).

**Confidence:** MEDIUM (sourced from VoteSmart about page and feature descriptions)

---

## Table Stakes

Features voters expect a voter guide to have. Missing these makes the product feel incomplete or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| All races on the ballot shown | Every competitor shows every race from federal to township; voters who open Election Central and don't see their county commissioner race will assume the app is broken. | MEDIUM | Data gap: EV currently has 12 races for Monroe County. The expected count is ~30-40+ races across federal, state, county, township, school board, and judicial. Primary constraint is manual data entry. |
| Candidate names for every race | Even if no profile data exists, voters need to know who is on their ballot. BallotReady and Vote411 show all candidates even with no profile. | LOW | For uncontested races, still need the candidate name. For races with multiple candidates, all must appear. Blank race cards destroy trust. |
| Office description ("What does this office do?") | Vote411 and BallotReady both provide plain-language job descriptions for every office. First-time voters especially need this for obscure offices like County Surveyor or Township Trustee. | LOW | Can be static copy per office type. Approximately 20 distinct office types in Monroe County. No API needed — just a lookup table of office_type → description string. |
| Countdown to election / election date visible | All four competitors show the election date prominently. EV's Election Central already has a countdown but it must be accurate. | LOW | Already built. Verify May 5, 2026 date is correct in the database. |
| Personalized ballot by address | Every competitor limits the ballot to races relevant to the user's address. A voter in Bloomington shouldn't see Clear Creek Township races. | HIGH | Currently EV shows all races in a coverage area. True precinct-level filtering requires precinct boundary geofences or at minimum district-level geofences for all races. Township geofences are not yet imported. |
| Candidate comparison side-by-side | Vote411's key UX feature. Voters want to see two candidates' positions on the same issue without navigating back and forth. | MEDIUM | EV has the compass comparison and Read & Rank head-to-head, but these require the voter to have filled out the compass first. A direct side-by-side candidate view (without compass dependency) is missing. |
| Links to official campaign/government websites | All four competitors link to official sources. Voters who want more information need a way out. | LOW | EV already has politician_contacts table with website URLs. For new candidates without politician profiles, campaign website links need to be in the race_candidates data. |
| What party primary am I voting in? | Indiana primary requires voters to choose a party. This context must be surfaced before showing races. | LOW | Currently not explicit in EV UI. A one-line note ("Indiana voters choose one party primary") reduces confusion. |

---

## Differentiators

Features EV offers (or could offer) that competitors do not, aligned with the platform's existing strengths.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Compass alignment score on candidate card | No competitor shows a policy-alignment radar between the voter's compass and the candidate's stances on Election Central. EV already has this infrastructure via CompassCard. | MEDIUM | Requires: (a) candidate has compass stances entered, (b) voter has compass data. Currently near-zero local candidates have stances — this is the bottleneck. High value if data exists. |
| Read & Rank quotes for primary candidates | No competitor lets voters evaluate candidate statements via head-to-head judgment. EV's Read & Rank is unique. | MEDIUM | Requires sourced quotes for candidates. Currently exists for incumbents (congressional, state legislative). Most primary challengers have no quotes imported. Data entry is the bottleneck. |
| Legislative record on incumbent profiles | Committees, bills, votes, leadership positions from Congress.gov/LegiScan. No voter guide competitor shows voting record inline on a profile — they link to external sites. | LOW | Already built for federal/IN state legislators. Directly usable for Matt Pierce (IN House D-61), Erin Houchin (US House D-9), Todd Young's successor's opponent research, etc. |
| Budget data integration via Treasury Tracker | Treasury Tracker shows Bloomington municipal budget. No competitor links budget decisions to elected officials. | HIGH | Requires explicit linking of budget line items to elected officials who voted on them. Not yet built. Valuable but out of scope for a 2-week sprint. |
| Antipartisan design throughout | Competitors all display party affiliation prominently; party color-coding is standard. EV's deliberate removal of partisan signals is a differentiator for voters who want to judge candidates on substance. | LOW (design principle, not a feature to build) | Already enforced at schema and ingestion layers. Must remain consistent on new race/candidate displays. |
| Offline-compatible saved ballot | BallotReady supports save + print. EV does not. For voters who want to bring choices to the polls on paper or screenshot, this is a practical need. | MEDIUM | Could be a simple "Print this page" or PDF export of the Election Central view filtered to the voter's races. No backend changes needed — browser print CSS. |

---

## Anti-Features

Features to explicitly NOT build for this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Interest group ratings / ideology scores | VoteSmart includes these; they directly embed partisan framing. Knowing a candidate is rated 90% by the NRA or 85% by the Sierra Club primes voters along partisan lines before they read actual positions. | Show raw voting records and sourced quotes. Let voters form their own judgments. |
| Party affiliation display | All four competitors show party; EV is explicitly antipartisan. Even "D" / "R" initials on cards introduce partisan priming. | Show office, district, government tier. If party is legally required context (e.g., "Democratic Primary"), state it once as structural context, not as a candidate attribute. |
| Endorsement tracking | BallotReady and Ballotpedia track endorsements. For local races, endorsements are heavily partisan signals (party chairs, unions, PACs). | Candidate's own words via quotes and Q&A answers are more informative and less partisan. |
| AI-generated candidate summaries | Civic tech is seeing AI summaries emerge as a differentiator (Spotlight PA, others). However, hallucination risk on local candidates (who have sparse public record) is high, and the nonprofit's editorial credibility depends on accuracy. | Source-verified quotes and voting records only. Flag unverified claims clearly. |
| Precinct-level sample ballot accuracy claim | Making a strong "here's your exact ballot" claim requires precinct boundary data the system doesn't have. Overclaiming accuracy destroys trust when wrong. | Say "races for your area" not "your ballot." Add caveat: "check official sample ballot for your exact precinct." |
| Comprehensive statewide race coverage | Indiana has hundreds of state legislative races. Attempting to cover all of them in 2 weeks for this primary is not feasible. | Focus on Monroe County specifically. Be explicit about coverage scope on the Election Central page. |

---

## Monroe County IN 2026 Primary — Expected Race List

Primary date: **Tuesday, May 5, 2026.** Indiana requires voters to choose one party primary (Democrat or Republican).

This is the authoritative list of races expected on Monroe County ballots based on research from B-Square Bulletin, Indiana Daily Student, Ballotpedia, Indiana Citizen, and LWV Bloomington-Monroe County sources.

### Federal

| Race | Party Primary | Candidates Known | In EV? | Notes |
|------|--------------|-----------------|--------|-------|
| U.S. House, Indiana District 9 | D (contested) | Jim Graham, Brad Meyer, Timothy Peck, Keil Roark | Unknown | Monroe County is in IN-09. Democratic contested primary. Erin Houchin (R) runs unopposed in GOP primary. |
| U.S. House, Indiana District 9 | R (uncontested) | Erin Houchin (incumbent) | Unknown | |

**No U.S. Senate race in Indiana in 2026.** Todd Young's term runs to 2029.

**Complexity: LOW** — races exist in EV's existing federal tier. Candidate import needed.

### State Legislative

| Race | Party Primary | Candidates Known | In EV? | Notes |
|------|--------------|-----------------|--------|-------|
| Indiana House District 61 | D (contested) | Matt Pierce (incumbent), Lilliana Young | Likely partial | Pierce is a sitting representative; his profile likely exists. Young is a challenger — new candidate record needed. |
| Indiana House District 62 | D (uncontested) | Amy Huffman Oliver | Unknown | District 62 covers parts of Monroe + Brown + Jackson counties. |
| Indiana Senate (district TBD) | Varies | TBD | Unknown | Indiana Senate districts covering Monroe County include portions of Districts 40 and 42. Only 25 of 50 seats up in 2026 — need to verify which Senate district(s) in Monroe County are on ballot this cycle. |

**Complexity: MEDIUM** — state house incumbents likely in DB; challengers need new candidate records.

### County Offices (Non-judicial)

All county offices on the 2026 primary ballot per search results: judge, county councilor (three at-large), county commissioner, auditor, coroner, surveyor, treasurer.

| Race | Party Primary | Candidates Known | In EV? | Notes |
|------|--------------|-----------------|--------|-------|
| County Assessor | D (contested) | Bob Nyquist, Judith A. Sharp (incumbent) | Unknown | Contested Democratic primary. |
| County Clerk | D (contested) | Tanner Dale Branham, Joe Davis, Tree Martin Lucas | Unknown | Three-way Democratic primary. |
| County Commissioner District 1 | D (contested) | Trent Deckard, David G. Henry | Unknown | Both are current county council at-large members running for commissioner. |
| County Commissioner District 1 | R | TBD | Unknown | Verify if contested. |
| Prosecuting Attorney | D (contested) | Benjamin T. Arrington, Erika Oliphant (incumbent) | Unknown | Two-way Democratic primary. |
| County Council District 1 | D (uncontested) | Peter James Iversen | Unknown | |
| County Council District 2 | D (uncontested) | Kate Wiltz | Unknown | |
| County Council District 3 | R (uncontested) | Martha Hawk | Unknown | |
| County Auditor | Both parties | Incumbent: Brianne Gregory (D) | Unknown | Need to verify if primary contested. |
| County Treasurer | Both parties | Incumbent: Catherine Smith (D) | Unknown | Need to verify if primary contested. |
| County Surveyor | Both parties | Incumbent: Trohn Enright-Randolph | Unknown | Need to verify party/contested status. |
| County Coroner | Both parties | TBD | Unknown | Need candidate research. |
| County Judge | Both parties | TBD | Unknown | Indiana trial court judges run in contested partisan primaries (not retention elections) in most counties including Monroe. Need to verify which judge seats are on the 2026 ballot. |

**Complexity: HIGH** — most county-level candidates are not yet in EV. Manual data entry required for each candidate. 8-10 distinct races, many with 2-3 candidates each.

### Township Offices

Monroe County has 11 townships: Bean Blossom, Benton, Bloomington, Clear Creek, Indian Creek, Perry, Polk, Richland, Salt Creek, Van Buren, Washington.

Not all townships have contested primaries. Known contested races:

| Race | Party Primary | Candidates Known | In EV? | Notes |
|------|--------------|-----------------|--------|-------|
| Clear Creek Township Trustee | R (contested) | Steven A. Hinds, Thelma Kelley Jeffries (incumbent), Ty Mungle | No | Three-way Republican primary. |
| Clear Creek Township Board | R (contested) | Dustin Cole Dillard (incumbent), R. Shannon Reed, Paul Strain, Steven E. Webb | No | Four candidates for board seats. |
| Indian Creek Township Trustee | General matchup set | Susan (Gus) Hingle (D), Christopher Reynolds (R, incumbent) | No | November matchup set; primary may be uncontested for each party. |
| Perry Township Trustee | D (contested) | Levi Combs, Leon Gordon | No | Note: Eric Petry withdrew before Feb 13 deadline. |
| Perry Township Board | D (contested) | Jack Davis (incumbent), Jeremy Goodrich, Susie Hamilton (incumbent), Jenny Olmes-Stevens, Barbara Sturbaum (incumbent) | No | Five candidates for three seats. |
| Richland Township Board | R (contested) | Traves Conyer, Elaine Thomsen, Jay Thrasher (incumbent), David Willibey (incumbent) | No | Four candidates. |
| Remaining 6-7 townships | Both parties | Mostly uncontested | No | Need to verify: Bean Blossom, Benton, Bloomington, Polk, Salt Creek, Van Buren, Washington township trustees and boards. |

**Complexity: HIGH** — zero township data currently in EV. ~20+ individual candidate records needed across 11 townships. Township geofences not yet imported (cannot do precinct-level filtering). This is the largest raw data gap.

### School Board (MCCSC)

Monroe County Community School Corporation (MCCSC) school board elections. Indiana school board elections are typically held in November (general election), but primary may include internal party elections for school board in some cases.

| Race | Notes |
|------|-------|
| MCCSC Board of School Trustees | Indiana school board races are generally nonpartisan and held in November; primary ballot unlikely to include MCCSC. Needs verification. |

**Complexity: LOW to verify, MEDIUM to implement** — need to confirm if MCCSC appears on May 5 primary ballot at all.

### Judicial

Indiana trial court judges in Monroe County run in contested partisan primaries, not retention elections (unlike Marion, Lake, Vanderburgh, Allen, and St. Joseph counties which have retention elections).

| Race | Notes |
|------|-------|
| Monroe County Circuit Court Judge(s) | Need to verify which judge seats are up in 2026 primary and who has filed. In 2024, three circuit court judges ran uncontested in November. Verify 2026 cycle. |
| Monroe County Superior Court Judge(s) | Same — need filing information. |

**Complexity: MEDIUM** — need to determine which specific judge seats are on the primary ballot and whether any are contested. Judge profile pages would be minimal (no legislative record; bio + campaign website).

---

## Feature Gap Summary: EV vs Competitors

| Feature | BallotReady | VOTE411 | Ballotpedia | VoteSmart | EV Current | EV Gap |
|---------|-------------|---------|-------------|-----------|-----------|--------|
| All races on ballot shown | YES (Tier 3-4 for Monroe Co.) | YES (address-based) | PARTIAL (top 100 cities only) | NO (federal/state only) | PARTIAL (12 races) | ~20-30 races missing |
| Office descriptions | YES | YES | YES | PARTIAL | NO | Need static copy for ~20 office types |
| Candidate names for all races | YES | YES | PARTIAL | NO | PARTIAL | Township/judge/county races largely missing |
| Candidate biography | YES (edu + experience) | NO | YES | YES | YES (for politicians) | Challenger candidates lack profiles |
| Candidate issue positions | YES (own words from website) | YES (Q&A in own words) | PARTIAL | YES (Political Courage Test) | YES via Compass (sparse for locals) | Most local candidates have no stances |
| Candidate quotes | NO | NO | NO | YES (public statements) | YES via Read & Rank (sparse for locals) | Most primary candidates have no quotes |
| Voting record | NO | NO | PARTIAL | YES | YES (for incumbents) | Challengers and local officials have no record |
| Legislative record (bills/committees) | NO | NO | NO | NO | YES | Unique differentiator — already built |
| Side-by-side comparison | NO (separate profiles) | YES (Q&A side-by-side) | NO | NO | PARTIAL (compass only) | Missing direct comparison without compass |
| Personalized ballot by address | YES | YES | YES | NO | PARTIAL (area not precinct) | Township/precinct geofences not imported |
| Save/print ballot choices | YES | YES (PDF) | NO | NO | NO | Missing "take to the polls" feature |
| Ballot measure coverage | YES | YES | YES | NO | NO | No ballot measures currently tracked |
| Election date / countdown | YES | YES | PARTIAL | NO | YES | Already built |
| Party primary context | YES | YES | YES | N/A | NO (antipartisan — structural note needed) | One-line Indiana primary party choice explainer |

---

## Feature Dependencies

```
All races visible on Election Central
    └──requires──> Data import for ~30+ races (county, township, judicial, federal, state)
    └──requires──> race_candidates records for each candidate
    └──bottleneck──> Manual data entry effort; no automated pipeline for county/township candidates
    └──partial mitigation──> Import from Indiana SoS candidate list PDF (2026-Candidate-Guide.FINAL.pdf exists)

Precinct-level ballot personalization
    └──requires──> Township boundary geofences in essentials.geofences
    └──requires──> TIGER 2024 township boundary shapefiles (same pipeline as congressional/state)
    └──requires──> District-level mapping for county commissioner districts 1-3
    └──note──> HIGH effort; partial solution is district-level filtering without full precinct precision

Office descriptions
    └──requires──> Static lookup table: office_type → description text (~20 entries)
    └──does NOT require──> Database changes (can be frontend constants)
    └──low effort──> ~2 hours of copywriting

Side-by-side candidate comparison (without compass)
    └──requires──> Two candidates selected (could be URL params)
    └──requires──> Candidate data: bio + positions + quotes
    └──depends on──> Having candidate data imported (circular dependency with data gap)
    └──scoped approach──> Build comparison UI; it is only useful once data is imported

Compass alignment on candidate cards
    └──requires──> Candidate has compass stances (almost none for local candidates currently)
    └──requires──> Voter has a compass (handled by CTA mode)
    └──bottleneck──> Stance data import for primary candidates (PROF-04, deferred since v2026.3.8)

Read & Rank quotes for primary candidates
    └──requires──> Sourced verbatim quotes for each candidate
    └──requires──> Manual research and import via Go CLI (import-quotes subcommand exists)
    └──bottleneck──> Source availability: local candidates have minimal press coverage

Save/print ballot
    └──requires──> UI to select/save candidate choices (not yet built)
    └──OR──> Simple print CSS on Election Central page (lower effort, lower value)

Indiana party primary explainer
    └──requires──> One-line static UI copy addition
    └──no backend changes needed
```

---

## MVP Recommendation: Before May 5 Primary

### Tier 1 — Ship Before Primary (highest impact, achievable in ~2 weeks)

1. **Import all missing Monroe County races** — federal (US House D-9), state (IN House D-61, D-62), county (assessor, clerk, commissioner, prosecutor, council, auditor, treasurer, coroner, surveyor, judge), township (Clear Creek, Perry, Richland at minimum). Source: Indiana SoS 2026 Candidate Guide PDF + B-Square Bulletin. (~30-40 candidate records, ~20 race records)
   - Complexity: MEDIUM-HIGH (data entry + import scripts)
   - Value: Without this, Election Central is incomplete for any Monroe County voter

2. **Office descriptions ("What does this office do?")** — Static copy for County Assessor, Clerk, Commissioner, Prosecutor, Council, Auditor, Treasurer, Coroner, Surveyor, Judge, Township Trustee, Township Board, US House, Indiana House, Indiana Senate. ~20 entries, frontend-only.
   - Complexity: LOW
   - Value: Addresses the #1 voter complaint about local elections ("I don't know what this person even does")

3. **Indiana primary party choice explainer** — One-sentence UI copy on Election Central: "Indiana requires you to choose one party primary. Races shown are available across both parties."
   - Complexity: LOW
   - Value: Eliminates voter confusion about why they can't vote in both primaries

4. **Verify and fix race/candidate data accuracy** — spot-check all 12 existing races against current official candidate filings; verify election date is May 5, 2026; fix any stale data from v2026.3.8 import.
   - Complexity: LOW
   - Value: Data accuracy is table stakes; errors destroy credibility

### Tier 2 — Ship Before Primary if bandwidth allows

5. **Compass stance imports for Monroe County primary candidates** — At minimum for the 4 Democratic US House D-9 candidates and the 2 IN House D-61 candidates. Source: campaign websites, public statements.
   - Complexity: MEDIUM (research + staging entry + review)
   - Value: Unlocks compass alignment on Election Central for the most-contested races

6. **Sourced quote imports for primary candidates** — 3-5 verbatim quotes per candidate for US House D-9 and IN House D-61 candidates. Source: local press (Indiana Daily Student, Herald-Times, B-Square Bulletin).
   - Complexity: MEDIUM (research + import-quotes CLI)
   - Value: Enables Read & Rank for the most-visible primary races

7. **Township geofence import (partial)** — Import TIGER 2024 township boundaries for Monroe County's 11 townships. Enables filtering township races from the display for voters not in that township.
   - Complexity: MEDIUM (same TIGER pipeline already built for congressional/state districts)
   - Value: Prevents Bloomington residents from seeing Clear Creek Township races

### Defer to Post-Primary

- **Side-by-side candidate comparison UI** — Build the UI after data is complete; incomplete data makes comparison useless
- **Save/print ballot** — Valuable but not blocking; voters can screenshot
- **Budget-to-official linking** — HIGH complexity, requires new data model
- **All township races fully researched** — Bean Blossom, Benton, Polk, Salt Creek, Van Buren, Washington townships have limited public profile data
- **MCCSC school board import** — Likely November general election, not May primary
- **Comprehensive statewide coverage** — Out of scope; Monroe County focus only

---

## Complexity Summary

| Gap | Complexity | Blocking |
|-----|-----------|---------|
| Import ~30 missing races | MEDIUM-HIGH | YES — core election completeness |
| Import ~80+ missing candidate records | HIGH | YES — ballot completeness |
| Office descriptions (static copy) | LOW | YES — table stakes UX |
| Indiana party primary explainer | LOW | YES — voter confusion |
| Data accuracy audit | LOW | YES — credibility |
| Compass stances for top candidates | MEDIUM | NO — differentiator |
| Quotes for top candidates | MEDIUM | NO — differentiator |
| Township geofences | MEDIUM | NO — nice-to-have for filtering |
| Side-by-side comparison UI | MEDIUM | NO — needs data first |
| Save/print ballot | MEDIUM | NO — workaround exists |
| Ballot measures | MEDIUM | NO — none identified for May 5 |
| Precinct-level personalization | HIGH | NO — district-level acceptable |
| Budget-to-official linking | HIGH | NO — future milestone |

---

## Sources

- [B-Square Bulletin — 2026 Monroe County contested primaries](https://bsquarebulletin.com/election-2026-contested-local-primaries-some-november-matchups-take-shape-across-monroe-county/) — PRIMARY source for known contested races (MEDIUM confidence — local outlet, recently published)
- [Indiana Daily Student — IN House District 61 candidates](https://www.idsnews.com/article/2026/03/democratic-candidates-bloomington-state-house-election-public-forum) — Matt Pierce vs. Lilliana Young confirmed (MEDIUM confidence)
- [Indiana Daily Student — US House District 9 Democrats](https://www.idsnews.com/article/2026/02/district-9-election-candidates-monroe-county-democrats-open-house) — Four Democratic candidates confirmed (MEDIUM confidence)
- [Indiana Daily Student — Monroe County prosecutor race](https://www.idsnews.com/article/2026/03/monroe-county-prosecutor-candidate-race-democratic-primary) — Arrington vs. Oliphant confirmed (MEDIUM confidence)
- [Ballotpedia — Monroe County Indiana elections 2026](https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026) — County office list confirmed (MEDIUM confidence — Ballotpedia local coverage is partial for Monroe County)
- [Indiana Citizen — 2026 Primary Candidate List](https://indianacitizen.org/2026-indiana-primary-candidate-list/) — State-level candidate compilation (MEDIUM confidence)
- [Indiana SoS 2026 Candidate Guide PDF](https://www.in.gov/sos/elections/files/2026-Candidate-Guide.FINAL.pdf) — Official source, not fetched but URL confirmed in search results (HIGH confidence for existence, contents unverified)
- [MCPL Voting Information — 2026 sample ballot PDFs](https://mcpl.info/geninfo/voting-information) — Republican 2026 primary sample ballot PDF linked (HIGH confidence for existence, not fetched)
- [Monroe County townships list](https://en.wikipedia.org/wiki/Category:Townships_in_Monroe_County,_Indiana) — 11 townships confirmed: Bean Blossom, Benton, Bloomington, Clear Creek, Indian Creek, Perry, Polk, Richland, Salt Creek, Van Buren, Washington (HIGH confidence)
- [BallotReady data tiers documentation](https://support.ballotready.org/ballotready-data-tiers-position-and-candidate-research) — Tier 3-4 covers Monroe County township/school board; candidate profile data points confirmed (MEDIUM confidence)
- [BallotReady research process](https://www.ballotready.org/research-process) — Education/experience/endorsements/stances methodology (MEDIUM confidence)
- [VOTE411 LWV overview](https://www.lwv.org/elections/vote411) — Q&A format, candidate self-submission, side-by-side comparison confirmed (MEDIUM confidence)
- [LWV Bloomington-Monroe County](https://www.lwv-bmc.org/content.aspx?page_id=22&club_id=901066&module_id=518281) — Local chapter produces "Keys to the Candidates" PDF distributed to senior centers and library (MEDIUM confidence)
- [VoteSmart features](https://justfacts.votesmart.org/about/political-courage-test/) — Political Courage Test, interest group ratings confirmed (MEDIUM confidence)
- [Ballotpedia sample ballot FAQ](https://ballotpedia.org/Sample_Ballot_Frequently_Asked_Questions) — Coverage limited to top 100 US cities; Monroe County not covered (MEDIUM confidence)
- [Indiana judicial elections — Ballotpedia](https://ballotpedia.org/Indiana_judicial_elections) — Monroe County judges run in contested partisan elections, not retention (MEDIUM confidence)

---

*Feature research for: v2026.4.3 Indiana Primary Election Readiness Audit*
*Researched: 2026-04-11*
