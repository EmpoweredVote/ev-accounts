-- ============================================================================
-- Migration 541: Russell E. Holmes Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Russell E. Holmes (MA State Rep,
--          6th Suffolk District, HD-126, external_id=-210166).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Russell E. Holmes (HD-126, external_id=-210166, id=e96b35eb-dad1-4a29-b416-d9b10838840f) --

-- ----- Russell E. Holmes / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Holmes sponsored H.1627 (behavioral health access improvements) and H.1752 (substance use disorder treatment expansion). He represents Mattapan and parts of Roxbury/Hyde Park — communities with significant health disparities. He has focused on community health equity and behavioral health services expansion for underserved communities of color.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1627', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Holmes co-sponsored H.2093 (juvenile justice reform) and the Police Reform Act (H.4835). As a Black legislator from Mattapan, he has been a leading advocate for racial equity and ending systemic racism. He supported the CROWN Act (H.1973) protecting against hair discrimination and has championed civil rights protections for communities of color throughout his tenure.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1973', 'https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Holmes voted for the 2020 Police Reform Act (H.4835) and has been a prominent voice on police accountability reform. He has advocated for community-based violence prevention programs and mental health crisis response as alternatives to traditional policing. His Mattapan and Roxbury district has experienced high rates of police encounters and he has consistently pushed for accountability reforms and community investment.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Holmes co-sponsored H.1299 (tenant protection from eviction) and H.2219 (rent stabilization). He represents Mattapan, where Black homeownership and affordable rental housing are under significant pressure from gentrification spreading from South End and Jamaica Plain. He has been a strong advocate for rent stabilization, community land trusts, and anti-displacement policies for communities of color.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1299', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Holmes co-sponsored H.1304 (An Act to lift the ban on rent stabilization) and has been one of the House's leading advocates for allowing municipalities to implement rent control. Massachusetts banned rent control in 1994; Holmes has championed restoring local authority to regulate rents to protect Mattapan residents from displacement by rapid rent increases.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Holmes sponsored H.1891 (minority business development) and H.2065 (economic development in environmental justice communities). He has consistently advocated for targeted economic investment in Mattapan and Roxbury, focusing on minority-owned business development, workforce training for residents of color, and community wealth-building strategies.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1891', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Holmes voted for the 2021 Climate Act (H.4933) and has specifically linked climate change to racial justice, noting that communities of color in Mattapan bear disproportionate heat and pollution burdens. He has advocated for climate resilience investment in Environmental Justice communities and supported the Environmental Justice Act.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Holmes co-sponsored the Environmental Justice Policy Act (H.4264) and has been a champion of linking environmental justice to racial equity in Mattapan. His district is surrounded by highways and industrial zones generating disproportionate pollution burdens. He has advocated for urban tree canopy expansion, urban agriculture, and green infrastructure investment to improve environmental quality in his community.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Holmes co-sponsored the Safe Communities Act (H.3369) and has supported immigrant integration services. Mattapan has a large Haitian-American immigrant community; he has championed their rights and access to state services regardless of immigration status. He has publicly opposed ICE enforcement actions targeting Boston's immigrant communities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Holmes co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). He has connected reproductive rights to racial justice, noting that abortion restrictions have disproportionate impacts on women of color. His stance is full support for comprehensive abortion access with MassHealth coverage and no gestational limits in appropriate circumstances.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Russell E. Holmes / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e96b35eb-dad1-4a29-b416-d9b10838840f',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Holmes co-sponsored H.1795 (prison moratorium) and has been a consistent advocate for reducing incarceration. Mattapan has been among the Boston neighborhoods most affected by mass incarceration, with significant numbers of residents having been incarcerated. He has championed decarceration, community-based alternatives, and reentry support programs rather than expanding correctional capacity.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1795', 'https://malegislature.gov/Legislators/Profile/REH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e96b35eb-dad1-4a29-b416-d9b10838840f';
-- unpaired=0, uncited=0
