# Requirements: Empowered Vote v1.7 LA County Data Enrichment

**Defined:** 2026-02-24
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.7 Requirements

Requirements for LA County data enrichment. Each maps to roadmap phases.

### Headshot Photos

- [ ] **PHOTO-01**: User sees headshot photo for each LA County supervisor on their profile page
- [ ] **PHOTO-02**: User sees headshot photo for each LA City council member on their profile page
- [ ] **PHOTO-03**: User sees headshot photo for 80%+ of city council members across 89 LA County cities
- [ ] **PHOTO-04**: All scraped headshots stored in Supabase Storage CDN (not hotlinked from source sites)
- [ ] **PHOTO-05**: Photo licensing tracked for each scraped image

### Building Photos

- [ ] **BLDG-01**: User sees city hall building photo in the local tier section for LA City
- [ ] **BLDG-02**: User sees city hall building photos for top 20 LA County cities by population
- [ ] **BLDG-03**: Building photos sourced from Wikimedia Commons (CC-licensed)

### Contact Info

- [ ] **CONT-01**: User sees website URL on profile for officials in all 89 LA County cities
- [ ] **CONT-02**: User sees phone number on profile for county supervisors
- [ ] **CONT-03**: User sees contact info section on politician profile page (phone, email, website)
- [ ] **CONT-04**: Go API returns contacts in politician profile response

### Term Data

- [ ] **TERM-01**: User sees term start and end dates for county supervisors on profile page
- [ ] **TERM-02**: User sees derived term dates for city council members where election year is known
- [ ] **TERM-03**: Term date display respects precision (year-only shows "2024" not "Jan 2024")

### Bio

- [ ] **BIO-01**: User sees biography text for county supervisors on profile page
- [ ] **BIO-02**: User sees biography text for LA City council members on profile page

### Pipeline

- [ ] **PIPE-01**: Enrichment scripts are idempotent and config-driven (re-runnable without duplicates)
- [ ] **PIPE-02**: Scraping respects rate limits with delays between requests
- [ ] **PIPE-03**: Coverage report validates 80%+ headshot and contact targets
- [ ] **PIPE-04**: Pipeline designed for future regional expansion (config-driven, not LA-specific)

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Building Photos

- **BLDG-04**: City hall building photos for remaining 69 LA County cities beyond top 20
- **BLDG-05**: Building photo refresh pipeline for stale Wikimedia URLs

### Bio/Education/Experience

- **BIO-03**: Bio text for city council members across 89 cities where available
- **BIO-04**: Education history (degrees, schools) for county supervisors and LA City council
- **BIO-05**: Work/office experience timeline for county supervisors and LA City council

### Pipeline

- **PIPE-05**: Automated enrichment scheduling (nightly or weekly re-scrape)
- **PIPE-06**: School board data enrichment (402 members excluded from v1.7)
- **PIPE-07**: Photo refresh pipeline detecting stale/broken Supabase Storage URLs

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Automated nightly re-scrape | Manual re-runs sufficient; complex orchestration not justified for 389 records |
| School board enrichment | 402 members excluded from v1.7 scope — data availability low, anti-bot protections high |
| Bio/education for smaller city councils | ~30% availability with inconsistent HTML; high per-city effort for low return |
| Ballotpedia scraping | ToS prohibits scraping; no public API available |
| Geocoding office addresses to lat/lng | Adds Google Maps billing dependency; text addresses sufficient |
| Google Places API for building photos | Per-request billing, non-permanent URLs, 10K/month free cap |
| Individual council member email addresses | ~20-30% availability at city council level; web forms more common |
| Education/experience for local officials | Rarely published at city council level |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PHOTO-01 | — | Pending |
| PHOTO-02 | — | Pending |
| PHOTO-03 | — | Pending |
| PHOTO-04 | — | Pending |
| PHOTO-05 | — | Pending |
| BLDG-01 | — | Pending |
| BLDG-02 | — | Pending |
| BLDG-03 | — | Pending |
| CONT-01 | — | Pending |
| CONT-02 | — | Pending |
| CONT-03 | — | Pending |
| CONT-04 | — | Pending |
| TERM-01 | — | Pending |
| TERM-02 | — | Pending |
| TERM-03 | — | Pending |
| BIO-01 | — | Pending |
| BIO-02 | — | Pending |
| PIPE-01 | — | Pending |
| PIPE-02 | — | Pending |
| PIPE-03 | — | Pending |
| PIPE-04 | — | Pending |

**Coverage:**
- v1.7 requirements: 21 total
- Mapped to phases: 0
- Unmapped: 21

---
*Requirements defined: 2026-02-24*
*Last updated: 2026-02-24 after initial definition*
