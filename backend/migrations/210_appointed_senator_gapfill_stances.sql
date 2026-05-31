-- ============================================================================
-- Migration 210: Appointed Senator Gap-Fill (Armstrong OK + Husted OH)
-- ============================================================================
-- Purpose: Insert/upsert stance data for 2 politicians.
--
-- Topic scope: All applicable topics.
--
-- Post-state: ~9 rows expected
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ============================================================
-- Alan Armstrong
-- ============================================================

-- ----- Alan Armstrong / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Armstrong voted YEA on March 24 2026 on two procedural votes (v67 and v68) that advanced S.1383, the "Protection of Women and Girls in Sports Act," blocking Democratic motions that would have sent the bill back to committee. The Tuberville Amendment to S.1383 was explicitly "to protect women and girls in athletics" (v60, March 21 — before Armstrong was seated, all Republicans voted YEA). Armstrong's consistent YEA on S.1383 procedural motions on his first day in the Senate reflects support for requiring transgender athletes to compete on teams matching their biological sex.$$,
        ARRAY['https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00067.htm', 'https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00068.htm', 'https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00060.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Armstrong / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Armstrong voted YEA on confirmation of every Trump-nominated federal district judge he participated in: Christopher R. Wolfe for Western District of Texas (v77/v78, April 14 2026), Andrew B. Davis for Western District of Texas (v85/v86, April 16/20 2026), John Thomas Shepherd for Western District of Arkansas (v75/v76, April 13/14 2026), and Sheria Akins Clarke for District of South Carolina (v126/v127, May 19 2026). Trump's judicial nominees are selected by the Federalist Society for adherence to originalist/textualist judicial philosophy — the view that the Constitution means what it said when written. Armstrong's unanimous support signals alignment with this interpretive approach.$$,
        ARRAY['https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00078.htm', 'https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00086.htm', 'https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00076.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Armstrong / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Armstrong voted YEA on all four Trump-nominated federal district judge confirmations he participated in (Wolfe v78, Davis v86, Shepherd v76, Clarke v127 — April-May 2026). Trump's judicial nominees emphasize accountability, victim rights, and law enforcement deference over rehabilitative or restorative approaches. He also voted YEA on the ATF Director nomination (Robert Cekada, v109, April 29 2026), signaling support for traditional law enforcement. No votes on specific criminal justice reform legislation (sentencing, pretrial detention, alternatives to incarceration) occurred in this session, but his consistent support for enforcement-focused nominees aligns with accountability-first criminal justice values.$$,
        ARRAY['https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00109.htm', 'https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00078.htm', 'https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00076.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jon Husted
-- ============================================================

-- ----- Jon Husted / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted Yea on final passage of H.R. 6644, a bipartisan bill to increase housing supply through market-oriented and deregulatory mechanisms (89-10, March 12 2026). Voted Nay on a Democratic amendment (S.Amdt. 5235) to restrict hedge fund ownership of single-family homes — a renter-protection measure Husted and all Republicans opposed (April 23 2026). This supply-side approach without renter protections aligns with private developer solutions over expanded federal assistance.$$,
        ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=2&vote=00053', 'https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=2&vote=00100', 'https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=2&vote=00045']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Husted / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Husted has explicitly stated that the most important government function is to 'protect people, property' and has backed law enforcement-first legislation including the Protect and Serve Act and LEOSA Reform Act. He framed opposition to Biden-era policies as allowing 'high crime,' signaling enforcement-priority orientation. No statements supporting decriminalization of sleeping in public or housing-first alternatives were found.$$,
        ARRAY['https://husted.senate.gov/media/press-releases/husted-backs-national-police-week-resolution-law-enforcement-safety-bill', 'https://husted.senate.gov/media/press-releases/husted-backs-senate-framework-to-fund-law-enforcement-keep-border-secure']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Husted / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Husted's consistent emphasis on enforcement over services — backing law enforcement legislation, opposing DHS funding restrictions, and prioritizing public safety as the primary government function — points to enforcement as his primary homelessness response tool. His vote against the hedge fund housing amendment also signals skepticism toward government interventions to improve housing affordability for lower-income residents.$$,
        ARRAY['https://husted.senate.gov/media/press-releases/husted-backs-national-police-week-resolution-law-enforcement-safety-bill', 'https://husted.senate.gov/media/press-releases/husted-backs-senate-framework-to-fund-law-enforcement-keep-border-secure']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Husted / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Husted voted Yea on the confirmation of Gadyaces Serralta as Director of the U.S. Marshals Service (119th Congress, Session 1, Vote 460), supporting expanded federal law enforcement capacity. He backed law enforcement funding through the DHS framework (April 23 2026 press release) and has expressed no support for prison diversion, bail reform, or incarceration alternatives. His 'protect people, property' philosophy aligns with building capacity over reducing the incarcerated population.$$,
        ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=1&vote=00460', 'https://husted.senate.gov/media/press-releases/husted-backs-senate-framework-to-fund-law-enforcement-keep-border-secure']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Husted / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Husted stated the most important government function is to 'protect people, property' and said 'We cannot go back to the Biden administration's dangerous policies of open borders and high crime.' He backed the Protect and Serve Act (federal penalties for crimes targeting officers), the LEOSA Reform Act (expanded officer carry rights), and voted Yea on Kash Patel for FBI Director (Vote 60, Session 1). His record consistently prioritizes punishment and deterrence over rehabilitation.$$,
        ARRAY['https://husted.senate.gov/media/press-releases/husted-backs-national-police-week-resolution-law-enforcement-safety-bill', 'https://husted.senate.gov/media/press-releases/husted-backs-senate-framework-to-fund-law-enforcement-keep-border-secure', 'https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=1&vote=00060']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Husted / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5740b38-9b65-431a-9e33-645d432dec61',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Husted voted Yea on every Trump judicial nominee in the 119th Congress, including party-line confirmations of LaCour (51-47, Oct 2025), Maxwell (51-46), Chamberlin (51-46), Bragdon (53-45), and Evan Rikhye (52-47, May 2026). Trump's nominees are uniformly Federalist Society-vetted textualists and originalists; Democratic opposition was nearly unanimous on the contested picks. Husted's consistent alignment with these nominees across all 10+ votes signals a clear originalist/textualist judicial philosophy.$$,
        ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=1&vote=00596', 'https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=1&vote=00640', 'https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=2&vote=00130']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Per-candidate row count (every candidate must have >= 10 topics):
-- SELECT p.full_name, COUNT(pa.topic_id) AS topic_count
-- FROM essentials.politicians p
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
-- WHERE p.id IN ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387', 'd5740b38-9b65-431a-9e33-645d432dec61')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387', 'd5740b38-9b65-431a-9e33-645d432dec61')
--   AND pc.politician_id IS NULL;