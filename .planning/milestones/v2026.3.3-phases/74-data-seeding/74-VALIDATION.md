---
phase: 74
slug: data-seeding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 74 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — no automated test suite; Go build + manual SQL verification |
| **Config file** | none |
| **Quick run command** | `cd EV-Backend && go build -o server . && echo "build OK"` |
| **Full suite command** | Manual: psql queries to verify seeded rows + curl against running server |
| **Estimated runtime** | ~5 seconds (build) + manual queries |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-Backend && go build -o server . && echo "build OK"`
- **After every plan wave:** Run manual psql verification queries
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 74-01-01 | 01 | 1 | LINK-03 | manual-smoke | `psql $DATABASE_URL -c "SELECT body_key, geo_id, website_url FROM essentials.government_bodies WHERE state='18' AND body_key LIKE 'Monroe%' ORDER BY body_key, geo_id"` | N/A | ⬜ pending |
| 74-01-02 | 01 | 1 | LINK-04 | manual-smoke | `psql $DATABASE_URL -c "SELECT body_key, geo_id, website_url FROM essentials.government_bodies WHERE body_key='Bloomington Common Council' ORDER BY geo_id"` | N/A | ⬜ pending |
| 74-01-03 | 01 | 1 | LINK-03 | manual-smoke | `psql $DATABASE_URL -c "SELECT name, name_formal FROM essentials.chambers WHERE name IN ('Monroe County Assessor','Monroe County Sheriff','Monroe County Auditor')"` | N/A | ⬜ pending |
| 74-01-04 | 01 | 1 | LINK-03, LINK-04 | build | `cd EV-Backend && go build -o server .` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.*

No test framework installation needed. All validation is Go build + manual SQL queries.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 14 government_bodies rows seeded with non-null URLs | LINK-03, LINK-04 | No automated test suite; verification via direct DB query | Run psql query: `SELECT state, geo_id, body_key, display_name, website_url FROM essentials.government_bodies WHERE state='18' ORDER BY body_key, geo_id` — expect 14 rows, all with non-null website_url |
| body_key JOIN matches for Monroe County officials | LINK-03 | Requires running server + DB | Start server, curl ZIP 47401 search, verify Commissioner/Council/Sheriff JSON objects have non-empty government_body_url |
| body_key JOIN matches for Bloomington council | LINK-04 | Requires running server + DB | Start server, curl Bloomington address search, verify council member JSON objects have non-empty government_body_url |
| Seeded URLs are reachable government sites | LINK-03, LINK-04 | Network access required | Open each of the 4 URLs in browser: commissioners/, council/, monroe/, bloomington.in.gov/council |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
