# Compass Voter-Side Walkthrough (UX-02)

**Persona:** First-time Monroe County voter preparing for the May 5, 2026 Indiana primary
**Address context:** 200 W Kirkwood Ave, Bloomington, IN 47404 (same persona as Essentials walk)
**Environment:** Production — https://compass.empowered.vote/
**Date:** 2026-04-13
**Method:** Playwright MCP — full calibration quiz auto-advanced via `browser_evaluate`, Build topic selection via real Playwright clicks, compare picker filtered to Indiana
**Screenshots:** 9 PNGs in `screenshots/compass/`
**Gaps appended:** G-114-011 through G-114-015

---

## §1 — Overview

The Compass walk covers four distinct phases of the voter experience: (1) the landing topic library, (2) the 33-question full calibration quiz, (3) the Build topic selection screen, and (4) the radar results page with the politician compare feature. Each phase surfaces distinct voter-facing gaps.

The central framing question for this walk: **Can a Monroe County primary voter use Compass to make informed decisions about candidates on the May 5 ballot?** The short answer is "partially" — Compass works well for understanding your own stance geometry and comparing against elected sitting officials, but it cannot support direct comparison against any of the contested primary challengers on the May 5 ballot. That finding is the single most important output of this walk.

---

## §2 — Landing Page

**URL:** https://compass.empowered.vote/ | **Screenshot:** 01-landing.png

The landing page presents the full topic library — a grid of 21 topic tiles (Civil Rights, Abortion, Taxes, Healthcare, Immigration, Climate Change, etc.). Two clear CTAs:
- "Take the Full Calibration" — top-right button with estimated time hint
- "Build a Custom Compass" — visible for selecting a subset of topics

The page immediately frames the app's antipartisan approach via a `?` info icon linking to `/how-it-works#spectrum-direction`. The antipartisan framing ("ideas first, not labels") is confirmed throughout the session — party labels are absent from every screen.

No gaps on the landing page. UX is clean and focused.

---

## §3 — Full Calibration Quiz (33 Questions)

**URL:** https://compass.empowered.vote/quiz?mode=full | **Screenshot:** 02-quiz-q1.png

The full calibration runs 33 questions across all 21 topics. Q1 (Civil Rights) presents the format:
- Category header: "Civil Rights and Social Policy"
- Full question text: "What role should government play in addressing racial and social inequality?"
- 5 stance buttons ranging from strongest progressive to strongest conservative
- A "Write your own..." custom button
- Bottom nav: `Back` (disabled), `1 of 33`, `Next` (disabled until selection)
- Inline help link: "Why is the stance order not fixed?" → `/how-it-works#spectrum-direction`

The stance order rotation is the key antipartisan design choice: neither the most progressive nor most conservative position is always shown first, preventing positional bias.

**Potential duplicate question observed:** During auto-advance through all 33 questions, Religious Freedom appeared at approximately Q4 and again at approximately Q20 with what appeared to be the same or nearly identical question text. This may represent two distinct questions covering different Religious Freedom aspects, or it may be a content error. Logged as G-114-015 (minor, pending content audit).

---

## §4 — Build (Topic Selection)

**URL:** https://compass.empowered.vote/build | **Screenshots:** 03-build-pick-topics.png, 04-build-6-selected.png

After completing the calibration, voters reach a Build screen showing 8 topic tiles they may have answered during calibration. The voter can select which topics to include on their radar. The CTA button is disabled until ≥1 topic is selected and updates dynamically: "View My Compass (6)" when 6 are selected.

**Technical note from walk:** The first attempt to select all 8 tiles via `browser_evaluate` JS `.click()` loops failed — only 1 of 8 registered because React @dnd-kit requires real PointerEvents. All subsequent topic selections used real Playwright `browser_click` calls. 6 of 8 tiles were selected for the radar.

No voter-facing gaps on the Build screen itself. The tile selection UX is responsive and the counter feedback is clear.

---

## §5 — Results: Radar Chart

**URL:** https://compass.empowered.vote/results | **Screenshot:** 05-compass-results.png

The results page renders a 6-spoke radar chart matching the 6 selected topics (Abortion, Taxes, Climate Change, Healthcare, Immigration, Voting Rights). The coral-filled polygon represents the voter's calibrated position.

Positive observations:
- Radar renders cleanly and proportionally
- "How to read the compass" `?` help link → `/how-it-works#compass-positions`
- "Back to Library" navigation always visible
- Unauthenticated state: a dismissible banner prompts account creation to save results

One potential gap: the `how-it-works` anchor links (`#spectrum-direction`, `#compass-positions`) appear throughout the UI. If the `/how-it-works` page does not yet exist or lacks those specific anchors, every help link silently fails. Not confirmed during this walk; flagged in G-114-014 as needing verification.

---

## §6 — Compare Picker (All Politicians)

**URL:** https://compass.empowered.vote/results | **Screenshot:** 06-compare-picker.png

Clicking "Compare" opens a modal picker: "Select a politician to compare." The picker contains:
- Free-text search field
- A "State" dropdown defaulting to no filter (shows ALL states: California, Indiana)
- Tier filter buttons: All / Federal (21) / State (15) / Local (16) = **52 total politicians**
- Scrollable list starting with Julia Brownley (CA-26, a California rep)

The default unsorted list intermixes California and Indiana politicians with no location-aware prioritization. A Monroe County voter who clicks Compare expecting to find their local primary candidates will see Julia Brownley and Eleni Kounalakis at the top — neither is relevant to the May 5 Indiana ballot. The voter must manually change the dropdown to "Indiana" to find relevant politicians. Logged as G-114-011.

---

## §7 — Indiana Filter: Complete Politician Roster

**URL:** https://compass.empowered.vote/results | **Screenshot:** 07-indiana-picker-filtered.png

Filtering the State dropdown to "Indiana" narrows the list to **9–10 politicians** grouped as Federal (3) / State (3) / Local (3):

| Tier | Politician | Office |
|------|-----------|--------|
| Federal | Jim Banks | U.S. Senator - Indiana |
| Federal | Todd Young | U.S. Senator - Indiana |
| Federal | Erin Houchin | U.S. Representative - IN-9 |
| State | Lilliana Young | Indiana State Representative |
| State | Micah Beckwith | Indiana Lieutenant Governor |
| State | Mike Braun | Indiana Governor |
| State | Matt Pierce | Indiana House of Representatives - District 61 |
| Local | David G Henry | Council - At Large |
| Local | Kerry Thomson | City Mayor |
| Local | Trent Deckard | Council - At Large |

All 9–10 are sitting officials or known candidates with entered stance data. None are primary challengers. The following BALLOT-BASELINE candidates with Indiana primary races are completely absent:

| Race | Absent candidates |
|------|------------------|
| IN-9 D Primary | Will Graham, Seth Meyer, Timothy Peck, Nathan Roark |
| Monroe County Prosecutor | Benjamin T. Arrington, Erika Oliphant |
| Monroe County Assessor | Bob Nyquist, Judith A. Sharp |
| Monroe County Clerk | Tanner Branham, Joe Davis, Tree Martin Lucas, Julie M. Hays |
| County Council D-4 | Jeff Crossley (uncontested in D primary) |
| Bloomington Township | All candidates absent |
| Judicial | Kelly Hanlon, Jonathan Willsey |

**Root cause:** These candidates are either DB stubs with no politician record (Arrington, Nyquist, Branham, Davis, Hays per AUDIT-REPORT-112.md §AUDIT-03) or simply have no stance data entered. Stance data entry is a prerequisite for the Compass compare feature; no data = not in picker. Logged as G-114-012 (blocker).

---

## §8 — Per-Race Stance Availability for May 5 Ballot

The table below answers the voter's core question: "Which of my May 5 ballot races can I use Compass to inform?"

| Race | Candidates on Ballot | In Compass Picker? | Compass Useful? |
|------|---------------------|-------------------|-----------------|
| U.S. Rep IN-9 (D Primary) | Houchin (R incumbent) + Graham/Meyer/Peck/Roark (D) | Houchin only | No — challengers absent |
| IN HD-61 (D Primary) | Pierce + Young | Both ✅ | **Yes** — best use case |
| Monroe Co Prosecutor | Arrington + Oliphant | Neither | No — stubs |
| Monroe Co Assessor | Nyquist + Sharp | Neither | No — stubs |
| Monroe Co Clerk | Branham + Davis + Lucas + Hays | None | No — stubs |
| County Council D-4 | Crossley | No | No — absent |
| Bloomington Township Trustee | Uncontested | No | No — absent |
| Judicial | Hanlon + Willsey | No | No — absent |

**Conclusion:** Compass is voter-useful for exactly **1 of 8 ballot races** (IN HD-61 D Primary: Pierce vs Young). For every other May 5 race, the compare feature returns no results or only one side of the race.

---

## §9 — Dual-Radar Comparison: Matt Pierce

**URL:** https://compass.empowered.vote/results | **Screenshots:** 08-compare-pierce-overlay.png, 09-compare-clean.png

Selecting Matt Pierce from the Indiana-filtered picker triggers the dual-radar view:
- Coral polygon = voter's calibrated positions
- Blue polygon = Matt Pierce's recorded stances
- Legend: "You" / "Matt Pierce" at top-left
- Right panel: Matt Pierce comparison card with grey avatar placeholder (no headshot visible in Compass despite headshot existing in Essentials — G-114-014), office label, "View full profile on Essentials ↗" cross-app link
- Topic drill-down: "Select a topic..." dropdown narrows the comparison to a single spoke

The cross-app link in the compare panel passes the voter's compass session as a base64-encoded fragment (`#compass=...`), confirming active cross-app integration between Compass and Essentials. This is a positive finding.

**Onboarding tooltip (first use):** Upon opening the compare panel, a 4-step fixed-overlay tooltip fires: "1 of 4 — Search for any politician to compare your views side by side. You won't see their party here — we want you to look at the ideas first, not the labels." The tooltip renders over the radar, requiring the voter to either advance through all 4 steps or click "Skip All" before they can interact with the comparison. Logged as G-114-013.

---

## §10 — Framing Question Answer

**Q: Can a Monroe County primary voter use Compass to make informed decisions about candidates on the May 5 ballot?**

**A:** For most races — no. For one race — yes.

The Compass compare feature works correctly for comparing the voter against sitting officials who have entered stance data. But the feature's utility collapses for the specific context of a May 5, 2026 Indiana primary voter because:

1. **The contested federal primary has no data:** All 4 IN-9 D primary challengers (Graham, Meyer, Peck, Roark) are absent from the compare picker. The voter can compare against Erin Houchin (the R incumbent), but Houchin is not on the D primary ballot they're deciding.

2. **County-wide races are all stubs:** Arrington, Nyquist, Branham, Davis, Hays are DB stubs with no stance data. The contested County Prosecutor and Clerk primaries are completely dark in Compass.

3. **Exception — HD-61:** Matt Pierce and Lilliana Young are both in the picker. For a voter deciding between Pierce and Young in the D House primary, Compass can deliver a real comparison. Pierce has 73.1% stance coverage (per AUDIT-112); Young has 57.7%. Both render on the radar. This is the tool working as intended.

The most actionable recommendation for Phase 115: logging the absence of primary challenger stance data as a data-intake priority for the run-up to May 5. Even a 3-question Compass profile for each IN-9 D challenger would make the comparison feature relevant for the most contested race on the Monroe County ballot.

---

## §11 — Positive Findings

- Antipartisan design is consistently applied: no party labels on any screen, stance order rotated, onboarding tooltip explicitly explains the "ideas first" principle
- Dual-radar rendering is clean and visually distinct (coral vs blue)
- Cross-app "View full profile on Essentials ↗" link in the compare panel with session state passthrough via `#compass=` fragment confirms integration architecture working
- Indiana-filtered picker contains both HD-61 candidates (Pierce + Young), giving one primary race full Compass coverage
- "Save your compass results" unauthenticated prompt is appropriately low-friction (dismissible banner, not a gate)

---

*Phase: 114-ux-walkthrough*
*Plan: 03*
*Completed: 2026-04-13*
