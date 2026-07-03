-- 1168_nc_general_field_reconciliation.sql
-- Post-hoc reconciliation of the NC 2026 US House field against the OFFICIAL NCSBE general-election
-- candidate list (Candidate_Listing_2026.csv + 2026_general_candidate_detail_list_federal_and_state.pdf,
-- dl.ncsbe.gov "Elections/2026/Candidate Filing/", files updated 2026-07-02). Closes Phase 156
-- carry-forward #1 (NCSBE minor-line prune). Verified 2026-07-02.
--
-- FINDING: the feared mass-prune was FALSE. All 9 NC Libertarians from mig 1130 (Bailey NC-1,
-- Laszacs NC-2, Cavender NC-3, Meilleur NC-4, Luffman NC-5, Abu-Ghazalah NC-7, Feldman NC-10,
-- Groo NC-11, Swinton NC-13) ARE on the certified general list (Dec-2025 LIB filings; the earlier
-- "only Luffman" read came from a partial CSV snapshot). Actual diff vs live DB:
--
--   1) PRUNE 2 — NOT on the certified Nov-3 ballot (appear NOWHERE in the NCSBE listing, any
--      contest/any date): NC-11 John Rogers (-371103, was Independent) + NC-13 Anthony Aguilar
--      (-371302, was Green). Both have 0 stances / 0 images. race_candidates -> 'withdrawn'
--      (records kept, FL-151/153 provisional-cull pattern). NC-11/NC-13 both retain >=2 active.
--
--   2) ADD 1 — NC-8 Bo Whitehead (ROBERT WILLIAM WHITEHEAD, Green, Charlotte), filed 06/15/2026
--      (post-primary Green certification, same batch as Michael Dublin GRE US Senate), certified
--      on the Nov-3 general ballot; also listed by Ballotpedia ("Incumbent Mark Harris, Colby
--      Watson, and Bo Whitehead are running in the general election"). New politician -370802
--      (NC-8 seq: Watson -370801) + active race_candidate on NC-8 race 45f2b223.
--      DEDUP (D-03, live-verified): only other real Whitehead = David Whitehead (Treasurer,
--      -367680), different person; -370802 collision-free. Stance/headshot: whole-record
--      honest-skip with search trail (2x web search no coverage; Ballotpedia bio = stub, no
--      Candidate Connection survey, "Submit photo" placeholder; NCSBE filing contact = email only,
--      no campaign site) — pinned in scripts/156-verify.sql.
--
-- Carry-forward #2 (OH-1 Stoops-vs-Hancock) resolved with NO data change: John Hancock (-390102)
-- IS the certified Libertarian nominee — won the May-5 primary 527-51 (91.2%) over Jason Stoops'
-- write-in bid (official SoS canvass; Ballotpedia general box = Landsman/Conroy/Hancock). The
-- LPO-site Stoops listing is their stale pre-primary endorsement, not the nomination.
--
-- ANTIPARTISAN (D-06): party NOT stored on the candidate card.
-- Idempotent: INSERTs guarded by NOT EXISTS; UPDATEs match current status (re-run = UPDATE 0).

BEGIN;

-- 1) Prune the 2 non-certified lines (status flip only; politician records kept).
UPDATE essentials.race_candidates rc
SET candidate_status = 'withdrawn'
FROM essentials.politicians p
WHERE p.id = rc.politician_id
  AND p.external_id IN (-371103, -371302)   -- John Rogers NC-11, Anthony Aguilar NC-13
  AND rc.candidate_status = 'active';

-- 2) New politician: Bo Whitehead (NC-8 Green).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), -370802, 'Bo Whitehead', 'Bo', 'Whitehead', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = -370802);

-- 3) Active race_candidate on the NC-8 race.
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), '45f2b223-e5ac-44ef-a50f-7234d682462e'::uuid, p.id, 'Bo Whitehead', 'Bo', 'Whitehead', false, 'active',
       'https://s3.amazonaws.com/dl.ncsbe.gov/Elections/2026/Candidate%20Filing/Candidate_Listing_2026.csv'
FROM essentials.politicians p
WHERE p.external_id = -370802
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = '45f2b223-e5ac-44ef-a50f-7234d682462e'::uuid
      AND lower(rc.full_name) = 'bo whitehead'
  );

-- Post-checks (visibility only)
DO $$
DECLARE
  v_withdrawn int;
  v_whitehead int;
BEGIN
  SELECT COUNT(*) INTO v_withdrawn
  FROM essentials.race_candidates rc
  JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE p.external_id IN (-371103, -371302) AND rc.candidate_status = 'withdrawn';

  SELECT COUNT(*) INTO v_whitehead
  FROM essentials.race_candidates rc
  JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE p.external_id = -370802 AND rc.candidate_status = 'active'
    AND rc.race_id = '45f2b223-e5ac-44ef-a50f-7234d682462e'::uuid;

  IF v_withdrawn <> 2 THEN
    RAISE EXCEPTION 'POST-CHECK FAIL: expected 2 withdrawn (Rogers/Aguilar), got %', v_withdrawn;
  END IF;
  IF v_whitehead <> 1 THEN
    RAISE EXCEPTION 'POST-CHECK FAIL: expected 1 active Bo Whitehead on NC-8, got %', v_whitehead;
  END IF;
  RAISE NOTICE 'POST-CHECK PASS: Rogers+Aguilar withdrawn, Whitehead active on NC-8';
END $$;

COMMIT;
