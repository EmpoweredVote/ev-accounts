---
status: diagnosed
phase: 04-compass-ux-enhancements
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md, 04-04-SUMMARY.md]
started: 2026-02-18T02:00:00Z
updated: 2026-02-18T02:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Admin TopicEditor question text field
expected: In the admin TopicEditor, open any topic for editing. A "Question" textarea (2 rows) appears between "Short Title" and "Stances" with placeholder text "What should the government do about...?". Below it is a "Level" dropdown with options: Not set, Federal, State, Local.
result: issue
reported: "An issue might apply to multiple levels. So some issues might be federal and state or federal, state, and local, etc. so it needs to be multiple choice"
severity: major

### 2. Admin save persists question text and level
expected: Type a question in the textarea (e.g., "What should the government do about healthcare?"), select a level (e.g., "Federal"), and click Save. Reopen the topic — the question text and level are still there.
result: issue
reported: "After I hit save, I don't see the changes reflected. When I go back to the editing topic, the question and level are reset and blank"
severity: major

### 3. Library cards show question text
expected: On the Library page, issue cards display question prompts as their primary text instead of bare short titles. If a topic has a question_text set via admin, that text appears. If not, it shows "What should the government do about {short_title}?"
result: pass

### 4. Library cards show level badges
expected: Cards for topics with a level set show a small icon + label badge at the bottom (e.g., a building icon with "Federal"). Cards with no level set show no badge — no empty space or placeholder.
result: skipped
reason: No topics have levels assigned yet — need to set levels via admin first (blocked by Test 2 save issue)

### 5. Library search matches question text
expected: Type part of a question text into the Library search bar. Cards matching that question text appear in results, even if the short_title doesn't match the search term.
result: pass

### 6. ComparePanel shows question header
expected: On the Library page, when a topic is selected and the ComparePanel is visible, a bold question text header appears above the stance list/legend. It shows the topic's question or the auto-generated fallback.
result: issue
reported: "the compare panel is not showing up. when I click on a topic, the page goes blank and this shows in the browser console: LibraryDrawer.jsx:61 Uncaught TypeError: Cannot read properties of null (reading 'map') at LibraryDrawer"
severity: blocker

### 7. Stance order is stable across reloads
expected: Open the quiz, note which stances appear in which order for a topic. Reload the page. The stance order is identical — stances that were flipped stay flipped, stances that were not stay the same.
result: issue
reported: "stances are not flipping at all"
severity: major

### 8. Stance order works in full quiz mode
expected: Switch to full quiz mode (all topics). Stances are randomized (some topics flipped, some not). The randomization is the same on every reload.
result: issue
reported: "same issue, not flipping"
severity: major

### 9. Library drawer opens on card click
expected: On the Library page, clicking an issue card opens a slide-in panel from the right side. The panel slides in with a smooth animation. The Library grid remains visible behind a semi-transparent backdrop.
result: skipped
reason: Blocked by Test 6 — LibraryDrawer crashes on card click

### 10. Library drawer shows question and stances
expected: The drawer shows the topic's short title at top, the question text below it (bold), and all stances as clickable buttons. If you have already answered this topic, your current answer is highlighted with a yellow border.
result: skipped
reason: Blocked by Test 6 — LibraryDrawer crashes on card click

### 11. Library drawer inline answer editing
expected: Click a different stance in the drawer. It immediately highlights with the yellow border (your new selection). The drawer stays open. Going back to the Library, the card reflects your updated answer (checkmark if newly answered).
result: skipped
reason: Blocked by Test 6 — LibraryDrawer crashes on card click

### 12. Library drawer close behavior
expected: Clicking the X button or clicking the semi-transparent backdrop closes the drawer with a smooth slide-out animation.
result: skipped
reason: Blocked by Test 6 — LibraryDrawer crashes on card click

## Summary

total: 12
passed: 2
issues: 5
pending: 0
skipped: 5

## Gaps

- truth: "Level selector allows multiple levels to be selected per topic (e.g., federal+state, federal+state+local)"
  status: failed
  reason: "User reported: An issue might apply to multiple levels. So some issues might be federal and state or federal, state, and local, etc. so it needs to be multiple choice"
  severity: major
  test: 1
  root_cause: "Level field is VARCHAR storing a single string. All layers (DB model, API handler, admin UI dropdown, Library badge) only support one value. Must change to pq.StringArray (text[]) in backend model, checkbox group in admin UI, and iterate array for badges."
  artifacts:
    - path: "EV-Backend/internal/compass/models.go"
      issue: "Level is plain string, needs pq.StringArray with gorm:type:text[]"
    - path: "EV-Backend/internal/compass/handlers.go"
      issue: "TopicUpdateHandler accepts *string for level, needs []string"
    - path: "CompassV2/src/components/admin/TopicEditor.jsx"
      issue: "Single-select dropdown, needs checkbox group"
    - path: "CompassV2/src/pages/Library.jsx"
      issue: "LEVEL_CONFIG lookup assumes single string, needs array iteration"
  missing:
    - "Change Level type to pq.StringArray in Topic model"
    - "Change TopicUpdateHandler to accept/persist []string"
    - "Replace dropdown with checkbox group in TopicEditor"
    - "Iterate level array for badge rendering in Library.jsx"
  debug_session: ".planning/debug/topic-level-multi-select.md"
- truth: "Saving question_text and level via admin TopicEditor persists the values — reopening the topic shows them"
  status: failed
  reason: "User reported: After I hit save, I don't see the changes reflected. When I go back to the editing topic, the question and level are reset and blank"
  severity: major
  test: 2
  root_cause: "TopicEditor handleSave PATCH response is never checked for ok status. If the request fails silently (auth, network, server error), the code continues, refreshData re-fetches old DB values, and edits appear to vanish. Secondary: optimistic setTopics only updates stances/categories via spread, omitting question_text/level from the explicit update."
  artifacts:
    - path: "CompassV2/src/components/admin/TopicEditor.jsx"
      issue: "PATCH response not checked for res.ok (line ~100); optimistic setTopics omits question_text/level (lines 150-162)"
  missing:
    - "Check res.ok after PATCH and throw/alert on failure"
    - "Add question_text, level, title, short_title to optimistic setTopics spread"
  debug_session: ".planning/debug/topic-editor-save-not-persisting.md"
- truth: "Clicking a Library card opens the drawer with question and stances without crashing"
  status: failed
  reason: "User reported: page goes blank — LibraryDrawer.jsx:61 Uncaught TypeError: Cannot read properties of null (reading 'map') at LibraryDrawer"
  severity: blocker
  test: 6
  root_cause: "/compass/categories backend endpoint preloads Topics but NOT Topics.Stances. Library.jsx passes category-embedded topic objects (stances=null) to setDrawerTopic. LibraryDrawer calls .map() on null stances."
  artifacts:
    - path: "EV-Backend/internal/compass/handlers.go"
      issue: "CategoryHandler (line 260) missing nested Preload('Topics.Stances')"
    - path: "CompassV2/src/pages/Library.jsx"
      issue: "Passes category-embedded topic (no stances) to setDrawerTopic instead of full topic from context"
    - path: "CompassV2/src/components/LibraryDrawer.jsx"
      issue: "No null guard on topic.stances before .map() or [...spread]"
  missing:
    - "Add Preload('Topics.Stances') to CategoryHandler OR look up full topic from topics array in Library.jsx"
    - "Add defensive null guard in LibraryDrawer: (topic.stances ?? [])"
  debug_session: ".planning/debug/library-drawer-null-map-crash.md"
- truth: "Stance randomization flips ~50% of topics so some stances appear in reversed order"
  status: failed
  reason: "User reported: stances are not flipping at all"
  severity: major
  test: 7
  root_cause: "Quiz.jsx rendering never consumes invertedSpokes to reorder stances. Line 346: `const ordered = currentTopic.stances` always uses original order. invertedSpokes is only passed to RadarChart for visual chart display — never used to reverse the stance button list."
  artifacts:
    - path: "CompassV2/src/pages/Quiz.jsx"
      issue: "Line 346 uses currentTopic.stances directly; lines 418-435 render without checking invertedSpokes"
  missing:
    - "Add inversion logic: const ordered = invertedSpokes[currentTopic.short_title] ? [...currentTopic.stances].reverse() : currentTopic.stances"
  debug_session: ".planning/debug/stance-randomization-not-flipping.md"
- truth: "Stance randomization works in full quiz mode — some topics flipped, stable across reloads"
  status: failed
  reason: "User reported: same issue, not flipping (same as test 7)"
  severity: major
  test: 8
  root_cause: "Same root cause as test 7 — Quiz.jsx never reverses stance display order based on invertedSpokes. Affects both curated and full modes equally."
  artifacts:
    - path: "CompassV2/src/pages/Quiz.jsx"
      issue: "Same as test 7"
  missing:
    - "Same fix as test 7"
  debug_session: ".planning/debug/stance-randomization-not-flipping.md"
