-- ============================================================================
-- Migration 445: Manny Cruz Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Manny Cruz (MA State Rep, HD-30,
--   7th Essex District, Salem).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e (external_id=-210070)

BEGIN;

-- ----- Manny Cruz / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cruz co-sponsored the Abortion Access Act as tracked by Act on Mass, a bill that would expand and strengthen abortion access protections in Massachusetts. He also co-sponsored birth center and midwifery coverage legislation (H.1117), reflecting a comprehensive reproductive healthcare stance.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Bills/194/H1117']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cruz co-sponsored the Safe Communities Act (Act on Mass) — Massachusetts's sanctuary bill limiting local law enforcement from assisting with federal immigration enforcement. He also sponsored H.1994 to protect tenants from retaliation by landlords who threaten to disclose immigration status, directly protecting immigrant community members in Salem. These bills reflect a strong pro-immigrant protection stance.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Bills/194/H1994']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Cruz sponsored H.1994 to protect tenants from retaliation by landlords who threaten to disclose immigration status to conceal wage or tax violations, and H.2176 relative to employer disclosure of immigration status to conceal wage, benefit, or tax law violations. These local-level immigration protection bills address workplace and housing exploitation of immigrant communities in Essex County.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1994', 'https://malegislature.gov/Bills/194/H2176']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cruz co-sponsored Medicare for All, the CARE Act, and the Cherish Act (Act on Mass). He sponsored H.1117 relative to insurance coverage of birth centers and the midwifery workforce, H.761 on the long-term care workforce and capital trust fund, and H.1426 on deferred maintenance for public college buildings including a green and healthy buildings commission. These bills reflect strong support for universal healthcare coverage and expanded public health infrastructure.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Bills/194/H1117', 'https://malegislature.gov/Bills/194/H761']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cruz sponsored H.1482 to establish an accessory dwelling unit trust fund (expanding affordable housing supply) and H.1483 relative to the use of credit reporting for rent-subsidized tenants (tenant protection). He also sponsored H.1994 protecting tenants from landlord retaliation and co-sponsored H.4568 on the Family Self-Sufficiency Program. This housing portfolio reflects both supply-side (ADU fund) and demand-side (tenant protection) housing priorities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1482', 'https://malegislature.gov/Bills/194/H1483', 'https://malegislature.gov/Bills/194/H1994']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cruz co-sponsored Healthy Youth Act (LGBTQ+ inclusive sex education), Ban Native American Mascots, Indigenous Peoples Day, and Support Native Students legislation (Act on Mass). He serves on the Joint Committee on Racial Equity, Civil Rights, and Inclusion. He also sponsored H.1923 on the age of criminal majority. These bills reflect a comprehensive civil rights priority across racial, gender, and LGBTQ+ dimensions.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Legislators/Profile/M_C3/Committees', 'https://malegislature.gov/Bills/194/H1923']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Cruz co-sponsored Campaign Childcare legislation as tracked by Act on Mass, which would make childcare more affordable and accessible. He also co-sponsored H.210 relative to school attendance requirements for certain aid programs, reflecting an interest in connecting family support services to educational outcomes for children.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Bills/194/H210']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Cruz co-sponsored Right to Unionize for Ride Share Drivers and Stop Wage Theft legislation (Act on Mass). He sponsored H.2080 on job training for workers with limited-English proficiency, H.2081 on minimum gratuity while dining (service worker wages), and H.536 on a municipal education fund for DESE. These bills reflect a strong worker rights and community economic development focus for a diverse urban district.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Bills/194/H2080', 'https://malegislature.gov/Bills/194/H2081']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Cruz / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cruz co-sponsored Progressive Revenue and Stop Corporate Offshoring legislation (Act on Mass), reflecting support for progressive tax policy and higher taxes on corporations. He also co-sponsored a local option sales tax bill for Salem — a local fiscal tool to generate city revenue. His tax bills reflect a balanced approach of progressive state taxes combined with local revenue authority.$$,
        ARRAY['https://actonmass.org/legislators/manny-cruz/', 'https://malegislature.gov/Legislators/Profile/M_C3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
