---
phase: 160
slug: field-resolution-stance-gap-diagnostic
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-03
---

# Phase 160 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Phase profile: purely read-only diagnostic/data phase — SELECT-only prod queries via existing credentials, web research fetches of public election records, and git-tracked CSV artifacts. No new API surface, no user input, no app-serving endpoints, no package installs. ASVS V2–V6 Not Applicable (per 160-RESEARCH.md §Security Domain); supply-chain checkpoint (T-*-SC) N/A.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| diag scripts / 160-verify.sql → production DB | SELECT-only via existing `DATABASE_URL` (backend/.env, Session pooler); only writes are `CREATE TEMP TABLE ... ON COMMIT DROP` in the SQL gate | Public politician/race/district data |
| scripts → git-tracked CSV artifacts | Local CSV writes committed to `.planning/` only | Public election-field data |
| research agents / orchestrator → public web sources | Read-only fetches of official SoS/board-of-elections lists, Wikipedia, FEC API | Public election records |
| field-table CSVs → downstream seeding (Phases 161-165) | Canonical input artifacts; fabricated/mis-merged rows would corrupt seeding | Sourced ballot-field rows |
| Phase 160 → OR Phase-177/178 dirs (parallel session) | READ-only; no writes to reserved dirs | None |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-160-01 | Tampering | diag-160 DB scripts | mitigate | SELECT-only by construction; grep for INSERT/UPDATE/DELETE = 0 (verified in 160-01 execution; commit 9881ed7f reworded a banner comment to keep the grep clean); code review confirms read-only across all 5 files | closed |
| T-160-02 | Information Disclosure | .env / DATABASE_URL | mitigate | .env uncommitted; scripts load via dotenv/config, never echo credentials; CSVs contain only public data (code review: credential handling holds) | closed |
| T-160-03 | Tampering | negative external_id space | accept | Audit is read-only reporting; collisions resolved at seeding time via documented safe_start_seq (now incl. at-large cd=0 bands per fix b61f75df) | closed |
| T-160-04 | Tampering/Repudiation | field-table-p161 rows | mitigate | Source-URL-required per row (hard guard: 37/37 non-empty); flag-don't-guess; D-01a template validated on anchor wave | closed |
| T-160-05 | Information Disclosure | source citations (p161) | accept | Public election records; candidates are public figures already in prod | closed |
| T-160-06 | Tampering | field-table-p162 rows (esp. IN-9) | mitigate | Source-URL guard (33/33); IN-9 stale-flag bug documented-not-propagated (NOTE-IN9 in row; verifier confirmed correct incumbent flags) | closed |
| T-160-07 | Information Disclosure | source citations (p162) | accept | Public election records | closed |
| T-160-08 | Tampering | AL district-split + LA jungle rows | mitigate | Hard guards: AL exactly 3 decided + 4 late (district-specific sources); LA exactly 6 open-primary-nov3 + 2026-08-07 deadline | closed |
| T-160-09 | Information Disclosure | source citations (p163) | accept | Public election records | closed |
| T-160-10 | Tampering | field-table-p164 rows | mitigate | Source-URL guard (38/38); OR existing_race_id carried (no duplicate races); KY-CD1/OK-CD1 collision notes embedded | closed |
| T-160-11 | Tampering | OR Phase-177/178 dirs (parallel session) | mitigate | Plan wrote only phase-160 files; verified no writes under .planning/phases/177-*/178-*; OR agent explicitly scoped read-only | closed |
| T-160-12 | Tampering | RCV field completeness (AK/ME) | mitigate | D-04a maximal thoroughness: AK 15 candidates exact match between official DoE list and independent source; ME triple-source exhaustiveness; rcv=true guard (exactly 3 rows) | closed |
| T-160-13 | Tampering | NV/ME pre-existing rows | mitigate | existing_race_id hard guards (NV 4 + ME 2); NV-2 NULL-pid flagged fix-not-recreate; UT primary-derived + NOTE-UT-REDISTRICTED-2026 re-key note | closed |
| T-160-14 | Information Disclosure | source citations (p165) | accept | Public election records | closed |
| T-160-15 | Tampering | 160-verify.sql gate | mitigate | Write-free by construction (ON_ERROR_STOP, SELECT-only, ON COMMIT DROP temp tables); code review: assertions correct, re-runnable, clean | closed |
| T-160-16 | Tampering | master merge fidelity | mitigate | Verbatim concatenation with 178-row + 88/90 + seeding_phase-distribution guard; diag-160-validate-field-table.py exits 0 (re-run independently by orchestrator and verifier); verification 10/10 | closed |
| T-160-17 | Information Disclosure | .env / DATABASE_URL (psql gate) | mitigate | psql reads DATABASE_URL from env, never echoes; artifacts public-data-only | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-160-01 | T-160-03 | Collision audit is read-only reporting; actual collision-safety is enforced at seeding time via live pre-INSERT checks using the audited safe_start_seq values (19 districts incl. AK-CD0=5 / DE-CD0=48 / VT-CD0=6; KY-CD1/OK-CD1 = 200+ sub-band) | plan-time disposition (160-01-PLAN.md), execution confirmed | 2026-07-03 |
| AR-160-02 | T-160-05/07/09/14 | Source citations reference public election records only; every named candidate is a public figure in public filings | plan-time disposition | 2026-07-03 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-03 | 17 | 17 | 0 | orchestrator (plan-time register; execution-evidence classification: hard guards, grep write-scan, validator/verifier re-runs, code review CR + read-only confirmation, no-177/178-writes check) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-03
