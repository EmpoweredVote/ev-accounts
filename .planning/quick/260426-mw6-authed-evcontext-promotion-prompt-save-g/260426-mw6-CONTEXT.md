---
quick_id: 260426-mw6
status: ready_for_planning
date: 2026-04-26
---

# Quick Task 260426-mw6: Authed ev-context promotion prompt - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Task Boundary

Close the "I signed up later" gap. Today, `promoteCompassImportDraft()` in `ev-accounts/backend/src/lib/compassService.ts:36-66` only fires when the Connected onboarding flow wrote a `compass_import_draft`. A guest who calibrates compass on read-rank/essentials and then signs up *outside* that flow has ev-context data that never reaches their server-side account.

This task adds the **inverse direction** of task 260426-mc5: when an authed user opens any of our apps and the API has **no data** for a domain (compass, address, or verdicts) but ev-context **does**, surface an inline banner offering "Save this to your account?". One click → POST to existing endpoints.

**In scope:**
- New hook in `@empoweredvote/ev-ui`: `useEvContextPromotion()` (or similar) that detects per-domain gaps and returns `{ shouldPrompt, promote, dismiss }`.
- Three inline banner components (compass, address, verdicts) — one per domain — placed in the consumer apps near the affected feature.
- Wiring the hook + banners into CompassV2 (compass), essentials (compass + address), read-rank (verdicts + address).
- Treasury-tracker is read-only of address — no prompt needed (it doesn't *write* address; it just hydrates).

**Out of scope:**
- Backend changes — uses existing `POST /compass/answers/batch`, `POST /compass/verdicts`, `POST /connect/set-location`.
- Modifying or replacing `promoteCompassImportDraft()` — it stays as the Connected-onboarding seam.
- Selected_topics, jurisdictions, XP/gems — same scope as 260426-mc5.
- Conflict UI — we only fire when the API is empty for that domain, so there is no conflict to resolve.

</domain>

<decisions>
## Implementation Decisions

### Trigger condition
- **Fire only when the API is empty for that domain.**
- Per-domain check: if `apiCompass.length === 0 && evContext.compass exists` → prompt for compass. Same shape for address and verdicts.
- If the API already has *any* data in that domain, do nothing — assume the user has either already saved or intentionally cleared.
- Why: avoids reintroducing data the user already deleted on purpose, and avoids interrupting users who already promoted via the Connected onboarding flow. Lowest false-positive rate.

### Conflict handling
- **There is no conflict by construction.** The trigger condition only fires when API is empty.
- If the user dismisses the prompt and the API stays empty, the prompt may re-appear on next mount (planner to decide: stamp a per-userId "dismissed" flag in ev-context to suppress for the session, or accept that the prompt is sticky until the user clicks Save or makes any API write).

### UI surface
- **Inline banner near the affected feature.**
- Compass banner: small element above the topic library / answers list — "You answered 8 questions before signing up — save them to your account? [Save] [Dismiss]"
- Address banner: small element above the address input on essentials — "Use the address from your earlier visit? [Save] [Dismiss]"
- Verdicts banner: small element on read-rank's verdicts/results screen — "Save your earlier verdicts to your account? [Save] [Dismiss]"
- Per-app, contextual. Not a global modal. Not silent auto-promotion.
- Why: respects user agency, keeps the prompt visible only where it makes sense, no interruption to the rest of the UI.

### Scope of promoted data
- **Compass answers, address, read-rank verdicts.**
- Mirrors the scope locked in task 260426-mc5. Selected_topics, jurisdictions, XP/gems, profile state are explicitly out.

### Where the logic lives
- **`useEvContextPromotion()` hook in `@empoweredvote/ev-ui`.**
- Tentative shape: `useEvContextPromotion({ domain, apiData, isLoggedIn, userId })` → returns `{ shouldPrompt, promote(): Promise, dismiss(): void }`.
  - `shouldPrompt`: boolean — true iff `isLoggedIn && apiData empty && evContext[domain] populated`
  - `promote()`: calls a caller-supplied API writer with the ev-context payload, then on success stamps the authed slice (the helper added in 260426-mc5) so the prompt stops firing
  - `dismiss()`: optionally writes a per-userId "dismissed" stamp (planner's call)
- Banner UI is per-app (not in ev-ui) — gives each consumer freedom over copy, layout, and styling without forcing a one-size-fits-all banner component.
- Why: detection logic is the same across apps and benefits from one place to fix bugs; the banner UI varies enough per app that centralizing it would create more friction than it saves.

### Claude's Discretion
- **Dismiss persistence shape.** Whether dismissal sticks for the session, the user, or until next API write. Planner's call — recommend stamping `evContext.authed.{userId}.promotionDismissed.{domain} = true` on dismiss, cleared on successful promote.
- **Banner copy and styling.** Each consumer app picks copy that matches its existing UI tone. The planner can suggest copy but should not lock it.
- **What "address" means for the prompt.** Today essentials writes address via `POST /connect/set-location`. The hook should accept an `apiWriter` callback so each consumer wires its own endpoint — keeps the hook decoupled from backend specifics.

</decisions>

<specifics>
## Specific Ideas

- **Existing endpoints (no changes):**
  - `POST /compass/answers/batch` — bulk compass-answer save
  - `POST /compass/verdicts` — verdict map save
  - `POST /connect/set-location` — address save
- **Existing helpers (from task 260426-mc5):**
  - `evContext.getAuthedSlice({ userId })` / `setAuthedSlice(...)` / `clearAuthedSlice()` — the userId-stamped cache
  - These are the read-side for "what does ev-context have" check
- **Reference pattern:** essentials' existing `suggestedSaveAddress` flow is the closest precedent — same shape (detect gap, offer to save, single endpoint). The new hook should generalize it.
- **The promotion seam in the backend (`promoteCompassImportDraft()`) stays untouched** — it covers the Connected-onboarding case. This task covers everyone else.

</specifics>

<canonical_refs>
## Canonical References

- `CLAUDE.md` — "Current Workstreams › ev-context follow-ups": item #1 ("Compass guest → authed promotion via ev-context")
- `CLAUDE.md` — "Cross-subdomain shared state (ev-context)" section
- `.planning/quick/260426-mc5-authed-users-write-through-ev-context-as/260426-mc5-CONTEXT.md` — sibling task, shares scope decisions
- `ev-accounts/backend/src/lib/compassService.ts:36-66` — `promoteCompassImportDraft()` (existing seam, for context only)

</canonical_refs>
