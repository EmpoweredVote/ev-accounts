---
quick_id: 260428-fp1
slug: feedback-pipeline-worker-linear
date: 2026-04-28
status: Ready for planning
---

# Quick Task 260428-fp1: Feedback Pipeline — Linear + Resend via ev-accounts

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Task Boundary

Wire up a feedback pipeline for Empowered Vote:
- Static `feedback.html` form in `EmpoweredVote/ev-landing` repo
- POST endpoint at `/api/feedback` in the existing `ev-accounts` Express backend
- Endpoint creates a Linear issue + sends email via Resend
- Spam protection: honeypot field + Cloudflare Turnstile (works as standalone widget, no CF hosting required)
- ev-ui shared header/PoliticianProfile gets a feedback button linking to the form with `?feature=` pre-filled
- ev-landing gets Render static site deployment configured

</domain>

<decisions>
## Implementation Decisions

### Form hosting
- Static `feedback.html` lives in `EmpoweredVote/ev-landing` repo
- Render deploys ev-landing as a static site (repo exists but not yet deployed — Render setup is in scope)
- Form POSTs to `https://api.empowered.vote/api/feedback`

### Backend
- New route `/api/feedback` added to `ev-accounts` Express backend (`backend/src/routes/feedback.ts`)
- New service `backend/src/lib/feedbackService.ts` handles Linear issueCreate + Resend email
- No new Render service, no Cloudflare Worker — use existing infrastructure

### Linear setup
- Linear workspace already exists; no need to walk through account creation
- Session delivers: label creation steps, API key generation instructions, team/project IDs needed for the mutation
- Labels needed: feature labels (compass, essentials, readrank, treasury, badges, trivia, landing, other) + severity labels (bug, data-error, idea, urgent)
- Default workflow states: Inbox → Triaged → In Progress → Done → Won't Fix

### ev-ui scope
- In scope: add a feedback button/link to ev-ui that links to `https://ev-landing.empowered.vote/feedback.html?feature=<feature>`
- Placement: TBD by implementer — likely in PoliticianProfile footer or a shared header component
- This counts as an ev-ui patch release (triggers auto-bump to consumers)

### Spam protection
- Honeypot field (hidden input, reject if filled)
- Cloudflare Turnstile (free, no Cloudflare hosting required — just include the script widget)
- Server-side: verify Turnstile token before processing; reject on failure

### Claude's Discretion
- Exact Render static site config (build command, publish dir) — use standard static HTML conventions
- CORS policy on `/api/feedback` — allow `*.empowered.vote` origins
- Email template design — match EV palette, keep it minimal (plain summary for internal use)
- Issue body format — follow user's spec: full body + email + URL + timestamp + IP-derived country + "Sent from ev-landing alpha" footer

</decisions>

<specifics>
## Specific Requirements

- Form fields: what's wrong (textarea, required), feature (dropdown), email (optional), URL (optional, pre-filled from `?url=` query param)
- Issue title: first 60 chars of the report text
- Issue description: full body + reporter email + source URL + timestamp + IP country (no full IP) + footer "Sent from ev-landing alpha"
- Linear label = feature dropdown value
- Resend email to: feedback@empowered.vote
- Form styling: Manrope font, EV palette (yellow #FED12E, teal #00657C, coral #FF5740, paper #fdfcf8)
- Feature dropdown values: Compass, Essentials, Read & Rank, Treasury Tracker, Empowered Badges, Civic Trivia, Landing page, Other
- Severity labels: user does not select severity — that's for triage. Only feature label set at submission time.
- Secrets: LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_PROJECT_ID, RESEND_API_KEY, TURNSTILE_SECRET_KEY stored as Render env vars (not in git)

</specifics>

<canonical_refs>
## Canonical References

- ev-accounts pattern: new service at `backend/src/lib/<feature>Service.ts`, route at `backend/src/routes/<feature>.ts`, wired in `backend/src/index.ts`
- ev-ui auto-bump pipeline: `npm version patch && git push origin main --follow-tags` → CI publishes to npm + dispatches bumps to 4 consumer repos
- Linear GraphQL API: `issueCreate` mutation (user will provide API key + team/project IDs after setup)
- Resend API: `POST /emails` with from/to/subject/html
- Cloudflare Turnstile: standalone widget at `https://challenges.cloudflare.com/turnstile/v0/api.js`, verify at `https://challenges.cloudflare.com/turnstile/v0/siteverify`

</canonical_refs>
