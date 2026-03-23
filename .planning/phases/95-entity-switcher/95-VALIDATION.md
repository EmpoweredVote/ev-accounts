---
phase: 95
slug: entity-switcher
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-22
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — treasury-tracker has no test framework installed |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | Manual browser verification |
| **Full suite command** | Manual browser verification (see protocol below) |
| **Estimated runtime** | ~120 seconds (manual) |

---

## Sampling Rate

- **After every task commit:** Manual smoke test in browser
- **After every plan wave:** Full manual test protocol
- **Before `/gsd:verify-work`:** Full protocol must pass
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 95-01-01 | 01 | 1 | UI-01 | manual | Browser: dropdown renders with grouped entities | N/A | ⬜ pending |
| 95-01-02 | 01 | 1 | UI-02 | manual | Browser: hero/breadcrumbs/tabs update on switch | N/A | ⬜ pending |
| 95-01-03 | 01 | 1 | UI-03 | manual | Browser: entities grouped by city/county in dropdown | N/A | ⬜ pending |
| 95-01-04 | 01 | 1 | UI-04 | manual | Browser: switch entities, verify no stale data | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No test framework to install — all verification is manual browser testing
- Treasury-tracker has no vitest/jest configured; adding a test framework is out of scope for Phase 95

*Existing infrastructure covers all phase requirements via manual verification.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Entity dropdown renders municipalities grouped by type | UI-01, UI-03 | No test framework; requires visual verification of grouped dropdown | Load app → click dropdown → verify Cities and Counties groups appear with correct entities |
| Hero card, breadcrumbs, dataset tabs update on entity switch | UI-02 | DOM state change requires browser interaction | Switch from Bloomington to Monroe County → verify hero title says "Monroe County Finances", breadcrumb shows "Monroe County", dataset tabs reflect available data |
| County label displays correctly (not "Monroe County, City") | UI-02 | Text rendering edge case requiring visual check | Switch to county entity → verify breadcrumb/hero show county label, not city suffix |
| Cache key prevents stale cross-entity data | UI-04 | Requires switching entities and verifying data freshness | Switch Bloomington → Monroe County → back to Bloomington → verify data matches each entity, no cross-contamination |
| URL params update and are shareable | UI-01 | Browser URL bar inspection | Switch entity → verify URL shows `?entity=bloomington-in` → copy URL → open in new tab → verify same entity loads |
| Disabled dataset tabs for missing data | UI-02 | Visual styling + interaction check | Switch to entity with missing dataset → verify tab is grayed out, non-clickable, shows tooltip |

---

## Validation Sign-Off

- [ ] All tasks have manual verify protocol
- [ ] Sampling continuity: manual check after each task commit
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
