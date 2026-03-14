# Phase 23: Central Profile Page + Admin Tier Promotion - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a single aggregated profile API endpoint that serves tier-appropriate data to public and authenticated callers, replace per-feature admin user views with a single profile page, and add admin tooling to promote users from Inform → Connected with a full audit trail. Candidate discovery/browsing and Connected friend-based stance sharing are explicitly out of scope.

</domain>

<decisions>
## Implementation Decisions

### Tier model and privacy contract

- **Empowered = public accountability**. Empowered users have opted into transparency — their compass answers and politician metadata are fully public. This is the value exchange of the Empowered tier.
- **Connected = private stances**. Connected users retain compass privacy. Public-facing profile shows display name (slug), level, and XP only — no stance data.
- **Inform = minimal public profile**. Display name, level, XP. No compass or gem data (they don't have connected_profiles rows).

### Public profile shape — `GET /api/account/profile/:userId`

Returned without authentication for any valid userId:

- **All tiers**: `{ username (= slug), tier, level, total_xp }`
- **Connected tier adds**: `{ selected_topic_ids }` (areas of interest, not stances)
- **Empowered tier adds**: `{ selected_topic_ids, compass_answers: [...], empowered_profile: { ...full politician record } }`
  - `compass_answers` = ALL answers, not filtered to selected topics. Full public record.
  - `empowered_profile` = full politician record (all columns from `inform.politicians` — office_title, district, representing_city, photo_origin_url, full_name, preferred_name, etc.)

Excluded from public view for all tiers: gems, tolerance_rating, legal_name, location, email.

### Owner profile — `GET /api/account/profile/me`

Authenticated owner gets public shape PLUS:
- `{ gem_balances: { yellow, blue, red }, location_consent, email }`

### Admin profile page layout

- **Placement**: Replace/extend existing account detail page at `/admin/accounts/:userId` — not a new section.
- **Accessible for all tiers**: Inform users can be viewed (admin needs this to promote them). Page renders with tier-appropriate sections.
- **Layout**: Sections/cards by data type:
  - **Account section**: tier badge, level, XP, gem balances (yellow/blue/red). Promotion CTA lives here (Inform-tier only).
  - **Compass section**: selected topics, answers (Connected and Empowered only).
  - **Politician section**: full politician record, all stances (Empowered only).
  - **Promotion History section**: all `tier_promotion_log` entries for this user.
- **Promotion button**: Hidden entirely for Connected and Empowered users. Only visible for Inform-tier accounts. No disabled state — simply absent.

### Promotion flow UX

- **Confirmation step**: Modal dialog showing the target user's name and current tier.
  - Note field: **optional** (not required — routine Alpha promotions shouldn't need justification).
  - CTA: "Promote to Connected" (clearly labeled).
- **Success feedback**: Modal closes → success toast ("John Smith promoted to Connected") → profile page refreshes in place. Promotion button disappears (user is now Connected).
- **Error states**: Attempting to promote an already-Connected or Empowered user returns a user-facing error without writing a log row. The promotion button is hidden for these tiers so this only triggers via direct API calls.

### Tier promotion audit log

- **Per-user**: Promotion history shown on the user's profile page (promotion history section).
- **Global log**: Separate `/admin/promotions` page showing all promotions across all users.
- **Columns displayed**: target display name, admin email, timestamp, note (if provided), previous tier → new tier.

### User search behavior

- **Location**: In the accounts list header (existing accounts section) — search plugs into the list.
- **Match type**: Partial/substring, case-insensitive ILIKE on both email and username (slug).
- **Results display**: Inline dropdown below search field, search-as-you-type. Admin clicks result to navigate to their profile.
- **No results**: Empty state with message "No users found for [query]" — clear and actionable.

### Claude's Discretion

- Exact columns returned in the `empowered_profile` block (read from `inform.politicians` schema)
- Debounce timing on search-as-you-type
- Promotion log pagination (if log grows large)
- Exact toast duration and styling
- Migration number for `connect.tier_promotion_log` table

</decisions>

<specifics>
## Specific Ideas

- **Empowered = less privacy, more power**: The privacy trade-off is explicit and intentional. Empowered users gain access to Empower Pillar features (Symposium speaking rights, etc.) in exchange for public accountability on their compass positions. Voters can sort/explore candidates by stances — the profile endpoint is the data foundation for this.
- **"Two Mars Problems" framing**: This profile endpoint becomes the canonical source of truth for who a user is across the platform. CompassV2 and CTC should eventually read from it.

</specifics>

<deferred>
## Deferred Ideas

- **Candidate directory / browse by stance** — No phase currently in roadmap. A `GET /api/account/candidates` endpoint returning all Empowered users filterable/sortable by compass position. Add to v1.3 backlog or new milestone. This is the discovery surface voters need to "sort and explore candidates."
- **Connected friend-based stance sharing** — Future social graph feature. Two Connected users who have "friended" each other can see each other's private compass stances. Requires friend graph schema (accept/decline requests), permission-scoped profile reads, and a friendship API. Own phase.
- **Aggregate compass stats** — "70% of Connected users picked X on this topic." Requires aggregation queries across connected_profiles compass answers. Separate analytics/insights feature.

</deferred>

---

*Phase: 23-central-profile-page-admin-tier-promotion*
*Context gathered: 2026-03-14*
