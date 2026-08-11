-- 1687_md_surname_adjudicated_accepts.sql
--
-- The 32 SURNAME_ONLY rows held back from 1685, now adjudicated one at a time.
-- A bill sponsor sharing a surname is NOT the same person until proved. Each candidate slug was
-- resolved by reading its member page title; slugs change when a member switches chamber, so dead
-- slugs were retried WITH THE BILL'S SESSION (`washington?ys=2019RS` = "Delegate Mary L. Washington").
--
--   19 ACCEPT  (this migration) -- sponsoring slug proved to be the same person
--   11 REJECT  -- a genuinely DIFFERENT legislator: Guy Guzzone (3), Frank S. Turner (2),
--                Pat Young (1), Mary/Mary L. Washington (5 filed under Alonzo T. Washington)
--    2 HOLD    -- slug `washington` on 2022RS HB0937 resolves in no session: UNKNOWN, not negative
--
-- Auto-accepting surname matches would have credited four other legislators' sponsorships to the
-- wrong people. That is why they were held out of 1685.
--
-- 🔴 SECOND DEFECT FOUND HERE, WIDER THAN THIS QUEUE: a cited member slug can belong to ANOTHER REAL
-- POLITICIAN. `jones01` is **Dana Jones** yet is cited by all 17 of Adrienne A. Jones's stances;
-- `king01` is **James M. King**, cited by Nancy J. King. Corpus-wide: of 176 politicians citing an
-- mgaleg member page, 143 OK, 22 cite a DEAD slug, 10 cite a DIFFERENT PERSON. Invisible to every
-- earlier check because the page resolves, is a real member page, and carries the right surname.
-- This migration fixes the slug only on the 19 rows it already touches; the rest is a separate repair.
--
-- No stance VALUE is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-surname-accepts-1687-rollback.json
--
BEGIN
;

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1413?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Adrienne A. Jones / Childcare Affordability & Access  (slug jones01 -> jones)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1056?ys=2014RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- Adrienne A. Jones / Criminal Justice Approach  (slug jones01 -> jones)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1413?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Adrienne A. Jones / Economic Development Incentives  (slug jones01 -> jones)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0554?ys=2014RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Adrienne A. Jones / Immigration and Treatment of Immigrants  (slug jones01 -> jones)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1413?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Adrienne A. Jones / School Vouchers & Public Education Funding  (slug jones01 -> jones)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1413?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Adrienne A. Jones / Taxation and Public Spending  (slug jones01 -> jones)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Antonio Hayes / Climate Change and Environmental Protection  (slug hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0915?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Cory V. McCray / School Vouchers & Public Education Funding  (slug mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0583?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Dana Stein / Climate Change and Environmental Protection  (slug stein01 -> stein)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0583?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Dana Stein / Fossil Fuel Policy  (slug stein01 -> stein)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Dana Stein / Reproductive Rights and Abortion Access  (slug stein01 -> stein)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Heather Bagnall / Reproductive Rights and Abortion Access  (slug bagnall -> bagnall01)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0779?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Mary Beth Carozza / Climate Change and Environmental Protection  (slug carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1413?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01','https://ballotpedia.org/Mary_Washington']::text[]
WHERE politician_id = '38404814-7be0-40e3-b044-062f98b2a5b0'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Mary Washington / School Vouchers & Public Education Funding  (slug washington01 -> washington01)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Nancy J. King / Climate Change and Environmental Protection  (slug king01 -> king)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Nancy J. King / Fossil Fuel Policy  (slug king01 -> king)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1000?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Nancy J. King / School Vouchers & Public Education Funding  (slug king01 -> king)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1533?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Terri L. Hill / Civil Rights and Social Justice  (slug hill04 -> hill02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Terri L. Hill / Reproductive Rights and Abortion Access  (slug hill04 -> hill02)

DO $$
DECLARE bad int;
BEGIN
  -- Every touched row must carry a bill citation.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('04e1a744-acf5-4453-9172-7135b6bfce96'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('38404814-7be0-40e3-b044-062f98b2a5b0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid)
  ) AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % touched row(s) lack a bill citation', bad; END IF;

  -- No touched row may still cite a slug proved to be the wrong person or dead.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('04e1a744-acf5-4453-9172-7135b6bfce96'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('38404814-7be0-40e3-b044-062f98b2a5b0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid)
  ) AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE
        s LIKE '%Members/Details/jones01%' OR s LIKE '%Members/Details/king01%'
     OR s LIKE '%Members/Details/stein01%' OR s LIKE '%Members/Details/hill04%'
     OR s LIKE '%Members/Details/hayes01%' OR s LIKE '%Members/Details/mccray01%'
     OR s LIKE '%Members/Details/bagnall?%' OR s LIKE '%Members/Details/bagnall'
     OR s LIKE '%Members/Details/carozza01%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite a bad member slug', bad; END IF;
END
$$;

COMMIT
;
