---
id: 260412-lqd
name: Center calibration question title
mode: quick
must_haves:
  truths:
    - "Quiz full-mode question wrapper is horizontally centered"
    - "Quiz curated-mode question wrapper is horizontally centered"
    - "? icon remains vertically centered next to question text"
  artifacts:
    - "CompassV2/src/pages/Quiz.jsx"
  key_links:
    - "CompassV2/src/pages/Quiz.jsx:573"
    - "CompassV2/src/pages/Quiz.jsx:681"
---

# Quick Task 260412-lqd: Center calibration question title

## Goal

The `<h1>` + `?` icon flex wrapper in both calibration modes is stretching
full-width, causing the question to left-align while the category pill and
topic subtitle remain centered. Add `justify-center` to both wrappers.

## Tasks

### Task 1: Add `justify-center` to question flex wrappers in Quiz.jsx

**files:** `CompassV2/src/pages/Quiz.jsx`

**action:**
- Line 573 (full mode): change `className="flex items-center gap-2"` to
  `className="flex items-center justify-center gap-2"`
- Line 681 (curated mode): same change

**verify:**
- `grep -n 'flex items-center justify-center gap-2' CompassV2/src/pages/Quiz.jsx`
  returns 2 matches
- `grep -n 'flex items-center gap-2"' CompassV2/src/pages/Quiz.jsx` returns 0 matches
- `cd CompassV2 && npm run build` succeeds

**done:**
- Both flex wrappers have `justify-center`
- Build passes
