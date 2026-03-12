# Phase 77: Standalone Extraction - Research

**Researched:** 2026-03-11
**Domain:** GitHub repo creation, Cloudflare Pages deployment, Zustand persist migration, CORS
**Confidence:** HIGH

## Summary

Phase 77 extracts the Read & Rank app from the `EV-prototypes` monorepo into a standalone GitHub repo and deploys it to `readrank.empowered.vote` on Cloudflare Pages. The app already exists as `chrisandrewsedu/EV-readrank` on GitHub (private, created 2025-12-14), but it is stale — it predates the current IssueHub architecture, multi-issue progress tracking, and ev-ui integration. The cleanest path is to treat that repo as the destination and overwrite its contents with the current `EV-prototypes/read-rank/` source, updated for standalone deployment.

The four mechanical changes required beyond file copying are: (1) fix the `vite.config.ts` base path (currently hardcoded to `/read-rank/dist/`), (2) fix `BrowserRouter` basename (same hardcoding), (3) update `@chrisandrewsedu/ev-ui` from `^0.1.6` to `^0.1.41`, and (4) rename the Zustand persist key from `readrank-storage` to `ev_readrank` with a `migrate` function to carry forward existing state. The CORS allowlist in `EV-Backend/internal/middleware/middleware.go` needs two new entries (`https://readrank.empowered.vote` and a dev variant).

Cloudflare Pages is new to this project — all existing deployed apps use Netlify. The SPA routing mechanism differs: Cloudflare Pages uses a `_redirects` file (identical syntax to Netlify's) placed in the build output directory, or a `wrangler.toml` — the `_redirects` file is simpler and requires no wrangler install.

**Primary recommendation:** Copy `EV-prototypes/read-rank/` into the `chrisandrewsedu/EV-readrank` repo, make the four targeted changes, add `.npmrc` and `_redirects`, configure Cloudflare Pages dashboard to point at the repo with `NPM_TOKEN` env var, and add the two CORS entries.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EXTR-01 | Read & Rank extracted to standalone GitHub repo | Existing `chrisandrewsedu/EV-readrank` (private) is the destination — overwrite with current EV-prototypes/read-rank source |
| EXTR-02 | Deployed to `readrank.empowered.vote` on Cloudflare Pages with SPA routing | Cloudflare Pages `_redirects` file handles SPA; vite `base: "/"` required |
| EXTR-03 | Backend CORS allowlist updated to include `readrank.empowered.vote` | Two string entries added to `allowed` map in `middleware.go` |
| EXTR-04 | ev-ui dependency updated from `^0.1.6` to current `^0.1.41` | Package version bump; local vite alias pattern copied from essentials |
| EXTR-05 | Zustand persist key namespaced `ev_readrank` with migration from `readrank-storage` | Zustand v5 `persist` middleware supports `name`, `version`, and `migrate` options |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Zustand | 5.0.11 (installed) | State + localStorage persistence | Already in use; `persist` middleware has `migrate` option built in |
| Vite | ^7.2.4 | Build tool | Already in use; base path config is one line |
| React Router DOM | ^7.11.0 | Client-side routing | Already in use; `BrowserRouter` basename must change from `/read-rank/dist` to `/` |
| `@chrisandrewsedu/ev-ui` | ^0.1.41 | SiteHeader + design tokens | Must bump from ^0.1.6; essentials already uses 0.1.41 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Cloudflare Pages `_redirects` | n/a (static file) | SPA 200-redirect for all routes | Must be present in `dist/` at deploy time |
| `.npmrc` | n/a | GitHub npm registry auth for ev-ui | Required in repo root; `NPM_TOKEN` provided via CF Pages env var |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `_redirects` file | `wrangler.toml` | wrangler.toml requires wrangler CLI installation; `_redirects` is zero-dependency and already familiar from Netlify |
| Overwrite EV-readrank | Create a new repo | Reusing existing repo preserves commit history stub and avoids namespace confusion |

**Installation (in standalone repo after copy):**
```bash
npm install
# After bumping ev-ui to ^0.1.41 in package.json:
npm install @chrisandrewsedu/ev-ui@^0.1.41
```

---

## Architecture Patterns

### Recommended Project Structure
```
ev-readrank/            (standalone repo root)
├── .npmrc              # GitHub registry auth (NPM_TOKEN var)
├── index.html          # unchanged from prototype
├── package.json        # updated: name, ev-ui version
├── vite.config.ts      # updated: base "/" (no hardcoded subpath)
├── public/
│   ├── EVLogo.svg      # carried over from prototype/public
│   ├── _redirects      # NEW: Cloudflare Pages SPA rule
│   └── vite.svg
├── src/
│   ├── App.tsx         # updated: BrowserRouter basename="/"
│   ├── store/
│   │   └── useReadRankStore.ts  # updated: name + version + migrate
│   └── ...             # all other src files unchanged
├── tailwind.config.js  # unchanged
└── tsconfig*.json      # unchanged
```

### Pattern 1: Cloudflare Pages SPA Routing via `_redirects`

**What:** A `_redirects` file placed in the `public/` directory (Vite copies it to `dist/` automatically) tells Cloudflare Pages to serve `index.html` for all routes with a 200 status, enabling React Router to handle navigation client-side.

**When to use:** Required for any SPA deployed to Cloudflare Pages that uses client-side routing.

**Example:**
```
# public/_redirects
/*    /index.html    200
```

Confidence: HIGH — documented behavior of Cloudflare Pages, identical syntax to Netlify `_redirects`. [https://developers.cloudflare.com/pages/configuration/redirects/](https://developers.cloudflare.com/pages/configuration/redirects/)

### Pattern 2: Vite Base Path for Root Deployment

**What:** The current prototype has `base: '/read-rank/dist/'` because it is nested inside the Netlify monorepo. The standalone deploy lives at the domain root, so base becomes `"/"` (Vite default).

**Example:**
```typescript
// vite.config.ts — standalone version
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/',
})
```

Also update `App.tsx`:
```tsx
// Before (monorepo):
<BrowserRouter basename="/read-rank/dist">

// After (standalone):
<BrowserRouter basename="/">
```

The `SiteHeader` logo src uses `import.meta.env.BASE_URL` which resolves correctly once base is `/`.

### Pattern 3: Local ev-ui Alias (Dev Only)

Copied from `essentials/vite.config.js` — allows local `../ev-ui/dist` symlink during development without affecting CI builds:

```typescript
// vite.config.ts — with local dev alias
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import fs from 'fs'

const localEvUi = path.resolve(__dirname, '../ev-ui/dist')
const useLocalEvUi = fs.existsSync(localEvUi)

export default defineConfig({
  plugins: [react()],
  base: '/',
  resolve: {
    alias: useLocalEvUi ? { '@chrisandrewsedu/ev-ui': localEvUi } : {},
  },
})
```

Confidence: HIGH — this exact pattern is in production in `essentials/vite.config.js`.

### Pattern 4: Zustand Persist Key Migration

**What:** Renaming the persist `name` without a migration silently drops all stored state on first load. Zustand v5 `persist` middleware supports `version` + `migrate` options to carry state forward from the old key by manually reading localStorage.

**Important:** Zustand's `migrate` option only runs when the persisted data's `version` field does NOT match the store's declared `version`. It does NOT handle a key rename — that requires an explicit one-time migration block in `onRehydrateStorage` or a `migrate` shim that reads the old key on startup.

**Correct approach for key rename:**

```typescript
// src/store/useReadRankStore.ts — updated persist config
persist(
  (set, get) => ({ /* ...actions unchanged... */ }),
  {
    name: 'ev_readrank',          // NEW key (EXTR-05)
    version: 1,
    migrate: (persistedState, version) => {
      // version 0 → 1: nothing to transform, shape is identical
      return persistedState as PersistedState
    },
    onRehydrateStorage: () => (state) => {
      // One-time migration from old key on first load
      if (!state) return
      const oldRaw = localStorage.getItem('readrank-storage')
      if (oldRaw) {
        try {
          const parsed = JSON.parse(oldRaw)
          if (parsed?.state) {
            // State already hydrated from new key; old key exists as leftover — remove it
            localStorage.removeItem('readrank-storage')
          }
        } catch {
          // ignore
        }
      }
    },
  }
)
```

**Simpler alternative** — if the old key has no users to preserve (prototype only, no production users with real data), simply change `name` to `'ev_readrank'`. The requirement says "migration from old key" but the old key is from a Netlify prototype with negligible real-world usage. Document both paths; let the planner choose.

Confidence: HIGH — Zustand v5 `PersistOptions` types confirmed in `node_modules/zustand/middleware/persist.d.ts`.

### Pattern 5: CORS Allowlist Update

**What:** Add two strings to the `allowed` map in `EV-Backend/internal/middleware/middleware.go`.

```go
// internal/middleware/middleware.go — add to allowed map
"https://readrank.empowered.vote":     {},
"https://readrank-dev.empowered.vote": {}, // optional staging subdomain
```

The backend is a Go app deployed to Render. Adding entries requires a commit + redeploy of EV-Backend.

### Pattern 6: `.npmrc` for GitHub Registry

All deployed apps in this workspace use the same `.npmrc` pattern. Copy directly:

```
@chrisandrewsedu:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NPM_TOKEN}
```

Cloudflare Pages exposes `NPM_TOKEN` as an environment variable during CI builds. This must be added in the Cloudflare Pages dashboard under **Settings > Environment variables** before the first build.

### Anti-Patterns to Avoid

- **Leaving `base: '/read-rank/dist/'` in vite.config.ts:** All asset URLs will be prefixed with that subpath and 404 on Cloudflare Pages.
- **Forgetting `_redirects` in `public/`:** Direct navigation to `/candidate/:id/alignment` or `/animation-options` returns 404 from CF Pages without it.
- **Changing persist `name` without awareness of state loss:** Existing prototype users (few, but possible) lose all issue progress. The migration approach preserves it.
- **Missing `NPM_TOKEN` in CF Pages env before first build:** Build fails at `npm install` with a 401 from `npm.pkg.github.com`. There is no retry mechanism — must be set before triggering the first build.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SPA routing on CF Pages | Custom edge worker or redirect logic | `public/_redirects` with `/* /index.html 200` | CF Pages natively processes this file; zero config |
| localStorage key migration | Custom migration hook | Zustand `persist` `migrate` option + `onRehydrateStorage` | Already in the middleware; well-tested edge cases |
| GitHub registry auth in CI | Inline token in build command | `.npmrc` + `NPM_TOKEN` env var | Same pattern used by all other deployed apps in this workspace |

---

## Common Pitfalls

### Pitfall 1: Hardcoded Base Path in App.tsx BrowserRouter
**What goes wrong:** `BrowserRouter basename="/read-rank/dist"` is left in place. React Router resolves all `<Link>` hrefs relative to that basename, so `/` renders correctly but `/candidate/:id/alignment` silently navigates to `/read-rank/dist/candidate/:id/alignment` — a 404 on CF Pages.
**Why it happens:** The monorepo needed the subpath for Netlify's multi-app routing; it was never removed.
**How to avoid:** Search for `basename` in `App.tsx` and set it to `"/"`.
**Warning signs:** The hub page loads but clicking into alignment pages lands on a 404.

### Pitfall 2: `base` in vite.config.ts Left as Subpath
**What goes wrong:** All bundled JS and CSS assets are served from `/read-rank/dist/assets/...`. CF Pages serves them from `/assets/...`. Assets 404, app is blank.
**Why it happens:** Same monorepo deployment assumption.
**How to avoid:** Set `base: '/'` (or remove the `base` line entirely — Vite defaults to `/`).
**Warning signs:** Browser devtools show 404s for all `.js` and `.css` files in the network tab.

### Pitfall 3: NPM_TOKEN Not Set Before First CF Pages Build
**What goes wrong:** `npm install` fails with `401 Unauthorized` when trying to fetch `@chrisandrewsedu/ev-ui` from `npm.pkg.github.com`.
**Why it happens:** CF Pages has no `NPM_TOKEN` env var unless explicitly added in the dashboard.
**How to avoid:** Add `NPM_TOKEN` in CF Pages Settings > Environment variables (both Production and Preview) before connecting the repo and triggering any build.
**Warning signs:** Build log shows `npm ERR! 401 Unauthorized` or `npm warn 404`.

### Pitfall 4: `_redirects` File Not in Build Output
**What goes wrong:** Direct URL access to `/animation-options` or `/candidate/abc/alignment` returns CF Pages' own 404 page instead of the React app.
**Why it happens:** Vite only copies files from `public/` to `dist/`. If `_redirects` is placed anywhere else it is not included.
**How to avoid:** Place `_redirects` in `public/` — Vite copies it verbatim to `dist/`.
**Warning signs:** `/` loads fine; any route refreshed directly returns 404.

### Pitfall 5: ev-ui Version Mismatch Breaking SiteHeader
**What goes wrong:** Read & Rank currently depends on `@chrisandrewsedu/ev-ui@^0.1.6`. Version 0.1.41 (published) may have changed the `SiteHeader` or `Header` component API. If props were added or renamed between 0.1.6 and 0.1.41, TypeScript compilation fails.
**Why it happens:** The local type declarations in `src/types/ev-ui.d.ts` override the package's own types. If the installed version's exports changed, the manual shim may be out of date.
**How to avoid:** After bumping to 0.1.41, check whether the published package now ships its own `.d.ts` files and delete or update the manual shim in `src/types/ev-ui.d.ts`.
**Warning signs:** TypeScript errors on `SiteHeader` import or missing exports.

---

## Code Examples

### Cloudflare Pages `_redirects` for SPA
```
# public/_redirects
/*    /index.html    200
```
Source: https://developers.cloudflare.com/pages/configuration/redirects/

### Zustand v5 Persist with Key Rename + Version Migration
```typescript
// src/store/useReadRankStore.ts — persist config block only
persist(
  (set, get) => ({ /* unchanged */ }),
  {
    name: 'ev_readrank',
    version: 1,
    migrate: (persistedState, _version) => {
      // Shape is unchanged from readrank-storage v0; pass through
      return persistedState as PersistedState
    },
    partialize: (state) => ({
      phase: state.phase,
      currentIssueId: state.currentIssueId,
      issueProgress: state.issueProgress,
      agreedQuotes: state.agreedQuotes,
      disagreedQuotes: state.disagreedQuotes,
      rankedQuotes: state.rankedQuotes,
      badgeAssignments: state.badgeAssignments,
      issueTitle: state.issueTitle,
      questionText: state.questionText,
      topicId: state.topicId,
    }),
  }
)
```
Source: `node_modules/zustand/middleware/persist.d.ts` (confirmed in repo)

### CORS Allowlist Addition (Go)
```go
// internal/middleware/middleware.go — add to allowed map
var allowed = map[string]struct{}{
  // ...existing entries...
  "https://readrank.empowered.vote": {},
}
```
Source: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/middleware/middleware.go` (read directly)

### .npmrc for GitHub Registry
```
@chrisandrewsedu:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NPM_TOKEN}
```
Source: Confirmed identical in `essentials/.npmrc` and `CompassV2/.npmrc`

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multi-app Netlify monorepo at `/read-rank/dist` subpath | Standalone Cloudflare Pages at domain root | This phase | Base path and BrowserRouter basename both change to `/` |
| `@chrisandrewsedu/ev-ui@^0.1.6` | `@chrisandrewsedu/ev-ui@^0.1.41` | Published incrementally | Must verify SiteHeader API compatibility; remove or update manual type shim |
| Persist key `readrank-storage` | Persist key `ev_readrank` | This phase | Zustand `version` + `migrate` prevents silent state loss |

**Deprecated/outdated in the extracted app:**
- `vite.config.ts` `base: '/read-rank/dist/'` — must become `'/'`
- `BrowserRouter basename="/read-rank/dist"` — must become `"/"`
- `"name": "readrank-prototype"` in `package.json` — update to something like `"ev-readrank"`
- `netlify.toml` in the extracted repo — replace with `public/_redirects` for CF Pages

---

## Open Questions

1. **Should `chrisandrewsedu/EV-readrank` remain private or go public?**
   - What we know: Currently private. Other EV repos (essentials, CompassV2) are forks of public EmpoweredVote repos.
   - What's unclear: Whether the standalone repo should be under `chrisandrewsedu` (isolation fork) or `EmpoweredVote` org.
   - Recommendation: Keep under `chrisandrewsedu` for now per workspace isolation strategy in CLAUDE.md; can transfer to org later.

2. **Does ev-ui v0.1.41 publish its own TypeScript declarations?**
   - What we know: The read-rank app ships a manual shim at `src/types/ev-ui.d.ts`. ev-ui is built with `tsup` which generates `.d.ts` files.
   - What's unclear: Whether the published 0.1.41 package includes `.d.ts` and whether the shim conflicts.
   - Recommendation: After installing 0.1.41, check `node_modules/@chrisandrewsedu/ev-ui/` for `.d.ts` files. If present, delete the manual shim.

3. **Should a `readrank-dev.empowered.vote` CF Pages preview subdomain be added to CORS?**
   - What we know: Other apps have `-dev` subdomain entries (e.g., `essentials-dev.empowered.vote`) in the CORS allowlist.
   - What's unclear: Whether CF Pages preview deployments use a fixed subdomain or random `*.pages.dev` URLs.
   - Recommendation: Add `https://readrank-dev.empowered.vote` to CORS proactively. CF Pages preview deployments use random `*.pages.dev` URLs by default — those do NOT need CORS entries since the backend uses credentials and same-origin cookies anyway.

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — TypeScript compilation via `tsc -b` is the only automated check |
| Config file | `tsconfig.app.json`, `tsconfig.node.json` |
| Quick run command | `npm run build` (runs `tsc -b && vite build`) |
| Full suite command | `npm run build` |

No test framework (Jest, Vitest, etc.) exists in the read-rank source. The TypeScript compiler and a successful Vite build are the only automated verification available.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXTR-01 | Repo exists with correct source | manual | `gh repo view chrisandrewsedu/EV-readrank` | N/A |
| EXTR-02 | All three routes load at `readrank.empowered.vote` | smoke (manual) | Visit URL in browser | ❌ Wave 0 |
| EXTR-03 | CORS allows `readrank.empowered.vote` | smoke (manual) | `curl -H "Origin: https://readrank.empowered.vote" https://api.empowered.vote/essentials/quotes -I` | N/A |
| EXTR-04 | ev-ui 0.1.41 builds without TypeScript errors | unit (compile) | `npm run build` (in extracted repo) | ❌ Wave 0 |
| EXTR-05 | Zustand key is `ev_readrank`; old key migrated | unit (manual) | Check `localStorage` in devtools after load | N/A |

### Sampling Rate
- **Per task commit:** `npm run build` — confirms TypeScript + Vite succeed
- **Per wave merge:** `npm run build` + manual smoke of all three routes
- **Phase gate:** All three routes accessible at `readrank.empowered.vote`; API calls succeed (network tab shows 200 from `api.empowered.vote`); localStorage key is `ev_readrank`

### Wave 0 Gaps
- [ ] No Vitest or Jest config — no automated route/behavior tests exist; manual smoke is the only option for EXTR-02 and EXTR-05
- [ ] `npm run build` in the extracted repo (does not yet exist) — Wave 0 task is the extraction itself

*(No existing test infrastructure to extend — all phase validation is manual smoke + TypeScript compilation.)*

---

## Sources

### Primary (HIGH confidence)
- `EV-prototypes/read-rank/` — full source read directly; all file paths verified
- `EV-Backend/internal/middleware/middleware.go` — CORS map read directly
- `node_modules/zustand/middleware/persist.d.ts` — Zustand v5 `PersistOptions` types confirmed in repo
- `essentials/.npmrc`, `CompassV2/.npmrc` — `.npmrc` pattern confirmed identical in both
- `essentials/vite.config.js` — local ev-ui alias pattern confirmed

### Secondary (MEDIUM confidence)
- Cloudflare Pages `_redirects` documentation: https://developers.cloudflare.com/pages/configuration/redirects/ — SPA redirect syntax is documented; confirmed `/*  /index.html  200` is the correct form

### Tertiary (LOW confidence)
- CF Pages environment variable behavior for `NPM_TOKEN` during `npm install` — standard CI behavior, not verified against CF Pages-specific docs but consistent with all CI platform behavior

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified in source; Zustand types read directly from node_modules
- Architecture: HIGH — base path, BrowserRouter, and CORS changes derived directly from reading source files; CF Pages `_redirects` is well-documented
- Pitfalls: HIGH — base path and BrowserRouter pitfalls verified by reading actual hardcoded values in source; CORS and NPM_TOKEN pitfalls verified by reading existing backend and `.npmrc` files

**Research date:** 2026-03-11
**Valid until:** 2026-04-11 (stable stack; Cloudflare Pages `_redirects` syntax has not changed in years)
