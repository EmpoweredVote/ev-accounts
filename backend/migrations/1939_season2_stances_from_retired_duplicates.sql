-- Migration 1939 — the two Season 2 chairs that survived the eight-topic re-research.
--
-- WHAT THIS IS. Migration 1938 retired two duplicate person rows whose stances contradicted the
-- survivors'. Eight (person, topic) pairs were covered by the retired rows and not by the
-- survivors, and 1938 could not move them because Season 1 is closed. The operator ruled the work
-- be redone in the LIVE season. This is that work: all eight were researched from scratch, and
-- TWO are seated here. The other six are refused, and the reasons are recorded below because a
-- refusal that is not written down gets re-attempted.
--
-- 🔑 THE GATE THAT DECIDED EACH ONE is inform.compass_topic_roles.evidence_basis AT THE MEMBER'S
-- SCOPE. Both people sit at state scope. medicare/aid, campaign-finance, healthcare, taxes,
-- school-vouchers and trans-athletes are `record` there; deportation and social-security are
-- `own-words`. A record needs a lever; own words can seat a chair only where the codebook says so.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- THE TWO SEATS, and why the instrument IS the rung in each case.
-- ─────────────────────────────────────────────────────────────────────────────
-- NGUYEN / medicare/aid -> 1.  Rung 1: "expand Medicare to cover everyone regardless of age."
--   The instrument is "An Act establishing Medicare for All in Massachusetts", cosponsored in two
--   consecutive sessions (193/H.1239, 194/H.1405), verified on each bill's own cosponsor page.
--   The filed text creates a single-payer Trust that shall "guarantee health care access to all
--   residents of the Commonwealth without regard to financial or employment status" and eliminates
--   co-insurance, co-payments and deductibles. Rung 2 is explicitly "stopping short of universal
--   coverage", so the Act's own text chooses between the two — this is not a least-extreme guess.
--   ⚖ PRECEDENT: migration 1900 confirmed two verified cosponsors of this same Act at rung 1, and
--   blanked four members whose rows cited it while they were NOT on the cosponsor list. This row is
--   on the kept side of that line, checked the same way.
--   ⚠ Her Season 1 row was also 1, but sourced to her campaign site — inadmissible on a `record`
--   topic. This is NOT a port of that value; it is the same chair reached through a real lever.
--
-- MARSHALL / trans-athletes -> 4.  Rung 4: "require transgender athletes to compete only on teams
--   matching their biological sex assigned at birth."
--   The instrument is a 26-state amicus brief he LED with Arkansas, filed 14 August 2024, urging
--   the U.S. Supreme Court to review the Ninth Circuit's ruling against Idaho's Fairness in Women's
--   Sports Act and the parallel West Virginia case. His office describes the laws as using
--   "biological sex rather than gender identity to classify sports teams at public schools".
--   🔑 LEADING A BRIEF IN ANOTHER STATE'S CASE IS DISCRETIONARY. That matters here: an AG defending
--   his own state's statute is performing an office duty, which is not a position (mig 1935). He
--   is not defending Alabama's law in these cases; he chose to intervene in Idaho's and West
--   Virginia's. Rung 5 ("completely ban all transgender athletes from competing in any organized
--   sports") is excluded by the instrument itself: classifying teams by sex is not barring
--   competition.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- THE SIX REFUSALS. Each fails for a different, recorded reason.
-- ─────────────────────────────────────────────────────────────────────────────
-- NGUYEN / deportation      — `own-words`, and THE SOURCE IS EXTINCT. Both campaign domains
--   (tramforcongress.com and votetram.com) now serve a "Site paused or lapsed" shell; confirmed by
--   rendering the page, not merely by curl. The Internet Archive answered "Temporarily Offline" for
--   the CDX path, so the absence is UNCHECKED there and should be re-tried, not treated as settled.
--   Her live immigration levers are the PROTECT Act and 194/H1588 (immigration detention and
--   collaboration agreements) — both govern STATE AND LOCAL cooperation with federal enforcement,
--   the class migration 1930 ruled cannot seat a deportation chair. Her only quoted words in the
--   PROTECT Act coverage are about trust and civil rights, not who should be deported.
-- NGUYEN / campaign-finance — `record`, and NO INSTRUMENT EXISTS. Zero campaign-finance bills
--   across all 469 documents she sponsored or cosponsored in the 193rd and 194th General Courts
--   (malegislature.gov API, both sessions enumerated). A checked absence, not an unchecked one.
-- MARSHALL / healthcare     — `record`, DIRECTION WITHOUT MAGNITUDE. He joined the 20-state motion
--   to enjoin the ACA (filed 26 April 2018, N.D. Tex.), but his office's own release puts the
--   objection on "the tremendous cost of its individual mandate" and says nothing about Medicaid,
--   about the poorest, or about what replaces the Act. Rung 4 ("only help the poorest") and rung 5
--   ("stay out of healthcare entirely") both sit on that side and the instrument chooses neither.
--   ⚖ Same structure as the 14 healthcare rows migration 1928 refused: expansion proves a floor and
--   never a ceiling — and a suit to strike proves a direction and never a floor.
-- MARSHALL / taxes          — `record`, OFF AXIS. Alabama v. Yellen (he led 13 states) attacks the
--   ARPA offset provision as an unconstitutionally ambiguous SPENDING CONDITION. It asserts the
--   state's AUTHORITY to set tax policy; it says nothing about tax LEVELS, and nothing at all about
--   scaling back services (rung 4) or shrinking government (rung 5).
-- MARSHALL / school-vouchers— `record`, OFF AXIS. His nearest filing is the amicus on whether a
--   state may exclude religious schools from CHARTER funding. Rungs 3, 4 and 5 are separated by
--   voucher ELIGIBILITY BREADTH (income cap / most families / universal); a religious
--   non-discrimination argument does not reach that axis. No filing of his addresses the CHOOSE Act.
-- MARSHALL / social-security— `own-words`, and THERE ARE NONE. An Alabama AG has no Social Security
--   lever, and his Ballotpedia profile — fetched with a browser UA and confirmed to be his page —
--   contains zero occurrences of "Social Security", "Medicare", "retirement", "entitlement" or
--   "payroll tax". His 2026 Senate bid ended in the primary.
--
-- ⚠ TWO SEATS FROM EIGHT TOPICS IS THE EXPECTED SHAPE, not a shortfall: a rung stating a MECHANISM
-- is routinely out of reach of evidence that states a DIRECTION. Reaching for "the least extreme
-- option the record supports" in the six would have been the tiebreaker that signals a row is not
-- evidenced.
--
-- APPLIED BY HAND. No migration runner exists in this repo; this file records SQL applied via the
-- Supabase MCP against production. "Applied" means its data effects are live.
-- PRE-WRITE GATE: scripts/audit-chair-evidence.mjs --csv
--   backend/data/stance-research/duplicate-retirement-1939/stances.csv  -> OK (2/2).

BEGIN;

CREATE TEMP TABLE mig1939_targets (
  politician_id      uuid,
  topic_id           uuid,
  topic_revision_id  uuid,
  chair              numeric,
  who                text,
  reasoning          text,
  sources            text[]
) ON COMMIT DROP;

INSERT INTO mig1939_targets VALUES
( 'fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid,
  'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,
  '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid,
  1,
  'Nguyen / medicare-aid',
  $txt$Nguyen cosponsored An Act establishing Medicare for All in Massachusetts in two consecutive sessions — 193/H.1239 and 194/H.1405 — and her cosponsorship is verified on each bill's own cosponsor page. The Act creates a single-payer Massachusetts Health Care Trust that would "guarantee health care access to all residents of the Commonwealth without regard to financial or employment status", with no co-insurance, co-payments or deductibles. That universal guarantee is chair 1. Chair 2 expressly stops short of universal coverage, so the Act's own text separates the two rather than leaving the choice to inference. Same instrument and same chair as the two cosponsors confirmed at 1 by migration 1900.$txt$,
  ARRAY[
    'https://malegislature.gov/Bills/194/H1405/Cosponsor',
    'https://malegislature.gov/Bills/193/H1239/Cosponsor',
    'https://malegislature.gov/Bills/194/H1405'
  ]
),
( 'd33b1fb5-bac7-48b9-9628-8169e28f4e16'::uuid,
  'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,
  'af2c6427-daf8-4819-93ba-42db212bae68'::uuid,
  4,
  'Marshall / trans-athletes',
  $txt$Marshall led a 26-state amicus brief to the U.S. Supreme Court on 14 August 2024, filed jointly with Arkansas, urging review of the Ninth Circuit's ruling against Idaho's Fairness in Women's Sports Act and of the parallel West Virginia case. His own office describes the laws at issue as using "biological sex rather than gender identity to classify sports teams at public schools". Leading a brief in another state's litigation is a discretionary act, not the office duty of defending Alabama's own statute. Classifying teams by sex assigned at birth is chair 4; chair 5 would bar transgender athletes from all organized competition, which neither the brief nor the laws it defends do.$txt$,
  ARRAY[
    'https://www.alabamaag.gov/alabama-attorney-general-marshall-leads-coalition-urging-supreme-court-to-uphold-state-laws-protecting-girls-sports/'
  ]
);

-- ─── PRE-FLIGHT ──────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  IF (SELECT count(*) FROM mig1939_targets) <> 2 THEN
    RAISE EXCEPTION 'migration 1939: expected 2 targets, found %', (SELECT count(*) FROM mig1939_targets);
  END IF;

  -- Season 2 must still be the open season.
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                  WHERE id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status='open') THEN
    RAISE EXCEPTION 'migration 1939: Season 2 is not open — do not write to a closed season';
  END IF;

  -- 🔴 THE LADDER IS REVISION-SCOPED. Each revision id must be the one Season 2 actually serves for
  -- that topic; reading compass_stances instead put a wrong chair in prod in migration 1935.
  SELECT count(*) INTO n
    FROM mig1939_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.season_questions sq
      WHERE sq.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND sq.topic_id = t.topic_id
        AND sq.topic_revision_id = t.topic_revision_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % target(s) name a revision Season 2 does not serve', n; END IF;

  -- The chair must exist on that revision's ladder.
  SELECT count(*) INTO n
    FROM mig1939_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_stance_revisions csr
      WHERE csr.topic_revision_id = t.topic_revision_id AND csr.value = t.chair);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % target(s) name a rung that does not exist in this season', n; END IF;

  -- Both topics are seated on a `record` basis at state scope, which is what the evidence supplies.
  SELECT count(*) INTO n
    FROM mig1939_targets t
    JOIN inform.compass_topic_roles r ON r.topic_id = t.topic_id AND r.role_scope = 'state'
   WHERE r.evidence_basis <> 'record';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % target(s) are not `record` at state scope — re-read the codebook', n; END IF;

  -- These are INSERTS. If a row already exists for the pair in any season, stop and re-measure.
  SELECT count(*) INTO n
    FROM mig1939_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % answer row(s) already exist for these pairs — this migration only inserts', n; END IF;
END $$;

-- ─── THE WRITE ───────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers
  (politician_id, topic_id, value, season_id, topic_revision_id)
SELECT t.politician_id, t.topic_id, t.chair,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, t.topic_revision_id
  FROM mig1939_targets t;

INSERT INTO inform.politician_context
  (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
SELECT t.politician_id, t.topic_id, t.reasoning, t.sources,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, t.topic_revision_id
  FROM mig1939_targets t;

-- ─── POST-FLIGHT ─────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  -- Both rows exist at exactly the chair claimed.
  SELECT count(*) INTO n
    FROM mig1939_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id=t.politician_id AND pa.topic_id=t.topic_id
     AND pa.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = t.chair AND pa.topic_revision_id = t.topic_revision_id;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1939: expected 2 rows at their stated chair, found %', n; END IF;

  -- Every seated row carries citations.
  SELECT count(*) INTO n
    FROM mig1939_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources),0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % row(s) carry no citation', n; END IF;

  -- 🔑 Every seated row must name an identifier the chair-evidence gate can see.
  SELECT count(*) INTO n
    FROM mig1939_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning !~ '\yAct\y';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % seated row(s) name no citable instrument', n; END IF;

  -- 🔴 BLAST RADIUS: this migration adds two Season 2 answers and nothing else.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
   WHERE pa.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.created_at > now() - interval '5 minutes';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1939: % Season 2 answer(s) created in this window, expected 2', n; END IF;

  -- Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1939: % Season 1 answer(s) were modified — Season 1 is closed', n; END IF;

  RAISE NOTICE 'migration 1939: seated 2 of 8 researched pairs; 6 refused and recorded in the header';
END $$;

COMMIT;
