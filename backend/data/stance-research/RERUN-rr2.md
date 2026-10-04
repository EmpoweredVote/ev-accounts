# Coder re-run rr2 (2026-10-03)

The three headless coders re-run over the saved inputs of all 104 batches that carry blind gold, with
the codebook at master 80f78ceb: codebook 0.4 + H13–H17 **and the 60 Season 2 annexes (#854)**, which
`build-coder-inputs.ts` now puts in every coder prompt. Made by
`scripts/gold-desk/rerun_coders.py rr2`; stored under batch ids `<batch>-rr2`; reported with
`npx tsx scripts/reliability-report.ts --run rr2`. Committed files as for rr1 (see RERUN-rr1.md).

## Leakage

The annex "commonly confused / hard case" lines were drafted from adjudicated gold. The last annex edit
is 7f1c6f5c (2026-10-01 21:13 -04), so gold first recorded before 2026-10-02T01:14Z is annex-exposed:
72 of the 104 batches. 32 batches (rounds 12–18) are clean. View 3 drops the exposed batches with
`--exclude-batches` (report-level); `excluded_from_cert` is NOT set, because that flag is global and
certification eb2f791a rests on those rows.

## Result (state × record)

| view | run | gold | M1 α | M2 α | M3 | certified? |
|---|---|---|---|---|---|---|
| all | rr1 | 57 | 0.830 | 0.932 | 36/36 | yes |
| all | rr2 | 52 | 0.949 | 1.000 | 37/37 | yes |
| minus 7 H13–H17 items | rr1 | 55 | 0.824 | 0.929 | 36/36 | yes |
| minus 7 H13–H17 items | rr2 | 51 | 0.948 | 1.000 | 37/37 | yes |
| clean only | rr1 | 18 | 0.851 | 0.927 | 11/11 | no — n < 50 |
| clean only | rr2 | 17 | 0.944 | 1.000 | 8/8 | no — n < 50 |

Blanks (diagnostic): rr1 60/62, 2 missed chairs; rr2 62/62, 0 missed (clean: 19/19 → 20/20).

Views 1 and 2 are not evidence for the annex setup: 72 of their items could have written an annex line.
The clean view moves the same way (M1 0.851 → 0.944, M2 0.927 → 1.000) but has 17 gold and 8 unanimous
chairs, so it cannot certify. **No certification row written.** eb2f791a stands for the setup it
measured; rr2 does not show the annex setup is worse, so no decertification is indicated. Certifying the
annex setup needs ~33 more fresh record gold items (clean record n 17 → 50) with M3 Wilson low ≥ 0.90.

Invalid rows in rr2 (excluded by the report, as usual): bray-hb1032 c2, smaltz-hb1032 c2,
garten-sb1ss c1, behning-hb1296 c2 — one row each.
