# Feature Landscape

**Domain:** Swipe-evaluate + badge-rank + reveal — civic quote evaluation app (Read & Rank v2026.3.6 redesign)
**Researched:** 2026-03-14
**Confidence:** HIGH (existing codebase fully inspected; patterns verified against source)

---

## Context: What Already Exists

The v2026.3.4 milestone shipped a standalone Read & Rank at `readrank.empowered.vote` with these fully working features:

- 4-phase linear flow: Hub → Evaluation (swipe agree/disagree) → Ranking (separate page, badge assignment + dnd-kit reorder) → Results (reveal who said what)
- Framer Motion swipe cards with drag, `SwipeBackground` color flash, keyboard shortcuts (A/D/arrows), desktop action buttons
- `AgreedQuotesSidebar` on desktop showing agreed quotes during evaluation
- Separate `RankingPhase` component: dnd-kit sortable list + Diamond/Gold badge assignment UI
- Results page: staggered framer-motion reveal, candidate photo + quote + source + "View Alignment" CTA + "View on Essentials" CTA
- `CandidateAlignmentPage` showing per-candidate quote breakdown
- Zustand store with per-issue progress tracking, localStorage persist (`ev_readrank` key, version 1)
- Verdict sync: URL fragment for guests, backend POST for logged-in users
- `ProgressHeader` component (phase breadcrumb nav — slated for removal)
- `AnimationOptionsPage` (settings step before main flow — slated for removal)

This milestone (v2026.3.6) overlays: unified evaluate+rank interaction, practice round onboarding, coach marks, location-based quote filtering, results reveal polish, and visual redesign.

---

## Table Stakes

Features users expect given the existing product and genre. Missing = product feels incomplete or regressed.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Swipe to agree/disagree | Core mechanic — the product identity | Low | Already exists; must survive unification intact |
| Badge assignment in the same interaction session as swiping | Users do not want a context switch to a separate "ranking" page; modern swipe apps keep priority actions inline with the primary gesture | Medium | This is the key collapse: RankingPhase must be absorbed. Desktop can use extended sidebar; mobile needs a post-evaluation badge screen before "See Results" |
| Agree/disagree visual feedback during drag | Colored background flash and directional label are now expected from swipe interactions (Tinder standard since 2012) | Low | `SwipeBackground` already handles this; keep unchanged |
| Progress indicator during evaluation | "3 of 8" prevents abandonment; users need orientation | Low | Already exists |
| "Skip badges" path | Not every user will have a strong top pick; forcing a badge assignment blocks the flow | Low | Already present with "You can continue without awarding badges" — preserve this |
| Results page revealing candidate identity | The payoff is the mystery reveal — results must show names and photos | Low | Already exists |
| Source links on every quote | Verifiable quotes are table stakes for a civic trust product | Low | Already exists |
| Resume interrupted session | localStorage persistence means users expect to return to the same place | Low | Already exists via Zustand persist |
| Back to hub from results | Users need a way to explore more issues after finishing one | Low | Already exists |
| Desktop keyboard shortcuts | Arrow keys and A/D are expected by desktop power users once they discover the mechanic | Low | Already exists |

---

## Differentiators

Features that set this product apart and are valued but not universally expected.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Practice round with non-political quotes | Teaches the swipe mechanic and badge system safely before political content — reduces first-use anxiety; the Duolingo pattern of "learn by doing without stakes" | Medium | Needs: a fixed `practice` issue ID in data layer (pizza toppings or similar fun quotes), practice flag in Zustand store to skip verdict sync and scoring, and a clear "Now the real thing" moment on completion. Should auto-launch on first visit (`has_done_practice` in localStorage). |
| Coach marks on first real issue (not practice) | Contextual just-in-time guidance shown exactly once, where and when the interaction appears — far more effective than a static tutorial modal | Medium | `CoachMark` component with SVG mask spotlight already exists in CompassV2 and works well; needs porting to Read & Rank. Show 2-3 marks: swipe direction hint, badge assignment hint. Dismiss permanently via `has_seen_coach_marks` localStorage flag. |
| Inline badge assignment on desktop sidebar | During evaluation, the `AgreedQuotesSidebar` shows agreed quotes accumulating in real time. Extending it with Diamond/Gold tap buttons means badge assignment happens mid-flow with no phase boundary — the ranking and evaluation are simultaneous for desktop users. | Medium | `AgreedQuotesSidebar` is already rendered in the desktop split layout. Adding badge tap buttons means wiring `assignBadge` from the store into the sidebar. Store already supports this. |
| Post-evaluation badge assignment screen (mobile) | Mobile has no sidebar. After all cards are swiped, a compact "Done" state shows agreed quotes with badge tap affordance before "See Results." One focused screen, not a full separate phase page. | Medium | Replaces `RankingPhase` on mobile. The dnd-kit reorder is removed in favor of simple badge taps — reordering within the evaluation context is unnecessary now that badges (not list position) determine priority. |
| Location-based quote filtering | Only surface quotes from the user's actual elected representatives — makes the tool personally relevant rather than a generic political quiz | High | Three parts: (1) address input UI (Google Maps Places autocomplete, already used in Essentials), (2) Essentials context bridge (read saved address from localStorage `ev_location` key if already set in Essentials, or prompt for address in Read & Rank), (3) filtered quote fetch via existing `GET /essentials/quotes?politician_id=X` endpoint with multiple IDs. Graceful fallback: if no address set or no quotes for user's district, show all quotes with a soft explanation. |
| Dramatic staggered results reveal | Cards reveal one by one with a beat of suspense — the "who said what" moment feels earned, not just a data dump | Low | Framer Motion stagger already partially implemented in `ResultsPhase`. Needs tightening: increase pre-reveal delay, reduce per-card delay, add a brief "Revealing..." moment before first card appears. |
| Cross-app verdicts in Essentials profiles | Verdicts flow to Essentials politician profiles as badges — users see their evaluations in context when researching a candidate | Low | Already fully shipped in v2026.3.4. Preserve — no regression. |

---

## Anti-Features

Features to explicitly NOT build in this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| `ProgressHeader` component | Adds a phase breadcrumb nav bar that clutters the top of every phase and implies a back-navigation affordance that disrupts linear flow. Milestone explicitly calls for removal. | Remove the component entirely. Phase context is communicated by the card content itself and the question banner. |
| `AnimationOptionsPage` | A settings screen before the main flow adds a step that interrupts time-to-first-swipe. Most users will click through it blindly. | Remove it. Default animation behavior is the only behavior. If animation preferences become genuinely needed, a settings page in the hub is less disruptive. |
| dnd-kit sortable reorder in ranking | Drag-to-reorder a list of agreed quotes is a high-friction interaction that most users skip in favor of badge assignment. The ranking order was used for matching math but badge assignment carries the same signal with far less effort. | Remove dnd-kit reorder from the ranking experience. Keep badge assignment only. If quote ordering matters for matching, derive it from badge status (diamond = rank 1, gold = rank 2, rest = unranked). |
| Tutorial modal / instructional splash screen | Static "here's how it works" modals have 60-70% immediate dismiss rates. Users do not read them. | Use the practice round instead — users learn by doing with non-political content, which is demonstrably more effective (Duolingo, onboarding gamification research). |
| Mandatory badge assignment gate | Blocking "See Results" until badges are assigned alienates users who agreed with zero or one quote | Keep the "continue without badges" path. Show a gentle nudge if no badges assigned but do not block. |
| Login required for location filtering | Requiring login before the address input creates friction at the most motivated moment — right when a user is about to engage with content relevant to them | Store the address in localStorage (`ev_location` key) for guests, same pattern as existing compass and verdict guest paths. Prompt login only to persist across devices. |
| Third badge tier (Silver, etc.) | A third tier increases cognitive load without proportional value. Diamond + Gold already communicates "top pick" vs "runner up" clearly. | Keep Diamond + Gold only. |
| Full geocoding on the client side | Calling Google Maps Geocoding API from the browser exposes the API key in network requests and consumes the 28K/month free tier budget | Use the existing EV-Backend `/essentials` endpoint: POST the address, backend geocodes server-side with the stored API key and returns matching politician IDs |
| Cross-issue global ranking or leaderboard | Aggregating verdicts across issues into a "most aligned candidate" score creates an implied endorsement. The nonprofit's antipartisan mission requires per-issue evaluation to stay personal and non-aggregated. | Keep results scoped to one issue at a time. The CandidateAlignmentPage already shows per-candidate quote breakdown — that is the correct scope. |

---

## Feature Dependencies

```
Chrome Cleanup (remove ProgressHeader, AnimationOptionsPage)
  → no dependencies
  → unblocks: visual redesign (cleaner component tree, fewer CSS conflicts)

Practice Round
  → requires: practice issue data (fixed pizza-toppings quotes in static data layer or DB)
  → requires: practice flag in Zustand store (skip verdict sync, skip scoring)
  → requires: `has_done_practice` flag in localStorage
  → should complete before: coach marks (practice round IS the primary mechanic teacher;
      coach marks supplement for the first real issue)

Coach Marks (first real issue)
  → requires: practice round complete (marks are redundant if practice already showed the mechanic)
  → requires: CoachMark component (port from CompassV2 or extract to ev-ui)
  → requires: `has_seen_coach_marks` localStorage flag
  → scoped to: first real issue only, not practice round

Unified Evaluate+Rank (inline badge assignment)
  → requires: AgreedQuotesSidebar extended with badge tap buttons (desktop path)
  → requires: evaluation-complete state shows badge assignment summary inline (mobile path)
  → removes: standalone RankingPhase component
  → removes: dnd-kit sortable reorder dependency (can remove @dnd-kit from bundle)
  → store: no changes needed — assignBadge() already works; badgeAssignments already
      in store. Only UI location changes.

Location-Based Filtering
  → requires: address input component in hub or issue selection screen
      (Google Maps Places autocomplete — same library as Essentials)
  → requires: Essentials context bridge — read `ev_location` localStorage key if
      already set by Essentials, or prompt in Read & Rank and write to same key
  → requires: filtered quote fetch — already supported via
      `GET /essentials/quotes?politician_id=X` with comma-separated IDs
  → requires: PostGIS politician-id resolution — call existing
      `POST /essentials/search` (or a lightweight address-to-politician-ids endpoint)
  → requires: graceful fallback: if no address, no geofence match, or zero quotes
      for district — show all quotes with soft "showing all candidates" message
  → does NOT require: any backend schema changes
  → risk: "no quotes for your district" is the expected common case outside
      Bloomington IN and LA County CA — fallback UX is critical

Results Reveal Polish
  → requires: unified evaluate+rank to be complete (results are now reached from
      the unified flow, not from RankingPhase)
  → independent of: location filtering, practice round, coach marks

Visual Redesign
  → no hard dependencies
  → chrome cleanup (remove ProgressHeader, AnimationOptionsPage) should happen
      first to avoid redesigning components that will be deleted
  → can proceed in parallel with any phase of the above
```

---

## MVP Recommendation

Build in this order to minimize risk and deliver visible value at each step:

1. **Chrome cleanup** — Remove `ProgressHeader` and `AnimationOptionsPage`. No behavior change, reduces scope for everything that follows. ~1 hour.

2. **Unified evaluate+rank** — Highest value interaction change. Desktop: extend `AgreedQuotesSidebar` with inline badge tap buttons. Mobile: replace `RankingPhase` full page with a compact badge assignment screen at the evaluation-complete state. Remove dnd-kit reorder. Store requires no changes.

3. **Practice round** — Fixed "pizza toppings" issue that auto-starts on first visit. Non-political content. Clear "Now the real thing" transition. `has_done_practice` flag prevents repeat. Practice verdicts are not synced or scored.

4. **Coach marks on first real issue** — Port `CoachMark` from CompassV2. Show 2-3 marks on first entry to a real issue after completing practice. Dismiss permanently.

5. **Results reveal polish** — Tighter stagger, pre-reveal suspense moment. Low effort, high perceived quality.

6. **Location-based filtering** — Address input in hub. Read `ev_location` from localStorage first (re-use cross-app address context from Essentials). Call backend to resolve politician IDs. Fetch filtered quotes. Graceful fallback. This is the highest-complexity item — doing it last means the rest of the flow is stable before adding the filtering layer.

7. **Visual redesign** — Can be layered throughout or done as a final pass. Depends on stable component structure from steps 1-6.

Defer to a future milestone:
- "My reps" surfacing on Compass compare page — belongs in Essentials, not Read & Rank
- Multi-issue summary / cross-issue alignment score — significant state complexity, antipartisan risk
- Share results card / social sharing — image generation adds infra complexity

---

## Complexity Summary

| Feature | Complexity | Main Risk |
|---------|-----------|-----------|
| Chrome cleanup (remove 2 components) | Low | None — pure deletion |
| Unified evaluate+rank desktop (sidebar badge taps) | Medium | Badge state must be readable in `AgreedQuotesSidebar`; store already supports it |
| Unified evaluate+rank mobile (inline at evaluation-complete) | Medium | Layout: fitting badge pickers into compact "Done" state without crowding on small screens |
| Practice round | Medium | Must mark practice issue as special in store so it skips verdict sync and backend scoring |
| Coach marks | Low-Medium | Port from CompassV2 is the main work; logic is straightforward |
| Results reveal polish | Low | Framer Motion stagger tuning only |
| Location-based filtering | High | Three-part implementation; "no quotes for district" is the common-case fallback UX |
| Visual redesign | Medium | Every component; risk is breaking animation behavior while restyling |

---

## Sources

- Codebase: `EV-readrank/src/components/` — all phase components inspected
- Codebase: `EV-readrank/src/store/useReadRankStore.ts` — Zustand store shape, `ev_readrank` key
- Codebase: `EV-readrank/src/components/AgreedQuotesSidebar.tsx`, `EvaluationPhase.tsx`, `RankingPhase.tsx`, `ResultsPhase.tsx`, `IssueHub.tsx`
- CompassV2 CoachMark component: already built and in production (v2026.4)
- Duolingo onboarding: learn-by-doing, safe-to-fail practice pattern — [UserGuiding Duolingo Breakdown](https://userguiding.com/blog/duolingo-onboarding-ux), [Appcues Duolingo](https://goodux.appcues.com/blog/duolingo-user-onboarding)
- Onboarding gamification research: [Userpilot Onboarding Gamification](https://userpilot.com/blog/onboarding-gamification/), [Appcues Gamification Tips](https://www.appcues.com/blog/onboarding-gamification-strategies)
- Coach marks best practices 2025: [NN/G Instructional Overlays](https://www.nngroup.com/articles/mobile-instructional-overlay/), [Docsie Coach Marks 2025](https://www.docsie.io/blog/glossary/coach-marks/), [Plotline Coachmarks & Spotlight](https://www.plotline.so/blog/coachmarks-and-spotlight-ui-mobile-apps)
- Swipe card UX: [Conjointly Single Swipe Card](https://conjointly.com/guides/single-swipe-card-question/)
- Location/district civic tech UX: `essentials/` codebase, `EV-Backend/internal/essentials/handlers.go` (PostGIS geofence matching, `/essentials/quotes?politician_id=X`)

---
*Feature research for: v2026.3.6 Read & Rank Redesign milestone*
*Researched: 2026-03-14*
