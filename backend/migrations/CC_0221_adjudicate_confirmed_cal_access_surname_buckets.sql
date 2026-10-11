-- CC_0221 — the surname-bucket defect is in the CONFIRMED population too. Adjudicate 69 of it.
--
-- `CC_0213`-`CC_0218` cleaned the surname buckets out of the **disputed** CAL-ACCESS population.
-- This migration records that the same defect is **live in the `confirmed` population**, where a
-- source is published rather than withheld, and adjudicates the part of it that primary evidence
-- settles outright.
--
-- Worklist and method: `.planning/todos/2026-10-10-cal-access-confirmed-518-audit-log.md`.
-- Reframing that produced it: `.planning/todos/2026-10-10-cal-access-published-source-audit.md`.
--
--
-- ══ WHAT THE AUDIT FOUND ═════════════════════════════════════════════════════════════════════
--
-- 223 of the 518 `confirmed` / `candidate_committee` sources were checked against the CAL-ACCESS
-- **candidate** page — the primary source that names a candidate *and* their committees by filer
-- id. That covered **$338.7M of the $357.4M those sources publish (94.8%)**.
--
-- 🟢 **The money side came back clean.** Not one money-carrying source was found on the wrong
-- politician. The ten heaviest politicians — 80 sources, $265M — produced a single defect, and it
-- carries $0.
--
-- 🔴 **The defect is not where the money is. It is on EIGHT INACTIVE DUPLICATE ROWS**, which hold
-- 100 `confirmed` sources between them and carry $0:
--
--     Dan O'Brien         80207395   44 sources,  0 name him
--     Paulette Francis    7e7834d9   23 sources,  2 name her
--     Tasha Cerda         7e189f77   10 sources,  3 name her
--     Lauren Meister      55233c22    8 sources,  3 name her
--     Maria Davila        4931b7d2    6 sources,  0 name her
--     Haidar Awad         156a8cc8    4 sources,  1 names him
--     Marvin Crist        ba8b83fd    3 sources,  2 name him
--     Drew Boyles         39d282fe    2 sources,  1 names him
--                                  ─── 100 sources
--
-- Dan O'Brien's 44 include committees to elect **David W., Sean, Frank, Mike, Rennie, Kate, Cindy,
-- Gerald, Richard, Shannon, Jason, Bill, Edward, Martha, Michelle and Eimear O'Brien**. Not one
-- says Dan. Paulette Francis's 23 include **Francis Carbajal** and **Francis Tsang** — matched on
-- the *forename* Francis, not on the surname at all — and `BARCLAY SUPERIOR COURT JUDGE, COMMITTEE
-- TO ELECT FRANCIS FRITZ`, whose surname is Barclay.
--
-- 🔴🔴 **EVERY ONE OF THE EIGHT DUPLICATES A LIVE, SEATED OFFICIAL OF THE SAME NAME.** Nothing
-- publishes today, because the rows are `is_active = false` and carry no contributions. But the
-- dedupe programme merges duplicates into live rows, and **that merge is the `CC_0220` incident** —
-- 18 foreign committees landed on Bryan Fish's and Angie Reyes English's live rows. Here it would
-- be 100 sources across eight officeholders. This migration is the prerequisite, exactly as
-- `CC_0217` was for its four: **attribution first, merge second.**
--
-- ⚠ **THE CANDIDATE-PAGE METHOD CANNOT RESOLVE THESE.** None of the eight are CAL-ACCESS *state*
-- candidates, so no candidate page exists for them. The evidence used here is the **committee's own
-- official name**, which names a different person outright. Positive-controlled: a `letter=O` sweep
-- over 13 sessions returns `O'DONNELL` but no `O'BRIEN`, while the same code finds `LACKEY` under
-- `L`. A "not found" was not taken on trust.
--
--
-- ══ WHAT THIS MIGRATION DOES, AND DELIBERATELY DOES NOT ══════════════════════════════════════
--
-- **69 sources change. 32 of the 100 are left exactly as they are**, because the evidence does not
-- settle them and a guess in either direction is a claim this corpus should not make.
--
--   PART A  66 -> `not_applicable`  the committee name names a DIFFERENT PERSON
--   PART B   3 -> `disputed`        the committee SUPPORTS or OPPOSES the person; it is not theirs
--   (left)  32                      undetermined, or genuinely theirs — see below
--
-- 🔴 **DAN O'BRIEN IS A CULVER CITY COUNCIL MEMBER, so `1444844` and `1482680`
-- (`O'BRIEN FOR CULVER CITY COUNCIL 2022` / `2026`) are left `confirmed`.** They carry no forename,
-- and an earlier pass of this audit had them in the disputed list on that basis alone. Checking the
-- live twin's jurisdiction is what pulled them back out. **A missing forename is not evidence of a
-- wrong owner.** The same reasoning leaves Lauren Meister's two West Hollywood district committees,
-- Maria Davila's South Gate one, and Tasha Cerda's unnamed South Bay Irrigation one for a pass that
-- can evidence them.
--
-- ⚠ `1276861` `O'BRIEN, COMMITTEE TO ELECT DR.` is also left alone. "DR." is a title, not a
-- forename: it does not name Dan and it does not name anybody else either.
--
-- ⚠ **PART B IS NOT `ie_committee`, AND THAT IS ON PURPOSE.** `OutsideSpendingCommittee` carries no
-- support/oppose field, so publishing `HAWTHORNE CITIZENS OPPOSING HAIDAR AWAD` as outside spending
-- would still misstate it — the same design question the Newsom recall committee raised and which
-- the worklist leaves open. `disputed` publishes nothing and is the correct resting state until the
-- UI can say "opposing".
--
-- 🔴 **One of the three is a defect of the worst kind the money-first ordering would never reach:**
-- `1434041` `AWAD FOR MAYOR 2020; HAWTHORNE CITIZENS OPPOSING HAIDAR` is published as Haidar Awad's
-- **own fundraising**. It is a committee formed against him.
--
-- **Plus one source outside the eight rows.** `1446273` `HURTADO FOR SENATE 2026` sits `confirmed`
-- on **Melissa Hurtado**, who is live and incumbent. CAL-ACCESS's candidate pages put it on
-- **ESMERALDA HURTADO** (filer `1446266`), not Melissa (filer `1401463`); Melissa's own 2026
-- committee is `1456951` `HURTADO FOR SENATE 2026; VALLEY FAMILIES FOR MELISSA`. There is no
-- Esmeralda Hurtado row in this corpus — only `cal_access_discovery` placeholders — so the terminal
-- state is `not_applicable`, not a repoint.
--
-- Terminal state `not_applicable` follows the operator ruling of 2026-10-09 recorded in `CC_0216`:
-- `disputed` reads as *contested and unresolved* and invites the next session to redo the research.
--
-- ⚠ **NO MONEY MOVES AND NONE CAN.** All 69 carry zero contributions, asserted both before and
-- after. `contributions.politician_source_id` has no foreign key, so nothing is deleted here —
-- only `research_status` changes.

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n_na int;
  n_dsp int;
BEGIN
  CREATE TEMP TABLE _na (pid uuid, ext text) ON COMMIT DROP;
  CREATE TEMP TABLE _dsp (pid uuid, ext text) ON COMMIT DROP;

  -- PART A — the committee's official name names a different person.
  INSERT INTO _na (pid, ext) VALUES
    -- Dan O'Brien (34): David W., Sean, Frank, Mike, Rennie, Gerald, Kate, Cindy, Richard,
    -- Shannon, Jason, Bill, Edward, Martha, Michelle, Eimear — never Dan.
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1060592'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1065364'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1077492'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1219624'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1225629'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1229362'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1239227'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1243271'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1243272'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1248607'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1268332'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1268697'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1314511'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1320715'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1333061'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1345886'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1358235'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1365865'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1369305'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1369349'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1377832'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1378043'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1391622'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1393119'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1398369'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1408090'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1427336'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1444431'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1447511'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1455265'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1459295'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1473329'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1474236'),
    ('80207395-5f7a-43e9-bfe7-8d33e35d557b','1478133'),
    -- Paulette Francis (17): Frank, Francis Fritz Barclay, Janet, Andy, Jolene, Larry N.,
    -- Francis Carbajal (x3), a Redding slate, Roy R. (x2), Richard, Francis Tsang,
    -- Tyler Francis Shields, Emily (x2).
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1050856'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1065526'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1230637'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1236974'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1266322'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1275887'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1301225'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1333322'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1334331'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1359179'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1373841'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1382040'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1445176'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1469465'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1469850'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1471459'),
    ('7e7834d9-9649-4ea3-9727-c46c80a390ac','1488194'),
    -- Tasha Cerda (5): Jose F. (x3), Jesse, Gerald.
    ('7e189f77-9074-420e-807a-5cc79a1e9957','1390539'),
    ('7e189f77-9074-420e-807a-5cc79a1e9957','1430104'),
    ('7e189f77-9074-420e-807a-5cc79a1e9957','1433852'),
    ('7e189f77-9074-420e-807a-5cc79a1e9957','1434180'),
    ('7e189f77-9074-420e-807a-5cc79a1e9957','1480144'),
    -- Lauren Meister (2): Christian, Judith.
    ('55233c22-4e02-44fd-bd4e-8028ac44d76c','1258892'),
    ('55233c22-4e02-44fd-bd4e-8028ac44d76c','1308428'),
    -- Maria Davila (4): Brigitte (x3, San Francisco), Cheryl (Berkeley).
    ('4931b7d2-9b28-4d8d-9290-9e477a844e99','1371220'),
    ('4931b7d2-9b28-4d8d-9290-9e477a844e99','1385748'),
    ('4931b7d2-9b28-4d8d-9290-9e477a844e99','1406559'),
    ('4931b7d2-9b28-4d8d-9290-9e477a844e99','1450929'),
    -- Haidar Awad (1): Corinne.
    ('156a8cc8-2e5a-4d1f-8a10-e8b3614f7c98','1471081'),
    -- Marvin Crist (1): Robin.
    ('ba8b83fd-d7af-4db0-8226-59cd4655955b','1280084'),
    -- Drew Boyles (1): Denny.
    ('39d282fe-303e-4768-bcf7-4b50d3c244b0','1232515'),
    -- Melissa Hurtado (1), LIVE AND INCUMBENT: this is Esmeralda Hurtado's committee.
    ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26','1446273');

  -- PART B — supports or opposes the person; not a committee they control.
  INSERT INTO _dsp (pid, ext) VALUES
    ('7e189f77-9074-420e-807a-5cc79a1e9957','1484689'),  -- CERDA 2026; SUPPORTERS OF MAYOR TASHA
    ('55233c22-4e02-44fd-bd4e-8028ac44d76c','1375008'),  -- ... IN SUPPORT OF LAUREN MEISTER
    ('156a8cc8-2e5a-4d1f-8a10-e8b3614f7c98','1434041');  -- HAWTHORNE CITIZENS OPPOSING HAIDAR

  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT s.id, s.essentials_politician_id AS pid, s.external_id AS ext, 'na'::text AS grp
      FROM transparent_motivations.politician_sources s
      JOIN _na n ON n.pid = s.essentials_politician_id AND n.ext = s.external_id
     WHERE s.source_system = 'cal_access' AND s.source_type = 'candidate_committee'
    UNION ALL
    SELECT s.id, s.essentials_politician_id, s.external_id, 'dsp'
      FROM transparent_motivations.politician_sources s
      JOIN _dsp d ON d.pid = s.essentials_politician_id AND d.ext = s.external_id
     WHERE s.source_system = 'cal_access' AND s.source_type = 'candidate_committee';

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  -- 1. Every listed pair resolves to exactly one source. The UNIQUE index on
  --    (politician, source_system, external_id) makes one the only possible answer.
  SELECT count(*) INTO v_cnt FROM _srcs;
  IF v_cnt <> 69 THEN RAISE EXCEPTION 'CC_0221: listed pairs resolve to % sources, expected 69', v_cnt; END IF;

  -- 2. All 69 are CONFIRMED right now. If a pass already moved one, stop and re-read the worklist.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'confirmed';
  IF v_cnt <> 69 THEN RAISE EXCEPTION 'CC_0221: % of the 69 are confirmed, expected 69', v_cnt; END IF;

  -- 3. 🔴 NOT ONE CARRIES MONEY. This is what makes the change invisible to every voter page, and
  --    it is asserted rather than assumed — a source that had gained a contribution since the
  --    audit must stop this migration, not be quietly demoted.
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0221: the 69 sources carry % contributions, expected 0 — refusing', v_contrib0;
  END IF;

  -- 4. The eight bucket rows are INACTIVE, and Melissa Hurtado's is ACTIVE. Both halves matter:
  --    the first says nothing publishes today, the second says why 1446273 was worth finding.
  SELECT count(*) INTO v_cnt
    FROM essentials.politicians p
   WHERE p.id IN ('80207395-5f7a-43e9-bfe7-8d33e35d557b','7e7834d9-9649-4ea3-9727-c46c80a390ac',
                  '7e189f77-9074-420e-807a-5cc79a1e9957','55233c22-4e02-44fd-bd4e-8028ac44d76c',
                  '4931b7d2-9b28-4d8d-9290-9e477a844e99','156a8cc8-2e5a-4d1f-8a10-e8b3614f7c98',
                  'ba8b83fd-d7af-4db0-8226-59cd4655955b','39d282fe-303e-4768-bcf7-4b50d3c244b0')
     AND p.is_active;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0221: % of the 8 bucket rows are ACTIVE — refusing', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians p
   WHERE p.id = 'd3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26' AND p.is_active;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0221: Melissa Hurtado is not the live row — re-check'; END IF;

  -- 5. The eight rows hold 100 confirmed sources, and this migration touches 68 of them. The
  --    other 32 are deliberately left; if that total has moved, the worklist is stale.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.source_type = 'candidate_committee'
     AND s.research_status = 'confirmed'
     AND s.essentials_politician_id IN (
       '80207395-5f7a-43e9-bfe7-8d33e35d557b','7e7834d9-9649-4ea3-9727-c46c80a390ac',
       '7e189f77-9074-420e-807a-5cc79a1e9957','55233c22-4e02-44fd-bd4e-8028ac44d76c',
       '4931b7d2-9b28-4d8d-9290-9e477a844e99','156a8cc8-2e5a-4d1f-8a10-e8b3614f7c98',
       'ba8b83fd-d7af-4db0-8226-59cd4655955b','39d282fe-303e-4768-bcf7-4b50d3c244b0');
  IF v_cnt <> 100 THEN RAISE EXCEPTION 'CC_0221: the 8 rows hold % confirmed sources, expected 100', v_cnt; END IF;

  -- ── PART A ────────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes, '')
                 || ' | NOT APPLICABLE CC_0221: the committee name names a different person; '
                 || 'adjudicated against CAL-ACCESS committee and candidate pages 2026-10-10',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND x.grp = 'na' AND s.research_status = 'confirmed';
  GET DIAGNOSTICS n_na = ROW_COUNT;
  IF n_na <> 66 THEN RAISE EXCEPTION 'CC_0221: marked % not_applicable, expected 66', n_na; END IF;

  -- ── PART B ────────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'disputed',
         notes = COALESCE(s.notes, '')
                 || ' | DISPUTED CC_0221: supports or opposes this politician; not a committee they '
                 || 'control. NOT retyped ie_committee because OutsideSpendingCommittee carries no '
                 || 'support/oppose field and would misstate an OPPOSING committee',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND x.grp = 'dsp' AND s.research_status = 'confirmed';
  GET DIAGNOSTICS n_dsp = ROW_COUNT;
  IF n_dsp <> 3 THEN RAISE EXCEPTION 'CC_0221: marked % disputed, expected 3', n_dsp; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- 1. End state of the 69, read back rather than inferred from the row counts above.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 66 THEN RAISE EXCEPTION 'CC_0221: % not_applicable, expected 66', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'CC_0221: % disputed, expected 3', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'confirmed';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0221: % of the 69 are still confirmed', v_cnt; END IF;

  -- 2. The 8 rows now publish 32 sources, not 100. 🔴 Counting what is LEFT is the check that
  --    catches an over-wide UPDATE; the ROW_COUNT above cannot, because it only sees what matched.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.source_type = 'candidate_committee'
     AND s.research_status = 'confirmed'
     AND s.essentials_politician_id IN (
       '80207395-5f7a-43e9-bfe7-8d33e35d557b','7e7834d9-9649-4ea3-9727-c46c80a390ac',
       '7e189f77-9074-420e-807a-5cc79a1e9957','55233c22-4e02-44fd-bd4e-8028ac44d76c',
       '4931b7d2-9b28-4d8d-9290-9e477a844e99','156a8cc8-2e5a-4d1f-8a10-e8b3614f7c98',
       'ba8b83fd-d7af-4db0-8226-59cd4655955b','39d282fe-303e-4768-bcf7-4b50d3c244b0');
  IF v_cnt <> 32 THEN RAISE EXCEPTION 'CC_0221: the 8 rows now publish % sources, expected 32', v_cnt; END IF;

  -- 3. 🔴 Dan O'Brien's two CULVER CITY committees are still confirmed. He is a Culver City
  --    council member; an earlier pass had these in the disputed list on "no forename" alone.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = '80207395-5f7a-43e9-bfe7-8d33e35d557b'
     AND s.external_id IN ('1444844','1482680') AND s.research_status = 'confirmed';
  IF v_cnt <> 2 THEN
    RAISE EXCEPTION 'CC_0221: % of O''Brien''s 2 Culver City committees survive, expected 2', v_cnt;
  END IF;

  -- 4. Melissa Hurtado keeps her own 2026 committee. Removing the wrong one must not take the
  --    right one with it.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = 'd3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'
     AND s.external_id = '1456951' AND s.research_status = 'confirmed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0221: Melissa Hurtado lost her own 2026 committee'; END IF;

  -- 5. No contribution row was touched or stranded. It was 0 before and must be 0 now.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0221: the 69 sources carried % contributions and now carry %', v_contrib0, v_cnt;
  END IF;

  -- 6. Nothing outside the 69 changed status today on any cal_access candidate source.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.source_type = 'candidate_committee'
     AND s.notes LIKE '%CC_0221%' AND s.id NOT IN (SELECT id FROM _srcs);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0221: % sources outside the worklist carry a CC_0221 note', v_cnt; END IF;

  RAISE NOTICE 'CC_0221: 66 not_applicable, 3 disputed, 32 left on the 8 duplicate rows, 0 money moved';
END $$;

COMMIT;
