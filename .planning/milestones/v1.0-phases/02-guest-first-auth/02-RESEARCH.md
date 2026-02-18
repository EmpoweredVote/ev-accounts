# Phase 02: Guest-First Auth - Research

**Researched:** 2026-02-17
**Domain:** Frontend auth gating removal, localStorage-first state, backend guest merge on register/login
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Save Prompt**
- Appears after viewing results — user sees their radar chart first, then gets prompted
- Modal dialog initially — if user dismisses, a persistent bottom banner replaces it
- Messaging focuses on saving results — "Create an account to save your compass results"
- If guest dismisses both modal and banner, show the banner once more on next visit, then stop permanently
- The modal includes inline registration (email/password fields) — user signs up without leaving the results page

**Guest Experience**
- Subtle nav hint — a small "Sign in" or "Guest" label in the header area, nothing intrusive
- Full access for guests — quiz, results, library, compare all work identically to logged-in users
- Keep current navigation flow — same landing behavior, just remove the login gate
- No features are restricted for guests

**Account Merge**
- Silent merge for new accounts — answers transfer seamlessly, no notification needed
- Brief notice when logging into an existing account with different local answers — "Your saved answers have been restored" so user knows local changes didn't persist
- Server-wins strategy is confirmed — server answers always take priority on login

**Admin Controls**
- Confirmation dialog required before clearing compass — "Are you sure? This will clear all your compass answers."
- Clear wipes both server and localStorage — complete reset
- Only "Clear compass" is admin-only in this phase — nothing else changes
- Placement: inline with other profile actions (logout, etc.) — no special separator

### Claude's Discretion
- Exact nav treatment for guest indicator (sign in button style, placement)
- localStorage management strategy after server sync (clear vs keep as fallback)
- Loading states and error handling during merge/registration
- Toast/notification styling for the "saved answers restored" message

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-02 | User can take full compass quiz without logging in | Remove ProtectedRoute from /quiz, /results, /library, /build; CompassContext localStorage-first for answers |
| AUTH-03 | Guest answers persist in localStorage across browser sessions | answers + writeIns + selectedTopics already use localStorage; need to extend answers to also write to localStorage |
| AUTH-04 | Post-completion save prompt appears after quiz completion, not before | Modal/banner in Compass.jsx results page, not a route guard |
| AUTH-05 | Guest localStorage state merges to server on account creation (server-wins) | New `guest_state` body field in /auth/register; new endpoint or behavior in /auth/login to restore server answers |
| AUTH-06 | Clear compass is admin-only, accessible from profile dropdown | New handler DELETE /compass/answers/me on backend; isAdmin gate in Layout.jsx profileItems |
</phase_requirements>

---

## Summary

This phase converts CompassV2 from a fully-gated app to a guest-first experience. The current architecture puts every meaningful route behind `ProtectedRoute`, which bounces unauthenticated users to `/401`. All quiz state (answers, writeIns) is held in React state only and immediately flushed to the backend via `POST /compass/answers` — there is no localStorage persistence for answers today (only for `selectedTopics` and `invertedSpokes`).

The three workstreams are: (1) backend changes to accept `guest_state` on register and restore server answers on login, (2) frontend CompassContext changes to hold answers in localStorage and skip server calls when unauthenticated, and (3) the results-page save prompt with inline registration + the admin-only clear button.

**Primary recommendation:** Make `answers` localStorage-first in CompassContext (parallel to how `selectedTopics` already works), remove ProtectedRoute from guest-accessible routes, add a `guest_state` JSON column to the register/login payloads for merge, and render the save prompt as an overlay on the Compass (results) page — not as a separate route.

---

## Standard Stack

### Core (already present — no new installs needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React 19 | ^19.1.0 | UI | Already installed |
| react-router 7 | ^7.6.2 | Routing | Already installed |
| Framer Motion | ^12.23.0 | Modal animation | Already installed |
| Tailwind CSS 4 | ^4.1.10 | Styling | Already installed |

### Supporting (already present)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| localStorage (browser API) | native | Guest state persistence | answers, writeIns, selectedTopics, save-prompt dismissal flags |
| ev-ui AuthForm | ^0.1.12 | Registration form component | Reuse inside inline registration modal |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| localStorage for answers | sessionStorage | sessionStorage clears on tab close — breaks AUTH-03 requirement |
| Framer Motion modal | custom CSS | Framer Motion already imported; no reason to duplicate |
| New `/compass/answers/me` DELETE endpoint | Reusing existing answer endpoints | Clean separation; existing endpoints don't support bulk-delete-own |

**Installation:** No new packages needed. All required libraries already exist in `CompassV2/package.json`.

---

## Architecture Patterns

### Current Codebase State (what exists today)

```
CompassV2/src/
├── App.jsx                        # All routes behind ProtectedRoute
├── components/
│   ├── CompassContext.jsx          # selectedTopics in localStorage; answers in React state only
│   ├── ProtectedRoute.jsx          # Calls /auth/me, redirects to /401 if not authed
│   ├── AdminRoute.jsx              # Calls /auth/admin-check
│   ├── Layout.jsx                  # Header with username + profile menu; isAdmin hook
│   └── admin/AdminDashboard.jsx
├── hooks/
│   └── IsAdmin.jsx                 # Calls /auth/admin (note: endpoint is /auth/admin not /auth/admin-check)
└── pages/
    ├── Quiz.jsx                    # POST /compass/answers on every Next click (requires session)
    ├── Compass.jsx                 # POST /compass/answers/batch to load answers (requires session)
    ├── Library.jsx                 # Behind ProtectedRoute
    ├── Login.jsx                   # Uses AuthForm from ev-ui
    └── Register.jsx                # Uses AuthForm from ev-ui
```

**Key observations:**
- `answers` and `writeIns` live only in React state (no localStorage persistence)
- `selectedTopics` and `invertedSpokes` are already localStorage-persisted
- Every `POST /compass/answers` in Quiz.jsx will fail with 401 for guests (requires session cookie)
- `Compass.jsx` loads answers via `POST /compass/answers/batch` which also requires session
- `CompassContext.refreshSelectedTopics` silently handles 401 (falls back to localStorage)
- The `IsAdmin` hook calls `/auth/admin` but the route manifest shows `/auth/admin-check` — this is an existing discrepancy (noted, not in scope)

### What Changes

#### 1. App.jsx — Route Ungating

Remove `ProtectedRoute` wrapper from `/library`, `/quiz`, `/results`, `/build`. Keep `ProtectedRoute` only for `/home`, `/help`, `/admin`. The `/` and `/login` routes stay as-is.

**Before:**
```jsx
<Route path="/quiz" element={<ProtectedRoute><Quiz /></ProtectedRoute>} />
<Route path="/results" element={<ProtectedRoute><Layout><Compass /></Layout></ProtectedRoute>} />
<Route path="/library" element={<ProtectedRoute><Layout><Library /></Layout></ProtectedRoute>} />
<Route path="/build" element={<ProtectedRoute><Layout><BuildCompass /></Layout></ProtectedRoute>} />
```

**After:**
```jsx
<Route path="/quiz" element={<Quiz />} />
<Route path="/results" element={<Layout><Compass /></Layout>} />
<Route path="/library" element={<Layout><Library /></Layout>} />
<Route path="/build" element={<Layout><BuildCompass /></Layout>} />
```

#### 2. CompassContext.jsx — localStorage-First Answers

`answers` and `writeIns` need the same localStorage persistence pattern that `selectedTopics` already uses. The pattern:
- Initialize from localStorage
- Write to localStorage on every update
- Server sync only when session is active (check via `useAuth` hook or optimistic try)

**Pattern (mirrors existing selectedTopics approach):**
```jsx
const [answers, setAnswers] = useState(
  () => safeParse(localStorage.getItem("answers"), {})
);

// Sync to localStorage on every change
useEffect(() => {
  localStorage.setItem("answers", JSON.stringify(answers));
}, [answers]);

// Sync to localStorage on writeIns change
const [writeIns, setWriteIns] = useState(
  () => safeParse(localStorage.getItem("writeIns"), {})
);
useEffect(() => {
  localStorage.setItem("writeIns", JSON.stringify(writeIns));
}, [writeIns]);
```

CompassContext also needs to know if the user is authenticated to decide whether to sync answers to the server. Simplest approach: maintain an `isLoggedIn` boolean in context, set it after `/auth/me` succeeds on mount.

```jsx
const [isLoggedIn, setIsLoggedIn] = useState(false);

useEffect(() => {
  fetch(`${API}/auth/me`, { credentials: "include" })
    .then(r => r.ok ? r.json() : null)
    .then(data => {
      if (data) setIsLoggedIn(true);
    })
    .catch(() => {});
}, []);
```

#### 3. Quiz.jsx — Guard Answer POSTs

Currently `handleNext` unconditionally calls `POST /compass/answers`. For guests, this will 401. Two options:

**Option A (recommended):** Skip server POST for guests, rely on localStorage. On handleNext, check `isLoggedIn` from context before fetching.

```jsx
const handleNext = () => {
  // Always update localStorage via setAnswers (already done via context)

  if (isLoggedIn) {
    fetch(`${API}/compass/answers`, { method: "POST", ... })
      .then(() => advanceOrNavigate())
      .catch(() => alert("Error saving"));
  } else {
    advanceOrNavigate(); // localStorage is source of truth for guests
  }
};
```

**Option B:** Let the 401 happen silently, ignore the error. Simpler but wastes a network round-trip per question.

Option A is cleaner and avoids unnecessary API calls.

#### 4. Compass.jsx — Answer Loading + Save Prompt

Currently loads answers via `POST /compass/answers/batch` (requires session). For guests, answers are already in localStorage via CompassContext. Change:

- When `isLoggedIn` is true: fetch from server (existing behavior)
- When `isLoggedIn` is false: read from CompassContext.answers (already populated from localStorage)

**Save Prompt (Locked Decision):**

After the radar chart renders, show a modal. On dismiss, replace with a bottom banner. Track dismissal with localStorage flags:

```js
// localStorage keys for prompt state
"savePromptModalDismissed"   // set when user closes modal
"savePromptBannerDismissed"  // set when user closes banner
"savePromptBannerVisitCount" // increment on each visit; stop showing after 2
```

Inline registration inside the modal uses the existing `AuthForm` component from `@chrisandrewsedu/ev-ui` in `register` mode. Before calling `/auth/register`, package localStorage answers into `guest_state`.

```jsx
const handleInlineRegister = async (username, password) => {
  const guestState = {
    answers: safeParse(localStorage.getItem("answers"), {}),
    writeIns: safeParse(localStorage.getItem("writeIns"), {}),
    selectedTopics: safeParse(localStorage.getItem("selectedTopics"), []),
  };

  const res = await fetch(`${API}/auth/register`, {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password, guest_state: guestState }),
  });

  if (res.ok) {
    setIsLoggedIn(true);
    // localStorage stays as-is (server confirms same data)
    closeSavePrompt();
  }
};
```

#### 5. Layout.jsx — Guest Indicator + Admin Clear Compass

**Guest indicator (Claude's discretion):** When `username` is null (guest), show a "Sign in" button in the header instead of the profile menu. Simplest implementation: check `username` state in Layout, render a button that navigates to `/login`.

**Admin clear compass:** Add "Clear compass" to `profileItems` when `isAdmin` is true. Trigger a confirmation dialog, then call `DELETE /compass/answers/me`.

```jsx
const profileItems = [
  ...(isAdmin ? [
    { label: "Admin", href: "/admin" },
    { label: "Clear compass", onClick: handleClearCompass },
  ] : []),
  { label: "Logout", onClick: logout },
];
```

```jsx
const handleClearCompass = () => {
  if (!confirm("Are you sure? This will clear all your compass answers.")) return;
  fetch(`${API}/compass/answers/me`, {
    method: "DELETE",
    credentials: "include",
  }).then(() => {
    // Wipe localStorage
    localStorage.removeItem("answers");
    localStorage.removeItem("writeIns");
    localStorage.removeItem("selectedTopics");
    localStorage.removeItem("invertedSpokes");
    setAnswers({});
    setWriteIns({});
    setSelectedTopics([]);
  });
};
```

### Backend Changes

#### Plan 02-01: /auth/register guest_state

Add optional `GuestState` field to register request body. After creating the user and session, bulk-insert the guest answers into `compass.answers`.

**Request body change:**
```go
type RegisterRequest struct {
    Username   string     `json:"username"`
    Password   string     `json:"password"`
    GuestState *GuestState `json:"guest_state,omitempty"`
}

type GuestState struct {
    Answers  []GuestAnswer `json:"answers"`
    WriteIns map[string]string `json:"write_ins,omitempty"`
    // selectedTopics stored separately via UserCompass
}

type GuestAnswer struct {
    TopicID     string  `json:"topic_id"`
    Value       float64 `json:"value"`
    WriteInText string  `json:"write_in_text,omitempty"`
}
```

After user created + session set, if `GuestState != nil`, bulk-insert answers in a transaction. Map `short_title` → `topic_id` lookup if the frontend sends short_titles, OR have the frontend send topic UUIDs directly (preferred — simpler backend logic).

Note: The current `answers` state in CompassContext uses `short_title` as keys. For the guest_state merge, the frontend needs to send topic UUIDs. This means the frontend must convert short_title → topic_id using the `topics` array from CompassContext before POSTing guest_state.

#### Plan 02-01: /auth/login server-wins

On successful login, if the account already has answers in `compass.answers`, the server-wins strategy means: do nothing extra — just return the user's session. The frontend reads server answers on the Compass page via the normal `answers/batch` fetch. This naturally overwrites any localStorage values.

The "brief notice" for existing-account login happens on the frontend: detect that `localStorage.answers` is non-empty AND the user logged into an existing account (not register), then show a toast "Your saved answers have been restored." The detection logic: after `POST /auth/login` succeeds, check if `localStorage.getItem("answers")` has any keys; if yes, show the toast, then clear localStorage answers (server wins).

#### Plan 02-01: DELETE /compass/answers/me

New endpoint, session-protected:

```go
func DeleteMyAnswersHandler(w http.ResponseWriter, r *http.Request) {
    userID, ok := utils.GetUserIDFromContext(r.Context())
    if !ok {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }
    if err := db.DB.Where("user_id = ?", userID).Delete(&Answer{}).Error; err != nil {
        http.Error(w, "Failed to delete answers", http.StatusInternalServerError)
        return
    }
    // Also clear UserCompass (selected topics)
    db.DB.Where("user_id = ?", userID).Delete(&UserCompass{})
    w.WriteHeader(http.StatusOK)
}
```

Route in compass/routes.go under SessionMiddleware + AdminMiddleware:
```go
r.With(middleware.AdminMiddleware(...)).Delete("/answers/me", DeleteMyAnswersHandler)
```

### Pattern: localStorage as Source of Truth for Unauthenticated State

This is the standard pattern for "offline-first" or "guest-first" web apps:

1. State initializes from localStorage
2. Every state update writes back to localStorage
3. On authenticated mount, server data takes priority and overwrites localStorage
4. Server writes happen only when session is active

This pattern is already partially implemented in CompassContext for `selectedTopics` and `invertedSpokes`. The change extends it to `answers` and `writeIns`.

### Anti-Patterns to Avoid

- **Checking authStatus in every component separately:** CompassContext should own the `isLoggedIn` boolean so quiz, compass, and library all share one source of truth.
- **Sending guest answers with short_title keys:** Backend requires topic UUIDs; frontend must convert before sending `guest_state`.
- **Showing save prompt before results:** The prompt lives in `Compass.jsx` (results page), not in Quiz.jsx. Do not add navigation guards.
- **Clearing localStorage before server confirms merge:** If registration fails mid-request, localStorage should still have the answers. Only clear after successful merge.
- **Using `window.confirm` for the clear compass confirmation:** The decisions doc says "confirmation dialog" — a native `confirm()` call is acceptable and simplest; a custom modal is also fine but heavier.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Registration form in modal | Custom form fields | `AuthForm` from ev-ui in `register` mode | Already used in Register.jsx; handles validation, submit state, error display |
| Toast notification | Custom toast component | Small inline state (`showRestoredToast`) + Framer Motion fade | Toast library is overkill; Framer Motion already present |
| UUID conversion (short_title → topic_id) | Custom lookup table | CompassContext.topics array already loaded | topics is available in context; `topics.find(t => t.short_title === key)` |

---

## Common Pitfalls

### Pitfall 1: Quiz.jsx crashes when answers POST returns 401

**What goes wrong:** Quiz.jsx's `handleNext` calls `fetch(POST /compass/answers)` which returns 401 for guests. Current code shows `alert("Error saving your answer. Please try again.")` — this breaks the guest experience badly.

**Why it happens:** The route is now accessible without auth, but the backend endpoint still requires a session cookie.

**How to avoid:** Gate the server POST behind `isLoggedIn` from CompassContext. For guests, just advance the index (localStorage is already updated via setAnswers).

**Warning signs:** Guest sees alert dialogs while taking the quiz.

### Pitfall 2: Compass.jsx answers/batch POST 401 for guests

**What goes wrong:** `Compass.jsx` fires `POST /compass/answers/batch` on mount for the selected topics. For guests this returns 401, so `setAnswers` never gets called, and the radar chart shows empty.

**Why it happens:** `useEffect` fires unconditionally regardless of auth state.

**How to avoid:** Gate the fetch behind `isLoggedIn`. When not logged in, the answers are already in state from localStorage initialization in CompassContext — no fetch needed.

**Warning signs:** Guest radar chart is empty/blank on results page despite having answered questions.

### Pitfall 3: Guest state double-serialization

**What goes wrong:** The frontend stores `answers` as `{ [shortTitle]: value }` in localStorage, but the backend `/auth/register` endpoint needs topic UUIDs. If the frontend sends short_titles in `guest_state`, the backend has no mapping and must do an expensive lookup or error.

**Why it happens:** CompassContext uses short_titles as keys internally (matching what the RadarChart expects as labels), but the DB uses UUID topic_ids.

**How to avoid:** Frontend converts before POSTing — use `topics.find(t => t.short_title === key)?.id` to build the UUID-keyed `guest_state.answers` array. This conversion happens in the inline registration handler, not in CompassContext.

**Warning signs:** Backend returns 400 or inserts 0 answers after registration.

### Pitfall 4: Save prompt showing for logged-in users

**What goes wrong:** If `isLoggedIn` state isn't properly set after inline registration, or if CompassContext doesn't update it after login, the save prompt may still appear.

**Why it happens:** CompassContext only checks auth once on mount; inline registration inside the modal updates server state but doesn't trigger a re-check.

**How to avoid:** After successful inline registration, explicitly call `setIsLoggedIn(true)` in CompassContext (exposed as a setter or via a `refreshAuth()` function). The save prompt renders conditionally on `!isLoggedIn`.

**Warning signs:** Modal/banner still visible after user registers.

### Pitfall 5: Banner show-once-more logic on next visit

**What goes wrong:** The "show banner once more on next visit" requirement needs a persistent counter. If implemented with a React state boolean only, it resets on every page load.

**Why it happens:** Transient state doesn't survive navigation.

**How to avoid:** Use a localStorage counter:
```js
const bannerDismissCount = parseInt(localStorage.getItem("savePromptBannerDismissed") || "0");
// Show if count < 2
// Increment on dismiss
localStorage.setItem("savePromptBannerDismissed", String(bannerDismissCount + 1));
```

**Warning signs:** Banner shows infinitely, or never shows the second time.

### Pitfall 6: selectedTopics sync fires for guests

**What goes wrong:** CompassContext has a `useEffect` that PUTs `selectedTopics` to `/compass/selected-topics` whenever `selectedTopics` changes. For guests this will 401 on every topic toggle.

**Why it happens:** The sync effect checks `serverLoaded.current` before firing, but `serverLoaded` gets set to `true` at end of `refreshSelectedTopics` regardless of whether the user was authenticated. The 401 response is silently ignored (`.catch(() => {})`), so it won't break anything — but it's wasteful.

**How to avoid:** Gate the PUT behind `isLoggedIn`. Or accept the silent 401s as-is (they're already caught). Low risk, but clean code gating it is preferred.

**Warning signs:** Network tab shows 401s on PUT /compass/selected-topics for guest users.

---

## Code Examples

### Guest-First Route Structure

```jsx
// App.jsx — after changes
<Routes>
  <Route path="/" element={<Login />} />
  <Route path="/login" element={<Login />} />
  <Route path="/register" element={<Register />} />

  {/* Guest-accessible routes — no ProtectedRoute */}
  <Route path="/library" element={<Layout><Library /></Layout>} />
  <Route path="/quiz" element={<Quiz />} />
  <Route path="/build" element={<Layout><BuildCompass /></Layout>} />
  <Route path="/results" element={<Layout><Compass /></Layout>} />

  {/* Auth-required routes — keep ProtectedRoute */}
  <Route path="/help" element={<ProtectedRoute><Onboarding /></ProtectedRoute>} />
  <Route path="/home" element={<ProtectedRoute><Home /></ProtectedRoute>} />
  <Route path="/admin" element={
    <ProtectedRoute>
      <AdminRoute>
        <Layout><AdminDashboard /></Layout>
      </AdminRoute>
    </ProtectedRoute>
  } />
  <Route path="/401" element={<Unauthorized />} />
</Routes>
```

### CompassContext isLoggedIn + localStorage-first answers

```jsx
// CompassContext.jsx additions
const [isLoggedIn, setIsLoggedIn] = useState(false);

const [answers, setAnswers] = useState(
  () => safeParse(localStorage.getItem("answers"), {})
);
const [writeIns, setWriteIns] = useState(
  () => safeParse(localStorage.getItem("writeIns"), {})
);

// Persist answers to localStorage
useEffect(() => {
  localStorage.setItem("answers", JSON.stringify(answers));
}, [answers]);

useEffect(() => {
  localStorage.setItem("writeIns", JSON.stringify(writeIns));
}, [writeIns]);

// Auth check on mount
useEffect(() => {
  fetch(`${API}/auth/me`, { credentials: "include" })
    .then(r => r.ok ? r.json() : null)
    .then(data => { if (data) setIsLoggedIn(true); })
    .catch(() => {});
}, []);

// Expose setIsLoggedIn for inline registration
// ... in context value: isLoggedIn, setIsLoggedIn
```

### Save Prompt State Machine (localStorage-backed)

```jsx
// In Compass.jsx
const MODAL_KEY = "savePromptModalDismissed";
const BANNER_KEY = "savePromptBannerDismissCount";

function useSavePromptState(isLoggedIn) {
  const [showModal, setShowModal] = useState(false);
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    if (isLoggedIn) return;
    const modalDismissed = localStorage.getItem(MODAL_KEY) === "1";
    const bannerCount = parseInt(localStorage.getItem(BANNER_KEY) || "0");

    if (!modalDismissed) {
      setShowModal(true);
    } else if (bannerCount < 2) {
      setShowBanner(true);
    }
  }, [isLoggedIn]);

  const dismissModal = () => {
    localStorage.setItem(MODAL_KEY, "1");
    setShowModal(false);
    const bannerCount = parseInt(localStorage.getItem(BANNER_KEY) || "0");
    if (bannerCount < 2) setShowBanner(true);
  };

  const dismissBanner = () => {
    const count = parseInt(localStorage.getItem(BANNER_KEY) || "0");
    localStorage.setItem(BANNER_KEY, String(count + 1));
    setShowBanner(false);
  };

  return { showModal, showBanner, dismissModal, dismissBanner };
}
```

### Backend: Register with guest_state (Go)

```go
// auth/handlers.go — RegisterHandler additions
type GuestAnswer struct {
    TopicID     string  `json:"topic_id"`
    Value       float64 `json:"value"`
    WriteInText string  `json:"write_in_text,omitempty"`
}

type GuestState struct {
    Answers      []GuestAnswer `json:"answers,omitempty"`
    SelectedTopics []string    `json:"selected_topics,omitempty"`
}

// In RegisterHandler, after creating user and session:
if body.GuestState != nil && len(body.GuestState.Answers) > 0 {
    // Bulk insert answers in a transaction
    tx := db.DB.Begin()
    for _, ga := range body.GuestState.Answers {
        tid, err := uuid.Parse(ga.TopicID)
        if err != nil { continue } // skip invalid UUIDs
        a := compass.Answer{
            ID:          uuid.NewString(),
            UserID:      user.UserID,
            TopicID:     tid,
            Value:       ga.Value,
            WriteInText: ga.WriteInText,
        }
        tx.Create(&a)
    }
    tx.Commit()

    // Upsert selected topics if provided
    if len(body.GuestState.SelectedTopics) > 0 {
        uc := compass.UserCompass{
            UserID:   user.UserID,
            TopicIDs: pq.StringArray(body.GuestState.SelectedTopics),
        }
        db.DB.Where("user_id = ?", user.UserID).Assign(uc).FirstOrCreate(&uc)
    }
}
```

### Backend: DELETE /compass/answers/me

```go
// compass/handlers.go
func DeleteMyAnswersHandler(w http.ResponseWriter, r *http.Request) {
    userID, ok := utils.GetUserIDFromContext(r.Context())
    if !ok {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }

    tx := db.DB.Begin()
    if err := tx.Where("user_id = ?", userID).Delete(&Answer{}).Error; err != nil {
        tx.Rollback()
        http.Error(w, "Failed to clear answers", http.StatusInternalServerError)
        return
    }
    if err := tx.Where("user_id = ?", userID).Delete(&UserCompass{}).Error; err != nil {
        tx.Rollback()
        http.Error(w, "Failed to clear selected topics", http.StatusInternalServerError)
        return
    }
    tx.Commit()
    w.WriteHeader(http.StatusOK)
}

// In routes.go, under AdminMiddleware group:
r.Delete("/answers/me", DeleteMyAnswersHandler)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| answers in React state only | answers in localStorage + React state | This phase | Enables guest persistence |
| All routes behind ProtectedRoute | Guest-accessible routes open | This phase | AUTH-02 requirement |
| Register creates empty account | Register accepts + stores guest_state | This phase | AUTH-05 requirement |

**No deprecated APIs involved.** react-router v7, React 19, and framer-motion 12 are all current versions. No migration concerns.

---

## Open Questions

1. **Does AuthForm (ev-ui) support being rendered inside a modal?**
   - What we know: `AuthForm` is used in standalone `Register.jsx` and `Login.jsx` pages; it likely renders a full-page centered card layout.
   - What's unclear: Whether it accepts a `compact` prop or renders without the full-page wrapper — need to inspect the ev-ui source.
   - Recommendation: Check `/Users/chrisandrews/Documents/GitHub/ev-ui/` before building the inline registration modal. If `AuthForm` forces a full-page layout, build a minimal inline form instead (username + password inputs + submit button) that calls the same register flow. This is under "Claude's discretion" for styling.

2. **Does the SiteHeader from ev-ui accept a guest/login button slot?**
   - What we know: `Layout.jsx` passes `profileMenu={{ label: username, items: profileItems }}` to `SiteHeader`. When `username` is null, the label will be null.
   - What's unclear: How `SiteHeader` renders when `label` is null — whether it shows nothing or crashes.
   - Recommendation: Inspect ev-ui `SiteHeader` component before finalizing the guest indicator approach. May need to pass a fallback label like `"Guest"` or render a separate sign-in button alongside the header.

3. **`/auth/admin` vs `/auth/admin-check` discrepancy**
   - What we know: `IsAdmin.jsx` hook calls `/auth/admin`, but `auth/routes.go` registers the admin check at `/auth/admin-check`. `AdminRoute.jsx` correctly calls `/auth/admin-check`.
   - What's unclear: Whether `/auth/admin` exists (it does — it's the route that requires AdminMiddleware and returns 200 "Admin access granted"). So `IsAdmin` hook is actually calling the right thing through a different endpoint.
   - Recommendation: This is pre-existing; not a blocker for this phase. Note it for a future cleanup task.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — all file paths cited are real files read during research session
- `CompassV2/src/components/CompassContext.jsx` — localStorage pattern for selectedTopics (confirmed pattern to extend)
- `CompassV2/src/App.jsx` — complete route structure (confirmed all ProtectedRoute wrappings)
- `CompassV2/src/pages/Quiz.jsx` — confirmed answer POST behavior per question
- `CompassV2/src/pages/Compass.jsx` — confirmed answers/batch fetch pattern
- `CompassV2/src/components/Layout.jsx` — confirmed profileItems structure + isAdmin hook
- `EV-Backend/internal/auth/handlers.go` — confirmed RegisterHandler shape and LoginHandler behavior
- `EV-Backend/internal/compass/handlers.go` — confirmed SelectedTopicsHandler and answer handler patterns
- `EV-Backend/internal/compass/routes.go` — confirmed SessionMiddleware and AdminMiddleware groupings
- `EV-Backend/internal/compass/models.go` — confirmed Answer, UserCompass model shapes

### Secondary (MEDIUM confidence)
- `ev-ui AuthForm` usability inside a modal — inferred from Register.jsx usage; actual ev-ui source not read (flagged as Open Question 1)
- `SiteHeader` null-label behavior — inferred from Layout.jsx usage; actual ev-ui source not read (flagged as Open Question 2)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all libraries confirmed present in package.json
- Architecture: HIGH — all patterns derived from reading actual source files
- Backend changes: HIGH — handler shape follows established patterns in codebase; new code follows existing idioms
- Pitfalls: HIGH — all pitfalls derived from reading actual code paths and identifying the failure modes
- Open questions: MEDIUM — two ev-ui internal behaviors not confirmed; both have safe fallbacks documented

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable codebase; no fast-moving dependencies)
