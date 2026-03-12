# Phase 81: Profile Integration - Research

**Researched:** 2026-03-12
**Domain:** Cross-app verdict bridging via URL fragment; React Context extension; ev-ui StanceAccordion quote display
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Verdict granularity**
- Badges are per-quote, not per-topic: `verdictsByQuote: Record<quote_id, 'agreed'|'disagreed'>`
- No topic-level summary badge on the collapsed row — the existing `verdictsByTopic` prop from Phase 80 is superseded by quote-level verdicts
- When a user expands a topic row in StanceAccordion, ALL quotes for that politician/topic are shown — even if the user has zero verdicts
- Quotes with verdicts show Agreed (cyan) or Disagreed (amber) badge; unrated quotes show no badge

**Quote display in StanceAccordion**
- Quotes are ALWAYS shown in the expanded row, not just when the user has verdicts
- Quote loading: lazy-fetch per topic alongside the context fetch (reasoning + sources)
  - Extend the existing context fetch or fire a parallel GET /essentials/quotes?politician_id=X
  - Quotes + reasoning both resolve when user expands the row
- Quote cards display: quote text + verdict badge (if any) + source attribution
- Requires ev-ui update (v0.1.43+): new `verdictsByQuote` prop and quote display in expanded rows

**Fragment format (VERD-05)**
- Fragment key `v` encodes `{ [quote_id]: 'agreed' | 'disagreed' }` directly — no topic_key→UUID mapping needed
- Full fragment schema becomes: `#compass=BASE64({ a, s, i, v })`
- `v` carries ALL verdicts from the current Read & Rank session (across all politicians and topics) — not scoped to one politician
- This way, when a guest visits any politician profile in Essentials, badges appear for any quote they evaluated regardless of which politician they clicked "View on Essentials" from

**"View on Essentials" CTA (PROF-04)**
- Appears on both surfaces in Read & Rank:
  1. CandidateAlignmentPage — direct link to that politician's Essentials profile with full verdict fragment
  2. ResultsPhase — one CTA per candidate card in the results list, each linking to the respective politician's profile
- Fragment encodes all session verdicts (full `v` map), not scoped to the candidate being linked
- The `candidate.id` in Read & Rank is the politician's UUID — Essentials profile URL: `essentials.empowered.vote/politician/{candidate.id}#{compass+verdict fragment}`

**CompassContext verdicts field (PROF-01)**
- New `verdicts` state field: `Record<quote_id, 'agreed' | 'disagreed'>`
- Priority: API (Phase 82, not this phase) > URL fragment `v` key > `guestVerdicts` localStorage key > empty `{}`
- Populated in the same `loadAll()` effect that handles compass data — verdicts from fragment are cached to localStorage alongside compass data being cached to guestCompass

**localStorage strategy**
- Separate key: `guestVerdicts` (not bundled into `guestCompass`)
- Format: `{ [quote_id]: 'agreed' | 'disagreed' }`
- Expiry: Never expires automatically; cleared when user logs in (analogous to `clearGuestCompass()` on login)
- `saveGuestVerdicts(verdicts)` and `loadGuestVerdicts()` helper functions in `essentials/src/lib/compass.js`

### Claude's Discretion
- Whether quotes inside the expanded row render as cards with border or as a simple list
- Exact loading state treatment when quotes are fetching (spinner inline or skeleton)
- Whether to collapse or remove `verdictsByTopic` prop from StanceAccordion given it's superseded (can deprecate silently)
- ev-ui version bump number (v0.1.43 or higher as appropriate)

### Deferred Ideas (OUT OF SCOPE)
- "Explore this topic on Read & Rank" deep-link from StanceAccordion back to Read & Rank with topic pre-selected — noted as PROF-05 in requirements, future phase
- Verdict history view ("all quotes I evaluated for this politician") — PROF-06, future phase
- Phase 82 handles the logged-in sync (POST verdicts to backend; fetch from API as highest-priority source)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VERD-05 | Guest verdict fragment encoding in URL when navigating to Essentials | Fragment builder utility in EV-ReadRank; existing `#compass=BASE64` mechanism extended with `v` key |
| VERD-06 | Essentials reads and caches guest verdicts from URL fragment to localStorage | `parseCompassFragment` + new `saveGuestVerdicts`/`loadGuestVerdicts` helpers in `essentials/src/lib/compass.js` |
| PROF-01 | CompassContext extended with verdicts state field (priority: API > fragment > localStorage) | `loadAll()` in CompassContext.jsx already has the 3-path priority pattern to extend |
| PROF-02 | StanceAccordion displays agree/disagree verdict badges inline under each topic (per-quote in expanded row) | ev-ui StanceAccordion.jsx already has collapsed-row topic badges via `verdictsByTopic`; needs expanded-row quote display + `verdictsByQuote` prop |
| PROF-04 | "View on Essentials" CTA in Read & Rank results linking to politician profile with verdict fragment | ResultsPhase.tsx and CandidateAlignmentPage.tsx identified; no CTA currently exists |
</phase_requirements>

---

## Summary

Phase 81 wires Read & Rank quote verdicts (agree/disagree evaluations) into Essentials politician profiles as per-quote badges inside the StanceAccordion expanded row. The work spans three repositories: EV-ReadRank (build and emit the verdict fragment), ev-ui (update StanceAccordion to fetch and display quotes with verdict badges), and essentials (parse/cache fragment, expose verdicts through CompassContext, pass to CompassCard/StanceAccordion).

The cross-app bridge is a proven mechanism: `#compass=BASE64(JSON)` already carries compass answers and selected topics from CompassV2 to Essentials, with localStorage caching on the Essentials side. Phase 81 extends this fragment with a new `v` key carrying the full `{ [quote_id]: 'agreed'|'disagreed' }` map. The only new credential needed on the EV-ReadRank side is knowing the Essentials profile URL pattern, which is `https://essentials.empowered.vote/politician/{uuid}`.

The largest single-file change is in ev-ui `StanceAccordion.jsx`: the expanded row currently shows reasoning + sources fetched from a context endpoint; it must now also fetch quotes (via the existing `GET /essentials/quotes?politician_id=X` endpoint) and render each quote card with an optional verdict badge. This requires a parallel fetch alongside the context fetch and a new `verdictsByQuote` prop threaded through from CompassCard to StanceAccordion.

**Primary recommendation:** Sequence as three plans — (1) ev-ui update (adds quote fetch + `verdictsByQuote` prop, publishes v0.1.43), (2) EV-ReadRank CTA addition (builds fragment, adds "View on Essentials" buttons), (3) Essentials fragment parsing + context wiring. The ev-ui plan must complete first because Essentials depends on the new prop.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.x | UI rendering | Project-wide standard |
| Vite | 7.x | Build tooling | Project-wide standard |
| Tailwind CSS | 4.x | Utility styling (EV-ReadRank) | Project-wide standard |
| tsup | 8.x | ev-ui library bundler | Already in ev-ui devDependencies |
| zustand | 5.x | Read & Rank state | Already in EV-ReadRank |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| framer-motion | 12.x | Animations | EV-ReadRank only — do NOT add to ev-ui or essentials |
| react-spring/web | 9.x / 10.x | Animations | ev-ui and essentials — existing dependency |
| react-router-dom | 7.x | Routing | All React apps |

### Installation
No new packages are required. All dependencies are already present in their respective repos.

---

## Architecture Patterns

### Recommended Project Structure

This phase touches three repos. Changes per repo:

```
ev-ui/src/
└── StanceAccordion.jsx    # Add verdictsByQuote prop, quote fetch, quote cards in expanded row

EV-ReadRank/src/
├── components/
│   ├── ResultsPhase.tsx          # Add "View on Essentials" CTA per candidate card
│   └── CandidateAlignmentPage.tsx # Add "View on Essentials" CTA for featured candidate
└── utils/                        # New: buildVerdictFragment(issueProgress) helper

essentials/src/
├── lib/compass.js                # Add saveGuestVerdicts, loadGuestVerdicts, clearGuestVerdicts
├── contexts/CompassContext.jsx   # Add verdicts state + v-key parsing in loadAll()
└── components/CompassCard.jsx    # Pass verdictsByQuote from context to StanceAccordion
```

### Pattern 1: Fragment Extension (VERD-05 / VERD-06)

**What:** The existing `#compass=BASE64({a, s, i})` fragment grows a `v` key. No format changes to existing keys.

**When to use:** Whenever a user navigates from Read & Rank to Essentials as a guest.

**Existing parseCompassFragment (essentials/src/lib/compass.js):**
```javascript
// Source: /Users/chrisandrews/Documents/GitHub/essentials/src/lib/compass.js
export function parseCompassFragment() {
  try {
    const hash = window.location.hash;
    if (!hash.startsWith("#compass=")) return null;
    const base64str = hash.slice("#compass=".length);
    if (!base64str) return null;
    const decoded = JSON.parse(atob(base64str));
    // Current validation: requires a (answers) and s (selected topics)
    if (!decoded || typeof decoded.a !== "object" || decoded.a === null || !Array.isArray(decoded.s)) {
      return null;
    }
    history.replaceState(null, "", window.location.pathname + window.location.search);
    return { answers: decoded.a, selectedTopics: decoded.s, invertedSpokes: decoded.i || {} };
  } catch {
    return null;
  }
}
```

**Extended version must:** return `verdicts: decoded.v || {}` in the return object. The validation guard does NOT need to require `v` — verdicts are optional (guest may have opened Essentials without doing Read & Rank). The `a` and `s` guard remains: if there are only verdicts and no compass data, return `null` for the compass portion and handle verdicts separately.

**Wait** — the CONTEXT.md says verdicts fragment is standalone for cases where user navigates directly from Read & Rank with zero compass data. The fragment only works if it has the `#compass=` prefix. So: if a guest comes from Read & Rank but has never done CompassV2, the fragment has no `a`/`s` data but does have `v`. The current validation would return `null` and strip the fragment, losing the verdicts.

**Resolution:** The fragment parser needs to be more permissive. When the fragment has `v` but no valid `a`/`s`, it should still extract verdicts. Two options:
1. Make `a` and `s` optional — return `null` only if the entire decoded object is invalid
2. Parse verdicts before the `a`/`s` guard

The cleanest approach (aligned with CONTEXT.md's "Guest experience should be as full-featured as possible"): relax the guard to accept fragments that have `v` but not necessarily `a` and `s`.

**Fragment builder in EV-ReadRank:**
```typescript
// Source: pattern derived from existing compass bridge
// Place in EV-ReadRank/src/utils/verdictFragment.ts

export function buildVerdictFragment(
  issueProgress: Record<string, IssueProgress>
): string {
  // Collect all agree/disagree verdicts across ALL issues
  const v: Record<string, 'agreed' | 'disagreed'> = {};
  for (const progress of Object.values(issueProgress)) {
    for (const quote of progress.agreedQuotes) {
      v[quote.id] = 'agreed';
    }
    for (const quote of progress.rankedQuotes) {
      v[quote.id] = 'agreed'; // ranked = agreed
    }
    for (const quote of progress.disagreedQuotes) {
      v[quote.id] = 'disagreed';
    }
  }
  // Encode as compass fragment with only v key (no a/s/i — user may not have done CompassV2)
  const payload = btoa(JSON.stringify({ v }));
  return `#compass=${payload}`;
}

export function buildEssentialsProfileUrl(
  candidateId: string,
  issueProgress: Record<string, IssueProgress>,
  baseUrl: string = 'https://essentials.empowered.vote'
): string {
  const fragment = buildVerdictFragment(issueProgress);
  return `${baseUrl}/politician/${candidateId}${fragment}`;
}
```

**Important:** `rankedQuotes` in Zustand store = quotes the user agreed to AND ranked. They must be included in the `agreed` verdict map. The store's `agreedQuotes` accumulates as user swipes right; `rankedQuotes` is a ranked subset of those. The fragment should include BOTH (deduped), treating both as `agreed`.

### Pattern 2: localStorage Verdict Cache (VERD-06)

**What:** Parallel to `guestCompass` / `GUEST_COMPASS_KEY`. Three new helpers mirror the existing pattern exactly.

**Example (essentials/src/lib/compass.js additions):**
```javascript
// Source: mirrors existing saveGuestCompass / loadGuestCompass pattern
export const GUEST_VERDICTS_KEY = "guestVerdicts";

export function saveGuestVerdicts(verdicts) {
  localStorage.setItem(GUEST_VERDICTS_KEY, JSON.stringify(verdicts));
}

export function loadGuestVerdicts() {
  try {
    const raw = localStorage.getItem(GUEST_VERDICTS_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return null;
    return parsed; // { [quote_id]: 'agreed' | 'disagreed' }
  } catch {
    return null;
  }
}

export function clearGuestVerdicts() {
  localStorage.removeItem(GUEST_VERDICTS_KEY);
}
```

### Pattern 3: CompassContext verdicts State (PROF-01)

**What:** New `verdicts` state field added alongside existing fields. Populated in `loadAll()` following the same priority logic.

**Current `loadAll()` priority structure (existing):**
```
if (authRes.ok)         → fetch from API, clearGuestCompass()
else if (fragment)      → use fragment data, saveGuestCompass()
else                    → use loadGuestCompass()
```

**Extended structure:**
```
if (authRes.ok)         → fetch from API (no verdicts yet — Phase 82), clearGuestVerdicts()
else if (fragment && fragment.verdicts has entries)
                        → use fragment.verdicts, saveGuestVerdicts(fragment.verdicts)
else                    → use loadGuestVerdicts() || {}
```

Note: `verdicts` is independent of the compass `answers`/`selectedTopics` path. A user may have fragment verdicts but no fragment compass data (came from Read & Rank without doing CompassV2). The two subsystems run in parallel within the same `loadAll()`.

**Context value shape addition:**
```javascript
// Add to useMemo value object and dependency array
verdicts,  // Record<quote_id, 'agreed' | 'disagreed'>
```

### Pattern 4: StanceAccordion Quote Fetch (PROF-02)

**What:** On row expand, the accordion currently fetches one URL (context endpoint). It must now fire two fetches in parallel: the existing context fetch AND a quotes fetch.

**Quotes endpoint:** `GET /essentials/quotes?politician_id={UUID}` — already exists (VERD-04, Phase 79 complete). Returns `{ quotes: [...], candidates: [...], issues: [...] }`. The StanceAccordion receives `politicianId`, so it can call this endpoint directly.

**Fetch strategy:** Fetch all quotes for the politician ONCE (not per-topic) on first expand of any row. Cache in a ref alongside `contextCache`:
```javascript
// In StanceAccordion
const quotesCache = useRef(null); // null = not fetched, [] = fetched but empty

async function fetchQuotesForPolitician() {
  if (quotesCache.current !== null) return;
  try {
    const res = await fetch(`${apiUrl}/essentials/quotes?politician_id=${politicianId}`);
    if (res.ok) {
      const data = await res.json();
      quotesCache.current = data.quotes || [];
    } else {
      quotesCache.current = [];
    }
  } catch {
    quotesCache.current = [];
  }
}
```

On expand, call `fetchQuotesForPolitician()` in parallel with the existing context fetch. Once resolved, filter quotes by `quote.issue === topicKey` (where `topicKey` is the topic's identifier that links Read & Rank quotes to compass topics).

**Topic key mapping:** The `essentials.quotes` table has a `topic_key` column that matches the `issue` field in the Read & Rank `Quote` type. The `allTopics` prop contains full topic objects. The match is `topic.short_title` or another topic identifier. Looking at the GetQuotes handler: it returns `Issue: row.TopicKey`. In the existing data flow, `quote.issue` = `topic_key` in the database = should match some field on the compass topic object.

Checking the compass topics: the `allTopics` array (from `GET /compass/topics`) has topic objects with `id`, `short_title`, `question_text`, `stances`. The `topic_key` in `essentials.quotes` is a string slug (e.g., "healthcare"). The StanceAccordion receives `topics` array (subset of `allTopics`). Each `topic` has `topic.id` (UUID) which `polAnswerMap` uses, but the quote's `issue` field is a `topic_key` string.

**Key finding:** There is no direct `topic_key` field on the compass topic objects exposed to the StanceAccordion. The connection between a compass topic and Read & Rank quotes goes through `topic_key`. This needs resolution in the StanceAccordion's quote-filtering logic. Options:
1. Filter quotes by `quote.candidateId === politicianId && quote.issue === topic.short_title` (if topic_key = short_title)
2. Pass a `topicKeyMap: Record<topic_id, topic_key>` prop from CompassCard
3. Accept that StanceAccordion fetches all quotes for the politician and filters by checking if `topic.id` maps to any quotes — but this requires the topic object to expose `topic_key`

The cleanest solution: when CompassCard passes the `topics` array to StanceAccordion, each topic object already has `short_title`. If `topic_key` in the quotes table matches `short_title` (which it does — looking at the IssueData type in Read & Rank: `id: string` used as `issue` field), then the mapping is `quote.issue === topic.short_title` or uses a separate `key` field.

**Definitive check needed in planning:** Verify the exact `topic_key` values in the database against `topic.short_title` values. This may require a small investigation during implementation, but the pattern is clear: filter `quotesCache.current` by `q.issue === someTopicIdentifier` for each expanded row.

### Pattern 5: "View on Essentials" CTA (PROF-04)

**ResultsPhase.tsx:** Each `QuoteResultCard` already has an "action footer" with a "View Your Alignment" button that calls `onViewAlignment(candidate.id)` which navigates to `/candidate/${candidateId}/alignment` (internal React Router navigation). Add a second CTA button "View on Essentials" as an `<a>` tag linking to the profile URL with fragment.

**CandidateAlignmentPage.tsx:** The page header already has candidate info. Add a "View on Essentials" button/link in the header section or after the stats section.

**VITE_ESSENTIALS_URL pattern:** EV-ReadRank currently uses only `VITE_API_URL`. Adding `VITE_ESSENTIALS_URL` with fallback to `'https://essentials.empowered.vote'` follows the same pattern as `API_BASE` in `api.ts`.

```typescript
// EV-ReadRank — hardcoded fallback is safe since there's only one Essentials deployment
const ESSENTIALS_BASE = import.meta.env.VITE_ESSENTIALS_URL || 'https://essentials.empowered.vote';
```

### Anti-Patterns to Avoid

- **Fragment validation too strict:** Returning `null` from `parseCompassFragment` when `v` is present but `a`/`s` are absent loses verdicts silently. The parser must extract verdicts even from verdict-only fragments.
- **Including rankedQuotes.id in verdicts without deduplication:** `agreedQuotes` and `rankedQuotes` in Zustand share quote objects. Build the verdict map with a simple `v[quote.id] = 'agreed'` which naturally deduplicates.
- **Fetching quotes per-topic in StanceAccordion:** The `GET /essentials/quotes?politician_id=X` returns all quotes for the politician in one call. Fetch once and filter client-side — don't fire a separate request per topic expand.
- **Adding `verdictsByTopic` removal as a separate task:** The CONTEXT.md says to deprecate silently. Keep the prop signature but stop passing it from CompassCard (just pass `verdictsByQuote` instead). No breaking change needed.
- **ev-ui using Tailwind classes:** The existing StanceAccordion uses inline styles exclusively (project decision recorded in STATE.md). Quote cards in the expanded row must also use inline styles.
- **Blocking Essentials render on verdicts:** Verdicts are additive UI. The `compassLoading` guard in CompassContext already controls rendering. Verdicts should be available at the same time as `compassLoading` becomes false.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fragment encoding/decoding | Custom serializer | `btoa(JSON.stringify(...))`  / `JSON.parse(atob(...))` | Already proven in production by compass bridge |
| localStorage persistence | IndexedDB / cookies | `localStorage.setItem/getItem` | Established pattern with `guestCompass` key |
| Quote-to-topic mapping | New endpoint or new DB field | Filter `quotes` by `q.issue === topic.short_title` (or topic key) client-side | `GET /essentials/quotes?politician_id=X` already exists and returns `issue` field |
| Verdict badge styling | New design tokens or CSS vars | Inline styles: `#ecfeff / #0e7490` (cyan) and `#fffbeb / #b45309` (amber) | These exact values already used in StanceAccordion.jsx for `verdictsByTopic` badges |

---

## Common Pitfalls

### Pitfall 1: Fragment Stripping Before Verdicts Are Read
**What goes wrong:** `parseCompassFragment` calls `history.replaceState` immediately on success. If parsing succeeds but verdicts aren't extracted from `decoded.v`, they are lost forever (fragment is gone from URL).
**Why it happens:** The function was written to handle only `a`/`s`/`i` keys. Adding `v` requires updating the return object before the `history.replaceState` call.
**How to avoid:** Update `parseCompassFragment` to return `verdicts: decoded.v || {}` in the return object. The `history.replaceState` call location doesn't change — it correctly strips after extraction.
**Warning signs:** Badges never appear on first visit to profile after Read & Rank CTA click.

### Pitfall 2: Verdict-Only Fragment Fails Validation
**What goes wrong:** A user comes from Read & Rank but has never set up their compass. Fragment has `{ v: {...} }` but no `a` or `s`. The current guard `typeof decoded.a !== "object" || !Array.isArray(decoded.s)` returns `null`, stripping the fragment without saving verdicts.
**Why it happens:** The guard was designed for compass-only fragments.
**How to avoid:** Restructure `parseCompassFragment` to attempt verdict extraction even when compass data is absent. Return `{ answers: null, selectedTopics: null, invertedSpokes: {}, verdicts: decoded.v || {} }` with the caller checking `fragment.answers !== null` before using compass data.
**Warning signs:** Badges don't appear for users who haven't done the compass quiz.

### Pitfall 3: rankedQuotes Duplicating agreedQuotes in Verdict Map
**What goes wrong:** `issueProgress[id].agreedQuotes` accumulates all agreed quotes as user swipes right. `rankedQuotes` is a ranked re-ordering of a subset. Both arrays may contain the same quote IDs. If the builder loops both arrays and sets `v[id] = 'agreed'` for both, the result is just a duplicate key assignment — harmless since the value is the same.
**Why it happens:** The store maintains both arrays for ranking UI purposes.
**How to avoid:** This is actually safe — duplicate key assignment with identical values is idempotent. Just loop both arrays with `v[quote.id] = 'agreed'`. No deduplication code needed.
**Warning signs:** None — this is actually fine.

### Pitfall 4: Topic Key Mismatch Between Quotes and Accordion Topics
**What goes wrong:** StanceAccordion filters `quotesCache.current` by topic but uses the wrong field name for matching, resulting in no quotes showing for any topic.
**Why it happens:** `topic.id` is a UUID; `quote.issue` is a string slug (`topic_key`). These don't directly match. The accordion must use `topic.short_title` or another field to match.
**How to avoid:** Verify one data sample during implementation. If `topic_key` = `topic.short_title` (likely true given the existing compass topic/issue relationship), filter by `q.issue === topic.short_title`. If not, add a `topicKey` field to the compass topic API response or pass a mapping from CompassCard.
**Warning signs:** Quote section in expanded row shows "No quotes" for all topics despite quotes existing in DB.

### Pitfall 5: ev-ui Build Not Published Before Essentials Consumes New Prop
**What goes wrong:** Essentials passes `verdictsByQuote` to StanceAccordion, but the installed v0.1.42 doesn't support it — the prop is silently ignored, no badges appear.
**Why it happens:** ev-ui is a published package; Essentials uses `^0.1.42` which won't auto-update past 0.1.42 until a new version is published and `npm install` is re-run.
**How to avoid:** Plan 1 (ev-ui update) must be fully complete — built AND published to GitHub npm registry — before Plans 2/3 begin. During local dev, vite.config.ts in EV-ReadRank already has the local ev-ui alias; essentials/vite.config.ts should be checked for the same alias.
**Warning signs:** TypeScript in essentials doesn't know about `verdictsByQuote` prop; verdict badges absent in production.

### Pitfall 6: Essentials vite.config.ts Missing Local ev-ui Alias
**What goes wrong:** EV-ReadRank's `vite.config.ts` has `fs.existsSync(localEvUi)` alias for local development. Essentials may lack this, requiring an actual npm publish for every ev-ui iteration during dev.
**How to avoid:** Check `essentials/vite.config.ts`. If the alias isn't there, add it during Wave 0 of the ev-ui plan.
**Warning signs:** Local dev changes to ev-ui don't reflect in essentials without npm publish.

---

## Code Examples

### Fragment Builder (EV-ReadRank)
```typescript
// Source: derived from existing compass bridge pattern in essentials/src/lib/compass.js
// Place in EV-ReadRank/src/utils/verdictFragment.ts

import type { IssueProgress } from '../store/useReadRankStore';

export function buildVerdictFragment(
  issueProgress: Record<string, IssueProgress>
): string {
  const v: Record<string, 'agreed' | 'disagreed'> = {};
  for (const progress of Object.values(issueProgress)) {
    // rankedQuotes is a subset of agreedQuotes — both map to 'agreed'
    for (const quote of [...progress.agreedQuotes, ...progress.rankedQuotes]) {
      v[quote.id] = 'agreed';
    }
    for (const quote of progress.disagreedQuotes) {
      v[quote.id] = 'disagreed';
    }
  }
  return `#compass=${btoa(JSON.stringify({ v }))}`;
}

export function buildEssentialsProfileUrl(
  candidateId: string,
  issueProgress: Record<string, IssueProgress>,
  base = import.meta.env.VITE_ESSENTIALS_URL || 'https://essentials.empowered.vote'
): string {
  return `${base}/politician/${candidateId}${buildVerdictFragment(issueProgress)}`;
}
```

### Updated parseCompassFragment (essentials)
```javascript
// Source: extended from /Users/chrisandrews/Documents/GitHub/essentials/src/lib/compass.js
export function parseCompassFragment() {
  try {
    const hash = window.location.hash;
    if (!hash.startsWith("#compass=")) return null;
    const base64str = hash.slice("#compass=".length);
    if (!base64str) return null;
    const decoded = JSON.parse(atob(base64str));
    if (!decoded || typeof decoded !== 'object') return null;

    // Extract verdicts regardless of whether compass data is present
    const verdicts = (decoded.v && typeof decoded.v === 'object') ? decoded.v : {};

    // Compass data is optional — only validate if present
    const hasCompassData =
      typeof decoded.a === "object" && decoded.a !== null &&
      Array.isArray(decoded.s);

    // Strip fragment from URL for clean navigation
    history.replaceState(null, "", window.location.pathname + window.location.search);

    if (!hasCompassData && Object.keys(verdicts).length === 0) return null;

    return {
      answers: hasCompassData ? decoded.a : null,
      selectedTopics: hasCompassData ? decoded.s : [],
      invertedSpokes: decoded.i || {},
      verdicts,
    };
  } catch {
    return null;
  }
}
```

### CompassContext loadAll() verdict integration
```javascript
// Source: extended from /Users/chrisandrews/Documents/GitHub/essentials/src/contexts/CompassContext.jsx
// Inside loadAll(), after existing compass priority logic:

let verdicts = {};
if (authRes.ok) {
  // Logged-in: clear guest verdicts (Phase 82 will fetch from API)
  clearGuestVerdicts();
} else if (fragment && Object.keys(fragment.verdicts || {}).length > 0) {
  // Guest with fresh verdict fragment
  verdicts = fragment.verdicts;
  saveGuestVerdicts(verdicts);
} else {
  // Guest without fragment: try localStorage cache
  verdicts = loadGuestVerdicts() || {};
}

if (!cancelled) {
  setVerdicts(verdicts);
}
```

### "View on Essentials" CTA in ResultsPhase (EV-ReadRank)
```tsx
// Source: addition to /Users/chrisandrews/Documents/GitHub/EV-ReadRank/src/components/ResultsPhase.tsx
// In QuoteResultCard component, the action footer already has one button.
// Add alongside existing "View Your Alignment" button:

import { buildEssentialsProfileUrl } from '../utils/verdictFragment';

// In QuoteResultCard, receive issueProgress as prop:
<a
  href={buildEssentialsProfileUrl(candidate.id, issueProgress)}
  target="_blank"
  rel="noopener noreferrer"
  className="w-full py-2 px-4 border border-ev-muted-blue text-ev-muted-blue font-manrope font-semibold rounded-xl transition-colors duration-200 flex items-center justify-center gap-2 text-sm hover:bg-ev-muted-blue hover:text-white"
>
  <span>View on Essentials</span>
  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
  </svg>
</a>
```

### StanceAccordion Quote Fetch (ev-ui)
```javascript
// Source: extension to /Users/chrisandrews/Documents/GitHub/ev-ui/src/StanceAccordion.jsx
// New ref alongside contextCache:
const quotesCache = useRef(null); // null=unfetched, array=fetched

async function ensureQuotesFetched() {
  if (quotesCache.current !== null) return;
  try {
    const res = await fetch(
      `${apiUrl}/essentials/quotes?politician_id=${politicianId}`,
      { credentials: 'include' }
    );
    quotesCache.current = res.ok ? (await res.json()).quotes || [] : [];
  } catch {
    quotesCache.current = [];
  }
}

// In handleToggle, call in parallel:
await Promise.all([
  fetchContext(topicId),    // existing context fetch
  ensureQuotesFetched(),    // new quotes fetch
]);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `verdictsByTopic` prop on StanceAccordion | `verdictsByQuote` prop (per-quote granularity) | Phase 81 | Badges move from collapsed row header to expanded row quote cards |
| Compass fragment has `{a, s, i}` keys | Fragment has `{a, s, i, v}` keys | Phase 81 | Verdicts travel across app boundary via URL |
| StanceAccordion expanded row: reasoning + sources only | Expanded row: reasoning + sources + quote cards | Phase 81 | Profile page becomes the canonical destination after Read & Rank |

**Deprecated/outdated:**
- `verdictsByTopic` prop: Will be silently deprecated in StanceAccordion — prop remains in signature for backward compatibility but CompassCard stops passing it.

---

## Open Questions

1. **topic_key vs short_title mapping**
   - What we know: `essentials.quotes.topic_key` is a string slug; `quote.issue` = `topic_key` in Read & Rank; compass topic objects have `short_title` field
   - What's unclear: Whether `topic_key` values exactly match `short_title` values (e.g., "healthcare" vs "Healthcare")
   - Recommendation: During Wave 0 of ev-ui plan, query the DB or fetch from `/essentials/quotes` and `/compass/topics` to confirm the mapping. If they match (case-insensitive), filter by `q.issue.toLowerCase() === topic.short_title.toLowerCase()`. If they don't match, the compass topic object likely has a `key` field not currently exposed in the API response — add it.

2. **essentials vite.config.ts local alias**
   - What we know: EV-ReadRank has `fs.existsSync` alias for local ev-ui dev
   - What's unclear: Whether essentials has the same alias
   - Recommendation: Check during Wave 0 of the ev-ui plan. If missing, add it. This is low risk but blocks fast local iteration.

3. **Fragment with verdicts but no compass data — caller behavior in CompassContext**
   - What we know: The updated `parseCompassFragment` may return `{ answers: null, selectedTopics: [], verdicts: {...} }`
   - What's unclear: Whether the existing `else if (fragment)` branch in `loadAll()` safely handles `fragment.answers === null`
   - Recommendation: The `convertGuestAnswersToApiFormat` call must be guarded: `if (fragment.answers !== null) { answers = convertGuestAnswersToApiFormat(...) }`. This is a safe addition.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no test config files in any of the three repos |
| Config file | None — Wave 0 gap |
| Quick run command | Manual browser verification |
| Full suite command | Manual end-to-end flow test |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VERD-05 | `buildVerdictFragment()` encodes all agreed/disagreed quote IDs into `#compass=BASE64({v})` | unit | None — manual | ❌ Wave 0 |
| VERD-06 | Essentials reads `v` key from fragment and saves to `guestVerdicts` localStorage | manual-only | Open Essentials with crafted fragment URL, check localStorage | N/A |
| PROF-01 | `useCompass().verdicts` returns `{ [quoteId]: 'agreed'|'disagreed' }` after fragment parse | manual-only | Open Essentials profile with verdict fragment, inspect React DevTools | N/A |
| PROF-02 | Expanded StanceAccordion row shows quote cards with Agreed (cyan) / Disagreed (amber) badges | manual-only | Expand a topic row on a profile with verdicts loaded | N/A |
| PROF-04 | "View on Essentials" CTA in ResultsPhase and CandidateAlignmentPage opens correct profile with fragment | manual-only | Click CTA, verify URL contains fragment, verify profile shows badges | N/A |

### Sampling Rate
- **Per task commit:** Run local dev server and manually verify the changed behavior
- **Per wave merge:** Full end-to-end flow: do a Read & Rank session, click "View on Essentials", verify badges on profile
- **Phase gate:** Full end-to-end flow passes before `/gsd:verify-work`

### Wave 0 Gaps
- No automated test infrastructure exists across ev-ui, EV-ReadRank, or essentials
- Manual verification protocol serves as the test gate for this phase

*(No automated test framework to install — manual verification is the established pattern for this project)*

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/compass.js` — complete compass bridge implementation, localStorage pattern, fragment format
- `/Users/chrisandrews/Documents/GitHub/essentials/src/contexts/CompassContext.jsx` — complete `loadAll()` priority logic
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/StanceAccordion.jsx` — v0.1.42 implementation, inline styles, `verdictsByTopic` prop, context fetch, accordion expand pattern
- `/Users/chrisandrews/Documents/GitHub/EV-ReadRank/src/store/useReadRankStore.ts` — `IssueProgress` interface, `agreedQuotes`/`disagreedQuotes`/`rankedQuotes` structure
- `/Users/chrisandrews/Documents/GitHub/EV-ReadRank/src/components/ResultsPhase.tsx` — QuoteResultCard component, `onViewAlignment` handler
- `/Users/chrisandrews/Documents/GitHub/EV-ReadRank/src/components/CandidateAlignmentPage.tsx` — full page structure, header location for CTA
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` lines 3078–3240 — `GetQuotes` handler, `politician_id` query param support confirmed
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/81-profile-integration/81-CONTEXT.md` — all locked decisions
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — inline styles decision for ev-ui (Phase 80 entry)

### Secondary (MEDIUM confidence)
- `essentials/package.json` — ev-ui at `^0.1.42`, confirms upgrade to v0.1.43+ is needed
- `EV-ReadRank/package.json` — ev-ui at `^0.1.41`, confirms EV-ReadRank does not consume StanceAccordion and doesn't need ev-ui bump
- `EV-ReadRank/vite.config.ts` — local ev-ui alias pattern available for essentials to adopt

### Tertiary (LOW confidence)
- topic_key ↔ short_title mapping — inferred from data flow; needs verification during Wave 0

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified from package.json files
- Architecture: HIGH — all integration points confirmed in source code
- Pitfalls: HIGH — derived from reading actual code paths, not assumptions
- topic_key mapping: LOW — inferred; needs one data verification step

**Research date:** 2026-03-12
**Valid until:** 2026-04-12 (stable domain — no external dependencies changing)
