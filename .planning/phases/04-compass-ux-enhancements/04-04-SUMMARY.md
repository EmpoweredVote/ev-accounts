---
phase: 04-compass-ux-enhancements
plan: 04
subsystem: CompassV2 frontend
tags: [drawer, library, inline-editing, framer-motion, answer-saving]
dependency_graph:
  requires: [04-02, 04-03]
  provides: [library-drawer-inline-editing]
  affects: [CompassV2/src/pages/Library.jsx, CompassV2/src/components/LibraryDrawer.jsx]
tech_stack:
  added: []
  patterns: [framer-motion AnimatePresence, spring animation, drawer pattern]
key_files:
  created:
    - CompassV2/src/components/LibraryDrawer.jsx
  modified:
    - CompassV2/src/pages/Library.jsx
decisions:
  - "AnimatePresence wraps conditional children — no early return guard on LibraryDrawer to allow exit animation"
  - "Card click opens drawer (setDrawerTopic) instead of toggling compass topic selection"
  - "Drawer panel stays open after stance selection — no auto-close on answer"
  - "Stance order in drawer respects invertedSpokes from Plan 02 seeded randomization"
  - "handleDrawerSelect updates answeredTopicIDs locally to keep checkmark state in sync"
metrics:
  duration: 1 min
  completed_date: 2026-02-17
  tasks_completed: 2
  files_changed: 2
---

# Phase 04 Plan 04: Library Drawer Inline Answer Editing Summary

Slide-in drawer on Library cards allowing users to view and change their answers inline without navigating to the quiz, using Framer Motion spring animation and the same stance button UI as Quiz.jsx.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create LibraryDrawer.jsx slide-in panel | 5dcaf79 | CompassV2/src/components/LibraryDrawer.jsx |
| 2 | Wire drawer into Library.jsx with answer save logic | e38d304 | CompassV2/src/pages/Library.jsx |

## What Was Built

**LibraryDrawer.jsx** — New component providing:
- Slide-in panel from the right with spring animation (damping 30, stiffness 300)
- Semi-transparent backdrop (bg-black/20) that closes the drawer on click
- Header: topic short_title label + X close button
- Question text (from `question_text` field or fallback to "What should the government do about {short_title}?")
- Stance buttons with exact same styling as Quiz.jsx (`border-ev-yellow border-2 bg-ev-yellow-light` for selected)
- Stance order respects `invertedSpokes` (reversed when topic is flipped)
- Panel stays open after selecting a stance

**Library.jsx updates:**
- Added `LibraryDrawer` import
- Added `invertedSpokes` and `isLoggedIn` to useCompass destructure
- Added `drawerTopic` state (null = closed, topic object = open)
- Card `onClick` changed from `toggleTopic(topic.id)` to `setDrawerTopic(topic)` — cards now open the drawer
- Added `getAnswer(topic)` helper to look up current numeric answer for a topic
- Added `handleDrawerSelect(topic, stanceValue)` that:
  - Updates `answers` in context (auto-persists to localStorage)
  - Adds to `answeredTopicIDs` if first answer on this topic
  - POSTs to `/compass/answers` for logged-in users (fire-and-forget with silent catch)
- LibraryDrawer rendered at the bottom of the JSX return

## Deviations from Plan

None — plan executed exactly as written.

The plan noted the AnimatePresence guard issue upfront (warning against early return before AnimatePresence) and the implementation correctly moves the null guard inside the AnimatePresence wrapper.

## Self-Check: PASSED

- FOUND: CompassV2/src/components/LibraryDrawer.jsx
- FOUND: CompassV2/src/pages/Library.jsx
- FOUND: commit 5dcaf79 (feat(04-04): create LibraryDrawer slide-in panel component)
- FOUND: commit e38d304 (feat(04-04): wire LibraryDrawer into Library.jsx with answer save logic)
