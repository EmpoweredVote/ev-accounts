# Auth Pages Visual Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the six `admin/` auth pages onto one polished, on-brand shell built around the real logo (replacing the lowercase `empowered.vote` text wordmark), with no change to auth behavior.

**Architecture:** Introduce one presentational component, `admin/src/components/AuthShell.tsx`, that owns the background, the centered card (with a teal→coral top accent), the theme-aware logo, and an optional heading. Every auth page renders its existing form as `children` inside it. Pages keep all state, handlers, flags, and links; only their chrome markup changes.

**Tech Stack:** React + TypeScript, Vite, Tailwind CSS v4 (with `@theme` brand tokens in `admin/src/index.css`), dark mode via a `.dark` class (`@custom-variant dark`).

## Global Constraints

- **Presentational only.** No change to any auth logic, routing, API call, form validation, or the embedded-WorkOS flow. Every handler, flag, state variable, and link keeps its exact current behavior. (Spec: "Behavior preserved".)
- **No new dependencies.** No new npm package, no web font, no icon library. Tailwind v4 utilities + existing `ev-*` brand tokens only.
- **Brand tokens (already defined in `admin/src/index.css`):** `--color-ev-teal #00657C`, `--color-ev-teal-light #59B0C4`, `--color-ev-red #FF5740` (coral), `--color-ev-black #1c1c1c`.
- **Theme-aware logo assets (already in `admin/public/`):** `Empowered_Vote_Logo_2026.png` (dark teal → light mode), `logo.png` (lighter teal → dark mode). Same horizontal lockup.
- **Dark mode is a `.dark` class**, so theme-conditional visuals use Tailwind `dark:` variants (e.g. `block dark:hidden`) — no JS theme read.
- **Verification is build + live preview** (no frontend unit-test harness exists in `admin/`): `npm run build` (`tsc && vite build`) must be clean, and each page is checked in the browser preview in light and dark.
- **Branch:** work is already on `claude/auth-pages-polish` (cut from `origin/master`) in this worktree. All commits land there. One PR against `master` at the end.

---

### Task 1: Create the shared `AuthShell` component

**Files:**
- Modify: `admin/src/index.css` (add the two `.auth-bg` background classes)
- Create: `admin/src/components/AuthShell.tsx`

**Interfaces:**
- Produces:
  - `admin/src/index.css` gains class `.auth-bg` (light) and `.dark .auth-bg` (dark) — a brand-tinted radial wash used as the full-page background.
  - `AuthShell` default export with props:
    ```ts
    interface AuthShellProps {
      heading?: string;          // card title, e.g. "Log in" / "Enter your code"
      subheading?: React.ReactNode; // optional line under the heading
      width?: 'sm' | 'md';       // card max-width; default 'sm', signup forms use 'md'
      children: React.ReactNode; // the page's form / body
    }
    ```
  - Rendered structure (top → bottom): full-height `.auth-bg` flex-center → card (`relative`, rounded-2xl, border, `p-8`, elevated shadow) → teal→coral top accent bar → theme-swapped logo (`h-10`) → optional `heading` (`<h1>`) → optional `subheading` (`<p>`) → `children`.

- [ ] **Step 1: Add the background classes to `admin/src/index.css`**

Append after the `@theme { ... }` block:

```css
/* Auth pages: subtle brand-tinted background wash */
.auth-bg {
  background:
    radial-gradient(1100px 600px at 50% -10%, rgba(0, 101, 124, 0.08), transparent 60%),
    var(--color-ev-gray-50, #f7f9fa);
}
.dark .auth-bg {
  background:
    radial-gradient(1100px 600px at 50% -10%, rgba(89, 176, 196, 0.10), transparent 60%),
    #141414;
}
```

(The `var(--color-ev-gray-50, #f7f9fa)` fallback keeps light mode a hair warmer than pure white without depending on a token that may not exist — the literal `#f7f9fa` is the effective value.)

- [ ] **Step 2: Create `admin/src/components/AuthShell.tsx`**

```tsx
import type { ReactNode } from 'react';

interface AuthShellProps {
  /** Card title, e.g. "Log in" or "Enter your code". Omit for none. */
  heading?: string;
  /** Optional short line under the heading (e.g. reset instructions). */
  subheading?: ReactNode;
  /** Card max-width. Default 'sm'; signup forms use 'md'. */
  width?: 'sm' | 'md';
  children: ReactNode;
}

/**
 * Shared chrome for every auth page (login, signup, password reset, etc.):
 * the brand-tinted background, the centered card with a teal→coral top accent,
 * and the theme-aware Empowered Vote logo. Presentational only — pages own all
 * form state, handlers, and links and pass them as `children`.
 */
export default function AuthShell({ heading, subheading, width = 'sm', children }: AuthShellProps) {
  return (
    <div className="auth-bg min-h-screen flex items-center justify-center px-4 py-12">
      <div
        className={`relative w-full ${width === 'md' ? 'max-w-md' : 'max-w-sm'} overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-8 shadow-[0_12px_40px_-12px_rgba(0,101,124,0.18),0_2px_8px_rgba(16,24,40,0.04)] dark:shadow-[0_16px_48px_-16px_rgba(0,0,0,0.6)]`}
      >
        {/* teal→coral accent, echoing the two logo colors */}
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-ev-teal to-ev-red dark:from-ev-teal-light dark:to-ev-red" />

        {/* theme-aware logo: dark-teal lockup on light, lighter-teal on dark */}
        <div className="flex justify-center mb-6">
          <img
            src="/Empowered_Vote_Logo_2026.png"
            alt="Empowered Vote"
            className="block dark:hidden h-10 w-auto object-contain"
          />
          <img
            src="/logo.png"
            alt="Empowered Vote"
            className="hidden dark:block h-10 w-auto object-contain"
          />
        </div>

        {heading && (
          <h1 className="text-xl font-bold tracking-tight text-center text-gray-900 dark:text-white">
            {heading}
          </h1>
        )}
        {subheading && (
          <p className="mt-1.5 text-sm text-center text-gray-500 dark:text-gray-400">
            {subheading}
          </p>
        )}

        <div className={heading || subheading ? 'mt-6' : ''}>{children}</div>
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Verify it compiles**

Run: `npm run build --prefix admin`
Expected: clean `tsc` + `vite build`, no errors. (AuthShell is unused so far; this only proves it type-checks and the CSS is valid.)

- [ ] **Step 4: Commit**

```bash
git add admin/src/components/AuthShell.tsx admin/src/index.css
git commit -m "feat(auth-ui): add shared AuthShell (theme-aware logo, polished card)"
```

---

### Task 2: Migrate `Login.tsx` to `AuthShell` (highest-risk — most logic)

**Files:**
- Modify: `admin/src/pages/Login.tsx`

**Interfaces:**
- Consumes: `AuthShell` from Task 1.

`Login.tsx` has THREE render sites that currently draw the text-wordmark layout, plus the main card. All must move to `AuthShell` while every handler/flag stays byte-for-byte:

1. The `showResolving` early return (`One moment…` notice).
2. The `autoForwarding` early return (`Redirecting to sign in…` notice).
3. The main `return (...)` — the wordmark `<div>` above the card, and the card itself.

**MUST NOT CHANGE (spec must-not-break checklist):** `handleEmbeddedSubmit` vs `handleSubmit` selection (`embeddedAuthEnabled && !allowClassic`), the `codeStep` verification-code form + `handleResendCode`, `allowClassic` break-glass, the `showResolving` / `autoForwarding` conditions, the SSO handoff effect, `finishLogin`, the error banner, `showUnverifiedResend` / `handleResendConfirmation`, `workosCompleting` and `appName` banners, and all links (`forgotHref`, signup).

- [ ] **Step 1: Import AuthShell**

At the top of `admin/src/pages/Login.tsx`, add:
```tsx
import AuthShell from '../components/AuthShell';
```

- [ ] **Step 2: Replace the `showResolving` early return**

Replace its returned JSX (the `min-h-screen … <h1>empowered.vote</h1> … <p>One moment…</p>` block) with:
```tsx
return (
  <AuthShell>
    <p className="text-sm text-center text-gray-500 dark:text-gray-400">One moment…</p>
  </AuthShell>
);
```

- [ ] **Step 3: Replace the `autoForwarding` early return**

Same shape, with the redirect copy:
```tsx
return (
  <AuthShell>
    <p className="text-sm text-center text-gray-500 dark:text-gray-400">Redirecting to sign in…</p>
  </AuthShell>
);
```

- [ ] **Step 4: Replace the main return's wrapper**

In the main `return (...)`: delete the outer `<div className="min-h-screen …">`, the wordmark `<div className="mb-8 text-center"><h1>empowered.vote</h1></div>`, and the card `<div className="bg-white … rounded-2xl … max-w-sm …">` wrapper. Wrap the card's INNER contents in `AuthShell` instead. The card's first child is currently `<h2>{codeStep ? 'Enter your code' : 'Log in'}</h2>` — pass that as the `heading` prop and delete the `<h2>`:

```tsx
return (
  <AuthShell heading={codeStep ? 'Enter your code' : 'Log in'}>
    {/* everything that was INSIDE the old card, verbatim and in order:
        workosCompleting banner, appName banner, error banner,
        the {showLoginForm && !codeStep && (<form …>)} block,
        the {showLoginForm && codeStep && (<form …>)} block,
        and whatever footer/links followed. Keep the existing `space-y-*`
        rhythm by wrapping these children in a <div className="space-y-5"> if
        the old card used one. */}
  </AuthShell>
);
```

Keep every inner element (banners, both forms, links) exactly as-is. Only the outer wrapper, the wordmark, and the `<h2>` heading are removed (heading now comes from `AuthShell`).

- [ ] **Step 5: Build**

Run: `npm run build --prefix admin`
Expected: clean. Fix any type/JSX errors before proceeding.

- [ ] **Step 6: Verify live in the browser preview**

Start the admin dev server and open `/login`:
- `preview_start` the admin dev server (`npm run dev` in `admin/`, Vite default port 5173). If `.claude/launch.json` has no admin entry, add one: `{ "name": "admin", "runtimeExecutable": "npm", "runtimeArgs": ["run", "dev", "--prefix", "admin"], "port": 5173 }`.
- Load `/login`. Confirm: the real logo shows (not text), the card has the teal→coral accent, inputs and the teal button look right.
- Toggle dark mode (add `.dark` to `<html>` via `javascript_tool`: `document.documentElement.classList.toggle('dark')`) and confirm the logo swaps to the lighter-teal version and colors invert cleanly.
- Load `/login/classic` — the classic email/password form must still render (break-glass).
- Screenshot light and dark for the record.

- [ ] **Step 7: Commit**

```bash
git add admin/src/pages/Login.tsx
git commit -m "feat(auth-ui): move Login onto AuthShell (logo + polished card)"
```

---

### Task 3: Migrate `Signup.tsx` and `InformSignup.tsx`

**Files:**
- Modify: `admin/src/pages/Signup.tsx`
- Modify: `admin/src/pages/InformSignup.tsx`

**Interfaces:**
- Consumes: `AuthShell` from Task 1.

These already render the logo image inside a card, but hardcode the dark-teal logo in dark mode and use a different card style (`rounded-lg shadow-md`, `dark:bg-gray-950`). Each file has MULTIPLE render branches (e.g. Signup has separate `min-h-screen` blocks for its states, ~lines 227, 295, 335). Convert every branch to `AuthShell`.

- [ ] **Step 1: Import AuthShell in both files**

```tsx
import AuthShell from '../components/AuthShell';
```

- [ ] **Step 2: Convert each render branch in `Signup.tsx`**

For each `min-h-screen` block: delete the outer `min-h-screen … bg-gray-50 dark:bg-gray-950` wrapper, the inner card `<div className="bg-white … rounded-lg shadow-md p-8 max-w-md">`, the `<div className="flex justify-center mb-6"><img … /></div>` logo block, and the block's own heading `<h1>` — replacing them with `<AuthShell width="md" heading={…}>…form…</AuthShell>`. Pass the branch's heading text (e.g. `"Enter your code"`, `"Create your account"`) as `heading`. Keep the form body, error banners, and all handlers verbatim.

- [ ] **Step 3: Convert `InformSignup.tsx` the same way**

Apply the identical transformation to each of its render branches. Use `width="md"` to match the signup form width.

- [ ] **Step 4: Build**

Run: `npm run build --prefix admin`
Expected: clean.

- [ ] **Step 5: Verify live**

In the browser preview, load `/signup` and `/signup/inform`. Confirm the logo now swaps by theme (it previously stayed dark-teal in dark mode), the card matches Login's, and each state's heading/body renders. Screenshot light + dark.

- [ ] **Step 6: Commit**

```bash
git add admin/src/pages/Signup.tsx admin/src/pages/InformSignup.tsx
git commit -m "feat(auth-ui): move signup pages onto AuthShell (theme-aware logo)"
```

---

### Task 4: Migrate `ForgotPassword.tsx`, `ResetPassword.tsx`, `EmailConfirmed.tsx`

**Files:**
- Modify: `admin/src/pages/ForgotPassword.tsx`
- Modify: `admin/src/pages/ResetPassword.tsx`
- Modify: `admin/src/pages/EmailConfirmed.tsx`

**Interfaces:**
- Consumes: `AuthShell` from Task 1.

These use the text-wordmark pattern (`<h1>empowered.vote</h1>` above a card), some with more than one render branch (`ResetPassword` has ~3). Convert each branch to `AuthShell`.

- [ ] **Step 1: Import AuthShell in all three files**

```tsx
import AuthShell from '../components/AuthShell';
```

- [ ] **Step 2: Convert each render branch**

For every branch: delete the `min-h-screen` wrapper, the `<h1>empowered.vote</h1>` wordmark block, and the card wrapper; wrap the inner content in `<AuthShell heading={…}>`. Give each branch a sensible heading from its existing copy (e.g. ForgotPassword → `"Reset your password"`; ResetPassword form → `"Choose a new password"`; ResetPassword success → `"Password updated"`; EmailConfirmed → `"Email confirmed"`). If a branch's body already leads with an explanatory sentence, pass it as `subheading` and remove the duplicate. Keep all form fields, buttons, links, and handlers verbatim.

- [ ] **Step 3: Build**

Run: `npm run build --prefix admin`
Expected: clean.

- [ ] **Step 4: Verify live**

In the browser preview, load `/forgot-password`, `/reset-password`, and `/email-confirmed`. Confirm the logo (theme-aware), the unified card, and each branch's heading render correctly. For `/reset-password`, exercise its branches if reachable without a token (at minimum the "invalid/expired token" state). Screenshot light + dark.

- [ ] **Step 5: Commit**

```bash
git add admin/src/pages/ForgotPassword.tsx admin/src/pages/ResetPassword.tsx admin/src/pages/EmailConfirmed.tsx
git commit -m "feat(auth-ui): move password-reset + email-confirmed onto AuthShell"
```

---

### Task 5: Cross-page verification sweep + open PR

**Files:** none (verification + PR only)

- [ ] **Step 1: Full build**

Run: `npm run build --prefix admin`
Expected: clean `tsc && vite build`.

- [ ] **Step 2: Grep for leftovers**

Run: `grep -rn "empowered.vote" admin/src/pages` and confirm no remaining `<h1>…empowered.vote…</h1>` text wordmark (matches inside links/URLs are fine). Run: `grep -rln "min-h-screen" admin/src/pages` and confirm the six auth pages no longer draw their own full-page wrappers (they delegate to `AuthShell`).

- [ ] **Step 3: Visual QA sweep**

In the browser preview, walk all six pages (`/login`, `/login/classic`, `/signup`, `/signup/inform`, `/forgot-password`, `/reset-password`, `/email-confirmed`) in BOTH light and dark. Confirm: consistent card, consistent logo that swaps by theme, teal→coral accent, no layout breakage, no console errors (`read_console_messages`). Capture a couple of representative screenshots (e.g. Login light + dark) to share.

- [ ] **Step 4: Behavior spot-check**

Confirm no logic changed: `git diff origin/master -- admin/src/pages` should show only wrapper/markup/heading changes — no edits to handlers, `fetch` calls, state, flags, or effects. On `/login`, confirm the form still submits (the embedded or classic handler fires) and the verification-code step still renders when reached.

- [ ] **Step 5: Open the PR**

```bash
git push -u origin claude/auth-pages-polish
gh pr create --base master --head claude/auth-pages-polish \
  --title "feat(auth-ui): polish the auth pages onto one shell with the real logo" \
  --body "Presentational refresh of the six admin/ auth pages. New AuthShell component: theme-aware logo (replaces the lowercase empowered.vote text), unified card with a teal→coral accent, refined inputs/shadow, brand-tinted background. No auth-logic or dependency changes. Design + spec: docs/superpowers/specs/2026-09-02-auth-pages-polish-design.md."
```

---

## Self-Review

**Spec coverage:**
- Theme-aware logo → Task 1 (AuthShell renders both imgs with `block dark:hidden` / `hidden dark:block`), applied by Tasks 2–4. ✓
- Shared `AuthShell` across all six pages → Task 1 creates it; Tasks 2–4 migrate all six. ✓
- Card polish (shadow, border, radius, padding, accent bar, focus rings, brand background) → Task 1 (shell + `.auth-bg`); input focus rings already live on each page's inputs and are preserved. ✓
- Behavior preserved → Global Constraints + Task 2 must-not-break list + Task 5 Step 4 diff check. ✓
- No new dependencies / no new font → Global Constraints. ✓
- Verification (build + live light/dark + state walk) → every task's verify step + Task 5 sweep. ✓
- Rollout: single PR against master, admin redeploys, no env → Task 5 Step 5. ✓

**Placeholder scan:** AuthShell code is complete and literal. Page tasks describe concrete transformations (which wrappers to delete, what to pass as `heading`) rather than reproducing each page's full form — deliberate, because the forms must be preserved verbatim and reproducing them invites accidental edits. No "TBD"/"add error handling"/"similar to Task N".

**Type consistency:** `AuthShell` prop names (`heading`, `subheading`, `width`, `children`) and the `width` union (`'sm' | 'md'`) are identical everywhere they appear. The import path `../components/AuthShell` is consistent across Tasks 2–4 (all pages sit in `admin/src/pages/`).
