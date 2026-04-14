# Phase 115: Gap Report Synthesis — Research

**Researched:** 2026-04-13
**Domain:** Document synthesis — tiered gap classification, execution backlog authoring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Primary tiering signal is severity-first: all UX gaps tagged `blocker` (G-114-001 through 031 severity=blocker) are automatically Tier 1 candidates. `confusing` and `minor` gaps default to Tier 2 unless they also represent data gaps with race coverage impact.
- **D-02:** May 1, 2026 is the Tier 1 hard cutoff — 4 days before the May 5 primary. Any fix that cannot plausibly land in prod by May 1 is Tier 2 even if severity=blocker. This feasibility ceiling is applied after severity screening, not before.
- **D-03:** Data audit findings from Phase 112 (AUDIT-REPORT-112.md) do not have pre-assigned severity. They inherit severity from their UX counterpart: if a data audit row is already covered by a G-114-NNN entry, inherit that entry's severity. Data audit findings with no UX counterpart default to Tier 2.
- **D-04:** The report is organized in sections by source, preserving original IDs: Section 1 UX Gaps (cite G-114-NNN), Section 2 Data Audit Findings (cite AUDIT-REPORT-112.md rows), Section 3 Cross-Cutting Patterns (new entries). Each section header names the source so findings are fully traceable back to their evidence.
- **D-05:** Benchmark matrix findings (MATRIX.md) appear as context and rationale only — they inform why a gap is Tier 1 rather than creating new gap entries. Example: "EV scores 0 on candidate bio vs VoteSmart's 3 — this elevates [gap ref] to Tier 1." Benchmark findings do NOT generate standalone gap entries unless they reveal a voter-facing gap not already in the UX gaps or audit rows (D-06).
- **D-06:** Exception — benchmark-derived gaps: If the benchmark + audit together reveal a voter-facing gap that the UX walkthrough missed (and it can be evidenced by both a MATRIX.md cell score AND an AUDIT-REPORT-112 row), the synthesis agent may create a new finding. It must cite both the benchmark score and the audit row as dual evidence. These go in Section 3 (Cross-Cutting Patterns), not Section 1 or 2.
- **D-07:** The synthesis agent may discover cross-cutting patterns not present in any single input. When the same root cause appears across multiple G-114-* entries or audit rows, the agent can name it as a pattern gap with a new ID (e.g., PATTERN-001). These entries are clearly labeled "cross-cutting pattern" and must cite the constituent gaps that evidence them.
- **D-08:** Each backlog item is a ROADMAP-ready phase entry containing: Phase name, Goal statement (1-2 sentences), Gaps closed (list of G-114-NNN, audit row refs, or PATTERN-NNN), Effort signal S/M/L, Depends-on (if any prior phase must run first). Ready to paste into ROADMAP.md for v2026.4.4 planning with minimal revision.
- **D-09:** T-shirt sizing (S/M/L) is the effort signal for each phase. No plan-count estimates.
- **D-10:** The gap report must include an explicit "Intentional Omissions" section listing antipartisan choices that are NOT gaps: no party labels, no endorsements, no interest-group ratings, no partisan color associations. These were documented in Phase 114's METHODOLOGY.md §8 and must be copied/referenced here.

### Claude's Discretion

- Exact file name for the gap report document (recommendation: `.planning/GAP-REPORT.md`)
- Whether Tier 1 and Tier 2 items are interleaved in each section or separated into top-level Tier 1 / Tier 2 blocks
- How many ROADMAP-ready phase entries to produce (determined by gap clustering)
- Narrative framing for the executive summary

### Deferred Ideas (OUT OF SCOPE)

None surfaced during discussion.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GAP-01 | Tiered gap report produced with Tier 1 (before primary) vs Tier 2 (future) classification | All three input sources read; tiering logic documented below |
| GAP-02 | Gap report separates data gaps, feature gaps, and intentional omissions (antipartisan) | Type taxonomy from METHODOLOGY.md §6 catalogued; intentional omissions list compiled from METHODOLOGY.md §8 and MATRIX.md intentional omissions section |
| GAP-03 | Execution backlog produced — prioritized phases for filling Tier 1 gaps in a follow-on milestone | Gap clustering analysis produces 7 candidate backlog phases; format modeled on existing ROADMAP.md entries |
</phase_requirements>

---

## Summary

Phase 115 synthesizes three completed audit tracks into a single gap report with a prioritized execution backlog. This is a pure document-authoring phase: the planner's job is to write two markdown files (`.planning/GAP-REPORT.md` and the execution backlog, either as a section of GAP-REPORT.md or as a companion `.planning/BACKLOG.md`) based on source material that is already complete and fully read.

The three input sources contain 31 UX gaps (G-114-001..031), 46 audited races with 81 candidates across coverage dimensions (stances, quotes, photos, bios), and a 10-dimension benchmark matrix with explicit intentional-omissions classification. The synthesis task is classification and clustering, not new discovery — except for cross-cutting patterns (D-07) and benchmark-derived gaps (D-06) that emerge from the combination.

The most important planning insight is that the work divides into two conceptually distinct tasks: (1) writing the GAP-REPORT.md document that classifies and structures all existing findings, and (2) writing the BACKLOG.md execution plan that clusters those gaps into ROADMAP-ready phases for v2026.4.4. These can be a single plan or two plans. Given that the tiering logic (D-01/D-02/D-03) must be applied before backlog clustering is possible, two sequential plans is the natural structure.

**Primary recommendation:** Two plans — Plan 115-01 writes GAP-REPORT.md (tiering + intentional omissions), Plan 115-02 writes the execution backlog. Both are markdown-only, no code.

---

## Input Inventory

All source files have been read. Findings below are [VERIFIED: direct file read].

### UX Gaps (G-114-001..031)
[VERIFIED: .planning/research/ux-walkthrough/GAPS.md]

**31 total gaps across 5 apps.**

| By severity | Count | Tier 1 candidates (D-01) |
|-------------|-------|--------------------------|
| blocker | 8 | All 8 |
| confusing | 17 | Only if data gap with race coverage impact |
| minor | 6 | None by default |

**The 8 blockers:**
| ID | App | Description |
|----|-----|-------------|
| G-114-003 | essentials | Default Representatives tab hides primary challengers |
| G-114-006 | essentials | Profile page shows wrong election date "May 4, 2026" |
| G-114-010 | essentials | 4 of May 5 candidates are DB stubs with empty profile pages |
| G-114-012 | compass | Primary challengers absent from Compass compare picker |
| G-114-016 | read-rank | Both location filter mechanisms are non-functional |
| G-114-018 | read-rank | IN-9 D primary challengers and county-race candidates have zero quotes |
| G-114-026 | cross-app | SiteHeader Treasury/Badges nav links point to retired Netlify URL |
| G-114-029 | cross-app | Read & Rank verdict badges absent from politician profile (10 quotes in DB) |

**Confusing gaps that have data-type with race coverage impact (Tier 1 elevatable per D-01):**
| ID | Severity | Type | Notes |
|----|----------|------|-------|
| G-114-007 | confusing | data | Pierce has no bio (contested D-61 race) |
| G-114-009 | confusing | data | Young has no headshot (contested D-61 race) |

**Minor gaps (all default Tier 2):** G-114-002, G-114-015, G-114-020, G-114-023, G-114-024, G-114-025

### Data Audit Findings (AUDIT-REPORT-112.md)
[VERIFIED: .planning/research/AUDIT-REPORT-112.md]

**Summary metrics:**
| Metric | Value |
|--------|-------|
| Total candidates | 81 (51 linked, 30 stubs) |
| Stance coverage | 5/51 linked candidates (9.8%) |
| Quote coverage | 4/51 linked candidates (7.8%) |
| Photo coverage | 19 cdn, 62 none (23.5%) |
| Bio coverage | 0/51 (0%) |
| Avg contacts/candidate | 1.2 |

**Candidates with stance data (5/51):** Houchin (80.8%), Pierce (73.1%), Young (57.7%), Deckard (38.5%), Henry (34.6%). All others 0%.

**Candidates with quote data (4/51):** Henry (22), Deckard (16), Pierce (10), Young (6). All others 0.

**30 stub candidates (no politician record, no content possible):** Includes Benjamin T. Arrington, Bob Nyquist, Joe Davis, Tanner Dale Branham, Julie M. Hays, Tree Martin Lucas — the full list of contested county-race candidates.

**Key data audit finding not fully surfaced in UX walkthrough:** 0/51 linked candidates have bios. The UX walkthrough observed Pierce's missing bio (G-114-007) but the audit confirms this is an app-wide problem, not a single-candidate gap.

### Benchmark Matrix (MATRIX.md)
[VERIFIED: .planning/research/benchmark/MATRIX.md]

**Core-10 scores:** EV 15/30 (tied with Ballotpedia; leads BallotReady 3 and Vote411 9; trails VoteSmart 19).

**EV's non-intentional gaps, per MATRIX.md "EV Gap Classification for Phase 115" section:**
1. Dim 3 — Candidate bio (EV=0 vs VoteSmart/Ballotpedia=3) — highest priority
2. Dim 7 — Legislative record surfacing (EV=2 vs VoteSmart=3) — data exists, UI surface incomplete
3. Dim 2 — Candidate photos (EV=1 vs Ballotpedia=2) — 77% missing
4. Dim 5 — Stance coverage (EV=1) — feature works, only 5/51 covered
5. Dim 6 — Candidate quotes (EV=1) — 4/51 covered
6. E4 — No candidate-response Q&A product (EV=0 vs Vote411=2, VoteSmart=3, Ballotpedia=3)
7. E5 — No withdrawn candidate tracking (EV=0 vs Ballotpedia=3)
8. County Council D1→D4 geofence binding bug (Dim 1 evidence)
9. Rural address geocoding failure (Mt Tabor Rd)

---

## Tiering Analysis

[VERIFIED: applying D-01, D-02, D-03 rules from CONTEXT.md to the source data above]

### Tier 1 Determination Logic

Step 1: All blockers are Tier 1 candidates.
Step 2: Apply D-02 feasibility ceiling — can it plausibly land in prod by May 1?
Step 3: For data/confusing gaps, check race coverage impact per D-01.

**Feasibility assessment (18 days until May 1 cutoff from research date):**

| Gap | Type | Feasibility by May 1 | Rationale |
|-----|------|----------------------|-----------|
| G-114-006 (wrong date "May 4") | content | S — hours | Single string/date fix, probably 1 line of code |
| G-114-026 (broken nav links) | feature | S — hours | URL string update in ev-ui SiteHeader, auto-bump pipeline |
| G-114-003 (wrong default tab) | ux-friction | S — hours | Tab default logic change in essentials Results |
| G-114-029 (verdict badges missing) | feature | M — 1-3 plans | Requires debugging PoliticianProfile.jsx component rendering |
| G-114-016 (broken location filter) | feature | M — 1-3 plans | Location filter is read-rank-specific, needs geocoding wiring |
| G-114-010 (stub profiles) | data | L — 3+ plans | Requires creating politician records + data import for 30 stubs |
| G-114-012 (challengers missing from Compass) | data | L — same root cause as G-114-010 | Challenger stance data requires politician records first |
| G-114-018 (zero quotes for challengers) | data | L — same root cause as G-114-010 | Quote import requires politician records first |

**Note on G-114-010 / G-114-012 / G-114-018 as a cluster:** These three blockers share the same root cause — 30 stub candidates have no politician records, making data import impossible. A single "stub resolution" phase would close all three. Whether this can land by May 1 depends on data availability for county-level candidates. This is the critical feasibility question for the planner (see Open Questions below).

### Preliminary Tier 1 List

**Definite Tier 1 (feasible + blocker/high-impact confusing):**
- G-114-006 — Wrong election date
- G-114-026 — Broken SiteHeader nav links
- G-114-003 — Wrong default tab hides challengers
- G-114-029 — Verdict badges missing from profile
- G-114-007 — Pierce bio missing (confusing data, contested race)
- G-114-009 — Young headshot missing (confusing data, contested race)

**Tier 1 conditional on May 1 feasibility (needs data import work):**
- G-114-010 + G-114-012 + G-114-018 — Stub resolution + data import cluster
- G-114-016 — Read & Rank location filter

**Definite Tier 2:**
- All minor gaps (G-114-002, G-114-015, G-114-020, G-114-023, G-114-024, G-114-025)
- Most confusing gaps without data/race-coverage impact
- Benchmark-derived feature gaps (Q&A product, withdrawn candidate tracking)
- Data audit rows with no UX counterpart

---

## Cross-Cutting Patterns (D-07 analysis)

[ASSUMED] Pattern identification is based on the research reading of source material — the planner should verify these observations during authoring.

These patterns emerge from overlaying G-114-* entries with AUDIT-REPORT-112 rows:

### PATTERN-001: Challenger Data Desert
**Root cause:** 30 stub candidates have no politician records in the DB. This single root cause explains G-114-010 (empty Essentials profiles), G-114-012 (challengers absent from Compass picker), and G-114-018 (zero quotes for challengers). All three apps fail at the same contested races (County Prosecutor, County Clerk, County Assessor) because the underlying politician records don't exist.

**Constituent gaps:** G-114-010, G-114-012, G-114-018, AUDIT-02 rows for stub candidates, AUDIT-03 stub rows, AUDIT-04 stub rows

**Benchmark context:** MATRIX.md Dim 3 (bio=0), Dim 5 (stances 5/51), Dim 6 (quotes 4/51) all trace to this same missing-records problem at the stub layer.

### PATTERN-002: Cross-App Loop Broken
**Root cause:** The voter journey Compass → Read & Rank → Essentials is architecturally implemented but broken at multiple integration points in production. G-114-028 (CompassCard doesn't show existing calibration), G-114-029 (verdict badges missing), G-114-030 (no "View profile" from Compass picker), G-114-031 (no Essentials→Treasury handoff) all represent the same category: cross-app CTAs and state relay that were built but either regressed or were never surfaced to guests.

**Constituent gaps:** G-114-027, G-114-028, G-114-029, G-114-030, G-114-031

### PATTERN-003: App-Wide Bio Gap
**Root cause:** 0/51 linked candidates have bio text. The UX walkthrough caught Pierce's missing bio (G-114-007) but the audit confirms it is universal — every profile renders a generic chamber description instead of a personal biography. MATRIX.md Dim 3 (EV=0, competitor max=3) makes this EV's largest non-intentional gap against the competitive set.

**Constituent gaps:** G-114-007, AUDIT-06 rows for all 51 linked candidates, MATRIX.md Dim 3 score

### Potential benchmark-derived gap (D-06 check):

The MATRIX.md identifies County Council D1→D4 geofence binding bug as a "concrete, falsifiable miss" (Dim 1 evidence note) — the Kirkwood voter sees County Council District 4 when they are in District 1. AUDIT-REPORT-112 does not have a dedicated audit row for this, but the race coverage table shows CC D1 linked to geofence (Y) yet the benchmark run observed the wrong district returned. This qualifies as a benchmark-derived gap per D-06 (evidenced by MATRIX.md Dim 1 footnote + implicitly in AUDIT-01 race table). **Recommend creating PATTERN-004 or a standalone gap entry for the CC D1→D4 geofence bug.**

---

## Intentional Omissions Content

[VERIFIED: .planning/research/ux-walkthrough/METHODOLOGY.md §8 and .planning/research/benchmark/MATRIX.md "Intentional omissions" section]

The following content is pre-prepared for the GAP-REPORT.md Intentional Omissions section:

**From UX walkthrough METHODOLOGY.md §8:**
- Missing party labels (D / R / I) on candidate cards, search results, or profile pages — intentional per EV's antipartisan principle
- Missing endorsement lists (newspaper endorsements, political committee endorsements, advocacy-group endorsements) — intentional
- Missing interest-group ratings (NRA scores, Sierra Club scores, Chamber of Commerce ratings, any third-party advocacy scorecard) — intentional

**From MATRIX.md "EV Gap Classification for Phase 115 — Intentional omissions":**
- E1 — Interest-group ratings / scorecards (VoteSmart=3): deliberately omitted
- E2 — Explicit endorsements aggregation (Ballotpedia=3, VoteSmart=2): deliberately omitted
- E3 — Third-party partisan race ratings (Ballotpedia=3): deliberately omitted
- Donor / fundraising breakdowns: deliberately omitted; EV ships raw FEC total only
- Party labels on sitting-official cards (Vote411, VoteSmart, Ballotpedia all have these): deliberately omitted. Party labels appear only on Elections tab race-group headers as a structural necessity for closed-primary display

**From PROJECT.md "Out of Scope":**
- Party affiliation display — antipartisan by design — intentional omission
- Interest group ratings — embeds partisan framing
- Endorsement tracking — heavily partisan signal for local races

These three sources should all be cited in the Intentional Omissions section to give it maximum authority against future contributors.

---

## Architecture Patterns

### Recommended File Structure

```
.planning/
├── GAP-REPORT.md          # Primary output — tiered gap report + intentional omissions
└── BACKLOG.md             # Execution backlog — ROADMAP-ready phase entries for v2026.4.4
```

OR (if Claude's discretion chooses single-file approach):

```
.planning/
└── GAP-REPORT.md          # Combined — tiered gaps + intentional omissions + backlog
```

**Recommendation (Claude's discretion):** Two files. GAP-REPORT.md is the audit artifact (classification of what exists). BACKLOG.md is the planning artifact (what to do next). They serve different audiences and update cadences. Keeping them separate avoids a massive single file that is hard to navigate.

### GAP-REPORT.md Recommended Structure

```markdown
# Gap Report — Monroe County IN Primary Readiness (v2026.4.3)

## Executive Summary
## Tier 1 Summary (before May 1)
## Tier 2 Summary (future)

## Section 1: UX Gaps (G-114-001..031)
  ### Tier 1
  ### Tier 2

## Section 2: Data Audit Findings (AUDIT-REPORT-112)
  ### Tier 1
  ### Tier 2

## Section 3: Cross-Cutting Patterns (PATTERN-NNN)
  ### Tier 1
  ### Tier 2

## Intentional Omissions
  (antipartisan choices — NOT gaps)

## Methodology Notes
  (tiering criteria applied, source traceability)
```

**Layout decision (Claude's discretion):** Tier 1 / Tier 2 as sub-sections within each source-section (rather than top-level Tier 1 / Tier 2 blocks). Rationale: source traceability is more important for this report than tier grouping — the reader needs to trace a gap back to G-114-NNN or AUDIT-112 row quickly. Tier can be a badge/label on each entry. The executive summary provides the tier-sorted view.

### BACKLOG.md Recommended Structure

```markdown
# Execution Backlog — v2026.4.4

## Tier 1 Phases (target: shipped by May 1, 2026)

### Phase NNN: [Name]
**Goal:** ...
**Gaps closed:** G-114-NNN, PATTERN-NNN
**Effort:** S | M | L
**Depends on:** Phase NNN (if any)

## Tier 2 Phases (future milestone)
...
```

This mirrors the ROADMAP.md phase detail format [VERIFIED: .planning/ROADMAP.md structure].

### Effort Sizing Guidance

Based on the gap analysis:

| S (few hours) | M (1-3 plans) | L (3+ plans) |
|---------------|---------------|--------------|
| G-114-006 date fix | G-114-029 verdict badges | Stub resolution + data import (PATTERN-001) |
| G-114-026 nav links | G-114-016 location filter | Bio authoring for linked candidates |
| G-114-003 default tab | G-114-011 Compass geo-filter | Township geofences |
| G-114-020 page title | G-114-013 onboarding tour timing | CC D1→D4 geofence bug |
| G-114-002 ALLCAPS | Cross-app CompassCard state relay | |

---

## Gap Clustering for Backlog

Based on root-cause analysis, these gap clusters map to natural ROADMAP-ready phases:

**Cluster 1: Quick Correctness Fixes (S)**
Fixes: G-114-006 (wrong date), G-114-026 (broken links), G-114-003 (default tab), G-114-020 (page title), G-114-002 (ALLCAPS).
One phase, hours of work.

**Cluster 2: Read & Rank Repair (M)**
Fixes: G-114-016 (location filter), G-114-017 (candidate navigation), G-114-019 (dead CTA), plus Read & Rank integration wiring back to Essentials.

**Cluster 3: Candidate Stub Resolution + Data Import (L)**
Fixes: PATTERN-001 (G-114-010, G-114-012, G-114-018). Creates politician records for 30 stubs, imports minimum data. This is the highest-impact Tier 1 cluster.

**Cluster 4: Cross-App Loop Repair (M)**
Fixes: PATTERN-002 (G-114-028, G-114-029, G-114-030, G-114-031). Verdict badges, CompassCard state, Compass→Essentials links.

**Cluster 5: Photo Coverage Expansion (M)**
Fixes: G-114-009 (Young headshot), broader photo coverage for 30 linked candidates with no photo (62 total missing). Extends the headshot scraping pipeline from v2026.4.1.

**Cluster 6: Bio Authoring for Key Contested Candidates (M)**
Fixes: G-114-007 (Pierce bio), PATTERN-003 elevation for contested races. Scope-limited to the 5-10 candidates in contested May 5 races rather than all 51.

**Cluster 7: Geofence Hardening (M, Tier 2)**
Fixes: County Council D1→D4 binding bug, rural address geocoding, township geofences.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Tiering judgment table | Custom scoring algorithm | Apply D-01/D-02/D-03 rules mechanically from CONTEXT.md |
| Backlog phase numbering | Skip-based numbering | Continue from Phase 116 in sequence |
| Intentional omissions list | New antipartisan policy | Copy verbatim from METHODOLOGY.md §8 and MATRIX.md |
| Gap IDs for patterns | New NNN sequences | Use PATTERN-NNN as specified in D-07 |

---

## Common Pitfalls

### Pitfall 1: Treating benchmark-derived features as gaps
**What goes wrong:** The planner lists "no candidate Q&A product (E4)" as a Tier 1 gap because competitors score 2-3.
**Why it happens:** MATRIX.md has a separate "non-intentional gaps" section that doesn't distinguish feasibility from desirability.
**How to avoid:** Apply D-02 feasibility ceiling. A new Q&A product cannot ship by May 1. All benchmark-derived product feature gaps (E4, E5) are Tier 2.
**Warning signs:** Any backlog phase for a feature that doesn't exist yet is almost certainly Tier 2.

### Pitfall 2: Losing source traceability
**What goes wrong:** GAP-REPORT.md entries describe gaps in new language without citing G-114-NNN or AUDIT-112 row names.
**Why it happens:** Synthesis tempts paraphrasing. D-04 says preserve original IDs.
**How to avoid:** Every entry in Section 1 must cite a G-114-NNN ID. Every entry in Section 2 must cite the AUDIT-REPORT-112 section (e.g., AUDIT-03, AUDIT-05) and the specific candidate row where relevant.

### Pitfall 3: Missing the PATTERN-001 feasibility question
**What goes wrong:** The planner marks the stub resolution cluster as Tier 1 blocker without addressing whether data for 30 county-level candidates can be sourced before May 1.
**Why it happens:** G-114-010 is severity=blocker so it auto-promotes to Tier 1 candidate. But D-02 says feasibility applies after severity screening.
**How to avoid:** The gap report should note the feasibility uncertainty for PATTERN-001 explicitly. The backlog entry for stub resolution should state the data-sourcing dependency.

### Pitfall 4: Omitting the intentional omissions section
**What goes wrong:** The final GAP-REPORT.md focuses only on gaps and omits the antipartisan context.
**Why it happens:** It feels like a separate document.
**How to avoid:** D-10 is a locked decision — the section is mandatory. Without it, future contributors in v2026.4.4 may re-file "no party labels" as a gap.

### Pitfall 5: Creating a bloated backlog
**What goes wrong:** Every gap gets its own phase entry in BACKLOG.md.
**Why it happens:** 1-to-1 mapping feels precise.
**How to avoid:** Gaps should be clustered by root cause and implementation affinity (per the gap clustering section above). 7 phases is approximately right — more than 10 Tier 1+2 phases would likely represent over-splitting.

---

## Code Examples

No code is produced in this phase. The "code" is the markdown document structure.

### Example GAP-REPORT.md gap entry (for planner reference)

```markdown
### G-114-006 — Profile page shows wrong election date "May 4, 2026"
- **Tier:** 1
- **App:** essentials
- **Severity:** blocker
- **Type:** content
- **Source:** G-114-006 (Phase 114 UX Walkthrough)
- **Evidence:** screenshots/essentials/05-pierce-profile.png — confirmed on 3 separate profiles
- **Benchmark context:** n/a (not a dimension in MATRIX.md Core-10)
- **Fix:** Correct date string in candidate profile template; Indiana primary is May 5, not May 4.
```

### Example BACKLOG.md phase entry (for planner reference — matching ROADMAP.md format)

```markdown
### Phase 116: Quick Correctness Fixes
**Goal**: Correct high-visibility factual errors and broken navigation that a voter would notice immediately — wrong election date, broken header links, wrong default tab.
**Gaps closed:** G-114-006, G-114-026, G-114-003, G-114-020, G-114-002
**Effort:** S
**Depends on:** None
```

---

## State of the Art

| Old understanding | Current finding | Impact |
|-------------------|-----------------|--------|
| "EV has photo gaps for challengers" | 0/51 linked candidates have bios (universal, not just challengers) | Bio gap is larger than photo gap — re-priorities Tier 1 scope |
| "Read & Rank verdict bridge was shipped v2026.3.4" | Verdict badges confirmed absent from production profile (G-114-029) | Shipped ≠ working in prod; needs debugging not new feature work |
| "SiteHeader nav links were updated v2026.3.5" | SiteHeader still links to retired Netlify URL for Treasury/Badges (G-114-026) | Either v2026.3.5 didn't deploy, or a later ev-ui bump reverted it |

---

## Open Questions

1. **Stub resolution data sourcing**
   - What we know: 30 candidates are stubs with no politician records. PATTERN-001 covers the most contested county races.
   - What's unclear: Can minimum data (name, office, photo, 1-line bio) be sourced for Arrington, Oliphant, Nyquist, Sharp, Branham, Davis, Lucas, Hays, and the other stubs before May 1? What are the public record sources?
   - Recommendation: The backlog phase for stub resolution should include a data-sourcing sub-task. The planner should note this dependency explicitly in the backlog entry rather than treating it as a code-only task.

2. **G-114-029 verdict badges — regression or never shipped?**
   - What we know: 10 Pierce quotes confirmed in DB per AUDIT-04. PoliticianProfile.jsx is documented to render verdict badges per CLAUDE.md. Production profile shows no badges.
   - What's unclear: Is this a CSS/render regression, a feature flag, or a component prop wiring issue? No code was examined during this research phase.
   - Recommendation: The backlog phase entry for cross-app loop repair should include a code-investigation step before implementation.

3. **G-114-026 SiteHeader link — why did it regress?**
   - What we know: CLAUDE.md PROJECT.md confirms `SiteHeader nav links updated to production .empowered.vote URLs (ev-ui v0.1.49) — v2026.3.5`. Production still shows retired Netlify URL.
   - What's unclear: Was ev-ui reverted? Did a consumer not pick up the bump? Is there a hardcoded fallback?
   - Recommendation: Investigate ev-ui published version in each consumer before writing the fix plan. The auto-bump pipeline should handle re-fix without major effort.

4. **Single-file vs two-file output**
   - What we know: CONTEXT.md specifies GAP-REPORT.md as the primary output; the backlog can be a section or companion BACKLOG.md per Claude's discretion.
   - Recommendation: Two files. GAP-REPORT.md for audit artifact, BACKLOG.md for planning artifact. Easier for downstream v2026.4.4 roadmap work to extract phases from BACKLOG.md without parsing the full gap report.

---

## Validation Architecture

> nyquist_validation is not explicitly set to false in config.json — treating as enabled. However, this phase produces markdown documents only. There are no automated tests possible against markdown content.

**Test framework:** Not applicable — markdown-only output.

**Manual verification criteria (Phase gate):**
- [ ] Every G-114-NNN (1..031) appears in GAP-REPORT.md with a Tier assignment
- [ ] Every entry in Section 1 cites its original G-114-NNN ID
- [ ] Intentional omissions section is present and cites METHODOLOGY.md §8 and MATRIX.md
- [ ] Every BACKLOG.md phase entry has: name, goal, gaps-closed, S/M/L effort, depends-on
- [ ] No benchmark-derived features appear as Tier 1 (feasibility check)
- [ ] PATTERN-NNN entries each cite their constituent gap IDs

---

## Environment Availability

Step 2.6: SKIPPED — this phase produces markdown documents only with no external dependencies beyond reading existing files in `.planning/research/`.

---

## Security Domain

Not applicable. This phase produces planning documents only — no code, no DB, no API routes.

---

## Sources

### Primary (HIGH confidence)
- `.planning/research/ux-walkthrough/GAPS.md` — all 31 gap entries G-114-001..031 read and catalogued
- `.planning/research/ux-walkthrough/METHODOLOGY.md` — severity/type definitions, intentional omissions §8
- `.planning/research/AUDIT-REPORT-112.md` — full candidate/stance/quote/photo/bio audit data read
- `.planning/research/benchmark/MATRIX.md` — Core-10 scores, EV gap classification, intentional omissions list
- `.planning/research/BALLOT-BASELINE-2026-05-05.md` — authoritative race/candidate denominator
- `.planning/phases/115-gap-report-synthesis/115-CONTEXT.md` — locked decisions D-01..D-10
- `.planning/REQUIREMENTS.md` — GAP-01, GAP-02, GAP-03 definitions
- `.planning/PROJECT.md` — antipartisan principle and out-of-scope list
- `.planning/ROADMAP.md` — existing ROADMAP phase entry format for backlog modeling

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — project context, pending todos (12 politicians with no quotes noted)

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PATTERN-001, PATTERN-002, PATTERN-003, PATTERN-004 are the right cluster boundaries | Cross-Cutting Patterns | Planner may find additional patterns or choose different clustering during authoring — low risk, patterns are illustrative not binding |
| A2 | Two-file output (GAP-REPORT.md + BACKLOG.md) is better than single file | Architecture Patterns | If planner prefers single file, the structure still works — preference only |
| A3 | 7 backlog phases is approximately right for gap clustering | Gap Clustering | Planner should adjust based on actual gap grouping during authoring |

---

## Metadata

**Confidence breakdown:**
- Input inventory: HIGH — all source files read directly
- Tiering analysis: HIGH — D-01/D-02/D-03 rules applied mechanically to verified data
- Pattern identification: MEDIUM — patterns are inferred from data; planner should verify during authoring
- Backlog clustering: MEDIUM — effort sizing is approximate; actual plans determine final sizing

**Research date:** 2026-04-13
**Valid until:** 2026-05-01 (Tier 1 cutoff date; after that, Tier classification is moot)
