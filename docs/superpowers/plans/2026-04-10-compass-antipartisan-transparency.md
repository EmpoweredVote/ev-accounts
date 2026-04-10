# Compass Antipartisan Transparency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a `/how-it-works` page on CompassV2 explaining the compass's antipartisan design choices, and surface it via a persistent entry point, a new onboarding coach-mark step, and two contextual "?" info icons on the Quiz and Compass pages.

**Architecture:**
1. New `HowItWorks.jsx` page wrapped in the existing `Layout`, with six anchor-linked sections and two static inline SVG visuals.
2. New `/how-it-works` route in `App.jsx`; the stale `/help → /results` redirect is repointed to `/how-it-works`.
3. The existing persistent bottom-right **?** button in `Layout.jsx` is repurposed from the dead `/help` redirect to navigate to `/how-it-works` — this replaces the "footer link" from the spec because CompassV2 has no footer, and this button is already a circled "?" on every page. (Spec deviation noted; functionally equivalent.)
4. A new coach-mark step (step 4 of 4) is added to the existing post-calibration tour in `Compass.jsx`, targeting the radar chart container. Its tooltip includes a link that opens `/how-it-works#compass-positions` in a new tab without advancing or dismissing the tour.
5. Two inline SVG "?" info icons — one on `Quiz.jsx` next to the topic question header, one on `Compass.jsx` next to the radar chart — each an anchor (`<a target="_blank" rel="noopener">`) to the relevant `/how-it-works` section.

**Tech Stack:** React 19, Vite 6, Tailwind CSS 4, `react-router`, existing `CoachMark` component, existing `Layout` component. No new dependencies. No backend changes.

**Testing approach:** CompassV2 has no test runner (`package.json` has no `test` script, no vitest/jest). Verification is done via `npm run build` (type/import sanity) and `npm run dev` (manual visual check of each surface). Each task ends with an explicit manual verification step and a commit.

---

## File structure

### New files

- `CompassV2/src/pages/HowItWorks.jsx` — the transparency page. Single responsibility: render the six sections with inline SVG visuals. No data fetching, no context, no router hooks beyond the ones needed for anchor scrolling.

### Modified files

- `CompassV2/src/App.jsx` — add `/how-it-works` route; repoint `/help` redirect target.
- `CompassV2/src/components/Layout.jsx` — change the existing help button's `navigate("/help")` call to `navigate("/how-it-works")` and update `title`/`aria-label`.
- `CompassV2/src/pages/Quiz.jsx` — add a "?" info anchor next to the topic question header.
- `CompassV2/src/pages/Compass.jsx` — add a "?" info anchor next to the radar chart, and add a 4th step to the post-calibration tour.

No changes to `ev-ui`, no changes to the backend, no changes to `CoachMark.jsx`, no changes to the randomization logic.

---

## Task 1: Create the `HowItWorks` page component

**Files:**
- Create: `CompassV2/src/pages/HowItWorks.jsx`

- [ ] **Step 1: Create the page file with all six sections and both visuals**

Create `CompassV2/src/pages/HowItWorks.jsx` with the following exact contents:

```jsx
import { useEffect } from "react";
import { useLocation } from "react-router";
import Layout from "../components/Layout";

/**
 * HowItWorks — transparency page explaining the Compass's antipartisan design choices.
 * Reached from the persistent help button in Layout, from the final step of the
 * post-calibration tour, and from contextual "?" icons on the Quiz and Compass pages.
 */
export default function HowItWorks() {
  const location = useLocation();

  // When navigated to with a hash (e.g. /how-it-works#compass-positions),
  // scroll the target section into view after the page mounts.
  useEffect(() => {
    if (location.hash) {
      const el = document.querySelector(location.hash);
      if (el) {
        // Delay slightly so layout settles before scrolling
        setTimeout(() => el.scrollIntoView({ behavior: "smooth", block: "start" }), 50);
      }
    } else {
      window.scrollTo({ top: 0 });
    }
  }, [location.hash]);

  return (
    <Layout>
      <article className="max-w-[720px] mx-auto px-6 py-10 text-gray-800 leading-relaxed">
        <header className="mb-10">
          <h1 className="text-3xl md:text-4xl font-semibold text-[#00657c] mb-3">
            How the Compass Works
          </h1>
          <p className="text-lg text-gray-600">
            Our approach to helping you think about politics without taking sides.
          </p>
        </header>

        <section id="spectrum-direction" className="mb-10 scroll-mt-24">
          <h2 className="text-2xl font-semibold text-[#00657c] mb-3">
            Why stances don't always run the same direction
          </h2>
          <p className="mb-4">
            Most topics have a natural spectrum of policy positions — often something
            like more-government-intervention on one end and less on the other. We keep
            the stances in their spectrum order (so neighboring positions stay
            neighbors), but we <strong>randomly flip the direction</strong> each time.
            Sometimes the spectrum runs one way, sometimes the other.
          </p>
          <p className="mb-6">
            Why? Because consistently putting one "side" at the top — even if
            unintentional — quietly tells users which answers are the "default" or
            "first" ones. Flipping the direction breaks that signal without scrambling
            the stances into nonsense.
          </p>

          <figure className="my-6 border border-gray-200 rounded-xl p-5 bg-gray-50">
            <svg
              viewBox="0 0 520 180"
              role="img"
              aria-labelledby="spectrum-diagram-title spectrum-diagram-desc"
              className="w-full h-auto"
            >
              <title id="spectrum-diagram-title">
                Same answer, two possible spectrum orientations
              </title>
              <desc id="spectrum-diagram-desc">
                Two horizontal spectrums showing the same five policy positions. In the
                top spectrum the direction runs left to right; in the bottom spectrum it
                runs right to left. The same user pick lands at different positions.
              </desc>

              {/* Top spectrum: left to right */}
              <g transform="translate(20, 30)">
                <line x1="0" y1="20" x2="480" y2="20" stroke="#00657c" strokeWidth="2" />
                {[0, 1, 2, 3, 4].map((i) => (
                  <circle
                    key={`top-${i}`}
                    cx={i * 120}
                    cy="20"
                    r="8"
                    fill={i === 3 ? "#ff5740" : "#ffffff"}
                    stroke="#00657c"
                    strokeWidth="2"
                  />
                ))}
                <text x="0" y="50" fontSize="12" fill="#6b7280">Position 1</text>
                <text x="440" y="50" fontSize="12" fill="#6b7280">Position 5</text>
                <text x="360" y="5" fontSize="11" fill="#ff5740" fontWeight="600">
                  ← your pick
                </text>
              </g>

              {/* Bottom spectrum: right to left (reversed) */}
              <g transform="translate(20, 110)">
                <line x1="0" y1="20" x2="480" y2="20" stroke="#00657c" strokeWidth="2" />
                {[0, 1, 2, 3, 4].map((i) => (
                  <circle
                    key={`bot-${i}`}
                    cx={i * 120}
                    cy="20"
                    r="8"
                    fill={i === 1 ? "#ff5740" : "#ffffff"}
                    stroke="#00657c"
                    strokeWidth="2"
                  />
                ))}
                <text x="0" y="50" fontSize="12" fill="#6b7280">Position 5</text>
                <text x="440" y="50" fontSize="12" fill="#6b7280">Position 1</text>
                <text x="80" y="5" fontSize="11" fill="#ff5740" fontWeight="600">
                  ← your pick
                </text>
              </g>
            </svg>
            <figcaption className="text-sm text-gray-600 mt-3 text-center italic">
              Same answer, two possible orientations. That's why your compass shape isn't
              a partisan score.
            </figcaption>
          </figure>
        </section>

        <section id="compass-positions" className="mb-10 scroll-mt-24">
          <h2 className="text-2xl font-semibold text-[#00657c] mb-3">
            Why your compass positions may look counterintuitive
          </h2>
          <p className="mb-4">
            Because each topic's spectrum direction is randomly flipped, a position
            that's "far from the center" on one topic might be "close to the center" on
            another — even if they represent the same kind of policy view. The same
            liberal-leaning or conservative-leaning answer can land in very different
            spots depending on which way that topic's spectrum happened to be pointing.
          </p>
          <p>
            So if your compass shape looks scattered or lopsided, that's expected. The
            shape is a reflection of your specific answers combined with randomized
            spectrum directions — not a partisan score.
          </p>
        </section>

        <section id="no-parties-no-colors" className="mb-10 scroll-mt-24">
          <h2 className="text-2xl font-semibold text-[#00657c] mb-3">
            We don't show parties or use red and blue
          </h2>
          <p className="mb-4">
            We deliberately hide political party affiliation throughout the compass. We
            don't use red, blue, or any partisan color coding. The goal is to help you
            evaluate policy positions on their merits, not on which team they belong to.
          </p>
          <p>
            This isn't about pretending parties don't exist. It's about asking you to
            decide what you think before you see the label.
          </p>
        </section>

        <section id="topic-selection" className="mb-10 scroll-mt-24">
          <h2 className="text-2xl font-semibold text-[#00657c] mb-3">
            How we pick topics
          </h2>
          <p className="mb-4">
            Topics are chosen for civic importance, not for balance theater. We don't
            artificially pair a "liberal topic" with a "conservative topic" to look
            even-handed. Many important issues don't even fit cleanly on a left–right
            axis.
          </p>
          <p>
            If a topic seems missing or unfairly framed, tell us. The topic list is
            meant to grow.
          </p>
        </section>

        <section id="reading-the-radar" className="mb-10 scroll-mt-24">
          <h2 className="text-2xl font-semibold text-[#00657c] mb-3">
            How to read the radar chart
          </h2>
          <p className="mb-4">
            Each spoke is a topic. Your dot on that spoke shows which policy position
            you picked along that topic's spectrum. Distance from the center tells you
            where your answer sits on <em>that topic's</em> spectrum — but since we flip
            spectrum directions randomly, you can't compare distances across topics and
            read a left/right meaning into the overall shape.
          </p>
          <p className="mb-6">
            Use the compass to compare yourself with politicians topic by topic, not as
            a single "score."
          </p>

          <figure className="my-6 border border-gray-200 rounded-xl p-5 bg-gray-50">
            <svg
              viewBox="0 0 320 280"
              role="img"
              aria-labelledby="radar-diagram-title radar-diagram-desc"
              className="w-full h-auto max-w-[360px] mx-auto block"
            >
              <title id="radar-diagram-title">Annotated radar chart reference</title>
              <desc id="radar-diagram-desc">
                A small radar chart with five spokes labeled as topics. Dots mark example
                picks on each spoke. Callouts indicate that each spoke is a topic and
                each dot is a pick, but that distances cannot be compared across spokes.
              </desc>

              {/* Center point */}
              <g transform="translate(160, 130)">
                {/* Concentric rings */}
                {[30, 60, 90].map((r) => (
                  <circle key={r} cx="0" cy="0" r={r} fill="none" stroke="#e5e7eb" strokeWidth="1" />
                ))}
                {/* 5 spokes */}
                {[0, 1, 2, 3, 4].map((i) => {
                  const angle = (2 * Math.PI * i) / 5 - Math.PI / 2;
                  const x = 90 * Math.cos(angle);
                  const y = 90 * Math.sin(angle);
                  return (
                    <line
                      key={`spoke-${i}`}
                      x1="0"
                      y1="0"
                      x2={x}
                      y2={y}
                      stroke="#9ca3af"
                      strokeWidth="1"
                    />
                  );
                })}
                {/* Sample filled shape */}
                <polygon
                  points={[0.8, 0.4, 0.6, 0.9, 0.3]
                    .map((v, i) => {
                      const angle = (2 * Math.PI * i) / 5 - Math.PI / 2;
                      return `${90 * v * Math.cos(angle)},${90 * v * Math.sin(angle)}`;
                    })
                    .join(" ")}
                  fill="#00657c"
                  fillOpacity="0.15"
                  stroke="#00657c"
                  strokeWidth="2"
                />
                {/* Sample dots */}
                {[0.8, 0.4, 0.6, 0.9, 0.3].map((v, i) => {
                  const angle = (2 * Math.PI * i) / 5 - Math.PI / 2;
                  return (
                    <circle
                      key={`dot-${i}`}
                      cx={90 * v * Math.cos(angle)}
                      cy={90 * v * Math.sin(angle)}
                      r="4"
                      fill="#ff5740"
                    />
                  );
                })}
              </g>

              {/* Callout: each spoke = a topic */}
              <text x="10" y="20" fontSize="11" fill="#374151">
                each spoke = a topic
              </text>
              <line x1="75" y1="23" x2="140" y2="55" stroke="#9ca3af" strokeWidth="1" />

              {/* Callout: dot = your pick */}
              <text x="220" y="20" fontSize="11" fill="#374151">
                dot = your pick
              </text>
              <line x1="240" y1="23" x2="200" y2="80" stroke="#9ca3af" strokeWidth="1" />

              {/* Callout: distance within one spoke is meaningful */}
              <text x="10" y="260" fontSize="11" fill="#374151">
                distances within a spoke = meaningful
              </text>
              <text x="10" y="274" fontSize="11" fill="#374151">
                distances across spokes = not comparable
              </text>
            </svg>
            <figcaption className="text-sm text-gray-600 mt-3 text-center italic">
              Each spoke is a topic. Each dot is your pick. Compare your shape with a
              politician's, topic by topic.
            </figcaption>
          </figure>
        </section>

        <section id="our-commitment" className="mb-10 scroll-mt-24">
          <h2 className="text-2xl font-semibold text-[#00657c] mb-3">
            Our antipartisan commitment
          </h2>
          <p className="mb-4">
            The Empowered Vote Compass exists to help you think, not to tell you what to
            think. We don't boost parties, we don't encode partisan assumptions into the
            visuals, and we try to be transparent about every design choice that could
            tilt the result.
          </p>
          <p>
            We're not perfect — bias creeps in. If something on the compass feels skewed
            or off, we want to hear about it. Transparency is our best defense against
            the biases we haven't noticed yet.
          </p>
        </section>
      </article>
    </Layout>
  );
}
```

- [ ] **Step 2: Verify the file compiles with `npm run build`**

Run:
```bash
cd CompassV2&& npm run build
```
Expected: Build succeeds with no errors. (The page isn't routed yet, so it won't be reachable in the dev server until Task 2.)

- [ ] **Step 3: Commit**

```bash
git add CompassV2/src/pages/HowItWorks.jsx
git commit -m "feat(compass): add HowItWorks transparency page"
```

---

## Task 2: Wire the `/how-it-works` route and repoint `/help`

**Files:**
- Modify: `CompassV2/src/App.jsx`

- [ ] **Step 1: Import `HowItWorks` and add the route**

In `CompassV2/src/App.jsx`, add this import with the other page imports near the top of the file:

```jsx
import HowItWorks from "./pages/HowItWorks";
```

- [ ] **Step 2: Add `/how-it-works` to the `GUARD_BYPASS` array**

Find the existing line:
```jsx
const GUARD_BYPASS = ["/help", "/login", "/register", "/admin", "/401", "/results"];
```

Replace it with:
```jsx
const GUARD_BYPASS = ["/help", "/how-it-works", "/login", "/register", "/admin", "/401", "/results"];
```

This ensures users can reach the page without being redirected by `HelpGuard` when calibration isn't done.

- [ ] **Step 3: Add the `/how-it-works` route and repoint the stale `/help` redirect**

Find the existing line:
```jsx
<Route path="/help" element={<Navigate to="/results" replace />} />
```

Replace it with:
```jsx
<Route path="/help" element={<Navigate to="/how-it-works" replace />} />
<Route path="/how-it-works" element={<HowItWorks />} />
```

The new route is public (no `HelpGuard` wrapper) because it's already in `GUARD_BYPASS` and because it's a content page that should be reachable from any state — including when the user arrives via the in-tour link in a new tab.

- [ ] **Step 4: Verify build and dev server**

Run:
```bash
cd CompassV2 && npm run build
```
Expected: Build succeeds.

Then run:
```bash
cd CompassV2 && npm run dev
```
In a browser, navigate to `http://localhost:<port>/how-it-works`. Expected: the page renders with all six sections, both SVG diagrams, and the header/subhead. Navigate to `http://localhost:<port>/how-it-works#compass-positions` — page should scroll to Section 2. Stop the dev server after verifying.

- [ ] **Step 5: Commit**

```bash
git add CompassV2/src/App.jsx
git commit -m "feat(compass): route /how-it-works and repoint /help"
```

---

## Task 3: Repurpose the persistent help button in `Layout.jsx`

**Files:**
- Modify: `CompassV2/src/components/Layout.jsx`

- [ ] **Step 1: Update the help button to navigate to `/how-it-works`**

Find the existing help button in `CompassV2/src/components/Layout.jsx` (around lines 99–109):

```jsx
      {/* Help button — always visible */}
      <button
        onClick={() => navigate("/help")}
        className="fixed bottom-4 right-4 z-40 w-9 h-9 rounded-full bg-white border border-gray-300 shadow-md flex items-center justify-center text-gray-500 hover:text-[#00657c] hover:border-[#00657c] transition-colors cursor-pointer"
        title="Help & walkthrough"
        aria-label="Help"
      >
```

Replace with:

```jsx
      {/* How It Works button — always visible */}
      <button
        onClick={() => navigate("/how-it-works")}
        className="fixed bottom-4 right-4 z-40 w-9 h-9 rounded-full bg-white border border-gray-300 shadow-md flex items-center justify-center text-gray-500 hover:text-[#00657c] hover:border-[#00657c] transition-colors cursor-pointer"
        title="How the Compass works"
        aria-label="How the Compass works"
      >
```

Do not change the SVG or the button position — only the `onClick`, `title`, `aria-label`, and the comment.

- [ ] **Step 2: Verify build and dev server**

Run:
```bash
cd CompassV2 && npm run build
```
Expected: Build succeeds.

Run the dev server, load any page (e.g. `/library`), and click the circled "?" button in the bottom-right. Expected: navigation to `/how-it-works`. Hover over the button — tooltip reads "How the Compass works". Stop the dev server.

- [ ] **Step 3: Commit**

```bash
git add CompassV2/src/components/Layout.jsx
git commit -m "feat(compass): repurpose persistent help button for /how-it-works"
```

---

## Task 4: Add "?" info icon on `Quiz.jsx` next to the topic question header

**Files:**
- Modify: `CompassV2/src/pages/Quiz.jsx`

- [ ] **Step 1: Add the info icon next to the topic question header**

In `CompassV2/src/pages/Quiz.jsx`, there are two `<h1>` elements rendering the topic question: around line 573 and around line 667. Both look like:

```jsx
<h1 className="text-xl md:text-2xl font-semibold">{question || topicName}</h1>
```

Replace **each** of the two occurrences with:

```jsx
<div className="flex items-center gap-2">
  <h1 className="text-xl md:text-2xl font-semibold">{question || topicName}</h1>
  <a
    href="/how-it-works#spectrum-direction"
    target="_blank"
    rel="noopener"
    title="Why is the order of stances not fixed?"
    aria-label="Why is the stance order not fixed? Opens explanation in a new tab."
    className="flex-shrink-0 w-6 h-6 rounded-full text-gray-400 hover:text-[#00657c] transition-colors inline-flex items-center justify-center"
  >
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5">
      <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM8.94 6.94a.75.75 0 11-1.061-1.061 3 3 0 112.871 5.026v.345a.75.75 0 01-1.5 0v-.5c0-.72.57-1.172 1.081-1.287A1.5 1.5 0 108.94 6.94zM10 15a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
    </svg>
  </a>
</div>
```

Both occurrences get the identical replacement — they represent the same UI header in two render branches.

- [ ] **Step 2: Verify build and dev server**

Run:
```bash
cd CompassV2 && npm run build
```
Expected: Build succeeds.

Run the dev server, walk through calibration (or load an existing quiz state), and navigate to the Quiz. Expected: a small circled "?" icon appears to the right of the topic question header. Hovering shows the tooltip "Why is the order of stances not fixed?". Clicking opens `/how-it-works#spectrum-direction` in a new tab. The current Quiz page stays where it was. Stop the dev server.

- [ ] **Step 3: Commit**

```bash
git add CompassV2/src/pages/Quiz.jsx
git commit -m "feat(compass): add antipartisan info icon to quiz question header"
```

---

## Task 5: Add "?" info icon on `Compass.jsx` next to the radar chart

**Files:**
- Modify: `CompassV2/src/pages/Compass.jsx`

- [ ] **Step 1: Locate the radar chart container and add the info icon adjacent to it**

Open `CompassV2/src/pages/Compass.jsx`. The radar chart container uses `chartContainerRef` (declared around line 407). Find the JSX element that uses `ref={chartContainerRef}`. Immediately after that element's opening tag (or inside it, at the very top), add an absolutely-positioned info anchor so it floats in the top-right corner of the chart container without disturbing the existing layout.

First, confirm the container has `relative` positioning — if it does not already use `className="... relative ..."`, add `relative` to its classes. Then insert the following JSX as the first child of the chart container:

```jsx
<a
  href="/how-it-works#compass-positions"
  target="_blank"
  rel="noopener"
  title="How do I read this?"
  aria-label="How to read the compass. Opens explanation in a new tab."
  className="absolute top-2 right-2 z-10 w-7 h-7 rounded-full bg-white/80 backdrop-blur-sm border border-gray-200 text-gray-400 hover:text-[#00657c] hover:border-[#00657c] transition-colors inline-flex items-center justify-center"
>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM8.94 6.94a.75.75 0 11-1.061-1.061 3 3 0 112.871 5.026v.345a.75.75 0 01-1.5 0v-.5c0-.72.57-1.172 1.081-1.287A1.5 1.5 0 108.94 6.94zM10 15a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
  </svg>
</a>
```

The semi-transparent white background keeps the icon legible over whatever pixels the chart draws underneath.

- [ ] **Step 2: Verify build and dev server**

Run:
```bash
cd CompassV2 && npm run build
```
Expected: Build succeeds.

Run the dev server and navigate to `/results` (the Compass page). Expected: a small circled "?" icon in the top-right corner of the radar chart area. Hovering shows "How do I read this?". Clicking opens `/how-it-works#compass-positions` in a new tab. Stop the dev server.

- [ ] **Step 3: Commit**

```bash
git add CompassV2/src/pages/Compass.jsx
git commit -m "feat(compass): add antipartisan info icon to radar chart"
```

---

## Task 6: Add step 4 to the post-calibration coach-mark tour

**Files:**
- Modify: `CompassV2/src/pages/Compass.jsx`

- [ ] **Step 1: Extend `tourMessages` with the new step**

In `CompassV2/src/pages/Compass.jsx`, find the `tourMessages` array (around lines 379–383):

```jsx
  const tourMessages = [
    "Tap any spoke label to flip its direction — this only changes the visual layout, not your actual stance",
    "See how your views line up with a politician",
    "Add or change topics anytime from the Library",
  ];
```

Replace with:

```jsx
  const tourMessages = [
    "Tap any spoke label to flip its direction — this only changes the visual layout, not your actual stance",
    "See how your views line up with a politician",
    "Add or change topics anytime from the Library",
    (
      <>
        Your compass may look scattered — that's intentional. We randomize stance spectrum direction and don't encode left/right on the chart, so the shape isn't a partisan score.{" "}
        <a
          href="/how-it-works#compass-positions"
          target="_blank"
          rel="noopener"
          className="text-[#00657c] underline hover:text-[#ff5740]"
          onClick={(e) => e.stopPropagation()}
        >
          Want the full story?
        </a>
      </>
    ),
  ];
```

Note: `CoachMark` renders `message` as its content via `{content}` (see `CoachMark.jsx:244, 397–399`), so React nodes are accepted — strings and JSX both work in the same array.

- [ ] **Step 2: Update `advanceTour` to allow step 3 (the new final step)**

Find the existing `advanceTour` function (around lines 386–394):

```jsx
  const advanceTour = () => {
    if (tourStep < 2) {
      setTourStep(tourStep + 1);
    } else {
      // Final step — dismiss
      localStorage.setItem("onboarding_postCalTour", "1");
      setTourStep(-1);
    }
  };
```

Replace with:

```jsx
  const advanceTour = () => {
    if (tourStep < 3) {
      setTourStep(tourStep + 1);
    } else {
      // Final step — dismiss
      localStorage.setItem("onboarding_postCalTour", "1");
      setTourStep(-1);
    }
  };
```

Only the `< 2` → `< 3` change. The dismissal logic stays the same.

- [ ] **Step 3: Update the `CoachMark` render block to handle step 3 and show "4 of 4"**

Find the post-calibration tour render block (around lines 891–907):

```jsx
      {tourStep >= 0 && (
        <CoachMark
          targetRef={
            tourStep === 0 ? spokeRef
            : tourStep === 1 ? compareRef
            : backToLibRef
          }
          message={tourMessages[tourStep]}
          stepLabel={`${tourStep + 1} of 3`}
          onNext={advanceTour}
          onSkipAll={skipTour}
          onDismiss={advanceTour}
          show={true}
          allowSpotlightInteraction={tourStep === 0}
        />
      )}
```

Replace with:

```jsx
      {tourStep >= 0 && (
        <CoachMark
          targetRef={
            tourStep === 0 ? spokeRef
            : tourStep === 1 ? compareRef
            : tourStep === 2 ? backToLibRef
            : chartContainerRef
          }
          message={tourMessages[tourStep]}
          stepLabel={`${tourStep + 1} of 4`}
          onNext={advanceTour}
          onSkipAll={skipTour}
          onDismiss={advanceTour}
          show={true}
          allowSpotlightInteraction={tourStep === 0 || tourStep === 3}
        />
      )}
```

Changes:
- `stepLabel` updated from `3` to `4`
- `targetRef` ternary extended: step 2 → `backToLibRef`, step 3 → `chartContainerRef` (the radar chart container, already declared around line 407)
- `allowSpotlightInteraction` also true on step 3 so the user can actually click the "Want the full story?" anchor inside the tooltip without the backdrop eating the click

- [ ] **Step 4: Verify the tour runs end-to-end in the dev server**

Run:
```bash
cd CompassV2 && npm run build
```
Expected: Build succeeds.

Run the dev server. To re-trigger the post-calibration tour, clear its dismiss flag in the browser console:
```js
localStorage.removeItem("onboarding_postCalTour");
```
Then navigate to `/results`. Expected behavior: the tour walks steps 1–3 as before (same messages, same targets), then advances to step 4, which spotlights the radar chart area and shows the antipartisan message with a "Want the full story?" link. Clicking the link opens `/how-it-works#compass-positions` in a new tab; the tour tooltip remains on step 4 until the user clicks **Next** (which dismisses the tour normally) or **Skip All**. Step labels read "1 of 4" through "4 of 4". Stop the dev server.

- [ ] **Step 5: Commit**

```bash
git add CompassV2/src/pages/Compass.jsx
git commit -m "feat(compass): add antipartisan capstone step to post-calibration tour"
```

---

## Task 7: Final cross-surface verification

**Files:** (no code changes)

- [ ] **Step 1: Clean dev run across all surfaces**

Run the dev server fresh. In a single session, verify the following user journeys:

1. **Persistent entry point:** From any page, click the circled "?" button in the bottom-right. Lands on `/how-it-works` with the full page rendered, both visuals visible.
2. **Quiz icon:** From the Quiz page, click the circled "?" next to a topic question. Opens `/how-it-works#spectrum-direction` in a new tab; the original Quiz tab is untouched.
3. **Compass icon:** From the Compass (`/results`) page, click the circled "?" on the radar chart. Opens `/how-it-works#compass-positions` in a new tab; the original Compass tab is untouched.
4. **Onboarding tour:** Clear `localStorage["onboarding_postCalTour"]` and reload `/results`. Walk the 4-step tour. On step 4, click "Want the full story?" — new tab opens on the anchor; existing tab still shows the tooltip; clicking **Next** dismisses the tour cleanly; reloading the page does not re-trigger the tour.
5. **Anchor scrolling:** Manually navigate to `/how-it-works#no-parties-no-colors`, `/how-it-works#topic-selection`, `/how-it-works#reading-the-radar`, and `/how-it-works#our-commitment`. Each lands on the correct section.
6. **Stale `/help`:** Navigate to `/help`. Expect redirect to `/how-it-works`.

- [ ] **Step 2: Production build sanity check**

Run:
```bash
cd CompassV2 && npm run build
```
Expected: Build succeeds with no errors or warnings about missing imports, unused variables, or broken JSX.

- [ ] **Step 3: No commit necessary**

This task is verification-only. If any step fails, fix it in a new focused commit rather than amending.

---

## Self-review notes

**Spec coverage:**
- Section 1 (#spectrum-direction) — Task 1 ✓
- Section 2 (#compass-positions) — Task 1 ✓
- Section 3 (#no-parties-no-colors) — Task 1 ✓
- Section 4 (#topic-selection) — Task 1 ✓
- Section 5 (#reading-the-radar) — Task 1 ✓
- Section 6 (#our-commitment) — Task 1 ✓
- Spectrum-direction visual — Task 1 ✓
- Radar reference visual — Task 1 ✓
- Footer link → adapted to persistent help button (noted in Architecture) — Task 3 ✓
- Onboarding coach-mark step (step 4, new tab link, non-interrupting) — Task 6 ✓
- Quiz "?" icon → #spectrum-direction — Task 4 ✓
- Compass "?" icon → #compass-positions — Task 5 ✓
- All new-tab links use `target="_blank" rel="noopener"` ✓
- All icons have `aria-label` with "opens in a new tab" phrasing ✓
- Manrope font / ev-muted-blue / no partisan colors ✓ (inherited via Layout and class names)

**No placeholders:** Every task has exact paths, full code blocks, and exact verification commands. No "TBD", no "handle edge cases", no "similar to above."

**Type/name consistency:** `chartContainerRef` is the same ref used by the existing `compareTour` (line 407) — reusing it for step 4 does not conflict because only one tour runs at a time. `tourMessages` is a plain array of `ReactNode` values, which `CoachMark` already accepts via the `children ?? message` path.

**Spec deviation (documented):** CompassV2 has no footer component. Rather than introduce one, Task 3 repurposes the pre-existing persistent help button in `Layout.jsx` (previously a dead redirect to `/results`) as the always-visible entry point. This preserves the spec's intent (persistent, low-salience, reachable from every page) without adding UI chrome the project doesn't have.
