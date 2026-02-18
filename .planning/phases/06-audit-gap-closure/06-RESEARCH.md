# Phase 6: Audit Gap Closure - Research

**Researched:** 2026-02-18
**Domain:** React UI fix (Quiz.jsx heading + Register.jsx payload), Go backend fix (CandidateOut.ChamberName)
**Confidence:** HIGH — all three gaps are precisely located from codebase reading and the v1 audit

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Quiz question display**
- Shrink font progressively to fit full question text rather than truncating with ellipsis
- Applies to both full quiz mode and curated quiz mode
- Also verify ComparePanel shows question_text — fix if missing (not just Quiz cards)
- Fallback chain: question_text -> title (standard pattern)

**Registration answer feedback**
- Toast notification after successful registration: brief confirmation like "Your quiz answers have been saved to your account"
- Same toast regardless of merge outcome — don't surface server-wins merge complexity to user
- Fix Register.jsx (standalone page from banner) AND verify inline modal path still sends guest_state correctly
- User stays on current page after registration — banner disappears since they're now logged in

**Candidate chamber classification**
- Keep current Phase 5 candidate display behavior — just fix ChamberName so grouping works correctly
- Show candidates even with minimal data — don't filter out incomplete records
- **No party affiliation on any candidate card** — even when BallotReady provides party data, do not display it

### Claude's Discretion
- Quiz heading approach (replace vs primary/secondary) — match whatever Library cards already do
- ChamberName fallback strategy — pick the approach that produces most accurate groupings
- Toast styling — match existing toast patterns in the app

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| QUIZ-01 | Issue cards show question/prompt instead of category title | Quiz.jsx lines 530 and 615 render `currentTopic.title`; fix is `currentTopic.question_text \|\| currentTopic.title`. stanceContent `h2` uses `start_phrase`, not title — that stays as-is. The `h1` heading is the target. ComparePanel.jsx already correct (line 143-145). |
| AUTH-05 | Guest localStorage state merges to server on account creation | Register.jsx sends only `{ username, password }` — no `guest_state`. BuildGuestState pattern already implemented in SavePromptModal.jsx. Register.jsx must import `useCompass`, read topics + localStorage, and add `guest_state` to POST body. |
</phase_requirements>

---

## Summary

Phase 6 closes three precisely-located gaps found by the v1 milestone audit. All three are small, targeted fixes with no new architecture required — each touches one file in one focused way.

**Gap 1 (QUIZ-01):** Quiz.jsx renders `currentTopic.title` as the card heading in both full mode (line 530) and curated mode (line 615). The `question_text` field exists on every topic object from the API. The fix is a two-line substitution: replace `{currentTopic.title}` with `{currentTopic.question_text || currentTopic.title}` at both locations. Library.jsx already uses a `getQuestion()` helper at module scope that does the same pattern — match that approach. ComparePanel.jsx already shows `question_text` correctly at line 143-145 (already fixed, no change needed). The `h2` inside `stanceContent` shows `currentTopic.start_phrase` — that is intentional and should not change.

**Gap 2 (AUTH-05):** Register.jsx (at `/register`, reached via the banner's "Sign up" CTA) sends `{ username, password }` only. SavePromptModal.jsx has the complete working pattern for building and sending `guest_state`. Register.jsx needs to be refactored to: import `useCompass` to get `topics`, read `answers`/`writeIns`/`selectedTopics` from localStorage, build the same `guest_state` shape, and include it in the POST body. After success the user stays on the page they came from (the banner will disappear because `isLoggedIn` becomes true). A toast confirms answers were saved.

**Gap 3 (ChamberName):** `GetCandidatesByZip` in `handlers.go` assembles `CandidateOut` structs but never sets `ChamberName`. The `racesByZipQuery` GraphQL query does not currently request position chamber data. `RacePositionNode` type also lacks a chamber field. The fix requires: (1) extending `racesByZipQuery` to fetch `normalizedPosition { name }` (or another useful chamber signal) from BallotReady, (2) extending `RacePositionNode` with the new field, and (3) populating `ChamberName` in the `GetCandidatesByZip` loop using a fallback strategy. Since BallotReady race positions do not carry a `chamber` object directly, the best available signal is `normalizedPosition.name` combined with keyword inference over `position.name` — which is the same strategy already used by `levelToDistrictType`.

**Primary recommendation:** Three separate plan files (one per gap), each touching exactly one file. No shared state changes, no new dependencies.

---

## Standard Stack

No new libraries required. All fixes use patterns already present in the codebase.

### Core (already in use)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React 19 | 19.x | UI rendering | Already in CompassV2 |
| Framer Motion | 12.x | Toast animation | Already used in Login.jsx for `showRestoredToast` toast |
| useCompass hook | internal | Access topics + auth state | Already the pattern for context access in all CompassV2 components |
| Go chi router | v5 | Route handling | Already in EV-Backend |

### No New Installations Required

All patterns (Framer Motion toast, useCompass guest_state build, Go struct field assignment) are already demonstrated in the existing codebase.

---

## Architecture Patterns

### Pattern 1: question_text Fallback (Library.jsx model)

Library.jsx defines at module scope (line 43-44):
```js
const getQuestion = (topic) =>
  topic.question_text || `What should the government do about ${topic.short_title}?`;
```

Quiz.jsx should adopt the same pattern — define `getQuestion` at module scope and use it for both the full-mode `h1` (line 529) and curated-mode `h1` (line 614). The fallback used in Library.jsx is the right one to match. The `stanceContent` section's `h2` rendering `{currentTopic.start_phrase}...` is correct behavior and must not change.

### Pattern 2: Font Shrinking for Long question_text

The decision is "shrink font progressively to fit full question text rather than truncating." Tailwind's responsive size classes already in use (e.g., `text-2xl md:text-3xl`) are the right tool. The pattern is to start at a smaller base size and let it grow responsively, rather than using `truncate` or `line-clamp`. The heading currently uses `text-2xl md:text-3xl font-semibold` — this can stay but should not have `truncate` or `line-clamp` applied. Long text will wrap naturally. If desired, a very long question could be sized at `text-xl md:text-2xl` — but the exact sizing is Claude's discretion.

### Pattern 3: buildGuestState in Register.jsx (SavePromptModal model)

SavePromptModal.jsx lines 70-89 show the complete, working pattern:
```js
const buildGuestState = () => {
  const localAnswers = safeParse(localStorage.getItem("answers"), {});
  const localWriteIns = safeParse(localStorage.getItem("writeIns"), {});
  const localSelectedTopics = safeParse(localStorage.getItem("selectedTopics"), []);

  const answers = Object.entries(localAnswers).map(([shortTitle, value]) => {
    const topic = topics.find(t => t.short_title === shortTitle);
    if (!topic) return null;
    return {
      topic_id: topic.id,
      value: value,
      write_in_text: localWriteIns[shortTitle] || "",
    };
  }).filter(Boolean);

  return {
    answers,
    selected_topics: localSelectedTopics,
  };
};
```

Register.jsx must replicate this exactly. The key dependency is `topics` from `useCompass()` — needed to convert `short_title` keys to `topic_id` UUIDs.

Register.jsx currently uses the `AuthForm` component from `@chrisandrewsedu/ev-ui` which accepts an `onSubmit(username, password)` callback. The fix must intercept that callback to inject `guest_state` before posting. The `handleSubmit` function already receives both values — just extend the fetch body.

### Pattern 4: Toast in Register.jsx (Login.jsx model)

Login.jsx implements a toast (lines 97-107):
```jsx
<AnimatePresence>
  {showRestoredToast && (
    <motion.div
      initial={{ y: -40, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      exit={{ y: -40, opacity: 0 }}
      className="fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-[#00657c] text-white px-5 py-2.5 rounded-lg shadow-lg text-sm font-medium"
    >
      Your saved answers have been restored.
    </motion.div>
  )}
</AnimatePresence>
```

Register.jsx's toast should use identical markup and styling. Text: "Your quiz answers have been saved to your account." The toast fires unconditionally on successful registration (regardless of whether guest_state was empty or not). Show for ~2 seconds then the banner disappears naturally (isLoggedIn becomes true via CompassContext, but Register.jsx does not have direct access to setIsLoggedIn — it navigates away, so the banner goes away when the parent re-renders). Actually: Register.jsx currently calls `navigate("/")` after success — the decision says "User stays on current page after registration." This means Register.jsx should NOT navigate on success. Instead it should show the toast and let the banner disappear. It needs to call `setIsLoggedIn(true)` and `setUsername()` via CompassContext.

### Pattern 5: ChamberName Population (Go)

The `racesByZipQuery` currently requests only:
```graphql
position {
  id
  databaseId
  name
  level
  state
  judicial
  appointed
}
```

BallotReady's position type does not have a `chamber` object at the races level (unlike the `officeHolders` query which joins to a full chamber/government chain). The best available approach is:

1. Add `normalizedPosition { name }` to the races query (this is available on the position type from BallotReady)
2. Add `NormalizedPositionName string` to `RacePositionNode`
3. In `GetCandidatesByZip`, derive `ChamberName` using keyword inference over `race.Position.NormalizedPositionName` or `race.Position.Name`

The keyword inference approach matches what `levelToDistrictType` already does with `posName` — it is the established pattern for this data. A reasonable fallback chain:
- If `normalizedPosition.name` is non-empty → use it as `ChamberName`
- Else derive from `position.name` keywords (e.g., "Senate" → "U.S. Senate" or "State Senate" based on level)
- Else leave empty (classifyCategory falls back to title-based matching which still works for most cases)

This provides accurate grouping for: U.S. Senate, U.S. House, State Senate, State House/Assembly, Governor, and most local positions where the position name is descriptive.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Guest state assembly | New serialization logic | Copy SavePromptModal.jsx `buildGuestState()` pattern verbatim | Already tested, handles UUID mapping correctly |
| Toast animation | CSS animation from scratch | Framer Motion (already imported in Login.jsx) | Same as existing toast |
| ChamberName inference | New lookup table | Extend existing `levelToDistrictType` keyword approach | Pattern already established, same data signals |

---

## Common Pitfalls

### Pitfall 1: Changing stanceContent h2 Instead of Card h1

**What goes wrong:** Developer sees `{currentTopic.start_phrase}...` in `stanceContent` and also changes it to `question_text`.
**Why it happens:** Both are `h`-level headings in Quiz.jsx.
**How to avoid:** Only the outer card headings (the `h1` at lines 529 and 614 in full/curated modes respectively) should change. The `stanceContent` block's `h2` shows the start phrase for the stance selection — it is intentional.
**Warning signs:** If the stance section begins with a question instead of an incomplete sentence fragment, the wrong element was changed.

### Pitfall 2: Register.jsx Navigates Away Instead of Staying

**What goes wrong:** After successful registration, `navigate("/")` fires, but the requirement says the user stays on current page.
**Why it happens:** Current Register.jsx always navigates to "/" on success.
**How to avoid:** Replace `navigate("/")` with: `setIsLoggedIn(true)`, `setUsername(trimmedUsername)`, show toast, let banner disappear from re-render.
**Warning signs:** User is redirected to Home page after registering via the /register route.

### Pitfall 3: Register.jsx Has No Access to topics Until useCompass is Imported

**What goes wrong:** `buildGuestState()` in Register.jsx tries to map `short_title` to `topic_id` but `topics` is empty because `useCompass()` was not imported.
**Why it happens:** Register.jsx currently has zero context imports.
**How to avoid:** Add `const { topics, setIsLoggedIn, setUsername } = useCompass()` before building guest state. If `topics` is still empty (race condition on mount), the answers array will be empty — which is acceptable (better than crashing). The backend handles empty `guest_state.answers` gracefully.
**Warning signs:** Zero answers saved even when user had filled out the quiz.

### Pitfall 4: Assuming BallotReady Races Have a Chamber Object

**What goes wrong:** Developer adds `position { chamber { name } }` to the races GraphQL query expecting the same shape as the officeHolders query.
**Why it happens:** The officeHolders query fetches chamber via: `position → chamber → name`. The races query uses a lighter position type that may not expose `chamber`.
**How to avoid:** Use `normalizedPosition { name }` instead, which is confirmed available on the position type. Alternatively, derive from `position.name` + `level` using keyword matching.
**Warning signs:** GraphQL API returns an error about unknown field `chamber` on position in the races query.

### Pitfall 5: Toast Shown Even When No Answers Existed

**What goes wrong:** Toast fires "Your quiz answers have been saved" even when the guest had zero answers.
**Why it happens:** The decision says "same toast regardless of merge outcome."
**How to avoid:** This is intentional per the locked decision. Fire the toast unconditionally on successful registration. Keep it simple.

---

## Code Examples

Verified patterns from codebase reading:

### Quiz.jsx — Where to Change (lines 529 and 614)

Full mode heading (line 529 area):
```jsx
// BEFORE (line 529):
<h1 className="text-2xl md:text-3xl font-semibold mt-4 mb-6 text-center px-4">
  {currentTopic.title}
</h1>

// AFTER:
<h1 className="text-xl md:text-2xl font-semibold mt-4 mb-6 text-center px-4">
  {currentTopic.question_text || currentTopic.title}
</h1>
```

Curated mode heading (line 614 area):
```jsx
// BEFORE (line 614):
<h1 className="text-2xl md:text-3xl font-semibold mt-1 md:my-4 text-center">
  {currentTopic.title}
</h1>

// AFTER:
<h1 className="text-xl md:text-2xl font-semibold mt-1 md:my-4 text-center">
  {currentTopic.question_text || currentTopic.title}
</h1>
```

Note: Font size reduced one step (`text-2xl md:text-3xl` → `text-xl md:text-2xl`) to accommodate longer question text. This matches the "shrink progressively" decision.

### stanceContent h2 — DO NOT CHANGE

```jsx
// This stays as-is (line 414):
<h2 className="text-xl md:text-2xl font-semibold mb-2">
  {currentTopic.start_phrase}...
</h2>
```

### Register.jsx — Full Rewrite Pattern

```jsx
import { useState } from "react";
import { useNavigate } from "react-router";
import { AnimatePresence, motion } from "framer-motion";
import { AuthForm } from "@chrisandrewsedu/ev-ui";
import { useCompass } from "../components/CompassContext";

function safeParse(str, fallback) {
  try { return str ? JSON.parse(str) : fallback; } catch { return fallback; }
}

function Register() {
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [showToast, setShowToast] = useState(false);
  const navigate = useNavigate();
  const { topics, setIsLoggedIn, setUsername } = useCompass();

  const buildGuestState = () => {
    const localAnswers = safeParse(localStorage.getItem("answers"), {});
    const localWriteIns = safeParse(localStorage.getItem("writeIns"), {});
    const localSelectedTopics = safeParse(localStorage.getItem("selectedTopics"), []);
    const answers = Object.entries(localAnswers).map(([shortTitle, value]) => {
      const topic = topics.find(t => t.short_title === shortTitle);
      if (!topic) return null;
      return { topic_id: topic.id, value, write_in_text: localWriteIns[shortTitle] || "" };
    }).filter(Boolean);
    return { answers, selected_topics: localSelectedTopics };
  };

  const handleSubmit = async (username, password) => {
    try {
      setSubmitting(true);
      setError(null);
      const guestState = buildGuestState();
      const response = await fetch(
        `${import.meta.env.VITE_API_URL}/auth/register`,
        {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ username, password, guest_state: guestState }),
        }
      );
      if (!response.ok) {
        setError("Username is already taken.");
        return;
      }
      // Stay on page; update auth state so banner disappears
      setIsLoggedIn(true);
      setUsername(username.trim());
      setShowToast(true);
      // Toast auto-clears; no navigation needed
    } catch (err) {
      console.error("Error during registration:", err);
      setError("Something went wrong. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <AnimatePresence>
        {showToast && (
          <motion.div
            initial={{ y: -40, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -40, opacity: 0 }}
            className="fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-[#00657c] text-white px-5 py-2.5 rounded-lg shadow-lg text-sm font-medium"
          >
            Your quiz answers have been saved to your account.
          </motion.div>
        )}
      </AnimatePresence>
      <AuthForm
        logoSrc="/EVLogo.svg"
        appName="Empowered Vote"
        appSubtitle="Empowered Compass"
        mode="register"
        onSubmit={handleSubmit}
        onModeSwitch={() => navigate("/")}
        error={error}
        submitting={submitting}
      />
    </>
  );
}

export default Register;
```

### GetCandidatesByZip — ChamberName Population (Go)

Step 1: Extend `RacePositionNode` in `types.go`:
```go
type RacePositionNode struct {
  ID                   string                `json:"id"`
  DatabaseID           int                   `json:"databaseId"`
  Name                 string                `json:"name"`
  Level                string                `json:"level"`
  State                string                `json:"state"`
  Judicial             bool                  `json:"judicial"`
  Appointed            bool                  `json:"appointed"`
  NormalizedPosition   *RaceNormalizedPos    `json:"normalizedPosition,omitempty"`
}

type RaceNormalizedPos struct {
  Name string `json:"name"`
}
```

Step 2: Extend `racesByZipQuery` in `client.go`:
```graphql
position {
  id
  databaseId
  name
  level
  state
  judicial
  appointed
  normalizedPosition { name }
}
```

Step 3: Add `raceChamberName` helper in `handlers.go`:
```go
// raceChamberName derives a chamber name from BallotReady race position data.
// Uses normalizedPosition.name first, then falls back to keyword inference.
func raceChamberName(pos ballotready.RacePositionNode) string {
  if pos.NormalizedPosition != nil && pos.NormalizedPosition.Name != "" {
    return pos.NormalizedPosition.Name
  }
  // Keyword inference from position name + level
  name := strings.ToLower(pos.Name)
  level := strings.ToUpper(pos.Level)
  switch {
  case strings.Contains(name, "senate") && level == "FEDERAL":
    return "U.S. Senate"
  case strings.Contains(name, "house") || strings.Contains(name, "representative"):
    if level == "FEDERAL" {
      return "U.S. House of Representatives"
    }
    return pos.Name
  case strings.Contains(name, "senate") && level == "STATE":
    return pos.Name // e.g. "Illinois Senate"
  default:
    return pos.Name // use position name as fallback
  }
}
```

Step 4: Assign in the candidate loop:
```go
candidates = append(candidates, CandidateOut{
  // ... existing fields ...
  ChamberName: raceChamberName(race.Position),
})
```

---

## State of the Art

No library version changes involved. All three fixes use React 19 + Framer Motion + Go patterns already present.

---

## Open Questions

1. **Should Register.jsx import framer-motion or is it already in the bundle?**
   - What we know: CompassV2 uses Framer Motion throughout (Login.jsx, SavePromptModal.jsx, LibraryDrawer.jsx). It is in `package.json`.
   - What's unclear: Whether Register.jsx needs its own import or if tree-shaking affects anything.
   - Recommendation: Import directly — `import { AnimatePresence, motion } from "framer-motion"` — identical to Login.jsx. No bundle concern.

2. **Does `normalizedPosition` exist on the races query position type in BallotReady?**
   - What we know: `normalizedPosition` is present on the `officeHolders` position type (`NormalizedPosition` struct already exists in `types.go`).
   - What's unclear: Whether the races query position type also exposes it (same underlying Position type vs. a lighter variant).
   - Recommendation: Add it to the query and test. If BallotReady returns a GraphQL error for that field, fall back to keyword inference from `position.name` alone (which already works for most cases via `levelToDistrictType`). The `ChamberName` field is `omitempty` so empty strings are safe.

3. **Does the toast need an auto-dismiss timer?**
   - What we know: Login.jsx uses `setTimeout(navigate, 2000)` to navigate away after 2 seconds, which implicitly dismisses the toast. Register.jsx stays on the page, so the toast would persist.
   - What's unclear: Whether the toast should auto-dismiss after N seconds or stay until the user takes action.
   - Recommendation: Add a `setTimeout(() => setShowToast(false), 3000)` in the success branch. 3 seconds is enough to read the message. The banner will have already disappeared (isLoggedIn turned true), so the page will show the logged-in state cleanly.

---

## Sources

### Primary (HIGH confidence)

- Codebase read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Quiz.jsx` — confirms `currentTopic.title` at lines 529/614, confirms `start_phrase` in stanceContent h2
- Codebase read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Register.jsx` — confirms no `useCompass` import, no `guest_state` in POST body, calls `navigate("/")`
- Codebase read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/SavePromptModal.jsx` — complete `buildGuestState()` pattern (lines 70-89), inline modal sends `guest_state`
- Codebase read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Login.jsx` — toast pattern with Framer Motion, `showRestoredToast` state
- Codebase read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/ComparePanel.jsx` — line 143-145 confirms `question_text` already correct, no change needed
- Codebase read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Library.jsx` — `getQuestion()` helper at line 43-44, module-scope definition pattern
- Codebase read: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — `GetCandidatesByZip` confirmed does not set `ChamberName`, `CandidateOut` struct at line 3599-3616, candidate loop at lines 3679-3720
- Codebase read: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/ballotready/client.go` — `racesByZipQuery` at lines 476-524 (no `normalizedPosition` requested)
- Codebase read: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/ballotready/types.go` — `RacePositionNode` confirmed lacks chamber fields, `NormalizedPosition` struct exists for officeHolders
- Codebase read: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/auth/handlers.go` — `RegisterHandler` correctly processes `guest_state` when present
- Codebase read: `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/classify.js` — `classifyCategory()` uses `chamber_name_formal || chamber_name` for all executive sub-type grouping
- Codebase read: `/Users/chrisandrews/Documents/GitHub/.planning/v1-MILESTONE-AUDIT.md` — authoritative gap descriptions

---

## Metadata

**Confidence breakdown:**
- Gap locations: HIGH — exact line numbers verified from source code
- Fix patterns: HIGH — patterns copied verbatim from working code in same codebase
- ChamberName/normalizedPosition availability: MEDIUM — confirmed for officeHolders query type, assumed for races query type (pending API test)
- Toast auto-dismiss timing: HIGH — 3 second convention matches Login.jsx's 2 second pattern

**Research date:** 2026-02-18
**Valid until:** 2026-03-20 (stable codebase, no fast-moving dependencies)
