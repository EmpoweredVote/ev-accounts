# Phase 29: Validation, Polish & Key Removal - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Confirm all BallotReady references are removed from Go source code, decommission the BALLOTREADY_API_KEY from all deployment environments (App Runner, Netlify), and configure Google Maps API billing monitoring. The backend must start and operate normally without the BallotReady key.

</domain>

<decisions>
## Implementation Decisions

### Billing alerts
- Monitor Google Maps API call volume, not dollar spend
- Alert threshold: 5,000 API calls per month (halfway to the 10,000 free tier limit)
- Notification: email only to the default GCP project account email
- No daily request quota cap — keep the API fully open, rely on the email alert
- No hard limits or daily caps; this is informational monitoring only

### Claude's Discretion
- Audit scope: how thoroughly to grep for BallotReady references (Go source vs configs/docs/comments)
- Key removal order: whether to verify code works without key before removing from environments
- How to handle historical BallotReady mentions in migration files or comments
- Exact grep patterns and file exclusions for the codebase audit

</decisions>

<specifics>
## Specific Ideas

- User is on Google Maps free tier (10,000 calls/month free) and expects current usage to stay well within that
- The 5,000-call alert is an early warning — not an action trigger, just awareness

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 29-validation-polish-key-removal*
*Context gathered: 2026-02-22*
