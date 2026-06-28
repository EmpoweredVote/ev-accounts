# Phase 117-03 Summary: MA City Official Stances — Wave 3 (Quincy)

**Status:** COMPLETE  
**Date:** 2026-06-14  
**Migration:** 597

## What Was Done

Researched and seeded stance data for Quincy city government officials. This was the final wave of Phase 117 MA City Official Stances (v2.13).

## Quincy Results

**29 stances across 9 officials.** 1 official honest-skipped (DiBona — no accessible public record).

| Official | Role | Topics Covered | Honest Skip |
|---|---|---|---|
| Thomas P. Koch | Mayor | economic-development=4, growth-and-development=4, housing=4, homelessness=4, homelessness-response=4, religious-freedom=4, city-sanitation=3, local-environment=3 | — |
| Anne Mahoney | At-Large | economic-development=3, local-environment=3, city-sanitation=3, public-safety-approach=3 | — |
| Ziqiang Yuan | At-Large | city-sanitation=3, economic-development=3, local-environment=3, public-safety-approach=3 | — |
| David Jacobs | Ward 1 | city-sanitation=4, local-environment=3 | — |
| Richard Ash | Ward 2 | city-sanitation=4, local-environment=3 | — |
| Walter Hubley | Ward 3 | city-sanitation=4, local-environment=3, transportation-priorities=3 | — |
| Virginia Ryan | Ward 4 | city-sanitation=4, local-environment=3 | — |
| Maggie McKee | Ward 5 | city-sanitation=3, local-environment=3 | — |
| Deborah Riley | Ward 6 | city-sanitation=4, local-environment=3 | — |
| Noel DiBona | At-Large | — | YES — no accessible public record |

**Primary sources:**
- Mayor Koch: wgbh.org (2018 downtown revitalization, 2018 Long Island Bridge, 2025–26 saint statues litigation), quincyma.gov
- All 8 councillors: Quincy City Council meeting minutes (cms7files1.revize.com), Jan–Apr 2026 — specifically the April 6, 2026 Joint Public Works & Ordinance Committee on sewer/FOG enforcement ordinances and March 2 snow operations briefing

**Key differentiator — sewer/FOG discharge ordinance vote (April 6, 2026):**
- Written-warning amendment proposed by Mahoney, supported by Yuan and McKee (→ sanitation=3)
- Amendment failed 2-7; Jacobs, Ash, Hubley, Ryan, Riley opposed it (→ sanitation=4 for those 5)

**Dropped row:** Koch/campaign-finance — only evidence was a 2023 MEC compliance settlement (absence of documented stance, not a real documented position). Dropped per no-party-inference constraint.

## Phase 117 Complete — All Waves

| Wave | City | Officials With Stances | Migration |
|---|---|---|---|
| 117-01 | Lowell | 11 officials, 21 stances | 584 |
| 117-02 | Brockton | 3 officials, 13 stances | 589 |
| 117-03 | Quincy | 9 officials, 29 stances | 597 |

## 3-Gate Verification (post-migration 597)

| Gate | Check | Result |
|---|---|---|
| Gate 1 | All 7 MA cities have officials_with_stances > 0 | PASS — Boston=14, Brockton=3, Cambridge=15, Lowell=11, Quincy=9, Springfield=8, Worcester=11 |
| Gate 2 | Global unpaired count = 0 | PASS |
| Gate 3 | Global uncited count = 0 | PASS |

## Next Phase

Phase 118: MA TIGER geofencing (ma_sldl + ma_sldu state legislative districts).
