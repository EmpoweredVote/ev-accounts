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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.7 | 6 | 15 | First milestone with Python scraping pipeline; manual curation accepted as valid gap-closure strategy |

### Top Lessons (Verified Across Milestones)

1. Schema-first phases prevent retroactive migrations (verified v1.6 pipeline infrastructure, v1.7 schema prep)
2. Config-driven scripts with idempotent upserts enable safe re-runs (verified v1.6 scrapers, v1.7 headshot/building/contact importers)
3. Coverage validation scripts with exit codes enable milestone gating (new in v1.7, pattern ready for future milestones)
