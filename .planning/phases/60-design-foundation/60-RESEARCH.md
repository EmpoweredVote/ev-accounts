# Phase 60: Design Foundation - Research

**Researched:** 2026-04-25
**Domain:** React component library, Tailwind v4 token system, design system for dark-themed civic app
**Confidence:** HIGH — all findings derived from live codebase inspection and installed package versions

---

## Summary

Phase 60 establishes the shared design language for v2.0 by adding two color tokens to `index.css` files and creating six shared React components. This is a pure frontend task — no backend involvement, no routing changes, no state management changes.

The codebase already has a complete Tailwind v4 `@theme` pattern in both `app/src/index.css` and `admin/src/index.css`. Adding `ev-blue` and `ev-navy` follows the exact same syntax as the five existing tokens. All six components are greenfield (none exist yet), but the existing pages give extensive reference for the visual language, Tailwind class patterns, and TypeScript prop interfaces the team expects.

The central design shift in v2.0 is: existing auth/onboarding flows use `ev-teal-light` for primary buttons and `bg-ev-black` for page backgrounds; v2.0 replaces these with `ev-blue` CTAs and `ev-navy` backgrounds. Component implementations must reflect this new palette.

**Primary recommendation:** Build components by extracting patterns already present in LoginPage.tsx and SignupPage.tsx, then adapt them from the old teal/black palette to the new blue/navy palette. The existing code is the best reference.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 18.3.1 | Component model | Project-wide standard |
| TypeScript | 5.6.0 | Strict typing | Project-wide standard |
| Tailwind CSS | 4.2.1 | Utility classes + `@theme` tokens | Already installed, configured via `@tailwindcss/vite` plugin |
| Vite | 5.4.0 | Build tool | Already configured |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @headlessui/react | 2.2.9 | Accessible UI primitives | Already installed — use if a component needs focus trapping or ARIA; none of the 6 components in scope require it |
| react-router-dom | 6.21.1 | Routing (Link component) | AppNav may need `Link` for internal routes |

### No New Dependencies Needed

All six components are implementable with existing dependencies. No new `npm install` required for this phase.

**Installation:**

None required.

---

## Architecture Patterns

### Recommended Project Structure

```
app/src/
├── components/
│   ├── AuthGuard.tsx          (existing)
│   ├── OnboardingGuard.tsx    (existing)
│   ├── PostHistory.tsx        (existing)
│   ├── AuthCard.tsx           ← new (DSGN-02)
│   ├── AuthInput.tsx          ← new (DSGN-03)
│   ├── PrimaryButton.tsx      ← new (DSGN-04)
│   ├── SecondaryButton.tsx    ← new (DSGN-04)
│   ├── StepProgress.tsx       ← new (DSGN-05)
│   └── AppNav.tsx             ← new (DSGN-06)
├── index.css                  ← add ev-blue + ev-navy tokens (DSGN-01)
```

```
admin/src/
├── index.css                  ← add ev-blue token only (DSGN-01)
```

All new components live flat in `app/src/components/`. The codebase does not use subfolders in `components/` — maintain that pattern.

### Pattern 1: Tailwind v4 `@theme` Token Addition

**What:** Add CSS custom properties under `--color-*` namespace in the `@theme` block. Tailwind v4 auto-generates utility classes from these (`bg-ev-blue`, `text-ev-navy`, `border-ev-blue`, opacity variants like `bg-ev-blue/20`).

**When to use:** Any new brand color.

**Example (from `app/src/index.css` — live codebase):**
```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  /* Empowered Vote brand colors */
  --color-ev-red: #FF5740;
  --color-ev-teal: #00657C;
  --color-ev-teal-light: #59B0C4;
  --color-ev-yellow: #FED12E;
  --color-ev-black: #1c1c1c;
  /* v2.0 additions: */
  --color-ev-blue: #3B82F6;
  --color-ev-navy: #020618;
}
```

The `--color-` prefix is required — Tailwind v4 reads `--color-*` variables from `@theme` to generate color utilities. Variable names become class suffixes: `--color-ev-blue` → `bg-ev-blue`, `text-ev-blue`, `border-ev-blue`, `ring-ev-blue`, etc.

### Pattern 2: Typed React Component Props

**What:** All components use explicit TypeScript interfaces for props. No `React.FC` — plain function with typed parameter destructuring. This matches every existing component in the codebase.

**Example (from `WelcomeStep.tsx` — live codebase):**
```typescript
interface Props {
  onContinue: () => void;
}

export function WelcomeStep({ onContinue }: Props) {
  // ...
}
```

Components in `/components/` that are consumed by pages use named exports (e.g., `export function AuthCard`), consistent with `AuthGuard.tsx` and `OnboardingGuard.tsx`. Page-level default exports are fine for pages, but shared components use named exports.

### Pattern 3: Dark Card Pattern (AuthCard reference implementation)

**What:** The existing `LoginPage.tsx` and `SignupPage.tsx` already implement the card pattern — dark rounded card, border, consistent padding. `AuthCard` extracts this as a reusable wrapper.

**Current implementation in LoginPage.tsx (lines 80–131):**
```tsx
<div className="w-full max-w-sm bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5">
  {/* content */}
</div>
```

**AuthCard should preserve this exact styling**, replacing `bg-gray-900` with `bg-ev-navy` (or equivalent dark background) per v2.0 design language. The card accepts `children` and optionally a `className` for overrides.

### Pattern 4: Input Pattern (AuthInput reference implementation)

**Current implementation in LoginPage.tsx (lines 91–99):**
```tsx
<div>
  <label className="block text-sm font-medium text-gray-300 mb-1.5">Email</label>
  <input
    type="email"
    value={email}
    onChange={(e) => setEmail(e.target.value)}
    className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base"
  />
</div>
```

**AuthInput** wraps label + input + optional error message. The focus ring changes from `ev-teal-light` to `ev-blue`. Error state adds a red border + red error text below.

**AuthInput interface:**
```typescript
interface AuthInputProps {
  label: string;
  type?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  error?: string;
  autoComplete?: string;
  required?: boolean;
  // pass-through for specialized inputs (e.g., inputMode, spellCheck)
  inputProps?: React.InputHTMLAttributes<HTMLInputElement>;
}
```

### Pattern 5: Button Pattern

**Current primary button in LoginPage.tsx (lines 116–122):**
```tsx
<button
  type="submit"
  disabled={loading}
  className="w-full bg-ev-teal-light text-ev-black rounded-xl py-3 font-bold text-base hover:bg-ev-teal-light/90 disabled:opacity-40 transition-colors"
>
```

**PrimaryButton** replaces `bg-ev-teal-light text-ev-black` with `bg-ev-blue text-white`.

**SecondaryButton** uses a dark/outline style — `bg-transparent border border-gray-700 text-gray-300` or `bg-gray-800 text-white`, consistent with the dark theme. No existing secondary button in current codebase — use judgment matching the overall dark aesthetic.

**Button interface:**
```typescript
interface ButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
  disabled?: boolean;
  loading?: boolean;
  className?: string;
}
```

### Pattern 6: StepProgress Component

**What:** Visual step indicator. Renders "Step X of Y" text label + percentage number + a horizontal progress bar track with a blue filled portion.

**No existing equivalent in codebase.** Design from scratch. The progress bar pattern exists in `DashboardPage.tsx` (XP bar):
```tsx
<div className="h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
  <div
    className="h-full rounded-full bg-ev-teal transition-all duration-700"
    style={{ width: `${xpPercent}%` }}
  />
</div>
```

**StepProgress** follows this pattern but uses `bg-ev-blue` fill instead of `bg-ev-teal`.

**StepProgress interface:**
```typescript
interface StepProgressProps {
  currentStep: number;
  totalSteps: number;
}
```
Internally computes `percent = Math.round((currentStep / totalSteps) * 100)`.

### Pattern 7: AppNav Component

**What:** Top navigation bar for the app surface. Logo mark + "Civic Platform" wordmark on left; right slot for auth controls (e.g., sign-in link or user menu).

**Reference implementation from DashboardPage.tsx (lines 279–304):**
```tsx
<header className="bg-white dark:bg-gray-950 border-b border-gray-100 dark:border-gray-800 sticky top-0 z-10">
  <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
    <span className="font-bold text-ev-teal-light text-lg">profile.empowered.vote</span>
    <div className="flex items-center gap-3">
      {/* right slot */}
    </div>
  </div>
</header>
```

**AppNav** adapts this shell with:
- Left: logo image (`/logo.png` from admin/public or a new asset in app/public) + "Civic Platform" wordmark text
- Background: dark navy (`bg-ev-navy`) instead of white/gray-950
- Right: accepts `children` prop for auth controls slot

**Logo asset situation:** `app/public/` currently has no logo file. `admin/public/logo.png` is a 688×156px PNG. The logo will need to be copied to `app/public/logo.png` or the `Empowered_Vote_Logo_2026.png` asset used. The plan should include copying the logo asset from `admin/public/` to `app/public/`.

**AppNav interface:**
```typescript
interface AppNavProps {
  children?: React.ReactNode;  // right slot for auth controls
}
```

### Anti-Patterns to Avoid

- **Using `React.FC<Props>`:** All existing components use `function Name({ prop }: Props)` pattern — no `React.FC`. Stay consistent.
- **Inline all styles rather than extracting:** The existing codebase inlines Tailwind classes. The new components should still extract to components (that's the point of this phase), but don't add CSS modules or styled-components — Tailwind only.
- **`className` merging libraries (clsx, cn):** Not installed, not used. If conditional classes are needed, use template literals or ternary. Don't add clsx unless genuinely needed.
- **`ev-blue` focus ring on input in old pages:** After DSGN-03 ships, the focus ring color changes. Do NOT update existing pages in this phase — that's Phase 61 and 62's job.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Progress bar animation | Custom CSS keyframe | Tailwind `transition-all duration-700` + inline `style={{ width }}` | Already proven in DashboardPage XP bar |
| Dark mode toggle | Custom implementation | Tailwind `dark:` variant via `@custom-variant dark` already in index.css | Already configured and working |
| Focus management in forms | Custom focus trap | Native HTML `autoFocus` + standard tab order | Good enough for these auth forms |
| Icon system | External icon library | Inline SVG paths | Pattern established throughout codebase; no icon library installed |

**Key insight:** Every visual pattern needed for these 6 components already exists somewhere in the codebase. The job is extraction and token-replacement, not invention.

---

## Common Pitfalls

### Pitfall 1: Using `--color-*` incorrectly in Tailwind v4

**What goes wrong:** In Tailwind v3, colors were defined in `tailwind.config.js`. In v4, they live in `@theme` blocks in CSS. Using a `tailwind.config.js` approach will silently fail to generate classes.

**Why it happens:** Muscle memory from Tailwind v3 and outdated documentation.

**How to avoid:** Follow the exact pattern in the live `app/src/index.css` — `@theme { --color-ev-blue: #3B82F6; }`. The `--color-` prefix is mandatory for Tailwind v4 color utility generation.

**Warning signs:** `bg-ev-blue` renders as unstyled (transparent/default) at runtime.

### Pitfall 2: Forgetting ev-navy as a page background token

**What goes wrong:** `ev-navy` (#020618) is almost black. Someone might use `bg-gray-950` or `bg-black` thinking it's close enough. This prevents the `bg-ev-navy` class from working in Phase 61+.

**Why it happens:** The color looks visually similar to existing dark grays at a glance.

**How to avoid:** DSGN-01 requires the token to be declared. Plan task must explicitly test `bg-ev-navy` renders as #020618, distinct from gray-950 (#030712 in Tailwind).

**Warning signs:** Phase 61 pages can't use `bg-ev-navy` class.

### Pitfall 3: Implementing AuthInput as an uncontrolled component

**What goes wrong:** Making AuthInput accept `defaultValue` or not properly lifting value/onChange leads to form state management problems in parent pages.

**Why it happens:** Trying to make the component "simpler" by hiding state inside it.

**How to avoid:** AuthInput must be fully controlled (accept `value` + `onChange`). All existing inputs in the codebase are controlled. Match the pattern in `LocationStep.tsx` (lines 121–130).

### Pitfall 4: Adding logo.png to app/public without verifying it renders

**What goes wrong:** AppNav references `/logo.png` but `app/public/logo.png` doesn't exist, causing a broken image.

**Why it happens:** Admin has the logo at `admin/public/logo.png` but it was never copied to `app/public/`.

**How to avoid:** Copy `admin/public/logo.png` to `app/public/logo.png` as a task step. Alternatively use `Empowered_Vote_Logo_2026.png` — it's already in `admin/public/` and the repo root.

### Pitfall 5: Making AuthCard too opinionated about max-width

**What goes wrong:** Hardcoding `max-w-sm` inside AuthCard forces every consumer to the same width — but some screens (e.g., onboarding steps) may want a wider card.

**Why it happens:** LoginPage uses `max-w-sm` so the component author embeds it.

**How to avoid:** AuthCard handles padding, border, rounded corners, and background color. Max-width is set by the parent page, not the card. Accept optional `className` prop for width overrides.

---

## Code Examples

### Token Addition (app/src/index.css)

```css
/* Source: live codebase pattern, app/src/index.css */
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-ev-red: #FF5740;
  --color-ev-teal: #00657C;
  --color-ev-teal-light: #59B0C4;
  --color-ev-yellow: #FED12E;
  --color-ev-black: #1c1c1c;
  --color-ev-blue: #3B82F6;    /* v2.0: blue CTA */
  --color-ev-navy: #020618;    /* v2.0: dark page background */
}
```

### AuthCard Component

```typescript
// app/src/components/AuthCard.tsx
// Pattern: extracted from LoginPage.tsx lines 80–131

interface AuthCardProps {
  children: React.ReactNode;
  className?: string;
}

export function AuthCard({ children, className = '' }: AuthCardProps) {
  return (
    <div className={`bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5 ${className}`}>
      {children}
    </div>
  );
}
```

Note: The exact background color (`bg-gray-900` vs `bg-ev-navy` vs some other dark) is a design call for the planner. The pattern is clear. The v2.0 design language suggests using `bg-ev-navy` or a slightly lighter surface color. Given the card sits ON a navy background, `bg-gray-900` (slightly lighter than ev-navy) provides the layering. Either works — the planner should pick one and be consistent.

### StepProgress Component

```typescript
// app/src/components/StepProgress.tsx
// Pattern: adapted from DashboardPage.tsx XP bar (lines 354–371)

interface StepProgressProps {
  currentStep: number;
  totalSteps: number;
}

export function StepProgress({ currentStep, totalSteps }: StepProgressProps) {
  const percent = Math.round((currentStep / totalSteps) * 100);

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between text-sm text-gray-400">
        <span>Step {currentStep} of {totalSteps}</span>
        <span>{percent}%</span>
      </div>
      <div className="h-1.5 rounded-full bg-gray-800 overflow-hidden">
        <div
          className="h-full rounded-full bg-ev-blue transition-all duration-500"
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}
```

### AppNav Component

```typescript
// app/src/components/AppNav.tsx
// Pattern: adapted from DashboardPage.tsx header (lines 279–304)

interface AppNavProps {
  children?: React.ReactNode;  // right slot for auth controls
}

export function AppNav({ children }: AppNavProps) {
  return (
    <header className="bg-ev-navy border-b border-white/10 sticky top-0 z-10">
      <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <img src="/logo.png" alt="Empowered Vote" className="h-6 w-auto" />
          <span className="text-sm font-semibold text-white/70">Civic Platform</span>
        </div>
        {children && (
          <div className="flex items-center gap-3">
            {children}
          </div>
        )}
      </div>
    </header>
  );
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tailwind.config.js` color tokens | `@theme { --color-* }` in CSS | Tailwind v4 | Must use CSS `@theme`, not config file |
| Class-based dark mode | `@custom-variant dark` with `.dark` class | Tailwind v4 | Already configured in both index.css files |
| `React.FC<Props>` type | `function Name({ }: Props)` | React team recommendation ~2022 | Already established in codebase |

**Deprecated/outdated:**
- `tailwind.config.js` color extension: not applicable in v4; `@theme` block is the only mechanism
- `@apply` for component abstractions: still works in v4 but not used in this codebase; stick with utility classes directly in JSX

---

## Open Questions

1. **AuthCard surface color**
   - What we know: The card sits on `ev-navy` (#020618) background; existing LoginPage uses `bg-gray-900` (#111827) for card backgrounds
   - What's unclear: Should AuthCard use `bg-gray-900` (has contrast with ev-navy) or `bg-ev-navy` (same as background, no visual separation) or some intermediate
   - Recommendation: Use `bg-gray-900` to maintain visual card separation from the navy background. This matches the existing LoginPage card styling exactly.

2. **Logo asset for AppNav**
   - What we know: `admin/public/logo.png` (688×156px PNG) exists and works in AdminLayout. `app/public/` has no logo file.
   - What's unclear: Whether to copy `logo.png` or use `Empowered_Vote_Logo_2026.png`, or use a text-only fallback until a proper asset is provided.
   - Recommendation: Copy `admin/public/logo.png` to `app/public/logo.png` as part of the DSGN-06 task. It's the known-good asset.

3. **SecondaryButton visual design**
   - What we know: No secondary button exists anywhere in the codebase to reference
   - What's unclear: Should it be an outline button (border only), a dark fill button, or a ghost/text button?
   - Recommendation: Dark fill with slightly lighter background than the card (`bg-gray-800 text-white border border-gray-700`) — consistent with the dark theme and distinguishable from PrimaryButton.

---

## Sources

### Primary (HIGH confidence)

- Live codebase inspection: `app/src/index.css` — verified Tailwind v4 `@theme` syntax in use
- Live codebase inspection: `admin/src/index.css` — confirmed identical pattern, only needs `ev-blue` added
- Live codebase inspection: `LoginPage.tsx`, `SignupPage.tsx` — confirmed no AuthCard/AuthInput/Button components exist; inline patterns to extract
- Live codebase inspection: `DashboardPage.tsx` — confirmed progress bar pattern + header/nav pattern
- Live codebase inspection: `app/package.json` — confirmed Tailwind v4.2.1 installed, `@tailwindcss/vite` plugin, no clsx/cn, no icon library
- Live codebase inspection: `app/public/` — confirmed no logo.png exists; needs to be added

### Secondary (MEDIUM confidence)

- Tailwind v4.2.1 installed package — `@theme` block with `--color-*` generates color utilities; verified by existing `bg-ev-teal`, `text-ev-red` usage throughout codebase working correctly

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — inspected installed packages directly
- Architecture: HIGH — derived from live codebase patterns, not speculation
- Pitfalls: HIGH — pitfalls 1-3 are from observed codebase patterns; pitfall 4 confirmed by `ls app/public/`

**Research date:** 2026-04-25
**Valid until:** 2026-05-25 (stable stack — no dependency churn expected)
