-- 1909_ca_generic_profile_sourcing_cohort_season2.sql
-- The California generic-profile-sourcing cohort: every voter-visible stance row of a California
-- officeholder whose EVERY cited source is a generic page about the PERSON -- a Wikipedia or
-- Ballotpedia biography, or a BallotReady profile -- rather than evidence of a position.
--
-- Measured fresh against production: 132 keys / 42 officeholders.
-- 119 rows written here: 32 CITATION REPAIRS (chair unchanged) and 87 BLANKS.
-- 4 rows HELD for the operator. 9 rows BLOCKED.
--
-- ══ 🔑 WHY THIS COHORT IS NOT MARYLAND OR TEXAS ═══════════════════════════════════════════════
-- In Maryland and Texas the cited page was a legislative ROSTER page, which lists the member's
-- own bills, so ~70% of rows were repairable from the page already cited. California is
-- different in two ways that change the whole job:
--   * 131 of the 132 rows carry EXACTLY ONE source and it is a biography. There are no roster
--     pages in this cohort at all.
--   * Only 41 of 132 keys belong to state legislators. The rest are LOCAL officials -- Los
--     Angeles City Council 43, county and SF supervisors 27, mayors, a city attorney -- for whom
--     there is no bill corpus to fall back on.
-- The repair rate here is 32 of the 123 writable rows, about 26%: closer to Massachusetts than
-- to Maryland. The class name never predicts the answer; measure each jurisdiction.
--
-- ══ ⚖ WHAT MAKES A ROW A REPAIR RATHER THAN A BLANK ═══════════════════════════════════════════
-- A biography is not automatically empty. Several of these pages carry a dedicated positions
-- section and real first-person action: Eunisses Hernandez's page has "Positions on housing";
-- Raul Campillo's has "Political positions > Homelessness"; Ballotpedia and BallotReady render
-- candidate survey answers IN THE CANDIDATE'S OWN WORDS. Where the page states what the member
-- did or said on this topic, the row is REPAIRED: the chair stays exactly where it was and the
-- reasoning now says what the page says instead of citing it bare.
-- Where it does not, the row is blanked, and the blank records WHICH KIND of nothing it was.
--
-- ══ 🔴 THE NINE KINDS OF NOTHING -- all found by reading, none by counting ════════════════════
-- Every blank carries one of these, chosen by reading the page:
--   SILENT (41)               the page does not mention the subject at all
--   OFF_TOPIC (14)            it speaks about something nearby, not about this topic
--   BIOGRAPHY (7)             education, residence, prior job -- facts that carry no position
--   SURVEY_NOT_COMPLETED (7)  🔑 the page's only position-bearing section states that the person
--                             DID NOT COMPLETE the survey. The source affirmatively records that
--                             there is nothing to cite, which is stronger than failing to find.
--   COMMITTEE_LIST (4)        sitting on a budget committee is not a position on taxes
--   ENDORSEMENT_LIST (4)      an endorsement is somebody else's judgement, not a stated position
--   CHROME (3)                the "matches" are the citing site's own navigation menu
--   ELECTION_RESULTS (2)      vote totals record that a person ran, not what they would do
--   SUBJECT_ARTICLE (2)       the citation is the encyclopedia article on SANCTUARY CITIES, which
--                             explains the policy and says nothing about this person
--   PERSONAL_HEALTH (2)       🔴 the only matches describe the member's own medical leave. A
--                             politician's health is not a healthcare policy position.
--   CATEGORY_TAG (1)          Wikipedia category footers. A category records what a person IS.
--
-- ══ ⚖ THE CARRY GATE: 4 ROWS HELD, NOT WRITTEN ═══════════════════════════════════════════════
-- A citation repair must not move a chair, and in Season 2 that is not automatic. For each
-- repair whose chair was read from Season 1, the rung AT THAT VALUE must still say the same
-- thing in Season 2. Of 37 candidate repairs: 6 were already in Season 2 (no carry question),
-- 17 rungs are identical, 13 changed and were read by hand, and 1 is on a blocked topic.
-- Five of the changed pairs carry (a rewording, or Season 2 asking strictly less). Four do not,
-- and those rows are HELD rather than written at a chair their own evidence now contradicts:
--   Brian Gutierrez / economic-development · Brian Gutierrez / homelessness-response
--   Raul Campillo / homelessness           · Hugo Soto-Martinez / homelessness-response
-- 🔴 The sharpest is homelessness-response rung 3, which Season 2 rewrote into its opposite:
-- Season 1 "Invest in outreach, shelter, and mental health services" became Season 2 "Maintain
-- current housing and service programs at today's funding level, with no major new spending".
--
-- ══ 🔴 9 ROWS CANNOT BE WRITTEN AT ALL ════════════════════════════════════════════════════════
-- All nine are `immigration`, which has NO SEASON 2 PIN -- the national 1,678-stance orphan.
-- One of them, Adena Ishii's, is a row this pass would otherwise have REPAIRED with good
-- evidence. The national total blocked on this topic is now ~155.
--
-- Season 1 is CLOSED and IMMUTABLE: every write here is forward, into Season 2.
-- No migration runner exists; this file records SQL applied by hand.


DO $pre$
DECLARE n integer;
BEGIN
  -- all 119 must still sit at the chair recorded when they were read, from whichever season is
  -- effective. If anything moved since the read, stop rather than write over it.
  WITH eff AS (
    SELECT DISTINCT ON (pa.politician_id, pa.topic_id) pa.politician_id, pa.topic_id, pa.value
      FROM inform.politician_answers pa
      JOIN inform.seasons s ON s.id = pa.season_id
     WHERE s.number IN (1,2)
     ORDER BY pa.politician_id, pa.topic_id, s.number DESC
  ), k(pid, tid, expected) AS (VALUES
    ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('ba647863-25fb-4ccf-9cb0-5a1c912d1b27'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 3),
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2),
    ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 3),
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 4),
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 4),
    ('708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2),
    ('2ba6e476-1d62-4ac5-a70d-f4bcbe704f39'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2),
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, 3),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 1),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('685f2150-7b2a-4f94-992c-bf0cf23ffa69'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('1caa9043-2397-4f75-b430-acc0623d64d7'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 2),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 1),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 3),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 4),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 4),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 5),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 4),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3),
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 2),
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2),
    ('005d7df1-227e-4110-b254-ec835d5b5e95'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('41949a2b-563a-4608-91c6-951c63252a91'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 3),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('bab3379b-d64e-423b-b62e-4efa04cee750'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('ff77225c-51f9-4628-acc3-020d40382d05'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, 3),
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 3),
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3),
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 4),
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 5),
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 5),
    ('1e29ce86-9e02-4079-b50d-bb0d039613a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
    ('4ba62f32-dd20-48ce-8d84-d09bb129ad59'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1),
    ('522efd15-f5e2-4e1a-8708-aad87410637d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 5),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4)
  )
  SELECT count(*) INTO n FROM k JOIN eff e ON e.politician_id = k.pid AND e.topic_id = k.tid
   WHERE e.value = k.expected;
  IF n <> 119 THEN
    RAISE EXCEPTION 'migration 1909: expected 119 rows at their recorded chairs, found %', n;
  END IF;

  -- none of them may be a row migration 1908 blanked as wrong-person
  SELECT count(*) INTO n
    FROM inform.politician_context c
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE '%(migration 1908)%'
     AND (c.politician_id, c.topic_id) IN (SELECT pid, tid FROM (VALUES
    ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('ba647863-25fb-4ccf-9cb0-5a1c912d1b27'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 3),
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2),
    ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 3),
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 4),
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 4),
    ('708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 2),
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2),
    ('2ba6e476-1d62-4ac5-a70d-f4bcbe704f39'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2),
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, 3),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 2),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 1),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 3),
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('685f2150-7b2a-4f94-992c-bf0cf23ffa69'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('1caa9043-2397-4f75-b430-acc0623d64d7'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 2),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 1),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 3),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 4),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 4),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 5),
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 4),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3),
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, 2),
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2),
    ('005d7df1-227e-4110-b254-ec835d5b5e95'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('41949a2b-563a-4608-91c6-951c63252a91'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 3),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 3),
    ('bab3379b-d64e-423b-b62e-4efa04cee750'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('ff77225c-51f9-4628-acc3-020d40382d05'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, 3),
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 3),
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3),
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 4),
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 5),
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 5),
    ('1e29ce86-9e02-4079-b50d-bb0d039613a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
    ('4ba62f32-dd20-48ce-8d84-d09bb129ad59'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1),
    ('522efd15-f5e2-4e1a-8708-aad87410637d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 5),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4)
     ) AS z(pid, tid, expected));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1909: % of these rows were already blanked by migration 1908', n;
  END IF;
END
$pre$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
VALUES
  -- Adena Ishii / deportation  (REPAIR, chair 2 held)
    ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She and the rest of the Berkeley City Council voted unanimously to reaffirm Berkeley''s status as a sanctuary city, and she said at the meeting that in the current political climate some cities are actively assisting ICE. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Adena_Ishii']::text[]),
  -- Ana Valencia / public-safety-approach  (REPAIR, chair 4 held)
    ('ba647863-25fb-4ccf-9cb0-5a1c912d1b27'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own Ballotpedia Candidate Connection survey answer she wrote that her top issue is public safety and that she will ''continue to prioritize the safety of our community by enhancing community policing and increasing support for emergency services.'' ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Ana_Valencia_(Norwalk_City_Council_At-large,_California,_candidate_2024)']::text[]),
  -- Angelique Ashby / tariffs  (BLANK SILENT)
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '9f094155-f604-47e8-93db-54a3142420ca'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby']::text[]),
  -- Angelique Ashby / ukraine-support  (BLANK SILENT)
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby']::text[]),
  -- Brian W. Jones / tariffs  (BLANK SILENT)
    ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '9f094155-f604-47e8-93db-54a3142420ca'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[]),
  -- Carl DeMaio / healthcare  (REPAIR, chair 4 held)
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He proposed a ''Freedomcare'' health insurance system to replace the Affordable Care Act, allowing individuals to buy insurance across state lines and putting the government exchanges under private management. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Carl_DeMaio']::text[]),
  -- Carl DeMaio / medicare/aid  (BLANK SILENT)
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Carl_DeMaio']::text[]),
  -- Catherine Stefani / abortion  (REPAIR, chair 2 held)
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own Ballotpedia survey answer she wrote, ''I understand the significance of California as a sanctuary for abortion access and vow to protect and preserve access to life-saving reproductive care.'' ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Catherine_Stefani#Campaign_themes']::text[]),
  -- Catherine Stefani / homelessness  (BLANK ENDORSEMENT_LIST)
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Catherine_Stefani#Campaign_themes']::text[]),
  -- Chyanne Chen / growth-and-development  (REPAIR, chair 2 held)
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '65e8ffd5-5aac-4d40-8862-a321949eafa4'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She was a leading critic of the legislation to upzone 60% of San Francisco, arguing ''This legislation is an example of the government doing things to our communities, not with our communities.'' ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen']::text[]),
  -- Chyanne Chen / residential-zoning  (BLANK BIOGRAPHY)
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ef2a5e59-525a-41fa-94de-ce771df7c927'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen']::text[]),
  -- Daniel Lurie / childcare  (REPAIR, chair 2 held)
    ('708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In January 2026 he announced a policy providing free childcare to families earning under $250,000 a year and subsidised childcare below $310,000, as part of a broader affordability agenda. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]),
  -- David Chiu / childcare  (BLANK SILENT)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]),
  -- David Chiu / local-environment  (REPAIR, chair 2 held)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In 2010 he established the Healthy Nail Salon Recognition Program, and in 2017 he authored two environmental laws including AB 546. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]),
  -- David Chiu / trans-athletes  (BLANK OFF_TOPIC)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]),
  -- David Chiu / ukraine-support  (BLANK SILENT)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]),
  -- Dawn Addis / school-vouchers  (BLANK SILENT)
    ('2ba6e476-1d62-4ac5-a70d-f4bcbe704f39'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Dawn_Addis']::text[]),
  -- Eunisses Hernandez / campaign-finance  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / city-sanitation  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af3c2445-97e5-46a7-b33d-6915c13eab5c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / civil-rights  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / deportation  (REPAIR, chair 2 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She co-introduced the 2023 motion directing the city attorney to draft a sanctuary city ordinance for Los Angeles, prohibiting the use of city resources for federal immigration enforcement; the ordinance was enacted in November 2024. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / growth-and-development  (REPAIR, chair 2 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '65e8ffd5-5aac-4d40-8862-a321949eafa4'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She said during the campaign, ''My plan to fight gentrification is to be the biggest barrier I can to luxury and market-rate development,'' and argued the city should help community land trusts buy apartments. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / homelessness  (BLANK OFF_TOPIC)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / jail-capacity  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She worked for JusticeLA as a campaign coordinator pushing to halt a new women''s jail at Mira Loma, was appointed to an Alternatives to Incarceration working group, co-founded La Defensa to reduce the number of incarcerated people in LA County, and co-chaired Measure J. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / local-environment  (BLANK BIOGRAPHY)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / local-immigration  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She co-introduced the 2023 motion directing the city attorney to draft Los Angeles''s sanctuary city ordinance, which prohibits city resources being used for federal immigration enforcement. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez', 'https://en.wikipedia.org/wiki/Sanctuary_city']::text[]),
  -- Eunisses Hernandez / public-safety-approach  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She is described as a self-described police and prison abolitionist; she led the vote against Mayor Bass''s first budget, citing the $3.2 billion allocated to the LAPD, and voted with Raman and Soto-Martinez against a four-year package of raises for rank-and-file police officers. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / rent-regulation  (REPAIR, chair 2 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In 2024 she cosponsored amendments to the city''s tenant anti-harassment ordinance increasing penalties against landlords, which passed over the opposition of three councilmembers; after the 2025 Los Angeles wildfires she co-authored a motion with Hugo Soto-Martinez for a moratorium on evictions and rent hikes for affected households. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / residential-zoning  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ef2a5e59-525a-41fa-94de-ce771df7c927'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / taxes  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Eunisses Hernandez / transportation-priorities  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She spoke at the launch of ''La Sombrita'', the bus-stop shade and lighting fixture, put forward a motion funding a study of traffic to Dodger Stadium, and took part in the council''s handling of the Union Station to Dodger Stadium gondola proposal. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Eunisses_Hernandez']::text[]),
  -- Gavin Newsom / medicare/aid  (BLANK OFF_TOPIC)
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Gavin_Newsom']::text[]),
  -- Gavin Newsom / religious-freedom  (BLANK OFF_TOPIC)
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Gavin_Newsom']::text[]),
  -- Hugo Soto-Martinez / campaign-finance  (BLANK SILENT)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / city-sanitation  (BLANK OFF_TOPIC)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af3c2445-97e5-46a7-b33d-6915c13eab5c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / civil-rights  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In June 2024 he helped remove U-turn signs installed in 1997 that were considered discriminatory, having been placed to deter gay men from cruising the neighbourhood. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / deportation  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He introduced the motion with Eunisses Hernandez and Nithya Raman to make Los Angeles a sanctuary city, codifying existing policy barring city employees from using public facilities or resources to assist federal civil immigration enforcement. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / homelessness  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He campaigned against the incumbent''s handling of Echo Park''s homeless population and had the fence around Echo Park Lake removed, the fence erected after the 2021 police sweep of encampments there. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / jail-capacity  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He supported Measure J, the initiative allocating at least 10% of Los Angeles County funding to community reinvestment and alternatives to incarceration. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / public-safety-approach  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He voted against a four-year package of raises and bonuses for rank-and-file police officers, arguing it would pull money from mental health clinicians and homeless outreach workers, and he has worked against deputy gangs inside the Los Angeles Sheriff''s Department. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Hugo Soto-Martinez / taxes  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In May 2024 he opposed a city budget that slashed funding to nearly all departments apart from the LAPD. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Jackie Fielder / abortion  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / ai-regulation  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c594dc06-0c70-4707-8ae0-d4bc760172db'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / healthcare  (BLANK PERSONAL_HEALTH)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches describe this person''s own medical leave. A politician''s health is not a healthcare policy position, and it should not have been read as one. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / medicare/aid  (BLANK PERSONAL_HEALTH)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches describe this person''s own medical leave. A politician''s health is not a healthcare policy position, and it should not have been read as one. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / misinformation  (BLANK OFF_TOPIC)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / redistricting  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / religious-freedom  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / school-vouchers  (BLANK BIOGRAPHY)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / social-security  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '8defc029-0b7e-426f-b838-a2e170f566c9'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / tariffs  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '9f094155-f604-47e8-93db-54a3142420ca'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / trans-athletes  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / ukraine-support  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jackie Fielder / voting-rights  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]),
  -- Jesse Gabriel / taxes  (BLANK COMMITTEE_LIST)
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are committee assignments. Sitting on a budget committee is not a position on taxes. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[]),
  -- Jesse Gabriel / voting-rights  (BLANK OFF_TOPIC)
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[]),
  -- Jose Luis Solache Jr. / abortion  (BLANK SILENT)
    ('1caa9043-2397-4f75-b430-acc0623d64d7'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Jose_Solache']::text[]),
  -- Karen Ruth Bass / misinformation  (BLANK CHROME)
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The apparent matches are the citing site''s own navigation furniture and section index, not content about this person. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Karen_Bass']::text[]),
  -- Karen Ruth Bass / voting-rights  (BLANK CHROME)
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The apparent matches are the citing site''s own navigation furniture and section index, not content about this person. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Karen_Bass']::text[]),
  -- Kathryn Barger / abortion  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Kathryn Barger / homelessness-response  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e47ec98-46af-4e77-ae81-04d1311b4543'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Kathryn Barger / judicial-criminal-justice  (BLANK CHROME)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The apparent matches are the citing site''s own navigation furniture and section index, not content about this person. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Kathryn Barger / local-immigration  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Kathryn Barger / public-safety-approach  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Kathryn Barger / rent-regulation  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 5 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Kathryn Barger / transportation-priorities  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]),
  -- Katy Yaroslavsky / abortion  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / deportation  (BLANK SUBJECT_ARTICLE)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The citation is a general encyclopedia article about the SUBJECT, not a page about this person. It explains what the policy is; it says nothing about where this person stands. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Sanctuary_city']::text[]),
  -- Katy Yaroslavsky / jail-capacity  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / local-immigration  (BLANK SUBJECT_ARTICLE)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The citation is a general encyclopedia article about the SUBJECT, not a page about this person. It explains what the policy is; it says nothing about where this person stands. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Sanctuary_city', 'https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / school-vouchers  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / taxes  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / voting-rights  (BLANK ELECTION_RESULTS)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are this person''s own election results and vote totals, which record that they ran, not what they would do. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Maria Elena Durazo / religious-freedom  (BLANK SILENT)
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[]),
  -- Maria Elena Durazo / social-security  (BLANK OFF_TOPIC)
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '8defc029-0b7e-426f-b838-a2e170f566c9'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[]),
  -- Maria Elena Durazo / ukraine-support  (BLANK SILENT)
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[]),
  -- Marqueece Harris-Dawson / economic-development  (REPAIR, chair 2 held)
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page records that he has leveraged $1.7 billion in federal, state and Metro funding to address disinvestment and revitalise streetscapes, and that during the 2020 pandemic he created a Senior Meals Program that partnered with 32 South LA businesses to provide them income during the lockdown. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Marqueece_Harris-Dawson']::text[]),
  -- Marqueece Harris-Dawson / redistricting  (REPAIR, chair 1 held)
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He advocated an independent redistricting commission by opening up the city charter for full reform, and that measure went on the November 2024 ballot. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Marqueece_Harris-Dawson']::text[]),
  -- Matt Mahan / redistricting  (BLANK OFF_TOPIC)
    ('41949a2b-563a-4608-91c6-951c63252a91'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan']::text[]),
  -- Michelle Rodriguez / civil-rights  (BLANK SILENT)
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[]),
  -- Michelle Rodriguez / healthcare  (REPAIR, chair 2 held)
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page records that her legislative priorities included advancing universal healthcare. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[]),
  -- Michelle Rodriguez / homelessness  (REPAIR, chair 2 held)
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page records that her legislative priorities included addressing homelessness. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[]),
  -- Nithya Raman / redistricting  (BLANK OFF_TOPIC)
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Nithya_Raman']::text[]),
  -- Nithya Raman / taxes  (BLANK OFF_TOPIC)
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Nithya_Raman']::text[]),
  -- Patrick J. Ahrens / abortion  (BLANK ENDORSEMENT_LIST)
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Patrick_Ahrens#Campaign_themes']::text[]),
  -- Patrick J. Ahrens / homelessness  (REPAIR, chair 3 held)
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In his own candidate statement he wrote, ''In the Assembly, I''ll champion new ideas for old problems like housing, homelessness, climate change, and public safety,'' and described having been homeless for parts of his college years. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Patrick_Ahrens']::text[]),
  -- Raul Campillo / taxes  (BLANK OFF_TOPIC)
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Raul_Campillo']::text[]),
  -- Ricardo Lara / redistricting  (BLANK SURVEY_NOT_COMPLETED)
    ('bab3379b-d64e-423b-b62e-4efa04cee750'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ricardo_Lara']::text[]),
  -- Sean Elo-Rivera / city-sanitation  (BLANK SILENT)
    ('dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af3c2445-97e5-46a7-b33d-6915c13eab5c'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[]),
  -- Shamann Walton / misinformation  (BLANK SILENT)
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton']::text[]),
  -- Shamann Walton / religious-freedom  (BLANK SILENT)
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton']::text[]),
  -- Shamann Walton / residential-zoning  (BLANK BIOGRAPHY)
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ef2a5e59-525a-41fa-94de-ce771df7c927'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton']::text[]),
  -- Shannon Grove / abortion  (REPAIR, chair 4 held)
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: She has introduced anti-abortion legislation in the Assembly, which did not pass, and opposed the 2015 legislation requiring crisis pregnancy centres to disclose whether they were licensed. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Shannon_Grove']::text[]),
  -- Shannon Grove / healthcare  (BLANK COMMITTEE_LIST)
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 5 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are committee assignments. Sitting on a budget committee is not a position on taxes. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Shannon_Grove']::text[]),
  -- Shannon Grove / misinformation  (BLANK OFF_TOPIC)
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 5 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Shannon_Grove']::text[]),
  -- Sharon Quirk-Silva / homelessness  (BLANK SILENT)
    ('1e29ce86-9e02-4079-b50d-bb0d039613a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Sharon_Quirk-Silva#Campaign_themes']::text[]),
  -- Shirley N. Weber / taxes  (BLANK COMMITTEE_LIST)
    ('4ba62f32-dd20-48ce-8d84-d09bb129ad59'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are committee assignments. Sitting on a budget committee is not a position on taxes. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Shirley_Weber']::text[]),
  -- Tina S. McKinnor / abortion  (BLANK ENDORSEMENT_LIST)
    ('522efd15-f5e2-4e1a-8708-aad87410637d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Tina_McKinnor']::text[]),
  -- Tom Lackey / climate-change  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[]),
  -- Tom Lackey / fossil-fuels  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[]),
  -- Tom Lackey / homelessness  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 5 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Tom_Lackey']::text[]),
  -- Tom Lackey / school-vouchers  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[]),
  -- Tom Lackey / taxes  (BLANK COMMITTEE_LIST)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are committee assignments. Sitting on a budget committee is not a position on taxes. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[]);


INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
VALUES
  -- Adena Ishii / deportation  (REPAIR, chair 2 held)
    ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 2),
  -- Ana Valencia / public-safety-approach  (REPAIR, chair 4 held)
    ('ba647863-25fb-4ccf-9cb0-5a1c912d1b27'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 4),
  -- Angelique Ashby / tariffs  (BLANK SILENT)
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '9f094155-f604-47e8-93db-54a3142420ca'::uuid, 0),
  -- Angelique Ashby / ukraine-support  (BLANK SILENT)
    ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 0),
  -- Brian W. Jones / tariffs  (BLANK SILENT)
    ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '9f094155-f604-47e8-93db-54a3142420ca'::uuid, 0),
  -- Carl DeMaio / healthcare  (REPAIR, chair 4 held)
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 4),
  -- Carl DeMaio / medicare/aid  (BLANK SILENT)
    ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 0),
  -- Catherine Stefani / abortion  (REPAIR, chair 2 held)
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 2),
  -- Catherine Stefani / homelessness  (BLANK ENDORSEMENT_LIST)
    ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 0),
  -- Chyanne Chen / growth-and-development  (REPAIR, chair 2 held)
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '65e8ffd5-5aac-4d40-8862-a321949eafa4'::uuid, 2),
  -- Chyanne Chen / residential-zoning  (BLANK BIOGRAPHY)
    ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ef2a5e59-525a-41fa-94de-ce771df7c927'::uuid, 0),
  -- Daniel Lurie / childcare  (REPAIR, chair 2 held)
    ('708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 2),
  -- David Chiu / childcare  (BLANK SILENT)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- David Chiu / local-environment  (REPAIR, chair 2 held)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 2),
  -- David Chiu / trans-athletes  (BLANK OFF_TOPIC)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 0),
  -- David Chiu / ukraine-support  (BLANK SILENT)
    ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 0),
  -- Dawn Addis / school-vouchers  (BLANK SILENT)
    ('2ba6e476-1d62-4ac5-a70d-f4bcbe704f39'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Eunisses Hernandez / campaign-finance  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 0),
  -- Eunisses Hernandez / city-sanitation  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af3c2445-97e5-46a7-b33d-6915c13eab5c'::uuid, 0),
  -- Eunisses Hernandez / civil-rights  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Eunisses Hernandez / deportation  (REPAIR, chair 2 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 2),
  -- Eunisses Hernandez / growth-and-development  (REPAIR, chair 2 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '65e8ffd5-5aac-4d40-8862-a321949eafa4'::uuid, 2),
  -- Eunisses Hernandez / homelessness  (BLANK OFF_TOPIC)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 0),
  -- Eunisses Hernandez / jail-capacity  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 1),
  -- Eunisses Hernandez / local-environment  (BLANK BIOGRAPHY)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid, 0),
  -- Eunisses Hernandez / local-immigration  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 1),
  -- Eunisses Hernandez / public-safety-approach  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 1),
  -- Eunisses Hernandez / rent-regulation  (REPAIR, chair 2 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 2),
  -- Eunisses Hernandez / residential-zoning  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ef2a5e59-525a-41fa-94de-ce771df7c927'::uuid, 0),
  -- Eunisses Hernandez / taxes  (BLANK SILENT)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Eunisses Hernandez / transportation-priorities  (REPAIR, chair 1 held)
    ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 1),
  -- Gavin Newsom / medicare/aid  (BLANK OFF_TOPIC)
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 0),
  -- Gavin Newsom / religious-freedom  (BLANK OFF_TOPIC)
    ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Hugo Soto-Martinez / campaign-finance  (BLANK SILENT)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 0),
  -- Hugo Soto-Martinez / city-sanitation  (BLANK OFF_TOPIC)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af3c2445-97e5-46a7-b33d-6915c13eab5c'::uuid, 0),
  -- Hugo Soto-Martinez / civil-rights  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 2),
  -- Hugo Soto-Martinez / deportation  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 2),
  -- Hugo Soto-Martinez / homelessness  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 2),
  -- Hugo Soto-Martinez / jail-capacity  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 2),
  -- Hugo Soto-Martinez / public-safety-approach  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 2),
  -- Hugo Soto-Martinez / taxes  (REPAIR, chair 2 held)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Jackie Fielder / abortion  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Jackie Fielder / ai-regulation  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c594dc06-0c70-4707-8ae0-d4bc760172db'::uuid, 0),
  -- Jackie Fielder / healthcare  (BLANK PERSONAL_HEALTH)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Jackie Fielder / medicare/aid  (BLANK PERSONAL_HEALTH)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 0),
  -- Jackie Fielder / misinformation  (BLANK OFF_TOPIC)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 0),
  -- Jackie Fielder / redistricting  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Jackie Fielder / religious-freedom  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Jackie Fielder / school-vouchers  (BLANK BIOGRAPHY)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Jackie Fielder / social-security  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '8defc029-0b7e-426f-b838-a2e170f566c9'::uuid, 0),
  -- Jackie Fielder / tariffs  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '683c8084-2281-4920-a07c-18439b2dd413'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '9f094155-f604-47e8-93db-54a3142420ca'::uuid, 0),
  -- Jackie Fielder / trans-athletes  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 0),
  -- Jackie Fielder / ukraine-support  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 0),
  -- Jackie Fielder / voting-rights  (BLANK SILENT)
    ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Jesse Gabriel / taxes  (BLANK COMMITTEE_LIST)
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Jesse Gabriel / voting-rights  (BLANK OFF_TOPIC)
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Jose Luis Solache Jr. / abortion  (BLANK SILENT)
    ('1caa9043-2397-4f75-b430-acc0623d64d7'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Karen Ruth Bass / misinformation  (BLANK CHROME)
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 0),
  -- Karen Ruth Bass / voting-rights  (BLANK CHROME)
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Kathryn Barger / abortion  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Kathryn Barger / homelessness-response  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e47ec98-46af-4e77-ae81-04d1311b4543'::uuid, 0),
  -- Kathryn Barger / judicial-criminal-justice  (BLANK CHROME)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid, 0),
  -- Kathryn Barger / local-immigration  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 0),
  -- Kathryn Barger / public-safety-approach  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 0),
  -- Kathryn Barger / rent-regulation  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6fa44a68-8006-48e9-b562-6b5e61d58693'::uuid, 0),
  -- Kathryn Barger / transportation-priorities  (BLANK SURVEY_NOT_COMPLETED)
    ('122f1897-2dae-4f21-bee0-1c02c95e9e3a'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid, 0),
  -- Katy Yaroslavsky / abortion  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Katy Yaroslavsky / deportation  (BLANK SUBJECT_ARTICLE)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 0),
  -- Katy Yaroslavsky / jail-capacity  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid, 0),
  -- Katy Yaroslavsky / local-immigration  (BLANK SUBJECT_ARTICLE)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid, 0),
  -- Katy Yaroslavsky / school-vouchers  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Katy Yaroslavsky / taxes  (BLANK SILENT)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Katy Yaroslavsky / voting-rights  (BLANK ELECTION_RESULTS)
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Maria Elena Durazo / religious-freedom  (BLANK SILENT)
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Maria Elena Durazo / social-security  (BLANK OFF_TOPIC)
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '87d20824-a6e9-407b-983c-65440084a0ab'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '8defc029-0b7e-426f-b838-a2e170f566c9'::uuid, 0),
  -- Maria Elena Durazo / ukraine-support  (BLANK SILENT)
    ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '107d180d-a949-4a42-a250-54f0a7683be0'::uuid, 0),
  -- Marqueece Harris-Dawson / economic-development  (REPAIR, chair 2 held)
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 2),
  -- Marqueece Harris-Dawson / redistricting  (REPAIR, chair 1 held)
    ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 1),
  -- Matt Mahan / redistricting  (BLANK OFF_TOPIC)
    ('41949a2b-563a-4608-91c6-951c63252a91'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Michelle Rodriguez / civil-rights  (BLANK SILENT)
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Michelle Rodriguez / healthcare  (REPAIR, chair 2 held)
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Michelle Rodriguez / homelessness  (REPAIR, chair 2 held)
    ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 2),
  -- Nithya Raman / redistricting  (BLANK OFF_TOPIC)
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Nithya Raman / taxes  (BLANK OFF_TOPIC)
    ('26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Patrick J. Ahrens / abortion  (BLANK ENDORSEMENT_LIST)
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Patrick J. Ahrens / homelessness  (REPAIR, chair 3 held)
    ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 3),
  -- Raul Campillo / taxes  (BLANK OFF_TOPIC)
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Ricardo Lara / redistricting  (BLANK SURVEY_NOT_COMPLETED)
    ('bab3379b-d64e-423b-b62e-4efa04cee750'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Sean Elo-Rivera / city-sanitation  (BLANK SILENT)
    ('dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, '7687de4f-4d0b-462a-b803-bdfb23b16b42'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af3c2445-97e5-46a7-b33d-6915c13eab5c'::uuid, 0),
  -- Shamann Walton / misinformation  (BLANK SILENT)
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 0),
  -- Shamann Walton / religious-freedom  (BLANK SILENT)
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Shamann Walton / residential-zoning  (BLANK BIOGRAPHY)
    ('eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ef2a5e59-525a-41fa-94de-ce771df7c927'::uuid, 0),
  -- Shannon Grove / abortion  (REPAIR, chair 4 held)
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 4),
  -- Shannon Grove / healthcare  (BLANK COMMITTEE_LIST)
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Shannon Grove / misinformation  (BLANK OFF_TOPIC)
    ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid, 0),
  -- Sharon Quirk-Silva / homelessness  (BLANK SILENT)
    ('1e29ce86-9e02-4079-b50d-bb0d039613a2'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 0),
  -- Shirley N. Weber / taxes  (BLANK COMMITTEE_LIST)
    ('4ba62f32-dd20-48ce-8d84-d09bb129ad59'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Tina S. McKinnor / abortion  (BLANK ENDORSEMENT_LIST)
    ('522efd15-f5e2-4e1a-8708-aad87410637d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Tom Lackey / climate-change  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Tom Lackey / fossil-fuels  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Tom Lackey / homelessness  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 0),
  -- Tom Lackey / school-vouchers  (BLANK SILENT)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Tom Lackey / taxes  (BLANK COMMITTEE_LIST)
    ('e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0);


  -- Carl DeMaio / same-sex-marriage  (REPAIR, chair 3 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He announced his support for same-sex marriage after 2008 and has participated in LGBT Pride; the National Journal records that he ''has voiced support for gay marriage, abortion rights, and environmental protections.'' ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 3, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Catherine Stefani / housing  (BLANK ELECTION_RESULTS)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The only matches are this person''s own election results and vote totals, which record that they ran, not what they would do. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Catherine Stefani / same-sex-marriage  (BLANK ENDORSEMENT_LIST)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Chyanne Chen / housing  (BLANK BIOGRAPHY)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- David Chiu / same-sex-marriage  (REPAIR, chair 2 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He authored successful legislation protecting the parental rights of LGBTQ+ couples who rely on assisted reproduction. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 2, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Eunisses Hernandez / housing  (REPAIR, chair 3 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page carries a dedicated ''Positions on housing'' section: during her campaign and first term she has prioritised expanding renters'' protections and preventing displacement, and she pushed the city to build a large-scale social housing programme. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 3, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Gavin Newsom / same-sex-marriage  (REPAIR, chair 2 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: As Mayor of San Francisco he directed the city to issue marriage licences to same-sex couples in the 2004 same-sex weddings, and his page covers his opposition to Proposition 8. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 2, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Hugo Soto-Martinez / housing  (BLANK OFF_TOPIC)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The page does speak about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Jackie Fielder / same-sex-marriage  (BLANK CATEGORY_TAG)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The only matches are Wikipedia category tags in the page footer. A category records what a person IS, not what they have argued for. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Jesse Gabriel / same-sex-marriage  (REPAIR, chair 2 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He co-authored the constitutional amendment to protect marriage equality in the California Constitution. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 2, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Jessica M. Caloza / same-sex-marriage  (BLANK SILENT)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '685f2150-7b2a-4f94-992c-bf0cf23ffa69'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '685f2150-7b2a-4f94-992c-bf0cf23ffa69'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Mark Gonzalez / same-sex-marriage  (BLANK SILENT)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '005d7df1-227e-4110-b254-ec835d5b5e95'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '005d7df1-227e-4110-b254-ec835d5b5e95'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Michelle Rodriguez / housing  (BLANK SILENT)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 3 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Monica Rodriguez / housing  (BLANK BIOGRAPHY)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 4 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Rick Chavez Zbur / same-sex-marriage  (REPAIR, chair 2 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1909). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: He is a well-known LGBT civil rights advocate and was the first openly gay non-incumbent candidate to win a California congressional primary; he led Equality California before his election. ⚠ WHAT WAS WRONG BEFORE: this row cited the bare page and said nothing about what is on it, which is why the national detector read it as a biography-only row. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'ff77225c-51f9-4628-acc3-020d40382d05'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 2, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'ff77225c-51f9-4628-acc3-020d40382d05'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Todd Gloria / same-sex-marriage  (BLANK BIOGRAPHY)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1909). The chair of 2 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The only matches are biographical facts -- where the person was educated, where they live, what job they held -- which carry no position. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and it is not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;


DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND reasoning LIKE '%(migration 1909)%';
  IF n <> 119 THEN
    RAISE EXCEPTION 'migration 1909: wrote % reasoning rows, expected 119', n;
  END IF;

  SELECT count(*) INTO n
    FROM inform.politician_context c
    JOIN inform.politician_answers a ON a.politician_id = c.politician_id
     AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE 'Citation repaired%(migration 1909)%' AND a.value > 0;
  IF n <> 32 THEN
    RAISE EXCEPTION 'migration 1909: % repairs hold a live chair, expected 32', n;
  END IF;

  SELECT count(*) INTO n
    FROM inform.politician_context c
    JOIN inform.politician_answers a ON a.politician_id = c.politician_id
     AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE 'Blanked 2026-10-08 (migration 1909)%' AND a.value = 0;
  IF n <> 87 THEN
    RAISE EXCEPTION 'migration 1909: % blanks at 0, expected 87', n;
  END IF;

  -- ⚖ NO REPAIR MAY HAVE MOVED A CHAIR -- asserted against the EFFECTIVE chair each row was
  -- read at, NOT against its Season 1 value. 🔴 The first version of this guard compared to
  -- Season 1 for every repair and fired on the six rows whose chair came from Season 2, where
  -- the value legitimately differs because Season 2 renumbered the ladder. Comparing the same
  -- rung NUMBER across seasons is only valid when the chair was read from Season 1.
  WITH expected(pid, tid, val) AS (VALUES
      ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
      ('ba647863-25fb-4ccf-9cb0-5a1c912d1b27'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
      ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
      ('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
      ('0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
      ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),
      ('708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
      ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),
      ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 1),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2),
      ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1),
      ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
      ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
      ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 2),
      ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
      ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 2),
      ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2),
      ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
      ('f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
      ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
      ('ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
      ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 2),
      ('bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 3),
      ('ff77225c-51f9-4628-acc3-020d40382d05'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
      ('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4)
  )
  SELECT count(*) INTO n
    FROM expected x
    JOIN inform.politician_answers a ON a.politician_id = x.pid AND a.topic_id = x.tid
     AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   WHERE a.value <> x.val;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1909: % repaired rows are not at the chair they were read at', n;
  END IF;

  -- Season 1 untouched
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND reasoning LIKE '%migration 1909%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1909: % Season 1 rows were altered, expected 0', n;
  END IF;

  -- the four HELD rows must NOT have been written
  SELECT count(*) INTO n
    FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE '%(migration 1909)%'
     AND (p.full_name, t.topic_key) IN (
          ('Brian Gutierrez','economic-development'),
          ('Brian Gutierrez','homelessness-response'),
          ('Raul Campillo','homelessness'),
          ('Hugo Soto-Martinez','homelessness-response'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1909: % held rows were written, expected 0', n;
  END IF;

  -- and the wrong-person blanks from migration 1908 must be intact
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND reasoning LIKE '%(migration 1908)%';
  IF n <> 47 THEN
    RAISE EXCEPTION 'migration 1909: migration 1908 now shows % rows, expected 47', n;
  END IF;
END
$post$;
