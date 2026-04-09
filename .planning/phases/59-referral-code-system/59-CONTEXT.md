# Phase 59: Referral Code System - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Level-gated invite quota system with social accountability. Users earn the ability to invite new members as they level up (via CTC or Validation Quests). Admins can override allocations per user. Inviters bear partial accountability for invitee misconduct via Tolerance Rating adjustment. The existing invite code infrastructure (`connect.invite_codes`, `connect.invite_chains`, `claim_invite_code` RPC) is the foundation — this phase adds quota enforcement, slot management, admin overrides, and the accountability surface.

</domain>

<decisions>
## Implementation Decisions

### Quota schedule
- **Level 1:** 0 invite codes — earn it before vouching for anyone
- **Levels 2–5:** 1 code earned per level, max 3 active invitees at any time
- **Levels 6–10:** 2 codes earned per level, max 5 active invitees
- **Levels 11–20:** 5 codes earned per level, max 10 active invitees
- **Levels 21+:** max 15 active invitees
- "Active invitee" = someone you invited who has not yet reached level 2
- **Codes are minted on demand** — no banking of code tokens. Your level determines your active invitee cap. You can generate a new invite code any time your active invitee count is below your cap.

### Code lifecycle
- **Form:** Single-use 8-character token (A3B7-XK29 format) — same as existing `connect.invite_codes` schema
- **Unclaimed expiry:** 30 days. If a generated code is never redeemed, it expires and the slot is freed with no penalty to the inviter
- **Graduation:** When an invitee reaches level 2, they "graduate" — that slot is freed, inviter can invite someone new
- **Suspension impact:** If an invitee is suspended/sanctioned, the inviter's slot is locked for min(60 days, until invitee is unsuspended). Slot is restored whichever comes first.
- **Revocation:** Inviters cannot revoke the relationship after a code is claimed. Admin-only revocation (e.g., for stolen/shared codes).

### Admin override
- **Per-user numeric override:** Admin can set a specific active-invitee cap for any user. `null` = use level-based default.
- **Unlimited option:** Admin can grant a user unlimited invites (stored as a special value, e.g., `-1` or a boolean flag).
- **Effective cap logic:** `max(level-based cap, admin override cap)` — override is a floor, never a ceiling. Leveling up can never reduce your cap.
- **Admin UI placement:** Two surfaces:
  1. Editable field on the user's profile page in the admin tool
  2. Dedicated "Invite Overrides" list view showing all users with active overrides

### Accountability surface
- **Invitee visibility:** Compact list on Profile Hub — username, standing (active/suspended), level progress toward graduation (level 2). No deeper stats (XP totals, activity).
- **UI location:** Profile Hub (`app.empowered.vote`) — dedicated Referrals section (tab or card)
- **Sanction notification:** Active in-app notification when an invitee is sanctioned and the inviter's TR is affected. TR change also recorded in TR history log.
- **TR penalty:** Scales with sanction severity — requires a severity field/category on the sanction record. This is a dependency: the sanctioning system must expose severity when TR adjustments are applied.

### Claude's Discretion
- Exact database column name and storage format for unlimited invites flag
- Whether invite cap override gets its own audit log table or uses the existing role audit pattern
- Profile Hub Referrals section layout (card vs tab)
- In-app notification delivery mechanism (reuse existing notification infrastructure or new)

</decisions>

<specifics>
## Specific Ideas

- Existing `connect.invite_codes` and `connect.invite_chains` tables are the foundation — no need to redesign code generation or claim flow
- The 8-character single-use token format (A3B7-XK29) is confirmed and preferred
- The level schedule was designed deliberately: slow early growth, bigger unlocks at higher commitment levels

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 59-referral-code-system*
*Context gathered: 2026-04-08*
