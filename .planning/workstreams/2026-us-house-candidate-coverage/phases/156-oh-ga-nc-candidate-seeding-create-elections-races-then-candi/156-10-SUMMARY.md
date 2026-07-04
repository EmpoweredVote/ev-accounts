# 156-10 SUMMARY — Phase 156 consolidated gate + coordinate smoke

**Status:** COMPLETE ✅ — Phase 156 verified end-to-end.
**Artifacts:** `backend/scripts/156-coordinate-smoke.ts` (new); `backend/scripts/156-verify.sql` (final skip-pins).

## Gate — `156-verify.sql` ALL PASS (psql exit 0, 11 PASS)
USHC2-03a, USHC2-03b, USHC2-02a, USHC2-02c (39 incl. NC-6 McDowell), D-04-GA, D-04-GA13, D-02, USHC2-04, USHC2-05a (0 unsourced), USHC2-05b, ALL ASSERTIONS PASSED. Write-free, per-state scoped.

## Coordinate smoke — GREEN (9 districts)
| geo | district | active | challengers | note |
|-----|----------|--------|-------------|------|
| 3901 | OH-1 | 3 | 2 | Landsman + Conroy + Hancock |
| 3904 | OH-4 | 3 | 2 | Jordan + Kolasinski + Wilson (I) |
| 3909 | OH-9 | 3 | 2 | Kaptur + Merrin + Althaus (L) |
| 1305 | GA-5 | 2 | 1 | renominated Williams + Salvesen |
| 1310 | GA-10 | 2 | 2 | **open**: Gaines active, Collins absent |
| 1313 | GA-13 | 2 | 2 | **VACANCY**: Clark + Chavez, 0 incumbent |
| 3701 | NC-1 | 3 | 2 | Davis + Buckhout + Bailey (L) |
| 3706 | NC-6 | 2 | 1 | McDowell (reused inc) + Jefferson |
| 3709 | NC-9 | 2 | 1 | Hudson + Ojeda |

All samples: geofence ST_Covers → race → active field with ≥1 challenger, 0 null pid. GA-10 D-04 open-seat guard + GA-13 D-04-GA13 vacancy guard both pass.

## Phase 156 final tallies (OH + GA + NC = 43 districts)
- **Migrations:** 1127 (3 elections + 43 races + GA-13 vacancy office), 1128 (OH), 1129 (GA), 1130 (NC).
- **New records:** OH 19 + GA 18 + NC 25 = **62 new politicians**, wired as **101 active race_candidates** (34 OH + 28 GA + 39 NC) alongside reused incumbents.
- **Headshots:** 5 imaged (Jasmine Clark, Houston Gaines, Richard Ojeda, Raymond Smith Jr., Laurie Buckhout) + 57 honest-skips (2 wrong-person attaches caught & reverted).
- **Stances:** 17 candidates covered (OH 9 / GA 5 / NC 2 new + **NC-6 McDowell 0→22**), 130 rows, **0 unsourced**; 46 whole-record honest-skips pinned (10 OH + 13 GA + 23 NC).
- **GA-13 vacancy:** office created (no ghost incumbent); Clark + Chavez active. **GA-1/10/11** lost/retired incumbents absent, certified nominees active.

## Carry-forward flags (for a post-hoc reconciliation, Phase-153-style)
1. **NC minor-line NCSBE reconciliation:** the official NCSBE 2026 filing CSV lists only Robert Luffman (NC-5) as an NC-US-House Libertarian; the other 154-listed NC Libertarians (Bailey/Laszacs/Cavender/Meilleur/Abu-Ghazalah/Feldman/Groo/Swinton) + Green (Aguilar) + Independent (Rogers) may not have certified. Records kept (locked 154 source). Recommend a certified-list prune.
2. **OH-1 Libertarian:** LPO lists Jason Stoops (not John Hancock) for OH-1 — possible 154 mis-ID.
3. **GA-13/GA-10 legislator records:** Jasmine Clark + Houston Gaines have GA-legislature roll-call records behind a JS SPA — candidates for a Playwright-based stance enhancement pass.
4. **McDowell + Jerrad Christian** stance coverage leans on iSideWith (candidate-stated) — candidates for later vote-based corroboration.

This SUMMARY is the OH+GA+NC input to the Phase 158 full-113-district gate.
