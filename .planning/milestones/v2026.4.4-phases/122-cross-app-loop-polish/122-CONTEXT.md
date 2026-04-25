# Phase 122: Cross-App Loop Polish - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the remaining Compass → Read & Rank → Essentials cross-app integration gaps so
the full voter loop works end-to-end without dead ends or missing state:

1. **INTG-01 (G-114-028):** CompassCard on Essentials profile pages shows the
   comparison overlay for returning visitors who have calibrated (instead of always
   showing the "Calibrate your compass" CTA).
2. **INTG-02 (G-114-030):** Compass compare page "View full profile on Essentials"
   link resolves correctly for all politicians in the picker, including candidates
   whose IDs may differ from politician IDs.
3. **INTG-03 (G-114-031):** Essentials Results page shows a contextual "Explore
   [Municipality] revenue and expenses" link below each local-tier section that has
   matching Treasury Tracker data.

**In scope:** All three INTG items above; diagnosis of the CompassCard relay break;
candidate ID mapping verification; Treasury API integration for municipality detection.

**Out of scope:** Auth state relay (G-114-027, separate gap — cookie domain was fixed
in v2026.3.2); Read & Rank location filter (Phase 119); any new compass or Read & Rank
features; geofence repair (Phase 121); UX polish bundle (Phase 125).

</domain>

<decisions>
## Implementation Decisions

### INTG-01: CompassCard State Relay

- **D-01:** When a visitor arrives at an Essentials profile page with no fresh
  `#compass=` URL fragment, CompassCard should **read `guestCompass` from
  Essentials-domain localStorage** and render the comparison overlay if data exists.
  If `guestCompass` is empty, show the "Calibrate your compass" CTA as before.
  This is the intended behavior — the question is why it's not working.

- **D-02:** **Diagnose-first approach.** The research/plan step must identify the
  actual break in the relay chain before writing any code. Verify in order:
  (a) Does the `#compass=` fragment write succeed? After navigating from Compass via
      the "View profile" link, is `guestCompass` written to Essentials localStorage?
  (b) On a subsequent direct visit (no fragment), does `loadGuestCompass()` return
      data?
  (c) Is `userAnswers` populated from that data before CompassCard mounts and evaluates
      `hasUserCompass`?
  Fix whichever layer is broken. Do not assume the break — it could be in the fragment
  write, the localStorage read, the context timing, or the render condition.

- **D-03:** The fragment relay mechanism is the **only** cross-origin bridge. CompassV2
  uses raw localStorage keys (`answers`, `selectedTopics`, `invertedSpokes`); Essentials
  uses `guestCompass`. These live on different origins and are never directly shared.
  The relay path is: CompassV2 `serializeCompassFragment()` → URL fragment → Essentials
  `parseCompassFragment()` → `saveGuestCompass()` → `guestCompass` key on
  essentials-domain localStorage. All three steps must be working.

- **D-04:** **Do not follow-through past the first root cause** until that layer is
  verified fixed. Once the root cause is identified and patched, confirm `guestCompass`
  is present on the next direct visit before moving on.

### INTG-02: Compass→Essentials Profile Links

- **D-05:** The "View full profile on Essentials" link at `ComparePanel.jsx:120` uses
  `/politician/${politician.id}` — this is the Essentials UUID route (`/politician/:id`).
  The link already appends `serializeCompassFragment()` (confirmed in code).

- **D-06:** **Verification-first.** The research step must confirm:
  (a) Does the link resolve for currently-available Compass picker politicians (e.g.
      Matt Pierce UUID)? Test both politician and candidate-type entries in the picker.
  (b) Are any candidates in the picker using a `candidate_id` that doesn't match an
      Essentials `/politician/:id` route? If so, Essentials also has `/candidate/:id` —
      verify whether those IDs match.
  (c) Fix the ID mapping if there is a mismatch (e.g. link to `/candidate/:id` when
      the picker entry is a candidate, `/politician/:id` when it's a politician).

- **D-07:** If no code fix is needed for INTG-02 (the link already works), document
  the verification evidence and close INTG-02 with that proof. Do not add code for
  a problem that doesn't exist.

### INTG-03: Essentials→Treasury CTA

- **D-08:** The Treasury CTA appears **below each local-tier municipality section**
  in the Essentials Results page. A "section" here is a grouped block of local
  officials for a specific body (e.g. "Bloomington City Council", "Monroe County
  Board of Commissioners", a township trustee section). The CTA appears for each
  such section where the municipality has matching data in Treasury Tracker.

- **D-09:** **Dynamic detection via Treasury API.** Query `/api/treasury/cities` (or
  equivalent endpoint that lists municipalities with data) to determine which
  municipality names/slugs have Treasury data. Match against the local-tier section
  headings returned for the user's address. Show the CTA for matches, hide for
  non-matches.

- **D-10:** **CTA link text:** "Explore [Municipality] revenue and expenses →"
  where [Municipality] is the specific local body name from the Results data
  (e.g. "Explore Bloomington revenue and expenses →"). No dollar amount in the link.

- **D-11:** **CTA link destination:** `https://treasurytracker.empowered.vote` (or
  the relevant VITE env var), deep-linked to the matching municipality if the
  Treasury Tracker URL structure supports it. Researcher should check whether a
  direct municipality deep-link is possible or whether the root URL is sufficient.

- **D-12:** The CTA is placed **below** the municipality section (after all the
  official cards for that body), not in the header area. If a section has no
  Treasury data, no CTA is shown — do not show a disabled/grayed-out state.

### Verification & Sequencing

- **D-13:** **Production verification required.** Final verification for all three
  INTG items must happen on production URLs
  (essentials.empowered.vote, compass.empowered.vote) after Render deploy. Local dev
  for iteration; production DOM/screenshot evidence before closing each INTG item.
  Same pattern as Phases 118 and 119.

- **D-14:** **Both guest and logged-in paths** must be verified for INTG-01 and
  INTG-02 — consistent with Phase 118 D-15.

- **D-15:** **Sequencing within one plan:** INTG-01 (CompassCard relay diagnosis +
  fix) → INTG-02 (link verification + ID fix if needed) → INTG-03 (Treasury CTA).
  All three ship in a single plan and a single Render deploy.

- **D-16:** If the INTG-01 fix lands in `ev-ui` (e.g. a StanceAccordion or
  ev-ui component change is implicated), ship via the standard auto-bump pipeline
  (`npm version patch` → git tag → CI publish → repository_dispatch). This is
  unlikely but must be checked during diagnosis.

### Claude's Discretion

- Exact diagnostic commands, localStorage inspection steps, and network tracing used
  to identify the INTG-01 break.
- Whether to add a defensive dev-mode log when `guestCompass` is empty but fragment
  parsing was attempted (optional — only if it helps debug faster).
- Visual treatment of the Treasury CTA (color, icon, spacing) — follow existing
  Essentials design patterns (`ev-coral` / `ev-muted-blue` / `ev-light-blue`,
  Manrope font, Tailwind CSS 4).
- Whether the Treasury deep-link can route to the specific municipality in Treasury
  Tracker (researcher determines).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 122" — phase goal, success criteria, dependency on Phase 118
- `.planning/REQUIREMENTS.md` INTG-01, INTG-02, INTG-03 — acceptance criteria
- `.planning/GAP-REPORT.md` §G-114-027, §G-114-028, §G-114-030, §G-114-031 — fix sketches and evidence screenshots

### INTG-01: CompassCard State Relay
- `essentials/src/components/CompassCard.jsx` — render gate: `hasUserCompass`, `politicianIdsWithStances`, two `StanceAccordion` call sites
- `essentials/src/contexts/CompassContext.jsx` §53–169 — fragment parse → `userAnswers` population; §104–141 guest data priority chain
- `essentials/src/lib/compass.js` §102 `GUEST_COMPASS_KEY="guestCompass"`, §179 `saveGuestCompass()`, §191 `loadGuestCompass()` — localStorage bridge
- `CompassV2/src/components/CompassContext.jsx` §281–291 `serializeCompassFragment()` — fragment serialization
- `CompassV2/src/components/ComparePanel.jsx:1` — imports `serializeCompassFragment`

### INTG-02: Compass→Essentials Links
- `CompassV2/src/components/ComparePanel.jsx:9–10, 120–123` — `VITE_ESSENTIALS_URL` env var; "View full profile" link with `politician.id` + fragment
- `essentials/src/App.jsx:53–56` — `/politician/:id` and `/candidate/:id` routes (both use UUID params)

### INTG-03: Treasury CTA
- `essentials/src/pages/Results.jsx` — local-tier section rendering; insertion point for Treasury CTAs
- `ev-accounts/backend/src/routes/treasury.ts` (or equivalent) — Treasury cities/municipalities endpoint; researcher must confirm endpoint path and response shape
- `CompassV2/src/components/ReturnBanner.jsx` — reference pattern for a contextual cross-app CTA

### Release Pipeline (if ev-ui change needed)
- `ev-ui/README-AUTOBUMP.md` — auto-bump pipeline (release flow, repository_dispatch)

### Phase 118 Decisions (same component surface)
- `.planning/phases/118-read-rank-verdict-badge-fix/118-CONTEXT.md` — D-11 through D-16 (ev-ui fix path, verification pattern, authed+guest paths)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`serializeCompassFragment()` (CompassV2)** — serializes current compass state into `#compass=BASE64` fragment; already used in `ComparePanel.jsx` "View profile" link and `ReturnBanner.jsx`.
- **`parseCompassFragment()` + `saveGuestCompass()` (Essentials)** — fragment parsing and localStorage write already implemented; the question is whether they're executing correctly.
- **`loadGuestCompass()` (Essentials)** — reads `guestCompass` key from Essentials-domain localStorage; called at line 141 of CompassContext.jsx for returning guests.
- **`VITE_ESSENTIALS_URL` env var (CompassV2)** — already set up in ComparePanel; `https://essentials.empowered.vote` default.
- **`VITE_TREASURY_URL` or similar** — check whether a treasury URL env var exists in Essentials; if not, add one.

### Established Patterns
- **Fragment relay is the cross-origin bridge** — localStorage is origin-scoped; fragment is the only way to pass state from compass.empowered.vote to essentials.empowered.vote without a server round-trip.
- **Guest priority chain in CompassContext** — API > fragment > localStorage > empty. Diagnosis must cover all four levels, not just localStorage.
- **`/politician/:id` and `/candidate/:id`** — both routes exist in Essentials with UUID params. The Compass picker may contain entries of either type.
- **Cross-app CTA styling** — `ReturnBanner.jsx` in CompassV2 is a reference for a contextual cross-app link style (light blue / ev-light-blue color, inline arrow).

### Integration Points
- **CompassCard gates on `politicianIdsWithStances`** — politician must be in that set for CompassCard to render at all. Diagnosis should confirm Pierce and other test politicians are in the set before investigating the relay break.
- **Treasury section grouping in Results.jsx** — researcher should identify how local-tier sections are currently grouped (by `government_body`, by district type, or by category label) to determine the correct insertion point for the Treasury CTA.
- **Treasury API** — researcher must confirm the endpoint that lists municipalities/cities with available data (likely `/api/treasury/cities` or `/api/treasury/municipalities`).

</code_context>

<specifics>
## Specific Ideas

- The "Explore [Municipality] revenue and expenses →" CTA text is fixed — no dollar
  amount in the link (user preference — keep it clean and generalizable).
- The CTA appears BELOW each municipality section's official cards, not in the header.
- If a municipality has no Treasury data, no CTA is shown (not grayed out, simply absent).
- Detection is dynamic — query the Treasury API for which municipalities have data,
  match against local-tier section names from the Essentials results. This allows the
  CTA to automatically appear for future municipalities added to Treasury Tracker.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 122-cross-app-loop-polish*
*Context gathered: 2026-04-16*
