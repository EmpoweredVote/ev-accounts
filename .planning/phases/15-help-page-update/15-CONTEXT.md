# Phase 15: Help Page Update - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Update the /help page to accurately describe the compass and Library after v1.2 changes. The current 5-slide GIF walkthrough references the obsolete "Start Quiz" flow and must be rewritten to reflect the calibration overlay, drawer-based Library interactions, and new compass onboarding. Also wire auto-routing so first-time users see the help walkthrough before using the app.

</domain>

<decisions>
## Implementation Decisions

### Content structure
- Keep the carousel (step-by-step slide) format
- Slides should mirror the actual user flow: Welcome → Calibrate (overlay) → Explore Library (drawer) → Compare → Done
- Claude determines the right number of slides to cover this flow (may be more or fewer than 5)
- Keep content high-level — don't mention specific limits (3-8 topics) or settings (reset compass)
- Compare with Candidates slide stays — feature is still active
- Welcome slide keeps current branding: "Welcome to the Empowered Compass!"
- Final slide points to /compass (not /library) since calibration overlay is the new starting point

### Content medium
- Replace GIFs with static screenshots of the current UI
- Capture real screenshots during execution (Playwright or manual), not placeholders
- Responsive screenshots: capture both mobile and desktop versions of each slide
- Mobile users see mobile screenshots, desktop users see desktop screenshots (responsive swap, not side-by-side)

### Tone and depth
- Friendly and encouraging tone — same energy as current ("You're ready to begin!")
- Primary audience: first-time users who haven't seen the app
- Title + 1-2 sentence description per slide (same density as current)
- Keep copy general — describe the experience, not specific UI elements (e.g., "explore topics on your compass" not "tap a spoke to open the topic drawer")

### Post-help destination
- Final slide uses a CTA button (e.g., "Calibrate Your Compass") instead of generic "Done"
- Close (X) button navigates to /compass instead of /library
- Keep the /auth/complete-onboarding API call on completion for logged-in users
- Auto-route first-time users to /help — users without the onboarding flag get redirected before using the app

### Claude's Discretion
- Exact number of slides (should fit the new flow naturally)
- Slide copy wording (within the friendly/general guidelines)
- Screenshot composition and framing
- How to detect "first visit" for auto-routing (localStorage flag, onboarding API status, etc.)

</decisions>

<specifics>
## Specific Ideas

- Keep "Welcome to the Empowered Compass!" as the opening title
- CTA on final slide should say something like "Calibrate Your Compass" to set up what happens next
- Screenshots should show real app state (not empty/mock data)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 15-help-page-update*
*Context gathered: 2026-02-19*
