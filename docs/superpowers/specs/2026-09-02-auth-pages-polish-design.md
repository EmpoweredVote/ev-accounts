# Auth pages visual polish — design

Date: 2026-09-02
Author: Chris Andrews (with Claude)
Status: Approved (direction) — pending spec review

## Goal

The sign-in surface at `login.empowered.vote` / `accounts.empowered.vote` (served by the
`admin/` build) looks dated and generic, and it prints the brand as lowercase
`empowered.vote` **text** instead of the real logo. Refresh all of the auth pages to a
single, polished, on-brand look built around the actual logo. This is a **presentational**
change only — no auth behavior changes.

## Scope

Six pages in `admin/src/pages/`:

- `Login.tsx`
- `Signup.tsx`
- `InformSignup.tsx`
- `ForgotPassword.tsx`
- `ResetPassword.tsx`
- `EmailConfirmed.tsx`

Plus one new shared component: `admin/src/components/AuthShell.tsx`.

Out of scope: any change to auth logic, routing, API calls, form validation, or the
embedded-WorkOS flow. Out of scope: the `app/` build's auth pages and CompassV2 (a later
pass could reuse the same idea, but this spec covers `admin/` only).

## Current state (the problem)

Two divergent card patterns already exist:

- **Login / ResetPassword / EmailConfirmed / ForgotPassword** render a lowercase
  `<h1>empowered.vote</h1>` text wordmark **above** a `rounded-2xl border shadow-sm` card,
  on a `bg-gray-50 dark:bg-ev-black` background.
- **Signup / InformSignup** already render the **logo image** (`/Empowered_Vote_Logo_2026.png`,
  `h-12`) **inside** a `rounded-lg shadow-md` card, on a `bg-gray-50 dark:bg-gray-950`
  background — but they hardcode the dark-teal logo even in dark mode, where it reads poorly
  on the near-black panel.

So the pages are inconsistent (text vs image, two card styles, two dark backgrounds, no
theme-aware logo). The redesign converges them on one shell.

## Design

### 1. Theme-aware logo

- Two logo assets already exist in `admin/public/`: `Empowered_Vote_Logo_2026.png` (dark
  teal, for light backgrounds) and `logo.png` (lighter teal, for dark backgrounds). Both are
  the same horizontal lockup (wordmark + flag/circle mark), ~12 KB each.
- Show the dark-teal logo in light mode and the lighter-teal logo in dark mode. Because the
  app toggles dark mode with a `.dark` class on the root (`@custom-variant dark`), render
  **both** `<img>` tags and show/hide with `block dark:hidden` / `hidden dark:block`. This
  avoids a JS theme read and works with SSR-less Vite.
- `alt="Empowered Vote"`, `object-contain`, height ~`h-10`, centered at the top of the card.

### 2. Shared `AuthShell` component

`admin/src/components/AuthShell.tsx` owns the background, the centered card, the logo, and an
optional heading. Every auth page renders its form as `children` inside it.

Proposed interface:

```tsx
interface AuthShellProps {
  /** Card heading, e.g. "Log in" or "Enter your code". Omit for none. */
  heading?: string;
  /** Optional short line under the heading (e.g. reset-password instructions). */
  subheading?: React.ReactNode;
  /** Constrain card width. Default "sm"; signup forms use "md". */
  width?: 'sm' | 'md';
  children: React.ReactNode; // the form / body
}
```

The shell renders: full-height flex-centered background → card (with the top accent bar) →
theme-aware logo → optional heading/subheading → `children`. Pages keep ownership of all
form state, error banners, buttons, and links; they just no longer repeat the background,
logo, and card chrome.

### 3. Card polish (the visual language)

Brand tokens (already in `admin/src/index.css`): `--color-ev-teal #00657C`,
`--color-ev-teal-light #59B0C4`, `--color-ev-red #FF5740` (coral), `--color-ev-black #1c1c1c`.

- **Background:** a soft brand-tinted wash. Light: a faint teal radial fading into
  `bg-gray-50`. Dark: a faint teal-light glow over `ev-black`. Subtle, not loud.
- **Card:** white / `gray-900`, `rounded-2xl`, refined 1px border, generous padding
  (`p-8`), and an elevated shadow with a slight teal tint (light) / deep neutral shadow
  (dark).
- **Top accent bar:** a thin (~4px) `teal → coral` gradient strip across the top edge of the
  card, echoing the logo's two colors. In dark mode it runs `teal-light → coral`. This is the
  only place coral appears.
- **Inputs:** `rounded-xl`, refined borders, a clear teal focus ring
  (`focus:ring-2 ring-ev-teal` / `ring-ev-teal-light` in dark).
- **Primary button:** stays teal (`ev-teal`, `ev-teal-light` in dark), full width,
  `rounded-xl`, medium-bold, subtle hover.
- **Typography:** keep the system font stack. Tighten heading size/weight/tracking; no new
  font dependency.

### 4. Behavior preserved (must-not-break checklist)

`Login.tsx` carries the most logic. The redesign must keep every one of these working,
unchanged:

- Embedded-WorkOS submit (`handleEmbeddedSubmit`) vs classic submit (`handleSubmit`), chosen
  by `embeddedAuthEnabled && !allowClassic`.
- The on-page 6-digit **verification-code step** (`codeStep`), including resend.
- The **break-glass** classic path (`allowClassic`, route `/login/classic`).
- The **session-resolve** notice (`showResolving`) and the **auto-forward** notice
  (`autoForwarding`) — these currently render their own mini-layout with the text wordmark;
  they move to `AuthShell` too so they get the logo, but their logic is untouched.
- The SSO handoff effect, `finishLogin`, error banner, and the "Resend confirmation email"
  affordance.

The other five pages are simpler; the same rule applies — only the wrapper/markup changes.

### 5. No new dependencies

No new npm packages, no web font, no icon library. Tailwind v4 utilities + the existing
brand tokens only.

## Isolation / boundaries

- `AuthShell` is a pure presentational component: props in, markup out, no data fetching, no
  auth state. It can be understood and changed without touching any page's logic.
- Each page keeps a single clear responsibility (its own form + flow) and delegates only
  chrome to the shell. A page's behavior is testable/readable without reading the shell's
  internals, and the shell can be restyled without touching page logic.

## Verification

- `admin` build clean: `tsc && vite build`.
- Run the admin dev server and load `/login`, `/signup`, `/forgot-password`,
  `/reset-password`, `/email-confirmed` in the browser preview; screenshot light and dark.
- Confirm the logo swaps by theme (toggle `.dark`).
- Manually walk the Login states that render without a backend: default form, the
  verification-code step, the resolving/redirecting notices, and `/login/classic`
  (break-glass shows the classic form).
- No behavior/logic diffs beyond markup — spot-check that handlers, flags, and links are
  unchanged.

## Rollout

Single PR against `master`. Presentational only, no flag needed. `admin/` static redeploys
on merge. No backend or env change.
