# Phase 120: Contested-Race Bio + Photo Review Data

**Prepared:** 2026-04-16
**Candidates:** 11 total (11 needing bio, 1 needing photo)
**Scope:** Minimum-viable per scope_override — Priority B (10 bio-only) + Priority A (1 both) from `120-CANDIDATE-SCOPE.md`. Priority C (17 photo-only township candidates) deferred.

**Photo-column legend:**
- `EXISTING` — candidate already has a `type='default'` photo in Supabase CDN (verified via `essentials.politician_images`). No photo work needed — bio-only row.
- URL — photo to source and re-host in Plan 03.
- `NO_PHOTO` — no photo available from any source; ev-ui initials fallback will render.

## Review Table

| # | Candidate Name | Slug | Politician ID | Race | Bio Text | Photo Source URL | Source Citation | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Bob Nyquist | (no slug) | da3a4550-4a3e-449b-b4ca-bbc9b15a11d7 | Monroe County Assessor | Finance professional and Hinsdale Central High School alumnus seeking the Monroe County Assessor office, per his Ballotpedia Candidate Connection survey. | EXISTING | https://ballotpedia.org/Bob_Nyquist_(Monroe_County_Assessor,_Indiana,_candidate_2026) | APPROVED |
| 2 | Tanner Dale Branham | (no slug) | 88c1b0f1-470e-4d96-8518-306c92d12021 | Monroe County Clerk | Candidate for Monroe County Circuit Court Clerk. | EXISTING | https://ballotpedia.org/Tanner_Dale_Branham_(Monroe_County_Circuit_Court_Clerk,_Indiana,_candidate_2026) | APPROVED |
| 3 | Joe Davis | (no slug) | c0c45428-53c9-473e-ba4b-dc956d1868f2 | Monroe County Clerk | Candidate for Monroe County Circuit Court Clerk. | EXISTING | https://ballotpedia.org/Joe_Davis_(Monroe_County_Circuit_Court_Clerk,_Indiana,_candidate_2026) | APPROVED |
| 4 | Tree Martin Lucas | (no slug) | 609ee4ab-195b-4908-9463-9ff33c37688d | Monroe County Clerk | Candidate for Monroe County Circuit Court Clerk. | EXISTING | https://ballotpedia.org/Tree_Martin_Lucas_(Monroe_County_Circuit_Court_Clerk,_Indiana,_candidate_2026) | APPROVED |
| 5 | Benjamin T. Arrington | (no slug) | 6ede6d42-2364-4e97-82dc-1ad850239d08 | Monroe County Prosecuting Attorney | Candidate for Monroe County Prosecuting Attorney. | EXISTING | https://ballotpedia.org/Benjamin_T._Arrington_(Monroe_County_Prosecuting_Attorney,_Indiana,_candidate_2026) | APPROVED |
| 6 | Lilliana Young | (no slug) | 1b5e218c-8fe0-48fe-b7af-52a2fbf1b0fc | State Representative, District 061 | Self-described lifelong service worker, mother, and artist running for the Indiana House of Representatives, District 61, per her Ballotpedia survey. | EXISTING | https://ballotpedia.org/Lilliana_Young | APPROVED |
| 7 | James Graham | (no slug) | 037ad94f-d379-4f9c-baf1-a75742a46eac | United States Representative, Ninth District | Computer engineer with degrees from Rose-Hulman, Purdue, and MIT running for U.S. House, Indiana 9th District, per Ballotpedia. | EXISTING | https://ballotpedia.org/Jim_Graham_(Indiana) | APPROVED |
| 8 | Bradley Meyer | (no slug) | 926943ad-ee64-4ddb-b9e7-6475a6a2d087 | United States Representative, Ninth District | Brownsburg-born Purdue-educated civilian engineer at Crane Naval Sea Systems Command running for U.S. House, Indiana 9th District, per Ballotpedia. | EXISTING | https://ballotpedia.org/Brad_Meyer | APPROVED |
| 9 | Timothy Peck | (no slug) | a9233775-b8af-423e-aea6-734c2855e5ac | United States Representative, Ninth District | Harvard-trained emergency physician who founded three mission-based health technology companies, now running for U.S. House, Indiana 9th District. | EXISTING | https://ballotpedia.org/Timothy_Peck | APPROVED |
| 10 | Keil Roark | (no slug) | 283b1fdd-3d89-4f82-a065-098324f2f967 | United States Representative, Ninth District | U.S. Navy veteran (2010-2020) and Navy Reservist (2020-2021) running for U.S. House, Indiana 9th District, per Ballotpedia. | EXISTING | https://ballotpedia.org/Keil_Roark | APPROVED |
| 11 | David Waters | (no slug) | 533ae2ea-a474-4436-96b7-c2655242cefb | State Representative, District 060 | Vincennes-born homemaker and investment manager with degrees from Indiana University, Purdue, and CU Denver, running for Indiana House District 60. | https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/200/DavidWaters2026.jpg | https://ballotpedia.org/David_Waters | APPROVED |

## Bio Character Counts (verification — hard max 180)

| # | Name | Chars |
|---|---|---|
| 1 | Bob Nyquist | 153 |
| 2 | Tanner Dale Branham | 48 |
| 3 | Joe Davis | 48 |
| 4 | Tree Martin Lucas | 48 |
| 5 | Benjamin T. Arrington | 49 |
| 6 | Lilliana Young | 149 |
| 7 | James Graham | 127 |
| 8 | Bradley Meyer | 147 |
| 9 | Timothy Peck | 146 |
| 10 | Keil Roark | 123 |
| 11 | David Waters | 147 |

All under 180, all single sentence, all single-source (Ballotpedia).

## Photo Sourcing Summary

- **11 candidates** in scope for bios.
- **10 candidates** already have `type='default'` photos in Supabase CDN (marked `EXISTING`) — verified by direct query against `essentials.politician_images`. No photo work needed.
- **1 candidate** (David Waters) has no CDN photo — sourced URL from Ballotpedia for Plan 03 to re-host.
- **17 Priority C** photo-only township candidates out of scope per user's minimum-viable override.

## Notes

### Sourcing methodology

- **Primary source:** Ballotpedia candidate pages were the single named source for all 11 bios. Ballotpedia's Candidate Connection survey (self-reported) provided extractable facts for Bob Nyquist and Lilliana Young; Ballotpedia editorial content provided biographical paragraphs for the four U.S. House Indiana 9 candidates (Graham, Meyer, Peck, Roark) and David Waters.
- **Fallback used (D-15):** Three Monroe County Circuit Court Clerk candidates (Tanner Dale Branham, Joe Davis, Tree Martin Lucas) and one Prosecuting Attorney candidate (Benjamin T. Arrington) have Ballotpedia candidate pages but have not completed the Candidate Connection survey and have no extractable biographical detail. Office-title-only fallback applied per D-15 and `120-BIO-METHODOLOGY.md` Fallback section.
- **Antipartisan constraint (D-13):** No bio contains party framing. Party is omitted from every row even though several candidates' Ballotpedia pages label them "(Democratic Party)" or "(Republican Party)". The `race_candidates.primary_party` field carries party display at the UI level — bios do not duplicate.
- **Single-source rule (D-14):** Each bio is extracted and lightly compressed from a single Ballotpedia page. No multi-source synthesis. For candidates where Ballotpedia pointed to an external campaign site (e.g., Bob Nyquist's nyquist4mcta.com, David Waters' watersfor60.com), the external site was NOT pulled into the bio — Ballotpedia's own text is the named source.

### Slug field — downstream action required for Plan 03

All 11 `Slug` values are recorded as `(no slug)` because `essentials.politicians.slug` is NULL in the production DB for these candidates (confirmed in `120-CANDIDATE-SCOPE.md`). This matches the literal scope-doc data per Task 1 instruction to "copy slug values exactly."

**Plan 03 action item:** The import script must generate a slug for each candidate before constructing the Supabase Storage path (`monroe_2026/{slug}.{ext}`). Recommended pattern: lowercase full_name, replace spaces with hyphens, strip punctuation, append a UUID fragment if there's a collision — the same pattern used elsewhere in the codebase (e.g., `jack-davis-94a01ba3-2dac-4e54-bb11-3bf8fe7675b1`). This is a Plan 03 concern, not a Plan 02 blocker.

Only David Waters has a photo source URL in this review, so the slug-for-Storage concern applies to one candidate for this plan. Plan 03 should also write the generated slug back to `essentials.politicians.slug` so subsequent profile lookups by slug work.

### Photo source — David Waters

David Waters' photo is Ballotpedia's candidate thumbnail at `https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/200/DavidWaters2026.jpg`. Priority per D-08 would normally favor an official government page or campaign site over a third-party aggregator, but Waters is a first-time candidate with no incumbent .gov page, and his campaign site (watersfor60.com) was not fetched for this review. Ballotpedia's candidate-submitted photo is Tier 2 under D-08 (campaign-sourced, re-hosted by Ballotpedia) and was selected because it is stable and unambiguously the candidate. If the user prefers a direct campaign-site photo, mark the row EDIT with a replacement URL.

### Skipped from scope

Per user scope_override (see spawn prompt):
- All 17 Priority C photo-only township candidates (Bloomington/Clear Creek/Indian Creek/Perry/Richland/Salt Creek/Washington Township Boards) — deferred to a later phase.
- These candidates already have bios in the DB; only headshots are missing. Addressing them is a separate body of work not included in this minimum-viable sweep.

### Existing CDN photos (verified 2026-04-16)

10 of the 11 candidates already have `type='default'` rows in `essentials.politician_images` pointing to `https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/{uuid}-headshot.{ext}`. These were resurfaced via direct query — the original Wave 1 scope doc correctly classified them as Priority B "bio only", but the first pass of this review doc conflated "no photo researched" with "no photo exists" and mislabeled them `NO_PHOTO`. Corrected to `EXISTING`.

No photo re-hosting work is required for these 10 — Plan 03 touches only bio_text for them. David Waters is the sole photo-upload target.
