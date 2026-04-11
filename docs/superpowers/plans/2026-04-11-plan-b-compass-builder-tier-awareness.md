# Plan B — Compass Builder Tier Awareness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give voters visible information about topic applicability when building their compass so they can make informed coverage choices. Adds a `<TopicTierBadge />` component in `ev-ui` and consumes it from `CompassV2/src/pages/BuildCompass.jsx`, along with an inline coverage summary showing how many of the picked topics apply at each tier.

**Architecture:** One new presentational component in `@empoweredvote/ev-ui` (`TopicTierBadge`) that renders tier pills from a topic's `applies_federal/state/local` booleans using the existing `tierColors` design tokens. `BuildCompass.jsx` imports the component and renders it on each topic button, then adds an inline coverage-count breakdown to the existing "N of 8 selected" status line. No new backend work — Plan A already exposes the tier booleans via `getCompassTopics`.

**Tech Stack:** React 18+ (ev-ui targets React 18 as peer dep), `@empoweredvote/ev-ui` (public npm, published via OIDC), CompassV2 (React 19 + Vite 6 + Tailwind CSS 4). ev-ui uses inline style objects with design tokens, not Tailwind.

**Spec:** `docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md` (section: "Compass builder UX")
**Depends on:** Plan A (data foundation) — must be fully landed and deployed to prod before Plan B starts. The `applies_federal/state/local` booleans must flow through `/api/compass/topics` responses.

---

## File Structure

**Files created:**
- `ev-ui/src/TopicTierBadge.jsx` — new React component rendering tier pills. Takes a `topic` prop (or explicit `tiers` array) and renders styled pills using `tierColors` from tokens.

**Files modified:**
- `ev-ui/src/index.js` — add `TopicTierBadge` to the exports list.
- `ev-ui/package.json` — version bump via `npm version patch` during release.
- `CompassV2/src/pages/BuildCompass.jsx` — import `TopicTierBadge`, render it on each topic button, add inline coverage summary to the header.
- `CompassV2/package.json` — updated automatically by the auto-bump pipeline when ev-ui releases.

**Not modified this plan:**
- Backend (ev-accounts) — tier flag data already flows through from Plan A.
- `essentialsService.ts` — Plan B is CompassV2-only.
- Any other ev-ui components — only index.js gets the new export line.

**Coverage hint placement:** Inline in `BuildCompass.jsx`, not a separate component. Per spec, it's a simple derived counter, not a reusable UI primitive. Plan C's essentials coverage *callout* is a separate, distinct component with different logic and display.

---

## Task 1: Create TopicTierBadge Component in ev-ui

**Files:**
- Create: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/TopicTierBadge.jsx`

The component renders 1-3 small pills showing which tiers a topic applies to. It uses the existing `tierColors` export in `ev-ui/src/tokens.js` for styling, so federal/state/local pills match the rest of the design system.

**Component API:**

```jsx
<TopicTierBadge topic={topic} />               // derive tiers from topic.applies_federal/state/local
<TopicTierBadge tiers={['federal', 'state']} /> // or pass tiers explicitly
<TopicTierBadge topic={topic} size="xs" />     // size: 'xs' | 'sm' (default 'sm')
<TopicTierBadge topic={topic} layout="compact" /> // layout: 'compact' (abbreviated F·S·L) | 'full' (default 'full')
```

- [ ] **Step 1: Create the component file**

Write this exact content to `/Users/chrisandrews/Documents/GitHub/ev-ui/src/TopicTierBadge.jsx`:

```jsx
import React from 'react';
import { tierColors, fonts, fontWeights, fontSizes, spacing, borderRadius } from './tokens';

const TIER_LABELS = {
  federal: { full: 'Federal', compact: 'F' },
  state:   { full: 'State',   compact: 'S' },
  local:   { full: 'Local',   compact: 'L' },
};

const SIZE_STYLES = {
  xs: {
    fontSize: fontSizes.xs,
    padding: `${spacing[1]} ${spacing[2]}`,
    gap: spacing[1],
  },
  sm: {
    fontSize: fontSizes.xs,
    padding: `${spacing[1]} ${spacing[2]}`,
    gap: spacing[1],
  },
};

/**
 * TopicTierBadge — small pill badges showing which tiers of government
 * have real jurisdiction on a compass topic.
 *
 * Used in the compass builder to help voters pick topics with good
 * cross-tier coverage. Purely informational — tier flags do NOT gate
 * compass rendering or filter politician comparisons.
 *
 * @param {Object} props
 * @param {Object} [props.topic] - Topic object with applies_federal/state/local booleans
 * @param {Array<'federal'|'state'|'local'>} [props.tiers] - Explicit tier list (overrides topic)
 * @param {'xs'|'sm'} [props.size='sm'] - Pill size
 * @param {'full'|'compact'} [props.layout='full'] - 'full' shows "Federal·State·Local", 'compact' shows "F·S·L"
 * @param {Object} [props.style] - Additional container styles
 */
export default function TopicTierBadge({
  topic,
  tiers,
  size = 'sm',
  layout = 'full',
  style = {},
}) {
  // Derive tiers from topic if not explicitly passed
  const effectiveTiers = tiers ?? (
    topic
      ? [
          topic.applies_federal ? 'federal' : null,
          topic.applies_state ? 'state' : null,
          topic.applies_local ? 'local' : null,
        ].filter(Boolean)
      : []
  );

  if (effectiveTiers.length === 0) return null;

  const sizeStyle = SIZE_STYLES[size] || SIZE_STYLES.sm;

  const containerStyle = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: sizeStyle.gap,
    flexWrap: 'wrap',
    ...style,
  };

  const pillStyle = (tier) => ({
    display: 'inline-flex',
    alignItems: 'center',
    padding: sizeStyle.padding,
    borderRadius: borderRadius.full,
    fontFamily: fonts.primary,
    fontWeight: fontWeights.medium,
    fontSize: sizeStyle.fontSize,
    backgroundColor: tierColors[tier].bg,
    color: tierColors[tier].text,
    border: `1px solid ${tierColors[tier].text}`,
    lineHeight: 1,
    userSelect: 'none',
  });

  return (
    <span
      className="ev-topic-tier-badge"
      style={containerStyle}
      role="group"
      aria-label={`Applies at: ${effectiveTiers.map(t => TIER_LABELS[t].full).join(', ')}`}
    >
      {effectiveTiers.map((tier) => (
        <span key={tier} style={pillStyle(tier)}>
          {TIER_LABELS[tier][layout]}
        </span>
      ))}
    </span>
  );
}
```

- [ ] **Step 2: Verify the component file was written**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
wc -l src/TopicTierBadge.jsx
cat src/TopicTierBadge.jsx | grep -c "export default"
```

Expected:
- File should be around 90 lines
- `export default` should appear exactly once

- [ ] **Step 3: Verify tokens.js exports what we're importing**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
node -e "
const tokens = require('./src/tokens.js');
console.log('tierColors:', typeof tokens.tierColors);
console.log('tierColors.federal:', tokens.tierColors?.federal);
console.log('tierColors.state:', tokens.tierColors?.state);
console.log('tierColors.local:', tokens.tierColors?.local);
console.log('fonts.primary:', tokens.fonts?.primary);
console.log('fontSizes.xs:', tokens.fontSizes?.xs);
console.log('spacing[1]:', tokens.spacing?.[1]);
console.log('borderRadius.full:', tokens.borderRadius?.full);
"
```

Expected: all fields should print defined values (not `undefined`). If any are undefined, the import path in TopicTierBadge.jsx needs adjustment — read `tokens.js` and match the actual export structure.

If `tierColors` is missing, STOP and report BLOCKED — the component design depends on that export existing (it was confirmed to exist during plan drafting).

---

## Task 2: Export TopicTierBadge from ev-ui Index and Build

**Files:**
- Modify: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/index.js`

- [ ] **Step 1: Read the current ev-ui index.js**

```bash
cat /Users/chrisandrews/Documents/GitHub/ev-ui/src/index.js
```

Verify the current state matches what the plan expects (component export lines, hooks, design tokens, etc.). If it has drifted significantly from what Task 2 assumes, note the drift in your report.

- [ ] **Step 2: Add the TopicTierBadge export**

Use the Edit tool to add a new export line to `/Users/chrisandrews/Documents/GitHub/ev-ui/src/index.js`.

Find this line:
```javascript
export { default as AuthForm } from "./AuthForm.jsx";
```

Add immediately after it:
```javascript
export { default as TopicTierBadge } from "./TopicTierBadge.jsx";
```

The diff should be a single new line addition.

- [ ] **Step 3: Build ev-ui**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
npm run build
```

Expected: successful build, `dist/index.js` and `dist/index.mjs` produced, no errors.

If the build fails with an import error on `./tokens` (CJS vs ESM mismatch), verify the existing components handle the import the same way TopicTierBadge does. If they use a different path (e.g., `./tokens.js`), adjust the component's import to match.

- [ ] **Step 4: Verify TopicTierBadge is exported from the built bundle**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
grep -l "TopicTierBadge" dist/*.js dist/*.mjs 2>&1 | head -3
```

Expected: at least one dist file contains a `TopicTierBadge` reference.

```bash
node -e "
import('./dist/index.mjs').then(m => {
  console.log('Export keys include TopicTierBadge:', 'TopicTierBadge' in m);
  if ('TopicTierBadge' in m) {
    console.log('Type:', typeof m.TopicTierBadge);
  }
}).catch(e => { console.error(e); process.exit(1); });
"
```

Expected output:
```
Export keys include TopicTierBadge: true
Type: function
```

If not found, the index.js edit didn't land properly. Re-check and re-build.

---

## Task 3: Commit ev-ui Changes (No Release Yet)

**Files:**
- Commit to ev-ui git repo (separate from monorepo): `src/TopicTierBadge.jsx`, `src/index.js`

- [ ] **Step 1: Confirm ev-ui git state**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
git status
git branch --show-current
```

Expected:
- Branch: `main`
- Modified: `src/index.js`
- Untracked: `src/TopicTierBadge.jsx`
- Likely also modified: `dist/*` files (if `dist/` is tracked — check with `git ls-files dist/ | head -3`)

If `dist/` is tracked, the built artifacts need to be included in the commit. If it's gitignored, only source files commit.

- [ ] **Step 2: Commit the ev-ui changes**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
git add src/TopicTierBadge.jsx src/index.js
# If dist/ is tracked, also add it:
# git add dist/

git commit -m "$(cat <<'EOF'
feat: add TopicTierBadge component

Small pill component showing which tiers (federal/state/local) a
compass topic applies at. Uses tierColors design tokens for consistent
styling. Purely informational — tier flags do not gate compass rendering.

Consumed by CompassV2's BuildCompass page to help voters pick topics
with good cross-tier coverage. See docs/superpowers/specs/2026-04-10
in the monorepo for the broader design.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Do NOT push yet**

Stop here. The push happens in Task 4 as part of the release flow.

Run `git log --oneline -1` and record the commit SHA for the next task.

---

## Task 4: Release ev-ui — Version Bump and Tag Push

This task publishes the new version of `@empoweredvote/ev-ui` to npm via the automated OIDC publish workflow and triggers the auto-bump pipeline that opens PRs in consumer repos.

**Blast radius warning:** This task modifies the public npm package and triggers auto-bump PRs in CompassV2, essentials, read-rank, and civic-spaces. The auto-bump PRs are auto-merged by the build-check workflow for patch/minor versions. Render will auto-deploy each consumer on merge to main. This is normal behavior per the auto-bump pipeline docs (CLAUDE.md → ev-ui section) but means the release is a real public deployment event, not a local change.

Chris has authorized ev-ui releases as part of Plan B execution. If you're uncertain whether to trigger the release, STOP and escalate.

- [ ] **Step 1: Run npm version patch**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
npm version patch
```

Expected: prints the new version (e.g., `v0.2.3`), updates `package.json`, and creates a git tag + commit automatically.

- [ ] **Step 2: Push with follow-tags**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
git push origin main --follow-tags
```

Expected: pushes the branch and the version tag. Stdout should show the tag being pushed (`* [new tag] v0.2.3 -> v0.2.3` or similar).

- [ ] **Step 3: Monitor the publish workflow**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
gh run list --workflow publish.yml --limit 3
```

Expected: a new workflow run triggered by the tag push, status `in_progress` or `completed`. Wait up to 3 minutes for it to finish.

```bash
# Wait and re-check
sleep 60
gh run list --workflow publish.yml --limit 3
```

If the run fails, inspect with `gh run view --log <run-id>` and report BLOCKED. The most likely failure modes:
- OIDC trust not configured for new contributor (shouldn't happen if previous releases work)
- Build script failure (shouldn't happen if Task 2 build passed)
- Dispatch token expired (would block auto-bump, not publish)

- [ ] **Step 4: Verify the new version is live on npm**

```bash
npm view @empoweredvote/ev-ui version
```

Expected: the new version printed (e.g., `0.2.3`). If the registry hasn't updated yet, wait 30 seconds and retry — npm can lag briefly.

- [ ] **Step 5: Record the new version**

Record the new version string (e.g., `0.2.3`) for reference in Task 6.

---

## Task 5: Verify CompassV2 Auto-Bump PR Merged

The release in Task 4 fires a `repository_dispatch` event to CompassV2 (and 3 other consumers). CompassV2's `.github/workflows/ev-ui-bump.yml` receives the dispatch, opens a PR bumping the `@empoweredvote/ev-ui` version in `package.json`, and auto-merges if the bump is patch or minor and the build-check workflow passes.

- [ ] **Step 1: Check for the auto-bump PR**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
gh pr list --state all --head "ev-ui-bump" --limit 5
```

Or if the bump uses a different branch pattern:
```bash
gh pr list --state all --search "ev-ui" --limit 5
```

Expected: a recent PR with title like "chore: bump @empoweredvote/ev-ui to 0.2.3" (or similar). Status should be `MERGED` if auto-merge worked, `OPEN` if auto-merge didn't trigger.

If no PR appears after 2 minutes, check the ev-ui dispatch workflow logs:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
gh run list --workflow publish.yml --limit 3
gh run view --log <most-recent-run-id> 2>&1 | grep -i "dispatch\|bump\|error" | head -20
```

- [ ] **Step 2: Pull latest CompassV2 main**

Whether the auto-bump PR was auto-merged or needs manual merge, pull the latest:

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
git fetch origin
git checkout main
git pull origin main
```

- [ ] **Step 3: Verify the new ev-ui version is in CompassV2's package.json**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
grep "@empoweredvote/ev-ui" package.json
```

Expected: the line should show the new version from Task 4 (e.g., `"@empoweredvote/ev-ui": "^0.2.3"` or similar).

If it still shows the old version, the auto-bump PR wasn't merged. Manually merge the PR via `gh pr merge <pr-number>` or open it in the browser.

- [ ] **Step 4: Install the new version locally**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
npm install
```

Expected: clean install, `node_modules/@empoweredvote/ev-ui/` exists with the new version.

Quick verification:
```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
cat node_modules/@empoweredvote/ev-ui/package.json | grep '"version"'
grep -l TopicTierBadge node_modules/@empoweredvote/ev-ui/dist/*.js node_modules/@empoweredvote/ev-ui/dist/*.mjs 2>&1 | head -3
```

Expected: version matches Task 4's new version, dist files contain `TopicTierBadge`.

---

## Task 6: Update BuildCompass.jsx to Use TopicTierBadge

**Files:**
- Modify: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/BuildCompass.jsx`

Two changes in this file:
1. **Render `TopicTierBadge` on each topic button** — small inline badge showing the topic's applicable tiers.
2. **Add inline coverage summary** to the header counter line — "6 of 8 selected · 5 Federal · 4 State · 3 Local".

- [ ] **Step 1: Read the current BuildCompass.jsx**

```bash
cat /Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/BuildCompass.jsx
```

Verify the file still matches the structure assumed by this plan (199 lines, imports from `useCompass` context, renders topic buttons in categories). If it has drifted significantly, note the drift in your report and adapt the edits.

- [ ] **Step 2: Add the import**

Edit the top of `BuildCompass.jsx`. Find this line:
```jsx
import { apiFetch } from "../lib/auth";
```

Add immediately after it:
```jsx
import { TopicTierBadge } from "@empoweredvote/ev-ui";
```

- [ ] **Step 3: Add a coverage summary helper inside the component**

Find this block (around line 73):
```jsx
  const handleViewCompass = () => {
    setSelectedTopics(picked);
    navigate("/results");
  };
```

Add immediately before it:
```jsx
  // Derive per-tier counts from the current picked topics.
  // A topic counts toward any tier it applies to (topics can apply at multiple).
  const pickedTopics = picked
    .map((id) => topics.find((t) => t.id === id))
    .filter(Boolean);
  const tierCounts = {
    federal: pickedTopics.filter((t) => t.applies_federal).length,
    state:   pickedTopics.filter((t) => t.applies_state).length,
    local:   pickedTopics.filter((t) => t.applies_local).length,
  };
```

- [ ] **Step 4: Update the "N of 8 selected" status line to include tier counts**

Find this block (around lines 97-104):
```jsx
        <p className="text-center text-sm font-medium mb-6">
          <span className={picked.length >= MIN_TOPICS ? "text-green-600" : "text-gray-500"}>
            {picked.length} of {MAX_TOPICS} selected
          </span>
          {picked.length < MIN_TOPICS && (
            <span className="text-gray-400 ml-2">(minimum {MIN_TOPICS})</span>
          )}
        </p>
```

Replace it with:
```jsx
        <p className="text-center text-sm font-medium mb-2">
          <span className={picked.length >= MIN_TOPICS ? "text-green-600" : "text-gray-500"}>
            {picked.length} of {MAX_TOPICS} selected
          </span>
          {picked.length < MIN_TOPICS && (
            <span className="text-gray-400 ml-2">(minimum {MIN_TOPICS})</span>
          )}
        </p>
        {picked.length > 0 && (
          <p className="text-center text-xs text-gray-500 mb-6">
            Tier coverage:{" "}
            <span className="font-medium">{tierCounts.federal} Federal</span>
            {" · "}
            <span className="font-medium">{tierCounts.state} State</span>
            {" · "}
            <span className="font-medium">{tierCounts.local} Local</span>
          </p>
        )}
```

This preserves the existing "N of 8 selected" line unchanged and adds a second smaller line below it showing the tier breakdown. The coverage line only renders when at least one topic is picked (otherwise it's empty noise).

- [ ] **Step 5: Render TopicTierBadge on each topic button**

Find this block (around lines 165-169):
```jsx
                      <span className={`text-xs mt-1 block ${color.text} opacity-80`}>
                        {category.title}
                      </span>
                    </button>
```

Replace with:
```jsx
                      <span className={`text-xs mt-1 block ${color.text} opacity-80`}>
                        {category.title}
                      </span>
                      <div className="mt-2">
                        <TopicTierBadge topic={topic} size="xs" layout="compact" />
                      </div>
                    </button>
```

This renders the tier badge in a new row below the category label, inside each topic button. `layout="compact"` uses the abbreviated F·S·L form to save horizontal space in the grid layout.

- [ ] **Step 6: Run the dev server and visually verify locally**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
npm run dev
```

Open the dev URL (usually `http://localhost:5173`) in a browser. Navigate to the "Build Compass" page.

Verify:
- Each topic button shows a small tier badge row below the category label
- Tariffs shows only "F"
- Housing shows "F·S·L" (all three)
- Jail Capacity (if present) shows "S·L"
- When you pick a topic, the header shows "Tier coverage: X Federal · Y State · Z Local"
- Picking different topics updates the tier counts correctly
- Unpicking all topics hides the tier coverage line

If the tier badges don't show up at all, the most likely causes:
1. The topics from `useCompass()` don't have `applies_federal/state/local` fields — verify by logging `topics[0]` to console or using React DevTools
2. The import path is wrong — verify `TopicTierBadge` is exported from the installed ev-ui version
3. The `tierColors` in tokens.js doesn't have the expected shape — check the console for runtime errors

STOP and report DONE_WITH_CONCERNS if the visual result is wrong but you can't figure out why.

- [ ] **Step 7: Stop the dev server**

Ctrl+C in the terminal running `npm run dev`.

---

## Task 7: Commit CompassV2 Changes

**Files:**
- Commit: `CompassV2/src/pages/BuildCompass.jsx`

- [ ] **Step 1: Confirm state**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
git status
```

Expected: `src/pages/BuildCompass.jsx` modified. Possibly `package.json` and `package-lock.json` too if Task 5's auto-bump left them dirty — those should already be committed by the auto-bump PR but double-check.

If there are other unexpected modifications in CompassV2, STOP and escalate so Chris can handle the WIP before committing.

- [ ] **Step 2: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
git add src/pages/BuildCompass.jsx
git commit -m "$(cat <<'EOF'
feat(compass): show tier badges on topic picker

Adds TopicTierBadge from @empoweredvote/ev-ui to each topic button
in BuildCompass so voters can see which levels of government each
topic applies at. Adds an inline tier coverage summary below the
"N of 8 selected" header showing how many picked topics apply at
each tier.

Tier flags are metadata only — they don't gate compass rendering
or filter politician comparisons. This is purely informational to
help voters build a compass with good cross-tier coverage.

Part of Plan B. See docs/superpowers/specs/2026-04-10 in the
monorepo for the broader design.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Push to main**

```bash
cd /Users/chrisandrews/Documents/GitHub/CompassV2
git push origin main
```

Expected: push succeeds. Render will auto-deploy compass.empowered.vote on merge to main. The deploy typically takes 2-5 minutes.

Run `git log --oneline -1` and record the commit SHA.

---

## Task 8: Deployed Verification

- [ ] **Step 1: Wait for Render deploy**

```bash
sleep 120  # 2-minute wait for Render to pick up the push and start deploying
```

Check Render dashboard or deployment status if the `render` CLI is available.

- [ ] **Step 2: Visit the deployed compass builder**

Open `https://compass.empowered.vote/build-compass` (or the equivalent path — check the router in CompassV2 if the path differs).

Verify the same three things as in Task 6 Step 6:
1. Topic buttons show tier badges
2. Tariffs = F, Housing = F·S·L, Jail Capacity = S·L (if present)
3. Tier coverage summary updates as topics are picked

If the deployed version doesn't match the local dev version, the Render deploy may still be in progress. Wait another 2 minutes and retry. If it still doesn't match after 5 minutes, check Render deploy logs for errors.

---

## Plan B Complete

After all tasks pass:

1. ✅ `@empoweredvote/ev-ui` published with new `TopicTierBadge` component (version bumped from 0.2.2 to 0.2.3 or newer)
2. ✅ CompassV2 automatically bumped to the new version via the auto-bump pipeline
3. ✅ BuildCompass.jsx renders tier badges on topic buttons
4. ✅ BuildCompass.jsx shows an inline tier coverage summary when topics are picked
5. ✅ Voters can now see which tiers of government each compass topic applies at, enabling informed picks

**Visible user impact:** Voters building their compass see small F/S/L pills under each topic. When they pick topics, a "Tier coverage: X Federal · Y State · Z Local" line tells them how balanced their selection is across levels of government. Pure information — no forced choices.

**Not delivered by Plan B (comes in Plans C and D):**
- Essentials coverage callout (Plan C) — banner on address results pages when voter's compass has poor coverage for the results shown
- Deep comparison view on politician profiles (Plan C)
- Topic rewrite workflow (Plan D)

**Unblocks:** Plan C can now build the coverage callout using the same tier flag data. The `TopicTierBadge` component built here can also be reused in Plan C if the coverage callout wants to show tier pills on suggested topics.
