# CA chairs owed evidence — handoff (2026-08-13)

Maryland is closed (debt 110 → 1). Next state is **CA: 31 rows across 8 politicians**.
Standard, gate and all cross-state lessons: [[chairs_owed_evidence]] in memory, plus `CLAUDE.md`.

## 🔴 CA IS NOT A STATE-LEGISLATURE PROBLEM. Do not build a leginfo scraper.
Every one of the 8 is a **CITY** official, so none of the Maryland tooling transfers:

| politician | body | rows |
|---|---|---|
| Igor Tregub | Berkeley City Council | 8 |
| Terry Taplin | Berkeley City Council | 7 |
| Ben Bartlett | Berkeley City Council | 6 |
| Rashi Kesarwani | Berkeley City Council | 4 |
| Brent Blackaby | Berkeley City Council | 2 |
| Todd Gloria | San Diego (Mayor) | 2 |
| Sean Elo-Rivera | San Diego City Council | 1 |
| Drew Boyles | El Segundo | 1 |

The instruments are **city ordinances, resolutions and council votes** on `berkeleyca.gov` and
`sandiego.gov`. Prior art for reading them: [[city_minutes_reresearch]]. `audit-chair-evidence.mjs`
already accepts `ordinance|agenda|minutes` in its INSTRUMENT_SRC, so a council ordinance passes the
gate the same way a bill does.
Topics are the LOCAL lens, not the national one: Rent Regulation, Homelessness Response,
Criminalization of Homelessness, Local Immigration Enforcement, Deportation Priorities, City
Sanitation and Cleanliness, Transportation Priorities, Residential Zoning, Fossil Fuel Policy,
Affordable Housing, Climate Change, Environmental Protection vs. Development, Public Safety.

## 🔴🔴 THE DEFECT THAT IS ALREADY VISIBLE: 13 of 31 rows cite NO .gov source at all
They rest on the politician's **own campaign site**, which is self-description, not an instrument —
the opposite of what the standard asks for:
- **Terry Taplin — ALL 7 rows** cite only `terrytaplin.com`
- **Rashi Kesarwani — ALL 4 rows** cite only `rashikesarwani.com`
- **Drew Boyles — 1 row** cites only `drewforelsegundo.com`
- **Sean Elo-Rivera — 1 row** cites `en.wikipedia.org` + `timesofsandiego.com`
Ben Bartlett's 6 rows mix `ben2024.com` with `berkeleyca.gov`; Tregub's 8 and Blackaby's 2 cite
`berkeleyca.gov` throughout — those are the healthiest.
⚠ A campaign-site citation is NOT automatically false, but it can never be the instrument. Treat
these 13 as needing a council record, not as needing deletion.

## Order of work
1. Regenerate the worklist: `node scripts/audit-chair-evidence.mjs --worklist <out>` and filter CA.
2. Berkeley first — 27 of the 31 rows, one source of record for five members. Find how far back
   `berkeleyca.gov` agendas/minutes go and whether votes are attributable per member.
3. Then San Diego (3) and El Segundo (1).
4. Read COMPLETE candidate lists per row before any blank, and FETCH every instrument before citing.

## Carry these in, all learned the hard way in MD
- 🔴 **The ranker's "no discriminating candidate" bucket is not a blank list.** Measured yield from
  reading it anyway: 3 of 42. From the flagged bucket: 8 of 26.
- 🔴 **Fetch every lead-sponsored instrument in a row before concluding anything about it** — the
  Hester error (mig 1737) was an absence built on the 2 bills of 5 I had not fetched.
- 🔴 **Magnitude is not provable from sponsorship.** Any chair pair differing only in degree
  ("moderately" vs "significantly") cannot be settled this way — all 13 MD Taxation rows died on
  this. Sean Elo-Rivera / Taxation ch2 is the same ladder; expect the same outcome.
- 🔴 **Read the whole record, not the flattering half.** Ellis was nearly seated on a no-net-loss
  co-sponsorship while his own lead bill exempted cemeteries from forest conservation.
- ⚠ **Check topic scope before sourcing.** Mig 1735 found 117 answers on ladders that speak as a
  judge or a prosecutor, held by people who are neither. `Public Safety Approach` appears in Tregub's
  set — confirm the local ladder is the one seated, not a role-conduct ladder.
- ⚠ On-topic by VOCABULARY ≠ by RATIONALE; a blank spoke is the correct honest state.
