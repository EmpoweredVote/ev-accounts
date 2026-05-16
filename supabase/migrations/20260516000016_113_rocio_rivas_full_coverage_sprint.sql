-- Full coverage sprint for Rocio Rivas (politician_id: b2cb156d-7322-470d-9f82-6f08e18991e8)
-- LAUSD Board of Education (DSA/UTLA-backed); confirmed running in District 2 (Eastside/Central LA)
-- in the June 2026 primary per LAist/Knock LA voter guides.
-- Group A: add/update sources on 5 thin context rows
--          (deportation ×2 IDs, immigration ×2 IDs + value correction 1.0→2.0, school-vouchers)
-- Group B: 3 new answer+context rows (civil-rights=2, childcare=2, local-immigration=1)
-- Skipped: abortion, same-sex-marriage, religious-freedom, trans-athletes, voting-rights,
--          residential-zoning, rent-regulation, growth-and-development, transportation-priorities,
--          economic-development, jail-capacity, misinformation, homelessness, homelessness-response,
--          fossil-fuels, campaign-finance — no verifiable evidence found

-- ── GROUP A: Add sources / update thin context rows ──────────────────────────

-- deportation (both topic IDs — duplicate UUIDs in compass_topics)
UPDATE inform.politician_context SET
  reasoning = 'Rivas urged LAUSD to distribute Know Your Rights cards and resources to students and families ''regardless of immigration status'' following Trump administration''s Jan. 2025 directive allowing ICE arrests near schools. LAUSD has maintained a sanctuary district policy since 2016, and Rivas''s advocacy is consistent with protecting long-term residents from deportation while supporting legal pathways — aligning with deporting only violent offenders and providing legal status to others.',
  sources = ARRAY[
    'https://laist.com/news/education/lausd-equips-students-red-cards-defend-their-rights-when-encountering-immigration-agents',
    'https://laist.com/news/education/immigration-activism-and-fear-deflate-attendance-la-schools',
    'https://drrivasforschoolboard.com/'
  ]
WHERE politician_id = 'b2cb156d-7322-470d-9f82-6f08e18991e8'
  AND topic_id IN ('83eeb217-0289-47df-bde9-c53866b5b3e9','44905f3b-e105-4f6c-afc7-5d223813dbac');

-- immigration: correct value 1.0→2.0 on one row; update sources on both rows
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'b2cb156d-7322-470d-9f82-6f08e18991e8'
  AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

UPDATE inform.politician_context SET
  reasoning = 'Rivas explicitly framed her advocacy around protecting immigrant families, urging LAUSD to distribute rights resources ''regardless of immigration status'' (Jan. 2025). Her campaign platform lists ''immigrant families'' as a key constituency she serves. As a DSA-endorsed UTLA-backed board member representing a district with high concentrations of undocumented residents, her record reflects strong support for expanded protections and legal pathways rather than open borders.',
  sources = ARRAY[
    'https://laist.com/news/education/lausd-equips-students-red-cards-defend-their-rights-when-encountering-immigration-agents',
    'https://drrivasforschoolboard.com/',
    'https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/'
  ]
WHERE politician_id = 'b2cb156d-7322-470d-9f82-6f08e18991e8'
  AND topic_id IN ('4e2c69ce-591e-4197-9cd5-7aceff79d390','c6957429-bc9e-48e7-b36f-a102b968a972');

-- school-vouchers
UPDATE inform.politician_context SET
  reasoning = 'Rivas is a strong opponent of school privatization. She voted YES on the Feb. 2024 LAUSD board resolution restricting charter school co-location on the district''s most vulnerable campuses (4-3 vote), and the 2026 LAist voter guide confirms she authored the co-location policy to protect neighborhood schools. In her 2022 campaign she stated charters must demonstrate superiority over district-run schools and supported closing underperforming charters. She is endorsed by UTLA, whose platform explicitly opposes vouchers and charter expansion.',
  sources = ARRAY[
    'https://laist.com/news/education/how-charter-schools-are-steered-away-from-lausds-most-fragile-campuses',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-los-angeles-unified-school-board-district-2',
    'https://laist.com/news/politics/2022-election-california-general-los-angeles-county-lausd-school-board'
  ]
WHERE politician_id = 'b2cb156d-7322-470d-9f82-6f08e18991e8'
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b2cb156d-7322-470d-9f82-6f08e18991e8', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b2cb156d-7322-470d-9f82-6f08e18991e8', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Rivas co-authored a resolution in March 2026 calling for LAUSD to rename schools honoring Cesar Chavez due to sexual assault allegations, stating ''prioritize student safety, dignity and truth.'' She has consistently championed students of color and LGBTQ+ youth on her board platform, and voted NO on a layoff plan in Feb. 2026 stating ''I will not accept reductions in force as a default response without a clear discipline showing that this is the most responsible and strategic course available to us.'' Endorsed by LA County Federation of Labor.',
  ARRAY[
    'https://laist.com/news/education/lausd-school-board-members-name-change-chavez-schools',
    'https://laist.com/news/education/lausd-board-approves-plan-that-could-see-significant-job-cuts-what-happens-now',
    'https://drrivasforschoolboard.com/'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b2cb156d-7322-470d-9f82-6f08e18991e8', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b2cb156d-7322-470d-9f82-6f08e18991e8', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'In her 2022 campaign Rivas called for the state to significantly expand funding for early childhood education, stating she wants to ''double, if not triple that budget'' for early childhood centers in high-need areas. She linked declining enrollment in part to inadequate early childhood infrastructure and advocated for major state investment. This aligns with substantially expanding childcare subsidies and provider grants.',
  ARRAY['https://laist.com/news/politics/2022-election-california-general-los-angeles-county-lausd-school-board'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b2cb156d-7322-470d-9f82-6f08e18991e8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b2cb156d-7322-470d-9f82-6f08e18991e8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Rivas urged LAUSD to distribute Know Your Rights materials ''regardless of immigration status'' and supports LAUSD''s sanctuary district policy (in place since 2016) which prohibits collecting or sharing immigration status information. She has been an active voice for protecting immigrant students from federal immigration enforcement, consistent with refusing all ICE detainers and prohibiting district employees from sharing immigration status with federal agencies.',
  ARRAY[
    'https://laist.com/news/education/lausd-equips-students-red-cards-defend-their-rights-when-encountering-immigration-agents',
    'https://laist.com/news/education/california-leaders-reject-trump-administration-order-to-allow-immigration-enforcement-in-schools',
    'https://drrivasforschoolboard.com/'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
