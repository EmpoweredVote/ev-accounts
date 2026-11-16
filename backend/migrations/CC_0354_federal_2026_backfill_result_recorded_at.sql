-- CC_0354 - 2026-11-03 federal: backfill `result_recorded_at` on the 1,009 rows written by
-- CC_0339, CC_0350 and CC_0351.
--
-- `CC_0350`, `CC_0351`, `CC_0352` and `CC_0353` each reported the same debt. This pays it.
--
-- 🔴 IT IS NOT ONE DEFECT, IT IS TWO, AND THE SMALLER ONE IS WORSE.
--
--   854 rows - `result_recorded_at` IS NULL. The outcome is recorded; when we recorded it is not.
--   155 rows - `result_recorded_at` IS SET AND IS WRONG. These are the rows that already carried
--              `result = 'advanced'` with a state ballot-qualification citation when the AP call
--              overwrote it. The timestamp was never updated, so it still dates the BALLOT
--              RECORD - 2026-08-20 to 2026-09-24 - against a result that did not exist until
--              2026-11-04. The column's own comment reads "When the outcome was written"; for
--              these 155 it names the write of an outcome that is no longer there.
--              ▶ A NULL SAYS "UNKNOWN". A STALE VALUE MAKES A FALSE STATEMENT. Both are fixed
--              here, and the 155 old values are written down below because there is no history.
--
--   854 + 155 = 1,009, which is the figure the four earlier passes reported.
--
-- ============================================================================================
-- 🔴 THE TRUE WRITE INSTANT IS UNRECOVERABLE. THIS FILE WRITES A DERIVED VALUE AND SAYS SO.
-- ============================================================================================
-- Three places could have held the real moment. All three were checked, and all three are empty:
--
--   1. `race_candidates.updated_at` EXISTS, AND IT CANNOT DATE A RESULT. No trigger maintains
--      it - the table's only trigger is `race_candidate_mirror_data` (politician_id /
--      photo_url / website_url) - so it moves only when a writer sets it by hand, and the three
--      result migrations never did. 🔴 PROVEN, NOT ASSUMED: Chuck Edwards' row was updated by
--      `CC_0352` on 2026-11-04 and its `updated_at` still reads 2026-07-01T04:12:58.150Z, its
--      insert default. Anyone reaching for this column would have back-dated rows by months.
--      ⚠ AND IT IS NOT UNIFORMLY STALE, WHICH IS WHY IT IS WORSE THAN USELESS: 1,060 of the
--      table's 5,175 rows DO carry an `updated_at` later than `created_at`, written by other
--      code paths. So the column looks maintained, answers plausibly for a fifth of the table,
--      and is silent about every result this programme wrote.
--   2. POSTGRES COMMIT TIMESTAMPS - `track_commit_timestamp` is `off` on this server, so
--      `pg_xact_commit_timestamp(xmin)` holds nothing. (Turning it on is a server setting and a
--      restart; it would only help from that point on, and it is worth doing for the next time.)
--   3. A SERVER LOG - `apply-migration-file.mjs` writes to stdout only, there is no apply table
--      by design (see `CC_0070`'s table comment), and the management API's log endpoint this
--      repo's tooling uses has been withdrawn. Ordinary DML would not be logged in any case.
--
-- ▶ SO EACH ROW GETS THE GIT COMMIT TIMESTAMP OF THE MIGRATION THAT WROTE ITS RESULT:
--
--   | migration | rows | commit   | committed (UTC)          | what it wrote                 |
--   |-----------|------|----------|--------------------------|-------------------------------|
--   | CC_0339   |   33 | 3d4088708| 2026-11-05T00:02:22Z     | the Senate winners            |
--   | CC_0350   |  377 | f7702c4fc| 2026-11-05T00:41:54Z     | the House winners             |
--   | CC_0351   |  599 | 21c54a4e9| 2026-11-05T01:12:43Z     | the losers, both chambers     |
--
-- ⚠ THIS IS AN UPPER BOUND, AND IT IS SLIGHTLY LATE. The workflow is apply-to-production, then
-- commit, so each write happened a few minutes BEFORE the timestamp it is now given. The error
-- is minutes and it is in a known direction. It is not a measurement and must not be read as
-- one. `CC_0339`'s is the EARLIEST commit of that file, not its squash-merge (#1317, 16:11:50
-- -08:00), because the earliest commit is the one nearest the apply.
--
-- 🟢 THE THREE DERIVED VALUES CROSS-CHECK AGAINST TWO MEASURED ONES. `CC_0352` and `CC_0353`
-- stamped their own rows with `now()` at apply: 2026-11-05T01:59:21.737696Z and
-- 2026-11-05T05:07:55.375038Z. The five timestamps are strictly increasing in the order the five
-- passes ran - 00:02:22 < 00:41:54 < 01:12:43 < 01:59:21 < 05:07:55 - and the three derived ones
-- all fall before the first measured one. A gate below asserts exactly that, so a mistyped
-- timestamp raises instead of landing.
--
-- ⚠ PIN A TIMESTAMP ON WHAT THE DATABASE PRINTS, NOT ON WHAT A CLIENT HANDS YOU. Those two
-- measured values are stored to MICROSECONDS (.737696, .375038); the `pg` driver returns a JS
-- `Date`, which truncates to MILLISECONDS (.737, .375). The first draft of the gates below
-- pinned the truncated values and the dry run failed with "0 of the 4 CC_0352 rows keep their
-- measured timestamp" - a real equality failure that reads like a data problem. Read such a
-- value with `to_char(... ,'YYYY-MM-DD HH24:MI:SS.US')`.
--
-- ============================================================================================
-- 🔴 THE ATTRIBUTION IS MEASURED, NOT ASSUMED
-- ============================================================================================
-- Which migration wrote a row is derived from the row itself: AP-sourced (its `result_source`
-- carries `interactives.apelections.org`), then
--   Senate + `won`  -> CC_0339 · House + `won` -> CC_0350 · `lost` -> CC_0351
-- with the six rows `CC_0352` and `CC_0353` already stamped excluded BY ID.
--
-- 🟢 THAT SPLIT LANDS ON 33 / 377 / 599, WHICH IS WHAT THE THREE MIGRATIONS SAID THEY WROTE.
-- 🟢 AND THE 155 STALE ROWS SPLIT 51 `won` / 104 `lost` - which is exactly the count of prior
-- citations `CC_0350` (51) and `CC_0351` (104) each reported overwriting, arrived at from the
-- opposite direction. Two independent descriptions of the same set agreeing is the evidence
-- that the attribution is right.
--
-- ============================================================================================
-- 🔴 THE 155 VALUES THIS FILE OVERWRITES. THERE IS NO HISTORY TABLE; THIS IS THE ONLY RECORD.
-- ============================================================================================
-- Every row below is an AP-called result whose `result_recorded_at` still dated the ballot
-- record the call replaced. Format: race_candidates.id · old value (UTC) · seat · result · name.
-- The same list is committed as JSON at
-- `backend/data/federal-2026-recorded-at-backfill/overwritten-2026-11-05.json`.
--
--   87c7fc49-b43b-4b3f-bc3d-ede77cb5cfbf  2026-09-24T20:15:04.341Z  AZ-07  won   Adelita S. Grijalva
--   c3490d9f-24b3-4e0c-bedd-3a530c3ffb8b  2026-09-24T20:15:04.341Z  AZ-03  lost  Alan Aversa
--   253874ea-6251-4890-856d-8d8a6529fbac  2026-09-24T20:15:04.341Z  AZ-07  lost  Daniel Butierez
--   52ec0d01-905c-484d-99cd-df28212e02be  2026-09-24T20:15:04.341Z  AZ-09  lost  Danielle Sterbinsky
--   ad7ead77-4a7e-4480-bd2c-41c94a6f77b1  2026-09-24T20:15:04.341Z  AZ-03  lost  David Redkey
--   d6aa8f68-d09d-47aa-b148-e6cb3e446038  2026-09-24T20:35:12.067Z  AZ-09  lost  G. Seville Hatch
--   9f7085a4-5608-4d44-973c-b92e40c50296  2026-09-24T20:15:04.341Z  AZ-04  won   Greg Stanton
--   8d99369d-9410-4f80-b6c1-8da8a037da7c  2026-09-24T20:35:12.067Z  AZ-03  lost  Jacob Parkman
--   44fb6bc9-ddf9-4fe2-834d-0694c5b449b4  2026-09-24T20:15:04.341Z  AZ-09  won   Paul A. Gosar
--   f5afe8a7-52b3-4a25-8273-db819176dd00  2026-09-24T20:35:12.067Z  AZ-04  lost  Steven Sanders
--   2a4219ee-f0c3-4103-8f88-ea57c36c9ac5  2026-09-24T20:15:04.341Z  AZ-04  lost  Tisha Benoit
--   8a69effe-8ab1-4b69-b069-fb2315b732d7  2026-09-24T20:35:12.067Z  AZ-09  lost  William Perry
--   de1604fd-b4af-44c7-8b44-33d2c0c7df45  2026-09-24T20:15:04.341Z  AZ-03  won   Yassamin Ansari
--   bd444d5b-e687-4b8e-a2fe-e9ee9157d31a  2026-09-24T20:15:04.341Z  AZ-04  lost  Zuhdi Jasser
--   a86bf332-9a10-409b-a9a9-fa0b32715864  2026-09-24T17:35:22.369Z  CT-01  lost  Amy Chai
--   ac44106a-8532-4f69-9ee2-6366f8f8ab74  2026-09-24T17:50:11.994Z  CT-04  lost  Benjamin Wesley
--   6d30cfb2-0eb9-4b58-9130-860bfa97414c  2026-09-24T17:35:22.369Z  CT-05  lost  Chris Shea
--   3672fd86-0b4f-422e-ad5a-00e60ef1e8bc  2026-09-24T17:35:22.369Z  CT-03  lost  Christopher Lancia
--   9140d372-dea4-4743-b393-465321cf2118  2026-09-24T17:35:22.369Z  CT-02  lost  George Austin
--   3c85fa92-e2df-4c43-bc07-f13e93a85b46  2026-09-24T17:35:22.369Z  CT-05  won   Jahana Hayes
--   6f017a10-98e4-47c0-a23f-35eca564be75  2026-09-24T17:35:22.369Z  CT-04  won   James A. Himes
--   4f9080b8-b12d-4378-9221-c87514c71f02  2026-09-24T17:35:22.369Z  CT-02  won   Joe Courtney
--   6602313e-1891-45b2-887d-c2acfdda71b4  2026-09-24T17:35:22.369Z  CT-01  won   Luke Bronin
--   05415e85-0f0d-42fa-aa4f-b253575a1f6c  2026-09-24T17:50:11.994Z  CT-01  lost  Mary L. Sanders
--   2c1dc290-4597-4bad-89e6-4517fc6fd9f2  2026-09-24T17:35:22.369Z  CT-04  lost  Michael Goldstein
--   cd4e98a2-20de-4a56-a353-9ae492ee6eb2  2026-09-24T17:35:22.369Z  CT-03  won   Rosa L. DeLauro
--   50b2fa4e-8775-41f6-90b5-b30969d45ff3  2026-09-24T17:50:11.994Z  CT-03  lost  Thomas Egan
--   80a1d902-ea40-4e12-a376-2ac48a60b0b3  2026-09-24T17:50:11.994Z  DE-00  lost  Joseph "Dr. Joe" Arminio
--   78dd9d2c-88a5-4f34-a250-ec7e196f1160  2026-09-24T17:24:03.868Z  DE-00  won   Sarah McBride
--   bbdcadb5-3930-4551-b980-e9359d155bcf  2026-09-24T17:18:34.927Z  HI-01  lost  Adriel Lam
--   6ff63143-4c56-4fa5-be14-8b148f968fc2  2026-09-24T17:18:34.927Z  HI-02  lost  Brenton Awa
--   4a5ab0f0-4211-4d9d-9dae-0d161d38ce8d  2026-09-24T17:18:34.927Z  HI-01  won   Ed Case
--   8c4289e2-81d5-465d-9bcb-36dc6d63fcfb  2026-09-24T17:18:34.927Z  HI-02  won   Jill N. Tokuda
--   c22df365-3f41-4eb9-91ae-c6970b263379  2026-09-24T17:18:34.927Z  HI-01  lost  Jordan Conley
--   dfa31d60-a534-43d2-83c6-2268a86e8fe4  2026-09-24T17:18:34.927Z  HI-01  lost  Nathan Berning
--   b8eecbc8-18cd-456e-9cda-d67cbf652a28  2026-09-24T17:24:03.868Z  KS-04  lost  Drew Cranmer
--   651a06ca-318d-4c40-9f16-ddff0cc593cc  2026-09-24T17:24:03.868Z  KS-04  lost  Katy Tyndell
--   025a9ecc-5db0-465c-8b42-5e0aea994d41  2026-09-24T17:24:03.868Z  KS-04  won   Ron Estes
--   a4aeb4c8-02e1-4c77-83be-76f41775c15d  2026-09-24T17:24:03.868Z  MA-01  lost  Nadia Milleron
--   9bce4e4c-a8b9-43ed-85d5-028a65b47964  2026-09-24T17:24:03.868Z  MA-01  won   Richard Neal
--   69d5c0d8-4b88-42d0-a738-e2b932e3789f  2026-09-24T17:24:03.868Z  MN-04  won   Betty McCollum
--   4aa10c13-4a7f-43bd-93e5-2fe53bfecc07  2026-09-24T17:24:03.868Z  MN-05  lost  DeVelle L. Jackson
--   d304d71d-8b67-424a-8148-37e8adcca217  2026-09-24T17:24:03.868Z  MN-06  lost  Doug Chapin
--   4158e0ac-e400-4b01-ac8a-453c5a370308  2026-09-24T17:24:03.868Z  MN-02  lost  Eric Pratt
--   4bf01c51-2a3b-4e37-9d78-5049b4f1e01e  2026-09-24T17:24:03.868Z  MN-07  lost  Erik Osberg
--   b402d5e0-e0fc-4809-80c7-597157d2ae07  2026-09-24T17:24:03.868Z  MN-05  won   Ilhan Omar
--   b683c3a8-8e53-4aa5-a4e1-7ed80e778f97  2026-09-24T17:24:03.868Z  MN-05  lost  John Nagel
--   c3d3e28b-4e31-4f4c-b785-8efbfd3fd70d  2026-09-24T17:24:03.868Z  MN-03  won   Kelly Morrison
--   21727028-c911-4be8-891a-95654de2a820  2026-09-24T17:24:03.868Z  MN-02  won   Matt Little
--   8353a4cb-141f-490e-9145-cd58d3218189  2026-09-24T17:24:03.868Z  MN-07  won   Michelle Fischbach
--   cab9b5af-1158-4dc8-85f9-035faeb56d9c  2026-09-24T17:24:03.868Z  MN-04  lost  Paul Wikstrom
--   98ca2883-f97a-4d54-8849-a91fed0db3ed  2026-09-24T17:24:03.868Z  MN-08  won   Pete Stauber
--   b1bfe00f-9dce-4c41-9db7-1548956e1663  2026-09-24T17:24:03.868Z  MN-06  won   Tom Emmer
--   6856c62d-5df7-4c05-8992-9e806f658158  2026-09-24T17:24:03.868Z  MN-08  lost  Trina Swanson
--   d1999bb6-8e1a-43f3-8731-b4fe885f5e35  2026-09-24T17:24:03.868Z  MN-03  lost  Tyler Bass
--   4e86b181-3de5-43fa-b6f9-8cebcc29ea62  2026-09-24T17:24:03.868Z  NH-01  lost  Anthony DiLorenzo
--   f7d7f4d0-942b-416b-9b98-ac2d0209d7fc  2026-09-24T17:24:03.868Z  NH-02  lost  Lily Tang Williams
--   910046e6-0f0e-4590-9447-97edf90e2b98  2026-09-24T17:24:03.868Z  NH-02  won   Maggie Goodlander
--   5a8a1916-7e31-43dd-bab5-5043fe607b7e  2026-09-24T17:50:11.994Z  NH-02  lost  Robbie Mahrou
--   fe026b5f-50cc-494b-8e3a-ff6f12e8fd15  2026-09-24T17:24:03.868Z  NH-01  won   Stefany Shaheen
--   b31eca69-173a-438b-9eda-20a93d8450dc  2026-09-24T17:24:03.868Z  RI-01  won   Gabe Amo
--   db8645df-c7f0-4624-aac5-3b915fcb6666  2026-09-24T17:24:03.868Z  RI-01  lost  Kellie Keenan
--   8b1ee110-3dc6-4582-a403-3fe8ece8c84b  2026-09-24T17:24:03.868Z  RI-01  lost  Pedro DeSouza
--   e55dc1ed-14d9-4092-8489-8928ba8690c5  2026-09-24T17:24:03.868Z  RI-02  won   Seth Magaziner
--   c967eb2f-8eab-46a7-9a83-2b41353ac073  2026-09-24T17:24:03.868Z  RI-02  lost  Victor Mellor
--   481c27a8-a4ae-4fbf-b2be-a2fa852b1b4e  2026-09-24T17:35:22.369Z  TN-08  lost  Adam D. Austill
--   35c82757-aa5d-4569-bf95-8d5851908441  2026-09-24T17:35:22.369Z  TN-02  lost  Adam Heimerman
--   ec036e2c-6177-4c0b-bea7-81928ad6f0fa  2026-09-24T17:35:22.369Z  TN-06  lost  Angus Purdy
--   5aa7b24f-4daa-49de-8e65-19b7c8c62146  2026-09-24T17:35:22.369Z  TN-03  lost  Anna Golladay
--   b78eb028-3640-4457-9eb7-2d7e9e3b8dfb  2026-09-24T17:35:22.369Z  TN-08  lost  Antonio Futch
--   18d25f65-6cbd-49f2-ad2d-56174c3b7edf  2026-09-24T17:35:22.369Z  TN-01  lost  Billy Cody
--   2fadef14-c670-49e1-bd3e-acf3b12d4337  2026-09-24T17:35:22.369Z  TN-02  lost  Bruce Fine
--   162e9ada-b7c4-4dcb-9cf4-910cb07f1b2d  2026-09-24T17:35:22.369Z  TN-03  won   Charles J. "Chuck" Fleischmann
--   35c057a4-6a79-4d70-9fee-e8258545d571  2026-09-24T17:35:22.369Z  TN-05  won   Charlie Hatcher
--   1d4ce0c5-46c7-4ba8-9a71-bdb85218a73c  2026-09-24T17:35:22.369Z  TN-05  lost  Chaz Molder
--   d25564f8-02fa-40e9-b1db-72929b74f83b  2026-09-24T17:35:22.369Z  TN-01  lost  Chris Campbell
--   63e832df-348e-4891-97d5-faf4ede64ab0  2026-09-24T17:35:22.369Z  TN-06  lost  Christopher B. Monday
--   83b52118-1e9c-4ab8-9a29-27d524ecd4be  2026-09-24T17:35:22.369Z  TN-08  won   David Kustoff
--   4fea44fe-0926-496d-b2a3-51ec790cbf34  2026-09-24T17:35:22.369Z  TN-03  lost  Dean Arnold
--   3e46ae9a-9006-468a-baa0-65ef60af69e5  2026-09-24T17:35:22.369Z  TN-01  won   Diana Harshbarger
--   3c3ad441-d5f0-4c93-89dc-42d6f061c7d5  2026-09-24T17:35:22.369Z  TN-03  lost  Donnie Lynn Ownby
--   2ca11ef3-77d0-4ad6-9786-2d7856f27128  2026-09-24T17:35:22.369Z  TN-03  lost  Edward John Roland
--   dc76b277-d52c-43b0-beb3-daa28c77bfed  2026-09-24T17:35:22.369Z  TN-08  lost  Heidi Kuhn
--   b8902bee-0772-494e-9756-e4aefcbbe88f  2026-09-24T17:35:22.369Z  TN-08  lost  Henry J. Ward, III
--   00199c31-a692-45b2-a813-4147f0b261c1  2026-09-24T17:35:22.369Z  TN-08  lost  Horace Taylor
--   663331f9-61ad-4724-bc91-50c4a6f71b26  2026-09-24T17:35:22.369Z  TN-05  lost  James A. Johnson
--   ab409cc5-9b97-42ae-a0d8-a8163902c5aa  2026-09-24T17:35:22.369Z  TN-03  lost  Jean Howard-Hill
--   6af52e4e-7382-4dbc-9535-c81c2bd1935f  2026-09-24T17:35:22.369Z  TN-06  won   Johnny Garrett
--   84df68db-257b-43fa-986d-5201dd742c91  2026-09-24T17:35:22.369Z  TN-01  lost  Joshua Ray Ashburn
--   5cad0953-0195-4624-825d-58f7e1b97b6b  2026-09-24T17:35:22.369Z  TN-01  lost  Kristi Burke
--   f9dc065c-a7df-4b31-906a-50923ed3ec12  2026-09-24T17:35:22.369Z  TN-02  lost  Michaela Barnett
--   ab8a44dd-446f-48ff-b7f6-7188ea60a520  2026-09-24T17:35:22.369Z  TN-05  lost  Micheál (Me-Haul) O'Leary
--   02227cb0-daa8-455a-8316-7bfbbcef7ac7  2026-09-24T17:35:22.369Z  TN-06  lost  Mike Croley
--   ac0c2d23-a659-4e55-9b53-c4eb2fd85a4c  2026-09-24T17:35:22.369Z  TN-08  lost  Pamela Jeanine "P." Moses
--   6922fcca-65d6-47aa-9ab4-879d3001fbd8  2026-09-24T17:35:22.369Z  TN-01  lost  Richard G. Baker
--   ba622b03-21d9-4b09-b6c3-3a49b063e464  2026-09-24T17:35:22.369Z  TN-03  lost  Rodney Joe King
--   b1351245-db4f-4fbc-bd5c-c911f5448204  2026-09-24T17:35:22.369Z  TN-02  won   Tim Burchett
--   340ac7d9-75b8-4ce2-8bd1-dc03ff652f84  2026-09-24T17:35:22.369Z  TN-01  lost  Tyler Brice Mitchell McClain
--   7fa0ac82-f72d-4dbd-87c3-18a1d1dd0ea1  2026-09-24T17:35:22.369Z  TN-08  lost  Wendell "Wells" Blankenship
--   c0e627ff-596e-4b6e-83a7-67fce59bb585  2026-09-24T18:35:28.885Z  VA-07  lost  Alaha Ahrar
--   7a859705-1f47-44ce-81f3-913c0d841bdc  2026-09-24T18:35:28.885Z  VA-07  lost  Doug Ollivant
--   434a0c71-40a7-471d-9b76-29b8b63be9c1  2026-09-24T18:35:28.885Z  VA-07  won   Eugene Vindman
--   750255ac-fcfc-46fa-b738-014a2bd48b4a  2026-09-24T18:35:28.885Z  VA-04  won   Jennifer McClellan
--   6dc39d51-1e99-4ea3-b27c-1963ed04b5bc  2026-09-24T18:35:28.885Z  VA-04  lost  Joan E. "Andrews" Bell
--   c640eea4-14a2-4325-a4ba-8847ad1303a7  2026-09-24T18:35:28.885Z  VA-07  lost  Joshua E. Ertle
--   44005981-fcc5-49f9-8a5c-dfd94cdb68d2  2026-09-24T18:35:28.885Z  VA-07  lost  Randall Terry
--   72a7a87d-61a0-4036-a10c-3aefc0fb2187  2026-09-24T18:35:28.885Z  VA-04  lost  Robert P. "Family Man" Murray, Jr.
--   760e45aa-eaa2-4237-b8b8-d8a488e9746f  2026-09-24T18:35:28.885Z  VA-07  lost  Taner E. Demirci Lopez
--   c222836d-9e05-44aa-9f0f-cbae96567338  2026-09-24T18:35:28.885Z  VT-00  lost  Adam Ortiz
--   bff347a9-31f1-4b82-ae19-676b26f9c202  2026-09-24T17:18:36.034Z  VT-00  won   Becca Balint
--   c35f4624-c61d-432a-bc3f-ef3488355cc4  2026-09-24T17:18:36.034Z  VT-00  lost  Gerald Malloy
--   db685792-762f-40e3-bde3-cbb02fac4a10  2026-09-24T18:35:28.885Z  VT-00  lost  Phoenix K. Altair
--   17e23ab1-502f-40ce-9649-aa619c3c1eac  2026-09-24T18:35:28.885Z  VT-00  lost  Ryan P. Walton
--   31a03324-4d55-4418-8a7e-f355638e64fa  2026-09-24T18:35:28.885Z  VT-00  lost  Suzanne "Suz" Seymour
--   2fbe85c6-7141-4b71-9895-58b0d526c960  2026-08-20T08:16:20.424Z  WA-09  won   Adam Smith
--   386a2238-8798-416f-945d-0eb5e65a36fe  2026-08-20T08:16:20.424Z  WA-10  lost  Chris D. Chung
--   2318e911-5dcb-4da7-89e2-fd2051eaee4c  2026-08-20T08:16:20.424Z  WA-09  lost  Doug Basler
--   b3cfa12f-0e81-4c70-9cbc-4fd6cd4bc879  2026-08-20T08:16:20.424Z  WA-02  lost  Edwin H. Feller
--   7ed48f80-e979-4d99-9d10-0fe2e413711a  2026-08-20T08:16:20.424Z  WA-06  won   Emily Randall
--   b521b46c-b8d0-4996-9b0b-ab9de13ece0b  2026-08-20T08:16:20.424Z  WA-03  lost  John Braun
--   60c63f81-bf03-4768-9b81-52a4a8573912  2026-08-20T08:16:20.424Z  WA-08  won   Kim Schrier
--   2fec4c81-5441-4e9f-bd31-14da4701b84c  2026-08-20T08:16:20.424Z  WA-03  won   Marie Gluesenkamp Perez
--   78c5291a-57c0-464d-9ae3-b0181573fd13  2026-08-20T08:16:20.424Z  WA-10  won   Marilyn Strickland
--   fb0c6876-1a16-47a1-bc62-26b59f8c3460  2026-08-20T08:16:20.424Z  WA-01  lost  Mary Silva
--   5ffd8e8b-1e2d-4a58-8108-02952ee65b02  2026-08-20T08:16:20.424Z  WA-07  lost  Nirav Sheth
--   b66735ff-c35b-4a60-947a-7a72e0edd634  2026-08-20T08:16:20.424Z  WA-07  won   Pramila Jayapal
--   e64bdc03-cdaf-4cbf-a5b9-f8173c35755e  2026-08-20T08:16:20.424Z  WA-02  won   Rick Larsen
--   035f2f79-a977-4837-9806-4bd40a260366  2026-08-20T08:16:20.424Z  WA-08  lost  Spencer Meline
--   c4694185-0fc6-461e-a00e-a3328219efd8  2026-08-20T08:16:20.424Z  WA-01  won   Suzan K. DelBene
--   585310bc-693c-4933-ac36-d5d5707e9f19  2026-08-20T08:16:20.424Z  WA-06  lost  Teresa Fox
--   d9b39dde-beb8-482f-bafc-2ca273fdc138  2026-09-24T18:13:54.787Z  WI-03  lost  Alexander Valiensi Kent
--   3e6670b2-ce9f-4616-a7cb-816f8446132c  2026-09-24T18:13:54.787Z  WI-05  lost  Andrew Beck
--   f0a27834-efd5-4d7e-849b-2c35ee9a5d8a  2026-09-24T18:13:54.787Z  WI-04  lost  Arthur Burks
--   46b7ffd3-3d76-49dc-b766-6afaccfb0317  2026-09-24T18:13:54.787Z  WI-06  lost  Brad Smith
--   1f476e69-e267-4376-9c78-42cc6577b530  2026-09-24T18:13:54.787Z  WI-01  lost  Bryan Steil
--   8adecdec-233c-41bf-b19e-447626f4e651  2026-09-24T18:13:54.787Z  WI-03  lost  Derrick Van Orden
--   333fdb75-fe1f-41ca-8a1e-7d5b5917fc23  2026-09-24T18:13:54.787Z  WI-06  lost  Elizabeth Fitzgibbon
--   c6e8d256-35d9-4774-91f6-1952cad92f45  2026-09-24T18:13:54.787Z  WI-07  lost  Fred Clark
--   c6a84313-fc8c-417c-818a-01ade3cdbf61  2026-09-24T18:13:54.787Z  WI-06  won   Glenn Grothman
--   763c2c90-5aa5-4b35-9a16-97e05b4d8ea5  2026-09-24T18:13:54.787Z  WI-04  won   Gwen Moore
--   c20bda0e-18ef-44d9-b986-599f26fd8953  2026-09-24T18:13:54.787Z  WI-02  won   Mark Pocan
--   a9340175-3785-43b3-99f9-6957876e7e5b  2026-09-24T18:13:54.787Z  WI-06  lost  Matthew Arndt
--   02f64fe0-6d68-4c8b-b42b-3c801453277a  2026-09-24T18:13:54.787Z  WI-07  won   Michael Alfonso
--   8439119b-d200-404e-863c-c1a74672f93f  2026-09-24T18:13:54.787Z  WI-06  lost  Michael Thurow
--   1a985897-72d5-462b-a1af-b53ea59efa85  2026-09-24T18:13:54.787Z  WI-01  won   Mitchell Berman
--   d4a86cbd-82df-4533-8246-d3af8de3675c  2026-09-24T18:13:54.787Z  WI-03  won   Rebecca Cooke
--   7756b935-7af2-4dce-ad1c-b3e285d40e8f  2026-09-24T18:13:54.787Z  WI-08  lost  Rick Crosson
--   c6ea4a97-f8ce-4cff-8101-1258458debaa  2026-09-24T18:13:54.787Z  WI-03  lost  Rustin Provance
--   adcc8b1e-d8f9-4ff6-b3c7-c2982ec880be  2026-09-24T18:13:54.787Z  WI-05  won   Scott Fitzgerald
--   e2160dc9-2e88-4ad3-9c1c-422a9c7ecaa6  2026-09-24T18:13:54.787Z  WI-04  lost  Tim Rogers
--   ace7d969-5a0b-40e6-84e5-b54f401623b9  2026-09-24T18:13:54.787Z  WI-08  won   Tony Wied
--   ef7cb9bc-d200-4b74-b848-2f24ea3e9114  2026-09-24T17:18:38.012Z  WY-00  won   Chuck Gray
--   ce867509-173c-49a6-bbe4-75f0cc857d5b  2026-09-24T18:35:28.885Z  WY-00  lost  Jeffrey A. Haggit
--   f42cf295-5d86-40d7-9622-a4b7c937a9b3  2026-09-24T17:18:38.012Z  WY-00  lost  Lisa Kinney
--   e13d3830-ffdc-4257-96b3-387a16f8b660  2026-09-24T18:35:28.885Z  WY-00  lost  Shawn Johnson
--
-- ============================================================================================
-- WHAT THIS FILE DOES NOT TOUCH
-- ============================================================================================
-- ⚠ 294 federal rows carry a result that is NOT AP-sourced - 253 `not_nominated`, 39
-- `advanced`, 2 `withdrew` - and every one already has a `result_recorded_at` that is true about
-- its own write. None is touched, and a gate asserts all 294 are unchanged.
--   ⚠ ONE OF THE 294 WAS WRITTEN BY THIS PROGRAMME AND STILL DOES NOT BELONG HERE: Chuck
--   Edwards' NC-11 row, marked `withdrawn`/`withdrew` by `CC_0352`. His citation reasons FROM
--   AP's candidate list without quoting the feed URL, so the AP predicate does not match him -
--   and it should not: `CC_0352` stamped him with `now()` at apply, so his timestamp is already
--   measured. ▶ The first draft of this file said 293 here, counting him as programme-written;
--   the over-reach gate failed the dry run at "294 of the 293", which is the gate doing its job.
-- ⚠ The six rows `CC_0352` and `CC_0353` stamped are excluded by id, and a gate re-asserts their
-- exact values afterwards.
-- ⚠ `result`, `result_certainty` and `result_source` are not read from or written to by this
-- file at all, beyond using `result_source` to identify AP-sourced rows. No citation moves.
-- ⚠ The column comment should say that 1,009 of its values are derived. `ev_api` cannot
-- `COMMENT ON` a table it does not own ("must be owner of relation race_candidates"), so that
-- one statement is applied separately through the privileged connection and is recorded in
-- `backend/data/federal-2026-recorded-at-backfill/NOTES.md`.

BEGIN;

-- ─── 0. Snapshot EVERY federal 2026-11-03 candidate row before anything is written ───────────
-- 🔴 The over-reach gate depends on this being taken first and covering every row in scope,
-- not only the rows this file means to change.
CREATE TEMP TABLE before_backfill ON COMMIT DROP AS
SELECT rc.id,
       rc.result_recorded_at AS before_val,
       rc.result,
       d.district_type,
       (rc.result_source LIKE '%interactives.apelections.org%') AS ap_sourced
  FROM essentials.race_candidates rc
  JOIN essentials.races r      ON r.id = rc.race_id
  JOIN essentials.elections e  ON e.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER');

-- ─── 1. The three derived write times ────────────────────────────────────────────────────────
CREATE TEMP TABLE write_times (migration text, rows_expected int, commit_sha text, ts timestamptz)
  ON COMMIT DROP;
INSERT INTO write_times VALUES
  ('CC_0339',  33, '3d4088708', TIMESTAMPTZ '2026-11-05 00:02:22+00'),
  ('CC_0350', 377, 'f7702c4fc', TIMESTAMPTZ '2026-11-05 00:41:54+00'),
  ('CC_0351', 599, '21c54a4e9', TIMESTAMPTZ '2026-11-05 01:12:43+00');

-- ─── 2. Attribute every row, excluding the six already stamped ───────────────────────────────
CREATE TEMP TABLE targets ON COMMIT DROP AS
SELECT rc.id,
       CASE WHEN d.district_type = 'NATIONAL_UPPER' AND rc.result = 'won'  THEN 'CC_0339'
            WHEN d.district_type = 'NATIONAL_LOWER' AND rc.result = 'won'  THEN 'CC_0350'
            WHEN rc.result = 'lost'                                        THEN 'CC_0351'
       END AS migration,
       rc.result_recorded_at AS before_val
  FROM essentials.race_candidates rc
  JOIN essentials.races r      ON r.id = rc.race_id
  JOIN essentials.elections e  ON e.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
   AND rc.result_source LIKE '%interactives.apelections.org%'
   AND rc.id NOT IN (
     '37b52c12-cc98-41c0-9e81-ebc9e5f124f9'::uuid,  -- Trever Nehls   TX-22  CC_0352
     '11b0eab7-a294-4dd8-98ab-3888a6dcdce7'::uuid,  -- Lauren Jewett  LA-01  CC_0352
     '3bc3cfc4-b306-4d83-85c2-72d8338069cf'::uuid,  -- Jennifer Balkcom NC-11 CC_0352
     '205d4158-1302-437f-997b-46f8ce956a4a'::uuid,  -- Arthur Purves  VA-11  CC_0352
     '4db413a4-b041-4c57-887d-b6cbf295e8e9'::uuid,  -- E. Liddy Glass LA-01  CC_0353
     '73304b5e-0e97-4ef2-8c8a-7d5b6887b9ca'::uuid); -- Dianne Blais   VA-11  CC_0353

-- ─── 3. Gate the attribution BEFORE writing anything ─────────────────────────────────────────
-- 🔴 An UPDATE driven by a CASE must prove the CASE covered everything it matched. An
-- unattributed row would otherwise be written to NULL and look like one this file never saw.
DO $$
DECLARE v_total bigint; v_null bigint; v_bad text; v_missing bigint; v_stale bigint;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE migration IS NULL) INTO v_total, v_null FROM targets;
  IF v_null <> 0 THEN
    RAISE EXCEPTION 'CC_0354: % AP-sourced row(s) match no migration; the attribution CASE is incomplete', v_null;
  END IF;
  IF v_total <> 1009 THEN
    RAISE EXCEPTION 'CC_0354: % rows attributed, expected 1009', v_total;
  END IF;

  SELECT string_agg(x.migration || '=' || x.n || ' (expected ' || w.rows_expected || ')', ', ' ORDER BY x.migration)
    INTO v_bad
    FROM (SELECT migration, count(*) n FROM targets GROUP BY 1) x
    JOIN write_times w ON w.migration = x.migration
   WHERE x.n <> w.rows_expected;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0354: the per-migration split is wrong: %', v_bad;
  END IF;

  -- 🔴 THE TWO DEFECTS ARE COUNTED BEFORE THEY ARE FIXED, because the header states both numbers
  -- and the 155 old values are written down against this count.
  SELECT count(*) FILTER (WHERE before_val IS NULL),
         count(*) FILTER (WHERE before_val IS NOT NULL)
    INTO v_missing, v_stale FROM targets;
  IF v_missing <> 854 THEN RAISE EXCEPTION 'CC_0354: % rows are missing a timestamp, expected 854', v_missing; END IF;
  IF v_stale <> 155 THEN RAISE EXCEPTION 'CC_0354: % rows carry a stale timestamp, expected 155', v_stale; END IF;
END $$;

-- ─── 4. The backfill ─────────────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET result_recorded_at = w.ts
  FROM targets t
  JOIN write_times w ON w.migration = t.migration
 WHERE rc.id = t.id
   AND rc.result_recorded_at IS DISTINCT FROM w.ts;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_null bigint; v_changed bigint; v_unexpected bigint; v_untouched bigint;
  v_pins bigint; v_order bigint; v_before_election bigint; v_split text;
  v_cc0352 timestamptz; v_cc0353 timestamptz; v_max_derived timestamptz;
BEGIN
  -- 🟢 THE DEBT IS PAID: no AP-sourced federal row is left without a recorded time.
  SELECT count(*) INTO v_null
    FROM essentials.race_candidates rc
    JOIN essentials.races r      ON r.id = rc.race_id
    JOIN essentials.elections e  ON e.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     AND rc.result_source LIKE '%interactives.apelections.org%'
     AND rc.result_recorded_at IS NULL;
  IF v_null <> 0 THEN
    RAISE EXCEPTION 'CC_0354: % AP-sourced federal row(s) still carry no result_recorded_at', v_null;
  END IF;

  -- 🔴 EXACTLY 1,009 ROWS CHANGED, AND EVERY ONE OF THEM WAS A TARGET. This is the over-reach
  -- gate: it compares against the snapshot taken before anything was written, across EVERY
  -- federal row in scope, not only the ones this file meant to touch.
  SELECT count(*) INTO v_changed
    FROM before_backfill b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result_recorded_at IS DISTINCT FROM b.before_val;
  IF v_changed <> 1009 THEN
    RAISE EXCEPTION 'CC_0354: % federal row(s) changed, expected exactly 1009', v_changed;
  END IF;

  SELECT count(*) INTO v_unexpected
    FROM before_backfill b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result_recorded_at IS DISTINCT FROM b.before_val
     AND NOT EXISTS (SELECT 1 FROM targets t WHERE t.id = b.id);
  IF v_unexpected <> 0 THEN
    RAISE EXCEPTION 'CC_0354: % changed row(s) were not in the attributed set', v_unexpected;
  END IF;

  -- 🔴 THE 294 NON-AP-SOURCED RESULT ROWS KEEP THEIR OWN TIMESTAMPS.
  SELECT count(*) INTO v_untouched
    FROM before_backfill b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE b.ap_sourced = false AND b.result IS NOT NULL
     AND rc.result_recorded_at IS NOT DISTINCT FROM b.before_val;
  IF v_untouched <> 294 THEN
    RAISE EXCEPTION 'CC_0354: % of the 294 non-AP-sourced result rows are unchanged, expected 294', v_untouched;
  END IF;

  -- 🔴 THE SIX ROWS CC_0352 AND CC_0353 MEASURED KEEP THEIR MEASURED VALUES.
  SELECT count(*) INTO v_pins FROM essentials.race_candidates
   WHERE id IN ('37b52c12-cc98-41c0-9e81-ebc9e5f124f9'::uuid,
                '11b0eab7-a294-4dd8-98ab-3888a6dcdce7'::uuid,
                '3bc3cfc4-b306-4d83-85c2-72d8338069cf'::uuid,
                '205d4158-1302-437f-997b-46f8ce956a4a'::uuid)
     AND result_recorded_at = TIMESTAMPTZ '2026-11-05 01:59:21.737696+00';
  IF v_pins <> 4 THEN
    RAISE EXCEPTION 'CC_0354: % of the 4 CC_0352 rows keep their measured timestamp, expected 4', v_pins;
  END IF;

  SELECT count(*) INTO v_pins FROM essentials.race_candidates
   WHERE id IN ('4db413a4-b041-4c57-887d-b6cbf295e8e9'::uuid,
                '73304b5e-0e97-4ef2-8c8a-7d5b6887b9ca'::uuid)
     AND result_recorded_at = TIMESTAMPTZ '2026-11-05 05:07:55.375038+00';
  IF v_pins <> 2 THEN
    RAISE EXCEPTION 'CC_0354: % of the 2 CC_0353 rows keep their measured timestamp, expected 2', v_pins;
  END IF;

  -- 🔴 THE DERIVED TIMESTAMPS MUST SIT IN THE ORDER THE PASSES RAN, AND BEFORE THE MEASURED
  -- ONES. A mistyped timestamp is the fault this catches, and nothing else here would see it.
  SELECT count(*) INTO v_order FROM write_times a JOIN write_times b ON a.migration < b.migration
   WHERE a.ts >= b.ts;
  IF v_order <> 0 THEN
    RAISE EXCEPTION 'CC_0354: the three derived timestamps are not in migration order';
  END IF;

  SELECT max(ts) INTO v_max_derived FROM write_times;
  SELECT result_recorded_at INTO v_cc0352 FROM essentials.race_candidates
   WHERE id = '37b52c12-cc98-41c0-9e81-ebc9e5f124f9'::uuid;
  SELECT result_recorded_at INTO v_cc0353 FROM essentials.race_candidates
   WHERE id = '4db413a4-b041-4c57-887d-b6cbf295e8e9'::uuid;
  IF v_max_derived >= v_cc0352 OR v_cc0352 >= v_cc0353 THEN
    RAISE EXCEPTION 'CC_0354: derived % does not fall before the measured % and %', v_max_derived, v_cc0352, v_cc0353;
  END IF;

  -- 🔴 AND NOTHING MAY CLAIM A RESULT WAS RECORDED BEFORE THE ELECTION WAS HELD.
  SELECT count(*) INTO v_before_election
    FROM essentials.race_candidates rc
    JOIN essentials.races r      ON r.id = rc.race_id
    JOIN essentials.elections e  ON e.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     AND rc.result_source LIKE '%interactives.apelections.org%'
     AND rc.result_recorded_at < TIMESTAMPTZ '2026-11-03 00:00:00+00';
  IF v_before_election <> 0 THEN
    RAISE EXCEPTION 'CC_0354: % AP-called row(s) claim to have been recorded before election day', v_before_election;
  END IF;

  SELECT string_agg(m || '=' || n, ' ' ORDER BY m) INTO v_split FROM (
    SELECT w.migration m, count(*) n
      FROM essentials.race_candidates rc JOIN write_times w ON w.ts = rc.result_recorded_at
     GROUP BY 1) x;
  RAISE NOTICE 'CC_0354 OK: 1009 rows backfilled (854 were NULL, 155 were stale) - %', v_split;
END $$;

COMMIT;
