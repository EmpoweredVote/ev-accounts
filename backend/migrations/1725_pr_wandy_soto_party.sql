-- 1725_pr_wandy_soto_party.sql
--
-- Senator Wandy Soto (Wanda M. "Wandy" Soto Tolentino, Senatorial District 7 / Humacao) is
-- recorded as Partido Popular Democrático. She is Partido Nuevo Progresista. Found while
-- verifying every PR legislator against their chamber's own profile page during the
-- headshot wave (migration 1723); deliberately left out of that migration because a party
-- is a factual claim about a real person and does not belong in a photo import.
--
-- Four independent sources, all agreeing:
--   1. senado.pr.gov roster card  — "Hon. Wanda M. Soto Tolentino  Partido Nuevo Progresista"
--   2. her own profile page       — "Senadora Distrito de Humacao  Partido Nuevo Progresista"
--                                    (states it twice; zero mentions of the PPD)
--   3. 2024 general election result, senatorial district VII (Humacao):
--      Wanda Soto Tolentino (PNP) 60,403 votes, re-elected alongside
--      Luis Daniel Colón La Santa (PNP) 59,032 — the district returned two PNP senators,
--      which is why our PPD value looked plausible in isolation and was not.
--   4. her biography: elected in 2020 "haciendo historia al entrar en Minoría". The PPD held
--      the Senate majority that term, so entering in the minority is consistent with PNP and
--      inconsistent with PPD.
--
-- AGGREGATE CHECK, which is what turned a single suspicious row into a certainty. The 28th
-- Senate (2025-2029) was elected PNP 19 / PPD 5 / PIP 2 / Proyecto Dignidad 1 / independent 1.
-- We hold PNP 18 / PPD 6 / PIP 2 / Independent 2. This one row reconciles PNP and PPD exactly.
--
-- 🔴 THE REMAINING DIFFERENCE IS NOT AN ERROR — DO NOT "FIX" IT. We hold two senators as
-- Independent (Joanne M. Rodríguez Veve and Eliezer Molina Pérez) where the election result
-- says Proyecto Dignidad 1 + independent 1. Rodríguez Veve was ELECTED under Proyecto Dignidad
-- but sits as an independent: senado.pr.gov states "Senadora por Acumulación Independiente"
-- twice on her page with no mention of Dignidad, and her Wikipedia article gives her current
-- status in the 28th Senate as Independent. That is a difference between party-elected-under
-- and current affiliation, not a defect. Our column holds current affiliation.
--
-- Only politicians.party is touched. She has no race_candidates rows and no compass answers,
-- so there is no second place this value is mirrored (party is never on race_candidates by
-- design — it lives on races.primary_party, which PR has none of).
--
-- Idempotent: guarded on the current value, so a re-run updates nothing.

BEGIN;

-- Pre-flight: refuse unless this is the person we verified, still seated in the seat we
-- verified her in. Matching on external_id AND district, never on name -- these surnames
-- collide badly (see migration 1723's header).
DO $$
DECLARE n_target int; n_party int;
BEGIN
  SELECT count(*) INTO n_target
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices   o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.external_id = -7210014
    AND o.title = 'Senator'
    AND d.label  = 'Senatorial District 7';
  IF n_target <> 1 THEN
    RAISE EXCEPTION 'aborting: expected exactly 1 seated SD-7 senator with external_id -7210014, found %',
      n_target;
  END IF;

  -- Accept either the pre-fix or the post-fix value; anything else means someone has been
  -- here before us with a third answer and this migration should not guess.
  SELECT count(*) INTO n_party
  FROM essentials.politicians
  WHERE external_id = -7210014
    AND party IN ('Partido Popular Democrático', 'Partido Nuevo Progresista');
  IF n_party <> 1 THEN
    RAISE EXCEPTION 'aborting: SD-7 senator carries an unexpected party value';
  END IF;
END $$;

UPDATE essentials.politicians
SET party = 'Partido Nuevo Progresista'
WHERE external_id = -7210014
  AND party = 'Partido Popular Democrático';

-- Post-verify: the row itself, and the chamber aggregate it was found by.
DO $$
DECLARE n_pnp int; n_ppd int; n_pip int; n_bad int; v_party text;
BEGIN
  SELECT party INTO v_party FROM essentials.politicians WHERE external_id = -7210014;
  IF v_party <> 'Partido Nuevo Progresista' THEN
    RAISE EXCEPTION 'expected PNP for the SD-7 senator, found %', v_party;
  END IF;

  SELECT
    count(*) FILTER (WHERE p.party = 'Partido Nuevo Progresista'),
    count(*) FILTER (WHERE p.party = 'Partido Popular Democrático'),
    count(*) FILTER (WHERE p.party = 'Partido Independentista Puertorriqueño')
  INTO n_pnp, n_ppd, n_pip
  FROM essentials.offices o
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE p.external_id::text LIKE '-72%' AND o.title = 'Senator';

  IF (n_pnp, n_ppd, n_pip) <> (19, 5, 2) THEN
    RAISE EXCEPTION 'PR Senate composition is now PNP %, PPD %, PIP % — expected 19/5/2',
      n_pnp, n_ppd, n_pip;
  END IF;

  -- Migration 1720's rule: PR parties are stored verbatim in Spanish and do not map onto the
  -- U.S. two-party split. A mainland label here means something upstream is wrong.
  SELECT count(*) INTO n_bad
  FROM essentials.politicians p
  WHERE p.external_id::text LIKE '-72%'
    AND p.party IN ('Democrat', 'Republican', 'Democratic', 'Democratic Party', 'Republican Party');
  IF n_bad <> 0 THEN
    RAISE EXCEPTION '% PR member(s) carry a mainland party label', n_bad;
  END IF;

  RAISE NOTICE 'ok: SD-7 senator is PNP; PR Senate now PNP %, PPD %, PIP %', n_pnp, n_ppd, n_pip;
END $$;

COMMIT;
