# Phase 86: Chrome Cleanup + Store Migration - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove dead chrome (ProgressHeader, AnimationOptionsPage, /animation-options route) and migrate the Zustand store to v2 with a clean-reset migration. Move reset functionality to the profile menu matching the Compass pattern. Remove badge system and legacy flat state. The app should build cleanly with no references to deleted components, the old Phase union value 'ranking', or badge types.

</domain>

<decisions>
## Implementation Decisions

### Profile menu reset
- Single "Clear Read & Rank" menu item — matches Compass's single "Clear Compass" pattern
- Confirmation dialog before wiping: "Clear all your Read & Rank progress? This can't be undone." with Cancel/Clear buttons
- Clears localStorage only — server-side quote_verdicts remain (no DELETE endpoint needed)
- Menu order: "Clear Read & Rank" above "Sign out" (matches Compass layout)

### Store v2 migration
- Keep persist key 'ev_readrank', bump version to 2
- v2 migrate function resets to clean initial state — all old progress wiped (ranking phase won't exist in new flow)
- Delete RankingPhase component and all its imports
- partialize returns only `{ phase, currentIssueId, issueProgress }` — no redundant legacy data

### Badge system cleanup
- Remove BadgeType, BadgeAssignment interfaces from store
- Remove assignBadge, clearBadge store actions and badgeAssignments from IssueProgress
- Delete BadgeIcons component
- Strip diamond/gold point bonuses from matchingAlgorithm.ts — rank-only scoring per FLOW-05
- Strip badge data from verdictFragment.ts encoder (Essentials only reads agree/disagree + rank order)

### Legacy flat state removal
- Remove all deprecated flat fields: issueTitle, questionText, topicId, flat agreedQuotes, disagreedQuotes, rankedQuotes, candidateMatches, badgeAssignments
- Remove legacy methods: setQuotes, setIssueInfo
- Update all component reads from `store.agreedQuotes` etc. to `getCurrentIssueProgress()` pattern
- Audit and remove orphaned components (CollectionPhase if unused, any others found)

### Claude's Discretion
- Whether to remove 'ranking' from Phase union now or leave for Phase 87 — Claude picks based on what's cleanest given RankingPhase deletion
- Any other dead code discovered during audit

</decisions>

<specifics>
## Specific Ideas

- Compass pattern for reset: single menu item with confirmation dialog, localStorage-only clear
- Profile menu structure mirrors CompassV2 exactly (Clear action above Sign out)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `useAuthState` hook: Already provides isLoggedIn/userName/logout — profile menu logic lives in App.tsx
- SiteHeader `profileMenu` prop: Already wired with spread cast — add "Clear Read & Rank" as new menu item

### Established Patterns
- Zustand persist with version + migrate: Already in place at version 1 — bump to 2 with reset migrate
- `getCurrentIssueProgress()` / `getIssueProgress(issueId)`: Already exist as store methods — components should use these

### Integration Points
- `App.tsx` line 17: profileMenu items array — add Clear menu item here
- `useReadRankStore.ts`: Store definition — primary file for v2 migration
- `matchingAlgorithm.ts`: Badge scoring logic to strip
- `verdictFragment.ts`: Fragment encoder badge data to strip
- `PhaseContainer.tsx`: Renders phase switch — needs RankingPhase case removed
- `verdictSync.ts`: May reference badge data — needs audit

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 86-chrome-cleanup-store-migration*
*Context gathered: 2026-03-14*
