---
phase: 60-design-foundation
plan: 02
subsystem: ui
tags: [react, typescript, tailwind, components, design-system]

# Dependency graph
requires:
  - phase: 60-01
    provides: ev-blue and ev-navy color tokens in app/src/index.css (focus ring depends on ev-blue)
provides:
  - AuthCard named export — dark rounded bordered card wrapper for auth/onboarding screens
  - AuthInput named export — fully controlled labeled input with ev-blue focus ring and ev-red error state
affects:
  - 60-design-foundation (plans 60-05, 60-06 may compose these)
  - 61-auth-flow-restyle (consumes AuthCard + AuthInput on every screen)
  - 62-onboarding-restyle (consumes AuthCard + AuthInput in step screens)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Named function exports (export function X), not React.FC or default export
    - TypeScript interface for props, not type alias
    - Fully controlled inputs — (value: string) => void onChange signature
    - Omit<InputHTMLAttributes<HTMLInputElement>, ...> escape hatch for pass-through inputProps
    - className trim() pattern for clean optional class merging

key-files:
  created:
    - app/src/components/AuthCard.tsx
    - app/src/components/AuthInput.tsx
  modified: []

key-decisions:
  - "AuthCard uses bg-gray-900 (not bg-ev-navy) — card must visually layer against the navy page bg"
  - "AuthCard omits width/max-width — parent owns sizing; onboarding steps may need wider than login"
  - "AuthInput focus ring is focus:ring-ev-blue (solid, not opacity variant) per design spec"
  - "AuthInput onChange is (value: string) => void — component extracts e.target.value, caller receives string"
  - "inputProps uses Omit<> to prevent TypeScript-invisible override of controlled props"

patterns-established:
  - "Controlled input convention: onChange: (value: string) => void (not React.ChangeEvent)"
  - "className merge pattern: template literal with .trim() for clean empty-string default"
  - "Omit<InputHTMLAttributes<...>, named-props> for pass-through escape hatches"

# Metrics
duration: 8min
completed: 2026-04-25
---

# Phase 60 Plan 02: AuthCard + AuthInput Components Summary

**Dark card wrapper (AuthCard) and fully-controlled labeled input (AuthInput) built as named exports with ev-blue focus ring, ready for Phase 61/62 auth and onboarding restyle.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-25T20:05:00Z
- **Completed:** 2026-04-25T20:13:00Z
- **Tasks:** 2
- **Files modified:** 2 (both created new)

## Accomplishments

- AuthCard: thin wrapper producing `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5` with optional className merge; no width hardcoded
- AuthInput: fully controlled labeled input with ev-blue focus ring in normal state and ev-red border/ring/error-paragraph in error state; stateless; Omit<> escape hatch for uncommon attributes
- Both components follow codebase conventions (named exports, interface props, no React.FC)
- App build passes; TypeScript strict check reports zero errors

## Task Commits

1. **Task 1: Create AuthCard component (DSGN-02)** — `2dfb785` (feat)
2. **Task 2: Create AuthInput component (DSGN-03)** — `70ffc39` (feat)

## Files Created/Modified

- `app/src/components/AuthCard.tsx` — Dark rounded bordered card wrapper; accepts children + optional className
- `app/src/components/AuthInput.tsx` — Controlled labeled input with label, input, and optional error paragraph

## Component API Reference

### AuthCard

```tsx
interface AuthCardProps {
  children: ReactNode;
  className?: string;        // optional — merged and trimmed into base classes
}
```

Base classes rendered: `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5`

No width hardcoded. Consumer applies `w-full max-w-sm` or similar via `className` or a wrapper div.

### AuthInput

```tsx
interface AuthInputProps {
  label: string;             // required — rendered as <label> above input
  type?: string;             // default: 'text'
  value: string;             // required — fully controlled
  onChange: (value: string) => void;  // required — receives string, not SyntheticEvent
  placeholder?: string;
  error?: string;            // if set: red border, red ring, red error paragraph below
  autoComplete?: string;
  required?: boolean;
  autoFocus?: boolean;
  inputProps?: Omit<InputHTMLAttributes<HTMLInputElement>,
    'type' | 'value' | 'onChange' | 'placeholder' | 'autoComplete' | 'required' | 'autoFocus'>;
}
```

Normal state: `border-gray-700 focus:ring-ev-blue`
Error state: `border-ev-red focus:ring-ev-red` + `<p className="mt-1.5 text-ev-red text-sm">{error}</p>`

## Decisions Made

1. **bg-gray-900 on AuthCard, not bg-ev-navy** — Card must provide visible contrast against the navy page background. Same color would make the card invisible. Resolved per 60-RESEARCH.md Open Question 1.
2. **No max-width in AuthCard base classes** — Login uses `max-w-sm`; onboarding step screens may need wider. Parent controls sizing, AuthCard never does.
3. **focus:ring-ev-blue solid (not /50 opacity)** — Design spec calls for a solid blue ring; opacity variants reserved for hover/disabled states.
4. **onChange as (value: string) => void** — Matches the convention used in existing onboarding step components; callers never need to touch a SyntheticEvent for a simple text input.
5. **Omit<> on inputProps** — Prevents a consumer from silently overriding `value` or `onChange` through the escape hatch; TypeScript catches it at compile time.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `AuthCard` and `AuthInput` are ready for Phase 61 (Auth Flow Restyle) and Phase 62 (Onboarding Restyle)
- Both imports: `import { AuthCard } from '../components/AuthCard'` / `import { AuthInput } from '../components/AuthInput'`
- Build verified clean; no TypeScript errors
- No blockers

---
*Phase: 60-design-foundation*
*Completed: 2026-04-25*
