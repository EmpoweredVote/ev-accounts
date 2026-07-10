# Dual-pid politicians: mig-196 Senate placeholder + separate officeholder record (11 pairs)

Found 2026-07-10 during the Senate deep-seed dedup pass. Eleven 2026 Senate candidates exist as
TWO `essentials.politicians` rows each: a mig-196 "Candidate for U.S. Senate — <State>" placeholder
AND their real officeholder record. (Talarico/Paxton show the correct pattern — one politician,
both offices.) The Senate seed points `race_candidates` at the **placeholder pids** (they carry the
`politician_images` rows, so election cards get photos; officeholder pids have 0 image rows —
their photos ride `politicians.photo_origin_url` from the v2.15 era). Neither pid in any pair has
`politician_stances` rows, so no stance migration is needed.

## Merge direction (recommended)
Merge placeholder → INTO officeholder pid (the richer/original record), Talarico-style:
1. Move the "Candidate for U.S. Senate" `offices` row to the officeholder pid.
2. Move `politician_images` rows (rename storage keys `<old-pid>-headshot.jpg` → `<new-pid>-…`
   or re-upload; update url).
3. Repoint `race_candidates` rows (the 2026 Senate seed will have created these on placeholder pids).
4. Check every politician_id FK before delete (`information_schema` FK sweep), then delete placeholder.
Do each pair in one transaction; verify officials + elections surfaces after (the
'Candidate for%' title exclusion must keep working — see project_senate_candidate_office_leak).

## The 11 pairs (placeholder pid | officeholder pid)

| Person | Placeholder (KEEP assets from) | Officeholder (merge INTO) | Officeholder office |
|---|---|---|---|
| Barry Moore (AL) | 3428e87f-dc47-4033-9f6a-6fe63ffc9fc9 | ea4cb6d8-76aa-47f4-a064-babaac0bc436 | US Rep AL-1 |
| Mike Collins (GA) | ce8d48a3-5137-4521-81cd-8a86c0999b37 | b6542655-fc71-4b18-a022-6528522cdcae | US Rep GA-10 |
| Ashley Hinson (IA) | bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1 | 91aa37bf-dc8a-45f3-9bf7-e887b8dd99bd | US Rep IA-2 |
| Juliana Stratton (IL) | 965ffd53-89a8-46cc-adb1-16bf588ed1c3 | 40373be4-5a51-48d7-8afc-e6be734653ce | IL Lt. Gov (v2.18) |
| Julia Letlow (LA) | c79994ff-9e88-4318-97d9-d06b0ede183f | b0ef94c3-d047-4af3-907d-3d1da2b09e50 | US Rep LA-5 |
| Haley Stevens (MI) | 3957855d-a78c-492d-b3b6-0f680c1f82c8 | 5b642054-504c-46c8-a68b-324e7b593587 | US Rep MI-11 ("Haley M. Stevens") |
| Angie Craig (MN) | 0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff | 00b75ed0-3355-4bc5-a426-1667c12e2486 | US Rep MN-2 |
| Peggy Flanagan (MN) | 15bd3382-0d8a-4c3e-8ab9-ab324517882d | c788d228-1757-4069-bca4-6a9586819dc8 | MN Lt. Gov (v2.18) — BOTH pids have 1 image |
| Chris Pappas (NH) | a4f51d46-c361-4b17-bd63-7932a01ee2c3 | 36c07696-c330-45c8-aad9-eac9ee560cf1 | US Rep NH-1 |
| Kevin Hern (OK) | b1114b75-8ca1-494e-9251-e8faa84ff408 | 96e589b9-d04a-4749-bf9f-9b66eaea5083 | US Rep OK-1 |
| Harriet Hageman (WY) | e2f59e14-a81d-45fe-86c0-c992a63d86cd | 1e08c7c7-68c1-4498-90b2-20850bac1c80 | US Rep WY-AL ("Harriet M. Hageman") |

## NOT dual-pids — do not merge (wrong-person homonyms)
- Mike Rogers (MI Senate candidate, placeholder ace0b96d-8ef8-4aca-8928-6848ae430da6): the other
  two "Mike Rogers" pids are the ALABAMA US Rep (dafa64fd, NATIONAL_LOWER 0103) and a MARYLAND
  Delegate (24980735, STATE_LOWER 24032). Three different people.
- v2.18 lesson repeat: Stratton + Flanagan are Lt. Govs whose state-leader pids existed — same
  class as the WY Gray / SD Jackley reuse rule; the mig-196 placeholders should have reused them.

## Sequencing
AFTER the 2026 Senate seed lands (it references placeholder pids; merging first would break the
seed's pid map). No urgency — surfaces are correct today because the 'Candidate for%' exclusion
keeps placeholders out of officials lists and elections surfaces join politicians by pid either way.
