---
phase: 113-competitive-benchmarking
plan: 07
subsystem: research/benchmark
tags: [benchmarking, synthesis, matrix, competitive-analysis]
dependency_graph:
  requires: [113-01, 113-02, 113-03, 113-04, 113-05, 113-06]
  provides: [MATRIX.md, matrix.csv, EV-gap-classification]
  affects: [115-gap-report-synthesis]
tech_stack:
  added: []
  patterns: [markdown-csv-pairing, evidence-footnoted-scoring, long-form-normalized-csv]
key_files:
  created: []
  modified:
    - .planning/research/benchmark/MATRIX.md
    - .planning/research/benchmark/matrix.csv
decisions:
  - "matrix.csv regenerated as long-form normalized table (subject,dimension,score,evidence_file) rather than wide-form mirror — easier for Phase 115 to filter and aggregate"
  - "EV intentional omissions on derived extras E1/E2/E3 recorded as 'intentional' literal string in CSV, not as 0, to preserve METHODOLOGY §6/§7 carve-out through downstream synthesis"
  - "Per-cell evidence footnotes use numeric references in MATRIX.md (1-42) rather than inline parentheticals, to keep the scoring table readable at table width"
  - "County Council D1→D4 geofence miss explicitly separated from 'coverage gap' — it is a falsifiable precision bug, logged as Phase 115 bug candidate rather than lumped into Dim 1 coverage failure"
metrics:
  duration: "~25 min"
  tasks_completed: 2
  files_modified: 2
  completed: "2026-04-12"
requirements: [BENCH-05, BENCH-06]
---

# Phase 113 Plan 07: MATRIX Synthesis Summary

One-liner: Merged the 5 per-subject spot-check files into a fully scored MATRIX.md + normalized matrix.csv, populating all 50 core cells + 25 derived-extra rows with 0–3 scores and evidence-file traces, producing the final competitive scoreboard that feeds Phase 115.

---

## Per-subject core-10 totals (out of 30)

| Rank | Subject     | Total | One-line |
| ---- | ----------- | ----- | -------- |
| 1    | VoteSmart   | 19    | Deepest candidate data (bio/contact/stances/legislative = 3s); narrow ballot scope (~21%); maximally partisan-framed |
| 2    | Ballotpedia | 16    | Best-balanced ballot tool + encyclopedic depth; freshest data in the set; partisan-framed while claiming neutrality |
| 3    | **EV**      | **15** | Top-cluster ballot coverage (~93%); uniquely antipartisan (Dim 10 = 3); bio/photo/stance/quote gaps are real |
| 4    | Vote411     | 9     | The "ballot product that works" for Monroe County on the run date; thin candidate-level depth |
| 5    | BallotReady | 3     | Measured product gap (0% ballot coverage); dimension 10 = 3 only because there is no candidate content |

---

## Top 3 dimensions where EV leads (or ties for lead)

1. **Dim 10 — Antipartisan framing: EV=3** (alone at 3 among products with real candidate content; BallotReady also 3 but trivially because it has no content to label). Every competitor with real ballot data scores ≤1 on this dimension.
2. **Dim 1 — Race coverage vs baseline: EV=2, tied with Vote411=2 and Ballotpedia=2** at the top cluster (~93% of the Kirkwood voter's on-ballot races surfaced), ahead of VoteSmart (1) and BallotReady (0).
3. **Dim 7 — Legislative record: EV=2** on federal + state incumbents via Congress.gov + LegiScan wiring, ahead of Vote411 (0), Ballotpedia (1), and BallotReady (0). Only VoteSmart (3) beats EV on this dimension, and EV's data-model already has the surface — see gap #2 below.

Additionally EV owns two derived extras no competitor has:
- **E11 — Compass cross-link from profile** (unique platform feature; issue-alignment tool integration)
- **E12 — Tier-level classification + group filter** (Local/State/Federal toggle; no competitor has this)

---

## Top 3 dimensions where EV lags (non-intentional gaps)

1. **Dim 3 — Candidate bio: EV=0, Ballotpedia=3, VoteSmart=3.** 0/51 linked candidates have bios per AUDIT-REPORT-112. Profiles render a generic chamber description in the bio slot. **Phase 115 priority #1.**
2. **Dim 7 — Legislative record surface (EV=2 vs VoteSmart=3).** EV has the data (`essentials.bills` + `essentials.votes`) but the profile UI only renders summary counts + single example votes, not VoteSmart's 31-page roll-call drill. **Data-model complete, UI surface incomplete — highest-ROI fix.** Also: local-tier (Bolden / county council / township) has zero legislative data.
3. **Dim 2 — Candidate photos: EV=1, Ballotpedia=2.** 19 cdn / 0 local / 62 none across 81 candidates (~23% coverage). Needs challenger photo scraping for the 2026 primary slate.

Additional meaningful lags: Dim 5 (stances, EV=1 vs VoteSmart=3), Dim 6 (quotes, EV=1 vs all others ≥2), E4 (candidate-response Q&A product, EV=0 — no LWV/Political Courage Test/Candidate Connection equivalent).

---

## Baseline race-match rates per competitor (Kirkwood, 14 baseline races)

| Competitor  | Match rate |
| ----------- | ---------- |
| EV          | ~93% (13/14) — with 1 wrong-district miss (County Council D4 shown instead of voter's D1) |
| Vote411     | ~93% (13+/14) — plus 3 superset council district races |
| Ballotpedia | ~79–93% (11–13/14) — varies by drill-depth verification |
| VoteSmart   | ~21% (3/14) — product-scope mismatch (no county / judicial / township primary coverage) |
| BallotReady | 0% (0/14) — empty civic center despite no access blockers |

---

## Derived-extra dimensions added

Primary (cross-subject scoring significance):
- **E1** Interest-group ratings / scorecards — VoteSmart=3, all others 0, EV=intentional
- **E2** Explicit endorsements aggregation — Ballotpedia=3, VoteSmart=2, others 0, EV=intentional
- **E3** Third-party partisan race ratings (Cook / Sabato / DDHQ / Inside Elections) — Ballotpedia=3, others 0, EV=intentional
- **E4** Candidate-response Q&A product (LWV / Political Courage Test / Candidate Connection) — Ballotpedia=3, VoteSmart=3, Vote411=2, BallotReady=0, **EV=0 (non-intentional gap)**
- **E5** Withdrawn / disqualified candidate tracking — Ballotpedia=3, others 0, EV=0

Secondary (single-subject highlights, logged in MATRIX.md for reference):
- E6 BallotReady — voter registration check-and-update (3)
- E7 Vote411 — debates & forums with venue + time (3)
- E8 Vote411 — multilingual support (2)
- E9 VoteSmart — roll-call-vote surface with bill filters (3) — **EV non-intentional data-in-DB-but-not-in-UI gap**
- E10 Ballotpedia — encyclopedic race/district wiki pages (3)
- E11 EV — Compass cross-link (2, unique)
- E12 EV — tier filter (3, unique)

---

## Blocked cells

**None.** Zero `blocked` cells in the 50-cell core matrix. All 5 subjects were reachable without hard access gates:
- BallotReady: `accessible` — product returned no Monroe County data (measured gap, not access gap)
- Vote411: `accessible` — worked fully for primary + d62 secondary; rural Mt Tabor address failed at the Google-Civic geocoder (geocoding gap, not access gap)
- VoteSmart: **`partially blocked`** on ONE dimension only — the interest-group RATINGS tab is behind a soft 3-free-use modal in natural left-to-right navigation flow. Mitigated with fresh browser contexts + direct URLs. Core 10 dimensions were all measured; no `blocked` cell in the matrix.
- Ballotpedia: `accessible` with a discoverability caveat (sblv3 widget is buried) — not a blocker once located
- EV: `accessible` (self-audited)

---

## Editorial asymmetries flagged for Phase 115

1. **"Nonpartisan" has two definitions.** VoteSmart is partisan-by-mission (interest-group disclosure IS the feature) and honest about it. Ballotpedia is partisan-by-feature (party tags + endorsements + Cook/Sabato race ratings) while claiming neutrality in its mission statement. Both score Dim 10 = 0; the editorial self-awareness differs.
2. **Vote411's and EV's party labeling are close in intent but score differently.** Both acknowledge Indiana's closed-primary structure; Vote411 labels individual candidates with party, EV labels only race-group headers on the Elections tab. Score divergence (1 vs 3) reflects surface placement, not fundamentally different editorial posture.
3. **BallotReady's "Coming soon!" is the benchmark's single most informative finding.** 23 days before the May 5 primary, a product branded "Where you go before you vote" cannot show a Monroe County voter their ballot.

---

## EV gap classification (intentional vs non-intentional)

### Intentional omissions (NOT gaps; METHODOLOGY §6 carve-out)

- Interest-group ratings (E1)
- Endorsements aggregation (E2)
- Third-party partisan race ratings (E3)
- Donor / fundraising breakdowns
- Party labels on sitting-official representative cards

### Non-intentional gaps (Phase 115 gap-report candidates, prioritized)

1. **Dim 3 — Candidate bios** (hard 0 vs competitor 3s)
2. **Dim 7 — Roll-call vote UI surface** (data exists in `essentials.votes`, not rendered in profile)
3. **Dim 2 — Candidate photos** (23% coverage)
4. **Dim 5 — Stance coverage** (10% of linked candidates)
5. **Dim 6 — Candidate quotes** (8% of linked candidates; Read & Rank expansion needed)
6. **E4 — Candidate-response Q&A product** (no EV equivalent)
7. **E5 — Withdrawn candidate tracking** (ties into `project_candidates_vs_politicians.md`)
8. **County Council D1→D4 geofence binding bug** (concrete, falsifiable — file as bug)
9. **Rural address geocoding (Mt Tabor)** — shared failure mode with Vote411; Google Places upstream

---

## Deviations from Plan

**None — plan executed exactly as written.** Both tasks completed autonomously without needing any Rule 1/2/3 auto-fixes. No architectural Rule 4 decisions required. No blockers or checkpoints encountered.

Notes on discretionary choices (all within plan-authorized scope):
- matrix.csv was regenerated as long-form normalized rather than as direct wide-form mirror — per plan D-07 "Claude's discretion on whether `matrix.csv` is a direct MATRIX.md mirror or a normalized long-form table."
- EV's intentional omissions on derived extras recorded as the literal string `intentional` in the CSV to preserve the METHODOLOGY §6/§7 carve-out through Phase 115 aggregation. Phase 115 should treat `intentional` as non-scored rather than zero.
- Numeric footnote references (1–42) in MATRIX.md table cells chosen over inline parentheticals for table width readability.

---

## Commits

- `feat(113-07): score MATRIX.md core 10 + race counts + derived extras` — f3455af
- `feat(113-07): regenerate matrix.csv as long-form mirror of MATRIX.md` — 313fc24

---

## Self-Check: PASSED

- `.planning/research/benchmark/MATRIX.md` — FOUND (0 TBD, Race/Count + Derived-Extra + Score Summary sections present, 53 table rows)
- `.planning/research/benchmark/matrix.csv` — FOUND (76 lines; all 5 subjects present; header matches spec)
- Commit f3455af — FOUND
- Commit 313fc24 — FOUND
