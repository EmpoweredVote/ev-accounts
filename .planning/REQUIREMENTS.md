# Milestone v2026.4.5 Requirements — Compass-First Politician Card

**Goal:** Ship a compass-first horizontal politician card (based on the existing `/prototype` variant C) across Essentials, with a view toggle, preserved card metadata, and non-compass variants for roles without a meaningful compass.

## Active Requirements

### CARD — Compass-first card component (ev-ui)

- [ ] **CARD-01**: Publish a `CompassCardHorizontal` component in `@empoweredvote/ev-ui` based on Prototype variant C (horizontal radar-left / meta-right layout), with props for politician, user compass answers, and tier/branch visuals
- [ ] **CARD-02**: Card supports a dual-view toggle between compass (radar) view and portrait/photo view; toggle state persists per page (or per user preference — decided in discuss-phase)
- [ ] **CARD-03**: Card preserves all existing PoliticianCard affordances without regression — tier/branch badges, elected/appointed marker, unopposed icon, term dates, years-in-office, chamber/district subtitle, initials fallback

### STATES — Empty and non-compass variants

- [ ] **STATE-01**: When the user has insufficient compass answers (<3 topics), card renders a placeholder radar with a "Build your compass" CTA deep-linking to CompassV2 calibration for the relevant topics
- [ ] **STATE-02**: Administrative roles (clerks, auditors, recorders, treasurers, and similar non-policy offices) render a non-compass variant — portrait-forward layout with role-appropriate content replacing the radar (content spec defined in discuss-phase)
- [ ] **STATE-03**: Judicial roles render a judge-appropriate non-compass variant (retention history / court level / appointment source — spec defined in discuss-phase); retention judges continue their existing dual-appearance behavior on the representatives page

### ADOPTION — Wire into Essentials

- [ ] **ADOPT-01**: Representatives page politician cards replaced with the new compass-first card, preserving existing sort/filter controls, elected/appointed filter, and scroll-spy background bands
- [ ] **ADOPT-02**: Elections page candidate cards adopt the new card — incumbents use full compass, challengers use appropriate empty/minimal variant
- [x] **ADOPT-03**: `/prototype` route retired or reduced to an internal reference once adoption ships, to prevent UI drift
- [ ] **ADOPT-04**: ev-ui version bumped via the auto-bump pipeline; essentials and CompassV2 compass picker continue to render correctly on main after merge

## Future Requirements

(none at this time — will grow as discuss-phase uncovers additions)

## Out of Scope

- Rewriting the underlying RadarChartCore — current chart is used as-is (only consumer layout changes)
- Changing compass topic data model — the card reads existing user answers and politician stances
- Read & Rank verdict badge relocation — stays in StanceAccordion as today
- Additions to BallotReady / geofence / election data models — data layer is stable from v2026.4.4

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CARD-01 | Phase 127 | Pending |
| CARD-02 | Phase 127 | Pending |
| CARD-03 | Phase 127 | Pending |
| STATE-01 | Phase 128 | Pending |
| STATE-02 | Phase 128 | Pending |
| STATE-03 | Phase 128 | Pending |
| ADOPT-01 | Phase 129 | Pending |
| ADOPT-02 | Phase 129 | Pending |
| ADOPT-03 | Phase 129 | Complete |
| ADOPT-04 | Phase 129 | Pending |

**Coverage:** 10/10 requirements mapped, no orphans, no duplicates.

---

**Shared branch:** `feat/compass-first-card` (essentials, ev-ui, CompassV2)
