# Phase 30: Fix Compass Calibration Flow Layout and Write-In Option - Research

**Researched:** 2026-02-22
**Domain:** React layout (Tailwind CSS 4), dnd-kit drag-and-drop, CalibrationOverlay component
**Confidence:** HIGH — all findings come directly from reading the existing codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Change from 60/40 split to 50/50 split (chart left, question + stances right)
- Question text and topic title must sit directly above the stances column, not centered across the full page width
- Radar chart vertically centers beside the stances column (stances take natural height, chart aligns to their center)
- Dead space between chart and stances must be eliminated — they should read as a unified pair
- Mobile: keep chart visible above stances in column layout (don't hide it)
- Use the same drag-and-drop approach as Quiz page (dnd-kit with PointerSensor + TouchSensor)
- "Write your own..." trigger button appears below all stance cards
- When write-in activates, chart stays visible in the 50/50 split — drag-and-drop list replaces the stances on the right
- Support both desktop and mobile (reuse existing touch sensor implementation from Quiz page)
- Data handling: same decimal positioning system (writeIns stored in CompassContext, synced to localStorage)

### Claude's Discretion

- Sticky vs scrolling header (topic pills + progress bar) — pick what works with new layout
- Exact chart sizing within the 50% column
- Transition animation when switching between stance mode and write-in mode
- Mobile chart size above stances

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

## Summary

Phase 30 is a surgical UI fix to one component: `CalibrationOverlay.jsx`. The answer step (`step === "answer"`) has two problems: (1) a layout issue where the question text floats centered over the full page instead of being anchored above the stances column, and (2) a missing write-in option that already exists in `Quiz.jsx` (curated mode) and `LibraryDrawer.jsx`.

The write-in implementation in `Quiz.jsx` is the canonical reference. It uses `SortableWriteInCard` and `SortableStanceLabel` components, a `DndContext` with `PointerSensor` + `TouchSensor`, and stores results in `CompassContext`'s `writeIns` state (keyed by `topic.short_title`, decimal value in `answers`). The `CalibrationOverlay` already imports `useCompass` and has access to `setAnswers`, `setWriteIns` (via context), and `invertedSpokes`. It currently does NOT destructure `writeIns` or `setWriteIns` from context — those need to be added.

The layout fix requires restructuring the answer step's JSX: move the question title block into the right-side column so it sits directly above the stances, change `md:basis-3/5` / `md:basis-2/5` to `md:basis-1/2` / `md:basis-1/2`, and use `items-center` on the left column so the chart vertically centers against the stances column height.

**Primary recommendation:** Restructure the answer step layout in one focused pass, then lift the write-in state and handlers from `Quiz.jsx` into `CalibrationOverlay.jsx` directly — no new components needed, just copy/adapt the existing pattern.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | ^19.1.0 | UI rendering | Project standard |
| Tailwind CSS | ^4.1.10 | Utility styling | Project standard via `@tailwindcss/vite` |
| @dnd-kit/core | ^6.3.1 | Drag-and-drop context + sensors | Already used in Quiz.jsx and LibraryDrawer.jsx |
| @dnd-kit/sortable | ^10.0.0 | Sortable list, `useSortable`, `SortableContext` | Already used |
| @dnd-kit/modifiers | ^9.0.0 | `restrictToVerticalAxis` | Already used |
| @dnd-kit/utilities | (peer) | `CSS.Translate.toString()` | Already used |

### No New Packages Required

All required packages are already installed. This phase is purely JSX + Tailwind edits.

---

## Architecture Patterns

### File to Modify

Single file: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/CalibrationOverlay.jsx`

No other files need to change. All write-in state lives in CompassContext (already shared), and the API call pattern for saving answers already exists in `handleSelectStance`.

### Existing Layout Structure (Current — Broken)

```
// Fixed overlay, flex column
<div className="fixed inset-0 z-50 bg-white overflow-y-auto flex flex-col min-h-screen">

  {/* Header: back btn + progress + view compass btn */}
  <div className="flex items-center justify-between px-4 pt-4 pb-2 shrink-0">

  {/* Topic pills — horizontal scroll strip */}
  <div className="flex gap-2 px-4 py-2 overflow-x-auto shrink-0">

  {/* Question title — PROBLEM: centered on full page width */}
  <div className="shrink-0 px-4 mt-2 mb-1 text-center">
    <p>...question text...</p>   ← floats over entire page
  </div>

  {/* Main content: chart (basis-3/5) + stances (basis-2/5) */}
  <div className="flex-1 flex flex-col md:flex-row md:pb-4">
    <div className="md:basis-3/5 flex justify-center px-2">   ← 60%
    <div className="md:basis-2/5 flex flex-col gap-3 px-4 ...">  ← 40%
  </div>

  {/* Footer */}
  <div className="sticky bottom-0 ...">
```

### Target Layout Structure (Fixed)

```
// Same outer wrapper
<div className="fixed inset-0 z-50 bg-white overflow-y-auto flex flex-col min-h-screen">

  {/* Header: keep as-is or make sticky */}
  <div className="...sticky top-0 bg-white ...">

  {/* Topic pills — keep as-is */}
  <div className="flex gap-2 px-4 py-2 overflow-x-auto shrink-0">

  {/* REMOVE the centered question title block from here */}

  {/* Main content: 50/50, items-start so columns define their own heights */}
  <div className="flex-1 flex flex-col md:flex-row">

    {/* LEFT: chart — takes 50%, chart vertically centers against right column */}
    <div className="md:basis-1/2 flex items-center justify-center px-2">
      <div className="w-full max-w-[400px] aspect-square">
        <RadarChart ... />
      </div>
    </div>

    {/* RIGHT: question title + stances, stacked in column */}
    <div className="md:basis-1/2 flex flex-col px-4 pb-4 md:py-4 md:pr-6">

      {/* Question title: now anchored above stances */}
      <div className="mb-3">
        <p className="text-xl md:text-2xl font-semibold">
          {getQuestionText(currentTopic) || parseTensionTitle(currentTopic).name}
        </p>
        {getQuestionText(currentTopic) && (
          <p className="text-base text-gray-500 font-normal mt-1">
            {parseTensionTitle(currentTopic).name}
          </p>
        )}
      </div>

      {/* Stances (or write-in DndContext) */}
      <div className="flex flex-col gap-3">
        {stanceContent}
      </div>
    </div>
  </div>

  {/* Footer: same sticky bottom nav */}
  <div className="sticky bottom-0 ...">
```

**Key change:** The question text block moves from being a sibling of the two-column area (where it spans full width) to being a child of the right column (where it's scoped above stances only).

### Chart Vertical Centering Pattern

The existing implementation uses `md:justify-center` on the stances column. The correct pattern for centering the chart against the stances column (which has natural/variable height) is:

```jsx
// Outer two-column flex: use items-stretch (default) so both columns fill the same height
<div className="flex-1 flex flex-col md:flex-row">

  // Left column: items-center vertically centers the chart within the shared row height
  <div className="md:basis-1/2 flex items-center justify-center px-2">
    <div className="w-full max-w-[400px] aspect-square">
      <RadarChart ... />
    </div>
  </div>

  // Right column: flex-col, no justify-center needed (stances stack naturally from top)
  <div className="md:basis-1/2 flex flex-col px-4 ...">
    {/* question title + stances */}
  </div>
</div>
```

This works because flex children default to `align-items: stretch` (both columns fill the container height), and then `items-center` on the left column vertically centers the chart within that stretched height.

### Write-In State Management (from Quiz.jsx)

The write-in pattern requires these local state variables in CalibrationOverlay:

```jsx
const [showWriteIn, setShowWriteIn] = useState(false);
const [writeInText, setWriteInText] = useState(false);
const [orderedItems, setOrderedItems] = useState([]);
const [hasRepositioned, setHasRepositioned] = useState(false);
```

And these must be added to the `useCompass()` destructure:

```jsx
const {
  // ... existing ...
  writeIns,        // ← ADD
  setWriteIns,     // ← ADD
} = useCompass();
```

`writeIns` is already in CompassContext (persisted to localStorage). No context changes needed.

### Write-In Sensors (copy from Quiz.jsx, lines 194-199)

```jsx
const sensors = useSensors(
  useSensor(PointerSensor, { activationConstraint: { distance: 3 } }),
  useSensor(TouchSensor, {
    activationConstraint: { delay: 150, tolerance: 5 },
  })
);
```

### Write-In Handlers (adapt from Quiz.jsx)

**`selectAnswer` in CalibrationOverlay uses a different pattern than Quiz.jsx** — the existing `handleSelectStance(value)` saves directly and makes an API call. The write-in path needs the same: save decimal value to `answers` and text to `writeIns`.

Key difference: CalibrationOverlay saves via `handleSelectStance` which posts to `/compass/answers`. For write-in, we need a parallel path that posts `write_in_text` alongside the decimal value.

```jsx
// New handler for write-in answer selection
const selectWriteInPlacement = (midpointValue) => {
  if (!currentTopic) return;
  setAnswers((prev) => ({ ...prev, [currentTopic.short_title]: midpointValue }));
  setWriteIns((prev) => ({ ...prev, [currentTopic.short_title]: writeInText }));
  setSelectedAnswer(midpointValue);
  if (isLoggedIn) {
    fetch(`${import.meta.env.VITE_API_URL}/compass/answers`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        topic_id: currentTopic.id,
        value: midpointValue,
        write_in_text: writeInText,
      }),
    }).catch(() => {});
  }
};

const handleDragEnd = ({ active, over }) => {
  if (!over || active.id === over.id) return;
  const oldIndex = orderedItems.indexOf(active.id);
  const newIndex = orderedItems.indexOf(over.id);
  const reordered = arrayMove(orderedItems, oldIndex, newIndex);
  setOrderedItems(reordered);
  setHasRepositioned(true);
  const writeInIndex = reordered.indexOf("write-in");
  selectWriteInPlacement(writeInIndex + 0.5);
};

const handleWriteInTextChange = (newText) => {
  setWriteInText(newText);
  if (selectedAnswer && !Number.isInteger(selectedAnswer)) {
    if (newText.trim()) {
      setWriteIns((prev) => ({ ...prev, [currentTopic.short_title]: newText }));
    } else {
      setSelectedAnswer(null);
      setAnswers((prev) => {
        const updated = { ...prev };
        delete updated[currentTopic.short_title];
        return updated;
      });
      setWriteIns((prev) => {
        const updated = { ...prev };
        delete updated[currentTopic.short_title];
        return updated;
      });
    }
  }
};

const handleCancelWriteIn = () => {
  setShowWriteIn(false);
  setWriteInText("");
  setOrderedItems([]);
  if (selectedAnswer && !Number.isInteger(selectedAnswer)) {
    setSelectedAnswer(null);
    setAnswers((prev) => {
      const updated = { ...prev };
      delete updated[currentTopic.short_title];
      return updated;
    });
    setWriteIns((prev) => {
      const updated = { ...prev };
      delete updated[currentTopic.short_title];
      return updated;
    });
  }
};
```

### `stanceContent` JSX (adapt from Quiz.jsx lines 413-487)

The `stanceContent` variable pattern from Quiz.jsx can be adopted directly. Replace the inline stance buttons in CalibrationOverlay's answer step with the same `stanceContent` block:

```jsx
const stanceContent = (
  <>
    {!showWriteIn ? (
      <>
        {orderedStances.map((stance, i) => {
          const stanceValue = i + 1;
          return (
            <button
              key={stance.id}
              onClick={() => {
                setShowWriteIn(false);
                setWriteInText("");
                handleSelectStance(stanceValue);
              }}
              className={`text-left px-4 py-3 rounded-lg transition-all duration-200 text-sm md:text-base font-medium cursor-pointer ${
                selectedAnswer === stanceValue
                  ? "border-ev-yellow border-2 bg-ev-yellow-light"
                  : "bg-white text-black border-2 border-gray-300 hover:bg-gray-50"
              }`}
            >
              {stance.text}
            </button>
          );
        })}
        <button
          onClick={() => {
            setShowWriteIn(true);
            setHasRepositioned(false);
            setOrderedItems([...orderedStances.map((s) => s.id), "write-in"]);
          }}
          className="text-left px-4 py-3 rounded-lg transition-all duration-200 text-sm md:text-base font-medium cursor-pointer border-2 border-dashed border-gray-400 text-gray-500 hover:border-ev-yellow hover:text-black"
        >
          Write your own...
        </button>
      </>
    ) : (
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        modifiers={[restrictToVerticalAxis]}
        onDragEnd={handleDragEnd}
      >
        <SortableContext items={orderedItems} strategy={verticalListSortingStrategy}>
          <div className="flex flex-col gap-3">
            {orderedItems.map((itemId) =>
              itemId === "write-in" ? (
                <SortableWriteInCard
                  key="write-in"
                  id="write-in"
                  text={writeInText}
                  onChange={handleWriteInTextChange}
                  onCancel={handleCancelWriteIn}
                  showHint={!!writeInText.trim() && !hasRepositioned}
                />
              ) : (
                <SortableStanceLabel
                  key={itemId}
                  id={itemId}
                  text={orderedStances.find((s) => s.id === itemId)?.text ?? ""}
                />
              )
            )}
          </div>
        </SortableContext>
      </DndContext>
    )}
  </>
);
```

### Reset Write-In State on Topic Change

When `currentIndex` changes (navigating between topics), write-in state needs to reset (or restore if the topic already has a write-in). The existing `useEffect` at line 138 handles the answer restoration. It needs to be extended:

```jsx
useEffect(() => {
  if (step !== "answer") return;
  const topicId = pickedTopics[currentIndex];
  const topic = topics.find((t) => t.id === topicId);
  if (!topic) return;
  const val = answers[topic.short_title];
  setSelectedAnswer(typeof val === "number" && val > 0 ? val : null);

  // Reset write-in state on topic change
  const savedWriteIn = writeIns?.[topic.short_title];
  if (savedWriteIn && val != null && !Number.isInteger(val)) {
    setShowWriteIn(true);
    setWriteInText(savedWriteIn);
    setHasRepositioned(true);
    const stanceIds = orderedStances.map((s) => s.id);  // careful: orderedStances is computed below
    const writeInIndex = Math.floor(val);
    const items = [...stanceIds];
    items.splice(writeInIndex, 0, "write-in");
    setOrderedItems(items);
  } else {
    setShowWriteIn(false);
    setWriteInText("");
    setOrderedItems([]);
    setHasRepositioned(false);
  }
}, [currentIndex, step, pickedTopics, topics, answers]);
```

**Note:** `orderedStances` is derived from `currentTopic` and `invertedSpokes` and is already computed in the component. The stances used to build `orderedItems` must use the SAME ordered list that the rendered stance buttons use (i.e., the flipped or non-flipped list). Check that the useEffect captures the right stances — may need to derive them inline within the effect rather than using the outer `orderedStances` variable (which is defined after the effect).

### Mobile Layout

The current mobile layout stacks vertically (chart on top, stances below), which is the correct behavior. The decision is to keep the chart visible above stances on mobile — no changes needed to the mobile column layout (`flex-col` default on small screens). The chart size on mobile is at Claude's discretion; a reasonable default is `max-w-[280px] md:max-w-[400px]` within the chart container.

### dnd-kit Imports

These imports are needed in CalibrationOverlay (currently absent, all present in Quiz.jsx and LibraryDrawer.jsx):

```jsx
import {
  DndContext,
  closestCenter,
  PointerSensor,
  TouchSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  SortableContext,
  useSortable,
  verticalListSortingStrategy,
  arrayMove,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { restrictToVerticalAxis } from "@dnd-kit/modifiers";
```

### SortableWriteInCard and SortableStanceLabel Components

These are currently defined locally in both `Quiz.jsx` and `LibraryDrawer.jsx` (duplicated). For this phase, define them locally in `CalibrationOverlay.jsx` as well — identical to the copies in the other files. Extracting them to a shared file is out of scope for this phase.

Both components are verbatim-copyable from `Quiz.jsx` lines 28-130.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Drag-to-position write-in | Custom drag logic | dnd-kit (`DndContext`, `useSortable`) | Already installed, proven in Quiz.jsx |
| Stance label (non-draggable) in dnd list | Static div | `SortableStanceLabel` with `disabled: { draggable: true }` | Makes label participate in drop target calculations without being draggable |
| Decimal position calculation | Custom math | `reordered.indexOf("write-in") + 0.5` | Midpoint between integer stances, same as Quiz.jsx |

---

## Common Pitfalls

### Pitfall 1: orderedStances reference in useEffect

**What goes wrong:** The `useEffect` that resets write-in state on topic change references `orderedStances`, but `orderedStances` is computed AFTER the effect declaration using `currentTopic`. If the effect runs before `currentTopic` is updated (different closure), the stances used to build `orderedItems` may be from the previous topic.

**How to avoid:** Inside the effect, derive stances directly from the topic found within the effect:

```jsx
useEffect(() => {
  if (step !== "answer") return;
  const topicId = pickedTopics[currentIndex];
  const topic = topics.find((t) => t.id === topicId);
  if (!topic) return;
  const val = answers[topic.short_title];
  setSelectedAnswer(typeof val === "number" && val > 0 ? val : null);

  const isFlippedInEffect = invertedSpokes[topic.short_title];
  const effectStances = topic.stances
    ? isFlippedInEffect ? [...topic.stances].reverse() : topic.stances
    : [];

  const savedWriteIn = writeIns?.[topic.short_title];
  if (savedWriteIn && val != null && !Number.isInteger(val)) {
    setShowWriteIn(true);
    setWriteInText(savedWriteIn);
    setHasRepositioned(true);
    const items = [...effectStances.map((s) => s.id)];
    items.splice(Math.floor(val), 0, "write-in");
    setOrderedItems(items);
  } else {
    setShowWriteIn(false);
    setWriteInText("");
    setOrderedItems([]);
    setHasRepositioned(false);
  }
}, [currentIndex, step, pickedTopics, topics, answers, writeIns, invertedSpokes]);
```

### Pitfall 2: selectedAnswer type for write-in

**What goes wrong:** `handleNext` / `handleFinish` check `selectedAnswer` truthiness to enable the Next/Finish button. A write-in sets `selectedAnswer` to a decimal (e.g., `1.5`), which is truthy. But the existing "is answered" check in `answeredCount` uses `val != null && val > 0` — decimals satisfy this. No issue here, but confirm `isFlipped` / `allRemainingAnswered` logic also works with decimals.

**How to avoid:** The existing answer checks (`val != null && val > 0`) already work with decimal values. No change needed. Just verify the Next button enables on write-in placement.

### Pitfall 3: 50/50 split on very small screens

**What goes wrong:** At 50% width on a small phone, the chart and stances column may both be cramped.

**How to avoid:** The 50/50 split is only applied at `md:` breakpoint and above. Below `md`, the layout stacks vertically (chart on top, stances below) — already the default `flex-col` behavior. Chart size should be constrained with `max-w-[280px]` or similar on mobile to avoid a huge chart crowding the stances.

### Pitfall 4: Sticky header conflicts with overflow-y-auto

**What goes wrong:** The overlay container uses `overflow-y-auto` and `flex flex-col`. A `sticky` child only sticks within its scroll container. If the sticky header is inside an `overflow-y-auto` container, it works. But if the topic pills strip also tries to be sticky, two sticky rows together may cause visual glitches.

**How to avoid:** Keep the header (back btn + progress + view compass btn) sticky. The topic pills can be sticky too — both are `shrink-0` and stack cleanly. Alternatively, keep topic pills as non-sticky (just part of normal flow). The scroll behavior inside `overflow-y-auto` on the whole overlay means both header and pills will scroll away on small screens — that may be fine for this phase.

### Pitfall 5: Write-in clearing on topic navigation

**What goes wrong:** If `showWriteIn` is `true` when navigating to next topic, the DndContext and stances from the OLD topic render briefly before the `useEffect` clears them.

**How to avoid:** The `useEffect` dependency array includes `currentIndex`, so it fires synchronously on the same render cycle that updates `currentIndex`. React batches state updates within event handlers — the `setCurrentIndex` call in `handleNext`/`handleBack` will trigger a re-render, and the effect fires after that render. This is acceptable — there's no stale frame issue in practice.

---

## Code Examples

### Current Answer Step Layout (Lines to Change)

Current structure in `CalibrationOverlay.jsx` (answer step, lines 498-636):

```jsx
// Line 499 — outer wrapper (keep)
<div className="fixed inset-0 z-50 bg-white overflow-y-auto flex flex-col min-h-screen">

  // Lines 501-536 — Header (keep, optionally make sticky)
  <div className="flex items-center justify-between px-4 pt-4 pb-2 shrink-0">

  // Lines 539-561 — Topic pills (keep)
  <div className="flex gap-2 px-4 py-2 overflow-x-auto shrink-0">

  // Lines 563-569 — Question title block: REMOVE FROM HERE
  <div className="shrink-0 px-4 mt-2 mb-1 text-center">

  // Lines 572-608 — Main content: RESTRUCTURE
  <div className="flex-1 flex flex-col md:flex-row md:pb-4">
    <div className="md:basis-3/5 ...">  ← change to md:basis-1/2
    <div className="md:basis-2/5 ...">  ← change to md:basis-1/2, ADD question title here
  </div>
```

### dnd-kit Decimal Position Pattern (from Quiz.jsx)

```jsx
// On drag end:
const writeInIndex = reordered.indexOf("write-in");
selectWriteInPlacement(writeInIndex + 0.5);  // 0.5 = between stance 0 and 1

// Value semantics:
// 0.5 = before first stance (between nothing and stance 1)
// 1.5 = between stance 1 and stance 2
// N.5 = between stance N and stance N+1
// Integer values (1, 2, 3...) = regular stance picks
```

### CompassContext write-in Data Flow

```
User types write-in text → setWriteInText (local state)
User drags to position → handleDragEnd
  → arrayMove reorders items
  → setHasRepositioned(true)
  → selectWriteInPlacement(decimal)
    → setAnswers({ [topic.short_title]: decimal })   ← in context, persisted to localStorage
    → setWriteIns({ [topic.short_title]: text })     ← in context, persisted to localStorage
    → setSelectedAnswer(decimal)                      ← local state
    → POST /compass/answers { value: decimal, write_in_text: text }  ← if logged in
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| 60/40 chart/stance split | 50/50 split (this phase) | Chart doesn't dominate; stances have more breathing room |
| Question text centered on full page | Question above stances column | Reads as a unified question+answer unit |
| No write-in in calibration | Write-in via dnd-kit (this phase) | Calibration parity with Quiz/Library features |

---

## Open Questions

1. **Header sticky behavior**
   - What we know: Current header is `shrink-0` but not explicitly `sticky`. Works fine because the overlay itself is `overflow-y-auto flex flex-col` and header is at top.
   - What's unclear: Whether topic pills should also be sticky or scroll with content. On mobile, having 2 sticky rows may eat too much vertical space.
   - Recommendation: Make the progress row (back btn + progress bar + view compass) sticky (`sticky top-0 bg-white z-10`); let topic pills scroll naturally. Revisit if it looks bad during implementation.

2. **Right column overflow on mobile with write-in**
   - What we know: When write-in is active, the DndContext list can be taller than stance buttons.
   - What's unclear: Whether the right column in the 50/50 layout needs `overflow-y-auto` on desktop when there are many stances + write-in card.
   - Recommendation: Add `md:overflow-y-auto` to the right column as a safety valve, keeping the chart fixed height alongside a scrollable stances column.

3. **Write-in save on CalibrationOverlay exit mid-flow**
   - What we know: `handleExitDuringAnswer` and `handleFinish` remove unanswered topics. If write-in is active but not positioned yet (`showWriteIn === true` but `selectedAnswer` is still null/integer), the write-in won't count as answered.
   - What's unclear: Should the "Write your own..." activation itself count as a pending answer?
   - Recommendation: No — match Quiz.jsx behavior exactly. Write-in only counts as answered when positioned (decimal value in `answers`). The `writeInText` alone without placement is not a valid answer.

---

## Sources

### Primary (HIGH confidence)

- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/CalibrationOverlay.jsx` — Full source of component to modify
- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Quiz.jsx` — Canonical write-in implementation (SortableWriteInCard, SortableStanceLabel, sensors, handlers)
- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/LibraryDrawer.jsx` — Secondary write-in implementation (confirms pattern consistency)
- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/CompassContext.jsx` — Context shape; `writeIns`, `setWriteIns` confirmed present and localStorage-persisted
- `/Users/chrisandrews/Documents/GitHub/CompassV2/package.json` — Confirmed @dnd-kit/core ^6.3.1, @dnd-kit/sortable ^10.0.0, @dnd-kit/modifiers ^9.0.0 already installed
- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/index.css` — Tailwind 4 theme; confirmed `ev-yellow`, `ev-yellow-light`, `ev-coral`, `ev-muted-blue` custom colors

---

## Metadata

**Confidence breakdown:**
- Layout fix: HIGH — problem and solution are directly readable from the JSX
- Write-in implementation: HIGH — exact pattern exists in Quiz.jsx, copy/adapt with minor adjustments
- dnd-kit behavior: HIGH — library already used and working in this project
- Edge cases (write-in on navigate, exit): MEDIUM — logic matches Quiz.jsx, but CalibrationOverlay has unique navigation (index-hopping via pills, skip) that needs testing

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (stable codebase; no library upgrades expected)
