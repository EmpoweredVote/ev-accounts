# Phase 115: Gap Report Synthesis - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Synthesize findings from the three completed audit tracks (Phase 112 data completeness audit, Phase 113 competitive benchmarking, Phase 114 UX walkthrough) into:
1. A tiered gap report classifying every finding as Tier 1 (must fix before May 5 primary) or Tier 2 (future improvement)
2. An intentional omissions section distinguishing antipartisan choices from data gaps
3. An execution backlog of ROADMAP-ready phase entries for v2026.4.4

Output is markdown documents only — no code changes, no DB changes, no frontend changes.

</domain>

<decisions>
## Implementation Decisions

### Tiering Criteria
- **D-01:** Primary tiering signal is **severity-first**: all UX gaps tagged `blocker` (G-114-001 through 031 severity=blocker) are automatically Tier 1 candidates. `confusing` and `minor` gaps default to Tier 2 unless they also represent data gaps with race coverage impact.
- **D-02:** **May 1, 2026** is the Tier 1 hard cutoff — 4 days before the May 5 primary. Any fix that cannot plausibly land in prod by May 1 is Tier 2 even if severity=blocker. This feasibility ceiling is applied after severity screening, not before.
- **D-03:** Data audit findings from Phase 112 (AUDIT-REPORT-112.md) do not have pre-assigned severity. They inherit severity from their UX counterpart: if a data audit row is already covered by a G-114-NNN entry, inherit that entry's severity. Data audit findings with **no UX counterpart** default to **Tier 2**.

### Source Unification
- **D-04:** The report is organized in **sections by source**, preserving original IDs:
  - Section 1: UX Gaps (cite G-114-NNN)
  - Section 2: Data Audit Findings (cite AUDIT-REPORT-112.md rows)
  - Section 3: Cross-Cutting Patterns (new entries — see D-07)
  Each section header names the source so findings are fully traceable back to their evidence.
- **D-05:** Benchmark matrix findings (MATRIX.md) appear as **context and rationale only** — they inform why a gap is Tier 1 rather than creating new gap entries. Example: "EV scores 0 on candidate bio vs VoteSmart's 3 — this elevates [gap ref] to Tier 1." Benchmark findings do NOT generate standalone gap entries unless they reveal a voter-facing gap not already in the UX gaps or audit rows (see D-06).
- **D-06:** **Exception — benchmark-derived gaps:** If the benchmark + audit together reveal a voter-facing gap that the UX walkthrough missed (and it can be evidenced by both a MATRIX.md cell score AND an AUDIT-REPORT-112 row), the synthesis agent may create a new finding. It must cite both the benchmark score and the audit row as dual evidence. These go in Section 3 (Cross-Cutting Patterns), not Section 1 or 2.

### Synthesis Scope
- **D-07:** The synthesis agent **may discover cross-cutting patterns** not present in any single input. When the same root cause appears across multiple G-114-* entries or audit rows, the agent can name it as a pattern gap with a new ID (e.g., `PATTERN-001`). These entries are clearly labeled "cross-cutting pattern" and must cite the constituent gaps that evidence them. This is the value of synthesis over a simple merge — capturing what no single audit phase could see.

### Execution Backlog Format
- **D-08:** Each backlog item is a **ROADMAP-ready phase entry** containing:
  - Phase name
  - Goal statement (1-2 sentences)
  - Gaps closed (list of G-114-NNN, audit row refs, or PATTERN-NNN)
  - Effort signal: **S** (few hours), **M** (1–3 plans), **L** (3+ plans)
  - Depends-on (if any prior phase must run first)
  Ready to paste into ROADMAP.md for v2026.4.4 planning with minimal revision.
- **D-09:** T-shirt sizing (S/M/L) is the effort signal for each phase. No plan-count estimates — those are set during discuss-phase for v2026.4.4.

### Intentional Omissions
- **D-10:** The gap report must include an explicit "Intentional Omissions" section listing antipartisan choices that are NOT gaps: no party labels, no endorsements, no interest-group ratings, no partisan color associations. These were documented in Phase 114's METHODOLOGY.md §8 and must be copied/referenced here to prevent future contributors from re-filing them as gaps.

### Claude's Discretion
- Exact file name for the gap report document (recommendation: `.planning/GAP-REPORT.md`)
- Whether Tier 1 and Tier 2 items are interleaved in each section or separated into top-level Tier 1 / Tier 2 blocks
- How many ROADMAP-ready phase entries to produce (determined by gap clustering)
- Narrative framing for the executive summary

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 112 Outputs (data audit)
- `.planning/research/AUDIT-REPORT-112.md` — Structured data completeness report: race coverage, candidate counts (linked vs stub), stance/quote/photo/bio coverage metrics. Primary source for Section 2 (Data Audit Findings).
- `.planning/research/BALLOT-BASELINE-2026-05-05.md` — Authoritative Monroe County May 5, 2026 ballot. Required denominator when tiering data gaps.

### Phase 113 Outputs (benchmark)
- `.planning/research/benchmark/MATRIX.md` — Core-10 scoring table, EV vs BallotReady/Vote411/VoteSmart/Ballotpedia. Used as context/rationale for tier decisions, not as a gap source (per D-05). Exception: benchmark-derived gaps per D-06.
- `.planning/research/benchmark/METHODOLOGY.md` — Fairness framing and antipartisan scoring definition (Dim 10) — relevant to D-10 intentional omissions section.

### Phase 114 Outputs (UX walkthrough)
- `.planning/research/ux-walkthrough/GAPS.md` — 31 entries G-114-001..031, each with app/screen/severity/type/evidence/baseline_ref. **Primary source for Section 1 (UX Gaps).** This is the backbone of the gap report.
- `.planning/research/ux-walkthrough/gaps.csv` — Machine-readable mirror of GAPS.md for any programmatic processing.
- `.planning/research/ux-walkthrough/METHODOLOGY.md` — Severity/type definitions (blocker/confusing/minor, data/feature/content/ux-friction), intentional omissions §8 (antipartisan choices).

### Context Files (prior phase decisions)
- `.planning/phases/114-ux-walkthrough/114-CONTEXT.md` — D-10 gap schema, D-14 intentional omissions, gap ID convention.
- `.planning/phases/113-competitive-benchmarking/113-CONTEXT.md` — Benchmark dimension definitions and scoring methodology.
- `.planning/phases/112-data-completeness-audit/112-CONTEXT.md` — Data audit output format and column conventions.

### Requirements
- `.planning/REQUIREMENTS.md` — GAP-01 (tiered report), GAP-02 (gap types + intentional omissions), GAP-03 (execution backlog) — the three success criteria this phase must satisfy.

### Project Principles
- `.planning/PROJECT.md` — Antipartisan principle (no party labels, endorsements, interest-group ratings) — drives D-10 intentional omissions section.

</canonical_refs>

<code_context>
## Existing Code Insights

This is a documentation/synthesis phase. No application code is produced. The "output" is:
- `.planning/GAP-REPORT.md` — the tiered gap report + intentional omissions section
- An execution backlog section within GAP-REPORT.md (or a companion `BACKLOG.md`) — ROADMAP-ready phase entries for v2026.4.4

### Input Artifacts Summary (for orientation)
- **31 UX gaps** in GAPS.md: 8 blocker / 17 confusing / 6 minor × data/feature/content/ux-friction
- **Data audit**: 81 total candidates (51 linked, 30 stubs), 5/51 stances, 4/51 quotes, 19/81 photos, 0/51 bios
- **Benchmark**: EV 15/30 core-10 total (tied with Ballotpedia; leads BallotReady/Vote411; trails VoteSmart 19/30 on bio, stances, quotes, votes)

### Not Applicable
- No DB queries, no backend routes, no frontend changes
- No Playwright — all inputs already exist as files in `.planning/research/`
- No new npm dependencies

</code_context>

<specifics>
## Specific Details

- **Tier 1 hard cutoff: May 1, 2026** (4 days before May 5 primary). This is the feasibility ceiling for Tier 1 classification.
- **Source sections, original IDs**: Report uses G-114-NNN, AUDIT-REPORT-112 row references, and new PATTERN-NNN IDs for cross-cutting patterns. No re-ID of existing findings.
- **Benchmark = context, not gaps** — unless a gap is evidenced by both MATRIX.md and AUDIT-REPORT-112 simultaneously (benchmark-derived gap exception per D-06).
- **Backlog entries must be ROADMAP-paste-ready**: name + goal + gap refs + S/M/L effort + depends-on.
- **Intentional omissions are mandatory**: antipartisan choices must be in the report so they're not re-filed as gaps in v2026.4.4.

</specifics>

<deferred>
## Deferred Ideas

None surfaced during discussion.

</deferred>

---

*Phase: 115-gap-report-synthesis*
*Context gathered: 2026-04-13*
