# Requirements: Essentials Election Central

**Defined:** 2026-03-29
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3.8 Requirements

Requirements for Essentials Election Central milestone. Each maps to roadmap phases.

### Data Infrastructure

- [ ] **DATA-01**: Election data source researched and integrated for Bloomington/Monroe County IN + LA County CA
- [ ] **DATA-02**: Elections table created with election_date, election_type (primary/general/retention/special), and geographic scope
- [ ] **DATA-03**: Races table created linking offices to elections with position-level granularity
- [ ] **DATA-04**: Candidate-race linkage established connecting candidates to specific races with incumbent flag
- [ ] **DATA-05**: is_appointed data audited and backfilled for all officials added post-BallotReady (v1.6+)
- [ ] **DATA-06**: Candidate records populated in database for upcoming races in coverage areas

### Election Central Page

- [ ] **ELEC-01**: User can view upcoming election races for their address on a dedicated Election Central page
- [ ] **ELEC-02**: Races grouped by government body (Federal > State > Local) then by specific position (e.g., "City Council District 3")
- [ ] **ELEC-03**: Each race section shows all candidates with name, photo, and position sought
- [ ] **ELEC-04**: Incumbent candidates visually distinguished with badge/indicator
- [ ] **ELEC-05**: Election date and type (Primary/General/Retention) displayed per race with days-until countdown when <60 days
- [ ] **ELEC-06**: User navigates to Election Central from the same address search as the representatives page
- [ ] **ELEC-07**: Empty state shown clearly when no upcoming election data exists for the searched address

### Candidate Profiles

- [ ] **PROF-01**: User can view a full profile page for any candidate (same treatment as current officials)
- [ ] **PROF-02**: Candidate profiles include compass comparison card with user's calibrated data
- [ ] **PROF-03**: Candidate profiles include Read & Rank verdict badges from sourced quotes
- [ ] **PROF-04**: Compass stances researched and imported for candidates in coverage areas
- [ ] **PROF-05**: Sourced quotes collected and imported for candidates via existing quote pipeline

### Representatives Filter

- [ ] **FILT-01**: User can filter the main representatives page by Elected, Appointed, or All
- [ ] **FILT-02**: Retention judges (appointed with retention vote) appear under both Elected and Appointed filters
- [ ] **FILT-03**: Filter defaults to "All" preserving current behavior

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Election Enhancements

- **ELEC-F01**: Ballot measures / referendum display on Election Central
- **ELEC-F02**: Polling place / "how to vote" logistics integration
- **ELEC-F03**: Real-time election results on election night
- **ELEC-F04**: Candidate self-submitted Q&A responses (VOTE411-style)

### Coverage Expansion

- **COV-F01**: Election data for additional states beyond IN and CA
- **COV-F02**: Automated election data refresh pipeline (nightly/weekly)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Party affiliation display | Antipartisan mission — voters derive alignment from compass, votes, and quotes |
| Endorsement lists | Partisan signals by nature; conflicts with antipartisan mission |
| Animated countdown timer (seconds) | Undermines serious, trustworthy tone |
| Polling place lookup | Operational scope is voter research, not logistics; link to county registrar instead |
| Real-time election results | Link to county election board; not core mission |
| Ballot measures / referendums | Different data model and UX pattern; no existing infrastructure |
| Coverage beyond IN + CA | Pipeline reusable but data sourcing per-state is manual effort |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | — | Pending |
| DATA-02 | — | Pending |
| DATA-03 | — | Pending |
| DATA-04 | — | Pending |
| DATA-05 | — | Pending |
| DATA-06 | — | Pending |
| ELEC-01 | — | Pending |
| ELEC-02 | — | Pending |
| ELEC-03 | — | Pending |
| ELEC-04 | — | Pending |
| ELEC-05 | — | Pending |
| ELEC-06 | — | Pending |
| ELEC-07 | — | Pending |
| PROF-01 | — | Pending |
| PROF-02 | — | Pending |
| PROF-03 | — | Pending |
| PROF-04 | — | Pending |
| PROF-05 | — | Pending |
| FILT-01 | — | Pending |
| FILT-02 | — | Pending |
| FILT-03 | — | Pending |

**Coverage:**
- v2026.3.8 requirements: 21 total
- Mapped to phases: 0
- Unmapped: 21

---
*Requirements defined: 2026-03-29*
*Last updated: 2026-03-29 after initial definition*
