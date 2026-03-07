# Phase 68: Guest Data Bridge - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Guest users who calibrated on CompassV2 can have their compass answers accessed from the Essentials app. The bridge transfers compass data across origins via URL fragments, persists it in Essentials localStorage, and supports bidirectional navigation between the two apps. No backend changes required.

</domain>

<decisions>
## Implementation Decisions

### Bridge Mechanism
- URL fragment transfer: CompassV2 encodes guest answers into a URL fragment (#compass=...) when linking to Essentials
- Fragment is always appended on any outbound link from CompassV2 to Essentials (not just explicit "return" actions)
- Essentials reads the fragment on load, converts short_title to topic_id using allTopics from /compass/topics, stores in localStorage
- Essentials strips the fragment from the URL after reading via history.replaceState (clean URLs, no stale data in bookmarks)
- No backend changes needed — purely client-side bridge

### Navigation Flow — Both Directions
- **Essentials-first:** Guest sees CTA on profile → link to CompassV2 includes ?return=essentials.empowered.vote/profile/{slug} → CompassV2 shows persistent return banner → after calibration, user clicks return link which appends compass fragment
- **CompassV2-first:** Guest on compare page sees "View full profile on Essentials" link next to politician name → link opens Essentials profile with compass fragment in URL
- CompassV2 compare page outbound link carries compass data in fragment to the specific politician's Essentials profile page

### Return Banner in CompassV2
- Persistent subtle top bar when ?return param is active: "You came from Essentials — Return to [politician name]"
- Thin, dismissible bar at the top of the page
- Stays visible across CompassV2 pages while the return URL param is set
- Return link appends compass data fragment to the return URL

### Data Persistence in Essentials
- Guest compass data stored in Essentials localStorage (key like 'guestCompass')
- Survives browser close — guest can return to Essentials tomorrow without re-bridging
- New fragment always wins: if user arrives with compass fragment, it overwrites whatever is in localStorage (handles compass updates)
- Cleared on login: once logged in, compass data comes from API (Phase 67); guest cache removed to avoid conflicts
- Clean separation: guest = localStorage, logged-in = API

### CompassContext Boot Priority
- Priority order on Essentials page load:
  1. URL fragment present? Parse it, store in localStorage, use it
  2. Logged in? Fetch from API (existing Phase 67 path)
  3. Guest localStorage cache exists? Use cached data
  4. None of the above → empty arrays, CTA mode (existing Phase 67 fallback)

### Uncalibrated Guest CTA
- Existing CTA (greyed compass + "Take the Quiz") upgraded with return URL
- CTA link becomes: compass.empowered.vote?return={current_essentials_profile_url}
- After calibrating, guest sees persistent top bar to return to the specific politician profile

### Claude's Discretion
- URL fragment encoding format (base64 JSON vs compact custom encoding vs other)
- Tab behavior for compare page outbound links (same tab vs new tab)
- Exact banner design and dismiss behavior in CompassV2
- Error handling for malformed or invalid fragment data
- localStorage key naming and data structure

</decisions>

<specifics>
## Specific Ideas

- "I think it needs to be something like a link to the politician profile page" — CompassV2 compare page should link directly to the specific politician's Essentials profile, not just the Essentials homepage
- Persistent banner preferred over a one-time post-calibration prompt — user may browse CompassV2 before returning

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `essentials/src/contexts/CompassContext.jsx`: Already has loadAll() with auth check, topic fetch, user answer fetch — extend with fragment parsing and localStorage guest path
- `essentials/src/lib/compass.js`: Has buildAnswerMapByShortTitle() for short_title↔topic_id mapping — reverse this for fragment parsing
- `essentials/src/components/CompassPreview.jsx`: Has CTA mode with COMPASS_URL env var (line 6) — upgrade link to include return URL
- `CompassV2/src/components/CompassContext.jsx`: Guest answers in localStorage under key "answers" (short_title-keyed object), "selectedTopics" (UUID array), "writeIns" — read these for fragment encoding
- `CompassV2/src/pages/Compass.jsx`: Post-calibration screen — potential mount point for return banner

### Established Patterns
- CompassV2 localStorage keys: "answers" ({short_title: value}), "selectedTopics" ([uuid]), "writeIns" ({short_title: text}), "guestId" (uuid)
- Essentials expects API format: [{topic_id, value, write_in_text}] — fragment parsing must do the short_title→topic_id conversion using allTopics
- Both apps already fetch /compass/topics — topic data available for the mapping
- Register.jsx buildGuestState() (lines 18-37) already does this exact conversion — pattern can be mirrored

### Integration Points
- `essentials/src/contexts/CompassContext.jsx`: Add fragment parsing to loadAll(), add localStorage guest cache read/write
- `essentials/src/components/CompassPreview.jsx`: Update CTA link to include ?return= param
- `CompassV2/src/pages/Compass.jsx`: Add return banner component when ?return param detected
- `CompassV2/src/components/CompassContext.jsx`: Add utility to serialize guest state to URL fragment
- CompassV2 compare page: Add "View full profile on Essentials" link next to politician name

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 68-guest-data-bridge*
*Context gathered: 2026-03-07*
