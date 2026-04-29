---
phase: quick
plan: 260428-fp1
subsystem: feedback-pipeline
tags: [feedback, linear, resend, turnstile, ev-landing, ev-ui, ev-accounts]
dependency_graph:
  requires: []
  provides: [POST /api/feedback, feedback.html, FeedbackButton]
  affects: [ev-accounts, ev-landing, ev-ui]
tech_stack:
  added: [Cloudflare Turnstile (server-side verify), Linear GraphQL API, Resend email API]
  patterns: [honeypot spam filter, graceful-degrade on missing keys, ?feature= query param pre-fill]
key_files:
  created:
    - .planning/quick/260428-fp1-feedback-pipeline-worker-linear/SETUP-GUIDE.md
    - ev-accounts/backend/src/lib/feedbackService.ts
    - ev-accounts/backend/src/routes/feedback.ts
    - ev-landing/feedback.html
    - ev-ui/src/FeedbackButton.jsx
  modified:
    - ev-accounts/backend/src/lib/env.ts
    - ev-accounts/backend/src/index.ts
    - ev-landing/index.html
    - ev-ui/src/SiteHeader.jsx
    - ev-ui/src/index.js
decisions:
  - "All 5 new env keys added as optional so server starts without them in dev; each integration skips gracefully with a console.warn when key is absent"
  - "Honeypot field uses position:absolute/opacity:0 instead of display:none so bots with display-none detection still encounter it"
  - "Turnstile skip-in-dev behavior: when TURNSTILE_SECRET_KEY is absent, verification is bypassed with a warning (allows local dev without Cloudflare account)"
  - "ev-ui FeedbackButton added as top-level nav item in defaultNavItems (not in Features dropdown) for visibility"
  - "ev-landing committed and pushed directly to EmpoweredVote/ev-landing (separate git repo); ev-ui committed and pushed to EmpoweredVote/ev-ui with v0.6.6 tag triggering CI"
metrics:
  duration: "~3 minutes"
  completed: "2026-04-29"
  tasks_completed: 4
  files_changed: 10
---

# Phase quick Plan 260428-fp1: Feedback Pipeline — Linear + Resend + ev-landing + ev-ui Summary

**One-liner:** Full feedback pipeline: static HTML form on ev-landing with Turnstile/honeypot spam protection, POST /api/feedback endpoint routing to Linear issues + Resend email, FeedbackButton in ev-ui SiteHeader nav.

## Tasks Completed

| # | Name | Commit | Key files |
|---|------|--------|-----------|
| 1 | Linear setup guide + Render deployment instructions | d836d79 | SETUP-GUIDE.md |
| 2 | feedbackService + POST /api/feedback + env wiring | 0802edb | feedbackService.ts, routes/feedback.ts, env.ts, index.ts |
| 3 | feedback.html + index.html mailto swap | b50c7e3 (ev-landing) | feedback.html, index.html |
| 4 | FeedbackButton + SiteHeader + ev-ui v0.6.6 patch release | 2b47a92 + v0.6.6 tag (ev-ui) | FeedbackButton.jsx, SiteHeader.jsx, index.js |

## What Was Built

### SETUP-GUIDE.md
Step-by-step instructions for a developer to complete the pipeline setup: Linear API key + team/project IDs, feature label creation, Cloudflare Turnstile site setup, Resend domain verification, Render static site deployment, and Route 53 CNAME for ev-landing.empowered.vote. Includes a final checklist.

### POST /api/feedback (ev-accounts)
- Zod schema validates `body`, `feature` (enum of 8 values), optional `email`/`url`, honeypot `website`, and `cf-turnstile-response`
- Honeypot: filled `website` field → silent 200 (no side effects)
- Turnstile: server-side POST to `challenges.cloudflare.com/turnstile/v0/siteverify`; bypassed with warning if `TURNSTILE_SECRET_KEY` absent (dev mode)
- On pass: calls `submitFeedback()` which fans out to `createLinearIssue()` and `sendFeedbackEmail()` in parallel
- Both Linear and Resend integrations skip gracefully (warn + return) when API keys are absent

### feedback.html (ev-landing)
- Pure static HTML — no build step needed for Render deployment
- EV design tokens (Manrope font, `--teal`, `--coral`, `--yellow`, `--bg`, `--card`)
- Form fields: feature select (8 options), body textarea, optional URL, optional email
- Honeypot: `position:absolute; left:-9999px; opacity:0` (not `display:none`)
- Turnstile widget: `data-sitekey="REPLACE_WITH_SITE_KEY"` placeholder (developer replaces after Cloudflare setup)
- `?feature=` and `?url=` query params pre-fill fields on load
- Success/error states inline; submit button disabled during flight
- index.html: both `mailto:feedback@empowered.vote` hrefs replaced with `https://ev-landing.empowered.vote/feedback.html`

### FeedbackButton + SiteHeader (ev-ui v0.6.6)
- `FeedbackButton.jsx`: `<a>` link to `feedback.html` with optional `?feature=` encoding; accepts `feature`, `className`, `label` props
- `SiteHeader.jsx`: `defaultNavItems` now includes `{ label: 'Feedback', href: 'https://ev-landing.empowered.vote/feedback.html' }` as top-level nav item
- `index.js`: exports `FeedbackButton`
- Tag `v0.6.6` pushed — CI triggers npm publish + auto-bump PRs for CompassV2, essentials, read-rank, treasury-tracker

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ev-ui and ev-landing are separate git repos — committed within each repo's context**
- **Found during:** Task 3 and Task 4 staging
- **Issue:** `git add ev-landing/...` from the workspace root failed because ev-landing and ev-ui have their own `.git` directories; `npm version patch` also requires a clean working tree
- **Fix:** Ran `git add` and `git commit` from within each sub-repo directory (`ev-landing/`, `ev-ui/`); for ev-ui, committed the source files first then ran `npm version patch && git push --follow-tags`
- **Impact:** None — same commits, same tags, CI triggered as intended

## Known Stubs

One placeholder that requires manual replacement before the form works end-to-end in production:

| File | Location | Value | Action required |
|------|----------|-------|-----------------|
| `ev-landing/feedback.html` | `<div class="cf-turnstile" data-sitekey="REPLACE_WITH_SITE_KEY">` | Literal string `REPLACE_WITH_SITE_KEY` | Replace with actual Cloudflare Turnstile Site Key after completing SETUP-GUIDE.md Section 1 step 6 |

The backend bypasses Turnstile verification when `TURNSTILE_SECRET_KEY` is absent (dev mode) — so the form will function locally without the real key, but production requires both the site key in HTML and the secret key in Render env vars.

## Threat Flags

No new threat surface beyond what was modeled in the plan's threat register. All T-fp1-01 through T-fp1-05 mitigations are implemented:
- T-fp1-01 (Spoofing): Turnstile + honeypot in place
- T-fp1-02 (Tampering): Zod max(5000), title sliced to 60 chars server-side
- T-fp1-04 (Info Disclosure): IP extracted from X-Forwarded-For for Turnstile only; not stored or sent to Linear
- T-fp1-05 (DoS): Turnstile + honeypot block bulk submissions

## Self-Check: PASSED

All key files exist and all commits verified:
- SETUP-GUIDE.md: FOUND
- feedbackService.ts: FOUND
- routes/feedback.ts: FOUND
- ev-landing/feedback.html: FOUND
- ev-ui/src/FeedbackButton.jsx: FOUND
- Commit d836d79 (SETUP-GUIDE): FOUND
- Commit 0802edb (backend): FOUND
- Commit b50c7e3 (ev-landing): FOUND
- Commit 2b47a92 (ev-ui): FOUND
- Tag v0.6.6: FOUND
