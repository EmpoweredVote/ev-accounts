# Phase 7 Research: Integration Polish

## GAP-01: Library.jsx Batch Fetch 401 for Guests

**File:** `CompassV2/src/pages/Library.jsx` (lines ~146-185)

**Problem:** Second `useEffect` fires `POST /compass/answers/batch` without checking `isLoggedIn`. Guests get 401 console errors when toggling topics.

**Current code:**
```javascript
useEffect(() => {
  if (!selectedTopics.length || !topicsRef.current.length) return;
  // NO isLoggedIn guard here
  fetch(`${import.meta.env.VITE_API_URL}/compass/answers/batch`, {
    method: "POST",
    credentials: "include",
    ...
  })
}, [selectedTopics]);
```

**Fix:** Add `if (!isLoggedIn) return;` guard. `isLoggedIn` already destructured from `useCompass()` at line 65. Add to dependency array.

**Existing pattern:** First effect (line ~75-85) already guards with `if (!isLoggedIn) { /* localStorage path */ return; }`. The handleDrawerSelect (line ~256-270) also guards server saves with `if (isLoggedIn)`.

---

## GAP-02: Register.jsx Sign In Link Navigation

**File:** `CompassV2/src/pages/Register.jsx` (line ~92)

**Problem:** `onModeSwitch={() => navigate("/")}` sends user to Library page (`/` = Library route in App.jsx) instead of login page.

**Fix:** Change to `navigate("/login")`. This matches the Login.jsx pattern which uses `navigate("/register")` for its mode switch.

---

## GAP-03: Register.jsx buildGuestState() Race Condition

**File:** `CompassV2/src/pages/Register.jsx` (lines ~18-37)

**Problem:** `buildGuestState()` maps localStorage answers (keyed by `short_title`) to `topic_id` using `topics.find()`. If `topics` hasn't loaded from API yet (empty array), all `.find()` calls return null, answers are filtered out by `.filter(Boolean)`, and guest state is silently empty.

**Current code:**
```javascript
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
```

**Fix options:**
1. **Guard the submit handler** — if `topics.length === 0`, wait/retry or warn user
2. **Await topics before submitting** — disable register button until topics loaded (simplest)

**Topics lifecycle:** CompassContext fetches `/compass/topics` on mount via `refreshData()`. Register accesses via `useCompass()`. No guarantee topics load before form submit.

---

## RESEARCH COMPLETE
