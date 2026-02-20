# Phase 14: Guided Onboarding Flow - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the blank compass experience for first-time users (or users with fewer than 3 topics) with a guided, full-screen calibration flow. Users pick topics upfront, answer them one at a time with the compass rendering live, then land on a usable compass. Also: remove "Start Quiz" from Library, rebrand "quiz" to "calibrate", add spoke-click-to-drawer on compass page, and add a "Reset compass" option.

</domain>

<decisions>
## Implementation Decisions

### Overlay entry point
- Full-screen takeover when user has fewer than 3 answered compass topics
- Welcome screen with instructional tone: explains the mechanic directly (e.g., "Answer a few questions to build your political compass")
- Welcome screen includes a faint/ghost radar chart outline to hint at what they're building
- "Calibrate your Compass" CTA button to begin
- "Skip for now" link available — takes user to the empty compass page (which shows Phase 13's minimum-3 progress dots)
- Onboarding triggers at <3 answered compass topics, not just at zero

### Topic selection step
- After tapping CTA, user sees all available topics and picks 3-8 upfront before answering
- Free pick with soft hint — subtle text like "pick at least 3" but no hard block until they try to proceed with fewer than 3
- After selecting, topics are presented one at a time for stance answering

### Card-by-card flow
- Keep existing stance selection UI (Strongly Agree / Agree / Neutral / Disagree / Strongly Disagree buttons)
- Rebrand all "quiz" language to "calibrate" throughout the app
- No fancy card transitions — keep the existing flow style
- No progress indicator (topic number) — the compass itself serves as progress since spokes appear as they answer
- Back button available to revisit and change a previous answer
- Layout: compass on the left, topic card on the right (same as existing)

### Live compass rendering
- User data only (pink overlay) during onboarding — no comparison dataset
- New spokes animate in (spring/grow effect from center) when a topic is answered
- When going back and changing a stance, the spoke animates smoothly to its new position

### Exit & completion
- Users are expected to answer all topics they selected — if they try to exit early, warn that unanswered topics will be removed from their compass
- After answering all selected topics: brief completion moment ("Your compass is ready!") with the completed chart, then transition to normal compass page
- If user leaves mid-onboarding (closes tab, navigates away): resume where they left off when they return (persist onboarding progress)
- If user drops below 3 topics after onboarding (via removal): show Phase 13 minimum warning, do NOT re-trigger onboarding overlay

### Spoke interaction (compass page)
- Clicking a compass spoke opens the LibraryDrawer for that topic, overlaid on the compass page (no navigation away)
- Replaces the current spoke-click-to-swap behavior

### Reset compass
- Settings/menu icon on compass page with "Reset compass" option
- Confirmation dialog before wiping: explains all topics and stances will be removed and they'll go through calibration again
- After reset: onboarding overlay re-triggers (user is back to zero topics)

### Library page cleanup
- Remove "Start Quiz" fixed bottom button — the calibration overlay on the compass page serves this entry point

### Claude's Discretion
- Exact welcome screen copy and layout
- Ghost radar chart visual treatment
- Topic picker grid/list layout
- Completion celebration design
- Settings menu icon style and placement
- LocalStorage schema for persisting onboarding progress

</decisions>

<specifics>
## Specific Ideas

- The compass during onboarding works exactly like the existing quiz layout (compass left, card right) but rebranded as "calibrate"
- Spoke animations should use react-spring (already in RadarChartCore)
- The LibraryDrawer is reused on the compass page, not a new component — just needs to be portable outside the Library page context

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-guided-onboarding-flow*
*Context gathered: 2026-02-19*
