---
phase: 77-standalone-extraction
verified: 2026-03-12T03:00:00Z
status: passed
score: 7/7 must-haves verified
re_verification: false
gaps: []
human_verification:
  - test: "Open DevTools > Application > Local Storage at readrank.empowered.vote and interact with an issue"
    expected: "localStorage key ev_readrank (not readrank-storage) appears with persisted state"
    why_human: "Cannot read browser localStorage programmatically; curl/grep cannot verify client-side storage key name"
---

# Phase 77: Standalone Extraction Verification Report

**Phase Goal:** Extract Read & Rank from EV-prototypes monorepo into a standalone deployable repo (EmpoweredVote/read-rank) deployed to readrank.empowered.vote on Cloudflare Pages.
**Verified:** 2026-03-12T03:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | EV-readrank repo exists as a standalone GitHub repo with full source | VERIFIED | `gh repo view EmpoweredVote/read-rank` returns `read-rank` at `https://github.com/EmpoweredVote/read-rank`, pushed 2026-03-12 |
| 2 | `npm run build` produces a clean dist/ with _redirects | VERIFIED | `dist/` contains `index.html`, `_redirects`, `assets/` (index JS + CSS + mockData chunks); no build errors |
| 3 | Vite base path is `/` (not the monorepo subpath) | VERIFIED | `vite.config.ts` line 11: `base: '/'` |
| 4 | BrowserRouter basename is `/` | VERIFIED | `src/App.tsx` line 24: `<BrowserRouter basename="/">` |
| 5 | Zustand persist key is `ev_readrank` with version 1 and a migrate function | VERIFIED | `src/store/useReadRankStore.ts` lines 511-516: `name: 'ev_readrank'`, `version: 1`, `migrate` passthrough cast to `ReadRankState` |
| 6 | readrank.empowered.vote is live and SPA routing works | VERIFIED | `curl https://readrank.empowered.vote` → 200; `curl https://readrank.empowered.vote/animation-options` → 200 (SPA _redirects active) |
| 7 | CORS from readrank.empowered.vote to api.empowered.vote returns correct headers | VERIFIED | `curl -sI -H "Origin: https://readrank.empowered.vote" https://api.empowered.vote/essentials/quotes` → `access-control-allow-origin: https://readrank.empowered.vote`, `access-control-allow-credentials: true` |

**Score:** 7/7 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-readrank/vite.config.ts` | Vite config with `base: '/'` and local ev-ui alias | VERIFIED | All required content present: `base: '/'`, `fs.existsSync` alias pattern, `dedupe` config |
| `EV-readrank/src/App.tsx` | BrowserRouter with `basename="/"` | VERIFIED | Line 24: `<BrowserRouter basename="/">` with all three routes defined |
| `EV-readrank/src/store/useReadRankStore.ts` | Zustand store with persist key `ev_readrank` | VERIFIED | `name: 'ev_readrank'`, `version: 1`, migrate passthrough, partialize unchanged from prototype |
| `EV-readrank/public/_redirects` | Cloudflare Pages SPA fallback | VERIFIED | Contains exactly `/*    /index.html    200` |
| `EV-readrank/.npmrc` | GitHub npm registry auth with NPM_TOKEN | VERIFIED | `@chrisandrewsedu:registry=https://npm.pkg.github.com` and `//npm.pkg.github.com/:_authToken=${NPM_TOKEN}` — token is a variable reference, not a secret |
| `EV-readrank/package.json` | Name `ev-readrank`, ev-ui `^0.1.41` | VERIFIED | `"name": "ev-readrank"`, `"@chrisandrewsedu/ev-ui": "^0.1.41"` |
| `EV-Backend/internal/middleware/middleware.go` | CORS allowlist with readrank subdomain | VERIFIED | Lines 74-75: both `https://readrank.empowered.vote` and `https://readrank-dev.empowered.vote` present |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `vite.config.ts` (`base: '/'`) | `dist/_redirects` | Vite copies `public/` verbatim to `dist/` | VERIFIED | `dist/_redirects` exists with correct content; confirmed by directory listing |
| `src/App.tsx` | `BrowserRouter` | `basename` prop | VERIFIED | `basename="/"` — all three routes are domain-root-relative |
| `readrank.empowered.vote` | `api.empowered.vote` | CORS preflight + credentialed fetch | VERIFIED | Live CORS check returns `access-control-allow-origin: https://readrank.empowered.vote` with `allow-credentials: true` |
| `EV-readrank/.npmrc` | GitHub npm registry | `NPM_TOKEN` env var at CI build time | VERIFIED (conditional) | `.npmrc` committed with `${NPM_TOKEN}` variable reference; CI build passing confirmed by live site being up |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| EXTR-01 | 77-01 | Read & Rank extracted to standalone GitHub repo | SATISFIED | `EmpoweredVote/read-rank` public repo exists with full source at commit `64af700` |
| EXTR-02 | 77-02 | Deployed to `readrank.empowered.vote` on Cloudflare Pages with SPA routing | SATISFIED | `curl https://readrank.empowered.vote` → 200; `/animation-options` deep route → 200 (SPA routing confirmed) |
| EXTR-03 | 77-02 | Backend CORS allowlist updated for readrank subdomain | SATISFIED | Both `readrank.empowered.vote` and `readrank-dev.empowered.vote` in allowed map, live CORS preflight returns correct headers |
| EXTR-04 | 77-01 | ev-ui dependency updated from ^0.1.6 to ^0.1.41 | SATISFIED | `package.json` line 13: `"@chrisandrewsedu/ev-ui": "^0.1.41"` |
| EXTR-05 | 77-01 | Zustand persist key namespaced with migration | SATISFIED | `name: 'ev_readrank'`, `version: 1`, `migrate` passthrough function — covers rename from `readrank-storage` |

**Requirements coverage: 5/5 — all EXTR requirements satisfied. No orphaned requirements.**

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `EV-readrank/netlify.toml` | 1-27 | Stale monorepo artifact copied from prototype | INFO | None — Cloudflare Pages ignores `netlify.toml`; `_redirects` is the active SPA config. No behavior impact. |

No blockers. No stub implementations. No empty handlers.

---

### Human Verification Required

#### 1. Zustand localStorage key in browser

**Test:** Visit `https://readrank.empowered.vote`, click into an issue, evaluate one quote. Open DevTools > Application > Local Storage > `https://readrank.empowered.vote`.
**Expected:** A key named `ev_readrank` appears (not the old `readrank-storage` key).
**Why human:** Browser localStorage is not accessible via curl or grep. The code is correct (`name: 'ev_readrank'`), but the runtime behavior can only be confirmed in a browser session.

---

### Gaps Summary

No gaps. All seven observable truths verified, all five requirement IDs satisfied, all artifacts substantive and wired. The only non-passing item is the human verification of the localStorage key name at runtime — the code is demonstrably correct and this is a formality.

One informational finding: `netlify.toml` was carried over from the prototype copy. It has no effect on the Cloudflare Pages deployment and does not block any goal.

---

_Verified: 2026-03-12T03:00:00Z_
_Verifier: Claude (gsd-verifier)_
