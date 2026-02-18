# Phase 04: Compass UX Enhancements - Research

**Researched:** 2026-02-17
**Domain:** CompassV2 React frontend + EV-Backend Go API — quiz UX, localStorage persistence, Framer Motion drawer, GORM migrations
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Question prompts:**
- Question text **replaces** the category title on issue cards — cards show the question (e.g., "What should the government do about healthcare?"), not the bare title
- On the compare page, the question appears **above the stances** as a header, separate from the politician stance columns
- Backend seeds default question text using a template like "What should the government do about {title}?" — admins can customize via textarea in the admin topic editor
- If a topic has no question set, the **frontend auto-generates** "What should the government do about {title}?" on the fly — no empty states

**Library popup (slide-in panel):**
- Clicking an issue card on the Library page opens a **slide-in panel from the right** (drawer style) — library grid stays visible behind it
- Stances in the panel use the **same UI as the quiz** answer options — consistent experience
- Selecting a different stance **saves instantly** (localStorage and/or server) and the **panel stays open** for review — no save button needed
- Panel content is **minimal: question + stances only** — no extra topic metadata or descriptions

**Stance randomization:**
- Per-user seed stored as a **localStorage guest ID** generated on first visit
- Each topic's stances are either shown in **original order or fully reversed** (binary flip per topic, decided by seed) — not a full shuffle, preserving the spectrum
- When a guest creates an account, the **guest seed migrates** to the account — stance order never changes for that user
- If a guest clears localStorage or uses a new browser, they get a **fresh guest ID and new randomization** — acceptable since they're anonymous

**Level indicators:**
- Level shown as **icon + text** at the **bottom of the issue card** (footer position)
- Icons are **custom SVG** matching the EV design system (Capitol dome for federal, state house for state, city hall for local)
- Level data comes from a **new column on compass.topics** (federal/state/local enum) — admin sets it per topic

### Claude's Discretion
- SVG icon design for the three level indicators
- Exact slide-in panel animation and width
- Spacing and typography adjustments for question text replacing titles
- How the admin textarea for question editing integrates with the existing topic form

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| QUIZ-01 | Issue cards show question/prompt instead of category title | Backend: new `question_text` column on `compass.topics`; frontend: auto-generate if null; Library card replaces `topic.short_title` display with question |
| QUIZ-02 | Compare page shows question/prompt above politician stances | ComparePanel already receives `selectedTopic` from topics array; add `question` header before stance list when topic is selected |
| QUIZ-03 | Clicking issue card on Library page opens popup with question, stances, and user's current selection (editable in-place) | Framer Motion `motion.div` + `AnimatePresence` for right-drawer; re-use Quiz stance button pattern; save via existing `POST /compass/answers` endpoint |
| QUIZ-08 | Stance order randomly inverted per user, permanent per issue (direction flip preserving spectrum) | Current `initRandomInversions` uses `Math.random()` — not stable. Replace with seeded PRNG using `localStorage` guest ID as seed; binary flip per `(seed, topicId)` hash |
| QUIZ-09 | Federal/state/local level indicators shown on issue cards | Backend: new `level` enum column on `compass.topics` (`federal`/`state`/`local`/`''`); custom SVG icons; footer of Library card |
</phase_requirements>

---

## Summary

Phase 4 enriches the CompassV2 quiz experience across four distinct axes: question prompts, stable stance randomization, inline answer editing from the Library, and federal/state/local level badges. All changes are self-contained within CompassV2 (React 19, Framer Motion 12, Tailwind 4) and the EV-Backend compass module (Go, GORM, PostgreSQL).

The backend work is minimal but precise: two new nullable columns on `compass.topics` — `question_text TEXT` and `level VARCHAR(10)` — plus a new admin PATCH endpoint to set them, and seeding logic that auto-populates `question_text` for existing topics. GORM AutoMigrate handles schema changes automatically; no manual migrations needed.

The frontend work is the bulk of the phase. The Library page needs the most significant change: topic cards now show question text as the primary label (auto-generated client-side if `question_text` is null), a level badge in the footer, and a click handler that opens a Framer Motion slide-in drawer. The drawer reuses the exact Quiz stance button pattern. Stance order randomization needs a deterministic PRNG seeded from a `localStorage` guest ID — replacing the current `Math.random()` approach.

**Primary recommendation:** Tackle in sequence: (1) backend schema + endpoints, (2) question text wiring, (3) stance randomization fix, (4) Library drawer, (5) level badges. The drawer is the most UI-intensive task and benefits from question text and stance logic being already wired.

---

## Standard Stack

### Core (already in project — no new installs needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `framer-motion` | ^12.23.0 | Slide-in drawer animation | Already in package.json; `motion.div` + `AnimatePresence` covers all drawer needs |
| `react` | ^19.1.0 | UI framework | Project standard |
| `tailwindcss` | ^4.1.10 | Styling | Project standard |
| GORM | (Go backend) | DB schema + ORM | Project standard for all backend models |

### No New Installs Required

All functionality can be built with existing dependencies. The seeded PRNG is a small pure function — no library needed for a simple mulberry32 or xmur3 implementation.

**Installation:**
```bash
# Nothing to install — all libraries already present
```

---

## Architecture Patterns

### Recommended Project Structure Changes

```
CompassV2/src/
├── components/
│   └── LibraryDrawer.jsx    # NEW: slide-in panel component
├── pages/
│   └── Library.jsx          # MODIFIED: question text, level badges, drawer trigger
│   └── Quiz.jsx             # MODIFIED: stance flip logic using seeded PRNG
├── components/
│   ├── CompassContext.jsx   # MODIFIED: seedId init, seeded initRandomInversions
│   └── admin/
│       └── TopicEditor.jsx  # MODIFIED: question_text textarea + level dropdown

EV-Backend/internal/compass/
├── models.go        # MODIFIED: add QuestionText, Level fields to Topic
├── handlers.go      # MODIFIED: TopicUpdateHandler to accept question_text + level
├── setup.go         # No change — AutoMigrate picks up new fields
```

### Pattern 1: Seeded PRNG for Stable Stance Randomization

**What:** Replace `Math.random()` in `initRandomInversions` with a deterministic hash of `(guestId, topicId)` to decide binary flip per topic.

**When to use:** Any time stance display order must be stable across page reloads for the same user.

**Current problem (CompassContext.jsx line 52):**
```js
// CURRENT — not stable:
if (Math.random() < 0.5) {
  next[st] = true;
}
```

**Recommended fix — seeded hash approach:**
```js
// In CompassContext.jsx

// Generate or restore guest ID on mount
function getOrCreateGuestId() {
  let id = localStorage.getItem("guestId");
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem("guestId", id);
  }
  return id;
}

// Simple deterministic hash: combines guestId + topicId to 0 or 1
function shouldFlip(guestId, topicId) {
  let hash = 0;
  const str = guestId + topicId;
  for (let i = 0; i < str.length; i++) {
    hash = (hash * 31 + str.charCodeAt(i)) >>> 0; // unsigned 32-bit
  }
  return (hash & 1) === 1; // odd hash = flip
}

// Replace initRandomInversions usage:
const initRandomInversions = useCallback((topicsArray) => {
  setInvertedSpokesRaw((prev) => {
    const hasExisting = topicsArray.some((t) => t.short_title in prev);
    if (hasExisting) return prev;
    const guestId = getOrCreateGuestId();
    const next = { ...prev };
    for (const topic of topicsArray) {
      if (shouldFlip(guestId, topic.id)) {
        next[topic.short_title] = true;
      }
    }
    localStorage.setItem("invertedSpokes", JSON.stringify(next));
    return next;
  });
}, []);
```

**Note:** `initRandomInversions` currently takes `shortTitles` (an array of strings). To hash against `topicId`, the call sites must pass topic objects or the full topics array instead. Both call sites are in `Quiz.jsx` — update accordingly.

**Confidence:** HIGH — deterministic hash approach is well-established for this pattern.

### Pattern 2: Library Slide-In Drawer

**What:** Framer Motion `AnimatePresence` + `motion.div` with `x` translate for a right-side drawer. Library grid remains visible (not a modal overlay).

**When to use:** When content should slide in from the edge without blocking the underlying page.

```jsx
// LibraryDrawer.jsx — recommended structure
import { motion, AnimatePresence } from "framer-motion";

function LibraryDrawer({ topic, currentAnswer, onClose, onSelectStance }) {
  const question = topic?.question_text
    ?? `What should the government do about ${topic?.short_title}?`;

  return (
    <AnimatePresence>
      {topic && (
        <>
          {/* Backdrop — semi-transparent, closes drawer on click */}
          <motion.div
            key="backdrop"
            className="fixed inset-0 bg-black/20 z-40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Drawer panel */}
          <motion.div
            key="drawer"
            className="fixed right-0 top-0 h-full w-full sm:w-96 bg-white shadow-xl z-50 flex flex-col"
            initial={{ x: "100%" }}
            animate={{ x: 0 }}
            exit={{ x: "100%" }}
            transition={{ type: "spring", damping: 30, stiffness: 300 }}
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-gray-100">
              <button onClick={onClose}>...</button>
            </div>

            {/* Question */}
            <p className="px-4 pt-4 pb-2 text-lg font-semibold">{question}</p>

            {/* Stances — same buttons as Quiz */}
            <div className="flex-1 overflow-y-auto px-4 pb-4 flex flex-col gap-3">
              {topic.stances.map((stance, i) => (
                <button
                  key={stance.id}
                  onClick={() => onSelectStance(topic, i + 1)}
                  className={`text-left px-4 py-3 rounded-lg text-sm font-medium
                    ${currentAnswer === i + 1
                      ? "border-ev-yellow border-2 bg-ev-yellow-light"
                      : "bg-white border-2 border-gray-300 hover:bg-gray-50"
                    }`}
                >
                  {stance.text}
                </button>
              ))}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
```

**Confidence:** HIGH — verified against Framer Motion 12 docs (AnimatePresence + motion.div + x translate is the canonical right-drawer pattern).

### Pattern 3: Question Text in Library Cards

**What:** Replace `topic.short_title` as the primary card label with the question text. Auto-generate client-side when `question_text` is null.

**When to use:** Always — no empty state needed per the locked decision.

```jsx
// In Library.jsx — inside the card render
const getQuestion = (topic) =>
  topic.question_text ?? `What should the government do about ${topic.short_title}?`;

// Card primary text:
<span className="text-sm md:text-base font-medium leading-snug">
  {getQuestion(topic)}
</span>
// Keep short_title in a secondary position or remove — question IS the label
```

**Note:** The current card also shows `category.title` as a sub-label. With question text as the primary label, the category sub-label becomes redundant — remove it or keep it small as context. The level badge (QUIZ-09) serves as the geographic context footer.

### Pattern 4: Question Above Stances in ComparePanel

**What:** Add a question header above the stance list inside ComparePanel when a topic is selected.

**Current structure (ComparePanel.jsx ~line 140):** `{topicSelected && selectedTopic && (...)}` renders the legend then stances immediately. Insert the question between the topic selector and the legend.

```jsx
// In ComparePanel.jsx — after topic selector div, before legend
{topicSelected && selectedTopic && (
  <>
    {/* Question header — NEW */}
    <p className="px-5 pb-3 text-base font-semibold text-neutral-800">
      {selectedTopic.question_text
        ?? `What should the government do about ${selectedTopic.short_title}?`}
    </p>

    {/* Existing legend */}
    <div className="flex items-center gap-3 text-xs text-neutral-400 px-5 pb-2">
      ...
    </div>
    ...
  </>
)}
```

### Pattern 5: Level Badge on Library Cards

**What:** Icon + text in card footer. Three SVG icons for federal/state/local.

**When to use:** When topic has a `level` value set. If `level` is null/empty, show nothing (no badge).

```jsx
// In Library.jsx — at the bottom of each card
const LEVEL_CONFIG = {
  federal: { label: "Federal", icon: <CapitolDomeSVG /> },
  state:   { label: "State",   icon: <StateHouseSVG /> },
  local:   { label: "Local",   icon: <CityHallSVG />   },
};

// Inside card:
{topic.level && LEVEL_CONFIG[topic.level] && (
  <div className="flex items-center gap-1 mt-2 text-xs text-gray-400">
    {LEVEL_CONFIG[topic.level].icon}
    <span>{LEVEL_CONFIG[topic.level].label}</span>
  </div>
)}
```

### Pattern 6: Backend — Adding Fields to Topic

**What:** Two new nullable columns on `compass.topics`. GORM AutoMigrate adds them automatically; no manual SQL needed.

```go
// models.go — updated Topic struct
type Topic struct {
  ID           uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
  TopicKey     string    `gorm:"uniqueIndex;not null" json:"topic_key"`
  Title        string    `json:"title"`
  ShortTitle   string    `gorm:"uniqueIndex" json:"short_title"`
  StartPhrase  string    `json:"start_phrase"`
  QuestionText string    `json:"question_text,omitempty"` // NEW
  Level        string    `json:"level,omitempty"`         // NEW: "federal"|"state"|"local"|""
  IsActive     bool      `gorm:"default:true" json:"is_active"`

  Stances    []Stance   `gorm:"foreignKey:TopicID" json:"stances"`
  Categories []Category `gorm:"many2many:compass.topic_categories;" json:"categories"`
}
```

**TopicUpdateHandler** needs to accept `question_text` and `level` in its PATCH body — extend the existing `topicRequest` struct.

**Seeding:** A one-time seed migration function (called from `Init()` or a separate admin endpoint) can populate `question_text` from `"What should the government do about " + short_title + "?"` for all existing topics where `question_text = ""`.

### Pattern 7: Guest Seed Migration on Account Creation

**What:** When a guest registers, their `guestId` from localStorage must carry over so stance order never changes. This requires passing `guestId` in the registration payload and storing it server-side, or simply preserving it in localStorage across registration (no clearing on registration).

**Simplest approach:** Since the guest ID is in localStorage and registration does NOT clear localStorage (only logout does), the `guestId` key survives registration. The `getOrCreateGuestId()` function will find the existing key and return the same ID. No server-side migration needed.

**Confirmed:** `Layout.jsx` logout clears `invertedSpokes`, `selectedTopics`, `answers`, `writeIns` — but `guestId` is not in that list. Adding `guestId` to the logout clear list is intentionally skipped (so a logged-out user starting a fresh session gets a new randomization).

### Anti-Patterns to Avoid

- **Using Math.random() for stance order:** Not deterministic across reloads. The current implementation has this bug — it's guarded by `hasExisting` check, so it only randomizes once per session mount, but a page reload after `localStorage.clear()` gives different results.
- **Full stance shuffle:** Destroys the spectrum. Binary flip only.
- **Modal instead of drawer:** Hides the library grid. Use a side-panel that keeps background visible.
- **Save button in drawer:** Creates friction. Save on stance click is the locked decision.
- **Storing level as integer:** Use string enum (`"federal"/"state"/"local"`) — more readable in both Go and JS, no magic numbers.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Drawer animation | Custom CSS transitions + JS state toggle | Framer Motion `AnimatePresence` + `motion.div` | AnimatePresence handles mount/unmount correctly; spring physics built in |
| Seeded random | Full Seedrandom library | 10-line hash function (djb2-style) | No dependency needed for a single binary flip per (seed, topicId) |
| Admin text editor | Rich text / WYSIWYG | Plain `<textarea>` in the existing TopicEditor form | The question text is a single sentence — no formatting needed |

**Key insight:** The existing Quiz stance button UI is already pixel-perfect. Extract the button className into a shared constant or reuse the same Tailwind classes directly in the drawer — do not create an abstraction.

---

## Common Pitfalls

### Pitfall 1: Drawer clips behind nav
**What goes wrong:** The slide-in drawer appears behind the site header or bottom nav bar.
**Why it happens:** `z-index` not high enough; `fixed` positioning needs correct z stacking context.
**How to avoid:** Use `z-50` (or higher if nav uses a high z-index). Check that `SiteHeader` from `ev-ui` does not create a new stacking context that traps the drawer.
**Warning signs:** Drawer appears but header overlaps it.

### Pitfall 2: Stance flip not stable after topic is first answered
**What goes wrong:** `initRandomInversions` skips if `hasExisting` is true — so answered topics never get flipped. But on a fresh guest visit, all topics are new and all get assigned. The problem is: Quiz.jsx calls `initRandomInversions(shortTitles)` where shortTitles are the **selected** topics only. Full quiz mode never calls it. So full-quiz stances are never flipped.
**Why it happens:** The call to `initRandomInversions` is conditional on `mode !== "full"` (Quiz.jsx line 201-207).
**How to avoid:** Either call `initRandomInversions` in both modes, or compute the flip inline in the stance rendering from the seed directly — so it works regardless of mode.
**Warning signs:** Curated quiz has stable order; full quiz does not.

### Pitfall 3: Answer save in drawer for guests vs logged-in users
**What goes wrong:** Drawer's "save instantly" behavior needs to work for both guests (localStorage only) and logged-in users (POST /compass/answers).
**Why it happens:** The existing Library page does NOT have answer-saving logic — it's read-only. The new drawer must add it.
**How to avoid:** Mirror the `selectAnswer` + `handleNext` logic from Quiz.jsx but without navigation. For guests: update `answers` in CompassContext (which auto-persists to localStorage). For logged-in: also POST to backend.
**Warning signs:** Drawer answer appears to save visually but reverts on page reload for guests.

### Pitfall 4: Question text missing from category API response
**What goes wrong:** `CategoryHandler` preloads `Topics` but the Topic struct only returns active topics with basic fields. If `question_text` and `level` are added to the model, they'll be included automatically via GORM.
**Why it happens:** Nothing — GORM serializes all struct fields. This is not actually a pitfall, but worth verifying.
**Confirmation needed:** After AutoMigrate adds the columns, test that `/compass/categories` and `/compass/topics` responses include `question_text` and `level` in the JSON.

### Pitfall 5: `initRandomInversions` called with wrong argument shape
**What goes wrong:** Current call passes `shortTitles` (string array). New seeded version needs `topicId` for hashing. Changing the argument type will break existing call sites.
**How to avoid:** Change the function signature to accept topic objects `{ short_title, id }` instead of just short title strings. Update both call sites in Quiz.jsx.

### Pitfall 6: Admin level dropdown saves empty string vs null
**What goes wrong:** If admin leaves level unset, backend receives `""` which may or may not match Go's zero-value for string. Frontend should treat both `""` and `null` as "no level set" and show no badge.
**How to avoid:** Frontend badge render: `topic.level && LEVEL_CONFIG[topic.level]`. Backend handler: store as-is (empty string is fine — no constraint needed).

---

## Code Examples

Verified patterns from codebase:

### Existing stance button pattern (Quiz.jsx ~line 411-427)
```jsx
// This exact pattern must be reused in LibraryDrawer
<button
  key={stance.id}
  onClick={() => selectAnswer(i + 1)}
  className={`text-left px-4 py-3 rounded-lg transition-all duration-200 text-sm sm:text-base font-medium cursor-pointer
  ${
    selectedAnswer === i + 1
      ? "border-ev-yellow border-2 bg-ev-yellow-light"
      : "bg-white text-black border-2 border-gray-300 hover:bg-gray-50"
  }`}
>
  {stance.text}
</button>
```

### Existing answer save pattern (Quiz.jsx ~line 306-328)
```js
// For logged-in users in the drawer:
fetch(`${import.meta.env.VITE_API_URL}/compass/answers`, {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    topic_id: currentTopicId,
    value: selectedAnswer,
  }),
})
// For guests: setAnswers() in CompassContext auto-persists to localStorage
```

### Existing answer persistence in CompassContext (line 62-69)
```js
// Already handles localStorage sync — drawer just needs to call setAnswers()
useEffect(() => {
  localStorage.setItem("answers", JSON.stringify(answers));
}, [answers]);
```

### GORM AutoMigrate pattern (setup.go)
```go
// Adding fields to Topic struct is sufficient — AutoMigrate adds the columns
func Init() {
  if err := db.EnsureSchema(db.DB, "compass"); err != nil {
    log.Fatal("Failed to create compass schema: ", err)
  }
  if err := db.DB.AutoMigrate(&Topic{}, &Answer{}, &Stance{}, &Category{}, &Context{}, &UserCompass{}); err != nil {
    log.Fatal("Failed to auto-migrate tables", err)
  }
}
```

### TopicUpdateHandler extension pattern (handlers.go ~line 82-116)
```go
// Extend this struct to accept new fields:
var topicRequest struct {
  ID           string  `json:"id"`
  Title        *string `json:"title,omitempty"`
  ShortTitle   *string `json:"short_title,omitempty"`
  QuestionText *string `json:"question_text,omitempty"` // NEW
  Level        *string `json:"level,omitempty"`         // NEW
}
// Then add to updates map:
if topicRequest.QuestionText != nil {
  updates["question_text"] = *topicRequest.QuestionText
}
if topicRequest.Level != nil {
  updates["level"] = *topicRequest.Level
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Math.random()` per session mount | Seeded PRNG from `localStorage` guest ID | This phase | Stable stance order across reloads |
| Library card shows `short_title` | Library card shows question text | This phase | Cards are self-explanatory without the quiz |
| Library card click = toggle selection | Library card click = open drawer | This phase | User can edit answers inline |
| No level metadata on topics | `level` enum column in DB | This phase | Cards show federal/state/local scope |

**Deprecated/outdated:**
- `initRandomInversions(shortTitles: string[])`: Argument shape must change to include topic IDs for seeded hashing. Both call sites (Quiz.jsx curated mode effect) must be updated.

---

## Open Questions

1. **Should the drawer also replace the card's toggle-selection behavior?**
   - What we know: Cards currently toggle selection (add/remove from selectedTopics) on click. The new behavior opens the drawer.
   - What's unclear: Does selection still happen on click, or only via the drawer?
   - Recommendation: The drawer is for viewing/editing answers. Topic selection (for the curated compass) should remain a separate control — perhaps a checkbox or separate button on the card, separate from the click-to-open-drawer action. The locked decision says "clicking an issue card... opens a slide-in panel" — so the full card click opens the drawer. Selection mechanism may need a dedicated UI element (e.g., a checkbox in the card corner). **Planner should clarify this interaction before implementing.**

2. **Quiz.jsx full-mode stance flip**
   - What we know: `initRandomInversions` is only called in curated mode (guarded by `mode !== "full"`).
   - What's unclear: Should stances also be flipped in full quiz mode?
   - Recommendation: Yes — the CONTEXT.md says the flip is per-user per-topic, not per-mode. Apply the seeded flip in both modes. The flip should be computed from the guest ID + topic ID hash and applied at render time, independent of the `invertedSpokes` state (which tracks user-driven inversions on the Compass radar). **Planner should confirm: are stance flip (QUIZ-08) and spoke inversion (existing feature) the same mechanism or separate?** They appear to be the same `invertedSpokes` state, but the semantics differ: stance flip is randomized at first encounter; spoke inversion is user-triggered. They should remain the same localStorage key so they interact correctly.

3. **Seed migration when guest registers**
   - What we know: Logout clears `invertedSpokes`, `answers`, `writeIns`, `selectedTopics`. `guestId` is a new localStorage key that should NOT be cleared on logout (so a returning user without account gets new randomization on fresh visit, but an existing guest who just registered keeps their order).
   - What's unclear: Should `guestId` be cleared on logout?
   - Recommendation: Do NOT clear `guestId` on logout. The user's stance order is identity-less — it's a UX comfort feature, not security-sensitive. A new guest session on a shared device will inherit the previous guest's order, which is acceptable.

---

## Sources

### Primary (HIGH confidence)
- Codebase: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/CompassContext.jsx` — confirms `initRandomInversions` uses `Math.random()`, `invertedSpokes` localStorage key, existing answer persistence pattern
- Codebase: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Quiz.jsx` — confirms stance button classes, answer save pattern, `mode` guard for randomization
- Codebase: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Library.jsx` — confirms card renders `topic.short_title` and `category.title`, toggleTopic behavior
- Codebase: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/ComparePanel.jsx` — confirms where question header should be inserted, existing stance rendering
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/compass/models.go` — confirms `Topic` struct, existing fields, GORM table name
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/compass/handlers.go` — confirms `TopicUpdateHandler` pattern to extend
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/compass/setup.go` — confirms `AutoMigrate` adds columns automatically
- Codebase: `/Users/chrisandrews/Documents/GitHub/CompassV2/package.json` — confirms `framer-motion: ^12.23.0` already installed
- Context7 (`/grx7/framer-motion`) — confirms `AnimatePresence` + `motion.div` + `x` translate is the canonical right-drawer pattern

### Secondary (MEDIUM confidence)
- Context7 framer-motion docs — AnimatePresence with `initial/animate/exit` props for mount/unmount animation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified in package.json and codebase
- Architecture: HIGH — patterns derived directly from existing code; no guesswork
- Pitfalls: HIGH — identified from direct code reading; the `Math.random()` bug and full-mode gap are confirmed
- Open questions: MEDIUM — interaction design questions that the planner should confirm with context

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable framework, no fast-moving dependencies)
