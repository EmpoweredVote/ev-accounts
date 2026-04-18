# Phase 122: Cross-App Loop Polish - Research

**Researched:** 2026-04-16
**Domain:** Cross-app state relay (CompassV2 ↔ Essentials ↔ Treasury Tracker) — URL fragments, localStorage, React context, env-driven cross-origin links
**Confidence:** HIGH

## Summary

Phase 122 closes three residual integration gaps in the voter loop. All three are **wiring / configuration fixes**, not new features — the relay primitives (`serializeCompassFragment`, `parseCompassFragment`, `saveGuestCompass`, `loadGuestCompass`, `/api/treasury/cities`, cross-app `VITE_*_URL` env vars) already exist and work. The work is (a) diagnosing why the already-written INTG-01 chain doesn't surface data on return visits, (b) verifying a link that appears to already be correct (INTG-02), and (c) adding a thin UI layer that fetches one new endpoint and renders a conditional CTA (INTG-03).

Two findings change the plan:

1. **INTG-02 is likely already solved in code.** `/compass/politicians` returns `essentials.politicians.id` (a unified UUID after Phase 35 dedup). `/politician/:id` in Essentials resolves any such UUID. The link at `ComparePanel.jsx:120` already appends `serializeCompassFragment()`. Verification-first (D-07) applies — do not write code for a problem that doesn't exist. The only remaining risk is that Phase 117's `is_candidate` flag excludes candidates from the picker query, not that the link is wrong.
2. **Treasury Tracker already supports deep links** via `?entity=<slug>&year=<y>&dataset=<d>` query params (see `treasury-tracker/src/App.tsx:30` — slug format is `${name-kebab}-${state-lower}`, e.g. `bloomington-in`). D-11 deep-link question is answered YES.

**Primary recommendation:** Sequence the plan as (1) INTG-01 diagnostic wave → (1b) fix at the broken layer, (2) INTG-02 verification wave (likely closes with evidence only), (3) INTG-03 implementation wave. Treat each as a separate plan or a single 3-wave plan depending on planner judgement.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**INTG-01: CompassCard State Relay**
- **D-01:** On Essentials profile load with no fresh `#compass=` fragment, CompassCard should read `guestCompass` from Essentials-domain localStorage and render the comparison overlay. Empty guestCompass → show "Calibrate your compass" CTA.
- **D-02:** **Diagnose-first approach.** Verify (a) fragment write on arrival, (b) `loadGuestCompass()` read on return visit, (c) `userAnswers` populated before CompassCard mounts. Fix whichever layer is broken — do not assume.
- **D-03:** Fragment relay is the only cross-origin bridge. Chain: CompassV2 `serializeCompassFragment()` → `#compass=` → Essentials `parseCompassFragment()` → `saveGuestCompass()` → `guestCompass` localStorage key. All three must work.
- **D-04:** Do not follow through past the first root cause until that layer is verified fixed. Confirm `guestCompass` is present on the next direct visit before moving on.

**INTG-02: Compass→Essentials Profile Links**
- **D-05:** Current link is `/politician/${politician.id}` + `serializeCompassFragment()` — this is the Essentials UUID route.
- **D-06:** Verification-first. Confirm (a) link resolves for Pierce UUID, (b) any candidate picker entries still resolve (check `/candidate/:id` fallback), (c) fix ID mapping only if mismatch exists.
- **D-07:** If no code fix is needed, document verification evidence and close INTG-02. Do not add code for a non-existent problem.

**INTG-03: Essentials→Treasury CTA**
- **D-08:** CTA appears below each local-tier municipality section in Essentials Results page. "Section" = grouped block for a specific body (e.g. "Bloomington City Council").
- **D-09:** Dynamic detection via Treasury API — query endpoint listing municipalities with data; match against local-tier section headings; show CTA for matches, hide for non-matches.
- **D-10:** CTA text: `Explore [Municipality] revenue and expenses →` — no dollar amount.
- **D-11:** Destination: `https://treasurytracker.empowered.vote` via env var, deep-linked if URL structure supports it (researcher to check — **ANSWER: YES, supports `?entity=<slug>` deep linking**).
- **D-12:** Placement: below the municipality section (after official cards), not header. No match → no CTA (not grayed out).

**Verification & Sequencing**
- **D-13:** Production verification required on essentials.empowered.vote / compass.empowered.vote after Render deploy. Local dev for iteration only.
- **D-14:** Both guest and logged-in paths verified for INTG-01 and INTG-02 (matches Phase 118 D-15).
- **D-15:** Sequencing: INTG-01 → INTG-02 → INTG-03, single plan, single Render deploy.
- **D-16:** If INTG-01 fix lands in `ev-ui`, ship via auto-bump pipeline.

### Claude's Discretion
- Exact diagnostic commands, localStorage inspection steps, network tracing for INTG-01.
- Optional defensive dev-mode log when `guestCompass` is empty but fragment parsing was attempted.
- Visual treatment of the Treasury CTA — follow existing Essentials design (`ev-coral`, `ev-muted-blue`, `ev-light-blue`, Manrope, Tailwind 4).
- Whether Treasury deep-link routes to specific municipality (researcher to determine — **ANSWER: yes, supported**).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTG-01 | CompassCard state relay works across app boundaries (G-114-028) | §INTG-01 Diagnostic Plan below — three-layer trace across `saveGuestCompass` / `loadGuestCompass` / `userAnswers` population |
| INTG-02 | Compass compare page links to Essentials politician profiles (G-114-030) | §INTG-02 Verification Plan — link construction already correct per code read; need evidence |
| INTG-03 | Essentials→Treasury handoff functional (G-114-031) | §INTG-03 Implementation Plan — endpoint `/api/treasury/cities` confirmed; slug deep-link confirmed |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fragment serialization (`#compass=`) | CompassV2 client (browser) | — | Origin is compass.empowered.vote; reads its own localStorage and writes fragment on outbound link |
| Fragment parsing + persistence | Essentials client (browser) | — | Origin is essentials.empowered.vote; only this origin can write to `guestCompass` key under its own domain |
| Picker politician list | ev-accounts API (`/api/compass/politicians`) | — | Already exists; returns `essentials.politicians.id` UUIDs |
| Compass→Essentials link URL building | CompassV2 client (`ComparePanel`) | — | Built from env var + politician.id |
| Treasury municipality list | ev-accounts API (`GET /api/treasury/cities`) | — | Already exists; returns `{ id, name, state, available_datasets, ... }` |
| Local-section → municipality match | Essentials client (Results.jsx) | — | String normalization only; no API changes needed |
| Treasury CTA render | Essentials client | ev-ui (optional — if component lifted) | One-off CTA; hand-rolled styled anchor likely sufficient |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.x | UI (Essentials, CompassV2, Treasury Tracker) | [VERIFIED: project CLAUDE.md] already the stack |
| Vite | 6 (CompassV2) / 7 (Essentials) | Dev server + build | [VERIFIED: CLAUDE.md] already the stack |
| Tailwind CSS | 4 | Styling | [VERIFIED: CLAUDE.md] already the stack |
| `react-router-dom` | v6+ | Routing for Essentials (`/politician/:id`, `/candidate/:id`) | [VERIFIED: essentials/src/App.jsx:53-56] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@empoweredvote/ev-ui` | latest | Shared components (SiteHeader, StanceAccordion, GovernmentBodySection, SubGroupSection) | [VERIFIED: grep across repos] If INTG-01 touches `StanceAccordion`, ship via auto-bump |
| `@dnd-kit`, Framer Motion | — | [CITED: CLAUDE.md] already in CompassV2 | Not needed for Phase 122 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| localStorage fragment bridge | postMessage + iframe | [REJECTED — existing system is D-03 locked-in] |
| Server-side state relay | Backend-mediated session | [REJECTED — G-114-027 cookie path already handles authed case; guest case must stay fragment-based] |

**Installation:** No new dependencies required. All relay primitives already imported.

**Version verification:** Check current `@empoweredvote/ev-ui` version in `essentials/package.json` before planning INTG-01 fix, in case the fix lands in ev-ui and requires auto-bump.

## Architecture Patterns

### System Architecture Diagram

```
  ┌──────────────────────────┐     outbound link       ┌──────────────────────────┐
  │  CompassV2 (browser)     │  /politician/<id>       │  Essentials (browser)    │
  │  compass.empowered.vote  │  #compass=BASE64(a,s,i) │  essentials.empowered… │
  │                          │ ──────────────────────► │                          │
  │  localStorage:           │                         │  CompassContext on mount:│
  │   answers: {short:val}   │                         │   1) extractHashToken    │
  │   selectedTopics: [uuid] │                         │   2) parseCompassFragment│
  │   invertedSpokes: {}     │                         │   3) SSO cookie check    │
  │                          │                         │   4) auth fetch me       │
  │  serializeCompassFragment│                         │   5) fetchTopics +       │
  │   reads those 3 keys     │                         │      fetchPoliticians    │
  │   → base64 JSON          │                         │   6) priority chain:     │
  │   → "#compass=…"         │                         │      API > fragment >    │
  │                          │                         │      localStorage > ∅    │
  │                          │                         │   7) setUserAnswers(...) │
  │                          │                         │                          │
  │                          │  ◄ ─ fragment cleared ─ │   history.replaceState   │
  │                          │                         │   saveGuestCompass(a,s,i)│
  │                          │                         │                          │
  │                          │                         │  localStorage:           │
  │                          │                         │   guestCompass: {a,s,i}  │
  │                          │                         │                          │
  │                          │                         │  CompassCard subscribes  │
  │                          │                         │  to userAnswers via      │
  │                          │                         │  useCompass(); renders   │
  │                          │                         │  hasUserCompass branch   │
  └──────────────────────────┘                         └────────────┬─────────────┘
                                                                    │ (separate)
                                                                    │ below each
                                                                    │ local section
                                                                    ▼
                                                    ┌──────────────────────────┐
                                                    │  Essentials Results.jsx  │
                                                    │                          │
                                                    │  GET /api/treasury/cities│
                                                    │   → [{name, state,       │
                                                    │       available_datasets}│
                                                    │                          │
                                                    │  normalize(body.title)   │
                                                    │   vs normalize(name)     │
                                                    │   → match?               │
                                                    │                          │
                                                    │  if match →              │
                                                    │   render <a href=…>      │
                                                    │    treasurytracker.…/    │
                                                    │    ?entity=<slug>        │
                                                    └──────────────────────────┘
```

### Recommended Project Structure

No new files mandated. Touch points:
```
essentials/src/
├── contexts/CompassContext.jsx         # may need instrumentation for INTG-01 diagnosis
├── lib/compass.js                      # parse/save/load primitives live here
├── components/CompassCard.jsx          # hasUserCompass render gate (line 71)
├── pages/Results.jsx                   # add Treasury CTA insertion point under body.subgroups
└── lib/treasury.js                     # NEW (suggested): tiny fetch wrapper for /api/treasury/cities

CompassV2/src/components/
├── CompassContext.jsx §281-291         # serializeCompassFragment (canonical)
└── ComparePanel.jsx:118-137            # "View full profile" link (already correct)
```

### Pattern 1: Cross-Origin Guest Relay via URL Fragment
**What:** Serialize localStorage → base64 JSON → URL fragment → parse on arrival → write to destination-origin localStorage.
**When to use:** Guest state relay between apps on different subdomains where cookies/shared storage aren't viable.
**Example:**
```js
// Source: CompassV2/src/components/CompassContext.jsx §284-295 [VERIFIED]
export function serializeCompassFragment() {
  const answers = JSON.parse(localStorage.getItem("answers") || "{}");
  const selectedTopics = JSON.parse(localStorage.getItem("selectedTopics") || "[]");
  const invertedSpokes = JSON.parse(localStorage.getItem("invertedSpokes") || "{}");
  if (Object.keys(answers).length === 0) return "";
  const payload = { a: answers, s: selectedTopics, i: invertedSpokes };
  return "#compass=" + btoa(JSON.stringify(payload));
}
```
```js
// Source: essentials/src/lib/compass.js §117-157 [VERIFIED]
export function parseCompassFragment() { /* reads hash, base64-decodes, validates, strips via history.replaceState */ }
export function saveGuestCompass(answers, selectedTopics, invertedSpokes) {
  localStorage.setItem("guestCompass", JSON.stringify({ a, s, i }));
}
```

### Pattern 2: Priority Chain for User State
**What:** Load user state from highest-trust source first, fall through to lower-trust sources.
**When:** CompassContext does this for both answers (API > fragment > localStorage > empty) and verdicts. [VERIFIED: CompassContext.jsx §104-161]

### Pattern 3: Env-driven Cross-App Links
**Example:** `CompassV2/ComparePanel.jsx:9-10` uses `import.meta.env.VITE_ESSENTIALS_URL || "https://essentials.empowered.vote"`. Add `VITE_TREASURY_URL` to `essentials/.env*` for INTG-03.

### Anti-Patterns to Avoid
- **Reading CompassV2 localStorage from Essentials:** Impossible (origin isolation). Must go through fragment.
- **Hardcoding production URLs:** Use env vars with production defaults (matches existing pattern).
- **Matching `government_body_name` case-sensitively to Treasury name:** Use case-insensitive + tokenized match (`includes(municipality_name_lower)`).
- **Fetching `/api/treasury/cities` per card render:** Fetch once at Results page mount, memoize.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Base64 URL-safe encoding | Custom encoder | Built-in `btoa` / `atob` | Already used in `serializeCompassFragment` / `parseCompassFragment` |
| Fragment strip after parse | Manual history manipulation | `history.replaceState(null, '', pathname + search)` | [VERIFIED: compass.js §142] already the pattern |
| Municipality slug generation | Custom kebab-case | Reuse Treasury Tracker's `toSlug()` logic: `${name.toLowerCase().replace(/\s+/g, '-')}-${state.toLowerCase()}` | [VERIFIED: treasury-tracker/src/App.tsx:30] — this is the exact format the destination app expects |
| Guest state shape | Reinvent | Existing `{ a, s, i }` JSON payload shape in fragment; `{ a, s, i }` key structure in `guestCompass` | Already round-trips correctly |
| Cross-app auth relay | DIY cookie plumbing | Existing `.empowered.vote` shared cookie + `/auth/session` SSO check | [VERIFIED: CompassContext.jsx §59-75] out of scope for Phase 122 anyway (G-114-027 deferred) |

**Key insight:** Every primitive needed already exists. Phase 122 is wiring + verification + one thin CTA component — not new infrastructure.

## Common Pitfalls

### Pitfall 1: Assuming the Break is in localStorage
**What goes wrong:** Dev inspects `localStorage.getItem('guestCompass')` on a return visit, sees it's populated, declares INTG-01 fixed — but CompassCard still shows "Calibrate your compass" because the data never reaches `userAnswers`.
**Why it happens:** The priority chain in `CompassContext.jsx §129-147` has three branches. `loadGuestCompass()` is only called on the third branch (guest + no fragment). If the user is logged in (`authedUser` truthy), that path is skipped and `fetchUserAnswers()` result wins — even if it returns `[]`.
**How to avoid:** Verify `userAnswers.length > 0` in CompassContext state AFTER `compassLoading` flips to false, not just the localStorage read. Use React DevTools or add a temporary `console.log` inside the context.
**Warning signs:** `guestCompass` populated but `useCompass().userAnswers` empty on return visit.

### Pitfall 2: Race Condition Between `extractHashToken` and `parseCompassFragment`
**What goes wrong:** `extractHashToken()` at `CompassContext.jsx:51` runs before `parseCompassFragment()` at §56. If the incoming URL contains BOTH `#access_token=…` and `#compass=…`, only one can survive the hash-read; whichever runs second may see an empty hash (because the first already called `history.replaceState`).
**Why it happens:** Both functions read `window.location.hash` and both call `history.replaceState` to strip the fragment.
**How to avoid:** Check `extractHashToken()` implementation — does it strip ONLY `#access_token=` or the whole hash? If the latter, `parseCompassFragment()` sees nothing. Add this to the diagnosis checklist.
**Warning signs:** Fragment relay works for guests but fails when the user just logged in and got redirected with a token.

### Pitfall 3: `convertGuestAnswersToApiFormat` Silently Drops Unknown Topics
**What goes wrong:** `compass.js §167-176` iterates `[short_title, value]` and looks up `topics.find((t) => t.short_title === shortTitle)`. If CompassV2 wrote a stale `short_title` (typo fix, topic rename), the conversion silently omits that answer — `userAnswers` ends up with fewer entries than expected, possibly empty.
**Why it happens:** No error on unknown short_title; just skipped.
**How to avoid:** During diagnosis, if `guestCompass` is populated but `userAnswers` is `[]`, check whether the short_titles in `guestCompass.a` exist in the current `topics` response.
**Warning signs:** `Object.keys(loadGuestCompass().answers).length > 0` but `userAnswers.length === 0`.

### Pitfall 4: `politicianIdsWithStances` Gate Hides the Real Problem
**What goes wrong:** CompassCard `return null` at line 69 if `politicianIdsWithStances` doesn't contain the current politician's UUID — the diagnostic dev thinks the relay is broken, but actually the politician just doesn't have stance data.
**Why it happens:** `/compass/politicians` only returns politicians with at least one `inform.politician_answers` row [VERIFIED: compassService.ts §281].
**How to avoid:** Before diagnosing INTG-01, confirm the test politician (e.g. Pierce) is in the `politicianIdsWithStances` set. Use the Pierce UUID `72dd5219-490f-48bb-986e-183a6098d602` (from 118-CONTEXT.md) — it has 10 quotes per prior phase verification.

### Pitfall 5: Treasury Municipality Name vs Essentials Body Name Drift
**What goes wrong:** `body.title` in Essentials Results is "Bloomington City Council" (or "Monroe County Government"); Treasury `municipalities.name` is "Bloomington" or "Monroe County". Naive equality fails everywhere.
**How to avoid:** Normalize both sides: lowercase, strip common suffixes (`city council`, `town council`, `government`, `board of commissioners`, `township trustee`). Match if normalized Treasury name is a substring of normalized body title.
**Warning signs:** `/api/treasury/cities` returns Bloomington but no CTA appears under "Bloomington City Council".

### Pitfall 6: CTA Under County / Township When Only City Has Data
**What goes wrong:** Current Treasury DB has Bloomington only. If the matcher is too loose, CTA shows up under "Monroe County Board of Commissioners" (county ≠ city). D-12 says no false positives.
**How to avoid:** Require `entity_type` match (Treasury `municipalities.entity_type` column exists per `treasuryService.ts §290`). Only show CTA when the local-tier section's body-type aligns with the municipality's entity_type. Safer fallback: match only when body.title contains the municipality name as a whole word.

## Runtime State Inventory

> Phase 122 is not a rename/refactor phase. Included for completeness.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Essentials localStorage: `guestCompass`, `guestVerdicts`, `lastZip` (already cleared §20). CompassV2 localStorage: `answers`, `selectedTopics`, `invertedSpokes`, `writeIns`, `guestId`. No DB changes needed. | None — read/write paths already compatible |
| Live service config | None — no external service configs touched | None |
| OS-registered state | None | None |
| Secrets/env vars | `VITE_TREASURY_URL` — new, optional, defaults to `https://treasurytracker.empowered.vote`. Add to `essentials/.env.example` / Render env vars. `VITE_ESSENTIALS_URL` and `VITE_COMPASS_URL` already exist. | Add one Render env var for Essentials production |
| Build artifacts | None — no package rename | None |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Essentials dev server | Local iteration | ✓ | Vite 7 | — |
| CompassV2 dev server | Local iteration | ✓ | Vite 6 | — |
| ev-accounts backend (local) | `/api/treasury/cities`, `/api/compass/*` | Assumed available (project CLAUDE.md describes dev flow) | Node 20 | Hit production `api.empowered.vote` if local backend unavailable |
| `api.empowered.vote` (prod) | D-13 production verification | ✓ (live) | — | — |
| Treasury Tracker prod | Link destination | ✓ (`treasurytracker.empowered.vote`) | — | Root URL fallback if deep-link format changes |

No blocking dependencies. All tools available.

## INTG-01 Diagnostic Plan [CITED: D-02, D-04]

**Goal:** Identify which of the three relay layers is broken before writing any fix.

### Layer A — Arrival-time Fragment Write
**Test:** Open compass.empowered.vote as guest, answer at least 1 topic (so `answers` localStorage is non-empty), click "View full profile on Essentials" on Compare panel. On arrival at essentials.empowered.vote:

1. Open DevTools BEFORE the fragment is stripped. (Note: `parseCompassFragment` calls `history.replaceState` synchronously inside `CompassContext` effect — may need `sources` panel breakpoint or `?slow-3g` throttle to catch it.)
2. Check `location.hash` — should contain `#compass=BASE64…`.
3. After effect runs, check `localStorage.getItem('guestCompass')` — should be populated.

**Expected result:** Both present.
**If fragment absent on arrival:** Bug is in CompassV2 — likely `serializeCompassFragment` returned `""` because `answers` was empty (CompassV2 localStorage was cleared or never written). Test by opening `compass.empowered.vote` in a clean browser, checking `localStorage.getItem('answers')` after answering a question.
**If fragment present but `guestCompass` not written:** Bug is in `saveGuestCompass` call site inside `CompassContext.jsx §136` — check whether the fragment's `answers` field is null (verdict-only fragment guard at §132).

### Layer B — Return-visit localStorage Read
**Test:** After Layer A succeeds, close the tab, reopen `https://essentials.empowered.vote/politician/<UUID>` (NO `#compass=` in URL).

1. Check `localStorage.getItem('guestCompass')` — should still be populated.
2. In React DevTools, inspect `CompassContext` provider value: `userAnswers` should be non-empty; `compassLoading` should be false.

**Expected result:** Both present.
**If localStorage persists but `userAnswers` is `[]`:** Bug is in `CompassContext.jsx §140-147` OR `convertGuestAnswersToApiFormat` (see Pitfall 3). Log `cached` from §141 and `topics` from §92 — mismatch between `short_title` keys means the converter dropped all answers.

### Layer C — Render Condition
**Test:** Once `userAnswers.length > 0` is confirmed in context state, check CompassCard render.

1. Is politician in `politicianIdsWithStances`? (Pitfall 4.)
2. Is `hasUserCompass` true? `CompassCard.jsx:71` computes this as `userAnswers && userAnswers.length > 0`.
3. Does the render hit line 165 (hasUserCompass branch) or line 342 (guest-fallback branch)?

**If still renders guest branch with `userAnswers.length > 0`:** React re-render timing bug — likely CompassCard rendered before context finished loading but didn't re-render. Check `compassLoading` gate at line 66.

### Fix Location Hypotheses (by prior probability, descending)
1. **Essentials `CompassContext.jsx` priority-chain bug** — the `authedUser` branch doesn't call `loadGuestCompass()` fallback for users with no API answers yet. If the user logs in but hasn't taken the quiz, `authedUser` is truthy but `answers` is `[]`; guestCompass gets `clearGuestCompass()`'d at §128. This explains G-114-028 symptom perfectly.
2. **`extractHashToken` ate the compass fragment** — see Pitfall 2. Verify by reading `essentials/src/lib/auth.js:extractHashToken`.
3. **Short-title drift** — CompassV2 answers keyed by `short_title`, topics renamed in DB.
4. **CompassV2 fragment empty because `answers` localStorage was never populated** — less likely per existing evidence, but must rule out.

**Most likely fix:** In `CompassContext.jsx §109-128`, change behavior so that if `authedUser` is present BUT `fetchUserAnswers()` returned empty AND the URL has a fragment, prefer the fragment. OR, if `loadGuestCompass()` has data AND `fetchUserAnswers()` returned empty, preserve the guest cache (don't `clearGuestCompass()` blindly). **Confirm with user during plan-check** — this changes authed-guest priority semantics.

## INTG-02 Verification Plan [CITED: D-06, D-07]

**Current code (verified):**
- Picker source: `GET /api/compass/politicians` → `essentials.politicians` rows, field `id` is the unified UUID.
- Link built at `ComparePanel.jsx:120`: `${ESSENTIALS_URL}/politician/${politician.id}${serializeCompassFragment()}`.
- Essentials has both `/politician/:id` (Profile) and `/candidate/:id` (CandidateProfile) — both route on UUID.

**After Phase 117** the `is_candidate` column will gate picker inclusion. If Phase 117's compassService LEFT JOIN fix already excludes candidates from `/compass/politicians`, then the picker contains only sitting politicians → `/politician/:id` always resolves. If Phase 117 includes candidates, then some picker UUIDs may live in the `is_candidate=true` branch; `/politician/:id` still loads `Profile.jsx` which fetches from a politician endpoint that may 404 for pure candidates.

**Verification steps:**
1. Open `https://compass.empowered.vote`, select a politician (Matt Pierce `72dd5219-490f-48bb-986e-183a6098d602`). Confirm "View full profile on Essentials" link opens `/politician/<uuid>` and loads Pierce's profile with CompassCard populated (validates INTG-01 and INTG-02 simultaneously).
2. If a candidate-type picker entry exists post-Phase 117: click their link, verify behavior. If Profile page 404s/errors, two options:
   (a) Change link target to `/candidate/<uuid>` when `is_candidate` flag present on picker row. Requires adding `is_candidate` to `/compass/politicians` response.
   (b) Have `/politician/:id` fall through to candidate rendering when the politician is flagged `is_candidate`. (Likely cleaner; matches unified-table philosophy.)
3. If all picker entries are politicians (Phase 117 filter excludes candidates): document evidence, close INTG-02 with zero code change per D-07.

**Likely outcome:** No code change. INTG-02 closes with a screenshot of a successful Pierce profile load via the picker link.

## INTG-03 Implementation Plan

### Treasury API Contract [VERIFIED: routes/treasury.ts:46 + treasuryService.ts:288]
- Endpoint: `GET /api/treasury/cities` (public, `optionalAuth`)
- Response shape:
```ts
TreasuryCity[] where TreasuryCity = {
  id: string,           // UUID
  name: string,         // e.g. "Bloomington"
  state: string,        // e.g. "IN"
  entity_type: string,  // e.g. "city" / "county" / "township"
  population: number | null,
  hero_image_url: string | null,
  created_at: string,
  updated_at: string,
  available_datasets: Array<{ fiscal_year, dataset_type }>  // [] if no budgets
}
```
- **Has-data predicate:** `available_datasets.length > 0`. Municipalities with zero budgets should NOT show CTA.

### Treasury Tracker Deep-Link [VERIFIED: treasury-tracker/src/App.tsx:30-38]
- Slug format: `${name.toLowerCase().replace(/\s+/g, '-')}-${state.toLowerCase()}`
- Example: "Bloomington" + "IN" → `bloomington-in`
- Full URL: `https://treasurytracker.empowered.vote/?entity=bloomington-in`
- Optional additional params: `&year=<fiscal_year>&dataset=<revenue|operating|salaries>`. Omit for default landing.

### Matching Strategy
Section data in Results.jsx comes from `body` objects inside `filteredHierarchy`, where `body.title` is the government-body display name (e.g. "Bloomington Common Council", "Monroe County Government"). Match rule:

```js
function normalize(s) {
  return s.toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function findMatchingMunicipality(bodyTitle, municipalities) {
  const titleLower = normalize(bodyTitle);
  // Require the municipality NAME to appear as a whole-word prefix of the body title,
  // AND require at least one budget dataset available.
  return municipalities.find(m =>
    m.available_datasets.length > 0 &&
    titleLower.startsWith(normalize(m.name))
  ) || null;
}
```
This matches "Bloomington Common Council" (starts with "bloomington") → `m.name = "Bloomington"`, but does NOT match "Monroe County Government" (doesn't start with "bloomington"). Correctly handles future county data: when "Monroe County" municipality is added to Treasury, "Monroe County Government" title starts-with matches.

**Edge case:** Two municipalities with overlapping name prefixes (e.g. "Bloomington" and "Bloomington Township"). Sort matches by `m.name.length` desc and pick the longest match.

### Insertion Point [VERIFIED: essentials/src/pages/Results.jsx §920-954]
The local-tier section renders:
```jsx
<GovernmentBodySection key={body.key} title={body.title} ...>
  {body.subgroups.map(sg => <SubGroupSection .../>)}
</GovernmentBodySection>
```
Insert CTA AFTER `</GovernmentBodySection>`:
```jsx
{tier === 'Local' && (() => {
  const match = findMatchingMunicipality(body.title, treasuryCities);
  return match ? (
    <div className="mt-2 mb-4">
      <a
        href={`${TREASURY_URL}/?entity=${toSlug(match)}`}
        className="inline-flex items-center gap-1 text-sm text-[#59b0c4] hover:text-[#00657c] transition-colors"
        style={{ fontFamily: "'Manrope', sans-serif" }}
      >
        Explore {match.name} revenue and expenses
        <svg viewBox="0 0 16 16" className="w-3 h-3" fill="currentColor">
          <path fillRule="evenodd" d="M4.22 11.78a.75.75 0 010-1.06L9.44 5.5H5.75a.75.75 0 010-1.5h5.5a.75.75 0 01.75.75v5.5a.75.75 0 01-1.5 0V6.56l-5.22 5.22a.75.75 0 01-1.06 0z" clipRule="evenodd"/>
        </svg>
      </a>
    </div>
  ) : null;
})()}
```
Styling reference: `CompassV2/src/components/ComparePanel.jsx:118-137` (same ev-light-blue `#59b0c4`, Manrope font, inline arrow SVG) — matches ReturnBanner-style cross-app link language from §design-system.

### Data-Fetch Wiring
- Add `fetchTreasuryCities()` to `essentials/src/lib/` (new tiny file `treasury.js` or extend existing). Use `publicFetch` / `apiFetch` from `lib/auth.js`.
- Fetch once in `Results.jsx` `useEffect(() => { ... }, [])`. Memoize result in state.
- Gate CTA render on state present (don't render while loading, don't show placeholder).
- Handle API failure gracefully: `catch` → treat as empty list → no CTAs rendered (matches D-12 "no match → no CTA").

### New Env Var
Add to `essentials`:
```
VITE_TREASURY_URL=https://treasurytracker.empowered.vote
```
Use `import.meta.env.VITE_TREASURY_URL || 'https://treasurytracker.empowered.vote'` pattern matching `VITE_COMPASS_URL` usage at `CompassCard.jsx:7`.

## Code Examples

### Existing: Fragment Relay Outbound
```jsx
// Source: CompassV2/src/components/ComparePanel.jsx:118-137 [VERIFIED]
<a href={`${ESSENTIALS_URL}/politician/${politician.id}${serializeCompassFragment()}`}
   className="text-xs text-[#59b0c4] hover:text-[#00657c] ...">
  View full profile on Essentials <svg .../>
</a>
```

### Existing: Fragment Relay Inbound
```jsx
// Source: essentials/src/contexts/CompassContext.jsx §129-147 [VERIFIED]
} else if (fragment) {
  if (fragment.answers !== null) {
    answers = convertGuestAnswersToApiFormat(fragment.answers, topics);
    selected = fragment.selectedTopics;
    inverted = fragment.invertedSpokes || {};
    saveGuestCompass(fragment.answers, fragment.selectedTopics, inverted);
  }
} else {
  const cached = loadGuestCompass();
  if (cached) {
    answers = convertGuestAnswersToApiFormat(cached.answers, topics);
    selected = cached.selectedTopics;
    inverted = cached.invertedSpokes || {};
  }
}
```

### New: Treasury Cities Fetch
```js
// Source: [ASSUMED — standard essentials fetch pattern]
// essentials/src/lib/treasury.js (suggested new file)
import { apiFetch } from './auth';

export async function fetchTreasuryCities() {
  try {
    const res = await apiFetch('/treasury/cities');
    if (!res || !res.ok) return [];
    return await res.json();
  } catch {
    return [];
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Two separate politician tables (sitting + candidates) | Unified `essentials.politicians` after Phase 35 dedup | Pre-v2026 | `/politician/:id` resolves for both; INTG-02 likely zero-code |
| Go backend treasury routes | Express `/api/treasury/*` in ev-accounts | Go retirement milestone | Confirmed: `/api/treasury/cities` is the endpoint |
| Cookie-only guest state | localStorage + fragment relay | Pre-Phase 122 | Already working; diagnose-first |

**No deprecated APIs affect Phase 122.**

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `extractHashToken` strips only `#access_token=…`, not entire hash | Pitfall 2 | If it strips the full hash, `parseCompassFragment` always sees empty hash after a logged-in redirect → need to refactor order in `CompassContext.jsx`. Diagnosis Layer A will surface this. |
| A2 | Treasury Tracker's `?entity=<slug>` routing is stable and will not change | D-11 resolution | If slug format changes, deep links 404; root URL fallback mitigates. Add URL-construction to a small helper for easy update. |
| A3 | Post-Phase-117, `/compass/politicians` excludes `is_candidate=true` rows | INTG-02 Verification | If candidates ARE included, `/politician/:id` may error for pure candidates. Verification plan handles this. |
| A4 | `body.title` in Results `filteredHierarchy` is stable identifier (e.g. "Bloomington Common Council") | INTG-03 matching | If it contains prefixes like "Local: Bloomington…" the `startsWith` match fails. Planner should inspect actual body.title strings during Wave 0. |
| A5 | `/api/treasury/cities` returns ≤ ~50 rows (currently one municipality, growing slowly) | CTA fetch | If response balloons, still fine — memoize on mount. No pagination needed. |

**All assumptions are falsifiable via inspection during plan execution.**

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | No formal test suite on Essentials / CompassV2 frontends. Backend has Vitest (`ev-accounts`). Phase 118/119 pattern was manual + production verification. |
| Config file | `ev-accounts/backend/vitest.config.ts` (not relevant — all phase 122 fixes are frontend) |
| Quick run command | Local dev server smoke: `cd essentials && npm run dev` + manual flow |
| Full suite command | `cd ev-accounts/backend && npm test` (backend contract tests — not touched by this phase) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTG-01 | Returning guest with prior compass sees comparison overlay on profile | manual-only | (DevTools console + React DevTools inspection) | ✅ existing infra |
| INTG-01 | Logged-in user with API answers sees overlay | manual-only | Same as above, logged-in path | ✅ |
| INTG-02 | "View full profile" link from Pierce picker entry loads profile with compass hydrated | manual-only | Browser navigation check on compass.empowered.vote → essentials.empowered.vote | ✅ |
| INTG-02 | (conditional) Candidate-type picker entry link resolves | manual-only | Repeat for a candidate if picker includes them | ✅ |
| INTG-03 | Bloomington local sections show Treasury CTA | manual-only | Visit Results page for a Bloomington address; DOM-inspect for CTA link | ✅ |
| INTG-03 | CTA destination loads Treasury Tracker Bloomington view | manual-only | Click CTA; verify Treasury Tracker `?entity=bloomington-in` renders | ✅ |
| INTG-03 | Non-Treasury-covered body (e.g., a township with no budget) has NO CTA | manual-only | DOM-negative-assert for a township section | ✅ |
| INTG-03 | `/api/treasury/cities` endpoint shape unchanged | backend contract | `curl https://api.empowered.vote/api/treasury/cities \| jq '.[0] \| keys'` | ✅ |

### Sampling Rate
- **Per task commit:** Local dev manual smoke on the modified flow.
- **Per wave merge:** Full cross-app loop walkthrough (compass → click → essentials with compass hydrated → local section CTA → treasury tracker).
- **Phase gate:** Production verification on essentials.empowered.vote + compass.empowered.vote after Render deploy (D-13).

### Wave 0 Gaps
- [ ] `essentials/src/lib/treasury.js` — new tiny fetch helper (if planner chooses to extract)
- [ ] Production smoke script (suggested, optional): `curl https://api.empowered.vote/api/treasury/cities` to lock in shape expectation before frontend work. Already works without a script.
- [ ] No test framework install needed — this phase follows Phases 118/119 manual-verification pattern.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase doesn't touch auth (G-114-027 deferred) |
| V3 Session Management | no | No session changes |
| V4 Access Control | partial | Treasury cities endpoint is `optionalAuth` public data — intentional |
| V5 Input Validation | yes | Fragment payload already validated in `parseCompassFragment` (typeof checks, JSON.parse wrapped in try/catch); body.title → municipality matching must not inject URL values unsanitized |
| V6 Cryptography | no | Base64 is encoding, not encryption — state is not sensitive (compass answers are stance values, not PII) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious `#compass=` payload | Tampering | `parseCompassFragment` already wraps `JSON.parse(atob(...))` in try/catch, returns null on failure [VERIFIED: compass.js §117-157] |
| Open redirect via Treasury URL | Tampering | `TREASURY_URL` is env-driven with a production default; user never controls the destination URL |
| Quadratic matching cost if Treasury municipalities grow | DoS | Memoize `treasuryCities` fetch; `.find()` over a list of ~50 is O(n) and fine |
| XSS via municipality name inserted into CTA text | — | React escapes text children by default; `match.name` rendered as `{match.name}` is safe |

## Sources

### Primary (HIGH confidence)
- `essentials/src/contexts/CompassContext.jsx` (full file read) — priority chain, loading effect, fragment handling
- `essentials/src/lib/compass.js` (full file read) — bridge primitives
- `essentials/src/components/CompassCard.jsx` (full file read) — render gate, two call sites
- `essentials/src/App.jsx` (full file read) — route inventory
- `essentials/src/pages/Results.jsx` (targeted reads §400-512, §900-970) — hierarchy grouping + local-tier render
- `CompassV2/src/components/CompassContext.jsx` (partial + serializer §281-295) — serialization source
- `CompassV2/src/components/ComparePanel.jsx` (first 140 lines) — outbound link construction
- `CompassV2/src/components/ReturnBanner.jsx` (full) — styling reference
- `CompassV2/src/hooks/usePoliticianList.js` (full) — picker fetch source
- `ev-accounts/backend/src/routes/treasury.ts` (full) — cities endpoint confirmation
- `ev-accounts/backend/src/lib/treasuryService.ts` §286-327 — response shape
- `ev-accounts/backend/src/routes/compass.ts` §450-465 — `/compass/politicians` route
- `ev-accounts/backend/src/lib/compassService.ts` §261-305 — getCompassPoliticians (UUIDs, unified table)
- `treasury-tracker/src/App.tsx` §1-60 — slug format `toSlug()` + query-string routing
- `.planning/phases/122-cross-app-loop-polish/122-CONTEXT.md` — locked decisions
- `.planning/REQUIREMENTS.md` — INTG-01/02/03 acceptance criteria
- `.planning/ROADMAP.md` §Phase 122 — goals
- `.planning/GAP-REPORT.md` §G-114-027/028/030/031 — fix sketches

### Secondary (MEDIUM confidence)
- `.planning/phases/118-read-rank-verdict-badge-fix/118-CONTEXT.md` — parallel cross-app pattern (D-11..D-16)

### Tertiary (LOW confidence)
- None — all claims verified from codebase reads.

## Open Questions

1. **Does `extractHashToken` preserve `#compass=` on the hash?**
   - What we know: Both `extractHashToken()` and `parseCompassFragment()` read/modify `window.location.hash`. `extractHashToken` runs first (§51), `parseCompassFragment` runs second (§56).
   - What's unclear: Whether `extractHashToken` calls `history.replaceState(null, '', pathname + search)` unconditionally (wiping compass fragment) or only when it actually extracted a token.
   - Recommendation: Read `essentials/src/lib/auth.js:extractHashToken` during Wave 0 of the INTG-01 plan. If it wipes the full hash, the fix is to restructure the call order OR have it restore non-token hash segments.

2. **Does Phase 117's `compassService` LEFT JOIN fix include or exclude `is_candidate=true` rows from `/compass/politicians`?**
   - What we know: Phase 117 plan 04 is "compassService LEFT JOIN fix (CAND-05 strategy: Option A)". Phase 122 assumes candidates may be present.
   - What's unclear: Exact filtering semantics.
   - Recommendation: Read final Phase 117 plan 04 implementation before starting INTG-02 verification. If candidates included, add `is_candidate` to the `/compass/politicians` response so `ComparePanel` can pick `/politician/:id` vs `/candidate/:id` correctly.

3. **Is there a dev/staging Essentials environment for verification before Render prod deploy?**
   - What we know: Render auto-deploys on main merge; local dev uses `.env.local` pointing to `localhost:3000`.
   - What's unclear: Whether a preview environment exists.
   - Recommendation: D-13 allows local iteration + production gate. If preview exists, use it; otherwise follow the Phase 118/119 pattern (local + prod screenshot).

## Project Constraints (from CLAUDE.md)

- **ev-ui ships via auto-bump pipeline** (`npm version patch` → git tag → OIDC CI publish → `repository_dispatch` to all 4 consumers → auto-merge). If INTG-01 fix lands in ev-ui (e.g., a `StanceAccordion` prop change), follow this flow. No manual consumer cherry-pick. [CLAUDE.md §ev-ui / D-16]
- **Public npm registry** — no `.npmrc` or auth token required for consumers.
- **Never commit `.env`** — all new env vars must go into `.env.example` (and Render dashboard separately) and be explicitly in `.gitignore`.
- **Tailwind 4 + Manrope font** — match existing styling conventions.
- **EV colors:** `ev-coral` (#ff5740), `ev-muted-blue` (#00657c), `ev-light-blue` (#59b0c4), `ev-yellow` (#fed12e). CTA must use `ev-light-blue` / `ev-muted-blue` per ReturnBanner reference.
- **Antipartisan:** No party labels or partisan color associations in new UI. (Treasury CTA is apolitical — OK.)
- **Three-tier account system:** Inform / Connected / Empowered. Phase 122 does not gate by tier — CompassCard already handles guest vs authed paths. CTA is visible to all tiers.
- **Supabase PostGIS** for Essentials address → politician lookup. Phase 122 does not touch geocoding.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries and patterns already in use, verified by direct codebase reads
- Architecture: HIGH — relay chain and endpoint contracts verified; Treasury slug format verified from `treasury-tracker/src/App.tsx:30`
- Pitfalls: MEDIUM — Pitfalls 1–4 derived from code trace; Pitfalls 5–6 are UX/matching-logic inferences
- INTG-01 root cause: MEDIUM — most-likely hypothesis (priority-chain cache clear at §128) is informed but unconfirmed; diagnosis wave will verify

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (30 days for stable integration code) — re-verify if Phase 117 reshapes `/compass/politicians` response before Phase 122 plan runs
