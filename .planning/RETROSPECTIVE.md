# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.7 — LA County Data Enrichment

**Shipped:** 2026-02-26
**Phases:** 6 | **Plans:** 15 executed (1 deferred)

### What Was Built
- Headshot pipeline for LA County city councils (1,247-line scraper with 5-strategy extraction, 84 photos in Supabase CDN)
- High-value headshots for 20 LA County/City officials from Wikipedia Commons
- 11 city hall building photos from Wikimedia Commons
- Contact enrichment: 381 records with API endpoint and frontend section
- Term date precision formatting with UTC-safe year display
- Coverage validation script

### What Worked
- Schema-first approach (Phase 39), high-value officials first (Phase 40), config-driven pipeline
- Out-of-order phase execution: Phases 43/44 completed while Phase 42 manual curation deferred

### What Was Inefficient
- 80% headshot target unrealistic for automated scraping (~55 cities use Cloudflare WAF)
- Wikipedia strategy false positives, broken override URLs, REQUIREMENTS.md accuracy drift

### Key Lessons
1. Set realistic automation ceilings early — research anti-bot protections before setting targets
2. Manual curation is a valid engineering output — building tooling for efficient manual work
3. Deferred plans are acceptable when pipeline infrastructure is complete

---

## Milestone: v1.8 — Compass Data & Politician Research

**Shipped:** 2026-02-27
**Phases:** 6 | **Plans:** 28

### What Was Built
- Stance research CSV: 455 sourced data rows across 23 politicians on 21 compass topics
- Quote collection: 61 verbatim sourced quotes from 11 politicians
- Go CLI import subcommands with CSV parsing and upsert logic
- GET /essentials/quotes API with LATERAL JOIN; Read & Rank frontend integration
- Legacy cleanup: 2,584 lines removed; source URL integrity: 700+ fabricated URLs cleared

### What Worked
- CSV-first research pipeline, strict URL verification as separate plans, omit-rather-than-fabricate rule

### What Was Inefficient
- Phase 47 plan explosion (12 plans); Phase 49 quote attrition (179→61 rows)

### Key Lessons
1. AI-generated source URLs need systematic verification — 700+ fabricated URLs caught
2. Verbatim quote collection requires extractable sources — generic index pages don't contain quotes
3. Research milestones generate more plans than code milestones

---

## Milestone: v1.9 — Compare UX & Search Fixes

**Shipped:** 2026-02-28
**Phases:** 3 | **Plans:** 6

### What Was Built
- Inline politician picker on compare page with keyboard nav, search, clear, browse-all
- Level/state filters reused across both picker surfaces via shared hook
- ST_Intersects area-boundary search for city/ZIP/county queries
- Unified single search path (removed ZIP vs address branching)
- searchKey counter pattern fixing re-search-from-results bug
- Area label display on results page

### What Worked
- Shared hook pattern enabled zero code duplication across two picker surfaces
- Module-level cache avoided Provider wrapping; "keep old data visible" pattern for smooth morph
- Small focused milestone (3 phases, 6 plans) completed in 2 days with zero deviations

### What Was Inefficient
- "My reps" surfacing listed as target but deferred — should have been scoped out during requirements

### Key Lessons
1. Shared hooks + presentational components = maximum reuse
2. Conservative defaults for civic search (area over point) serve users better
3. Deprecation over deletion prevents build breakage in multi-consumer codebases

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.7 | 6 | 15 | First milestone with Python scraping pipeline; manual curation accepted |
| v1.8 | 6 | 28 | First research-heavy milestone; URL verification as separate plans |
| v1.9 | 3 | 6 | Smallest milestone yet — tight scope, 100% plan adherence |

### Top Lessons (Verified Across Milestones)

1. Schema-first phases prevent retroactive migrations (v1.6, v1.7, v1.8)
2. Config-driven scripts with idempotent upserts enable safe re-runs (v1.6, v1.7, v1.8)
3. Coverage validation scripts with exit codes enable milestone gating (v1.7, v1.8)
4. AI-generated source URLs require systematic verification (v1.8)
5. Shared hooks are the best React feature reuse boundary (v1.5, v1.9)
6. Backend-first changes reduce frontend complexity (v1.3, v1.9)
