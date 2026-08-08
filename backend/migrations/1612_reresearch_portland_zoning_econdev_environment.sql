-- 1612: Re-research 6 owed Portland rows across three topics.
--   Residential Zoning x3                        Avalos, Smith, Novick   (retired chair 2, 2, 2)
--   Economic Development Incentives x2           Zimmerman, Dunphy       (retired chair 3, 2)
--   Environmental Protection vs. Development x1  Novick                  (retired chair 1)
--
-- All retired by migration 1558, sole-sourced to fabricated willametteweek.com questionnaires. None
-- of the six pairs currently holds a row, so these are INSERTs into both tables. All six land on
-- chair 3 -- independently, on three different scales; it is not one judgment applied six times.
--
-- ================================ RESIDENTIAL ZONING (chair 3) ================================
-- Avalos, Smith and Novick have IDENTICAL records here -- all three Yea on all four documents:
--   2026-037  Affordable Housing Opportunities Project amendments to the Comprehensive Plan Map and
--             Official Zoning Map
--   2025-349  Comprehensive Plan Map, Zone Map and Title 33 amendments, Portland-Gresham Urban
--             Service Boundary
--   2025-026  Site-specific Comprehensive Plan Map and Zoning Map amendment (NE 11th / NE Fremont)
--   2026-106  Accelerated timeline for the Inner Eastside Area Planning Project and identification of
--             further area planning and zoning actions to advance housing production goals
--
-- ⚠ CHAIR 3, NOT 4 -- and the contrast with Dan Ryan is deliberate. Ryan was chaired 4 in migration
-- 1608 on genuinely stronger evidence from his earlier term: the Housing Regulatory Relief Project's
-- suspensions of development regulations and vehicle parking reforms, which is chair 4's "streamline
-- approvals and reduce parking requirements" almost verbatim. These three have no such votes. What
-- they have is a series of TARGETED rezonings and area plans, which is chair 3's "allow multifamily
-- and mixed-use near commercial corridors" rather than broad by-right upzoning. Same city, same
-- topic, different chairs, because the records differ.
-- ⚠ 2025-301 (Parking Space Reservation Code) is NOT cited: it concerns administration of reserved
-- parking spaces, not parking minimums, and would be a false match for chair 4's parking clause.
--
-- ========================= ECONOMIC DEVELOPMENT INCENTIVES (chair 3) ==========================
-- Both back place-based tax incentives run through Prosper Portland with community-governance
-- structures attached -- chair 3's "targeted incentives ... with community benefit agreements".
-- Chair 4 ("compete actively for major employers with significant tax abatements") is not evidenced:
-- nothing in the record chases a named employer. Consistent with Wilson's chair 3 in mig 1608, which
-- rested on the same six TIF districts seen from the mayor's agenda.
--   2025-111..116  Debt service funds for six tax increment financing districts
--   2026-016       Portland Enterprise Zone boundary change
--   2026-077       Increase the business license tax gross receipts exemption
--   2026-224 / 2026-084 / 2025-359  Prosper Portland Board of Commissioners appointments
--   2026-083 / 2025-024 / 2025-418  TIF district community leadership councils
--   2026-082       Cully TIF District Five-Year Action Plan -- Dunphy NAY, Zimmerman absent
--
-- ================== ENVIRONMENTAL PROTECTION vs. DEVELOPMENT (chair 3) =======================
-- Novick's retired chair was 1 ("require significant green space, tree preservation and environmental
-- review before approving ANY development"). That is not supported: he voted to STREAMLINE
-- environmental zoning review to let needed infrastructure proceed. What he does support is climate
-- investment and canopy planning alongside that flexibility -- chair 3.
--   2025-351  Adopt the Portland Urban Forest Plan (resilience to climate change)
--   2026-063  Public Infrastructure Environmental Code Project -- streamline environmental zoning
--   PCEF      Repeated funding and governance of the Portland Clean Energy Community Benefits Fund
-- ⚠ His Nay on 2026-222 (moving PCEF interest income into general budget restorations) is NOT cited:
-- a budget vote touching climate money is not a position on development versus preservation, and its
-- meaning is not determinable from a roll call.
-- ⚠ The two land-use APPEAL votes (Forest Park 2025-161, Pleasant Valley 2026-144) are NOT cited
-- either: the recorded vote is to CONSIDER an appeal, which does not reveal which way he came down.
--
-- ⚠ Absences are omitted rather than described, and no motive is inferred from any Nay (mig 1611).
-- All 18 citations were fetched and asserted to carry every document named, before this was written.
-- 🔴 One citation query was WRONG on the first pass: 2025-349's title reads "Zone Map", not "Zoning
-- Map", so it does not appear under ?council_document=Zoning+Map. Caught by the pre-write check;
-- the Urban Service Boundary vote gets its own citation rather than being dropped or mis-cited.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context pc
   WHERE (pc.politician_id, pc.topic_id) IN (
     ('c5db367e-9403-4a88-a95f-bf864279e13b','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('e6682850-601f-4017-b4e7-d9cd4be47aea','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('c9e19031-259e-4133-b5d9-96cf1a5f31ff','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('1518349b-3d63-49d0-9411-be19f86a7ea7','eb3d1247-0de1-4b7f-baec-7259861efd53'),
     ('14ebbd1c-597e-483a-a846-73a7aca54ed2','eb3d1247-0de1-4b7f-baec-7259861efd53'),
     ('c9e19031-259e-4133-b5d9-96cf1a5f31ff','1935979c-b290-42e4-baa5-8cb0138b4ffa'));
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

-- ---- Residential Zoning ----
('c5db367e-9403-4a88-a95f-bf864279e13b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Avalos has approved targeted rezonings that add housing rather than a blanket citywide upzoning. She voted to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan Map and Official Zoning Map, to approve Comprehensive Plan Map, Zone Map and Title 33 amendments for the Portland-Gresham Urban Service Boundary, and to direct an accelerated timeline for the Inner Eastside Area Planning Project along with further area planning and zoning actions to advance housing production goals.',
 ARRAY['https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Zoning+Map',
       'https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Urban+Service+Boundary',
       'https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=housing+production']),

('e6682850-601f-4017-b4e7-d9cd4be47aea', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Smith has approved targeted rezonings that add housing rather than a blanket citywide upzoning. She voted to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan Map and Official Zoning Map, to approve Comprehensive Plan Map, Zone Map and Title 33 amendments for the Portland-Gresham Urban Service Boundary, and to direct an accelerated timeline for the Inner Eastside Area Planning Project along with further area planning and zoning actions to advance housing production goals.',
 ARRAY['https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=Zoning+Map',
       'https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=Urban+Service+Boundary',
       'https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=housing+production']),

('c9e19031-259e-4133-b5d9-96cf1a5f31ff', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Novick has approved targeted rezonings that add housing rather than a blanket citywide upzoning. He voted to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan Map and Official Zoning Map, to approve Comprehensive Plan Map, Zone Map and Title 33 amendments for the Portland-Gresham Urban Service Boundary, and to direct an accelerated timeline for the Inner Eastside Area Planning Project along with further area planning and zoning actions to advance housing production goals.',
 ARRAY['https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Zoning+Map',
       'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Urban+Service+Boundary',
       'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=housing+production']),

-- ---- Economic Development Incentives ----
('1518349b-3d63-49d0-9411-be19f86a7ea7', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
 'Zimmerman backs place-based tax incentives delivered through Portland''s development agency, with community bodies attached to them. He voted to create debt service funds for six new tax increment financing districts, to amend the Portland Enterprise Zone boundary, to raise the business license tax gross receipts exemption for smaller firms, and to appoint members of the Prosper Portland Board of Commissioners and of the tax increment financing district community leadership councils.',
 ARRAY['https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=Tax+Increment',
       'https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=Prosper+Portland',
       'https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=Enterprise+Zone']),

('14ebbd1c-597e-483a-a846-73a7aca54ed2', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
 'Dunphy backs place-based tax incentives delivered through Portland''s development agency, with community bodies attached to them. He voted to create debt service funds for six new tax increment financing districts, to amend the Portland Enterprise Zone boundary, to raise the business license tax gross receipts exemption for smaller firms, and to appoint members of the Prosper Portland Board of Commissioners and of the tax increment financing district community leadership councils. He voted against the Cully Tax Increment Financing District Five-Year Action Plan.',
 ARRAY['https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Tax+Increment',
       'https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Prosper+Portland',
       'https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Enterprise+Zone']),

-- ---- Environmental Protection vs. Development ----
('c9e19031-259e-4133-b5d9-96cf1a5f31ff', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
 'Novick pairs climate investment and tree canopy planning with flexibility for infrastructure that the city needs built. He voted to adopt the Portland Urban Forest Plan to build resilience to climate change, and repeatedly to fund and govern the Portland Clean Energy Community Benefits Fund. He also voted to adopt the Public Infrastructure Environmental Code Project, which streamlines environmental zoning regulations to accommodate needed infrastructure projects while supporting ongoing natural resource management.',
 ARRAY['https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Urban+Forest',
       'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Clean+Energy',
       'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Environmental+Code']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pc.politician_id, pc.topic_id, 3
  FROM inform.politician_context pc
 WHERE (pc.politician_id, pc.topic_id) IN (
   ('c5db367e-9403-4a88-a95f-bf864279e13b','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
   ('e6682850-601f-4017-b4e7-d9cd4be47aea','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
   ('c9e19031-259e-4133-b5d9-96cf1a5f31ff','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
   ('1518349b-3d63-49d0-9411-be19f86a7ea7','eb3d1247-0de1-4b7f-baec-7259861efd53'),
   ('14ebbd1c-597e-483a-a846-73a7aca54ed2','eb3d1247-0de1-4b7f-baec-7259861efd53'),
   ('c9e19031-259e-4133-b5d9-96cf1a5f31ff','1935979c-b290-42e4-baa5-8cb0138b4ffa'));

DO $$
DECLARE v_ctx int; v_ans int; v_chair int; v_orphan int; v_empty int; v_prose int;
  pairs text[] := ARRAY[
    'c5db367e-9403-4a88-a95f-bf864279e13b|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    'e6682850-601f-4017-b4e7-d9cd4be47aea|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    'c9e19031-259e-4133-b5d9-96cf1a5f31ff|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    '1518349b-3d63-49d0-9411-be19f86a7ea7|eb3d1247-0de1-4b7f-baec-7259861efd53',
    '14ebbd1c-597e-483a-a846-73a7aca54ed2|eb3d1247-0de1-4b7f-baec-7259861efd53',
    'c9e19031-259e-4133-b5d9-96cf1a5f31ff|1935979c-b290-42e4-baa5-8cb0138b4ffa'];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs);
  IF v_ctx <> 6 THEN RAISE EXCEPTION 'expected 6 context rows, found %', v_ctx; END IF;

  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs);
  IF v_ans <> 6 THEN RAISE EXCEPTION 'expected 6 answer rows, found %', v_ans; END IF;

  SELECT count(*) INTO v_chair FROM inform.politician_answers
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs) AND value = 3;
  IF v_chair <> 6 THEN RAISE EXCEPTION 'expected all 6 chairs = 3, found %', v_chair; END IF;

  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id::text||'|'||pc.topic_id::text = ANY(pairs) AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;

  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs)
     AND (sources IS NULL OR cardinality(sources) = 0);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;

  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs) AND reasoning ~ 'https?://';
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
