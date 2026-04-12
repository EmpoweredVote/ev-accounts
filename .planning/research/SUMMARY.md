# Project Research Summary

**Project:** v2026.4.3 Indiana Primary Election Readiness Audit
**Domain:** Civic tech — competitive benchmarking and election data completeness audit for Monroe County IN primary
**Researched:** 2026-04-11
**Confidence:** HIGH (architecture from direct code inspection; stack confirmed against package.json; pitfalls from authoritative sources)

## Executive Summary

This milestone is an audit milestone, not a feature build. The platform already has a working election schema, Monroe County seed data, and voter guide features. What it does not have is assurance that the May 5, 2026 primary data is complete, accurate, and competitive with peer voter guide sites. The recommended approach is a two-track audit: (1) run read-only DB scripts to measure coverage against the actual full Monroe County ballot, and (2) conduct manual spot-checks on all four competitors with a real Bloomington address to benchmark data quality. The audit produces a tiered gap report — Tier 1 gaps get fixed before the primary, Tier 2 gaps become future phase plans.

The most critical finding from research is that completeness must be measured against the real ballot, not against the existing DB. The current 12 races / 18 candidates import covers a fraction of the expected 30-40+ races on a Monroe County May 5 ballot. Township races (11 townships, multiple contested primaries), county offices (assessor, clerk, commissioner, prosecutor, council, auditor, treasurer, coroner, surveyor), and judicial races are all missing or incomplete. The data gap is the primary execution risk — not missing features. The platform's differentiators (compass alignment, legislative record, Read & Rank) are already built; they are useless until candidate data exists to power them.

The key risk is scope creep: attempting to fill every gap (stance data, photos, bios for 80+ new candidates) in 3 weeks. The research is unambiguous that race+candidate import comes first; stance enrichment only where public records exist; antipartisan omissions are intentional and must not be misread as gaps. One tactical risk unique to this cycle is Indiana's new partisan school board law — school board filing opens May 19 (after the primary), and any attempt to import school board races for May 5 would be factually wrong.

## Key Findings

### Recommended Stack

No new infrastructure is needed for this milestone. The entire audit runs on the existing stack: `tsx` for script execution, `pg.Pool` / `DATABASE_URL` for direct DB queries, `xlsx` for Indiana SoS Excel parsing, and markdown files in `.planning/` for gap report output. The established `audit-is-appointed.ts` / `auditHeadshots.ts` script pattern is the template for all new audit scripts.

**Core technologies:**
- `tsx` + `pg.Pool`: Run read-only audit scripts directly against production DB — confirmed in package.json, established pattern
- `xlsx ^0.18.5`: Parse Indiana SoS `.xlsx` candidate files — already wired, no upgrade needed
- `csv-parse ^6.2.1` / `node-html-parser ^7.1.0`: Supporting parsers if needed — already in deps
- Markdown files in `.planning/research/`: Gap report and benchmark outputs — no DB tables, no frontend

**Explicit non-additions:** Playwright/Puppeteer (manual competitor spot-checks are sufficient and ToS-safe), VoteSmart API integration (manual benchmark is faster for a one-time audit), PDF generation libraries (markdown output is sufficient).

### Expected Features

**Must have before primary (table stakes):**
- All races on the ballot shown — currently ~12 of 30-40+ expected; blank race cards destroy voter trust
- Candidate names for every race — even uncontested races need candidate names
- Office descriptions ("What does this office do?") — ~20 static copy entries, frontend-only, no DB changes
- Indiana party primary explainer — one-line copy noting Indiana voters choose one party primary
- Data accuracy verification — confirm May 5, 2026 date; spot-check all 12 existing races against current filings
- Completeness caveat on Election Central — "For a complete official ballot, visit the Monroe County Clerk" with link

**Should have before primary if bandwidth allows:**
- Compass stances for top 6-8 candidates (US House D-9, IN House D-61) — unlocks platform differentiator
- Sourced quotes for contested federal/state races — enables Read & Rank for highest-visibility races
- Township geofence import for Monroe County's 11 townships — prevents Bloomington residents seeing Clear Creek races

**Defer to post-primary:**
- Side-by-side candidate comparison UI — build after data is complete
- Save/print ballot feature — medium complexity, low blocking impact
- Stance/bio research for township and county candidates — insufficient public record exists
- MCCSC school board races — filing opens May 19, these are November general election races

**Explicit anti-features (intentional omissions, not gaps):**
- Party affiliation display — antipartisan by design
- Interest group ratings — embeds partisan framing
- AI-generated candidate summaries — hallucination risk too high for local candidates
- Endorsement tracking — heavily partisan signal for local races

### Architecture Approach

The audit milestone is entirely additive and read-only. One new composite script (`audit-monroe-county-readiness.ts`) queries across races, candidates, stances, quotes, headshots, and geofences and outputs structured text. Two new planning documents (COMPETITOR-BENCHMARK.md and GAP-REPORT-v2026.4.3.md) capture manual findings. No service layer changes, no API endpoints, no schema migrations, no frontend changes.

**Major components (audit scope only):**
1. `backend/scripts/audit-monroe-county-readiness.ts` — composite read-only report via `pg.Pool`, output to stdout
2. `.planning/research/COMPETITOR-BENCHMARK.md` — manual spot-check matrix, one session, one Bloomington address, all four competitors
3. `.planning/GAP-REPORT-v2026.4.3.md` — tiered gap list feeding follow-on phase plans

### Critical Pitfalls

1. **Using 12 races as the completeness denominator** — Start from external authoritative ballot sources (Monroe County Clerk, Indiana SoS, B-Square Bulletin) to build the full ballot list first, then measure coverage.
2. **Importing school board races for May 5** — Indiana SB 177 moved school board filing to May 19. School boards are November races only.
3. **Benchmarking competitor features globally instead of Monroe County specifically** — Live Monroe County address spot-checks are mandatory.
4. **Listing party affiliation as a gap vs BallotReady** — It is an intentional antipartisan omission. Gap report must have an explicit "intentional omissions" column.
5. **Attempting stance research for 30+ candidates in 3 weeks** — Race+candidate import is the goal. Stance enrichment only where a clear public record exists.

## Implications for Roadmap

Suggested phases: **3**

### Phase 1: Data Completeness Audit + Competitive Benchmarking
**Rationale:** Must know the actual gap before filling it. DB audit script and manual competitor spot-checks run in parallel.
**Delivers:** Structured audit output (race/candidate/stance/quote/headshot/geofence gaps), competitor benchmark matrix, confirmed full ballot list for Monroe County May 5.

### Phase 2: Gap Report + Prioritization
**Rationale:** Synthesize Phase 1 findings into actionable, tiered work. Decision gate that prevents scope creep.
**Delivers:** `GAP-REPORT-v2026.4.3.md` with Tier 1 / Tier 2 partitioning; intentional omissions explicitly documented.

### Phase 3: Tier 1 Execution — Data + Quick UX Fixes
**Rationale:** Only what is both achievable and blocking for May 5. Data import before feature builds.
**Delivers:** All confirmed contested May 5 Monroe County races imported; completeness caveat live; office descriptions; Indiana party primary explainer.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All tooling confirmed against live package.json; no new packages required |
| Features | MEDIUM-HIGH | Competitor analysis from documentation + web search; live spot-checks are Phase 1 work |
| Architecture | HIGH | All findings from direct code inspection of live codebase |
| Pitfalls | HIGH | Critical pitfalls sourced from Indiana election law documents and project history |

**Overall confidence:** HIGH for architecture and execution approach; MEDIUM for exact race/candidate counts (confirmed by Phase 1 audit).

---
*Research completed: 2026-04-11*
*Ready for roadmap: yes*
