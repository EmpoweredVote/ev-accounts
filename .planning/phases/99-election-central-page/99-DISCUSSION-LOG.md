# Phase 99: election-central-page - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03
**Phase:** 99-election-central-page
**Areas discussed:** Verification method, Data scope, Fix ownership, Ship declaration bar

---

## Verification Method

| Option | Description | Selected |
|--------|-------------|----------|
| Playwright browser-drive | Agent navigates live site, captures screenshots, checks data against DB | ✓ |
| Structured checklist — user verifies | Agent generates checklist; user manually walks through and reports findings | |
| User tells me what they found | User has already checked; jump straight to Wave 2 | |

**User's choice:** Playwright browser-drive

---

| Option | Description | Selected |
|--------|-------------|----------|
| Page loads + address form renders | Basic smoke test — no JS errors, form visible | ✓ |
| Enter real address, verify elections list | Submit UT address, confirm elections list or empty state with correct data | ✓ |
| Data spot-check vs. DB | Cross-reference page display against essentials.elections + races for that location | ✓ |
| Mobile/responsive check | Resize to 375px, confirm layout not broken | ✓ |

**User's choice:** All four checks

---

| Option | Description | Selected |
|--------|-------------|----------|
| Utah primary address | e.g. '123 Main St, Salt Lake City, UT 84101' — nearest upcoming election | ✓ |
| Oregon address | e.g. Portland OR — Phase 89 data, good second check | |
| Both UT + OR | Run both addresses for more coverage | |

**User's choice:** Utah primary address only

---

## Data Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Upcoming elections only | election_date >= today — past elections are historical | ✓ |
| All elections in DB | Verify everything including past dates | |
| UT primary only | Focus entirely on June 23 Utah primary | |

**User's choice:** Upcoming elections only

---

| Option | Description | Selected |
|--------|-------------|----------|
| Correct election dates | Dates shown match DB | ✓ |
| Candidate names match DB | Every candidate matches essentials.politicians | ✓ |
| Race count completeness | Count of races shown matches essentials.races | ✓ |
| No withdrawn candidates shown | Verify withdrawn status honored | ✓ |

**User's choice:** All four data checks

---

## Fix Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Essentials is local at C:\Transparent Motivations\essentials | User-provided location | ✓ |

**Notes:** Also on GitHub and Render. Render auto-deploys from master.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Direct commit to essentials repo | Agent edits files, commits, Render auto-deploys | ✓ |
| PR to essentials repo | Agent opens PR; user reviews | |
| UI bugs to backlog — data fixes only | UI polish deferred | |

**User's choice:** Direct commit to essentials repo

---

## Ship Declaration Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Smoke test passes + MILESTONES.md updated | Page loads, elections appear for UT address, no console errors | ✓ |
| Every issue from Wave 1 fixed + smoke test | Nothing left open from verification | |
| Manual approval checkpoint | Agent stops; user confirms before writing milestone entry | |

**User's choice:** Smoke test passes + MILESTONES.md updated

---

## Claude's Discretion

None — all areas had clear user selections.

## Deferred Ideas

None — discussion stayed within phase scope.
