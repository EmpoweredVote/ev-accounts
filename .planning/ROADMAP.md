# Roadmap — v2026.4.3 Indiana Primary Election Readiness Audit

**Milestone goal:** Audit the full voter experience for Monroe County IN ahead of the Indiana primary (May 5, 2026), benchmark against BallotReady/VoteSmart/Vote411/Ballotpedia, and produce a tiered gap list (ship-before-primary vs future) across data, functionality, and UX.

**Granularity:** standard
**Total phases:** 4 (Phase 112 — Phase 115)
**Requirements covered:** 21/21
**Repos affected:** `ev-accounts` (read-only audit script), `.planning/` (markdown outputs only)

---

## Phases

- [x] **Phase 112: Data Completeness Audit** — DB audit script + full Monroe County May 5 ballot baseline built from authoritative sources (completed 2026-04-12)
- [ ] **Phase 113: Competitive Benchmarking** — Live Monroe County spot-checks on BallotReady, Vote411, VoteSmart, Ballotpedia with feature comparison matrix
- [ ] **Phase 114: UX Walkthrough** — Voter journey documented for Essentials, Compass, Read & Rank, and Treasury with gaps logged
- [ ] **Phase 115: Gap Report Synthesis** — Tiered gap report (Tier 1 before primary / Tier 2 future) with execution backlog for follow-on milestone

---

## Phase Details

### Phase 112: Data Completeness Audit
**Goal**: The actual gap between what is in the DB and what is on the May 5 Monroe County ballot is measured and documented, with a verified full ballot baseline from authoritative external sources.
**Depends on**: Nothing (foundation — read-only queries against existing DB; no external services required)
**Requirements**: AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04, AUDIT-05, AUDIT-06, AUDIT-07, AUDIT-08
**Success Criteria** (what must be TRUE):
  1. Running the audit script outputs a structured report showing race count in DB vs confirmed May 5 ballot total, with named missing races listed.
  2. Each race in the report has a candidate coverage line — how many candidates are linked, how many are unlinked stubs, and how many are expected.
  3. The report includes stance and quote coverage per candidate: how many have any compass stances, how many have any Read & Rank quotes.
  4. The report includes headshot coverage per candidate: CDN photo vs local file vs no photo.
  5. A full ballot baseline document exists in `.planning/research/` sourced from Indiana SoS + Monroe County Clerk + local press, listing every race and expected candidate count for May 5.
  6. A Bloomington address (e.g., 200 W Kirkwood Ave) resolves correctly through the geofence stack and the returned races match the baseline.
**Plans:** 3/3 plans complete
Plans:
- [x] 112-01-PLAN.md — Ballot baseline document + race and candidate audit scripts
- [x] 112-02-PLAN.md — Stance, quote, headshot, and profile completeness audit scripts
- [x] 112-03-PLAN.md — Geofence smoke test + assembler for unified audit report

### Phase 113: Competitive Benchmarking
**Goal**: EV's Monroe County coverage is benchmarked against all four major voter guide competitors using a live Bloomington address, producing a feature comparison matrix.
**Depends on**: Phase 112 (full ballot baseline must exist to compare race coverage accurately)
**Requirements**: BENCH-01, BENCH-02, BENCH-03, BENCH-04, BENCH-05, BENCH-06
**Success Criteria** (what must be TRUE):
  1. A live spot-check on BallotReady with a Monroe County address is documented: races shown, candidate data depth (fields present), stance/Q&A availability.
  2. A live spot-check on Vote411 with the same address is documented: races shown, Q&A coverage, and candidate profile depth.
  3. A live spot-check on VoteSmart with the same address is documented: candidate coverage and data fields.
  4. A live spot-check on Ballotpedia with the same address is documented: race and candidate coverage.
  5. A feature comparison matrix covering at least 15 dimensions (race coverage, candidate fields, stance data, quote/Q&A, photo, bio, legislative record, compass, geofence precision, antipartisan, etc.) places EV against all four competitors, with honest scoring.
  6. Per-competitor race and candidate counts for Monroe County are directly compared against the Phase 112 baseline in the matrix.
**Plans**: TBD
**UI hint**: no

### Phase 114: UX Walkthrough
**Goal**: A voter's first-time experience through each EV app for Monroe County IN is documented with specific friction points and gaps identified.
**Depends on**: Phase 112 (full ballot baseline and audit data must be available to assess data gaps during walkthrough)
**Requirements**: UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. The Essentials voter journey is documented: searching a Monroe County address, reviewing each screen (results, election central, representative cards, candidate profiles), with every gap, missing piece, or confusing moment logged.
  2. The Compass voter journey is documented: evaluating whether a Monroe County voter can meaningfully use the compass for candidates in contested races, with stance data availability assessed per race.
  3. The Read & Rank voter journey is documented: whether enough sourced quotes exist for Monroe County primary candidates for the tool to be useful, and whether candidate filtering works for the county.
  4. The Treasury relevance assessment is documented: whether Monroe County budget data is present, surfaced, and contextually useful to a voter visiting in an election context.
**Plans**: TBD
**UI hint**: no

### Phase 115: Gap Report Synthesis
**Goal**: Findings from the data audit, competitive benchmarking, and UX walkthrough are synthesized into an actionable tiered gap report with a prioritized execution backlog.
**Depends on**: Phase 112, Phase 113, Phase 114 (all three audit tracks must complete before synthesizing)
**Requirements**: GAP-01, GAP-02, GAP-03
**Success Criteria** (what must be TRUE):
  1. A gap report document exists in `.planning/` classifying every identified gap as Tier 1 (must ship before primary, ~May 6) or Tier 2 (future improvement).
  2. The gap report contains an explicit "intentional omissions" section documenting antipartisan choices (no party labels, no endorsements, no interest group ratings) to distinguish them from data gaps.
  3. An execution backlog exists as a prioritized list of phases for a follow-on milestone (v2026.4.4), sequencing Tier 1 gaps in the order they should be tackled with rough effort signals.
**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 112. Data Completeness Audit | 3/3 | Complete    | 2026-04-12 |
| 113. Competitive Benchmarking | 0/? | Not started | - |
| 114. UX Walkthrough | 0/? | Not started | - |
| 115. Gap Report Synthesis | 0/? | Not started | - |

---

## Coverage

**Requirements mapped:** 21/21

| REQ-ID | Phase |
|--------|-------|
| AUDIT-01 | 112 |
| AUDIT-02 | 112 |
| AUDIT-03 | 112 |
| AUDIT-04 | 112 |
| AUDIT-05 | 112 |
| AUDIT-06 | 112 |
| AUDIT-07 | 112 |
| AUDIT-08 | 112 |
| BENCH-01 | 113 |
| BENCH-02 | 113 |
| BENCH-03 | 113 |
| BENCH-04 | 113 |
| BENCH-05 | 113 |
| BENCH-06 | 113 |
| UX-01 | 114 |
| UX-02 | 114 |
| UX-03 | 114 |
| UX-04 | 114 |
| GAP-01 | 115 |
| GAP-02 | 115 |
| GAP-03 | 115 |

No orphaned requirements. No duplicates.

## Backlog

### Phase 999.1: Speaker identification for all meeting participants (BACKLOG)

**Goal:** Extend CouncilScribe identification to properly handle non-council speakers — recurring staff (clerk, attorney, department heads), invited presenters, and public commenters — without losing Phase 111's phantom rejection. Target design: add `chamber_attendees` (or `is_staff` flag on offices), a `recurring_commenters` table with classification, a `speaker_type` taxonomy on `SpeakerMapping`, pattern-aware L2 gating, and L3 phantom defense.

**Origin:** Regression discovered during Phase 111 verification run on 2026-02-25 Bloomington meeting — L2 roster gate blocked legitimate non-council names (e.g. City Clerk); LLM still hallucinated "Piafra" at L3 with no defense.

**Requirements:** TBD
**Plans:** 0 plans (likely 3–4 phase epic when promoted)

See: [.planning/phases/999.1-speaker-identification-all-meeting-participants/999.1-CONTEXT.md](./phases/999.1-speaker-identification-all-meeting-participants/999.1-CONTEXT.md) for full design notes.

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)
