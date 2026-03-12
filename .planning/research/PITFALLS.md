# Pitfalls Research

**Domain:** Cross-app localStorage sharing, monorepo app extraction, verdict data integration, Cloudflare Pages deployment
**Researched:** 2026-03-11
**Confidence:** HIGH — browser storage behavior verified via MDN/OWASP; deployment patterns verified via Cloudflare docs; code patterns verified from direct codebase inspection of `useReadRankStore.ts`, `compass.js`, `Layout.jsx`, `netlify.toml`

---

## Critical Pitfalls

### Pitfall 1: localStorage Is Origin-Isolated — Subdomains Cannot Share It Directly

**What goes wrong:**
The milestone calls for "shared `.empowered.vote` localStorage" between `readrank.empowered.vote`, `compass.empowered.vote`, and `essentials.empowered.vote`. The browser's same-origin policy makes this impossible without an explicit architectural workaround. `readrank.empowered.vote` and `compass.empowered.vote` are distinct origins. A key written at one subdomain is completely invisible at another subdomain — the `guestCompass` key written by CompassV2 at `compass.empowered.vote` will NOT be readable by essentials at `essentials.empowered.vote`.

**Why it happens:**
localStorage is partitioned strictly by origin (protocol + hostname + port). Unlike cookies, there is no `Domain=.empowered.vote` attribute for localStorage. The Web Storage API has never supported cross-subdomain sharing. The older `document.domain` hack that used to enable this is fully deprecated in modern browsers (Chrome 115+, Firefox 101+).

**How to avoid:**
Choose one of two architectures and commit before writing any sharing code.

Option A (recommended): Use the backend as the shared store. Verdicts and compass data are written to the server. All apps read from the API. Guest users get a server-assigned anonymous session ID stored in a cookie with `Domain=.empowered.vote` — cookies ARE shareable across subdomains. This supports cross-device sync and logged-in sync without any client-side hacks.

Option B (client-side only, guest-only): Host an iframe hub at the root domain (`empowered.vote/hub.html`). Apps communicate via `postMessage`. The hub reads/writes localStorage on the root origin. This is what libraries like `zendesk/cross-storage` do. It is fragile — if the hub iframe fails to load, all state sharing silently breaks with no error visible to the user.

**Warning signs:**
- Code that calls `localStorage.setItem()` on one subdomain expecting it to be readable on another
- Testing only on localhost where all apps share `localhost:XXXX` origin — this appears to work but fails in production where subdomains are distinct origins
- `guestCompass` key written by CompassV2 not appearing in the Essentials DevTools Application → Storage tab for `essentials.empowered.vote`

**Phase to address:**
Shared storage architecture design — must be decided before any integration work begins.

---

### Pitfall 2: Zustand and Raw localStorage Key Collisions Between Apps

**What goes wrong:**
The read-rank Zustand store currently persists under the key `readrank-storage`. CompassV2 uses bare keys: `answers`, `selectedTopics`, `invertedSpokes`, `calibration_completed`, etc. Essentials uses `guestCompass`. If both apps are ever served from the same origin (during development on localhost, or if routing is consolidated), keys will collide silently. More critically: if the shared-domain architecture uses a single root origin with path routing, both apps' localStorage will occupy the same namespace and collide.

**Why it happens:**
Each app was written independently without a cross-app key namespace convention. Bare keys like `answers` are collision-prone. Zustand's `persist` middleware uses the `name` field as-is with no automatic app prefix.

**How to avoid:**
Enforce a prefix convention during extraction, before any integration code is written. Rename all Zustand store keys and raw `localStorage` keys:
- CompassV2: `ev-compass:answers`, `ev-compass:selectedTopics`, `ev-compass:invertedSpokes`, etc.
- Read & Rank: `ev-readrank:issueProgress` (rename from `readrank-storage`)
- Essentials: `ev-essentials:guestCompass` (rename from `guestCompass`)
- Shared verdicts data accessible to both apps: `ev-shared:verdicts`

The rename needs a one-time migration (see Pitfall 8 below — Zustand key migration) to avoid silently resetting existing user state.

**Warning signs:**
- Any bare localStorage key without an app prefix (`answers`, `phase`, `selectedTopics`)
- Zustand persist `name` that is a generic word rather than a namespaced identifier
- State unexpectedly reset after deploying one app (collision overwrote the other app's keys)

**Phase to address:**
App extraction phase — rename keys during extraction before any new integration code is written. Do not defer.

---

### Pitfall 3: Retiring the URL Fragment Bridge Without a Migration Path for Existing Users

**What goes wrong:**
The URL fragment bridge (`CompassV2 → Essentials`) is the only mechanism guest users currently have for cross-app compass data. Removing it before the replacement storage mechanism is proven and deployed causes all guest users to lose compass comparison on politician profiles. Even a brief gap (one deploy cycle where bridge is gone but shared storage not yet working) is a visible regression.

**Why it happens:**
Migrations are treated as a simultaneous swap — "remove old, add new" — when they must be staged: "add new while old still works, verify production, then remove old."

**How to avoid:**
Follow a three-step retirement:
1. Deploy the new shared-domain storage mechanism alongside the existing fragment bridge. Both paths live simultaneously.
2. Verify the new path works in production for real guests on all three subdomains.
3. Only then remove the fragment bridge code from CompassV2.

The fragment bridge reading code in `essentials/src/contexts/CompassContext.jsx` already has a fallback chain: `fragment > localStorage cache`. Slot the new shared-storage read into this chain at the same priority: `fragment > shared-storage > empty`. This prevents regression during rollout.

**Warning signs:**
- Fragment bridge removal committed in the same PR as shared-storage implementation
- No end-to-end test verifying: start at `compass.empowered.vote` as guest → navigate to a politician on `essentials.empowered.vote` → compass comparison card appears
- Shared storage verified only on localhost (origin isolation problem does not apply there)

**Phase to address:**
Bridge retirement — must be a distinct phase after shared storage is verified in production.

---

### Pitfall 4: Missing `.npmrc` in New Repo Breaks CI on First Build

**What goes wrong:**
Read & Rank consumes `@chrisandrewsedu/ev-ui` from the GitHub npm registry. The existing `.npmrc` in EV-prototypes contains `//npm.pkg.github.com/:_authToken=${NPM_TOKEN}`. When read-rank is extracted to a new repo, this `.npmrc` must be reproduced in the new repo root. If it is missing, CI fails on `npm install` with a 401 error from GitHub Packages. Local development succeeds silently (developer's global `~/.npmrc` has the token hardcoded), masking the missing file until CI runs.

**Why it happens:**
The `.npmrc` is at the EV-prototypes monorepo root. Developers assume it travels with the project without realizing the new standalone repo has no root `.npmrc`. The global `~/.npmrc` masks the problem locally.

**How to avoid:**
Copy `.npmrc` to the new repo root as part of the extraction. Set `NPM_TOKEN` as an environment variable in the Cloudflare Pages project settings (same pattern used for Netlify). Verify CI can run `npm install` without the developer's local credentials by checking the first Pages build log.

**Warning signs:**
- First Cloudflare Pages build fails with `401 Unauthorized` or `npm ERR! code E401`
- Error message references `npm.pkg.github.com` or `@chrisandrewsedu/ev-ui`
- Local `npm install` succeeds but CI fails

**Phase to address:**
App extraction phase — checklist item before configuring any CI/CD.

---

### Pitfall 5: Cloudflare Pages SPA Routing Returns 404 on Page Refresh

**What goes wrong:**
A React SPA deployed to Cloudflare Pages returns a 404 for any direct URL navigation or page refresh on a non-root path (e.g., `/issue/healthcare`). The existing Netlify configuration handles this via `[[redirects]]` in `netlify.toml`. Cloudflare Pages uses a different mechanism and the Netlify config does not transfer.

The common incorrect fix — adding a `_redirects` file with `/* /index.html 200` to the `public/` directory — can trigger a Cloudflare "Infinite loop" detection if a `404.html` file is also present in `public/`, causing the rule to be silently ignored.

**Why it happens:**
Existing SPA redirect knowledge is Netlify-specific. Developers copy the pattern without checking the Cloudflare-specific requirements for file placement and conflicting files.

**How to avoid:**
Use `wrangler.toml` with `not_found_handling = "single-page-application"` — this is the Cloudflare-native approach and does not require a `_redirects` file. Do not add a `404.html` to `public/`. Verify by deploying and manually navigating to a non-root route in a fresh browser tab (copy-paste the URL into the address bar, do not use React Router's `<Link>`).

**Warning signs:**
- Direct URL navigation to any non-root route returns a Cloudflare 404 page (not the app's 404 component)
- A `404.html` file exists in `public/` or the build output
- `_redirects` file is at the repo root rather than inside the `dist/` build output

**Phase to address:**
Cloudflare Pages deployment phase — verify on first deploy before any other integration work.

---

### Pitfall 6: Visual Redesign Breaking Swipe Gesture Logic

**What goes wrong:**
The agree/disagree swipe mechanic uses `@use-gesture/react` with Framer Motion. The gesture recognizer is bound to a specific DOM element. A visual redesign that restructures component hierarchy — new wrapper divs, changed flex containers, CSS transforms on parent elements, `overflow: hidden` on the card container — can silently break gesture detection: swipes register at the wrong threshold, cards animate incorrectly, or the gesture area does not cover the visible card.

**Why it happens:**
Gesture libraries calculate gesture boundaries from the bound element's bounding rect. CSS transforms and `overflow: hidden` on parent elements shift where gesture coordinates are interpreted. Developers test by clicking/dragging manually in desktop browser and miss edge cases on mobile touch, fast swipes, and small screen widths.

**How to avoid:**
Before any visual redesign work, note which DOM elements receive `useDrag`/`useDrop` `bind()` props. Treat these as constraint zones: do not add `transform` on their parent elements, do not add `overflow: hidden` to the gesture container. After every CSS change to the card component, test swipe behavior using mobile DevTools emulation on both iOS Safari and Android Chrome profiles.

**Warning signs:**
- The element receiving `bind()` props has a new parent with `transform` or `overflow: hidden`
- Cards animate but do not reach the dismiss threshold or dismiss immediately on small movements
- Gestures work on desktop mouse but fail on mobile touch

**Phase to address:**
Visual redesign phase — document gesture boundaries before redesign begins; verify after each significant CSS change to card components.

---

### Pitfall 7: CORS Not Updated for New Subdomain

**What goes wrong:**
Any API call from `readrank.empowered.vote` to `api.empowered.vote` will fail with a CORS error unless `readrank.empowered.vote` is added to the allowlist in `internal/middleware/middleware.go`. The backend currently has explicit allowed origins. The new subdomain is not there. This is a silent failure from the user's perspective — the app loads, the UI appears, but network requests return nothing.

**Why it happens:**
CORS changes are easy to forget during repo extraction because the work is in the backend, not in the frontend being extracted.

**How to avoid:**
Add `readrank.empowered.vote` to the CORS allowlist in `internal/middleware/middleware.go` in the same phase as the Cloudflare Pages deployment — not as a follow-up. Verify from the deployed URL using browser DevTools Network tab, not from localhost.

**Warning signs:**
- API calls from the deployed app return CORS errors in browser console
- App works on localhost but all data-fetching fails on the deployed domain
- `Access-Control-Allow-Origin` header missing from API responses when Origin is `https://readrank.empowered.vote`

**Phase to address:**
App extraction / Cloudflare Pages deployment phase — backend change accompanies frontend deployment.

---

### Pitfall 8: Renaming Zustand Persist Key Silently Resets All Existing User State

**What goes wrong:**
When `readrank-storage` is renamed to `ev-readrank:issueProgress` (or any new key), Zustand no longer finds data under the old key on startup. The store initializes to its empty default state. All existing user progress — evaluated quotes, ranked results, badge assignments — is silently gone. Users who were mid-evaluation return to a blank hub with no indication that their progress was lost.

**Why it happens:**
Zustand's `persist` middleware reads from the key specified in `name`. If the key changes, the old data is orphaned in localStorage under the old key name. There is no automatic migration.

**How to avoid:**
Implement a one-time migration in the store's `onRehydrateStorage` callback:
1. On store init, check if the old key (`readrank-storage`) exists in localStorage.
2. If it does, read the data, write it to the new key, and remove the old key.
3. If it does not exist, proceed normally.

This migration runs once per user and handles the transition transparently. After 30 days post-deploy, the migration code can be removed.

**Warning signs:**
- Users reporting lost progress after an update
- DevTools shows old key still in localStorage alongside empty new key
- Store initializes to empty state despite data being visible under the old key name

**Phase to address:**
App extraction phase — implement migration in the same commit that renames the Zustand key.

---

### Pitfall 9: ev-ui Version Mismatch Between New Read & Rank Repo and Other Apps

**What goes wrong:**
The read-rank `package.json` currently pins `@chrisandrewsedu/ev-ui` at `^0.1.6`. The essentials and CompassV2 apps are at `^0.1.41`. When read-rank is extracted to a standalone repo, it starts from the EV-prototypes version (`0.1.6`) unless explicitly updated. This means:
- Read & Rank may consume a version of ev-ui that is missing components added in 0.1.7–0.1.41
- If the integration requires new shared components (e.g., a verdict display component added to ev-ui), both the library and the consuming apps must be updated in coordination
- Conflicting React versions between ev-ui peer dependencies and the app's React version cause runtime errors

**Why it happens:**
The read-rank prototype was not kept in sync with ev-ui updates because it was a standalone prototype, not a production app. Extraction is the moment this divergence becomes a real problem.

**How to avoid:**
Before or during extraction, update ev-ui to the current production version (`0.1.41` or whatever is current at extraction time). Run the app, fix any breaking changes, then proceed with the standalone repo. Do not defer this update — every version behind adds migration complexity.

**Warning signs:**
- `npm install` peer dependency warnings about React version mismatches
- Components that exist in essentials/CompassV2 missing from read-rank's ev-ui version
- Runtime errors about multiple React instances or hook rule violations (symptom of duplicate React copies from version conflict)

**Phase to address:**
App extraction phase — ev-ui version alignment is a prerequisite, not a follow-up.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Testing shared-storage on localhost only | Faster iteration | Cross-subdomain isolation bug only appears in production | Never — must test on real staging subdomains |
| Using bare localStorage keys without app prefix | Slightly less typing | Silent key collisions between apps on shared origin | Never in a multi-app context |
| Keeping EV-prototypes `netlify.toml` as-is after extraction | No migration effort | Netlify still rebuilds read-rank unnecessarily; costs CI minutes; dead build artifact | Acceptable short-term; remove within same milestone |
| Storing full verdict objects (quotes + results) in localStorage | Simpler than API calls | 5 MB quota fills up if user evaluates many quotes; `QuotaExceededError` crashes writes silently | Acceptable for guest MVP; must be replaced before production verdict sync |
| Not versioning the localStorage schema | Saves initial setup | Old schema silently corrupts state when data shape changes with no error shown | Never if schema may evolve |
| Skipping Zustand key migration when renaming persist key | Saves a few lines of code | Silent data loss for existing users | Never |

---

## Integration Gotchas

Common mistakes when connecting components of this system.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| ev-ui in new standalone repo | Starting from `^0.1.6` (EV-prototypes version) | Update to current production version (`0.1.41+`) before extraction |
| GitHub npm registry in new repo | Missing `.npmrc` causes 401 on CI | Copy `.npmrc` from EV-prototypes; set `NPM_TOKEN` env var in Cloudflare Pages settings |
| Cloudflare Pages env vars | `VITE_API_URL` not set in Pages project settings; build succeeds but app calls `undefined` | Set all `VITE_*` env vars in the Cloudflare Pages dashboard before first preview build |
| Backend CORS | `readrank.empowered.vote` not in CORS allowlist in `middleware.go` | Add origin to backend CORS list in same phase as Cloudflare deployment |
| Verdicts API endpoint | New endpoint not handling unauthenticated guest access | Follow compass pattern: public GET, protected POST/PUT/DELETE; guest reads by session cookie or anonymous ID |
| Zustand persist key rename | Old data orphaned under old key | Implement `onRehydrateStorage` migration before removing old key |
| Fragment bridge retirement | Bridge removed before replacement verified in production | Stage retirement: new path live → verified in production → old path removed |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Storing full quote text + all results in localStorage | `QuotaExceededError` on `setItem`; silent state corruption | Store only verdict decisions (quoteId + verdict enum); keep full quote text in API response | When user evaluates 50+ quotes across multiple issues |
| Reading verdicts from localStorage on every Essentials profile page render | Profile page re-reads full Zustand store on each render; unnecessary re-renders | Load verdicts once into React context on app mount; memoize per-politician verdict lookup | At any scale — it is an architecture issue, not a scale issue |
| Fetching quotes from API on every profile page visit | Network waterfall per profile view | Cache fetched quotes in component state or context; quotes data changes rarely | At current user volume, not a real concern, but establishes bad patterns |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Trusting localStorage verdict data as authoritative for server-side storage | Malicious user writes arbitrary verdicts to localStorage and syncs to server | Validate quoteId existence and verdict enum values server-side before persisting |
| Not validating `message.origin` in `postMessage` handler if iframe hub approach is used | Cross-origin XSS via crafted postMessage | Always check `event.origin === 'https://empowered.vote'` before processing any hub message |
| Hardcoding the GitHub npm token in `.npmrc` instead of using `${NPM_TOKEN}` variable | Token leaked to git history | Always use `${NPM_TOKEN}` variable reference; never commit a literal token |
| Opening CORS to `*` as a quick fix for the new subdomain | All origins can make credentialed requests to the backend | Add only `readrank.empowered.vote` to the explicit allowlist; never use wildcard origin |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing verdict data on politician profiles without attribution | Verdicts appear as editorial content; users don't know they set them | Always label: "Based on your Read & Rank session" with CTA to Read & Rank if user has no verdicts |
| Verdict UI visible only to users who have used Read & Rank | Non-users see empty space with no context or incentive | Show an empty state with a short explanation and a link to `readrank.empowered.vote` |
| Swipe mechanic with no tap/click alternative | Inaccessible to keyboard users and touch-only users who have trouble dragging | Provide tap-to-agree/disagree buttons alongside swipe; swipe is enhancement, not sole input |
| Redirecting from Netlify `/read-rank/` path with no notice | Users with saved links or bookmarks get 404 | Keep Netlify app alive at old path with a redirect banner, or set up a Netlify redirect to the new domain |
| Redesign resets user progress stored under old Zustand key | Users return to find all issue evaluations gone | Migrate old key on first load; show a notice if migration occurred |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Shared storage working:** Tested on real staging subdomains — not localhost — verify `compass.empowered.vote` writes and `essentials.empowered.vote` reads the same value in different browser tabs
- [ ] **URL fragment bridge retired safely:** CompassV2 no longer serializes compass fragments AND the guest flow still works via the new mechanism — verify end-to-end without fragment in URL
- [ ] **CORS updated in backend:** `readrank.empowered.vote` in `middleware.go` allowlist — verify from deployed URL via browser DevTools Network tab, not localhost
- [ ] **`.npmrc` in new repo:** CI builds `npm install` without developer's local credentials — verify by checking first Cloudflare Pages build log
- [ ] **ev-ui version aligned:** New read-rank repo uses same ev-ui version as essentials and CompassV2 — check `package.json` after extraction
- [ ] **Cloudflare Pages SPA routing:** Direct navigation to non-root path returns app, not Cloudflare 404 — copy a non-root URL into a fresh browser tab and verify
- [ ] **`VITE_API_URL` set:** Network tab shows API calls going to `https://api.empowered.vote`, not `undefined` or `localhost`
- [ ] **Zustand key migration:** Users with data under old key `readrank-storage` are not silently reset — test by seeding old key in DevTools, then loading the new app build
- [ ] **Gesture regression:** Swipe agree/disagree works on mobile after visual redesign — test on iOS Safari and Android Chrome using DevTools device emulation
- [ ] **localStorage quota guard:** `setItem` calls are wrapped in `try/catch`; `QuotaExceededError` is handled gracefully, not silently swallowed

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Shared storage does not work in production due to origin isolation | HIGH | Implement backend-mediated storage immediately; this cannot be fixed with a client-side workaround without introducing the iframe hub architecture |
| Key collision corrupts user state | MEDIUM | Deploy fix checking both old and new key names; clear corrupted state; show "your progress was reset" notice |
| Fragment bridge removed before replacement verified | HIGH | Revert the removal commit immediately; do not try to rebuild the bridge — restore it and follow the three-step retirement process |
| CI fails with 401 on npm install | LOW | Add `.npmrc` to new repo and set `NPM_TOKEN` in Cloudflare Pages env settings; trigger rebuild |
| Cloudflare 404 on page refresh | LOW | Add `wrangler.toml` with `not_found_handling = "single-page-application"` or correct `_redirects` file placement; redeploy |
| Gesture broken after redesign | MEDIUM | Revert CSS changes to gesture container elements; redesign only non-gesture elements; re-verify gesture after each isolated change |
| CORS error on deployed domain | LOW | Add origin to `middleware.go`; deploy backend; verify |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| localStorage origin isolation | Shared storage architecture design (before implementation) | Architecture decision documented; no localStorage cross-subdomain code written until decision is made |
| Key namespace collisions | App extraction phase | All localStorage keys prefixed with `ev-readrank:` or `ev-compass:` before new integration code |
| Fragment bridge retirement regression | Bridge retirement phase (own phase, after storage verified in production) | End-to-end guest flow: CompassV2 → Essentials profile shows compass with no fragment in URL |
| Missing `.npmrc` in new repo | App extraction phase | First CI build succeeds without developer local credentials |
| Cloudflare Pages SPA routing | Cloudflare deployment phase | Direct URL navigation to non-root path returns app |
| Gesture regression in visual redesign | Visual redesign phase | Gesture boundaries documented pre-redesign; mobile-tested post-redesign |
| CORS missing for new subdomain | App extraction / deployment phase | API call from deployed `readrank.empowered.vote` succeeds; no CORS error in browser console |
| Zustand key migration for existing users | App extraction phase | Old key detected and migrated on first load; verified with manual DevTools test |
| ev-ui version mismatch | App extraction phase | `package.json` shows same ev-ui version as other consuming apps |
| localStorage quota overflow | Verdict storage design phase | `setItem` wrapped in try/catch; only minimal verdict data stored client-side |

---

## Sources

- [MDN — Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API)
- [MDN — Same-origin policy](https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/Same-origin_policy)
- [MDN — Storage quotas and eviction criteria](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria)
- [OWASP — HTML5 Security Cheat Sheet (Web Storage)](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html)
- [Cross-Domain State Sharing: From Hacks to Real-Time Sync](https://adrai.medium.com/cross-domain-state-sharing-from-hacks-to-real-time-sync-1336763f05c5)
- [Cloudflare Pages — Single Page Application routing](https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/)
- [Cloudflare Pages — Custom domains](https://developers.cloudflare.com/pages/configuration/custom-domains/)
- [Cloudflare Community — 404 on SPA routes after Pages deployment](https://community.cloudflare.com/t/404-error-on-spa-routes-dashboard-pages-headers-rule-not-activating/869055)
- [Namespace localStorage — Emad Alam/Medium](https://medium.com/@emadalam/namespace-localstorage-e2d1d2e68b20)
- [Handling localStorage QuotaExceededError — Matteo Mazzarolo](https://mmazzarolo.com/blog/2022-06-25-local-storage-status/)
- [Extracting Parts of Git Repository and Keeping the History — ariya.io](https://ariya.io/2014/07/extracting-parts-of-git-repository-and-keeping-the-history)
- Codebase inspection: `EV-prototypes/read-rank/src/store/useReadRankStore.ts` — Zustand persist key `readrank-storage`, ev-ui `^0.1.6`
- Codebase inspection: `essentials/src/lib/compass.js` — `GUEST_COMPASS_KEY = "guestCompass"`
- Codebase inspection: `CompassV2/src/components/Layout.jsx` — bare localStorage keys (`answers`, `selectedTopics`, etc.)
- Codebase inspection: `EV-prototypes/netlify.toml` — current SPA redirect configuration

---
*Pitfalls research for: v2026.3.4 Read & Rank Integration — cross-app localStorage sharing, monorepo extraction, verdict integration, Cloudflare Pages deployment*
*Researched: 2026-03-11*
