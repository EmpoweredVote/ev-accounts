-- 1690_resource_md_surname_rejects.sql
--
-- The 4 pass-4c REJECT rows that READING SHOWED WERE RIGHT. Pass 4b had rejected them because the bill
-- it matched was sponsored by a different same-surname legislator -- but that match was its own error:
-- the prose states a YEAR and the matcher resolved bare bill numbers across all 14 sessions.
--
-- 🔑 Checked at the session the prose actually states, each politician IS a sponsor -- of a bill with a
-- different NUMBER than the prose gave. So the substance was true and the number was wrong, which is the
-- opposite conclusion from "this row credits someone else's bill".
--
-- Reasoning is repaired alongside the citation because it is VOTER-FACING and carried the wrong number.
-- Precedent for reasoning repair: migs 1524, 1526.
--
-- NOT in this migration, and why:
--   7 rows UNVERIFIED, left untouched -- Alonzo T. Washington (6) and Mary Washington (1) say "supported"
--     / "backed" / "voted YES", never "sponsored". A sponsor list cannot settle a floor vote, and BOTH
--     were in office for every bill named (Washington: House 2012-12-19 to 2023-01-30, then Senate;
--     M. Washington: House 2011-2019, Senate since 2019). Their claims are UNVERIFIED, not false, and
--     roll calls are separate PDFs. ⚠ Adding the matched bill would credit MARY Washington's sponsorship
--     to ALONZO -- exactly the error 1685 held these rows back to avoid.
--   2 rows PRE-TENURE and unsupported -- Pam Lanman Guzzone / School Vouchers and / Taxation both rest
--     solely on the Blueprint for Maryland's Future (2019/2020). She took office 2023-01-11, so she
--     cannot have supported it. She sponsors NONE of the 23 in-tenure voucher/BOOST bills nor any of the
--     14 in-tenure progressive-tax bills. Held for an operator decision -- retirement is the one
--     irreversible step on this workstream.
--
-- No stance VALUE is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-surname-rejects-1690-rollback.json
--
BEGIN
;

-- Caylin Young / Voting Rights and Electoral Integrity
-- HB0350 (2026) "Voting Rights Act of 2026 - Counties and Municipal Corporations"; young05 IS a sponsor. The prose already named this title exactly; pass 4b had matched a 2017 bill of Pat Young.
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]
WHERE politician_id = '92075c9b-6c7e-4763-981f-5a42a8afddf5'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;

-- Veronica Turner / Affordable Housing
-- Prose said "HB0480 (2026)"; 2026 HB0480 is "Transportation Network Companies - Deactivation of Operators". The bill she describes -- "Fair Housing and Housing Discrimination - Regulations, Intent, and Discriminatory Effect" -- is 2026 HB0573, and turner01 IS a sponsor.
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0573?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[], reasoning = 'Sponsored HB0573 (2026) — Fair Housing and Housing Discrimination - Regulations, Intent, and Discriminatory Effect; supports fair housing enforcement and anti-discrimination protections.'
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;

-- Veronica Turner / Criminal Justice Approach
-- Both acts are real and she sponsors both, under different numbers than the prose gave: Exonerated 5 Act is 2026 HB0626 (not HB0574), and the racial-disparities commission is 2026 HB1309 (not HB0810).
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1309?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[], reasoning = 'Sponsored the Exonerated 5 Act (HB0626, 2026) restricting admissibility of statements from custodial interrogation of minors; also sponsored HB1309 (2026) establishing a commission to review and assess racial disparities in the State criminal justice system; supports rehabilitation-focused reforms.'
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;

-- Pam Lanman Guzzone / Climate Change and Environmental Protection
-- Prose credited the Climate Solutions Now Act (2021/2022) -- PRE-TENURE, she took office 2023-01-11 -- and pass 4b matched it to Guy Guzzone. Her own in-tenure climate sponsorships carry the same position honestly.
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0347?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1279?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0340?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[], reasoning = 'Sponsored HB0347 (2023) authorizing Attorney General climate change actions, HB1279 (2024) on building performance standards and fossil fuel use, and HB0340 (2025) establishing a climate change restitution fund — consistently favors aggressive climate action.'
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;

DO $$
DECLARE bad int;
BEGIN
  -- Each touched row must now cite its verified bill.
  SELECT count(*) INTO bad FROM (VALUES
    ('92075c9b-6c7e-4763-981f-5a42a8afddf5'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS'),
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0573?ys=2026RS'),
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid,'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2026RS'),
    ('589ed7af-602a-4ec9-8072-448b05446772'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0347?ys=2023RS')
  ) AS v(pid, tid, billurl)
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c, unnest(c.sources) s
    WHERE c.politician_id = v.pid AND c.topic_id = v.tid AND s = v.billurl
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) lack their verified bill citation', bad; END IF;

  -- No touched row may still state a bill number this migration proved wrong.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('589ed7af-602a-4ec9-8072-448b05446772'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid)
  ) AND (c.reasoning LIKE '%HB0480%' OR c.reasoning LIKE '%HB0574%' OR c.reasoning LIKE '%HB0810%'
      OR c.reasoning LIKE '%Climate Solutions Now%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still state a disproved bill number', bad; END IF;
END
$$;

COMMIT
;
