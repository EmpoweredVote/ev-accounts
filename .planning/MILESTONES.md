# Milestones

## v1.0 Quality & Consolidation (Shipped: 2026-02-18)

**Phases completed:** 7 phases, 21 plans
**Timeline:** 9 days (2026-02-10 - 2026-02-18)
**Requirements:** 21/21 satisfied
**Repos:** CompassV2, EV-Backend, ev-ui, essentials

**Delivered:** Platform hardened for demo-ready quality — guest-first compass, visual polish, interactive library, candidate support, and full auth audit.

**Key accomplishments:**
1. Guest-first compass — users take the full quiz without logging in, with localStorage persistence and server-wins merge on registration
2. Compass visual polish — chart fits viewport without scrolling, labels handle overflow gracefully, spoke visual artifacts removed
3. Compass UX enhancements — question prompts on issue cards, seeded stance randomization, interactive Library drawer with write-in support, level badges
4. Essentials candidate support — opt-in candidate toggle alongside officials, election dates, building imagery, federal legislative-first reordering
5. Auth hardening — middleware unit tests, integration test suite, 62-route audit manifest, admin-only clear compass
6. Integration quality — 3 audit gaps closed (guest console noise, register navigation, buildGuestState race condition)

**Tech debt carried forward:**
- RadarChart.jsx: Large commented-out block (dead code)
- ~~Building images: SVG placeholders~~ — resolved in v1.1 (real photographs added)
- CompassV2 pins ev-ui ^0.1.16 (essentials pins ^0.1.17) — functional, not blocking

---


## v1.1 Essentials UX Polish (Shipped: 2026-02-19)

**Phases completed:** 3 phases, 3 plans, 7 tasks
**Timeline:** 1 day (2026-02-18)
**Requirements:** 10/10 satisfied
**Repos:** essentials, ev-ui

**Delivered:** Essentials app polished for demo-ready UX — sticky sidebar layout, real building photographs, and contextual term dates on profile pages.

**Key accomplishments:**
1. Sticky sidebar layout — FilterSidebar stays fixed while representatives panel scrolls independently on desktop, with IntersectionObserver scoped to the scrolling container
2. Real building photographs — 5 government building JPEGs from Wikimedia Commons replace SVG placeholders for Bloomington and LA locations
3. Term dates relocated — removed from dashboard card clutter, now display contextually on politician profile pages with en-dash formatting
4. ev-ui 0.1.19 — shared component library updated with term date helpers (formatTermDate/getTermLine)

**Tech debt carried forward:**
- RadarChart.jsx: Large commented-out block (dead code) — carried from v1.0
- CompassV2 pins ev-ui ^0.1.16 (essentials now ^0.1.19) — functional, not blocking
- BallotReady transform.go doesn't map SubAreaName to RepresentingCity — frontend workaround in Results.jsx

---

