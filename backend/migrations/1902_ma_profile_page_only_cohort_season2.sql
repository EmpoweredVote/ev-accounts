-- 1902_ma_profile_page_only_cohort_season2.sql
-- The Massachusetts profile-page-only cohort. 219 keys written: 68 citation repairs + 151 blanks.
-- 10 further keys are BLOCKED -- all on `immigration`, which has no Season 2 pin.
--
-- 🔴 WHY A FORWARD WRITE. Season 1 is CLOSED and IMMUTABLE. A blank is `value 0` INSERTED into
-- the OPEN season, never a DELETE -- a deleted Season 2 row falls back to Season 1 and the bad
-- chair stays visible (CC_0057). Every row written CARRIES THE SOURCES IT EXAMINED (mig 1887).
--
-- ══ WHAT THIS COHORT IS ══════════════════════════════════════════════════════════════════════
-- Measured fresh against production: 229 voter-visible, still-seated keys across 79 legislators
-- whose ONLY source is a malegislature.gov roster page -- no bill, no roll call, nothing else.
-- (The recorded backlog said "232 / 74". Re-measured rather than inherited.)
--
-- 🔑 THE MARYLAND RULE GOVERNED THE WHOLE PASS. A roster page LISTS THE MEMBER'S OWN BILLS, so
-- the URL being a roster page does not make the row false -- in Maryland 70% of the equivalent
-- class carried a verified sponsorship and the right fix was a CITATION REPAIR, not retirement
-- (mig 1898). This was therefore run as a REPAIR QUEUE and the blanks had to earn themselves.
-- Massachusetts turns out weaker than Maryland -- 30% repairable rather than 70% -- and the
-- reason is visible in the classes below: much of this cohort is characterisation, committee
-- seats and party inference rather than mis-cited evidence.
--
-- ══ THE EVIDENCE BASE BUILT FOR IT ═══════════════════════════════════════════════════════════
-- * EVERY MEMBER'S OWN BILL LIST, per General Court, 191st-194th: 79 members, 60,757 bill rows.
--   🔑 THE ENDPOINT LOOKS BROKEN AND IS NOT. `/Legislators/Profile/<code>/<court>/Bills/Sponsored`
--   and `.../Cosponsored` are CLIENT-SIDE tabs: plain GETs on both return byte-identical pages,
--   so the lists read as one short mixed list and an earlier note called them truncated. They
--   need `?isUpdate=True` AND `X-Requested-With: XMLHttpRequest`. With both, the lists separate
--   and are complete -- verified against 32 cosponsorships known independently from the bills'
--   own /Cosponsor pages: 32 of 32 present.
-- * TEN VERIFIED ROLL CALLS, each parsed and checked against the PDF's own declared totals.
--   🔑 A CONSTITUTIONAL CONVENTION IS A THIRD DOCUMENT SHAPE. The Fair Share Amendment vote of
--   9 June 2021 is a JOINT session: one sheet, 200 names, and each of YEAS./NAYS. split again
--   into "Senators." and "Representatives." with its own count. Summing those sub-tallies gives
--   159-41 and matches the bill history; taking the last one gives 121-39, the House half alone,
--   which reads as a parser failure on a correct parse.
--
-- ══ THE VERDICTS ═════════════════════════════════════════════════════════════════════════════
--   REPAIRS (68) -- the chair is kept and the citation is pointed at the instrument
--     22 VOTE_CONFIRMED             voted as the row says, on a verified and DIVIDED roll call
--     16 ACT_SPONSORSHIP_CONFIRMED  on a real filing of the act the row names by its popular name
--     13 SPONSORSHIP_CONFIRMED      the bill number the row gives is on the member's own list
--     10 SPONSORSHIP_MATCHED        the row describes a bill without naming it; matched on the list
--      7 DISSENT_CONFIRMED          voted NAY and the row says so -- dissent IS distinctive
--   BLANKS (151)
--     56 NO_INSTRUMENT              characterisation, district colour and party. Nothing to check.
--     19 RESTATES_RUNG              quotes the rung back as its own evidence, or infers from party
--     17 COMMITTEE_SEAT_ONLY        a seat is not a position; a CAUSE caucus would be
--     15 SPONSORSHIP_NOT_FOUND      asserts a sponsorship; nothing on the member's own lists matches
--     12 OMNIBUS_AND_NOT_DISTINCTIVE  see the MBTA Communities note below
--     10 LADDER_SCOPE               true, and no Season 2 rung can hold it (see below)
--     10 NOT_DISTINCTIVE            real vote, near-unanimous
--      4 BILL_NOT_THE_MEMBERS       the number is on none of this member's lists in any court
--      3 NOT_ON_THE_ROLL_CALL       presiding officer or absent; no vote recorded
--      2 NOT_SERVING                impossible, not merely unsupported
--      2 INVERTED_VOTE              the record says the opposite
--      1 NON_SPONSORSHIP            reasons from an absent signature
--
-- ══ 🔴🔴 TWO ROWS STATE THE OPPOSITE OF THE RECORD ════════════════════════════════════════════
-- * Kimberly N. Ferguson / climate-change, chair 4: "voted against the 2021 Climate Act (H.4933)".
--   H.4933 is not a climate bill in ANY General Court (in the 193rd it concerns notices to people
--   aged 55 and over; in the 191st and 192nd it does not exist). The 2021 climate act is S.9, and
--   SHE VOTED YEA -- House roll call #2, 144-14, and she is not among the fourteen.
-- * Patrick M. O'Connor / taxes, chair 2: "has opposed the 2022 millionaires surtax (Question 1)".
--   HE VOTED YEA to advance it -- joint session roll call #48, 159-41, exactly one O'Connor on the
--   sheet. ⚠ Voting to put a question to the voters and then opposing it at the ballot are not
--   strictly contradictory, but the row cites a BALLOT QUESTION, on which no legislator casts a
--   vote at all, and the only legislative record contradicts the direction it asserts.
--
-- ══ 🔴🔴 FOUR ROWS CREDIT A MEMBER WITH A BILL THAT IS NOT THEIRS ═════════════════════════════
-- The Maryland COMPOSED-CITATION class (mig 1898) is present here too -- a real bill number
-- welded to a subject it does not have:
--   * Ryan / local-environment: "H.4162 (environmental justice equity provisions)". H.4162 is a
--     Stockbridge treasurer (190th), a foster parents' bill of rights (191st), protecting workers
--     (192nd), disabled-veteran property tax (193rd) and ostomy care (194th). None is his.
--   * Gallagher / taxes: "H.5525 (tax exemption for veterans clubs)" is pension benefits for one
--     named firefighter, and is not his.
--   🔑 AND THE SUBTLER HALF, exactly as Maryland found: Rodrigues / campaign-finance cites S.507
--     "on campaign finance reporting improvements for ballot question committees" -- and 194/S507
--     REALLY IS that bill, correctly described. He is simply not on it: its Cosponsors page names
--     eleven senators and he is not among them. The citation is right and the ATTRIBUTION is false,
--     which is the hardest version to catch because everything checkable checks out.
--
-- ══ ⚠ TWO ACTS CHECKED RATHER THAN ASSUMED, AND NEITHER CAN SEAT A CHAIR ══════════════════════
-- * MBTA COMMUNITIES (12 rows). It is SECTION 18 of H.5250, "An Act enabling partnerships for
--   growth" -- a large economic-development omnibus, Chapter 358 of the Acts of 2020. A vote on
--   it is not a vote on zoning, and the vote could not seat a chair anyway: House 143-4,
--   Senate 40-0. This is the Maryland BOOST reasoning (an omnibus discriminates nothing).
-- * MENTAL HEALTH PARITY (part of the 10 NOT_DISTINCTIVE). Chapter 177 of 2022, S.3097: the
--   Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so
--   for a Representative there is no recorded individual position at all.
--
-- ══ 🔴 THE LADDER-SCOPE BLANKS (10) ═══════════════════════════════════════════════════════════
-- A repair keeps the chair, and in Season 2 that is not automatic. 57 carried chairs sit on a
-- rung whose text is character-for-character identical; three rewordings were read in full and
-- carried (civil-rights 1, where Season 2 DROPPED "and provide reparations" and so asks for
-- strictly less; deportation 1, "residents" -> "immigrants"; economic-development 2, reworded
-- without changing the claim). Four were not carried, because the Season 2 rung asks a DIFFERENT
-- QUESTION, and those rows are blanked with the finding preserved:
--   climate-change 1/2/3  Season 1 graded SPEED AND COMPULSION ("declare a climate emergency and
--                         ban all activities that increase carbon emissions"); Season 2 grades
--                         MECHANISM ("Fund clean energy with major subsidies, tax credits and
--                         public investment"). Wanting faster decarbonisation does not say which
--                         mechanism you prefer.
--   voting-rights 2       ballot ACCESS became VOTER IDENTIFICATION -- the same replacement that
--                         forced 14 ladder-scope blanks in migration 1900.
--   school-vouchers 1     Season 1 was a conjunction including public-school FUNDING; Season 2
--                         keeps only the voucher half. Already in the register from Maryland.
--   childcare 4           Season 1 graded DEREGULATION; Season 2 grades MEANS-TESTING.
--
-- ══ ⚠ FIVE PASSES, EACH RESCUING ROWS THE LAST WOULD HAVE BLANKED ═════════════════════════════
-- Recorded because the PATTERN is the lesson -- it is the same shape as Maryland's four passes.
--   1. Clause splitting broke on the period INSIDE a bill number: "Co-sponsored H.1937 (further
--      regulating bail process)" split into the clause "Co-sponsored H", so the whole subject was
--      thrown away and the row scored zero.
--   2. The member's OWN SURNAME is in every one of their petition descriptions ("By Representative
--      Ryan of Boston"), so it matched all their bills and scored a perfect 1.0 on clauses that
--      said nothing else. A false-match generator, the worst kind here.
--   3. Coverage scoring under-matched long claims. Shand's "flood risk, wetlands restoration, and
--      water quality monitoring (Merrimack River Collaborative)" hit merrimack + river + quality +
--      water + collaborative on exactly the right bill and still scored 0.28. Four distinctive
--      words together are not a coincidence; a fraction of a long sentence is.
--   4. A POPULAR ACT NAME WILL NEVER PARAPHRASE-MATCH: a petition description states the bill's
--      SUBJECT ("relative to healthy youth"), never its campaign name. Resolving the name to its
--      filings in every court first rescued 13 rows, five of them from NO_INSTRUMENT.
--   5. A PROFILE'S COURT LIST COVERS ONE CHAMBER. Ten of these 79 have two profiles; reading only
--      the current one declared Fernandes and Driscoll absent from a vote they cast as
--      Representatives. 🔑 AND COURT-LEVEL TENURE IS TOO COARSE FOR A DATED VOTE: Lydia Edwards
--      served in the 192nd but won a special election in 2022, so she is correctly absent from the
--      192nd's June 2021 roll call and present on its June 2022 one.
--
-- ══ 🔴 10 KEYS CANNOT BE WRITTEN ══════════════════════════════════════════════════════════════
-- All 10 sit on `immigration`, which has NO Season 2 pin. Running total of defective chairs
-- unfixable for this reason: migs 1896 (3) + 1897 (3) + 1898 (20) + 1899 (4) + 1900 (71) +
-- 1902 (10) = 111.
--
-- ══ RESOLVED IN PASSING ══════════════════════════════════════════════════════════════════════
-- The WORK AND FAMILY MOBILITY ACT, which migration 1900 recorded as "correct bill NOT yet
-- identified" against 54 citations, is filed as 191/H3012 · 191/S2061 · 191/S2641 · 192/H4461 ·
-- 192/H4470 · 192/H4805 · 192/S2851 · 192/S2872. Those rows remain blocked on `immigration`, but
-- the bill no longer needs finding.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local.

DO $pre$
DECLARE n integer;
BEGIN
  -- 1. the Season 1 cohort, as (politician, topic, value) TRIPLES
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND (a.politician_id, a.topic_id, a.value) IN (
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 2),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 1),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 1),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 1),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 5),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 4),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 4),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 1),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 2),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 2),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1)
  );
  IF n <> 219 THEN
    RAISE EXCEPTION 'migration 1902: expected 219 Season 1 rows at their recorded chairs, found %', n;
  END IF;

  -- 2. keys we INSERT must have no Season 2 row yet
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid)
  );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1902: % Season 2 rows already exist for the insert keys', n;
  END IF;

  -- 3. keys we UPDATE must already have one
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid)
  );
  IF n <> 22 THEN
    RAISE EXCEPTION 'migration 1902: expected 22 existing Season 2 rows, found %', n;
  END IF;

  -- 4. THE CARRY GATE, re-asserted: every chair kept goes into a Season 2 rung whose TEXT
  --    still says what the Season 1 rung said, or one of three rewords read in full and
  --    named here so the exemption is auditable.
  SELECT count(*) INTO n FROM (VALUES
    ('0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1),
    ('48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 2),
    ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
    ('c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 4),
    ('c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4)
  ) AS k(tid, val)
  JOIN inform.season_questions q1 ON q1.topic_id = k.tid AND q1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
  JOIN inform.season_questions q2 ON q2.topic_id = k.tid AND q2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
  JOIN inform.compass_stance_revisions r1 ON r1.topic_revision_id = q1.topic_revision_id AND r1.value = k.val
  JOIN inform.compass_stance_revisions r2 ON r2.topic_revision_id = q2.topic_revision_id AND r2.value = k.val
  JOIN inform.compass_topics t ON t.id = k.tid
  WHERE r1.text IS DISTINCT FROM r2.text
    AND (t.topic_key, k.val) NOT IN (('civil-rights', 1), ('deportation', 1),
                                     ('economic-development', 2));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1902: % carried chairs sit on a Season 2 rung whose text has changed', n;
  END IF;

  -- 5. `immigration` must still have NO Season 2 pin; if it gains one the 10 blocked keys
  --    below become writable and must be revisited.
  SELECT count(*) INTO n FROM inform.season_questions sq
    JOIN inform.compass_topics t ON t.id = sq.topic_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND t.topic_key = 'immigration';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1902: immigration now HAS a Season 2 pin (%) -- the blocked keys are writable, revisit', n;
  END IF;
END
$pre$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
VALUES
  -- Aaron Michlewitz / redistricting  (chair 4 -> 0, NON_SPONSORSHIP)
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 AN ABSENT SIGNATURE IS NOT A POSITION. The row reasons from an ABSENT signature -- the member NOT having co-sponsored something, or not appearing in a third-party tracker. An absent signature is not a vote against; a YES endorses, a NO only rejects, and an unsigned line says nothing at all. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AMM1']::text[]),
  -- Aaron Michlewitz / school-vouchers  (chair 2 -> 0, NO_INSTRUMENT)
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AMM1']::text[]),
  -- Aaron Michlewitz / transportation-priorities  (chair 2 -> 0, NO_INSTRUMENT)
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AMM1']::text[]),
  -- Adrianne P. Ramos / abortion  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Adrianne P. Ramos is on 2 of the 4 filings of Abortion Access Act -- 193/H1599, 194/H1815 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/H1599', 'https://malegislature.gov/Bills/193/H1599/Cosponsor', 'https://malegislature.gov/Bills/194/H1815/Cosponsor', 'https://malegislature.gov/Legislators/Profile/APR1']::text[]),
  -- Adrianne P. Ramos / civil-rights  (chair 1 -> 1, SPONSORSHIP_CONFIRMED)
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Adrianne P. Ramos is on H1940, H1942 in the member''s own Sponsored/Cosponsored list (H1940 in the 194/H1940, H1942 in the 194/H1942). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/H498', 'https://malegislature.gov/Bills/194/H1940/H1940', 'https://malegislature.gov/Bills/194/H1942/H1942', 'https://malegislature.gov/Legislators/Profile/APR1/Committees']::text[]),
  -- Adrianne P. Ramos / climate-change  (chair 2 -> 0, LADDER_SCOPE)
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Adrianne P. Ramos is on H3547 in the member''s own Sponsored/Cosponsored list (H3547 in the 194/H3547). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 graded SPEED AND COMPULSION, Season 2 grades MECHANISM. Season 1: "rapidly transition to renewable energy and phase out fossil fuels by 2030" Season 2: "Fund clean energy with major subsidies, tax credits, and public investment." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/APR1/Bills']::text[]),
  -- Adrianne P. Ramos / healthcare  (chair 2 -> 2, ACT_SPONSORSHIP_CONFIRMED)
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Adrianne P. Ramos is on 1 of the 6 filings of Cherish Act -- 193/H1260 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/H1260/Cosponsor', 'https://malegislature.gov/Bills/193/H497', 'https://malegislature.gov/Legislators/Profile/APR1']::text[]),
  -- Amy M. Sangiolo / civil-rights  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AMS3/Committees']::text[]),
  -- Amy M. Sangiolo / jail-capacity  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Amy M. Sangiolo is on H1984, H1985 in the member''s own Sponsored/Cosponsored list (H1984 in the 194/H1984, H1985 in the 194/H1985). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/H1984/H1984', 'https://malegislature.gov/Bills/194/H1985/H1985', 'https://malegislature.gov/Legislators/Profile/AMS3/Bills']::text[]),
  -- Amy M. Sangiolo / taxes  (chair 3 -> 0, RESTATES_RUNG)
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AMS3', 'https://malegislature.gov/Legislators/Profile/AMS3/Bills']::text[]),
  -- Amy M. Sangiolo / voting-rights  (chair 2 -> 0, RESTATES_RUNG)
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AMS3', 'https://malegislature.gov/Legislators/Profile/AMS3/Bills']::text[]),
  -- Angelo J. Puppolo / fossil-fuels  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Angelo J. Puppolo is on H3406 in the member''s own Sponsored/Cosponsored list (H3406 in the 194/H3406). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/H3406/H3406', 'https://malegislature.gov/Legislators/Profile/AJP1/Bills']::text[]),
  -- Angelo J. Puppolo / jail-capacity  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Angelo J. Puppolo is on H1937 in the member''s own Sponsored/Cosponsored list (H1937 in the 194/H1937). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/H1937/H1937', 'https://malegislature.gov/Legislators/Profile/AJP1/Bills']::text[]),
  -- Angelo J. Puppolo / school-vouchers  (chair 1 -> 0, LADDER_SCOPE)
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Angelo J. Puppolo is on 6 of the 6 filings of Cherish Act -- 191/H1214, 191/S741, 192/H1325, 192/S824, 193/H1260, 193/S816 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 was a conjunction including public-school FUNDING; Season 2 keeps only the voucher half. Season 1: "Fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions" Season 2: "Eliminating voucher programs that divert taxpayer money from public schools to private institutions" The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/AJP1/Bills']::text[]),
  -- Bradley H. Jones / climate-change  (chair 3 -> 0, LADDER_SCOPE)
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Bradley H. Jones is on H3512, H3535, H974 in the member''s own Sponsored/Cosponsored list (H3512 in the 194/H3512, H3535 in the 194/H3535, H974 in the 194/H974). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 graded SPEED AND COMPULSION, Season 2 grades MECHANISM. Season 1: "invest in clean energy while gradually reducing reliance on fossil fuels" Season 2: "Speed up clean energy by cutting permitting red tape and upgrading the grid." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BHJ1/Bills']::text[]),
  -- Bradley H. Jones / fossil-fuels  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Bradley H. Jones is on H3512, H3535 in the member''s own Sponsored/Cosponsored list (H3512 in the 194/H3512, H3535 in the 194/H3535). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/H3512', 'https://malegislature.gov/Bills/194/H3512/H3512', 'https://malegislature.gov/Bills/194/H3535/H3535', 'https://malegislature.gov/Legislators/Profile/BHJ1/Bills']::text[]),
  -- Brendan P. Crighton / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Brendan P. Crighton voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Brian M. Ashe / economic-development  (chair 3 -> 0, COMMITTEE_SEAT_ONLY)
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BMA1/Committees']::text[]),
  -- Brian W. Murray / economic-development  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BWM1', 'https://malegislature.gov/Legislators/Profile/BWM1/Bills']::text[]),
  -- Brian W. Murray / healthcare  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BWM1', 'https://malegislature.gov/Legislators/Profile/BWM1/Bills']::text[]),
  -- Bruce E. Tarr / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]),
  -- Bruce E. Tarr / fossil-fuels  (chair 3 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]),
  -- Bruce E. Tarr / healthcare  (chair 3 -> 0, NOT_DISTINCTIVE)
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]),
  -- Bruce E. Tarr / redistricting  (chair 4 -> 4, SPONSORSHIP_MATCHED)
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Bruce E. Tarr really is a cosponsored of 191/H679, which the row describes without naming: "He has advocated for an independent redistricting commission and filed legislation to reform the process". Matched on the member''s own bill list (overlap 0.60 on commission, independent, redistricting). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H679', 'https://malegislature.gov/Legislators/Profile/BET0']::text[]),
  -- Bruce E. Tarr / taxes  (chair 2 -> 0, NO_INSTRUMENT)
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]),
  -- Bruce E. Tarr / transportation-priorities  (chair 3 -> 0, NO_INSTRUMENT)
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]),
  -- Carole A. Fiola / economic-development  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/CAF1']::text[]),
  -- Christopher J. Worrell / transportation-priorities  (chair 1 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/CJW1']::text[]),
  -- Daniel J. Ryan / local-environment  (chair 2 -> 0, BILL_NOT_THE_MEMBERS)
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE CITED BILL IS NOT THIS MEMBER''S. The row credits Daniel J. Ryan with H4162. That number is on none of this member''s Sponsored or Cosponsored lists in any General Court they served. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DJR1']::text[]),
  -- Daniel M. Donahue / economic-development  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Daniel M. Donahue really is a cosponsored of 191/H177, which the row describes without naming: "He has co-sponsored economic development legislation in the 194th General Court focused on community investmen". Matched on the member''s own bill list (overlap 0.40 on community, development, economic, urban). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H177', 'https://malegislature.gov/Legislators/Profile/DMD1', 'https://malegislature.gov/Legislators/Profile/DMD1/Bills']::text[]),
  -- Daniel M. Donahue / healthcare  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Daniel M. Donahue really is a cosponsored of 192/H1114, which the row describes without naming: "Donahue has co-sponsored healthcare expansion legislation in the MA House, supporting MassHealth coverage expa". Matched on the member''s own bill list (overlap 0.38 on coverage, health, mental). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/H1114', 'https://malegislature.gov/Legislators/Profile/DMD1', 'https://malegislature.gov/Legislators/Profile/DMD1/Bills']::text[]),
  -- David A. LeBoeuf / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DAL1', 'https://malegislature.gov/Legislators/Profile/DAL1/Bills']::text[]),
  -- David A. LeBoeuf / economic-development  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: David A. LeBoeuf really is a cosponsored of 191/H177, which the row describes without naming: "He has co-sponsored economic development legislation in the 194th General Court with a community-centered inve". Matched on the member''s own bill list (overlap 0.40 on development, economic). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H177', 'https://malegislature.gov/Legislators/Profile/DAL1', 'https://malegislature.gov/Legislators/Profile/DAL1/Bills']::text[]),
  -- David A. LeBoeuf / healthcare  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: David A. LeBoeuf is on 6 of the 14 filings of Medicare for All -- 191/H1194, 191/S683, 192/H1267, 193/H1239, 194/H1405, 194/H5590 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H1194/Cosponsor', 'https://malegislature.gov/Bills/191/S683/Cosponsor', 'https://malegislature.gov/Bills/192/H1267/Cosponsor', 'https://malegislature.gov/Legislators/Profile/DAL1', 'https://malegislature.gov/Legislators/Profile/DAL1/Bills']::text[]),
  -- David K. Muradian / taxes  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: David K. Muradian voted NAY on the Fair Share Amendment (the 4% surtax) and the row says so -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. Dissent from a 80% majority is distinctive. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/DKM1', 'https://malegislature.gov/Legislators/Profile/DKM1/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- David P. Linsky / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: David P. Linsky voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/DPL1/Committees', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Dawne Shand / childcare  (chair 1 -> 0, SPONSORSHIP_NOT_FOUND)
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/D_S1/Committees']::text[]),
  -- Dawne Shand / climate-change  (chair 3 -> 0, LADDER_SCOPE)
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Dawne Shand really is a sponsored of 194/H1053, which the row describes without naming: "Sponsored legislation on flood risk, wetlands restoration, and water quality monitoring (Merrimack River Colla". Matched on the member''s own bill list (overlap 0.28 on collaborative, merrimack, quality, river, water). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 graded SPEED AND COMPULSION, Season 2 grades MECHANISM. Season 1: "invest in clean energy while gradually reducing reliance on fossil fuels" Season 2: "Speed up clean energy by cutting permitting red tape and upgrading the grid." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/D_S1']::text[]),
  -- Dawne Shand / healthcare  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Dawne Shand really is a cosponsored of 193/H938, which the row describes without naming: "Shand co-sponsored the THRIVE Act (Act on Mass), which supports expanded social and healthcare services". Matched on the member''s own bill list (overlap 0.40 on healthcare, services). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/H938', 'https://malegislature.gov/Legislators/Profile/D_S1/Committees']::text[]),
  -- Dennis C. Gallagher / abortion  (chair 2 -> 0, RESTATES_RUNG)
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DCG2', 'https://malegislature.gov/Legislators/Profile/DCG2/Bills']::text[]),
  -- Dennis C. Gallagher / climate-change  (chair 3 -> 0, RESTATES_RUNG)
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DCG2', 'https://malegislature.gov/Legislators/Profile/DCG2/Bills']::text[]),
  -- Dennis C. Gallagher / fossil-fuels  (chair 3 -> 0, RESTATES_RUNG)
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DCG2', 'https://malegislature.gov/Legislators/Profile/DCG2/Bills']::text[]),
  -- Dennis C. Gallagher / taxes  (chair 3 -> 0, BILL_NOT_THE_MEMBERS)
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE CITED BILL IS NOT THIS MEMBER''S. The row credits Dennis C. Gallagher with H5525. That number is on none of this member''s Sponsored or Cosponsored lists in any General Court they served. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DCG2/Bills']::text[]),
  -- Donald R. Berthiaume / taxes  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Donald R. Berthiaume voted NAY on the Fair Share Amendment (the 4% surtax) and the row says so -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. Dissent from a 80% majority is distinctive. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/DRB1', 'https://malegislature.gov/Legislators/Profile/DRB1/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Dylan A. Fernandes / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]),
  -- Dylan A. Fernandes / fossil-fuels  (chair 1 -> 0, NO_INSTRUMENT)
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]),
  -- Dylan A. Fernandes / local-environment  (chair 1 -> 0, NO_INSTRUMENT)
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]),
  -- Dylan A. Fernandes / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Dylan A. Fernandes voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Edward R. Philips / climate-change  (chair 3 -> 0, SPONSORSHIP_NOT_FOUND)
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/ERP1/Bills']::text[]),
  -- Edward R. Philips / voting-rights  (chair 2 -> 0, LADDER_SCOPE)
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Edward R. Philips really is a sponsored of 193/H3899, which the row describes without naming: "Sponsored legislation allowing voting rights for permanent resident aliens in the town of Sharon — a notably p". Matched on the member''s own bill list (overlap 0.67 on aliens, local, permanent, resident, rights, sharon). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 was ballot ACCESS, Season 2 is VOTER IDENTIFICATION. Season 1: "expand early voting periods and make mail-in voting available to all voters without requiring an excuse" Season 2: "Accept non-photo identification, such as a utility bill or bank statement." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/ERP1/Bills']::text[]),
  -- Francisco E. Paulino / climate-change  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/FEP1', 'https://malegislature.gov/Legislators/Profile/FEP1/Committees']::text[]),
  -- Greg Schwartz / civil-rights  (chair 3 -> 0, RESTATES_RUNG)
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/G_S1', 'https://malegislature.gov/Legislators/Profile/G_S1/Bills']::text[]),
  -- Greg Schwartz / climate-change  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/G_S1/Committees']::text[]),
  -- Greg Schwartz / economic-development  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/G_S1/Committees']::text[]),
  -- Greg Schwartz / jail-capacity  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Greg Schwartz is on H1955 in the member''s own Sponsored/Cosponsored list (H1955 in the 194/H1955). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/H1955/H1955', 'https://malegislature.gov/Legislators/Profile/G_S1', 'https://malegislature.gov/Legislators/Profile/G_S1/Bills']::text[]),
  -- Greg Schwartz / taxes  (chair 3 -> 0, RESTATES_RUNG)
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/G_S1', 'https://malegislature.gov/Legislators/Profile/G_S1/Bills']::text[]),
  -- Greg Schwartz / voting-rights  (chair 2 -> 0, RESTATES_RUNG)
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/G_S1', 'https://malegislature.gov/Legislators/Profile/G_S1/Bills']::text[]),
  -- Hadley Luddy / abortion  (chair 3 -> 0, NO_INSTRUMENT)
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/H_L1', 'https://malegislature.gov/Legislators/Profile/H_L1/Bills']::text[]),
  -- Hadley Luddy / healthcare  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Hadley Luddy is on H2489, H5188 in the member''s own Sponsored/Cosponsored list (H2489 in the 194/H2489, H5188 in the 194/H5188). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/H1405/Cosponsor', 'https://malegislature.gov/Bills/194/H2489', 'https://malegislature.gov/Bills/194/H2489/H2489', 'https://malegislature.gov/Bills/194/H5188/H5188', 'https://malegislature.gov/Bills/194/H5590/Cosponsor', 'https://malegislature.gov/Legislators/Profile/H_L1', 'https://malegislature.gov/Legislators/Profile/H_L1/Bills']::text[]),
  -- Hannah E. Kane / climate-change  (chair 3 -> 0, NO_INSTRUMENT)
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HEK1', 'https://malegislature.gov/Legislators/Profile/HEK1/Bills']::text[]),
  -- Hannah E. Kane / economic-development  (chair 3 -> 0, NO_INSTRUMENT)
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HEK1', 'https://malegislature.gov/Legislators/Profile/HEK1/Bills']::text[]),
  -- Hannah E. Kane / healthcare  (chair 3 -> 0, NO_INSTRUMENT)
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HEK1', 'https://malegislature.gov/Legislators/Profile/HEK1/Bills']::text[]),
  -- Hannah E. Kane / taxes  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Hannah E. Kane voted NAY on the Fair Share Amendment (the 4% surtax) and the row says so -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. Dissent from a 80% majority is distinctive. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/HEK1', 'https://malegislature.gov/Legislators/Profile/HEK1/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Hannah L. Bowen / civil-rights  (chair 2 -> 0, RESTATES_RUNG)
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Bills']::text[]),
  -- Hannah L. Bowen / climate-change  (chair 2 -> 0, LADDER_SCOPE)
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Hannah L. Bowen is on H4568 in the member''s own Sponsored/Cosponsored list (H4568 in the 194/H4568). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 graded SPEED AND COMPULSION, Season 2 grades MECHANISM. Season 1: "rapidly transition to renewable energy and phase out fossil fuels by 2030" Season 2: "Fund clean energy with major subsidies, tax credits, and public investment." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Bills']::text[]),
  -- Hannah L. Bowen / fossil-fuels  (chair 2 -> 0, RESTATES_RUNG)
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Bills']::text[]),
  -- Hannah L. Bowen / taxes  (chair 2 -> 0, RESTATES_RUNG)
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Bills']::text[]),
  -- Hannah L. Bowen / transportation-priorities  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Committees']::text[]),
  -- Hannah L. Bowen / voting-rights  (chair 2 -> 0, RESTATES_RUNG)
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Bills']::text[]),
  -- James J. O'Day / healthcare  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JJO1', 'https://malegislature.gov/Legislators/Profile/JJO1/Bills']::text[]),
  -- James K. Hawkins / transportation-priorities  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JKH1']::text[]),
  -- Jason M. Lewis / childcare  (chair 1 -> 1, SPONSORSHIP_MATCHED)
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Jason M. Lewis really is a cosponsored of 192/S2883, which the row describes without naming: "He backed the major early education funding increases in the FY2024 and FY2025 budgets and has filed legislati". Matched on the member''s own bill list (overlap 0.42 on affordable, childcare, early, education, families). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/S2883', 'https://malegislature.gov/Legislators/Profile/jml0']::text[]),
  -- Jason M. Lewis / fossil-fuels  (chair 1 -> 0, NO_INSTRUMENT)
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]),
  -- Jason M. Lewis / healthcare  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Jason M. Lewis is on 5 of the 14 filings of Medicare for All -- 191/S683, 192/H1267, 192/S766, 193/S744, 194/S860 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/S683/Cosponsor', 'https://malegislature.gov/Bills/192/H1267/Cosponsor', 'https://malegislature.gov/Bills/192/S766/Cosponsor', 'https://malegislature.gov/Legislators/Profile/jml0']::text[]),
  -- Jason M. Lewis / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Jason M. Lewis voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Jason M. Lewis / transportation-priorities  (chair 1 -> 0, NO_INSTRUMENT)
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]),
  -- Jeffrey R. Turco / transportation-priorities  (chair 3 -> 0, NO_INSTRUMENT)
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JRT1']::text[]),
  -- Joan B. Lovely / childcare  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]),
  -- Joan B. Lovely / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]),
  -- Joan B. Lovely / healthcare  (chair 2 -> 0, NOT_DISTINCTIVE)
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]),
  -- Joan B. Lovely / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Joan B. Lovely voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- John C. Velis / healthcare  (chair 1 -> 0, NO_INSTRUMENT)
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JCV0']::text[]),
  -- John F. Keenan / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JFK0']::text[]),
  -- John F. Keenan / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: John F. Keenan voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/JFK0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- John F. Keenan / transportation-priorities  (chair 2 -> 0, NO_INSTRUMENT)
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JFK0']::text[]),
  -- John J. Mahoney / economic-development  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JJM2', 'https://malegislature.gov/Legislators/Profile/JJM2/Bills']::text[]),
  -- John J. Mahoney / healthcare  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JJM2', 'https://malegislature.gov/Legislators/Profile/JJM2/Bills']::text[]),
  -- John J. Marsi / taxes  (chair 4 -> 0, NOT_SERVING)
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE MEMBER WAS NOT THERE. John J. Marsi does not appear on the roll call for the Fair Share Amendment (the 4% surtax) (Joint roll call #48, Constitutional Convention, 9 June 2021): NOT ON THE ROLL CALL. The member was not in the 192 General Court. Serving in a General Court is not the same as being seated for a vote taken inside it -- a member who arrives at a special election is absent from earlier roll calls of the same court. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JJM1', 'https://malegislature.gov/Legislators/Profile/JJM1/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Joseph D. McKenna / taxes  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Joseph D. McKenna voted NAY on the Fair Share Amendment (the 4% surtax) and the row says so -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. Dissent from a 80% majority is distinctive. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/JDM1', 'https://malegislature.gov/Legislators/Profile/JDM1/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Julian A. Cyr / healthcare  (chair 1 -> 0, NOT_DISTINCTIVE)
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JAC0']::text[]),
  -- Julian A. Cyr / local-environment  (chair 1 -> 0, NO_INSTRUMENT)
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/JAC0']::text[]),
  -- Julian A. Cyr / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Julian A. Cyr voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Karen E. Spilka / abortion  (chair 1 -> 1, VOTE_CONFIRMED)
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Karen E. Spilka voted for the ROE Act -- Senate roll call #372 (veto override, 29 Dec 2020), 32-8, a divided vote (80% yea). the ROE Act became law as H.5179, Chapter 263 of 2020; its own bill H.3320 never reached a floor vote. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://malegislature.gov/RollCall/191/SenateRollCall372.pdf']::text[]),
  -- Karen E. Spilka / childcare  (chair 1 -> 0, NO_INSTRUMENT)
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KES0']::text[]),
  -- Karen E. Spilka / healthcare  (chair 1 -> 0, NOT_DISTINCTIVE)
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KES0']::text[]),
  -- Kate Donaghue / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/K_D1', 'https://malegislature.gov/Legislators/Profile/K_D1/Bills']::text[]),
  -- Kate Donaghue / economic-development  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/K_D1', 'https://malegislature.gov/Legislators/Profile/K_D1/Bills']::text[]),
  -- Kate Donaghue / healthcare  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Kate Donaghue really is a sponsored of 193/H1145, which the row describes without naming: "Donaghue has co-sponsored healthcare expansion legislation in the MA House, supporting MassHealth coverage exp". Matched on the member''s own bill list (overlap 0.38 on coverage, health, healthcare). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/H1145', 'https://malegislature.gov/Legislators/Profile/K_D1', 'https://malegislature.gov/Legislators/Profile/K_D1/Bills']::text[]),
  -- Kelly A. Dooner / childcare  (chair 4 -> 0, LADDER_SCOPE)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Kelly A. Dooner is on S175 in the member''s own Sponsored/Cosponsored list (S175 in the 194/S175). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 graded DEREGULATION, Season 2 grades MEANS-TESTING. Season 1: "Reducing regulations on childcare providers to increase supply and lower costs, with limited subsidies reserved for the lowest-income families" Season 2: "Limiting government support to childcare subsidies for the lowest-income families, relying on the private market for everyone else" The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0/Bills']::text[]),
  -- Kelly A. Dooner / fossil-fuels  (chair 4 -> 0, NO_INSTRUMENT)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0/Bills']::text[]),
  -- Kelly A. Dooner / healthcare  (chair 4 -> 0, SPONSORSHIP_NOT_FOUND)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0/Bills']::text[]),
  -- Kelly A. Dooner / jail-capacity  (chair 4 -> 4, SPONSORSHIP_CONFIRMED)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Kelly A. Dooner is on S1666 in the member''s own Sponsored/Cosponsored list (S1666 in the 194/S1666). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/S1666/S1666', 'https://malegislature.gov/Legislators/Profile/KAD0/Bills']::text[]),
  -- Kelly A. Dooner / medicare/aid  (chair 4 -> 0, NO_INSTRUMENT)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0/Bills']::text[]),
  -- Kelly A. Dooner / redistricting  (chair 5 -> 0, NO_INSTRUMENT)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0']::text[]),
  -- Kelly A. Dooner / school-vouchers  (chair 4 -> 0, RESTATES_RUNG)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0/Bills']::text[]),
  -- Kelly A. Dooner / taxes  (chair 2 -> 0, NOT_SERVING)
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE MEMBER WAS NOT THERE. Kelly A. Dooner does not appear on the roll call for the Fair Share Amendment (the 4% surtax) (Joint roll call #48, Constitutional Convention, 9 June 2021): NOT ON THE ROLL CALL. The member was not in the 192 General Court. Serving in a General Court is not the same as being seated for a vote taken inside it -- a member who arrives at a special election is absent from earlier roll calls of the same court. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Kelly W. Pease / economic-development  (chair 4 -> 0, RESTATES_RUNG)
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KWP1/Committees']::text[]),
  -- Kenneth I. Gordon / voting-rights  (chair 2 -> 0, LADDER_SCOPE)
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Kenneth I. Gordon really is a cosponsored of 191/H656, which the row describes without naming: "Gordon co-sponsored same-day voter registration legislation, which would allow eligible voters to register and". Matched on the member''s own bill list (overlap 0.40 on election, registration, voter, voters). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 was ballot ACCESS, Season 2 is VOTER IDENTIFICATION. Season 1: "expand early voting periods and make mail-in voting available to all voters without requiring an excuse" Season 2: "Accept non-photo identification, such as a utility bill or bank statement." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KIG1']::text[]),
  -- Kevin G. Honan / economic-development  (chair 3 -> 0, NO_INSTRUMENT)
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KGH1']::text[]),
  -- Kimberly N. Ferguson / abortion  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Kimberly N. Ferguson voted NAY on the ROE Act and the row says so -- House roll call #374 (veto override, 28 Dec 2020), 107-46. Dissent from a 70% majority is distinctive. the ROE Act became law as H.5179, Chapter 263 of 2020; its own bill H.3320 never reached a floor vote. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/KNF1', 'https://malegislature.gov/RollCall/191/HouseRollCall374.pdf']::text[]),
  -- Kimberly N. Ferguson / climate-change  (chair 4 -> 0, INVERTED_VOTE)
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW STATES THE OPPOSITE OF THE RECORD. The row says Kimberly N. Ferguson opposed the 2021 climate roadmap. The record is the opposite: YEA on House roll call #2 (engrossment, 28 Jan 2021), 144-14. S.9, Chapter 8 of 2021. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KNF1', 'https://malegislature.gov/RollCall/192/HouseRollCall2.pdf']::text[]),
  -- Kimberly N. Ferguson / school-vouchers  (chair 4 -> 0, NO_INSTRUMENT)
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KNF1']::text[]),
  -- Kimberly N. Ferguson / transportation-priorities  (chair 4 -> 0, NO_INSTRUMENT)
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KNF1']::text[]),
  -- Kip A. Diggs / civil-rights  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD1']::text[]),
  -- Kip A. Diggs / economic-development  (chair 2 -> 0, BILL_NOT_THE_MEMBERS)
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE CITED BILL IS NOT THIS MEMBER''S. The row credits Kip A. Diggs with H101. That number is on none of this member''s Sponsored or Cosponsored lists in any General Court they served. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD1']::text[]),
  -- Kip A. Diggs / healthcare  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/KAD1']::text[]),
  -- Leigh S. Davis / climate-change  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LSD1']::text[]),
  -- Leigh S. Davis / voting-rights  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LSD1']::text[]),
  -- Lisa M. Field / childcare  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LMF1']::text[]),
  -- Lisa M. Field / healthcare  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LMF1']::text[]),
  -- Liz Miranda / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]),
  -- Liz Miranda / deportation  (chair 1 -> 0, NO_INSTRUMENT)
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]),
  -- Liz Miranda / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]),
  -- Liz Miranda / public-safety-approach  (chair 1 -> 0, NO_INSTRUMENT)
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]),
  -- Liz Miranda / rent-regulation  (chair 2 -> 2, ACT_SPONSORSHIP_CONFIRMED)
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Liz Miranda is on 3 of the 10 filings of rent stabilization -- 193/S1299, 193/S872, 194/S1447 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/S1299/Cosponsor', 'https://malegislature.gov/Bills/193/S872/Cosponsor', 'https://malegislature.gov/Bills/194/S1447/Cosponsor', 'https://malegislature.gov/Legislators/Profile/L%20M0']::text[]),
  -- Liz Miranda / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Liz Miranda voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Lydia M. Edwards / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]),
  -- Lydia M. Edwards / deportation  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Lydia M. Edwards is on 4 of the 10 filings of Safe Communities Act -- 192/S1579, 193/H2288, 193/S1510, 194/S1681 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/S1579/Cosponsor', 'https://malegislature.gov/Bills/193/H2288/Cosponsor', 'https://malegislature.gov/Bills/193/S1510/Cosponsor', 'https://malegislature.gov/Legislators/Profile/LME0']::text[]),
  -- Lydia M. Edwards / rent-regulation  (chair 2 -> 2, ACT_SPONSORSHIP_CONFIRMED)
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Lydia M. Edwards is on 5 of the 10 filings of rent stabilization -- 192/H1378, 192/S886, 193/H1304, 193/S872, 194/S1447 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/H1378/Cosponsor', 'https://malegislature.gov/Bills/192/S886/Cosponsor', 'https://malegislature.gov/Bills/193/H1304/Cosponsor', 'https://malegislature.gov/Legislators/Profile/LME0']::text[]),
  -- Lydia M. Edwards / taxes  (chair 2 -> 0, NOT_ON_THE_ROLL_CALL)
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ NO VOTE IS RECORDED FOR THIS MEMBER. Lydia M. Edwards does not appear on the roll call for the Fair Share Amendment (the 4% surtax) (Joint roll call #48, Constitutional Convention, 9 June 2021): NOT ON THE ROLL CALL. Serving in a General Court is not the same as being seated for a vote taken inside it -- a member who arrives at a special election is absent from earlier roll calls of the same court. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Lydia M. Edwards / transportation-priorities  (chair 1 -> 0, NO_INSTRUMENT)
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]),
  -- Mark C. Montigny / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]),
  -- Mark C. Montigny / healthcare  (chair 1 -> 0, NOT_DISTINCTIVE)
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]),
  -- Mark C. Montigny / local-environment  (chair 1 -> 0, NO_INSTRUMENT)
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]),
  -- Mark C. Montigny / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Mark C. Montigny voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Mary S. Keefe / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MSK1', 'https://malegislature.gov/Legislators/Profile/MSK1/Bills']::text[]),
  -- Mary S. Keefe / economic-development  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Mary S. Keefe really is a cosponsored of 191/H177, which the row describes without naming: "She has co-sponsored economic development legislation in the 194th General Court focused on community investme". Matched on the member''s own bill list (overlap 0.44 on community, development, economic, urban). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H177', 'https://malegislature.gov/Legislators/Profile/MSK1', 'https://malegislature.gov/Legislators/Profile/MSK1/Bills']::text[]),
  -- Mary S. Keefe / healthcare  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Mary S. Keefe is on 4 of the 14 filings of Medicare for All -- 191/H1194, 191/S683, 194/H1405, 194/H5590 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H1194/Cosponsor', 'https://malegislature.gov/Bills/191/S683/Cosponsor', 'https://malegislature.gov/Bills/194/H1405/Cosponsor', 'https://malegislature.gov/Legislators/Profile/MSK1', 'https://malegislature.gov/Legislators/Profile/MSK1/Bills']::text[]),
  -- Meghan Kilcoyne / economic-development  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/M_K1', 'https://malegislature.gov/Legislators/Profile/M_K1/Bills']::text[]),
  -- Meghan Kilcoyne / healthcare  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Meghan Kilcoyne really is a cosponsored of 192/S2583, which the row describes without naming: "Kilcoyne has co-sponsored healthcare access legislation in the MA House, supporting expanded MassHealth covera". Matched on the member''s own bill list (overlap 0.50 on access, coverage, health, masshealth). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/S2583', 'https://malegislature.gov/Legislators/Profile/M_K1', 'https://malegislature.gov/Legislators/Profile/M_K1/Bills']::text[]),
  -- Michael D. Brady / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MDB0']::text[]),
  -- Michael D. Brady / healthcare  (chair 2 -> 0, NOT_DISTINCTIVE)
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MDB0']::text[]),
  -- Michael D. Brady / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Michael D. Brady voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/MDB0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Michael J. Moran / abortion  (chair 3 -> 3, VOTE_CONFIRMED)
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Michael J. Moran voted for the ROE Act -- House roll call #374 (veto override, 28 Dec 2020), 107-46, a divided vote (70% yea). the ROE Act became law as H.5179, Chapter 263 of 2020; its own bill H.3320 never reached a floor vote. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/MJM1', 'https://malegislature.gov/RollCall/191/HouseRollCall374.pdf']::text[]),
  -- Michael J. Moran / economic-development  (chair 3 -> 0, NO_INSTRUMENT)
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJM1']::text[]),
  -- Michael J. Moran / transportation-priorities  (chair 3 -> 0, NO_INSTRUMENT)
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJM1']::text[]),
  -- Michael J. Rodrigues / campaign-finance  (chair 3 -> 0, BILL_NOT_THE_MEMBERS)
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE CITED BILL IS NOT THIS MEMBER''S. The row credits Michael J. Rodrigues with S507. That number is on none of this member''s Sponsored or Cosponsored lists in any General Court they served. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJR0/BillsSponsored']::text[]),
  -- Michael J. Rodrigues / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]),
  -- Michael J. Rodrigues / healthcare  (chair 2 -> 0, NOT_DISTINCTIVE)
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]),
  -- Michael J. Rodrigues / school-vouchers  (chair 1 -> 0, NO_INSTRUMENT)
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJR0/BillsSponsored']::text[]),
  -- Michael J. Rodrigues / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Michael J. Rodrigues voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Michael J. Rodrigues / transportation-priorities  (chair 2 -> 0, NO_INSTRUMENT)
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]),
  -- Michael J. Soter / taxes  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Michael J. Soter voted NAY on the Fair Share Amendment (the 4% surtax) and the row says so -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. Dissent from a 80% majority is distinctive. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/MJS3', 'https://malegislature.gov/Legislators/Profile/MJS3/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Michael P. Kushmerek / economic-development  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MPK1', 'https://malegislature.gov/Legislators/Profile/MPK1/Bills']::text[]),
  -- Michael P. Kushmerek / healthcare  (chair 2 -> 2, SPONSORSHIP_MATCHED)
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Michael P. Kushmerek really is a cosponsored of 192/H2075, which the row describes without naming: "Kushmerek has co-sponsored healthcare access legislation in the MA House, including bills expanding MassHealth". Matched on the member''s own bill list (overlap 0.44 on access, expanding, health, mental). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/H2075', 'https://malegislature.gov/Legislators/Profile/MPK1', 'https://malegislature.gov/Legislators/Profile/MPK1/Bills']::text[]),
  -- Michael S. Chaisson / economic-development  (chair 3 -> 0, COMMITTEE_SEAT_ONLY)
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/MSC1']::text[]),
  -- Natalie Higgins / civil-rights  (chair 1 -> 0, NO_INSTRUMENT)
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/N_H1', 'https://malegislature.gov/Legislators/Profile/N_H1/Bills']::text[]),
  -- Natalie Higgins / healthcare  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Natalie Higgins is on 5 of the 14 filings of Medicare for All -- 191/H1194, 192/H1267, 193/H1239, 194/H1405, 194/H5590 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H1194/Cosponsor', 'https://malegislature.gov/Bills/192/H1267/Cosponsor', 'https://malegislature.gov/Bills/193/H1239/Cosponsor', 'https://malegislature.gov/Legislators/Profile/N_H1', 'https://malegislature.gov/Legislators/Profile/N_H1/Bills']::text[]),
  -- Natalie Higgins / rent-regulation  (chair 2 -> 2, ACT_SPONSORSHIP_CONFIRMED)
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Natalie Higgins is on 3 of the 10 filings of rent stabilization -- 192/H1378, 193/H2103, 194/H2328 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/H1378/Cosponsor', 'https://malegislature.gov/Bills/193/H2103/Cosponsor', 'https://malegislature.gov/Bills/194/H2328/Cosponsor', 'https://malegislature.gov/Legislators/Profile/N_H1', 'https://malegislature.gov/Legislators/Profile/N_H1/Bills']::text[]),
  -- Nick Collins / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/N_C0']::text[]),
  -- Nick Collins / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Nick Collins voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/N_C0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Nick Collins / transportation-priorities  (chair 2 -> 0, NO_INSTRUMENT)
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/N_C0']::text[]),
  -- Patricia D. Jehlen / healthcare  (chair 1 -> 0, NOT_DISTINCTIVE)
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0']::text[]),
  -- Patricia D. Jehlen / rent-regulation  (chair 2 -> 2, ACT_SPONSORSHIP_CONFIRMED)
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Patricia D. Jehlen is on 6 of the 10 filings of rent stabilization -- 191/H3924, 192/H1378, 193/H1304, 193/S1299, 193/S872, 194/S1447 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H3924/Cosponsor', 'https://malegislature.gov/Bills/192/H1378/Cosponsor', 'https://malegislature.gov/Bills/193/H1304/Cosponsor', 'https://malegislature.gov/Legislators/Profile/PDJ0']::text[]),
  -- Patricia D. Jehlen / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Patricia D. Jehlen voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Patrick M. O'Connor / taxes  (chair 2 -> 0, INVERTED_VOTE)
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW STATES THE OPPOSITE OF THE RECORD. The row says Patrick M. O''Connor opposed the Fair Share Amendment (the 4% surtax). The record is the opposite: YEA on Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Paul K. Frost / taxes  (chair 4 -> 4, DISSENT_CONFIRMED)
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Paul K. Frost voted NAY on the Fair Share Amendment (the 4% surtax) and the row says so -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41. Dissent from a 80% majority is distinctive. the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/PKF1', 'https://malegislature.gov/Legislators/Profile/PKF1/Bills', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Paul R. Feeney / economic-development  (chair 2 -> 0, NO_INSTRUMENT)
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/PRF0']::text[]),
  -- Paul R. Feeney / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Paul R. Feeney voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/PRF0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Rob Consalvo / economic-development  (chair 3 -> 0, NO_INSTRUMENT)
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/R_C1']::text[]),
  -- Rob Consalvo / transportation-priorities  (chair 3 -> 0, NO_INSTRUMENT)
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/R_C1']::text[]),
  -- Ronald Mariano / economic-development  (chair 3 -> 0, NO_INSTRUMENT)
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/R_M1']::text[]),
  -- Ronald Mariano / healthcare  (chair 2 -> 0, NO_INSTRUMENT)
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/R_M1']::text[]),
  -- Sal N. DiDomenico / childcare  (chair 1 -> 0, NO_INSTRUMENT)
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/SND0']::text[]),
  -- Sal N. DiDomenico / healthcare  (chair 1 -> 0, NOT_DISTINCTIVE)
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/SND0']::text[]),
  -- Sal N. DiDomenico / taxes  (chair 2 -> 2, VOTE_CONFIRMED)
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Sal N. DiDomenico voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/SND0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- Simon Cataldo / healthcare  (chair 2 -> 2, ACT_SPONSORSHIP_CONFIRMED)
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Simon Cataldo is on 1 of the 6 filings of Cherish Act -- 193/H1260 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/193/H1260', 'https://malegislature.gov/Bills/193/H1260/Cosponsor', 'https://malegislature.gov/Legislators/Profile/S_C1/Committees']::text[]),
  -- Steven J. Ouellette / ai-regulation  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c594dc06-0c70-4707-8ae0-d4bc760172db'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/SJO1']::text[]),
  -- Tackey Chan / civil-rights  (chair 1 -> 0, SPONSORSHIP_NOT_FOUND)
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/T_C1']::text[]),
  -- Tackey Chan / healthcare  (chair 2 -> 0, NOT_DISTINCTIVE)
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE VOTE IS REAL AND NEARLY UNANIMOUS. The row rests on the 2022 mental health parity law, Chapter 177 of the Acts of 2022 (S.3097). The Senate accepted the conference report 39-0 and THE HOUSE ENACTED IT WITHOUT A ROLL CALL, so for a Representative there is no recorded individual position at all, and for a Senator a unanimous vote distinguishes nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/T_C1']::text[]),
  -- Tackey Chan / transportation-priorities  (chair 2 -> 0, NO_INSTRUMENT)
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/T_C1']::text[]),
  -- Tara T. Hong / local-environment  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/TTH1/Committees']::text[]),
  -- Thomas M. Stanley / voting-rights  (chair 2 -> 0, LADDER_SCOPE)
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Thomas M. Stanley really is a cosponsored of 191/H656, which the row describes without naming: "Stanley co-sponsored same-day voter registration legislation, which would allow eligible voters to register an". Matched on the member''s own bill list (overlap 0.40 on election, registration, voter, voters). The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 was ballot ACCESS, Season 2 is VOTER IDENTIFICATION. Season 1: "expand early voting periods and make mail-in voting available to all voters without requiring an excuse" Season 2: "Accept non-photo identification, such as a utility bill or bank statement." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/TMS1']::text[]),
  -- Thomas W. Moakley / childcare  (chair 2 -> 0, COMMITTEE_SEAT_ONLY)
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 A COMMITTEE SEAT IS NOT A POSITION. The row rests on a COMMITTEE ASSIGNMENT. A seat is not a position: members are assigned to committees by leadership, and the assignment says nothing about how they would vote. A CAUSE caucus is a position; a committee seat is not. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/TWM1']::text[]),
  -- Tram T. Nguyen / local-immigration  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Tram T. Nguyen is on 4 of the 10 filings of Safe Communities Act -- 191/H3573, 192/H2418, 193/H2288, 194/H2580 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H3573/Cosponsor', 'https://malegislature.gov/Bills/192/H2418', 'https://malegislature.gov/Bills/192/H2418/Cosponsor', 'https://malegislature.gov/Bills/193/H2288/Cosponsor', 'https://malegislature.gov/Legislators/Profile/TTN1']::text[]),
  -- Tricia Farley-Bouvier / campaign-finance  (chair 2 -> 0, SPONSORSHIP_NOT_FOUND)
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE CLAIMED SPONSORSHIP IS NOT ON THE MEMBER''S OWN LIST. The row asserts a sponsorship but names no bill, and nothing on this member''s own Sponsored or Cosponsored lists for the 191st to 194th General Courts matches what it describes. A checked absence over the courts actually fetched. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/TFB1']::text[]),
  -- Tricia Farley-Bouvier / civil-rights  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Tricia Farley-Bouvier is on 4 of the 24 filings of Healthy Youth Act -- 191/H410, 192/H673, 192/S2495, 192/S2541 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H410/Cosponsor', 'https://malegislature.gov/Bills/192/H673/Cosponsor', 'https://malegislature.gov/Bills/192/S2495/Cosponsor', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]),
  -- Tricia Farley-Bouvier / climate-change  (chair 1 -> 0, LADDER_SCOPE)
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07 (migration 1902). ⚠ THE FINDING IS TRUE AND THE SEASON 2 LADDER CANNOT HOLD IT. Tricia Farley-Bouvier is on 1 of the 3 filings of 100% Renewable Energy by 2045 -- 192/H3288 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The Season 2 rung at this value asks a DIFFERENT QUESTION. Season 1 graded SPEED AND COMPULSION, Season 2 grades MECHANISM. Season 1: "declare a climate emergency and ban all activities that increase carbon emissions" Season 2: "Require a shift to clean energy through mandates and firm deadlines." The finding stands and is preserved here, but it cannot seat the Season 2 chair, and a repair may not move a chair. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/TFB1']::text[]),
  -- Tricia Farley-Bouvier / fossil-fuels  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Tricia Farley-Bouvier is on 1 of the 3 filings of 100% Renewable Energy by 2045 -- 192/H3288 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/191/H2930', 'https://malegislature.gov/Bills/192/H3288/Cosponsor', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]),
  -- Tricia Farley-Bouvier / healthcare  (chair 1 -> 1, ACT_SPONSORSHIP_CONFIRMED)
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Tricia Farley-Bouvier is on 4 of the 14 filings of Medicare for All -- 192/H1267, 193/H1239, 194/H1405, 194/H5590 -- read from the member''s own bill list and the bills'' own Cosponsors pages. An act is refiled in every General Court, and a member who signed any filing is a cosponsor of the act. The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/192/H1267/Cosponsor', 'https://malegislature.gov/Bills/193/H1239/Cosponsor', 'https://malegislature.gov/Bills/193/H1981/Cosponsor', 'https://malegislature.gov/Bills/194/H1405/Cosponsor', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]),
  -- William J. Driscoll / abortion  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: William J. Driscoll is on S728 in the member''s own Sponsored/Cosponsored list (S728 in the 194/S728). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/S728/S728', 'https://malegislature.gov/Legislators/Profile/WJD0/BillsSponsored']::text[]),
  -- William J. Driscoll / fossil-fuels  (chair 2 -> 2, SPONSORSHIP_CONFIRMED)
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: William J. Driscoll is on S2263 in the member''s own Sponsored/Cosponsored list (S2263 in the 194/S2263). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/S2263', 'https://malegislature.gov/Bills/194/S2263/S2263', 'https://malegislature.gov/Legislators/Profile/WJD0/BillsSponsored']::text[]),
  -- William J. Driscoll / healthcare  (chair 3 -> 3, SPONSORSHIP_CONFIRMED)
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: William J. Driscoll is on S726, S727, S728 in the member''s own Sponsored/Cosponsored list (S726 in the 194/S726, S727 in the 194/S727, S728 in the 194/S728). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', ARRAY['https://malegislature.gov/Bills/194/S726/S726', 'https://malegislature.gov/Bills/194/S727', 'https://malegislature.gov/Bills/194/S727/S727', 'https://malegislature.gov/Bills/194/S728/S728', 'https://malegislature.gov/Legislators/Profile/WJD0/BillsSponsored']::text[]),
  -- William J. Driscoll / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: William J. Driscoll voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/WJD0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- William N. Brownsberger / public-safety-approach  (chair 1 -> 0, NO_INSTRUMENT)
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/WNB0']::text[]),
  -- William N. Brownsberger / taxes  (chair 3 -> 3, VOTE_CONFIRMED)
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: William N. Brownsberger voted for the Fair Share Amendment (the 4% surtax) -- Joint roll call #48 (Constitutional Convention, 9 June 2021), 159-41, a divided vote (80% yea). the amendment was agreed to in joint session 159-41; the 2022 BALLOT QUESTION is not a legislative vote and no legislator casts one. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', ARRAY['https://malegislature.gov/Legislators/Profile/WNB0', 'https://malegislature.gov/RollCall/192/SenateRollCall48.pdf']::text[]),
  -- William N. Brownsberger / transportation-priorities  (chair 1 -> 0, NO_INSTRUMENT)
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-07 (migration 1902). 🔴 THE ROW NAMES NOTHING THAT CAN BE CHECKED. The row names no bill, no vote, no sponsorship and no other instrument -- only characterisation, district description and party. There is nothing here to check. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', ARRAY['https://malegislature.gov/Legislators/Profile/WNB0']::text[]);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
VALUES
  -- Aaron Michlewitz / redistricting -> 0
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Aaron Michlewitz / school-vouchers -> 0
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Aaron Michlewitz / transportation-priorities -> 0
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Adrianne P. Ramos / abortion -> 1
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 1),
  -- Adrianne P. Ramos / civil-rights -> 1
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 1),
  -- Adrianne P. Ramos / climate-change -> 0
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Adrianne P. Ramos / healthcare -> 2
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Amy M. Sangiolo / civil-rights -> 0
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Amy M. Sangiolo / jail-capacity -> 3
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 3),
  -- Amy M. Sangiolo / taxes -> 0
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Amy M. Sangiolo / voting-rights -> 0
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Angelo J. Puppolo / fossil-fuels -> 3
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 3),
  -- Angelo J. Puppolo / jail-capacity -> 3
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 3),
  -- Angelo J. Puppolo / school-vouchers -> 0
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Bradley H. Jones / climate-change -> 0
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Bradley H. Jones / fossil-fuels -> 3
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 3),
  -- Brendan P. Crighton / taxes -> 2
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Brian M. Ashe / economic-development -> 0
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Brian W. Murray / economic-development -> 0
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Brian W. Murray / healthcare -> 0
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Bruce E. Tarr / economic-development -> 0
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Bruce E. Tarr / fossil-fuels -> 0
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Bruce E. Tarr / healthcare -> 0
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Bruce E. Tarr / redistricting -> 4
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 4),
  -- Bruce E. Tarr / taxes -> 0
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Bruce E. Tarr / transportation-priorities -> 0
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Carole A. Fiola / economic-development -> 0
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Christopher J. Worrell / transportation-priorities -> 0
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Daniel J. Ryan / local-environment -> 0
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 0),
  -- Daniel M. Donahue / economic-development -> 2
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 2),
  -- Daniel M. Donahue / healthcare -> 2
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- David A. LeBoeuf / civil-rights -> 0
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- David A. LeBoeuf / economic-development -> 2
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 2),
  -- David A. LeBoeuf / healthcare -> 1
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 1),
  -- David K. Muradian / taxes -> 4
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- David P. Linsky / taxes -> 2
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Dawne Shand / childcare -> 0
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Dawne Shand / climate-change -> 0
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Dawne Shand / healthcare -> 2
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Dennis C. Gallagher / abortion -> 0
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Dennis C. Gallagher / climate-change -> 0
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Dennis C. Gallagher / fossil-fuels -> 0
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Dennis C. Gallagher / taxes -> 0
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Donald R. Berthiaume / taxes -> 4
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Dylan A. Fernandes / civil-rights -> 0
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Dylan A. Fernandes / fossil-fuels -> 0
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Dylan A. Fernandes / local-environment -> 0
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 0),
  -- Dylan A. Fernandes / taxes -> 2
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Edward R. Philips / climate-change -> 0
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Edward R. Philips / voting-rights -> 0
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Francisco E. Paulino / climate-change -> 0
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Greg Schwartz / civil-rights -> 0
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Greg Schwartz / climate-change -> 0
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Greg Schwartz / economic-development -> 0
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Greg Schwartz / jail-capacity -> 3
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 3),
  -- Greg Schwartz / taxes -> 0
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Greg Schwartz / voting-rights -> 0
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Hadley Luddy / abortion -> 0
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Hadley Luddy / healthcare -> 3
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 3),
  -- Hannah E. Kane / climate-change -> 0
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Hannah E. Kane / economic-development -> 0
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Hannah E. Kane / healthcare -> 0
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Hannah E. Kane / taxes -> 4
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Hannah L. Bowen / civil-rights -> 0
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Hannah L. Bowen / climate-change -> 0
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Hannah L. Bowen / fossil-fuels -> 0
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Hannah L. Bowen / taxes -> 0
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Hannah L. Bowen / transportation-priorities -> 0
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Hannah L. Bowen / voting-rights -> 0
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- James J. O'Day / healthcare -> 0
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- James K. Hawkins / transportation-priorities -> 0
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Jason M. Lewis / childcare -> 1
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 1),
  -- Jason M. Lewis / fossil-fuels -> 0
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Jason M. Lewis / healthcare -> 1
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 1),
  -- Jason M. Lewis / taxes -> 2
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Jason M. Lewis / transportation-priorities -> 0
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Jeffrey R. Turco / transportation-priorities -> 0
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Joan B. Lovely / childcare -> 0
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Joan B. Lovely / economic-development -> 0
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Joan B. Lovely / healthcare -> 0
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Joan B. Lovely / taxes -> 3
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- John C. Velis / healthcare -> 0
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- John F. Keenan / economic-development -> 0
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- John F. Keenan / taxes -> 3
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- John F. Keenan / transportation-priorities -> 0
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- John J. Mahoney / economic-development -> 0
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- John J. Mahoney / healthcare -> 0
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- John J. Marsi / taxes -> 0
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Joseph D. McKenna / taxes -> 4
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Julian A. Cyr / healthcare -> 0
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Julian A. Cyr / local-environment -> 0
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 0),
  -- Julian A. Cyr / taxes -> 2
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Karen E. Spilka / abortion -> 1
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 1),
  -- Karen E. Spilka / childcare -> 0
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Karen E. Spilka / healthcare -> 0
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Kate Donaghue / civil-rights -> 0
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Kate Donaghue / economic-development -> 0
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Kate Donaghue / healthcare -> 2
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Kelly A. Dooner / childcare -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Kelly A. Dooner / fossil-fuels -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Kelly A. Dooner / healthcare -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Kelly A. Dooner / jail-capacity -> 4
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 4),
  -- Kelly A. Dooner / medicare/aid -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 0),
  -- Kelly A. Dooner / redistricting -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Kelly A. Dooner / school-vouchers -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Kelly A. Dooner / taxes -> 0
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Kelly W. Pease / economic-development -> 0
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Kenneth I. Gordon / voting-rights -> 0
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Kevin G. Honan / economic-development -> 0
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Kimberly N. Ferguson / abortion -> 4
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 4),
  -- Kimberly N. Ferguson / climate-change -> 0
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Kimberly N. Ferguson / school-vouchers -> 0
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Kimberly N. Ferguson / transportation-priorities -> 0
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Kip A. Diggs / civil-rights -> 0
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Kip A. Diggs / economic-development -> 0
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Kip A. Diggs / healthcare -> 0
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Leigh S. Davis / climate-change -> 0
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Leigh S. Davis / voting-rights -> 0
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Lisa M. Field / childcare -> 0
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Lisa M. Field / healthcare -> 0
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Liz Miranda / civil-rights -> 0
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Liz Miranda / deportation -> 0
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 0),
  -- Liz Miranda / economic-development -> 0
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Liz Miranda / public-safety-approach -> 0
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 0),
  -- Liz Miranda / rent-regulation -> 2
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 2),
  -- Liz Miranda / taxes -> 2
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Lydia M. Edwards / civil-rights -> 0
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Lydia M. Edwards / deportation -> 1
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 1),
  -- Lydia M. Edwards / rent-regulation -> 2
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 2),
  -- Lydia M. Edwards / taxes -> 0
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Lydia M. Edwards / transportation-priorities -> 0
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Mark C. Montigny / economic-development -> 0
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Mark C. Montigny / healthcare -> 0
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Mark C. Montigny / local-environment -> 0
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 0),
  -- Mark C. Montigny / taxes -> 2
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Mary S. Keefe / civil-rights -> 0
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Mary S. Keefe / economic-development -> 2
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 2),
  -- Mary S. Keefe / healthcare -> 1
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 1),
  -- Meghan Kilcoyne / economic-development -> 0
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Meghan Kilcoyne / healthcare -> 2
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Michael D. Brady / economic-development -> 0
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Michael D. Brady / healthcare -> 0
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Michael D. Brady / taxes -> 3
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- Michael J. Moran / abortion -> 3
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 3),
  -- Michael J. Moran / economic-development -> 0
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Michael J. Moran / transportation-priorities -> 0
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Michael J. Rodrigues / campaign-finance -> 0
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 0),
  -- Michael J. Rodrigues / economic-development -> 0
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Michael J. Rodrigues / healthcare -> 0
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Michael J. Rodrigues / school-vouchers -> 0
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Michael J. Rodrigues / taxes -> 3
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- Michael J. Rodrigues / transportation-priorities -> 0
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Michael J. Soter / taxes -> 4
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Michael P. Kushmerek / economic-development -> 0
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Michael P. Kushmerek / healthcare -> 2
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Michael S. Chaisson / economic-development -> 0
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Natalie Higgins / civil-rights -> 0
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Natalie Higgins / healthcare -> 1
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 1),
  -- Natalie Higgins / rent-regulation -> 2
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 2),
  -- Nick Collins / economic-development -> 0
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Nick Collins / taxes -> 3
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- Nick Collins / transportation-priorities -> 0
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Patricia D. Jehlen / healthcare -> 0
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Patricia D. Jehlen / rent-regulation -> 2
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 2),
  -- Patricia D. Jehlen / taxes -> 2
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Patrick M. O'Connor / taxes -> 0
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Paul K. Frost / taxes -> 4
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Paul R. Feeney / economic-development -> 0
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Paul R. Feeney / taxes -> 2
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Rob Consalvo / economic-development -> 0
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Rob Consalvo / transportation-priorities -> 0
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Ronald Mariano / economic-development -> 0
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 0),
  -- Ronald Mariano / healthcare -> 0
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Sal N. DiDomenico / childcare -> 0
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Sal N. DiDomenico / healthcare -> 0
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Sal N. DiDomenico / taxes -> 2
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Simon Cataldo / healthcare -> 2
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Steven J. Ouellette / ai-regulation -> 0
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c594dc06-0c70-4707-8ae0-d4bc760172db'::uuid, 0),
  -- Tackey Chan / civil-rights -> 0
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Tackey Chan / healthcare -> 0
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Tackey Chan / transportation-priorities -> 0
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Tara T. Hong / local-environment -> 0
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 0),
  -- Thomas M. Stanley / voting-rights -> 0
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Thomas W. Moakley / childcare -> 0
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Tram T. Nguyen / local-immigration -> 1
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 1),
  -- Tricia Farley-Bouvier / campaign-finance -> 0
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 0),
  -- Tricia Farley-Bouvier / civil-rights -> 1
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 1),
  -- Tricia Farley-Bouvier / climate-change -> 0
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Tricia Farley-Bouvier / fossil-fuels -> 1
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 1),
  -- Tricia Farley-Bouvier / healthcare -> 1
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 1),
  -- William J. Driscoll / abortion -> 3
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 3),
  -- William J. Driscoll / fossil-fuels -> 2
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 2),
  -- William J. Driscoll / healthcare -> 3
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 3),
  -- William J. Driscoll / taxes -> 3
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- William N. Brownsberger / public-safety-approach -> 0
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 0),
  -- William N. Brownsberger / taxes -> 3
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 3),
  -- William N. Brownsberger / transportation-priorities -> 0
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0);

-- Amy M. Sangiolo / same-sex-marriage  (Season 2 row exists at 2.0 -> 0, RESTATES_RUNG)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/AMS3', 'https://malegislature.gov/Legislators/Profile/AMS3/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
-- Bradley H. Jones / housing  (Season 2 row exists at 5.0 -> 5, SPONSORSHIP_CONFIRMED)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Bradley H. Jones is on H1527, H1536 in the member''s own Sponsored/Cosponsored list (H1527 in the 194/H1527, H1536 in the 194/H1536). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', sources = ARRAY['https://malegislature.gov/Bills/194/H1527/H1527', 'https://malegislature.gov/Bills/194/H1536/H1536', 'https://malegislature.gov/Legislators/Profile/BHJ1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 5, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- David K. Muradian / housing  (Season 2 row exists at 5.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/DKM1', 'https://malegislature.gov/Legislators/Profile/DKM1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '891030da-39e2-496f-8a20-72aeb27093ba'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '891030da-39e2-496f-8a20-72aeb27093ba'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Dennis C. Gallagher / same-sex-marriage  (Season 2 row exists at 3.0 -> 0, RESTATES_RUNG)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/DCG2', 'https://malegislature.gov/Legislators/Profile/DCG2/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '17035eb6-e7d3-4372-9b96-0741adb57468'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '17035eb6-e7d3-4372-9b96-0741adb57468'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
-- Donald R. Berthiaume / housing  (Season 2 row exists at 5.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/DRB1', 'https://malegislature.gov/Legislators/Profile/DRB1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '329212d4-14ef-4685-9d95-cc7473aad949'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '329212d4-14ef-4685-9d95-cc7473aad949'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Dylan A. Fernandes / housing  (Season 2 row exists at 3.0 -> 3, VOTE_CONFIRMED)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Dylan A. Fernandes voted for the Affordable Homes Act -- House roll call #199 (enactment, 1 Aug 2024), 128-24, a divided vote (84% yea). H.4977, Chapter 150 of 2024. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://malegislature.gov/RollCall/193/HouseRollCall199.pdf']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 3, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Greg Schwartz / housing  (Season 2 row exists at 4.0 -> 0, RESTATES_RUNG)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/G_S1', 'https://malegislature.gov/Legislators/Profile/G_S1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Greg Schwartz / same-sex-marriage  (Season 2 row exists at 2.0 -> 0, RESTATES_RUNG)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/G_S1', 'https://malegislature.gov/Legislators/Profile/G_S1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
-- Hadley Luddy / housing  (Season 2 row exists at 3.0 -> 3, SPONSORSHIP_CONFIRMED)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE SPONSORSHIP IS VERIFIED: Hadley Luddy is on H4288, H4291, H4311, H4318, H4410, H4411, H4576, H4577 in the member''s own Sponsored/Cosponsored list (H4288 in the 194/H4288, H4291 in the 194/H4291, H4311 in the 194/H4311, H4318 in the 194/H4318, H4410 in the 194/H4410, H4411 in the 194/H4411, H4576 in the 194/H4576, H4577 in the 194/H4577). The claim holds; the row cited only a roster page for it. The sources now point at the bill.', sources = ARRAY['https://malegislature.gov/Bills/194/H4288/H4288', 'https://malegislature.gov/Bills/194/H4291/H4291', 'https://malegislature.gov/Bills/194/H4311', 'https://malegislature.gov/Bills/194/H4311/H4311', 'https://malegislature.gov/Bills/194/H4318/H4318', 'https://malegislature.gov/Bills/194/H4410/H4410', 'https://malegislature.gov/Bills/194/H4411/H4411', 'https://malegislature.gov/Bills/194/H4576/H4576', 'https://malegislature.gov/Bills/194/H4577/H4577', 'https://malegislature.gov/Legislators/Profile/H_L1']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '03e35156-c179-4dd5-9c8c-8d418976914e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 3, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '03e35156-c179-4dd5-9c8c-8d418976914e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Hannah E. Kane / housing  (Season 2 row exists at 4.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/HEK1', 'https://malegislature.gov/Legislators/Profile/HEK1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'd54b9791-0668-4397-b488-160d06f7c420'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'd54b9791-0668-4397-b488-160d06f7c420'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Hannah L. Bowen / same-sex-marriage  (Season 2 row exists at 2.0 -> 0, RESTATES_RUNG)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). 🔴🔴 THE ROW QUOTES THE RUNG BACK AS ITS OWN EVIDENCE. The row reaches this chair by quoting the rung back as its own evidence, or by inferring from party and from the corpus''s own other unsourced stances. A chair is shown to voters as this person''s position; the record already has a way of saying unknown, and this is it: value 0. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/HLB1', 'https://malegislature.gov/Legislators/Profile/HLB1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'b651cf67-37b4-4cbf-afcd-088010247788'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'b651cf67-37b4-4cbf-afcd-088010247788'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
-- John J. Marsi / housing  (Season 2 row exists at 5.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/JJM1', 'https://malegislature.gov/Legislators/Profile/JJM1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '9dd7276b-1c24-466c-a530-d2297607a784'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '9dd7276b-1c24-466c-a530-d2297607a784'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Joseph D. McKenna / housing  (Season 2 row exists at 5.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/JDM1', 'https://malegislature.gov/Legislators/Profile/JDM1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Karen E. Spilka / housing  (Season 2 row exists at 1.0 -> 0, NOT_ON_THE_ROLL_CALL)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ NO VOTE IS RECORDED FOR THIS MEMBER. Karen E. Spilka does not appear on the roll call for the Affordable Homes Act (Senate roll call #249, enactment, 1 Aug 2024): NOT ON THE ROLL CALL. Serving in a General Court is not the same as being seated for a vote taken inside it -- a member who arrives at a special election is absent from earlier roll calls of the same court. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://malegislature.gov/RollCall/193/SenateRollCall249.pdf']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Kelly A. Dooner / housing  (Season 2 row exists at 4.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/KAD0']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Kip A. Diggs / housing  (Season 2 row exists at 3.0 -> 3, VOTE_CONFIRMED)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: Kip A. Diggs voted for the Affordable Homes Act -- House roll call #199 (enactment, 1 Aug 2024), 128-24, a divided vote (84% yea). H.4977, Chapter 150 of 2024. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/KAD1', 'https://malegislature.gov/RollCall/193/HouseRollCall199.pdf']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 3, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Michael J. Soter / housing  (Season 2 row exists at 5.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/MJS3', 'https://malegislature.gov/Legislators/Profile/MJS3/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Paul K. Frost / housing  (Season 2 row exists at 5.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/PKF1', 'https://malegislature.gov/Legislators/Profile/PKF1/Bills']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Richard G. Wells / housing  (Season 2 row exists at 3.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/RGW1']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Ronald Mariano / housing  (Season 2 row exists at 3.0 -> 0, NOT_ON_THE_ROLL_CALL)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ NO VOTE IS RECORDED FOR THIS MEMBER. Ronald Mariano does not appear on the roll call for the Affordable Homes Act (House roll call #199, enactment, 1 Aug 2024): NOT ON THE ROLL CALL. Serving in a General Court is not the same as being seated for a vote taken inside it -- a member who arrives at a special election is absent from earlier roll calls of the same court. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/R_M1', 'https://malegislature.gov/RollCall/193/HouseRollCall199.pdf']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- Tackey Chan / housing  (Season 2 row exists at 3.0 -> 0, OMNIBUS_AND_NOT_DISTINCTIVE)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07 (migration 1902). ⚠ AN OMNIBUS VOTE IS NOT A VOTE ON ONE OF ITS SECTIONS. The row rests on the MBTA Communities zoning requirement. That is SECTION 18 of H.5250, "An Act enabling partnerships for growth" -- a large economic development omnibus, Chapter 358 of the Acts of 2020 -- so a vote on it is not a vote on zoning. And the vote could not seat a chair in any case: the House enacted it 143-4 and the Senate 40-0. A near-unanimous vote on an omnibus distinguishes this member from nobody. The sources examined are kept below so the next reader does not re-derive this. This is a blank, not a deletion -- the chair may well be re-researchable, and that is an invitation.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/T_C1']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '90602902-b178-4709-a74b-68b30fe45394'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '90602902-b178-4709-a74b-68b30fe45394'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
-- William J. Driscoll / housing  (Season 2 row exists at 4.0 -> 4, VOTE_CONFIRMED)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-07 (migration 1902); THE CHAIR IS UNCHANGED. The row cited only this member''s roster page on malegislature.gov -- no bill, no roll call. 🔑 A ROSTER PAGE LISTS THE MEMBER''S OWN BILLS, so a profile URL is not automatically a bad source -- for much of this cohort it genuinely is the evidence, and the fix is a CITATION REPAIR rather than retirement (the Maryland finding, migration 1898). The repair points the citation at the instrument itself. 🔑 THE VOTE IS VERIFIED AGAINST THE PRIMARY RECORD: William J. Driscoll voted for the Affordable Homes Act -- House roll call #199 (enactment, 1 Aug 2024), 128-24, a divided vote (84% yea). H.4977, Chapter 150 of 2024. The claim holds; the row simply cited no instrument for it. (the parse was checked against the roll call''s own declared totals before any name was read off it). The sources now point at the roll call itself.', sources = ARRAY['https://malegislature.gov/Legislators/Profile/WJD0', 'https://malegislature.gov/RollCall/193/HouseRollCall199.pdf']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 4, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;

DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c USING (politician_id, topic_id, season_id)
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid)
  );
  IF n <> 219 THEN
    RAISE EXCEPTION 'migration 1902: expected 219 paired Season 2 rows, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = 0 AND (a.politician_id, a.topic_id) IN (
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid)
  );
  IF n <> 151 THEN
    RAISE EXCEPTION 'migration 1902: expected 151 Season 2 blanks at 0, found %', n;
  END IF;

  -- a repair must not move a chair
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id, a.value) IN (
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 5),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 2),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3)
  );
  IF n <> 68 THEN
    RAISE EXCEPTION 'migration 1902: the 68 repairs did not land at their original chairs (found %)', n;
  END IF;

  -- every repaired row now cites something OTHER than a roster page
  SELECT count(*) INTO n FROM inform.politician_context c WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
    AND (c.politician_id, c.topic_id) IN (
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
    )
    AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s
                     WHERE s NOT LIKE '%/Legislators/Profile/%');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1902: % repaired rows still cite nothing but a roster page', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context c WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
    AND (c.politician_id, c.topic_id) IN (
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid)
    )
    AND (c.sources IS NULL OR cardinality(c.sources) = 0 OR coalesce(btrim(c.reasoning),'') = '');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1902: % rows written with empty sources or empty reasoning', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND (a.politician_id, a.topic_id, a.value) IN (
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 2),
    ('9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('a6e1a867-1e4e-449f-bb10-4f55449762bf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 1),
    ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('d54b9791-0668-4397-b488-160d06f7c420'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 1),
    ('bd451748-111f-461d-9752-95e7c243769e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 1),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 5),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 4),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 4),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 1),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('d9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 3),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 2),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('90602902-b178-4709-a74b-68b30fe45394'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),
    ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 2),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1)
  );
  IF n <> 219 THEN
    RAISE EXCEPTION 'migration 1902: Season 1 changed under us (219 expected, %)', n;
  END IF;
END
$post$;
