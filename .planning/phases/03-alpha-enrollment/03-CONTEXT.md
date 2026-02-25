# Phase 3: Alpha Enrollment - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce invite-only access and deliver the complete enrollment pipeline — from receiving an invite to holding a verified Connected profile. This covers: invite code generation and claim atomicity, the Connect verification flow (multi-step with resumption), compass data import from localStorage, and the Tolerance Rating accountability chain. Creating posts, compass calibration routes, and empowerment are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Invite code mechanics
- Code format: short alphanumeric, human-readable — e.g. `A3B7-XK29` (8 chars with hyphen)
- Each Connected user starts with 5 invite codes
- Codes expire after 30 days if unclaimed
- First invites (before any real users exist) are created by admin via the API — POST /api/admin/invites, which is built in Phase 7; this phase just needs to support admin-created codes in the data model

### Connect flow steps
- "Verified" at Alpha = valid invite code + required profile fields completed
- Connect flow is mandatory at signup — the invite code IS the entry point; no account exists without going through it
- Required fields before `connected_profiles` is created: `display_name`, `legal_name`, `location` (city/region), `home_address`
- Flow is resumable: if a user abandons mid-step and returns, they restart from the beginning of the step they abandoned (completed steps are not repeated)
- A user cannot repeat a completed Connect flow to create a second `connected_profiles` record

### Compass import during enrollment
- Import step is optional — offered during the Connect flow but skippable; user can calibrate later via Phase 4 routes
- Anonymous calibration source (Framer-hosted compass) is out of scope for Phase 3; this phase only handles the server-side import API endpoint
- Import step is presented only if the client detects localStorage compass data (or the client always offers the option and the user sees an empty import if nothing exists)

### Tolerance Rating adjustment
- Trigger: invitee is suspended by an admin action
- Direction: fixed decrement (Claude decides the exact value — e.g. -0.1 on a 0–1 scale, or -1 on a 0–10 scale based on schema conventions)
- Cascade depth: one level only — inviter's TR adjusts; inviter's inviter is not affected
- Visibility: inviter receives a notification event when their TR is adjusted ("Your Tolerance Rating was adjusted because an account you invited was suspended")
- Floor: TR cannot go below 0
- Consequence at floor: when inviter's TR reaches 0, their account is automatically suspended via the same mechanism as a manual admin suspension

### Claude's Discretion
- Exact TR decrement value (choose based on the scale defined in the schema)
- Version mismatch UX during compass import (flag mismatched topics, Claude decides how to surface them)
- localStorage cleanup after successful import (success criteria says "cleared only after successful import" — treat this as confirmed behavior)

</decisions>

<specifics>
## Specific Ideas

- Home address is required during Connect flow alongside legal name, location, and display name — the field needs to exist in `connected_profiles` or a related table if not already in schema
- Connect flow is the single entry point to the platform — no "sign up and connect later" path exists at Alpha

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-alpha-enrollment*
*Context gathered: 2026-02-25*
