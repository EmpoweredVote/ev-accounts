-- ============================================================================
-- Migration 552: Kevin G. Honan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kevin G. Honan (MA State Rep,
--          17th Suffolk District, HD-137, external_id=-210177).
--          Long-serving Brighton/Allston representative; Chair of Housing Committee.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Kevin G. Honan (HD-137, external_id=-210177, id=c7c8d91f-156b-42ea-93f1-7dac0c4080a4) --

-- ----- Kevin G. Honan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$As Chair of the Joint Committee on Housing, Honan has been the Legislature's leading voice on housing policy for over a decade. He was the primary House driver of the Affordable Homes Act (H.4977), a $5.16 billion housing investment package. He has championed affordable housing production, first-time homebuyer programs, and tenant protections throughout his tenure representing Brighton.$$,
        ARRAY['https://malegislature.gov/Bills/193/H4977', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Honan co-authored the 2021 MBTA Communities Act (H.4933 Section 3A), requiring transit-adjacent municipalities to permit multifamily housing near transit. As Housing Committee Chair, he has championed zoning reform to allow more housing near MBTA stations. He supports upzoning near transit while balancing neighborhood character concerns in his Brighton district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Honan sponsored H.1693 (behavioral health access for residents) and H.1801 (substance use disorder services). He represents Brighton — home to significant student and immigrant populations with behavioral health needs. His healthcare priorities focus on community health center funding and behavioral health expansion rather than structural universal coverage reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1693', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$As Housing Committee Chair, Honan has navigated the rent control debate carefully. He has acknowledged rent stabilization as a tool some municipalities might use while advocating for production-first approaches. The Affordable Homes Act he championed included just-cause eviction provisions but not direct rent control restoration. His position leans toward production and tenant protections over price controls.$$,
        ARRAY['https://malegislature.gov/Bills/193/H4977', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Honan voted for the 2021 Climate Act (H.4933) and has incorporated climate resilience provisions into the Affordable Homes Act including green building standards. He has championed transit-oriented housing development as both a housing and climate strategy. His approach connects housing production near transit with reducing greenhouse gas emissions from transportation.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Honan co-sponsored the Safe Communities Act (H.3369) and has supported immigrant integration through housing access. Brighton has a significant immigrant population from Brazil, China, and other countries; he has advocated for immigrant access to affordable housing programs. His moderate stance reflects a pragmatic approach to immigrant integration through policy rather than frontline advocacy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Honan voted for the ROE Act (H.3320) in 2020. He is a longtime Brighton Democrat and represents a district with significant Catholic constituencies. He voted for abortion access expansion through the ROE Act while not being among the leading advocates on reproductive rights in the House.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Honan has been a champion of transit-oriented development policy, explicitly linking housing production near MBTA stations through the MBTA Communities Act (H.4933). Brighton's Green Line B branch service improvements have been a longstanding advocacy point. His housing chairmanship has made transit investment integral to his broader housing production agenda.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Honan voted for the Police Reform Act (H.4835) as a veteran House Democrat. He represents Brighton and Allston — neighborhoods with both student populations and working-class communities that have varying views on public safety. His moderate stance reflects support for accountability reforms while maintaining traditional community policing as a valued institution.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin G. Honan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Honan has supported economic development tied to housing production — viewing residential construction as economic stimulus. He represents Allston-Brighton, home to Harvard and Boston University institutions that drive significant economic activity. His economic development approach centers on housing production, job creation through construction, and university-community partnerships rather than targeted redistribution programs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KGH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c7c8d91f-156b-42ea-93f1-7dac0c4080a4';
-- unpaired=0, uncited=0
