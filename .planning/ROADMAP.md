# Roadmap — Empowered Vote Platform

## Milestones

- ✅ **v2026.4.4 Indiana Primary Fix Wave** — Phases 116–125 (shipped 2026-04-18)
- 📋 **v2026.4.5 Compass-First Politician Card** — Phases 127–129 (planning, 2026-04-18)

---

## Phases

<details>
<summary>✅ v2026.4.4 Indiana Primary Fix Wave (Phases 116–125) — SHIPPED 2026-04-18</summary>

- [x] Phase 116: Quick Correctness Fixes (1/1 plans) — completed 2026-04-15
- [ ] Phase 117: Candidate Stub Resolution + Data Import — deferred to next milestone
- [x] Phase 118: Read & Rank Verdict Badge Fix (3/3 plans) — completed 2026-04-16
- [x] Phase 119: Read & Rank Location Filter Repair (2/2 plans) — completed 2026-04-16
- [~] Phase 120: Contested-Race Bio + Photo Authoring (2/3 plans) — content researched, import deferred
- [x] Phase 121: County Council D1→D4 Geofence Repair (4/4 plans) — completed 2026-04-17
- [x] Phase 122: Cross-App Loop Polish (1/1 plans) — completed 2026-04-17
- [x] Phase 123: Photo Coverage Expansion (3/3 plans) — completed 2026-04-17
- [ ] Phase 124: App-Wide Bio Authoring — deferred to next milestone
- [x] Phase 125: Tier 2 UX Polish Bundle (4/4 plans) — completed 2026-04-18
- [ ] Phase 126: Geofence Hardening — deferred to next milestone

See full details: [milestones/v2026.4.4-ROADMAP.md](milestones/v2026.4.4-ROADMAP.md)

</details>

### 📋 v2026.4.5 Compass-First Politician Card (Planning)

**Milestone goal:** Ship a compass-first horizontal politician card across Essentials (and ev-ui), based on the existing `/prototype` variant C, while preserving current card metadata and handling cases where a compass doesn't apply.

**Shared branch:** `feat/compass-first-card` (essentials, ev-ui, CompassV2)
**Granularity:** standard
**Requirements coverage:** 10/10 v1 requirements mapped

- [x] **Phase 127: CompassCardHorizontal in ev-ui** — Publish the horizontal compass-first card component with dual-view toggle and preserved affordances (completed 2026-04-19)
- [ ] **Phase 128: Empty & Non-Compass Variants** — Add placeholder, administrative, and judicial variants for cases where a compass doesn't apply
- [ ] **Phase 129: Essentials Adoption & Prototype Retirement** — Replace existing cards on Representatives and Elections pages; retire `/prototype`; ship via auto-bump

**Deferred carryovers (not in v2026.4.5 scope unless explicitly re-added):**

- Phase 117: Candidate Stub Resolution + Data Import (CAND-01–CAND-05)
- Phase 120-03: Contested-Race Bio Import Execution (content ready in 120-REVIEW-DATA.md)
- Phase 124: App-Wide Bio Authoring — ~45 candidates (BIO-01, BIO-02)
- Phase 126: Geofence Hardening — rural addresses + 11 missing townships (INFRA-01, INFRA-02)

---

## Phase Details (v2026.4.5)

### Phase 127: CompassCardHorizontal in ev-ui
**Goal**: A production-ready horizontal compass-first card component is available in `@empoweredvote/ev-ui` with view toggle and full metadata parity with the existing PoliticianCard.
**Depends on**: Nothing (first phase of milestone)
**Requirements**: CARD-01, CARD-02, CARD-03
**Success Criteria** (what must be TRUE):
  1. A consumer app importing `CompassCardHorizontal` from `@empoweredvote/ev-ui` can render a card with radar on the left and politician metadata on the right, matching the `/prototype` variant C layout
  2. A user viewing a rendered card can toggle between compass (radar) view and portrait/photo view, and the toggle choice sticks while the user stays on the page (or across sessions per decision in discuss-phase)
  3. A card rendered for a politician with tier/branch/term data shows all current PoliticianCard affordances (tier/branch badges, elected/appointed marker, unopposed icon, term dates, years-in-office, chamber/district subtitle, initials fallback) with no regression versus today
  4. Component props accept a politician object, the user's compass answers, and tier/branch visuals; a prototype harness demonstrates all three
**Plans**: 3 plans
- [x] 127-01-PLAN.md — Scaffold @floating-ui peer dep + port PlaceholderRadar + port IconOverlay (leaf primitives)
- [x] 127-02-PLAN.md — Build CompassCardHorizontal + Meta + compassHelpers; add barrel exports
- [x] 127-03-PLAN.md — Update essentials Prototype harness + view toggle persistence + human-verify checkpoint
**UI hint**: yes

### Phase 128: Empty & Non-Compass Variants
**Goal**: Users see an appropriate card variant for every politician, including those where a compass doesn't apply (low user answers, administrative roles, judicial roles).
**Depends on**: Phase 127
**Requirements**: STATE-01, STATE-02, STATE-03
**Success Criteria** (what must be TRUE):
  1. A user with fewer than 3 compass topics answered sees a placeholder radar on every compass-eligible card with a "Build your compass" CTA that deep-links into CompassV2 calibration for the relevant topics
  2. A user viewing a clerk, auditor, recorder, treasurer, or similar administrative role sees a portrait-forward non-compass variant with role-appropriate content replacing the radar (content spec finalized during discuss-phase)
  3. A user viewing a judicial role sees a judge-appropriate non-compass variant (e.g., retention history, court level, appointment source — spec finalized during discuss-phase)
  4. A user viewing the representatives page sees retention judges appear in both elected and appointed filter views, matching existing dual-appearance behavior
**Plans**: 4 plans
- [x] 128-01-PLAN.md — Wave 0: export computeVariant from classify.js + Vitest coverage for STATE-01/02/03
- [x] 128-02-PLAN.md — Wave 1: extend ev-ui CompassCardHorizontal with variant + onBuildCompass props (empty CTA + unavailable plate render paths)
- [x] 128-03-PLAN.md — Wave 2: switch essentials Prototype.jsx to CompassCardHorizontal + computeVariant + COMPASS_URL deep-link handler
- [ ] 128-04-PLAN.md — Wave 3: bump ev-ui to next minor (new public API) and verify auto-bump pipeline reaches consumers
**UI hint**: yes

### Phase 129: Essentials Adoption & Prototype Retirement
**Goal**: The compass-first card is the live card on Essentials Representatives and Elections pages, the `/prototype` route is retired or reduced, and the ev-ui bump reaches production via the auto-bump pipeline without breaking CompassV2 or the compare picker.
**Depends on**: Phase 127, Phase 128
**Requirements**: ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04
**Success Criteria** (what must be TRUE):
  1. A user visiting the Essentials representatives page sees the new compass-first card for every politician, with existing sort/filter controls, elected/appointed filter, and scroll-spy tier background bands still functioning
  2. A user visiting the Essentials elections page sees incumbents rendered with the full compass card and challengers rendered with the appropriate empty/minimal variant
  3. A user visiting `/prototype` on production Essentials is either redirected away or sees only an internal reference note — the duplicate UI surface no longer exists for end users
  4. After the ev-ui version is bumped via the auto-bump pipeline and merged on `main`, both Essentials (live card) and CompassV2 (compare picker) render correctly in production without visual or functional regression
**Plans**: 3 plans
Plans:
- [x] 129-01-PLAN.md — Retire /prototype route and delete prototype-only files
- [x] 129-02-PLAN.md — Remove CompassPreview popover from Results.jsx and delete component
- [ ] 129-03-PLAN.md — End-to-end verification (build + Reps/Elections smoke-test)
**UI hint**: yes

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 116. Quick Correctness Fixes | v2026.4.4 | 1/1 | Complete | 2026-04-15 |
| 117. Candidate Stub Resolution | v2026.4.4 | 0/7 | Deferred | - |
| 118. Read & Rank Verdict Badge Fix | v2026.4.4 | 3/3 | Complete | 2026-04-16 |
| 119. Read & Rank Location Filter Repair | v2026.4.4 | 2/2 | Complete | 2026-04-16 |
| 120. Contested-Race Bio + Photo Authoring | v2026.4.4 | 2/3 | Partial | - |
| 121. County Council D1→D4 Geofence Repair | v2026.4.4 | 4/4 | Complete | 2026-04-17 |
| 122. Cross-App Loop Polish | v2026.4.4 | 1/1 | Complete | 2026-04-17 |
| 123. Photo Coverage Expansion | v2026.4.4 | 3/3 | Complete | 2026-04-17 |
| 124. App-Wide Bio Authoring | v2026.4.4 | 0/4 | Deferred | - |
| 125. Tier 2 UX Polish Bundle | v2026.4.4 | 4/4 | Complete | 2026-04-18 |
| 126. Geofence Hardening | v2026.4.4 | 0/4 | Deferred | - |
| 127. CompassCardHorizontal in ev-ui | v2026.4.5 | 3/3 | Complete   | 2026-04-19 |
| 128. Empty & Non-Compass Variants | v2026.4.5 | 3/4 | In Progress|  |
| 129. Essentials Adoption & Prototype Retirement | v2026.4.5 | 2/3 | In Progress|  |
