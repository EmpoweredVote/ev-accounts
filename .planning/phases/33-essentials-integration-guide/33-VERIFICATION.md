---
phase: 33-essentials-integration-guide
verified: 2026-03-19T00:00:00Z
status: passed
score: 5/5 must-haves verified
---

# Phase 33: Essentials Integration Guide Verification Report

**Phase Goal:** The Essentials team has a reference document covering the Inform Pillar access pattern, the "never ask address again" jurisdiction principle, and how to surface Connected enhancements as opt-in — enabling correct anonymous and authenticated experiences in one guide.
**Verified:** 2026-03-19
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Developer knows when to show address input vs use jurisdiction silently, with concrete code pattern | VERIFIED | Section 3 + Section 5: three-branch `detectUserState()` TypeScript function with switch statement showing `renderAddressInput()` vs `renderWithJurisdiction()` by branch (lines 168–231) |
| 2 | Guide defines both UX states (anonymous/Inform and Connected) and specifies the transition | VERIFIED | Section 4 covers all three sub-states explicitly: Inform, Connected with jurisdiction, Connected without jurisdiction. Section 7 covers the Auth Hub redirect transition with full flow diagram (lines 105–404) |
| 3 | Guide covers how to detect a Connected user without requiring auth, and how to surface "connect your account" prompt | VERIFIED | Section 5 decision tree starts from localStorage token check — no auth required until a token exists. Section 4 Inform state specifies: "show a 'connect your account' prompt. Redirect to the Auth Hub on confirmation" (line 117) |
| 4 | All jurisdiction field names and canonical string formats listed with real production examples | VERIFIED | Section 6 provides TypeScript `Jurisdiction` interface with all 10 fields, a GEOID Format Table with format descriptions and example codes/names, explicit note on TIGER/Line 2024 source and numeric-only format (lines 244–293) |
| 5 | Guide specifies how Essentials can offer Connected enhancements as opt-in on top of anonymous experience | VERIFIED | Section 8 opens: "XP awards and gem awards are opt-in additions on top of the anonymous Essentials experience. Essentials works fully and correctly without them." Full request/response shapes, idempotency patterns, and gem type table provided. EDOC-06 checklist reinforces the pattern (lines 410–651) |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `docs/ESSENTIALS-INTEGRATION.md` | Essentials team integration reference, 200+ lines, contains "never ask for address" | VERIFIED | 654 lines. Contains "You must never ask a Connected user for their address" at line 94. Exports no code — documentation artifact. |

**Artifact level checks:**
- **Exists:** Yes — `docs/ESSENTIALS-INTEGRATION.md`
- **Substantive:** 654 lines (well above 200-line minimum). No stub patterns, no placeholder text, no TODO/FIXME comments.
- **Wired:** Documentation artifact — wiring concept does not apply in the traditional sense. The document is the deliverable itself.

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `docs/ESSENTIALS-INTEGRATION.md` | `GET /api/account/me` | Jurisdiction detection pattern | VERIFIED | Pattern present in Section 3 (line 97), Section 5 decision tree and TypeScript implementation (lines 144–204), and checklist EDOC-02 (line 611) |
| `docs/ESSENTIALS-INTEGRATION.md` | `POST /api/xp/award` | Connected enhancement documentation | VERIFIED | Full endpoint documented in Section 8 with request shape, response shape, TypeScript example, and idempotency guidance (lines 425–479) |
| `docs/ESSENTIALS-INTEGRATION.md` | `POST /api/gems/award` | Connected enhancement documentation | VERIFIED | Full endpoint documented in Section 8 with request shape, response shape, TypeScript example, and gem type table (lines 481–551) |

---

### Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| EDOC-01 — Jurisdiction Principle: Never Ask for Address Again | SATISFIED | Section 3 states it explicitly as a product violation. Checklist at lines 603–608. |
| EDOC-02 — Two-State UX Pattern: Inform vs Connected | SATISFIED | Section 4 covers all three sub-states. Three-branch TypeScript pattern in Section 5. |
| EDOC-03 — Auth Flow: Anonymous to Connected Transition | SATISFIED | Section 7 covers redirect construction, hash fragment extraction, token storage, and token lifecycle with full flow diagram. |
| EDOC-04 — Three-Pillar Philosophy: Inform Pillar Emphasis | SATISFIED | Section 2 states "Inform is not a degraded state; it is the baseline" (line 84). Section 8 reinforces the opt-in framing. |
| EDOC-05 — Jurisdiction Field Names and Formats | SATISFIED | Section 6 provides complete TypeScript interface + GEOID format table with all district types and production examples. |
| EDOC-06 — Connected Enhancements as Opt-In | SATISFIED | Section 8 framing, award endpoint documentation, idempotency patterns, and provisioning notes all present. |

---

### Anti-Patterns Found

None. The guide contains no TODO/FIXME markers, no placeholder text, no empty implementations, and no lorem ipsum. All code patterns are complete and runnable TypeScript.

---

### Human Verification Required

None required for a documentation artifact. The content is directly readable and verifiable against the must-haves.

---

## Summary

`docs/ESSENTIALS-INTEGRATION.md` exists, is 654 lines, and is substantive throughout. All five must-haves are fully addressed:

1. **Address input decision pattern** — the three-branch `detectUserState()` function in Section 5 gives a developer an exact, copy-pasteable pattern. The switch statement shows exactly which branches show address input and which use jurisdiction silently.

2. **Both UX states + transition** — Section 4 explicitly names and specifies Inform (anonymous), Connected with jurisdiction, and Connected without jurisdiction. Section 7 covers the full Auth Hub redirect transition with a rendered flow diagram.

3. **Connected detection without requiring auth** — Section 5 starts from `localStorage.getItem('ev_token')` with no auth prerequisite. The decision tree handles no-token and 401-expired-token identically, both returning the Inform state. The "connect your account" prompt trigger is specified in Section 4's Inform state description.

4. **Jurisdiction field names and formats** — Section 6 provides the complete `Jurisdiction` TypeScript interface, a 10-row GEOID Format Table with format descriptions and production examples (e.g., `"1807"` for Indiana's 7th Congressional District), and a note on TIGER/Line 2024 source and numeric-only format.

5. **Connected enhancements as opt-in** — Section 8 opens with the explicit opt-in framing, documents both award endpoints with full request/response shapes, provides idempotency guidance, and specifies that XP/gem calls must be skipped entirely for Inform users. The checklist EDOC-06 reinforces all gate conditions before first production use.

The phase goal is achieved.

---

_Verified: 2026-03-19_
_Verifier: Claude (gsd-verifier)_
