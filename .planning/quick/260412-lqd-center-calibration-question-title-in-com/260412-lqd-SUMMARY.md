---
name: 260412-lqd SUMMARY
description: Centered calibration question title wrapper in both quiz modes
type: quick-task-summary
---

# Quick Task 260412-lqd: Summary

## What Changed

`CompassV2/src/pages/Quiz.jsx` — added `justify-center` to the flex wrapper
around the question `<h1>` + `?` help-link icon in both calibration modes:

- Line 573: full mode
- Line 681: curated mode

## Root Cause

When the how-it-works page was added and the `?` help icon link was introduced
next to the question text, the `<h1>` was wrapped in a new flex container
(`flex items-center gap-2`) to align the icon beside it. That flex container
had no `justify-center`, so it stretched full-width inside the `text-center`
parent and left-aligned its flex children, while the category pill above and
the topic-name subtitle below (which are plain inline/block elements) remained
centered. Result: the question line looked off-center relative to everything
else.

## Fix

Added `justify-center` to both flex wrappers. The `?` icon remains vertically
centered (`items-center`) next to the question text and wraps correctly on
narrow screens.

## Verification

- `grep` confirms both wrappers now use `flex items-center justify-center gap-2`
- `cd CompassV2 && npm run build` succeeds (993ms)
