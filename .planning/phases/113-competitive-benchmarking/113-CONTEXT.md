# Phase 113: Competitive Benchmarking - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Benchmark EV's Monroe County coverage against BallotReady, Vote411, VoteSmart, and Ballotpedia using a live Bloomington address. Produce a feature comparison matrix scoring EV against all four competitors across ~15 dimensions, with per-competitor race and candidate counts compared directly to the Phase 112 ballot baseline (`BALLOT-BASELINE-2026-05-05.md`). Output is research artifacts only — no code changes, no DB changes, no frontend changes.

</domain>

<decisions>
## Implementation Decisions

### Execution Method
- **D-01:** Hybrid Playwright-first with human fallback. Claude drives `plugin_playwright` against each competitor site, navigates to the Monroe County address lookup, and captures the resulting race/candidate pages. When a site blocks with signup, captcha, paywall, or region gating, Claude writes specific step-by-step human instructions (URL, form values, what to screenshot) and pauses for the user to complete manually and paste findings back.
- **D-02:** Every blocker is logged as a "blocked" row in the matrix, not silently treated as "absent." Distinguishes product gaps from access gaps.

### Evidence Captured Per Competitor
- **D-03:** Four evidence types captured for every competitor:
  1. **Screenshots** — PNG captures of key screens (address entry, race list, candidate profile) stored in `.planning/research/benchmark/screenshots/{competitor}/`.
  2. **Structured field inventory** — machine-readable list of which data fields appear on a candidate profile (name, photo, bio, contact, stances, quotes, legislative record, endorsements, fundraising, etc.). Format: table in the per-competitor markdown file, mirrored into `matrix.csv` where useful.
  3. **Race/candidate count table** — line-by-line comparison of what the competitor shows for Monroe County May 5, 2026 primary vs `BALLOT-BASELINE-2026-05-05.md`. Directly satisfies BENCH-06.
  4. **Narrative notes** — free-form markdown observations on UX quirks, editorial quality, surprises.

### Matrix Dimensions & Scoring
- **D-04:** Predefined core + derived extras. Claude locks ~10 core dimensions upfront (applied to every competitor identically) and adds 3-5 extras during execution if a competitor does something not in the core list. Core dimensions include (final list decided by Claude during research, but MUST cover): race coverage vs baseline, candidate photo, candidate bio, candidate contact info, stance/issue data, candidate quotes/Q&A, legislative record, geofence/address precision, data freshness, antipartisan framing.
- **D-05:** Scoring is a 0-3 depth scale per cell:
  - `0` = absent
  - `1` = minimal/token presence
  - `2` = present and usable
  - `3` = comprehensive
  Every cell also has a short evidence note (cited to the screenshot or URL it came from). Binary Y/N was explicitly rejected — it hides depth differences that matter for this benchmark.

### Output Structure & Location
- **D-06:** All artifacts live under `.planning/research/benchmark/` alongside `BALLOT-BASELINE-2026-05-05.md`, NOT inside the phase directory. Rationale: Phase 115 synthesis reads from `.planning/research/`, so co-locating keeps it one read.
- **D-07:** File layout:
  ```
  .planning/research/benchmark/
    METHODOLOGY.md         # Fairness framing — see D-10
    MATRIX.md              # The ~15-dim table with EV + 4 competitors, scored 0-3 with notes
    matrix.csv             # Machine-readable mirror of MATRIX.md
    ballotready.md         # Narrative + field inventory + race/candidate count table
    vote411.md
    votesmart.md
    ballotpedia.md
    ev.md                  # EV's own scoring on the same dimensions (for honest comparison)
    screenshots/
      ballotready/
      vote411/
      votesmart/
      ballotpedia/
      ev/
  ```

### Address Strategy
- **D-08:** Primary address + 2 secondary. Primary = `200 W Kirkwood Ave, Bloomington, IN 47404` (the same address Phase 112 used for the geofence smoke test — cleanest apples-to-apples). Full matrix scoring uses only the primary address — all four competitors + EV scored against the Kirkwood result.
- **D-09:** 2 secondary addresses are used ONLY for a lightweight "does address precision hold?" pass (not full matrix scoring):
  - A rural Benton Township address (to exercise State Rep district 46/60 boundary)
  - A second Bloomington-area address on the opposite side of the House District 61/62 line
  These expose whether each competitor correctly distinguishes district-specific races when the address moves a few miles. Findings go in a short "Precinct Precision" subsection within each per-competitor file.

### Fairness Framing
- **D-10:** `METHODOLOGY.md` is written BEFORE MATRIX.md is scored and opens the benchmark output. It documents:
  1. Exact addresses used (primary + 2 secondary) and the date run.
  2. What each 0-3 score means, with a worked example.
  3. What was behind auth walls / captchas / paywalls — logged per competitor as "blocked" not "absent."
  4. Dimensions EV intentionally omits (antipartisan principle — no party labels in UI, no endorsements, no interest-group ratings) so these are not mis-scored as gaps in EV's column.
  5. A self-audit note: EV is scored on the same dimensions as competitors, and EV's column is not privileged (if EV lacks something a competitor has, it scores 0 or 1 same as any competitor).
- **D-11:** No separate "peer-review checkpoint" gate — the explicit methodology section is the fairness mechanism.

### Claude's Discretion
- Final exact list of the ~10 core matrix dimensions (bounded by D-04)
- Which 2 secondary addresses to pick (bounded by D-09 — must exercise district boundaries)
- Per-competitor narrative depth and editorial tone
- Screenshot filenames and count per screen
- Whether `matrix.csv` is a direct MATRIX.md mirror or a normalized long-form table

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before researching or planning.**

### Phase 112 Outputs (the baseline denominator)
- `.planning/research/BALLOT-BASELINE-2026-05-05.md` — Authoritative Monroe County May 5, 2026 primary race and candidate list. This is the denominator for BENCH-06 race/candidate count comparisons.
- `.planning/research/AUDIT-REPORT-112.md` — EV's measured coverage against that baseline. Used to score EV's column in the matrix.
- `.planning/phases/112-data-completeness-audit/112-CONTEXT.md` — Prior phase's decision patterns (markdown + CSV output convention).

### Requirements
- `.planning/REQUIREMENTS.md` — BENCH-01 through BENCH-06 definitions (4 live spot-checks + comparison matrix + coverage depth comparison).

### Project Principles
- `.planning/PROJECT.md` — Antipartisan principle and vision framing that informs D-10 fairness methodology.

### Tooling
- `plugin_playwright` MCP tools (`browser_navigate`, `browser_snapshot`, `browser_take_screenshot`, `browser_fill_form`, `browser_click`) — primary execution path for D-01.

### Competitor Sites (entry points)
- BallotReady — https://www.ballotready.org/
- Vote411 (League of Women Voters) — https://www.vote411.org/
- VoteSmart — https://justfacts.votesmart.org/
- Ballotpedia — https://ballotpedia.org/

</canonical_refs>

<code_context>
## Existing Code Insights

This is a research/documentation phase. No application code is produced. The "code" is:
- Playwright MCP tool invocations (no persistent scripts required — one-shot browser sessions)
- Markdown + CSV artifact generation in `.planning/research/benchmark/`

### Reusable Patterns from Phase 112
- Markdown + CSV pairing convention (MATRIX.md + matrix.csv)
- Per-dimension structured output that Phase 115 can read directly
- Research artifacts co-located in `.planning/research/` for cross-phase consumption

### Not Applicable
- No DB queries (Phase 112 already ran those; this phase reads Phase 112's output, not the DB)
- No backend routes, no frontend changes
- No new npm dependencies (Playwright MCP is already available in the Claude Code environment)

</code_context>

<specifics>
## Specific Ideas

- Primary address is `200 W Kirkwood Ave, Bloomington, IN 47404` — matches Phase 112's geofence smoke test so any scoring divergence is attributable to the product, not to input variance.
- Core matrix dimensions MUST include: race coverage vs baseline, candidate photo, candidate bio, candidate contact info, stance/issue data, candidate quotes/Q&A, legislative record, geofence/address precision, data freshness, antipartisan framing. Claude can add up to 5 more derived from findings.
- Blockers (signup walls, captchas, paywalls) are logged as a "blocked" score class in the matrix — never silently treated as absent. This is a hard rule from D-02.
- EV is scored on the same sheet as competitors, using the same 0-3 scale, not given a privileged column. See D-10.5.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. Scope creep prevention: any "we should also benchmark X tool" or "we should also build Y competitive feature" belongs in Phase 115 (gap report) or a future milestone, not here.

</deferred>

---

*Phase: 113-competitive-benchmarking*
*Context gathered: 2026-04-12*
