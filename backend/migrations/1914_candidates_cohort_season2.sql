-- 1914_candidates_cohort_season2.sql
--
-- THE CANDIDATES COHORT: 100 rows / 51 people whose stance cited only a generic page.
-- 49 citation repairs, 15 re-seats, 36 blanks. Every row was read against the SEASON 2
-- ladder text, not carried forward on its number.
--
-- WHO THESE PEOPLE ARE. They are the generic-sourcing rows belonging to politicians with no
-- office record. 141 of the 160 such people are candidates in the 2026-11-03 election, so this
-- is the most voter-facing slice of the national audit rather than the least. A Season 1 answer
-- IS served to voters wherever no Season 2 answer exists -- compassService takes the newest
-- PUBLISHED season per topic -- which is why 93 of these rows are written forward into Season 2
-- here rather than left alone. The other 7 already had a Season 2 row and are updated in place.
--
-- WHAT THIS MIGRATION DOES NOT CLAIM
--   * It does not touch Season 1. Season 1 is closed; every write here is into Season 2, and
--     the post-check proves the Season 1 values are unchanged.
--   * A blank is value 0 plus an INTERNAL record naming WHICH KIND of nothing (ruling Q2, #919).
--     It is not a deletion, and it is not a claim that the person holds no view.
--   * Where a chair MOVED, the reasoning says so, names the old rung, and gives the reason.
--   * Where a rung is the nearest fit on a single-choice ladder rather than an exact match,
--     the row says that as well.
--
-- THE INSERTED-RUNG PROBE, re-run against production immediately before writing
--   housing            1->1, 2->3, 3->4, 4->5, 5->5   (a rung was INSERTED at position 2)
--   same-sex-marriage  1->2, 2->3, 3->GONE, 4->4, 5->5
--   every other topic in this cohort maps same-number, so a value change is a real chair move.
--   All 5 housing rows and both same-sex-marriage rows are ALREADY in Season 2, so no carry
--   question arises on either rewritten ladder. The probe was still required to know that.
--
-- WHY THERE ARE 36 BLANKS. The governing test was: does the evidence distinguish the seated
-- rung from its NEIGHBOURS? Rungs share a direction and differ by magnitude or mechanism, so
-- evidence that fixes only the direction picks a BAND, not a rung. The recurring shapes:
--   * band not rung -- "end gerrymandering", "affordable childcare", "bodily autonomy";
--   * a Season 2 ladder asking a different question than the evidence answers -- voting-rights
--     is an IDENTIFICATION ladder and lost 4 of 4; homelessness is an ENFORCEMENT ladder;
--     fossil-fuels is a PERMITS ladder;
--   * an affiliation standing in for a position -- caucus or committee membership, a
--     presidential-alignment score, an endorsement, a chairmanship, CAMPAIGN DONORS, and in one
--     case the candidate's own sexual orientation;
--   * a citation that does not carry the claim -- a 404 naming the wrong contest, a transposed
--     bill number on a page that never mentions the programme;
--   * the row quoting the LADDER'S OWN RUNG back as its evidence (one case, tariffs).
--
-- TWO FINDINGS FOR THE SEASON 3 REVIEW, recorded here because they are not row defects
--   * voting-rights lost 4 of 4. Its axis is identification, which almost no candidate
--     addresses; the evidence that exists is about registration, the VRA and mail voting.
--   * the housing ladder has NO rung for exclusionary localism. Tony Strickland stopped
--     accepting ADU applications and the Attorney General sued his city under the HOME Act;
--     rung 5 describes CUTTING regulation so the market can build. No seat exists for what he
--     actually did, so his row is blanked rather than forced onto rung 5.
--
-- Per-row reading ledger, with the evidence and the reason for every disposition:
--   C:/ev-stance-work/cands/LEDGER.md

DO $pre$
DECLARE n int;
BEGIN
  -- (a) all 100 pairs still sit where they were read, in the season they were read.
  WITH want(pid, tid, season, oldval) AS (VALUES
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 2.0::numeric),
    ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 5.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 4.0::numeric),
    ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 5.0::numeric),
    ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 4.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric),
    ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 5.0::numeric),
    ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 5.0::numeric),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 3.0::numeric),
    ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 2.0::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 3.0::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid, 1.0::numeric)
  )
  SELECT count(*) INTO n FROM want w
    JOIN inform.politician_answers a ON a.politician_id = w.pid AND a.topic_id = w.tid
     AND a.season_id = w.season AND a.value = w.oldval;
  IF n <> 100 THEN
    RAISE EXCEPTION 'migration 1914: % of 100 rows still sit where they were read', n;
  END IF;

  -- (b) the rows read in Season 1 must have NO Season 2 answer, or this migration would be
  --     overwriting a chair nobody read.
  WITH want(pid, tid) AS (VALUES
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid),
    ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid)
  )
  SELECT count(*) INTO n FROM want w
    JOIN inform.politician_answers a ON a.politician_id = w.pid AND a.topic_id = w.tid
     AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1914: % Season-1-read rows already hold a Season 2 answer', n;
  END IF;

  -- (c) the Season 2 rungs this file seats against still read as it assumes.
  WITH want(tkey, val, frag) AS (VALUES
    ('voting-rights',     5, '%documentary proof of citizenship%'),
    ('medicare/aid',      2, '%expand Medicare or Medicaid eligibility%'),
    ('climate-change',    3, '%cutting permitting red tape%'),
    ('housing',           3, '%Build no public housing%'),
    ('housing',           5, '%cut the regulations and zoning limits%'),
    ('ai-regulation',     3, '%legally responsible when their systems cause harm%'),
    ('tariffs',           4, '%trade fairly with America%'),
    ('school-vouchers',   2, '%blocking their expansion%'),
    ('redistricting',     1, '%no elected officials involved at any level%'),
    ('healthcare',        1, '%paid for and run by the public sector%')
  )
  SELECT count(*) INTO n FROM want w
    JOIN inform.compass_topics t ON t.topic_key = w.tkey
    JOIN inform.season_questions sq ON sq.topic_id = t.id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = sq.topic_revision_id
     AND r.value = w.val AND lower(r.text) LIKE lower(w.frag);
  IF n <> 10 THEN
    RAISE EXCEPTION 'migration 1914: % of 10 Season 2 rungs still read as this file assumes', n;
  END IF;
END $pre$;


INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT v.pid, v.tid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,
       (SELECT sq.topic_revision_id FROM inform.season_questions sq
         WHERE sq.topic_id = v.tid AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'),
       v.reasoning, v.sources
  FROM (VALUES
    -- Aisha Farooqi | abortion | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'Her platform commits to defending Michigan’s Reproductive Freedom for All amendment, adopted in 2022, which protects abortion to fetal viability with post-viability exceptions for the patient’s life and health, and to protecting access to contraception and IVF. A viability framework is rung 2; she claims nothing about public funding at all stages.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | climate-change | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'Her platform supports "a bold, national plan to tackle climate change", "investing in clean energy, expanding electric vehicle production, and modernizing our infrastructure and power grid", and restoring the Environmental Protection Agency. The instrument is public investment, which is this rung.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | healthcare | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'Her platform states she "supports Medicare for All: a universal, single-payer system that guarantees healthcare for every American, no exceptions" — rung 1 exactly.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | medicare/aid | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'Her support for Medicare for All, "a universal, single-payer system", is by definition extending Medicare to everyone regardless of age, which is what this rung asks.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | redistricting | reseat
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'Moved from rung 2 to rung 1. She names Michigan’s commission as her model — "independent redistricting commissions – like the kind in Michigan". Michigan’s Independent Citizens Redistricting Commission bars elected officials and partisan officeholders from serving, which is rung 1’s distinguishing clause; rung 2 asks only for equal representation of the two major parties.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | religious-freedom | reseat
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 'Moved from rung 2 to rung 3. Her platform states that "protecting civil liberties includes defending the rights of LGBTQIA Americans and safeguarding religious freedom for all" and that "no one should face discrimination because of who they are, who they love, or how they choose to worship". That states a balance between the two. Rung 2 asserts a priority — that religious freedom must not override anti-discrimination protections in employment and housing — which she never claims.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | school-vouchers | blank
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'INTERNAL RECORD — blanked for absence of evidence. Her education section covers zero-interest student loans, student-debt cancellation and "fair, fully-funded public schools". Funding public schools is not rung 1’s eliminating of voucher programs, and the page states no voucher position either way.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | taxes | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'Her platform says "it’s time for billionaires to be taxed at the same rate as ordinary Americans" while protecting Medicare and Social Security — a Buffett-rule measure that raises effective rates on the very wealthy to sustain existing programmes, which is rung 2 rather than rung 1’s significant raise to fund more public services.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Aisha Farooqi | voting-rights | blank
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 'INTERNAL RECORD — blanked because the Season 2 ladder changed axis. This question now asks only what identification a voter must present, from none to documentary proof of citizenship. Her evidence is restoring the Voting Rights Act through the John R. Lewis Act and setting national standards for vote-by-mail, early voting and registration access. None of that is an identification position. Same disposition as Saddam Salim in migration 1913.', ARRAY['https://www.ballotready.org/people/aisha-farooqi']::text[]),
    -- Amir Hassan | tariffs | blank
    ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 'INTERNAL RECORD — blanked, and the previous row should be read as a warning. Its quoted evidence, "increase tariffs on countries that don’t trade fairly with America", is the text of rung 4 itself, quoted back as though he had said it. The word tariff does not appear on his cited page. What the page says is that he "supports President Trump and his agenda to rebalance our trade deals", which names no tariff policy; rung 3’s selective tariffs are not claimed either.', ARRAY['https://www.ballotready.org/people/amir-hassan']::text[]),
    -- Andrej Selivra | economic-development | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 'INTERNAL RECORD — blanked because the source is gone, not because the claim is false. The row cited ballotpedia.org/Los_Angeles_City_Council_elections,_2026, which returns 404 and names the wrong contest: he was a candidate for Mayor of Los Angeles on 2026-06-02, not for City Council. His transit-oriented Economic Opportunity Zones plank is corroborated by independent coverage, but his campaign site andrej4la.com has expired, his GoodParty profile is unclaimed and empty, theballotbrief.com returns 410, and he has no Ballotpedia page. Re-research against the LA City Clerk June-2026 candidate filing.', ARRAY['https://goodparty.org/candidate/andrej-selivra/los-angeles-city-mayor']::text[]),
    -- Andrej Selivra | growth-and-development | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 'INTERNAL RECORD — same disposition as his economic-development row. The upzoning and transit-oriented development plank is real but no fetchable source now carries it, and the cited page is a 404 for the wrong contest.', ARRAY['https://goodparty.org/candidate/andrej-selivra/los-angeles-city-mayor']::text[]),
    -- Andrej Selivra | homelessness | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 'INTERNAL RECORD — same disposition. His signature City-operated Public Dormitories proposal is corroborated by independent coverage of the 2026 mayoral race, but the cited page is a 404 for the wrong contest and no fetchable source now carries the platform text.', ARRAY['https://goodparty.org/candidate/andrej-selivra/los-angeles-city-mayor']::text[]),
    -- Andrej Selivra | local-immigration | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 'INTERNAL RECORD — blanked for absence of evidence, which the row already stated. Its own reasoning read "no detailed local immigration enforcement positions were publicly available at time of research", and it nonetheless carried rung 1. A row that reports finding nothing must not hold a value.', ARRAY['https://goodparty.org/candidate/andrej-selivra/los-angeles-city-mayor']::text[]),
    -- Andrej Selivra | public-safety-approach | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 'INTERNAL RECORD — blanked for absence of evidence, which the row already stated: "no comprehensive public safety platform was detailed in campaign materials at time of research". It nonetheless carried rung 3.', ARRAY['https://goodparty.org/candidate/andrej-selivra/los-angeles-city-mayor']::text[]),
    -- Andrej Selivra | residential-zoning | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 'INTERNAL RECORD — same disposition as his other rows. The upzoning plank is real but unreachable, and the cited page is a 404 naming the wrong contest.', ARRAY['https://goodparty.org/candidate/andrej-selivra/los-angeles-city-mayor']::text[]),
    -- Andy Barr | ukraine-support | reseat
    ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 'Moved from rung 3 to rung 2. The previous reasoning held that his "specific Ukraine voting record is not prominently documented". It is: on the passage of H.R. 8035, the Ukraine Security Supplemental Appropriations Act, 2024, roll call 118-2024/h151, the Clerk records KY-6 Representative Andy Barr voting Yea. Voting for the supplemental is continuing military and economic aid. The vote is also distinctive rather than consensual — his conference split roughly in half, and he was among the Republicans voting yes.', ARRAY['https://www.govtrack.us/congress/votes/118-2024/h151', 'https://www.govtrack.us/congress/bills/118/hr8035']::text[]),
    -- Ben McAdams | medicare/aid | repair
    ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'As Salt Lake County Mayor he publicly backed Utah House Bill 437, the 2016 compromise Medicaid expansion covering an estimated 16,000 of the state’s most-in-need residents, alongside Salt Lake City Mayor Jackie Biskupski, while saying he would prefer "a solution that would close the coverage gap entirely, but this proposal appears to have the best hope of passing". Expanding eligibility while stopping short of universal coverage is this rung. Two corrections: the bill is HB437, not HB347, and the Wikipedia biography previously cited contains no mention of Medicaid at all.', ARRAY['https://www.kuer.org/health-care/2016-03-01/salt-lake-area-leaders-support-compromise-health-care-bill']::text[]),
    -- Bo Biteman | voting-rights | reseat
    ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 'Moved from rung 4 to rung 5. He is a named sponsor of Wyoming Senate File SF0190 (2025), "Election transparency", whose own first page reads "Sponsored by: Senator(s) Biteman and Salazar" and which is "AN ACT relating to elections; requiring paper ballots as specified … requiring proof of United States citizenship to register to vote as specified". That is this rung almost word for word, not rung 4’s photo identification. The bill did not pass; chief sponsorship establishes his position and this row asserts no law. The Ballotpedia profile previously cited carries no bill, only scorecard boilerplate.', ARRAY['https://wyoleg.gov/2025/Introduced/SF0190.pdf']::text[]),
    -- Bob Good | ukraine-support | repair
    ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 'On the passage of H.R. 8035, the Ukraine Security Supplemental Appropriations Act, 2024, roll call 118-2024/h151, the Clerk records VA-5 Representative Bob Good voting Nay. Voting against one supplemental supports reducing aid; it does not establish rung 5’s ending of all aid. The chair is unchanged, but its basis is: the previous reasoning rested on Freedom Caucus membership, a presidential-alignment score and the ALLIES Act, which concerns Afghan visas, none of which is a position on Ukraine.', ARRAY['https://www.govtrack.us/congress/votes/118-2024/h151', 'https://www.govtrack.us/congress/bills/118/hr8035']::text[]),
    -- Brinker Harding | fossil-fuels | repair
    ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 'His platform pledges to "expand American energy production to reduce our dependence on foreign countries". Expansion is more than rung 3’s current levels, and he proposes no removal of environmental restrictions, which rung 5 would require. The row records that he writes "American energy production" rather than naming fossil fuels.', ARRAY['https://ballotpedia.org/Brinker_Harding#Campaign_themes']::text[]),
    -- Bryce Nickel | climate-change | repair
    ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'His survey calls for "massive federal investments in green public transit and sustainable infrastructure to connect our communities and combat climate change", funded by a federal wealth tax. Public investment is this rung.', ARRAY['https://ballotpedia.org/Bryce_Nickel#Campaign_themes']::text[]),
    -- Byron Sigcho-Lopez | taxes | reseat
    ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'Moved from rung 1 to rung 2. The cited evidence is a 2019 letter he co-signed criticising Mayor Lightfoot’s budget for "an over-reliance on property taxes" and "regressive funding models" that are "burdensome to our working-class citizens, while giving the wealthy and large corporations a pass". That establishes direction but not magnitude. The previous reasoning reached rung 1’s "significantly" through his caucus’s platform; caucus membership is not a position, and with that step removed the letter supports rung 2.', ARRAY['https://en.wikipedia.org/wiki/Byron_Sigcho-Lopez']::text[]),
    -- Caroline Menjivar | same-sex-marriage | blank
    ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 'INTERNAL RECORD — blanked because identity and affiliation are not a position. The chair rested on her being the first LGBTQ legislator to represent the San Fernando Valley and serving on the board of GLSEN’s Los Angeles chapter. Neither states a position on marriage law, and the cited article carries no marriage statement by her.', ARRAY['https://en.wikipedia.org/wiki/Caroline_Menjivar']::text[]),
    -- Casey Shepard | abortion | blank
    ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'INTERNAL RECORD — blanked because the evidence names a direction, not a rung. "Bodily autonomy" appears once on the page, as one item in a fifteen-item list of Democratic priorities beside DEI, LGBTQ+ rights and trade policy. The words abortion and reproductive do not appear on the page at all.', ARRAY['https://ballotpedia.org/Casey_Shepard#Campaign_themes']::text[]),
    -- Civil Miller-Watkins | voting-rights | blank
    ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 'INTERNAL RECORD — blanked because the Season 2 ladder asks a different question. Her platform says she is "a strong supporter of the John Lewis Voting Rights Act" and will "protect voting rights, increase civic participation, strengthen faith in our elections". This question now asks only what identification a voter must present, and she states no position on it.', ARRAY['https://ballotpedia.org/Civil_Miller-Watkins#Campaign_themes']::text[]),
    -- Cliff Johnson | medicare/aid | blank
    ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'INTERNAL RECORD — blanked because the evidence is a diagnosis, not a position. He warns that "tens of thousands of Mississippians who have insurance through Medicaid and the Affordable Care Act are about to lose coverage" and that "insurance is unaffordable for too many". That rules out rungs 4 and 5 but is equally consistent with rungs 1, 2 and 3 — and in Mississippi the live question is Medicaid expansion, which he never addresses.', ARRAY['https://ballotpedia.org/Cliff_Johnson_(Mississippi)#Campaign_themes']::text[]),
    -- Cori Bush | abortion | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'Cosponsor of the Women’s Health Protection Act of 2023 (H.R. 12), which would establish a statutory right to provide and receive abortion care, and of the EACH Act of 2023 (H.R. 561), which would end the Hyde Amendment and require federal health programs to cover abortion. The EACH Act is what carries the public-funding limb of this rung; the previously cited member landing page holds no position and could not be fetched.', ARRAY['https://www.govtrack.us/congress/bills/118/hr12', 'https://www.govtrack.us/congress/bills/118/hr561']::text[]),
    -- Cori Bush | childcare | reseat
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 'Moved from rung 2 to rung 1. Cosponsor of the Child Care for Every Community Act (H.R. 953), whose stated purpose is "to establish universal child care and early learning programs" — that is rung 1, not rung 2’s expansion of subsidies. She also cosponsored the Child Care for Working Families Act (H.R. 2976), which caps costs and expands subsidies; the more expansive commitment governs the seat.', ARRAY['https://www.govtrack.us/congress/bills/118/hr953', 'https://www.govtrack.us/congress/bills/118/hr2976']::text[]),
    -- Cori Bush | civil-rights | reseat
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 'Moved from rung 1 to rung 2. Cosponsor of H.R. 40, which creates a commission to study reparation proposals, of the CROWN Act of 2024 (H.R. 8191) banning race-based hair discrimination, and of the Domestic Workers Bill of Rights Act (H.R. 8732). A study commission and two anti-discrimination statutes strengthen enforcement and address systemic discrimination; none of them mandates racial equity requirements in all institutions, which is what rung 1 asks.', ARRAY['https://www.govtrack.us/congress/bills/118/hr40', 'https://www.govtrack.us/congress/bills/118/hr8191', 'https://www.govtrack.us/congress/bills/118/hr8732']::text[]),
    -- Cori Bush | climate-change | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'Cosponsor of the Green New Deal for Public Housing Act (H.R. 7782), the Green New Deal for Public Schools Act of 2023 (H.R. 5784) and the BUILD GREEN Infrastructure and Jobs Act (H.R. 8253). All three are public-investment vehicles, which is what this rung asks; the citation previously pointed at a member landing page rather than the bills.', ARRAY['https://www.govtrack.us/congress/bills/118/hr7782', 'https://www.govtrack.us/congress/bills/118/hr5784', 'https://www.govtrack.us/congress/bills/118/hr8253']::text[]),
    -- Cori Bush | fossil-fuels | blank
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 'INTERNAL RECORD — blanked because the evidence is on a different axis, not because none exists. Her documented record is subsidy repeal: the End Polluter Welfare Act of 2024 (H.R. 8554) and the End Polluter Welfare for Enhanced Oil Recovery Act of 2024 (H.R. 9838), both cosponsored. Every rung on this ladder is about permits and production levels, and ending subsidies is none of them. She is not a cosponsor of Keep It in the Ground (H.R. 10489), the vehicle rung 1 would require. Re-research if a production or leasing position is found.', ARRAY['https://www.govtrack.us/congress/bills/118/hr8554', 'https://www.govtrack.us/congress/bills/118/hr9838', 'https://www.govtrack.us/congress/bills/118/hr10489']::text[]),
    -- Cori Bush | homelessness | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 'Sponsor — not merely cosponsor — of H.Res. 634, the Unhoused Persons Bill of Rights, which asserts the human rights of unhoused people to "free movement in public spaces" and "freedom from harassment by law enforcement". That is this rung in her own words. The housing-supply bills previously cited say nothing about enforcement, which is the axis this ladder measures.', ARRAY['https://www.govtrack.us/congress/bills/118/hres634']::text[]),
    -- Cori Bush | housing | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 'Cosponsor of the Housing Is a Human Right Act of 2023 (H.R. 1708), of the Homes Act of 2024 (H.R. 9662), which would create a federal authority to develop and operate social housing, and of the Green New Deal for Public Housing Act (H.R. 7782). Together they make government the main provider. Note H.R. 9662 is the Homes Act; the similarly titled H.R. 9958 "HOMES Act of 2024" is an unrelated retirement-account tax bill she has no part in.', ARRAY['https://www.govtrack.us/congress/bills/118/hr1708', 'https://www.govtrack.us/congress/bills/118/hr9662', 'https://www.govtrack.us/congress/bills/118/hr7782']::text[]),
    -- Cori Bush | school-vouchers | blank
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'INTERNAL RECORD — blanked for absence of evidence. The previous reasoning’s own basis was that "no cosponsorship or statement supporting school vouchers was found", which cannot seat rung 1; rung 1 requires affirmative support for eliminating voucher programs. The Green New Deal for Public Schools Act (H.R. 5784) funds public-school infrastructure and says nothing about vouchers. No position either way is on record.', ARRAY['https://www.govtrack.us/congress/bills/118/hr5784']::text[]),
    -- Cori Bush | taxes | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'Cosponsor of the Ultra-Millionaire Tax Act of 2024 (H.R. 7749), which imposes an annual wealth tax on households worth more than $50 million to fund public services — rung 1 precisely.', ARRAY['https://www.govtrack.us/congress/bills/118/hr7749']::text[]),
    -- Cori Bush | trans-athletes | blank
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'INTERNAL RECORD — blanked because a clear general record does not reach this question. She cosponsored the Transgender Bill of Rights (H.Res. 269), whose text contains no reference to sport or athletics, and voted for the Equality Act, which states no athletics rule. On H.R. 734, the one House vote on exactly this question (roll 118-2023/h192), the Clerk records her as not voting. On topic by vocabulary, not by rationale.', ARRAY['https://www.govtrack.us/congress/bills/118/hres269', 'https://www.govtrack.us/congress/votes/118-2023/h192']::text[]),
    -- Danny Minton | redistricting | blank
    ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'INTERNAL RECORD — blanked because the evidence names a goal, not a mechanism. His platform demands "fair maps" and condemns politicians who "rig maps" and "pick their voters", which is verified on the page but says nothing about who should draw districts. Rung 1 requires independent citizens’ commissions with no elected officials involved.', ARRAY['https://ballotpedia.org/Danny_Minton#Campaign_themes']::text[]),
    -- David S. Kerr, Jr. | healthcare | repair
    ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'His survey says "the ACA has been defunded by the Republican Party which has caused many people to lose health care coverage" and proposes redirecting a share of military spending to fund healthcare. The Affordable Care Act is itself the public-programmes-plus-regulated-private-insurance model this rung describes.', ARRAY['https://ballotpedia.org/David_Kerr_Jr._(Tennessee)#Campaign_themes']::text[]),
    -- David Womack | deportation | repair
    ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'His survey supports "effective border control with humane enforcement, and creating a pathway to citizenship for nonviolent undocumented immigrants", with "enforcement at the border, not in our neighborhoods". Reserving removal for those convicted of serious violent crimes is this rung.', ARRAY['https://ballotpedia.org/David_Womack#Campaign_themes']::text[]),
    -- Devin Hermanson | redistricting | blank
    ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'INTERNAL RECORD — blanked because the evidence names a goal, not a mechanism. His website lists "get money out of politics, protect voting rights, end gerrymandering, fight disinformation, expand the Supreme Court" as democracy priorities. No map-drawing mechanism is proposed.', ARRAY['https://ballotpedia.org/Devin_Hermanson#Campaign_themes']::text[]),
    -- Dewey Gordon Bryan | social-security | repair
    ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 'His survey warns that Social Security "is projected to be broke" and asks what representatives have done to prevent it, and he opposes plans to take "your government contributions and place them under the management of … the stock market". Opposing private accounts rules out rung 5, and demanding solvency for future generations is this rung; he names no specific adjustment.', ARRAY['https://ballotpedia.org/Dewey_Gordon_Bryan#Campaign_themes']::text[]),
    -- Ernie Rivera | social-security | repair
    ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 'His platform pledges to "protect the Medicare and Social Security benefits seniors have earned". Defending earned benefits rules out rung 4’s benefit reductions and rung 5’s private accounts, and claims none of the expansion in rungs 1 and 2. The row records that he proposes no specific adjustment of his own.', ARRAY['https://ballotpedia.org/Ernie_Rivera#Campaign_themes']::text[]),
    -- Hunter Gordon | climate-change | blank
    ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'INTERNAL RECORD — blanked because the evidence names a programme, not a rung. "Fighting for a Green New Deal" appears once, as a clause in a list beside LGBTQ+ rights and immigration; the words climate and energy do not appear on the page. The Green New Deal spans rung 1’s mandates and deadlines and rung 2’s investment, and a bare mention cannot choose between them.', ARRAY['https://ballotpedia.org/Hunter_Gordon#Campaign_themes']::text[]),
    -- Jackie Goldberg | school-vouchers | reseat
    ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'Moved from rung 1 to rung 2. Her verified record is opposition to charter-school expansion — she challenged aid to charter schools on joining the board — and her campaign pledged that she would "defend public education from federal attacks by Betsy DeVos and all others". Charters are public schools, not rung 1’s private institutions, and California operates no voucher programme to eliminate. Opposing vouchers and blocking their expansion is the supportable seat.', ARRAY['https://ballotpedia.org/Jackie_Goldberg#Campaign_themes']::text[]),
    -- Jarrett Keohokalole | voting-rights | blank
    ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 'INTERNAL RECORD — blanked because the Season 2 ladder asks a different question. His evidence is Hawaii HB489 (2015), automatic voter registration for driver’s-licence and state-ID applicants. That is a registration measure; this ladder is entirely about identification requirements. Migration 1913 settled this shape for Saddam Salim: inferring an identification stance from a registration bill reads the chair off the member’s party.', ARRAY['https://ballotpedia.org/Jarrett_Keohokalole#Campaign_themes']::text[]),
    -- Jason Pearce | childcare | blank
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 'INTERNAL RECORD — blanked because the evidence names a direction, not a rung. His platform lists "affordable childcare" as one item in a bullet list beside free school meals and free community college. Rungs 1 to 4 all deliver childcare affordability and differ only in scope and instrument, neither of which he states.', ARRAY['https://ballotpedia.org/Jason_Pearce#Campaign_themes']::text[]),
    -- Jason Pearce | redistricting | blank
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'INTERNAL RECORD — blanked because the evidence names a goal, not a mechanism. His platform lists "end gerrymandering" among clean-government goals. Rungs 1 to 4 all claim to reduce gerrymandering and differ only by who draws the map. The phrase rules out rung 5 and nothing further.', ARRAY['https://ballotpedia.org/Jason_Pearce#Campaign_themes']::text[]),
    -- Johnny Baucom | taxes | repair
    ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'His Candidate Connection survey, carried in full on the district election page, states that "income, and property taxes are unconstitutional, and reprehensible" and that "the full abolition of the IRS is the only proper step forward in American liberation" — rung 5 or beyond. The citation is an election page, which Ballotpedia uses to host candidate surveys; it resolves and carries the text.', ARRAY['https://ballotpedia.org/Mississippi''s_1st_Congressional_District_election,_2026']::text[]),
    -- Jonathan Nez | abortion | blank
    ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'INTERNAL RECORD — blanked because the evidence names a direction, not a rung. His campaign website states "the right to choose is about individual sovereignty. In Arizona, we don’t let anyone tell us what to do – especially about our own bodies." A bare pro-choice statement with no gestational or funding content cannot separate rungs 1, 2 and 3.', ARRAY['https://ballotpedia.org/Jonathan_Nez#Campaign_themes']::text[]),
    -- Jordan Conley | homelessness | blank
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 'INTERNAL RECORD — blanked because the Season 2 ladder asks a different question. His survey describes a Housing First programme: "First we put people in homes. Then we help them further depending on needs." That is a provision strategy. This ladder measures enforcement, from protecting the right to sleep in public to criminal penalties, and he states no position on it.', ARRAY['https://ballotpedia.org/Jordan_Conley#Campaign_themes']::text[]),
    -- Jordan Conley | taxes | repair
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'His survey lists "taxing the rich" among the policies he is most passionate about, and he would fund state universal health care through "an empty homes tax, visitor tax, and lowering prices by negotiating directly with hospital and caregivers" — raising taxes on wealth to fund new public services, which is rung 1.', ARRAY['https://ballotpedia.org/Jordan_Conley#Campaign_themes']::text[]),
    -- Joshua Ray Ashburn | taxes | reseat
    ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'Moved from rung 4 to rung 3. His survey asks to "reduce their tax burden" for small business owners and farmers and to "cut unnecessary red tape". Rung 4 is cutting taxes for everyone and scaling back public services to match; he proposes neither the universality nor the service reductions, and targeted relief is a small adjustment to the current system.', ARRAY['https://ballotpedia.org/Joshua_Ray_Ashburn#Campaign_themes']::text[]),
    -- Kelley Dennison | climate-change | repair
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'Her platform supports "American energy independence through responsible domestic oil, natural gas, and clean energy production". Backing all sources at once is rung 4’s market neutrality rather than a preference for any transition path.', ARRAY['https://www.ballotready.org/people/kelley-anne-dennison']::text[]),
    -- Kelley Dennison | fossil-fuels | repair
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 'Her platform objects to "policies that weaken domestic energy development" and backs "responsible domestic energy production with strong environmental accountability". Opposing weakened development is more than rung 3’s status quo, and the accountability commitment rules out rung 5’s removal of environmental restrictions.', ARRAY['https://www.ballotready.org/people/kelley-anne-dennison']::text[]),
    -- Kelley Dennison | housing | repair
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 'Her platform would "increase housing availability, reduce unnecessary federal regulations, and empower local communities to responsibly address housing needs without excessive government interference" — rung 5 in substance.', ARRAY['https://www.ballotready.org/people/kelley-anne-dennison']::text[]),
    -- Kelley Dennison | taxes | reseat
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'Moved from rung 4 to rung 3. Rung 4 is cutting taxes for everyone and scaling back public services to match. She proposes no tax cut: her planks are spending restraint — "reduce reckless federal spending", stop "trillion-dollar spending packages" — and shielding seniors from rising taxes. Opposing increases is not proposing cuts, so the current system stands.', ARRAY['https://www.ballotready.org/people/kelley-anne-dennison']::text[]),
    -- Kevin Fagan | campaign-finance | reseat
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 'Moved from rung 1 to rung 2. He pledges to refuse all corporate PAC money, would bar members of Congress from trading individual stocks, and says he "will support any effort to overturn SCOTUS’ Citizen’s United decision". Overturning Citizens United strictly limits corporate and dark-money spending; rung 1 is a ban on all private money in campaigns, which he never proposes.', ARRAY['https://ballotpedia.org/Kevin_Fagan#Campaign_themes']::text[]),
    -- Kevin Fagan | housing | repair
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 'He would "make government a partner in progress, not a roadblock", "streamline regulations so we can build faster and more affordably — with good union jobs and real community investment", and build more infill housing near services. Subsidy and investment without binding rules on the private market is rung 4; he proposes neither rent caps nor affordability mandates.', ARRAY['https://ballotpedia.org/Kevin_Fagan#Campaign_themes']::text[]),
    -- Kim Farington | climate-change | repair
    ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'Her platform summary states "energy policy: strongly supports oil, gas, coal, and nuclear expansion; opposes federal fossil-fuel restrictions on its use. Against government-mandated solar and wind energy", and separately that she "opposes aggressive federal climate mandates". Ending mandates for clean energy is this rung, and the stated fossil preference rules out rung 4’s neutrality.', ARRAY['https://ballotpedia.org/Kim_Farington#Campaign_themes']::text[]),
    -- Kristi Burke | healthcare | blank
    ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'INTERNAL RECORD — blanked because the evidence names a principle, not a mechanism. She writes that she does not have health insurance, "navigating the same pay or pray system you do", and that "essential needs like healthcare, housing, and a clean environment should never be gatekept by wealth". Rungs 1 and 2 both satisfy that, and she names no delivery model.', ARRAY['https://ballotpedia.org/Kristi_Burke#Campaign_themes']::text[]),
    -- Luke Bronin | childcare | blank
    ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 'INTERNAL RECORD — blanked because the evidence is a cost diagnosis, not a rung. His platform says "childcare and eldercare costs are forcing families into impossible choices", that those costs fall hardest on women and working families, and that caregivers are underpaid. No instrument and no scope are named, which leaves rungs 1, 2 and 3 equally consistent.', ARRAY['https://ballotpedia.org/Luke_Bronin#Campaign_themes']::text[]),
    -- Lynn Chapman | same-sex-marriage | blank
    ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 'INTERNAL RECORD — blanked on currency, not accuracy. The citation is sound: the article names her among opponents of Nevada’s 1993 sodomy-law repeal and quotes her warning that repeal would "open the floodgate … in legalizing, condoning and recognizing homosexuality to be on an equal footing with heterosexuality" and lead to "such things as homosexual marriage and adoption of children". But that is testimony about a different statute, given thirty-three years ago, naming same-sex marriage only as a feared consequence, with nothing since. The latest filing governs, and a chair shown to voters in 2026 cannot rest on it.', ARRAY['https://en.wikipedia.org/wiki/LGBTQ_rights_in_Nevada']::text[]),
    -- Marquita Bradshaw | civil-rights | repair
    ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 'Her campaign statement calls for "a fundamental overhaul of our justice system to ensure that we all are being held to an equal interpretation of the law, not one rooted in racial and income bias" — addressing systemic discrimination, which is this rung. Her Sierra Club environmental-justice chairmanship is dropped from the basis: a title is not a position.', ARRAY['https://ballotpedia.org/Marquita_Bradshaw#Campaign_themes']::text[]),
    -- Michael Van Meter | taxes | repair
    ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'His platform states "we must find ways to reduce taxes and promote economic growth" in an economy "as free as possible from government interference". A general tax cut with a smaller state is rung 4, short of rung 5’s drastic shrinkage. The platform is from his 2024 run; a later filing would govern.', ARRAY['https://ballotpedia.org/Michael_Van_Meter#Campaign_themes']::text[]),
    -- Mikel Wein | ai-regulation | blank
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 'INTERNAL RECORD — blanked because the evidence is on a different axis. His survey calls for "strong regulation on growth of AI, including data centers", which is about buildout. Every rung here is about controls on development and deployment — unrestricted, voluntary guidelines, liability, safety testing, pre-approval. The previous reasoning conceded he "does not specify an approval-based licensing regime", arguing him off rung 5 without evidencing rung 4.', ARRAY['https://ballotpedia.org/Mikel_Wein#Campaign_themes']::text[]),
    -- Mikel Wein | climate-change | reseat
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'Moved from rung 3 to rung 2, because the rung changed. His Resilient Community Corps would "repurpose abandoned mine lands for local green energy" and fund renewable-energy and infrastructure projects in eastern Kentucky. That is public investment, which was Season 1 rung 3 and is Season 2 rung 2; Season 2 rung 3 now asks about permitting and the grid, which he does not address.', ARRAY['https://ballotpedia.org/Mikel_Wein#Campaign_themes']::text[]),
    -- Mikel Wein | deportation | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'His Candidate Connection survey states he would "de-fund services, such as ICE, that are unlawfully harming people in our own country and making us afraid" — dismantling the removal apparatus rather than redirecting it, which is this rung. Deep-linked to the survey section; the bare profile URL and the district election page were not the evidence.', ARRAY['https://ballotpedia.org/Mikel_Wein#Campaign_themes']::text[]),
    -- Mikel Wein | healthcare | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'His survey calls for "a national healthcare system that prioritizes people over profit". Rung 1 is the nearest rung on a single-choice ladder: he does not use the words free or public sector, but a national system displacing profit-driven provision is not rung 2’s regulated private mix.', ARRAY['https://ballotpedia.org/Mikel_Wein#Campaign_themes']::text[]),
    -- Mikel Wein | taxes | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'His survey calls to "fix our upside-down tax code" with a "no billionaire" tax code and frames the campaign around ending wealth inequality — rung 1.', ARRAY['https://ballotpedia.org/Mikel_Wein#Campaign_themes']::text[]),
    -- Mikel Wein | ukraine-support | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 'His survey calls to "end wars, military actions, foreign entanglements", to "de-fund our own military actions against other countries" and to "halt military support for other countries". The plank is categorical and Ukraine is such a country, so the entailment is direct. Two limits are recorded: he never names Ukraine, and he addresses military support rather than the humanitarian aid this rung also covers.', ARRAY['https://ballotpedia.org/Mikel_Wein#Campaign_themes']::text[]),
    -- Mónica García | deportation | blank
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'INTERNAL RECORD — blanked because the cited page does not carry the claim. The row cited ballotpedia.org/Monica_Garcia, which is a 404 stub; her real page, at the accented spelling, contains no occurrence of deport, immigra or sanctuary. The 2017 LAUSD sanctuary-schools resolution attributed to her is not on it, and a board resolution adopted unanimously would in any case be weak evidence of an individual position.', ARRAY['https://ballotpedia.org/M%C3%B3nica_Garc%C3%ADa']::text[]),
    -- Mónica García | school-vouchers | blank
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'INTERNAL RECORD — blanked because the basis was impermissible and the page contradicts it. The previous reasoning inferred a moderate stance from her "campaign donations from both charter supporters and traditional district employees"; who donates to a candidate is not her position. The word voucher does not appear on her real page, and her own 2017 campaign text says she "fought to give parents more choices of where they send their children to school", which points away from rung 2 rather than toward it.', ARRAY['https://ballotpedia.org/M%C3%B3nica_Garc%C3%ADa']::text[]),
    -- Nadia Milleron | healthcare | reseat
    ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'Moved from rung 3 to rung 1. The previous reasoning held that she proposes "no single-payer or public-option mechanism". Her page says "I support kicking corporate insurance out of healthcare" and that "by driving popular Healthcare for All legislation, I will drastically lower costs". Rung 3 keeps private insurance for everyone else, which that directly contradicts.', ARRAY['https://ballotpedia.org/Nadia_Milleron#Campaign_themes']::text[]),
    -- Nanette Barragan | religious-freedom | repair
    ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 'Cosponsor of the Do No Harm Act in the 115th Congress (H.R. 3222) and again in the 117th (H.R. 1378). The Act limits religious exemptions under the Religious Freedom Restoration Act where they would override anti-discrimination law or deny benefits and services to third parties — protecting religious freedom while preventing it from overriding anti-discrimination protections, which is this rung. Cited to GovTrack because congress.gov returns 403.', ARRAY['https://www.govtrack.us/congress/bills/117/hr1378', 'https://www.govtrack.us/congress/bills/115/hr3222']::text[]),
    -- Reid Rasner | misinformation | repair
    ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 'His platform states he "aims to end government and big tech censorship of conservative voices, believing in the importance of preserving diverse viewpoints in the public discourse". Protecting online speech and preventing government censorship is this rung; he stops short of rung 5’s ban on any government involvement in moderation. The platform is from his 2024 run; a later filing would govern.', ARRAY['https://ballotpedia.org/Reid_Rasner#Campaign_themes']::text[]),
    -- Richard Ojeda | abortion | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'The Political positions section records that he self-identifies as pro choice, supports abortion rights, would nominate only judges who share that support, and has said he supported Roe v. Wade and Planned Parenthood. Roe’s framework is legal access to viability, which is rung 2; nothing on record claims public funding at all stages.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Abortion']::text[]),
    -- Richard Ojeda | campaign-finance | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 'He has pledged not to take corporate donations, supports WolfPAC, which campaigns to overturn Citizens United, and has proposed body-cameras on lobbyists and earnings limits on retired federal officials. Overturning Citizens United strictly limits corporate and dark-money spending; it is not rung 1’s ban on all private money in campaigns.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Campaign_finance,_political_ethics,_and_transparency']::text[]),
    -- Richard Ojeda | climate-change | blank
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'INTERNAL RECORD — blanked because the rung his evidence fits was replaced between seasons. He has called for sustainable energy and for miners to transition into other well-paying jobs, and has acknowledged coal is "not gonna come back". That matched the Season 1 rung 3, "invest in clean energy while gradually reducing reliance on fossil fuels". Season 2 rung 3 now reads "speed up clean energy by cutting permitting red tape and upgrading the grid", which he has never addressed, and rung 2 requires a funding instrument he does not name. No Season 2 rung asks what his evidence answers.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Environment']::text[]),
    -- Richard Ojeda | deportation | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'He supports Deferred Action for Childhood Arrivals and a pathway to citizenship for Dreamers, has opposed family separation at the border, and has made changing federal immigration policy his top 2026 priority while criticising ICE raids. That protects long-settled immigrants, which is the second half of this rung. He states no position on recent arrivals, the rung’s first half; rung 3 is recorded as the nearest rung on a single-choice ladder.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Immigration']::text[]),
    -- Richard Ojeda | fossil-fuels | blank
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 'INTERNAL RECORD — blanked for want of a production position. This ladder is identical in both seasons, so the failure is evidential, not structural. His coal statements are a prediction ("not gonna come back") and an observation that coal retains a limited role in steel-making; neither states what production or permitting policy he would set. His one regulatory statement on record — praising the 2018 rollback of environmental regulations — points away from rung 3’s "with existing environmental regulations".', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Environment']::text[]),
    -- Richard Ojeda | healthcare | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'In his 2026 North Carolina campaign he has backed expanding Medicaid and protecting the Affordable Care Act. That is coverage through a mix of public programmes and regulated private insurance, which is this rung.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Healthcare']::text[]),
    -- Richard Ojeda | medicare/aid | reseat
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'Moved from rung 3 to rung 2, because the rung changed. The previous reasoning placed him at 3 on the ground that the record "does not document a position on lowering the Medicare eligibility age to 55". Season 1 rung 2 was a conjunction — "lower Medicare age to 55 and expand Medicaid significantly" — and Season 2 rung 2 is a disjunction, "significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage". His support for Medicaid expansion alone now satisfies it.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Healthcare']::text[]),
    -- Richard Ojeda | taxes | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'Recorded as one of the few West Virginia lawmakers to come out for raising taxes on corporations and the rich, calling for higher corporate taxes to offset spending cuts that had damaged public services — rung 1 exactly.', ARRAY['https://en.wikipedia.org/wiki/Richard_Ojeda#Taxes']::text[]),
    -- Sarah Zabel | ai-regulation | repair
    ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 'Her survey answer begins "the U.S. government must ensure that people are held accountable for what they do", and goes on to ask for transparency so people know when they are interacting with AI or seeing AI-generated audio and video, and for the learning path of an AI to be documented. The accountability clause is this rung. The row records a limit: Season 1 rung 3 also carried a disclosure requirement and Season 2 dropped it, so her transparency proposals now have no home on this ladder and the seat rests on liability alone.', ARRAY['https://ballotpedia.org/Sarah_Zabel_(Idaho)#Campaign_themes']::text[]),
    -- Seth Moulton | ai-regulation | blank
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 'INTERNAL RECORD — blanked for absence of evidence, which the row already stated. Its own reasoning opened "no strong documented public position on AI regulation found in available sources", then seated him on membership of the House Select Committee on Strategic Competition with China. A committee seat is not a position, and the phrase artificial intelligence does not appear on the cited page.', ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton']::text[]),
    -- Seth Moulton | trans-athletes | repair
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'His record is mixed and all three parts are documented. He cosponsored the Transgender Bill of Rights in 2022 and 2023 and voted for the Equality Act. After the 2024 election he said "I have two little girls, I don’t want them getting run over on a playing field by a male or formerly male athlete". In January 2025 he voted Nay on the Protection of Women and Girls in Sports Act, roll call 119-2025/h12, calling the bill "too extreme". The Nay rules out rungs 4 and 5, the comment rules out unrestricted inclusion, and a sport-specific, case-by-case approach is what remains.', ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton', 'https://www.govtrack.us/congress/votes/119-2025/h12']::text[]),
    -- Todd Warner | taxes | repair
    ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'His platform pledges to "make the Trump tax cuts permanent, eliminate the death tax, slash federal regulations … and oppose every tax hike", under the heading "Cut the taxes. Slash the red tape. Get out of the way." — rung 5.', ARRAY['https://ballotpedia.org/Todd_Warner#Campaign_themes']::text[]),
    -- Tom Schmitz | abortion | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'He argues that free-market medical innovation — he cites artificial-womb technology and compensated adoption — can make abortion "obsolete" by voluntary means rather than by government banning or funding it. This ladder has no government-stays-out rung; rung 2 is the nearest legal-but-not-publicly-funded rung, and the row records that he states no gestational limit.', ARRAY['https://www.ballotready.org/people/tom-schmitz']::text[]),
    -- Tom Schmitz | climate-change | blank
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'INTERNAL RECORD — blanked because the rung his evidence fits was replaced between seasons. He says nuclear power "is exactly what we need to fight global climate change" and calls for a revamped EPA with "dramatically increased effort and attention on protecting our environment". That matched Season 1 rung 3, investing in clean energy; Season 2 rung 3 is permitting and grid upgrades, which he never mentions, and rung 2 requires a subsidy instrument he does not propose. Third row in this cohort lost to the same rewrite.', ARRAY['https://www.ballotready.org/people/tom-schmitz']::text[]),
    -- Tom Schmitz | healthcare | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'He calls for "separation of healthcare and state" and would reduce the FDA to an advisory role before phasing it out — rung 5 exactly.', ARRAY['https://www.ballotready.org/people/tom-schmitz']::text[]),
    -- Tom Schmitz | taxes | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'He calls for replacing compulsory taxation with "a system of voluntary taxation" and for phasing out government safety nets in favour of voluntary charity — at or beyond the end of this ladder.', ARRAY['https://www.ballotready.org/people/tom-schmitz']::text[]),
    -- Tom Schmitz | ukraine-support | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 'He endorses a foreign policy of "peace and non-interventionism" and calls to "end all foreign aid, across the board". The claim is categorical and covers all aid, so unlike a military-support-only plank it reaches this rung’s humanitarian limb as well.', ARRAY['https://www.ballotready.org/people/tom-schmitz']::text[]),
    -- Tony Strickland | housing | blank
    ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 'INTERNAL RECORD — blanked because no rung on this ladder describes his record. As Huntington Beach councilmember and mayor he "staunchly opposed increasing housing supply", the city stopped accepting accessory-dwelling-unit applications, and the state Attorney General sued the city over the California HOME Act. Rung 5 describes relying on the market and cutting the regulations and zoning limits that block private building; he added such barriers rather than removing them, and rungs 1 to 4 are public provision or market regulation. The ladder has no rung for using local zoning to block housing — recorded for the Season 3 review.', ARRAY['https://en.wikipedia.org/wiki/Tony_Strickland#Housing_issues']::text[]),
    -- Trina Swanson | medicare/aid | repair
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'Her platform would focus on "lowering prescription drug prices, expanding rural health care access, protecting Medicare and Social Security". Lowering drug prices is cost control and expanding rural access improves the current programmes, which is this rung in substance.', ARRAY['https://ballotpedia.org/Trina_Swanson#Campaign_themes']::text[]),
    -- Trina Swanson | social-security | repair
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 'Her platform lists "protecting Medicare and Social Security" among her affordability priorities. As with any protect-as-is position this rules out reductions and privatisation while claiming no expansion; the row records that she proposes no specific adjustment.', ARRAY['https://ballotpedia.org/Trina_Swanson#Campaign_themes']::text[]),
    -- Victoria Broderick | abortion | repair
    ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'Her survey records that "Roe was overturned during my maternity leave, and I sprang into action", and lists "Reproductive Freedom. Every person deserves the right to choice" among her three key campaign messages. The anchor is Roe’s framework, which is what distinguishes this rung from rung 3’s first-trimester rule; she states no gestational limit of her own.', ARRAY['https://ballotpedia.org/Victoria_Broderick#Campaign_themes']::text[]),
    -- William Lawrence | civil-rights | blank
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 'INTERNAL RECORD — blanked because affiliation is not a position. The chair rested on membership of the Democratic Socialists of America and an endorsement from Showing Up for Racial Justice. Neither states what civil-rights policy he would enact.', ARRAY['https://en.wikipedia.org/wiki/William_Lawrence_(activist)']::text[]),
    -- William Lawrence | housing | reseat
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 'Moved from rung 3 to rung 2. The article records that he "is an advocate for Medicare for All and a Green New Deal, as well as creating more public housing", would "invest in affordable housing", founded the Mid-Michigan Tenant Resource Center and coordinates a tenant-union coalition. Season 2 rung 3 opens "build no public housing", which his advocacy contradicts. Note the previous row carried value 3 while its own reasoning said "aligns with scale value 2: rent caps" — a correct Season 1 to Season 2 renumbering of a seat that was wrong to begin with.', ARRAY['https://en.wikipedia.org/wiki/William_Lawrence_(activist)']::text[]),
    -- William Lawrence | medicare/aid | repair
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'The article states plainly that "he is an advocate for Medicare for All", which is extending Medicare to everyone regardless of age. The National Nurses United endorsement previously cited is dropped: an endorsement is not a position.', ARRAY['https://en.wikipedia.org/wiki/William_Lawrence_(activist)']::text[])
  ) AS v(pid, tid, reasoning, sources)
ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
  SET reasoning  = EXCLUDED.reasoning,
      sources    = EXCLUDED.sources,
      updated_at = now();


INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT v.pid, v.tid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,
       (SELECT sq.topic_revision_id FROM inform.season_questions sq
         WHERE sq.topic_id = v.tid AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'),
       v.value
  FROM (VALUES
    -- Aisha Farooqi | abortion | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    -- Aisha Farooqi | climate-change | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    -- Aisha Farooqi | healthcare | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1::numeric),
    -- Aisha Farooqi | medicare/aid | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1::numeric),
    -- Aisha Farooqi | redistricting | reseat (was 2.0)
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1::numeric),
    -- Aisha Farooqi | religious-freedom | reseat (was 2.0)
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3::numeric),
    -- Aisha Farooqi | school-vouchers | blank
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 0::numeric),
    -- Aisha Farooqi | taxes | repair
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2::numeric),
    -- Aisha Farooqi | voting-rights | blank
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0::numeric),
    -- Amir Hassan | tariffs | blank
    ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 0::numeric),
    -- Andrej Selivra | economic-development | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 0::numeric),
    -- Andrej Selivra | growth-and-development | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 0::numeric),
    -- Andrej Selivra | homelessness | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 0::numeric),
    -- Andrej Selivra | local-immigration | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 0::numeric),
    -- Andrej Selivra | public-safety-approach | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 0::numeric),
    -- Andrej Selivra | residential-zoning | blank
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 0::numeric),
    -- Andy Barr | ukraine-support | reseat (was 3.0)
    ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2::numeric),
    -- Ben McAdams | medicare/aid | repair
    ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2::numeric),
    -- Bo Biteman | voting-rights | reseat (was 4.0)
    ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 5::numeric),
    -- Bob Good | ukraine-support | repair
    ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 4::numeric),
    -- Brinker Harding | fossil-fuels | repair
    ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4::numeric),
    -- Bryce Nickel | climate-change | repair
    ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    -- Byron Sigcho-Lopez | taxes | reseat (was 1.0)
    ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2::numeric),
    -- Caroline Menjivar | same-sex-marriage | blank
    ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 0::numeric),
    -- Casey Shepard | abortion | blank
    ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 0::numeric),
    -- Civil Miller-Watkins | voting-rights | blank
    ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0::numeric),
    -- Cliff Johnson | medicare/aid | blank
    ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 0::numeric),
    -- Cori Bush | abortion | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1::numeric),
    -- Cori Bush | childcare | reseat (was 2.0)
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1::numeric),
    -- Cori Bush | civil-rights | reseat (was 1.0)
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric),
    -- Cori Bush | climate-change | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    -- Cori Bush | fossil-fuels | blank
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 0::numeric),
    -- Cori Bush | homelessness | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 1::numeric),
    -- Cori Bush | housing | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 1::numeric),
    -- Cori Bush | school-vouchers | blank
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 0::numeric),
    -- Cori Bush | taxes | repair
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    -- Cori Bush | trans-athletes | blank
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 0::numeric),
    -- Danny Minton | redistricting | blank
    ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 0::numeric),
    -- David S. Kerr, Jr. | healthcare | repair
    ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric),
    -- David Womack | deportation | repair
    ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2::numeric),
    -- Devin Hermanson | redistricting | blank
    ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 0::numeric),
    -- Dewey Gordon Bryan | social-security | repair
    ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3::numeric),
    -- Ernie Rivera | social-security | repair
    ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3::numeric),
    -- Hunter Gordon | climate-change | blank
    ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 0::numeric),
    -- Jackie Goldberg | school-vouchers | reseat (was 1.0)
    ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 2::numeric),
    -- Jarrett Keohokalole | voting-rights | blank
    ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0::numeric),
    -- Jason Pearce | childcare | blank
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 0::numeric),
    -- Jason Pearce | redistricting | blank
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 0::numeric),
    -- Johnny Baucom | taxes | repair
    ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5::numeric),
    -- Jonathan Nez | abortion | blank
    ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 0::numeric),
    -- Jordan Conley | homelessness | blank
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 0::numeric),
    -- Jordan Conley | taxes | repair
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    -- Joshua Ray Ashburn | taxes | reseat (was 4.0)
    ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3::numeric),
    -- Kelley Dennison | climate-change | repair
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4::numeric),
    -- Kelley Dennison | fossil-fuels | repair
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4::numeric),
    -- Kelley Dennison | housing | repair
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 5::numeric),
    -- Kelley Dennison | taxes | reseat (was 4.0)
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3::numeric),
    -- Kevin Fagan | campaign-finance | reseat (was 1.0)
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2::numeric),
    -- Kevin Fagan | housing | repair
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4::numeric),
    -- Kim Farington | climate-change | repair
    ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 5::numeric),
    -- Kristi Burke | healthcare | blank
    ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 0::numeric),
    -- Luke Bronin | childcare | blank
    ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 0::numeric),
    -- Lynn Chapman | same-sex-marriage | blank
    ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 0::numeric),
    -- Marquita Bradshaw | civil-rights | repair
    ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric),
    -- Michael Van Meter | taxes | repair
    ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4::numeric),
    -- Mikel Wein | ai-regulation | blank
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 0::numeric),
    -- Mikel Wein | climate-change | reseat (was 3.0)
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    -- Mikel Wein | deportation | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1::numeric),
    -- Mikel Wein | healthcare | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1::numeric),
    -- Mikel Wein | taxes | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    -- Mikel Wein | ukraine-support | repair
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 5::numeric),
    -- Mónica García | deportation | blank
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 0::numeric),
    -- Mónica García | school-vouchers | blank
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 0::numeric),
    -- Nadia Milleron | healthcare | reseat (was 3.0)
    ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1::numeric),
    -- Nanette Barragan | religious-freedom | repair
    ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2::numeric),
    -- Reid Rasner | misinformation | repair
    ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 4::numeric),
    -- Richard Ojeda | abortion | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    -- Richard Ojeda | campaign-finance | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2::numeric),
    -- Richard Ojeda | climate-change | blank
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 0::numeric),
    -- Richard Ojeda | deportation | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 3::numeric),
    -- Richard Ojeda | fossil-fuels | blank
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 0::numeric),
    -- Richard Ojeda | healthcare | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric),
    -- Richard Ojeda | medicare/aid | reseat (was 3.0)
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2::numeric),
    -- Richard Ojeda | taxes | repair
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    -- Sarah Zabel | ai-regulation | repair
    ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 3::numeric),
    -- Seth Moulton | ai-regulation | blank
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 0::numeric),
    -- Seth Moulton | trans-athletes | repair
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 3::numeric),
    -- Todd Warner | taxes | repair
    ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5::numeric),
    -- Tom Schmitz | abortion | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    -- Tom Schmitz | climate-change | blank
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 0::numeric),
    -- Tom Schmitz | healthcare | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 5::numeric),
    -- Tom Schmitz | taxes | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5::numeric),
    -- Tom Schmitz | ukraine-support | repair
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 5::numeric),
    -- Tony Strickland | housing | blank
    ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 0::numeric),
    -- Trina Swanson | medicare/aid | repair
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 3::numeric),
    -- Trina Swanson | social-security | repair
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3::numeric),
    -- Victoria Broderick | abortion | repair
    ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    -- William Lawrence | civil-rights | blank
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 0::numeric),
    -- William Lawrence | housing | reseat (was 3.0)
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric),
    -- William Lawrence | medicare/aid | repair
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1::numeric)
  ) AS v(pid, tid, value)
ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
  SET value      = EXCLUDED.value,
      updated_at = now();


DO $post$
DECLARE n int;
BEGIN
  -- every row landed at its intended value
  WITH want(pid, tid, val) AS (VALUES
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0::numeric),
    ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 0::numeric),
    ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2::numeric),
    ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2::numeric),
    ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 5::numeric),
    ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 4::numeric),
    ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4::numeric),
    ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2::numeric),
    ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 0::numeric),
    ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 0::numeric),
    ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0::numeric),
    ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 1::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 1::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 0::numeric),
    ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 0::numeric),
    ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric),
    ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2::numeric),
    ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 0::numeric),
    ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3::numeric),
    ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3::numeric),
    ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 0::numeric),
    ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 2::numeric),
    ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0::numeric),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 0::numeric),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 0::numeric),
    ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5::numeric),
    ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 0::numeric),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 0::numeric),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 5::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3::numeric),
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2::numeric),
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4::numeric),
    ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 5::numeric),
    ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 0::numeric),
    ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 0::numeric),
    ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 0::numeric),
    ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric),
    ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 5::numeric),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 0::numeric),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 0::numeric),
    ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1::numeric),
    ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2::numeric),
    ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 4::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 3::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1::numeric),
    ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 3::numeric),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 0::numeric),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 3::numeric),
    ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 5::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 5::numeric),
    ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 0::numeric),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 3::numeric),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3::numeric),
    ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 0::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1::numeric)
  )
  SELECT count(*) INTO n FROM want w
    JOIN inform.politician_answers a ON a.politician_id = w.pid AND a.topic_id = w.tid
     AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = w.val;
  IF n <> 100 THEN
    RAISE EXCEPTION 'migration 1914: % of 100 answers landed at the intended value', n;
  END IF;

  -- every row has its context
  SELECT count(*) INTO n FROM inform.politician_context c
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (c.politician_id, c.topic_id) IN (
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid),
       ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
       ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
       ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
       ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
       ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
       ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
       ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid)
     );
  IF n <> 100 THEN
    RAISE EXCEPTION 'migration 1914: % of 100 context rows present', n;
  END IF;

  -- the blanks are counted, not assumed
  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = 0
     AND (a.politician_id, a.topic_id) IN (
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid),
       ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
       ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
       ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
       ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
       ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
       ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
       ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid)
     );
  IF n <> 36 THEN
    RAISE EXCEPTION 'migration 1914: % blanks, expected 36', n;
  END IF;

  -- no row written without a source, blank or not
  SELECT count(*) INTO n FROM inform.politician_context c
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND coalesce(cardinality(c.sources), 0) = 0
     AND (c.politician_id, c.topic_id) IN (
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
       ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid),
       ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
       ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
       ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
       ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
       ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),
       ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
       ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
       ('f5441844-f641-4356-959f-b03461e50cba'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
       ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
       ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
       ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
       ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
       ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
       ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid),
       ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
       ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
       ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
       ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid)
     );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1914: % rows written with no source', n;
  END IF;

  -- Season 1 is untouched: the rows read there still hold their original values
  WITH want(pid, tid, oldval) AS (VALUES
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2.0::numeric),
    ('03ad7e84-1016-4ddb-b8e7-dbfdef118bc4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2.0::numeric),
    ('665434de-4809-4a7c-b1e2-81c29d11540a'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 4.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 3.0::numeric),
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 2.0::numeric),
    ('d6d297f5-5319-4be1-b938-6bcce63368e7'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 3.0::numeric),
    ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2.0::numeric),
    ('8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 4.0::numeric),
    ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 4.0::numeric),
    ('2f063464-29d8-42a4-bba3-d521ceb53555'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4.0::numeric),
    ('d2b0af22-bdc9-4ebf-ae71-3160b4592954'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2.0::numeric),
    ('c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1.0::numeric),
    ('1d67c8ad-ef38-47d6-8dae-691d0bc7bf9e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2.0::numeric),
    ('0d2998fc-a952-4337-9c12-61d11d0a2506'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2.0::numeric),
    ('244d3210-4ebc-4c42-a267-4587e4f795de'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 3.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1.0::numeric),
    ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 1.0::numeric),
    ('1af0730f-0e36-49f8-a454-768f9eb48f03'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1.0::numeric),
    ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2.0::numeric),
    ('3c724790-5982-466a-b9ab-659bd99c279e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2.0::numeric),
    ('8014ac34-62dd-48d8-ad9c-14485da42e51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1.0::numeric),
    ('305d2ded-2833-4cad-a7e7-e001972d9947'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3.0::numeric),
    ('bde578b4-fbb6-4d80-a55a-d5c3a24656ff'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3.0::numeric),
    ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2.0::numeric),
    ('92a8c2af-7365-4361-97a2-a16a189a046a'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1.0::numeric),
    ('4439ea32-1275-4cb2-9e0b-5a4d398a2d7a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 1.0::numeric),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2.0::numeric),
    ('e987cfff-23ae-4b24-a64d-4cde8582f520'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1.0::numeric),
    ('a8895322-9cf9-44ad-af0b-2be7e76c0c5d'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5.0::numeric),
    ('348622c5-c7e7-4ef6-a2ea-e5a49881bd42'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2.0::numeric),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2.0::numeric),
    ('c70f5297-a176-43b0-b9dd-19c053dfd458'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1.0::numeric),
    ('b15b9b17-3585-4d13-bad4-564afe05d839'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4.0::numeric),
    ('1643942c-47f2-4156-a1d1-c12f3d3f0039'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4.0::numeric),
    ('2dc05537-1ba1-4f16-9bc1-fd5564c18be5'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 1.0::numeric),
    ('69b5322a-cc38-4e55-838c-b08bb80fbcd1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 5.0::numeric),
    ('574974b3-b91a-4ea5-b5b0-560663e56ef9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2.0::numeric),
    ('c924abea-3bdf-49af-98cc-7d117cb54ad1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2.0::numeric),
    ('fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2.0::numeric),
    ('4f67e1b7-3f4d-4aef-b806-904555a7aee4'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 4.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1.0::numeric),
    ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 5.0::numeric),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2.0::numeric),
    ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 2.0::numeric),
    ('7f51d769-116d-458c-9c60-76aed2c135cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3.0::numeric),
    ('6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2.0::numeric),
    ('3accdf38-2590-48d3-bb0c-d89f24aeec4a'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 4.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 3.0::numeric),
    ('aef06c48-6403-46eb-bd83-3b638f59ef8e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1.0::numeric),
    ('870437b0-1498-4def-835f-966ad989e9e1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 3.0::numeric),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 3.0::numeric),
    ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 3.0::numeric),
    ('b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 5.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5.0::numeric),
    ('5fc487bf-4359-40f3-9aab-11dd94791dc1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 5.0::numeric),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 3.0::numeric),
    ('1b857086-aa3c-426d-9b88-fb445df8ac6d'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 3.0::numeric),
    ('95f2c68c-03d0-45c6-bfe4-8fc971d6f96b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2.0::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2.0::numeric),
    ('89604caf-b2c6-4f3a-84a5-bcefcf1aa04e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1.0::numeric)
  )
  SELECT count(*) INTO n FROM want w
    JOIN inform.politician_answers a ON a.politician_id = w.pid AND a.topic_id = w.tid
     AND a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND a.value = w.oldval;
  IF n <> 93 THEN
    RAISE EXCEPTION 'migration 1914: Season 1 was altered - % of 93 rows intact', n;
  END IF;

  RAISE NOTICE 'migration 1914 OK: 100 Season 2 rows (36 blanks), Season 1 intact';
END $post$;
