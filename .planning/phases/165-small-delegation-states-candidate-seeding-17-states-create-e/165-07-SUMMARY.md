---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 07
state: RI+DE+VT+WY
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1268, 1269, 1270, 1271, 1272, 1273, 1274, 1275]
election_name: "RI/DE/VT/WY 2026 Statewide General"
---

# 165-07 SUMMARY — RI + DE + VT + WY late-primary PROVISIONAL fields

## What was built
4 elections + 5 races (RI 2, DE/VT/WY 1 at-large each) on existing NATIONAL_LOWER offices, all PROVISIONAL with **verified cull dates: RI ≥ 2026-09-09, DE ≥ 2026-09-15, VT ≥ 2026-08-11, WY ≥ 2026-08-18** (all fetched 2026-07-07). At-large races use the 'U.S. Representative At-Large' convention set in 165-03.

## Key facts (for 165-17 gate)
- **RI (migs 1268/1269):** -440101 Keenan (R), -440102 DeSouza (I) on RI-1; -440201 Mellor (R), -440202 Skoly (R) on RI-2. Incumbents reused: -44001 Amo, -44002 Magaziner.
- **DE (migs 1270/1271, Pitfall-6 trap validated):** seqs 1–47 confirmed live as **26 unrelated legacy Wave-1 records**; Earl Cooper created at **-100048 (mandatory safe_start_seq=48)**. McBride (-10000) reused.
- **VT (migs 1272/1273, safe_start_seq=6):** -500006 Coester (R), -500007 Malloy (R) — both R primary rivals seeded per the full-qualified-field rule — and -500008 Adam Ortiz (I, official VT SoS XLSX). Balint (-50000) reused.
- **WY (migs 1274/1275, OPEN):** Hageman (1e08c7c7) → Senate, **0 active rows**. 14 active candidates, 0 incumbent-flagged: **Chuck Gray = pid-reuse of the v2.18 WY Secretary of State record (b503b679, no new politician)** + 13 NEW at -560001..-560013 (Balow, Biteman, Chapman, Christensen, Dodson, Friess, Giralt, Rasner, Goodenough, Kinney, Del Real, Johnson-L, Workman-I).
- **DEVIATION (documented):** plan said WY = 18 candidates / "14-R primary"; the authoritative 160-field-table AND the live WY SoS primary roster PDF (re-fetched 2026-07-07) both show **10 R + 2 D + 1 L + 1 I = 14**. Plan's 18 was an authoring arithmetic slip; 14 seeded. Gate 165-17 pins race counts, not WY candidate count — no gate conflict.
- 5 races, all office_id NOT NULL, all PROVISIONAL; idempotent (re-run all 8 = 0 rows).

## Headshots — 2 uploads, 21 honest-skips
- Uploaded (correct-person WY politicians): -560002 Bo Biteman (state senator), -560001 Jillian Balow (former Superintendent).
- Honest-skips documented in `_ri/_de/_vt/_wy-house-headshot-results.json` (RI 4, DE 1, VT 3, WY 11). Chuck Gray reuses the already-imaged v2.18 record.
- DE/VT headshot bands are **lower-bounded** (-100048 / -500006) so legacy-record collisions are never scanned.

## Files
- `backend/scripts/165-{ri,de,vt,wy}-generate.mts`
- `backend/migrations/1268..1275_seed_{ri,de,vt,wy}_2026_house_*.sql`
- `backend/scripts/seed-{ri,de,vt,wy}-house-headshots.py`
- `backend/data/seed-wy-2026-house/165-07-ri-de-vt-wy-reconciliation.csv`

## Self-Check: PASSED
5 races PROVISIONAL with verified dates, office_id NOT NULL; DE seq-48 trap honored; VT seq-6; WY open 14-field 0-incumbent, Gray pid-reused, Hageman 0 rows; 0 dup; idempotent; headshots verified or honest-skipped. Ready for stance research (165-15).
