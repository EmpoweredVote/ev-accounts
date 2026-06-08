---
phase: 108
slug: la-county-city-officials
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 108 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL verification queries (psql / Supabase SQL editor) |
| **Config file** | none — migrations are SQL files applied to Supabase |
| **Quick run command** | `psql $DATABASE_URL -c "SELECT COUNT(*) FROM essentials.politicians WHERE external_id < -699999;"` |
| **Full suite command** | `psql $DATABASE_URL -f backend/scripts/verify-la-county-108.sql` (created in Wave 1) |
| **Estimated runtime** | ~5 seconds per verification query |

---

## Sampling Rate

- **After every task commit:** Run count query for affected city
- **After every plan wave:** Run full verification script for that wave's cities
- **Before `/gsd-verify-work`:** Full suite must be green (all expected counts match)
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-01 | 01 | 1 | LAOF-01 | — | N/A | sql | `SELECT COUNT(*) FROM essentials.politicians WHERE office_id IN (SELECT id FROM essentials.offices WHERE district_id IN (SELECT id FROM essentials.districts WHERE geo_id IN ('0643000','0630000','0608954','0619766','0622230','0636546','0640130','0652526','0655156','0656000','0658072','0669088','0680000','0684200')));` | ✅ | ⬜ pending |
| 108-02-01 | 02 | 2 | LAOF-02 | — | N/A | sql | `SELECT COUNT(*) FROM essentials.politicians WHERE office_id IN (SELECT id FROM essentials.offices WHERE district_id IN (SELECT id FROM essentials.districts WHERE geo_id IN ('0606308','0670000','0644000')));` | ✅ | ⬜ pending |
| 108-03-01 | 03 | 3 | LAOF-03 | — | N/A | sql | `SELECT COUNT(*) FROM essentials.politicians WHERE external_id BETWEEN -700999 AND -700001;` | ✅ | ⬜ pending |
| 108-04-01 | 04 | 4 | LAOF-04 | — | N/A | sql | `SELECT d.geo_id, COUNT(p.id) FROM essentials.districts d LEFT JOIN essentials.offices o ON o.district_id = d.id LEFT JOIN essentials.politicians p ON p.office_id = o.id WHERE d.geo_id IS NOT NULL GROUP BY d.geo_id ORDER BY d.geo_id;` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing Supabase infrastructure covers all migration execution
- No test file stubs needed — validation is via SQL verification queries after each migration

*SQL verification queries are embedded in each migration or run separately.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| photo_origin_url resolves to a real image | LAOF-05 | URL validation requires HTTP request | Spot-check 5–10 photo_origin_url values per wave in browser |
| is_incumbent reflects June 2026 reality | LAOF-01 | Requires knowledge of election outcomes | Verify against official city websites for any recently-elected members |
| Elected offices correctly excluded appointed ones | LAOF-06 | Requires charter research not automatable | Review West Hollywood + Carson city attorney seeding decisions vs. city charter |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
