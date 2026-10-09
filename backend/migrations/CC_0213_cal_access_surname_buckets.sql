-- CC_0213 — detach the CAL-ACCESS surname buckets, and give two politicians their real finance.
--
-- `confirm-cal-access.ts` matched committees to politicians BY SURNAME and wrote
-- `research_status = 'confirmed'`. Seven rows became surname buckets holding other people's money.
-- Adjudication and the full evidence: `.planning/todos/2026-10-09-finance-surname-buckets.md`.
--
-- 🟢 **THE DETACH MECHANISM IS `research_status`, NOT A DELETE.** `campaignFinanceService.ts:37`
-- reads a politician's own fundraising through
-- `ps.research_status = 'confirmed' AND ps.source_type = 'candidate_committee'`,
-- so moving a source to `disputed` removes it from every read. Nothing is destroyed, no
-- contribution row is touched, and the whole migration reverts with one UPDATE back to 'confirmed'.
-- ⚠ `essentials_politician_id` is NOT NULL, so a source cannot simply be unhooked; and deleting one
-- would hit a RESTRICT foreign key from `filed_report_summaries`. `disputed` is the right tool.
--
--
-- ══ PART 1 — DETACH (159 sources after the repoint; 168 in the CAL-ACCESS bucket set) ════════
--
-- Predicate: on these seven rows, a source is detached when the committee name does NOT contain the
-- politician's own FORENAME.
--
-- 🔴🔴 **COMPARE THE FIRST TOKEN OF `first_name`, NOT THE WHOLE FIELD.** `John M. Erickson`'s field
-- is "John M.", which does not substring-match "ERICKSON FOR STATE SENATE 2026; JOHN". The naive
-- version of this predicate would have DETACHED HIS OWN $1,359,433 / 981 contributions. Same trap
-- for "Angie Reyes" English and "Bryan \"Bubba\"" Fish. This is the middle-name false trail the
-- worklist records, and it bit twice.
--
-- Counts below are per bucket row over ALL source systems; this migration touches only the
-- CAL-ACCESS ones (168 of them), of which 9 are repointed in part 2, leaving 159 detached.
-- ⚠ Arthur Dixon also carries `fec_house:H6CA34302`, which is NOT cal_access and is left alone.
--
--   Gil Hurtado          20 of 24 sources   2,061 contributions   $12,249,211
--   David Patterson      60 of 65           4,355                 $ 6,192,878
--   Arthur Dixon         44 of 44           3,357                 $ 3,814,347
--   Fernando Dutra       14 of 17           1,983                 $ 1,910,440
--   John M. Erickson     13 of 16             323                 $   120,038  (keeps his own 981)
--   Angie Reyes English  12 of 12             167                 $    93,652
--   Bryan "Bubba" Fish    6 of 6                9                 $    34,649
--
-- Gil Hurtado's row held 24 committees from at least SEVEN different Hurtados — Melissa (state
-- senator), Esmeralda, Jewel, G. Sylvia, Ricky, Jaime and Gil — and Melissa's Senate committees
-- hold 2,044 of its 2,061 contributions. Arthur Dixon's 44 include committees named for the CITY of
-- Dixon ("DIXON CITY COUNCIL", "DIXON UNIFIED SCHOOL DISTRICT", "BOGUE FOR DIXON CITY COUNCIL") —
-- the surname is also a place name, which is why that bucket is the largest.
--
-- 🟢 All seven rows are `is_active = false`, so no voter sees any of this today. The harm this
-- prevents is the MERGE that would have moved it onto the active namesake's page.
--
--
-- ══ PART 2 — REPOINT, where the real owner is in the corpus and the evidence names them ══════
--
-- **Melissa Hurtado** `d3b4ee4d` (California State Senator, 0 finance of her own until now) — 5
-- sources, 1,577 contributions. Ballotpedia: "Melissa Hurtado … California State Senate, Tenure
-- 2018 - Present, District 16". She is the only Hurtado ever to sit in the California Senate, so
-- the Senate committees are hers; the two city-council committees name her outright.
--     1414453  HURTADO FOR SENATE 2022               1,154
--     1401462  HURTADO FOR SENATE 2018                 423
--     1446273  HURTADO FOR SENATE 2026                   0
--     1395239  HURTADO FOR CITY COUNCIL 2020; MELISSA    0
--     1386623  HURTADO FOR CITY COUNCIL 2016; MELISSA    0
--
-- ⚠ **TWO MELISSA COMMITTEES ARE DELIBERATELY DETACHED RATHER THAN REPOINTED**, because they read
-- as INDEPENDENT EXPENDITURE committees while being typed `candidate_committee`:
--     1456951  HURTADO FOR SENATE 2026; VALLEY FAMILIES FOR MELISSA          467
--     1447993  HURTADO 2022; COALITION OF BUSINESS ORGANISATIONS … MELISSA     8
--   Repointing them would publish someone else's spending FOR her as her OWN fundraising — the
--   exact defect `campaignFinanceService.ts:28` records as fixed on 2026-09-24. Their `source_type`
--   needs a human ruling; until then `disputed` is the honest state.
--
-- **Joe Patterson** `038b7624` (California Assembly Member, 0 finance of his own until now) — 4
-- sources, 1,418 contributions, every one naming him in the committee title.
--     1456524  PATTERSON FOR ASSEMBLY 2024; JOE                519
--     1476880  PATTERSON FOR ASSEMBLY 2026; JOE                467
--     1443381  PATTERSON FOR ASSEMBLY 2022; JOE                432
--     1388707  PATTERSON FOR ROCKLIN CITY COUNCIL 2020; JOE      0
--
-- ⚠ **THE SAME `external_id` SITS ON SEVERAL POLITICIAN ROWS** (most as `needs_research` with null
-- notes), so every statement below targets a source by its own `id`, resolved from
-- (external_id + the bucket row it currently hangs on). Never by external_id alone.
--
-- Diane Dixon, Ronda Dixon, John Dutra, Esmeralda Hurtado, Brian Erickson, Ken English and
-- Jonathan Fish have no row in the corpus, so their committees are detached and left for whoever
-- creates those records.
--
-- NOT DONE HERE, deliberately: retiring the duplicate rows. Hurtado, Dutra and Dixon each look like
-- one person with their active namesake, but "looks like" is not the standard this repo applies to a
-- merge, and John Fleming is blocked on an operator decision about overlapping (topic, season)
-- answers. Attribution first; the merge is a separate, evidenced step.

BEGIN;

DO $$
DECLARE
  r         record;
  n_disp    int := 0;
  n_point   int := 0;
  v_cnt     bigint;
  v_sid     uuid;
BEGIN
  -- resolve the seven bucket rows by id prefix so the migration carries no mistyped uuid
  CREATE TEMP TABLE _buckets ON COMMIT DROP AS
    SELECT p.id, p.full_name,
           upper(btrim(regexp_replace(split_part(btrim(p.first_name),' ',1),'[^A-Za-z]','','g'))) AS fore
      FROM essentials.politicians p
     WHERE p.id::text LIKE '1a6190c0%' OR p.id::text LIKE 'b8e3727a%' OR p.id::text LIKE 'bf91e362%'
        OR p.id::text LIKE '903b537b%' OR p.id::text LIKE 'af66146f%' OR p.id::text LIKE '97f376e1%'
        OR p.id::text LIKE '837613f5%';

  SELECT count(*) INTO v_cnt FROM _buckets;
  IF v_cnt <> 7 THEN RAISE EXCEPTION 'CC_0213: resolved % bucket rows, expected 7', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM _buckets WHERE fore IS NULL OR fore = '';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0213: % bucket rows have no usable forename', v_cnt; END IF;
  -- every bucket row must be inactive; detaching finance from a live page is a different decision
  SELECT count(*) INTO v_cnt FROM _buckets b JOIN essentials.politicians p ON p.id=b.id WHERE p.is_active;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0213: % bucket rows are ACTIVE — refusing', v_cnt; END IF;

  -- ───────────────────────────────────────────── PART 2 first: repoint, then detach the rest
  FOR r IN
    SELECT x.ext, x.owner, x.bucket_like, x.nm
      FROM (VALUES
        ('1414453','d3b4ee4d','1a6190c0%','Melissa Hurtado'),
        ('1401462','d3b4ee4d','1a6190c0%','Melissa Hurtado'),
        ('1446273','d3b4ee4d','1a6190c0%','Melissa Hurtado'),
        ('1395239','d3b4ee4d','1a6190c0%','Melissa Hurtado'),
        ('1386623','d3b4ee4d','1a6190c0%','Melissa Hurtado'),
        ('1456524','038b7624','903b537b%','Joe Patterson'),
        ('1476880','038b7624','903b537b%','Joe Patterson'),
        ('1443381','038b7624','903b537b%','Joe Patterson'),
        ('1388707','038b7624','903b537b%','Joe Patterson')
      ) AS x(ext, owner, bucket_like, nm)
  LOOP
    -- the owner must exist, be active, and be the person the evidence names
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.id::text LIKE r.owner || '%' AND p.full_name = r.nm AND p.is_active) THEN
      RAISE EXCEPTION 'CC_0213: no active politician "%" at % — refusing to repoint', r.nm, r.owner;
    END IF;
    SELECT p.id INTO v_sid FROM essentials.politicians p
      WHERE p.id::text LIKE r.owner || '%' AND p.full_name = r.nm;

    -- exactly one source row: this external_id as it hangs on THAT bucket row
    SELECT count(*) INTO v_cnt
      FROM transparent_motivations.politician_sources s
      JOIN _buckets b ON b.id = s.essentials_politician_id
     WHERE s.source_system='cal_access' AND s.external_id = r.ext AND b.id::text LIKE r.bucket_like;
    IF v_cnt <> 1 THEN
      RAISE EXCEPTION 'CC_0213: external_id % resolves to % sources on its bucket row, expected 1', r.ext, v_cnt;
    END IF;

    UPDATE transparent_motivations.politician_sources s
       SET essentials_politician_id = v_sid,
           research_status = 'confirmed'
     WHERE s.source_system='cal_access' AND s.external_id = r.ext
       AND s.essentials_politician_id IN (SELECT id FROM _buckets WHERE id::text LIKE r.bucket_like);
    n_point := n_point + 1;
  END LOOP;

  IF n_point <> 9 THEN RAISE EXCEPTION 'CC_0213: repointed % sources, expected 9', n_point; END IF;

  -- ───────────────────────────────────────────── PART 1: detach what does not name the person
  WITH moved AS (
    UPDATE transparent_motivations.politician_sources s
       SET research_status = 'disputed'
      FROM _buckets b
     WHERE s.essentials_politician_id = b.id
       AND s.source_system = 'cal_access'
       AND s.research_status <> 'disputed'
       AND (
         (regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1] IS NULL
         OR position(b.fore in upper((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1])) = 0
       )
    RETURNING 1)
  SELECT count(*) INTO v_cnt FROM moved;
  n_disp := v_cnt::int;

  IF n_disp <> 159 THEN
    RAISE EXCEPTION 'CC_0213: detached % sources, expected 159 — the bucket contents have changed', n_disp;
  END IF;

  -- ──────────────────────────────────────────────────────────────── verify
  -- 1. THE REAL INVARIANT: a bucket row may still publish money, but ONLY from a committee whose
  --    name carries its own forename. Erickson legitimately keeps his 981, and he IS a bucket row —
  --    an earlier version of this check asserted "0 published" and failed on exactly that.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
    JOIN _buckets b ON b.id = s.essentials_politician_id
   WHERE s.research_status = 'confirmed' AND s.source_type = 'candidate_committee'
     AND s.source_system = 'cal_access'
     AND (
       (regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1] IS NULL
       OR position(b.fore in upper((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1])) = 0
     );
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0213: bucket rows still publish % contributions from committees that do not name them', v_cnt;
  END IF;

  -- 2. John Erickson must KEEP his own money. This is the middle-name trap, asserted.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id::text LIKE 'af66146f%'
     AND s.research_status = 'confirmed';
  IF v_cnt <> 981 THEN
    RAISE EXCEPTION 'CC_0213: John M. Erickson reads % of his own contributions, expected 981 — the forename predicate is wrong', v_cnt;
  END IF;

  -- 3. the two people who gained their real finance
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id::text LIKE 'd3b4ee4d%' AND s.research_status='confirmed';
  IF v_cnt <> 1577 THEN
    RAISE EXCEPTION 'CC_0213: Melissa Hurtado reads % contributions, expected 1577', v_cnt;
  END IF;
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id::text LIKE '038b7624%' AND s.research_status='confirmed';
  IF v_cnt <> 1418 THEN
    RAISE EXCEPTION 'CC_0213: Joe Patterson reads % contributions, expected 1418', v_cnt;
  END IF;

  -- 4. NO check for orphaned contributions. This migration deletes no politician_sources row,
  --    so the foreign key already guarantees it — and a NOT EXISTS over the whole
  --    contributions table exceeds the statement timeout, which is how that was found out.

  RAISE NOTICE 'CC_0213: detached % mis-attributed cal_access sources from 7 surname buckets; repointed % to Melissa Hurtado (1,577 contributions) and Joe Patterson (1,418). John M. Erickson keeps his own 981. No contribution row was touched.',
    n_disp, n_point;
END $$;

COMMIT;
