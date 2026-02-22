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


## v1.2 Compass Onboarding & UX (Shipped: 2026-02-20)

**Phases completed:** 6 phases, 12 plans, 27 tasks
**Timeline:** 2 days (2026-02-18 - 2026-02-20)
**Requirements:** 15/15 satisfied
**Repos:** CompassV2, EV-Backend

**Delivered:** Compass quiz made intuitive for first-time users with guided card-by-card onboarding, topic selection enforcement, and a complete question framing overhaul.

**Key accomplishments:**
1. Guided onboarding flow — CalibrationOverlay on empty compass walks new users through topic selection card-by-card with live radar rendering
2. Topic selection enforcement — 8-topic cap and 3-topic minimum enforced across all paths (Library, onboarding, quiz)
3. Library UX improvements — default "All" filter, on-compass card indicators with add/remove toggle, X/8 counter badge
4. Question framing overhaul — rebranded to "Where do you stand on [topic]?" with 7 vague topic titles rewritten in database
5. Help page & auto-routing — 5-slide walkthrough with responsive screenshots, HelpGuard routes new users through /help first
6. Audit gap closure — fixed non-admin compass reset (403 bug), synced help_seen from DB completed_onboarding flag, removed unused imports

**Tech debt carried forward:**
- BallotReady transform.go doesn't map SubAreaName to RepresentingCity — frontend workaround in Results.jsx
- Settings gear placement and spoke inversion persistence across views — cosmetic, deferred
- QFRM-02 topic title rewrites are database-only (needs live server to verify display)

---


## v1.3 Compass Bug Fixes & Title Standardization (Shipped: 2026-02-22)

**Phases completed:** 4 phases, 7 plans
**Timeline:** 2 days (2026-02-20 - 2026-02-21)
**Requirements:** 7/7 satisfied
**Repos:** CompassV2, EV-Backend, ev-ui

**Delivered:** Compass topic naming standardized server-side, calibration flow fixed for all mixed-state edge cases, and double-overlay compare bug eliminated.

**Key accomplishments:**
1. Title standardization — all 21 compass topics use tension title format (Topic: Pole A — Pole B) as server-side canonical source of truth, with deprecated ShortName/StartPhrase columns dropped
2. Unified topic display — parseTensionTitle helper renders consistent two-line layout across Library cards, calibration cards, compass spoke labels, quiz, and compare panel
3. Calibration auto-routing — users with unanswered topics auto-enter calibration starting at first unanswered topic, with resume flow that skips pick step and exit gating until 3+ answered
4. Mixed-state radar chart — gray dashed unanswered spokes in RadarChartCore, below-3 threshold shows grayed chart overlay with calibration CTA instead of dead end
5. Compare bug fix — single polygon rendering with spoke-order iteration and immediate spring reset, published as ev-ui@0.1.21
6. Anti-partisan design — pole order randomized per topic (10 right-first, 11 left-first) to prevent visual bias

**Tech debt carried forward:**
- compassimport/models.go and cmd/seed/compass_csv_seeder.go still reference dropped StartPhrase column — standalone CLI tools, would fail at runtime
- Admin TopicEditor sends short_name in PATCH body (silently ignored) and initializes vestigial editedFields.short_name
- BallotReady transform.go SubAreaName → RepresentingCity mapping fix — frontend workaround in Results.jsx (carried from v1.1)

---

