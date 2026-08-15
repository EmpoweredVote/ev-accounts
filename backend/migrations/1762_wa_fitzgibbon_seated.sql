-- 1762_wa_fitzgibbon_seated.sql
-- First three rows of the 147-legislator Washington sweep. Joe Fitzgibbon (LD 34, House Majority
-- Leader), politician 9f914ddb-ba7c-4b30-b756-fe7cd981f919. He held ZERO answers and ZERO context
-- rows before this migration, as did all 147 WA legislators.
--
-- 🔑 EVERY IDENTITY HERE IS RESOLVED THROUGH THE LEGISLATURE'S MEMBER ID, NEVER A SURNAME.
-- The DB contains an ELIZABETH Fitzgibbon (a6e7e6ea-e33b-4c57-936e-dfaadd3c1f36) who already holds
-- four answers. A surname match would have written Joe's stances onto her record, or hers onto his.
-- Sponsorship was read from wslwebservices.leg.wa.gov GetSponsors, which returns member Id +
-- Primary/Secondary, and joined to the DB through a linkage verified at 147/147 with zero unmatched
-- and zero ambiguous rows. Joe is member 13198.
--
-- ── taxes = 2 ────────────────────────────────────────────────────────────────────────────────
-- PRIME sponsor (order 0) of HB 2724, "Establishing a tax on millionaires": 9.90 percent on
-- Washington taxable income, applying only to individuals with adjusted gross income of at least
-- $1,000,000 (secs. 201, 1(9)).
-- 🔴 THE TITLE IS A TRAP AND POINTS AT THE WRONG CHAIR. "Millionaires tax" reads as chair 1,
-- "significantly raise taxes on wealthy people and large companies to fund MORE public services".
-- The enacted text says the opposite about DESTINATION. Sec. 1(6): "the intent of this act is to
-- MAINTAIN AND PRESERVE essential governmental services". Sec. 202 sends five percent to the county
-- public defense funding stabilization account and "the remainder to the state general fund to fund
-- the sales and use tax relief ..., the working families' tax credit program, ... and the business
-- and occupation tax relief". The package pays for tax CUTS elsewhere and preserves what exists; it
-- does not buy new services. That is chair 2's "to fund existing services".
-- 🔑 The chair rests on DESTINATION, not on the adverb. This follows migration 1759 (Mosqueda,
-- taxes = 1) verbatim: "neither instrument characterises the increase as significant or moderate, so
-- the chair rests on the DESTINATION". There the destination was entirely new investment and gave
-- chair 1; here it is preservation plus offsetting relief and gives chair 2. Same test, opposite
-- reading, because the two texts say different things.
-- ⚠ THE COUNTER-ARGUMENT, RECORDED RATHER THAN DROPPED. Fitzgibbon also voted Yea on final passage of
-- ESSB 6346 (House, 2026-03-09, 51-46), the version that actually became law, and ITS sec. 202 adds
-- "and to make public investments in K-12 education, health care, human services, and higher
-- education" plus five percent to the fair start for kids account. That destination leans chair 1.
-- The row is seated on the instrument he AUTHORED as prime sponsor rather than the one he voted for.
-- A reader who thinks a floor vote outweighs authorship should revisit this row and the 37-member
-- HB 2724 cohort together.
--
-- ── climate-change = 3 ───────────────────────────────────────────────────────────────────────
-- PRIME sponsor of HB 2367, Chapter 37, Laws of 2026: "eliminating preferential treatment related to
-- a coal-fired electric generating plant". It amends RCW 70A.65.080 to pull the plant into the
-- cap-and-invest program and repeals its sales and use tax exemptions (RCW 82.08.811, 82.12.811).
-- 🔴 A SECOND TITLE TRAP, AND IT POINTS AT CHAIR 1. The act's title ends "and declaring an
-- emergency". Chair 1 is "DECLARE A CLIMATE EMERGENCY and ban all activities that increase carbon
-- emissions". In Washington that clause is boilerplate for immediate effect and has nothing to do
-- with climate. Reading the title alone seats this at chair 1 and is flatly wrong.
-- 🔑 Chair 2 is refuted rather than merely unproven: it requires phasing out fossil fuels BY 2030,
-- and this instrument sets no phase-out date at all -- it works through a cap that declines over
-- time. What remains is chair 3, "invest in clean energy while gradually reducing reliance on fossil
-- fuels", which is what a declining cap plus removal of a fossil tax preference does.
--
-- ── rent-regulation = 2 ──────────────────────────────────────────────────────────────────────
-- CO-SPONSOR of EHB 1217, Chapter 209, Laws of 2025. Sec. 101 bars a landlord from raising rent
-- during the first 12 months of a tenancy, and thereafter by more than "seven percent plus the
-- consumer price index, or 10 percent, whichever is less", across BOTH the residential landlord-
-- tenant act and the manufactured/mobile home landlord-tenant act.
-- 🔑 Sec. 102 is what decides the chair. Rent increases are NOT limited for units whose first
-- certificate of occupancy issued 12 or fewer years ago, for public housing and public development
-- authorities, for nonprofit and LIHTC housing whose rents are already regulated, for units sharing a
-- kitchen or bath with a resident owner, or for owner-occupied single-family homes. Those carve-outs
-- REFUTE chair 1, which requires rent control on ALL rental units.
-- ⚠ Neither survivor is a clean fit and that is recorded here rather than smoothed over. Chair 2
-- says "strengthen EXISTING rent stabilization", and Washington had no statewide rent stabilization
-- before this act. Chair 3 says "MAINTAIN current tenant protections", which a first-ever statewide
-- rent cap plainly does not do. Chair 2 was chosen because "maintain" is the more serious mismatch --
-- the act creates a major new protection and extends it across two landlord-tenant acts, which is
-- chair 2's behaviour. Operator approved this reading on 2026-08-15.
-- ⚠ Co-sponsorship counts as much as authorship, so this reasoning binds all 35 seated sponsors of
-- EHB 1217 identically. They are NOT written here: each still needs a check for a stronger or
-- contradicting instrument of their own before the cohort is applied.
--
-- Sources cited below were all fetched successfully before seating; none is inferred from a title,
-- a summary page, or a press account.
BEGIN;

CREATE TEMP TABLE fitz_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int; t text; tid uuid;
BEGIN
  -- Nothing may already exist for this politician on these three ladders. If it does, someone
  -- researched him after this migration was drafted and their work must not be overwritten.
  FOREACH tid IN ARRAY ARRAY[
      'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,   -- taxes
      'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,   -- climate-change
      'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid]   -- rent-regulation
  LOOP
    SELECT count(*) INTO n FROM inform.politician_answers
     WHERE politician_id='9f914ddb-ba7c-4b30-b756-fe7cd981f919' AND topic_id=tid;
    IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Fitzgibbon already has an answer on %', tid; END IF;

    SELECT count(*) INTO n FROM inform.politician_context
     WHERE politician_id='9f914ddb-ba7c-4b30-b756-fe7cd981f919' AND topic_id=tid;
    IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Fitzgibbon already has a context row on %', tid; END IF;
  END LOOP;

  -- The politician must be the Joe Fitzgibbon seated in the WA House, not the Elizabeth Fitzgibbon
  -- who shares the surname and already holds answers.
  SELECT full_name INTO t FROM essentials.politicians
   WHERE id='9f914ddb-ba7c-4b30-b756-fe7cd981f919';
  IF t <> 'Joe Fitzgibbon' THEN
    RAISE EXCEPTION 'pre-check: politician id resolves to "%", expected Joe Fitzgibbon', t; END IF;
END $$;

-- Each chair must be defined exactly once on its ladder, or the row renders blank to the voter.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes chair 2 not defined exactly once (%)', n; END IF;

  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: climate chair 3 not defined exactly once (%)', n; END IF;

  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: rent chair 2 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('9f914ddb-ba7c-4b30-b756-fe7cd981f919','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Prime sponsor of HB 2724 (2026), which would tax Washington income above $1 million at 9.9 percent. The bill states its intent is to "maintain and preserve essential governmental services", and directs the revenue to offset sales-and-use and business-and-occupation tax relief and to fund the working families' tax credit rather than to buy new services.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2724.pdf',
       'https://app.leg.wa.gov/billsummary?BillNumber=2724&Year=2025&Initiative=false']),

('9f914ddb-ba7c-4b30-b756-fe7cd981f919','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Prime sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),

('9f914ddb-ba7c-4b30-b756-fe7cd981f919','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('9f914ddb-ba7c-4b30-b756-fe7cd981f919','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('9f914ddb-ba7c-4b30-b756-fe7cd981f919','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('9f914ddb-ba7c-4b30-b756-fe7cd981f919','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2);

-- Guard 1: exactly three answers and three context rows appear, and nothing else moves.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM fitz_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 3 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +3', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 3 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +3', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 2: each row sits at the chair that was read, carries the phrase the chair was read FROM, and
-- cites the document that phrase was read IN. Checked on content, not on the fact that an INSERT ran.
DO $$
DECLARE v numeric; r text; srcs text[];
BEGIN
  SELECT a.value, c.reasoning, c.sources INTO v, r, srcs
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.politician_id='9f914ddb-ba7c-4b30-b756-fe7cd981f919'
     AND a.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF v <> 2 THEN RAISE EXCEPTION 'guard 2: taxes chair is %, expected 2', v; END IF;
  IF r !~ 'maintain and preserve essential governmental services' THEN
    RAISE EXCEPTION 'guard 2: taxes reasoning does not carry the destination phrase the chair rests on'; END IF;
  IF NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2724.pdf' = ANY(srcs)) THEN
    RAISE EXCEPTION 'guard 2: taxes row does not cite the bill text it was read from'; END IF;

  SELECT a.value, c.reasoning, c.sources INTO v, r, srcs
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.politician_id='9f914ddb-ba7c-4b30-b756-fe7cd981f919'
     AND a.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF v <> 3 THEN RAISE EXCEPTION 'guard 2: climate chair is %, expected 3', v; END IF;
  IF r !~ 'does not set a phase-out date' THEN
    RAISE EXCEPTION 'guard 2: climate reasoning does not carry the clause that refutes chair 2'; END IF;
  IF NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf' = ANY(srcs)) THEN
    RAISE EXCEPTION 'guard 2: climate row does not cite the session law'; END IF;

  SELECT a.value, c.reasoning, c.sources INTO v, r, srcs
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.politician_id='9f914ddb-ba7c-4b30-b756-fe7cd981f919'
     AND a.topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF v <> 2 THEN RAISE EXCEPTION 'guard 2: rent chair is %, expected 2', v; END IF;
  IF r !~ 'broad but not universal' THEN
    RAISE EXCEPTION 'guard 2: rent reasoning does not carry the scope clause that refutes chair 1'; END IF;
  IF NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf' = ANY(srcs)) THEN
    RAISE EXCEPTION 'guard 2: rent row does not cite the session law'; END IF;
END $$;

-- Guard 3: the gate invariants this workstream protects are unchanged. The ORPHAN_CONTEXT predicate
-- below is copied verbatim from the CI gate -- migration 1735 shipped a guard that asserted the
-- OPPOSITE property and passed green, so the predicate must match the gate's, not merely resemble it.
DO $$
DECLARE orphans int; ans_wo_ctx int; seated int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  SELECT count(*) INTO seated FROM inform.politician_answers
   WHERE politician_id='9f914ddb-ba7c-4b30-b756-fe7cd981f919';
  IF seated <> 3 THEN RAISE EXCEPTION 'guard 3: Fitzgibbon holds % answers, expected 3', seated; END IF;

  RAISE NOTICE 'Fitzgibbon seated: taxes=2, climate-change=3, rent-regulation=2; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
