# Competitive Benchmarking Methodology — Empowered Vote vs BallotReady / Vote411 / VoteSmart / Ballotpedia

**Run date:** 2026-04-12
**Phase:** 113-competitive-benchmarking
**Purpose:** Lock the fairness ruler BEFORE any scoring happens. Per D-10/D-11, this document is the fairness mechanism — there is no separate peer-review checkpoint. Every cell scored in plans 02–07 must trace back to the rules defined here.

---

## 1. Addresses Used

### Primary address (full matrix scoring)

- **`200 W Kirkwood Ave, Bloomington, IN 47404`**
- Rationale: this is the same address used for the Phase 112 geofence smoke test and is the anchor for `BALLOT-BASELINE-2026-05-05.md`. Reusing it guarantees apples-to-apples scoring — any divergence between competitors and EV is attributable to the product, not to input variance.
- **All five subjects (EV + 4 competitors) are scored on the full matrix using ONLY this address.**

### Secondary addresses (precinct precision subsection only — NOT scored on the full matrix)

Secondary addresses exist solely to verify whether each competitor correctly changes its district-specific race list when the address moves across a known district boundary. They are used only inside each per-competitor file's "Precinct Precision" subsection.

- **Secondary #1 — rural Benton Township (Indiana State House District 46/60 boundary test)**
  - Address: `7333 W Mt Tabor Rd, Bloomington, IN 47404`
  - Justification: Mt Tabor Rd runs through Benton Township in rural western Monroe County. This address sits in Benton Twp on the opposite side of the State House District 46/60 line from downtown Bloomington (Kirkwood is in HD 61/62). A correctly geofenced product MUST surface a different State House race for this address than for the primary.

- **Secondary #2 — opposite side of the Indiana State House District 61/62 boundary from Kirkwood**
  - Address: `2700 E Covenanter Dr, Bloomington, IN 47401`
  - Justification: Covenanter Dr is in southeastern Bloomington. The HD 61/62 line cuts through Bloomington roughly along a north-south axis; 200 W Kirkwood (downtown west) and 2700 E Covenanter (southeast) sit on opposite sides of that boundary. A correctly geofenced product MUST surface a different State House district race for this address than for the primary.

> **Secondary addresses are NOT used for full matrix scoring. They exist only to verify whether each competitor correctly changes its district-specific race list when the address moves across a district boundary.**

---

## 2. Scoring Rubric (0–3 depth scale)

Per D-05, each matrix cell is scored on a 0–3 depth scale. Binary Y/N was explicitly rejected because it hides depth differences that matter for this benchmark.

| Score      | Meaning                                                                 |
| ---------- | ----------------------------------------------------------------------- |
| `0`        | **Absent** — field/feature not present at all. (`0 = absent`)           |
| `1`        | **Minimal / token** — present but shallow (e.g. name only, no bio/photo). |
| `2`        | **Present and usable** — substantive enough for a voter to act on.       |
| `3`        | **Comprehensive** — full depth (e.g. bio + sourced quotes + legislative record + photo + contact). |
| `blocked`  | **Distinct from 0.** Used when a signup wall, captcha, paywall, or region gate prevented measurement. **Blockers MUST NOT be scored as `0`.** See §5. |

Every scored cell also carries a short evidence note citing the screenshot or URL the score came from.

### Worked example — "Candidate photo" for BallotReady at 200 W Kirkwood Ave

- If every candidate card on BallotReady's Bloomington 47404 results page shows a high-resolution headshot → **3**
- If most cards show headshots but several render placeholder silhouettes → **2**
- If only a minority of candidates show any image → **1**
- If no images render at all → **0**
- If access to BallotReady's Monroe County race list was blocked behind signup/captcha/region gate → **`blocked`** (with note naming the blocker and a human-fallback instruction)

The same worked-example logic applies to every dimension and every subject. The rubric does not change between subjects.

---

## 3. Locked Core Dimensions (the 10-row ruler)

These 10 dimensions are locked. Plans 02–07 score every subject (EV + BallotReady + Vote411 + VoteSmart + Ballotpedia) against the same 10 rows, in the same order, using the same rubric. This is the D-04 core list.

| #  | Dimension                                                                                                       |
| -- | --------------------------------------------------------------------------------------------------------------- |
| 1  | **Race coverage vs baseline** — ratio of `BALLOT-BASELINE-2026-05-05.md` races surfaced for the primary address |
| 2  | **Candidate photo** — presence and quality of candidate headshots                                               |
| 3  | **Candidate bio / biography prose** — substantive biographical narrative                                        |
| 4  | **Candidate contact info** — email, phone, website, mailing address                                             |
| 5  | **Stance / issue position data** — structured issue positions / policy stances                                  |
| 6  | **Candidate quotes / Q&A / direct statements** — sourced verbatim statements from the candidate                 |
| 7  | **Legislative record** — votes, bills, committee memberships (for sitting officials)                            |
| 8  | **Geofence / address precision** — does moving the address change the race list correctly? (uses §1 secondaries) |
| 9  | **Data freshness** — last-updated signals; how old the newest candidate record is                               |
| 10 | **Antipartisan framing** — absence of party labels, endorsements, interest-group ratings (INVERTED — higher score = MORE antipartisan) |

> Up to 5 derived-extra dimensions may be added during execution (plan 07) if a competitor surfaces a feature outside this core 10. Derived extras are noted as such in the matrix and do NOT replace any of the locked rows above.

**Dimension 10 inversion note:** Antipartisan framing is the only inverted dimension. A subject that loudly displays party labels, endorsement lists, and interest-group ratings scores **0**. A subject that displays none of these scores **3**. This inversion is intentional and aligns with EV's antipartisan principle (see §6 and `PROJECT.md`).

---

## 4. Race-Count Denominator

Race-coverage scoring (Dimension 1) and per-competitor race/candidate count tables use **`.planning/research/BALLOT-BASELINE-2026-05-05.md`** as the authoritative denominator. That file enumerates approximately 43 race slots for the Monroe County May 5, 2026 primary and is the single source of truth for "how many races SHOULD this address see." A competitor surfacing 20 of those slots scores differently than one surfacing 43, regardless of how visually polished the result page is.

---

## 5. Blocker Handling

Per D-02: any **signup wall, captcha, paywall, region gate, or geo-block** that prevents Claude (via Playwright MCP) from reaching the candidate-level data is logged as **`blocked`** in that cell — never silently treated as `0`.

Each `blocked` entry MUST include:

1. The exact blocker encountered (e.g. "BallotReady requires email signup before showing race list").
2. A human-fallback instruction telling the user precisely what to do manually (URL, form values, what to screenshot, what to paste back).
3. A note distinguishing **product gap** ("the data is genuinely missing") from **access gap** ("the data may exist but we couldn't measure it").

Blockers are tallied in the final report as a separate category — they are NOT counted as zeros against the blocked subject.

---

## 6. EV's Intentional Omissions (NOT gaps)

Per `PROJECT.md` and the antipartisan principle, EV deliberately does NOT do the following. These are NOT gaps to be scored against EV — they are intentional product decisions and EV's column should reflect them as intentional omissions, not as missing features:

- **No party labels** in the UI (no "(D)" / "(R)" / "(I)" tags on candidate cards)
- **No endorsements** (no labor / advocacy / newspaper endorsement lists)
- **No interest-group ratings** (no NRA / Sierra Club / NARAL / ACU scorecards)
- **No donor / fundraising summaries** (no FEC dollar totals on profile pages)
- **No partisan color associations** (no red/blue overlays)

For Dimension 10 (Antipartisan framing), EV's expected score is **3** because it intentionally omits all of the above. Competitors that prominently feature party labels, endorsement lists, or interest-group ratings will score lower on this dimension by design.

These omissions are documented here so that downstream scoring in plans 02–07 does not mis-score them as absences on Dimensions 4 (contact info), 5 (stances), or 6 (quotes). Specifically: a candidate's stance and quote data may be present in EV without any associated party label or endorsement, and that is the intended state.

---

## 7. Self-Audit Stance

Per D-10.5:

> **EV is scored on the same sheet as competitors, using the same 0–3 rubric. EV's column is not privileged. If EV lacks something a competitor has on a non-omitted dimension, EV scores 0 or 1 just like any competitor.**

The only exception to "same ruler" treatment is the antipartisan-omission carve-out in §6 — and that carve-out only applies to features EV intentionally does NOT build, not to features EV is simply missing. If a competitor has candidate bios and EV does not, EV's bio cell scores 0 or 1 the same as any other subject. The Phase 112 audit (`AUDIT-REPORT-112.md`) is the source for EV's measured coverage (5/51 stances, 4/51 quotes, 19/81 headshots, 0/51 bios) and feeds directly into EV's column scoring.

The honest comparison is the point. If EV scores poorly against competitors on a dimension the antipartisan principle does not exempt, that finding belongs in the gap report (Phase 115), not hidden under a privileged column.

---

## 8. Decision Trace

This methodology implements decisions D-01 through D-11 from `113-CONTEXT.md` literally:

- **D-01** Hybrid Playwright-first with human fallback → §5
- **D-02** Blockers logged as `blocked`, never as `0` → §5
- **D-03** Four evidence types per competitor (screenshots, field inventory, race/candidate count table, narrative notes) → enforced in plans 02–06
- **D-04** Predefined core dimensions + up to 5 derived extras → §3
- **D-05** 0–3 depth scale (binary Y/N rejected) → §2
- **D-06 / D-07** Output co-located in `.planning/research/benchmark/` → file layout
- **D-08** Primary address = 200 W Kirkwood Ave → §1
- **D-09** 2 secondary addresses for precinct precision only → §1
- **D-10** METHODOLOGY.md written BEFORE scoring; opens the benchmark output → this file
- **D-10.5** Self-audit stance — EV not privileged → §7
- **D-11** No separate peer-review checkpoint — methodology IS the fairness mechanism → §0 (purpose)
