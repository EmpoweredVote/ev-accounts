# Domain Pitfalls

**Domain:** Indiana Primary Election Readiness Audit — adding election audit and competitive benchmarking to an existing civic engagement platform
**Researched:** 2026-04-11
**Scope:** v2026.4.3 — Monroe County IN primary readiness audit, competitive benchmarking, data gap analysis

---

## Critical Pitfalls

Mistakes that invalidate the audit, produce false confidence, or create antipartisan violations.

---

### Pitfall 1: Treating the Current 12 Races / 18 Candidates as the Baseline for Completeness

**What goes wrong:** The audit begins by asking "how complete are we?" against the 12 imported races and 18 candidates. But completeness must be measured against the full ballot for a Monroe County address on May 5, 2026 — not against what was already imported. Using the existing import as the denominator creates false confidence: "we cover 100% of our races" is true but meaningless if the full ballot has 30+ races.

**Why it happens:** The natural anchor for an audit is the data that exists. Starting from what's imported feels like starting from a solid foundation. In practice, the election schema was bootstrapped from Indiana SoS Excel data at a single point in time, and the import did not necessarily capture every down-ballot race.

**Consequences:** The gap report underestimates missing races. Critical down-ballot races (township trustees, advisory board seats, prosecutor) appear as "future work" when they are May 5 primary races. Voters searching a Monroe County address get an incomplete election picture with no indication it is incomplete.

**Prevention:**
- Phase 1 of the audit must start from authoritative external sources: (a) Monroe County Clerk ballot certification, (b) Indiana SoS candidate list for Monroe County, (c) confirmed list from the bsquare Bulletin / local coverage.
- Build the "full ballot" list first, then compare against the database. Completeness = (races in DB) / (races on actual ballot).
- Confirmed May 5 races that are NOT in the current 12: County Assessor, County Clerk, County Commissioner District 1, County Prosecutor, Clear Creek Township Board, Clear Creek Township Trustee, Perry Township Board, Perry Township Trustee, Richland Township Board, Indian Creek Township Trustee, state legislative districts covering Monroe County (IN House District 62 etc.).

**Detection:** Query the elections schema for all races where `election_date = '2026-05-05'` and `state = 'IN'`. Cross-reference against the bsquare Bulletin race list (confirmed as of April 2026) and the Indiana Citizen primary candidate list.

**Phase:** Must be addressed in Phase 1 (data completeness audit). This is the single most important finding the audit must produce.

---

### Pitfall 2: School Board Races Are Absent from the Primary Ballot by Design — But Absent from the Schema for a Different Reason

**What goes wrong:** The audit flags "school board races missing" as a data gap to fill before the primary. In Indiana 2026, school board candidates do NOT appear on the May 5 primary ballot at all — the filing window for school board candidates opens May 19 (14 days after the primary) under the new Senate Bill 177 schedule, with elections in November. Importing or displaying school board races as "May 5 primary" content would be factually wrong and potentially misleading to voters.

**Why it happens:** School board races are typically down-ballot and often appear near township races and county races. An audit that does not know about the 2025 partisan school board law (SB 287 + SB 177) will assume they are missing data rather than missing by design. Indiana is now the 10th state with partisan school board elections, but the transition means NO school board primaries in 2026 — candidates file post-primary for November placement.

**Consequences:** Importing school board data for May 5 sends voters to a race that does not exist. Or the audit incorrectly escalates school boards to a "critical gap before the primary" when it should be a "November election work item."

**Prevention:**
- Flag school board races as November 2026 work, not May 5 primary work. Filing window opens May 19 — candidate data will not exist until after the primary.
- The new partisan school board system creates a secondary antipartisan compliance concern: when school board races DO appear in November, Indiana law requires displaying party affiliation (or an explicit nonpartisan/no-disclosure label) on the ballot. The platform's antipartisan enforcement must decide how to handle this before November.
- Do not import school board candidates as part of primary election readiness work.

**Detection:** Check any election import job targeting `mccsc` or `monroe county community school` for a May 5 election date — this indicates a misclassification.

**Phase:** Phase 1 (data completeness audit). Flag clearly as November scope. Create a future work item for antipartisan handling of partisan school board display.

---

### Pitfall 3: Competitive Benchmarking Scores BallotReady/Vote411 Features Without Accounting for Their Actual Monroe County Coverage

**What goes wrong:** The benchmarking audit scores competitor platforms on features (candidate bios, stance questionnaires, sample ballot accuracy) in general, then concludes "we should build X feature." But BallotReady's and Vote411's coverage of Monroe County IN may already have gaps. If BallotReady has no data for Clear Creek Township Trustee races and neither does the platform, the platform is not "behind" BallotReady on that race — both are at zero. Benchmarking against the feature set rather than Monroe County spot-check results leads to building features that would only be differentiated if the underlying data existed.

**Why it happens:** Benchmarking is easier to do by reading documentation and feature lists than by doing live spot-checks with a Monroe County address. The natural shortcut is "BallotReady has candidate questionnaires, we don't." But the real question is: does BallotReady have questionnaire data for Clear Creek Township Trustee Steven Hinds? Very likely no.

**Consequences:** The execution backlog prioritizes feature parity (building questionnaire infrastructure) over data coverage (actually importing the missing 15+ races). Features built on empty data provide no voter value.

**Prevention:**
- Every competitor benchmark must include a live spot-check: enter a Monroe County address (e.g., 401 N Morton St, Bloomington IN 47404) in BallotReady, Vote411, VoteSmart, and Ballotpedia. Screenshot or document what each returns.
- Score each platform on: races shown (count), candidate coverage (count), biography/bio text, stance data, photos, contact information.
- Note where competitors also have gaps — this calibrates the audit. "BallotReady shows 8 races, we show 6" is more actionable than "BallotReady has questionnaires."
- BallotReady was previously removed from the platform (BALLOTREADY_API_KEY decommissioned in v1.5). Do not re-engage their data pipeline for this milestone — benchmarking is read-only.

**Detection:** If the benchmark analysis does not include a live Monroe County address test for each competitor, the analysis is incomplete.

**Phase:** Phase 1 (competitive benchmarking). Live spot-check is mandatory, not optional.

---

### Pitfall 4: Antipartisan Violation in Benchmarking Documentation or Gap Reports

**What goes wrong:** The competitive benchmarking analysis notes that BallotReady or Vote411 "shows party affiliation on candidate cards." The gap report gets written as "we don't show party affiliation — gap vs BallotReady." This is not a gap to fill; it is an intentional antipartisan design choice. If "party affiliation display" is listed as a gap, it creates pressure to add partisan data to close the benchmark gap.

**Why it happens:** Mechanical feature checklists treat "shows party affiliation" as a neutral feature. An analyst ticking off BallotReady features without knowledge of the antipartisan principle will list it as missing.

**Consequences:** Party affiliation data gets imported as part of the gap-filling work. Even if not displayed publicly, the presence of partisan data in the database creates future pressure to display it. The antipartisan enforcement documented at the schema and ingestion layers gets bypassed.

**Prevention:**
- All benchmarking templates must have an explicit "antipartisan exclusion" category. Features that display party affiliations, partisan ratings, partisan endorsements, or political leaning scores are not gaps — they are intentional omissions.
- Document in the benchmark report: "EV platform intentionally omits: party affiliation display, partisan color coding, party-aligned voter guides."
- Flag Indiana school board partisan labeling as a future November-scope antipartisan compliance decision, not a current gap.
- The antipartisan principle is documented in project MEMORY (feedback_antipartisan.md) — reference it explicitly in the benchmark methodology.

**Detection:** Review every item in the benchmark gap list. Any item that involves displaying, storing, or linking to party affiliation should be moved to the "intentional omission" column.

**Phase:** Applies to all benchmarking and gap-report phases. Lock the exclusion list before writing any gap report.

---

## Moderate Pitfalls

Mistakes that produce incorrect gap assessments or wasted data import work.

---

### Pitfall 5: Township Trustee and Advisory Board Candidates Are Treated as Low-Priority Because They Are Unfamiliar

**What goes wrong:** The audit de-prioritizes township trustee races because the office is obscure and the candidates are local figures with no public profile. The gap report puts them in "future" tier. In practice, township trustees control local government services (poor relief, fire protection in some jurisdictions), and these races have directly contested primaries in Monroe County in May 2026 — Clear Creek Township Trustee (3 Republican primary candidates) and Perry Township Trustee (2 Democratic primary candidates) are active contested races. A voter searching their address in May gets no information about a race they will literally vote in.

**Why it happens:** Prioritization instincts favor name recognition. Governor, US Senate, state legislature feel more important than township trustee. But from a voter's perspective, all five primary races on their ballot matter equally.

**Consequences:** The platform shows federal and state races correctly but is silent on the contested township primary that is actually on the May 5 ballot. This is a direct failure of the core value ("helping voters make informed decisions").

**Prevention:**
- Treat "contested before May 5" as the prioritization criterion, not "name recognition" or "scope of office."
- All confirmed contested May 5 primaries in Monroe County must be in the platform before primary day — regardless of how obscure the office.
- Separate the data work: importing races and candidates is fast (schema exists); importing stances and bios is slow and optional. Import the races with minimal candidate data first; leave bio/stance enrichment as follow-up.

**Detection:** For every May 5 primary race identified in external sources, confirm it exists in the `essentials.elections` schema before the primary. A race with zero candidates is still better than no race record — it tells the voter "this race is happening" even if candidate data is thin.

**Phase:** Phase 2 (gap prioritization). Township races must be in the "before primary" tier, not "future."

---

### Pitfall 6: Assuming the Indiana SoS Excel Export Contains All Races

**What goes wrong:** The existing election import pipeline was built using Indiana SoS Excel data. The SoS candidate filing list is authoritative for state and federal races but may not include all township trustee and advisory board races, which are filed at the county clerk level rather than the state level. An audit that relies solely on the SoS Excel export will miss county-clerk-administered races.

**Why it happens:** The SoS is the canonical state-level source. It is easy to treat the SoS download as "complete." Indiana election administration distributes filing between the state (legislative, statewide offices) and county (local offices, township offices). Township races are not on the SoS candidate list.

**Consequences:** The audit concludes the SoS data is complete and stops there. Township trustee races are never imported. Voters in Clear Creek or Perry townships see no election data for their local primary.

**Prevention:**
- The complete source set for Monroe County races is: (1) Indiana SoS candidate filing list (state/federal), (2) Monroe County Clerk or Board of Elections (county and township races), (3) local media cross-check (bsquare Bulletin, Herald-Times) to catch anything missed.
- The Monroe County Clerk website or direct contact is required to get the complete local candidate list.
- Use the confirmed bsquare Bulletin race coverage as a completeness check against SoS data.

**Detection:** Compare the SoS candidate list count against the bsquare Bulletin race list. Any race in the local press that does not appear in the SoS list is a county-clerk-administered race.

**Phase:** Phase 1 (data completeness audit). Identify the gap between SoS data and full ballot before scoring completeness.

---

### Pitfall 7: Stance Data and Quote Imports Attempted on a 3-Week Timeline for New Candidates

**What goes wrong:** The gap report identifies that township and county candidates have no stance data or quotes for Read & Rank. The team attempts to research and import stances for all 30+ new candidates before the primary. With the existing CSV research workflow and Go CLI import process, a typical politician takes 1-3 hours of research per person (finding reliable sources, verifying URLs, avoiding hallucinated sources). Thirty candidates at 2 hours each is 60 hours of research work — beyond the team's capacity in 3 weeks alongside other gap-filling work.

**Why it happens:** The stance data gap is real. The instinct is to fill every gap before the primary. Down-ballot township candidates have almost no public stance record — township trustees do not give speeches, write op-eds, or have legislative voting records.

**Consequences:** The team spreads effort too thin. No import reaches production quality by the primary. The v1.8 lesson (700+ hallucinated URLs cleared from the data) applies here: rushed stance research produces bad data.

**Prevention:**
- Stance data for township and county candidates should be "future" tier in the gap report. These candidates have minimal public records.
- Prioritize in this order: (1) import missing races and candidates with minimal data (name, party if applicable, office), (2) add photos where available from candidate websites or local press, (3) stance data only for candidates with clear public records (incumbent legislators, county-level offices with documented voting history).
- The Read & Rank value for township trustee candidates is low — there are no quotes to evaluate. Do not force stance imports where the underlying public record does not exist.
- Explicitly state in the gap report: "Stance coverage for township candidates deferred — insufficient public record exists."

**Detection:** Before assigning stance research tasks, check whether the candidate has any public presence: website, news coverage, documented public statements. If a web search returns zero results for a candidate, stance research is impossible and should be deferred.

**Phase:** Phase 3 (gap prioritization / execution planning). Lock the "before primary" scope to race+candidate import, not stance enrichment.

---

### Pitfall 8: The Election Central Page Showing an Incomplete Ballot Without a Completeness Signal

**What goes wrong:** After the audit, some races get imported and others do not. The Election Central page for a Monroe County address shows 6 primary races when the actual ballot has 14+. A voter trusts the platform is showing "their ballot" and goes to vote having researched only the races displayed. The missing races are invisible — there is no "we may be missing races in your area" indicator.

**Why it happens:** The platform presents election data as a curated voter guide, not as a guarantee of completeness. But the UX does not communicate this distinction. The election page header implies completeness.

**Consequences:** Voter proceeds to the polls unprepared for township races they had no way to research on the platform. This is a trust and mission failure even if the platform delivered accurate data for the races it did show.

**Prevention:**
- Add a completeness caveat to the Election Central page: "Coverage for this area is ongoing. For a complete official ballot, visit the Monroe County Clerk or Indiana Secretary of State website" with a direct link.
- This is a one-line copy addition, not a feature build. It should be in the "before primary" execution scope regardless of how complete the data becomes.
- Do not remove the caveat even after importing all known races — election data can always have gaps.

**Detection:** Check the Election Central page for a Monroe County address immediately before the primary. Verify the caveat copy and the official ballot link are present and point to valid URLs.

**Phase:** Phase 2 (UX gap analysis). The completeness caveat is a fast fix that should ship in the same deployment as any new race imports.

---

### Pitfall 9: Benchmarking Against Ballotpedia's Full Scope Rather Than Their Monroe County Spot-Check Performance

**What goes wrong:** Ballotpedia is treated as the gold standard for election completeness. The gap report lists features from Ballotpedia's national coverage (judicial elections, legislative voting records, PAC donations, endorsements) as features to match. In practice, Ballotpedia's coverage of Monroe County judicial retention and township races may be thin or absent. The platform's scope is specifically Monroe County — where hyper-local coverage is the differentiator.

**Why it happens:** Ballotpedia's brand is comprehensive election data. It is natural to use their national feature set as the benchmark ceiling.

**Consequences:** The gap report overestimates required work. Features that Ballotpedia "has" nationally but does not have for Monroe County specifically are treated as competitive gaps when they are not.

**Prevention:**
- Benchmark only on Monroe County spot-check results: enter a Bloomington IN address in each competitor and document exactly what they return.
- Ballotpedia likely has: federal races, state legislative races, appellate judicial retention. Ballotpedia likely lacks: Clear Creek Township Trustee candidates, Perry Township Board candidates, Monroe County Assessor primary candidates.
- If Ballotpedia does not have data for a race, that race is a local-first opportunity for the platform, not a gap vs Ballotpedia.

**Detection:** The benchmark report must include a column "Available on Ballotpedia for Monroe County" not just "Ballotpedia has this feature globally."

**Phase:** Phase 1 (competitive benchmarking). The benchmark methodology must be Monroe County-specific from the start.

---

### Pitfall 10: Judicial Races Treated as Uniform When Indiana Has Multiple Judicial Selection Methods

**What goes wrong:** Indiana judicial races are not uniform. State appellate judges face retention elections (November 2026). Monroe County Circuit Court judges face partisan elections (Monroe County is not among the counties with merit-selection). A data import or audit that treats "judges" as a single category will either import retention-only data and miss contested partisan judicial primaries, or import partisan judicial race data and then display it incorrectly for retention judges (who are not contested).

**Why it happens:** Judicial selection systems vary by state and county. The schema has `faces_retention_vote` on the races table (introduced in v2026.3.8), but whether that flag is set correctly for all Indiana judicial races requires verification.

**Consequences:** A retention judge (yes/no vote) is displayed as having opponents. Or a contested circuit court race is treated as a retention vote. Both are wrong in ways that confuse voters.

**Prevention:**
- For Indiana: state appellate judges (Supreme Court, Court of Appeals) = retention elections in November 2026. Monroe County trial court judges = partisan election cycle (check Monroe County Clerk for 2026 races).
- Verify `faces_retention_vote` flag on any judicial races in the schema.
- If no Monroe County Circuit Court race exists on the primary ballot, do not create a placeholder — an empty retention record for a non-election-year judge is worse than no record.

**Detection:** Cross-check Indiana Judicial Branch retention schedule against any judicial entries in the races table. Confirm the `faces_retention_vote` flag is correctly set.

**Phase:** Phase 1 (data completeness audit). Judicial races must be individually verified, not imported as a category.

---

## Minor Pitfalls

Mistakes that create rework or inconsistency but do not invalidate the audit.

---

### Pitfall 11: Competitor Spot-Check Screenshots Taken at Different Times Are Not Comparable

**What goes wrong:** The benchmarking analysis is done over several days. BallotReady is checked on day 1, Vote411 on day 3, Ballotpedia on day 5. Competitor data changes daily as new candidates file and data teams import content. The benchmark report compares platforms at different snapshots, producing misleading comparisons.

**Prevention:**
- Complete all competitor spot-checks in a single session, same address, documented with timestamps.
- Note the spot-check date clearly in the benchmark report.

**Phase:** Phase 1 (competitive benchmarking). Do all spot-checks in one sitting.

---

### Pitfall 12: The Gap Report Mixes "Missing Data" Gaps with "Missing Features" Gaps

**What goes wrong:** The gap report lists "no stance data for Clear Creek Township Trustee" (data gap) alongside "no candidate questionnaire infrastructure" (feature gap) in the same list, both labeled as gaps. The execution backlog then has data tasks and feature build tasks interleaved, making prioritization unclear.

**Prevention:**
- Separate the gap report into three columns: (1) Data gaps — races/candidates not imported, (2) Feature gaps — UI/UX capabilities not present, (3) Intentional omissions — antipartisan choices and out-of-scope features.
- Feature gaps generally take longer to ship than data gaps. For a 3-week primary timeline, data gaps are higher value.

**Phase:** Phase 1 (gap report structure). Set the template before filling in findings.

---

### Pitfall 13: Treasury Data Relevance Check Expands Scope Unnecessarily

**What goes wrong:** The treasury relevance check is listed as part of the audit scope. Municipal budget data for Bloomington is in the platform. The relevance check concludes "voters might care about this before an election" and the execution backlog adds treasury integration to the election page. This is a reasonable long-term goal but a distraction on a 3-week primary timeline.

**Prevention:**
- Scope the treasury relevance check as: "Does any May 5 primary candidate's platform explicitly relate to the treasury data we have?" If yes, note it for stance research. If no, defer.
- The treasury tracker is a separate surface — cross-linking it from Election Central is future work.

**Phase:** Audit phase only. No feature work on treasury-election integration before the primary.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Data completeness audit | Using 12 races as denominator instead of full ballot | Start from external authoritative ballot sources, not existing DB count |
| Data source identification | Assuming SoS Excel contains all races | Township races are county-clerk-administered; contact Monroe County Clerk separately |
| School board handling | Importing school board races for May 5 | School board filing doesn't open until May 19; these are November races only |
| Competitive benchmarking | Scoring features globally rather than Monroe County spot-check | Live address test required for each competitor; document what they return for Bloomington IN |
| Gap report writing | Listing party affiliation display as a gap vs BallotReady | Party data is an intentional antipartisan omission; use an exclusion column in the gap report |
| Indiana partisan school board law | Treating future partisan labels as antipartisan violation to prevent | Decide October 2026 display approach now; do not import school board data before the primary |
| Judicial race imports | Applying uniform "judicial" category to mixed retention/partisan system | Verify each judge's selection method; set `faces_retention_vote` correctly per race |
| Gap prioritization | Putting township races in "future" tier | Contested May 5 primary races are all "before primary" tier regardless of name recognition |
| Stance research under time pressure | Attempting 30+ candidate stances in 3 weeks | Race+candidate import is the goal; stance research only where public record exists |
| Election Central UX | Showing partial ballot without completeness signal | Ship caveat copy and official ballot link in same deploy as new race imports |
| Benchmark scope creep | Matching Ballotpedia's full national feature set | Benchmark ceiling is Monroe County spot-check results, not Ballotpedia's global coverage |
| Treasury relevance check | Expanding scope to election-treasury integration | Treat as an informational check only; no feature builds before the primary |

---

## Sources

- Monroe County 2026 primary race list: [bsquare Bulletin](https://bsquarebulletin.com/election-2026-contested-local-primaries-some-november-matchups-take-shape-across-monroe-county/)
- Indiana school board partisan election law (SB 287 + SB 177): [Chalkbeat Indiana](https://www.chalkbeat.org/indiana/2026/04/07/primary-election-ballot-changes-exclude-education-races-and-referendums/) | [Chalkbeat 2025](https://www.chalkbeat.org/indiana/2025/04/24/partisan-school-board-election-bill-passes/)
- Indiana primary date (May 5, 2026): [WFYI](https://www.wfyi.org/statewide/2026-04-06/how-to-vote-early-in-indianas-2026-primary-election)
- Indiana judicial retention elections 2026: [Indiana Judicial Branch](https://www.in.gov/courts/retention/)
- Indiana 2026 candidate guide: [Indiana SoS](https://www.in.gov/sos/elections/files/2026-Candidate-Guide.FINAL.pdf)
- Ballot information problem (civic data gaps for down-ballot): [PBS Preserving Democracy](https://www.pbs.org/wnet/preserving-democracy/2024/02/27/the-ballot-information-problem/)
- BallotReady voter guide features: [BallotReady Support](https://support.ballotready.org/article/771-ballotreadys-voter-guide)
- Indiana 2026 primary candidates: [Indiana Citizen](https://indianacitizen.org/2026-indiana-primary-candidate-list/)
- 2026 Indiana election calendar: [Indiana SoS](https://www.in.gov/counties/clarkcountyclerkofcourts/voting-and-elections/files/2026-Indiana-Election-Calendar.pdf)
- Antipartisan principle: project MEMORY (feedback_antipartisan.md)
