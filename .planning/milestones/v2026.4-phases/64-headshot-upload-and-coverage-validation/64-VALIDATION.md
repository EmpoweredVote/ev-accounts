---
phase: 64
slug: headshot-upload-and-coverage-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 64 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual script execution + coverage_report.py |
| **Config file** | none — script-based validation |
| **Quick run command** | `python3 coverage_report.py --check 1` |
| **Full suite command** | `python3 coverage_report.py` (all 3 checks) |
| **Estimated runtime** | ~60 seconds (HEAD requests to CDN URLs) |

---

## Sampling Rate

- **After every task commit:** Review stdout for `FAIL download` or `ERROR` lines
- **After every plan wave:** Run `python3 coverage_report.py --check 1`
- **Before `/gsd:verify-work`:** `coverage_report.py --check 1` must exit 0
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | PHOTO-03 | smoke | `python3 coverage_report.py --check 1` | Yes | ⬜ pending |
| 64-01-02 | 01 | 1 | PHOTO-04 | integration | `psql -c "SELECT COUNT(*) FROM essentials.politician_images WHERE type='default' AND url LIKE '%supabase%'"` | Yes | ⬜ pending |
| 64-01-03 | 01 | 1 | PHOTO-05 | smoke | `python3 coverage_report.py --check 1` exits 0 | Yes | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `EV-Backend/scripts/upload_manifest_headshots.py` — new upload pipeline script; covers PHOTO-03, PHOTO-04

*coverage_report.py already exists and covers PHOTO-05*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Politician profile pages display new headshots instead of initials | PHOTO-03 | Visual verification in browser | Navigate to essentials app, search LA County ZIP, verify politician cards show headshot images |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
