-- Full coverage sprint for Marissa Roy (politician_id: 7157dd95-0f1b-4e05-bd4f-39317345b47c)
-- 2026 LA City Attorney challenger; Deputy AG at California DOJ (Consumer Protection/Tenant Rights)
-- Group A: add sources to 9 existing thin context rows (all value=2)
--          (climate-change, economic-development, growth-and-development, homelessness-response,
--           immigration, local-environment, public-safety-approach, rent-regulation, residential-zoning)
-- Group B: insert 8 new answer+context rows
--          (same-sex-marriage, religious-freedom, abortion, deportation, fossil-fuels,
--           homelessness, housing, jail-capacity)
-- Skipped: healthcare, taxes, school-vouchers, childcare, misinformation, trans-athletes,
--          voting-rights, transportation-priorities, city-sanitation — no evidence for City Attorney role

-- ── GROUP A: Add sources to existing thin context rows ───────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Roy''s platform explicitly pledges to file lawsuits against corporate polluters responsible for climate change and references her experience assisting California cities in holding oil companies accountable for fossil fuel climate impact misrepresentation. Her approach — aggressive litigation against fossil fuel companies while supporting community greening projects — aligns with a rapid clean-energy transition stance.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/meet-marissa']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

UPDATE inform.politician_context SET
  reasoning = 'Roy''s platform frames the City Attorney''s office as ''the largest public interest law firm in the city'' focused on combating wage theft, worker misclassification, and corporate fraud rather than attracting businesses through subsidies or tax abatements. Her endorsers include DSA Los Angeles, labor unions, and progressive clubs — not business chambers — suggesting opposition to large corporate incentives while supporting worker-centered economic programs.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/endorsements']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

UPDATE inform.politician_context SET
  reasoning = 'Roy criticizes the incumbent for blocking approved affordable housing projects and obstructing Stay Housed LA programming, and proposes expediting approved housing construction. This implies support for growth where infrastructure supports it and where affordable units are included, rather than imposing growth limits or removing all regulatory barriers.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

UPDATE inform.politician_context SET
  reasoning = 'Roy''s platform frames homelessness as rooted in ''skyrocketing rents, stagnant wages, and housing shortage'' and proposes expanding diversion programs connecting people to mental health treatment, addiction services, housing, and vocational training rather than criminalization. She criticizes the incumbent for blocking affordable housing that would address root causes.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';

UPDATE inform.politician_context SET
  reasoning = 'As outside counsel for LA County during Trump''s first term, Roy defended sanctuary cities, DACA recipients, students, and asylum seekers in over a dozen legal actions. Her platform pledges to fight ICE tactics she characterizes as constitutional violations and to lead direct legal challenges against federal immigration enforcement affecting LA residents.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/meet-marissa']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

UPDATE inform.politician_context SET
  reasoning = 'Roy''s platform commits to filing lawsuits against corporate polluters responsible for toxic dumping and environmental deception, with recovery funds supporting community greening projects. She references experience assisting California cities in holding oil companies accountable. This reflects strong environmental protection enforcement while allowing development that meets standards.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';

UPDATE inform.politician_context SET
  reasoning = 'Roy explicitly opposes criminalization as the primary public safety tool, stating she will expand diversion programs that connect people to mental health treatment, addiction services, housing, and vocational training to reduce recidivism. She describes her approach as ''getting serious about public safety with strategies that break cycles of criminalization,'' consistent with maintaining current staffing while shifting non-violent calls to services.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/what-is-the-city-attorney']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

UPDATE inform.politician_context SET
  reasoning = 'Roy''s platform establishes a Tenants'' Rights Team to combat unlawful evictions, security deposit scams, uninhabitable conditions, and landlord harassment, and references her current work with California''s DOJ on corporate housing law violations. She explicitly criticizes the incumbent for blocking Stay Housed LA programming. This reflects strong tenant protection enforcement and support for expanding rent stabilization coverage.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/meet-marissa']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';

UPDATE inform.politician_context SET
  reasoning = 'Roy criticizes the incumbent City Attorney for obstructing approved affordable housing projects, advocates for expediting approved housing construction, and identifies housing shortage as a root cause of homelessness. Her platform implies support for allowing multifamily housing development while maintaining community input processes, consistent with a modest-density-increase approach rather than eliminating zoning rules entirely.',
  sources = ARRAY['https://www.marissaroy.com/the-people-s-platform']
WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','c5ab4eab-702f-49b8-9277-8ea53f3835c6',
  'Roy credits Prop 8''s passage in 2008 with inspiring her entire legal career — she witnessed San Francisco''s City Attorney challenge the proposition and decided to pursue public interest law as a result. She has received endorsements from Stonewall Democratic Club and California Women''s List. She supports full federal marriage equality and protections without religious exemptions undermining LGBTQ rights.',
  ARRAY['https://www.marissaroy.com/meet-marissa','https://www.marissaroy.com/endorsements'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','6b9ba6d9-1001-43f5-b073-4d37130696fd',
  'Roy''s origin story — entering public service specifically to fight Prop 8, which was backed by religious organizations seeking an exemption from civil rights norms — signals that she would not allow religious freedom claims to override anti-discrimination protections in employment or housing. Her platform''s focus on civil rights enforcement and opposition to ''constitutional violations'' reflects a balance-of-rights rather than religious-exemption-first approach.',
  ARRAY['https://www.marissaroy.com/meet-marissa','https://www.marissaroy.com/the-people-s-platform'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  'Roy currently works as a Deputy Attorney General at the California DOJ under Rob Bonta, who has been one of the nation''s most aggressive defenders of abortion access, and she received Bonta''s personal endorsement. Her platform explicitly commits to resisting ''unconstitutional attacks from the Trump administration'' and defending California residents'' rights — which in California''s legal context centrally includes reproductive rights.',
  ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/endorsements'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','44905f3b-e105-4f6c-afc7-5d223813dbac',
  'Roy''s platform characterizes federal immigration enforcement tactics as ''constitutional violations'' and ''fascism in action,'' and pledges to lead legal challenges against ICE operations affecting LA residents. Her experience includes defending DACA recipients and asylum seekers from removal. This strongly implies she would support deporting only those who commit serious violent crimes while providing legal status to others.',
  ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/meet-marissa'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'a22215c3-6693-4bc2-b248-01aebba14570', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','a22215c3-6693-4bc2-b248-01aebba14570',
  'Roy''s platform explicitly pledges to hold oil companies accountable for fossil fuel climate impact misrepresentation and references experience assisting California cities in climate litigation against fossil fuel companies. Her environmental enforcement approach — stopping corporate environmental deception and pursuing polluters — aligns with stopping new fossil fuel permits rather than maintaining current levels or expanding extraction.',
  ARRAY['https://www.marissaroy.com/the-people-s-platform'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','4938766b-b45a-46e3-93bd-b8b30651271a',
  'Roy''s platform identifies housing shortage, skyrocketing rents, and stagnant wages as core causes of homelessness and proposes scaling the tenants'' rights team, expediting approved affordable housing construction, and expanding diversion programs for mental health and addiction services. This reflects a build-more-affordable-housing and expand-services approach rather than either a guaranteed-housing right or enforcement-first stance.',
  ARRAY['https://www.marissaroy.com/the-people-s-platform'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','669cac97-66a6-4087-b036-936fbe62efb3',
  'Roy criticizes the incumbent for blocking affordable housing projects and obstructing Stay Housed LA programming, proposes expediting approved affordable housing construction, and pledges to defend tenants against wrongful eviction as a core City Attorney function. Her current work at California DOJ includes investigating violations of state housing law. This reflects support for building affordable housing and expanding rental assistance programs.',
  ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/meet-marissa'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c','c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
  'Roy''s platform explicitly rejects criminalization as a primary response to crime and public disorder, pledging to expand diversion programs that connect people to mental health treatment, addiction services, housing, and vocational training to break cycles of recidivism. She describes this as a core City Attorney function. This aligns with reducing the incarcerated population through pretrial diversion and treatment alternatives rather than building new capacity.',
  ARRAY['https://www.marissaroy.com/the-people-s-platform','https://www.marissaroy.com/what-is-the-city-attorney'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
