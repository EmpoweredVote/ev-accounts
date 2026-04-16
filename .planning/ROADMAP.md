# Roadmap — v2026.4.4 Indiana Primary Fix Wave

**Milestone goal:** Ship Tier 1 gap fixes before the May 5 Indiana primary — correct wrong data, repair broken features, and import minimum viable candidate data for Monroe County voters.

**Granularity:** standard
**Total phases:** 11 (Phase 116 — Phase 126)
**Requirements covered:** 25/25
**Tier 1 deadline:** May 1, 2026 (4 days before May 5 Indiana primary)
**Repos affected:** `essentials`, `ev-accounts`, `ev-ui`, `read-rank`

---

## Phases

- [x] **Phase 116: Quick Correctness Fixes** — Correct wrong election date, broken nav links, and wrong default Representatives tab (completed 2026-04-15)
- [ ] **Phase 117: Candidate Stub Resolution + Data Import** — Create politician records and import minimum viable data for ~30 stub Monroe County candidates
- [x] **Phase 118: Read & Rank Verdict Badge Fix** — Restore verdict badges on politician profile pages in production (completed 2026-04-16)
- [x] **Phase 119: Read & Rank Location Filter Repair** — Restore Monroe County location filter (both filter mechanisms broken) (completed 2026-04-16)
- [ ] **Phase 120: Contested-Race Bio + Photo Authoring** — Author bios and source headshots for ~5–10 contested-race candidates
- [ ] **Phase 121: County Council D1→D4 Geofence Repair** — Fix Kirkwood Ave Bloomington address resolving to wrong council district
- [ ] **Phase 122: Cross-App Loop Polish** — Repair remaining Compass→Read & Rank→Essentials integration gaps
- [ ] **Phase 123: Photo Coverage Expansion** — Extend headshot pipeline to fill remaining 62-candidate photo gap
- [ ] **Phase 124: App-Wide Bio Authoring** — Author bios for ~45 remaining linked candidates
- [ ] **Phase 125: Tier 2 UX Polish Bundle** — Address 21 Tier 2 minor/confusing UX gaps
- [ ] **Phase 126: Geofence Hardening** — Repair rural address geocoding failures and import 11 missing township geofences

---

## Phase Details

### Phase 116: Quick Correctness Fixes
**Goal**: A Monroe County voter visiting for the first time sees the correct election date, functional navigation, and can find all candidates in their representative view.
**Depends on**: Nothing
**Requirements**: CORR-01, CORR-02, CORR-03
**Success Criteria** (what must be TRUE):
  1. Election Central page displays May 5, 2026 as the election date (not a wrong date).
  2. All SiteHeader navigation links resolve to live empowered.vote pages — no 404s when clicking between apps.
  3. The Representatives page defaults to a tab that shows all elected officials including challengers.
**Plans**: 1 plan
  - [x] 116-01-PLAN.md — Edit ev-ui SiteHeader (delete 3 nav items, update 2 Features URLs), ship via auto-bump, close CORR-01/CORR-03 misflags

### Phase 117: Candidate Stub Resolution + Data Import
**Goal**: Contested Monroe County races have real candidate records — stub profiles are replaced with minimum viable data (name, office, photo, 1-line bio), making Essentials profiles usable and the Compass picker functional for those candidates.
**Depends on**: Nothing (start in parallel with Phase 116 due to data-sourcing lead time)
**Requirements**: CAND-01, CAND-02, CAND-03, CAND-04, CAND-05
**Success Criteria** (what must be TRUE):
  1. A feasibility evaluation document exists confirming which ~30 stub candidates have sourced public record data available, before any code work begins.
  2. Politician records exist in the DB for stub candidates in contested Monroe County races, with at minimum name and office title.
  3. Each resolved candidate has a minimum viable profile: photo (or placeholder), 1-line bio, and correct office title.
  4. Resolved candidate profile pages in Essentials load without errors and display the imported data.
  5. Resolved candidates appear in the Compass politician picker and can be selected for comparison.
**Plans**: 7 plans
  - [ ] 117-01-PLAN.md — Feasibility evaluation: source public records for every stub, tiered doc + CSV sidecar, April 25 go/no-go
  - [ ] 117-02-PLAN.md — Migration 068: add is_candidate + bio_source_url columns, backfill is_candidate from race_candidates
  - [ ] 117-03-PLAN.md — essentialsService address-resolver filter (is_candidate=true excluded from tier-grouped results)
  - [ ] 117-04-PLAN.md — compassService LEFT JOIN fix (CAND-05 strategy: Option A)
  - [ ] 117-05-PLAN.md — uploadCandidatePhoto TS helper (Supabase Storage port)
  - [ ] 117-06-PLAN.md — Import script + bio code-review gate + production run
  - [ ] 117-07-PLAN.md — Wave 0 verification SQL + shell smoke tests + human pre-May-1 smoke checklist
**UI hint**: yes

### Phase 118: Read & Rank Verdict Badge Fix
**Goal**: Verdict badges from Read & Rank sessions appear correctly on politician profile pages in production — the 10 Pierce quotes in the DB render as verdict badges in the StanceAccordion.
**Depends on**: Nothing
**Requirements**: RR-01, RR-02
**Success Criteria** (what must be TRUE):
  1. Verdict badges render on politician profile pages in production for politicians with existing DB quotes.
  2. A root cause document identifies exactly which layer caused the regression (CSS, prop wiring, ev-ui version mismatch, or feature flag).
**Plans**: 3 plans
  - [x] 118-01-PLAN.md — Hypothesis-first diagnosis (H1–H5) on both Pierce URLs × both auth paths; produce 118-DIAGNOSIS.md with root cause layer
  - [x] 118-02-PLAN.md — Apply minimal fix in the layer declared by diagnosis (checkpoint-gated); auto-bump pipeline if ev-ui; RR-02 root cause note in fix PR description
  - [x] 118-03-PLAN.md — Production verification 2×2 matrix on essentials.empowered.vote + cross-consumer smoke + user sign-off (D-16)
**UI hint**: yes

### Phase 119: Read & Rank Location Filter Repair
**Goal**: A voter entering a Monroe County address in Read & Rank sees only quotes from their local candidates — both the geocoding and filter logic work end-to-end.
**Depends on**: Nothing
**Requirements**: RR-03, RR-04
**Success Criteria** (what must be TRUE):
  1. Entering a Monroe County address in the Read & Rank location filter scopes the displayed quote list to Monroe County candidates only.
  2. Both filter mechanisms (geocoding wiring and filter predicate logic) are functional and verified against a Monroe County test address.
**Plans**: 2 plans
  - [x] 119-01-PLAN.md — End-to-end diagnosis: DB data audit, API/CORS smoke tests, frontend predicate inspection; produce 119-DIAGNOSIS.md
  - [x] 119-02-PLAN.md — Apply diagnosed fixes + zero-state empty message (D-06) + production verification checkpoint
**UI hint**: yes

### Phase 120: Contested-Race Bio + Photo Authoring
**Goal**: The small set of candidates in contested Monroe County May 5 races (D-61 IN House, IN-9 US House, contested county offices) have authored bios and sourced headshots — the highest-visibility profiles are complete before primary day.
**Depends on**: Nothing
**Requirements**: CONT-01, CONT-02
**Success Criteria** (what must be TRUE):
  1. Bios are authored and live in the DB for all candidates in contested Monroe County May 5 races (approximately 5–10 candidates).
  2. Headshots are sourced, uploaded to Supabase CDN, and rendering on profile pages for all contested-race candidates who lacked photos (including Todd Young).
**Plans**: 3 plans
  - [x] 120-01-PLAN.md — Candidate scoping audit + ev-ui bio_text render patch + bio methodology doc
  - [x] 120-02-PLAN.md — Content research + REVIEW-DATA.md compilation + user review checkpoint
  - [ ] 120-03-PLAN.md — Import script creation + production execution + profile verification checkpoint

### Phase 121: County Council D1→D4 Geofence Repair
**Goal**: A voter at a Kirkwood Ave Bloomington address is returned the correct Monroe County Council district — the D1→D4 binding bug is fixed and verified.
**Depends on**: Nothing
**Requirements**: GEO-01, GEO-02
**Success Criteria** (what must be TRUE):
  1. The Kirkwood Ave Bloomington test address resolves to the correct Monroe County Council district (D4, not D1) in the API response.
  2. The fix is validated using the same Kirkwood test address documented in MATRIX.md Dim 1 and the geofence smoke test script.
**Plans**: 4 plans
  - [ ] 121-01-PLAN.md — Wave 0 diagnosis: read-only MCC state dump, extend audit-112 smoke with Kirkwood exclusivity assertion, record ground-truth attestation
  - [ ] 121-02-PLAN.md — Wave 1 polygon import: fetch 4 MCC polygons from Monroe County GIS FeatureServer, insert 4 geofence_boundaries + 4 districts rows (idempotent)
  - [ ] 121-03-PLAN.md — Wave 2 re-link + local smoke: edit link-monroe-county-races-to-geofences.sql §2a/§2e/§3f, run green smoke on dev DB
  - [ ] 121-04-PLAN.md — Wave 3 doc correction + prod verify: correct GAP-REPORT.md PATTERN-004 wording, human-gated prod DB promotion + api.empowered.vote smoke

### Phase 122: Cross-App Loop Polish
**Goal**: The full Compass → Read & Rank → Essentials voter loop works without integration gaps — CompassCard state relays correctly, Compass links to Essentials profiles, and the Essentials→Treasury handoff is functional.
**Depends on**: Phase 118 (verdict badge fix must land first — same component surface)
**Requirements**: INTG-01, INTG-02, INTG-03
**Success Criteria** (what must be TRUE):
  1. CompassCard state relay works across app boundaries — data passed from Compass renders correctly on Essentials profile cards.
  2. The Compass compare page includes working links to Essentials politician profile pages for each politician in the picker.
  3. The Essentials→Treasury handoff is functional — relevant budget data is accessible from the Essentials context where documented (G-114-030, G-114-031).
**Plans**: 4 plans
  - [ ] 121-01-PLAN.md — Wave 0 diagnosis: read-only MCC state dump, extend audit-112 smoke with Kirkwood exclusivity assertion, record ground-truth attestation
  - [ ] 121-02-PLAN.md — Wave 1 polygon import: fetch 4 MCC polygons from Monroe County GIS FeatureServer, insert 4 geofence_boundaries + 4 districts rows (idempotent)
  - [ ] 121-03-PLAN.md — Wave 2 re-link + local smoke: edit link-monroe-county-races-to-geofences.sql §2a/§2e/§3f, run green smoke on dev DB
  - [ ] 121-04-PLAN.md — Wave 3 doc correction + prod verify: correct GAP-REPORT.md PATTERN-004 wording, human-gated prod DB promotion + api.empowered.vote smoke
**UI hint**: yes

### Phase 123: Photo Coverage Expansion
**Goal**: The 62-candidate photo gap (non-contested-race linked candidates) is addressed by extending the headshot scraping/sourcing pipeline.
**Depends on**: Phase 120 (contested-race photos delivered first)
**Requirements**: PHOTO-01
**Success Criteria** (what must be TRUE):
  1. The headshot scraping/sourcing pipeline is extended to cover non-contested-race linked candidates, reducing the unphoted candidate count from 62 toward zero.
**Plans**: 4 plans
  - [ ] 121-01-PLAN.md — Wave 0 diagnosis: read-only MCC state dump, extend audit-112 smoke with Kirkwood exclusivity assertion, record ground-truth attestation
  - [ ] 121-02-PLAN.md — Wave 1 polygon import: fetch 4 MCC polygons from Monroe County GIS FeatureServer, insert 4 geofence_boundaries + 4 districts rows (idempotent)
  - [ ] 121-03-PLAN.md — Wave 2 re-link + local smoke: edit link-monroe-county-races-to-geofences.sql §2a/§2e/§3f, run green smoke on dev DB
  - [ ] 121-04-PLAN.md — Wave 3 doc correction + prod verify: correct GAP-REPORT.md PATTERN-004 wording, human-gated prod DB promotion + api.empowered.vote smoke

### Phase 124: App-Wide Bio Authoring
**Goal**: Bios for the remaining ~45 linked candidates not covered by Phase 120 are authored and live, closing the platform-wide 0/51 bio gap that drives EV's lowest competitive matrix score.
**Depends on**: Phase 120 (contested-race batch authored first, methodology established)
**Requirements**: BIO-01, BIO-02
**Success Criteria** (what must be TRUE):
  1. Bios are authored and persisted in the DB for approximately 45 linked candidates not covered by Phase 120.
  2. A bio authoring methodology document exists in `.planning/` covering sourcing approach, tone, length, and antipartisan constraints — repeatable for future imports.
**Plans**: 4 plans
  - [ ] 121-01-PLAN.md — Wave 0 diagnosis: read-only MCC state dump, extend audit-112 smoke with Kirkwood exclusivity assertion, record ground-truth attestation
  - [ ] 121-02-PLAN.md — Wave 1 polygon import: fetch 4 MCC polygons from Monroe County GIS FeatureServer, insert 4 geofence_boundaries + 4 districts rows (idempotent)
  - [ ] 121-03-PLAN.md — Wave 2 re-link + local smoke: edit link-monroe-county-races-to-geofences.sql §2a/§2e/§3f, run green smoke on dev DB
  - [ ] 121-04-PLAN.md — Wave 3 doc correction + prod verify: correct GAP-REPORT.md PATTERN-004 wording, human-gated prod DB promotion + api.empowered.vote smoke

### Phase 125: Tier 2 UX Polish Bundle
**Goal**: The 21 Tier 2 G-114 minor/confusing UX gaps are addressed, improving platform polish without blocking any voter-critical flows.
**Depends on**: Nothing
**Requirements**: UX-01
**Success Criteria** (what must be TRUE):
  1. All 17 identified G-114 Tier 2 UX gaps (G-114-001/002/004/005/008/011/013/014/015/017/019/020/021/022/023/024/025) are resolved and verified in production.
**Plans**: 4 plans
  - [ ] 121-01-PLAN.md — Wave 0 diagnosis: read-only MCC state dump, extend audit-112 smoke with Kirkwood exclusivity assertion, record ground-truth attestation
  - [ ] 121-02-PLAN.md — Wave 1 polygon import: fetch 4 MCC polygons from Monroe County GIS FeatureServer, insert 4 geofence_boundaries + 4 districts rows (idempotent)
  - [ ] 121-03-PLAN.md — Wave 2 re-link + local smoke: edit link-monroe-county-races-to-geofences.sql §2a/§2e/§3f, run green smoke on dev DB
  - [ ] 121-04-PLAN.md — Wave 3 doc correction + prod verify: correct GAP-REPORT.md PATTERN-004 wording, human-gated prod DB promotion + api.empowered.vote smoke
**UI hint**: yes

### Phase 126: Geofence Hardening
**Goal**: Rural Monroe County addresses resolve correctly through the geofence stack, and 11 missing township geofences are imported for precinct-level precision.
**Depends on**: Phase 121 (County Council D1 fix must land first)
**Requirements**: INFRA-01, INFRA-02
**Success Criteria** (what must be TRUE):
  1. Rural address geocoding failures (e.g., Mt Tabor Rd) are diagnosed, root-caused, and repaired — the address resolves to the correct representatives.
  2. All 11 missing Monroe County township geofences are imported into the geofences table and validated against test addresses in each township.
**Plans**: 4 plans
  - [ ] 121-01-PLAN.md — Wave 0 diagnosis: read-only MCC state dump, extend audit-112 smoke with Kirkwood exclusivity assertion, record ground-truth attestation
  - [ ] 121-02-PLAN.md — Wave 1 polygon import: fetch 4 MCC polygons from Monroe County GIS FeatureServer, insert 4 geofence_boundaries + 4 districts rows (idempotent)
  - [ ] 121-03-PLAN.md — Wave 2 re-link + local smoke: edit link-monroe-county-races-to-geofences.sql §2a/§2e/§3f, run green smoke on dev DB
  - [ ] 121-04-PLAN.md — Wave 3 doc correction + prod verify: correct GAP-REPORT.md PATTERN-004 wording, human-gated prod DB promotion + api.empowered.vote smoke

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 116. Quick Correctness Fixes | 1/1 | Complete   | 2026-04-15 |
| 117. Candidate Stub Resolution + Data Import | 0/? | Not started | - |
| 118. Read & Rank Verdict Badge Fix | 3/3 | Complete    | 2026-04-16 |
| 119. Read & Rank Location Filter Repair | 2/2 | Complete    | 2026-04-16 |
| 120. Contested-Race Bio + Photo Authoring | 2/3 | In Progress|  |
| 121. County Council D1→D4 Geofence Repair | 0/4 | Not started | - |
| 122. Cross-App Loop Polish | 0/? | Not started | - |
| 123. Photo Coverage Expansion | 0/? | Not started | - |
| 124. App-Wide Bio Authoring | 0/? | Not started | - |
| 125. Tier 2 UX Polish Bundle | 0/? | Not started | - |
| 126. Geofence Hardening | 0/? | Not started | - |

---

## Coverage

**Requirements mapped:** 25/25

| REQ-ID | Phase |
|--------|-------|
| CORR-01 | 116 |
| CORR-02 | 116 |
| CORR-03 | 116 |
| CAND-01 | 117 |
| CAND-02 | 117 |
| CAND-03 | 117 |
| CAND-04 | 117 |
| CAND-05 | 117 |
| RR-01 | 118 |
| RR-02 | 118 |
| RR-03 | 119 |
| RR-04 | 119 |
| CONT-01 | 120 |
| CONT-02 | 120 |
| GEO-01 | 121 |
| GEO-02 | 121 |
| INTG-01 | 122 |
| INTG-02 | 122 |
| INTG-03 | 122 |
| PHOTO-01 | 123 |
| BIO-01 | 124 |
| BIO-02 | 124 |
| UX-01 | 125 |
| INFRA-01 | 126 |
| INFRA-02 | 126 |

No orphaned requirements. No duplicates.
