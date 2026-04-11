# Plan C — Essentials Coverage Callout + Deep Comparison Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the essentials compass experience useful for voters regardless of compass tier coverage, and give clean, honest treatment to offices where the compass paradigm doesn't fit. Adds a coverage callout on the results page, an "expand your compass" nudge on the politician profile, and explicit treatment for administrative offices and contested-election judges that currently render as blank-feeling profiles.

**Architecture:** Two new ev-ui components (`CompassCoverageCallout`, `ExpandCompassNudge`) and one small utility (`computeTierCoverage`). Consumed by `essentials/src/pages/Results.jsx` (callout on the results grid) and `essentials/src/components/CompassCard.jsx` (nudge on the politician profile). A small addition to `essentials/src/pages/Profile.jsx` renders an explicit "administrative office" note when `policy_engagement_level === 'none'`. Contested-election judges get a parallel "evaluated on record, not positions" note.

**Tech Stack:** React 19 + Vite 7 + Tailwind CSS 4 (essentials), React + inline style tokens (ev-ui), `@empoweredvote/ev-ui` published via auto-bump pipeline.

**Spec:** `docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md` (sections: "Essentials coverage callout", "Politician profile deep comparison view", core principle #4)

**Depends on:** Plan A (ev-accounts backend tier flags + `policy_engagement_level`) and Plan B (ev-ui `TopicTierBadge@0.3.0`). Both deployed.

**Key constraint:** No new stance data is created in this plan. No retention-judge track record system is built — that's still out of scope. This plan is purely presentation-layer work over existing data.

---

## What's already built (important — don't rebuild)

The discovery phase found a lot of the experience already exists. Plan C is additive over the current architecture:

- **CompassCard.jsx handles 3 states already**: user-has-compass, guest, zero-overlap. Each has its own CTA and layout. Plan C enhances these, not replaces them.
- **StanceAccordion from ev-ui is already used** as the deep breakdown on the right panel of CompassCard. No separate "deep comparison view" component needed — this IS the deep view.
- **Admin offices already render cleanly** — CompassCard returns `null` when the politician has no stances, and `politicianIdsWithStances` is the gate. The role description in the header already explains the office. Plan C just adds a single short acknowledgment line.
- **Judicial differentiation exists**: `pol.is_judicial` already routes to `JudicialScorecard` vs `LegislativeInlineSummary` in ev-ui's `PoliticianProfile`. Plan C adds no new judicial plumbing.
- **Results.jsx uses `PoliticianCard` + `GovernmentBodySection`** from ev-ui and already has a filter sidebar with "All / Local / State / Federal" groups. Plan C adds a banner above the grid, not a new grid system.
- **`allTopics` in CompassContext now carries tier flag booleans** after Plan A's backend fix. No fetch changes needed.

Net effect: **Plan C is smaller than it looks in the spec.** Most infrastructure exists.

---

## File Structure

**Files created (ev-ui):**
- `ev-ui/src/CompassCoverageCallout.jsx` — banner showing "Your compass has N of M [tier] topics. Add more..." with a CTA button. Pure presentation. Props: `tier`, `count`, `totalSelected`, `compassUrl`, optional `onDismiss`.
- `ev-ui/src/ExpandCompassNudge.jsx` — card-style prompt showing "[Politician] has X more topics you haven't answered yet. Expand your compass to compare." with a deep-link CTA. Props: `politicianName`, `missingCount`, `compassUrl`, `tier` (optional, for tier-scoped nudges).
- `ev-ui/src/computeTierCoverage.js` — small utility: `computeTierCoverage(selectedTopicObjects) → { federal: n, state: n, local: n }`. Keeps math in one place so Plan C consumers don't duplicate it.

**Files modified (ev-ui):**
- `ev-ui/src/index.js` — add three new exports.

**Files modified (essentials):**
- `essentials/src/pages/Results.jsx` — import `CompassCoverageCallout` + `computeTierCoverage`, render callout(s) above the results grid when the user's compass has <3 topics at a tier AND that tier is present in the current results.
- `essentials/src/components/CompassCard.jsx` — import `ExpandCompassNudge`, render it below the StanceAccordion when the user has a compass and there's a non-zero gap between politician stance topics and user-answered topics. Optionally tier-aware based on the politician's level.
- `essentials/src/pages/Profile.jsx` — add a small section rendered when the politician's `policy_engagement_level === 'none'` (administrative office) OR when `policy_engagement_level === 'full' && is_judicial && !politicianIdsWithStances.has(id)` (contested judge with no stance research yet). Each case shows a different short message.

**Not modified this plan:**
- `PoliticianProfile.jsx` in ev-ui — already supports `{children}` slot and judicial routing. No changes needed.
- `StanceAccordion.jsx` in ev-ui — already handles the deep stance display. No changes needed.
- Backend (ev-accounts) — all data already exposed via Plan A.

**Policy-engagement-level plumbing note:** Results.jsx politician cards already receive `policy_engagement_level` from the essentials backend (added in Plan A). Profile.jsx gets the full politician object from `fetchPolitician(id)` which already includes it. No new API work needed.

---

## Task 1: Create `computeTierCoverage` Utility in ev-ui

**Files:**
- Create: `ev-ui/src/computeTierCoverage.js`

This is a small utility function that counts how many topics in an array apply at each tier. Used by CompassCoverageCallout, by Plan C's Results page logic, and potentially by future consumers.

- [ ] **Step 1: Create the file**

Write this exact content to `/Users/chrisandrews/Documents/GitHub/ev-ui/src/computeTierCoverage.js`:

```javascript
/**
 * computeTierCoverage
 *
 * Counts how many topics apply at each tier of government. A topic with
 * `applies_federal`, `applies_state`, `applies_local` booleans contributes
 * to each tier it's marked for; cross-cutting topics contribute to all three.
 *
 * Topics missing tier flag fields (e.g., from an older API response) are
 * treated as cross-cutting (all three tiers = true). This matches the
 * backend default behavior in getCompassTopics/getCompassCategories.
 *
 * @param {Array<{applies_federal?: boolean, applies_state?: boolean, applies_local?: boolean}>} topics
 * @returns {{ federal: number, state: number, local: number }}
 *
 * @example
 *   computeTierCoverage([
 *     { applies_federal: true, applies_state: true, applies_local: true },  // housing
 *     { applies_federal: true, applies_state: false, applies_local: false }, // tariffs
 *   ])
 *   // → { federal: 2, state: 1, local: 1 }
 */
export function computeTierCoverage(topics) {
  const counts = { federal: 0, state: 0, local: 0 };
  if (!Array.isArray(topics)) return counts;

  for (const t of topics) {
    if (!t) continue;
    // Default to cross-cutting if tier fields are missing entirely.
    const hasFlags =
      'applies_federal' in t || 'applies_state' in t || 'applies_local' in t;
    const f = hasFlags ? Boolean(t.applies_federal) : true;
    const s = hasFlags ? Boolean(t.applies_state) : true;
    const l = hasFlags ? Boolean(t.applies_local) : true;
    if (f) counts.federal++;
    if (s) counts.state++;
    if (l) counts.local++;
  }

  return counts;
}
```

- [ ] **Step 2: Verify the file was written**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
wc -l src/computeTierCoverage.js
grep -c "export function computeTierCoverage" src/computeTierCoverage.js
```

Expected:
- ~44 lines
- Exactly 1 match for the export

- [ ] **Step 3: Quick sanity check via Node**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
node -e "
import('./src/computeTierCoverage.js').then(m => {
  const result = m.computeTierCoverage([
    { applies_federal: true, applies_state: true, applies_local: true },
    { applies_federal: true, applies_state: false, applies_local: false },
    { applies_federal: false, applies_state: true, applies_local: true },
  ]);
  console.log('Result:', JSON.stringify(result));
  const expected = { federal: 2, state: 2, local: 2 };
  const match = JSON.stringify(result) === JSON.stringify(expected);
  console.log('Match:', match);
  if (!match) process.exit(1);
}).catch(e => { console.error(e); process.exit(1); });
"
```

Expected output:
```
Result: {"federal":2,"state":2,"local":2}
Match: true
```

---

## Task 2: Create `CompassCoverageCallout` Component in ev-ui

**Files:**
- Create: `ev-ui/src/CompassCoverageCallout.jsx`

Small banner component. Shows when the user's compass has poor tier coverage for the results currently being shown. Non-blocking — can be dismissed, clicked through to expand the compass, or ignored.

- [ ] **Step 1: Create the component file**

Write this exact content to `/Users/chrisandrews/Documents/GitHub/ev-ui/src/CompassCoverageCallout.jsx`:

```jsx
import React, { useState } from 'react';
import { tierColors, fonts, fontWeights, fontSizes, spacing, borderRadius } from './tokens';

const TIER_LABELS = {
  federal: 'federal',
  state:   'state',
  local:   'local',
};

/**
 * CompassCoverageCallout — non-blocking banner shown on results pages when
 * the voter's compass has poor tier coverage for politicians in the current
 * results. Suggests adding more tier-applicable topics, with a CTA that
 * deep-links to the compass builder.
 *
 * The callout is purely informational. It does not change what politicians
 * are shown, reshape any compass radar, or filter results. It's a hint.
 *
 * @param {Object} props
 * @param {'federal'|'state'|'local'} props.tier - The tier that's under-covered
 * @param {number} props.count - How many of the voter's compass topics apply at this tier
 * @param {number} [props.totalSelected] - Total compass size (for context in the message)
 * @param {string} props.compassUrl - URL to open the compass builder (absolute or relative)
 * @param {Function} [props.onDismiss] - Optional dismiss handler; if provided, a close button renders
 */
export default function CompassCoverageCallout({
  tier,
  count,
  totalSelected,
  compassUrl,
  onDismiss,
}) {
  const [dismissed, setDismissed] = useState(false);
  if (dismissed) return null;

  const tierLabel = TIER_LABELS[tier] || tier;
  const tierStyle = tierColors[tier] || tierColors.federal;

  const containerStyle = {
    display: 'flex',
    alignItems: 'flex-start',
    gap: spacing[3],
    padding: `${spacing[3]} ${spacing[4]}`,
    borderLeft: `4px solid ${tierStyle.text}`,
    backgroundColor: tierStyle.bg,
    borderRadius: `0 ${borderRadius.md} ${borderRadius.md} 0`,
    fontFamily: fonts.primary,
    margin: `${spacing[3]} 0`,
  };

  const textStyle = {
    flex: 1,
    fontSize: fontSizes.sm,
    color: '#2d3748',
    lineHeight: 1.5,
  };

  const headlineStyle = {
    fontWeight: fontWeights.semibold,
    marginBottom: spacing[1],
    color: tierStyle.text,
  };

  const ctaStyle = {
    display: 'inline-block',
    marginTop: spacing[2],
    padding: `${spacing[2]} ${spacing[4]}`,
    backgroundColor: tierStyle.text,
    color: '#ffffff',
    borderRadius: borderRadius.full,
    fontSize: fontSizes.sm,
    fontWeight: fontWeights.semibold,
    textDecoration: 'none',
    cursor: 'pointer',
  };

  const closeStyle = {
    background: 'none',
    border: 'none',
    padding: spacing[1],
    cursor: 'pointer',
    color: '#718096',
    fontSize: fontSizes.lg,
    lineHeight: 1,
  };

  const handleDismiss = () => {
    setDismissed(true);
    if (onDismiss) onDismiss();
  };

  return (
    <div
      className="ev-compass-coverage-callout"
      role="status"
      style={containerStyle}
    >
      <div style={textStyle}>
        <div style={headlineStyle}>Your compass covers {tierLabel} issues lightly</div>
        <div>
          {count === 0
            ? `None of your ${totalSelected ?? 'selected'} compass topics apply at the ${tierLabel} level. `
            : `Only ${count} of your ${totalSelected ?? 'selected'} compass topics apply at the ${tierLabel} level. `}
          Add more {tierLabel}-applicable topics to get better comparisons with {tierLabel} officials.
        </div>
        <a href={compassUrl} style={ctaStyle}>
          Add {tierLabel} topics →
        </a>
      </div>
      {onDismiss !== undefined && (
        <button
          onClick={handleDismiss}
          style={closeStyle}
          aria-label="Dismiss coverage callout"
        >
          ×
        </button>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Verify the file**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
wc -l src/CompassCoverageCallout.jsx
grep -c "export default" src/CompassCoverageCallout.jsx
```

Expected: ~100 lines, exactly 1 default export.

- [ ] **Step 3: Check tokens usage**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
node -e "
import('./src/tokens.js').then(tokens => {
  const checks = {
    'tierColors.federal.bg': tokens.tierColors?.federal?.bg,
    'tierColors.federal.text': tokens.tierColors?.federal?.text,
    'tierColors.state.bg': tokens.tierColors?.state?.bg,
    'tierColors.local.bg': tokens.tierColors?.local?.bg,
    'borderRadius.md': tokens.borderRadius?.md,
    'borderRadius.full': tokens.borderRadius?.full,
    'spacing[3]': tokens.spacing?.[3],
    'spacing[4]': tokens.spacing?.[4],
    'fontSizes.sm': tokens.fontSizes?.sm,
    'fontSizes.lg': tokens.fontSizes?.lg,
    'fontWeights.semibold': tokens.fontWeights?.semibold,
  };
  let ok = true;
  for (const [k, v] of Object.entries(checks)) {
    if (v === undefined) { console.error('MISSING:', k); ok = false; }
  }
  console.log(ok ? 'All tokens present' : 'MISSING TOKENS — see above');
  process.exit(ok ? 0 : 1);
}).catch(e => { console.error(e); process.exit(1); });
"
```

If any token is missing, STOP and report BLOCKED — the component uses tokens that don't exist. Fix by either adding the missing token to `tokens.js` OR adjusting the component to use a token that does exist. Check the existing `tokens.js` file to see what's available.

---

## Task 3: Create `ExpandCompassNudge` Component in ev-ui

**Files:**
- Create: `ev-ui/src/ExpandCompassNudge.jsx`

A subtle prompt that appears below the StanceAccordion in CompassCard when there's a gap between the topics a politician has stances on and the topics the voter has answered. Deep-links to the compass to add more topics.

- [ ] **Step 1: Create the component file**

Write this exact content to `/Users/chrisandrews/Documents/GitHub/ev-ui/src/ExpandCompassNudge.jsx`:

```jsx
import React from 'react';
import { fonts, fontWeights, fontSizes, spacing, borderRadius } from './tokens';

/**
 * ExpandCompassNudge — card-style prompt shown below the deep stance view
 * on a politician profile. Tells the voter how many topics the politician
 * has stances on that the voter hasn't answered yet, and offers a CTA to
 * expand the compass.
 *
 * Only useful to render when missingCount > 0. Caller should handle the
 * zero-missing case by not rendering this component at all.
 *
 * @param {Object} props
 * @param {string} props.politicianName - Display name for the CTA text
 * @param {number} props.missingCount - How many topics the politician has stances on that the voter hasn't answered
 * @param {string} props.compassUrl - URL to deep-link into the compass builder (should include a return param)
 * @param {Object} [props.style] - Additional styles to merge
 */
export default function ExpandCompassNudge({
  politicianName,
  missingCount,
  compassUrl,
  style = {},
}) {
  if (!missingCount || missingCount <= 0) return null;

  const containerStyle = {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-start',
    gap: spacing[2],
    padding: spacing[4],
    marginTop: spacing[4],
    backgroundColor: '#F5F9FA',
    borderRadius: borderRadius.lg,
    border: '1px solid #e0e6eb',
    fontFamily: fonts.primary,
    ...style,
  };

  const headlineStyle = {
    fontSize: fontSizes.base,
    fontWeight: fontWeights.semibold,
    color: '#2d3748',
    margin: 0,
  };

  const bodyStyle = {
    fontSize: fontSizes.sm,
    color: '#4a5568',
    lineHeight: 1.5,
    margin: 0,
  };

  const ctaStyle = {
    display: 'inline-block',
    marginTop: spacing[2],
    padding: `${spacing[2]} ${spacing[4]}`,
    backgroundColor: '#00657c',
    color: '#ffffff',
    borderRadius: borderRadius.full,
    fontSize: fontSizes.sm,
    fontWeight: fontWeights.semibold,
    textDecoration: 'none',
    cursor: 'pointer',
  };

  const topicsLabel = missingCount === 1 ? 'topic' : 'topics';
  const speakerName = politicianName || 'This politician';

  return (
    <div className="ev-expand-compass-nudge" style={containerStyle} role="region">
      <p style={headlineStyle}>Want a richer comparison?</p>
      <p style={bodyStyle}>
        {speakerName} has stances on {missingCount} more {topicsLabel} you haven't
        answered yet. Expand your compass to see where you stand on all of them.
      </p>
      <a href={compassUrl} style={ctaStyle}>
        Expand my compass →
      </a>
    </div>
  );
}
```

- [ ] **Step 2: Verify the file**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
wc -l src/ExpandCompassNudge.jsx
grep -c "export default" src/ExpandCompassNudge.jsx
```

Expected: ~80 lines, exactly 1 default export.

---

## Task 4: Export New Pieces from ev-ui and Build

**Files:**
- Modify: `ev-ui/src/index.js`

- [ ] **Step 1: Read the current index.js**

```bash
cat /Users/chrisandrews/Documents/GitHub/ev-ui/src/index.js
```

Confirm the file has the existing exports. Note the current end-of-file — you'll add new lines near the TopicTierBadge export.

- [ ] **Step 2: Add the new exports**

Use the Edit tool to add two new component exports and one utility export to `/Users/chrisandrews/Documents/GitHub/ev-ui/src/index.js`.

- old_string (exact — copy from the actual file):
```
export { default as TopicTierBadge } from "./TopicTierBadge.jsx";
```

- new_string (exact):
```
export { default as TopicTierBadge } from "./TopicTierBadge.jsx";
export { default as CompassCoverageCallout } from "./CompassCoverageCallout.jsx";
export { default as ExpandCompassNudge } from "./ExpandCompassNudge.jsx";
export { computeTierCoverage } from "./computeTierCoverage.js";
```

- [ ] **Step 3: Build ev-ui**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
npm run build 2>&1 | tail -10
```

Expected: clean build, `dist/index.js` and `dist/index.mjs` produced, no errors.

- [ ] **Step 4: Verify all four new exports are in the built bundle**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
node -e "
import('./dist/index.mjs').then(m => {
  const expected = ['TopicTierBadge', 'CompassCoverageCallout', 'ExpandCompassNudge', 'computeTierCoverage'];
  let ok = true;
  for (const name of expected) {
    const present = name in m;
    const t = typeof m[name];
    console.log(name + ':', present ? 'ok (' + t + ')' : 'MISSING');
    if (!present) ok = false;
  }
  process.exit(ok ? 0 : 1);
}).catch(e => { console.error(e); process.exit(1); });
"
```

Expected output:
```
TopicTierBadge: ok (function)
CompassCoverageCallout: ok (function)
ExpandCompassNudge: ok (function)
computeTierCoverage: ok (function)
```

If any are missing, the edit didn't land cleanly — re-check and re-build.

---

## Task 5: Commit and Release ev-ui v0.4.0

**Files:**
- Commit to ev-ui repo (separate git repo): src/CompassCoverageCallout.jsx, src/ExpandCompassNudge.jsx, src/computeTierCoverage.js, src/index.js

This release triggers the auto-bump pipeline in consumer repos (essentials, CompassV2, read-rank, civic-spaces). We only care about essentials for Plan C — the other consumers will auto-bump harmlessly.

**Note:** Earlier Plan B releases hit a race condition where the dispatch fired before npm registry propagation. If that happens again, fall back to a manual `npm install` in essentials as in Plan B Task 5.

- [ ] **Step 1: Commit the ev-ui changes**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
git status
```

Expected modified/untracked: `src/CompassCoverageCallout.jsx` (new), `src/ExpandCompassNudge.jsx` (new), `src/computeTierCoverage.js` (new), `src/index.js` (modified). If `dist/` is gitignored (as of v0.3.0 release, it is), it won't appear.

If unrelated uncommitted changes are present, STOP and escalate — don't include them in this commit.

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
git add src/CompassCoverageCallout.jsx src/ExpandCompassNudge.jsx src/computeTierCoverage.js src/index.js
git commit -m "$(cat <<'EOF'
feat: add CompassCoverageCallout, ExpandCompassNudge, computeTierCoverage

Three additions for Plan C:

- CompassCoverageCallout: non-blocking banner for essentials Results page
  showing when the voter's compass has poor tier coverage for the politicians
  in the current view. Tier-colored left border, CTA to expand the compass.

- ExpandCompassNudge: card-style prompt for the politician profile page
  showing how many topics a politician has stances on that the voter hasn't
  answered yet. Renders nothing when missingCount is 0.

- computeTierCoverage: small utility counting how many topics in an array
  apply at each of federal/state/local. Shared by the callout logic in
  Results.jsx and future consumers. Topics missing tier fields default to
  cross-cutting (matches backend default).

All three are purely additive — no breaking changes to existing components.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

Record the new commit SHA.

- [ ] **Step 2: Version bump and push**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
npm version minor
git push origin main --follow-tags
```

Expected:
- `npm version minor` prints `v0.4.0` (or higher if someone bumped between Plan B and C)
- `git push` pushes branch + new tag

- [ ] **Step 3: Monitor the publish workflow**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
sleep 10
gh run list --workflow publish.yml --limit 1
```

Wait for the run to reach `completed` + `success`. May take 2-3 minutes.

```bash
# Poll every 30s up to 5 minutes
for i in 1 2 3 4 5 6 7 8 9 10; do
  STATUS=$(gh run list --workflow publish.yml --limit 1 --json status --jq '.[0].status')
  CONCLUSION=$(gh run list --workflow publish.yml --limit 1 --json conclusion --jq '.[0].conclusion')
  echo "Attempt $i: status=$STATUS conclusion=$CONCLUSION"
  if [ "$STATUS" = "completed" ]; then break; fi
  sleep 30
done
```

Expected final: `completed` + `success`. If `failure`, inspect logs with `gh run view --log <id>`.

- [ ] **Step 4: Verify the new version is live on npm**

```bash
sleep 10
npm view @empoweredvote/ev-ui version
```

Expected: the new version from Step 2 (e.g., `0.4.0`). If the registry hasn't updated, wait 30s and retry.

---

## Task 6: Wait For / Manually Apply essentials Auto-Bump

The release in Task 5 fires `repository_dispatch` to all four consumer repos including `essentials`. The auto-bump workflow in essentials opens a PR and auto-merges patch/minor.

- [ ] **Step 1: Check essentials for the auto-bump PR**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
sleep 30
gh pr list --state all --search "ev-ui" --limit 5
```

Expected: a new PR with title like "chore: bump @empoweredvote/ev-ui to 0.4.0". Status should be `MERGED`.

If the PR doesn't appear after 2 minutes OR if it exists but failed to merge (e.g., because of the npm-registry race condition seen in Plan B Task 4), fall back to a manual bump:

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
git checkout main
git pull origin main
npm install @empoweredvote/ev-ui@0.4.0 --save-exact=false
```

Then commit and push:
```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
git add package.json package-lock.json
git commit -m "chore: bump @empoweredvote/ev-ui to 0.4.0 (manual — auto-bump race)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
git push origin main
```

- [ ] **Step 2: Pull latest essentials main and verify node_modules**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
git pull origin main
npm install
grep '"@empoweredvote/ev-ui"' package.json
cat node_modules/@empoweredvote/ev-ui/package.json | grep '"version"'
```

Expected: both show `0.4.0` (or the new version from Task 5).

- [ ] **Step 3: Runtime verify new exports are available**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
node -e "
import('@empoweredvote/ev-ui').then(m => {
  const expected = ['TopicTierBadge', 'CompassCoverageCallout', 'ExpandCompassNudge', 'computeTierCoverage'];
  for (const name of expected) {
    console.log(name + ':', typeof m[name]);
  }
}).catch(e => { console.error(e); process.exit(1); });
"
```

Expected: all four print `function`.

---

## Task 7: Add Coverage Callout to essentials Results.jsx

**Files:**
- Modify: `essentials/src/pages/Results.jsx`

Adds the coverage callout above the results grid. Logic: for each tier present in the current results, count how many of the voter's compass topics apply at that tier. If `< 3` AND the user has a non-empty compass, render a `CompassCoverageCallout` for that tier.

**Critical lookup before editing:** The plan was drafted against a 1011-line file. Before editing, read the current state of Results.jsx around the main render — specifically where the results grid starts and where the filter sidebar ends. The exact line numbers may drift, so use grep to find stable anchors.

- [ ] **Step 1: Read the current imports and find the main render block**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
grep -n "from '@empoweredvote/ev-ui'\|useCompass\|GovernmentBodySection\|return (" src/pages/Results.jsx | head -20
```

Identify:
- The `import ... from '@empoweredvote/ev-ui'` line (expected near line 3)
- The `useCompass()` hook call (need to know if it's already used)
- The line where `GovernmentBodySection` starts being rendered (~line 929 in the current version)

Read a ~60-line window around each anchor to confirm the current code matches this plan's assumptions.

- [ ] **Step 2: Extend the ev-ui import**

Find the existing import line (something like):
```jsx
import { GovernmentBodySection, SubGroupSection, PoliticianCard, useMediaQuery, tierColors } from '@empoweredvote/ev-ui';
```

Replace with:
```jsx
import { GovernmentBodySection, SubGroupSection, PoliticianCard, useMediaQuery, tierColors, CompassCoverageCallout, computeTierCoverage } from '@empoweredvote/ev-ui';
```

If the existing import looks different (e.g., line break, different field order), preserve the formatting and just add the two new imports.

- [ ] **Step 3: Confirm `useCompass` is already imported + called**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
grep -n "useCompass" src/pages/Results.jsx
```

Expected: at least one import and one call. If `useCompass` isn't already used in Results.jsx, add the import from `../contexts/CompassContext` and call it in the Results function to get `selectedTopics` and `allTopics`:

```jsx
import { useCompass } from '../contexts/CompassContext';
// ... inside the component:
const { selectedTopics, allTopics } = useCompass();
```

(Only add these if they're not already present. If the variables are already destructured elsewhere in the component, use the existing reference.)

- [ ] **Step 4: Compute tier coverage and derive missing tiers**

Find a stable location inside the `Results` component function body, after all the hooks and before the `return (` statement. A good anchor is `const renderPoliticianCard = (pol) => {` — you'll add code above this.

Add:

```jsx
// Plan C: tier coverage analysis for the coverage callout
const selectedTopicObjects = (allTopics ?? []).filter((t) =>
  (selectedTopics ?? []).map(String).includes(String(t.id))
);
const tierCoverage = computeTierCoverage(selectedTopicObjects);
const COMPASS_URL = import.meta.env.VITE_COMPASS_URL || 'https://compass.empowered.vote';

// Build a list of tiers that (a) have <3 applicable topics in the user's compass
// and (b) are present in the current results set. We use the group filter if
// one is selected; otherwise we show callouts for all under-covered tiers.
const currentResultsTiers = (() => {
  // If the user has filtered to a specific group, only that tier is in view.
  if (selectedFilter && selectedFilter !== 'all') {
    return [selectedFilter]; // 'local' | 'state' | 'federal'
  }
  // Otherwise: all three. The callout will only show for under-covered ones.
  return ['federal', 'state', 'local'];
})();

const underCoveredTiers = currentResultsTiers.filter((tier) => {
  if (!selectedTopics || selectedTopics.length === 0) return false; // no compass yet = different UX, don't nudge here
  return tierCoverage[tier] < 3;
});
```

**Important:** `selectedFilter` is the state variable that backs the "All / Local / State / Federal" radio group in the filter sidebar. Confirm this exists in the file — grep for `selectedFilter` in Results.jsx. If the variable name is different (e.g., `group`, `activeGroup`, `tierFilter`), use whatever is actually in the file. If the filter sidebar isn't wired through state at all, skip the filter-aware branch and always use `['federal', 'state', 'local']`.

- [ ] **Step 5: Render the callouts above the grid**

Find the main content area where the results grid begins. A good anchor is the first `<main` element or the first `GovernmentBodySection` render. Add the callouts just above the group list.

Search for something like:
```jsx
<main
```
or
```jsx
{/* Government bodies list */}
```

Add a render block just above the existing grid:

```jsx
{underCoveredTiers.length > 0 && (
  <div className="mb-2">
    {underCoveredTiers.map((tier) => (
      <CompassCoverageCallout
        key={tier}
        tier={tier}
        count={tierCoverage[tier]}
        totalSelected={selectedTopics?.length ?? 0}
        compassUrl={`${COMPASS_URL}?return=${encodeURIComponent(window.location.href)}`}
      />
    ))}
  </div>
)}
```

Place this inside the same parent as the existing results grid content, just before the grid starts.

- [ ] **Step 6: Build essentials and fix any issues**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
npm run build 2>&1 | tail -15
```

If the build fails with an unresolved variable (e.g., `selectedFilter is not defined`), the variable name in your edits doesn't match the actual file. Grep for the real name and adjust. Do NOT commit a broken build.

- [ ] **Step 7: Runtime verification via dev server + Playwright (or direct curl)**

Start the essentials dev server:
```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
npm run dev > /tmp/essentials-dev.log 2>&1 &
DEV_PID=$!
sleep 6
grep -i "local\|5173\|ready" /tmp/essentials-dev.log | head -5
```

Record the dev URL (likely http://localhost:5173 or another port if 5173 is occupied).

The controller will use Playwright to navigate to `/results?q=200+W+6th+St,+Bloomington,+IN+47404`, inject a guest compass with mostly federal topics into localStorage (similar to Plan B Task 8), and verify that the coverage callout renders for state and local tiers.

**Do not commit yet.** Report back with:
- Dev server URL
- Whether the build passed
- Confirmation that the callouts render (pending visual check by the controller)

---

## Task 8: Add Expand Compass Nudge to essentials CompassCard.jsx

**Files:**
- Modify: `essentials/src/components/CompassCard.jsx`

Adds a small nudge below the StanceAccordion when the user has a compass AND the politician has stances on topics the user hasn't answered.

- [ ] **Step 1: Read current CompassCard.jsx**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
wc -l src/components/CompassCard.jsx
grep -n "from '@empoweredvote/ev-ui'\|StanceAccordion\|allPolTopics" src/components/CompassCard.jsx
```

Confirm the imports and key variables. The current file (417 lines as of this plan) has:
- Imports from `@empoweredvote/ev-ui`: `RadarChartCore`, `StanceAccordion`
- Local variable `allPolTopics` (all topics the politician has stances on)
- Local variable `userAnswers` from `useCompass()`
- Two branches: `hasUserCompass` true (radar + accordion) and false (guest CTA + accordion)

- [ ] **Step 2: Extend the ev-ui import**

Find the existing import line:
```jsx
import { RadarChartCore, StanceAccordion } from '@empoweredvote/ev-ui';
```

Replace with:
```jsx
import { RadarChartCore, StanceAccordion, ExpandCompassNudge } from '@empoweredvote/ev-ui';
```

- [ ] **Step 3: Compute the missing-topics count**

Find the block where `allPolTopics` is computed (around line 135-139). After that block, add:

```jsx
// Plan C: count topics the politician has stances on that the user hasn't answered
const userAnsweredIds = new Set((userAnswers ?? []).map((a) => String(a.topic_id)));
const missingTopicCount = allPolTopics.filter(
  (t) => !userAnsweredIds.has(String(t.id))
).length;
```

- [ ] **Step 4: Render the nudge below the user-has-compass accordion**

Find the closing `</StanceAccordion>` or the container div that wraps the right zone in the `hasUserCompass` branch. The right zone currently ends around line 324-325 with `</StanceAccordion>` followed by `</div>`.

Immediately after the StanceAccordion element (and its closing div), add:

```jsx
{hasUserCompass && !polLoading && missingTopicCount > 0 && (
  <ExpandCompassNudge
    politicianName={politicianName}
    missingCount={missingTopicCount}
    compassUrl={ctaHref}
  />
)}
```

Place this inside the main grid container so it appears after the two-column grid. If the layout uses a different wrapper, render the nudge as a sibling element that appears after the grid ends.

**Important:** `ctaHref` is already defined in CompassCard.jsx around line 73 (`const ctaHref = \`${COMPASS_URL}?return=...\``). Use it — don't recompute.

`hasUserCompass` is also already defined around line 71. Use it.

- [ ] **Step 5: Build essentials**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
npm run build 2>&1 | tail -10
```

Expected: clean build, no errors.

- [ ] **Step 6: Do NOT commit yet**

The controller will use Playwright to visually verify both this and Task 7's changes together before committing. Leave the dev server running.

---

## Task 9: Add Office Engagement Level Treatment to Profile.jsx

**Files:**
- Modify: `essentials/src/pages/Profile.jsx`

Adds explicit treatment for two cases the current UX handles silently:
1. **Administrative offices** (`policy_engagement_level === 'none'`) — a short "this office doesn't take policy positions" note
2. **Contested-election judges without stance research** — a short "judges are evaluated on record, not positions" note

Both render in place of where CompassCard would have rendered, so there's a coherent "why is there no compass here" explanation.

- [ ] **Step 1: Read current Profile.jsx**

```bash
cat /Users/chrisandrews/Documents/GitHub/essentials/src/pages/Profile.jsx
```

Confirm the current structure. The `CompassCard` is rendered around line 169-173 with politician props. The component itself gates on `politicianIdsWithStances` and returns null for politicians without stances.

- [ ] **Step 2: Check that `pol` includes `policy_engagement_level`**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
grep -n "policy_engagement_level\|fetchPolitician" src/lib/api.jsx src/pages/Profile.jsx 2>&1 | head -10
```

Confirm that the `fetchPolitician` API call returns the engagement level on the politician object. This was exposed by Plan A Task 6. If for some reason the API response doesn't include it yet (e.g., route layer strips it), STOP and report DONE_WITH_CONCERNS.

You can also hit the live API:
```bash
curl -s "https://api.empowered.vote/api/essentials/politicians/4d20abb8-b05a-444c-883d-03eb4b43d166" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log('policy_engagement_level:', data.policy_engagement_level);
console.log('is_judicial:', data.is_judicial);
"
```

Expected: `policy_engagement_level: none` for Nicole Bolden (city clerk).

- [ ] **Step 3: Import `useCompass` in Profile.jsx if not already**

```bash
grep -n "useCompass" /Users/chrisandrews/Documents/GitHub/essentials/src/pages/Profile.jsx
```

If not present, add:
```jsx
import { useCompass } from '../contexts/CompassContext';
```

Then inside the Profile function, destructure what's needed:
```jsx
const { politicianIdsWithStances } = useCompass();
```

- [ ] **Step 4: Add the engagement level gate before CompassCard**

Find the block (around line 169-173):
```jsx
<CompassCard
  politicianId={id}
  politicianName={pol.first_name ? `${pol.first_name} ${pol.last_name}` : ''}
  politicianTitle={pol.office_title || ''}
/>
```

Replace with:
```jsx
{(() => {
  // Plan C: explicit treatment for offices where compass doesn't apply
  const engagement = pol.policy_engagement_level || 'full';
  const hasStances = politicianIdsWithStances.has(String(id));

  // Administrative offices — no compass comparison applies
  if (engagement === 'none') {
    return (
      <section className="mt-8">
        <h2 className="text-2xl font-bold mb-4" style={{ fontFamily: "'Manrope', sans-serif" }}>
          Compass & Issues
        </h2>
        <div className="bg-white rounded-xl shadow-sm p-6 text-center">
          <p className="text-gray-600" style={{ fontSize: '15px', lineHeight: 1.6, margin: 0 }}>
            This is an administrative office — it doesn't take policy positions,
            so no compass comparison applies. See the role description and contact
            information above.
          </p>
        </div>
      </section>
    );
  }

  // Contested judges without stance research — honest placeholder
  if (pol.is_judicial && engagement === 'full' && !hasStances) {
    return (
      <section className="mt-8">
        <h2 className="text-2xl font-bold mb-4" style={{ fontFamily: "'Manrope', sans-serif" }}>
          Compass & Issues
        </h2>
        <div className="bg-white rounded-xl shadow-sm p-6 text-center">
          <p className="text-gray-600 mb-2" style={{ fontSize: '15px', lineHeight: 1.6 }}>
            Judges are typically evaluated on their record rather than stated policy positions.
          </p>
          <p className="text-gray-500" style={{ fontSize: '14px', lineHeight: 1.6, margin: 0 }}>
            We're working on surfacing judicial records. In the meantime, you can review the
            role description and contact information above.
          </p>
        </div>
      </section>
    );
  }

  // Default: render the existing CompassCard (handles full-policy offices with stances)
  return (
    <CompassCard
      politicianId={id}
      politicianName={pol.first_name ? `${pol.first_name} ${pol.last_name}` : ''}
      politicianTitle={pol.office_title || ''}
    />
  );
})()}
```

The IIFE pattern keeps the three render cases inline without extracting a helper component (which would be over-engineering for 30 lines of JSX).

- [ ] **Step 5: Build essentials**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
npm run build 2>&1 | tail -10
```

Expected: clean build.

- [ ] **Step 6: Restart the dev server**

If the dev server from earlier tasks is still running, Vite HMR should already have picked up the changes. Otherwise restart:

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
pkill -f "vite.*essentials" 2>/dev/null || true
sleep 1
npm run dev > /tmp/essentials-dev.log 2>&1 &
sleep 5
```

- [ ] **Step 7: Do NOT commit yet**

All four task-6, task-7, task-8, task-9 edits are now in the working tree. The controller will do a full visual verification pass across:
- Results page (with a federal-only compass) — expect local + state coverage callouts
- Kerry Thomson profile (full engagement, has stances) — expect compass section + expand nudge
- Nicole Bolden profile (administrative) — expect "administrative office" note
- Geoffrey Bradley profile (contested judge, no stances) — expect "judges are evaluated on record" note

If anything looks wrong, iterate. If everything looks right, proceed to the commit task.

---

## Task 10: Full Visual Verification via Playwright

**Files:** no code changes — this is controller-side verification.

Using the dev server started in earlier tasks, navigate to each of the four test surfaces and verify the new elements render as expected. The controller (not the implementer subagent) runs this task.

- [ ] **Step 1: Set up a known compass state in localStorage**

Navigate to the essentials dev URL, then via `browser_evaluate` set:

```javascript
localStorage.setItem('ev:guestCompass', JSON.stringify({
  answers: {
    "Tariffs": 4,
    "Ukraine Support": 3,
    "Social Security": 2,
    "Medicare/aid": 4,
  },
  selectedTopics: ['<id of tariffs>', '<id of ukraine>', '<id of social security>', '<id of medicare/aid>'],
}));
```

(Exact storage key may differ — check `essentials/src/lib/compass.js` for `saveGuestCompass`.)

This simulates a voter whose compass is 100% federal topics — so local and state callouts should fire.

- [ ] **Step 2: Results page verification**

Navigate to `/results?q=200+W+6th+St,+Bloomington,+IN+47404`. Expect:
- Coverage callouts for **state** and **local** tiers rendering above the grid (because the compass has 0 state/local topics)
- No federal callout (compass has 4 federal topics, ≥3)
- Existing grid unchanged otherwise

Take a screenshot named `plan-c-results-callouts.png`.

- [ ] **Step 3: Kerry Thomson profile verification**

Navigate to `/politician/1c6dbdaf-e110-48d3-9b88-27f911d9521f`. Expect:
- Existing Compass & Issues section renders as before (with user having a guest compass now, it should render the radar state not the guest CTA)
- **New:** `ExpandCompassNudge` rendered below the StanceAccordion with copy like "Kerry Thomson has stances on N more topics you haven't answered yet" where N > 0 (because the user has only 4 topics and Thomson has 15)

Screenshot: `plan-c-thomson-nudge.png`.

- [ ] **Step 4: Nicole Bolden profile verification**

Navigate to `/politician/4d20abb8-b05a-444c-883d-03eb4b43d166`. Expect:
- **New:** Compass & Issues section renders with "This is an administrative office — it doesn't take policy positions..." message
- No radar, no stance accordion

Screenshot: `plan-c-bolden-admin.png`.

- [ ] **Step 5: Geoffrey Bradley profile verification**

Navigate to `/politician/999a9d38-9894-45f0-80c7-228880089699`. Expect:
- **New:** Compass & Issues section renders with "Judges are typically evaluated on their record..." message

Screenshot: `plan-c-bradley-judge.png`.

- [ ] **Step 6: Report findings**

The controller reviews the four screenshots. If any render wrong, dispatch a fix task pointing at the specific issue. If all four match, proceed to commit.

- [ ] **Step 7: Stop the dev server**

```bash
kill <DEV_PID>
```

---

## Task 11: Commit and Push essentials Changes

**Files:**
- Commit: `essentials/src/pages/Results.jsx`, `essentials/src/pages/Profile.jsx`, `essentials/src/components/CompassCard.jsx`, possibly `package.json` + `package-lock.json` if Task 6 did a manual bump

- [ ] **Step 1: Review the changes one more time**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
git status -s
git diff --stat
```

Expected modified files:
- `src/pages/Results.jsx`
- `src/pages/Profile.jsx`
- `src/components/CompassCard.jsx`
- (optionally) `package.json`, `package-lock.json` from Task 6

If the auto-bump in Task 6 landed via PR merge, `package.json` should already be clean on main. If Task 6 did a manual bump, it's part of this commit.

If any unrelated files are modified, STOP and escalate — don't bundle them.

- [ ] **Step 2: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
git add src/pages/Results.jsx src/pages/Profile.jsx src/components/CompassCard.jsx
# If package.json was part of Task 6's manual bump and isn't already on main:
# git add package.json package-lock.json
git commit -m "$(cat <<'EOF'
feat(essentials): tier coverage callouts + engagement level treatment

Plan C deliverables:

Results.jsx:
- Compute tier coverage from the voter's selected compass topics
- Render CompassCoverageCallout above the grid for tiers that have <3
  applicable topics in the user's compass AND are in the current results
  view (respects the filter sidebar's active group)

CompassCard.jsx:
- Render ExpandCompassNudge below the StanceAccordion when the user has
  a compass and the politician has stances on topics the user hasn't
  answered yet. Deep-links into the compass to expand coverage

Profile.jsx:
- Administrative offices (policy_engagement_level = 'none') now render
  an explicit "doesn't take policy positions" note in the Compass &
  Issues slot instead of rendering nothing
- Contested-election judges without stance research render a "evaluated
  on record" note, acknowledging the compass gap honestly

All three changes consume ev-ui 0.4.0's new exports
(CompassCoverageCallout, ExpandCompassNudge, computeTierCoverage).

Tier flags are metadata only — they drive the callout's recommendation
logic but do not filter compass rendering or hide politicians.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Push to main**

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials
git push origin main
```

Render will auto-deploy essentials.empowered.vote on merge to main.

Record the commit SHA and push result.

---

## Task 12: Deployed Verification

- [ ] **Step 1: Wait for Render to pick up the push**

```bash
sleep 180  # 3 minutes
```

- [ ] **Step 2: Visit each deployed surface and verify**

Using Playwright, re-run the four verifications from Task 10 against `https://essentials.empowered.vote` (not localhost). Inject the same guest compass state in the browser and navigate to each test ID.

Screenshots this time:
- `plan-c-deployed-results.png`
- `plan-c-deployed-thomson.png`
- `plan-c-deployed-bolden.png`
- `plan-c-deployed-bradley.png`

If the deployed version doesn't match the local version, investigate: likely a Render deploy lag or a different build path. Retry in 2 minutes.

---

## Plan C Complete

After all tasks pass, the deliverables are:

1. ✅ `@empoweredvote/ev-ui@0.4.0` published with three new exports: `CompassCoverageCallout`, `ExpandCompassNudge`, `computeTierCoverage`
2. ✅ essentials Results page shows tier coverage callouts when the voter's compass is poorly matched to the tier(s) in view
3. ✅ essentials politician profile shows an "expand your compass" nudge below the deep stance breakdown when the politician has more topics than the user has answered
4. ✅ essentials politician profile renders explicit "administrative office" note for `none` engagement chambers (recorders, auditors, surveyors, coroners, assessors, clerks, treasurers)
5. ✅ essentials politician profile renders explicit "judges evaluated on record" note for contested-election judges without stance research
6. ✅ All existing UX (Kerry Thomson's compass section, the StanceAccordion, the radar chart) continues to work unchanged

**Visible user impact:**

| Voter situation | Before Plan C | After Plan C |
|---|---|---|
| Has federal-only compass, looks up local officials | Sparse compass comparisons, no explanation | Banner suggests adding local topics, click-through to compass builder |
| Views Kerry Thomson profile with limited compass | Sees partial comparison, no path to more | Sees comparison + nudge showing N more topics available |
| Views Nicole Bolden (city clerk) profile | Silently no compass section — unclear why | Explicit "administrative office" note |
| Views Geoffrey Bradley (circuit judge) profile | Silently no compass section — unclear why | "Judges evaluated on record" note |

**Not delivered by Plan C (still out of scope):**
- Retention judge track record data (sentencing patterns, reversal rates, ABA ratings) — future workstream
- Quote deidentification for read-rank — future workstream
- Candidate vs politician data model split — future workstream
- Topic rewrite workflow — Plan D

**Unblocks:** Plan D can now happen independently. The user-facing v1 of the tier-scoping work is complete after Plan C.
