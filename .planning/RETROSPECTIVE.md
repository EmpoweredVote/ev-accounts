# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.7 — LA County Data Enrichment

**Shipped:** 2026-02-26
**Phases:** 6 | **Plans:** 15 executed (1 deferred)

### What Was Built
- Headshot pipeline for LA County city councils (1,247-line scraper with 5-strategy extraction, 84 photos in Supabase CDN)
- High-value headshots for 20 LA County/City officials (supervisors + city council) from Wikipedia Commons
- 11 city hall building photos from Wikimedia Commons, uploaded to Supabase Storage CDN
- Contact enrichment: 381 records (376 city website URLs + 5 supervisor phones) with API endpoint and frontend section
- Term date precision formatting with UTC-safe year display
- Coverage validation script confirming CDN health, contact presence, and zero hotlinks

### What Worked
- **Schema-first approach** (Phase 39): Adding all schema prerequisites before any enrichment script ran prevented retroactive migrations and kept subsequent phases clean
- **High-value officials first** (Phase 40): Proving the Supabase Storage upload flow with 20 officials before scaling to 391 caught content-type and idempotency issues early
- **Out-of-order phase execution**: Phases 43 and 44 completed while Phase 42's manual curation sprint was deferred — didn't block API/frontend work on pipeline gaps
- **Config-driven pipeline**: city_sources.json and pipeline_config.json made scripts idempotent and re-runnable with zero side effects

### What Was Inefficient
- **80% headshot target was unrealistic for automated scraping** — ~55 of 89 cities use Cloudflare WAF or CivicPlus JS CMS that block all automated access; ceiling hit at 21.5% before recognizing manual curation was the only path forward
- **Wikipedia strategy false positives** (Phase 42-02): Common names matched historical figures (Ray Pearl → 1879 doctor, Octavio Martinez → Mexican general); required post-scrape manual review and deletion
- **Pomona/Santa Monica override URLs** (Phase 42-05): URLs were valid when added but broke between sessions (Akamai protection applied, files moved); wasted a plan cycle on broken overrides
- **REQUIREMENTS.md accuracy drift**: PHOTO-03 marked [x] despite 21.5% actual coverage; CONT-03 left unchecked despite being shipped

### Patterns Established
- **Supabase Storage upload with explicit content-type**: SDK defaults to text/plain; always set MIME from HTTP response headers
- **urlparse pattern for Supabase pooler URLs**: psycopg2.connect(url) fails when password contains @; extract components as kwargs
- **Research manifest pattern**: When automated coverage plateaus, generate a prioritized CSV manifest for manual curation (sorted by gap size descending)
- **Coverage validation as standalone script**: Python script with numbered checks, summary table, and exit code 0/1 for CI integration
- **formatTermDate UTC fix**: Use parseInt(dateStr, 10) for year precision to avoid timezone shift where new Date('2024') shows 'Dec 2023'

### Key Lessons
1. **Set realistic automation ceilings early**: Research the target ecosystem's anti-bot protections before committing to coverage targets — government websites vary wildly in accessibility
2. **Manual curation is a valid engineering output**: Building tooling that makes manual work efficient (manifest CSV, override support, --force-retry) is as valuable as full automation
3. **Deferred plans are acceptable**: Shipping the milestone with Plan 42-06 deferred was the right call — the pipeline infrastructure is complete and ready when the manual sprint happens

### Cost Observations
- Model mix: ~70% sonnet (executors), ~30% opus (planning, verification)
- Notable: Phase 42 consumed the most plans (6) due to iterative gap closure — each scraper enhancement revealed new extraction challenges

---

## Milestone: v1.8 — Compass Data & Politician Research

**Shipped:** 2026-02-27
**Phases:** 6 | **Plans:** 28

### What Was Built
- Stance research CSV with 455 sourced data rows across 23 politicians (CA/IN governors, lt. governors, US senators, 12 LA County House reps, Monroe County rep, 2 mayors) on 21 compass topics
- Quote collection CSV with 61 verbatim sourced politician quotes from 11 politicians for Read & Rank
- Go CLI import subcommands (import-stances, import-quotes) with CSV parsing, fuzzy name matching, and upsert logic
- GET /essentials/quotes API endpoint with LATERAL JOIN; Read & Rank frontend API client with mockData.ts fallback
- Legacy cleanup: 2,584 lines of deprecated 50-topic seed code removed
- Source URL integrity enforcement: 700+ hallucinated/fabricated URLs cleared across 6 cleanup plans

### What Worked
- **CSV-first research pipeline**: Defining the CSV schema in Phase 46 and appending incrementally through Phases 47-48 made validation cumulative — each plan's additions were checked against the growing dataset
- **Strict URL verification as separate plans (47-07 through 47-11)**: Dedicating cleanup plans to URL audit after initial research caught systematic hallucination patterns (AP year-suffix, house.gov/senate.gov slug-only fabrications) that would have shipped as bad data
- **Omit-rather-than-fabricate rule**: Not inventing positions for politicians with no documented record (Kounalakis 10/21, Beckwith 13/21, Thomson 12/21) maintained data integrity at the cost of coverage — the right tradeoff for a civic platform
- **Verbatim-only quote standard with aggressive cleanup (Plans 49-07, 49-08)**: Removing 118 rows that cited generic index pages (congress.gov member pages, bill pages) ensured every surviving quote is truly attributable

### What Was Inefficient
- **Phase 47 plan explosion**: 12 plans for federal officials research (original 6 + 6 URL cleanup plans) — the hallucinated URL problem required nearly doubling the plan count; should have anticipated source quality issues from the start
- **Phase 49 quote attrition**: Started with 179 quote rows, ended with 61 after two cleanup passes — verbatim verification removed 66% of collected quotes; future quote collection should verify extractability before committing rows
- **Duplicate state context entries**: STATE.md accumulated both `**47-12:**` and `[Phase 47-federal-officials-research]: 47-12:` entries for the same decisions; context logging needs dedup discipline

### Patterns Established
- **Research CSV append-and-validate pattern**: New politicians appended to existing CSV; Python validation script checks all rows on every append (not just new ones)
- **Hallucinated URL detection rules**: AP year-suffix pattern (apnews.com/article/[topic]-[year]), slug-only .gov press releases without hash/ID — applicable to any AI-generated content citing sources
- **congress.gov member page as verified fallback**: When no specific bill/vote URL exists, the bioguide member page is a real, authoritative URL for any federal official
- **CLI import-after-Init() pattern**: Placing subcommand dispatch after all Init() calls ensures schema migrations complete before import logic executes
- **LATERAL JOIN for one-to-many API responses**: Prevents row multiplication when joining politicians to offices in quote queries

### Key Lessons
1. **AI-generated source URLs need systematic verification**: Even with explicit instructions to cite real sources, 700+ URLs were fabricated — treat all AI-generated URLs as unverified until confirmed
2. **Verbatim quote collection requires extractable sources**: Generic index pages (congress.gov member pages) don't contain quotes; future research should identify press releases and news articles first, then extract quotes from them
3. **Research milestones generate more plans than code milestones**: 28 plans for 6 phases (4.7 avg) vs v1.7's 15 plans for 6 phases (2.5 avg) — research requires more iterative validation cycles

### Cost Observations
- Model mix: ~60% sonnet (executors), ~40% opus (research planning, cleanup verification)
- Notable: Phase 47 consumed 12 plans (43% of milestone total) due to URL cleanup — the most plan-intensive phase across all milestones

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.7 | 6 | 15 | First milestone with Python scraping pipeline; manual curation accepted as valid gap-closure strategy |
| v1.8 | 6 | 28 | First research-heavy milestone; URL verification as separate plans; verbatim-only quote standard |

### Top Lessons (Verified Across Milestones)

1. Schema-first phases prevent retroactive migrations (verified v1.6 pipeline infrastructure, v1.7 schema prep, v1.8 legacy cleanup before research)
2. Config-driven scripts with idempotent upserts enable safe re-runs (verified v1.6 scrapers, v1.7 headshot/building/contact importers, v1.8 stance/quote import CLI)
3. Coverage validation scripts with exit codes enable milestone gating (verified v1.7 coverage_report.py, v1.8 CSV validation)
4. AI-generated source URLs require systematic verification — treat as unverified until confirmed (new in v1.8, 700+ fabricated URLs caught)
