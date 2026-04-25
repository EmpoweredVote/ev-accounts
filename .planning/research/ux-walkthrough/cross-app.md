# Cross-App Integration Pass (per CONTEXT D-09)

**Run date:** 2026-04-13
**Phase:** 114-ux-walkthrough, Plan 114-06
**Framing:** Per D-09, this is an integration pass layered on top of the per-app walks (114-02..05). Each stitching link is walked discretely — this is NOT a merged single-session journey. The per-app walks answer "is each app useful?"; this pass answers "does the voter flow between apps, or do they get stuck at boundaries?"
**Address:** 200 W Kirkwood Ave, Bloomington, IN 47404
**Screenshots:** `screenshots/cross-app/` (13 PNGs)
**Gaps appended:** G-114-026 through G-114-031

---

## 1. SiteHeader Cross-App Nav (guest)

**Evidence:** `screenshots/cross-app/00-essentials-landing-baseline.png`, `01-siteheader-essentials-to-compass.png`, `02-siteheader-essentials-to-readrank.png`, `03-siteheader-essentials-to-treasury.png`

All four apps (Essentials, Compass, Read & Rank, Treasury Tracker) share a common SiteHeader with nav links to each other. The nav is consistent across apps and correctly surfaces all four products as a unified suite. However, two critical problems were discovered:

**Problem 1 — Treasury Tracker nav link points to the retired Netlify prototype URL.** The "Treasury Tracker" nav link in the SiteHeader resolves to `https://ev-prototypes.netlify.app/treasury-tracker/dist` — the old EV-prototypes Netlify deployment — not the production `https://treasurytracker.empowered.vote/`. Similarly, "Empowered Badges" links to `https://ev-prototypes.netlify.app/empowered-badges/dist`. A voter clicking "Treasury Tracker" from any app is routed to the stale prototype URL instead of the live Render deployment. (→ G-114-026)

**Problem 2 — No auth state persistence between apps.** Read & Rank and Treasury Tracker show a "Sign in" link in their SiteHeader, indicating the guest session from Essentials or Compass does not carry over. Each app has its own independent auth state; there is no shared session cookie or token relay. This is not a blocker for the guest flow (all apps are accessible without login), but a logged-in voter who leaves one app loses their auth context when they navigate to another. (→ G-114-027)

The Compass SiteHeader correctly redirects to `/results` (the live compare page) rather than `/` when navigating to Compass from another app — the app respects the stored calibration result on the device. No gap logged for this behavior.

---

## 2. Politician Profile → CompassCard

**Evidence:** `screenshots/cross-app/04-profile-compasscard.png`, `04a-essentials-results-for-address.png`

Matt Pierce's Essentials profile at `/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa` renders a "Compass & Issues" section below the legislative activity. The section shows Matt Pierce's 19 stance entries in a "Stance Breakdown" accordion (e.g., Healthcare, Abortion, Taxes, Same-Sex Marriage) and a "Calibrate your compass" CTA button. The CTA links to `https://compass.empowered.vote/?return=https://essentials.empowered.vote/candidate/7e768cda-...`, correctly passing a return URL so the voter can navigate back to the profile after calibrating.

This stitching link is functional and represents the strongest cross-app integration in the product. However, the hand-off is one-directional: the Compass app renders a calibration prompt rather than immediately showing the comparison result inline. A voter who has already calibrated their Compass sees the same "Calibrate your compass" prompt as a voter who has not. (→ G-114-028)

---

## 3. Politician Profile → Read & Rank Verdict Badges (StanceAccordion)

**Evidence:** `screenshots/cross-app/05-profile-stanceaccordion-readrank-badges.png`, `09-pierce-profile-full.png`, `13-pierce-profile-bottom-scroll.png`

Scrolling through the full Matt Pierce profile (page height 1743px) and checking the full DOM text, there is **no Read & Rank section, no StanceAccordion, and no verdict badge display anywhere on the profile page**. The term "Read & Rank" appears only in the SiteHeader navigation link — not as a section header, not as a badge, not as a CTA within the profile body.

`AUDIT-REPORT-112.md §AUDIT-04` confirms 10 sourced quotes are linked to Matt Pierce in the DB. Despite 10 quotes existing, the profile surfaces none of them. The CLAUDE.md documentation describes "Read & Rank verdict badges under StanceAccordion" as an existing integration in `ev-ui/src/PoliticianProfile.jsx` — the voter-side walkthrough confirms this integration is either not rendering or was not deployed to the current production build of Essentials. (→ G-114-029)

---

## 4. Compass Politician Picker → Candidate Record

**Evidence:** `screenshots/cross-app/06-compass-results-before-picker.png`, `06-compass-picker-to-candidate.png`

Navigating directly to `https://compass.empowered.vote/results` without an active calibration session causes the Compass app to render an onboarding/CTA screen ("Get Started" / "Skip for now") rather than the compare picker. No politician picker is accessible in the guest unauthenticated, uncalibrated state. All links on the Compass results page in this state are SiteHeader navigation links — there are zero deep-links from the Compass results page back to Essentials candidate profiles.

The Compass picker's "Indiana" filter, examined in the 114-03 walk, shows sitting officials only — no primary challengers. Even when the picker is accessible (after calibration), it does not link to Essentials candidate records; it only adds the politician to the Compass radar overlay for comparison. There is no "View profile in Essentials" link or CTA from the Compass compare panel to the corresponding Essentials politician profile. (→ G-114-030)

---

## 5. Essentials → Treasury Hand-Off

**Evidence:** `screenshots/cross-app/07-essentials-to-treasury-handoff.png`

Checking the Essentials results page (`/results?q=200+W+Kirkwood+Ave...`) and the Matt Pierce politician profile for any contextual link to Treasury Tracker: **none exists.** The only Treasury Tracker link from Essentials is in the shared SiteHeader nav — and that SiteHeader link points to the stale Netlify URL (see G-114-026). There is no contextual hand-off such as "Explore Bloomington's budget → Treasury Tracker" anywhere in the Essentials results flow, Election Central, or politician profile pages.

This is a feature gap: a voter who has just learned about their city council representative has no in-flow prompt to explore that representative's budget context in Treasury Tracker. The two apps exist in parallel with no content linking between them. (→ G-114-031)

---

## 6. Read & Rank → Essentials Verdict Flow-Back (guest URL fragment)

**Evidence:** `screenshots/cross-app/08-readrank-to-essentials-verdict.png`, `08a-readrank-landing-for-verdict-check.png`, `11-rr-topic-list-skip-practice.png`

The Read & Rank topic list page, after skipping practice, shows only the SiteHeader "Find Representatives" link to Essentials — a generic homepage link, not a per-politician deep-link with a URL fragment. The 114-04 walk confirmed that per-politician "View on Essentials" links with `#compass=` fragment ARE rendered in the "See Who Said It" reveal screen inside individual topic sessions (per the accessibility snapshot captured in 114-04). However, the broader topic list page (the main UI) does not surface any such link.

The verdict flow-back mechanism exists at the topic-reveal layer but is buried inside each topic's reveal state. A voter who completes a topic and returns to the topic list has no persistent navigation path from the post-completion state back to the politicians they just evaluated. The cross-app text "Your verdicts appear on candidate profiles in Essentials" on the topic list has no hyperlink (documented as G-114-019 in the per-app walk) — this creates the stitching gap. The fragment-based flow-back IS technically implemented but its discoverability is zero from the topic list level.

---

## 7. Gap Summary (IDs only)

Cross-app gaps introduced in this plan:

| ID | Description | Severity | Type |
|----|-------------|----------|------|
| G-114-026 | SiteHeader Treasury Tracker + Empowered Badges links point to retired Netlify prototype URLs | blocker | feature |
| G-114-027 | No auth state relay between apps — logged-in session lost on cross-app navigation | confusing | ux-friction |
| G-114-028 | Profile CompassCard always shows "Calibrate" prompt — no result shown for already-calibrated visitors | confusing | ux-friction |
| G-114-029 | Read & Rank verdict badges not rendered on politician profile despite 10 linked quotes | blocker | feature |
| G-114-030 | Compass compare panel has no "View in Essentials" link — picker is a dead end for candidate exploration | confusing | feature |
| G-114-031 | No contextual Essentials → Treasury hand-off link anywhere in the results or profile flow | confusing | feature |

All 6 entries have `app: cross-app`. Combined total gap count: G-114-001 through G-114-031 = 31 gaps.
